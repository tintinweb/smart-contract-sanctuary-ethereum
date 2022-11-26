/**
 *Submitted for verification at Etherscan.io on 2022-11-26
*/

// SPDX-License-Identifier: GPL-3.0
 
pragma solidity 0.8.15;
 
interface iMyFirstToken {

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
    function approve(address spender, uint256 amount) external returns (bool);
    // отправка amount токенов на адрес to с адреса msg.sender
    function transfer(address to, uint256 amount) external returns (bool);
    // отправка amount токенов на адрес to с адреса from
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract MyFirstToken is iMyFirstToken{
    uint256 _totalSupply;
    address _owner;
    string _name;
    string _symbol;
    uint8 _decimals;
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowed;

    constructor(){
        _name = "MyFirstToken";
        _symbol = "MFT";
        _decimals = 4;
        _owner = msg.sender;
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
        return _balances[account];
    }

    // возвращает количество токенов, которые spender может тратить с адреса owner
    function allowance(address owner, address spender) public view returns(uint256) {
        return _allowed[owner][spender];
    }

    // Функция эмиссии
    // to - на какой адрес 
    // value - сколько зачислить токенов
    function mint(address to, uint amount) public {
        require(msg.sender == _owner, "ERC20: You are not owner");
        _balances[to] += amount;
        _totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }
 
    // выдача адресу spender разрешения тратить amount токенов с адреса msg.sender
    function approve(address spender, uint256 amount) public returns(bool) {
        _allowed[msg.sender][spender] += amount;
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    // отправка amount токенов на адрес to с адреса msg.sender
    function transfer(address to, uint amount) public returns(bool) {
        require(_balances[msg.sender] >= amount, "ERC20: not enough tokens");
        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }
 
    // отправка amount токенов на адрес to с адреса from
    function transferFrom(address from, address to, uint amount) public returns(bool) {
        require(_allowed[from][to] >= amount, "ERC20: not enough tokens");
        _allowed[from][to] -= amount;
        _balances[to] += amount;
        _balances[from] -= amount;
        emit Transfer(from, to, amount);
        emit Approval(from, to, _allowed[from][to]);
        return true;
    }
}