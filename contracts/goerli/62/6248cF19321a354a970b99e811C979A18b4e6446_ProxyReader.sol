//SPDX-License-Identifier: MIT license
pragma solidity ^0.8.0;

abstract contract StateToken {
  function balanceOf(address _owner) external view virtual returns (uint256);
}

abstract contract CompoundStakingReward {
    function calculateSharesValueInState(address user) external view virtual returns (uint256);
}

contract ProxyReader {
    address constant stateTokenAddr = 0xDA2F1D68d76DA861629C86b8823fE35807Cf8689;
    address constant stakingAddr = 0x2Fcd20F97F27c3Ef78AC98189C3C1f22678A955E;

    function balanceOf(address _owner) public view returns (uint256) {
        return StateToken(stateTokenAddr).balanceOf(_owner) + 2 * CompoundStakingReward(stakingAddr).calculateSharesValueInState(_owner);
    }
}