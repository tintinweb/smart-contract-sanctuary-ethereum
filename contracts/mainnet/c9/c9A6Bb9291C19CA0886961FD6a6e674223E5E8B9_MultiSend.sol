// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract MultiSend{

    function send(address[] calldata to, uint[] calldata amount) public payable{
        uint total = 0;
        for(uint i = 0; i < to.length; i++){
            total += amount[i];
        }
        require(total == msg.value,"msg.value");

        for(uint i = 0; i < to.length; i++){
            payable(to[i]).transfer(amount[i]);
        }
    }
}