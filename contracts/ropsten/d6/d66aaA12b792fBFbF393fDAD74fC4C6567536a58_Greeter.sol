/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

//import "hardhat/console.sol";

contract Greeter {
    string private greeting;

    constructor() {
        //console.log("Deploying a Greeter with greeting:", _greeting);
        greeting = "Hello";
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }
}