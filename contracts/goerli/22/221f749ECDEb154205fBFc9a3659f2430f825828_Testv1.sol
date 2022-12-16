/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Testv1 {
    uint256 public greeting;

    function Greeter1() public {
        greeting = 1 ;
    }

    function setGreeting(uint256 _greeting) public {
        greeting = _greeting;
    }

    function greet() view public returns (uint256) {
        return greeting;
    }

}