/**
 *Submitted for verification at Etherscan.io on 2022-06-12
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    uint256 public favoriteNumber; //public variable automatically equivalent to getter function
    
    People public person = People({favoriteNumber: 123, name: "Alvin"}); //variables hoisting - struct

    mapping(string => uint256) public nameToFavoriteNumberMapping;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string calldata _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumberMapping[_name] = _favoriteNumber;
    }

    function addPerson2(string memory _name, uint256 _favoriteNumber) public {
        People memory newPerson = People(_favoriteNumber, _name);
        people.push(newPerson);
        nameToFavoriteNumberMapping[_name] = _favoriteNumber;
    }

    function removePerson() public {
        people.pop();
    }
}