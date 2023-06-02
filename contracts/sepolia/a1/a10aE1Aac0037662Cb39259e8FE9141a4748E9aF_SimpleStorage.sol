/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    uint256 favouriteNumber;
    struct People {
         string name;
        uint256 favouriteNumber;
    }
    People[] public people ;
    mapping(string =>uint256) public nameToFavouriteNumber;
    function store (uint _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }
    function reterive() public view returns(uint256){
        return favouriteNumber;
    }
    function addPerson(string memory _name,uint256 _favouriteNumber) public {
        people.push(People(_name,_favouriteNumber));
        nameToFavouriteNumber[_name]=_favouriteNumber;
    }
}