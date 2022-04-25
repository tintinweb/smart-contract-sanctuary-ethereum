/**
 *Submitted for verification at Etherscan.io on 2022-04-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Todos {
  struct Todo {
    string content;
    bool completed;
  }
  Todo[] public todoList;

  function create(string memory _content) public {
    todoList.push(Todo(_content, false));
    
    // todoList.push(Todo({content: _content, completed: false}));

    // Todo memory todoItem;
    // todoItem.content = _content;
    // todoList.push(todoItem);
  }

  function get(uint _index) public view returns(Todo memory todoItem) {
    return todoList[_index];
  }

  function update(uint _index, string memory _content) public {
    todoList[_index].content = _content;
  }

  function toggleCompleted(uint _index) public {
    todoList[_index].completed = !todoList[_index].completed;
  }

}