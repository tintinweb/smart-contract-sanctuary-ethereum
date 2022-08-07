/**
 *Submitted for verification at Etherscan.io on 2022-08-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;


struct Pending {
        string pendingTodo;
        uint256 startTime;
}

contract TodoList {    

    string[] public todos;
    string[] public todoCompleted;

    Pending[] public pendings;

    constructor() {}
    
    function addTodo(string memory todo) public {
        todos.push(todo);
    }

    function setCompleted(uint256 _index) external {
        string memory tmp = todos[_index];
        removeTodo(_index);

        // add to todoCompleted
        todoCompleted.push(tmp);
    }

    function addPending(string memory _pendingTodo, uint256 _startTime) internal {
        pendings.push( Pending({pendingTodo: _pendingTodo, startTime: _startTime}) );
    }

    function removeTodo(uint256 _index) public {
        todos[_index] = todos[todos.length -1];
        todos.pop();
    }

    function clearCompleted() external {
        string[] memory s;
        todoCompleted = s;
    }

    function removePending(uint256 _index) internal {
        pendings[_index] = pendings[pendings.length -1];
        pendings.pop();
    }

    function moveToPending(uint256 _index) external {
        uint256 t = block.timestamp;
        string memory s = todos[_index];
        removeTodo(_index);
        addPending(s, t);
    }

    function moveToTodo(uint256 _index) external {
        Pending memory pend = pendings[_index];
        require (block.timestamp < pend.startTime + 20 seconds, "over time limit");
        addTodo(pend.pendingTodo);
        removePending(_index);
        
    }

    function getTodo(uint256 _index) external view returns (string memory) {
        return todos[_index];
    }

    function getCompleted(uint256 _index) external view returns (string memory) {
        return todoCompleted[_index];
    }

    function getAllTodo() external view returns (string[] memory) {
        return todos;
    }

    function getAllCompleted() external view returns (string[] memory) {
        return todoCompleted;
    }

    function getPending(uint256 _index) external view returns (Pending memory){
        return pendings[_index];
    }

    function getAllPending() external view returns (Pending[] memory){
        return pendings;
    }

}