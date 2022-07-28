/**
 *Submitted for verification at Etherscan.io on 2022-07-27
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
    function approve(address spender, uint256 amount) external returns (bool);
    // отправка amount токенов на адрес to с адреса msg.sender
    function transfer(address to, uint256 amount) external returns (bool);
    // отправка amount токенов на адрес to с адреса from
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}


interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

contract ERC20 is IERC20, ERC165{
    // Адрес владельца контракта
    address tOwner;
    // Название токена
    string tName;
    // Символическое обозначение токена
    string tSymbol;
    // Количество нулей в токене, например в ETH 18 нулей, 1 ETH = 1 000 000 000 000 000 000 wei
    uint8 tDecimals;
    // Общее количество выпущенных токенов в "копейках"
    uint tTotalSupply;
 
    // Балансы аккаунтов
    mapping(address => uint) balances;
    // Словарь разрешений
    mapping(address => mapping(address => uint)) allowed;
 
    constructor(string memory _tName, string memory _tSymbol, uint8 _tDecimals){
        tOwner = msg.sender;
        tName = _tName;
        tSymbol = _tSymbol;
        tDecimals = _tDecimals;
    }
 
    // возвращает имя токена
    function name() public view override returns (string memory){
        return tName;
    }
    // возвращает символ токена
    function symbol() public view override returns (string memory){
        return tSymbol;
    }
    // возвращает количество нулей токена
    function decimals() public view override returns (uint8){
        return tDecimals;
    }
    // возвращает общую эмиссию токена
    function totalSupply() public view override returns (uint256){
        return tTotalSupply;
    }
    // возвращает баланс аккаунта по его адресу токена
    function balanceOf(address account)public view override returns(uint256){
        return balances[account];
    }
    // возвращает количество токенов, которые spender может тратить с адреса owner
    function allowance(address owner, address spender) public view override returns(uint256){
        return allowed[owner][spender];
    }

    // Функция эмиссии
    // to - на какой адрес 
    // value - сколько зачислить токенов
    function mint(address to, uint amount) public {
        // Проверка, что функцию вызывает хозяин контракта
        require(msg.sender == tOwner, "ERC20: You are not owner");
        // Изменяем общую эмиссию токенов
        tTotalSupply += amount;
        // Изменяем количество токенов на адресе
        balances[to] += amount;
        // Вызываем событие
        emit Transfer(address(0), to, amount);
    }
 
    // выдача адресу spender разрешения тратить amount токенов с адреса msg.sender
    function approve(address spender, uint256 amount) public override returns(bool){
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        // возвращаем true, если функция выполнена успешно
        return true;
    }

    // отправка amount токенов на адрес to с адреса msg.sender
    function transfer(address to, uint amount)public override returns(bool){
        // Проверяем, что у отправителя есть достаточное количество токенов
        require(balances[msg.sender] >= amount, "ERC20: not enough tokens");
        // Уменьшаем баланс отправителя
        balances[msg.sender] -= amount;
        // Увеличиваем баланс получателя
        balances[to] += amount;
        // Вызываем событие
        emit Transfer(msg.sender, to, amount);
        // возвращаем true, если функция выполнена успешно
        return true;
    }
 
    // отправка amount токенов на адрес to с адреса from
    function transferFrom(address from, address to, uint amount)public override returns(bool){
        // Проверяем, что у отправителя есть достаточное количество токенов        
        require(balances[from] >= amount, "ERC20: not enough tokens");
        // Проверяем, что у msg.sender есть право потратить value токенов from
        require(allowed[from][msg.sender] >= amount, "ERC20: no permission to spend");
        // Уменьшаем баланс отправителя        
        balances[from] -= amount;
        // Увеличиваем баланс получателя
        balances[to] += amount;
        // Уменьшаем количество токенов, которые разрешено тратить msg.sender с адреса from
        allowed[from][msg.sender] -= amount;
        // Вызываем событие
        emit Transfer(from, to, amount);
        emit Approval(from, to, allowed[from][msg.sender]);
        // возвращаем true, если функция выполнена успешно
        return true;
    }
 
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC20).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}