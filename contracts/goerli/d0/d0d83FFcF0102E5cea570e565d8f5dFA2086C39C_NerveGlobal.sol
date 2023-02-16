/**
 *Submitted for verification at polygonscan.com on 2022-10-12
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

/******************************************/
/*          Context starts here           */
/******************************************/

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/******************************************/
/*          Ownable starts here           */
/******************************************/

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/******************************************/
/*        INerveToken starts here         */
/******************************************/

interface INerveToken {

    // distribute new Nerve tokens in relation to paid fee and current price
    function mintNerve(address _to, uint256 _amount) external;
}

/******************************************/
/*        NerveSocial starts here         */
/******************************************/

contract NerveSocial
{
    mapping(address => bytes32) public addressRegister;
    mapping(bytes32 => address) public nameRegister;
    
    event NameRegistered(address indexed user, bytes32 registeredName);
    event SocialRegistered(address indexed user, string[] socialLinks, string[] socialIds);
    event LocationRegistered(address indexed user, string latitude, string longitude);  
    event UserBlacklisted(address indexed user, address userToBlacklist);

	/**
	 * @dev Register and associate a username with an address
	 * @param registeredName The username to register
	 */
    function registerName(bytes32 registeredName) external
    {
        if (registeredName [0] != 0) 
        {
            require(nameRegister[registeredName] == address(0), "Name already taken.");
            bytes32 actualName;
            if (addressRegister[msg.sender] != 0) 
            {
                actualName = addressRegister[msg.sender]; 
                delete nameRegister[actualName];
            }
            addressRegister[msg.sender] = registeredName;
            nameRegister[registeredName] = msg.sender;

            emit NameRegistered(msg.sender, registeredName);
        }
    }

    function registerSocial(string[] memory socialLinks, string[] memory socialIds) external
    {            
        emit SocialRegistered(msg.sender, socialLinks, socialIds);
    }
    
    function setLocation(string memory latitude, string memory longitude) external
    {
        emit LocationRegistered(msg.sender, latitude, longitude);
    }

    function setBlacklistUser(address userToBlacklist) external
    {
        emit UserBlacklisted(msg.sender, userToBlacklist);
    }
}

/******************************************/
/*         NerveGlobal starts here        */
/******************************************/

