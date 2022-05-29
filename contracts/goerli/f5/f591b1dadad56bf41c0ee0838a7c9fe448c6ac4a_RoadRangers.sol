/**
 *Submitted for verification at Etherscan.io on 2022-05-29
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    
    function name() external view returns(string memory);
    //название монеты

    function symbol() external view returns(string memory);
    // сокращение названия монеты  

    function decimals() external pure returns(uint);
    //кол-во символов (стандарт 18)

    function totalSupply() external view returns(uint);
    //Общий суплай монет (сколько всего монет существует)

    function balanceOf(address account) external view returns(uint);
    //функция для свободной проверки баланса наших токенов на любом кошельке

    function transfer(address to, uint amount) external;
    //функция для отправки токенов (в эфире она по умолчанию есть, но наш токен не эфир, поэтому прописываем)

    function allowance(address _owner, address spender) external view returns(uint);
     // функция предназначена для того, чтобы мы, как владельцы кошелька разрешали забирать у нас часть токенов (допустим, для продажи).

    function approve(address spender, uint amount) external;
    //функция аппрува(подтверждения)

    function transferFrom(address sender, address recipient, uint amount) external;
    //функция, которая непосредственно списывает токены с моего кошелька в чью-то пользу

    event Transfer(address indexed from, address indexed to, uint amount);
    //событие перевода токенов (по "indexed" можно будет осуществлять поиск в журнале)

    event Approve(address indexed owner, address indexed to, uint amout);
    //событие подтверждения перевода токенов (от создателя, куда и количество)
}

contract ERC20 is IERC20 {
    //делаем наследование библиотеки в этот контракт
    uint totalTokens;
    //переменная общего количества монет
    address owner;
    //прописываем главный кошелек
    mapping(address => uint) balances;
    //здесь мы сможем вести учет (у кошелька "а" такое кол-во токенов, у кошелька "b" другое кол-во токенов)
    mapping(address => mapping(address => uint)) allowances;
    /*здесь мы будем хранить информацию о том, что с кошелька "а" можно списать какое то количество токенов в пользу кошелька "b"
     (сделано для будущей продажи токенов)*/
    string _name;
    string _symbol;
    // cтроки названия и символа токена
    
    function name() external view returns(string memory) {
        return _name; //возвращаем название
    }

    function symbol() external view returns(string memory) {
        return _symbol; //возвращаем символ
    }

    function decimals() external pure returns(uint) {
        return 18; //возвращаем количество знаков после запятой (по стандарту 18)
    }

    function totalSupply() external view returns(uint) {
        return totalTokens; // возвращаем общее количество монет (тотал саплай)
    }

   
    modifier enoughTokens(address _from, uint _amount) {
        require(balanceOf(_from) >= _amount, "not enough tokens!");
        _;
    }
    //модификатор для проверки наличия достаточного количества токенов для перевода

    modifier onlyOwner() {
        require(msg.sender == owner, "not an owner!");
        _; 
    }
    //модификатор владельца токена

    constructor(string memory name_, string memory symbol_, uint initialSupply, address shop) {
        _name = name_;
        _symbol = symbol_;
        //cохраняем имя и мимвол

        owner = msg.sender;
        //сохраняем владельца
        
        mint(initialSupply, shop);
        //вводим токены в оборот
    }

     function balanceOf(address account) public view returns(uint) {
         return balances[account]; //функция возвращает баланс
    }

    function transfer(address to, uint amount) external enoughTokens(msg.sender, amount) {
        _beforeTokenTransfer(msg.sender, to, amount);
        balances[msg.sender] -= amount;
        //здесь мы забираем токены у отправителя
        balances[to] += amount;
        //а здесь мы добавляем токенов получателю
        emit Transfer(msg.sender, to, amount);
        //выполняем событие перевода (от отправителя к получателю)
    }

    function mint(uint amount, address shop) public onlyOwner {
        //функция создания монет. сколько вводим и куда отправляем
        _beforeTokenTransfer(address(0), shop, amount);
        balances[shop] += amount;
        //начисление токенов на баланс магазина (balances[shop])
        totalTokens += amount;
        //соответстенно необходимо увеличить и общее количество токенов (тотал саплай)
        emit Transfer(address(0), shop, amount);
        //выполняем событие перевода (от нулевого адреса в магазин)

    }

    function burn(address _from, uint amount) public onlyOwner {
        _beforeTokenTransfer(_from, address(0), amount);
        balances[_from] -= amount;
        totalTokens -= amount;
    }
    //Функция сжигания токенов

    function allowance(address _owner, address spender) public view returns(uint) {
        return allowances[_owner][spender];
    }
    //функция проверки, может ли сторонний аккаунт списать с моего кошелька токены в чью-то пользу

    function approve(address spender, uint amount) public {
        _approve(msg.sender, spender, amount);

    }

    function _approve(address sender, address spender, uint amount) internal virtual {
        allowances[sender][spender] = amount;
        emit Approve(sender, spender, amount);
    }

    function transferFrom(address sender, address recipient, uint amount) public enoughTokens(sender, amount) {
        _beforeTokenTransfer(sender, recipient, amount);
        //require(allowances[sender][recipient] >= amount, "check allowance!"); //доп проверка, что sender разрешил recipient забрать токены.
        allowances[sender][recipient] -= amount;
        balances[sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint amount) internal virtual {

    }
    // перед переводом токена, если необходимо перед этим сделать какую либо операцию с токеном, то эту операцию мы кладем сюда


}

contract RoadRangers is ERC20 {
    constructor(address shop) ERC20("RoadRangers","RR", 300000000000000000000000000, shop) {}
}

contract RRShop {
    IERC20 public token;
    address payable public owner;
    event Bought(uint _amount, address indexed _buyer);
    event Sold(uint _amount, address indexed _seller);

    constructor() {
        token = new RoadRangers(address(this));
        owner = payable(msg.sender);
    }

     modifier onlyOwner() {
        require(msg.sender == owner, "not an owner!");
        _; 
    }

    function sell(uint _amountToSell) external {
        require(
            _amountToSell > 0 &&
            token.balanceOf(msg.sender) >= _amountToSell,
            "incorrect amount!"
        );

        uint allowance = token.allowance(msg.sender, address(this));
        require(allowance >= _amountToSell, "check allowance!");
        // верхние 2 строчки проверяют, разрешил ли клиент забрать свои токены магазину перед продажей

        token.transferFrom(msg.sender, address(this), _amountToSell);
        payable(msg.sender).transfer(_amountToSell);

        emit Sold(_amountToSell, msg.sender);

    }

    receive() external payable {
        uint tokensToBuy = msg.value;
        require(tokensToBuy > 0, "not enough funds!");
        require(tokenBalance() >= tokensToBuy, "not enough tokens!");

        token.transfer(msg.sender, tokensToBuy);
        emit Bought(tokensToBuy, msg.sender);

    }

    function tokenBalance() public view returns(uint) {
        return token.balanceOf(address(this));
    }

    
}