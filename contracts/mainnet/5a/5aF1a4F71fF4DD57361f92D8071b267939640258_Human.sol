// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

contract Human {
    string public name;
    string public gender;
    string public birthday;

    address parent;

    event ParentSet(address indexed oldAddress, address indexed newAddress);

    modifier isParent() {
        require(msg.sender == parent, "Caller is not a parent!");
        _;
    }

    constructor() {
        parent = msg.sender;
    }

    function setParent(address newAddress) public isParent {
        emit ParentSet(parent, newAddress);
        parent = newAddress;
    }

    function setName(string calldata _name) public isParent {
        name = _name;
    }

    function setGender(string calldata _gender) public isParent {
        gender = _gender;
    }

    function setBirthday(string calldata _birthday) public isParent {
        birthday = _birthday;
    }
}