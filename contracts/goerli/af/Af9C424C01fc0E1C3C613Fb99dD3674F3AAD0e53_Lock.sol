// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
//sid w code test

contract Lock {
    uint public count;
    function increment() public {
        count += 1;
    }

    function getCount() public view returns(uint) {
        return count;
    }
}