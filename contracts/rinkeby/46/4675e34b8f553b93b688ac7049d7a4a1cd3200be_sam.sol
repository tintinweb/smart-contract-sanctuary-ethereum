/**
 *Submitted for verification at Etherscan.io on 2022-06-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract sam {
    struct myStruct {
        uint id;
        address account;
        string name;
        uint balance;
        bool verified;
    }
    myStruct[] myArray;
    mapping(string => myStruct) myMap;

    function set(
        address _addy,
        uint _id,
        string memory _name,
        uint _balance,
        bool _verified
    ) public {
        myStruct memory newStruct = myStruct({
            account: _addy,
            id: _id,
            name: _name,
            balance: _balance,
            verified: _verified
        });
        myMap[_name] = newStruct;
        myArray.push(newStruct);
    }

    function get(string memory _name) public view returns (myStruct memory) {
        return myMap[_name];
    }
}