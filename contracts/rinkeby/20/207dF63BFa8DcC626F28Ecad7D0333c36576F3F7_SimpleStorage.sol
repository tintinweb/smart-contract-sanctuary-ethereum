// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract SimpleStorage {
    uint256 favouriteNumber; // gets initialised to 0 (null value)
    // People public person = People({favouriteNumber: 2, name: "John"});

    mapping(string => uint256) public nameToFavNumber;

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    People[] public people;

    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    // view and pure dont require gas to use
    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    function addPerson(string memory _name, uint256 _number) public {
        // People memory newPerson = People({favouriteNumber: _number, name: _name});
        // People memory newPerson = People(_number,_name);
        // people.push(newPerson);

        // can all be simplified to one line
        people.push(People(_number, _name));

        // mapping test
        nameToFavNumber[_name] = _number;
    }
}