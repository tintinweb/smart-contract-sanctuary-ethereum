/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

contract Accounts { 
 
   uint id = 0;
   struct Account {
       uint userId;
   }
 
   mapping(address => Account) public accounts;  // key - address, value - uint id
 
 
   function Registration(address userAddress) external {
       id ++;
       accounts[userAddress] = Account(id);
   }
 
 
   function Authorization(address userAddress) external returns(Account memory){
       return accounts[userAddress];
   }
}