/**
 *Submitted for verification at Etherscan.io on 2022-09-26
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

contract TestG {

    address public owner;

    uint256 public data;

    constructor(){
        owner = msg.sender;
    }

    function setOwner(address _owner) public{
        owner = _owner;
    }

    function setData(uint256 _data) public{
        data = _data;
    }
}