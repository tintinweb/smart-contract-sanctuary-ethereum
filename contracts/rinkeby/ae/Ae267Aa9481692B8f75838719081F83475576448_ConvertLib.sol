/**
 *Submitted for verification at Etherscan.io on 2022-02-03
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library ConvertLib {
    function convertToRB(uint256 ethAmount) public pure returns (uint256) {
        // 0.01 eth gives me 1 RB
        // 1/0.01 = x/ethAmount
        return (100) * ethAmount;
    }

    function convertToEth(uint256 rbAmount) public pure returns (uint256) {
        return rbAmount / 100;
    }
}