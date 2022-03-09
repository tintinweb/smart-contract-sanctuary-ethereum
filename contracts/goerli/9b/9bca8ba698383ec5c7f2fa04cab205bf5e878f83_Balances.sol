/**
 *Submitted for verification at Etherscan.io on 2022-03-09
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
contract Balances{
     string name;
        constructor (string memory _name){
        name=_name;
         }

    mapping (address=>uint) public balances;

    function mint(address receiver,uint amount)public{
        balances[receiver]=balances[receiver]+amount;
    }
    function transfer(address receiver,uint amount)public{  
        balances[msg.sender]=balances[msg.sender]-amount;
        balances[receiver]=balances[receiver]+amount;
    }
    function balanceOf(address  user)public view returns(uint){
        return balances[user];
    }

}