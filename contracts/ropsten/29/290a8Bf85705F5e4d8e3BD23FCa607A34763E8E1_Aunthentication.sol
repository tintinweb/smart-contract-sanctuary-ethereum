/**
 *Submitted for verification at Etherscan.io on 2022-09-10
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
contract Aunthentication
{
    string userName="saurabh";
    uint password=1234;
    struct auth
    {
        uint id;
        string name;
        string company;
    }
    constructor() {
        
       

    }
    mapping(uint=>auth)public data;
    function setData(string memory _userName,uint _password,uint _id,string memory _name,string memory _company)public  
    {
          if(keccak256(bytes(userName))==keccak256(bytes(_userName)) )
         {
              if(password == _password)
             {
                 auth memory data2=data[_id];
        require(_id != data2.id,"id unique ");
          data[_id]=auth({id:_id,name:_name,company:_company});
             }
             else {
             revert ("enter valid password");
             }

         }
         else {
         revert ("enter valid userName ");

         }
    }

    
}