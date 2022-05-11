/**
 *Submitted for verification at Etherscan.io on 2022-05-11
*/

// File: test.sol



pragma solidity ^0.8.10;

contract Homework{
    uint x;

    function setX(uint _x) public {
        //設定變數X
        x = _x;
    }

    function getX( ) public view returns (uint) {
        // 回傳變數X
        return x;
    }
}