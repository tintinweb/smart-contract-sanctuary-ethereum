/**
 *Submitted for verification at Etherscan.io on 2022-07-06
*/

pragma solidity 0.8.4;
//SPDX-License-Identifier: MIT License;

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; 
    } 
    
    function safeMul(uint a, uint b) public pure returns (uint c) 
    { 
        c = a * b; require(a == 0 || c / a == b); 
    }
    
    function safeDiv(uint a, uint b) public pure returns (uint c) { 
        require(b > 0);
        c = a / b;
    }
}


contract ak_token is SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() {
        name = "ak75";
        symbol = "abk";
        decimals = 4;
        _totalSupply = 100000000000;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    function totalSupply() external view  returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) external   view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) external  view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function transfer(address to, uint tokens) external  returns (bool success) {
        balances[msg.sender] = balances[msg.sender] - tokens;
        balances[to] = balances[to]+ tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address owner, address buyer, uint tokens) public returns (bool) {
        require(tokens <= balances[owner]);
        require(tokens <= allowed[owner][msg.sender]);

        balances[owner] -= tokens;
        allowed[owner][msg.sender] -= tokens;
        balances[buyer] += tokens;
        emit Transfer(owner, buyer, tokens);
        return true;
    }
}