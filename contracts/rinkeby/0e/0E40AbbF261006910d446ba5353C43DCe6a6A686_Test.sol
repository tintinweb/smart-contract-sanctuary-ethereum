//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Test {

    string something = "hello";

    function changeSomething(string memory newSomething) public {
        something = newSomething;
    }
}