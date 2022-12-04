/**
 *Submitted for verification at Etherscan.io on 2022-12-04
*/

// SPDX-License-Identifier: GPL-3.0
 
pragma solidity 0.8.15;
 
interface IERC20 {
    // событие трансфера
    event Transfer(address indexed from, address indexed to, uint256 value);
    // событие разрешения
    event Approval(address indexed owner, address indexed spender, uint256 value);
    // возвращает имя токена
    function name() external view returns (string memory);
    // возвращает символ токена
    function symbol() external view returns (string memory);
    // возвращает количество нулей токена
    function decimals() external view returns (uint8);
    // возвращает общую эмиссию токена
    function totalSupply() external view returns (uint256);
    // возвращает баланс аккаунта по его адресу account
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
contract ERC20 is IERC20{
 
    // бщее количество выпущенных токенов в "копейках"
    uint256 _totalSupply;
    // адрес владельца контракта
    address _owner;
    // название токена
    string _name;
    // символическое обозначение токена
    string _symbol;
    // количество нулей в токене, например в ETH 18 нулей, 1 ETH = 1 000 000 000 000 000 000 wei
    uint8 _decimals;
    // балансы аккаунтов
    mapping(address => uint) balances;
    // словарь разрешений
    mapping(address => mapping(address => uint)) allowed;
 
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
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
    
    // возвращает баланс аккаунта по его адресу account
    function balanceOf(address account)public view returns(uint256) {
        return balances[account];
    }
 
    // возвращает количество токенов, которые spender может тратить с адреса owner
    function allowance(address owner, address spender) public view returns(uint256) {
        return allowed[owner][spender];
    }
    // Функция эмиссии
    // to - на какой адрес 
    // amount - сколько зачислить токенов
    function mint(address to, uint amount) public {
        // Проверка, что функцию вызывает хозяин контракта
        require(msg.sender == _owner, "ERC20: You are not owner");
        // Изменяем общую эмиссию токенов
        _totalSupply += amount;
        // Изменяем количество токенов на адресе
        balances[to] += amount;
        // Вызываем событие
        emit Transfer(address(0), to, amount);
    }
    // выдача адресу spender разрешения тратить amount токенов с адреса msg.sender
    function approve(address spender, uint256 amount) public returns(bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        // возвращаем true, если функция выполнена успешно
        return true;
    }
 
    // отправка amount токенов на адрес to с адреса msg.sender
    function transfer(address to, uint amount) public returns(bool) {
        // проверяем, что у отправителя msg.sender есть достаточное количество токенов
        require(balances[msg.sender] >= amount, "ERC20: not enough tokens");
        // уменьшаем баланс отправителя
        balances[msg.sender] -= amount;
        // увеличиваем баланс получателя
        balances[to] += amount;
        // вызываем событие
        emit Transfer(msg.sender, to, amount);
        // возвращаем true, если функция выполнена успешно
        return true;
    }
    // отправка amount токенов на адрес to с адреса from
    function transferFrom(address from, address to, uint amount) public returns(bool) {
        // проверяем, что у from есть достаточное количество токенов        
        require(balances[from] >= amount, "ERC20: not enough tokens");
        // проверяем, что у msg.sender есть право потратить amount токенов с баланса from
        require(allowed[from][msg.sender] >= amount, "ERC20: no permission to spend");
        // уменьшаем баланс отправителя        
        balances[from] -= amount;
        // увеличиваем баланс получателя
        balances[to] += amount;
        // уменьшаем количество токенов, которые msg.sender может потратить с адреса from
        allowed[from][msg.sender] -= amount;
        // вызываем события
        emit Transfer(from, to, amount);
        emit Approval(from, msg.sender, allowed[from][msg.sender]);
        // возвращаем true, если функция выполнена успешно
        return true;
    }
}