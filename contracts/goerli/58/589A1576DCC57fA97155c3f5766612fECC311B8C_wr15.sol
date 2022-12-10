/**
 *Submitted for verification at Etherscan.io on 2022-12-10
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

contract wr15 is IERC20{
    address _owner;
    uint256 _totalSupply;
    string _name;
    string _symbol;
    uint8  _decimals;
    address public staking;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    constructor(string memory name, string memory symbol, uint8 decimals) {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _owner = msg.sender;
    }

    // возвращает имя токена
    function name() public view returns (string memory) {
        return(_name);
    }

    // возвращает символ токена
    function symbol() public view returns (string memory) {
        return(_symbol);
    }

    // возвращает количество нулей токена
    function decimals() public view returns (uint8) {
        return(_decimals);
    }

    // возвращает общую эмиссию токена
    function totalSupply() public view returns (uint256) {
        return(_totalSupply);
    }

    // возвращает баланс аккаунта по его адресу токена
    function balanceOf(address account)public view returns(uint256){ return (account.balance);}

    // возвращает количество токенов, которые spender может тратить с адреса owner
    function allowance(address owner, address spender) public view returns(uint256) {
        return (allowed[owner][spender]);
    }

    // Функция эмиссии
    // to - на какой адрес 
    // value - сколько зачислить токенов
    function mint(address to, uint amount) public {
        require(msg.sender == _owner || msg.sender == staking, "ERC20: You are not owner");
        _totalSupply+=amount;
        balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }
    
    function setStaking(address _staking) public{
        require(msg.sender == _owner, "ERC20: You are not owner");
        staking = _staking;
    }
    // выдача адресу spender разрешения тратить amount токенов с адреса msg.sender
    function approve(address spender, uint256 amount) public returns(bool) {
        allowed[msg.sender][spender] = amount;
        return true; 
    }

    // отправка amount токенов на адрес to с адреса msg.sender
    function transfer(address to, uint amount)public returns(bool) {
        require(msg.sender.balance >= amount, "ERC20: not enough tokens");
        balances[msg.sender]-=amount;
        balances[to]+=amount;
        return true;
    }
 
    // отправка amount токенов на адрес to с адреса from
    function transferFrom(address from, address to, uint amount)public returns(bool) {
        require(from.balance >= amount, "ERC20: not enough tokens");
        require(allowed[msg.sender][from] >= amount, "ERC20: no permission to spend");
        balances[from]-=amount;
        balances[to]+=amount;
        allowed[from][msg.sender]-=amount;
        emit Approval(from, msg.sender, allowed[from][msg.sender]);
        emit Transfer(from, to, amount);
        return true;
    }
}