contract NerveGlobal is NerveSocial, Ownable
{
    INerveToken nerveToken;
    address nerveBurn;
    uint256 public taskFee = 50;    // denominator 1000
    bool feeActive;

    uint256 internal currentTaskID;
    mapping(uint256 => taskInfo) public tasks;
    
    struct taskInfo 
    {
        uint96 amount;
        uint96 entranceAmount;
        uint40 endTask;
        uint24 participants;
        
        address recipient;
        bool executed;
        bool finished;
        uint24 positiveVotes;
        uint24 negativeVotes;

        mapping(address => uint256) stakes;
        mapping(address => bool) voted;       
    }

    event TaskAdded(address indexed initiator, uint256 indexed taskID, address indexed recipient, uint256 amount, uint256 entranceAmount, string description, uint256 endTask, string language, string latitude, string longitude);
    event TaskJoined(address indexed participant, uint256 indexed taskID, uint256 amount);
    event Voted(address indexed participant, uint256 indexed taskID, bool vote, bool finished);
    event RecipientRedeemed(address indexed recipient, uint256 indexed taskID, uint256 amount);
    event UserRedeemed(address indexed participant, uint256 indexed taskID, uint256 amount);
    event TaskProved(uint256 indexed taskID, string proofLink);

    constructor()
    { 
        currentTaskID = 0;
    }

/******************************************/
/*            Admin starts here           */
/******************************************/

    function initialize(address payable _nerveToken, address _nerveBurn) public onlyOwner
    {
        require(address(nerveToken) == address(0), "Already initialized.");
        nerveToken = INerveToken(_nerveToken);
        nerveBurn = _nerveBurn;
    }

	// Set fee for task interactions (taskFee/1000)
    function setFee(uint256 _taskFee) external onlyOwner
    {
        taskFee = _taskFee;
    }

    function activateFee() external onlyOwner
    {
        require(feeActive == false, "Fee already activated.");
        feeActive = true;
    }

    function setNerveBurn(address _nerveBurn) external onlyOwner
    {
        nerveBurn = _nerveBurn;
    }

/******************************************/
/*          NerveTask starts here         */
/******************************************/

    function createTask(address recipient, string memory description, uint256 duration, string memory language, string memory latitude, string memory longitude) public payable
    {
        require(recipient != address(0), "0x00 address not allowed.");
        require(msg.value != 0, "No stake defined.");

        uint256 stake = msg.value;
        if (feeActive) {
            uint256 fee = msg.value * taskFee / 1000;
            stake = msg.value - fee;
            payable(nerveBurn).transfer(fee);
            nerveToken.mintNerve(msg.sender, fee);
        }

        currentTaskID++;        
        taskInfo storage s = tasks[currentTaskID];
        s.recipient = recipient;
        s.amount = uint96(stake);
        s.entranceAmount = uint96(msg.value);
        s.endTask = uint40(duration + block.timestamp);
        s.participants++;
        s.stakes[msg.sender] = stake;

        emit TaskAdded(msg.sender, currentTaskID, recipient, stake, msg.value, description, s.endTask, language, latitude, longitude);
    }

    function joinTask(uint256 taskID) public payable
    {           
        require(msg.value != 0, "No stake defined.");
        require(tasks[taskID].amount != 0, "Task does not exist.");
        require(tasks[taskID].entranceAmount <= msg.value, "Sent ETH does not match tasks entrance amount.");
        require(tasks[taskID].stakes[msg.sender] == 0, "Already participating in task.");
        require(tasks[taskID].endTask > block.timestamp, "Task participation period has ended." );
        require(tasks[taskID].recipient != msg.sender, "User can't be a task recipient.");
        require(tasks[taskID].finished != true, "Task already finished.");

        uint256 stake = msg.value;
        if (feeActive) {
            uint256 fee = msg.value * taskFee / 1000;
            stake = msg.value - fee;
            payable(nerveBurn).transfer(fee);
            nerveToken.mintNerve(msg.sender, fee);
        }

        tasks[taskID].amount = tasks[taskID].amount + uint96(stake);
        tasks[taskID].stakes[msg.sender] = stake;
        tasks[taskID].participants++;

        emit TaskJoined(msg.sender, taskID, stake);
    }
    
    function voteTask(uint256 taskID, bool vote) public
    { 
        require(tasks[taskID].amount != 0, "Task does not exist.");
        require(tasks[taskID].endTask > block.timestamp, "Task has already ended.");
        require(tasks[taskID].stakes[msg.sender] != 0, "Not participating in task.");
        require(tasks[taskID].voted[msg.sender] == false, "Vote has already been cast.");

        tasks[taskID].voted[msg.sender] = true;
        if (vote) {
            tasks[taskID].positiveVotes++;  
        } else {  
            tasks[taskID].negativeVotes++;                             
        }
        if (tasks[taskID].participants == tasks[taskID].negativeVotes + tasks[taskID].positiveVotes) {
            tasks[taskID].finished = true;
        }

        emit Voted(msg.sender, taskID, vote, tasks[taskID].finished);
    }

    function redeemRecipient(uint256 taskID) public
    {
        require(tasks[taskID].recipient == msg.sender, "This task does not belong to message sender.");
        require(tasks[taskID].endTask <= block.timestamp || tasks[taskID].finished == true, "Task is still running.");
        require(tasks[taskID].positiveVotes >= tasks[taskID].negativeVotes, "Streamer lost the vote.");
        require(tasks[taskID].executed != true, "Task reward already redeemed");

        tasks[taskID].executed = true; 
        if (feeActive) {                                                  
            uint256 fee = uint256(tasks[taskID].amount) * taskFee / 1000;
            payable(msg.sender).transfer(uint256(tasks[taskID].amount) - fee);
            payable(nerveBurn).transfer(fee);
            nerveToken.mintNerve(msg.sender, fee);                                                          
        } else {
            payable(msg.sender).transfer(uint256(tasks[taskID].amount));
        }  

        emit RecipientRedeemed(msg.sender, taskID, tasks[taskID].amount);
        
        delete tasks[taskID];
    }

    function redeemUser(uint256 taskID) public
    {
        require(tasks[taskID].endTask <= block.timestamp || tasks[taskID].finished == true, "Task is still running.");
        require(tasks[taskID].positiveVotes < tasks[taskID].negativeVotes, "Streamer fullfilled the task.");
        require(tasks[taskID].stakes[msg.sender] != 0, "User did not participate or has already redeemed his stakes.");

        uint256 tempStakes = tasks[taskID].stakes[msg.sender];
        tasks[taskID].stakes[msg.sender] = 0;       
        payable(msg.sender).transfer(tempStakes);

        emit UserRedeemed(msg.sender, taskID, tempStakes);
    }

    function proveTask(uint256 taskID, string memory proofLink) public
    {
        require(tasks[taskID].recipient == msg.sender, "Can only be proved by recipient.");

        emit TaskProved(taskID, proofLink);
    }
}