/**
 *Submitted for verification at Etherscan.io on 2023-01-05
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract SimpleStorage {
    uint public favoriteNumber;

    struct People {
        uint fav_num;
        string name;
    }

    mapping(string => uint) public fav_num_to_name;

    People public person = People(favoriteNumber, "Sahil");

    People[] public persons;

    function addPeople(uint _favoriteNumber, string memory _name) public {
        persons.push(People(_favoriteNumber, _name));
        fav_num_to_name[_name] = _favoriteNumber;
    }

    function getVal(uint _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint) {
        return favoriteNumber;
    }
}