/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <8.10.0;

contract TodoList {
  uint256 public taskCount = 0;
  address public owner;

  struct Task {
    uint id;
    string content;
    bool completed;
    address author;
    bool overdue;
    uint deadline;
  }

  mapping(uint => Task) public tasks;

  event TaskCreated(
    uint id,
    string content,
    bool completed,
    address author,
    bool overdue,
    uint deadline
  );

  event TaskComplited(
    uint id,
    bool complited,
    bool overdue
  );

  constructor() public {
 
    owner = msg.sender;
  }

  //создать задачу - передаем задачу и ко-во дней на выполнение
  function createTask(string memory _content, uint _WorkingDays) public {
    taskCount ++;
    //рассчитываем дату дедлайна
    uint dateInAWeek = block.timestamp;
    uint deadline = dateInAWeek + (_WorkingDays*86400);
    //заполняем структуру данными
    tasks[taskCount] = Task(taskCount,_content, false, msg.sender, false, deadline);
    emit TaskCreated(taskCount,_content, false, msg.sender, false, deadline);
  }

  //выполнение задачи - передаем ид задачи
  function tooggleComplited(uint _id) public {
    //проверка на владельца
    require(tasks[_id].author == owner, "Not owner!");
    //если не установлен признак "выполнена" устанавливаем его
    Task memory _task = tasks[_id];
    _task.completed = !_task.completed;
    //проверка если текущая дата больше дедлайна - устанавливаем признак "просрочена"
    if (block.timestamp <= tasks[_id].deadline) _task.overdue = false;
    else _task.overdue = true;
    //заполняем структуру данными
    tasks[_id] = _task;
    emit TaskComplited(_id, _task.completed, _task.overdue);
  }

  //удаление задачи
  function deleteTask(uint _id) public {
    require(tasks[_id].author == owner, "Not owner!");
    delete tasks[_id]; 
  }

  //расчет процента выполненных задач вовремя по пользователю - передаем автора
  //countTasks - выполнено задач
  //_taskCount - всего задач по автору
  function percentOfCompletion(address  _author) public view returns (uint256 percent, uint256 countTasks, uint256 _taskCount) {
    _taskCount = 1;
    for(uint i = 1; i <=taskCount; i++) {
      if (tasks[i].author == _author && tasks[i].overdue == false && tasks[i].completed == true) {
        countTasks ++;
        _taskCount++;
      }
    }
    percent = countTasks*100/_taskCount;
    return (percent,countTasks, _taskCount);
  }
}