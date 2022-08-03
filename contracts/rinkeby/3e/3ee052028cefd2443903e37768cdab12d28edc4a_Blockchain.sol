/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

// SPDX-License-Identifier: GLP-3.0
pragma solidity ^0.8.6;

contract Blockchain{
    uint nextId;

    struct Task{
        uint id;
        string cedula;
        string nombres;
        string barrio;
    }

    Task[] tasks;

    function createTask (string memory _cedula, string memory _nombres, string memory _barrio) public {
        tasks.push(Task(nextId, _cedula, _nombres, _barrio));
        nextId++;
    }

    function findIndex(uint _id) internal view returns (uint){
        for (uint i = 0; i < tasks.length; i++){
            if (tasks[i].id ==_id){
                return i;
            } 
        }
        revert('Fue modificado');
    }

    function readTask(uint _id) public view returns (uint, string memory, string memory, string memory){
        uint index = findIndex(_id);
        return (tasks[index].id, tasks[index].cedula, tasks[index].nombres, tasks[index].barrio);
    }

    function updateTask(uint _id, string memory _cedula, string memory _nombres, string memory _barrio) public{
        uint index = findIndex(_id);
        tasks[index].cedula = _cedula;
        tasks[index].nombres = _nombres;
        tasks[index].barrio = _barrio;
    }

    function deleteTask(uint _id) public{
        uint index = findIndex(_id);
        delete tasks[index];
    }
}