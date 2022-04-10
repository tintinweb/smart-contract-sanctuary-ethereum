/**
 *Submitted for verification at Etherscan.io on 2022-04-10
*/

pragma solidity ^0.4.24;

contract Test {
  event myEvent(string _msg);

  constructor() public {
    emit myEvent("記錄我的事件");
  }
}