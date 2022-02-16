// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";

contract TimeLock is Ownable {
  mapping(uint256 => uint256) public amounAtUnlockTime;
  uint256[] public unlockTimes;
  uint256 private unlockedBalance;

  function deposit(uint256 lockTimeInSeconds) public payable {
    require(msg.value > 0, "Send more eth");
    
    uint256 unlockTime = block.timestamp + lockTimeInSeconds;
    if (amounAtUnlockTime[unlockTime] > 0) {
      amounAtUnlockTime[unlockTime] += msg.value;
    } else {
      amounAtUnlockTime[unlockTime] = msg.value;
      unlockTimes.push(unlockTime);
      quickSort(unlockTimes, 0, int(unlockTimes.length - 1));
    }
  }

  function withdrawAll() public onlyOwner {
    unlockFunds();
    require(unlockedBalance > 0, "No unlocked balance");
    payable(owner).transfer(unlockedBalance);
  }

  function withdraw(uint256 amount) public onlyOwner {
    require(amount > 0, "Insert a valid amount");
    require(amount <= address(this).balance, "Insufficient balance");
    unlockFunds();
    require(amount <= unlockedBalance, "Amount still locked");

    payable(owner).transfer(amount);
  }

  function currentAvailableBalance() public view returns (uint256) {
    return availableBalance(block.timestamp);
  }

  function availableBalance(uint256 time) public view returns (uint256) {
    uint256 unlockedAmount = 0;
    for (uint i = 0; i < unlockTimes.length; ++i) {
      if (unlockTimes[i] > time)
        break;
      unlockedAmount += amounAtUnlockTime[unlockTimes[i]];
    }
    return unlockedAmount;
  }

  function unlockFunds() private {
    uint unlocked = 0;
    for (uint i = 0; i < unlockTimes.length; ++i) {
      if (unlockTimes[i] > block.timestamp)
        break;
      unlocked++;
      unlockedBalance += amounAtUnlockTime[unlockTimes[i]];
      amounAtUnlockTime[unlockTimes[i]] = 0;
    }
    uint256[] memory newUnlockTimes = new uint256[](unlockTimes.length - unlocked);
    for (uint i = 0; i < newUnlockTimes.length; ++i)
      newUnlockTimes[i] = unlockTimes[i + unlocked];
  }

  function quickSort(uint256[] memory arr, int left, int right) private pure {
    int i = left;
    int j = right;
    if (i == j) return;
    uint pivot = arr[uint(left + (right - left) / 2)];
    while (i <= j) {
      while (arr[uint(i)] < pivot) i++;
      while (pivot < arr[uint(j)]) j--;
      if (i <= j) {
        (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
        i++;
        j--;
      }
    }
    if (left < j)
      quickSort(arr, left, j);
    if (i < right)
      quickSort(arr, i, right);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ownable {
  address public owner;
  
  event OwnerSet(address indexed oldOwner, address indexed newOwner);
  
  modifier onlyOwner() {
    require(msg.sender == owner, "Caller is not owner");

    _;
  }
  
  constructor() {
    owner = msg.sender;
    emit OwnerSet(address(0), owner);
  }

  function changeOwner(address newOwner) public onlyOwner {
    require(newOwner != address(0), "Invalid new owner");

    emit OwnerSet(owner, newOwner);
    owner = newOwner;
  }
}