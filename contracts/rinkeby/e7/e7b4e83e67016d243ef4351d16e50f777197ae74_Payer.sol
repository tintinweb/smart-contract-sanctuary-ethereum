/**
 *Submitted for verification at Etherscan.io on 2022-09-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Payer {
    uint public balance = 0;

    function destruct(address payable _to) external payable {
        selfdestruct(_to);
    }

    function deposit() external payable {
        balance += msg.value;
    }
}