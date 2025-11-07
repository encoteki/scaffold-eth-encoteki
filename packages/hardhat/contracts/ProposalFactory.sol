// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./BusinessProposalImplementation.sol";
import "./DAOImplementation.sol";
import { ProposalInfo, ProposalType, CreateDAO, CreateProposal } from "./structs/ProposalStructs.sol";

contract ProposalFactory is Ownable {
  using Clones for address;

  // ---------------------------------------------------------------------
  // Types / Events
  // ---------------------------------------------------------------------

  event ProposalCreated(
    address indexed creator,
    address indexed proposalAddress,
    ProposalType proposalType,
    uint256 id
  );

  // ---------------------------------------------------------------------
  // Storage
  // ---------------------------------------------------------------------

  address public daoImplementation;
  address public bpImplementation;
  address public erc721Address;

  ProposalInfo[] private _proposals;

  constructor(address _daoImpl, address _bpImpl, address _erc721Address) Ownable(msg.sender) {
    daoImplementation = _daoImpl;
    bpImplementation = _bpImpl;
    erc721Address = _erc721Address;
  }

  // ---------------------------------------------------------------------
  // Create functions (split)
  // ---------------------------------------------------------------------

  /**
   * @notice Creates a new DAO proposal contract (ProposalType.DAO).
   */
  function createDAOProposal(CreateDAO calldata _config) external returns (address proposalAddress) {
    proposalAddress = daoImplementation.clone();
    // owner of the clone = msg.sender (EOA that called the factory)
    DAOImplementation(proposalAddress).initialize(address(this), erc721Address, _config, msg.sender);

    uint256 newId = _proposals.length + 1;
    _proposals.push(ProposalInfo(newId, ProposalType.DAO, proposalAddress, msg.sender));

    emit ProposalCreated(msg.sender, proposalAddress, ProposalType.DAO, newId);
  }

  /**
   * @notice Creates a new BP proposal contract (ProposalType.BP).
   */
  function createBusinessProposal(CreateProposal calldata _config) external returns (address proposalAddress) {
    proposalAddress = bpImplementation.clone();
    // owner of the clone = msg.sender (EOA that called the factory)
    BusinessProposalImplementation(proposalAddress).initialize(address(this), erc721Address, _config, msg.sender);

    uint256 newId = _proposals.length + 1;
    _proposals.push(ProposalInfo(newId, ProposalType.Business, proposalAddress, msg.sender));

    emit ProposalCreated(msg.sender, proposalAddress, ProposalType.Business, newId);
  }

  // ---------------------------------------------------------------------
  // Getter functions
  // ---------------------------------------------------------------------

  function getProposal(uint256 id) external view returns (ProposalInfo memory) {
    require(id < _proposals.length, "Proposal does not exist");
    return _proposals[id];
  }

  function getAllProposals() external view returns (ProposalInfo[] memory) {
    return _proposals;
  }

  function totalProposals() external view returns (uint256) {
    return _proposals.length;
  }
}
