// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract BoxV2 {
    uint public val;

    function inc() external {
        val+=1;
    }
}