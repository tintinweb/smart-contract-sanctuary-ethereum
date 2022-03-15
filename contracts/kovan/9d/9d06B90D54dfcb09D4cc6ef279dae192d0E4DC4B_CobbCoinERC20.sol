/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

// Define a library for Balances
library Balances {
    // Define move method. Checks that balances sent between addresses line up.
    function move(mapping(address => uint256) storage balances, address from, address to, uint amount) internal {
        require(balances[from] >= amount);
        require(balances[to] + amount >= balances[to]);
        balances[from] -= amount;
        balances[to] += amount;
    }
}

// Contract for coin creation
contract CobbCoinERC20 {
  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

  // Define basic coin info
  string public constant name = "Cobb Coin";
  string public constant symbol = "COBB";
  uint8 public constant decimals = 4;

  // Allow use of Balances library
  mapping(address => uint256) balances;
  using Balances for *;
  mapping(address => mapping (address => uint256)) allowed;

  // Declare total supply as an integer
  uint256 totalSupply_;

  // Constructor is run when coin is initally created
  constructor(uint256 total) {
    totalSupply_ = total;
    balances[msg.sender] = totalSupply_;
  }

  // Get the balance of tokenOwner's tokens in contract (address passed in when func is called)
  function balanceOf(address tokenOwner) public view returns (uint) {
    return balances[tokenOwner];
  }

  function transfer(address receiver, uint numTokens) public returns (bool success) {
    balances.move(msg.sender, receiver, numTokens);
    emit Transfer(msg.sender, receiver, numTokens);
    return true;
  }

  function approve(address delegate, uint numTokens) public returns (bool success) {
    allowed[msg.sender][delegate] = numTokens;
    emit Approval(msg.sender, delegate, numTokens);
    return true;
  }

  function allowance(address owner, address delegate) public view returns (uint) {
    return allowed[owner][delegate];
  }

  function transferFrom(address from, address to, uint numTokens) public returns (bool success) {
    require(numTokens <= balances[from]);
    require(numTokens <= allowed[from][msg.sender]);
    balances[from] -= numTokens;
    allowed[from][msg.sender] -= numTokens;
    balances[to] += numTokens;
    emit Transfer(from, to, numTokens);
    return true;
  }
}

contract SafeMath {
  function safeAdd(uint a, uint b) public pure returns (uint c) {
    c = a + b;
    require(c >= a);
  }
  function safeSub(uint a, uint b) public pure returns (uint c) {
    require(b <= a);
    c = a - b;
  }
  function safeMul(uint a, uint b) public pure returns (uint c) {
    c = a * b;
    require(a == 0 || c / a == b);
  }
  function safeDiv(uint a, uint b) public pure returns (uint c) {
    require(b > 0);
    c = a / b;
  }
}