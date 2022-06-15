/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

pragma solidity ^0.8.14;

contract C {
    
  uint256 public _lastTime; //上一次产币时间
  uint256 public _total; 

  function buyPower() external returns(bool){
    _lastTime = block.timestamp;
    return true;
  }

  function add() external returns(bool){
    _total++;
    return true;
  }

}