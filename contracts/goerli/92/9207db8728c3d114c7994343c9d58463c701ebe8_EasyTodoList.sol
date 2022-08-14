/**
 *Submitted for verification at Etherscan.io on 2022-08-14
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract EasyTodoList {
    enum TaskStatus {
        todo,
        pending,
        complete
    }
    struct Task {
        string title;
        TaskStatus status;
        uint256 expireTime;
    }

    uint256 public expirePeriod = 5;
    Task [] public todos;

    modifier onlyTODO(uint256 _index) {
        require(todos[_index].status == TaskStatus.todo, "only todo can execute");
        _;
    }

    modifier pendingVarify(uint256 _index) {
        require(todos[_index].status == TaskStatus.pending, "only pending can execute");
        require(todos[_index].expireTime >= block.timestamp, "expired!");
        _;
    }
    
    //getAllTodo
    function getAllTodos() external view returns (string [10] memory) {
        string [10] memory result;
        for (uint256 i = 0; i < todos.length; i++) {
            if (todos[i].status == TaskStatus.todo) {
                result[i] = todos[i].title;
            }
        }
        return result;
    } 

    //getAllPendings
    // function getAllPendings() external view returns (Task [] memory) {
    //     Task [] memory result;
    //     for (uint256 i = 0; i < todos.length; i++) {
    //         if (todos[i].status == TaskStatus.pending) {
    //             result.push(todos[i]);
    //         }
    //     }
    //     return result;
    // }

    //gat all complete
    // function getAllCompletes() external view returns (Task [] memory) {
    //     Task [] memory result;
    //     for (uint256 i = 0; i < todos.length; i++) {
    //         if (todos[i].status == TaskStatus.complete) {
    //             result.push(todos[i]);
    //         }
    //     }
    //     return result;
    // } 

    //add todo
    function addTodo(string memory _title) external {
        todos.push(Task({
            title : _title,
            status : TaskStatus.todo,
            expireTime : 0
        }));
    }

    //move todo to pending
    function moveTodoToPending(uint256 _index) external onlyTODO(_index) {

        Task storage targetTask = todos[_index];
        targetTask.status = TaskStatus.pending;

        //expire
        targetTask.expireTime = block.timestamp + expirePeriod;
    }

    //move pending to todo
    function movePendingToTodo(uint256 _index) external pendingVarify(_index) {
        Task storage targetTask = todos[_index];
        targetTask.status = TaskStatus.todo;
        targetTask.expireTime = 0;
    }

    //move todo to done
    function moveToDone(uint256 _index) external {
        //require(_index >= todos.length, "out of bound").
        // require(todos[_index].status = TaskStatus.TODO, "only todo can tranlate to done.").
        Task storage targetTask = todos[_index];
        targetTask.status = TaskStatus.complete;
    }

}