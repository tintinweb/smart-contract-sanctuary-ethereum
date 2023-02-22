/**
 *Submitted for verification at Etherscan.io on 2023-02-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract MockIrBankStake {

    struct UserStaked {
        address stakingTokenAddress;
        uint256 balance;
    }

    UserStaked [] public userStakes;
    mapping(address => UserStaked []) public userInfo;

    function setUserStaked (address account, address pToken, uint256 amount) external  {
        userStakes.push(UserStaked({stakingTokenAddress: pToken,balance: amount}));
        userInfo[account] = userStakes;
    }

    function getUserStaked(address account) external view returns (UserStaked [] memory) { 
        return userInfo[account];
    }
}