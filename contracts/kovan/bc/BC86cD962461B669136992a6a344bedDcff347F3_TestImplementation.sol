/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;
pragma abicoder v2;

contract TestImplementation {
    address staker;
    address spender;
    address recipient;
    uint256 underlyingAmount;
    uint256 stakeAmount;

    event Staked(
        address indexed staker,
        address spender,
        uint256 underlyingAmount,
        uint256 stakeAmount
    );

    event WithdrewStake(
        address indexed staker,
        address recipient,
        uint256 underlyingAmount,
        uint256 stakeAmount
    );

    function emitStaked() external {
        emit Staked(staker, spender, underlyingAmount, stakeAmount);
    }

    function emitWithdrewStake() external {
        emit WithdrewStake(staker, recipient, underlyingAmount, stakeAmount);
    }
}