/**
 *Submitted for verification at Etherscan.io on 2022-07-14
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0; // version
// ^0.6.0 any version of 0.6

contract SimpleStorage{
    //global contract scope 
    uint256 favoriteNumber; // initializing my integer variable to 0
    // default visibility is private

    struct People{ // custom class
        uint256 favoriteNumber;
        string name;
    }
    // Dynamic array: can change in size 
    People[] public people;
    // People public person = People({favoriteNumber:7, name:"Caleb"});

    // mapping allows us to find the associated value tagged to the input parameter (input => value)
    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public { // public keyword denotes the visibility of the variable/ function to the public
        favoriteNumber = _favoriteNumber;
    }

    // view and pure do not change the state of the blockchain
    // pure does math 
    function retrieve() public view returns(uint256){ // a return function 
        return favoriteNumber;
    }
    // orange buttons: change the state of the blockchain 
    // blue buttons: do not change the state of the blockchain like retrieve where it simply views the favoriteNumber

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber; // regsiter the mapping of the key and the associated value
    }
    // 2 ways to store information: memory and storage 
    // memory: Data will be stored during the execution of the function; usually paired with string during paramter call
    // storage: data will persists even after the function has been executed; keep it forever


}