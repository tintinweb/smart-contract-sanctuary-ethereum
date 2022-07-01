// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract op{
  uint public num;
  function setNum(uint256 newNum)public{
      num=newNum;
  }
}
contract temp{
    function callFunc(address dest)public{
       dest.call(abi.encodeWithSignature("setNum(uint256)",10));
    }
}