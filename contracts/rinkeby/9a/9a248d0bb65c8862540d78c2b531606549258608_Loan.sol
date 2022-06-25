/**
 *Submitted for verification at Etherscan.io on 2022-06-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract Loan {
   uint amt;
   address admin;
   uint age;
    function setAmt(uint _amt) public {
        amt = _amt;
        admin = msg.sender;
    }
   function getMsgSender() public view returns(address){
      return msg.sender;
    }
   function checkAmt() public view returns(uint) {
      return amt;
   }
   function setAge(uint _age) public {
      require(msg.sender == admin);
      age = _age;
   }
}