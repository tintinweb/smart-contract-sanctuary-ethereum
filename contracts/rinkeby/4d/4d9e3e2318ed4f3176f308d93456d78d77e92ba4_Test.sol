/**
 *Submitted for verification at Etherscan.io on 2022-06-05
*/

pragma solidity ^0.5.0;

contract Test {
   event Deposit(address indexed _from, address indexed _to, uint _value);
   function deposit(address _to) public payable {      
      emit Deposit(msg.sender, _to, msg.value);
   }
}