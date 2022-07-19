/**
 *Submitted for verification at Etherscan.io on 2022-07-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 favNum;
    //People public person = People({favNum: 7, name: "Sheraz"});
    mapping(string => uint256) public nameToFavNumber;
    People[] public person;

    struct People {
        uint256 favNum;
        string name;
    }

    function store(uint256 _favNum) public virtual {
        favNum = _favNum;
    }

    function retrieve() public view returns (uint256) {
        return favNum;
    }

    function addPerson(uint256 _favNum, string memory _name) public {
        //person.push(People({favNum: _favNum, name: _name}));
        // Or
        person.push(People(_favNum, _name));
        // Or
        //People memory newPerson = People({favNum: 7, name: "Sheraz"});
        //person.push(newPerson);
        // Or
        //People memory newPerson2 = People(8, "Sheraz");
        //person.push(newPerson2);
        nameToFavNumber[_name] = _favNum;
    }
}