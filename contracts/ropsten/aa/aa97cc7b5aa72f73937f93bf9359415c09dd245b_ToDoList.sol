/**
 *Submitted for verification at Etherscan.io on 2022-09-24
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.4;

contract ToDoList
{
    struct Tasks
    {
        //ID
        //Data
        //isCompleted or not

        uint Id;
        string Data;
        bool isCompleted;

    }

    Tasks[] private task; //lenght = 0

    function createTask(string memory _data) public
    {
        task.push(Tasks(task.length, _data, false));
    }

    function getTasks(uint _id) public view returns (uint, string memory, bool)
    {
        return (
            task[_id].Id,
            task[_id].Data,
            task[_id].isCompleted
        );
    }

    function getAllTasks() public view returns(Tasks[] memory)
    {
        return task;
    }

    function taskUpdate(uint _id) public 
    {
        task[_id].isCompleted = true;
    }

}