// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Voting is Ownable {
    /**Global Variables and arrays
    */ 
    address public chairman;
    address[] public teachers;
    address[] public BODs;
    address[] public students;
    address[] public stakeholdersList;
    Candidate[] public candidates;
    uint256 electionCount = 0;
    uint256 candidateCount;
    uint256 voterCount;
    bool votingState;
    bool released;
    bool paused;
   

    /// @notice a declaration of different roles available to be assigned to stakeholders
    /// @dev an enum to represent the possible roles an address can take.
    enum Role {
        BOD,
        TEACHER,
        STUDENT,
        CHAIRMAN
    } 

    /// @notice a way to store details of each stakeholder
    /// @dev a struct to store the details of each stakeholder
    /// @param role a variable to store the role of type enum 
    /// @param hasVoted a boolean to store whether a person has voted or not 
    /// @param name a variable to show the candidate's name during election
    struct Stakeholder {
        Role role;
        bool hasVoted; 
        string name;  
    } 


     /// @notice a way to store details of each Candidate
    /// @dev a struct to store the details of each Candidate
    /// @param candidateId a variable to store the id of the candidate 
    /// @param hasVoted a boolean to store whether a person has voted or not 
    /// @param name a variable to show the candidate's name during election
     /// @param slogan a variable to show the candidate's slogan for the election
      /// @param voteCount a variable to show the candidate's votes recieved during election
    struct Candidate {
        address candidateAddress;
        uint256 candidateId;
        string name;
        string slogan;
        uint256 voteCount;
    }

    // Modeling a Election Details
    struct ElectionDetails {
        string name;
        string electivePosition;
        uint256 candidateCount;
        uint256 electionID;
    }

    /// @notice Public Variable to look up stakeholders' addresses
    /// @dev mapping to check for an address in the stakeholder struct
    mapping(address => Stakeholder) public stakeholders; 

    /// @notice Public Variable to look up elections' information
    /// @dev mapping to check for an id in the election struct
    mapping(uint256 => ElectionDetails) public electionDetails; 

    /**
    @notice mappings for access control
    */ 
    mapping (address=>bool) public isTeacher;
    mapping (address=>bool) public isBODMember;
    mapping (address=>bool) public isStudent;
    mapping (address=>bool) public isStakeHolder; 


    mapping(uint256  => Candidate) public candidateDetails;

    /**
    * @notice events emitted for front-end
    */ 
        event TeacherSet(address _teachers);
        event TeacherRemoved(address[] _teachers);
        event StudentSet(address _students);
        event StudentRemoved(address[] _students);
        event BODSet(address  _BODs);
        event BODRemoved(address[] _BODs);


        // @notice this event is emitted when multiple stakeholders are created.
        event CreateMultipleStakeHolders(string message, uint256 _role);
        

    /**
    @notice Modifier for only Chairman access
    */ 

        modifier onlyChairman {
            // Modifier for only chairman access
            require(msg.sender == chairman,"You're not the Chairman!");
            _;
        }
    /**
    @notice Modifier to release results
    */ 

        modifier onlyWhenReleased {
            // Modifier for only chairman access
            require(released, "Results not released yet");
            _;
        }
    /**
    @notice Modifier to release results
    */ 

        modifier NotPaused {
            // Modifier for only chairman access
            require(paused == false, "Contract is Paused");
            _;
        }
    /**
    @notice Modifier for only Chairman, BOD or teacher access
    */ 
        modifier onlyTrustee {
            require(msg.sender == chairman || isBODMember[msg.sender] || isTeacher[msg.sender], "You're not a Trustee Member");
            _;
        }
    /**
    @notice Modifier for only stakeHolders
    */ 
        modifier onlyStakeHolder {
            require(isStakeHolder[msg.sender], "You're not a StakeHolder");
            _;
        }
    /**
    @notice Modifier to ensure voting has started
    */ 
        modifier VotingActive {
            require(votingState, "Voting not allowed.");
            _;
        }
        /**
    @notice Modifier to ensure voting has started
    */ 
    function setChairman(address _chairman) public onlyOwner {
        chairman = _chairman;
    }
    /// @notice create a stakeholder
    /// @dev initialize the stakeholders mapping to roles and push them into their respective arrays
    /// @param _address The address of the impending stakeholder
    /// @param _role parameter taking the input for the role to be assigned to the inputted address
    function createStakeHolder(address _address, uint256 _role, string memory _name)
        public
        onlyChairman
    {
        stakeholders[_address] = Stakeholder(Role(_role), false, _name); //add stakeholders to the mapping
        stakeholdersList.push(_address); // add stakeholder's address to the list of stakeHolders addresses
        if (stakeholders[_address].role == Role(0)) {
            BODs.push(_address);
            isBODMember[_address]= true;
            isStakeHolder[_address]= true;
            emit BODSet(_address);
        }
        if (stakeholders[_address].role == Role(1)) {
            teachers.push(_address);
            isTeacher[_address]= true;
            isStakeHolder[_address]= true;
            emit TeacherSet(_address);
        }
        if (stakeholders[_address].role == Role(2)) {
            students.push(_address);
             isStudent[_address]= true;
             isStakeHolder[_address]= true;
            emit StudentSet(_address);
        }
    }
    /// @notice create multiple stakeholders
    /// @dev use a loop to add an array of addresses into respective roles
    /// @param _addressArray an array of impending stakeholder addresses
    /// @param _role parameter taking the input for the role to be assigned to the inputted address
    function createMultipleStakeHolders(address[] memory _addressArray, uint256 _role, string[] memory _name ) public onlyChairman {
        require(_addressArray.length <= 50, "Can only add a max of 50 stakeholders at a time");
        require(_addressArray.length == _name.length, "The number of addresses and names must tally");
        for (uint256 i = 0; i < _addressArray.length; i++){
            createStakeHolder(_addressArray[i], _role, _name[i]);
        }

        emit CreateMultipleStakeHolders("You just created multiple stakeholders", _role);
    }
   
    /**
        @notice A method to remove an address(es) as a Teacher(s)
        @param _teachers addresses to remove as Teachers.
        */
        function removeTeacher(address [] memory _teachers) public onlyChairman NotPaused {
            require(_teachers.length <= 50, "Can only remove a max of 50 teachers at a time");
            for(uint i = 0; i < _teachers.length; i++) {
            uint index = find(_teachers[i], teachers);
                teachers[index] = teachers[teachers.length - 1];
                teachers.pop();
            uint secondIndex = find(_teachers[i], stakeholdersList); 
                stakeholdersList[secondIndex] = stakeholdersList[stakeholdersList.length - 1];
                stakeholdersList.pop();
                isTeacher[_teachers[i]]= false;
                isStakeHolder[_teachers[i]]= false;
                delete stakeholders[_teachers[i]];
            }
            emit TeacherRemoved(_teachers);
        }

    /**
        @notice A method to remove an address(es) as a student(s)
        @param _students addresses to remove as students.
        */
        function removeStudent(address [] memory _students) public onlyChairman NotPaused{
            require(_students.length <= 50, "Can only remove a max of 50 students at a time");
            for(uint i = 0; i < _students.length; i++) {
            uint index = find(_students[i], students);
                students[index] = students[students.length - 1];
                students.pop();
            uint secondIndex = find(_students[i], stakeholdersList); 
                stakeholdersList[secondIndex] = stakeholdersList[stakeholdersList.length - 1];
                stakeholdersList.pop();
                isStudent[_students[i]]= false;
                isStakeHolder[_students[i]]= false;
                delete stakeholders[_students[i]];
            }
            emit StudentRemoved(_students);
        }

    /**
        @notice A method to remove an address(es) as a BOD(s)
        @param _BOD addresses to remove as BODs.
        */
        function removeBOD(address [] memory _BOD) public onlyChairman NotPaused{
            require(_BOD.length <= 50, "Can only remove a max of 50 BODs at a time");
            for(uint i = 0; i < _BOD.length; i++) {
            uint index = find(_BOD[i], BODs);
                BODs[index] = BODs[BODs.length - 1];
                BODs.pop();
            uint secondIndex = find(_BOD[i], stakeholdersList); 
                stakeholdersList[secondIndex] = stakeholdersList[stakeholdersList.length - 1];
                stakeholdersList.pop();
                isBODMember[_BOD[i]]= false;
                isStakeHolder[_BOD[i]]= false;
                delete stakeholders[_BOD[i]];
            }
            emit BODRemoved(_BOD);
        }



    /**
        @notice A method to iterate through an array and find the index of an element
        @param addr element to find it's index
        @param _array array to loop through
        */
        function find(address addr, address[] memory _array) public pure returns(uint){
            uint i = 0;
            while (_array[i] != addr) {
                i++;
            }
            return i;
        }
