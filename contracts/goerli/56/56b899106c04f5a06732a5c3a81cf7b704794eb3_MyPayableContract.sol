/**
 *Submitted for verification at Etherscan.io on 2022-11-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract MyPayableContract {

    function payMeBack(uint input) external payable returns (string memory) {
        if (input == 9) {
            return "We dont like 9";
        }

        if ((input % 2) == 0) {
            // Even - pay back half the eth
            payable(msg.sender).transfer(msg.value / 2);
            return "Half ether returned!";
        } else {
            // Odd - return back all ether
            payable(msg.sender).transfer(msg.value);
            return "All ether returned!";
        }
    }
}