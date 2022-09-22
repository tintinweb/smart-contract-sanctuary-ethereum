/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

struct Student{
    uint256 id;
    uint256 number;
}

contract Mapping{
    mapping(uint => address) public idToAddress; //id到地址
    mapping(address => address) public swapPair; //幣對

    function writeMap(uint _k, address _v) public {
        idToAddress[_k] = _v;
    }
}