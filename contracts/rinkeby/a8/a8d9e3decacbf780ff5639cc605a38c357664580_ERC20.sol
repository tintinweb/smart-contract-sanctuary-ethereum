/**
 *Submitted for verification at Etherscan.io on 2022-02-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;


interface IERC20 {

     function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(address sender,address recipient,uint amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

// ----------------------------------------------------------------------------
// Safe Math Library
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
    }
}

contract ERC20 is IERC20, SafeMath{

    string public name;
    string public symbol;
    uint8 public decimals; // decimals means how many zeros to use to repersent one ERC20 token, so 10 to the power 18 means one RTEST token.
    uint public _totalSupply;
    mapping(address => uint) public _balanceOf;
    mapping(address => mapping(address => uint)) public _allowance;

    constructor(){
        name = "RTest";
        symbol = "RTEST";
        decimals = 18;
        _totalSupply = 10 ** decimals;
        _balanceOf[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    function totalSupply() external view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint) {
        return _balanceOf[account];
    }


    function transfer(address recipient, uint amount) external returns (bool) {
        _balanceOf[msg.sender] = safeSub(_balanceOf[msg.sender], amount);
        _balanceOf[recipient] = safeAdd(_balanceOf[recipient], amount);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint){
        return _allowance[owner][spender];
    }

    function approve(address spender, uint amount) external returns (bool){
        _allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool){
        _allowance[sender][msg.sender] = safeSub(_allowance[sender][msg.sender], amount);
        _balanceOf[sender] = safeSub(_balanceOf[sender], amount) ;
        _balanceOf[recipient] = safeSub(_balanceOf[recipient], amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    // here mint function work is to create new token.
    function mint(uint amount) external {
        _balanceOf[msg.sender] += amount;
        _totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount); // this line code means, from address(0) transfer over to msg.sender for that amount.
    }

    // here burn function work is to destroy existing token from the circulation
    function burn(uint amount) external {
        _balanceOf[msg.sender] -= amount;
        _totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}