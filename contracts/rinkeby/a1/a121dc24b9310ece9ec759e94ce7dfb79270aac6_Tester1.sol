/**
 *Submitted for verification at Etherscan.io on 2022-09-26
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Tester1 {
    struct StakeAgreement {
        uint256 stakeStart;
        uint256 stakeEnd;
        uint256 amount;
    }

    mapping (address => StakeAgreement[]) public agreements;
}