/**
 *Submitted for verification at Etherscan.io on 2022-08-09
*/

// SPDX-License-Identifier: MIT

/*
    This contract stores values in the blockchain for different people.
*/

pragma solidity ^0.8.0;

contract StoreValueForPeople {
    struct People {
        string name;
        uint256 value;
    }

    People[] public people;
    mapping(string => uint256) public nameToValue;

    function addPerson(string memory _name, uint256 _value) public {
        people.push(People(_name, _value));
        nameToValue[_name] = _value;
    }
}