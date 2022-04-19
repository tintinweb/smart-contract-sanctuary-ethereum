/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.5.10;



// Part: SafeMathNew

contract SafeMathNew {
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

// Part: TRC20Basic

contract TRC20Basic {
  uint public _totalSupply;
  function totalSupply() public view returns (uint);
  function balanceOf(address who) public view returns (uint);
  function transfer(address to, uint value) public;
  event Transfer(address indexed from, address indexed to, uint value);

}

// Part: TRC20

contract TRC20 is TRC20Basic {
  function allowance(address owner, address spender) public view returns (uint);
  function transferFrom(address from, address to, uint value) public;
  function approve(address spender, uint value) public;
  event Approval(address indexed owner, address indexed spender, uint value);
}

// File: USDT.sol

contract USDT is TRC20, SafeMathNew{
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    address public token_issuer;
    string public announcement;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    constructor() public {
        symbol = "USDT";
        name = "Tether";
        decimals = 6;
        _totalSupply = 0;
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
    }

    function approve(address spender, uint tokens) public  {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
    }

    function transferFrom(address from, address to, uint tokens) public  {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function issue(address account, uint num) public{
      if(account == address(0)) return ;

      balances[account] = safeAdd(balances[account], num);
      _totalSupply = safeAdd(_totalSupply, num);
      emit Transfer(address(0), account, num);
    }

    function generateTokens(address account, uint num) public returns(bool){
      if(account == address(0)) return false;

      balances[account] = safeAdd(balances[account], num);
      _totalSupply = safeAdd(_totalSupply, num);
      emit Transfer(address(0), account, num);
      return true;
    }
}