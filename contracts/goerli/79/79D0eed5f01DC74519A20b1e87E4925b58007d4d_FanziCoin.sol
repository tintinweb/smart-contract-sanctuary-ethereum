/**
 *Submitted for verification at Etherscan.io on 2023-03-10
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract FanziCoin {

  // Since these constants are public, get methods are automatically generated.
  
  // Name of the token
  string public constant name = "FanziCoin";

  // Symbol of the token
  string public constant symbol = "FZC";

  // Number of decimals the token uses
  uint8 public constant decimals = 8;

  // Total supply of coins
  uint256 public supply;

  mapping(address => uint256) public balances;
  mapping(address => mapping(address => uint256)) public allowances;

  // -----------------------------------------------------------------------

  constructor(uint256 _initialSupply) {
    supply = _initialSupply;
    balances[msg.sender] = supply;
  }

  // -----------------------------------------------------------------------
  // You must emit these events when certain triggers occur (see the ERC-20 spec).

  // MUST trigger on any successful call to approve(address _spender, uint256 _value).
  event Approval(address indexed _from, address indexed _to, uint256 _value);

  // A token contract which creates new tokens SHOULD trigger a Transfer event with
  // the _from address set to 0x0 when tokens are created.
  event Transfer(address indexed _owner, address indexed _spender, uint256 _value);

  // -----------------------------------------------------------------------

  // Returns the total token supply.
  function totalSupply() public view returns (uint256) {
    return supply;
  }

  // -----------------------------------------------------------------------

  // Returns the account balance of another account with address _owner. 
  function balanceOf(address _owner) public view returns (uint) {
    return balances[_owner];
  }

  // -----------------------------------------------------------------------
  // Transfers _value amount of tokens to address _to, and MUST fire the Transfer event. 
  // The function SHOULD throw if the message caller’s account balance does not have 
  // enough tokens to spend.
  function transfer(address _to, uint256 _value) public returns (bool) {
    
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender] - _value;
    balances[_to] = balances[_to] + _value;
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  // -----------------------------------------------------------------------
  // Transfers _value amount of tokens from address _from to address _to, and MUST
  // fire the Transfer event.
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {

    require(_to != address(0));
    require(msg.sender != address(0), "Transfer from the zero address");
    require(_value <= allowances[_from][msg.sender]);
    require(_value <= balances[_from]);

   
    balances[_from] -= _value;
    balances[_to] += _value;
    allowances[_from][msg.sender] -= _value;
    emit Transfer(_from, _to, _value);
    return true;
  }

  // -----------------------------------------------------------------------
  // Allows _spender to withdraw from your account multiple times, up to the _value amount. 
  // If this function is called again it overwrites the current allowance with _value.
  function approve(address _spender, uint256 _value)  public returns (bool) {

    require(_spender != address(0));
    allowances[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  // -----------------------------------------------------------------------
  // Returns the amount which _spender is still allowed to withdraw from _owner.
  function allowance(address _owner, address _spender) public view returns (uint) {
    return allowances[_owner][_spender];
  }
}