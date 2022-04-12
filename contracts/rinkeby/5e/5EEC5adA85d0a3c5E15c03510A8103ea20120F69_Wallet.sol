/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Wallet{
    mapping(address => uint ) public balances;
    

    function Deposit() payable public{
       
        balances[msg.sender] = msg.value;
    }
    function withdraw(uint amount) public payable{
        require(balances[msg.sender] >= amount ,"Low Blance");
         balances[msg.sender] -=amount;
        
         payable(msg.sender).call{value: amount}("");
         
        
    }
    function balance(address _address) public view returns(uint){
        return balances[_address];
    }
    function Funds() public view returns(uint){
        return address(this).balance;
    }
   
}