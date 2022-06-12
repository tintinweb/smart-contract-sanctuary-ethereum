/**
 *Submitted for verification at Etherscan.io on 2022-06-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage{
    uint favouritenumber;

    struct People{
        uint256 favouritenumber;
        string name;
    }

    People[] public people;
    

    mapping(string=>uint256) nametoFavouritenumber;

    function store(uint256 _favouritenumber) public virtual{
        favouritenumber = _favouritenumber;
    }

    function retrieve() public view returns(uint256){
        return favouritenumber;
    }

    function addPerson(string memory _name, uint256 _favouritenumber)  public{
        people.push(People(_favouritenumber,_name));
        nametoFavouritenumber[_name] = _favouritenumber;
    }

}