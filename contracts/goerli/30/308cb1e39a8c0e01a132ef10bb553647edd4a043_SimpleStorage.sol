/**
 *Submitted for verification at Etherscan.io on 2023-01-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8; //Put the most staable version of solidity >=0.8.7  <0.9.0

//define a contract

contract SimpleStorage {
    // types  in solidity  boolean, unit, init, address,  bytes
    //Every  single  smart contract   has an address #0xd9145CCE52D386f254917e481eB44e9943F39138
    //bool  hasFavoriteNumber = true;
    uint256 public favoriteNumber; //default  value of  var in sol is  0

    //Srore data in map for better  search

    //mapping name to number
    mapping(string => uint256) public nameToFavoriteNumber;

    //manual way to  create  people
    //People public person = People({favoriteNumber: 2, name: "Aaryav"});//in curly places becoz we are referring to struct

    struct People {
        uint256 favoriteNumber; //indeed at 0
        string name; //indeed at1
    }

    // If we  awnt to creatte list of people then  we should use aaray if  we  want multiple  people better  way to initialize and manage
    People[] public people;

    //computationally active functions spend gas and showcased  as  orange buttons on the contracts
    //in  order for  the store function to be overridable in future  contracts we  can add "virtual" keyword
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
        // favoriteNumber = favoriteNumber + 1;  more gas  to  spend if  more computations to  do

        //calling  view  functions  inside the functions that   costs  gas will be considered  computational and active gas spend needs  to happen
        // eg retrieve();
    }

    //computationally inactive functions  are displayed in  blue color on the SC

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        //People memory newPerson = People({favoriteNumber: _favoriteNumber, name: _name});
        //OR
        //People memory newPerson = People({_favoriteNumber, _name});
        //OR

        people.push(People(_favoriteNumber, _name));
        //people.push(newPerson);

        //aassociate  favorite  number  to  name
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    // pure function  diallow reading  and modifying
    function add() public pure returns (uint256) {
        return (1 + 1);
    }
}

// Two  ways to  deploy  and run this contract , one way is to  deploy it  on Javascript  VM En  or Deploy it  on Testnet (Injected Web  3  that connects   to   your metamask)
//  Working  with  metamask gives you real time transaction simulation