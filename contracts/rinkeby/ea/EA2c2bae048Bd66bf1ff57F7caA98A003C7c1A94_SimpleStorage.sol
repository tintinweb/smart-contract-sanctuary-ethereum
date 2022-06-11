// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; // any 8 version

contract SimpleStorage { // a class

    // https://docs.soliditylang.org/en/v0.8.11/types.html
    uint256 favNum; // inits to 0

    // bool fav = true;
    // string favStr = "Favourite";
    // int256 favInt = -5;
    // address myAddress = 0x01589DBA6D8d030D0A32C4601eE7f3cAc18083aB;
    // bytes32 myBytes = "cat";

    function store(uint _favNum) public { // private internal (default) external
        favNum = _favNum;
    }

    // view, pure are read only and dont need a transaction
    function retrieve() public view returns (uint256) {
        return favNum;
    }

    struct Person {
        uint256 favNum;
        string name;
    }

    Person[] people; // People[1] - fixed size array
    mapping(string => uint256) nameIndex; // dictionary mapping names to indexes

    // options: memory, storage. memory only persists for execution
    // after execution variable is deleted
    function addPerson(string memory _name, uint256 _favNum) public {
        people.push(Person({favNum: _favNum, name: _name}));
        nameIndex[_name] = people.length - 1;
    }

    function getFavouriteNumber(string memory _name) public view returns (uint256) {
        uint256 _index = nameIndex[_name];
        return people[_index].favNum;
    }
}