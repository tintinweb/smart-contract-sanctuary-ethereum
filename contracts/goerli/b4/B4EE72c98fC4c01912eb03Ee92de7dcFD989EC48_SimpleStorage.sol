// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

contract SimpleStorage {
    //Data Types:

    uint256 num1;
    bytes32 num2;
    string name1;
    bool teeth;
    int public num3 = 2;
    address my;

    //Methods or Functions:

    function rename(uint256 num4) public virtual {
        num1 = num4;
    }

    // View or Pure

    function check() public view returns (uint256) {
        return num1;
    }

    //Struct in Solidity:

    struct student {
        uint num;
        string name;
    }

    student public abd = student({num: 2, name: "Bhai"});
    student public abd2 = student({num: 4, name: "Bhayya"});

    //Arrays:

    student[] public insan;

    //mapping:

    mapping(uint => string) public find;

    //Push function to add values to arrays or structs-:

    function add(string memory _name, uint _num) public {
        insan.push(student({name: _name, num: _num}));
        find[_num] = _name;
    }
}