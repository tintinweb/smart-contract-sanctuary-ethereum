/**
 *Submitted for verification at Etherscan.io on 2023-02-11
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    uint256 public favoriteNumber;
    struct People {
        string name;
        uint256 favNum;
    }
    People[] public listOfPeople;
    mapping(string => uint256) public nameToFavNum;

    function storeFavNum(uint256 _favNum) public virtual {
        favoriteNumber = _favNum;
    }

    function retrieveFavNum() public view returns (uint256) {
        return favoriteNumber;
    }

    //object initializer syntax - create People object stored in memory and push object to array
    //maybe more notes on this method
    //maybe more notes on this method
    function addPerson0(string memory _name, uint256 _favNum) public {
        People memory newPerson = People({name: _name, favNum: _favNum});
        listOfPeople.push(newPerson);
        nameToFavNum[_name] = _favNum;
    }

    //object initializer syntax - create People object and push object to array in the same line
    //maybe more notes on this method
    //maybe more notes on this method
    function addPerson1(string memory _name, uint256 _favNum) public {
        listOfPeople.push(People({name: _name, favNum: _favNum}));
        nameToFavNum[_name] = _favNum;
    }

    //constructor function - create people constuctor and pass arguments directlty through it
    //maybe more notes on this method
    //maybe more notes on this method
    function addPerson2(string memory _name, uint256 _favNum) public {
        listOfPeople.push(People(_name, _favNum));
        nameToFavNum[_name] = _favNum;
    }

    //calldata is temporay variables that can't be modified
    //memory is temporay variables that can be modified
    //storage permanent variables that can be modified
    //a "pure" function can only perform calculations
    //a "view" functions can perform calculations & read the blockchain
}