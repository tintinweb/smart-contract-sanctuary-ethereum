// SPDX-License-Identifier: MIT

/*
  _______ _    _ ______
 |__   __| |  | |  ____|
    | |  | |__| | |__
    | |  |  __  |  __|
    | |  | |  | | |____
   _|_|_ |_|  |_|______|____   _____ _    _
  / ____| |  | | |  | |  __ \ / ____| |  | |
 | |    | |__| | |  | | |__) | |    | |__| |
 | |    |  __  | |  | |  _  /| |    |  __  |
 | |____| |  | | |__| | | \ \| |____| |  | |
  \_____|_|__|_|\____/|_|  \_\\_____|_|  |_|
  / __ \|  ____|
 | |  | | |__
 | |  | |  __|
 | |__| | |
  \____/|_|   _ ______          __ __     __
  / ____| |  | |  _ \ \        / /\\ \   / /
 | (___ | |  | | |_) \ \  /\  / /  \\ \_/ /
  \___ \| |  | |  _ < \ \/  \/ / /\ \\   /
  ____) | |__| | |_) | \  /\  / ____ \| |
 |_____/ \____/|____/_ _\/  \/_/____\_\_|
      | |  ____|/ ____| |  | |/ ____|
      | | |__  | (___ | |  | | (___
  _   | |  __|  \___ \| |  | |\___ \
 | |__| | |____ ____) | |__| |____) |
  \____/|______|_____/_\____/|_____/_      ______ _______ _____
 |  __ \ /\   |  \/  |  __ \| |  | | |    |  ____|__   __/ ____|
 | |__) /  \  | \  / | |__) | |__| | |    | |__     | | | (___
 |  ___/ /\ \ | |\/| |  ___/|  __  | |    |  __|    | |  \___ \
 | |  / ____ \| |  | | |    | |  | | |____| |____   | |  ____) |
 |_| /_/    \_\_|  |_|_|    |_|  |_|______|______|  |_| |_____/

Contract by steviep.eth


"Church" multisig of Subway Jesus Pamphlets

Subway Jesus Pamphlet token holders may vote on transactions, and receive one vote per token owned

Token holders may also delegate their token's vote to another address

All proposals require a 51% quorum of existing token votes to pass

The Church may elect to update the quorum needed

The Cardinal can execute any transaction without a vote

The Church may elect a new Cardinal

*/

pragma solidity ^0.8.11;

import "./SubwayJesusPamphlets.sol";

contract ChurchOfSubwayJesusPamphlets {
  SubwayJesusPamphlets public baseContract;

  address public cardinal;
  uint256 public quorumNeeded = 51;

  struct Proposal {
    bool executed;
    uint256 totalVotes;
  }

  mapping(uint256 => Proposal) private _proposals;
  mapping(uint256 => mapping(uint256 => bool)) private _proposalVotes;
  mapping(uint256 => address) public delegations;

  constructor(SubwayJesusPamphlets _addr, address _cardinal) {
    baseContract = _addr;
    cardinal = _cardinal;
  }

  function proposalVotes(uint256 proposalId, uint256 tokenId) external view returns (bool) {
    return _proposalVotes[proposalId][tokenId];
  }

  function proposals(uint256 proposalId) external view returns (bool executed, uint256 totalVotes) {
    return (_proposals[proposalId].executed, _proposals[proposalId].totalVotes);
  }

  /*
    target    - target contract
    value     - amount of ETH to send
    calldata_ - abi.encodeWithSignature("functionToCall(string,uint256)", "arg1", 123)
    nonce     - can be any number; exists to make sure same proposal can't be executed twice
  */
  function hashProposal(
    address target,
    uint256 value,
    bytes memory calldata_,
    uint256 nonce
  ) public pure returns (uint256) {
    return uint256(keccak256(abi.encode(target, value, calldata_, nonce)));
  }

  function castVote(uint256 proposalId, uint256 tokenId, bool vote) external {
    require(baseContract.ownerOf(tokenId) == msg.sender, 'Voter must be owner of token');
    _castVote(proposalId, tokenId, vote);
  }

  function castVotes(uint256 proposalId, uint256[] calldata tokenIds, bool vote) external {
    for (uint256 i; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      require(
        baseContract.ownerOf(tokenId) == msg.sender
        || delegations[tokenId] == msg.sender,
        "Voter must be owner or delegator of all tokens"
      );
      _castVote(proposalId, tokenId, vote);
    }
  }

  function delegate(uint256[] calldata tokenIds, address delegator) external {
    for (uint256 i; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      require(baseContract.ownerOf(tokenId) == msg.sender, "Signer must own token to delegate");
      delegations[tokenId] = delegator;
    }
  }

  function _castVote(uint256 proposalId, uint256 tokenId, bool vote) private {
    if (_proposalVotes[proposalId][tokenId] == vote) return;

    _proposalVotes[proposalId][tokenId] = vote;

    if (vote) {
      _proposals[proposalId].totalVotes += 1;
    } else {
      _proposals[proposalId].totalVotes -= 1;
    }
  }

  function execute(
    address target,
    uint256 value,
    bytes memory calldata_,
    uint256 nonce
  ) external payable returns (uint256) {
    uint256 proposalId = hashProposal(target, value, calldata_, nonce);

    Proposal storage proposal = _proposals[proposalId];

    require(!proposal.executed, "Proposal has already been executed");

    if (msg.sender != cardinal) {
      require(
        proposal.totalVotes * 100 >= (baseContract.totalSupply() * quorumNeeded),
        "Insufficient votes to execute proposal"
      );
    }

    proposal.executed = true;


    (bool success, bytes memory returndata) = target.call{value: value}(calldata_);
    Address.verifyCallResult(success, returndata, "Proposal execution reverted");

    return proposalId;
  }

  modifier onlyChurch {
    require(address(this) == msg.sender, 'Can only be called by the church');
    _;
  }

  function electCardinal(address _cardinal) external onlyChurch {
    cardinal = _cardinal;
  }

  function updateQuorumNeeded(uint256 quorumPercent) external onlyChurch {
    quorumNeeded = quorumPercent;
  }

  function onERC721Received(address, address, uint256, bytes calldata) external pure returns(bytes4) {
    return this.onERC721Received.selector;
  }

  function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external pure returns (bytes4) {
    return this.onERC1155BatchReceived.selector;
  }

  receive() external payable {}
  fallback() external payable {}
}