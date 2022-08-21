//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

error Storage__nameNotFound(string name);
contract C_01_Storage {
    mapping(string => uint256) private nameToLuckyNumber;
    
    struct People {
        string name;
        uint256 luckyNumber;
    }
    People[] public people;

    function storeLuckyNumber(string memory _name, uint256 _luckyNumber) public {
        nameToLuckyNumber[_name] = _luckyNumber;
        people.push(People(_name, _luckyNumber));
    }

    function getLuckyNumberByNames(string memory _name) public view returns (uint256) {
        return nameToLuckyNumber[_name];
    }
}