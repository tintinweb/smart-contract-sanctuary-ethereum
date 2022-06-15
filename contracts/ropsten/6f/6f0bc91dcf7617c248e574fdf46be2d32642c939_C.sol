/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

pragma solidity ^0.8.14;

contract C {
    
  uint256 public _lastTime; //上一次产币时间

  function buyPower(uint256 amount) external returns(bool){
    address sender = msg.sender;
    // if (_lastTime == block.timestamp){
    //     return true;
    // }
    _lastTime = block.timestamp;
    return true;
  }

}