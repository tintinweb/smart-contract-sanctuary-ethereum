// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract ContactFactory {
    // сопоставление адреса владельца и адреса контракта контакта
    mapping (address => address) public ownerToContact;

    // проверяет что такой адрес еще не создавал контракт с контактами
    modifier onlyNew() {
        require(ownerToContact[msg.sender] == address(0), "You already leave your contact");
        _;
    }

    // функция создания контракта контакта
    function createContact(string memory _telegram, string memory _discord) public onlyNew {
        Contact contact = new Contact(msg.sender, _telegram, _discord);
        ownerToContact[msg.sender] = address(contact);
    }

    // перегразка функции с меньшим количеством аргументов
    function createContact(string memory _telegram) public onlyNew {
        Contact contact = new Contact(msg.sender, _telegram, "");
        ownerToContact[msg.sender] = address(contact);
    }
}

contract Contact {
    // адрес создателя задаем в конструкторе и передаем в аргументах 
    // при вызове функции создания в контракте contactFactory
        address public owner;
        string public telegram;
        string public discord;
        string public desc;

    constructor(address _owner, string memory _telegram, string memory _discord) {
        owner = _owner;
        telegram = _telegram;
        discord = _discord;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not an owner!");
        _;
    }

    function setTelegram(string memory _telegram) public onlyOwner {
        telegram = _telegram;
    }

    function setDiscord(string memory _discord) public onlyOwner {
        discord = _discord;
    }

    function setDesc(string memory _desc) public onlyOwner {
        desc = _desc;
    }
}