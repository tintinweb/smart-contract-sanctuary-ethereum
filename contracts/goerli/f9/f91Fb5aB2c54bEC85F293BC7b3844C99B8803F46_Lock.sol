// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Lock {
    uint256 public numb = 6;

    function changeNumberTo(uint256 _change) public returns (uint256) {
        numb = _change;
        return numb;
    }
}