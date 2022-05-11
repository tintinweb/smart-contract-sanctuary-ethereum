/**
 *Submitted for verification at Etherscan.io on 2022-05-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Event {
    
    uint Counter;
    event Log(address indexed sender, string message, uint Counter);

    function test() public {
        Counter++;
        emit Log(msg.sender, "Hello World!", Counter);
    }

}