/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.11;

contract MplRewardsSanityChecker {

    function checkPeriodFinish(uint256 timestamp_) external {
        require(timestamp_ > block.timestamp);
    }

}