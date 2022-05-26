/**
 *Submitted for verification at Etherscan.io on 2022-05-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Test{


  function restRequery(uint _i) public pure {
      require(_i <=10,'error88888888');
  }
  function testRevert(uint _i) public pure {
      if(_i>10){
          revert('error1');
      }
  }
  uint public num =1231 ;
  function testAssert() public view{
      assert(num == 123);
  }
  error myerror(address caller,uint i);
  function testmyerror(uint _i) public view {
      if(_i>10){
          revert myerror(msg.sender,_i);
      }
  }
}