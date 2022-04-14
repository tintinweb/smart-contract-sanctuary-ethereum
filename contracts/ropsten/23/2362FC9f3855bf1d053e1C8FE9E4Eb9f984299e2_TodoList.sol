/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract TodoList {


    //Структура задачи
    struct Task {
        string content;
        uint timeBegin; //время начала
        uint timeEnd; //время конца
        uint timeRun; //время выполнения
        
        bool isDeleted;
    }

    Task[] public tasks; // список задач

    mapping (uint => address) public taskToOwner; //соответствие (id задачи => адрес владельца)
    mapping (address => uint) public ownerTaskCount; // соответствие (адрес владельца => количество задач)


    event NewTask(uint _taskId, string _name, uint _timeRun); //событие "создание задачи"
    event DelTask(uint _taskId); //событие "удаление задачи"
    event CompTask(uint _taskId); // событие "изменение статуса задачи"

    // доступ к изменению задачи только у её владельца
    modifier onlyOwnerOf(uint _taskId) {
        require(msg.sender == taskToOwner[_taskId]);
        _;
    }


    //создать задачу
    function createTask(string memory _name, uint _timeRun) public {
        tasks.push(Task(_name,  block.timestamp, 0, _timeRun, false)); //добавить задачу в массив
        taskToOwner[tasks.length - 1] = msg.sender; // сохраняем владельца задачи
        ownerTaskCount[msg.sender]++; //увеличиваем количество задач у владельца
        emit NewTask(tasks.length - 1, _name, _timeRun); //дергаем событие
    }


    // удалить/восстановить задачу (запускаем с правами владельца)
    function deleteTask(uint _taskId) public onlyOwnerOf(_taskId) { 
       
        if (tasks[_taskId].isDeleted == false) 
        {
            tasks[_taskId].isDeleted = true; //удаление 
            ownerTaskCount[msg.sender]--;
        }
        else
        {
            tasks[_taskId].isDeleted = false; // Восстановление
            ownerTaskCount[msg.sender]++;
        }
        emit DelTask(_taskId); //дергаем событие
    }


    // изменить статус задачи (запускаем с правами владельца)
    function completeTask(uint _taskId) public onlyOwnerOf(_taskId) {
        require(tasks[_taskId].isDeleted == false, "Task is deleted"); //Проверяем, что задача не удалена
        if (tasks[_taskId].timeEnd == 0)
            tasks[_taskId].timeEnd = block.timestamp; // Помечаем задачу, как выполненную. Сохраняем время выполнения
        else
            tasks[_taskId].timeEnd = 0; // Помечаем задачу, как невыполненную
        emit CompTask(_taskId); //дергаем событие
    }


    //получить конуретную задачу
    function getOne(uint _taskId) external view returns(Task memory) {
        return tasks[_taskId];
    }

    //Получить все задачи
    function getAll() external view returns(Task[] memory) {
        return tasks;
    }

    //Получить все задачи конкретного пользователя
    function getAllByOwner(address _owner) external view returns(Task[] memory) {
        Task[] memory result = new Task[](ownerTaskCount[_owner]); //Объявляем массив
        uint counter = 0;
        for (uint i = 0; i < tasks.length; i++) { //Обход массива задач
            if (taskToOwner[i] == _owner) { //Если нашли нужного пользователя
                result[counter] = tasks[i]; //То сохраняем в массив
                counter++;
            }
        }
        return result; //возвращаем массив
    }


    //получить процент выполненных в срок задач по пользователю
    function getPercent(address _owner) external view returns(uint) {
        uint counter = 0;
        for (uint i = 0; i < tasks.length; i++) { //обход списка задач
            if (taskToOwner[i] == _owner && tasks[i].timeEnd!=0 && tasks[i].timeEnd<=tasks[i].timeBegin+tasks[i].timeRun &&  tasks[i].isDeleted == false)
                counter++; //если текущая задача имеет дату завершения меньше чем дата начала + время на выполнение, то считаем её завершенной в срок
        }
        return 100*counter/ownerTaskCount[_owner];
    }
}