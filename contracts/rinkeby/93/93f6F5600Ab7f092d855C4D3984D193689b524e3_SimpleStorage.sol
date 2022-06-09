/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {

    uint256 favouriteNumber;

    struct People{
        uint256 favouriteNumber;
        string name;
    }
    People[] public people;
    mapping(string=>uint256) public nameToFavNum;

    function store(uint256 fn) public virtual{
        favouriteNumber= fn;
    }

    function retrieve() public view returns(uint256){
        return favouriteNumber;
    }

    function addPeople (string memory _name, uint256 _fn) public{
        //call push with the object 
        people.push(People(_fn,_name));
        nameToFavNum[_name]=_fn;
    }

}