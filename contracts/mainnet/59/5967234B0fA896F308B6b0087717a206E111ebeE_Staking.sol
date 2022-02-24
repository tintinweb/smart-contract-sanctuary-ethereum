// SPDX-License-Identifier: MIT
// solhint-disable max-states-count

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "../interfaces/IStaking.sol";
import "../interfaces/IManager.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import {SafeMathUpgradeable as SafeMath} from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import {MathUpgradeable as Math} from "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import {OwnableUpgradeable as Ownable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {EnumerableSetUpgradeable as EnumerableSet} from "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";
import {PausableUpgradeable as Pausable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable as ReentrancyGuard} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "../interfaces/events/Destinations.sol";
import "../interfaces/events/BalanceUpdateEvent.sol";
import "../interfaces/IDelegateFunction.sol";
import "../interfaces/events/IEventSender.sol";

contract Staking is IStaking, Initializable, Ownable, Pausable, ReentrancyGuard, IEventSender {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    IERC20 public tokeToken;
    IManager public manager;

    address public treasury;

    uint256 public withheldLiquidity; // DEPRECATED
    //userAddress -> withdrawalInfo
    mapping(address => WithdrawalInfo) public requestedWithdrawals; // DEPRECATED

    //userAddress -> -> scheduleIndex -> staking detail
    mapping(address => mapping(uint256 => StakingDetails)) public userStakings;

    //userAddress -> scheduleIdx[]
    mapping(address => uint256[]) public userStakingSchedules;

    //Schedule id/index counter
    uint256 public nextScheduleIndex;
    //scheduleIndex/id -> schedule
    mapping(uint256 => StakingSchedule) public schedules;
    //scheduleIndex/id[]
    EnumerableSet.UintSet private scheduleIdxs;

    //Can deposit into a non-public schedule
    mapping(address => bool) public override permissionedDepositors;

    bool public _eventSend;
    Destinations public destinations;

    IDelegateFunction public delegateFunction; //DEPRECATED

    // ScheduleIdx => notional address
    mapping(uint256 => address) public notionalAddresses;
    // address -> scheduleIdx -> WithdrawalInfo
    mapping(address => mapping(uint256 => WithdrawalInfo)) public withdrawalRequestsByIndex;

    modifier onlyPermissionedDepositors() {
        require(_isAllowedPermissionedDeposit(), "CALLER_NOT_PERMISSIONED");
        _;
    }

    modifier onEventSend() {
        if (_eventSend) {
            _;
        }
    }

    function initialize(
        IERC20 _tokeToken,
        IManager _manager,
        address _treasury,
        address _scheduleZeroNotional
    ) public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();

        require(address(_tokeToken) != address(0), "INVALID_TOKETOKEN");
        require(address(_manager) != address(0), "INVALID_MANAGER");
        require(_treasury != address(0), "INVALID_TREASURY");

        tokeToken = _tokeToken;
        manager = _manager;
        treasury = _treasury;

        //We want to be sure the schedule used for LP staking is first
        //because the order in which withdraws happen need to start with LP stakes
        _addSchedule(
            StakingSchedule({
                cliff: 0,
                duration: 1,
                interval: 1,
                setup: true,
                isActive: true,
                hardStart: 0,
                isPublic: true
            }),
            _scheduleZeroNotional
        );
    }

    function addSchedule(StakingSchedule memory schedule, address notional)
        external
        override
        onlyOwner
    {
        _addSchedule(schedule, notional);
    }

    function setPermissionedDepositor(address account, bool canDeposit)
        external
        override
        onlyOwner
    {
        permissionedDepositors[account] = canDeposit;

        emit PermissionedDepositorSet(account, canDeposit);
    }

    function setUserSchedules(address account, uint256[] calldata userSchedulesIdxs)
        external
        override
        onlyOwner
    {
        userStakingSchedules[account] = userSchedulesIdxs;

        emit UserSchedulesSet(account, userSchedulesIdxs);
    }

    function getSchedules()
        external
        view
        override
        returns (StakingScheduleInfo[] memory retSchedules)
    {
        uint256 length = scheduleIdxs.length();
        retSchedules = new StakingScheduleInfo[](length);
        for (uint256 i = 0; i < length; i++) {
            retSchedules[i] = StakingScheduleInfo(
                schedules[scheduleIdxs.at(i)],
                scheduleIdxs.at(i)
            );
        }
    }

    function getStakes(address account)
        external
        view
        override
        returns (StakingDetails[] memory stakes)
    {
        stakes = _getStakes(account);
    }

    function setNotionalAddresses(uint256[] calldata scheduleIdxArr, address[] calldata addresses)
        external
        override
        onlyOwner
    {
        require(scheduleIdxArr.length == addresses.length, "MISMATCH_LENGTH");
        for (uint256 i = 0; i < scheduleIdxArr.length; i++) {
            uint256 currentScheduleIdx = scheduleIdxArr[i];
            address currentAddress = addresses[i];
            require(scheduleIdxs.contains(currentScheduleIdx), "INDEX_DOESNT_EXIST");
            require(currentAddress != address(0), "INVALID_ADDRESS");

            notionalAddresses[currentScheduleIdx] = currentAddress;
        }
        emit NotionalAddressesSet(scheduleIdxArr, addresses);
    }

    function balanceOf(address account) public view override returns (uint256 value) {
        value = 0;
        uint256 scheduleCount = userStakingSchedules[account].length;
        for (uint256 i = 0; i < scheduleCount; i++) {
            uint256 remaining = userStakings[account][userStakingSchedules[account][i]].initial.sub(
                userStakings[account][userStakingSchedules[account][i]].withdrawn
            );
            uint256 slashed = userStakings[account][userStakingSchedules[account][i]].slashed;
            if (remaining > slashed) {
                value = value.add(remaining.sub(slashed));
            }
        }
    }

    function availableForWithdrawal(address account, uint256 scheduleIndex)
        external
        view
        override
        returns (uint256)
    {
        return _availableForWithdrawal(account, scheduleIndex);
    }

    function unvested(address account, uint256 scheduleIndex)
        external
        view
        override
        returns (uint256 value)
    {
        value = 0;
        StakingDetails memory stake = userStakings[account][scheduleIndex];

        value = stake.initial.sub(_vested(account, scheduleIndex));
    }

    function vested(address account, uint256 scheduleIndex)
        external
        view
        override
        returns (uint256 value)
    {
        return _vested(account, scheduleIndex);
    }

    function deposit(uint256 amount, uint256 scheduleIndex) external override {
        _depositFor(msg.sender, amount, scheduleIndex);
    }

    function deposit(uint256 amount) external override {
        _depositFor(msg.sender, amount, 0);
    }

    function depositFor(
        address account,
        uint256 amount,
        uint256 scheduleIndex
    ) external override onlyPermissionedDepositors {
        _depositFor(account, amount, scheduleIndex);
    }

    function depositWithSchedule(
        address account,
        uint256 amount,
        StakingSchedule calldata schedule,
        address notional
    ) external override onlyPermissionedDepositors {
        uint256 scheduleIx = nextScheduleIndex;
        _addSchedule(schedule, notional);
        _depositFor(account, amount, scheduleIx);
    }

    function requestWithdrawal(uint256 amount, uint256 scheduleIdx) external override {
        require(amount > 0, "INVALID_AMOUNT");
        require(scheduleIdxs.contains(scheduleIdx), "INVALID_SCHEDULE");
        uint256 availableAmount = _availableForWithdrawal(msg.sender, scheduleIdx);
        require(availableAmount >= amount, "INSUFFICIENT_AVAILABLE");

        withdrawalRequestsByIndex[msg.sender][scheduleIdx].amount = amount;
        if (manager.getRolloverStatus()) {
            withdrawalRequestsByIndex[msg.sender][scheduleIdx].minCycleIndex = manager
                .getCurrentCycleIndex()
                .add(2);
        } else {
            withdrawalRequestsByIndex[msg.sender][scheduleIdx].minCycleIndex = manager
                .getCurrentCycleIndex()
                .add(1);
        }

        bytes32 eventSig = "Withdrawal Request";
        StakingDetails memory userStake = userStakings[msg.sender][scheduleIdx];
        uint256 voteTotal = userStake.initial.sub((userStake.slashed.add(userStake.withdrawn))).sub(
            amount
        );
        encodeAndSendData(eventSig, msg.sender, scheduleIdx, voteTotal);

        emit WithdrawalRequested(msg.sender, scheduleIdx, amount);
    }

    function withdraw(uint256 amount, uint256 scheduleIdx)
        external
        override
        nonReentrant
        whenNotPaused
    {
        require(amount > 0, "NO_WITHDRAWAL");
        require(scheduleIdxs.contains(scheduleIdx), "INVALID_SCHEDULE");
        _withdraw(amount, scheduleIdx);
    }

    function withdraw(uint256 amount) external override whenNotPaused nonReentrant {
        require(amount > 0, "INVALID_AMOUNT");
        _withdraw(amount, 0);
    }

    function slash(
        address[] calldata accounts,
        uint256[] calldata amounts,
        uint256 scheduleIndex
    ) external override onlyOwner whenNotPaused {
        require(accounts.length == amounts.length, "LENGTH_MISMATCH");
        StakingSchedule storage schedule = schedules[scheduleIndex];
        require(schedule.setup, "INVALID_SCHEDULE");

        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            uint256 amount = amounts[i];

            require(amount > 0, "INVALID_AMOUNT");
            require(account != address(0), "INVALID_ADDRESS");

            StakingDetails memory userStake = userStakings[account][scheduleIndex];
            require(userStake.initial > 0, "NO_VESTING");

            uint256 availableToSlash = 0;
            uint256 remaining = userStake.initial.sub(userStake.withdrawn);
            if (remaining > userStake.slashed) {
                availableToSlash = remaining.sub(userStake.slashed);
            }

            require(availableToSlash >= amount, "INSUFFICIENT_AVAILABLE");

            userStake.slashed = userStake.slashed.add(amount);
            userStakings[account][scheduleIndex] = userStake;

            uint256 totalLeft = userStake.initial.sub((userStake.slashed.add(userStake.withdrawn)));

            if (withdrawalRequestsByIndex[account][scheduleIndex].amount > totalLeft) {
                withdrawalRequestsByIndex[account][scheduleIndex].amount = totalLeft;
            }

            uint256 voteAmount = totalLeft.sub(
                withdrawalRequestsByIndex[account][scheduleIndex].amount
            );
            bytes32 eventSig = "Slashed";

            encodeAndSendData(eventSig, account, scheduleIndex, voteAmount);

            tokeToken.safeTransfer(treasury, amount);

            emit Slashed(account, amount, scheduleIndex);
        }
    }

    function setScheduleStatus(uint256 scheduleId, bool activeBool) external override onlyOwner {
        StakingSchedule storage schedule = schedules[scheduleId];
        schedule.isActive = activeBool;

        emit ScheduleStatusSet(scheduleId, activeBool);
    }

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function setDestinations(address _fxStateSender, address _destinationOnL2)
        external
        override
        onlyOwner
    {
        require(_fxStateSender != address(0), "INVALID_ADDRESS");
        require(_destinationOnL2 != address(0), "INVALID_ADDRESS");

        destinations.fxStateSender = IFxStateSender(_fxStateSender);
        destinations.destinationOnL2 = _destinationOnL2;

        emit DestinationsSet(_fxStateSender, _destinationOnL2);
    }

    function setEventSend(bool _eventSendSet) external override onlyOwner {
        require(destinations.destinationOnL2 != address(0), "DESTINATIONS_NOT_SET");

        _eventSend = _eventSendSet;

        emit EventSendSet(_eventSendSet);
    }

    function _availableForWithdrawal(address account, uint256 scheduleIndex)
        private
        view
        returns (uint256)
    {
        StakingDetails memory stake = userStakings[account][scheduleIndex];
        uint256 vestedWoWithdrawn = _vested(account, scheduleIndex).sub(stake.withdrawn);
        if (stake.slashed > vestedWoWithdrawn) return 0;

        return vestedWoWithdrawn.sub(stake.slashed);
    }

    function _depositFor(
        address account,
        uint256 amount,
        uint256 scheduleIndex
    ) private nonReentrant whenNotPaused {
        StakingSchedule memory schedule = schedules[scheduleIndex];
        require(amount > 0, "INVALID_AMOUNT");
        require(schedule.setup, "INVALID_SCHEDULE");
        require(schedule.isActive, "INACTIVE_SCHEDULE");
        require(account != address(0), "INVALID_ADDRESS");
        require(schedule.isPublic || _isAllowedPermissionedDeposit(), "PERMISSIONED_SCHEDULE");

        StakingDetails memory userStake = _updateStakingDetails(scheduleIndex, account, amount);

        bytes32 eventSig = "Deposit";
        uint256 voteTotal = userStake.initial.sub((userStake.slashed.add(userStake.withdrawn))).sub(
            withdrawalRequestsByIndex[account][scheduleIndex].amount
        );
        encodeAndSendData(eventSig, account, scheduleIndex, voteTotal);

        tokeToken.safeTransferFrom(msg.sender, address(this), amount);

        emit Deposited(account, amount, scheduleIndex);
    }

    function _withdraw(uint256 amount, uint256 scheduleIdx) private {
        WithdrawalInfo memory request = withdrawalRequestsByIndex[msg.sender][scheduleIdx];
        require(amount <= request.amount, "INSUFFICIENT_AVAILABLE");
        require(request.minCycleIndex <= manager.getCurrentCycleIndex(), "INVALID_CYCLE");

        StakingDetails memory userStake = userStakings[msg.sender][scheduleIdx];
        userStake.withdrawn = userStake.withdrawn.add(amount);
        userStakings[msg.sender][scheduleIdx] = userStake;

        request.amount = request.amount.sub(amount);
        withdrawalRequestsByIndex[msg.sender][scheduleIdx] = request;

        if (request.amount == 0) {
            delete withdrawalRequestsByIndex[msg.sender][scheduleIdx];
        }

        tokeToken.safeTransfer(msg.sender, amount);

        emit WithdrawCompleted(msg.sender, scheduleIdx, amount);
    }

    function _vested(address account, uint256 scheduleIndex) private view returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        uint256 timestamp = block.timestamp;
        uint256 value = 0;
        StakingDetails memory stake = userStakings[account][scheduleIndex];
        StakingSchedule memory schedule = schedules[scheduleIndex];

        uint256 cliffTimestamp = stake.started.add(schedule.cliff);
        if (cliffTimestamp <= timestamp) {
            if (cliffTimestamp.add(schedule.duration) <= timestamp) {
                value = stake.initial;
            } else {
                uint256 secondsStaked = Math.max(timestamp.sub(cliffTimestamp), 1);
                //Precision loss is intentional. Enables the interval buckets
                uint256 effectiveSecondsStaked = (secondsStaked.div(schedule.interval)).mul(
                    schedule.interval
                );
                value = stake.initial.mul(effectiveSecondsStaked).div(schedule.duration);
            }
        }

        return value;
    }

    function _addSchedule(StakingSchedule memory schedule, address notional) private {
        require(schedule.duration > 0, "INVALID_DURATION");
        require(schedule.interval > 0, "INVALID_INTERVAL");
        require(notional != address(0), "INVALID_ADDRESS");

        schedule.setup = true;
        uint256 index = nextScheduleIndex;
        schedules[index] = schedule;
        notionalAddresses[index] = notional;
        require(scheduleIdxs.add(index), "ADD_FAIL");
        nextScheduleIndex = nextScheduleIndex.add(1);

        emit ScheduleAdded(
            index,
            schedule.cliff,
            schedule.duration,
            schedule.interval,
            schedule.setup,
            schedule.isActive,
            schedule.hardStart,
            notional
        );
    }

    function _getStakes(address account) private view returns (StakingDetails[] memory stakes) {
        uint256 stakeCnt = userStakingSchedules[account].length;
        stakes = new StakingDetails[](stakeCnt);

        for (uint256 i = 0; i < stakeCnt; i++) {
            stakes[i] = userStakings[account][userStakingSchedules[account][i]];
        }
    }

    function _isAllowedPermissionedDeposit() private view returns (bool) {
        return permissionedDepositors[msg.sender] || msg.sender == owner();
    }

    function encodeAndSendData(
        bytes32 _eventSig,
        address _user,
        uint256 _scheduleIdx,
        uint256 _userBalance
    ) private onEventSend {
        require(address(destinations.fxStateSender) != address(0), "ADDRESS_NOT_SET");
        require(destinations.destinationOnL2 != address(0), "ADDRESS_NOT_SET");
        address notionalAddress = notionalAddresses[_scheduleIdx];

        bytes memory data = abi.encode(
            BalanceUpdateEvent({
                eventSig: _eventSig,
                account: _user,
                token: notionalAddress,
                amount: _userBalance
            })
        );

        destinations.fxStateSender.sendMessageToChild(destinations.destinationOnL2, data);
    }

    function _updateStakingDetails(
        uint256 scheduleIdx,
        address account,
        uint256 amount
    ) private returns (StakingDetails memory) {
        StakingDetails memory stake = userStakings[account][scheduleIdx];
        if (stake.started == 0) {
            userStakingSchedules[account].push(scheduleIdx);
            StakingSchedule memory schedule = schedules[scheduleIdx];
            if (schedule.hardStart > 0) {
                stake.started = schedule.hardStart;
            } else {
                //solhint-disable-next-line not-rely-on-time
                stake.started = block.timestamp;
            }
        }
        stake.initial = stake.initial.add(amount);
        stake.scheduleIx = scheduleIdx;
        userStakings[account][scheduleIdx] = stake;

        return stake;
    }

    function depositWithdrawEvent(
        address withdrawUser,
        uint256 withdrawAmount,
        uint256 withdrawScheduleIdx,
        address depositUser,
        uint256 depositAmount,
        uint256 depositScheduleIdx
    ) private {
        bytes32 withdrawEvent = "Withdraw";
        bytes32 depositEvent = "Deposit";
        encodeAndSendData(withdrawEvent, withdrawUser, withdrawScheduleIdx, withdrawAmount);
        encodeAndSendData(depositEvent, depositUser, depositScheduleIdx, depositAmount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

/**
 *  @title Allows for the staking and vesting of TOKE for
 *  liquidity directors. Schedules can be added to enable various
 *  cliff+duration/interval unlock periods for vesting tokens.
 */
interface IStaking {
    struct StakingSchedule {
        uint256 cliff; // Duration in seconds before staking starts
        uint256 duration; // Seconds it takes for entire amount to stake
        uint256 interval; // Seconds it takes for a chunk to stake
        bool setup; //Just so we know its there
        bool isActive; //Whether we can setup new stakes with the schedule
        uint256 hardStart; //Stakings will always start at this timestamp if set
        bool isPublic; //Schedule can be written to by any account
    }

    struct StakingScheduleInfo {
        StakingSchedule schedule;
        uint256 index;
    }

    struct StakingDetails {
        uint256 initial; //Initial amount of asset when stake was created, total amount to be staked before slashing
        uint256 withdrawn; //Amount that was staked and subsequently withdrawn
        uint256 slashed; //Amount that has been slashed
        uint256 started; //Timestamp at which the stake started
        uint256 scheduleIx;
    }

    struct WithdrawalInfo {
        uint256 minCycleIndex;
        uint256 amount;
    }

    struct QueuedTransfer {
        address from;
        uint256 scheduleIdxFrom;
        uint256 scheduleIdxTo;
        uint256 amount;
        address to;
    }

    event ScheduleAdded(
        uint256 scheduleIndex,
        uint256 cliff,
        uint256 duration,
        uint256 interval,
        bool setup,
        bool isActive,
        uint256 hardStart,
        address notional
    );
    event ScheduleRemoved(uint256 scheduleIndex);
    event WithdrawalRequested(address account, uint256 scheduleIdx, uint256 amount);
    event WithdrawCompleted(address account, uint256 scheduleIdx, uint256 amount);
    event Deposited(address account, uint256 amount, uint256 scheduleIx);
    event Slashed(address account, uint256 amount, uint256 scheduleIx);
    event PermissionedDepositorSet(address depositor, bool allowed);
    event UserSchedulesSet(address account, uint256[] userSchedulesIdxs);
    event NotionalAddressesSet(uint256[] scheduleIdxs, address[] addresses);
    event ScheduleStatusSet(uint256 scheduleId, bool isActive);
    event StakeTransferred(
        address from,
        uint256 scheduleFrom,
        uint256 scheduleTo,
        uint256 amount,
        address to
    );
    event ZeroSweep(address user, uint256 amount, uint256 scheduleFrom);
    event TransferApproverSet(address approverAddress);
    event TransferQueued(
        address from,
        uint256 scheduleFrom,
        uint256 scheduleTo,
        uint256 amount,
        address to
    );
    event QueuedTransferRemoved(
        address from,
        uint256 scheduleFrom,
        uint256 scheduleTo,
        uint256 amount,
        address to
    );
    event QueuedTransferRejected(
        address from,
        uint256 scheduleFrom,
        uint256 scheduleTo,
        uint256 amount,
        address to
    );

    ///@notice Allows for checking of user address in permissionedDepositors mapping
    ///@param account Address of account being checked
    ///@return Boolean, true if address exists in mapping
    function permissionedDepositors(address account) external returns (bool);

    ///@notice Allows owner to set a multitude of schedules that an address has access to
    ///@param account User address
    ///@param userSchedulesIdxs Array of schedule indexes
    function setUserSchedules(address account, uint256[] calldata userSchedulesIdxs) external;

    ///@notice Allows owner to add schedule
    ///@param schedule A StakingSchedule struct that contains all info needed to make a schedule
    ///@param notional Notional addrss for schedule, used to send balances to L2 for voting purposes
    function addSchedule(StakingSchedule memory schedule, address notional) external;

    ///@notice Gets all info on all schedules
    ///@return retSchedules An array of StakingScheduleInfo struct
    function getSchedules() external view returns (StakingScheduleInfo[] memory retSchedules);

    ///@notice Allows owner to set a permissioned depositor
    ///@param account User address
    ///@param canDeposit Boolean representing whether user can deposit
    function setPermissionedDepositor(address account, bool canDeposit) external;

    ///@notice Allows a user to get the stakes of an account
    ///@param account Address that is being checked for stakes
    ///@return stakes StakingDetails array containing info about account's stakes
    function getStakes(address account) external view returns (StakingDetails[] memory stakes);

    ///@notice Gets total value staked for an address across all schedules
    ///@param account Address for which total stake is being calculated
    ///@return value uint256 total of account
    function balanceOf(address account) external view returns (uint256 value);

    ///@notice Returns amount available to withdraw for an account and schedule Index
    ///@param account Address that is being checked for withdrawals
    ///@param scheduleIndex Index of schedule that is being checked for withdrawals
    function availableForWithdrawal(address account, uint256 scheduleIndex)
        external
        view
        returns (uint256);

    ///@notice Returns unvested amount for certain address and schedule index
    ///@param account Address being checked for unvested amount
    ///@param scheduleIndex Schedule index being checked for unvested amount
    ///@return value Uint256 representing unvested amount
    function unvested(address account, uint256 scheduleIndex) external view returns (uint256 value);

    ///@notice Returns vested amount for address and schedule index
    ///@param account Address being checked for vested amount
    ///@param scheduleIndex Schedule index being checked for vested amount
    ///@return value Uint256 vested
    function vested(address account, uint256 scheduleIndex) external view returns (uint256 value);

    ///@notice Allows user to deposit token to specific vesting / staking schedule
    ///@param amount Uint256 amount to be deposited
    ///@param scheduleIndex Uint256 representing schedule to user
    function deposit(uint256 amount, uint256 scheduleIndex) external;

    /// @notice Allows users to deposit into 0 schedule
    /// @param amount Deposit amount
    function deposit(uint256 amount) external;

    ///@notice Allows account to deposit on behalf of other account
    ///@param account Account to be deposited for
    ///@param amount Amount to be deposited
    ///@param scheduleIndex Index of schedule to be used for deposit
    function depositFor(
        address account,
        uint256 amount,
        uint256 scheduleIndex
    ) external;

    ///@notice Allows permissioned depositors to deposit into custom schedule
    ///@param account Address of account being deposited for
    ///@param amount Uint256 amount being deposited
    ///@param schedule StakingSchedule struct containing details needed for new schedule
    ///@param notional Notional address attached to schedule, allows for different voting weights on L2
    function depositWithSchedule(
        address account,
        uint256 amount,
        StakingSchedule calldata schedule,
        address notional
    ) external;

    ///@notice User can request withdrawal from staking contract at end of cycle
    ///@notice Performs checks to make sure amount <= amount available
    ///@param amount Amount to withdraw
    ///@param scheduleIdx Schedule index for withdrawal Request
    function requestWithdrawal(uint256 amount, uint256 scheduleIdx) external;

    ///@notice Allows for withdrawal after successful withdraw request and proper amount of cycles passed
    ///@param amount Amount to withdraw
    ///@param scheduleIdx Schedule to withdraw from
    function withdraw(uint256 amount, uint256 scheduleIdx) external;

    /// @notice Allows owner to set schedule to active or not
    /// @param scheduleIndex Schedule index to set isActive boolean
    /// @param activeBoolean Bool to set schedule active or not
    function setScheduleStatus(uint256 scheduleIndex, bool activeBoolean) external;

    /// @notice Pause deposits on the pool. Withdraws still allowed
    function pause() external;

    /// @notice Unpause deposits on the pool.
    function unpause() external;

    /// @notice Used to slash user funds when needed
    /// @notice accounts and amounts arrays must be same length
    /// @notice Only one scheduleIndex can be slashed at a time
    /// @dev Implementation must be restructed to owner account
    /// @param accounts Array of accounts to slash
    /// @param amounts Array of amounts that corresponds with accounts
    /// @param scheduleIndex scheduleIndex of users that are being slashed
    function slash(
        address[] calldata accounts,
        uint256[] calldata amounts,
        uint256 scheduleIndex
    ) external;

    /// @notice Set the address used to denote the token amount for a particular schedule
    /// @dev Relates to the Balance Tracker tracking of tokens and balances. Each schedule is tracked separately
    function setNotionalAddresses(uint256[] calldata scheduleIdxArr, address[] calldata addresses)
        external;

    /// @notice Withdraw from the default schedule. Must have a request in previously
    /// @param amount Amount to withdraw
    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

/**
 *  @title Controls the transition and execution of liquidity deployment cycles.
 *  Accepts instructions that can move assets from the Pools to the Exchanges
 *  and back. Can also move assets to the treasury when appropriate.
 */
interface IManager {
    // bytes can take on the form of deploying or recovering liquidity
    struct ControllerTransferData {
        bytes32 controllerId; // controller to target
        bytes data; // data the controller will pass
    }

    struct PoolTransferData {
        address pool; // pool to target
        uint256 amount; // amount to transfer
    }

    struct MaintenanceExecution {
        ControllerTransferData[] cycleSteps;
    }

    struct RolloverExecution {
        PoolTransferData[] poolData;
        ControllerTransferData[] cycleSteps;
        address[] poolsForWithdraw; //Pools to target for manager -> pool transfer
        bool complete; //Whether to mark the rollover complete
        string rewardsIpfsHash;
    }

    event ControllerRegistered(bytes32 id, address controller);
    event ControllerUnregistered(bytes32 id, address controller);
    event PoolRegistered(address pool);
    event PoolUnregistered(address pool);
    event CycleDurationSet(uint256 duration);
    event LiquidityMovedToManager(address pool, uint256 amount);
    event DeploymentStepExecuted(bytes32 controller, address adapaterAddress, bytes data);
    event LiquidityMovedToPool(address pool, uint256 amount);
    event CycleRolloverStarted(uint256 timestamp);
    event CycleRolloverComplete(uint256 timestamp);
    event NextCycleStartSet(uint256 nextCycleStartTime);
    event ManagerSwept(address[] addresses, uint256[] amounts);

    /// @notice Registers controller
    /// @param id Bytes32 id of controller
    /// @param controller Address of controller
    function registerController(bytes32 id, address controller) external;

    /// @notice Registers pool
    /// @param pool Address of pool
    function registerPool(address pool) external;

    /// @notice Unregisters controller
    /// @param id Bytes32 controller id
    function unRegisterController(bytes32 id) external;

    /// @notice Unregisters pool
    /// @param pool Address of pool
    function unRegisterPool(address pool) external;

    ///@notice Gets addresses of all pools registered
    ///@return Memory array of pool addresses
    function getPools() external view returns (address[] memory);

    ///@notice Gets ids of all controllers registered
    ///@return Memory array of Bytes32 controller ids
    function getControllers() external view returns (bytes32[] memory);

    ///@notice Allows for owner to set cycle duration
    ///@param duration Block durtation of cycle
    function setCycleDuration(uint256 duration) external;

    ///@notice Starts cycle rollover
    ///@dev Sets rolloverStarted state boolean to true
    function startCycleRollover() external;

    ///@notice Allows for controller commands to be executed midcycle
    ///@param params Contains data for controllers and params
    function executeMaintenance(MaintenanceExecution calldata params) external;

    ///@notice Allows for withdrawals and deposits for pools along with liq deployment
    ///@param params Contains various data for executing against pools and controllers
    function executeRollover(RolloverExecution calldata params) external;

    ///@notice Completes cycle rollover, publishes rewards hash to ipfs
    ///@param rewardsIpfsHash rewards hash uploaded to ipfs
    function completeRollover(string calldata rewardsIpfsHash) external;

    ///@notice Gets reward hash by cycle index
    ///@param index Cycle index to retrieve rewards hash
    ///@return String memory hash
    function cycleRewardsHashes(uint256 index) external view returns (string memory);

    ///@notice Gets current starting block
    ///@return uint256 with block number
    function getCurrentCycle() external view returns (uint256);

    ///@notice Gets current cycle index
    ///@return uint256 current cycle number
    function getCurrentCycleIndex() external view returns (uint256);

    ///@notice Gets current cycle duration
    ///@return uint256 in block of cycle duration
    function getCycleDuration() external view returns (uint256);

    ///@notice Gets cycle rollover status, true for rolling false for not
    ///@return Bool representing whether cycle is rolling over or not
    function getRolloverStatus() external view returns (bool);

    /// @notice Sets next cycle start time manually
    /// @param nextCycleStartTime uint256 that represents start of next cycle
    function setNextCycleStartTime(uint256 nextCycleStartTime) external;

    /// @notice Sweeps amanager contract for any leftover funds
    /// @param addresses array of addresses of pools to sweep funds into
    function sweep(address[] calldata addresses) external;

    /// @notice Setup a role using internal function _setupRole
    /// @param role keccak256 of the role keccak256("MY_ROLE");
    function setupRole(bytes32 role) external;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

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
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;

import "../../fxPortal/IFxStateSender.sol";

/// @notice Configuration entity for sending events to Governance layer
struct Destinations {
    IFxStateSender fxStateSender;
    address destinationOnL2;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;

/// @notice Event sent to Governance layer when a users balance changes
struct BalanceUpdateEvent {
    bytes32 eventSig;
    address account;
    address token;
    uint256 amount;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "./structs/DelegateMapView.sol";
import "./structs/Signature.sol";

/**
 *   @title Manages the state of an accounts delegation settings.
 *   Allows for various methods of validation as well as enabling
 *   different system functions to be delegated to different accounts
 */
interface IDelegateFunction {
    struct AllowedFunctionSet {
        bytes32 id;
    }

    struct FunctionsListPayload {
        bytes32[] sets;
        uint256 nonce;
    }

    struct DelegatePayload {
        DelegateMap[] sets;
        uint256 nonce;
    }

    struct DelegateMap {
        bytes32 functionId;
        address otherParty;
        bool mustRelinquish;
    }

    struct Destination {
        address otherParty;
        bool mustRelinquish;
        bool pending;
    }

    struct DelegatedTo {
        address originalParty;
        bytes32 functionId;
    }

    event AllowedFunctionsSet(AllowedFunctionSet[] functions);
    event PendingDelegationAdded(address from, address to, bytes32 functionId, bool mustRelinquish);
    event PendingDelegationRemoved(
        address from,
        address to,
        bytes32 functionId,
        bool mustRelinquish
    );
    event DelegationRemoved(address from, address to, bytes32 functionId, bool mustRelinquish);
    event DelegationRelinquished(address from, address to, bytes32 functionId, bool mustRelinquish);
    event DelegationAccepted(address from, address to, bytes32 functionId, bool mustRelinquish);
    event DelegationRejected(address from, address to, bytes32 functionId, bool mustRelinquish);

    /// @notice Get the current nonce a contract wallet should use
    /// @param account Account to query
    /// @return nonce Nonce that should be used for next call
    function contractWalletNonces(address account) external returns (uint256 nonce);

    /// @notice Get an accounts current delegations
    /// @dev These may be in a pending state
    /// @param from Account that is delegating functions away
    /// @return maps List of delegations in various states of approval
    function getDelegations(address from) external view returns (DelegateMapView[] memory maps);

    /// @notice Get an accounts delegation of a specific function
    /// @dev These may be in a pending state
    /// @param from Account that is the delegation functions away
    /// @return map Delegation info
    function getDelegation(address from, bytes32 functionId)
        external
        view
        returns (DelegateMapView memory map);

    /// @notice Initiate delegation of one or more system functions to different account(s)
    /// @param sets Delegation instructions for the contract to initiate
    function delegate(DelegateMap[] memory sets) external;

    /// @notice Initiate delegation on behalf of a contract that supports ERC1271
    /// @param contractAddress Address of the ERC1271 contract used to verify the given signature
    /// @param delegatePayload Sets of DelegateMap objects
    /// @param signature Signature data
    /// @param signatureType Type of signature used (EIP712|EthSign)
    function delegateWithEIP1271(
        address contractAddress,
        DelegatePayload memory delegatePayload,
        bytes memory signature,
        SignatureType signatureType
    ) external;

    /// @notice Accept one or more delegations from another account
    /// @param incoming Delegation details being accepted
    function acceptDelegation(DelegatedTo[] calldata incoming) external;

    /// @notice Remove one or more delegation that you have previously setup
    function removeDelegation(bytes32[] calldata functionIds) external;

    /// @notice Remove one or more delegations that you have previously setup on behalf of a contract supporting EIP1271
    /// @param contractAddress Address of the ERC1271 contract used to verify the given signature
    /// @param functionsListPayload Sets of FunctionListPayload objects ({sets: bytes32[]})
    /// @param signature Signature data
    /// @param signatureType Type of signature used (EIP712|EthSign)
    function removeDelegationWithEIP1271(
        address contractAddress,
        FunctionsListPayload calldata functionsListPayload,
        bytes memory signature,
        SignatureType signatureType
    ) external;

    /// @notice Reject one or more delegations being sent to you
    /// @param rejections Delegations to reject
    function rejectDelegation(DelegatedTo[] calldata rejections) external;

    /// @notice Remove one or more delegations that you have previously accepted
    function relinquishDelegation(DelegatedTo[] calldata relinquish) external;

    /// @notice Cancel one or more delegations you have setup but that has not yet been accepted
    /// @param functionIds System functions you wish to retain control of
    function cancelPendingDelegation(bytes32[] calldata functionIds) external;

    /// @notice Cancel one or more delegations you have setup on behalf of a contract that supported EIP1271, but that has not yet been accepted
    /// @param contractAddress Address of the ERC1271 contract used to verify the given signature
    /// @param functionsListPayload Sets of FunctionListPayload objects ({sets: bytes32[]})
    /// @param signature Signature data
    /// @param signatureType Type of signature used (EIP712|EthSign)
    function cancelPendingDelegationWithEIP1271(
        address contractAddress,
        FunctionsListPayload calldata functionsListPayload,
        bytes memory signature,
        SignatureType signatureType
    ) external;

    /// @notice Add to the list of system functions that are allowed to be delegated
    /// @param functions New system function ids
    function setAllowedFunctions(AllowedFunctionSet[] calldata functions) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;
pragma experimental ABIEncoderV2;

import "./Destinations.sol";

interface IEventSender {
    event DestinationsSet(address fxStateSender, address destinationOnL2);
    event EventSendSet(bool eventSendSet);

    /// @notice Configure the Polygon state sender root and destination for messages sent
    /// @param fxStateSender Address of Polygon State Sender Root contract
    /// @param destinationOnL2 Destination address of events sent. Should be our Event Proxy
    function setDestinations(address fxStateSender, address destinationOnL2) external;

    /// @notice Enables or disables the sending of events
    function setEventSend(bool eventSendSet) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface IFxStateSender {
    function sendMessageToChild(address _receiver, bytes calldata _data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

/// @notice Stores votes and rewards delegation mapping in DelegateFunction
struct DelegateMapView {
    bytes32 functionId;
    address otherParty;
    bool mustRelinquish;
    bool pending;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

/// @notice Denotes the type of signature being submitted to contracts that support multiple
enum SignatureType {
    INVALID,
    // Specifically signTypedData_v4
    EIP712,
    // Specifically personal_sign
    ETHSIGN
}