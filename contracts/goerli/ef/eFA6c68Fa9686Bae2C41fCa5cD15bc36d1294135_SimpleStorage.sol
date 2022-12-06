/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7; // ^0.8.12 >=0.8.7 < 0.9.0 (for solidity version to use) 

contract SimpleStorage {
   uint256 public favoriteNumber; 
   bool hasFavoriteInBool = true; // private
   uint hasFavoriteInNumber = 5; // just for positive int number only
   string hasFavoriteInText = 'welcome';
   int256 hasFavoriteInInt = 5;
   address hasFavoriteInAddress = 0xdCad3a6d3569DF655070DEd06cb7A1b2Ccd1D3AF;
   bytes hasFavoriteInBytes = "cat"; //convert it to hexdecimal

   People public person = People({
      age: 6,
      name: "Ade"
   });

   People[] public people_;

   mapping(string => uint) public nameToAge;

   struct People {
      uint age;
      string name;
   }

   function store(uint _favoriteNumber) public virtual {
      favoriteNumber = _favoriteNumber + hasFavoriteInNumber;
   }

   // it is for output only without gas cost
   function retrieve() public view returns(uint256){
      return favoriteNumber;
   }

   //it is use for logo without gas cost 
   function add() public pure returns(uint){
      return(1 + 1);
   }

   function addPerson(string calldata _name, string memory fullname, uint  _age) public {
      fullname = "cat"; // can be modified because is memory  and store as tempoary

      // People memory newPerson = People({
      //    age: _age,
      //    name: _name // can't be modified because is calldata and store as tempoary
      // });
      // People memory newPerson = People(_age,_name);
      // people_.push(newPerson);
      people_.push(People(_age,_name));
      nameToAge[_name] = _age;
   }
}


// note that "view & pure"  are used without gas cost while other cost gas
// https://docs.soliditylang.org/en/0.8.13