/**
 *Submitted for verification at Etherscan.io on 2023-02-19
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract SimpleStorage {
    uint256 favouriteNumber;

    mapping(string => uint256) public nameToFavouriteNumber;

    //    People public person = People({favouriteNumber: 5, name: "Patric"});

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    People[] public people;

    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    function retrive() public view returns (uint256) {
        return favouriteNumber;
    }

    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        //method to push data int array or list
        //People memory newPerson = People({favouriteNumber: _favouriteNumber, name: _name});
        //people.push(newPerson);
        //simple way to push data
        people.push(People(_favouriteNumber, _name));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
}