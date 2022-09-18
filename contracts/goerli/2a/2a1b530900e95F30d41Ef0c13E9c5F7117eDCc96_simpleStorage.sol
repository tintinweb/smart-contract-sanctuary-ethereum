// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract simpleStorage {
    // get initialized to zero.
    uint256 public favNumber;

    struct People {
        string name;
        uint256 fav_number;
    }
    People[] public pe1;
    mapping(string => uint256) public nametofav;

    function store(uint256 _favNumber) public virtual {
        favNumber = _favNumber;
    }

    function retrive() public view returns (uint256) {
        return favNumber;
    }

    function addPerson(string memory _name, uint256 _fav_number) public {
        pe1.push(People(_name, _fav_number));
        nametofav[_name] = _fav_number;
    }
}