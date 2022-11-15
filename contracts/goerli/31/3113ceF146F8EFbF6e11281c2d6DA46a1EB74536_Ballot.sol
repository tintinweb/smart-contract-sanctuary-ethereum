// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Types.sol";
import "./BallotTime.sol";

/**
 * @title Ballot
 * @author Faraj Shuauib
 * @dev Implements voting process along with winning candidate
 */
contract Ballot is Ownable, BallotTime {
    Types.Candidate[] public candidates;
    mapping(uint256 => Types.Voter) voter;
    mapping(uint256 => Types.Candidate) candidate;
    mapping(uint256 => uint256) internal votesCount;
    /**
     * @dev Get candidate list.
     * @param voterAadharNumber Aadhar number of the current voter to send the relevent candidates list
     * @return candidatesList_ All the politicians who participate in the election
     */
    function getCandidateList(uint256 voterAadharNumber)
        public
        view
        returns (Types.Candidate[] memory)
    {
        Types.Voter storage voter_ = voter[voterAadharNumber];
        uint256 _politicianOfMyConstituencyLength = 0;

        for (uint256 i = 0; i < candidates.length; i++) {
            if (
                voter_.stateCode == candidates[i].stateCode &&
                voter_.constituencyCode == candidates[i].constituencyCode
            ) _politicianOfMyConstituencyLength++;
        }
        Types.Candidate[] memory cc = new Types.Candidate[](
            _politicianOfMyConstituencyLength
        );

        uint256 _indx = 0;
        for (uint256 i = 0; i < candidates.length; i++) {
            if (
                voter_.stateCode == candidates[i].stateCode &&
                voter_.constituencyCode == candidates[i].constituencyCode
            ) {
                cc[_indx] = candidates[i];
                _indx++;
            }
        }
        return cc;
    }

    /**
     * @dev Get candidate list.
     * @param voterAadharNumber Aadhar number of the current voter to send the relevent candidates list
     * @return voterEligible_ Whether the voter with provided aadhar is eligible or not
     */
    function isVoterEligible(uint256 voterAadharNumber)
        public
        view
        returns (bool voterEligible_)
    {
        Types.Voter storage voter_ = voter[voterAadharNumber];
        if (voter_.age >= 18 && voter_.isAlive) voterEligible_ = true;
    }

    /**
     * @dev Know whether the voter casted their vote or not. If casted get candidate object.
     * @param voterAadharNumber Aadhar number of the current voter
     * @return userVoted_ Boolean value which gives whether current voter casted vote or not
     * @return candidate_ Candidate details to whom voter casted his/her vote
     */
    function didCurrentVoterVoted(uint256 voterAadharNumber)
        public
        view
        returns (bool userVoted_, Types.Candidate memory candidate_)
    {
        userVoted_ = (voter[voterAadharNumber].votedTo != 0);
        if (userVoted_)
            candidate_ = candidate[voter[voterAadharNumber].votedTo];
    }

    /**
     * @dev Give your vote to candidate.
     * @param nominationNumber Aadhar Number of the candidate
     * @param voterAadharNumber Aadhar Number of the voter to avoid re-entry
     */
    function vote(
        uint256 nominationNumber,
        uint256 voterAadharNumber
    )
        public
        votingDuration()
        isEligibleVote(voterAadharNumber, nominationNumber)
    {
        // updating the current voter values
        voter[voterAadharNumber].votedTo = nominationNumber;

        // updates the votes the politician
        uint256 voteCount_ = votesCount[nominationNumber];
        votesCount[nominationNumber] = voteCount_ + 1;
    }

    /**
     * @dev sends all candidate list with their votes count
     * @return candidateList_ List of Candidate objects with votes count
     */
    function getResults()
        public
        view
        returns (Types.Results[] memory)
    {
        Types.Results[] memory resultsList_ = new Types.Results[](
            candidates.length
        );
        for (uint256 i = 0; i < candidates.length; i++) {
            resultsList_[i] = Types.Results({
                name: candidates[i].name,
                partyShortcut: candidates[i].partyShortcut,
                partyFlag: candidates[i].partyFlag,
                nominationNumber: candidates[i].nominationNumber,
                stateCode: candidates[i].stateCode,
                constituencyCode: candidates[i].constituencyCode,
                voteCount: votesCount[candidates[i].nominationNumber]
            });
        }
        return resultsList_;
    }



    /**
     * @notice To check if the voter's age is greater than or equal to 18
     * @param voterAadhar_ Aadhar number of the current voter
     * @param nominationNumber_ Nomination number of the candidate
     */
    modifier isEligibleVote(uint256 voterAadhar_, uint256 nominationNumber_) {
        Types.Voter memory voter_ = voter[voterAadhar_];
        Types.Candidate memory politician_ = candidate[nominationNumber_];
        require(voter_.age >= 18);
        require(voter_.isAlive);
        require(voter_.votedTo == 0);
        require(
            (politician_.stateCode == voter_.stateCode &&
                politician_.constituencyCode == voter_.constituencyCode)
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract BallotTime is Ownable {
    uint256 private startTime;
    uint256 private endTime;

    //modifier to check if the voting has already started
    modifier votingStarted() {
        if (startTime != 0) {
            require(block.timestamp < startTime, "Voting has already started.");
        }
        _;
    }

    //modifier to check if the voting has ended
    modifier votingEnded() {
        if (endTime != 0) {
            require(block.timestamp < endTime, "Voting has already ended.");
        }
        _;
    }

    //modifier to check if the voting is active or not
    modifier votingDuration() {
        require(block.timestamp > startTime, "voting hasn't started");
        require(block.timestamp < endTime, "voting has already ended");
        _;
    }
    //modifier to check if the vote Duration and Locking periods are valid or not
    modifier voteValid(uint256 _startTime, uint256 _endTime) {
        require(
            block.timestamp < _startTime,
            "Starting time is less than current TimeStamp!"
        );
        require(_startTime < _endTime, "Invalid vote Dates!");
        _;
    }

    //function to get the voting start time
    function getStartTime() public view returns (uint256) {
        return startTime;
    }

    //function to get the voting end time
    function getEndTime() public view returns (uint256) {
        return endTime;
    }

    //function to set voting duration and locking periods
    function setVotingPeriodParams(uint256 _startTime, uint256 _endTime)
        external
        onlyOwner
        votingStarted
        voteValid(_startTime, _endTime)
    {
        startTime = _startTime;
        endTime = _endTime;
    }

    // Stop the voting
    function stopVoting() external onlyOwner {
        require(block.timestamp > startTime, "Voting hasn't started yet!");
        if (block.timestamp < endTime) {
            endTime = block.timestamp;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

/**
 * @title Types
 * @author Faraj Shuauib
 * @dev All custom types that we have used in E-Voting will be declared here
 */
library Types {
    struct Voter {
        uint256 aadharNumber; // voter unique ID
        string name;
        uint8 age;
        uint8 stateCode;
        uint8 constituencyCode;
        bool isAlive;
        uint256 votedTo; // aadhar number of the candidate
    }

    struct Candidate {
        // Note: If we can limit the length to a certain number of bytes,
        // we can use one of bytes1 to bytes32 because they are much cheaper

        string name;
        string partyShortcut;
        string partyFlag;
        uint256 nominationNumber; // unique ID of candidate
        uint8 stateCode;
        uint8 constituencyCode;
    }

    struct Results {
        string name;
        string partyShortcut;
        string partyFlag;
        uint256 voteCount; // number of accumulated votes
        uint256 nominationNumber; // unique ID of candidate
        uint8 stateCode;
        uint8 constituencyCode;
    }
}