/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Greeter {
    /* Define variable greeting of the type string */
    string greeting;

    /* This runs when the contract is executed */
    constructor(string memory defaultGreeting)  {
        greeting = defaultGreeting;
    }

    /* Main function */
    function greet() public view returns (string memory) {
        return greeting;
    }
}