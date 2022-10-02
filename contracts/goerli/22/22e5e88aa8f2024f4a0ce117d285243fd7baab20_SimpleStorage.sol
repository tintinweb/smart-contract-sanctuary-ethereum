/**
 *Submitted for verification at Etherscan.io on 2022-10-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract SimpleStorage {
    // State variable to store a number
    uint public num;

    address owner;
    constructor () {
        owner = msg.sender;
    }

    function changeOwner (address newOwner) onlyOwner public {
        owner = newOwner;
    }

    function set(uint _num) public payable  {
    require(msg.value < 1000000000000000 , "not enough found");

        num = _num;
    }

    // You can read from a state variable without sending a transaction.
    function get() public view returns (uint) {
        return num;
    }


    modifier onlyOwner {
        require (msg.sender == owner , "Not owner");
        _;
    }
}