/**
 *Submitted for verification at Etherscan.io on 2022-08-06
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.4;

contract TodoList {
    // add todo tasks
    string[] public undoneArray;

    // add complete tasks
    string[] public doneArray;

    //append
    function addTask(string memory name) public {
        undoneArray.push(name);
    }

    //delete
    function removeTask(uint256 index) public {}

    //check all
    function checkAll() public view returns (string[] memory){
        //return 
    }

    struct TaskInfo {
        string name;
        bool isDone;
    }

    //check specific
    function checkTask(uint256 index) external view returns (TaskInfo memory){//(string memory, bool) {
        if (undoneArray.length > index) {
            return TaskInfo(undoneArray[index], true);
        }
        return TaskInfo("", true);
    }

    //done
    function switchIsDone(uint256 index) public {

    }

    //check all done
    function checkAllDoneTasks() public {}

}