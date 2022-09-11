/**
 *Submitted for verification at Etherscan.io on 2022-09-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TodoList {

    struct Task {
        string content;
        bool isCompleted;
    }

    event TaskCreated(address user, uint taskId);
    event TasksUpdated(address user);

    mapping(address => Task[]) database;

    function retrieveTasks(address user) public view returns( Task[] memory ) {
      return database[user];
    }

    function createTask(string memory content) public {
      Task[] storage tasks = database[msg.sender];
      tasks.push(Task(content, false));

      emit TaskCreated(msg.sender, tasks.length - 1);
    }

    function finishTask(uint id) public {
      Task storage task = database[msg.sender][id];
      task.isCompleted = true;
    }

    function swapTasks(uint id1, uint id2) public {
      Task memory temp = database[msg.sender][id1];
      database[msg.sender][id1] = database[msg.sender][id2];
      database[msg.sender][id2] = temp;
    }

    enum Operation {
      CREATE,
      DELETE,
      SWAP,
      FINISH
    }

    struct TaskOperation {
      Operation op;
      uint taskId;
      uint swap;
      string content;
    }

    // Helper function to bundle transactions
    function updateTasks(TaskOperation[] memory ops) public {

      for (uint i=0; i<ops.length; i++) {
          TaskOperation memory op = ops[i];

          if (op.op == Operation.CREATE) {
            createTask(op.content);
          } else if (op.op == Operation.DELETE) {
            delete database[msg.sender][op.taskId];
          } else if (op.op == Operation.SWAP) {
            swapTasks(op.taskId, op.swap);
          } else if (ops[i].op == Operation.FINISH) {
            finishTask(op.taskId);
          }
      }
      emit TasksUpdated(msg.sender);

    }


}