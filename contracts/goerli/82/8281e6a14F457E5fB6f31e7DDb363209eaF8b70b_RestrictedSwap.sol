// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IRestrictedSwap.sol";
import "./RestrictedLockupToken.sol";
import "./interfaces/IERC1404.sol";
import "./Dividends.sol";


contract RestrictedSwap is Dividends, IRestrictedSwap {

    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @dev swap number
    uint256 public _swapNumber;

    /// @dev swap number => swap
    mapping(uint256 => Swap) private _swap;

    event SwapPausedState(bool isPausedSwaps);

    bool public pausedSwaps;

    modifier onlyValidSwap(uint256 swapNumber) {
        Swap storage swap = _swap[swapNumber];
        require(swap.status != SwapStatus.Canceled, "Already canceled");
        require(swap.status != SwapStatus.Complete, "Already completed");
        _;
    }

    modifier onlyUnpaused() {
        require(pausedSwaps == false, "All swaps are paused");
        _;
    }

    function initialize(
        address contractAdmin_,
        address tokenReserveAdmin_,
        address restrictedLockupTokenAddress_
    ) initializer public override {
        __Ownable_init();
        __UUPSUpgradeable_init();

        __Dividends_init(
            contractAdmin_,
            tokenReserveAdmin_,
            restrictedLockupTokenAddress_
        );

        _swapNumber = 0;
        pausedSwaps = false;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function pauseSwaps() external onlyContractAdmin {
        pausedSwaps = true;
        emit SwapPausedState(true);
    }

    function unpauseSwaps() external onlyContractAdmin {
        pausedSwaps = false;
        emit SwapPausedState(false);
    }

    function swapNumber() external view returns (uint256) {
        return _swapNumber;
    }

    /**
     * @dev Configures swap and emits an event. This function does not fund tokens. Only for swap configuration.
   * @param restrictedTokenSender restricted token sender
   * @param quoteTokenSender quote token sender
   * @param quoteToken quote token
   * @param restrictedTokenAmount restricted token amount
   * @param quoteTokenAmount quote token amount
   */
    function _configureSwap(
        address restrictedTokenSender,
        address quoteTokenSender,
        address quoteToken,
        uint256 restrictedTokenAmount,
        uint256 quoteTokenAmount,
        SwapStatus configuror
    ) private onlyUnpaused {
        require(restrictedTokenAmount > 0, "Invalid restricted token amount");
        require(quoteTokenAmount > 0, "Invalid quote token amount");
        require(quoteToken != address(0), "Invalid quote token address");

        uint8 code = restrictedLockupToken.detectTransferRestriction(
            restrictedTokenSender,
            quoteTokenSender,
            restrictedTokenAmount);
        string memory message = restrictedLockupToken.messageForTransferRestriction(code);
        require(code == 0, message);
        // 0 == success

        bytes memory data = abi.encodeWithSelector(
            IERC1404(quoteToken).detectTransferRestriction.selector,
            quoteTokenSender,
            restrictedTokenSender,
            quoteTokenAmount);
        (bool isErc1404, bytes memory returnData) = quoteToken.call(data);

        if (isErc1404) {
            code = abi.decode(returnData, (uint8));
            message = IERC1404(quoteToken).messageForTransferRestriction(code);
            require(code == 0, message);
            // 0 == success
        }

        _swapNumber += 1;

        Swap storage swap = _swap[_swapNumber];
        swap.restrictedTokenSender = restrictedTokenSender;
        swap.restrictedTokenAmount = restrictedTokenAmount;
        swap.quoteTokenSender = quoteTokenSender;
        swap.quoteTokenAmount = quoteTokenAmount;
        swap.quoteToken = quoteToken;
        swap.status = configuror;

        emit SwapConfigured(
            _swapNumber,
            restrictedTokenSender,
            restrictedTokenAmount,
            quoteToken,
            quoteTokenSender,
            quoteTokenAmount
        );
    }

    /**
     *  @dev Configure swap and emit an event with new swap number
   *  @param restrictedTokenAmount the required amount for the erc1404Sender to send
   *  @param quoteToken the address of an erc1404 or erc20 that will be swapped
   *  @param quoteTokenSender the address that is approved to fund quoteToken
   *  @param quoteTokenAmount the required amount of quoteToken to swap
   */
    function configureSell(
        uint256 restrictedTokenAmount,
        address quoteToken,
        address quoteTokenSender,
        uint256 quoteTokenAmount
    ) external override {
        require(quoteTokenSender != address(0), "Invalid quote token sender");
        require(restrictedLockupToken.balanceOf(msg.sender) >= restrictedTokenAmount, "Insufficient restricted token amount");

        _configureSwap(
            msg.sender,
            quoteTokenSender,
            quoteToken,
            restrictedTokenAmount,
            quoteTokenAmount,
            SwapStatus.SellConfigured
        );

        // fund caller's restricted token into swap
        restrictedLockupToken.swapTransfer(msg.sender, address(this), restrictedTokenAmount);
    }

    /**
     *  @dev Configure swap and emit an event with new swap number
   *  @param restrictedTokenAmount the required amount for the erc1404Sender to send
   *  @param restrictedTokenSender restricted token sender
   *  @param quoteToken the address of an erc1404 or erc20 that will be swapped
   *  @param quoteTokenAmount the required amount of quoteToken to swap
   */
    function configureBuy(
        uint256 restrictedTokenAmount,
        address restrictedTokenSender,
        address quoteToken,
        uint256 quoteTokenAmount
    ) external override {
        require(restrictedTokenSender != address(0), "Invalid restricted token sender");

        _configureSwap(
            restrictedTokenSender,
            msg.sender,
            quoteToken,
            restrictedTokenAmount,
            quoteTokenAmount,
            SwapStatus.BuyConfigured
        );

        // fund caller's quote token into swap
        IERC20Upgradeable(quoteToken).safeTransferFrom(msg.sender, address(this), quoteTokenAmount);
    }

    /**
     *  @dev Complete swap with quote token
   *  @param swapNumber swap number
   */
    function completeSwapWithPaymentToken(uint256 swapNumber)
    external
    override
    onlyValidSwap(swapNumber) onlyUnpaused
    {
        Swap storage swap = _swap[swapNumber];

        require(swap.quoteTokenSender == msg.sender, "You are not appropriate token sender for this swap");

        uint256 balanceBefore = IERC20Upgradeable(swap.quoteToken).balanceOf(swap.restrictedTokenSender);
        IERC20Upgradeable(swap.quoteToken).safeTransferFrom(msg.sender, swap.restrictedTokenSender, swap.quoteTokenAmount);
        uint256 balanceAfter = IERC20Upgradeable(swap.quoteToken).balanceOf(swap.restrictedTokenSender);

        require(balanceBefore + swap.quoteTokenAmount == balanceAfter, "Deposit reverted for incorrect result of deposited amount");

        swap.status = SwapStatus.Complete;

        restrictedLockupToken.swapTransfer(address(this), swap.quoteTokenSender, swap.restrictedTokenAmount);

        emit SwapComplete(
            swapNumber,
            swap.restrictedTokenSender,
            swap.restrictedTokenAmount,
            swap.quoteTokenSender,
            swap.quoteToken,
            swap.quoteTokenAmount
        );
    }

    /**
     *  @dev Complete swap with restricted token
   *  @param swapNumber swap number
   */
    function completeSwapWithRestrictedToken(uint256 swapNumber)
    external
    override
    onlyValidSwap(swapNumber)
    onlyUnpaused
    {
        Swap storage swap = _swap[swapNumber];

        require(swap.restrictedTokenSender == msg.sender, "You are not appropriate token sender for this swap");

        uint256 balanceBefore = IERC20Upgradeable(swap.quoteToken).balanceOf(swap.restrictedTokenSender);
        IERC20Upgradeable(swap.quoteToken).safeTransfer(msg.sender, swap.quoteTokenAmount);
        uint256 balanceAfter = IERC20Upgradeable(swap.quoteToken).balanceOf(swap.restrictedTokenSender);

        require(balanceBefore + swap.quoteTokenAmount == balanceAfter, "Deposit reverted for incorrect result of deposited amount");

        swap.status = SwapStatus.Complete;

        restrictedLockupToken.swapTransfer(msg.sender, swap.quoteTokenSender, swap.restrictedTokenAmount);

        emit SwapComplete(
            swapNumber,
            swap.restrictedTokenSender,
            swap.restrictedTokenAmount,
            swap.quoteTokenSender,
            swap.quoteToken,
            swap.quoteTokenAmount
        );
    }

    /**
     *  @dev cancel swap
   *  @param swapNumber swap number
   */
    function cancelSell(uint256 swapNumber)
    external
    override
    onlyValidSwap(swapNumber)
    {
        Swap storage swap = _swap[swapNumber];

        require(swap.restrictedTokenSender != address(0), "This swap is not configured");
        require(swap.quoteTokenSender != address(0), "This swap is not configured");

        if (swap.status == SwapStatus.SellConfigured) {
            require(msg.sender == swap.restrictedTokenSender, "Only swap configurator can cancel the swap");
            restrictedLockupToken.swapTransfer(address(this), swap.restrictedTokenSender, swap.restrictedTokenAmount);
        } else if (swap.status == SwapStatus.BuyConfigured) {
            require(msg.sender == swap.quoteTokenSender, "Only swap configurator can cancel the swap");
            IERC20Upgradeable(swap.quoteToken).safeTransfer(swap.quoteTokenSender, swap.quoteTokenAmount);
        }

        swap.status = SwapStatus.Canceled;

        emit SwapCanceled(msg.sender, swapNumber);
    }

    /**
     * @dev Returns the swap status if exists
   * @param swapNumber swap number
   * @return SwapStatus status of the swap record
   */
    function swapStatus(uint256 swapNumber)
    external
    override
    view
        /*onlyWalletsAdminOrReserveAdmin*/
    returns
    (SwapStatus)
    {
        require(_swap[swapNumber].restrictedTokenSender != address(0), "Swap record not exists");
        return _swap[swapNumber].status;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20SnapshotUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./interfaces/ITransferRules.sol";
import "./EasyAccessControlUpgradeable.sol";

/**
  @title A smart contract for unlocking tokens based on a release schedule
  @author By CoMakery, Inc., Upside, Republic
  @dev When deployed the contract is as a proxy for a single token that it creates release schedules for
      it implements the ERC20 token interface to integrate with wallets but it is not an independent token.
      The token must implement a burn function.
*/
contract RestrictedLockupToken is
Initializable,
ERC20SnapshotUpgradeable,
UUPSUpgradeable,
OwnableUpgradeable,
EasyAccessControlUpgradeable,
ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct ReleaseSchedule {
        uint256 releaseCount;
        uint256 delayUntilFirstReleaseInSeconds;
        uint256 initialReleasePortionInBips;
        uint256 periodBetweenReleasesInSeconds;
    }

    struct Timelock {
        uint256 scheduleId;
        uint256 commencementTimestamp;
        uint256 tokensTransferred;
        uint256 totalAmount;
        address[] cancelableBy; // not cancelable unless set at the time of funding
    }

    ReleaseSchedule[] public releaseSchedules;
    uint256 public minTimelockAmount; // immutable
    uint256 public maxReleaseDelay; // immutable
    uint256 private constant BIPS_PRECISION = 10_000;
    uint256 private constant MAX_TIMELOCKS = 10_000;

    mapping(address => Timelock[]) public timelocks;
    mapping(address => uint) internal _totalTokensUnlocked;

    event ScheduleCreated(address indexed from, uint256 indexed scheduleId);

    event ScheduleFunded(
        address indexed from,
        address indexed to,
        uint256 indexed scheduleId,
        uint256 amount,
        uint256 commencementTimestamp,
        uint256 timelockId,
        address[] cancelableBy
    );

    event TimelockCanceled(
        address indexed canceledBy,
        address indexed target,
        uint256 indexed timelockIndex,
        address relaimTokenTo,
        uint256 canceledAmount,
        uint256 paidAmount
    );

    address private swapContract;

    uint8 constant SWAP_CONTRACT_ROLE = 16; // 10000

    uint8 public _decimals;

    ITransferRules public transferRules;

    uint256 public maxTotalSupply;

    // Transfer restriction "eternal storage" mappings that can be used by future TransferRules contract upgrades
    // They are accessed through getter and setter methods
    mapping(address => uint256) private _maxBalances;
    mapping(address => uint256) private _minBalances;
    mapping(address => uint256) private _transferGroups; // restricted groups like Reg D Accredited US, Reg CF Unaccredited US and Reg S Foreign

    mapping(uint256 => mapping(uint256 => uint256)) private _allowGroupTransfers; // approve transfers between groups: from => to => TimeLockUntil

    mapping(address => bool) private _frozenAddresses;

    int256 public holderMax; // Maximum uint256 value
    int256 public holderCount;
    mapping(uint256 => int256) public holderGroupCount;
    mapping(uint256 => int256) public holderGroupMax;

    bool public isPaused;

    event AddressMinMaxBalance(address indexed admin, address indexed addr, uint256 min, uint256 max);

    event AddressTransferGroup(address indexed admin, address indexed addr, uint256 indexed value);
    event AddressFrozen(address indexed admin, address indexed addr, bool indexed status);
    event AllowGroupTransfer(address indexed admin, uint256 indexed fromGroup, uint256 indexed toGroup, uint256 lockedUntil);
    event SwapContractUpdated(address indexed admin, address contractAddress);

    event Pause(address admin, bool status);
    event Upgrade(address admin, address oldRules, address newRules);

    /**
@dev Configure deployment for a specific token with release schedule security parameters
    @dev The symbol should end with " Unlock" & be less than 11 characters for MetaMask "custom token" compatibility
  */
    function initialize(
        address transferRules_,
        address contractAdmin_,
        address tokenReserveAdmin_,
        string memory symbol_,
        string memory name_,
        uint8 decimals_,
        uint256 totalSupply_,
        uint256 maxTotalSupply_,
        uint256 minTimelockAmount_,
        uint256 maxReleaseDelay_
    ) initializer public {
        __ERC20_init(name_, symbol_);
        __ReentrancyGuard_init();
        __ERC20Snapshot_init();

        __Ownable_init();
        __UUPSUpgradeable_init();

        // Restricted Token
        require(transferRules_ != address(0), "Transfer rules address cannot be 0x0");
        require(contractAdmin_ != address(0), "Token owner address cannot be 0x0");
        require(tokenReserveAdmin_ != address(0), "Token reserve admin address cannot be 0x0");

        // Transfer rules can be swapped out for a new contract inheriting from the ITransferRules interface
        // The "eternal storage" for rule data stays in this RestrictedToken contract for use by TransferRules contract upgrades
        transferRules = ITransferRules(transferRules_);

        maxTotalSupply = maxTotalSupply_;
        _decimals = decimals_;

        holderMax = 2 ** 255 - 1;

        isPaused = false;

        setupRole(contractAdmin_, CONTRACT_ADMIN_ROLE);
        setupRole(tokenReserveAdmin_, RESERVE_ADMIN_ROLE);

        _mint(tokenReserveAdmin_, totalSupply_);

        // Token Lockup
        require(minTimelockAmount_ > 0, "Min timelock amount > 0");
        minTimelockAmount = minTimelockAmount_;
        maxReleaseDelay = maxReleaseDelay_;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    modifier onlyWalletsAdminOrReserveAdmin() {
        require((hasRole(msg.sender, WALLETS_ADMIN_ROLE) || hasRole(msg.sender, RESERVE_ADMIN_ROLE)),
            "DOES NOT HAVE WALLETS ADMIN OR RESERVE ADMIN ROLE");
        _;
    }

    modifier onlySwapContract() {
        require((hasRole(msg.sender, SWAP_CONTRACT_ROLE)),
            "DOES NOT HAVE SWAP CONTRACT ROLE");
        _;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    // Create new snapshot
    function snapshot() external onlyContractAdmin returns (uint256)  {
        return _snapshot();
    }

    // Get current snapshot ID
    function getCurrentSnapshotId() view external returns (uint256) {
        return _getCurrentSnapshotId();
    }

    /// @dev Sets the maximum number of tokens an address will be allowed to hold.
    /// Addresses can hold 0 tokens by default.
    /// @param addr The address to restrict
    /// @param min the minimum number of tokens the address can hold
    /// @param max the maximum number of tokens the address can hold
    function setMinMaxBalance(address addr, uint256 min, uint256 max) public validAddress(addr) onlyWalletsAdmin {
        _minBalances[addr] = min;
        _maxBalances[addr] = max;
        emit AddressMinMaxBalance(msg.sender, addr, min, max);
    }

    /// @dev Gets the maximum number of tokens an address is allowed to hold
    /// @param addr The address to check restrictions for
    function getMaxBalance(address addr) external view returns (uint256) {
        return _maxBalances[addr];
    }

    /// @dev Gets the minimum number of tokens an address is allowed to hold
    /// @param addr The address to check restrictions for
    function getMinBalance(address addr) external view returns (uint256) {
        return _minBalances[addr];
    }

    /**
@notice Create a release schedule template that can be used to generate many token timelocks
    @param releaseCount Total number of releases including any initial "cliff'
    @param delayUntilFirstReleaseInSeconds "cliff" or 0 for immediate release
    @param initialReleasePortionInBips Portion to release in 100ths of 1% (10000 BIPS per 100%)
    @param periodBetweenReleasesInSeconds After the delay and initial release
        the remaining tokens will be distributed evenly across the remaining number of releases (releaseCount - 1)
    @return unlockScheduleId The id used to refer to the release schedule at the time of funding the schedule
  */
    function createReleaseSchedule(
        uint256 releaseCount,
        uint256 delayUntilFirstReleaseInSeconds,
        uint256 initialReleasePortionInBips,
        uint256 periodBetweenReleasesInSeconds
    ) external returns (uint256 unlockScheduleId) {
        require(delayUntilFirstReleaseInSeconds <= maxReleaseDelay, "first release > max");
        require(releaseCount >= 1, "< 1 release");
        require(initialReleasePortionInBips <= BIPS_PRECISION, "release > 100%");

        if (releaseCount > 1) {
            require(periodBetweenReleasesInSeconds > 0, "period = 0");
        } else if (releaseCount == 1) {
            require(initialReleasePortionInBips == BIPS_PRECISION, "released < 100%");
        }

        releaseSchedules.push(ReleaseSchedule(
                releaseCount,
                delayUntilFirstReleaseInSeconds,
                initialReleasePortionInBips,
                periodBetweenReleasesInSeconds
            ));

        unlockScheduleId = releaseSchedules.length - 1;
        emit ScheduleCreated(msg.sender, unlockScheduleId);

        return unlockScheduleId;
    }

    /**
@notice Fund the programmatic release of tokens to a recipient.
        WARNING: this function IS CANCELABLE by cancelableBy.
        If canceled the tokens that are locked at the time of the cancellation will be returned to the funder
        and unlocked tokens will be transferred to the recipient.
    @param to recipient address that will have tokens unlocked on a release schedule
    @param amount of tokens to transfer in base units (the smallest unit without the decimal point)
    @param commencementTimestamp the time the release schedule will start
    @param scheduleId the id of the release schedule that will be used to release the tokens
    @param cancelableBy array of canceler addresses
    @return success Always returns true on completion so that a function calling it can revert if the required call did not succeed
  */
    function fundReleaseSchedule(
        address to,
        uint256 amount,
        uint256 commencementTimestamp, // unix timestamp
        uint256 scheduleId,
        address[] memory cancelableBy
    ) public nonReentrant returns (bool success) {
        require(cancelableBy.length <= 10, "max 10 cancelableBy addressees");
        require(amount >= _minBalances[to], "amount < min balance");

        uint256 timelockId = _fund(to, amount, commencementTimestamp, scheduleId);

        if (cancelableBy.length > 0) {
            timelocks[to][timelockId].cancelableBy = cancelableBy;
        }

        emit ScheduleFunded(msg.sender, to, scheduleId, amount, commencementTimestamp, timelockId, cancelableBy);
        return true;
    }


    function _fund(
        address to,
        uint256 amount,
        uint256 commencementTimestamp, // unix timestamp
        uint256 scheduleId)
    internal returns (uint) {
        require(
            timelocks[to].length <= MAX_TIMELOCKS,
            "Max timelocks exceeded"
        );
        require(amount >= minTimelockAmount, "amount < min funding");
        require(to != address(0), "to 0 address");
        require(scheduleId < releaseSchedules.length, "bad scheduleId");
        require(amount >= releaseSchedules[scheduleId].releaseCount, "< 1 token per release");

        _transfer(address(this), amount);

        require(
            commencementTimestamp + releaseSchedules[scheduleId].delayUntilFirstReleaseInSeconds <=
            block.timestamp + maxReleaseDelay
        , "initial release out of range");

        Timelock memory timelock;
        timelock.scheduleId = scheduleId;
        timelock.commencementTimestamp = commencementTimestamp;
        timelock.totalAmount = amount;

        timelocks[to].push(timelock);
        return timelockCountOf(to) - 1;
    }

    /**
@notice Cancel a cancelable timelock created by the fundReleaseSchedule function.
        WARNING: this function cannot cancel a release schedule created by fundReleaseSchedule
        If canceled the tokens that are locked at the time of the cancellation will be returned to the funder
        and unlocked tokens will be transferred to the recipient.
    @param target The address that would receive the tokens when released from the timelock.
    @param timelockIndex timelock index
    @param target The address that would receive the tokens when released from the timelock
    @param scheduleId require it matches expected
    @param commencementTimestamp require it matches expected
    @param totalAmount require it matches expected
    @param reclaimTokenTo reclaim token to
    @return success Always returns true on completion so that a function calling it can revert if the required call did not succeed
  */
    function cancelTimelock(
        address target,
        uint256 timelockIndex,
        uint256 scheduleId,
        uint256 commencementTimestamp,
        uint256 totalAmount,
        address reclaimTokenTo
    ) public nonReentrant returns (bool success) {
        require(timelockCountOf(target) > timelockIndex, "invalid timelock");
        require(reclaimTokenTo != address(0), "Invalid reclaimTokenTo");

        Timelock storage timelock = timelocks[target][timelockIndex];

        require(_canBeCanceled(timelock), "You are not allowed to cancel this timelock");
        require(timelock.scheduleId == scheduleId, "Expected scheduleId does not match");
        require(timelock.commencementTimestamp == commencementTimestamp, "Expected commencementTimestamp does not match");
        require(timelock.totalAmount == totalAmount, "Expected totalAmount does not match");

        uint256 canceledAmount = lockedBalanceOfTimelock(target, timelockIndex);

        require(canceledAmount > 0, "Timelock has no value left");

        uint256 paidAmount = unlockedBalanceOfTimelock(target, timelockIndex);

        IERC20Upgradeable(this).safeTransfer(reclaimTokenTo, canceledAmount);
        IERC20Upgradeable(this).safeTransfer(target, paidAmount);

        emit TimelockCanceled(msg.sender, target, timelockIndex, reclaimTokenTo, canceledAmount, paidAmount);

        timelock.tokensTransferred = timelock.totalAmount;
        return true;
    }

    /**
     *  @notice Check if timelock can be cancelable by msg.sender
     */
    function _canBeCanceled(Timelock storage timelock)
    private
    view
    returns (bool)
    {
        uint256 len = timelock.cancelableBy.length;
        for (uint256 i = 0; i < len; i++) {
            if (msg.sender == timelock.cancelableBy[i]) {
                return true;
            }
        }
        return false;
    }

    /**
     *  @notice Batch version of fund cancelable release schedule
   *  @param to An array of recipient address that will have tokens unlocked on a release schedule
   *  @param amounts An array of amount of tokens to transfer in base units (the smallest unit without the decimal point)
   *  @param commencementTimestamps An array of the time the release schedule will start
   *  @param scheduleIds An array of the id of the release schedule that will be used to release the tokens
   *  @param cancelableBy An array of cancelables
   *  @return success Always returns true on completion so that a function calling it can revert if the required call did not succeed
   */
    function batchFundReleaseSchedule(
        address[] calldata to,
        uint[] calldata amounts,
        uint[] calldata commencementTimestamps,
        uint[] calldata scheduleIds,
        address[] calldata cancelableBy
    ) external returns (bool success) {
        require(to.length == amounts.length, "mismatched array length");
        require(to.length == commencementTimestamps.length, "mismatched array length");
        require(to.length == scheduleIds.length, "mismatched array length");

        for (uint256 i = 0; i < to.length; i++) {
            require(
                fundReleaseSchedule(
                    to[i],
                    amounts[i],
                    commencementTimestamps[i],
                    scheduleIds[i],
                    cancelableBy
                ),
                "Can not release schedule"
            );
        }

        return true;
    }

    /**
@notice Get The locked balance for a specific address and specific timelock
    @param who The address to check
    @param timelockIndex Specific timelock belonging to the who address
    @return locked Balance of the timelock
    lockedBalanceOfTimelock
  */
    function lockedBalanceOfTimelock(address who, uint256 timelockIndex) public view returns (uint256 locked) {
        Timelock memory timelock = timelockOf(who, timelockIndex);
        if (timelock.totalAmount <= timelock.tokensTransferred) {
            return 0;
        } else {
            return timelock.totalAmount - totalUnlockedToDateOfTimelock(who, timelockIndex);
        }
    }

    /**
@notice Get the unlocked balance for a specific address and specific timelock
    @param who the address to check
    @param timelockIndex for a specific timelock belonging to the who address
    @return unlocked balance of the timelock
    unlockedBalanceOfTimelock
  */
    function unlockedBalanceOfTimelock(address who, uint256 timelockIndex) public view returns (uint256 unlocked) {
        Timelock memory timelock = timelockOf(who, timelockIndex);
        if (timelock.totalAmount <= timelock.tokensTransferred) {
            return 0;
        } else {
            return totalUnlockedToDateOfTimelock(who, timelockIndex) - timelock.tokensTransferred;
        }
    }

    /**
@notice Check the total remaining balance of a timelock including the locked and unlocked portions
    @param who the address to check
    @param timelockIndex  Specific timelock belonging to the who address
    @return total remaining balance of a timelock
  */
    function balanceOfTimelock(address who, uint256 timelockIndex) external view returns (uint) {
        Timelock memory timelock = timelockOf(who, timelockIndex);
        if (timelock.totalAmount <= timelock.tokensTransferred) {
            return 0;
        } else {
            return timelock.totalAmount - timelock.tokensTransferred;
        }
    }

    /**
@notice Gets the total locked and unlocked balance of a specific address's timelocks
    @param who The address to check
    @param timelockIndex The index of the timelock for the who address
    @return total Locked and unlocked amount for the specified timelock
  */
    function totalUnlockedToDateOfTimelock(address who, uint256 timelockIndex) public view returns (uint256 total) {
        Timelock memory _timelock = timelockOf(who, timelockIndex);

        return calculateUnlocked(
            _timelock.commencementTimestamp,
            block.timestamp,
            _timelock.totalAmount,
            _timelock.scheduleId
        );
    }

    /**
        @notice ERC20 standard interface function
              Provide controls of Restricted and Lockup tokens
              Can transfer simple ERC-20 tokens and unlocked tokens at the same time
              First will transfer unlocked tokens and then simple ERC-20
        @param recipient of transfer
        @param amount of tokens to transfer
        @return true On success / Reverted on error
    */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(recipient != address(0), "Address cannot be 0x0");
        enforceTransferRestrictions(msg.sender, recipient, amount);
        return _transfer(recipient, amount);
    }

    function _transfer(address recipient, uint256 amount) private /*nonReentrant*/ returns (bool) {
        uint256[2] memory values = validateTransfer(msg.sender, recipient, amount);
        require(values[0] + values[1] >= amount, "Insufficent tokens");
        if (values[0] > 0) {// unlocked tokens
            super._transfer(address(this), recipient, values[0]);
        }
        if (values[1] > 0) {// simple tokens
            super._transfer(msg.sender, recipient, values[1]);
        }
        return true;
    }

    function updateSwapContract(address _swapContract) external onlyContractAdmin {
        require(_swapContract != address(0), "Address cannot be 0x0");
        swapContract = _swapContract;
        emit SwapContractUpdated(msg.sender, _swapContract);
    }

    function swapTransfer(address sender, address recipient, uint256 amount) external onlySwapContract {
        super._transfer(sender, recipient, amount);
    }

    /**
     * Transfer tokens from one address to another with ignoring of transfer rules
     * With reserve admin access only
     */
    function forceTransferBetween(
        address sender,
        address recipient,
        uint256 amount
    ) external onlyReserveAdmin {
        require(recipient != address(0) && sender != address(0), "Address cannot be 0x0");

        uint256[2] memory values = validateTransfer(sender, recipient, amount);
        require(values[0] + values[1] >= amount, "Insufficent tokens");

        if (values[0] > 0) {// unlocked tokens
            super._transfer(address(this), recipient, values[0]);
        }

        if (values[1] > 0) {// simple tokens
            super._approve(sender, msg.sender, values[1]);
            // approve transfer for reserve admin
            super.transferFrom(sender, recipient, values[1]);
        }
    }

    /**
        @notice ERC20 standard interface function
              Provide controls of Restricted and Lockup tokens
              Can transfer simple ERC-20 tokens and unlocked tokens at the same time
              First will transfer unlocked tokens and then simple ERC-20
        @param sender of transfer
        @param recipient of transfer
        @param amount of tokens to transfer
        @return true On success / Reverted on error
    */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        require(recipient != address(0) && sender != address(0), "Address cannot be 0x0");

        uint256 currentAllowance = allowance(sender, msg.sender);

        require(amount <= currentAllowance, "The approved allowance is lower than the transfer amount");
        enforceTransferRestrictions(sender, recipient, amount);

        uint256[2] memory values = validateTransfer(sender, recipient, amount);
        require(values[0] + values[1] >= amount, "Insufficent tokens");

        if (values[0] > 0) {// unlocked tokens
            super._transfer(address(this), recipient, values[0]);

            // Decrease allowance
        unchecked {
            _approve(sender, msg.sender, currentAllowance - values[0]);
        }
        }

        if (values[1] > 0) {// simple tokens
            super.transferFrom(sender, recipient, values[1]);
        }
        return true;
    }

    /**
        @notice Balance of simple ERC20 tokens without any timelocks
        @param who Address to calculate
        @return amount The amount of simple ERC-20 tokens available
        token.balanceOf
    **/
    function tokensBalanceOf(address who) public view returns (uint256) {
        return super.balanceOf(who);
    }

    /**
        @notice Get The total available to transfer balance exclude timelocked
        @param who Address to calculate
        @return amount The total available amount
        no have original
    **/
    function unlockedAmountOf(address who) public view returns (uint256) {
        return tokensBalanceOf(who) + unlockedBalanceOf(who);
    }

    /**
        @notice Get The total balance of tokens (simple + locked + unlocked)
        @param who Address to calculate
        @return amount The total account balance amount
        no have original
    **/
    function balanceOf(address who) public view override returns (uint256) {
        return tokensBalanceOf(who) + unlockedBalanceOf(who) + lockedBalanceOf(who);
    }

    /**
        @notice Get The total locked balance of an address for all timelocks
        @param who Address to calculate
        @return amount The total locked amount of tokens for all of the who address's timelocks
        lockedBalanceOf
    */
    function lockedBalanceOf(address who) public view returns (uint256 amount) {
        for (uint256 i = 0; i < timelockCountOf(who); i++) {
            amount += lockedBalanceOfTimelock(who, i);
        }
        return amount;
    }

    /**
        @notice Get The total unlocked balance of an address for all timelocks
        @param who Address to calculate
        @return amount The total unlocked amount of tokens for all of the who address's timelocks
        unlockedBalanceOf
    */
    function unlockedBalanceOf(address who) public view returns (uint256 amount) {
        for (uint256 i = 0; i < timelockCountOf(who); i++) {
            amount += unlockedBalanceOfTimelock(who, i);
        }
        return amount;
    }

    /**
        @notice Get timelocked balance - used only in tests
        @param who Address to calculate
        @return Amount of the tokens used in timelocks (locked+unlocked)
        balanceOf
    **/
//    function timelockBalanceOf(address who) public view returns (uint) {
//        return unlockedBalanceOf(who) + lockedBalanceOf(who);
//    }

    /**
        @notice Check and calculate the availability to transfer tokens between accounts from simple and timelock balances
        @param from Address from
        @param to Address to
        @param value Amount of tokens
        @return values Array of uint256[2] contains unlocked tokens at index 0, and simple ERC-20 at index 1 that can be used for transfer
    */
    function validateTransfer(address from, address to, uint256 value) internal returns (uint256[2] memory values) {
        uint256 balance = tokensBalanceOf(from);
        uint256 unlockedBalance = unlockedBalanceOf(from);

        require(balance + unlockedBalance >= value, "amount > unlocked");

        uint256 remainingTransfer = value;

        // transfer from unlocked tokens
        for (uint256 i = 0; i < timelockCountOf(from); i++) {
            // if the timelock has no value left
            if (timelocks[from][i].tokensTransferred == timelocks[from][i].totalAmount) {
                continue;
            } else if (remainingTransfer > unlockedBalanceOfTimelock(from, i)) {
                // if the remainingTransfer is more than the unlocked balance use it all
                remainingTransfer -= unlockedBalanceOfTimelock(from, i);
                timelocks[from][i].tokensTransferred += unlockedBalanceOfTimelock(from, i);
            } else {
                // if the remainingTransfer is less than or equal to the unlocked balance
                // use part or all and exit the loop
                timelocks[from][i].tokensTransferred += remainingTransfer;
                remainingTransfer = 0;
                break;
            }
        }

        values[0] = value - remainingTransfer;
        // from unlockedValue
        values[1] = remainingTransfer;
        // from balanceOf
    }

    /**
        @notice transfers the unlocked token from an address's specific timelock
            It is typically more convenient to call transfer. But if the account has many timelocks the cost of gas
            for calling transfer may be too high. Calling transferTimelock from a specific timelock limits the transfer cost.
        @param to the address that the tokens will be transferred to
        @param value the number of token base units to me transferred to the to address
        @param timelockId the specific timelock of the function caller to transfer unlocked tokens from
        @return bool always true when completed
    */
    function transferTimelock(address to, uint256 value, uint256 timelockId) public nonReentrant returns (bool) {
        require(unlockedBalanceOfTimelock(msg.sender, timelockId) >= value, "amount > unlocked");
        timelocks[msg.sender][timelockId].tokensTransferred += value;
        IERC20Upgradeable(this).safeTransfer(to, value);
        return true;
    }

    /**
        @notice calculates how many tokens would be released at a specified time for a scheduleId.
            This is independent of any specific address or address's timelock.

        @param commencedTimestamp the commencement time to use in the calculation for the scheduled
        @param currentTimestamp the timestamp to calculate unlocked tokens for
        @param amount the amount of tokens
        @param scheduleId the schedule id used to calculate the unlocked amount
        @return unlocked the total amount unlocked for the schedule given the other parameters
    */
    function calculateUnlocked(
        uint256 commencedTimestamp,
        uint256 currentTimestamp,
        uint256 amount,
        uint256 scheduleId
    ) public view returns (uint256 unlocked) {
        return calculateUnlocked(commencedTimestamp, currentTimestamp, amount, releaseSchedules[scheduleId]);
    }

    // @notice the total number of schedules that have been created
    function scheduleCount() external view returns (uint256 count) {
        return releaseSchedules.length;
    }

    /**
        @notice Get the struct details for an address's specific timelock
        @param who Address to check
        @param index The index of the timelock for the who address
        @return timelock Struct with the attributes of the timelock
    */
    function timelockOf(address who, uint256 index) public view returns (Timelock memory timelock) {
        return timelocks[who][index];
    }

    // @notice returns the total count of timelocks for a specific address
    function timelockCountOf(address who) public view returns (uint) {
        return timelocks[who].length;
    }

    /**
        @notice calculates how many tokens would be released at a specified time for a ReleaseSchedule struct.
                This is independent of any specific address or address's timelock.

        @param commencedTimestamp the commencement time to use in the calculation for the scheduled
        @param currentTimestamp the timestamp to calculate unlocked tokens for
        @param amount the amount of tokens
        @param releaseSchedule a ReleaseSchedule struct used to calculate the unlocked amount
        @return unlocked the total amount unlocked for the schedule given the other parameters
    */
    function calculateUnlocked(
        uint256 commencedTimestamp,
        uint256 currentTimestamp,
        uint256 amount,
        ReleaseSchedule memory releaseSchedule)
    public pure returns (uint256 unlocked) {
        return calculateUnlocked(
            commencedTimestamp,
            currentTimestamp,
            amount,
            releaseSchedule.releaseCount,
            releaseSchedule.delayUntilFirstReleaseInSeconds,
            releaseSchedule.initialReleasePortionInBips,
            releaseSchedule.periodBetweenReleasesInSeconds
        );
    }

    /**
        @notice The same functionality as above function with spread format of `releaseSchedule` arg
        @param commencedTimestamp the commencement time to use in the calculation for the scheduled
        @param currentTimestamp the timestamp to calculate unlocked tokens for
        @param amount the amount of tokens
        @param releaseCount Total number of releases including any initial "cliff'
        @param delayUntilFirstReleaseInSeconds "cliff" or 0 for immediate release
        @param initialReleasePortionInBips Portion to release in 100ths of 1% (10000 BIPS per 100%)
        @param periodBetweenReleasesInSeconds After the delay and initial release
        @return unlocked the total amount unlocked for the schedule given the other parameters
    */
    function calculateUnlocked(
        uint256 commencedTimestamp,
        uint256 currentTimestamp,
        uint256 amount,
        uint256 releaseCount,
        uint256 delayUntilFirstReleaseInSeconds,
        uint256 initialReleasePortionInBips,
        uint256 periodBetweenReleasesInSeconds
    ) public pure returns (uint256 unlocked) {
        if (commencedTimestamp > currentTimestamp) {
            return 0;
        }
        uint256 secondsElapsed = currentTimestamp - commencedTimestamp;

        // return the full amount if the total lockup period has expired
        // unlocked amounts in each period are truncated and round down remainders smaller than the smallest unit
        // unlocking the full amount unlocks any remainder amounts in the final unlock period
        // this is done first to reduce computation
        if (
            secondsElapsed >= delayUntilFirstReleaseInSeconds +
        (periodBetweenReleasesInSeconds * (releaseCount - 1))
        ) {
            return amount;
        }

        // unlock the initial release if the delay has elapsed
        if (secondsElapsed >= delayUntilFirstReleaseInSeconds) {
            unlocked = (amount * initialReleasePortionInBips) / BIPS_PRECISION;

            // if at least one period after the delay has passed
            if (secondsElapsed - delayUntilFirstReleaseInSeconds >= periodBetweenReleasesInSeconds) {

                // calculate the number of additional periods that have passed (not including the initial release)
                // this discards any remainders (ie it truncates / rounds down)
                uint256 additionalUnlockedPeriods = (secondsElapsed - delayUntilFirstReleaseInSeconds) / periodBetweenReleasesInSeconds;

                // calculate the amount of unlocked tokens for the additionalUnlockedPeriods
                // multiplication is applied before division to delay truncating to the smallest unit
                // this distributes unlocked tokens more evenly across unlock periods
                // than truncated division followed by multiplication
                unlocked += ((amount - unlocked) * additionalUnlockedPeriods) / (releaseCount - 1);
            }
        }

        return unlocked;
    }

    /// @dev Enforces transfer restrictions managed using the ERC-1404 standard functions.
    /// The TransferRules contract defines what the rules are. The data inputs to those rules remains in the RestrictedToken contract.
    /// TransferRules is a separate contract so its logic can be upgraded.
    /// @param from The address the tokens are transferred from
    /// @param to The address the tokens would be transferred to
    /// @param value the quantity of tokens to be transferred
    function enforceTransferRestrictions(address from, address to, uint256 value) public view {/*private*/
        uint8 restrictionCode = detectTransferRestriction(from, to, value);
        require(transferRules.checkSuccess(restrictionCode), messageForTransferRestriction(restrictionCode));
    }

    /// @dev Calls the TransferRules detectTransferRetriction function to determine if tokens can be transferred.
    /// detectTransferRestriction returns a status code.
    /// @param from The address the tokens are transferred from
    /// @param to The address the tokens would be transferred to
    /// @param value The quantity of tokens to be transferred
    function detectTransferRestriction(address from, address to, uint256 value) public view returns (uint8) {
        return transferRules.detectTransferRestriction(address(this), from, to, value);
    }

    /// @dev Calls TransferRules to lookup a human readable error message that goes with an error code.
    /// @param restrictionCode is an error code to lookup an error code for
    function messageForTransferRestriction(uint8 restrictionCode) public view returns (string memory) {
        return transferRules.messageForTransferRestriction(restrictionCode);
    }

    function setHolderMax(int256 holderMax_) public onlyWalletsAdmin {
        holderMax = holderMax_;
    }

    function setGroupHolderMax(uint256 groupId, int256 groupHolderMax) public onlyWalletsAdmin {
        holderGroupMax[groupId] = groupHolderMax;
    }

    /// @dev Set the one group that the address belongs to, such as a US Reg CF investor group.
    /// @param addr The address to set the group for.
    /// @param groupID The uint256 numeric ID of the group.
    function setTransferGroup(address addr, uint256 groupID, bool isCounted) public validAddress(addr) onlyWalletsAdmin {
        // Calculate total and group holders
        if (isCounted) {
            if (groupID > 0) {
                if (_transferGroups[addr] == 0) {
                    require(holderCount < holderMax, "Reached maximum number of holders");
                    holderCount = holderCount + 1;
                }
                if (holderGroupCount[_transferGroups[addr]] > 0) { // decrease group holders count
                    --holderGroupCount[_transferGroups[addr]];
                }
                require(holderGroupMax[groupID] == 0 || holderGroupCount[groupID] < holderGroupMax[groupID], "Reached maximum number of holders in group");
                ++holderGroupCount[groupID];
            } else {
                if (_transferGroups[addr] > 0) {
                    holderCount = holderCount - 1;
                    // decrease total holders count
                    if (holderGroupCount[_transferGroups[addr]] > 0) {// decrease group holders count
                        --holderGroupCount[_transferGroups[addr]];
                    }
                }
            }
        }

        _transferGroups[addr] = groupID;

        emit AddressTransferGroup(msg.sender, addr, groupID);
    }

    /// @dev Gets the transfer group the address belongs to. The default group is 0.
    /// @param addr The address to check.
    /// @return groupID The group id of the address.
    function getTransferGroup(address addr) external view returns (uint256 groupID) {
        return _transferGroups[addr];
    }

    /// @dev Freezes or unfreezes an address.
    /// Tokens in a frozen address cannot be transferred from until the address is unfrozen.
    /// @param addr The address to be frozen.
    /// @param status The frozenAddress status of the address. True means frozen false means not frozen.
    function freeze(address addr, bool status) public validAddress(addr) onlyWalletsAdminOrReserveAdmin {
        _frozenAddresses[addr] = status;
        emit AddressFrozen(msg.sender, addr, status);
    }

    /// @dev Checks the status of an address to see if its frozen
    /// @param addr The address to check
    /// @return status Returns true if the address is frozen and false if its not frozen.
    function getFrozenStatus(address addr) external view returns (bool status) {
        return _frozenAddresses[addr];
    }

    /// @dev A convenience method for updating the transfer group, lock until, max balance, and freeze status.
    /// The convenience method also helps to reduce gas costs.
    /// @notice This function has different parameters count from original
    /// @param addr The address to set permissions for.
    /// @param groupID The ID of the address
    /// @param lockedBalanceUntil The amount of tokens to be reserved until the timelock expires. Reservation is exclusive.
    /// @param maxBalance Is the maximum number of tokens the account can hold.
    /// @param status The frozenAddress status of the address. True means frozen false means not frozen.
    function setAddressPermissions(
        address addr,
        uint256 groupID,
        uint256 lockedBalanceUntil,
        uint256 minBalance,
        uint256 maxBalance,
        bool status,
        bool isCounted
    ) external validAddress(addr) onlyWalletsAdmin {
        setTransferGroup(addr, groupID, isCounted);
        setMinMaxBalance(addr, minBalance, maxBalance);
        freeze(addr, status);
    }

    /// @dev Sets an allowed transfer from a group to another group beginning at a specific time.
    /// There is only one definitive rule per from and to group.
    /// @param from The group the transfer is coming from.
    /// @param to The group the transfer is going to.
    /// @param lockedUntil The unix timestamp that the transfer is locked until. 0 is a special number. 0 means the transfer is not allowed.
    /// This is because in the smart contract mapping all pairs are implicitly defined with a default lockedUntil value of 0.
    /// But no transfers should be authorized until explicitly allowed. Thus 0 must mean no transfer is allowed.
    function setAllowGroupTransfer(uint256 from, uint256 to, uint256 lockedUntil) external onlyTransferAdmin {
        _allowGroupTransfers[from][to] = lockedUntil;
        emit AllowGroupTransfer(msg.sender, from, to, lockedUntil);
    }

    /// @dev Checks to see when a transfer between two addresses would be allowed.
    /// @param from The address the transfer is coming from
    /// @param to The address the transfer is going to
    /// @return timestamp The Unix timestamp of the time the transfer would be allowed. A 0 means never.
    /// The format is the number of seconds since the Unix epoch of 00:00:00 UTC on 1 January 1970.
    function getAllowTransferTime(address from, address to) external view returns (uint256 timestamp) {
        return _allowGroupTransfers[_transferGroups[from]][_transferGroups[to]];
    }

    /// @dev Checks to see when a transfer between two groups would be allowed.
    /// @param from The group id the transfer is coming from
    /// @param to The group id the transfer is going to
    /// @return timestamp The Unix timestamp of the time the transfer would be allowed. A 0 means never.
    /// The format is the number of seconds since the Unix epoch of 00:00:00 UTC on 1 January 1970.
    function getAllowGroupTransferTime(uint256 from, uint256 to) external view returns (uint256 timestamp) {
        return _allowGroupTransfers[from][to];
    }

    /// @dev Destroys tokens and removes them from the total supply. Can only be called by an address with a Reserve Admin role.
    /// @param from The address to destroy the tokens from.
    /// @param value The number of tokens to destroy from the address.
    function burn(address from, uint256 value) external validAddress(from) onlyReserveAdmin {
        _burn(from, value);
    }

    /// @dev Allows the reserve admin to create new tokens in a specified address.
    /// The total number of tokens cannot exceed the maxTotalSupply (the "Hard Cap").
    /// @param to The addres to mint tokens into.
    /// @param value The number of tokens to mint.
    function mint(address to, uint256 value) external validAddress(to) onlyReserveAdmin {
        require(totalSupply() + value <= maxTotalSupply, "Cannot mint more than the max total supply");
        _mint(to, value);
    }

    /// @dev Allows the contract admin to pause transfers.
    function pause(bool isPaused_) external onlyContractAdmin() {
        isPaused = isPaused_;
        emit Pause(msg.sender, isPaused_);
    }

    /// @dev Allows the contrac admin to upgrade the transfer rules.
    /// The upgraded transfer rules must implement the ITransferRules interface which conforms to the ERC-1404 token standard.
    /// @param newTransferRules The address of the deployed TransferRules contract.
    function upgradeTransferRules(ITransferRules newTransferRules) external onlyTransferAdmin {
        require(address(newTransferRules) != address(0x0), "Address cannot be 0x0");
        address oldRules = address(transferRules);
        transferRules = newTransferRules;
        emit Upgrade(msg.sender, oldRules, address(newTransferRules));
    }

    // @dev can delete, used only at tests
    function safeApprove(address spender, uint256 value) public {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero.
        require((value == 0) || (allowance(address(msg.sender), spender) == 0),
            "Cannot approve from non-zero to non-zero allowance"
        );
        approve(spender, value);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20SnapshotUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./EasyAccessControlUpgradeable.sol";

import "./interfaces/IDividends.sol";
//import "./interfaces/IRestrictedLockupToken.sol";
import "./RestrictedLockupToken.sol";

contract Dividends is
  IDividends,
  Initializable,
  UUPSUpgradeable,
  OwnableUpgradeable,
  EasyAccessControlUpgradeable,
  ReentrancyGuardUpgradeable
{
  RestrictedLockupToken public restrictedLockupToken;

  using SafeERC20Upgradeable for IERC20Upgradeable;

  struct TokensFunded {
    uint256 total;
    uint256 unused;
  }

  /// @dev snapshotID => funderAddress => token => getAmount;
  mapping(uint256 => mapping(address => mapping(address => uint256))) claimedTokens;

  /// @dev snapshotID => token => totalAmount of token
  mapping(uint256 => mapping(address => TokensFunded)) tokensFunded;

  /// @dev Accuracy of division
  uint256 public constant tokenPrecisionDivider = 10000;

  constructor() {}

  /**
   * @dev Contract constructor
   */
  function __Dividends_init(
    address contractAdmin_,
    address tokenReserveAdmin_,
    address restrictedLockupTokenAddress_
  ) public {
    __ReentrancyGuard_init();

    setupRole(contractAdmin_, CONTRACT_ADMIN_ROLE);
    setupRole(tokenReserveAdmin_, RESERVE_ADMIN_ROLE);

    restrictedLockupToken = RestrictedLockupToken(restrictedLockupTokenAddress_);
  }

  function initialize(
    address contractAdmin_,
    address tokenReserveAdmin_,
    address restrictedLockupTokenAddress_
  ) initializer public virtual {
    __Ownable_init();
    __UUPSUpgradeable_init();

    __Dividends_init(
        contractAdmin_,
        tokenReserveAdmin_,
        restrictedLockupTokenAddress_
    );
  }

  function _authorizeUpgrade(address) internal virtual override onlyOwner {}

  /// @dev Withdrawal remains of unused ERC-20 tokens at snapshot
  /// @param token ERC-20 token address
  /// @param snapshotId Snapshot ID
  function withdrawRemains(address token, uint256 snapshotId) override public onlyContractAdmin nonReentrant {
    require(token != address(0), "BAD TOKEN ADDRESS");

    uint256 amount = tokensAt(token, snapshotId);

    IERC20Upgradeable(token).safeTransfer(msg.sender, amount);

    tokensFunded[snapshotId][token].unused -= amount;

    emit Withdrawn(msg.sender, token, amount, snapshotId);
  }

  /**
   * @dev Fund any ERC-20 tokens into current contract
   * Tokens can be claimed by holders of RestrictedSwap Token uses claimDividends method
   * @param token ERC-20 token address
   * @param amount amount of tokens to fund
   * @param snapshotId snapshot ID of RestrictedSwap Token
   */
  function fundDividend(address token, uint256 amount, uint256 snapshotId) override public {
    require(token != address(0), "BAD TOKEN ADDRESS");

    IERC20Upgradeable paymentToken = IERC20Upgradeable(token);

    paymentToken.safeTransferFrom(msg.sender, address(this), amount);

    tokensFunded[snapshotId][token].total += amount;
    tokensFunded[snapshotId][token].unused += amount;

    emit Funded(msg.sender, token, amount, snapshotId);
  }

  /// @dev Get unused ERC-20 tokens on snapshot
  /// @param token ERC-20 token address
  /// @param snapshotId Snapshot ID
  /// @return amount of ERC-20 tokens
  function tokensAt(address token, uint256 snapshotId) override public view returns (uint256) {
    uint256 amount = tokensFunded[snapshotId][token].unused;
    if ( amount > 0 ) return amount;
    return 0;
  }

  /// @dev Proxy function for restricted token
  function totalSupplyAt(uint256 snapshotId) external view returns (uint256) {
    return restrictedLockupToken.totalSupplyAt(snapshotId);
  }

  /// @dev Proxy function for restricted token
  function balanceOfAt(address sender, uint256 snapshotId) external view returns(uint256) {
    return restrictedLockupToken.balanceOfAt(sender, snapshotId);
  }

  /**
   * @dev Get balance of ERC-20 tokens funded at snapshot
   * @param token ERC-20 token address
   * @param snapshotId snapshot ID of RestrictedSwap Token
   * @return amount of ERC-20 tokens
   */
  function fundsAt(address token, uint256 snapshotId) override public view returns (uint256) {
    return tokensFunded[snapshotId][token].total;
  }

  /**
   * @dev Amount of ERC-20 tokens distributed to the holder of RestrictedSwap Token at snapshot
   * @param token ERC-20 token address
   * @param receiver RestrictedSwap Token's holder address
   * @param snapshotId snapshot ID of RestrictedSwap Token
   * @return amount of total ERC-20 tokens distributed to the receiver
   */
  function totalAwardedBalanceAt(address token, address receiver, uint256 snapshotId) override public view returns (uint256) {
    uint256 secTokenBalance = restrictedLockupToken.balanceOfAt(receiver, snapshotId);
    uint256 totalSupply = restrictedLockupToken.totalSupplyAt(snapshotId);
    uint256 share = (secTokenBalance * tokenPrecisionDivider) / totalSupply;
    return (tokensFunded[snapshotId][token].total * share) / tokenPrecisionDivider;
  }

  /**
   * @dev Amount of ERC-20 tokens claimed by the holder of RestrictedSwap Token at snapshot
   * @param token ERC-20 token address
   * @param receiver RestrictedSwap Token's holder address
   * @param snapshotId snapshot ID of RestrictedSwap Token
   * @return amount of claimed ERC-20 tokens
   */
  function claimedBalanceAt(address token, address receiver, uint256 snapshotId) override public view returns (uint256) {
    return claimedTokens[snapshotId][token][receiver];
  }

  /**
   * @dev Amount of ERC-20 tokens that can be claimed by the holder of RestrictedSwap Token at snapshot
   * @param token ERC-20 token address
   * @param receiver RestrictedSwap Token's holder address
   * @param snapshotId snapshot ID of RestrictedSwap Token
   * @return amount of can be claimed ERC-20 tokens
   */
  function unclaimedBalanceAt(address token, address receiver, uint256 snapshotId) override public view returns (uint256) {
    return totalAwardedBalanceAt(token, receiver, snapshotId) - claimedBalanceAt(token, receiver, snapshotId);
  }

  /**
   * @dev Claim ERC-20 tokens (dividends) by RestrictedSwap Tokens holder
   * Tokens can be claimed when its allowed by unclaimedBalanceAt
   * @param token ERC-20 token address
   * @param snapshotId snapshot ID of RestrictedSwap Token
   */
  function claimDividend(address token, uint256 snapshotId) override public nonReentrant {
    uint256 unclaimedBalance = unclaimedBalanceAt(token, msg.sender, snapshotId);

    require(unclaimedBalance > 0, "YOU CAN`T RECEIVE MORE TOKENS");

    IERC20Upgradeable(token).safeTransfer(msg.sender, unclaimedBalance);

    claimedTokens[snapshotId][token][msg.sender] += unclaimedBalance;

    tokensFunded[snapshotId][token].unused -= unclaimedBalance;

    emit Claimed(msg.sender, token, unclaimedBalance, snapshotId);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IRestrictedSwap {  

  /************************
   * Data Structures
   ************************/
  
  enum SwapStatus {
    SellConfigured,
    BuyConfigured,
    Complete,
    Canceled
  }

  struct Swap {
    address restrictedTokenSender;
    address quoteTokenSender;
    address quoteToken;
    uint256 restrictedTokenAmount;
    uint256 quoteTokenAmount;
    SwapStatus status;
  }

  /************************
   * Functions
   ************************/

  /**
   *  @dev Configure swap and emit an event with new swap number
   *  @param restrictedTokenAmount the required amount for the erc1404Sender to send
   *  @param quoteToken the address of an erc1404 or erc20 that will be swapped
   *  @param token2Address the address that is approved to fund quoteToken
   *  @param quoteTokenAmount the required amount of quoteToken to swap
   */
  function configureSell(
    uint restrictedTokenAmount,
    address quoteToken,
    address token2Address,
    uint quoteTokenAmount
  ) external;

  /**
   *  @dev Configure swap and emit an event with new swap number
   *  @param restrictedTokenAmount the required amount for the erc1404Sender to send
   *  @param restrictedTokenSender restricted token sender
   *  @param quoteToken the address of an erc1404 or erc20 that will be swapped
   *  @param quoteTokenAmount the required amount of quoteToken to swap
   */
  function configureBuy(
    uint256 restrictedTokenAmount,
    address restrictedTokenSender,
    address quoteToken,
    uint256 quoteTokenAmount
  ) external;

  /**
   *  @dev Complete swap with quote token
   *  @param swapNumber swap number
   */
  function completeSwapWithPaymentToken(uint swapNumber) external;

  /**
   *  @dev Complete swap with restricted token
   *  @param swapNumber swap number
   */
  function completeSwapWithRestrictedToken(uint swapNumber) external;

  /**
   *  @dev cancel swap
   *  @param swapNumber swap number
   */
  function cancelSell(uint swapNumber) external;

  /**
   * @dev Returns the swap status if exists
   * @param swapNumber swap number
   * @return SwapStatus status of the swap record
   */
  function swapStatus(uint256 swapNumber) external view returns (SwapStatus);

  /****************************
   * Events
   ****************************/

  event SwapCanceled(address sender, uint256 swapNumber);

  event SwapConfigured(
    uint256 swapNumber,
    address restrictedTokenSender,
    uint256 restrictedTokenAmount,
    address quoteToken,
    address quoteTokenSender,
    uint256 quoteTokenAmount
  );

  event SwapComplete(
    uint256 swapNumber,
    address restrictedTokenSender,
    uint256 restrictedTokenAmount,
    address quoteTokenSender,
    address quoteToken,
    uint256 quoteTokenAmount
  );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC1404 is IERC20 {
  function detectTransferRestriction(
    address from,
    address to,
    uint256 value
  ) external view returns(uint8);

  function messageForTransferRestriction(
    uint8 restrictionCode
  ) external view returns(string memory);
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/**
  @title Binary Access control
  @author By CoMakery, Inc., Upside, Republic
  @dev Binary equivalent to OpenZeppelin/AccessControl
       Uses bits for storing user roles, minify gas cost and contact size
*/
contract EasyAccessControlUpgradeable {

  uint8 constant CONTRACT_ADMIN_ROLE = 1; // 0001
  uint8 constant RESERVE_ADMIN_ROLE = 2;  // 0010
  uint8 constant WALLETS_ADMIN_ROLE = 4;  // 0100
  uint8 constant TRANSFER_ADMIN_ROLE = 8; // 1000

  event RoleChange(address indexed grantor, address indexed grantee, uint8 role, bool indexed status);

  mapping (address => uint8) admins; // address => binary roles

  uint8 public contractAdminCount; // counter of contract admins to keep at least one

  modifier validAddress(address addr) {
    require(addr != address(0), "Address cannot be 0x0");
    _;
  }

  modifier validRole(uint8 role) {
    require( role > 0, "DOES NOT HAVE VALID ROLE");
    _;
  }

  modifier onlyContractAdmin() {
    require(hasRole(msg.sender, CONTRACT_ADMIN_ROLE), "DOES NOT HAVE CONTRACT ADMIN ROLE");
    _;
  }

  modifier onlyTransferAdmin() {
    require(hasRole(msg.sender, TRANSFER_ADMIN_ROLE), "DOES NOT HAVE TRANSFER ADMIN ROLE");
    _;
  }

  modifier onlyWalletsAdmin() {
    require(hasRole(msg.sender, WALLETS_ADMIN_ROLE), "DOES NOT HAVE WALLETS ADMIN ROLE");
    _;
  }

  modifier onlyReserveAdmin() {
    require(hasRole(msg.sender, RESERVE_ADMIN_ROLE), "DOES NOT HAVE RESERVE ADMIN ROLE");
    _;
  }

  /**
    @notice Grant role/roles to address use role bitmask
    @param addr to grant role
    @param role bitmask of role/roles to grant
  **/
  function grantRole(address addr, uint8 role) public validRole(role) validAddress(addr) onlyContractAdmin  {
    if ( admins[addr] & CONTRACT_ADMIN_ROLE == 0 && role & CONTRACT_ADMIN_ROLE > 0 ) contractAdminCount++;
    admins[addr] |= role;
    emit RoleChange(msg.sender, addr, role, true);
  }

  function setupRole(address addr, uint8 role) internal validAddress(addr) validRole(role) {
    if ( admins[addr] & CONTRACT_ADMIN_ROLE == 0 && role & CONTRACT_ADMIN_ROLE > 0 ) contractAdminCount++;
    admins[addr] |= role;
    emit RoleChange(msg.sender, addr, role, true);
  }

  /**
    @notice Revoke role/roles from address use role bitmask
    @param addr to revoke role
    @param role bitmask of role/roles to revoke
  **/
  function revokeRole(address addr, uint8 role) public validRole(role) validAddress(addr) onlyContractAdmin  {
    require(hasRole(addr, role), "CAN NOT REVOKE ROLE");
    if ( role & CONTRACT_ADMIN_ROLE > 0 ) {
      require( contractAdminCount > 1, "Must have at least one contract admin" );
      contractAdminCount--;
    }
    admins[addr] ^= role;
    emit RoleChange(msg.sender, addr, role, false);
  }

  /**
    @notice Check role/roles availability at address
    @param addr to revoke role
    @param role bitmask of role/roles to revoke
    @return bool true or false
  **/
  function hasRole(address addr, uint8 role) public view validRole(role) validAddress(addr) returns (bool) {
    return admins[addr] & role > 0;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface ITransferRules {
    /// @notice Detects if a transfer will be reverted and if so returns an appropriate reference code
    /// @param from Sending address
    /// @param to Receiving address
    /// @param value Amount of tokens being transferred
    /// @return Code by which to reference message for rejection reasoning
    function detectTransferRestriction(
        address token,
        address from,
        address to,
        uint256 value
    ) external view returns (uint8);

    /// @notice Returns a human-readable message for a given restriction code
    /// @param restrictionCode Identifier for looking up a message
    /// @return Text showing the restriction's reasoning
    function messageForTransferRestriction(uint8 restrictionCode)
        external
        view
        returns (string memory);

    function checkSuccess(uint8 restrictionCode) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/extensions/ERC20Snapshot.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../utils/ArraysUpgradeable.sol";
import "../../../utils/CountersUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This contract extends an ERC20 token with a snapshot mechanism. When a snapshot is created, the balances and
 * total supply at the time are recorded for later access.
 *
 * This can be used to safely create mechanisms based on token balances such as trustless dividends or weighted voting.
 * In naive implementations it's possible to perform a "double spend" attack by reusing the same balance from different
 * accounts. By using snapshots to calculate dividends or voting power, those attacks no longer apply. It can also be
 * used to create an efficient ERC20 forking mechanism.
 *
 * Snapshots are created by the internal {_snapshot} function, which will emit the {Snapshot} event and return a
 * snapshot id. To get the total supply at the time of a snapshot, call the function {totalSupplyAt} with the snapshot
 * id. To get the balance of an account at the time of a snapshot, call the {balanceOfAt} function with the snapshot id
 * and the account address.
 *
 * NOTE: Snapshot policy can be customized by overriding the {_getCurrentSnapshotId} method. For example, having it
 * return `block.number` will trigger the creation of snapshot at the beginning of each new block. When overriding this
 * function, be careful about the monotonicity of its result. Non-monotonic snapshot ids will break the contract.
 *
 * Implementing snapshots for every block using this method will incur significant gas costs. For a gas-efficient
 * alternative consider {ERC20Votes}.
 *
 * ==== Gas Costs
 *
 * Snapshots are efficient. Snapshot creation is _O(1)_. Retrieval of balances or total supply from a snapshot is _O(log
 * n)_ in the number of snapshots that have been created, although _n_ for a specific account will generally be much
 * smaller since identical balances in subsequent snapshots are stored as a single entry.
 *
 * There is a constant overhead for normal ERC20 transfers due to the additional snapshot bookkeeping. This overhead is
 * only significant for the first transfer that immediately follows a snapshot for a particular account. Subsequent
 * transfers will have normal cost until the next snapshot, and so on.
 */

abstract contract ERC20SnapshotUpgradeable is Initializable, ERC20Upgradeable {
    function __ERC20Snapshot_init() internal onlyInitializing {
    }

    function __ERC20Snapshot_init_unchained() internal onlyInitializing {
    }
    // Inspired by Jordi Baylina's MiniMeToken to record historical balances:
    // https://github.com/Giveth/minime/blob/ea04d950eea153a04c51fa510b068b9dded390cb/contracts/MiniMeToken.sol

    using ArraysUpgradeable for uint256[];
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // Snapshotted values have arrays of ids and the value corresponding to that id. These could be an array of a
    // Snapshot struct, but that would impede usage of functions that work on an array.
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping(address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalSupplySnapshots;

    // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.
    CountersUpgradeable.Counter private _currentSnapshotId;

    /**
     * @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
     */
    event Snapshot(uint256 id);

    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     * {_snapshot} is `internal` and you have to decide how to expose it externally. Its usage may be restricted to a
     * set of accounts, for example using {AccessControl}, or it may be open to the public.
     *
     * [WARNING]
     * ====
     * While an open way of calling {_snapshot} is required for certain trust minimization mechanisms such as forking,
     * you must consider that it can potentially be used by attackers in two ways.
     *
     * First, it can be used to increase the cost of retrieval of values from snapshots, although it will grow
     * logarithmically thus rendering this attack ineffective in the long term. Second, it can be used to target
     * specific accounts and increase the cost of ERC20 transfers for them, in the ways specified in the Gas Costs
     * section above.
     *
     * We haven't measured the actual numbers; if this is something you're interested in please reach out to us.
     * ====
     */
    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _getCurrentSnapshotId();
        emit Snapshot(currentId);
        return currentId;
    }

    /**
     * @dev Get the current snapshotId
     */
    function _getCurrentSnapshotId() internal view virtual returns (uint256) {
        return _currentSnapshotId.current();
    }

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(address account, uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : balanceOf(account);
    }

    /**
     * @dev Retrieves the total supply at the time `snapshotId` was created.
     */
    function totalSupplyAt(uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalSupplySnapshots);

        return snapshotted ? value : totalSupply();
    }

    // Update balance and/or total supply snapshots before the values are modified. This is implemented
    // in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) {
            // mint
            _updateAccountSnapshot(to);
            _updateTotalSupplySnapshot();
        } else if (to == address(0)) {
            // burn
            _updateAccountSnapshot(from);
            _updateTotalSupplySnapshot();
        } else {
            // transfer
            _updateAccountSnapshot(from);
            _updateAccountSnapshot(to);
        }
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots) private view returns (bool, uint256) {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        require(snapshotId <= _getCurrentSnapshotId(), "ERC20Snapshot: nonexistent id");

        // When a valid snapshot is queried, there are three possibilities:
        //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
        //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
        //  to this id is the current one.
        //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
        //  requested id, and its value is the one to return.
        //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
        //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
        //  larger than the requested one.
        //
        // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
        // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
        // exactly this.

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
    }

    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalSupplySnapshots, totalSupply());
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _getCurrentSnapshotId();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Arrays.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev Collection of functions related to array types.
 */
library ArraysUpgradeable {
    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = MathUpgradeable.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;



interface IDividends  {

  /************************
   * Functions
   ************************/

  /// @dev Get unused ERC-20 tokens on snapshot
  /// @param token ERC-20 token address
  /// @param snapshotId Snapshot ID
  /// @return amount of ERC-20 tokens
  function tokensAt(address token, uint256 snapshotId) external view returns (uint256);

  /// @dev Withdrawal remains of unused ERC-20 tokens at snapshot
  /// @param token ERC-20 token address
  /// @param snapshotId Snapshot ID
  function withdrawRemains(address token, uint256 snapshotId) external;

  /**
   * @dev Fund any ERC-20 tokens into current contract
   * Tokens can be claimed by holders of RestrictedSwap Token uses claimDividends method
   * @param token ERC-20 token address
   * @param amount amount of tokens to fund
   * @param snapshotId snapshot ID of RestrictedSwap Token
   */
  function fundDividend(address token, uint256 amount, uint256 snapshotId) external;

  /**
   * @dev Get balance of ERC-20 tokens funded at snapshot
   * @param token ERC-20 token address
   * @param snapshotId snapshot ID of RestrictedSwap Token
   * @return amount of ERC-20 tokens
   */
  function fundsAt(address token, uint256 snapshotId) external view returns (uint256);

  /**
   * @dev Amount of ERC-20 tokens distributed to the holder of RestrictedSwap Token at snapshot
   * @param token ERC-20 token address
   * @param receiver RestrictedSwap Token's holder address
   * @param snapshotId snapshot ID of RestrictedSwap Token
   * @return amount of total ERC-20 tokens distributed to the receiver
   */
  function totalAwardedBalanceAt(address token, address receiver, uint256 snapshotId) external view returns (uint256);

  /**
   * @dev Amount of ERC-20 tokens claimed by the holder of RestrictedSwap Token at snapshot
   * @param token ERC-20 token address
   * @param receiver RestrictedSwap Token's holder address
   * @param snapshotId snapshot ID of RestrictedSwap Token
   * @return amount of claimed ERC-20 tokens
   */
  function claimedBalanceAt(address token, address receiver, uint256 snapshotId) external view returns (uint256);

  /**
   * @dev Amount of ERC-20 tokens that can be claimed by the holder of RestrictedSwap Token at snapshot
   * @param token ERC-20 token address
   * @param receiver RestrictedSwap Token's holder address
   * @param snapshotId snapshot ID of RestrictedSwap Token
   * @return amount of can be claimed ERC-20 tokens
   */
  function unclaimedBalanceAt(address token, address receiver, uint256 snapshotId) external view returns (uint256);

  /**
   * @dev Claim ERC-20 tokens (dividends) by RestrictedSwap Tokens holder
   * Tokens can be claimed when its allowed by unclaimedBalanceAt
   * @param token ERC-20 token address
   * @param snapshotId snapshot ID of RestrictedSwap Token
   */
  function claimDividend(address token, uint256 snapshotId) external;

  /****************************
   * Events
   ****************************/

  event Funded (address indexed payer, address indexed token, uint256 amount, uint256 indexed snapshotId);
  event Claimed (address indexed payee, address indexed token, uint256 amount, uint256 indexed snapshotId);
  event Withdrawn (address indexed payee, address indexed token, uint256 amount, uint256 indexed snapshotId);
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