/**
 *Submitted for verification at Etherscan.io on 2023-05-25
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint public x;
    
    function set(uint newValue) public{
        x= newValue;
    }

    function get() public view returns(uint){
        return x;
    }
}