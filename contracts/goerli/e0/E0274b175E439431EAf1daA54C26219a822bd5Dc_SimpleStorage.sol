/**
 *Submitted for verification at Etherscan.io on 2022-11-01
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract SimpleStorage {
    uint favoriteNumber;
    mapping(string => uint) public nametoFavoriteNumber;

    function store(uint _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    struct People {
        uint favoriteNumber;
        string name;
    }

    //people is the array of People struct
    People[] public people;

    function addPerson(string memory _name, uint _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        //Can also do it this way
        /* People memory newPerson = People({favoriteNumber: _favoriteNumber,name: _name})
           people.push(newPerson); */

        nametoFavoriteNumber[_name] = _favoriteNumber;
    }

    function retrieve() public view returns (uint) {
        return favoriteNumber;
    }
}