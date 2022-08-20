// SPDX-License-Identifier: MIT

/*
   ______              _           ____
  /_  __/__ ______ _  (_)__  ___ _/ / /_ __
   / / / -_) __/  ' \/ / _ \/ _ `/ / / // /
  /_/__\__/_/ /_/_/_/_/_//_/\_,_/_/_/\_, /
   / __ \___  / (_)__  ___          /___/
  / /_/ / _ \/ / / _ \/ -_)
  \____/_//_/_/_/_//_/\__/


Multisig Contract
  This is a general-purpose multisig wallet contract where each token of the Terminally Online series gives its owner a single vote on wallet actions.
  The contract logic is based on the Open Zeppelin Governor contract.

  While this contract has the ability to receive any asset, it has two primary roles:
    1. To manage the TokenURI contract of the Terminally Online project. The initial TokenURI contract allows the multisig to update the project's base externalUrl.
    2. To manage the terminallyonline.eth ENS domain, and all subdomain (which it has been given ownership of).

  Proposals
    For the multisig execute any transaction, Terminally Online token holders must take the following steps:
      1. Someone must propose a transaction using `propose`. This must include the tokenId of the proposer, the target address of the transaction, the amount of ETH included in the transaction, and the calldata of the transaction.
      2. A simple majority of the Terminally Online token holders must vote for the proposal.
      3. Once enough votes have been secured, someone must execute the proposal.

  Admin Execution
    For the sake of expediency, the multisig contract can designate an address as the admin, which has the unilateral ability to execute multisig transactions without any votes.
    While the admin can be an EOA, this contract can also be extended by designating another contract as the admin. For example, another contract can define logic in which token holder signatures are validated, which would allow for more gas-efficient voting.
    To set the admin, a proposal needs to be made in which the multisig calls setAdmin on itself.
*/

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