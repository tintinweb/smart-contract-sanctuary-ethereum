/**
 *Submitted for verification at Etherscan.io on 2022-03-30
*/

pragma solidity 0.5.7;
// SPDX-License-Identifier: MIT

contract ERC20Interface {
   }
// ----------------------------------------------------------------------------
// Safe Math Library
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
    }
}


contract ONELOVE is ERC20Interface, SafeMath {
    bytes32 public name= "ONELOVE";
    bytes32 public symbol = "ONE";
    uint8 public decimals = 2; 
    uint256 public _totalSupply = 100000000000;
    

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);


    constructor() public {
    balances[msg.sender] = _totalSupply;
    emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
}