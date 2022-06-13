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
    address constant stakingAddr = 0xcf331422cC488882C7bE03EfF8B1f3B7683F26b8;

    function balanceOf(address _owner) public view returns (uint256) {
        return StateToken(stateTokenAddr).balanceOf(_owner) + 2 * CompoundStakingReward(stakingAddr).calculateSharesValueInState(_owner);
    }
}