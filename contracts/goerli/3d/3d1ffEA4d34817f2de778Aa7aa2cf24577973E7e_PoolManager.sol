/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

contract PoolManager {
  /// @notice Emitted when a new proposal is created
  event NewProposal(uint256 _id, uint256 _method, bytes _params);

  /// @notice Emitted when a user votes on a proposal
  event NewVote(address _voter, uint256 _votes, uint256 _method, uint256 _id);

  /// @notice Emitted when a proposal is cancelled
  event ProposalCancelled(uint256 _id, uint256 _method, bytes _params);

  /// @notice Emitted when a new proposal is executed
  event ProposalExecuted(uint256 _id, uint256 _method, bytes _params);

  /// @notice Emitted when a voter cancels their vote
  event VoteCancelled(address _voter, uint256 _method, uint256 _id);

  /// @notice Emitted when a proposal is queued
  event ProposalQueued(uint256 _id, uint256 _method, bytes _params);

   event FeesCollected(uint256 _totalFeePrice, uint256 _totalFeeToken);
   event RewardsAdded(uint256 _priceAmount, uint256 _tokenAmount);
   event ClaimedRewards(address _owner, address _to, uint256 _priceAmount, uint256 _tokenAmount);

   struct Proposal {
    uint256 id;
    bytes params;
    uint256 forVotes;
    bool open;
    uint256 timelockExpiry;
  }

  function claimRewards(address _to) external returns (uint256 _rewardPrice, uint256 _rewardToken) {
    emit ClaimedRewards(msg.sender, _to, _rewardPrice, _rewardToken);
  }

  function _feesDistribution(uint256 _totalToken0, uint256 _totalToken1) external {
    emit FeesCollected(_totalToken0, _totalToken1);
  }

  function _addRewards(uint256 _priceAmount, uint256 _tokenAmount) external {
    emit RewardsAdded(_priceAmount, _tokenAmount);
  }

    function queue(uint256 _method, bytes memory _parameters) external {
    emit ProposalQueued(block.number, _method, _parameters);
  }

  function cancelVote(uint256 _method) external {
    emit VoteCancelled(msg.sender, _method, block.number);
  }

  function execute(uint256 _method, bytes memory _parameters) external {
    emit ProposalExecuted(block.number, _method, _parameters);
  }

  function _cancelProposal(uint256 _method) external {
    emit ProposalCancelled(block.number, _method, bytes(""));
  }

  function _propose(uint256 _method, bytes memory _parameters) external {
    Proposal memory _newProposal = Proposal({id: block.number + 1, params: _parameters, forVotes: 0, open: true, timelockExpiry: 0});
    emit NewProposal(block.timestamp + _method, block.timestamp + 2, _newProposal.params);
  }

    function _acceptProposal(
    uint256 _method,
    address _voter
  ) external {
    emit NewVote(_voter, block.number, _method, block.number);
  }
}