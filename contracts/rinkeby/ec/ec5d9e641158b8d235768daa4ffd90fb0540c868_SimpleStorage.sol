/**
 *Submitted for verification at Etherscan.io on 2022-05-28
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

contract SimpleStorage{
    uint256 favouriteNumber;
    People[] public person;

    mapping(string => uint256) public nameToFavouriteNumber;

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    function store(uint256 _favouriteNumber) public{
        favouriteNumber = _favouriteNumber;
    }

    function retrieve() public view returns (uint256){
        return favouriteNumber;
    }

    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        People memory newPerson = People({favouriteNumber: _favouriteNumber, name: _name});
        person.push(newPerson);
        nameToFavouriteNumber[_name] = _favouriteNumber;

    }
}