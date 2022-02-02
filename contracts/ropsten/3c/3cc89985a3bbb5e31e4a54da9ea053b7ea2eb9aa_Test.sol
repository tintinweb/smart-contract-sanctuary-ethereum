/**
 *Submitted for verification at Etherscan.io on 2022-02-02
*/

/*
Задача №6:
Работа со структурами. Написать контракт для изменения значений полей структуры.
Пусть это будет массив структур. Сделать функционал для добавления новых элементов массива
и вывода содержимого n-го элемента (сразу всех полей структуры).
Добавить в контракт из задачи 5 функционал такой, чтобы одно из полей было типа enum.
*/

pragma solidity ^0.8.11;

contract Test {
    address payable public owner;

    event DepositInfo(address indexed _from, address indexed _to, uint256 _amount); // информация о пополнениях
    event WithdrawInfo(address indexed _from, address indexed _to, uint256 _amount); // информация о выводе
    event BlockInfo(address target, uint value, uint time, string reason); // информация о блокировке счет

    enum Status {Empty, Active, Blocked}
    /*
    Empty - депозит пуст
    Active - использование депозита разрешено
    Blocked - использование депозита запрещено
    */

    struct Holder {
        address holder;
        uint balance;
        bool valid;
        Status status;
    }

    Holder[] public holdersList;

    receive() external payable {}
    fallback() external {}

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOnwer {
        require(msg.sender == owner, "You are not a contract owner");
        _;
    }

    modifier onlyHolder(address _holder) {
        uint id = searchHolder(_holder);
        require(holdersList[id].holder == msg.sender, "You are not deposit owner");
        _;
    }

    modifier checkBalance(address _holder, uint _amount) {
        uint id = searchHolder(_holder);
        require(holdersList[id].balance >= _amount, "Incorrect amount");
        _;
    }

    // в случае блокировки не позволит вывести с депозита
    modifier blockCheck(address _target) {
        uint id = searchHolder(_target);
        if (holdersList[id].status == Status.Blocked) {
            revert("Deposit is blocked");
        }
        _;
    }

    // функция пополнения

    function deposit() public payable {
        payable(address(this)).send(msg.value);
        holdersList.push(Holder(msg.sender, msg.value, true, Status.Active));
        emit DepositInfo(msg.sender, address(this), msg.value);
    }

    // функция вывода для владельца
    function withdraw(uint amount) external onlyOnwer {
        if (address(this).balance > amount) {
            revert("Incorrect amount");
        }
        payable(msg.sender).transfer(amount);
        // payable(msg.sender).transfer(address(this).balance); выведем весь ETH с контракта
    }

    // функция вывода
    function withdrawHolder(address payable recipient, uint value) public payable
        onlyHolder(recipient)
        checkBalance(recipient, value)
        blockCheck(recipient)
    {   
        recipient.send(value);

        uint id = searchHolder(recipient);
        holdersList[id].balance -= value; // изменяем значение баланса
        if (holdersList[id].balance == 0) {
            holdersList[id].status = Status.Empty; // если баланс кошелька 0, обозначаем его как пустой
        }
        emit WithdrawInfo(address(this), recipient, value);
    }

    function getBalance() public view onlyOnwer returns (uint) {
        return address(this).balance;
    }

    // функция поиска индекса депозита по введенному адресу
    function searchHolder(address current) public view returns (uint id) {
        for (uint i = 0; i < holdersList.length; i++) {
            if (holdersList[i].holder == current) {
                id = i;
            }
            else {
                revert("Deposit of the desired holder was not found");
            }
        }
        return id;
    }

    // функция для вывода всех полей структуры в массиве на основе введенного адреса
    function getDepositInfo(address current) public view onlyOnwer onlyHolder(current) returns (
        address holder,
        uint balance,
        bool validation,
        Status _status
    )
    {
        uint id = searchHolder(current);
        holder = holdersList[id].holder;
        balance = holdersList[id].balance;
        validation = holdersList[id].valid;
        _status = holdersList[id].status;
    }

    // функция для вывода всех полей структуры по индексу в массиве
    function getDepositInfo2(uint id) public view onlyOnwer returns (
        address holder,
        uint balance,
        bool validation,
        Status _status
    )
    {
        if (id >= holdersList.length) {
            revert("Incorrect id, use *searchHolder* function");
        }
        else {
            holder = holdersList[id].holder;
            balance = holdersList[id].balance;
            validation = holdersList[id].valid;
            _status = holdersList[id].status;
        }
    }

    // изменение владельца депозита
    function editDeposit(address target, address newDepositOwner) public
        onlyHolder(target)
        blockCheck(target)
    {
        uint id = searchHolder(target);
        holdersList[id].holder = newDepositOwner;
    }

    // блокировка депозита
    function blockDeposit(address target, string memory reason) public onlyOnwer {
        uint id = searchHolder(target);
        holdersList[id].status = Status.Blocked;
        uint _value = holdersList[id].balance;
        emit BlockInfo(target, _value, block.timestamp, reason);
    }

    // разблокировка депозита
    function unblockDeposit(address target) public onlyOnwer {
        uint id = searchHolder(target);
        holdersList[id].status = Status.Active;
    }
}