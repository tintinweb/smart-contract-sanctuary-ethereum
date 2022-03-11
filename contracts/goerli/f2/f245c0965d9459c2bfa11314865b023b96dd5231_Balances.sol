/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
contract Balances{
     string name;
        constructor (string memory _name){
        name=_name;
         }  
    mapping (address=>uint) private balances;
    event Transfer(address sender,address receiver,uint amount);

    function mint(address receiver,uint amount)public{
        balances[receiver]+=amount;
        emit Transfer(address(0),receiver,amount);
    }

    function transfer(address receiver,uint amount)public{  
        //check whether balances of sender is greater than or equal to amount
        require(balances[msg.sender]>=amount,"Invalid Amount,please send more");
        balances[msg.sender]-=amount;
        balances[receiver]+=amount;
        emit Transfer(msg.sender,receiver,amount);
    }

    function balanceOf(address  user)public view returns(uint){
        return balances[user];
    }
}