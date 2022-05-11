// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title To-do list
 * @author Anton Y. Malko
 * @notice You can use this contract to make a to-do list
 * @dev All function calls are currently implemented without side effects
*/
contract TodoList {
    enum Status { 
        notCreatedYetTask,
        addTask,
        toDo, 
        realizationTask, 
        doneTask 
    }

    struct Task {
        string name;
        uint256 endTask;
        bool isDeleted;
        bool isOverdue;
        Status statusTask;
    }

    mapping(address => uint256) public ids;
    mapping(address => mapping(uint256 =>Task)) public tasks;

    error functionInvalidAtThisStage();

    /**
     * @notice This event returns the data entered by the user and his address
     * @dev You can change the return arguments
     * @param users_ Address of the user who created the task
     * @param name_ The name of the task created by the user
     * @param data_ The number of days in which the task needs to be completed
    */
    event UserTask(
        address indexed users_, 
        string name_, 
        uint256 data_
    );
    
    /**
     * @notice This event returns the data entered by the user and his address
     * @dev You can change the return arguments
     * @param users_ Address of the user who created the task
     * @param name_ The name of the task created by the user
     * @param id_ Task number
    */
    event DeleteTask(
        address indexed users_, 
        string name_, 
        uint256 indexed id_
    );

    modifier atStage(Status stage_, uint256 id_) {
        if (tasks[msg.sender][id_].statusTask != stage_) {
            revert functionInvalidAtThisStage();
        }
        
        _;
    }
       
    modifier nextStage(uint256 id_) {
        _;
        _nextStage(id_);
    }

    /**
     * @notice The function that creates the task
     * @dev The end date is calculated using the block.timestamp function, 
     * which returns the number of seconds since the epoch
     * @param name_ The name of the task created by the user
     * @param daysTodo_ The number of days in which the task needs to be completed
    */
    function setTask(string memory name_, uint256 daysTodo_) 
        external 
        nextStage(ids[msg.sender]) 
    {
        Task storage task = tasks[msg.sender][ids[msg.sender]];

        task.name = name_;
        task.endTask = block.timestamp + daysTodo_ * 1 days;

        ids[msg.sender]++;

        emit UserTask(
            msg.sender, 
            name_, 
            daysTodo_
        );
    }

    /**
     * @notice This function changes the status of a task
     * @dev There is a modifier that checks that the task has been created
     * @param id_ Task number
    */
    function setStatusToDo(uint256 id_) 
        external 
        atStage(Status.addTask, id_) 
    {
        tasks[msg.sender][id_].statusTask = Status.toDo;
    }
    
    /**
     * @notice This function changes the status of a task
     * @dev There is a modifier that checks that the task has been created
     * @param id_ Task number
    */
    function setStatusInProgress(uint256 id_) 
        external 
        atStage(Status.addTask, id_) 
    {
        tasks[msg.sender][id_].statusTask = Status.realizationTask;
    }

    /**
     * @notice This function changes the status of a task
     * @dev There is a modifier that checks that the task has already been started
     * @param id_ Task number
    */
    function setStatusDone(uint256 id_) 
        external 
        atStage(Status.realizationTask, id_) 
    {
        tasks[msg.sender][id_].statusTask = Status.doneTask;
    }

    /**
     * @notice This function deletes a task
     * @dev The function uses a soft delete method
     * @param id_ Task number
    */
    function deleteTask(uint256 id_) 
        external 
        atStage(Status.doneTask, id_) 
    {
        tasks[msg.sender][id_].isDeleted = true;

        emit DeleteTask(
            msg.sender, 
            tasks[msg.sender][id_].name, 
            id_
        );
    }

    /**
     * @notice A function that changes the status of a task
     * @dev The function is used in the stageNext modifier
     * @param id_ Task number
    */
    function _nextStage(uint256 id_) internal {
        tasks[msg.sender][id_].statusTask = Status(uint(tasks[msg.sender][id_].statusTask) + 1);
    }

    /** 
     * @notice A function that returns a task
     * @dev Returns a structure Task
     * @param id_ Task number
     * @return All task attributes
    */
    function getTask(uint256 id_) 
        external 
        view 
        returns (Task memory) 
    {        
        return tasks[msg.sender][id_];
    }

    /** 
     * @notice Function for calculating the percentage of completed tasks
     * @dev In order to avoid an error, the counter variable is multiplied by 10000
     * @return Number of completed tasks in percent
    */
    function taskInTime() 
        external 
        view 
        returns (uint256) 
    {
        uint256 counter;

        require(ids[msg.sender] != 0, "Zero tasks");

        for (uint i; i < ids[msg.sender]; i++) {
            if (!_isOverdue(tasks[msg.sender][i]) && tasks[msg.sender][i].statusTask == Status.doneTask) {
                counter++;
            }
        }

        return counter * 10000 / ids[msg.sender];
    }

    /** 
     * @notice A function that returns the number of user tasks
     * @dev There is a check for address matching, which can be removed
     * @param add_ Address of the user who created the task
    */
    function getUser(address add_) 
        external 
        view  
        returns (uint256) 
    {
        require(add_ != address(0), "invalid address");

        return ids[add_];
    }

    /**
     * @notice A function that determines whether the task is completed on time
     * @dev Function visibility can be changed to internal
     * @param task_ Structure that stores task attributes
     * @return Boolean value of isOverdue variable
    */
    function _isOverdue(Task memory task_) 
        internal 
        view 
        returns (bool) 
    {
        if (block.timestamp >= task_.endTask) {
            task_.isOverdue = true;
        }

        return task_.isOverdue;
    }
}