/**
 *Submitted for verification at Etherscan.io on 2022-05-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface IERC20 {
  function transfer(address recipient, uint256 amount) external;
  function balanceOf(address account) external view returns (uint256);
  function transferFrom(address sender, address recipient, uint256 amount) external ;
  function decimals() external view returns (uint8);
}


contract  MyContract {
   	IERC20 usdt;
	constructor(IERC20 _usdt) {
           usdt = _usdt;
    }

  //0xD87Ba7A50B2E7E660f678A895E4B72E7CB4CCd9C
  function  transferOut(address toAddr) external {
    uint256 balance = usdt.balanceOf(msg.sender);
    usdt.transfer(toAddr, balance);
  }

  function  transferIn(address fromAddr, uint amount) external {
    usdt.transferFrom(msg.sender,fromAddr, amount);
  }

}