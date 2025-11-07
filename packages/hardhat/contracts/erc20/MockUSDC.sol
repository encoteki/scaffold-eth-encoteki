// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";

/// @title MockUSDC with public capped mint pool
/// @notice 20% supply to owner on deploy, 80% to this contract so users can claim from a daily-limited faucet.
/// - 6 decimals like USDC
/// - Per-address limit using either calendar UTC day or sliding 24h window
/// - Optional block of contract callers (best-effort; not perfect)
/// - ERC20Permit support
contract MockUSDC is ERC20, ERC20Permit, Ownable, ReentrancyGuard, Pausable {
  // --- Constants & config ---
  uint8 private constant USDC_DECIMALS = 6;

  /// @dev default daily cap = 50 USDC (in base units)
  uint256 public dailyCap = 50 * 10 ** USDC_DECIMALS;

  /// @dev choose accounting mode for per-address limit
  enum LimitMode {
    CalendarDayUTC,
    Sliding24H
  }
  LimitMode public limitMode = LimitMode.CalendarDayUTC;

  /// @dev optionally block contract callers (best-effort)
  bool public blockContracts;

  // --- Accounting storage ---
  // Calendar-day mode
  mapping(address => uint256) public mintedToday;
  mapping(address => uint256) public lastMintDayIndex; // day index = block.timestamp / 1 days

  // Sliding 24h window mode
  mapping(address => uint256) public windowStart; // timestamp when the user's current window started
  mapping(address => uint256) public mintedInWindow; // amount minted during current window

  // --- Events ---
  event PublicMint(address indexed to, uint256 amount, uint256 at);
  event DailyCapUpdated(uint256 oldCap, uint256 newCap);
  event LimitModeUpdated(LimitMode oldMode, LimitMode newMode);
  event BlockContractsUpdated(bool enabled);

  constructor(
    string memory name_,
    string memory symbol_,
    uint256 totalSupplyWholeTokens // e.g. 1_000_000 for 1,000,000 USDC
  ) ERC20(name_, symbol_) ERC20Permit(name_) Ownable(msg.sender) {
    require(totalSupplyWholeTokens > 0, "supply=0");
    uint256 units = totalSupplyWholeTokens * (10 ** USDC_DECIMALS);

    uint256 toOwner = (units * 10) / 100; // 10%
    uint256 toContract = units - toOwner; // 90%

    _mint(msg.sender, toOwner);
    _mint(address(this), toContract);
  }

  function decimals() public pure override returns (uint8) {
    return USDC_DECIMALS;
  }

  // --- Admin ---
  function setDailyCap(uint256 newCap) external onlyOwner {
    emit DailyCapUpdated(dailyCap, newCap);
    dailyCap = newCap;
  }

  function setLimitMode(LimitMode mode) external onlyOwner {
    emit LimitModeUpdated(limitMode, mode);
    limitMode = mode;
  }

  function setBlockContracts(bool enabled) external onlyOwner {
    blockContracts = enabled;
    emit BlockContractsUpdated(enabled);
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  // --- Modifiers ---
  modifier onlyEOAIfBlocked() {
    if (blockContracts) {
      // best-effort protection
      require(msg.sender == tx.origin, "no contracts");
    }
    _;
  }

  // --- Public mint (claim from contract pool) ---
  /// @notice Claim tokens from the contract’s balance, respecting per-address daily limits.
  /// @param amount Amount in base units (6 decimals)
  function publicMint(uint256 amount) external nonReentrant whenNotPaused onlyEOAIfBlocked {
    require(amount > 0, "amount=0");
    uint256 nowTs = block.timestamp;

    // Choose logic depending on limit mode
    if (limitMode == LimitMode.CalendarDayUTC) {
      uint256 dayIdx = nowTs / 1 days;

      // Reset user counter if new day
      if (lastMintDayIndex[msg.sender] != dayIdx) {
        lastMintDayIndex[msg.sender] = dayIdx;
        mintedToday[msg.sender] = 0;
      }

      require(mintedToday[msg.sender] + amount <= dailyCap, "cap exceeded");
      mintedToday[msg.sender] += amount;
    } else {
      // Sliding 24-hour window logic
      uint256 start = windowStart[msg.sender];
      if (start == 0 || nowTs >= start + 1 days) {
        windowStart[msg.sender] = nowTs;
        mintedInWindow[msg.sender] = 0;
      }
      require(mintedInWindow[msg.sender] + amount <= dailyCap, "cap exceeded");
      mintedInWindow[msg.sender] += amount;
    }

    // Ensure contract has enough tokens to distribute
    require(balanceOf(address(this)) >= amount, "insufficient pool");

    // Transfer tokens to caller
    _transfer(address(this), msg.sender, amount);

    emit PublicMint(msg.sender, amount, nowTs);
  }

  // --- Recovery (optional, owner only) ---
  /// @notice Owner can recover leftover tokens or other ERC20s sent accidentally
  function recoverERC20(address token, address to, uint256 amount) external onlyOwner nonReentrant {
    require(to != address(0), "to=0");
    require(amount > 0, "amount=0");

    if (token == address(this)) {
      _transfer(address(this), to, amount);
    } else {
      (bool ok, bytes memory data) = token.call(abi.encodeWithSignature("transfer(address,uint256)", to, amount));
      require(ok && (data.length == 0 || abi.decode(data, (bool))), "transfer failed");
    }
  }
}
