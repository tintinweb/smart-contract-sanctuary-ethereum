/**
 *Submitted for verification at Etherscan.io on 2022-06-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {

    // This gets initialized to zero
    // <- This means that this section is a comment!
    uint256 favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;
    

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // uint256[] public favoriteNumbersList;
    People[] public people;


    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

   // view, pure
   function retrieve() public view returns(uint256){
       return favoriteNumber;
   }

   function addPerson(string memory _name, uint256 _favoriteNumber) public {
       people.push(People(_favoriteNumber, _name));
       nameToFavoriteNumber[_name] = _favoriteNumber;
   }

   
}