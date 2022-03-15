// SPDX-license-Identifier: MIT
pragma solidity ^0.8.0;

// this contract will input a nunmber and you'lll be able to see if the number is greater or less than 100
contract IfElse {
    bool boolean;

    function greaterThan100(uint256 input) public returns (bool) {
        if (input > 100) {
            boolean = true;
            return boolean;
        } else {
            boolean = false;
            return boolean;
        }
    }
}