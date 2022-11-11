/**
 *Submitted for verification at Etherscan.io on 2022-11-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

interface IProofOfHumanity {
    // https://etherscan.io/address/0xc5e9ddebb09cd64dfacab4011a0d5cedaf7c9bdb
    function isRegistered(address _submissionID) external view returns (bool);
}

contract Hestia {

    enum Status { 
        NEW, 
        CANCELLED,  
        PROGRESS, 
        VALIDATING,
        FINISHED, 
        DISPUTE_PROGRESS, 
        DISPUTE_RESULTS, 
        DISPUTE_LEGAL, 
        ILEGAL 
    } 

    struct Rating {
        uint8 score;
        uint8 messageId;
        uint taskId;
    }

    struct User {
        string nickname;
        uint createDate;
        bool poh;
        uint256 totalStakingRequired;
        uint32 countTask;
        Rating[] ratings;
    }

    struct TaskRefiner {
		uint createDate;
		uint initDate;
        uint256 amountOffer;
        bool approved;
	}

    struct TaskCreatedParam {
        uint32 cityId;
        uint deadlineDate;
        uint256 maxAmountLimit;
        string hashIpfsDetails;
    }

    struct TaskApprovedParam {
        uint taskId;
        uint256 amount;
        address tasker;
        string hashIpfsRefined;
    }

    struct TaskFinishedParam {
        uint taskId;
        uint8 ratingScorePoster;
        uint8 ratingMessageIdPoster;
        string hashIpfsResults;
    }
	
	struct TaskHistory {
		Status status;
		uint createDate;
	}

    struct Task {
        uint id;
        Status status;
		uint32 cityId;
		uint256 amount;
        uint256 maxAmountLimit;
        uint deadlineDate;
        uint createDate;
        string hashIpfsDetails;
        string hashIpfsRefined;
        string hashIpfsResults;
		TaskHistory[] history;
    }

    address private owner;
    address private ownerSubstitute;
    uint private tasksCount;
    uint256 private vault;
    uint8 private fee;
    uint8 private percentageOfStakingPerTaskWithPOH;
    uint8 private percentageOfStakingPerTaskWithoutPOH;
    uint32 private tasksMaxByAddr;
    address private POH_addr;
 
    mapping(address => User) private users;
    mapping(address => bool) private joinedUsers;
	mapping(address => uint256) private stakingAmountByUser;
	mapping(uint => Task) private tasks;
    mapping(uint => address) private taskerByTaskId; 
    mapping(uint => address) private posterByTaskId; 
	mapping(uint => mapping(address => TaskRefiner)) private refinerByTaskIdAndTasker; 
	
    event Joined(address indexed joined, string nickname);
    event Staking(address indexed staker, uint256 amountInStaking);
    event Created(address indexed jobPoster, uint taskId);
    event Finished(uint indexed taskId);
    event DisputeProgress(address indexed user);
    event DisputeFinish(address indexed user);
    event DisputeLegal(address indexed user);

    modifier isOwner() {
        require(msg.sender == owner || msg.sender == ownerSubstitute, "Caller is not owner");
        _; 
    }

    constructor() {
        owner = msg.sender;
        tasksMaxByAddr = 1000;
        fee = 2;
        percentageOfStakingPerTaskWithPOH = 10;
        percentageOfStakingPerTaskWithoutPOH = 30; 
        POH_addr = 0xB44F8c0B9De6605DB1259e3755923c063D6bD11d;
    }

    receive() external payable {
        revert("No call data provided");
    }

    fallback() external {
        revert("No call data provided");
    }

    // **************************** //
    // *     LOGIN                * //
    // **************************** //

    function join(string calldata nickname) external {
        require(!joinedUsers[msg.sender], "User already exists");
		
        User storage newUser = users[msg.sender];
        newUser.nickname = nickname;
        newUser.poh = proofOfHumanity().isRegistered(msg.sender);
        newUser.createDate = block.timestamp;
        joinedUsers[msg.sender] = true;
		
        emit Joined(msg.sender, nickname);
    }

    function getUser(address addr) external view returns (User memory) {
        return users[addr];
    }

    function updatePoh() external {
        validateUser(msg.sender, "Unregistered user");
        users[msg.sender].poh = proofOfHumanity().isRegistered(msg.sender);
    }

    // **************************** //
    // *     STAKING              * //
    // **************************** //

    function stake() external payable { 
        validateUser(msg.sender, "Unregistered user");
        stakingAmountByUser[msg.sender] += msg.value;
        emit Staking(msg.sender, stakingAmountByUser[msg.sender]);
    }

    function unstake(uint256 amount) external {
        validateUnStaking(amount);
        stakingAmountByUser[msg.sender] -= amount;
        transferBalance(payable(msg.sender), amount);
        emit Staking(msg.sender, stakingAmountByUser[msg.sender]);
    }

    // **************************** //
    // *     CREATE TASK          * //
    // **************************** //

    function createTask(TaskCreatedParam calldata param) public returns(uint) {
        validateTaskCreate(param);
        tasksCount++;
        uint id = tasksCount; 
    
        Task storage newTask = tasks[id];
        newTask.id = id;
        newTask.status = Status.NEW;
        newTask.cityId = param.cityId;
        newTask.deadlineDate = param.deadlineDate;
        newTask.maxAmountLimit = param.maxAmountLimit;
        newTask.hashIpfsDetails = param.hashIpfsDetails;
        newTask.createDate = block.timestamp;

        posterByTaskId[id] = msg.sender;
        users[msg.sender].countTask++;
				
        emit Created(msg.sender, id);   
        return id;
    }

    function createTaskAndSelectTasker(TaskCreatedParam calldata param, address tasker) external {
        validateTaskCreateAndSelectTasker(param, tasker);

        uint taskId = createTask(param);

		refinerByTaskIdAndTasker[taskId][tasker].createDate = block.timestamp;
        refinerByTaskIdAndTasker[taskId][tasker].initDate = block.timestamp;
        refinerByTaskIdAndTasker[taskId][tasker].amountOffer = param.maxAmountLimit;
    }

    function getTask(uint id) external view returns (Task memory) {
        return tasks[id];
    }

    function cancelTask(uint taskId) external {
        validateTask(true, taskId, Status.NEW);
        changeStatusTask(taskId, Status.CANCELLED);
    }

    // **************************** //
    // *     REFINING             * //
    // **************************** //
	
	function taskerRequestRefining(uint taskId, uint256 amountOffer) external {
        validateTaskRefining(false, taskId, Status.NEW, address(0), amountOffer);
		refinerByTaskIdAndTasker[taskId][msg.sender].createDate = block.timestamp;
        refinerByTaskIdAndTasker[taskId][msg.sender].amountOffer = amountOffer;
    }
	
	function selectTaskerRefining(uint taskId, address tasker) external {
        validateTaskRefining(true, taskId, Status.NEW, tasker, 0);
		refinerByTaskIdAndTasker[taskId][tasker].initDate = block.timestamp;
    }

	function taskerApprove(uint taskId) external {
        validateTask(false, taskId, Status.NEW);

        TaskRefiner memory taskerRefiner = refinerByTaskIdAndTasker[taskId][msg.sender];
        require(taskerRefiner.initDate > 0, "Tasker not request refining for this task");

        uint8 percOfStaking = users[msg.sender].poh ? percentageOfStakingPerTaskWithPOH : percentageOfStakingPerTaskWithoutPOH;

        uint moreStakingRequired = calculatePercent(taskerRefiner.amountOffer, percOfStaking);
        users[msg.sender].totalStakingRequired += moreStakingRequired;
        
        require(stakingAmountByUser[msg.sender] >= users[msg.sender].totalStakingRequired, "Tasker without staking enough for all tasks");

        refinerByTaskIdAndTasker[taskId][msg.sender].approved = true;
    }

    // **************************** //
    // *     ESCROW               * //
    // **************************** //

	function approveTaskerAndEscrow(TaskApprovedParam calldata param) external payable {
        validateTaskEscrow(param.taskId, Status.NEW, param.tasker, param.amount);
		
		tasks[param.taskId].amount = param.amount;
        tasks[param.taskId].hashIpfsRefined = param.hashIpfsRefined;
        taskerByTaskId[param.taskId] = param.tasker; 

        vault += calculatePercent(param.amount, fee);

        changeStatusTask(param.taskId, Status.PROGRESS);
    }	

    function disputeProgress(uint taskId) external {
        validateTask(true, taskId, Status.PROGRESS);

        changeStatusTask(taskId, Status.DISPUTE_PROGRESS);
        emit DisputeProgress(msg.sender);
    }

    // **************************** //
    // *     FINISH               * //
    // **************************** //

	function taskerFinish(TaskFinishedParam calldata param) external {
        validateTask(false, param.taskId, Status.PROGRESS);
			
        tasks[param.taskId].hashIpfsResults = param.hashIpfsResults;

        Rating[] storage ratings = users[posterByTaskId[param.taskId]].ratings;
        ratings.push(Rating(param.ratingScorePoster, param.ratingMessageIdPoster, param.taskId));

        changeStatusTask(param.taskId, Status.VALIDATING);
    }

    function approveFinish(uint taskId, uint8 ratingScoreTasker, uint8 ratingMessageIdTasker) external {
        validateTask(true, taskId, Status.VALIDATING);

        address taskerAddr = taskerByTaskId[taskId];

        uint8 percOfStaking = users[taskerAddr].poh ? percentageOfStakingPerTaskWithPOH : percentageOfStakingPerTaskWithoutPOH;

        users[taskerAddr].totalStakingRequired -= calculatePercent(refinerByTaskIdAndTasker[taskId][taskerAddr].amountOffer, percOfStaking);

        transferBalance(payable(taskerAddr), tasks[taskId].amount);

        Rating[] storage ratings = users[taskerAddr].ratings;
        ratings.push(Rating(ratingScoreTasker, ratingMessageIdTasker, taskId));

        changeStatusTask(taskId, Status.FINISHED);
        emit Finished(taskId);
    }

    function disapproveFinish(uint taskId) external {
        validateTask(true, taskId, Status.VALIDATING);
        changeStatusTask(taskId, Status.DISPUTE_RESULTS);
        emit DisputeFinish(msg.sender);
    }

    // **************************** //
    // *     VALIDATE             * //
    // **************************** //
	
    function validateTransfer(address to, uint256 amount) private view {
        require(to != address(0), "Error transfer to the zero address");
		require(address(this).balance >= amount, "Error amount balance"); 
    }

	function validateUser(address addr, string memory error) private view {
        require(joinedUsers[addr], error);
	}

    function validateUnStaking(uint256 amount) private view {
        validateUser(msg.sender, "Unregistered user");
        require(stakingAmountByUser[msg.sender] > 0, "User is not staking");
        require(stakingAmountByUser[msg.sender] >= amount, "The amount is higher than the staking");
        require(users[msg.sender].totalStakingRequired <= (stakingAmountByUser[msg.sender] - amount), "The staking result no can be less to staking required");
	}
	
	function validateTask(bool posterTaskCall, uint taskId, Status status) private view {
        validateUser(msg.sender, "Unregistered user");
		require(tasks[taskId].id > 0, "Task not exist");
        require(tasks[taskId].status == status, "Task invalid Status");

        if(posterTaskCall) {
        	require(posterByTaskId[taskId] == msg.sender, "User is not poster from task");
        } else {
            require(posterByTaskId[taskId] != msg.sender, "User is poster from task");
        }               		
	}

    function validateTaskCreate(TaskCreatedParam calldata param) private view {
        validateUser(msg.sender, "Unregistered user");
        require(param.cityId > 0, "invalid city selected");
        require(!compareStr(param.hashIpfsDetails, ""), "invalid hashIpfsDetails, must not be empty");
        require(param.deadlineDate > 0, "invalid deadLineDate");
        require(param.maxAmountLimit > 0, "invalid maxAmountLimit, must be greater than zero");
        require(users[msg.sender].countTask < tasksMaxByAddr, "Exceeded maximum task creation limit by User");
	}

    function validateTaskCreateAndSelectTasker(TaskCreatedParam calldata param, address tasker) private view {
        validateTaskCreate(param);
        validateUser(tasker, "Unregistered user");
        require(tasker != msg.sender, "Tasker can not be Job Poster");
	}

    function validateTaskRefining(bool posterTaskCall, uint taskId, Status status, address tasker, uint256 amountOffer) private view {
		validateTask(posterTaskCall, taskId, status);
        require(taskerByTaskId[taskId] == address(0), "Task already tasker asociated");

        if (posterTaskCall) {
            validateUser(tasker, "Tasker Unregistered");

            TaskRefiner memory taskerRefiner = refinerByTaskIdAndTasker[taskId][tasker];
		    require(taskerRefiner.createDate > 0, "Tasker not request refining for this task");
		    require(taskerRefiner.initDate == 0, "Tasker already refining this task");	
        } else {
            require(amountOffer > 0, "invalid amountOffer, must be greater than zero");
    		require(refinerByTaskIdAndTasker[taskId][msg.sender].createDate == 0, "Tasker already requested refining for this task");
        }
    }

    function validateTaskEscrow(uint taskId, Status status, address tasker, uint256 amount) private view {
		validateTask(true, taskId, status);
        validateUser(tasker, "Tasker Unregistered");
        uint256 amountMorePercent = (amount + calculatePercent(amount, fee));
        require(taskerByTaskId[taskId] == address(0), "Task already tasker asociated");
        require(amountMorePercent == msg.value, "The value sent must be equal to the amount from task plus fee");
            		
        TaskRefiner memory taskerRefiner = refinerByTaskIdAndTasker[taskId][tasker];
        require(taskerRefiner.createDate > 0, "Tasker not request refining for this task");
        require(taskerRefiner.initDate > 0, "Tasker not refining this task");
        require(taskerRefiner.approved, "Tasker not approve this task");
    }

    // **************************** //
    // *     INTEGRATIONS         * //
    // **************************** //

    function proofOfHumanity() private view returns (IProofOfHumanity) {
        return IProofOfHumanity(POH_addr);
    }

    // **************************** //
    // *     MISCELLANEOUS        * //
    // **************************** //

    function reportIlegalTask(uint taskId) external payable {
        Status status = tasks[taskId].status;
        require(status == Status.PROGRESS || status == Status.VALIDATING || status == Status.FINISHED, "Task invalid Status");
        require(tasks[taskId].amount == msg.value,"The value sent must be equal to the amount from task that report ilegal");

        changeStatusTask(taskId, Status.DISPUTE_LEGAL);
        emit DisputeLegal(msg.sender);
    }

    function changeStatusTask(uint taskId, Status newStatus) private {
        Task storage task = tasks[taskId];
		task.status = newStatus;
		
		createHistory(taskId, newStatus);
    }

    function createHistory(uint taskId, Status status) private {
        TaskHistory[] storage taskHistory = tasks[taskId].history;
		TaskHistory memory history = TaskHistory(status, block.timestamp);
		taskHistory.push(history);
    }

    function transferBalance(address payable to, uint256 amount) private {
	    validateTransfer(to, amount);
        to.transfer(amount);
    }

    function compareStr(string memory strA, string memory strB) private pure returns (bool) {
        return keccak256(abi.encodePacked(strA)) == keccak256(abi.encodePacked(strB));
    }

    function calculatePercent(uint256 amount, uint8 percent) private pure returns(uint256) {
        uint256 res = amount / 100;                 
        return res * percent;
    }

    function updateTaskMaxByAddr(uint32 newMaxByAddr) external isOwner {
        tasksMaxByAddr = newMaxByAddr;
    }

    function updateFee(uint8 newFee) external isOwner {
        fee = newFee;
    }

    function updateOwnerSubstitute(address addr) external isOwner {
        ownerSubstitute = addr;
    }

    function updatePOH(address addr) external isOwner {
        POH_addr = addr;
    }
}