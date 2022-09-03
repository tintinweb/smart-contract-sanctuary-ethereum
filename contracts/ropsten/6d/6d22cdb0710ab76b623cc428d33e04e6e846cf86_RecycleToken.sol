/**
 *Submitted for verification at Etherscan.io on 2022-09-02
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
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
//=========================================================================================================================
contract RecycleToken is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; 
    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    /**
     * Constrctor function
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        name = "RecycleToken";
        symbol = "RCT";
        decimals = 18;
        _totalSupply = 1000000 * 10**18;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint _amount) public returns (bool success) {
        allowed[msg.sender][spender] = _amount;
        emit Approval(msg.sender, spender, _amount);
        return true;
    }

    function transfer(address to, uint _amount) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], _amount);
        balances[to] = safeAdd(balances[to], _amount);
        emit Transfer(msg.sender, to, _amount);
        return true;
    }

    function transferFrom(address from, address to, uint _amount) public returns (bool success) {
        balances[from] = safeSub(balances[from], _amount);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], _amount);
        balances[to] = safeAdd(balances[to], _amount);
        emit Transfer(from, to, _amount);
        return true;
    }

    //--------------------------------------------------------------------------------------------------------
    function sendToken(address _from, address _to, uint _amount) public returns (bool success) {
        require(balances[_from] >= _amount, "Not enough tokens");
        balances[_from]  = safeSub(balances[_from], _amount);
        balances[_to] = safeAdd(balances[_to], _amount);
        return true;

    }
}