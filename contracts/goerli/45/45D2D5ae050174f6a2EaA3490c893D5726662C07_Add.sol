// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Add{

    uint public sum;

    event Addition(address owner, uint sum);

    function getSum(uint n1,uint n2 )public{
        sum = n1 + n2;
        emit Addition(msg.sender, sum);
    }

}