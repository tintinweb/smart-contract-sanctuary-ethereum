//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Blocknot {
    // список дел по адресу, из массива дел итерация по индексу
    mapping(address => string[]) public taskListOnAddress;
    // адрес массив индекс в массиве и пометка о выполнении
    mapping(address => mapping (uint => bool)) public taskComplete;
    // вспомогательный массив, только для использования внутри функции
    string[] private _string;
    // маппинг для сохранения последнего индекса task для адреса
    mapping(address => uint) public lastIndex;

    event TaskAdded(address _owner, string _task);
    event TaskComplete(address _owner, string _task);


    function addTask(string memory _task) external {
        // создать массив с уже существующими + новой задачей
        _string = taskListOnAddress[msg.sender];
        _string.push(_task);
        // добавить в taskListOnAddress новый массив по ключу адрес msg.msg.sender
        taskListOnAddress[msg.sender] = _string;
        // вычислить длинну массива taskListOnAddress[msg.sender].length или длинну нового созданного массива
        uint _index = _string.length - 1;
        // добавить в taskComplete новый индекс и false (по-умолчанию)
        taskComplete[msg.sender][_index] = false;
        // сохраняем последний индекс
        lastIndex[msg.sender] = _index;
        // создать событие TaskAdded
        emit TaskAdded(msg.sender, _task);
    }

    function taskChangeComplete(uint _index) external {
        // вычислить индекс элемента в массиве
        string memory _task = taskListOnAddress[msg.sender][_index];
        // помечаем задачу как true
        taskComplete[msg.sender][_index] = true;

        emit TaskComplete(msg.sender, _task);
    }
}