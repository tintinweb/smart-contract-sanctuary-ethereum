/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;
 
// Версия MSHP 2.0 
// создан 20.06.2022

contract ERC20{
    // Адрес владельца контракта
    address owner;
    // Версия токена
    string public version = "MSHP 2.0";
    // Название токена
    string public name;
    // Символическое обозначение токена
    string public symbol;
    // Количество нулей в токене, например в ETH 18 нулей, 1 ETH = 1 000 000 000 000 000 000 wei
    uint8 public decimals;
    // Общее количество выпущенных токенов в "копейках"
    uint public totalSupply = 0;
 
    // Балансы аккаунтов
    mapping(address => uint) balances;
    // Словарь разрешений
    mapping(address => mapping(address => uint)) allowed;
 
    constructor(string memory _name, string memory _symbol, uint8 _decimals){
        owner = msg.sender;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }
 
    // События при трансфере токенов и изменении словаря разрешений
    event Transfer(address indexed form, address indexed  to, uint256 value);
    event Approval(address indexed form, address indexed spender, uint256 value);
 
    // Функция эмиссии
    // to - на какой адрес 
    // value - сколько зачислить токенов
    function mint(address to, uint value)public{
        // Проверка, что функцию вызывает хозяин контракта
        require(msg.sender == owner, "ERC20: You are not owner");
        // Изменяем общую эмиссию токенов
        totalSupply += value;
        // Изменяем количество токенов на адресе
        balances[to] += value;
        // Вызываем событие
        emit Transfer(address(0), to, value);
    }
 
    // Возвращает баланс адреса to
    function balanceOf(address to)public view returns(uint){
        return balances[to];
    }
 
    // Отправляет value копеек токена на адрес to
    function transfer(address to, uint value)public returns(bool){
        // Проверяем, что у отправителя есть достаточное количество токенов
        require(balances[msg.sender] >= value, "ERC20: not enough tokens");
        // Уменьшаем баланс отправителя
        balances[msg.sender] -= value;
        // Увеличиваем баланс получателя
        balances[to] += value;
        // Вызываем событие
        emit Transfer(msg.sender, to, value);
        // возвращаем true, если функция выполнена успешно
        return true;
    }
 
    // Отправляет value копеек токена с адреса from на адрес to
    function transferFrom(address from, address to, uint value)public returns(bool){
        // Проверяем, что у отправителя есть достаточное количество токенов        
        require(balances[from] >= value, "ERC20: not enough tokens");
        // Проверяем, что у msg.sender есть право потратить value токенов from
        require(allowed[from][msg.sender] >= value, "ERC20: no permission to spend");
        // Уменьшаем баланс отправителя        
        balances[from] -= value;
        // Увеличиваем баланс получателя
        balances[to] += value;
        // Уменьшаем количество токенов, которые разрешено тратить msg.sender с адреса from
        allowed[from][msg.sender] -= value;
        // Вызываем событие
        emit Transfer(from, to, value);
        emit Approval(from, to, allowed[from][msg.sender]);
        // возвращаем true, если функция выполнена успешно
        return true;
    }
 
    // Разрешение адресу spender тратить value токенов с адреса msg.sender
    function approve(address spender, uint256 value)public returns(bool){
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        // возвращаем true, если функция выполнена успешно
        return true;
    }
 
    // Функция показыает какое количество токенов разрешено тратить адресу spender с адреса from
    function allownce(address from, address spender) public view returns(uint){
        return allowed[from][spender];
    }
}