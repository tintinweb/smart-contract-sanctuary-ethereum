/**
 *Submitted for verification at Etherscan.io on 2022-11-27
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Reference doc for token standards : https://ethereum.org/en/developers/docs/standards/tokens/erc-20/
contract Erc20{
  string private _name;
  string private _symbol;
  uint8 private _decimal;
  uint256 private _totalSupply;

  /*
    _balanceOf => object to hold the no. of tokens held by a address
    {
      address: balance
    }
  */
  mapping(address => uint256) private _balanceOf;

  /*
    _allowance => object to hold the allowed no. of tokens that the spender can use/transfer from the owner 
    {
      address: {
        address: allowance
      }
    }
  */
  mapping(address => mapping(address => uint256)) private _allowance;

  event Transfer (
    address indexed _from,
    address indexed _to,
    uint256 _value
  );

  event Approval (
    address indexed _owner,
    address indexed _spender,
    uint256 _value
  );


  constructor (string memory name_, string memory symbol_, uint8 decimal_, uint256 totalSupply_){
    _name = name_;
    _symbol = symbol_;
    _decimal = decimal_;
    _totalSupply = totalSupply_;
    // adding all the total supply in the balance of contract creator address
    _balanceOf[msg.sender] = totalSupply_;
  }

  function name() public view returns(string memory){
    return _name;
  }

  function symbol() public view returns(string memory){
    return _symbol;
  }

  function decimal() public view returns(uint8){
    return _decimal;
  }

  function totalSupply() public view returns(uint256){
    return _totalSupply;
  }

  function balanceOf(address owner) public view returns(uint256){
    return _balanceOf[owner];
  }

  // to transfer token from sender's/caller's address to receiver's address
  function transfer(address to, uint256 value) public returns(bool){
    // check if the sender has the sufficient amount of token to transfer
    require(_balanceOf[msg.sender] >= value, "Insufficient token balance");

    _balanceOf[msg.sender] -= value;
    _balanceOf[to] += value;

    emit Transfer(msg.sender, to, value);
    return true;
  }

  // to transfer token from owner's address by the approved spender to receiver's address
  function transferFrom(address from, address to, uint256 value) public returns(bool){
    // check if the spender has the approved limit for the amount of token transfered
    require(_allowance[from][msg.sender] >= value, "Exceeds allowance limit");
    // check if the owner has the sufficient amount of token to transfer
    require(_balanceOf[from] >= value, "Insufficient token balance");

    _balanceOf[from] -= value;
    _allowance[from][msg.sender] -= value;
    _balanceOf[to] += value;

    emit Transfer(from, to, value);
    return true;
  }

  // to check the allowance limit of spneder
  function allowance(address owner, address spender) public view returns(uint256){
    return _allowance[owner][spender];
  }

  // to set allowance limit for a spender 
  function approve(address spender, uint256 value) public returns(bool){
    _allowance[msg.sender][spender] = value;
    
    emit Approval(msg.sender, spender, value);
    return true;
  }
}