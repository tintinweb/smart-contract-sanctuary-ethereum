/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title NumberStorage
 * @dev Contract that stores a number and have different ways to modify it
 */

contract NumberStorage {
    address private owner;
    int private number;

    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    event NumberChanged(int oldNumber, int newNumber);
    
    // modifier to check if caller is owner
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    error InvalidArgument();

    constructor(int _num) {
        number = _num;
        owner = msg.sender;
    }

    /*
     * @dev Changes the owner
     */
    function setOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /*
     * @dev Changes the number stored
     */
    function setNumber(int _num) internal {
        emit NumberChanged(number, _num);
        number = _num;
    }

    function multiply(int _num) public isOwner {
        if (_num <= 0) revert InvalidArgument();
        setNumber(number * _num);
    }

    function divide(int _num) public isOwner {
        if (_num <= 0) revert InvalidArgument();
        setNumber(number / _num);
    }

    function multiplyDivide(int _num1, int _num2) public isOwner {
        if (_num1 <= 0 || _num2 <= 0) revert InvalidArgument();
        setNumber(number * _num1 / _num2);
    }

    function add(int _num) public isOwner {
        if (_num <= 0) revert InvalidArgument();
        setNumber(number + _num);
    }

    function subtract(int _num) public isOwner {
        if (_num <= 0) revert InvalidArgument();
        setNumber(number - _num);
    }
}