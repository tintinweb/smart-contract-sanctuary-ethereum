//// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint favNum;

    mapping(string => uint256) public nameToFavNum;

    struct People {
        uint favNum;
        string name;
    }

    People[] public people;

    function store(uint _fav) public virtual {
        favNum = _fav;
    }

    function retrieve() public view returns (uint) {
        return favNum;
    }

    // calldata is used when you fdonot want to modify a variable
    // memory is there because we have to tell solidity the data location of array, struct or mapping and string is an array of bytes

    function addPerson(string memory _name, uint _fav) public {
        People memory newPerson = People({favNum: _fav, name: _name});
        people.push(newPerson);
        nameToFavNum[_name] = _fav;
    }
}