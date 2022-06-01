/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage{
    uint favouriteNumber;

    struct People{
        uint256 favouriteNumber;
        string name;
    }

    People[] public people ;

    mapping(uint256 => string) public favouriteNumberToStringMap;

    function store(uint256 _favoriteNumber) public{
      favouriteNumber = _favoriteNumber;
    }

    function retrive() public view returns(uint256){
      return favouriteNumber;
    }

    function addToPeople(string memory _name, uint256 _favoriteNumber) public{
        people.push(People(_favoriteNumber,_name));
        favouriteNumberToStringMap[_favoriteNumber] = _name ;
    }
}