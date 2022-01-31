/**
 *Submitted for verification at Etherscan.io on 2022-01-31
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;// this is imporatnt

contract Count {
uint256 count;

function setCount(uint256 c) public{
    count = c;
}

function getCount() view public returns(uint256) {
    return count;
}

}