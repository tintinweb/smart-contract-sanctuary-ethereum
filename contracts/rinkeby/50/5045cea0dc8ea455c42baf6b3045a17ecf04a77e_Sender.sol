/**
 *Submitted for verification at Etherscan.io on 2022-07-19
*/

pragma solidity ^0.8.7;

contract Sender {
  function send(address payable _receiver) public payable {
    _receiver.transfer(msg.value);
  }
}