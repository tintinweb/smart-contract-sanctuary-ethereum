/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

//SPDX-License-Indentifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

contract StructTest {

    uint256 favoriteNumber = 22;

    event FavoriteNumberSaved(uint256 favoriteNumber);
    struct Person {
        uint256 favoriteNumber;
        string name;
    }
    
    mapping(string => Person) public peopleList;

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

    function addPerson(Person memory _person) public {
        //people.push(_person));
        peopleList[_person.name] = _person;
    }

    function getPersonFavNumber(string memory _name) public view returns(uint256) {
        return peopleList[_name].favoriteNumber;
    }
	
	function add(uint256 arg1, uint256 arg2) public pure returns(uint256) {
		return arg1 + arg2;
	}
}