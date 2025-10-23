// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

struct CreateDAO {
    string proposalName;
    uint256 id;
}

struct CreateProposal {
    string proposalName;
    uint256 id;
    uint256 proposedFund;
}

enum ProposalType {
    DAO,
    Business
}

struct ProposalInfo {
    uint256 id;
    ProposalType proposalType;
    address proposalAddress;
    address creator;
}
