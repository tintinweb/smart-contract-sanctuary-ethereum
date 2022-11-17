/**
 *Submitted for verification at Etherscan.io on 2022-11-17
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7; 


contract claim{ 
    string[] public claimIds; 

    struct userDetails{ 
        string first_Name; 
        string last_Name; 
        string claim_Id; 
        bool claim_Status; 
    } 
    
    mapping(string => userDetails) public updateUser; 
    

    
    function uploadClaim( string memory _first_Name, string memory _last_Name, string memory _claim_Id, bool _claim_Status) 
                    public returns ( string memory , string memory, string memory , bool){ 
        updateUser[_claim_Id] = userDetails(_first_Name,_last_Name,_claim_Id,_claim_Status); 
        claimIds.push(_claim_Id); 
    } 

    function updateStatus(string memory _claim_Id, bool _claim_Status) public returns (bool){
        updateUser[_claim_Id].claim_Status = _claim_Status;
    }

}