//Method to release results
    function ReleaseResults() public onlyChairman NotPaused{
        released = true;
    }
    //Pause contract function
    function PauseContract() public onlyOwner {
        paused = true;
    }
    //Unpuase Contract
    function PlayContract() public onlyOwner {
        paused = false;
    }


    // Adding new candidates
    function addCandidate(address _candidateAddress, string memory _name, string memory _slogan)
        public
        // Only students can not can add
        onlyTrustee
        NotPaused
    {
        Candidate memory newCandidate =
            Candidate({
                candidateAddress: _candidateAddress,
                candidateId: candidateCount,
                name: _name,
                slogan: _slogan,
                voteCount: 0
            });
        candidateDetails[candidateCount] = newCandidate;
        candidates.push(newCandidate);
        candidateCount += 1;
    }


    function setElectionDetails(
        string memory _name,
        string memory _electivePosition
    )
        public
        onlyTrustee // Only students can not add
        NotPaused
    {
        electionCount++;
        electionDetails[electionCount] = ElectionDetails(
            _name,
            _electivePosition,
            candidateCount,
            electionCount
        );
    }

    
    // function getElectionTitle() public view returns (string memory) {
    //     return electionDetails.name;
    // }

    // function getElectionPosition() public view returns (string memory) {
    //     return electionDetails.electivePosition;
    // }

    // Get candidates count
    function getTotalCandidate() public view returns (uint256) {
        // Returns total number of candidates
        return candidateCount;
    }

    // Get voters count
    function getTotalVoter() public view returns (uint256) {
        // Returns total number of voters
        return voterCount;
    }

    // Vote
    function vote(uint256 candidateId) public onlyStakeHolder VotingActive {
     //   require(hasVoted[msg.sender] == false, "You have already voted");
      //  hasVoted[msg.sender] = true;
        candidateDetails[candidateId].voteCount++;
        candidates[candidateId].voteCount++;

    }

    // Start voting
    function startElection() public onlyChairman {
        votingState = true;
    }

    // End voting
    function endElection() public onlyChairman {
        votingState = false;
    }

  function CurrentWinner() public view onlyTrustee
            returns (string memory)
    {
        Candidate memory winningCandidate;
        uint winningVoteCount = 0;
        for (uint i = 0; i < candidates.length; i++) {
            if (candidates[i].voteCount > winningVoteCount) {
                winningCandidate = candidates[i];
            }
        }
    return winningCandidate.name;
    }
   
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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