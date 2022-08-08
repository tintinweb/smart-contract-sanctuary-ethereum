// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GutterPicks is Ownable {

    struct Contest {
        address creator;
        uint256 minAmount;
        uint256 maxAmount;
        uint256 startTime;
        uint256 maxEntriesPerUser;
        uint256 entryFee;
        address entryFeeCurrency;
        bool isCanceledOrFinished;
        bool payoutPaused;
        uint256 totalEntries;
        mapping (address => uint256) entriesCount;
        mapping (address => mapping(uint256 => uint256)) participantLineups;
        mapping (address => bool) excludedParticipants;
    }

    mapping (uint256 => Contest) contests;
    uint256 contestCount;

    bool isOnlyWhitelistAllowed;

    mapping (address => bool) isWhitelistedCreator;
    mapping (address => bool) isAdmin;
    mapping (address => bool) isPlatform;

    event ContestCreated(address contestCreator, uint256 contestId);
    event ContestCanceled(uint256 contestId);

    event NewLineup(uint256 contestId, address participant, uint256 lineup);
    event EditLineup(uint256 contestId, address participant, uint256 lineup);
    event ParticipantExcluded(uint256 contestId, address participant);
    event PayoutExecuted(uint256 contestId, address[] receivers, uint256[] payments);

    modifier whitelistedCheck() {
        if (isOnlyWhitelistAllowed)
            require (isWhitelistedCreator[msg.sender], "GutterPicks: Not whitelisted");
        _;
    }

    function createContest(
        uint256 minAmount,
        uint256 maxAmount,
        uint256 maxEntriesPerUser,
        uint256 entryFee,
        address entryFeeCurrency
    ) external whitelistedCheck {
        // todo: add validation of entry fee currency

        uint256 id = contestCount;
        contests[id].minAmount = minAmount;
        contests[id].maxAmount = maxAmount;
        contests[id].maxEntriesPerUser = maxEntriesPerUser;
        contests[id].entryFee = entryFee;
        contests[id].entryFeeCurrency = entryFeeCurrency;
        contests[id].creator = msg.sender;

        contestCount++;

        emit ContestCreated(msg.sender, id);
    }
    

    function excludeParticipant(uint256 contestId, address participant, uint256 feeReturned) external {
        require(isAdmin[msg.sender], "GutterPicks: not the admin");
        if (feeReturned > 0) {
            IERC20 token = IERC20(contests[contestId].entryFeeCurrency);
            require(token.transfer(participant, feeReturned), "GutterPicks: failed to transfer fee");
        }

        contests[contestId].excludedParticipants[participant] = true;

        emit ParticipantExcluded(contestId, participant);
    }

    function createLineup(uint256 contestId, uint256 lineup) external {
        Contest storage contest = contests[contestId];
        require(!contest.isCanceledOrFinished, "GutterPicks: contest is canceled or finished");
        require(contest.creator != address(0), "GutterPicks: contest doesn't exist");
        require(!contest.excludedParticipants[msg.sender], "GutterPicks: participant excluded");
        require(contest.entriesCount[msg.sender] < contest.maxEntriesPerUser, "GutterPicks: max entries exceeded");
        require(contest.startTime > block.timestamp, "GutterPicks: contest started");

        uint256 entryId = contest.entriesCount[msg.sender] + 1;
        contest.participantLineups[msg.sender][entryId] = lineup;
        contest.entriesCount[msg.sender] += 1;

        contest.totalEntries += 1;

        IERC20 token = IERC20(contest.entryFeeCurrency);
        require(token.transferFrom(msg.sender, address(this), contest.entryFee), "GutterPicks: failed to transfer fee");

        emit NewLineup(contestId, msg.sender, lineup);
    }

    function editLineup(uint256 contestId, uint256 lineupId, uint256 lineup) external {
        Contest storage contest = contests[contestId];
        require(!contest.isCanceledOrFinished, "GutterPicks: contest is canceled or finished");
        require(contest.creator != address(0), "GutterPicks: contest doesn't exist");
        require(!contest.excludedParticipants[msg.sender], "GutterPicks: participant excluded");
        require(contest.participantLineups[msg.sender][lineupId] != 0, "GutterPicks: no lineup to edit");
        require(contest.startTime > block.timestamp, "GutterPicks: contest started");

        contest.participantLineups[msg.sender][lineupId] = lineup;

        emit EditLineup(contestId, msg.sender, lineup);
    }

    function cancelContest(uint256 contestId) external {
        require(!contests[contestId].isCanceledOrFinished, "GutterPicks: contest is canceled or finished");
        require(contests[contestId].creator == msg.sender, "GutterPicks: not the contest creator");

        contests[contestId].isCanceledOrFinished = true;

        emit ContestCanceled(contestId);
    }

    function pausePayout(uint256 contestId) external {
        require(isAdmin[msg.sender], "GutterPicks: non-admin");

        contests[contestId].payoutPaused = true;
    }

    function executePayout(
        uint256 contestId,
        address[] calldata receivers,
        uint256[] calldata payments,
        bool markCanceledFinished
    ) external {
        require(
            isAdmin[msg.sender] || (isPlatform[msg.sender] && !contests[contestId].payoutPaused),
            "GutterPicks: not eligible to payout"
        );
        require(receivers.length == payments.length, "GutterPicks: invalid length");

        IERC20 token = IERC20(contests[contestId].entryFeeCurrency);
        for (uint256 i = 0; i < receivers.length; i++) {
            require(token.transfer(receivers[i], payments[i]), "GutterPicks: failed to transfer fee");
        }

        if (markCanceledFinished)
            contests[contestId].isCanceledOrFinished = true;

        emit PayoutExecuted(contestId, receivers, payments);
    }

    function setAdmin(address admin, bool status) external onlyOwner {
        isAdmin[admin] = status;
    }

    function setPlatform(address platform, bool status) external onlyOwner {
        isPlatform[platform] = status;
    }

    function setWhitelistCreator(address creator, bool status) external onlyOwner {
        isWhitelistedCreator[creator] = status;
    }

    function setOnlyWhitelistAllowed(bool allowed) external onlyOwner {
        isOnlyWhitelistAllowed = allowed;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
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