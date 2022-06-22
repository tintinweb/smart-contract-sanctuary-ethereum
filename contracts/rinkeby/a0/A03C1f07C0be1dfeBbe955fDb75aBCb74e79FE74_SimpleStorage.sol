// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

contract SimpleStorage {
    // Default initialization is to "null" or 0 for uint
    uint256 public favNumber;
    bool favBool;

    // similar to an object
    struct People {
        uint256 favNumber;
        string name;
    }

    // array
    People[] public people;
    // mapping (basically an object with key value)
    mapping(string => uint256) public nameToFavNumber;

    function store(uint256 _favNumber) public {
        favNumber = _favNumber;
    }

    // "view" means that we'll only be reading some state
    // "pure" means we'll be doing some computation but not change any state
    function retrieve() public view returns (uint256) {
        return favNumber;
    }

    function addPerson(string memory _name, uint256 _favNumber) public {
        people.push(People({favNumber: _favNumber, name: _name}));
        nameToFavNumber[_name] = _favNumber;
    }
}