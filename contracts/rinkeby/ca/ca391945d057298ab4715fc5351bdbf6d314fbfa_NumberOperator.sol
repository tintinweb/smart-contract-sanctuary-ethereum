/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract NumberOperator {
    address public owner;
    uint256 number;

    // Set creator as owner
    constructor() {
        owner = msg.sender;
    }

    // Checks if the sender is the owner
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    // Checks if the sender is the owner in case a new number is written
    modifier isOwnerIfWrite(bool write) {
        if (write) {
            require(msg.sender == owner, "Caller is not owner");
        }
        _;
    }

    function set(uint256 newNumber) public isOwner returns (uint256) {
        number = newNumber;
        return number;
    }

    function get() public view returns (uint256) {
        return number;
    }

    function multiply(uint256 otherNumber, bool write) public returns (uint256) {
        return maybeWrite(number * otherNumber, write);
    }

    function divide(uint256 otherNumber, bool write) public returns (uint256) {
        return maybeWrite(number / otherNumber, write);
    }

    function add(uint256 otherNumber, bool write) public returns (uint256) {
        return maybeWrite(number + otherNumber, write);
    }

    function sub(uint256 otherNumber, bool write) public returns (uint256) {
        return maybeWrite(number + otherNumber, write);
    }

    function maybeWrite(uint256 result, bool write) private isOwnerIfWrite(write) returns (uint256) {
        if (write) {
            number = result;
        }
        return result;
    }
}