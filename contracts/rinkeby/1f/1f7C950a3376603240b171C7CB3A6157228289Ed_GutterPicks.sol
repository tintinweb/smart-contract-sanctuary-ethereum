// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GutterPicks is Ownable {

    struct Contest {
        address creator;
        uint256 minParticipants;
        uint256 maxParticipants;
        uint256 startDate;
        uint256 maxPerParticipant;
        uint256 entryFee;
        address entryFeeCurrency;
        bool isCanceledOrFinished;
        bool payoutPaused;
        uint256 totalEntries;
        mapping (address => uint256) entriesCount;
        mapping (address => mapping(uint256 => uint256)) participantLineups;
        mapping (address => bool) excludedParticipants;
    }

    mapping (string => Contest) contests;
    uint256 contestCount;

    bool isOnlyWhitelistAllowed;

    mapping (address => bool) isWhitelistedCreator;
    mapping (address => bool) isAdmin;
    mapping (address => bool) isPlatform;

    event ContestCreated(
        address contestCreator,
        string contestId,
        uint64 startDate,
        uint64 endDate,
        uint64 minParticipants,
        uint64 maxParticipants,
        uint64 maxPerParticipant,
        uint64 mainProps,
        uint64 backupProps
    );

    event LineupPropsSet(
        string contestId,
        string[] lineupProps
    );

    event BpsSet(
        string contestId,
        uint64[] prizeBps
    );

    event PresetPropsSet(
        string contestId,
        uint64[] presetProps
    );

    event ContestCanceled(string contestId);

    event NewLineup(string contestId, address participant, uint256 lineup);
    event EditLineup(string contestId, address participant, uint256 lineup);
    event ParticipantExcluded(string contestId, address participant);
    event PayoutExecuted(string contestId, address[] receivers, uint256[] payments);

    modifier whitelistedCheck() {
        if (isOnlyWhitelistAllowed)
            require (isWhitelistedCreator[msg.sender], "GutterPicks: Not whitelisted");
        _;
    }

    /**
    * @param id unique contest id
    * @param startDate date & time of contest start. Participants can't submit new lineups or edit
    * their lineups after startDate
    * @param endDate date when contest ends and results are calculted
    * @param minParticipants the # of participants enough to start the contest on startDate
    * successfully. If this amount if not reached, contest should be canceled
    * @param maxParticipants the max # of participants to take part in the contest
    * @param mainProps the # of over/under bets user needs to make for his main lineup in the contest
    * @param backupProps the # of over/under bets user needs to make for his backup lineup in the contest
    * @param lineupProps the prop titles to bet on based on the SportsData API, combined from playerID
    * and prop title. Example of value: ["20000:Fantasy Points"]
    * @param presetProps the override values for lineup props if contest creator wishes to set
    * custom limits and Over/Under points for a prop. The expected format is
    * [PropIndex, Value, OverPoints, UnderPoints].
    * PropIndex - index of lineupProps array element which limit is overwritten.
    * Value - custom limit.
    * OverPoints - amount of points participant wins if he bets Over and his bet wins.
    * UnderPoints - amount of points participant wins if he bets Under and his bet wins.
    * @param prizeBps array of places and prizes distribution in basis points, expected format:
    * [Place,PrizeBps], e.g. [1,5000,2,2500,3,1500,4,500,5,500]
    * @param entryFee the fee in wei to pay for participation
    * @param entryFeeCurrency the ERC20 token address in which the participation payment should occur
    */
    struct CreateContestDTO {
        string id;
        uint64 startDate;
        uint64 endDate;
        uint64 minParticipants;
        uint64 maxParticipants;
        uint64 maxPerParticipant;
        uint64 mainProps;
        uint64 backupProps;
        uint256 entryFee;
        address entryFeeCurrency;
        uint64[] prizeBps;
        string[] lineupProps;
        uint64[] presetProps;
    }
    
    function createContest(
        CreateContestDTO calldata contestDTO
    ) external whitelistedCheck {
        // todo: add validation of entry fee currency
        require(contests[contestDTO.id].creator == address(0), "GutterPicks: contest already exists");
        
        string memory id = contestDTO.id;

        {
            contests[id].minParticipants = contestDTO.minParticipants;
            contests[id].maxParticipants = contestDTO.maxParticipants;
            contests[id].maxPerParticipant = contestDTO.maxPerParticipant;
            contests[id].entryFee = contestDTO.entryFee;
            contests[id].entryFeeCurrency = contestDTO.entryFeeCurrency;
            contests[id].creator = msg.sender;
            contests[id].startDate = contestDTO.startDate;
        }

        contestCount++;

        {
            emit ContestCreated(
                msg.sender,
                id,
                contestDTO.startDate,
                contestDTO.endDate,
                contestDTO.minParticipants,
                contestDTO.maxParticipants,
                contestDTO.maxPerParticipant,
                contestDTO.mainProps,
                contestDTO.backupProps
            );
        }

        {
            emit BpsSet(id, contestDTO.prizeBps);
            emit LineupPropsSet(id, contestDTO.lineupProps);
            emit PresetPropsSet(id, contestDTO.presetProps);
        }
        
    }
    

    function excludeParticipant(string calldata contestId, address participant, uint256 feeReturned) external {
        require(isAdmin[msg.sender], "GutterPicks: not the admin");
        if (feeReturned > 0) {
            IERC20 token = IERC20(contests[contestId].entryFeeCurrency);
            require(token.transfer(participant, feeReturned), "GutterPicks: failed to transfer fee");
        }

        contests[contestId].excludedParticipants[participant] = true;

        emit ParticipantExcluded(contestId, participant);
    }

    function createLineup(string calldata contestId, uint256 lineup) external {
        Contest storage contest = contests[contestId];
        require(!contest.isCanceledOrFinished, "GutterPicks: contest is canceled or finished");
        require(contest.creator != address(0), "GutterPicks: contest doesn't exist");
        require(!contest.excludedParticipants[msg.sender], "GutterPicks: participant excluded");
        require(contest.entriesCount[msg.sender] < contest.maxPerParticipant, "GutterPicks: max entries exceeded");
        require(contest.startDate > block.timestamp, "GutterPicks: contest started");

        uint256 entryId = contest.entriesCount[msg.sender] + 1;
        contest.participantLineups[msg.sender][entryId] = lineup;
        contest.entriesCount[msg.sender] += 1;

        contest.totalEntries += 1;

        IERC20 token = IERC20(contest.entryFeeCurrency);
        require(token.transferFrom(msg.sender, address(this), contest.entryFee), "GutterPicks: failed to transfer fee");

        emit NewLineup(contestId, msg.sender, lineup);
    }

    function editLineup(string calldata contestId, uint256 lineupId, uint256 lineup) external {
        Contest storage contest = contests[contestId];
        require(!contest.isCanceledOrFinished, "GutterPicks: contest is canceled or finished");
        require(contest.creator != address(0), "GutterPicks: contest doesn't exist");
        require(!contest.excludedParticipants[msg.sender], "GutterPicks: participant excluded");
        require(contest.participantLineups[msg.sender][lineupId] != 0, "GutterPicks: no lineup to edit");
        require(contest.startDate > block.timestamp, "GutterPicks: contest started");

        contest.participantLineups[msg.sender][lineupId] = lineup;

        emit EditLineup(contestId, msg.sender, lineup);
    }

    function cancelContest(string calldata contestId) external {
        require(!contests[contestId].isCanceledOrFinished, "GutterPicks: contest is canceled or finished");
        require(contests[contestId].creator == msg.sender, "GutterPicks: not the contest creator");

        contests[contestId].isCanceledOrFinished = true;

        emit ContestCanceled(contestId);
    }

    function pausePayout(string calldata contestId) external {
        require(isAdmin[msg.sender], "GutterPicks: non-admin");

        contests[contestId].payoutPaused = true;
    }

    function executePayout(
        string calldata contestId,
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