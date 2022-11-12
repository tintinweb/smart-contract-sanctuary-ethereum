/**
 *Submitted for verification at Etherscan.io on 2022-11-12
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

contract ques4{

    event Create(address recipient, uint Id);
    event Delete(uint taskId, bool isDeleted);

    struct List {
        uint id;
        address username; // address of sender
        string name; // Name of task
        bool Status; // To check if the the task is deleted
    }

    List[] private l;  // Create an object l

    mapping(uint256 => address) taskToOwner;

    function addTask(string memory taskText, bool isDeleted) external {
        uint taskId = l.length;
        l.push(List(taskId, msg.sender, taskText,isDeleted));
        taskToOwner[taskId] = msg.sender;
        emit Create(msg.sender, taskId);
    }

    function getMyTasks() external view returns (List[] memory) {
        List[] memory temporary = new List[](l.length);
        uint counter = 0;
        for(uint i=0; i<l.length; i++) {
            if(taskToOwner[i] == msg.sender && l[i].Status == false) {
                temporary[counter] = l[i];
                counter++;
            }
        }

        List[] memory result = new List[](counter);
        for(uint i=0; i<counter; i++) {
            result[i] = temporary[i];
        }
        return result;
    }

    function deleteTask(uint taskId, bool isDeleted) external {
        if(taskToOwner[taskId] == msg.sender) {
            l[taskId].Status = isDeleted;
            emit Delete(taskId, isDeleted);
        }
    }

}