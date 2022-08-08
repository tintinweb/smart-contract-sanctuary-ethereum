/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

//SPDX-License-Indentifier: MIT

pragma solidity ^0.8.0;

contract SimpleStorage {

    uint256 favoriteNumber = 22;

    event FavoriteNumberSaved(uint256 favoriteNumber);
    struct Person {
        uint256 favoriteNumber;
        string name;
    }

    Person[] people;
    mapping(string => uint256) peopleList;



    function store(uint256 _favoriteNumber) public returns(uint256) {
        favoriteNumber = _favoriteNumber;
        return favoriteNumber;
    }

    function retrieve() public view returns(uint256) {
        return favoriteNumber;
    }
	
	function setFavNumber(uint256 _favNumber) public {
		favoriteNumber = _favNumber;
        emit FavoriteNumberSaved(_favNumber);
	}
    
    function getFavNumber() public view returns(uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(Person(_favoriteNumber, _name));
        peopleList[_name] = _favoriteNumber;

    }

    function getPersonFavNumber(string memory _name) private view returns(uint256) {
        return peopleList[_name];
    }
	
	function add(uint256 arg1, uint256 arg2) public pure returns(uint256) {
		return arg1 + arg2;
	}
}