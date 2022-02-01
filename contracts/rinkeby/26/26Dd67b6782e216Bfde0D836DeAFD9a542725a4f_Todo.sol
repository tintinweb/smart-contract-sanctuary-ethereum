//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Todo {
    struct TaskItem {
        uint256 id;
        string text;
        bool completed;
    }
    mapping (address => uint256) private taskCount;
    mapping(address => TaskItem[]) private todoList;

    event AddedTask(address indexed sender, string text);
    event ToggledTask(uint256 id, bool completed);
    event DeletedTask(uint256 id, string text);

    modifier validId(uint256 _id) {
        require(_id != 0,"Invalid id");
        _;
    }
    function getTodo() public view returns(TaskItem[] memory){
        require(todoList[msg.sender].length > 0, "You don't have todos");
        return todoList[msg.sender];
    }
    function addTodo(string memory _text) public {
        require(bytes(_text).length != 0,"Empty string");
        taskCount[msg.sender]++;
        todoList[msg.sender].push(TaskItem(taskCount[msg.sender],_text,false));
        emit AddedTask(msg.sender, _text);
    }
    function toggledTask(uint256 _id) validId(_id) public{
        TaskItem[] storage senderTodo = todoList[msg.sender];
        for(uint256 i = 0; i < senderTodo.length; i++) {
            if(senderTodo[i].id == _id && senderTodo[i].id != 0) {
                senderTodo[i].completed = !senderTodo[i].completed;
                emit ToggledTask(_id, senderTodo[i].completed);
            }
        }
    }
    function deleteTask(uint256 _id) validId(_id) public  {
        TaskItem[] storage senderTodo = todoList[msg.sender];
        for(uint256 i = 0; i < senderTodo.length; i++) {
            if(senderTodo[i].id == _id && senderTodo[i].id != 0) {
                string memory todoText = senderTodo[i].text;
                delete senderTodo[i];
                emit DeletedTask(_id, todoText);
            }
        }
        
    }
}