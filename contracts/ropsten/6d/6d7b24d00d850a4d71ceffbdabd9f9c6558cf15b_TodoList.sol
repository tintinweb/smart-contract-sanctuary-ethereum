/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TodoList {

    struct Task {
        uint code; // Имя задачи
        string description; // Описание задачи
        uint deadline; // Время на выполнение
        bool completed; // Если True то задача выполнена 
        bool overdue; // Если True то задача просрочена
        bool trashed; // Если True то задача удалена и её не учитывать  
    }

    mapping(address => Task[]) todoList; // Для каждого адреса свой массив со списком задач

    function addTask(uint _code, string memory _decription, uint _deadline) external { // Создание новой задачи

        for(uint i = 0; i <= todoList[msg.sender].length; i++) { // Проходимся по всему массиву у msg.sender
            require(todoList[msg.sender][i].code == _code, "This code is already taken"); // Если в массиве пользователя еже есть такой код, то ошибка
        } 

        Task memory newTask = Task({
            code: _code,
            description: _decription,
            deadline: block.timestamp + _deadline, // Время сейчас + время на задачу
            completed: false,
            overdue: false,
            trashed: false
        });

       todoList[msg.sender].push(newTask); // Добавили новую задачу в массив для msg.sender
    }

    function deleteTask(uint _code) external {
        for(uint i = 0; i <= todoList[msg.sender].length; i++) { // Проходимся по всему массиву у msg.sender
            if(todoList[msg.sender][i].code == _code) { // Находим нужную задачу
                todoList[msg.sender][i].trashed = true; // Помечаем как удалённую
                break; // Цикл можно прекратить т.к. code не повторяется, экономим газ
            }
        }
    }

    function changeTaskStatus(uint _code) external {
        for(uint i = 0; i <= todoList[msg.sender].length; i++) { // Проходимся по всему массиву у msg.sender
            if(todoList[msg.sender][i].code == _code) { // Находим нужную задачу
                todoList[msg.sender][i].completed = !(todoList[msg.sender][i].completed); // Меняем статус
                if(todoList[msg.sender][i].completed == true) { // Если статус задачи изменён на выполнено, то проверяем просрочена она или нет
                    todoList[msg.sender][i].overdue = todoList[msg.sender][i].deadline <= block.timestamp ? true : false; // Если текущее время больше чем время дедлайна, то задача просрочена
                }
                break; // Цикл можно прекратить т.к. code не повторяется, экономим газ
            }
        }
    }

    function getTask(uint _code) external view returns(string memory) { // Получаем конкретную задачу по коду
        for(uint i = 0; i <= todoList[msg.sender].length; i++) { // Проходимся по всему массиву у msg.sender
            if(todoList[msg.sender][i].code == _code) { // Находим нужную задачу
            return todoList[msg.sender][i].description;
            }
        }
        return "code not found"; // Если код не существует, возвращаем сообщение
    }

    function getAllTasks() external view returns(uint[] memory) { // Получаем список всех не удалённых задач
        uint[] memory allTasks;
        uint count;
        for(uint i = 0; i <= todoList[msg.sender].length; i++) { // Проходимся по всему массиву у msg.sender
            if(todoList[msg.sender][i].trashed == false) { // Если задача не удалена, то добавлеём её код в возвращаемый массив
            allTasks[count] = todoList[msg.sender][i].code;
            count++;
            }
        } 
        return allTasks;
    }

    function getPercentageCompletedTasks() external view returns(uint) { // Расчитываем процент выполненных задач
        uint allTask = 1; // Чтобы не было ошибки деления на ноль
        uint completedTask;

        for(uint i = 0; i <= todoList[msg.sender].length; i++) { // Проходимся по всему массиву у msg.sender
            if((todoList[msg.sender][i].completed == true) && (todoList[msg.sender][i].trashed == false)) { // Находим выполненные не удалённые задачи
            completedTask++;
            }
        }

        for(uint i = 0; i <= todoList[msg.sender].length; i++) { // Проходимся по всему массиву у msg.sender
            if(todoList[msg.sender][i].trashed == false) { // Находим все не удалённые задачи
            allTask++;
            }
        }  

        if(allTask > 1) {
            allTask--;
        }

        return (completedTask * 100) / (allTask * 100);
    }

}