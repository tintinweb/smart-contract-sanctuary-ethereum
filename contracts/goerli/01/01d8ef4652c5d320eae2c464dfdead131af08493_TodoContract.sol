/**
 *Submitted for verification at Etherscan.io on 2022-10-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
    contract TodoContract{
  
      struct Todo{
          string  title;
          string  description;
      }


      Todo [] public todos;
      

      function createTodo(string memory _title, string memory _description) public{
          todos.push(Todo({title: _title, description: _description}));
      }
      
      //This function fetches a single todo
      function fetchTodoWithIndex(uint _index) public view returns (string memory title, string memory description){
      
          Todo storage todo = todos[_index];
          return(todo.title, todo.description);
      }
      
      // this is very similar to the createTodo function 
      function updateTodo(uint _index,string memory _title, string memory _description ) public {
         Todo storage todo = todos[_index];
         todo.title = _title;
         todo.description = _description;
     }
     
      function fetchAllTodo() public view returns (Todo[] memory){
          return todos;
      }
      
      //this is the last function that deletes a todo from the list with it's index 
      // yeah I noticed too, it's too convenient ;)

     function deleteTodo(uint _index) public{
         delete todos[_index];
     }
 }