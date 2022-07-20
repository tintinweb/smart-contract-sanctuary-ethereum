/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

pragma solidity ^0.8.0;

contract ToDoEngine {

    address public owner;
    
    struct Todo {
        string title;
        string description;
        bool completed;
    }

    Todo[] public todos;

    modifier OnlyOwner () { 
        require (msg.sender == owner, "Error of owner");
        _;
    }

    constructor () {
        owner = msg.sender;
    }


    function addToDo(string calldata _title, string calldata _description) external OnlyOwner {
        todos.push(Todo({title: _title, description: _description, completed: false}));
   
    }

    function changeToDoTitle(string memory _newTitle, uint _index) external OnlyOwner {
        todos[_index].title=_newTitle;
    }


    function getTodo(uint _index) external view OnlyOwner returns(string memory, string memory, bool) {
        Todo memory myTodo = todos[_index];

        return (
            myTodo.title,
            myTodo.description,
            myTodo.completed
        );  
    }

    function changeToDoStatus (uint _index) external OnlyOwner {
        
        todos[_index].completed = !todos[_index].completed;
    }

    receive () external payable {

    }

}