// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TheSatwasBandDev is ERC721Enumerable, Ownable, ReentrancyGuard {
  using Strings for uint256;

  // ----- Config -----
  string private _baseTokenURI;
  string public baseExtension = ".json";
  string public notRevealedURI;

  uint256 public cost = 0.0001 ether;
  uint256 public maxSupply = 36;
  uint256 public maxMintPerTx = 1;

  bool public revealed = true;

  // ----- Constructor -----
  constructor(
    string memory name_,
    string memory symbol_,
    string memory initBaseURI_,
    string memory initNotRevealedUri_
  ) ERC721(name_, symbol_) Ownable(msg.sender) {
    _baseTokenURI = initBaseURI_;
    notRevealedURI = initNotRevealedUri_;
  }

  // ----- Minting -----
  // Add nonReentrant to block ERC721Receiver re-entry back into mint()
  function mint() external payable nonReentrant {
    uint256 supply = totalSupply();
    require(supply + maxMintPerTx <= maxSupply, "Max supply reached");

    uint256 requiredValue = cost * maxMintPerTx;
    require(msg.value >= requiredValue, "Insufficient ETH");

    _safeMint(msg.sender, supply + maxMintPerTx);
  }

  // ----- Views -----
  function walletOfOwner(address owner_) external view returns (uint256[] memory) {
    uint256 count = balanceOf(owner_);
    uint256[] memory tokenIds = new uint256[](count);
    for (uint256 i; i < count; ++i) {
      tokenIds[i] = tokenOfOwnerByIndex(owner_, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    _requireOwned(tokenId);

    if (!revealed) {
      return notRevealedURI;
    }

    // string memory currentBaseURI = _baseURI();
    return
      bytes(_baseTokenURI).length > 0 ? string(abi.encodePacked(_baseTokenURI, tokenId.toString(), baseExtension)) : "";
  }

  // ----- Admin -----
  function setRevealed(bool state) external onlyOwner {
    revealed = state;
  }

  function setCost(uint256 newCost) external onlyOwner {
    cost = newCost;
  }

  function setMaxMintPerTx(uint256 newMax) external onlyOwner {
    maxMintPerTx = newMax;
  }

  function setNotRevealedURI(string calldata uri) external onlyOwner {
    notRevealedURI = uri;
  }

  function setBaseURI(string calldata newBaseURI) external onlyOwner {
    _baseTokenURI = newBaseURI;
  }

  function setBaseExtension(string calldata ext) external onlyOwner {
    baseExtension = ext;
  }

  function withdraw() external onlyOwner nonReentrant {
    (bool ok, ) = payable(owner()).call{ value: address(this).balance }("");
    require(ok, "Withdraw failed");
  }

  // ----- Internal -----
  function _baseURI() internal view override returns (string memory) {
    return _baseTokenURI;
  }
}
