/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract PiggyBank{

// - 建立合約時可以設定儲蓄目標
// - 能查詢儲蓄目標
// - 能收取 ether
// - 提領時，儲蓄的總金額需大於儲蓄目標，並銷毀撲滿

uint public target;

constructor(uint t){
target=t;
}

receive() external payable{}

uint public u=address(this).balance;

function getAsset() public {

if (u>=target){
selfdestruct(payable(msg.sender));
}

}

}