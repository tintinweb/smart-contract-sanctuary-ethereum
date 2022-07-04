//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    uint256 public favNumber;

    struct People {
        uint256 favNumber;
        string name;
    }

    mapping(string => uint256) public nameToFavNumber;

    //People public person = People({favNumber:2, name: "Tinuz"});
    People[] public people;

    function store(uint256 _favNumber) public virtual {
        favNumber = _favNumber;
    }

    function retreive() public view returns (uint256) {
        return favNumber;
    }

    function add(uint256 _favNumber, string memory _name) public {
        people.push(People(_favNumber, _name));
    }

    function addToMapping(uint256 _favNumber, string memory _name) public {
        nameToFavNumber[_name] = _favNumber;
    }
}