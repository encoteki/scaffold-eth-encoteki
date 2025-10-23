// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

/**
 * @title ArtworkImpl
 * @notice ERC721 (upgradeable) where all tokenIds share the same metadata URI.
 *         Owner can update the collection URI until frozen.
 */
contract ArtworkImpl is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, ERC721EnumerableUpgradeable {
    struct CreateArtwork {
        address owner; // initial owner (will own the contract)
        string name; // just your custom display name (off-chain)
        uint256 cost; // custom value you track (off-chain or for minting)
        string baseUri; // the single metadata URI used for ALL tokenIds
    }

    // Custom metadata fields
    string public artworkName;
    uint256 public cost;

    // Shared URI storage
    string private _collectionURI;
    bool public isURIFrozen;

    // Events to help indexers/marketplaces notice changes
    event CollectionURISet(string newURI);
    event CollectionURIFrozen(string finalURI);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        // _disableInitializers();
    }

    function initialize(CreateArtwork calldata _data) public initializer {
        __ERC721_init("Artwork", "ART");
        __ERC721Enumerable_init();
        __Ownable_init(_data.owner);
        __ReentrancyGuard_init();

        artworkName = _data.name;
        cost = _data.cost;
        _collectionURI = _data.baseUri;

        emit CollectionURISet(_data.baseUri);
    }

    // ------------------ URI logic (shared for all tokenIds) ------------------

    /**
     * @dev All tokenIds will return the same URI. We still require existence
     *      so calls for non-existent tokens revert (OZ convention).
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721: invalid token ID");
        return _collectionURI;
    }

    /**
     * @notice Update the shared collection URI (e.g., "ipfs://Qm.../metadata.json").
     *         Will revert if the URI has been frozen.
     */
    function setCollectionURI(string calldata newURI) external onlyOwner {
        require(!isURIFrozen, "URI is frozen");
        _collectionURI = newURI;
        emit CollectionURISet(newURI);
    }

    /**
     * @notice Freeze the collection URI permanently (cannot be undone).
     *         Useful after reveal / finalization.
     */
    function freezeURI() external onlyOwner {
        require(!isURIFrozen, "Already frozen");
        isURIFrozen = true;
        emit CollectionURIFrozen(_collectionURI);
    }

    // ------------------ Minimal mint (example) ------------------

    /**
     * @dev Example safe mint; adjust access/pricing as you like.
     */
    function ownerMint(address to, uint256 tokenId) external onlyOwner nonReentrant {
        _safeMint(to, tokenId);
    }

    // ------------------ Required OZ v5 overrides ------------------

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }
}
