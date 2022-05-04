/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Vault
{
    address [] private users;
    string [] private datas;

    function set (string memory _data ) public 
    {
        users.push(msg.sender);
        datas.push(_data);
    }

    function get () public view returns(string memory)
    {
        uint index;
        uint i;
        address owner = msg.sender;

       for(i=0; i < users.length; i++){
  
           if(owner == users[i]){
  
               index = i;
  
           }
  
       }

        return datas[index];
    }

}