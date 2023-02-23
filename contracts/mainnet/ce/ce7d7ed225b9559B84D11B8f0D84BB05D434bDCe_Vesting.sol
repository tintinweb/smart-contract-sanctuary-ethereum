// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IMnt.sol";
import "./interfaces/IVesting.sol";
import "./libraries/PauseControl.sol";
import "./libraries/ErrorCodes.sol";

/**
 * @title Vesting contract provides unlocking of tokens on a schedule. It uses the *graded vesting* way,
 * which unlocks a specific amount of balance every period of time, until all balance unlocked.
 *
 * Vesting Schedule.
 *
 * The schedule of a vesting is described by data structure `VestingSchedule`: starting from the start timestamp
 * throughout the duration, the entire amount of totalAmount tokens will be unlocked.
 */
contract Vesting is IVesting, AccessControl, PauseControl, Initializable {
    using SafeERC20Upgradeable for IMnt;

    /// @notice The right part is the keccak-256 hash of variable name
    bytes32 public constant GATEKEEPER = bytes32(0x20162831d2f54c3e11eebafebfeda495d4c52c67b1708251179ec91fb76dd3b2);
    /// @dev Value is the Keccak-256 hash of "TOKEN_PROVIDER"
    bytes32 public constant TOKEN_PROVIDER =
        bytes32(0x8c60700f65fcee73179f64477eb1484ea199744913cfa6e5fe87df1dcd47e13d);

    IMnt public mnt;
    IBuyback public buyback;

    mapping(address => VestingSchedule) public schedules;
    mapping(address => bool) public delayList;
    uint256 public allocation;
    uint256 public freeAllocation;

    /**
     * @notice Construct a vesting contract.
     * @param _admin The address of the Admin
     * @param _mnt The address of the MNT contract.
     */
    function initialize(
        address _admin,
        IMnt _mnt,
        IBuyback _buyback
    ) public initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(GATEKEEPER, _admin);
        _grantRole(TOKEN_PROVIDER, _admin);
        mnt = _mnt;
        buyback = _buyback;
    }

    /// @inheritdoc IVesting
    function withdraw(uint256 amount_) external checkPaused(WITHDRAW_OP) {
        require(!delayList[msg.sender], ErrorCodes.DELAY_LIST_LIMIT);

        VestingSchedule storage schedule = schedules[msg.sender];

        require(schedule.start != 0, ErrorCodes.NO_VESTING_SCHEDULES);

        uint256 unreleased = releasableAmount(msg.sender);
        if (amount_ == type(uint256).max) {
            amount_ = unreleased;
        }
        require(amount_ > 0, ErrorCodes.MNT_AMOUNT_IS_ZERO);
        require(amount_ <= unreleased, ErrorCodes.INSUFFICIENT_UNRELEASED_TOKENS);

        uint256 mntRemaining = mnt.balanceOf(address(this));
        require(amount_ <= mntRemaining, ErrorCodes.INSUFFICIENT_TOKEN_IN_VESTING_CONTRACT);

        allocation -= amount_;
        schedule.released = schedule.released + amount_;
        // Remove the vesting schedule if all tokens were released to the account.
        if (schedule.released == schedule.totalAmount) {
            delete schedules[msg.sender];
        }

        emit Withdrawn(msg.sender, amount_);

        buyback.updateBuybackAndVotingWeights(msg.sender);

        mnt.safeTransfer(msg.sender, amount_);
    }

    /// @inheritdoc IVesting
    function refill(uint256 amount) external onlyRole(TOKEN_PROVIDER) {
        require(amount > 0, ErrorCodes.MNT_AMOUNT_IS_ZERO);
        allocation += amount;
        freeAllocation += amount;
        mnt.safeTransferFrom(msg.sender, address(this), amount);
    }

    /// @inheritdoc IVesting
    function sweep(address recipient, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(amount > 0, ErrorCodes.MNT_AMOUNT_IS_ZERO);
        uint256 unallocated = mnt.balanceOf(address(this)) - allocation;
        if (amount == type(uint256).max) amount = unallocated;
        require(amount <= unallocated, ErrorCodes.INCORRECT_AMOUNT);
        mnt.safeTransfer(recipient, amount);
    }

    /// @inheritdoc IVesting
    function createVestingScheduleBatch(ScheduleData[] memory schedulesData) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 length = schedulesData.length;
        uint32 rightNow = uint32(getTime());
        uint256 _freeAllocation = freeAllocation;

        for (uint256 i = 0; i < length; i++) {
            ScheduleData memory schedule = schedulesData[i];

            require(schedule.target != address(0), ErrorCodes.TARGET_ADDRESS_CANNOT_BE_ZERO);
            require(schedules[schedule.target].start == 0, ErrorCodes.VESTING_SCHEDULE_ALREADY_EXISTS);
            require(schedule.totalAmount > 0, ErrorCodes.MNT_AMOUNT_IS_ZERO);
            require(_freeAllocation >= schedule.totalAmount, ErrorCodes.INSUFFICIENT_TOKENS_TO_CREATE_SCHEDULE);

            schedules[schedule.target] = VestingSchedule({
                totalAmount: schedule.totalAmount,
                released: 0,
                created: rightNow,
                start: rightNow + schedule.start,
                duration: schedule.duration,
                revocable: schedule.revocable
            });

            _freeAllocation -= schedule.totalAmount;

            emit VestingScheduleAdded(schedule.target, schedules[schedule.target]);
        }

        freeAllocation = _freeAllocation;
    }

    /// @inheritdoc IVesting
    function revokeVestingSchedule(address target_) external onlyRole(GATEKEEPER) {
        VestingSchedule storage schedule = schedules[target_];
        require(schedule.start != 0, ErrorCodes.NO_VESTING_SCHEDULE);
        require(schedule.revocable, ErrorCodes.SCHEDULE_IS_IRREVOCABLE);

        if (delayList[target_]) {
            // If target is in delay list then do not transfer anything and instead
            // move their tokens into an unallocated pool.
            uint256 returned = schedule.totalAmount - schedule.released;

            freeAllocation += returned;
            delete schedules[target_];
            delete delayList[target_];

            emit VestingScheduleRevoked(target_, 0, returned);
            buyback.updateBuybackAndVotingWeights(target_);

            return;
        }

        uint256 locked = lockedAmount(schedule, schedule.start);
        uint256 unreleased = releasableAmount(target_);
        uint256 mntRemaining = mnt.balanceOf(address(this));

        require(mntRemaining >= unreleased, ErrorCodes.INSUFFICIENT_TOKENS_FOR_RELEASE);

        allocation -= unreleased;
        freeAllocation += locked;
        delete schedules[target_];
        delete delayList[target_];

        emit VestingScheduleRevoked(target_, unreleased, locked);
        buyback.updateBuybackAndVotingWeights(target_);

        mnt.safeTransfer(target_, unreleased);
    }

    /// @inheritdoc IVesting
    function endOfVesting(address who_) external view returns (uint256) {
        VestingSchedule storage schedule = schedules[who_];
        return uint256(schedule.start) + uint256(schedule.duration);
    }

    /// @inheritdoc IVesting
    function lockedAmount(address who_) external view returns (uint256) {
        VestingSchedule storage schedule = schedules[who_];
        return lockedAmount(schedule, schedule.start);
    }

    /// @dev Gets locked amount of vesting schedule with custom start timestamp.
    ///      Used to calculate normal and "cliffless" amounts.
    function lockedAmount(VestingSchedule storage schedule, uint256 _start) internal view returns (uint256) {
        // lockedAmount = (end - time) * totalAmount / duration;
        // if the parameter `duration` is zero, it means that the allocated tokens are not locked for address `who`.

        uint256 _now = getTime();
        if (_now < _start) return schedule.totalAmount;

        uint256 _duration = uint256(schedule.duration);
        uint256 _end = _start + _duration;
        if (_duration == 0 || _now > _end) return 0;

        return ((_end - _now) * schedule.totalAmount) / _duration;
    }

    /// @inheritdoc IVesting
    function vestedAmount(address who_) public view returns (uint256) {
        VestingSchedule storage schedule = schedules[who_];
        return schedule.totalAmount - lockedAmount(schedule, schedule.start);
    }

    /// @inheritdoc IVesting
    function releasableAmount(address who_) public view returns (uint256) {
        return vestedAmount(who_) - schedules[who_].released;
    }

    /// @inheritdoc IVesting
    function getReleasableWithoutCliff(address account) external view returns (uint256) {
        VestingSchedule storage schedule = schedules[account];
        uint256 vested = schedule.totalAmount - lockedAmount(schedule, schedule.created);
        return vested - schedule.released;
    }

    /// @inheritdoc IVesting
    function addToDelayList(address who_) external onlyRole(GATEKEEPER) {
        require(schedules[who_].revocable, ErrorCodes.SHOULD_HAVE_REVOCABLE_SCHEDULE);
        emit AddedToDelayList(who_);
        delayList[who_] = true;
    }

    /// @inheritdoc IVesting
    function removeFromDelayList(address who_) external onlyRole(GATEKEEPER) {
        require(delayList[who_], ErrorCodes.MEMBER_NOT_IN_DELAY_LIST);
        emit RemovedFromDelayList(who_);
        delete delayList[who_];
    }

    // // // // Pause control // // // //

    bytes32 internal constant WITHDRAW_OP = "Withdraw";

    function validatePause(address) internal view override {
        require(hasRole(GATEKEEPER, msg.sender), ErrorCodes.UNAUTHORIZED);
    }

    function validateUnpause(address) internal view override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), ErrorCodes.UNAUTHORIZED);
    }

    // // // // Utils // // // //

    /// @dev Gets timestamp truncated to minutes
    function getTime() internal view virtual returns (uint256) {
        return block.timestamp / 1 minutes;
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./ILinkageLeaf.sol";

interface IMnt is IERC20Upgradeable, IERC165, IAccessControlUpgradeable, ILinkageLeaf {
    event MaxNonVotingPeriodChanged(uint256 oldPeriod, uint256 newPeriod);
    event NewGovernor(address governor);
    event VotesUpdated(address account, uint256 oldVotingWeight, uint256 newVotingWeight);
    event TotalVotesUpdated(uint256 oldTotalVotes, uint256 newTotalVotes);

    /**
     * @notice get governor
     */
    function governor() external view returns (address);

    /**
     * @notice returns votingWeight for user
     */
    function votingWeight(address) external view returns (uint256);

    /**
     * @notice get total voting weight
     */
    function totalVotingWeight() external view returns (uint256);

    /**
     * @notice Updates voting power of the account
     */
    function updateVotingWeight(address account) external;

    /**
     * @notice Creates new total voting weight checkpoint
     * @dev RESTRICTION: Governor only.
     */
    function updateTotalWeightCheckpoint() external;

    /**
     * @notice Checks user activity for the last `maxNonVotingPeriod` blocks
     * @param account_ The address of the account
     * @return returns true if the user voted or his delegatee voted for the last maxNonVotingPeriod blocks,
     * otherwise returns false
     */
    function isParticipantActive(address account_) external view returns (bool);

    /**
     * @notice Updates last voting timestamp of the account
     * @dev RESTRICTION: Governor only.
     */
    function updateVoteTimestamp(address account) external;

    /**
     * @notice Gets the latest voting timestamp for account.
     * @dev If the user delegated his votes, then it also checks the timestamp of the last vote of the delegatee
     * @param account The address of the account
     * @return latest voting timestamp for account
     */
    function lastActivityTimestamp(address account) external view returns (uint256);

    /**
     * @notice set new governor
     * @dev RESTRICTION: Admin only.
     */
    function setGovernor(address newGovernor) external;

    /**
     * @notice Sets the maxNonVotingPeriod
     * @dev Admin function to set maxNonVotingPeriod
     * @param newPeriod_ The new maxNonVotingPeriod (in sec). Must be greater than 90 days and lower than 2 years.
     * @dev RESTRICTION: Admin only.
     */
    function setMaxNonVotingPeriod(uint256 newPeriod_) external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "./ErrorCodes.sol";

abstract contract PauseControl {
    event OperationPaused(bytes32 op, address subject);
    event OperationUnpaused(bytes32 op, address subject);

    mapping(address => mapping(bytes32 => bool)) internal pausedOps;

    function validatePause(address subject) internal view virtual;

    function validateUnpause(address subject) internal view virtual;

    function isOperationPaused(bytes32 op, address subject) public view returns (bool) {
        return pausedOps[subject][op];
    }

    function pauseOperation(bytes32 op, address subject) external virtual {
        validatePause(subject);
        require(!isOperationPaused(op, subject));
        pausedOps[subject][op] = true;
        emit OperationPaused(op, subject);
    }

    function unpauseOperation(bytes32 op, address subject) external virtual {
        validateUnpause(subject);
        require(isOperationPaused(op, subject));
        pausedOps[subject][op] = false;
        emit OperationUnpaused(op, subject);
    }

    modifier checkPausedSubject(bytes32 op, address subject) {
        require(!isOperationPaused(op, subject), ErrorCodes.OPERATION_PAUSED);
        _;
    }

    modifier checkPaused(bytes32 op) {
        require(!isOperationPaused(op, address(0)), ErrorCodes.OPERATION_PAUSED);
        _;
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IBuyback.sol";

/**
 * @title Vesting contract provides unlocking of tokens on a schedule. It uses the *graded vesting* way,
 * which unlocks a specific amount of balance every period of time, until all balance unlocked.
 *
 * Vesting Schedule.
 *
 * The schedule of a vesting is described by data structure `VestingSchedule`: starting from the start timestamp
 * throughout the duration, the entire amount of totalAmount tokens will be unlocked.
 */
interface IVesting is IAccessControl {
    /**
     * @notice An event that's emitted when a new vesting schedule for a account is created.
     */
    event VestingScheduleAdded(address target, VestingSchedule schedule);

    /**
     * @notice An event that's emitted when a vesting schedule revoked.
     */
    event VestingScheduleRevoked(address target, uint256 unreleased, uint256 locked);

    /**
     * @notice An event that's emitted when the account Withdrawn the released tokens.
     */
    event Withdrawn(address target, uint256 withdrawn);

    /**
     * @notice Emitted when an account is added to the delay list
     */
    event AddedToDelayList(address account);

    /**
     * @notice Emitted when an account is removed from the delay list
     */
    event RemovedFromDelayList(address account);

    /**
     * @notice The structure is used in the contract constructor for create vesting schedules
     * during contract deploying.
     * @param totalAmount the number of tokens to be vested during the vesting duration.
     * @param target the address that will receive tokens according to schedule parameters.
     * @param start offset in minutes at which vesting starts. Zero will vesting immediately.
     * @param duration duration in minutes of the period in which the tokens will vest.
     * @param revocable whether the vesting is revocable or not.
     */
    struct ScheduleData {
        uint256 totalAmount;
        address target;
        uint32 start;
        uint32 duration;
        bool revocable;
    }

    /**
     * @notice Vesting schedules of an account.
     * @param totalAmount the number of tokens to be vested during the vesting duration.
     * @param released the amount of the token released. It means that the account has called withdraw() and received
     * @param start the timestamp in minutes at which vesting starts. Must not be equal to zero, as it is used to
     * check for the existence of a vesting schedule.
     * @param duration duration in minutes of the period in which the tokens will vest.
     * `released amount` of tokens to his address.
     * @param revocable whether the vesting is revocable or not.
     */
    struct VestingSchedule {
        uint256 totalAmount;
        uint256 released;
        uint32 created;
        uint32 start;
        uint32 duration;
        bool revocable;
    }

    /// @notice get keccak-256 hash of GATEKEEPER role
    function GATEKEEPER() external view returns (bytes32);

    /// @notice get keccak-256 hash of TOKEN_PROVIDER role
    function TOKEN_PROVIDER() external view returns (bytes32);

    /**
     * @notice get vesting schedule of an account.
     */
    function schedules(address)
        external
        view
        returns (
            uint256 totalAmount,
            uint256 released,
            uint32 created,
            uint32 start,
            uint32 duration,
            bool revocable
        );

    /**
     * @notice Gets the amount of MNT that was transferred to Vesting contract
     * and can be transferred to other accounts via vesting process.
     * Transferring rewards from Vesting via withdraw method will decrease this amount.
     */
    function allocation() external view returns (uint256);

    /**
     * @notice Gets the amount of allocated MNT tokens that are not used in any vesting schedule yet.
     * Creation of new vesting schedules will decrease this amount.
     */
    function freeAllocation() external view returns (uint256);

    /**
     * @notice get Whether or not the account is in the delay list
     */
    function delayList(address) external view returns (bool);

    /**
     * @notice Withdraw the specified number of tokens. For a successful transaction, the requirement
     * `amount_ > 0 && amount_ <= unreleased` must be met.
     * If `amount_ == MaxUint256` withdraw all unreleased tokens.
     * @param amount_ The number of tokens to withdraw.
     */
    function withdraw(uint256 amount_) external;

    /**
     * @notice Increases vesting schedule allocation and transfers MNT into Vesting.
     * @dev RESTRICTION: TOKEN_PROVIDER only
     */
    function refill(uint256 amount) external;

    /**
     * @notice Transfers MNT that were added to the contract without calling the refill and are unallocated.
     * @dev RESTRICTION: Admin only
     */
    function sweep(address recipient, uint256 amount) external;

    /**
     * @notice Allows the admin to create a new vesting schedules.
     * @param schedulesData an array of vesting schedules that will be created.
     * @dev RESTRICTION: Admin only.
     */
    function createVestingScheduleBatch(ScheduleData[] memory schedulesData) external;

    /**
     * @notice Allows the admin to revoke the vesting schedule. Tokens already vested
     * transfer to the account, the rest are returned to the vesting contract.
     * Accounts that are in delay list have their withdraw blocked so they would not receive anything.
     * @param target_ the address from which the vesting schedule is revoked.
     * @dev RESTRICTION: Gatekeeper only.
     */
    function revokeVestingSchedule(address target_) external;

    /**
     * @notice Calculates the end of the vesting.
     * @param who_ account address for which the parameter is returned.
     * @return the end of the vesting.
     */
    function endOfVesting(address who_) external view returns (uint256);

    /**
     * @notice Calculates locked amount for a given `time`.
     * @param who_ account address for which the parameter is returned.
     * @return locked amount for a given `time`.
     */
    function lockedAmount(address who_) external view returns (uint256);

    /**
     * @notice Calculates the amount that has already vested.
     * @param who_ account address for which the parameter is returned.
     * @return the amount that has already vested.
     */
    function vestedAmount(address who_) external view returns (uint256);

    /**
     * @notice Calculates the amount that has already vested but hasn't been released yet.
     * @param who_ account address for which the parameter is returned.
     * @return the amount that has already vested but hasn't been released yet.
     */
    function releasableAmount(address who_) external view returns (uint256);

    /**
     * @notice Gets the amount that has already vested but hasn't been released yet if account
     *      schedule had no starting delay (cliff).
     */
    function getReleasableWithoutCliff(address account) external view returns (uint256);

    /**
     * @notice Add an account with revocable schedule to the delay list
     * @param who_ The account that is being added to the delay list
     * @dev RESTRICTION: Gatekeeper only.
     */
    function addToDelayList(address who_) external;

    /**
     * @notice Remove an account from the delay list
     * @param who_ The account that is being removed from the delay list
     * @dev RESTRICTION: Gatekeeper only.
     */
    function removeFromDelayList(address who_) external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

library ErrorCodes {
    // Common
    string internal constant ADMIN_ONLY = "E101";
    string internal constant UNAUTHORIZED = "E102";
    string internal constant OPERATION_PAUSED = "E103";
    string internal constant WHITELISTED_ONLY = "E104";
    string internal constant ADDRESS_IS_NOT_IN_AML_SYSTEM = "E105";
    string internal constant ADDRESS_IS_BLACKLISTED = "E106";

    // Invalid input
    string internal constant ADMIN_ADDRESS_CANNOT_BE_ZERO = "E201";
    string internal constant INVALID_REDEEM = "E202";
    string internal constant REDEEM_TOO_MUCH = "E203";
    string internal constant MARKET_NOT_LISTED = "E204";
    string internal constant INSUFFICIENT_LIQUIDITY = "E205";
    string internal constant INVALID_SENDER = "E206";
    string internal constant BORROW_CAP_REACHED = "E207";
    string internal constant BALANCE_OWED = "E208";
    string internal constant UNRELIABLE_LIQUIDATOR = "E209";
    string internal constant INVALID_DESTINATION = "E210";
    string internal constant INSUFFICIENT_STAKE = "E211";
    string internal constant INVALID_DURATION = "E212";
    string internal constant INVALID_PERIOD_RATE = "E213";
    string internal constant EB_TIER_LIMIT_REACHED = "E214";
    string internal constant INVALID_DEBT_REDEMPTION_RATE = "E215";
    string internal constant LQ_INVALID_SEIZE_DISTRIBUTION = "E216";
    string internal constant EB_TIER_DOES_NOT_EXIST = "E217";
    string internal constant EB_ZERO_TIER_CANNOT_BE_ENABLED = "E218";
    string internal constant EB_ALREADY_ACTIVATED_TIER = "E219";
    string internal constant EB_END_BLOCK_MUST_BE_LARGER_THAN_CURRENT = "E220";
    string internal constant EB_CANNOT_MINT_TOKEN_FOR_ACTIVATED_TIER = "E221";
    string internal constant EB_EMISSION_BOOST_IS_NOT_IN_RANGE = "E222";
    string internal constant TARGET_ADDRESS_CANNOT_BE_ZERO = "E223";
    string internal constant INSUFFICIENT_TOKEN_IN_VESTING_CONTRACT = "E224";
    string internal constant VESTING_SCHEDULE_ALREADY_EXISTS = "E225";
    string internal constant INSUFFICIENT_TOKENS_TO_CREATE_SCHEDULE = "E226";
    string internal constant NO_VESTING_SCHEDULE = "E227";
    string internal constant SCHEDULE_IS_IRREVOCABLE = "E228";
    string internal constant MNT_AMOUNT_IS_ZERO = "E230";
    string internal constant INCORRECT_AMOUNT = "E231";
    string internal constant MEMBERSHIP_LIMIT = "E232";
    string internal constant MEMBER_NOT_EXIST = "E233";
    string internal constant MEMBER_ALREADY_ADDED = "E234";
    string internal constant MEMBERSHIP_LIMIT_REACHED = "E235";
    string internal constant REPORTED_PRICE_SHOULD_BE_GREATER_THAN_ZERO = "E236";
    string internal constant MTOKEN_ADDRESS_CANNOT_BE_ZERO = "E237";
    string internal constant TOKEN_ADDRESS_CANNOT_BE_ZERO = "E238";
    string internal constant REDEEM_TOKENS_OR_REDEEM_AMOUNT_MUST_BE_ZERO = "E239";
    string internal constant FL_TOKEN_IS_NOT_UNDERLYING = "E240";
    string internal constant FL_AMOUNT_IS_TOO_LARGE = "E241";
    string internal constant FL_CALLBACK_FAILED = "E242";
    string internal constant DD_UNSUPPORTED_TOKEN = "E243";
    string internal constant DD_MARKET_ADDRESS_IS_ZERO = "E244";
    string internal constant DD_ROUTER_ADDRESS_IS_ZERO = "E245";
    string internal constant DD_RECEIVER_ADDRESS_IS_ZERO = "E246";
    string internal constant DD_BOT_ADDRESS_IS_ZERO = "E247";
    string internal constant DD_MARKET_NOT_FOUND = "E248";
    string internal constant DD_RECEIVER_NOT_FOUND = "E249";
    string internal constant DD_BOT_NOT_FOUND = "E250";
    string internal constant DD_ROUTER_ALREADY_SET = "E251";
    string internal constant DD_RECEIVER_ALREADY_SET = "E252";
    string internal constant DD_BOT_ALREADY_SET = "E253";
    string internal constant EB_MARKET_INDEX_IS_LESS_THAN_USER_INDEX = "E254";
    string internal constant LQ_INVALID_DRR_ARRAY = "E255";
    string internal constant LQ_INVALID_SEIZE_ARRAY = "E256";
    string internal constant LQ_INVALID_DEBT_REDEMPTION_RATE = "E257";
    string internal constant LQ_INVALID_SEIZE_INDEX = "E258";
    string internal constant LQ_DUPLICATE_SEIZE_INDEX = "E259";
    string internal constant DD_INVALID_TOKEN_IN_ADDRESS = "E260";
    string internal constant DD_INVALID_TOKEN_OUT_ADDRESS = "E261";
    string internal constant DD_INVALID_TOKEN_IN_AMOUNT = "E262";
    string internal constant DD_LIQUIDATION_ADDRESS_IS_ZERO = "E263";
    string internal constant DD_LIQUIDATION_ALREADY_SET = "E264";

    // Protocol errors
    string internal constant INVALID_PRICE = "E301";
    string internal constant MARKET_NOT_FRESH = "E302";
    string internal constant BORROW_RATE_TOO_HIGH = "E303";
    string internal constant INSUFFICIENT_TOKEN_CASH = "E304";
    string internal constant INSUFFICIENT_TOKENS_FOR_RELEASE = "E305";
    string internal constant INSUFFICIENT_MNT_FOR_GRANT = "E306";
    string internal constant TOKEN_TRANSFER_IN_UNDERFLOW = "E307";
    string internal constant NOT_PARTICIPATING_IN_BUYBACK = "E308";
    string internal constant NOT_ENOUGH_PARTICIPATING_ACCOUNTS = "E309";
    string internal constant NOTHING_TO_DISTRIBUTE = "E310";
    string internal constant ALREADY_PARTICIPATING_IN_BUYBACK = "E311";
    string internal constant MNT_APPROVE_FAILS = "E312";
    string internal constant TOO_EARLY_TO_DRIP = "E313";
    string internal constant BB_UNSTAKE_TOO_EARLY = "E314";
    string internal constant INSUFFICIENT_SHORTFALL = "E315";
    string internal constant HEALTHY_FACTOR_NOT_IN_RANGE = "E316";
    string internal constant BUYBACK_DRIPS_ALREADY_HAPPENED = "E317";
    string internal constant EB_INDEX_SHOULD_BE_GREATER_THAN_INITIAL = "E318";
    string internal constant NO_VESTING_SCHEDULES = "E319";
    string internal constant INSUFFICIENT_UNRELEASED_TOKENS = "E320";
    string internal constant ORACLE_PRICE_EXPIRED = "E321";
    string internal constant TOKEN_NOT_FOUND = "E322";
    string internal constant RECEIVED_PRICE_HAS_INVALID_ROUND = "E323";
    string internal constant FL_PULL_AMOUNT_IS_TOO_LOW = "E324";
    string internal constant INSUFFICIENT_TOTAL_PROTOCOL_INTEREST = "E325";
    string internal constant BB_ACCOUNT_RECENTLY_VOTED = "E326";
    string internal constant DD_SWAP_ROUTER_IS_ZERO = "E327";
    string internal constant DD_SWAP_CALL_FAILS = "E328";
    string internal constant LL_NEW_ROOT_CANNOT_BE_ZERO = "E329";
    string internal constant RH_PAYOUT_FROM_FUTURE = "E330";
    string internal constant RH_ACCRUE_WITHOUT_UNLOCK = "E331";
    string internal constant RH_LERP_DELTA_IS_GREATER_THAN_PERIOD = "E332";
    string internal constant PRECONDITIONS_NOT_MET = "E333";

    // Invalid input - Admin functions
    string internal constant ZERO_EXCHANGE_RATE = "E401";
    string internal constant SECOND_INITIALIZATION = "E402";
    string internal constant MARKET_ALREADY_LISTED = "E403";
    string internal constant IDENTICAL_VALUE = "E404";
    string internal constant ZERO_ADDRESS = "E405";
    string internal constant EC_INVALID_PROVIDER_REPRESENTATIVE = "E406";
    string internal constant EC_PROVIDER_CANT_BE_REPRESENTATIVE = "E407";
    string internal constant OR_ORACLE_ADDRESS_CANNOT_BE_ZERO = "E408";
    string internal constant OR_UNDERLYING_TOKENS_DECIMALS_SHOULD_BE_GREATER_THAN_ZERO = "E409";
    string internal constant OR_REPORTER_MULTIPLIER_SHOULD_BE_GREATER_THAN_ZERO = "E410";
    string internal constant INVALID_TOKEN = "E411";
    string internal constant INVALID_PROTOCOL_INTEREST_FACTOR_MANTISSA = "E412";
    string internal constant INVALID_REDUCE_AMOUNT = "E413";
    string internal constant LIQUIDATION_FEE_MANTISSA_SHOULD_BE_GREATER_THAN_ZERO = "E414";
    string internal constant INVALID_UTILISATION_FACTOR_MANTISSA = "E415";
    string internal constant INVALID_MTOKENS_OR_BORROW_CAPS = "E416";
    string internal constant FL_PARAM_IS_TOO_LARGE = "E417";
    string internal constant MNT_INVALID_NONVOTING_PERIOD = "E418";
    string internal constant INPUT_ARRAY_LENGTHS_ARE_NOT_EQUAL = "E419";
    string internal constant EC_INVALID_BOOSTS = "E420";
    string internal constant EC_ACCOUNT_IS_ALREADY_LIQUIDITY_PROVIDER = "E421";
    string internal constant EC_ACCOUNT_HAS_NO_AGREEMENT = "E422";
    string internal constant OR_TIMESTAMP_THRESHOLD_SHOULD_BE_GREATER_THAN_ZERO = "E423";
    string internal constant OR_UNDERLYING_TOKENS_DECIMALS_TOO_BIG = "E424";
    string internal constant OR_REPORTER_MULTIPLIER_TOO_BIG = "E425";
    string internal constant SHOULD_HAVE_REVOCABLE_SCHEDULE = "E426";
    string internal constant MEMBER_NOT_IN_DELAY_LIST = "E427";
    string internal constant DELAY_LIST_LIMIT = "E428";
    string internal constant NUMBER_IS_NOT_IN_SCALE = "E429";
    string internal constant BB_STRATUM_OF_FIRST_LOYALTY_GROUP_IS_NOT_ZERO = "E430";
    string internal constant INPUT_ARRAY_IS_EMPTY = "E431";
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "./ILinkageRoot.sol";

interface ILinkageLeaf {
    /**
     * @notice Emitted when root contract address is changed
     */
    event LinkageRootSwitched(ILinkageRoot newRoot, ILinkageRoot oldRoot);

    /**
     * @notice Connects new root contract address
     * @param newRoot New root contract address
     */
    function switchLinkageRoot(ILinkageRoot newRoot) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

interface ILinkageRoot {
    /**
     * @notice Emitted when new root contract connected to all leafs
     */
    event LinkageRootSwitch(ILinkageRoot newRoot);

    /**
     * @notice Emitted when root interconnects its contracts
     */
    event LinkageRootInterconnected();

    /**
     * @notice Connects new root to all leafs contracts
     * @param newRoot New root contract address
     */
    function switchLinkageRoot(ILinkageRoot newRoot) external;

    /**
     * @notice Update root for all leaf contracts
     * @dev Should include only leaf contracts
     */
    function interconnect() external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./ILinkageLeaf.sol";

interface IBuyback is IAccessControl, ILinkageLeaf {
    event Stake(address who, uint256 amount);
    event Unstake(address who, uint256 amount);
    event NewBuyback(uint256 amount, uint256 share);
    event ParticipateBuyback(address who);
    event LeaveBuyback(address who, uint256 currentStaked);
    event BuybackWeightChanged(address who, uint256 newWeight, uint256 oldWeight, uint256 newTotalWeight);
    event LoyaltyParametersChanged(uint256 newCoreFactor, uint32 newCoreResetPenalty);
    event LoyaltyStrataChanged();
    event LoyaltyGroupsChanged(uint256 newGroupCount);

    /**
     * @notice Gets info about account membership in Buyback
     */
    function getMemberInfo(address account)
        external
        view
        returns (
            bool participating,
            uint256 weight,
            uint256 lastIndex,
            uint256 stakeAmount
        );

    /**
     * @notice Gets info about accounts loyalty calculation
     */
    function getLoyaltyInfo(address account)
        external
        view
        returns (
            uint32 loyaltyStart,
            uint256 coreBalance,
            uint256 lastBalance
        );

    /**
     * @notice Gets if an account is participating in Buyback
     */
    function isParticipating(address account) external view returns (bool);

    /**
     * @notice Gets stake of the account
     */
    function getStakedAmount(address account) external view returns (uint256);

    /**
     * @notice Gets buyback weight of an account
     */
    function getWeight(address account) external view returns (uint256);

    /**
     * @notice Gets loyalty factor of an account with given balance.
     */
    function getLoyaltyFactorForBalance(address account, uint256 balance) external view returns (uint256);

    /**
     * @notice Gets total Buyback weight, which is the sum of weights of all accounts.
     */
    function getTotalWeight() external view returns (uint256);

    /**
     * @notice Gets current Buyback index.
     * Its the accumulated sum of MNTs shares that are given for each weight of an account.
     */
    function getBuybackIndex() external view returns (uint256);

    /**
     * @notice Gets all global loyalty parameters.
     */
    function getLoyaltyParameters()
        external
        view
        returns (
            uint256[24] memory loyaltyStrata,
            uint256[] memory groupThresholds,
            uint32[] memory groupStartStrata,
            uint256 coreFactor,
            uint32 coreResetPenalty
        );

    /**
     * @notice Stakes the specified amount of MNT and transfers them to this contract.
     * @notice This contract should be approved to transfer MNT from sender account
     * @param amount The amount of MNT to stake
     */
    function stake(uint256 amount) external;

    /**
     * @notice Unstakes the specified amount of MNT and transfers them back to sender if he participates
     *         in the Buyback system, otherwise just transfers MNT tokens to the sender.
     *         would not be greater than staked amount left. If `amount == MaxUint256` unstakes all staked tokens.
     * @param amount The amount of MNT to unstake
     */
    function unstake(uint256 amount) external;

    /**
     * @notice Claims buyback rewards, updates buyback weight and voting power.
     * Does nothing if account is not participating. Reverts if operation is paused.
     * @param account Address to update weights for
     */
    function updateBuybackAndVotingWeights(address account) external;

    /**
     * @notice Claims buyback rewards, updates buyback weight and voting power.
     * Does nothing if account is not participating or update is paused.
     * @param account Address to update weights for
     */
    function updateBuybackAndVotingWeightsRelaxed(address account) external;

    /**
     * @notice Does a buyback using the specified amount of MNT from sender's account
     * @param amount The amount of MNT to take and distribute as buyback
     * @dev RESTRICTION: Distributor only
     */
    function buyback(uint256 amount) external;

    /**
     * @notice Make account participating in the buyback.
     */
    function participate() external;

    /**
     * @notice Make accounts participate in buyback before its start.
     * @param accounts Address to make participate in buyback.
     * @dev RESTRICTION: Admin only
     */
    function participateOnBehalf(address[] memory accounts) external;

    /**
     * @notice Leave buyback participation, claim any MNTs rewarded by the buyback.
     * Leaving does not withdraw staked MNTs but reduces weight of the account to zero
     */
    function leave() external;

    /**
     * @notice Leave buyback participation on behalf, claim any MNTs rewarded by the buyback and
     * reduce the weight of account to zero. All staked MNTs remain on the buyback contract and available
     * for their owner to be claimed
     * Can only be called if (timestamp > participantLastVoteTimestamp + maxNonVotingPeriod).
     * @param participant Address to leave for
     * @dev RESTRICTION: GATEKEEPER only
     */
    function leaveOnBehalf(address participant) external;

    /**
     * @notice Leave buyback participation on behalf, claim any MNTs rewarded by the buyback and
     * reduce the weight of account to zero. All staked MNTs remain on the buyback contract and available
     * for their owner to be claimed.
     * @dev Function to leave sanctioned accounts from Buyback system
     * Can only be called if the participant is sanctioned by the AML system.
     * @param participant Address to leave for
     */
    function leaveByAmlDecision(address participant) external;

    /**
     * @notice Changes loyalty core factor and core reset penalty parameters.
     * @dev RESTRICTION: Admin only
     */
    function setLoyaltyParameters(uint256 newCoreFactor, uint32 newCoreResetPenalty) external;

    /**
     * @notice Sets new loyalty factors for all strata.
     * @dev RESTRICTION: Admin only
     */
    function setLoyaltyStrata(uint256[24] memory newLoyaltyStrata) external;

    /**
     * @notice Sets new groups and their parameters
     * @param newGroupThresholds New list of groups and their balance thresholds.
     * @param newGroupStartStrata Indexes of starting stratum of each group. First index MUST be zero.
     *        Length of array must be equal to the newGroupThresholds
     * @dev RESTRICTION: Admin only
     */
    function setLoyaltyGroups(uint256[] memory newGroupThresholds, uint32[] memory newGroupStartStrata) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}