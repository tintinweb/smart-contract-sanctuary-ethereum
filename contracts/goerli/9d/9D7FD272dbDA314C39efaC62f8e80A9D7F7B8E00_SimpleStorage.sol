// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract SimpleStorage {
    uint256 favNum;

    function store(uint256 _Num) public  {
        favNum = _Num;
    }

    function retrive() public view returns(uint256) {
        return favNum;
    }

    struct People {
        uint256 favNum;
        string name;
    }

    People[] public people;
    mapping (string => uint256 ) nameToNum;

    function addPerson(string memory _name, uint256 _num) public {
        people.push(People(_num,_name));
        nameToNum[_name] = _num;
    }
 
}