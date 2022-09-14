/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

// SPDX-License-Identifier: MIT
/*

Token Name: Evil Druid
Ticker: Elusive
Supply: 1,000,000,000
tax 0/0 community token

*/


pragma solidity 0.8.14;

interface IERC20
{
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IERC20Metadata is IERC20
{
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface erc20 is IERC20Metadata
{
    function decreaseAllowance(address spender, uint256 amount) external returns (bool);
    function increaseAllowance(address spender, uint256 amount) external returns (bool);

    function mint(address account, uint256 amount) external returns (bool);
    function burn(address account, uint256 amount) external returns (bool);
}

contract SmartContract is erc20
{
    address private _owner;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowed;

    constructor(string memory _name_, string memory _symbol_, uint8 _decimals_, uint256 _totalSupply_)
    {
        _owner = msg.sender;
        _name = _name_;
        _symbol = _symbol_;
        _decimals = _decimals_;
        _totalSupply = _totalSupply_ * (10 ** _decimals);

        _balance[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
    }

    function name() external view returns (string memory)
    {
        return _name;
    }

    function symbol() external view returns (string memory)
    {
        return _symbol;
    }

    function decimals() external view returns (uint8)
    {
        return _decimals;
    }

    function totalSupply() external view returns (uint256)
    {
        return _totalSupply;
    }

    function balanceOf(address owner) external view returns (uint256)
    {
        return _balance[owner];
    }

    function transfer(address recipient, uint256 amount) external returns (bool)
    {
        require(_balance[msg.sender] > 0, "Zero Balance!");
        require(_balance[msg.sender] >= amount, "Low Balance!");
        _balance[msg.sender] -= amount;
        _balance[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256)
    {
        return _allowed[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool)
    {
        _allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function decreaseAllowance(address spender, uint256 amount) external returns (bool)
    {
        require(_allowed[msg.sender][spender] >= amount, "Allowance Can't be less than Zero!");
        _allowed[msg.sender][spender] -= amount;
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function increaseAllowance(address spender, uint256 amount) external returns (bool)
    {
        _allowed[msg.sender][spender] += amount;
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool)
    {
        require(_allowed[sender][msg.sender] > 0, "Zero Allowance!");
        require(_allowed[sender][msg.sender] >= amount, "Low Allowance!");
        require(_balance[sender] > 0, "Zero Balance!");
        require(_balance[sender] >= amount, "Low Balance!");
        _allowed[sender][msg.sender] -= amount;
        _balance[sender] -= amount;
        _balance[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    modifier onlyOwner
    {
        require(msg.sender == _owner, "Permission Denied, You're not the Owner!");
        _;
    }

    function burn(address account, uint256 amount) onlyOwner external returns (bool)
    {
        require(_balance[account] > 0, "Zero Balance!");
        require(_balance[account] >= amount, "Low Balance!");
        _totalSupply -= amount;
        _balance[account] -= amount;
        emit Transfer(account, address(0), amount);
        return true;
    }

    function mint(address account, uint256 amount) onlyOwner external returns (bool)
    {
        _totalSupply += amount;
        _balance[account] += amount;
        emit Transfer(address(0), account, amount);
        return true;
    }
}