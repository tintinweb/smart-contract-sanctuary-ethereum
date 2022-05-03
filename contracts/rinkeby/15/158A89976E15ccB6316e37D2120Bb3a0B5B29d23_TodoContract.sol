// SPDX-License-Identifier: MIT
 pragma solidity ^0.8.1;

  contract TodoContract{
      struct Todo{
          string  title;
          string  description;
      }

      Todo [] public todos;

      function createTodo(string memory _title, string memory _description) public{
          todos.push(Todo({title: _title, description: _description}));
      }
      function fetchTodoWithIndex(uint _index) public view returns (string memory title, string memory description){
          Todo storage todo = todos[_index];
          return(todo.title, todo.description);
      }
      function updateTodo(uint _index,string memory _title, string memory _description ) public {
         Todo storage todo = todos[_index];
         todo.title = _title;
         todo.description = _description;
     }
      function fetchAllTodo() public view returns (Todo[] memory){
          return todos;
      }

     function deleteTodo(uint _index) public{
         delete todos[_index];
     }
 }