//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    uint256 favouriteNumber;
    // people public person =  people({favnum:2, name:"omar"});

    mapping(string => uint256) public nametofavnumber;

    // we can create our own types like string,bool. They are like list
    struct people {
        uint256 favnum;
        string name;
    }

    uint256[] favvnum;
    people[] public persons;

    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    //view and pure function don't spend gas
    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    //calldata, memory, storage
    function addperson(string memory _name, uint256 _favnum) public {
        people memory newperson = people({favnum: _favnum, name: _name});
        persons.push(newperson);
        nametofavnumber[_name] = _favnum;
    }
}