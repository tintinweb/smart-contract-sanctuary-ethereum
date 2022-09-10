// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract simplestorage {
    uint256 public favnumber;

    struct People {
        uint256 favnumber;
        string name;
    }
    People[] public people;

    mapping(string => uint256) public nametofavnumber;

    //virtual and override
    function store(uint256 _favnumber) public virtual {
        favnumber = _favnumber;
    }

    function retrive() public view returns (uint256) {
        return favnumber;
    }

    //calldata, memory, storage
    //calldata, temporary cannot be modified
    // memory, temporary can be modified
    //storage, permanent can be modified
    function addperson(string memory _name, uint256 _favnumber) public {
        People memory newperson = People({favnumber: _favnumber, name: _name});
        people.push(newperson);
        nametofavnumber[_name] = _favnumber;
    }
}