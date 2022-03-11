/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
contract Testing {
  uint256  reqNumber;
  struct Tasks {
      uint256 reqNumber;
      string name;
  }
  Tasks[] public task;
  mapping(string => uint256) public nameToReqNumber;

  function req(uint256 _reqNumber) public {
     reqNumber =_reqNumber;
  }
  function retrieve() public view returns(uint256) {
      return reqNumber;
  }
  function addTask(string memory _name, uint256 _reqNumber) public{
    task.push(Tasks( _reqNumber,_name));
    nameToReqNumber[_name] = _reqNumber;
  }
}