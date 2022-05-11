/**
 *Submitted for verification at Etherscan.io on 2022-05-11
*/

// File: contracts/4_Test.sol



pragma solidity ^0.8.10;

contract Homework {
    // 宣告一個變數’x’型態為uint
    uint x;

    function setX(uint _x) public {
        x = _x;
    }

    function getX() public view returns (uint) {
        return x;
    }
}