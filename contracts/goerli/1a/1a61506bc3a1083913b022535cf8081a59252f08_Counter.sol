/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

// import "forge-std/Test.sol";

interface ICounter {
    function myFunction() external;
}

contract Counter is ICounter {
    uint256 public number;
    bool public hogwild = false;

    function myFunction() external override {
    }
}