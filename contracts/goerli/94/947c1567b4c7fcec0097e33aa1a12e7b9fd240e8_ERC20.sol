/**
 *Submitted for verification at Etherscan.io on 2023-01-26
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract ERC20 is IERC20 {

    uint256 _totalSupply;
    address _owner;
    string _name;
    string _symbol;
    uint8 _decimals;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor(string memory __name, string memory __symbol, uint8 __decimals) {
        _owner = msg.sender;
        _name = __name;
        _symbol = __symbol;
        _decimals = __decimals;
    }

    function mint(address to, uint256 value) public {
        require(msg.sender == _owner, "ERC20: You are not owner");
        _totalSupply += value;
        balances[to] += value;
        emit Transfer(address(0), to, value);
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(balances[msg.sender] >= value, "ERC20: not enough tokens");
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(balances[from] >= value, "ERC20: not enough tokens");
        require(allowed[from][msg.sender] >= value, "ERC20: no permission to spend");
        balances[from] -= value;
        balances[to] += value;
        allowed[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        emit Approval(from, msg.sender, allowed[from][msg.sender]);
        return true;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }
}