/**
 *Submitted for verification at Etherscan.io on 2022-04-19
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

// File: contracts/vote.sol

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

    address public chairperson;
	uint public candidatesCount;
	uint public votersCount;
	string public name;

    enum STATUS{INACTIVE,ACTIVE,ENDED}
    STATUS status=STATUS.INACTIVE;
    

	event Voting(uint _start, uint _end);
	event CandidateCreated(uint _id, string _name, address _address);
	event givePermission(address _address);
	event voteFor(address _address, uint _candidateId, address _candidateAddress);
    event AddStakeHolder(address recipient);
    event RemoveStakeHolder(address recipient);

    constructor(address _chairperson, string memory _name) public {
		chairperson = _chairperson;
		voters[chairperson].weight = 1;
		votersCount++;
        teacherAddresses[_chairperson] = true;
		name = _name;
	}

     modifier onlyTeachers(){
        require(teacherAddresses[msg.sender] == true, "Not an admin");
        _;
    }

     function addTeacher(address addr) public onlyOwner returns (bool) {
        teacherAddresses[addr] = true;
        emit AddStakeHolder(addr);
        return true;
    }

     function removeTeacher(address addr) public onlyOwner returns (bool) {
        teacherAddresses[addr] = false;
        emit RemoveStakeHolder(addr);
        return true;
    }

     function electionStatus() public view returns(STATUS){
        return status;
    }

   function startVote() public onlyOwner{
       status=STATUS.ACTIVE;  
       }

   
   function endVote() public onlyOwner{
       require(status==STATUS.ACTIVE,"Election has not yet begun");
       status=STATUS.ENDED;
    }

	function addCandidate (address _candidateA, string memory _name) public onlyOwner returns(bool success) {
		candidatesCount++;
		candidates[candidatesCount] = Candidate(candidatesCount, _name, _candidateA, 0);

		emit CandidateCreated(candidatesCount, _name, _candidateA);

		return true;
	}

	function giveRightToVote(address voter) public returns(bool success) {
		require(!voters[voter].voted,	"The voter already voted.");
		require(voters[voter].weight == 0);

		voters[voter].weight = 1;

        studentAddresses[voter] = true;

		emit givePermission(voter);

		return true;
	}

	function delegate(address to) public {
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

	function vote(address _candidateAddress, uint _candidateId) public returns(bool success) {
		require(voters[msg.sender].weight != 0, 'Has no right to vote');
		require(!voters[msg.sender].voted, 'Already voted.');
        require(status==STATUS.ACTIVE,"Election has not yet started/already ended.");
		require(_candidateId > 0 && _candidateId <= candidatesCount, 'does not exist candidate by given id');

		voters[msg.sender].voted = true;
		voters[msg.sender].vote = _candidateId;
		candidates[_candidateId].voteCount += voters[msg.sender].weight; 
		emit voteFor(msg.sender, _candidateId, _candidateAddress);

		return true;
	}

	function winningCandidate() public onlyTeachers returns (uint winningCandidate_) {
        require(status==STATUS.ACTIVE,"Election has not yet started/already ended.");
		uint winningVoteCount = 0;
		for (uint i = 1; i <= candidatesCount; i++) {
			if (candidates[i].voteCount > winningVoteCount) {
				winningVoteCount = candidates[i].voteCount;
				winningCandidate_ = i;
			}
		}
	}

	function winnerName() public onlyTeachers returns (string memory winnerName_) {
        require(status==STATUS.ACTIVE,"Election has not yet started/already ended.");
		winnerName_ = candidates[winningCandidate()].name;
	}

    function getAllCandidates() public view onlyTeachers returns (string[] memory name, uint[] memory votecount) {
    string[] memory names = new string[](candidatesCount);
    uint[] memory voteCounts = new uint[](candidatesCount);
    for (uint i = 0; i < candidatesCount; i++) {
        names[i] = candidates[i].name;
        voteCounts[i] = candidates[i].voteCount;
    }
    return (names, voteCounts);
    }


    function EnrollAsStudent(address student) public onlyTeachers onlyOwner returns(bool success){
        require(studentAddresses[student] == false, "already a stakeHolder");
        require(!voters[student].voted,	"The voter already voted.");
		require(voters[student].weight == 0);

		voters[student].weight = 1;

        studentAddresses[student] = true;

		emit givePermission(student);

		return true;
    }

}