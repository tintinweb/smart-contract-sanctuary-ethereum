/**
 *Submitted for verification at Etherscan.io on 2022-11-25
*/

// SPDX-License-Identifier: GPL-3.0
 
pragma solidity 0.8.15;
 
interface IERC20 {

    // событие трансфера
    event Transfer(address indexed from, address indexed to, uint256 value);
    // событие изменения значения словаря разрешений
    event Approval(address indexed owner, address indexed spender, uint256 value);
    // возвращает имя токена
    function name() external view returns (string memory);
    // возвращает символ токена
    function symbol() external view returns (string memory);
    // возвращает количество нулей токена
    function decimals() external view returns (uint8);
    // возвращает общую эмиссию токена
    function totalSupply() external view returns (uint256);
    // возвращает баланс аккаунта по его адресу токена
    function balanceOf(address account) external view returns (uint256);
    // возвращает количество токенов, которые spender может тратить с адреса owner
    function allowance(address owner, address spender) external view returns (uint256);
    // выдача адресу spender разрешения тратить amount токенов с адреса msg.sender
    function approve(address spender, uint256 value) external returns (bool);
    // отправка amount токенов на адрес to с адреса msg.sender
    function transfer(address to, uint256 value) external returns (bool);
    // отправка amount токенов на адрес to с адреса from
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract ERC20 is IERC20{
 
    uint256 _totalSupply = 0;
    address _owner;
    string _name;
    string _symbol;
    uint8  _decimals;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor(string memory name_, string memory symbol_, uint8 decimals_){
        _owner = msg.sender;
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    // возвращает имя токена
    function name() public view returns (string memory) {
        return _name;
    }

    // возвращает символ токена
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    // возвращает количество нулей токена
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    // возвращает общую эмиссию токена
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // возвращает баланс аккаунта по его адресу токена
    function balanceOf(address account)public view returns(uint256){
        return balances[account];
    }

    // возвращает количество токенов, которые spender может тратить с адреса owner
    function allowance(address owner, address spender) public view returns(uint256) {
        return allowed[owner][spender];
    }

    // Функция эмиссии
    // to - на какой адрес 
    // value - сколько зачислить токенов
    function mint(address to, uint value) public {
        require(msg.sender == _owner, "ERC20: You are not owner");
        _totalSupply += value;
        balances[to] += value;
        emit Transfer(address(0), to, value);
    }
 
    // выдача адресу spender разрешения тратить value токенов с адреса msg.sender
    function approve(address spender, uint256 value) public returns(bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    // отправка value токенов на адрес to с адреса msg.sender
    function transfer(address to, uint value)public returns(bool) {
        require(balances[msg.sender] >= value, "ERC20: not enough tokens");
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
 
    // отправка value токенов на адрес to с адреса from
    function transferFrom(address from, address to, uint value)public returns(bool) {
        require(allowed[from][msg.sender] >= value, "ERC20: no permission to spend");
        require(balances[from] >= value, "ERC20: not enough tokens");
        balances[from] -= value;
        balances[to] += value;
        allowed[from][msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        emit Approval(from, msg.sender, allowed[from][msg.sender]);
        return true;
    }
}