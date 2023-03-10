// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Count {
    uint256 public counter;
    address owner;

    constructor(uint256 x){
        counter=x;
        owner=msg.sender;
    }

    function count()public returns(uint256){
        require(msg.sender==owner,"Not auth");
        counter=counter+1;
        return counter;
    }
}