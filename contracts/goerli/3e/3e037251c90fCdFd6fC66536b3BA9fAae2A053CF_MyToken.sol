/**
 *Submitted for verification at Etherscan.io on 2022-11-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//https://docs.soliditylang.org/en/v0.8.17/introduction-to-smart-contracts.html#:~:text=A%20contract%20in%20the%20sense,unsigned%20integer%20of%20256%20bits).

// contract in the sense of Solidity is a collection of code (its functions) and data (its state) that resides at a specific address on the Ethereum blockchain
// uint constant supply = 1000000; declares a constant state variable of type uint (unsigned integer of 256 bits)

contract MyToken { // 
  // total supply of token
  uint256 constant supply = 1000000;
 
  // event to be emitted on transfer
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  // event to be emitted on approval
  event Approval(
    address indexed _owner,
    address indexed _spender,
    uint256 _value
  );

  // TODO: create mapping for balances
  // basically creates an array for all balances, public means that the variable can be accessed by the contract and by other smart contracts.
  mapping(address => uint256) public balances; // https://ethereum.stackexchange.com/questions/108110/how-does-mappingaddress-uint-public-balances-get-balances

  // TODO: create mapping for allowances
  mapping(address => mapping(address => uint256)) public allowances;   

  constructor() {
    // TODO: set sender's balance to total supply
    balances[msg.sender] = supply;
  }

  function totalSupply() public pure returns (uint256) {
    // TODO: return total supply. 
    // In Solidity, a function that doesn't read or modify the variables of the state is called a pure function.
    // In solidity, the return type of the function is defined at the time of declaration.
    return supply;
  }

  function balanceOf(address _owner) public view returns (uint256) {
    // TODO: return the balance of _owner
    return (balances[_owner]);
  }

  // making a transfer, if balance of msg.sender is greater than or equal to _value (make sure they have enough in account),
  // subtract the value from their account, add it to _to, emit event Transfer
  function transfer(address _to, uint256 _value) public returns (bool) {
    // TODO: transfer `_value` tokens from sender to `_to`
    // NOTE: sender needs to have enough tokens
    require(balances[msg.sender] >= _value); // require is like 'if' in Python
    balances[msg.sender] -= _value;
    balances[_to] += _value;
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) public returns (bool) {
    // TODO: transfer `_value` tokens from `_from` to `_to`
    // NOTE: `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
    require(balances[_from] >= _value);
    require(allowances[_from][msg.sender] >= _value);
    balances[_from] -= _value;
    balances[_to] += _value;
    allowances[_from][msg.sender] -= _value;
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    // TODO: allow `_spender` to spend `_value` on sender's behalf
    // NOTE: if an allowance already exists, it should be overwritten
    allowances[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;

  }

  function allowance(address _owner, address _spender)
    public
    view
    returns (uint256 remaining)
  {
    // TODO: return how much `_spender` is allowed to spend on behalf of `_owner`
    return allowances[_owner][_spender];
  }
}