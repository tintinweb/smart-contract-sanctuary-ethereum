//SPDX-License-Identifier: MIT license
pragma solidity ^0.8.0;

abstract contract StateToken {
  function balanceOf(address _owner) external view virtual returns (uint256);
}

abstract contract CompoundStakingReward {
    function calculateSharesValueInState(address user) external view virtual returns (uint256);
}

contract ProxyReader {
    address constant stateTokenAddr = 0xdC6104b7993e997Ca5f08aCAB7D3AE86E13D20a6;
    address constant stakingAddr = 0xBb56Aec363b501Fa4ED406f544A05595Eb67072e;

    function balanceOf(address _owner) public view returns (uint256) {
        return StateToken(stateTokenAddr).balanceOf(_owner) + 2 * CompoundStakingReward(stakingAddr).calculateSharesValueInState(_owner);
    }
}