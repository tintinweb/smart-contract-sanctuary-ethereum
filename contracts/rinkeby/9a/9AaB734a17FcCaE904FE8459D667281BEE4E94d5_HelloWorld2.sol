/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

contract HelloWorld2 {
    string public bio;
    string public bioIntro = "Hello World. I am ";

    constructor(string memory name) {
        bio = name;
    }

    function setBio(string memory fullName) public {
        bio = fullName;
    }

    function getFeedback() public view returns (string memory) {
        return string (abi.encodePacked(bioIntro, bio));
    }
}