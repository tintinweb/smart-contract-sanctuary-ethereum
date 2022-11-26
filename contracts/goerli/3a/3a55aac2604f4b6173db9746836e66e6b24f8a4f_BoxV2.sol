// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract BoxV2 {
    uint256 public val;

    // function initialize(uint _val) external {
    //     val = _val;
    // }
    function inc() external {
        val += 1;
    }
}