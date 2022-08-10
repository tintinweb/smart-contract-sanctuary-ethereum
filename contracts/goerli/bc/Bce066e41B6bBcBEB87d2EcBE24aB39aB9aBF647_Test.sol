/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Import this file to use console.log
//import "hardhat/console.sol";

contract Test {
    uint amount;

    function AddAmount(uint x) public {
        amount = x;
    }

    function GetAmount() public view returns(uint) {
        return amount;
    }
}