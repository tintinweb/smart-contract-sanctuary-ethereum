/**
 *Submitted for verification at Etherscan.io on 2022-05-27
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Greeter {
    string greeting;

    function getGreet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }
}