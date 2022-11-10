/**
 *Submitted for verification at Etherscan.io on 2022-11-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract BasicSmartContract { 

    /**
     * @notice variables
    */

    // create a variable that store name
    // create a variable that store father name
    // create a variable that store mother name 
    // create a variable that has marritial status - type enum, values - single, married, divorcee
    // create a variable that store place you belong 
    // create a variable that store your district 
    // create a variable that store your state
    // create a variable that store your nation
    // create a variable that store your favorate sport
    // create a variable that store your profession

    /**
     * @notice setter function for all variable
    */

    /**
     * @notice getter function for all variable
    */

    enum marritalStatus{single, married, divorce}
    marritalStatus status;


    function getMarritalStatus() public view returns (marritalStatus){
        return status;
    }

    function setMarritalStatus(marritalStatus _status) public{
        status = _status;
    }
   
   
   string name;
   string fatherName;
   string  motherName;
   string  livinAddress;
   string  district;
   string  nation;
   string  favorateSport;
   string  profession;


   function setInfo(string memory _name, string memory _fatherName, string memory _motherName, string memory _livinAddress,
    string memory _district, string memory _nation, string memory _favorateSport, string memory _profession
      ) public {

          name = _name;
          fatherName = _fatherName;
          motherName = _motherName;
          livinAddress = _livinAddress;
          district = _district;
          nation = _nation;
          favorateSport = _favorateSport;
          profession = _profession;


      }



      function getInfo() public view returns(string memory, string memory, string memory, string memory, string memory
      ,string memory, string memory, string memory) {
          return (name, fatherName, motherName, livinAddress, district, nation, favorateSport, profession);
          
      }


     



 

}