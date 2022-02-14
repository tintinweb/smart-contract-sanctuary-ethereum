/**
 *Submitted for verification at Etherscan.io on 2022-02-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;



// File: testContract.sol

contract testContract{
    
    mapping(uint => address) public numToAddress;

    function insertAddress(uint _num) public{
        numToAddress[_num] = msg.sender;
    }
}