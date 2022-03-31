/**
 *Submitted for verification at Etherscan.io on 2022-03-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Banco{

  constructor() {

}

function incrementBalance () payable public {
require (msg.value==2000);

}

function getBalance()public {
    payable(msg.sender).transfer(address(this).balance);
}

function Balance() view public returns (uint256) {

return address(this).balance;
}


}