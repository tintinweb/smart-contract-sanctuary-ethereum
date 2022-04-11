/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

contract Functions{
    
    uint luckyNumber = 3;

    function showNumber() public view returns(uint){
        return luckyNumber;
    }

    function setNumber(uint _newNumber) public {
        luckyNumber = _newNumber;
    }

    function addToX(uint y) public view returns(uint){
        return luckyNumber + y;
    }

    function addAndView(uint a, uint b) public view returns (uint){
        return a * (b + 42) + block.timestamp;
    }

    function addAndPure(uint a, uint b) public pure returns (uint){
        return a * (b + 42);
    }

    function add(uint a, uint b) public pure returns(uint){
        return a + b;
    }

    function add2(uint c, uint d) public pure returns(uint){
        return add(c,d);
    }
}