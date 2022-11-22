//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Transfers
{
    struct Transfer
    {
        uint amount;
        uint timestamp;
        address sender;
    }

    Transfer[] transfers;//трансферы

    address owner; //владелец смарт-контракта
    //uint8 maxTransfers; //максимальное количество трасферов
    uint8 currentTransfers;

    //максимальное количество трансферов задается при деплое контракта
    //constructor(uint8 _maxTransfers)
    constructor()
    {
        owner = msg.sender; //адрес, который развернул смарт-контракт
        //maxTransfers = _maxTransfers;
    }

    //вытаскиваем по индексу конкретный трансфер из массива трансферов
    //проверяем, не превысило ли количество трансферов заданного максимального числа
    function getTransfer(uint _index) public view returns(Transfer memory)
    {
        require(_index < transfers.length, "Cannot find this transfer");
        return transfers[_index];
    }
    //модификатор, который проверяет, является ли аккаунт владельцем смарт-контракта
    modifier requireOwner()
    {
        require(owner == msg.sender, "Not an owner");
        _;
    }
    //функция вывода денежных средств из смарт-контракта
    //проверка, является ли тот кто выводит - владельцем контракта
    function withdrawTo(address payable _to) public requireOwner
    {
        if (owner == _to)
            _to.transfer(address(this).balance);
        else
            revert("You are not an owner");
        
    }

    //вызовется автоматически, если в контракт придет транзакция
    //без указания функции но с денежными средствами
    //проверяем не превысило ли количество транзакций предельно допустимого
    receive() external payable
    {
        //if (currentTransfers >= maxTransfers)
        //{
        //    revert("Cannot accept more transfers");
        // }
        //инициализируем запись трансфера
        Transfer memory newTransfer = Transfer(msg.value, block.timestamp, msg.sender);
        transfers.push(newTransfer); //добавляем новый транфер в массив
        currentTransfers++;

    }

}