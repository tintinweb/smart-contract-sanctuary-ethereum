/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

contract LockManager {
    event Locked(uint256 _priceAmount);
    event ClaimedRewards(address _owner, address _to, uint256 _priceAmount, uint256 _tokenAmount);
    event RewardsAdded(uint256 _priceAmount, uint256 _tokenAmount);
    event FeesCollected(uint256 _priceFees, uint256 _tokenFees);
    event Burned(uint256 _priceAmount); event WithdrawalsEnabled();
    event NewVote(address _voter, uint256 _votes, uint256 _method, uint256 _id);
    event VoteCancelled(address _voter, uint256 _method, uint256 _id);
    

  function lock(uint256 _priceAmount) external {
    emit Locked(_priceAmount);
  }

  function burn(uint256 _lockedPriceAmount) external {
    _burn(_lockedPriceAmount);
  }

  function _burn(uint256 _lockedPriceAmount) internal {
    emit Burned(_lockedPriceAmount);
  }

  function claimRewards(address _to) external returns (uint256 _rewardPrice, uint256 _rewardToken) {
    emit ClaimedRewards(msg.sender, _to, _rewardPrice, _rewardToken);
  }

  function addRewards(uint256 _priceAmount, uint256 _tokenAmount) external {
    emit RewardsAdded(_priceAmount, _tokenAmount);
  }

  function burnPositions() external {
    _feesDistribution(block.number, block.number * 2);
  }

  function _feesDistribution(uint256 _totalPrice, uint256 _totalToken) internal {
    emit FeesCollected(_totalPrice, _totalToken);
  }

  function newVote() external {
    emit NewVote(msg.sender, 4, 12, 4);
  }

  function cancelVote() external {
    emit VoteCancelled(msg.sender, 32, 54);
  }
}