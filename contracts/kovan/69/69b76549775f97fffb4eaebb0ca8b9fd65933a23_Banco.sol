/**
 *Submitted for verification at Etherscan.io on 2022-03-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Banco{

  constructor() {

}

function incrementBalance(uint256 amount)  private {

}

function getBalance()public {
    payable(msg.sender).transfer(address(this).balance);
}

function Balance() view public returns (uint256) {

return address(this).balance;
}


}