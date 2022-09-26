// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Todo.sol";

contract ContractFactory {
    event NewTodoContract(uint256 id);

    Todo public todo;
    //required for testing
    Todo[] public storeTodoContracts;

    //maps the user address to contract address
    mapping(address => address) public userAddressToContractAddress;

    function createTodo() public {
        todo = new Todo(msg.sender);
        //required for testing
        storeTodoContracts.push(todo);

        userAddressToContractAddress[msg.sender] = address(todo);
    }

    function getAddress(address _user) public view returns (address) {
        return userAddressToContractAddress[_user];
    }
}

//0x1f8a98d10d92e709AE243BB903C9C75bfB38bFc0

// SPDX-License-Identifier: None
pragma solidity ^0.8.13;

import "openzeppelin/token/ERC20/IERC20.sol";

contract Todo {
    event TaskAdded(uint256 indexed taskId);
    event UpdateTaskState(uint256 taskId, TaskState state);

    enum TaskState {
        ongoing,
        completed,
        failed
    }

    IERC20 public token;

    uint256 public taskId = 0;

    // authorised addresses to approve task completion
    address[] public authorised;

    mapping(address => bool) public isAuthorised;

    // storing the approvals
    mapping(uint256 => mapping(address => bool)) public approved;

    mapping(uint256 => bool) taskExecution;

    // num of approvals required to mark a task
    uint256 public required = 1;

    struct Task {
        uint256 taskId;
        address tokenAddress;
        uint256 amountStaked;
        uint256 endTimeStamp;
        address fallbackAddress;
        TaskState state;
    }

    Task[] public tasks;

    constructor(address _sender) {
        authorised.push(_sender);
        isAuthorised[_sender] = true;
    }

    receive() external payable {}

    fallback() external payable {}

    modifier onlyAuthorised() {
        require(isAuthorised[msg.sender] == true, "NotAuthorised");
        _;
    }

    modifier onlyCreator() {
        require(msg.sender == authorised[0], "OnlyCreator");
        _;
    }

    modifier onlyOngoing(uint256 _taskId) {
        require(tasks[_taskId].state == TaskState.ongoing, "TaskNotOngoing");
        _;
    }

    modifier timeLeft(uint256 _taskId) {
        require(block.timestamp <= tasks[_taskId].endTimeStamp, "Timeover");
        _;
    }

    function addTask(
        address _tokenAddress,
        uint256 _amountStaked,
        uint256 _endTimeStamp,
        address _fallbackAddress
    ) public onlyCreator returns (uint256) {
        tasks.push(
            Task({
                taskId: taskId,
                tokenAddress: _tokenAddress,
                amountStaked: _amountStaked,
                endTimeStamp: _endTimeStamp,
                fallbackAddress: _fallbackAddress,
                /*creator: msg.sender,*/
                state: TaskState.ongoing
            })
        );

        emit TaskAdded(taskId);

        // autmatically approves the task from user address
        approved[taskId][msg.sender] = true;

        token = IERC20(_tokenAddress);
        token.transferFrom(msg.sender, address(this), _amountStaked);

        return taskId++;
    }

    function approve(uint256 _taskId)
        public
        onlyAuthorised
        onlyOngoing(_taskId)
        timeLeft(_taskId)
    {
        approved[_taskId][msg.sender] = true;
    }

    function revokeApproval(uint256 _taskId)
        external
        onlyAuthorised
        onlyOngoing(_taskId)
        timeLeft(_taskId)
    {
        require(approved[_taskId][msg.sender], "TxNotApproved");
        approved[_taskId][msg.sender] = false;
    }

    function userWithdraw(uint256 _taskId)
        public
        onlyCreator
        onlyOngoing(_taskId)
    {
        require(
            block.timestamp >= tasks[_taskId].endTimeStamp,
            "NotEnoughTimeElapsed"
        );
        uint256 approvals = getApprovalCount(_taskId);
        if (approvals >= required) {
            tasks[_taskId].state = TaskState.completed;
            Task memory task = tasks[_taskId];
            IERC20(task.tokenAddress).transfer(
                authorised[0],
                task.amountStaked
            );
        } else {
            tasks[_taskId].state = TaskState.failed;
            IERC20(tasks[_taskId].tokenAddress).transfer(
                tasks[_taskId].fallbackAddress,
                tasks[_taskId].amountStaked
            );
        }
    }

    function addAuthorised(address _newAuthorised) public onlyCreator {
        authorised.push(_newAuthorised);
        isAuthorised[_newAuthorised] = true;
    }

    function removeAuthorised(address _removedAuthorised) public onlyCreator {
        require(
            isAuthorised[_removedAuthorised] == true &&
                _removedAuthorised != msg.sender
        );
        isAuthorised[_removedAuthorised] = false;
    }

    function updateRequired(uint256 _newRequired) public onlyCreator {
        required = _newRequired;
        require(required >= 1, "NumOfApprovalsShouldBe>=1");
    }

    //---------------------------------------//
    //                 Getters               //
    //---------------------------------------//

    function getApprovalCount(uint256 _taskId)
        public
        view
        returns (uint256 count)
    {
        for (uint256 i; i < authorised.length; i++) {
            if (approved[_taskId][authorised[i]]) {
                count += 1;
            }
        }
    }

    function getOngoingTasks()
        public
        view
        returns (Task[] memory ongoingTasks)
    {
        uint256 counter = 0;
        for (uint256 i = 0; i < tasks.length; i++) {
            if (tasks[i].state == TaskState.ongoing) {
                ongoingTasks[counter] = tasks[i];
                counter++;
            }
        }
        return ongoingTasks;
    }

    function getFailedTasks() public view returns (Task[] memory failedTasks) {
        uint256 counter = 0;
        for (uint256 i = 0; i < tasks.length; i++) {
            if (tasks[i].state == TaskState.failed) {
                failedTasks[counter] = tasks[i];
                counter++;
            }
        }
        return failedTasks;
    }

    function getCompletedTasks()
        public
        view
        returns (Task[] memory completedTasks)
    {
        uint256 counter = 0;
        for (uint256 i = 0; i < tasks.length; i++) {
            if (tasks[i].state == TaskState.completed) {
                completedTasks[counter] = tasks[i];
                counter++;
            }
        }
        return completedTasks;
    }

    function getNumOfPartners() public view returns (uint256) {
        return authorised.length;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}