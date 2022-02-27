/**
 *Submitted for verification at Etherscan.io on 2022-02-27
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract Deposit{

     receive() external payable{
     }
     
     
     function getBalance() public view returns(uint){
         return address(this).balance;
     }

     function sendEntireBalance(address payable _address) public returns(bool){
         _address.transfer(getBalance());
         return true;
     }


    
}