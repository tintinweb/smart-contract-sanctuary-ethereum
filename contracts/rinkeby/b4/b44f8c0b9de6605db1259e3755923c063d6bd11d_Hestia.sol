/**
 *Submitted for verification at Etherscan.io on 2022-06-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.13;

interface IProofOfHumanity {
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
        string description;
    }

    struct User {
        string nickname;
        uint createDate;
        bool poh;
        uint256 totalStakingRequired;
        uint8 percentageOfStakingPerTask;
        Rating[] ratings;
    }

    struct TaskRefiner {
		uint createDate;
		uint initDate;
	}

    struct TaskCreatedParam {
        string city;
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
        string ratingDescriptionPoster;
        string hashIpfsResults;
    }
	
	struct TaskHistory {
		Status status;
		uint createDate;
	}

    struct Task {
        uint id;
        Status status;
		string city;
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
    uint tasksCount;
    uint256 vault;
    uint8 fee;
    address POH_addr;

    mapping(address => User) private users;
    mapping(address => bool) private joinedUsers;
	mapping(address => uint256) private stakingAmountByUser;
	mapping(uint => Task) private tasks;
    mapping(uint => address) private taskerByTaskId; 
    mapping(uint => address) private posterByTaskId; 
	mapping(uint => mapping(address => TaskRefiner)) private refinerByTaskIdAndTasker; 
    
    //For validate quantity task to create by address
    mapping(address => uint[]) private taskIdsByPoster;
    uint32 tasksMaxByAddr;
	
    event UserJoined(address, string);
    event UserStaking(address, uint256);
    event TaskCreated(address, uint);
	event EscrowCreated(address);
    event WithdrawalCreated(address);
    event ValidatingCreated(address);
    event ApproveFinish(address);
    event OpenDisputeProgress(address);
    event OpenDisputeFinish(address);
    event OpenDisputeLegal(address);

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _; 
    }

    constructor() {
        owner = msg.sender;
        tasksMaxByAddr = 1000;
        fee = 2;
        POH_addr = 0xC5E9dDebb09Cd64DfaCab4011A0D5cEDaf7c9BDb;
    }

    receive() external payable {
        revert("No call data provided");
    }

    fallback() external {
        revert("No call data provided");
    }

    ///
    /// LOGIN
    ///

    function join(string calldata nickname) external {
        require(!joinedUsers[msg.sender], "User already exists");
		
        User storage newUser = users[msg.sender];
        newUser.nickname = nickname;

        // if (isRegisteredInPOH(msg.sender)) {
        //     newUser.poh = true;
        //     newUser.percentageOfStakingPerTask = 30;
        // } else {
        //     newUser.percentageOfStakingPerTask = 50;
        //     newUser.poh = false;
        // }

        newUser.percentageOfStakingPerTask = 50;
        newUser.poh = false;
        newUser.createDate = block.timestamp;
        joinedUsers[msg.sender] = true;
		
        emit UserJoined(msg.sender, nickname);
    }

    function getUser(address addr) external view returns (User memory) {
        return users[addr];
    }    

    ///
    /// STAKING
    ///

    function stake() external payable { 
        validateUser(msg.sender, "Unregistered user");
        stakingAmountByUser[msg.sender] += msg.value;
        emit UserStaking(msg.sender, stakingAmountByUser[msg.sender]);
    }

    function unstake(uint256 amount) external {
        validateUnStaking(amount);
        stakingAmountByUser[msg.sender] -= amount;
        transferBalance(payable(msg.sender), amount);
        emit UserStaking(msg.sender, stakingAmountByUser[msg.sender]);
    }

    ///
    /// CREATE TASK
    ///

    function createTask(TaskCreatedParam calldata param) external {
        validateTaskCreate(param);
        tasksCount++;
        uint id = tasksCount; 
    
        Task storage newTask = tasks[id];
        newTask.id = id;
        newTask.status = Status.NEW;
        newTask.city = param.city;
        newTask.deadlineDate = param.deadlineDate;
        newTask.maxAmountLimit = param.maxAmountLimit;
        newTask.hashIpfsDetails = param.hashIpfsDetails;
        newTask.createDate = block.timestamp;

        posterByTaskId[id] = msg.sender;
        taskIdsByPoster[msg.sender].push(id);
				
        emit TaskCreated(msg.sender, id);   
    }

    function getTask(uint id) public view returns (Task memory) {
        return tasks[id];
    }
	
	///
    /// REFINING
    ///
	
	function taskerRequestRefining(uint taskId) external {
        validateTaskRefining(false, taskId, Status.NEW, address(0));
		refinerByTaskIdAndTasker[taskId][msg.sender].createDate = block.timestamp;	
    }    
	
	function selectTaskerRefining(uint taskId, address tasker) external {
        validateTaskRefining(true, taskId, Status.NEW, tasker);
		refinerByTaskIdAndTasker[taskId][tasker].initDate = block.timestamp;
    }    

    ///
    /// ESCROW
    ///

	function approveTaskerAndEscrow(TaskApprovedParam calldata param) external payable {
        validateTaskEscrow(true, param.taskId, Status.NEW, param.tasker, param.amount);
		
		tasks[param.taskId].amount = param.amount;
        tasks[param.taskId].hashIpfsRefined = param.hashIpfsRefined;
        taskerByTaskId[param.taskId] = param.tasker; 

        vault += calculatePercent(param.amount, fee);
		
		emit EscrowCreated(msg.sender);
    }  

    function disapproveTaskerAndWithdrawal(uint taskId) external {
        validateTask(true, taskId, Status.NEW);
		
		uint256 amount = tasks[taskId].amount;
        tasks[taskId].amount = 0;
        taskerByTaskId[taskId] = address(0);

        vault -= calculatePercent(amount, fee);

        transferBalance(payable(msg.sender), amount);
		
		emit WithdrawalCreated(msg.sender);
    }  
	
	function taskerApprove(uint taskId) external {
        validateTaskEscrow(false, taskId, Status.NEW, address(0), tasks[taskId].amount);

        users[msg.sender].totalStakingRequired += calculatePercent(tasks[taskId].amount, users[msg.sender].percentageOfStakingPerTask);
        
        require(stakingAmountByUser[msg.sender] >= users[msg.sender].totalStakingRequired, "Tasker without staking enough for all tasks");

        changeStatusTask(taskId, Status.PROGRESS);
        emit EscrowCreated(msg.sender);
    }

    function disputeProgress(uint taskId) external {
        validateTask(true, taskId, Status.PROGRESS);
        changeStatusTask(taskId, Status.DISPUTE_PROGRESS);
        emit OpenDisputeProgress(msg.sender);
    }

    ///
    /// FINISH
    ///

	function taskerFinish(TaskFinishedParam calldata param) external {
        validateTask(false, param.taskId, Status.PROGRESS);
			
        tasks[param.taskId].hashIpfsResults = param.hashIpfsResults;

        Rating[] storage ratings = users[posterByTaskId[param.taskId]].ratings;
        ratings.push(Rating(param.ratingScorePoster, param.ratingDescriptionPoster));

        changeStatusTask(param.taskId, Status.VALIDATING);
        emit ValidatingCreated(msg.sender);
    }

    function approveFinish(uint taskId, uint8 ratingScoreTasker, string calldata ratingDescriptionTasker) external {
        validateTask(true, taskId, Status.VALIDATING);

        address taskerAddr = taskerByTaskId[taskId];

        users[taskerAddr].totalStakingRequired -= calculatePercent(tasks[taskId].amount, users[taskerAddr].percentageOfStakingPerTask);

        transferBalance(payable(taskerAddr), tasks[taskId].amount);

        Rating[] storage ratings = users[taskerAddr].ratings;
        ratings.push(Rating(ratingScoreTasker, ratingDescriptionTasker));

        changeStatusTask(taskId, Status.FINISHED);
        emit ApproveFinish(msg.sender);
    }

    function disapproveFinish(uint taskId) external {
        validateTask(true, taskId, Status.VALIDATING);
        changeStatusTask(taskId, Status.DISPUTE_RESULTS);
        emit OpenDisputeFinish(msg.sender);
    }

    ///
    /// VALIDATE
    ///
	
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
        require(!compareStr(param.city, ""), "invalid city selected");
        require(!compareStr(param.hashIpfsDetails, ""), "invalid hashIpfsDetails, must not be empty");
        require(param.deadlineDate > 0, "invalid deadLineDate");
        require(param.maxAmountLimit > 0, "invalid maxAmountLimit, must be greater than zero");
        require(taskIdsByPoster[msg.sender].length < tasksMaxByAddr, "Exceeded maximum task creation limit by User");      		
	}

    function validateTaskRefining(bool posterTaskCall, uint taskId, Status status, address tasker) private view {
		validateTask(posterTaskCall, taskId, status);
        require(taskerByTaskId[taskId] == address(0), "Task already tasker asociated");

        if (posterTaskCall) {
            validateUser(tasker, "Tasker Unregistered");

            TaskRefiner memory taskerRefiner = refinerByTaskIdAndTasker[taskId][tasker];
		    require(taskerRefiner.createDate > 0, "Tasker not request refining for this task");
		    require(taskerRefiner.initDate == 0, "Tasker already refining this task");	
        } else {
    		require(refinerByTaskIdAndTasker[taskId][msg.sender].createDate == 0, "Tasker already requested refining for this task");
        }
    }

    function validateTaskEscrow(bool posterTaskCall, uint taskId, Status status, address tasker, uint256 amount) private view {
		validateTask(posterTaskCall, taskId, status);

        if(posterTaskCall) {
            validateUser(tasker, "Tasker Unregistered");
            require(taskerByTaskId[taskId] == address(0), "Task already tasker asociated");
            require((amount + calculatePercent(amount, fee)) == msg.value, "The value sent must be equal to the amount from task more fee");
            		
            TaskRefiner memory taskerRefiner = refinerByTaskIdAndTasker[taskId][tasker];
            require(taskerRefiner.createDate > 0, "Tasker not request refining for this task");
            require(taskerRefiner.initDate > 0, "Tasker not refining this task");	
        } else {
            require(taskerByTaskId[taskId] == msg.sender, "Tasker is not selected by poster task");
        }      
    }

    ///
    /// MISCELLANEOUS
    ///

    function reportIlegalTask(uint taskId) external payable {
        Status status = tasks[taskId].status;
        require(status == Status.PROGRESS || status == Status.VALIDATING || status == Status.FINISHED, "Task invalid Status");
        require(tasks[taskId].amount == msg.value,"The value sent must be equal to the amount from task that report ilegal");

        changeStatusTask(taskId, Status.DISPUTE_LEGAL);
        emit OpenDisputeLegal(msg.sender);
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

    function isRegisteredInPOH(address submissionID) private view returns (bool) {
        return IProofOfHumanity(POH_addr).isRegistered(submissionID);
    }

    function compareStr(string memory strA, string memory strB) private pure returns (bool) {
        return keccak256(abi.encodePacked(strA)) == keccak256(abi.encodePacked(strB));
    }

    function calculatePercent(uint256 amount, uint8 percent) private pure returns(uint256) {
        return amount / 100 * percent;
    }

    function updateTaskMaxByAddr(uint32 newMaxByAddr) external isOwner {
        tasksMaxByAddr = newMaxByAddr;
    }

    function updateFee(uint8 newFee) external isOwner {
        fee = newFee;
    }

    function updatePOH(address addr) external isOwner {
        POH_addr = addr;
    }

    function withdrawalVault(address payable to, uint256 amount) external isOwner {
        require(address(this).balance >= amount, "Error amount balance in contract");
        require(vault >= amount, "Error amount balance in vault"); 
        vault -= amount;
        to.transfer(amount);
    }
}