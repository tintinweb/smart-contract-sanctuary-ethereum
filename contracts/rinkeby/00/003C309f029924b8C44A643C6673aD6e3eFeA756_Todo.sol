/**
 *Submitted for verification at Etherscan.io on 2022-09-10
*/

pragma solidity ^0.8.6;

contract Todo {

    string public todo;

    function saveTodo(string memory _todo) public{
        todo = _todo;
    }
}