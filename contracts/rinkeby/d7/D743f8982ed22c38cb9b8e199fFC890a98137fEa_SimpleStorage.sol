// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract SimpleStorage {
    uint256 favNumber;

    struct People {
        uint256 favNumber;
        string name;
    }

    People[] public people;

    mapping(string => uint256) public nameTofavNumber;

    function store(uint256 _favNumber) public{
        favNumber = _favNumber;
    }

    function retrieve() public view returns(uint256) {
        return favNumber;
    }

    function addPerson(string memory _name, uint256 _number) public{
        people.push(People(_number, _name));
        nameTofavNumber[_name] = _number;
    }




}