//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    uint number;

    struct User {
        address _address;
        uint balance;
    }

    mapping(address => User) public users;

    function increment(uint _numToAdd) public returns (uint) {
        number = number + _numToAdd;
        return number;
    }

    function decrement(uint _numToTake) public returns (uint) {
        number = number - _numToTake;
        if (number < 0) {
            revert();
        }
        return number;
    }

    function retrieve() public view returns (uint) {
        return number;
    }

    function addUser(uint _balance) public {
        User memory newUser = User({balance: _balance, _address: msg.sender});
        users[newUser._address] = newUser;
    }
}