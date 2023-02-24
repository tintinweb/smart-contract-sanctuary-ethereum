/**
 *Submitted for verification at Etherscan.io on 2023-02-24
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------
interface ERC20Interface {
    function totalSupply() external view returns (uint256);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) external view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) external returns (bool success);
    function approve(address spender, uint256 tokens) external returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

// ----------------------------------------------------------------------------
// Safe Math Library
// ----------------------------------------------------------------------------
library SafeMath {
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a, "SafeMath: addition overflow");
    }
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a, "SafeMath: subtraction overflow"); 
        c = a - b; 
    } 
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256 c) { 
        c = a * b; 
        require(a == 0 || c / a == b, "SafeMath: multiplication overflow"); 
    } 
    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256 c) { 
        require(b > 0, "SafeMath: division by zero");
        c = a / b;
    }
}


contract Skyocean is ERC20Interface {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it

    uint256 private _totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowed;

    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() {
        name = "Skyocean";
        symbol = "SKYT";
        decimals = 16;
        _totalSupply = 10000000000000000000000000;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view override returns (uint256) {
    return _totalSupply.safeSub(_balances[address(0)]);
    }


    function balanceOf(address tokenOwner) public view override returns (uint256 balance) {
        return _balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view override returns (uint256 remaining) {
        return _allowed[tokenOwner][spender];
    }

    function approve(address spender, uint256 tokens) public override returns (bool success) {
        _allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transfer(address to, uint256 tokens) public override returns (bool success) {
        _balances[msg.sender] = _balances[msg.sender].safeSub(tokens);
        _balances[to] = _balances[to].safeAdd(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true; 
    }

    function transferFrom(address from, address to, uint256 tokens)
     public returns (bool success) {
    require(tokens <= _allowed[from][msg.sender], "Transfer amount exceeds allowance");
    require(_balances[from] >= tokens, "Insufficient balance");

    _balances[from] = _balances[from].safeSub(tokens);
    _allowed[from][msg.sender] = _allowed[from][msg.sender].safeSub(tokens);
    _balances[to] = _balances[to].safeAdd(tokens);
    emit Transfer(from, to, tokens);
    return true;
}
}