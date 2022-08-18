/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

abstract contract ERC20Interface {
    function totalSupply() public virtual view returns (uint);
    function balanceOf(address tokenOwner) public virtual view returns (uint balance);
    function allowance(address tokenOwner, address spender) public virtual view returns (uint remaining);
    function transfer(address to, uint tokens) public virtual returns (bool success);
    function approve(address spender, uint tokens) public virtual returns (bool success);
    function transferFrom(address from, address to, uint tokens) public virtual returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract CodeWithJoe is ERC20Interface{
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 private _totalSupply;
    address public owner;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() {
        name = "testu";
        symbol = "D113";
        decimals = 18;
        _totalSupply = 1000000000000000000000000000;
        owner = 0x35C3eE9Fb1Fc3CD5201eBdc1C9d37272b9993Ff2;
        balances[owner] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public override view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public override view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public override returns (bool success) {
        require(tokens<=balances[msg.sender]);
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transfer(address to, uint tokens) public override returns (bool success) {
        require(msg.sender == owner,"You are not the owner");
        require(balances[msg.sender] >= tokens);
        unchecked{balances[msg.sender] -= tokens;}
        unchecked{balances[to] += tokens;}
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        require(tokens <= allowed[from][msg.sender]);
        unchecked{balances[from] -= tokens;}
        unchecked{allowed[from][msg.sender] -= tokens;}
        unchecked{balances[to] += tokens;}
        emit Transfer(from, to, tokens);
        return true;
    }
}