/**
 *Submitted for verification at Etherscan.io on 2023-06-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract Election{
    mapping (string =>uint) public CVoteCounter;
    mapping(uint =>uint) private IdtoAge;
      
    function addVoterData(uint ID,uint Age) public{
        
        IdtoAge[ID] =Age;
    }
   
    function setcondidatName(string memory _Condidatname) public{

     CVoteCounter[_Condidatname] = 0;
       
    }
    function  Eligibale(uint id) public view returns(bool){
    
        if( IdtoAge[id]>=18){
            return true;
        }
          else 
          return false;

        }
        function pollVote(uint _id,string memory _name) public{
          if(Eligibale(_id)){
            CVoteCounter[_name]+=1;

          }

        }

     
        

}