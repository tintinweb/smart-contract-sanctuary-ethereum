/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;


contract SimpleStorage{
    uint256 public favorateNumber ;


mapping (string=> uint256) public nameToFavorateNumber;

   struct People{
       uint256 favorateNumber;
       string name;
   }
   
   People[] public people;

   function addPerson (uint256 _favorateNumber,string memory _name) public {
     people.push(People(_favorateNumber ,_name));
    nameToFavorateNumber[_name]=_favorateNumber;
   }


  function retrieve() public view returns (uint256){
        return favorateNumber;
    }

    function store(uint256 _favorater) virtual  public{
        favorateNumber = _favorater;
    }
}