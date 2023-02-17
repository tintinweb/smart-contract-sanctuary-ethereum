// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

/// @title A todo list smart contract
/// @author Anoop Raju
/// @notice You can use this contract for storing your todos
/// @dev All functions are implemented without side effects
contract TodoList {
    struct todo {
        string title;
        string description;
        uint createdDate;
        uint timestamp;
        uint8 priority;
        bool status;
        uint lastUpdate;
        bool isPresent;
    }

    /// @notice event to anonuce that a new todo is created
    /// @dev event is emitted during a new todo is created
    /// @param owner is the address of the owner and title of todo as parameter
    event NewTodoCreated(address owner, string title);

    mapping(address => todo[]) todos;

    /// @notice check weather a todo is created or not
    /// @dev should be true if a todo with an id is present
    /// @param _id is the id for todo your looking for
    modifier validId(uint _id) {
        require(
            todos[msg.sender][_id].isPresent == true,
            "No todos are there for this address!"
        );
        _;
    }

    /// @notice function to create a todo
    /// @dev create a new todo
    /// @param _title is the title of todo, _description is the description
    /// @param _timestamp is the timestamp of deadline
    /// @param _priority is priority level of the todo
    function createTodo(
        string memory _title,
        string memory _description,
        uint _timestamp,
        uint8 _priority
    ) public {
        todo memory newTodo;

        newTodo.title = _title;
        newTodo.description = _description;
        newTodo.createdDate = block.timestamp;
        newTodo.timestamp = _timestamp;
        newTodo.priority = _priority;
        newTodo.lastUpdate = block.timestamp;
        newTodo.isPresent = true;

        todos[msg.sender].push(newTodo);

        emit NewTodoCreated(msg.sender, _title);
    }

    /// @notice function to count number of todos of sender
    /// @dev function to count number of todos of sender
    /// @return Number of todos in number
    function getTodosCount() public view returns (uint) {
        return todos[msg.sender].length;
    }

    /// @notice function to send single todo based on id
    /// @dev function returns a todo of specified id
    /// @param _id is the id of todo
    /// @return todo of specified id
    function getTodo(uint _id) public view validId(_id) returns (todo memory) {
        return todos[msg.sender][_id];
    }

    /// @notice function to return all the todos of a sender
    /// @dev function returns all the todos of sender
    /// @return an array of todos
    function getTodos() public view returns (todo[] memory) {
        return todos[msg.sender];
    }

    /// @notice function to change the title of a todo
    /// @dev change the title of a todo with the given id
    /// @param _id is the id of todo
    /// @param _title is the new title of the todo
    function updateTitle(uint _id, string memory _title) public validId(_id) {
        todos[msg.sender][_id].title = _title;
        todos[msg.sender][_id].lastUpdate = block.timestamp;
    }

    /// @notice function to change the description of a todo
    /// @dev change the description of a todo with the given id
    /// @param _id is the id of todo
    /// @param _description is the new description of the todo
    function updateDescription(
        uint _id,
        string memory _description
    ) public validId(_id) {
        todos[msg.sender][_id].description = _description;
        todos[msg.sender][_id].lastUpdate = block.timestamp;
    }

    /// @notice function to change the deathline/timestamp of a todo
    /// @dev change the deadline of a todo with the given id
    /// @param _id is the id of todo
    /// @param _timestamp is the new timestamp of the todo
    function updateTimestamp(uint _id, uint _timestamp) public validId(_id) {
        todos[msg.sender][_id].timestamp = _timestamp;
        todos[msg.sender][_id].lastUpdate = block.timestamp;
    }

    /// @notice function to change the priority value of a todo
    /// @dev change the priority of a todo with the given id
    /// @param _id is the id of todo
    /// @param _priority is the new priority of the todo
    function updatePriority(uint _id, uint8 _priority) public validId(_id) {
        todos[msg.sender][_id].priority = _priority;
        todos[msg.sender][_id].lastUpdate = block.timestamp;
    }

    /// @notice function to change the status of a todo (if completed then true else false)
    /// @dev toggles the status of todo
    /// @param _id is the id of todo
    function updateStatus(uint _id) public validId(_id) {
        todos[msg.sender][_id].status = !todos[msg.sender][_id].status;
        todos[msg.sender][_id].lastUpdate = block.timestamp;
    }
}