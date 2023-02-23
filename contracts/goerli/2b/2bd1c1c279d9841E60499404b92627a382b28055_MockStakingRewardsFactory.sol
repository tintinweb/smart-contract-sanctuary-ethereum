/**
 *Submitted for verification at Etherscan.io on 2023-02-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


contract MockStakingRewardsFactory {

    mapping(address => address) public stakingRewards;
    mapping(address => address) public stakingTokens;

    constructor(address _underlying, address _pToken, address _stakeReward) {

        stakingTokens[_underlying] = _pToken;
        stakingRewards[_pToken] = _stakeReward;

    }

    function getStakingRewards(address stakingToken)
        external
        view
        returns (address) {

            return stakingRewards[stakingToken];

        }

    function getStakingToken(address underlying)
        external
        view
        returns (address) {

            return stakingTokens[underlying];

        }
    }