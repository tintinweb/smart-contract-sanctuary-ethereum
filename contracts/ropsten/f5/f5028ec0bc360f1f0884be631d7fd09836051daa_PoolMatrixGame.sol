/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

contract PoolMatrixGame {

    address public owner;

    event MyEvent(string msg);

    constructor() public {
        owner = msg.sender;
    }

    receive() payable external {
        emit MyEvent("Hello world!");
    }

    function withdraw(uint amount, address payable destAddr) public {
        destAddr.transfer(amount);
    }
}