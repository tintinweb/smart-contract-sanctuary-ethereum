/**
 *Submitted for verification at Etherscan.io on 2022-04-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @title ExactlyPool
/// @author Rodrigo Bronzelle
/// @notice This contract creates a pool of Ether that rewards its parties proportionally to the amount of Ether they
/// have deposited.
contract ExactlyPool {
  event LogLabelValue(string label, uint256);

  // Reward
  struct RewardData {
    uint256 id;
    uint256 sharedA;
    uint256 sharedB;
  }
  RewardData private rewardData;
  uint256 private rewardId;

  // Account
  struct AccountData {
    uint256 balance;
    uint256 oldSharedRewardA;
    uint256 oldSharedRewardB;
    uint256 rewardId;
  }
  mapping(address => AccountData) private accountPool;

  // contract
  address private owner;

  /// @notice Constructor
  constructor() {
    owner = msg.sender;
    rewardId = 0;
    rewardData.sharedA = 1;
    rewardData.sharedB = 1;
  }

  /// @notice Add reward to distribute it to the pool. Only contract's owner canadd reward. A value must be proovided.
  function addReward() public payable {
    require(msg.sender == owner, "Only team can add reward");
    // Simplifying fraction to avoid arithmetic overflow.
    // Since B is always smaller than A, don't need to check it.
    if (rewardData.sharedB > 0.0000001 ether) {
      rewardData.sharedA /= 0.0000001 ether;
      rewardData.sharedB /= 0.0000001 ether;
    }

    uint256 currentBalance = address(this).balance;
    uint256 lastBalance = address(this).balance - msg.value;
    if (currentBalance > 0.0000001 ether) {
      currentBalance /= 0.0000001 ether;
      lastBalance /= 0.0000001 ether;
    }
    // To avoid error propagation related to rounding, tha ratio is stored as a fraction.
    rewardData = RewardData({
      id: rewardId,
      sharedA: rewardData.sharedA * currentBalance,
      sharedB: rewardData.sharedB * lastBalance
    });
    rewardId += 1;
  }

  /// @notice Deposit Ether to the pool. A value must be proovided.
  function deposit() public payable {
    uint256 value = msg.value;
    if (accountPool[msg.sender].balance > 0) {
      value += calculateBalance(msg.sender);
    }
    AccountData memory data = AccountData({
      balance: value,
      oldSharedRewardA: rewardData.sharedA,
      oldSharedRewardB: rewardData.sharedB,
      rewardId: rewardId
    });
    accountPool[msg.sender] = data;
  }

  /// @notice Read the amount of Ether is deposited to the pool summing up all the rewards.
  /// @return Total amount of Ether deposited to the pool by the caller.
  function getAccountBalance() public view returns (uint256) {
    if (accountPool[msg.sender].balance == 0) {
      return 0;
    }
    return calculateBalance(msg.sender);
  }

  /// @notice Withdraw Ether from the pool.
  /// @param amount Amount of Ether to withdraw.
  function withdraw(uint256 amount) public {
    require(accountPool[msg.sender].balance > 0, "Not enough balance");
    uint256 currentAccountBalance = calculateBalance(msg.sender);
    require(amount <= currentAccountBalance, "Not enough balance");
    uint256 newBalance = currentAccountBalance - amount;
    if (newBalance > 0) {
      accountPool[msg.sender].balance = newBalance;
      accountPool[msg.sender].oldSharedRewardA = rewardData.sharedA;
      accountPool[msg.sender].oldSharedRewardB = rewardData.sharedB;
    } else {
      delete accountPool[msg.sender];
    }
    payable(msg.sender).transfer(amount);
  }

  function calculateBalance(address _account) private view returns (uint256) {
    AccountData memory data = accountPool[_account];
    // Validate if some reward was added after the last deposit
    if (rewardData.id < data.rewardId) {
      return data.balance;
    } else {
      return (data.balance * rewardData.sharedA * data.oldSharedRewardB) / (rewardData.sharedB * data.oldSharedRewardA);
    }
  }
}