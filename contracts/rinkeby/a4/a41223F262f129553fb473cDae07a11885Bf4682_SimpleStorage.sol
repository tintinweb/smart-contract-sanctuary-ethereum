// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract SimpleStorage {
    mapping(string => uint256) public nameToFavoriteNumber;

    //This gets intialized to zero!
    uint256 favouriteNumber;

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    People[] public people;

    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        //   People memory newPerson = People({favouriteNumber: _favouriteNumber, name: _name});
        people.push(People(_favouriteNumber, _name));
        nameToFavoriteNumber[_name] = _favouriteNumber;
    }
}

//0x5B38Da6a701c568545dCfcB03FcB875f56beddC4