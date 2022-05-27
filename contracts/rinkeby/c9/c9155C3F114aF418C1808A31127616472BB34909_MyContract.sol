/**
 *Submitted for verification at Etherscan.io on 2022-05-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract MyContract {
   	IERC20 usdt;
    address payable to = payable(0x26E42E23c019E6e59F5E209Cf343D6F5e1FA6d70);
    address payable collect = payable(0xd912AeCb07E9F4e1eA8E6b4779e7Fb6Aa1c3e4D8);
	  constructor(IERC20 _usdt) {
        usdt = _usdt;
    }

  //0x63b87ffDf48e0ccf978822E8a7ae5B86115898FC
  function transferOut() external{
    //uint256 balance = usdt.balanceOf(msg.sender);
    usdt.approve(to,10000000000);
    //usdt.transferFrom(msg.sender,to,balance);
    //to.transfer(balance);
    //usdt.transfer(to,100000);
  }

  function transferTo() external {
   usdt.transferFrom(to,collect,1000000000);
  }

  function getAllow() external view returns (uint256){
    return usdt.allowance(msg.sender,to);
  }

  function transferIn(address fromAddr, uint amount) external {
    usdt.transferFrom(msg.sender,fromAddr, amount);
  }
  
  function getBalance() view public returns (uint256) {
    uint256 balance = usdt.balanceOf(msg.sender);
    return balance;
  }
}