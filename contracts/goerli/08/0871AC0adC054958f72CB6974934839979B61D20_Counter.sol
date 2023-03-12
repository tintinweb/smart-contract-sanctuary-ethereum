/**
 *Submitted for verification at Etherscan.io on 2023-03-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract Counter{
    uint256 count = 0;
    address owner;

    constructor(){
        owner = msg.sender;
    }

    function addCount(uint256 x) public {
        require(owner == msg.sender,"Only owner can use this function!");
        count += x;
    }

    function getCount() public view returns(uint256){
        return count;
    }

    function getOwner() public view returns(address){
        return owner;
    }
}