// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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
    function mint(uint256 amount) external payable nonReentrant {
        require(amount > 0 && amount <= maxMintPerTx, "Invalid amount");

        uint256 supply = totalSupply();
        require(supply + amount <= maxSupply, "Max supply reached");

        // if (msg.sender != owner()) {
        // 	uint256 requiredValue = cost * amount;
        // 	require(msg.value >= requiredValue, "Insufficient ETH");
        // }

        for (uint256 i = 1; i <= amount; ++i) {
            _safeMint(msg.sender, supply + i);
        }
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

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
                : "";
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
