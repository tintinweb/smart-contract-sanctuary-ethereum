/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//import "hardhat/console.sol";

contract Counter {
    uint256 counts;
    
    constructor() {
        counts = 0;
    }
    function add() public {
        counts = counts + 1;
    }
    function getCounts() public view returns (uint256) {
        return counts;
    } 
}