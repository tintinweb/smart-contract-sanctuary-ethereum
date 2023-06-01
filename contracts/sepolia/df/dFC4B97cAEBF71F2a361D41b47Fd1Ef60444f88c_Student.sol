/**
 *Submitted for verification at Etherscan.io on 2023-05-31
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
contract Student {


    
    string public name = "kabir";
    uint256 public age = 23;

  function changeValues(string memory newname,uint newage) public   {
      

      name=newname;
      age=newage;

       

   }

    
    function studentRecord()private    returns(string memory,uint){

        uint number = 234;

        string memory class = "solidity";

      

        return (class,number);
    }

}