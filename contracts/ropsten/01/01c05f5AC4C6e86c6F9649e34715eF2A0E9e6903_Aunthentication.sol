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
         string disease;
         uint age;
         string gender;
         string hash;
    }
     event tomar(address indexed ownerAddress,string hash,uint id);
    mapping(uint=>auth)public data;
    function setData(
        string memory _userName,
        uint _password,
        uint _id,
         uint _age,
        string memory _name,
        string memory _company,
         string memory _disease,
         string memory _gender,
         string memory _hash
        )public  
    {
          if(keccak256(bytes(userName))==keccak256(bytes(_userName)) )
         {
              if(password == _password)
             {
                 auth memory data2=data[_id];
        require(_id != data2.id,"id unique ");
          data[_id]=auth({id:_id,name:_name,company:_company,hash:_hash,age:_age,gender:_gender,disease:_disease});
             }
             else {
             revert ("enter valid password");
             }

         }
         else {
         revert ("enter valid userName ");

         }
          emit tomar(msg.sender,_hash,_id);
    }

    
}