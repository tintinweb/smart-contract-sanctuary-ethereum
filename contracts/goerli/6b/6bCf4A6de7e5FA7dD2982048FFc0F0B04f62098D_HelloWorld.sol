//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract HelloWorld {
    string public hello = "Hello World From Solidity";

    function Hello() public view returns (string memory) {
        return hello;
    }
}