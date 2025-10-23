// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
/// @title ITheSatwasBandDev
/// @notice Interface for ITheSatwasBandDev NFT contract
/// @dev Mirrors all external/public functions and events of the implementation
interface ITheSatwasBandDev {
    /*//////////////////////////////////////////////////////////////////////////
                                   EVENTS
    //////////////////////////////////////////////////////////////////////////*/
    // ERC721 core
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // Ownable
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////////////////
                                   MINTING
    //////////////////////////////////////////////////////////////////////////*/
    function mint(uint256 amount) external payable;

    /*//////////////////////////////////////////////////////////////////////////
                                   VIEWS (custom + ERC721/165/Ownable)
    //////////////////////////////////////////////////////////////////////////*/
    // Custom view
    function walletOfOwner(address owner_) external view returns (uint256[] memory);

    // Metadata
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    // Supply/ownership
    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    // Approvals
    function getApproved(uint256 tokenId) external view returns (address);

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // Introspection
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // Ownable
    function owner() external view returns (address);

    /*//////////////////////////////////////////////////////////////////////////
                                   AUTO-GENERATED PUBLIC GETTERS
    //////////////////////////////////////////////////////////////////////////*/
    function baseExtension() external view returns (string memory);

    function notRevealedURI() external view returns (string memory);

    function cost() external view returns (uint256);

    function maxSupply() external view returns (uint256);

    function maxMintPerTx() external view returns (uint256);

    function revealed() external view returns (bool);

    /*//////////////////////////////////////////////////////////////////////////
                                   ERC721 ACTIONS
    //////////////////////////////////////////////////////////////////////////*/
    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool approved) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /*//////////////////////////////////////////////////////////////////////////
                                   ADMIN (onlyOwner in impl)
    //////////////////////////////////////////////////////////////////////////*/
    function setRevealed(bool state) external;

    function setCost(uint256 newCost) external;

    function setMaxMintPerTx(uint256 newMax) external;

    function setNotRevealedURI(string calldata uri) external;

    function setBaseURI(string calldata newBaseURI) external;

    function setBaseExtension(string calldata ext) external;

    function transferOwnership(address newOwner) external;

    function renounceOwnership() external;

    function withdraw() external;
}
