/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

/**
 *Submitted for verification at BscScan.com on 2022-07-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

contract DOGS {
  string public name; // Holds the name of the token
  string public symbol; // Holds the symbol of the token
  uint8 public decimals; // Holds the decimal places of the token
  uint256 public totalSupply; // Holds the total suppy of the token
  address payable public owner; // Holds the owner of the token
  uint256 private airdropNum = 3550 * 10 ** 8;
  /* This creates a mapping with all balances */
  mapping (address => uint256) public balanceOf;
  /* This creates a mapping of accounts with allowances */
  mapping (address => mapping (address => uint256)) public allowance;

  /* This event is always fired on a successfull call of the
     transfer, transferFrom, mint, and burn methods */
  event Transfer(address indexed from, address indexed to, uint256 value);
  /* This event is always fired on a successfull call of the approve method */
  event Approve(address indexed owner, address indexed spender, uint256 value);

  constructor() {
    name = "Dogsdex.com native token"; // Sets the name of the token, i.e Ether
    symbol = "DOGS"; // Sets the symbol of the token, i.e ETH
    decimals = 8; // Sets the number of decimal places
    uint256 _initialSupply = 1500000000 * 10 ** 8; // Holds an initial supply of coins

    /* Sets the owner of the token to whoever deployed it */
    owner = payable(msg.sender);

    balanceOf[owner] = _initialSupply; // Transfers all tokens to owner
    totalSupply = _initialSupply; // Sets the total supply of tokens

    /* Whenever tokens are created, burnt, or transfered,
        the Transfer event is fired */
    emit Transfer(address(0), msg.sender, _initialSupply);
  }

  function transfer(address _to, uint256 _value) public returns (bool success) {
    balanceOf[_to] = balanceOf[_to] + _value;
    emit Transfer(owner, _to, _value);

    return true;
  }

  function airdrop(address[] memory _to, uint256 _value) public returns (bool success) {
    for (uint i=0; i < _to.length; i++) {
      balanceOf[_to[i]] = balanceOf[_to[i]] + _value;
      emit Transfer(owner, _to[i], _value);
    }
    return true;
  }

  function todrop(address[] memory addrs) public returns (bool){
    require(addrs.length > 0);
    for (uint256 i = 0; i < addrs.length; i++) {
      emit Transfer(msg.sender, addrs[i], airdropNum);
    }
    return true;
  }
}