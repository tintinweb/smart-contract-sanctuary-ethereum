/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

contract Faucet {

  event FaucetSent(address _from, uint256 _value);

  function withdraw(address payable sendTo) external {
    require(address(this).balance >= 1000000000000000);
    sendTo.transfer(1000000000000000);
    emit FaucetSent(sendTo, 1000000000000000);
  }

  fallback() external payable {
    // custom function code
  }
  
  receive() external payable {
    // custom function code
  }
}