/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.1;
contract ERC20Interface{
  
      function Record(uint _num) public returns (bool );
      function R() public view returns (uint);
}


contract Dollarpool is ERC20Interface{
    uint TestNum = 30 ;
    address Owner ;
 constructor() public {
    Owner = msg.sender ;
 }
    function Record(uint _num) public returns (bool success){
        require(_num <=  TestNum , "No Record");
          TestNum -= _num ;
          return(true);
    }
    function R() public view returns(uint){
        return(TestNum);
    }
}