// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract CertWork {
  struct Proposal {
    string description;
    uint256 goalAmount;
    uint256 totalRaised;
    mapping(address => uint256) donations;
    string bronzeMetaURI;
    string silverMetaURI;
    string goldMetaURI;
    address[] bronzeDonors;
    address[] silverDonnors;
    address[] goldDonors;
  }

  Proposal[] public proposals;

  function proposalCount() external view returns (uint256) {
    return proposals.length;
  }

  constructor() {}
}