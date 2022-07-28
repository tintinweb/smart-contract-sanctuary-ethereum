/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

error TaskContract__NotOwner();

contract TaskContract {
  
  /* events */
  event AddTask(address recipient, uint taskId);
  event DeleteTask(uint taskId, bool isDeleted);

  /* Types Variables */
  struct Task {
    uint id;
    string taskData;
    bool isDeleted;
  }

  Task[] private s_tasks;
  mapping(uint => address) private s_taskToOwner;

  function addTask(string memory _data, bool _isDeleted) external {
    uint id = s_tasks.length;
    s_tasks.push(Task(id,_data,_isDeleted));
    s_taskToOwner[id] = msg.sender;

    emit AddTask(msg.sender, id);
  }

  function getMyAllTasks() external view returns (Task[] memory) {
    Task[] memory temp = new Task[](s_tasks.length);
    uint counter = 0;
    for(uint i=0;i<s_tasks.length;i++){
        if(s_taskToOwner[i] == msg.sender && s_tasks[i].isDeleted == false) {
            temp[counter] = s_tasks[i];
            counter ++;
      }
    }
    Task[] memory result = new Task[](counter);
    for(uint i=0;i<counter;i++){
      result[i] = temp[i];
    }
    return result;
  }

  function deleteMyTask(uint _id, bool _flag) external {
    if(s_taskToOwner[_id] == msg.sender) {
      s_tasks[_id].isDeleted = _flag;
      emit DeleteTask(_id, _flag);
    }else{
      revert TaskContract__NotOwner();
    }
  }
}