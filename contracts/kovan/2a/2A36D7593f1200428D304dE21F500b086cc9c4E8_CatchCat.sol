/**
 *Submitted for verification at Etherscan.io on 2022-05-31
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract CatchCat{
    uint public totalCatNum;
    address owner;

    constructor() {
        totalCatNum = 100;
        owner = msg.sender;
    }

    function addCatNum(uint num) public{
        require(msg.sender == owner);
        totalCatNum += num;
    }

    function catchCat() public{
        totalCatNum -= 1;
    }
}