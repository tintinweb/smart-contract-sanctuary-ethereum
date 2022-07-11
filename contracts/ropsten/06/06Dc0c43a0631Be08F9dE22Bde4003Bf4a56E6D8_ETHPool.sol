/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

contract ETHPool {
  uint256 private constant MAGNITUDE = 10 ** 30;

  mapping(address => uint256) private _stakedAmount;
  mapping(address => uint256) private _stakeEntry;
  mapping(address => uint256) private _accured;
  uint256 private _totalStaked;
  uint256 private _totalReward;
  uint256 private _totalAccured;

  address private _owner;
  address private _team;

  constructor() {
    _owner = msg.sender;
  }

  function isTeam() internal view returns (bool) {
    if(_team == address(0))
      return (msg.sender == _owner);
    return (msg.sender == _team);
  }

  function changeTeam(address newTeam) external {
    require(isTeam(), "should be current team");
    require(newTeam != address(0), "Team should not be zero");
    _team = newTeam;
  }

  function team() external view returns (address) {
    return _team;
  }

  receive() external payable {
    require(msg.value > 0, "deposit should be positive");

    if(isTeam()) {
      // team deposit reward
      depositReward(msg.value);
    } else {
      // user deposit eth
      deposit(msg.value);
    }
  }

  function depositReward(uint256 newReward) internal {
    require(_totalStaked > 0, "No one has staked yet");

    _totalReward = _totalReward + newReward;
    _totalAccured = _totalAccured + newReward * MAGNITUDE / _totalStaked;
  }

  function deposit(uint256 stakeAmount) internal {
    if(_stakedAmount[msg.sender] > 0)
      _accured[msg.sender] = currentRewards(msg.sender);

    _stakedAmount[msg.sender] = _stakedAmount[msg.sender] + stakeAmount;
    _totalStaked = _totalStaked + stakeAmount;
    
    _stakeEntry[msg.sender] = _totalAccured;
  }

  // harvest claims all rewards at once
  function harvest() public {
    require(currentRewards(msg.sender) > 0, "Insufficient accured reward");

    uint256 reward = currentRewards(msg.sender);
    _totalReward = _totalReward - reward;
    _accured[msg.sender] = 0;
    _stakeEntry[msg.sender] = _totalAccured;
    
    address payable receiver = payable(msg.sender);
    receiver.transfer(reward);
  }

  // withdraw 'withdrawAmount' ETH from POOL, claim rewards proportionally
  function withdraw(uint256 withdrawAmount) public {
    require(withdrawAmount > 0, "amount should be positive");
    require(_stakedAmount[msg.sender] >= withdrawAmount, "amount exceeds staked");

    _accured[msg.sender] = currentRewards(msg.sender);

    uint256 withdrawRewards = withdrawAmount * _accured[msg.sender] / _stakedAmount[msg.sender];

    _totalStaked = _totalStaked - withdrawAmount;
    _stakedAmount[msg.sender] = _stakedAmount[msg.sender] - withdrawAmount;
    _totalReward = _totalReward - withdrawRewards;
    _accured[msg.sender] = _accured[msg.sender] - withdrawRewards;
    _stakeEntry[msg.sender] = _totalAccured;

    address payable receiver = payable(msg.sender);
    receiver.transfer(withdrawAmount + withdrawRewards);
  }

  // withdraw all ETH from POOL, claim all rewards
  function withdrawAll() public {
    require(_stakedAmount[msg.sender] > 0, "You have no stake");
    withdraw(_stakedAmount[msg.sender]);
  }

  function currentRewards(address addy) public view returns (uint256) {
    return _accured[addy] + _calculateReward(addy);
  }

  function currentStake(address addy) public view returns (uint256) {
    return _stakedAmount[addy];
  }

  function _calculateReward(address addy) private view returns (uint256) {
    return _stakedAmount[addy] * (_totalAccured - _stakeEntry[addy]) / MAGNITUDE;
  } 
}