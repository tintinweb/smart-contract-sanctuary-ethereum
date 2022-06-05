/**
 *Submitted for verification at Etherscan.io on 2022-06-05
*/

pragma solidity ^0.5.0;

contract Test {
   event Deposit(address indexed _from, uint indexed _id, uint _value);
   function deposit(uint _id) public payable {      
      emit Deposit(msg.sender, _id, msg.value);
   }
}