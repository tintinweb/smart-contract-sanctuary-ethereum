// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IVoting.sol";

/// @title Vote management contract.
/// @notice N-candidate vote management contract with getting a winner.
contract Voting is IVoting, Ownable, ReentrancyGuard {
    /// STORAGE ///

    /// @notice Duration for vote in seconds.
    uint256 private immutable voteDuration;
    /// @notice Start timestamp of vote.
    uint256 private startTime;
    /// @notice List of vote candidates.
    string[] public candidates;
    /// @notice Vote winner.
    string public winner;
    /// @notice Vote count of each candidate.
    mapping(uint8 => uint256) public candidateTotals;

    /// EVENTS ///

    /// @notice Emitted when a new candidate is added.
    /// @param id Index of a new candiate.
    /// @param name Name of a new candidate.
    event CandidateAdded(uint256 id, string name);

    /// @notice Emitted when vote starts.
    /// @param time Start timestamp of vote.
    event VoteStarted(uint256 time);

    /// @notice Emitted when vote completes.
    /// @param winner Name of a winner.
    event VoteComplete(string winner);

    /// @notice Emitted when cast a vote.
    /// @param voter Address of a voter.
    /// @param votedFor Name of a delegated candidate.
    event VoteCast(address indexed voter, string votedFor);

    /// ERRORS ///

    error Voting__VoteIsNotStarted();
    error Voting__VoteStarted();
    error Voting__VoteIsActive(uint256 endTime);
    error Voting__VoteIsEnded(uint256 endTime);

    /// MODIFIERS ///

    /// @dev Throws if called when vote had started.
    modifier whenVoteIsNotStarted() {
        if (startTime > 0) {
            revert Voting__VoteStarted();
        }
        _;
    }

    /// @dev Throws if called when vote is not started yet.
    modifier whenVoteHadStarted() {
        if (startTime == 0) {
            revert Voting__VoteIsNotStarted();
        }
        _;
    }

    /// @dev Throws if called when vote is ended.
    modifier whenVoteIsActive() {
        if (block.timestamp > startTime + voteDuration) {
            revert Voting__VoteIsEnded(startTime + voteDuration);
        }
        _;
    }

    /// @dev Throws if called when vote is active.
    modifier whenVoteHadEnded() {
        if (block.timestamp < startTime + voteDuration) {
            revert Voting__VoteIsActive(startTime + voteDuration);
        }
        _;
    }

    /// FUNCTIONS ///

    /// @notice Initialize the contract by setting the vote duration.
    /// @param duration Duration of vote.
    constructor(uint256 duration) {
        voteDuration = duration;
    }

    /// @inheritdoc IVoting
    function addCandidate(string calldata name)
        external
        override
        onlyOwner
        whenVoteIsNotStarted
    {
        candidates.push(name);

        emit CandidateAdded(candidates.length - 1, name);
    }

    /// @inheritdoc IVoting
    function startVote()
        external
        override
        onlyOwner
        whenVoteIsNotStarted
    {
        startTime = block.timestamp;

        emit VoteStarted(startTime);
    }

    /// @inheritdoc IVoting
    function castVote(uint8 id)
        external
        override
        nonReentrant
        whenVoteHadStarted
        whenVoteIsActive
    {
        candidateTotals[id]++;

        emit VoteCast(msg.sender, candidates[id]);
    }

    /// @inheritdoc IVoting
    function tallyVote()
        external
        override
        nonReentrant
        onlyOwner
        whenVoteHadStarted
        whenVoteHadEnded
    {
        uint8 currentWinner;

        for (uint8 i = 0; i < candidates.length; i++) {
            if (candidateTotals[i] > candidateTotals[currentWinner]) {
                currentWinner = i;
            }
        }

        winner = candidates[currentWinner];

        emit VoteComplete(winner);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

interface IVoting {
    /// @notice Add a new candiate.
    /// @dev Candidates can be added only before vote starts.
    /// @param name Name of a new candiate.
    function addCandidate(string calldata name) external;

    /// @notice Start a vote.
    function startVote() external;

    /// @notice Cast a vote.
    /// @dev Only can cast a vote when vote is active.
    /// @param id Index of a delegated candiate.
    function castVote(uint8 id) external;

    /// @notice Find out a winner.
    /// @dev Only can tally vote when vote is ended.
    function tallyVote() external;
}

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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