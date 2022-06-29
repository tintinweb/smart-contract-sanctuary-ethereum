/**
 *Submitted for verification at Etherscan.io on 2022-06-29
*/

/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract HqToken {

    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 private _totalSupply;
    address public owner;

    mapping(address=>uint256) private _balances;
    mapping(address=>mapping(address=>uint256)) _allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _name, string memory _symbol, uint256 _decimals)  {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        owner = msg.sender;
    }
    function totalSupply() public view returns(uint256){
        return  _totalSupply;
    }
    function mint(address to, uint256 amount) public {
        require(to != address(0), "mint: mint to the zero address");
        _balances[to] += amount;
        _totalSupply += amount;
        emit Transfer(address(0),to,amount);

    }
    function balanceOf(address account) public view returns(uint256){
        return _balances[account];
    }
    function allowance(address account, address sender) public view returns(uint256){
        return _allowances[account][sender];
    }
    function approve(address spender, uint256 amount) public {
        require(spender != address(0), "approve: approve to the zero address");
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender,spender,amount);
    }

    function transfer(address to, uint256 amount) public returns(bool) {
        require(to != address(0), "transfer: transfer to the zero address");
        require(to != msg.sender, "transfer: can't transfer to yourself");
        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        emit Transfer(msg.sender,to,amount);
        return true;
    }
    function transferFrom(address from,address to, uint256 amount) public returns(bool) {
        require(to != address(0), "transferFrom: from can't zero address");
        require(to != address(0), "transferFrom: transfer to the zero address");
        require(to != from, "transferFrom:can't transfer to yourself");
        uint256 allowAmount = allowance(from,msg.sender);
        require(allowAmount >= amount, "from allow tranfer amount not enough");
        _balances[from] -= amount;
        _balances[to] += amount;
        _allowances[from][msg.sender] -= amount;
        emit Transfer(from,to,amount);
        return true;
    }
}