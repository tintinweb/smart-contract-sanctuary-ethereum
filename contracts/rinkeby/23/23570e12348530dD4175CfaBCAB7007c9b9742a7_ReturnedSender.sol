// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract ReturnedSender {

    fallback() external payable{}
    receive() external payable{}

  function returningTxOrigin() public view returns(address){
      return tx.origin;
  }

  function returningMsgSender() public view returns(address){
      return msg.sender;
  }
}