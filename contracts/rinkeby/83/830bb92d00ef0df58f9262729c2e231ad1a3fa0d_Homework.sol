/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// File: contracts/4_test.sol



pragma solidity ^0.8.10;

contract Homework {
    uint x = 21312;

    function setX(uint _x) public {
        x = _x;
    }

    function getX() public view returns (uint) {
        return x;
    }
}