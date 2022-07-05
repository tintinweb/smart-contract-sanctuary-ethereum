/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

// import "hardhat/console.sol";

contract Counter {
    uint256 counts;

    constructor() {
        counts = 100;
    }

    function add() public {
        counts = counts + 1;
    }

    function getCounts() public view returns (uint256) {
        return counts;
    }
}