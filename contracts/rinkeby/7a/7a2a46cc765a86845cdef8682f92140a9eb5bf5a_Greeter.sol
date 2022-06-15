/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//import  "hardhat/console.sol";

contract Greeter {
    string private greeting;

    constructor(string memory _greeting) {
        //console.log("Deploying a Greeter with greeting:", _greeting);      
        greeting = _greeting;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function  add(uint128 a,uint128 b) public pure  returns (uint128 ) {
        return a+b;
    }

    function setGreeting(string memory _greeting) public {
        //console.log("Changing greeting from '%s' to '%s'", greeting, _greeting);
        greeting = _greeting;
    }
}