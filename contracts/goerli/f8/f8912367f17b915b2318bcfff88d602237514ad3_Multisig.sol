// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./Dependencies.sol";
import "./TerminallyOnline.sol";


contract Multisig {
  TerminallyOnline public baseContract;

  address public admin;

  struct Proposal {
    bool executed;
    uint256 totalVotes;
    uint256 maxVotes;
  }

  mapping(uint256 => Proposal) public proposals;
  mapping(uint256 => mapping(uint256 => bool)) public proposalVotes;

  constructor(TerminallyOnline _addr) {
    baseContract = _addr;
  }

  function hashProposal(
    address target,
    uint256 value,
    bytes memory calldata_
  ) public pure returns (uint256) {
    return uint256(keccak256(abi.encode(target, value, calldata_)));
  }


  /*
    target    - target contract
    value     - amount of ETH to send
    calldata_ - abi.encodeWithSignature("functionToCall(string,uint256)", "arg1", 123)
  */
  function propose(
    uint256 tokenId,
    address target,
    uint256 value,
    bytes memory calldata_
  ) public returns (uint256) {
    uint256 proposalId = hashProposal(target, value, calldata_);
    proposals[proposalId].maxVotes = baseContract.totalSupply();

    castVote(proposalId, tokenId, true);

    return proposalId;
  }

  function castVote(uint256 proposalId, uint256 tokenId, bool vote) public {
    require(baseContract.ownerOf(tokenId) == msg.sender);
    if (proposalVotes[proposalId][tokenId] == vote) return;

    proposalVotes[proposalId][tokenId] = vote;
    if (vote) {
      proposals[proposalId].totalVotes += 1;
    } else {
      proposals[proposalId].totalVotes -= 1;
    }
  }

  function execute(
    address target,
    uint256 value,
    bytes memory calldata_
  ) public payable returns (uint256) {
    uint256 proposalId = hashProposal(target, value, calldata_);

    Proposal storage proposal = proposals[proposalId];

    require(!proposal.executed, "Proposal has already been executed");
    require(
      proposal.totalVotes >= (proposal.maxVotes/2 + 1),
      "Insufficient votes to execute proposal"
    );

    proposal.executed = true;

    (bool success, bytes memory returndata) = target.call{value: value}(calldata_);
    Address.verifyCallResult(success, returndata, "Proposal execution reverted");

    return proposalId;
  }

  function adminExecute(
    address target,
    uint256 value,
    bytes memory calldata_
  ) public payable {
    require(msg.sender == admin);
    (bool success, bytes memory returndata) = target.call{value: value}(calldata_);
    Address.verifyCallResult(success, returndata, "Proposal execution reverted");
  }

  function setAdmin(address _admin) public {
    require(address(this) == msg.sender, 'Caller must equal this contract');
    admin = _admin;
  }

  receive() external payable {}
  fallback() external payable {}
}