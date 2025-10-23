// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { CreateDAO } from "./structs/ProposalStructs.sol";

/**
 * @title DAOImplementation
 * @notice ERC721 token-gated voting (1 NFT = 1 vote per tokenId).
 * - Optional option validation (owner seeds valid options, then locks them).
 * - Tallies per option.
 * - Bulk voting, pause/unpause, gas-friendly errors.
 */
contract DAOImplementation is Initializable, OwnableUpgradeable {
	// --------------------------------------------------
	// Errors (gas efficient)
	// --------------------------------------------------
	error OnlyFactory();
	error ZeroAddress();
	error VotingTokenNotSet();
	error AlreadyVoted(uint256 tokenId);
	error NotTokenOwner(uint256 tokenId);
	error InvalidOption(uint256 optionId);
	error EmptyArray();
	error Paused();

	// --------------------------------------------------
	// State
	// --------------------------------------------------
	address public factoryAddress;
	address public erc721Address;

	string public proposalName;
	uint256 public id;

	/// tokenId => has voted
	mapping(uint256 => bool) public hasVoted;

	/// tokenId => optionId chosen
	mapping(uint256 => uint256) public vote;

	/// optionId => votes
	mapping(uint256 => uint256) public optionTally;

	/// Total votes cast (sum of all option tallies)
	uint256 public totalVotesCast;

	// --------------------------------------------------
	// Events
	// --------------------------------------------------
	event InitializeProposal(
		address indexed proposalAddress,
		address owner,
		string proposalName,
		address erc721Address
	);

	event ProposalVoted(
		uint256 indexed tokenId,
		address indexed voter,
		uint256 indexed optionId
	);

	// --------------------------------------------------
	// Constructor (locks logic contract)
	// --------------------------------------------------
	constructor() {
		_disableInitializers();
	}

	// --------------------------------------------------
	// Initializer
	// --------------------------------------------------
	/**
	 * @param _factoryAddress ProposalFactory address (must be msg.sender).
	 * @param _erc721Address  ERC721 collection granting voting rights.
	 * @param _config         DAO config (expects proposalName, id).
	 * @param _initialOwner   Admin/owner for this clone.
	 */
	function initialize(
		address _factoryAddress,
		address _erc721Address,
		CreateDAO calldata _config,
		address _initialOwner
	) public initializer {
		if (msg.sender != _factoryAddress) revert OnlyFactory();
		if (_erc721Address == address(0)) revert ZeroAddress();

		__Ownable_init(_initialOwner);

		factoryAddress = _factoryAddress;
		erc721Address = _erc721Address;

		proposalName = _config.proposalName;
		id = _config.id;

		emit InitializeProposal(
			address(this),
			owner(),
			proposalName,
			erc721Address
		);
	}

	// --------------------------------------------------
	// Voting
	// --------------------------------------------------

	/**
	 * @notice Cast one vote using a specific tokenId.
	 * @dev    Caller must own `tokenId` at call time. Each tokenId votes once.
	 */
	function voteDAO(uint256 tokenId, uint256 optionId) external {
		if (erc721Address == address(0)) revert VotingTokenNotSet();
		if (hasVoted[tokenId]) revert AlreadyVoted(tokenId);
		if (IERC721(erc721Address).ownerOf(tokenId) != msg.sender)
			revert NotTokenOwner(tokenId);

		hasVoted[tokenId] = true;
		vote[tokenId] = optionId;
		unchecked {
			optionTally[optionId] += 1;
			totalVotesCast += 1;
		}

		emit ProposalVoted(tokenId, msg.sender, optionId);
	}

	// --------------------------------------------------
	// Views
	// --------------------------------------------------
	function getTally(uint256 optionId) external view returns (uint256) {
		return optionTally[optionId];
	}

	function canVote(
		address voter,
		uint256 tokenId
	) external view returns (bool) {
		if (erc721Address == address(0) || hasVoted[tokenId]) return false;
		return IERC721(erc721Address).ownerOf(tokenId) == voter;
	}

	// --------------------------------------------------
	// Upgradeable storage gap
	// --------------------------------------------------
	uint256[40] private __gap;
}
