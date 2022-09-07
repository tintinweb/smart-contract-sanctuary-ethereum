/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract TodoList {
    

    enum Status{
        in_progress,
        finished
    }
    struct TodoItem {
        address addres;
        string title;
        string content;
        Status status;
    }
   mapping(uint256 => TodoItem) todo; 

    function createTodoItem(uint256 id, string memory title, string memory content) public {
       todo[id] = TodoItem ({
           addres: msg.sender,
           title: title,
           content: content,
           status: Status.in_progress
       });  
    }
    
    function updateItem(uint256 id, string memory title, string memory content) public {
        require(todo[id].addres == msg.sender, "Not the owner");
        require(todo[id].status != Status.finished, "Already finished");
       todo[id].title = title;
       todo[id].content = content;
    }
    
    function toggleFinished(uint256 id) public {
        require(todo[id].addres == msg.sender, "Not the owner");
       todo[id].status = Status.finished;
    }
    function getTodoItem(uint256 id) public view returns (TodoItem memory){
        require(todo[id].addres == msg.sender, "Not the owner");
        return todo[id];
    }

    function deleteTodoItem(uint256 id) public {
      require(todo[id].addres == msg.sender, "Not the owner");
        delete todo[id];
    }
}