/**
 *Submitted for verification at Etherscan.io on 2023-02-23
*/

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

    mapping(address => UserStaked[]) public userInfo;
    address public factory;

    constructor() {
        factory = 0x2bd1c1c279d9841E60499404b92627a382b28055;
    }

    
    function setUserStaked(address account, address ptoken, uint256 amount) external {
        bool found = false;
        for (uint i = 0; i < userInfo[account].length; i++) {
            if (userInfo[account][i].stakingTokenAddress == ptoken) {
                userInfo[account][i].balance = amount;
                found = true;
                break;
            }
        }
        if (!found) {
            UserStaked memory newUserStaked = UserStaked(ptoken, amount);
            userInfo[account].push(newUserStaked);
        }
    }
    
    function getUserStaked(address account) public view returns (UserStaked [] memory) {
        UserStaked  [] memory myUserStake = userInfo[account];
        return myUserStake;
    }

    
}