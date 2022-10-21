/**
 *Submitted for verification at Etherscan.io on 2022-10-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
   uint256 public _uValue;
   mapping(string => uint256) _mapFavNumber;

   struct Person {
      uint256 uFavNum;
      string sName;
   }

   Person[] _people;

   function Store(uint256 uValue) public virtual {
      _uValue = uValue;
   }

   function Retrieve() public view returns (uint256) {
      return _uValue;
   }

   function AddPerson(string memory sName, uint256 uFav) public {
      _people.push(Person(uFav, sName));
      _mapFavNumber[sName] = uFav;
   }
}