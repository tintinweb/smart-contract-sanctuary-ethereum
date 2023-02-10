/**
 *Submitted for verification at Etherscan.io on 2023-02-10
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 luckyNumber;
    mapping(string => uint256) public nameToLuckyNumber;

    struct People {
        uint256 luckyNumber;
        string name;
        string expression;
        string date;
    }

    People[] public people;

    function store(uint256 _luckyNumber) public virtual {
        luckyNumber = _luckyNumber;
    }

    function retrieve() public view returns (uint256) {
        return luckyNumber;
    }

    function addPeople(
        uint256 _luckyNumber,
        string memory _name,
        string memory _expression,
        string memory _date
    ) public {
        People memory newperson = People({
            luckyNumber: _luckyNumber,
            name: _name,
            expression: _expression,
            date: _date
        });
        people.push(newperson);
        nameToLuckyNumber[_name] = _luckyNumber;
    }
}