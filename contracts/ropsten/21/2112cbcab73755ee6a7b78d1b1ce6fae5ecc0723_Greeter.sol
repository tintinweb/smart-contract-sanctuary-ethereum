/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//import "hardhat/console.sol";

contract Greeter {
    string private greeting2;

    constructor(string memory _greeting) {
        //console.log("Deploying a Greeter with greeting:", _greeting);
        greeting2 = _greeting;
    }

    function greet() public view returns (string memory) {
        return greeting2;
    }

    function setGreeting(string memory _greeting) public {
        //console.log("Changing greeting from '%s' to '%s'", greeting, _greeting);
        greeting2 = _greeting;
    }
}