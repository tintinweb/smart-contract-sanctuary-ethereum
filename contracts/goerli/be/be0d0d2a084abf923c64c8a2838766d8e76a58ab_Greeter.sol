/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Greeter {
    string private greeting;

    event ValueChanged(string greeting);
    event ValueReaded(string greeting);

    constructor(string memory _greeting) {
        greeting = _greeting;

        emit ValueReaded(_greeting);
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;

        emit ValueChanged(_greeting);
    }
}