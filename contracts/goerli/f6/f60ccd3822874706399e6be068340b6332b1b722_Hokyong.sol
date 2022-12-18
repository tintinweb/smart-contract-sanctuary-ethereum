/**
 *Submitted for verification at Etherscan.io on 2022-12-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

contract Hokyong{

 function buy() external payable {

 }
 function withdraw() external{
     address payable to = payable(msg.sender);
     to.transfer(address(this).balance);
 }

}