/**
 *Submitted for verification at Etherscan.io on 2022-01-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
contract EventPubSubwithNode {
      string fName;
      uint age;

      event Student(
         string fName,
         uint age
      );
   
   function setStudentDetail(string memory _fName, uint _age) public {

        fName = _fName;
        age = _age;
        emit Student(_fName, _age);
   }
   function getStudentDetail() public view returns (string memory, uint) {

        return (fName, age);
   }
}