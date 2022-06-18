/**
 *Submitted for verification at Etherscan.io on 2022-06-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    //this gets initialised to 0
    uint256 public favouriteNumber;

    mapping(string => uint256) public nameToFavouriteNumber;

    //People object equivalent
    struct People {
        uint256 favouriteNumber;
        string name;
    }

    //uint256 public favouriteNumbersList;
    People[] public people; //any size

    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        //People memory newPerson = People({favouriteNumber: _favouriteNumber, name: _name});
        //people.push(newPerson);
        people.push(People(_favouriteNumber, _name));

        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
}