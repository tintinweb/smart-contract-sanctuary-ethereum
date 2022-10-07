/**
 *Submitted for verification at Etherscan.io on 2022-10-07
*/

pragma solidity ^0.8.0;

contract TodoList {

    struct Todo { 
        string text;
        bool completed;
    }

    Todo[] public todos;

    function create(string calldata _text) external {
        todos.push(Todo({
            text: _text,
            completed: false
        }));
    }

    function updateText(uint _index, string calldata _text) external {
        // Cheaper on GAS if one field
        todos[_index].text = _text;

        // Cheaper on GAS if multiple fields
        // Todo storage todo = todos[_index];
        // todo.text = _text;
    }

    function get(uint _index) external view returns (string memory, bool){
        Todo storage todo = todos[_index];
        return (todo.text, todo.completed);
    }

    function toggleCompleted(uint _index) external {
        todos[_index].completed = !todos[_index].completed;
    }
}