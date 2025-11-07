// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import { CreateProposal } from "./structs/ProposalStructs.sol";

/**
 * @title BusinessProposalImplementation
 * @notice Implementation for Business Proposal with a hard fundraising cap.
 */
contract BusinessProposalImplementation is Initializable, OwnableUpgradeable {
  // --------------------------------------------------
  // Errors (gas-efficient reverts)
  // --------------------------------------------------
  error OnlyFactory();
  error InvalidAmount();
  error CapExceeded();

  // --------------------------------------------------
  // State Variables
  // --------------------------------------------------
  address public factoryAddress;
  address public erc721Address;

  string public proposalName;
  uint256 public id;
  uint256 public proposedFund; // fundraising target (cap)
  uint256 public totalAllocated; // sum of all allocations

  /// @notice Mapping [participantAddress] => allocated amount
  mapping(address => uint256) public allocatedFund;

  // --------------------------------------------------
  // Events
  // --------------------------------------------------
  event InitializeProposal(address indexed proposalAddress, address owner, string proposalName, uint256 proposedFund);

  event ProposalVoted(
    // kept your naming; here it represents "allocation"
    address indexed voter,
    address indexed proposalAddress,
    uint256 amount
  );

  event FundsAllocated(address indexed voter, uint256 amount);

  // --------------------------------------------------
  // Constructor
  // --------------------------------------------------
  /// @dev Lock the logic/implementation contract.
  constructor() {
    _disableInitializers();
  }

  // --------------------------------------------------
  // Initializer
  // --------------------------------------------------
  /**
   * @notice Initializes the contract with the given parameters.
   * @param _factoryAddress The address of ProposalFactory.
   * @param _erc721Address Optional reference (kept for symmetry/extensibility).
   * @param _config Proposal config (expects proposalName, id, proposedFund).
   * @param _initialOwner The EOA that will own/admin this clone.
   */
  function initialize(
    address _factoryAddress,
    address _erc721Address,
    CreateProposal calldata _config,
    address _initialOwner
  ) public initializer {
    if (msg.sender != _factoryAddress) revert OnlyFactory();

    __Ownable_init(_initialOwner);

    factoryAddress = _factoryAddress;
    erc721Address = _erc721Address;

    proposalName = _config.proposalName;
    id = _config.id;
    proposedFund = _config.proposedFund;

    emit InitializeProposal(address(this), owner(), proposalName, proposedFund);
  }

  // --------------------------------------------------
  // WRITE: Allocate (a.k.a. "vote with funds")
  // --------------------------------------------------
  /**
   * @notice Allocate funds towards this proposal (tracked in contract state).
   * @dev Enforces that totalAllocated never exceeds proposedFund.
   */
  function fund(uint256 amount) external {
    if (amount == 0) revert InvalidAmount();

    uint256 newTotal = totalAllocated + amount;
    if (newTotal > proposedFund) revert CapExceeded();

    allocatedFund[msg.sender] += amount;
    totalAllocated = newTotal;

    emit ProposalVoted(msg.sender, address(this), amount);
    emit FundsAllocated(msg.sender, amount);
  }

  // --------------------------------------------------
  // VIEWS: Helpers
  // --------------------------------------------------
  /// @notice Remaining capacity before reaching the cap.
  function remainingFund() public view returns (uint256) {
    uint256 allocated = totalAllocated;
    return allocated >= proposedFund ? 0 : (proposedFund - allocated);
  }

  /// @notice Whether the cap has been fully reached.
  function isFull() public view returns (bool) {
    return totalAllocated >= proposedFund;
  }

  /// @notice Whether a given amount could be allocated right now.
  function canAllocate(uint256 amount) public view returns (bool) {
    return amount > 0 && (totalAllocated + amount) <= proposedFund;
  }

  /// @notice Headroom for a specific user (currently same as global remaining).
  /// @dev Kept in case you later add per-user limits/logic.
  function availableToAllocate(address /*user*/) public view returns (uint256) {
    return remainingFund();
  }
}
