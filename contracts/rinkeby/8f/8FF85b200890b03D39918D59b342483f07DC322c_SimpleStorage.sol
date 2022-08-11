/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

contract SimpleStorage {
 
    uint public favoriteNumber; //defaults to 0 if not initialized to zero

   
    // People public person = People({favoriteNumber: 2, name: "Spencer"});

    People[] public people;

    //dictionay
    mapping(string => uint256) public nameToFavoriteNumber;

    //when u have a list of variables inside of an object they automatically get indexed
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    //in order for a function to be override we need to add virtual keyword
    // adding more to functon will increase its gas prices
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
        //if we call retrieve in this function gas price will go up
    }


    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

   
}