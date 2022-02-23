/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract CurrentShape {
    string public currentShape;
    address public owner;

    constructor() {
        owner = msg.sender;
        currentShape = "Undefined";
    }

    function GetShape() public view returns (string memory) {
        return currentShape;
    }

    function ChangeShape(string memory newShape) public returns (bool) {
        require(CompareStrings("Circle", newShape) || CompareStrings("Square", newShape));
        currentShape = newShape;
        return true;
    }

    function CompareStrings(string memory a, string memory b) public pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}