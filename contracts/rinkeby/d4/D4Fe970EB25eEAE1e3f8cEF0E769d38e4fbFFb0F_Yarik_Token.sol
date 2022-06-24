/**
 *Submitted for verification at Etherscan.io on 2022-06-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

contract Yarik_Token {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address private _owner;

    constructor() {
        _owner = msg.sender;
        _balances[_owner] = _totalSupply;
    }

    string private constant _name = "YARIK TOKEN";
    string private constant _symbol = "YARIK";
    uint8 private constant _decimals = 18;
    uint private _totalSupply = 1000 * 10 ** _decimals;

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view returns (uint) {
        return _balances[owner];
    }

    function allowance(address owner, address spender) public view returns (uint) {
        return _allowances[owner][spender];
    }

    function transfer(address to, uint value) public returns (bool success) {
        address sender = msg.sender;

        _transfer(sender, to, value);
        success = true;
    }

    function transferFrom(address from, address to, uint value) public returns (bool success) {
        address sender = msg.sender;
        require(_allowances[from][sender] >= value, "You don't have permission to send so many tokens");
        require(sender != from, "Use transfer function, instead of transferFrom");

        _transfer(from, to, value);

        _allowances[from][sender] -= value;
        success = true;
    }

    function approve(address spender, uint value) public returns (bool success) {
        address owner = msg.sender;

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
        success = true;
    }

    function burn(address account, uint amount) public CalledByOwner() {
        require(_balances[account] >= amount, "The account does not have enough tokens");

        _balances[account] -= amount;
        _totalSupply -= amount;
    }

    function mint(address account, uint amount) public CalledByOwner() {
        _balances[account] += amount;
        _totalSupply += amount;
    }

    function _transfer(address from, address to, uint value) private {
        require(_balances[from] >= value, "Sender does not have enough tokens");
        require(from != to, "There is no point in sending tokens to yourself");

        _balances[from] -= value;
        _balances[to] += value;

        emit Transfer(from, to, value);
    }

    event Transfer(address from, address to, uint value);
    event Approval(address owner, address spender, uint value);

    modifier CalledByOwner() {
        require(msg.sender == _owner, "Only owner can call this function");
        _;
    }
}