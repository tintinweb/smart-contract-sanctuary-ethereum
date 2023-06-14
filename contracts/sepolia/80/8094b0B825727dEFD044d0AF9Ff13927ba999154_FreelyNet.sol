/**
 *Submitted for verification at Etherscan.io on 2023-06-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}


contract FreelyNet {
    using Strings for uint256;

    struct Task {
        address client;               // Address of the client who posted the task
        string description;           // Description of the task
        uint budget;                  // Budget allocated for the task
        bool completed;               // Indicates if the task is completed
        address freelancer;           // Address of the assigned freelancer
        uint clientRating;            // Rating given by the client
        uint freelancerRating;        // Rating given by the freelancer
        string clientReview;          // Review provided by the client
        string freelancerReview;      // Review provided by the freelancer
        bool disputeRaised;           // Indicates if a dispute is raised for the task
        bool fundsReleased;           // Indicates if funds are released from escrow
        bool paymentHold;             // Indicates if the payment is on hold
        mapping(address => string[]) messages;  // Messages exchanged between the client and freelancer
        mapping(address => bool) bidders;  // Keeps track of freelancers who have bid on the task
    }

    Task[] public tasks;
    address payable public owner;

    event TaskCreated(uint indexed taskId, address indexed client, string description, uint budget);
    event TaskAssigned(uint indexed taskId, address indexed freelancer);
    event TaskCompleted(uint indexed taskId, address indexed freelancer);
    event RatingProvided(uint indexed taskId, address indexed rater, uint rating, string review);
    event DisputeRaised(uint indexed taskId, address indexed raiser);
    event DisputeResolved(uint indexed taskId, address indexed resolver);
    event FundsReleased(uint indexed taskId, uint amount, address indexed recipient);
    event MessageSent(uint indexed taskId, address indexed sender, string message);

    constructor() {
        owner = payable(msg.sender);
    }

    // Client posts a new task
    function postTask(string calldata _description, uint _budget) external {
        Task storage newTask = tasks.push();
        newTask.client = msg.sender;
        newTask.description = _description;
        newTask.budget = _budget;

        emit TaskCreated(tasks.length - 1, msg.sender, _description, _budget);
    }

    // Freelancer bids on a task
    function bidOnTask(uint _taskId) external payable {
        Task storage task = tasks[_taskId];
        require(!task.completed, "Task is already completed");
        require(task.freelancer == address(0), "Task is already assigned");
        require(msg.value > 0, "Bid amount must be greater than 0");

        task.freelancer = msg.sender;
        task.paymentHold = true;
        task.bidders[msg.sender] = true;  // Add freelancer to the list of bidders
        emit TaskAssigned(_taskId, msg.sender);
    }

    // Client marks a task as completed and releases payment
    function completeTask(uint _taskId) external {
        Task storage task = tasks[_taskId];
        require(!task.completed, "Task is already completed");
        require(task.client == msg.sender, "Only the client can complete the task");

        task.completed = true;
        task.paymentHold = false;

        uint deduction = task.budget / 10; // 10% deduction
        uint amountToTransfer = task.budget - deduction;

        owner.transfer(deduction); // Transfer the deducted amount to the owner
        emit FundsReleased(_taskId, deduction, owner);

        emit TaskCompleted(_taskId, task.freelancer);
    }

    // Client provides a rating and review for a task
    function provideRating(uint _taskId, uint _rating, string calldata _review) external {
        Task storage task = tasks[_taskId];
        require(task.completed, "Task is not completed");
        require(task.client == msg.sender || task.freelancer == msg.sender, "Only the client or freelancer can provide a rating");

        if (task.client == msg.sender) {
            require(task.clientRating == 0, "Client has already provided a rating");
            task.clientRating = _rating;
            task.clientReview = _review;
        } else {
            require(task.freelancerRating == 0, "Freelancer has already provided a rating");
            task.freelancerRating = _rating;
            task.freelancerReview = _review;
        }

        emit RatingProvided(_taskId, msg.sender, _rating, _review);
    }

    // Client raises a dispute for a task
    function raiseDispute(uint _taskId) external {
        Task storage task = tasks[_taskId];
        require(task.completed, "Task is not completed");
        require(!task.disputeRaised, "Dispute is already raised for the task");
        require(task.client == msg.sender || task.freelancer == msg.sender, "Only the client or freelancer can raise a dispute");

        task.disputeRaised = true;
        emit DisputeRaised(_taskId, msg.sender);
    }

    // Resolves a dispute for a task
    function resolveDispute(uint _taskId) external {
        Task storage task = tasks[_taskId];
        require(task.completed, "Task is not completed");
        require(task.disputeRaised, "No dispute is raised for the task");
        require(task.client == msg.sender || task.freelancer == msg.sender, "Only the client or freelancer can resolve a dispute");

        task.disputeRaised = false;
        emit DisputeResolved(_taskId, msg.sender);
    }

    // Releases funds from escrow for a task
    function releaseFunds(uint _taskId, address _recipient, uint _amount) external {
        Task storage task = tasks[_taskId];
        require(task.completed, "Task is not completed");
        require(!task.disputeRaised, "Dispute is raised for the task");
        require(task.client == msg.sender || task.freelancer == msg.sender, "Only the client or freelancer can release funds");
        require(!task.fundsReleased, "Funds are already released for the task");
        require(_amount <= task.budget, "Release amount cannot exceed the task budget");

        task.fundsReleased = true;
        payable(_recipient).transfer(_amount);
        emit FundsReleased(_taskId, _amount, _recipient);
    }

    // Sends a message to the task
    function sendMessage(uint _taskId, string calldata _message) external {
        Task storage task = tasks[_taskId];
        require(task.client == msg.sender || task.freelancer == msg.sender, "Only the client or freelancer can send messages");

        task.messages[msg.sender].push(_message);
        emit MessageSent(_taskId, msg.sender, _message);
    }

    // Get the total number of tasks
    function getTaskCount() external view returns (uint) {
        return tasks.length;
    }

    // Get task details
    function getTask(uint _taskId) external view returns (
        address, string memory, uint, bool, address, uint, uint, string memory, string memory, bool, bool, bool
    ) {
        Task storage task = tasks[_taskId];
        return (
            task.client,
            task.description,
            task.budget,
            task.completed,
            task.freelancer,
            task.clientRating,
            task.freelancerRating,
            task.clientReview,
            task.freelancerReview,
            task.disputeRaised,
            task.fundsReleased,
            task.paymentHold
        );
    }

    // Get the messages exchanged for a task
    function getTaskMessages(uint _taskId, address _participant) external view returns (string[] memory) {
        Task storage task = tasks[_taskId];
        return task.messages[_participant];
    }

    // Get the list of freelancers who have bid on a particular task
    function getBidders(uint _taskId) external view returns (address[] memory) {
        Task storage task = tasks[_taskId];
        address[] memory bidders = new address[](tasks[_taskId].freelancer != address(0) ? 1 : 0);
        if (task.freelancer != address(0)) {
            bidders[0] = task.freelancer;
        }
        return bidders;
    }

    // Get the average rating for a particular freelancer
    function getFreelancerAverageRating(address _freelancer) external view returns (uint) {
        uint totalRating;
        uint count;
        for (uint i = 0; i < tasks.length; i++) {
            Task storage task = tasks[i];
            if (task.freelancer == _freelancer && task.completed) {
                totalRating += task.freelancerRating;
                count++;
            }
        }
        return count > 0 ? totalRating / count : 0;
    }

    // Get the list of disputes raised for a particular task
    function getTaskDisputes(uint _taskId) external view returns (bool) {
        Task storage task = tasks[_taskId];
        return task.disputeRaised;
    }
}