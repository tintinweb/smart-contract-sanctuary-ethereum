/**
 *Submitted for verification at Etherscan.io on 2022-03-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Bridge {
    event DepositEvent(address indexed _from, address indexed _to);
    event ExecuteEvent(address indexed _from, address indexed _to);
    event KeyGenEvent();

    function Deposit(address to) public {
        emit DepositEvent(msg.sender, to);
    }

    function Execute(address to) public {
        emit ExecuteEvent(msg.sender, to);
    }

    function KeyGenTrigger() public {
        emit KeyGenEvent();
    }
}