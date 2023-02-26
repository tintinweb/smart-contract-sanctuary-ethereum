// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint public favouritenumber;

    mapping(string => uint256) public nameToFavouriteNumber;

    struct People {
        uint256 favouritenumber;
        string name;
    }
    People[] public people;

    function retrieve() public view returns (uint256) {
        return favouritenumber;
    }

    function store(uint tp) public {
        favouritenumber = tp;
    }

    function addperson(string memory _name, uint256 _favouritenumber) public {
        people.push(People(_favouritenumber, _name));
        nameToFavouriteNumber[_name] = _favouritenumber;
    }
}