// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";

contract VotingEngine is Ownable {
    uint256 public feeRate = 10000000000000000; // voting fee in wei
    uint256 public voteTime = 3 days; // duration of voting
    uint256 public percentFee = 10; // percent of voting fee amount for owner
    uint256 public feeSum; // Total owner earning 

    struct Voting {
        address[] applicants;
        uint256[] votes;
        uint256 startAt;
        uint256 endsAt;
        address winner;
        uint256 prizeEther;
        bool stopped;
    }
    mapping(address => mapping(uint256 => bool)) public electors; 

    mapping(uint256 => Voting) public votings;
    uint256 public votingCounter; // counter of the total number of votings

    event VotingCreated(uint256 indexed votingId, uint256 startAt, uint256 endsAt);
    event VotingEnded(uint256 indexed votingId, address winner, uint256 prizeEther);

    function addVoting(address[] memory applicants) external onlyOwner {
        Voting storage newVoting = votings[votingCounter++];

        newVoting.startAt = block.timestamp;
        newVoting.endsAt = newVoting.startAt + voteTime;

        for(uint256 i = 0; i < applicants.length; i++) {
            newVoting.applicants.push(applicants[i]);
            newVoting.votes.push(0);
        }

        emit VotingCreated(votingCounter - 1, newVoting.startAt, newVoting.endsAt);
    }

    function vote(uint256 indexVoting, uint256 indexApplicant) external payable {
        require(msg.value == feeRate, "Incorrect fee amount!");
        require(indexVoting < votingCounter, "Incorrect voting index!");
        require(!votings[indexVoting].stopped, "Voting already stopped!");
        require(votings[indexVoting].endsAt > block.timestamp, "Voting time is ended!");
        require(electors[msg.sender][indexVoting] == false, "Elector already voted!");

        electors[msg.sender][indexVoting] = true;
        votings[indexVoting].votes[indexApplicant]++;
        votings[indexVoting].prizeEther += msg.value;
    }

    function finish(uint256 votingIndex) external {
        require(!votings[votingIndex].stopped, "Voting already stopped!");
        require(votings[votingIndex].endsAt < block.timestamp, "Voting time is not ended!");
        require(votingIndex < votingCounter, "Incorrect voting index!");

        uint256 winningVoteCount = 0;
        address winner;
        for (uint i = 0; i < votings[votingIndex].votes.length; i++) {
            if (votings[votingIndex].votes[i] > winningVoteCount) {
                winningVoteCount = votings[votingIndex].votes[i];
                winner = votings[votingIndex].applicants[i];
            }
        }
        votings[votingIndex].winner = winner;
        payable(winner).transfer((votings[votingIndex].prizeEther * (100 - percentFee)) / 100);
        feeSum += (votings[votingIndex].prizeEther * percentFee) / 100;

        votings[votingIndex].stopped = true;
        emit VotingEnded(votingIndex, winner, votings[votingIndex].prizeEther);
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(feeSum);
        feeSum = 0;
    }
    
    function getApplicants(uint256 indexVoting) public view returns (address[] memory applicants) {
        return votings[indexVoting].applicants;
    }
        
    function getVotes(uint256 indexVoting) public view returns (uint256[] memory votes) {
        return votings[indexVoting].votes;
    }

    function getEndsAt(uint256 indexVoting) public view returns (uint256 startAt, uint256 endsAt) {
        return (votings[indexVoting].startAt, votings[indexVoting].endsAt);
    }
    
    function getWinner(uint256 indexVoting) public view returns (address winner) {
        return votings[indexVoting].winner;
    }

    function isVotingStopped(uint256 indexVoting) public view returns (bool stopped) {
        return votings[indexVoting].stopped;
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