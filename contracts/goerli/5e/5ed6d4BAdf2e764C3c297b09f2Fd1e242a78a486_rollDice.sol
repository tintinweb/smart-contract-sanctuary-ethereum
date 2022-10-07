// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

contract rollDice {
    string private name = "This is rollDice Contract";
    function getName() public view returns(string memory) {
        return name;
    } 
}