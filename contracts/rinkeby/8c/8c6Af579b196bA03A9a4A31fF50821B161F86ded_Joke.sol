/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

contract Joke {
    string public name;
    string public greet = "Hello World!";

    constructor() {}

    function setName(string memory newName) public {
        name = newName;
    }

    function getHelloworld() public view returns (string memory) {
        return string(abi.encodePacked(greet, name));
    }
}