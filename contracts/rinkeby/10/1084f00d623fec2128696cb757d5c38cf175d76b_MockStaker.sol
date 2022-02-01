// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Staking.sol";

// This is mock contract to access to StakingContract
contract MockStaker {
    Staking _staking;

    constructor(address payable stakingContractAddr) {
        _staking = Staking(stakingContractAddr);
    }

    receive() external payable {}

    function transfer(uint256 amount) public {
        payable(_staking).transfer(amount);
    }

    function stake(uint256 amount) public {
        _staking.stake{value: amount}();
    }

    function unstake() public {
        _staking.unstake();
    }
}