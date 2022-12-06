/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

// File: IVoteD21.sol


pragma solidity 0.8.9;

interface IVoteD21{
    
    struct Subject{
        string name;
        int votes;
    }
    
    function addSubject(string memory name) external;
    function addVoter(address addr) external;
    function getSubjects() external view returns(address[] memory);
    function getSubject(address addr) external view returns(Subject memory);
    function votePositive(address addr) external;
    function voteNegative(address addr) external;
    function getRemainingTime() external view returns (uint256);
    function getResults() external view returns(Subject[] memory);
}
// File: D21.sol


pragma solidity 0.8.9;


error UnregisteredVoter();
error NonExistentSubject();
error NoRemainingTime();
error AlreadyRegisteredSubject();
error OwnerOnly();
error VoteForSameSubjectTwice();
error AlreadyAllowedToVote();
error NoMorePositiveVotes();
error NoMoreNegativeVotes();
error NegativeVotesAfterTwoPositive();

// TODO: https://ethereum.stackexchange.com/questions/13167/are-there-well-solved-and-simple-storage-patterns-for-solidity

contract D21 is IVoteD21 {
    struct SubjectEntity {
        bool exists;
        Subject subject;
    }

    struct VotingLimitsEntity {
        bool allowedToVote;
        bool votedNegativelyOnce;
        address secondVoteAddress;
        address firstVoteAddress;
    }

    mapping(address => SubjectEntity) private _subjectStructs;
    address[] private _subjectList;
    mapping(address => VotingLimitsEntity) private _allowances;

    uint256 immutable votingEndDate;
    address immutable owner;

    constructor() {
        votingEndDate = (block.timestamp + 1 weeks);
        owner = msg.sender;
    }

    modifier onlyAllowedToVote() {
        if (!_allowances[msg.sender].allowedToVote) {
            revert UnregisteredVoter();
        }
        _;
    }

    modifier onlyInVotingPeriod() {
        if (votingEndDate <= block.timestamp) {
            revert NoRemainingTime();
        }
        _;
    }

    modifier onlyExistingSubject(address addr) {
        if (!_subjectStructs[addr].exists) {
            revert NonExistentSubject();
        }
        _;
    }

    function addSubject(string memory name) external onlyInVotingPeriod {
        SubjectEntity storage subject = _subjectStructs[msg.sender];
        if (subject.exists) {
            revert AlreadyRegisteredSubject();
        }

        subject.subject.name = name;
        subject.exists = true;
        _subjectList.push(msg.sender);
    }

    // Add a new voter into the voting system.
    function addVoter(address addr) external onlyInVotingPeriod {
        if (msg.sender != owner) {
            revert OwnerOnly();
        }
        if (_allowances[addr].allowedToVote) {
            revert AlreadyAllowedToVote();
        }
        _allowances[addr].allowedToVote = true;
    }

    // Get addresses of all registered subjects.
    function getSubjects() external view returns (address[] memory) {
        return _subjectList;
    }

    // Get the subject details.
    function getSubject(address addr)
        external
        view
        onlyExistingSubject(addr)
        returns (Subject memory)
    {
        return _subjectStructs[addr].subject;
    }

    // Vote positive for the subject.
    function votePositive(address addr)
        external
        onlyAllowedToVote
        onlyExistingSubject(addr)
        onlyInVotingPeriod
    {
        VotingLimitsEntity storage voting = _allowances[msg.sender];
        if (voting.firstVoteAddress == address(0)) {
            voting.firstVoteAddress = addr;
        } else if (voting.secondVoteAddress == address(0)) {
            if (voting.firstVoteAddress == addr) {
                revert VoteForSameSubjectTwice();
            }
            voting.secondVoteAddress = addr;
        } else {
            revert NoMorePositiveVotes();
        }
        _subjectStructs[addr].subject.votes++;
    }

    // Vote negative for the subject.
    function voteNegative(address addr)
        external
        onlyAllowedToVote
        onlyExistingSubject(addr)
        onlyInVotingPeriod
    {
        VotingLimitsEntity storage voting = _allowances[msg.sender];
        if (voting.votedNegativelyOnce) {
            revert NoMoreNegativeVotes();
        }
        if (
            voting.firstVoteAddress == address(0) ||
            voting.secondVoteAddress == address(0)
        ) {
            revert NegativeVotesAfterTwoPositive();
        }
        if (
            addr == voting.firstVoteAddress || addr == voting.secondVoteAddress
        ) {
            revert VoteForSameSubjectTwice();
        }

        voting.votedNegativelyOnce = true;
        _subjectStructs[addr].subject.votes--;
    }

    function quickPart(
        Subject[] memory data,
        uint256 low,
        uint256 high
    ) internal pure {
        if (low < high) {
            int256 pivotVal = data[(low + high) / 2].votes;

            uint256 low1 = low;
            uint256 high1 = high;
            for (;;) {
                while (data[low1].votes > pivotVal) low1++;
                while (data[high1].votes < pivotVal) high1--;
                if (low1 >= high1) break;
                (data[low1], data[high1]) = (data[high1], data[low1]);
                low1++;
                high1--;
            }
            if (low < high1) quickPart(data, low, high1);
            high1++;
            if (high1 < high) quickPart(data, high1, high);
        }
    }

    // Get the voting results, sorted descending by votes.
    function getResults() external view returns (Subject[] memory) {
        Subject[] memory result = new Subject[](_subjectList.length);
        uint256 length = _subjectList.length;
        for (uint256 i = 0; i < length; i++) {
            result[i] = _subjectStructs[_subjectList[i]].subject;
        }
        if (length > 1) {
            quickPart(result, 0, length - 1);
        }
        return result;
    }

    // Get the remaining time to the voting end in seconds.
    function getRemainingTime() external view returns (uint256) {
        if (votingEndDate <= block.timestamp) {
            return 0;
        }
        return votingEndDate - block.timestamp;
    }
}