/**
 *Submitted for verification at Etherscan.io on 2022-04-21
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/zuriV.sol


pragma solidity ^0.8.0;


contract ZuriVoting is Ownable{

	struct Voter {
		uint weight;
		bool voted;
		address delegate;
		uint vote;
	}

	struct Candidate {
		uint id;
		string name;
		address candidateAddr;
		uint voteCount;
	}

	mapping(address => Voter) public voters;
	mapping(uint => Candidate) public candidates;

    mapping(address => bool) public studentAddresses;
    mapping(address => bool) public teacherAddresses;

	address public boardOfDirectorsAddresses;

	uint public candidatesCount;
	uint public votersCount;

	string public proposal;
	string public ballotOfficialName;

	string public countResult;

    enum STATUS{INACTIVE,ACTIVE,ENDED}
    STATUS status=STATUS.INACTIVE;
    

	event Voting(uint _start, uint _end);
	event CandidateCreated(uint _id, string _name, address _address);
	event givePermission(address _address);
	event voteFor(address _address, uint _candidateId);
    event AddStakeHolder(address recipient);
    event RemoveStakeHolder(address recipient);

     modifier onlyTeachers(){
        require(teacherAddresses[msg.sender] == true, "Not a Teacher");
        _;
    }

	modifier inStatus(STATUS _status){
		require(status == _status);
		_;
	}

	constructor(string memory _ballotOfficialName, string memory _proposal) {
		boardOfDirectorsAddresses = msg.sender;
		voters[boardOfDirectorsAddresses].weight = 1;
		votersCount++;
        teacherAddresses[msg.sender] = true;
		proposal = _proposal;
		ballotOfficialName = _ballotOfficialName;

		status = STATUS.INACTIVE;	
	}

     function addTeacher(address addr)
	 public
	 onlyOwner
	 returns (bool) {
        teacherAddresses[addr] = true;
        emit AddStakeHolder(addr);
        return true;
    }

     function removeTeacher(address addr)
	 public
	 onlyOwner
	 returns (bool) {
        teacherAddresses[addr] = false;
        emit RemoveStakeHolder(addr);
        return true;
    }

     function electionStatus()
	 public
	 view
	 returns(STATUS){
        return status;
    }

   function startVote() 
   public 
   onlyOwner
   inStatus(STATUS.INACTIVE)
   {
       status=STATUS.ACTIVE;  
    }

   
   function endVote() 
   public 
   onlyOwner
   inStatus(STATUS.ACTIVE)
   {
       status= STATUS.ENDED;
   }

	function addCandidate (address _candidateAddress, string memory _name) 
	public 
	onlyOwner 
	inStatus(STATUS.INACTIVE) 
	returns(bool success) {
		candidatesCount++;
		candidates[candidatesCount] = Candidate(candidatesCount, _name, _candidateAddress, 0);

		emit CandidateCreated(candidatesCount, _name, _candidateAddress);

		return true;
	}

	function delegate(address to) 
	public
	inStatus(STATUS.INACTIVE) 
	{
		Voter storage sender = voters[msg.sender];
		require(!sender.voted, "You already voted.");

		require(to != msg.sender, "Self-delegation is disallowed.");

		while (voters[to].delegate != address(0)) {
			to = voters[to].delegate;

			require(to != msg.sender, "Found loop in delegation.");
		}

		sender.voted = true;
		sender.delegate = to;
		Voter storage delegate_ = voters[to];
		if (delegate_.voted) {
			candidates[delegate_.vote].voteCount += sender.weight;
		} else {
			delegate_.weight += sender.weight;
		}
	}

	function vote(uint _candidateId)
	public
	inStatus(STATUS.ACTIVE)
	returns(bool success) {
		require(voters[msg.sender].weight != 0, 'Has no right to vote');
		require(!voters[msg.sender].voted, 'Already voted.');
		require(_candidateId > 0 && _candidateId <= candidatesCount, 'does not exist candidate by given id');

		voters[msg.sender].voted = true;
		voters[msg.sender].vote = _candidateId;
		candidates[_candidateId].voteCount += voters[msg.sender].weight; 

		votersCount++;
		emit voteFor(msg.sender, _candidateId);

		return true;
	}

	function winningCandidate() 
	public
	view 
	onlyTeachers
	inStatus(STATUS.ENDED) 
	returns (uint winningCandidate_) {
		uint winningVoteCount = 0;
		for (uint i = 1; i <= candidatesCount; i++) {
			if (candidates[i].voteCount > winningVoteCount) {
				winningVoteCount = candidates[i].voteCount;
				winningCandidate_ = i;
			}
		}
	}

	function winnerName() 
	public 
	view 
	onlyTeachers
	inStatus(STATUS.ENDED)
	returns (string memory winnerName_) {
		winnerName_ = candidates[winningCandidate()].name;
	}

	//This function gets the list of candidates and their vote counts
	function getAllCandidates() external view onlyTeachers returns (string[] memory candidateName, uint[] memory votecount) {
    string[] memory names = new string[](candidatesCount);
    uint[] memory voteCounts = new uint[](candidatesCount);
	//loop function that checks gets all availiable candidates info.
    for (uint i = 0; i < candidatesCount; i++) {
        names[i] = candidates[i].name;
        voteCounts[i] = candidates[i].voteCount;
    }
    return (names, voteCounts);
    }

	// This function allow both teachers and the chairperson add students as StackHolder
    function EnrollStudent(address student) 
	public 
	onlyTeachers
	inStatus(STATUS.INACTIVE) 
	returns(bool success){
        require(studentAddresses[student] == false, "already a stakeHolder");
        require(!voters[student].voted,	"The voter already voted.");
		require(voters[student].weight == 0);

		voters[student].weight = 1;

        studentAddresses[student] = true;

		emit givePermission(student);

		return true;
    }

	function getVoteCount(uint index)
    public 
	view
	onlyTeachers
	returns(uint)
	{
    return candidates[index].voteCount;
	}

}