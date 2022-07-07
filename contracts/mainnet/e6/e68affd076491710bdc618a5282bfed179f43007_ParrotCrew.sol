// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./Owned.sol";

interface IParrots {
  function balanceOf(address owner) external view returns (uint256);
}

interface IStakedParrots {
  function getStakedParrots(address staker) external view returns (uint256[] memory);
}

contract ParrotCrew is Owned {
  IParrots internal immutable potcContract;
  IStakedParrots internal stakingContract;
  
  constructor(address potcAddress, address stakingAddress) Owned(msg.sender) {
    potcContract = IParrots(potcAddress);
    stakingContract = IStakedParrots(stakingAddress);
  }

  function balanceOf(address owner) public view returns(uint256) {
    return potcContract.balanceOf(owner) + stakingContract.getStakedParrots(owner).length;
  }

  function setStakingContract(address stakingAddress) external onlyOwner {
    stakingContract = IStakedParrots(stakingAddress);
  }
}