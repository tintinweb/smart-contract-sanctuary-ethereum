// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Box {
    uint public val;

    function initialize(uint _val) external {
        val = _val;
    }
}