// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Add{

    uint public sum;
    address[] public senders;

    event Addition(address owner, uint sum);
    event Senders(address[] array);

    function getSum(uint n1,uint n2 )public{
        sum = n1 + n2;
        emit Addition(msg.sender, sum);
    }

    function addSenders()public{
        senders.push(msg.sender);
        emit Senders(senders);
    }

    function getSenders()public view returns(address[] memory){
        return senders;
    }

}