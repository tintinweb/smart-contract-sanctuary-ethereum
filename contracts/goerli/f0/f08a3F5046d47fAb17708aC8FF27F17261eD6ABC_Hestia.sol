/**
 *Submitted for verification at Etherscan.io on 2023-03-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.18;

interface IProofOfHumanity {
    // https://etherscan.io/address/0xc5e9ddebb09cd64dfacab4011a0d5cedaf7c9bdb
    function isRegistered(address _submissionID) external view returns (bool);
}

contract Hestia {

    /*
	E001: Caller is not owner
	E002: No call data provided
	E003: User already exists
	E004: Unregistered user
	E005: Invalid amount, must be greater than zero
	E006: Tasker without staking enough for all tasks
	E007: Invalid hashIpfsResults, must not be empty
	E008: Error transfer to the zero address
	E009: Error amount balance
	E010: User is not staking
	E011: The amount is higher than the staking
	E012: The staking result no can be less to staking required
	E013: Task not exist
	E014: Task invalid Status
	E015: User is not poster from task
	E016: User is poster from task
	E017: Invalid hashIpfsDetails, must not be empty
	E018: Task invalid Type
	E019: Tasker can not be Job Poster
	E020: Invalid hashIpfsRefined, must not be empty
	E021: Tasker not approve this task
	E022: The value sent must be equal to the amount from task plus fee
	E023: Invalid value for percent payout Tasker
	E024: Error amount balance in vault
	E025: Error amount balance in contract
    E026: Task invalid City
    E027: Task already exists
    */

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
        string taskId;
    }

    struct User {
        string nickname;
        uint8 roleId;
        string skills;
        uint totalStakingRequired;
        Rating[] ratings;
    }

    struct Task {
        string id;
        uint num;
		uint amount;
        uint8 typeId;
        uint32 cityId;
        uint16 limitDays;
        string description;
        Status status;
        uint taskerStakingRequired;
        string hashIpfsDetails;
        string hashIpfsRefined;
        string hashIpfsResults;
    }

    address private owner;
    address private ownerSubstitute1;
    address private ownerSubstitute2;
    uint private tasksCount;
    uint8 private fee;
    uint8 private percentageOfStakingPerTaskWithPOH;
    uint8 private percentageOfStakingPerTaskWithoutPOH;
    uint private vault;
    uint private totalStaking;
    address private POH_addr;
 
    mapping(address => User) private users;
    mapping(address => bool) private joinedUsers;
	mapping(address => uint) private stakingAmountByUser;
	mapping(string => Task) private tasks;
    mapping(string => address) private taskerByTaskId; 
    mapping(string => address) private posterByTaskId; 
	mapping(string => mapping(address => uint)) private amountOfferByTaskIdAndTaskerAddr; 
	
    event Joined(address user, string nickname, uint8 roleId, string skills);
    event Staking(address user, uint amountInStaking);
    event Created(address poster, string taskId, uint num, uint8 typeId, uint32 cityId, uint amount, uint16 limitDays, string description, string hashIpfsDetails);
    event CreatedAndSelect(address poster, string taskId, uint num, uint8 typeId, uint32 cityId, uint amount, uint16 limitDays, string description, string hashIpfsDetails, address tasker);
    event Cancelled(address poster, string taskId);
    event Refining(address tasker, string taskId, uint amountOffer);
    event Progress(address poster, string taskId, address tasker, uint taskerStakingRequired, string hashIpfsRefined);
    event Validating(address tasker, string taskId, uint8 ratingScorePoster, uint8 ratingMessageIdPoster, string hashIpfsResults);
    event Finished(address poster, string taskId, uint8 ratingScoreTasker, uint8 ratingMessageIdTasker);
    event DisputeProgress(address user, string taskId);
    event DisputeFinish(address user, string taskId);
    event DisputeLegal(address user, string taskId);
    event ResolveDispute(address user, string taskId);

    modifier isOwner() {
        require(msg.sender == owner || msg.sender == ownerSubstitute1 || msg.sender == ownerSubstitute2, "E001");
        _; 
    }

    constructor() {
        owner = msg.sender;
        percentageOfStakingPerTaskWithPOH = 10;
        percentageOfStakingPerTaskWithoutPOH = 30; 
        fee = 2;
        POH_addr = 0xB44F8c0B9De6605DB1259e3755923c063D6bD11d;
    }

    receive() external payable {
        revert("E002");
    }

    fallback() external {
        revert("E002");
    }

    // **************************** //
    // *     LOGIN                * //
    // **************************** //

    function join(string calldata nickname, uint8 roleId, string calldata skills) external {
        require(!joinedUsers[msg.sender], "E003");
        users[msg.sender].nickname = nickname;
        users[msg.sender].roleId = roleId;
        users[msg.sender].skills = skills;
        joinedUsers[msg.sender] = true;
        emit Joined(msg.sender, nickname, roleId, skills);
    }

    // **************************** //
    // *     STAKING              * //
    // **************************** //

    function stake() external payable { 
        validateUser(msg.sender, "E004");
        stakingAmountByUser[msg.sender] += msg.value;
        totalStaking += msg.value;
        emit Staking(msg.sender, stakingAmountByUser[msg.sender]);
    }

    function unstake(uint256 amount) external {
        validateUnStaking(amount);
        stakingAmountByUser[msg.sender] -= amount;
        totalStaking -= amount;
        transferBalance(payable(msg.sender), amount);
        emit Staking(msg.sender, stakingAmountByUser[msg.sender]);
    }

    // **************************** //
    // *     CREATE TASK          * //
    // **************************** //
    function createTask(string memory taskId, uint8 typeId, uint32 cityId, uint amount, uint16 limitDays, string memory description, string memory hashIpfsDetails) public {
        _createTask(taskId, typeId, cityId, amount, limitDays, description, hashIpfsDetails);
        emit Created(msg.sender, taskId, tasks[taskId].num, typeId, cityId, amount, limitDays, description, hashIpfsDetails);   
    }

    function createTaskAndSelectTasker(string memory taskId, uint8 typeId, uint32 cityId, uint amount, uint16 limitDays, string memory description, string memory hashIpfsDetails, address tasker) external {
        validateUser(tasker, "E004");
        require(tasker != msg.sender, "E019");
        _createTask(taskId, typeId, cityId, amount, limitDays, description, hashIpfsDetails);
        emit CreatedAndSelect(msg.sender, taskId, tasks[taskId].num, typeId, cityId, amount, limitDays, description, hashIpfsDetails, tasker); 
    }

    function _createTask(string memory taskId, uint8 typeId, uint32 cityId, uint amount, uint16 limitDays, string memory description, string memory hashIpfsDetails) private {
        validateTaskCreate(taskId, typeId, cityId, amount, hashIpfsDetails);
        tasksCount++;
        tasks[taskId].id = taskId;
        tasks[taskId].num = tasksCount;
        tasks[taskId].status = Status.NEW;
        tasks[taskId].typeId = typeId;
        tasks[taskId].cityId = cityId;
        tasks[taskId].amount = amount;
        tasks[taskId].limitDays = limitDays;
        tasks[taskId].description = description;
        tasks[taskId].hashIpfsDetails = hashIpfsDetails;
        posterByTaskId[taskId] = msg.sender; 
    }

    function cancelTask(string memory taskId) external {
        validateTask(true, taskId, Status.NEW);
        changeStatusTask(taskId, Status.CANCELLED);
        emit Cancelled(msg.sender, taskId);
    }

    // **************************** //
    // *     REFINING             * //
    // **************************** //
	
	function taskerMakeOffer(string memory taskId, uint amountOffer) external {
        validateTask(false, taskId, Status.NEW);
        require(amountOffer > 0, "E005");
        amountOfferByTaskIdAndTaskerAddr[taskId][msg.sender] = amountOffer;
        uint8 percOfStaking = proofOfHumanity().isRegistered(msg.sender) ? percentageOfStakingPerTaskWithPOH : percentageOfStakingPerTaskWithoutPOH;
        uint totalStakingRequired = users[msg.sender].totalStakingRequired + calculatePercent(amountOffer, percOfStaking);
        require(stakingAmountByUser[msg.sender] >= totalStakingRequired, "E006");
        emit Refining(msg.sender, taskId, amountOffer);
    }

    // **************************** //
    // *     ESCROW               * //
    // **************************** //

	function approveTaskerAndEscrow(string memory taskId, address tasker, string memory hashIpfsRefined) external payable {
        validateTaskEscrow(taskId, Status.NEW, hashIpfsRefined, tasker);
        uint amount = amountOfferByTaskIdAndTaskerAddr[taskId][tasker];
		tasks[taskId].amount = amount;
        tasks[taskId].hashIpfsRefined = hashIpfsRefined;
        taskerByTaskId[taskId] = tasker; 
        uint8 percOfStaking = proofOfHumanity().isRegistered(tasker) ? percentageOfStakingPerTaskWithPOH : percentageOfStakingPerTaskWithoutPOH;
        tasks[taskId].taskerStakingRequired = calculatePercent(amount, percOfStaking);
        users[tasker].totalStakingRequired += tasks[taskId].taskerStakingRequired;
        vault += calculatePercent(amount, fee);
        changeStatusTask(taskId, Status.PROGRESS);
        emit Progress(msg.sender, taskId, tasker, tasks[taskId].taskerStakingRequired, hashIpfsRefined);
    }	

    function disputeProgress(string memory taskId) external {
        validateTask(true, taskId, Status.PROGRESS);
        changeStatusTask(taskId, Status.DISPUTE_PROGRESS);
        emit DisputeProgress(msg.sender, taskId);
    }

    // **************************** //
    // *     FINISH               * //
    // **************************** //

	function taskerFinish(string memory taskId, uint8 ratingScorePoster, uint8 ratingMessageIdPoster, string memory hashIpfsResults) external {
        validateTask(false, taskId, Status.PROGRESS);
        require(!compareStr(hashIpfsResults, ""), "E007");
        tasks[taskId].hashIpfsResults = hashIpfsResults;
        Rating[] storage ratings = users[posterByTaskId[taskId]].ratings;
        ratings.push(Rating(ratingScorePoster, ratingMessageIdPoster, taskId));
        changeStatusTask(taskId, Status.VALIDATING);
        emit Validating(msg.sender, taskId, ratingScorePoster, ratingMessageIdPoster, hashIpfsResults);
    }

    function approveFinish(string memory taskId, uint8 ratingScoreTasker, uint8 ratingMessageIdTasker) external {
        validateTask(true, taskId, Status.VALIDATING);
        address taskerAddr = taskerByTaskId[taskId];
        users[taskerAddr].totalStakingRequired -= tasks[taskId].taskerStakingRequired;
        transferBalance(payable(taskerAddr), tasks[taskId].amount);
        Rating[] storage ratings = users[taskerAddr].ratings;
        ratings.push(Rating(ratingScoreTasker, ratingMessageIdTasker, taskId));
        changeStatusTask(taskId, Status.FINISHED);
        emit Finished(msg.sender, taskId, ratingScoreTasker, ratingMessageIdTasker);
    }

    function disapproveFinish(string memory taskId) external {
        validateTask(true, taskId, Status.VALIDATING);
        changeStatusTask(taskId, Status.DISPUTE_RESULTS);
        emit DisputeFinish(msg.sender, taskId);
    }

    // **************************** //
    // *     VALIDATE             * //
    // **************************** //
	
    function validateTransfer(address to, uint amount) private view {
        require(to != address(0), "E008");
		require(address(this).balance >= amount, "E009"); 
    }

	function validateUser(address addr, string memory error) private view {
        require(joinedUsers[addr], error);
	}

    function validateUnStaking(uint amount) private view {
        validateUser(msg.sender, "E004");
        require(stakingAmountByUser[msg.sender] > 0, "E010");
        require(stakingAmountByUser[msg.sender] >= amount, "E011");
        require(users[msg.sender].totalStakingRequired <= (stakingAmountByUser[msg.sender] - amount), "E012");
	}
	
	function validateTask(bool posterTaskCall, string memory taskId, Status status) private view {
        validateUser(msg.sender, "E004");
	    require(!compareStr(tasks[taskId].id, ""), "E013");
        require(tasks[taskId].status == status, "E014");

        if(posterTaskCall) {
        	require(posterByTaskId[taskId] == msg.sender, "E015");
        } else {
            require(posterByTaskId[taskId] != msg.sender, "E016");
        }               		
	}

    function validateTaskCreate(string memory taskId, uint8 typeId, uint32 cityId, uint amount, string memory hashIpfsDetails) private view {
        validateUser(msg.sender, "E004");
	    require(compareStr(tasks[taskId].id, ""), "E027");
        require(typeId > 0, "E018");
        require(cityId > 0, "E026");
        require(amount > 0, "E005");
        require(!compareStr(hashIpfsDetails, ""), "E017");
	}

    function validateTaskEscrow(string memory taskId, Status status, string memory hashIpfsRefined, address tasker) private view {
		validateTask(true, taskId, status);
        validateUser(tasker, "E004");
        require(!compareStr(hashIpfsRefined, ""), "E020");

        uint amount = amountOfferByTaskIdAndTaskerAddr[taskId][tasker];
        require(amount > 0, "E021");
        require((amount + calculatePercent(amount, fee)) == msg.value, "E022");
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

    function changeStatusTask(string memory taskId, Status newStatus) private {
        tasks[taskId].status = newStatus;
    }

    function transferBalance(address payable to, uint amount) private {
	    validateTransfer(to, amount);
        to.transfer(amount);
    }

    function compareStr(string memory strA, string memory strB) private pure returns (bool) {
        return keccak256(abi.encodePacked(strA)) == keccak256(abi.encodePacked(strB));
    }

    function calculatePercent(uint amount, uint8 percent) private pure returns(uint256) {
        uint res = amount / 100;                 
        return res * percent;
    }

    function updateFee(uint8 newFee) external isOwner {
        fee = newFee;
    }

    function updatePercentageOfStakingPerTaskWithPOH(uint8 newPercentage) external isOwner {
        percentageOfStakingPerTaskWithPOH = newPercentage;
    }

    function updatePercentageOfStakingPerTaskWithoutPOH(uint8 newPercentage) external isOwner {
        percentageOfStakingPerTaskWithoutPOH = newPercentage;
    }

    function updatePOH(address addr) external isOwner {
        POH_addr = addr;
    }

    function updateOwnerSubstitute1(address addr) external isOwner {
        ownerSubstitute1 = addr;
    }
    
    function updateOwnerSubstitute2(address addr) external isOwner {
        ownerSubstitute2 = addr;
    }

    function resolveDispute(string memory taskId, uint8 percentPayoutTasker) external isOwner {
		require(!compareStr(tasks[taskId].id, ""), "E013");
        require(percentPayoutTasker <= 100, "E023");
        require(tasks[taskId].status == Status.DISPUTE_PROGRESS || tasks[taskId].status == Status.DISPUTE_RESULTS, "E014");

        users[taskerByTaskId[taskId]].totalStakingRequired -= tasks[taskId].taskerStakingRequired;
        uint payoutTasker = calculatePercent(tasks[taskId].amount, percentPayoutTasker);
        uint refundPoster = tasks[taskId].amount-payoutTasker;

        if (payoutTasker > 0) {
            transferBalance(payable(taskerByTaskId[taskId]), payoutTasker);
        }
        if (refundPoster > 0) {
            transferBalance(payable(posterByTaskId[taskId]), refundPoster);
        }

        changeStatusTask(taskId, Status.FINISHED);
        emit ResolveDispute(msg.sender, taskId);
    }

    function withdrawalVault(address payable to, uint amount) external isOwner {
        require(vault >= amount, "E024"); 
        require(address(this).balance >= amount, "E025");
        vault -= amount;
        to.transfer(amount);
    }
}