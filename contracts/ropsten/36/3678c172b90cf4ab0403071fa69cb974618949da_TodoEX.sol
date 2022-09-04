/**
 *Submitted for verification at Etherscan.io on 2022-09-04
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
//待办事项练习
contract TodoEX{
    struct Todo{
        string text;//待办事项名字("learn solidity,watch tv,read books")
        bool completed;//是否完成
    }

    Todo[] public todos;
    //创建事项
    function creat(string calldata _text) external {
        todos.push(Todo({text:_text, completed: false}));
    }
    //跟新代办事项
    function updateText(uint _index, string calldata _text) external {
        todos[_index].text = _text;
    }
    //对应索引的事项
    function get(uint _index) external view returns(string memory, bool) {
        Todo memory todo = todos[_index];
        return (todo.text,todo.completed);
    }
    //更改代办事项的状态
    function changeCompleted(uint _index) external {
        todos[_index].completed = !todos[_index].completed;
    }
}