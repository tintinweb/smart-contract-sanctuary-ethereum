/**
 *Submitted for verification at Etherscan.io on 2022-08-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.8.4;


/* @DEPLOY RUN TRANSACTIONS tab
    yellow -> gas fee needed
    greenishBlue -> free (read values)
    red -> payables
    [expanding the buttons will show the type of action]
*/


contract TodoList {

    //增加代辦事項 (TODO)
    string[] public todoList; //implicit storage

    //todoList pending state. 
    
    struct Task {
        string title;
        uint256 aliveForSeconds;
        uint256 exp;
    }
    Task[] public pendingList;
    //增加已完成代辦事項 (COMPLETED)
    string[] public doneList; //implicit storage

    //remove arr[index] from arr
    function stringArrRemoveIndex(string[] storage arr, uint256 index) private { 
        //https://solidity-by-example.org/array/
        require(index < arr.length, "index out of bound");
        for (uint256 i = index; i < arr.length - 1; i++) {
            arr[i] = arr[i+1];
        }
        arr.pop();
    }
    function taskArrRemoveIndex(Task[] storage arr, uint256 index) private { 
        //https://solidity-by-example.org/array/
        require(index < arr.length, "index out of bound");
        for (uint256 i = index; i < arr.length - 1; i++) {
            arr[i] = arr[i+1];
        }
        arr.pop();
    }

    //storage, memory, calldata <- immutable memory
    //syntax format -> type variableName (type storageType variableName) permissionType 
    function addTodo(string memory todo) public {
        todoList.push(todo);
    }
    //DELETE todo item
    function deleteTodo(uint256 index) public {
        //delete todoList[index];
        stringArrRemoveIndex(todoList,index);
    }
    //todo -> pending
    function markTodoAsPending(uint256 index, uint256 aliveForSeconds) public {
        pendingList.push( Task(todoList[index], aliveForSeconds, block.timestamp + aliveForSeconds) );
    }
    //pending -> todo
    function reverseMarkTodoAsPending(uint256 index) public {
        require(index < pendingList.length, "index exceeds array length");
        require(pendingList[index].exp > block.timestamp, "It's too late bitch.");
        taskArrRemoveIndex(pendingList, index);
    }
    //todo -> done
    function markTodoAsDone(uint256 index) public {
        doneList.push(todoList[index]);
        //delete todoList[index];
        stringArrRemoveIndex(todoList,index);
    }

    //GET a todo item
    // 
    function getTodo(uint256 index) public view returns (string memory) {
        return todoList[index];
    }
    //GET todo list
    function getTodoList() public view returns (string[] memory){
        return todoList;
    }
    //GET done list
    function getDoneList() public view returns (string[] memory){
        return doneList;
    }

    function clearDoneList() public {
        delete doneList;
    }

    function getPendingList() public view returns (Task[] memory){
        return pendingList;
    }
}