/**
 *Submitted for verification at Etherscan.io on 2022-12-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract trainning2 {

    string Starting = "I want";

    function start() public view returns(string memory) {
        return Starting;
    }

    function love() public {
        Starting = string.concat(Starting, " love");
    }

    function peace() public {
        Starting = string.concat(Starting, " peace");
    }

    function power() public {
        Starting = string.concat(Starting, " power");
    }


}