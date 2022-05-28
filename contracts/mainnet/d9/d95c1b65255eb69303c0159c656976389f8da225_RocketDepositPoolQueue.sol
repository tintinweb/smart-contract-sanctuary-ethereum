/**
 *Submitted for verification at Etherscan.io on 2022-05-28
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.14;

interface RocketStorageInterface {
  function getAddress(bytes32 _key) external view returns (address);
}

interface RocketDepositPoolInterface {
  function assignDeposits() external;
}

interface RocketMinipoolQueueInterface {
  function getTotalLength() external view returns (uint256);
  function getLength(MinipoolDeposit _depositType) external view returns (uint256);
}

interface RocketDAOProtocolSettingsDepositInterface {
  function getMaximumDepositAssignments() external view returns (uint256);
}

enum MinipoolDeposit {
  None,
  Full,
  Half,
  Empty
}

contract RocketDepositPoolQueue {
  RocketStorageInterface rocketStorage;

  constructor(RocketStorageInterface rocketStorageAddress) {
    rocketStorage = RocketStorageInterface(rocketStorageAddress);
  }

  function getQueueLength() public view returns (uint256) {
    RocketMinipoolQueueInterface queue = RocketMinipoolQueueInterface(getContractAddress("rocketMinipoolQueue"));
    return queue.getTotalLength();
  }

  function getHalfQueueLength() public view returns (uint256) {
    RocketMinipoolQueueInterface queue = RocketMinipoolQueueInterface(getContractAddress("rocketMinipoolQueue"));
    return queue.getLength(MinipoolDeposit.Half);
  }

  function getAssignmentCount() public view returns (uint256) {
    RocketDAOProtocolSettingsDepositInterface settings = RocketDAOProtocolSettingsDepositInterface(getContractAddress("rocketDAOProtocolSettingsDeposit"));
    return settings.getMaximumDepositAssignments();
  }

  function clearQueue() public {
    clearQueueUpTo(getQueueLength());
  }

  function clearHalfQueue() public {
    clearQueueUpTo(getHalfQueueLength());
  }

  function clearQueueUpTo(uint256 minipoolCount) public {
    RocketDepositPoolInterface depositPool = RocketDepositPoolInterface(getContractAddress("rocketDepositPool"));
    uint256 step = getAssignmentCount();
    for (uint256 i = 0; i < minipoolCount; i += step) {
      depositPool.assignDeposits();
    }
  }

  function getContractAddress(string memory contractName) private view returns (address) {
    return rocketStorage.getAddress(keccak256(abi.encodePacked("contract.address", contractName)));
  }
}