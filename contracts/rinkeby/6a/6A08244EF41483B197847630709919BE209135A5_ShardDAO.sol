//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "./AccessControl.sol";

/// @title A decentralized autonomous organization 
/// @notice This is a contract that depicts the features of voting in a decentralized autonomous organization
contract ShardDAO is Pausable, AccessControl {

    /// @notice An event that is emitted when a group of participants is registered
    event Register(address[] particants, string assignedRole, uint registeredAt);

    /// @notice Voted event is emitted after a succesful casting of vote
    event Voted(address voter, uint votedAt);
    
    /// @notice Struct representing all the features of a voting participant
    struct Participant {
        bool voted;
        bool registered;
    }
    
    /// @notice Struct representing all the features of a position contestant
    struct Contestant {
        string contestantName;
        address contestantAddress;
        uint voteCount;
    }

    /// @notice Mapping of addresses to participants
    mapping(address => Participant) public particants;

    /// @notice An array of contestants
    Contestant[] private contestants;

    /// @notice Stores the address of chairman 
    address public chairman;

    /// @notice This is the leadership postion that contestants will be voted for 
    string public nameOfPosition;
    
    // Voting start time
    uint private startTime;

    // Time that voters have to vote since startTime;
    uint private timeToVote;

    /// The vote has been called too late.
    error TooLate();

    /// @notice Total number of vote
    uint256 private totalVoteCount;

    /// @notice Initializes the value of nameOfPosition variable, create and register chairman.
    /// @dev Takes in a string and assings it to nameOfPosition.
    /// @param _nameOfPosition name of position being contested.
    constructor(string memory _nameOfPosition) {
        nameOfPosition = _nameOfPosition;
        chairman = msg.sender;
        particants[chairman] = Participant({voted: false, registered: true});
        _pause();
    }


    modifier whenEnded() {
        require(block.timestamp >= (startTime + timeToVote));
        _;
    }

    modifier whenNotEnded() {
        require(timeToVote > 0, "Wait for election to start");
        if (block.timestamp >= (startTime + timeToVote)) revert TooLate();
        _;
    }

    /// @param contestantName name of contestant to be added.
    /// @param contestantAddress address of contestant to be added.
    /// @dev adds the contestant with an id i
    function addContestant(string[] memory contestantName, address[] memory contestantAddress) public  isChairOrTeach() {
        require(contestantName.length == contestantAddress.length, "Array lengths must match!");
        for (uint i = 0; i < contestantName.length; i++)
         { 
            require(particants[contestantAddress[i]].registered, "Contestant not registered!"); 
            contestants.push(Contestant({
                contestantName: contestantName[i],
                contestantAddress: contestantAddress[i],
                voteCount:0
            }));
        }
    }

    /// @notice Returns details about all the contestants
    /// @dev    Details returned are the one's stored in the blockchain on upload.
    /// @return contestantName names of all contestants.
    /// @return contestantAddress address of all contestants.
    /// @return voteCount of all contestants.
    function getAllContestants() external view
    returns(string[] memory, address[] memory, uint[] memory) {
        uint len = contestants.length;

        string [] memory contestantName = new string[](len);
        address [] memory contestantAddress = new address[](len);
        uint [] memory voteCount = new uint[](len);

        for (uint i = 0; i < len; i++) {
            contestantName[i] = contestants[i].contestantName;
            contestantAddress[i] = contestants[i].contestantAddress;
            voteCount[i] = contestants[i].voteCount;
        }

        return(contestantName, contestantAddress, voteCount);
    }


    /// @notice Changes the name of position being contested for
    /// @dev Reassigns the value of nameOfPosition variable to input string
    /// @param _nameOfPosition new name of position
    /// @return bool a true value if action was successful
    function changeNameOfPosition(string memory _nameOfPosition) public onlyRole(Chairman) returns (bool) {
        nameOfPosition = _nameOfPosition;
        return true;
    }

    /// @notice This function registers group of address as students
    /// @dev Takes in an array of address input and assigns student role
    /// @param students An array of address 
    function registerStudent(address[] memory students) public isChairOrTeach(){
        for (uint i = 0; i < students.length; i++) {
            require(!particants[students[i]].registered, "Student already registered");
            particants[students[i]] = Participant({voted: false, registered: true});
            _grantRole(Students, students[i]);
        }
        emit Register(students, "STUDENT", block.timestamp);
    }

    /// @notice This function registers group of address as board members
    /// @dev Takes in an array of address input and assigns board member role
    /// @param board_members An array of address 
    function registerBoardMember(address[] memory board_members) public isChairOrTeach(){
        for (uint i = 0; i < board_members.length; i++) {
            require(!particants[board_members[i]].registered, "Board Member already registered");
            particants[board_members[i]] = Participant({voted: false, registered: true});
            _grantRole(Board, board_members[i]);
        }
        emit Register(board_members, "BOARD MEMBER", block.timestamp);
    }

    /// @notice This function registers group of address as teachers
    /// @dev Takes in an array of address input and assigns teacher role
    /// @param teachers An array of address 
    function registerTeacher(address[] memory teachers) public isChairOrTeach(){
        for (uint i = 0; i < teachers.length; i++) {
            require(!particants[teachers[i]].registered, "Teacher already registered");
            particants[teachers[i]] = Participant({voted: false, registered: true});
            _grantRole(Teachers, teachers[i]);
        }
        emit Register(teachers, "TEACHER", block.timestamp);
    }
    
    

    /// @notice Cast your vote
    /// @param _contestantId to identify who the voter is voting for
    function vote(uint _contestantId) external 
            whenNotPaused whenNotEnded 
    {
        require(particants[msg.sender].registered, "Not eligible to vote, please register");
        Participant storage voter = particants[msg.sender];
        require(!voter.voted, "Already voted.");
        voter.voted = true;

        // If `_contestantId` is out of the range of the array,
        // this will throw automatically and revert all
        // changes.
        contestants[_contestantId].voteCount += 1;
        totalVoteCount++;
        emit Voted(msg.sender, block.timestamp);
    }

    /// @notice Return total number of votes
    /// @return totalVoteCount 
    function getTotalVoteCount() external view returns (uint){
        return totalVoteCount;
    }

    /// @dev Computes the election results
    function _winningContestant() internal view
            returns (uint winningContestant_)
    {
        uint winningVoteCount = 0;
        for (uint p = 0; p < contestants.length; p++) {
            if (contestants[p].voteCount > winningVoteCount) {
                winningVoteCount = contestants[p].voteCount;
                winningContestant_ = p;
            }
        }
    }

    
    /// @notice returns name and address of the winner
    function winnerNameAndAddress() external isChairOrTeach() whenEnded whenNotPaused
            returns (string memory winnerName_, address winnerAddress_)
    {
        uint index = _winningContestant();
        winnerName_ = contestants[index].contestantName;
        winnerAddress_ = contestants[index].contestantAddress;
        timeToVote = 0;
    }
    
    ///@notice Emergency stop election
    function pause() external onlyRole(Chairman) {
        _pause();
    }

    
    /// @notice Switch to continue the election after an emergency stop`
    function unpause() external onlyRole(Chairman) {
        _unpause();
    }

    /// @dev the passed argument should be the intended duration in seconds
    /// @notice Allows the chairman or teacher role to reset the duration of an election
    /// @param _time the duration of an election
    function setVoteTime(uint _time) public 
            isChairOrTeach() whenEnded
            returns (bool) 
    {
        require(timeToVote > 0, "Only available after election starts");
        timeToVote = _time;
        return true;
    }

    /// @notice Starts the election
    /// @param _time Duration of the election
    function startElection(uint _time) external 
            isChairOrTeach() 
     {
        require(timeToVote == 0, "Election has already started");
        require(contestants.length > 0, "Please register at least one contestant");
        startTime = block.timestamp;
        timeToVote = _time;
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @dev All function calls are currently implemented without side effects
contract AccessControl {

     /** 
     @param role Admin right to be granted
     @param account acoount given admin right
    */
    event GrantRoles(bytes32 indexed role, address indexed account);
    event RemoveRoles(bytes32 indexed role, address indexed account);

    mapping(bytes32 => mapping(address => bool)) public roles;
    
    /// @dev Generates an hash for the Chairman
    //0x76dfba581cd3b5e02cf3469ec59636d3b2bc677066188c2346f32f81a159710
    bytes32 public constant Chairman = keccak256("Chairman");
    
    /// @dev Generates an hash for the Board
    // 0x440f0b4326c1ea763c9f96608623635c8105d5cc0e4b4f20a4e4fe0546b15eeb
    bytes32 public constant Board = keccak256("Board of directors");

    /// @dev Generates an hash for the Teachers
    // 0x24428a7c8016b6f2b3148e1c17f4bed00ad0f5ab53b599683050e4e0aced359b
    bytes32 public constant Teachers = keccak256("Teachers");

    /// @dev Generates an hash for the Students
    // 0x6d7942b32c5633723435ccc7414ccb4e054f91ce4a595460bedf2f56bb0f5a5a
    bytes32 public constant Students = keccak256("Students");

    /// @dev allows execution by the owner only
    modifier onlyRole(bytes32 _role) {
        require(roles[_role][msg.sender], "not authorized");
        _;
    }

    modifier isChairOrTeach() {
        require(roles[Chairman][msg.sender] || roles[Teachers][msg.sender]);
        _;
    }


    /// @notice admin rights are given to the deployer address
    constructor() {
        _grantRole(Chairman, msg.sender);
    }

    /// @notice Internal function for granting roles
    function _grantRole(bytes32 _role, address _account) internal {
        roles[_role][_account] = true; // grant role to the inputed address
        emit GrantRoles(_role, _account);

    }

    /**
     *  @dev Granting an address certain rights.
     *  @param _account  address to be granted _role rights.
     *  @param _role hash for role.
     */
    function grantRole(bytes32 _role, address _account) external onlyRole(Chairman) {
        _grantRole(_role, _account);
    }

    /// @dev verify if an address has chairman rights
    function isChairman(address _address) public view returns (bool) {
        return roles[Chairman][_address];
    }

    /// @dev verify if an address has Board member rights
    function isBoard(address _address) public view returns (bool) {
        return roles[Board][_address];
    }

    /// @dev verify if an address has Teachers rights
    function isTeacher(address _address) public view returns (bool) {
        return roles[Teachers][_address];
    }

    /// @dev verify if an address is a student 
    function isStudent(address _address) public view returns (bool) {
        return roles[Students][_address];
    }
    /// @notice verify if an address is an admin
    function getUserRole(address _address) public view returns (string memory) {
        if (roles[Chairman][_address]) return "Chairman";

        if (roles[Board][_address]) return "Board";

        if (roles[Teachers][_address]) return "Teachers";

        if (roles[Students][_address]) return "Students";
        return "not registered";
    }

    /** 
        @dev allows removal of roles 
        can only be called by the contract owner
        @param _account   address to be removed 
        @param _role hash for role
*/
    function removeRole(bytes32 _role, address _account) external onlyRole(Chairman) {
        roles[_role][_account] = false; // remove role to the inputed address
        emit RemoveRoles(_role, _account);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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