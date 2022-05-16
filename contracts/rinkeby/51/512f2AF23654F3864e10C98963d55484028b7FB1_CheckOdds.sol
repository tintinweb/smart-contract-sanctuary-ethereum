/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;


contract CheckOdds {
    function maybePayBackSome() external payable {
        require(msg.value != 9, "We don't like 9");
        if(msg.value %2 == 0) {
            payable(msg.sender).transfer(msg.value / 2);
        } else {
            payable(msg.sender).transfer(msg.value);
        }
    }
}