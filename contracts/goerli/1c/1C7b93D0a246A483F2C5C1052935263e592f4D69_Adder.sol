// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

//Contract address (Goerli) 0x57000dC09bF0774A9D61eF12E4AaEBd57c9f93C5

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Adder {
    uint number = 7;

    function add() public{
        number++;
    }

    function see() public view returns (uint){
        return number;
    }
}