/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

//SPDX-License-Identifier: GPL-3.0 
pragma solidity ^0.8.0;

contract MyContract {
  function pay() public payable {

  }

  function balance() public view returns (uint) {
    return address(this).balance;
  }

  function destroy() public {
    selfdestruct(payable(msg.sender));
  }

}