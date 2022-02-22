/**
 *Submitted for verification at Etherscan.io on 2022-02-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Zombie {
  

  mapping(address => uint256) balances;
  mapping(address => mapping(address => uint256)) allowances;

  uint256 private _totalSupply;

  string private _name;
  string private _symbol;

  /**
   * @dev Sets the values for {name} and {symbol}.
   *
   * The default value of {decimals} is 18. To select a different value for
   * {decimals} you should overload it.
   *
   * All two of these values are immutable: they can only be set once during
   * construction.
   */
  constructor(string memory name_, string memory symbol_, uint256 totalSupply_) {
      _name = name_;
      _symbol = symbol_;
      _totalSupply = totalSupply_;
      balances[msg.sender] = totalSupply_;
  }

  /**
   * @dev Returns the name of the token.
   */
  function name() public view returns (string memory) {
      return _name;
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() public view returns (string memory) {
      return _symbol;
  }

  /**
   * @dev Returns the number of decimals used to get its user representation.
   */
  function decimals() public pure returns (uint8) {
      return 0;
  }

  event Transfer(
  address indexed from, 
  address indexed to, 
  uint256 value
  );
  
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );

  /**
   * @dev Return total supply of the erc20 token
   * @return uint256
   */
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev Return amount of tokens held by an address
   * @param account address of owner
   * @return uint256
   */
  function balanceOf(address account) public view returns (uint256) {
    return balances[account];
  }

  /**
   * @dev Transfers ERC20 Tokens from caller's account to 'recipient'
   * @param recipient address
   * @param amount of tokens to be sent
   * @return bool status of transaction (success/failure)
   */
  function transfer(address recipient, uint256 amount) public returns (bool) {
    require(balances[msg.sender] >= amount, "Transfer not possible! Insufficient tokens!");

    balances[msg.sender] -= amount;
    balances[recipient] += amount;
    emit Transfer(msg.sender, recipient, amount);

    return true;
  }

  /**
   * @dev Returns the remaining amount of tokens that 'spender' will be allowed to spend on behalf of 'owner' through {transferFrom}.
   * @param owner address
   * @param spender address
   * @return uint256 amount allowed
   */
  function allowance(address owner, address spender) public view returns (uint256)
  {
    return allowances[owner][spender];
  }

  /**
   * @dev Sets 'amount' as the allowance of 'spender' over the caller's tokens.
   * @param spender address
   * @param amount of tokens to be approved
   * @return bool status of transaction
   */
  function approve(address spender, uint256 amount) public returns (bool) 
  {
    allowances[msg.sender][spender] = amount;
    emit Approval(msg.sender, spender, amount);

    return true;
  }

  /**
   * @dev Moves 'amount' tokens from 'sender' to 'recipient' using the allowance mechanism. 'amount' is then deducted from the caller's allowance.
   * @param sender address to transfer from
   * @param recipient address of receiver
   * @param amount of tokens to be sent
   * @return bool status of transaction
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public returns (bool) 
  {
    require(balances[sender] >= amount, "Transfer not possible! Insufficient tokens!");
    require(allowances[sender][msg.sender] >= amount, "Insufficient allowance");

    balances[sender] -= amount;
    allowances[sender][msg.sender] -= amount;
    balances[recipient] += amount;
    emit Transfer(sender, recipient, amount);

    return true;
  }
}