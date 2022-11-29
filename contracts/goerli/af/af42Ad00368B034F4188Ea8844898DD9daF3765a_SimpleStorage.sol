/**
 *Submitted for verification at Etherscan.io on 2022-11-29
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8; //First thing to add in a solidity file is it's version

contract SimpleStorage {
    //(unAssigned Var) this gets initialized to zero
    uint256 favouriteNumber; //internal
    // uint256 public favouriteNumber; //public

    /*@struct
     *using struct
     *using arrays
     */

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    mapping(string => uint256) public nameToFavourite; // mapping

    // People public person = People({favouriteNumber: 7, name: "emmanuel"});
    // or
    People[] public people; //for more than one

    // uint256[] public favouriteNumber;

    // Adding people to my array

    //calldata,memory,storage
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // People memory newPerson = People({favouriteNumber: _favoriteNumber , name : _name});  //needs a memory keyword to work
        // people.push(newPerson);
        people.push(People({favouriteNumber: _favoriteNumber, name: _name}));
        nameToFavourite[_name] = _favoriteNumber;
    }

    //   function
    function store(uint256 _favoriteNumber) public virtual {
        favouriteNumber = _favoriteNumber;
    }

    //  view,pure

    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }
}
// Contract address => 0xd9145CCE52D386f254917e481eB44e9943F39138 ;