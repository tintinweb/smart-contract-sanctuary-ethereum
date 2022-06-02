/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.8;

contract Greeter {
    string private greeting;
    event Greet(address indexed sender, string greeting);

    constructor() {}

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
        emit Greet(msg.sender, _greeting);
    }
}