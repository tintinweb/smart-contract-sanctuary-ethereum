/**
 *Submitted for verification at Etherscan.io on 2022-07-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract Homework {
    function payBack(uint input) external payable {
        uint256 halfRefund = msg.value / 2;
        if(input % 2 == 0) {
            payable(msg.sender).transfer(halfRefund);
        } else {
            payable(msg.sender).transfer(msg.value);
        }
        require(input != 9, "we dont like 9");
    }
}