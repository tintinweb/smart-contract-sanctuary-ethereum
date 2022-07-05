/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//import "hardhat/console.sol";

contract Greeter {
    string private greeting;

    event SetGreeting(string _greeting);

    constructor(string memory _greeting) payable {
        //console.log("Deploying a Greeter with greeting:", _greeting);
        greeting = _greeting;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        //console.log("Changing greeting from '%s' to '%s'", greeting, _greeting);
        greeting = _greeting;
        emit SetGreeting(greeting);
    }
}