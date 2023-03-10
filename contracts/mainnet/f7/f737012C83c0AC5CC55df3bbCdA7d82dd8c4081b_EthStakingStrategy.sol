// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

interface IAnyCallV6Proxy {
    function executor() external view returns (address);

    function anyCall(
        address to,
        bytes calldata data,
        address fallbackAddress,
        uint256 toChainID,
        uint256 flags
    ) external payable;
}

interface IAnyCallExecutor {
    function context()
        external
        view
        returns (
            address from,
            uint256 fromChainID,
            uint256 nonce
        );
}

interface IAnyFallback {
    function anyFallback(address to, bytes calldata data) external;
}

abstract contract AnyCallAppBase {
    uint256 private constant ANY_CALL_FLAG_PAY_ON_DEST = 0;
    uint256 private constant ANY_CALL_FLAG_PAY_ON_SRC = 2;

    address public immutable anyCallProxy;
    uint256 public immutable anyCallFlag;
    bool public immutable anyCallExecuteFallback;

    constructor(
        address anyCallProxy_,
        bool anyCallPayOnSrc_,
        bool anyCallExecuteFallback_
    ) internal {
        anyCallProxy = anyCallProxy_;
        anyCallFlag = anyCallPayOnSrc_ ? ANY_CALL_FLAG_PAY_ON_SRC : ANY_CALL_FLAG_PAY_ON_DEST;
        anyCallExecuteFallback = anyCallExecuteFallback_;
    }

    modifier onlyExecutor() {
        require(msg.sender == IAnyCallV6Proxy(anyCallProxy).executor());
        _;
    }

    function _anyCall(
        address to,
        uint256 toChainID,
        bytes memory data
    ) internal {
        uint256 callValue = anyCallFlag == ANY_CALL_FLAG_PAY_ON_DEST ? 0 : msg.value;
        address fallbackAddress = anyCallExecuteFallback ? address(this) : address(0);
        IAnyCallV6Proxy(anyCallProxy).anyCall{value: callValue}(
            to,
            data,
            fallbackAddress,
            toChainID,
            anyCallFlag
        );
    }

    function anyExecute(bytes calldata data)
        external
        onlyExecutor
        returns (bool success, bytes memory result)
    {
        (address from, uint256 fromChainID, ) =
            IAnyCallExecutor(IAnyCallV6Proxy(anyCallProxy).executor()).context();
        bytes4 selector = data.length >= 32 ? bytes4(abi.decode(data[0:32], (bytes32))) : bytes4(0);
        if (from == address(this) && selector == IAnyFallback.anyFallback.selector) {
            (address to, bytes memory fallbackData) =
                abi.decode(data[4:data.length], (address, bytes));
            require(_checkAnyFallbackTo(to, fromChainID), "Invalid anyFallback to");
            _anyFallback(fallbackData);
            return (true, "");
        }

        require(
            _checkAnyExecuteFrom(from, fromChainID) && from != address(0),
            "Invalid anyExecute from"
        );
        _anyExecute(fromChainID, data);
        return (true, "");
    }

    function _checkAnyExecuteFrom(address from, uint256 fromChainID)
        internal
        virtual
        returns (bool);

    function _checkAnyFallbackTo(address to, uint256 fromChainID) internal virtual returns (bool);

    function _anyExecute(uint256 fromChainID, bytes calldata data) internal virtual;

    function _anyFallback(bytes memory data) internal virtual;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./VotingEscrowCheckpoint.sol";
import "../utils/CoreUtility.sol";
import "../utils/ManagedPausable.sol";
import "../interfaces/IVotingEscrow.sol";
import "../utils/ProxyUtility.sol";

import "../anyswap/AnyCallAppBase.sol";
import "../anyswap/AnyswapChessPool.sol";
import "../interfaces/IAnyswapV6ERC20.sol";

contract VotingEscrowV3 is
    IVotingEscrow,
    OwnableUpgradeable,
    ReentrancyGuard,
    CoreUtility,
    VotingEscrowCheckpoint,
    ManagedPausable,
    ProxyUtility,
    AnyCallAppBase
{
    /// @dev Reserved storage slots for future base contract upgrades
    uint256[29] private _reservedSlots;

    using Math for uint256;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event LockCreated(address indexed account, uint256 amount, uint256 unlockTime);

    event AmountIncreased(address indexed account, uint256 increasedAmount);

    event AmountDecreased(address indexed account, uint256 decreasedAmount);

    event UnlockTimeIncreased(address indexed account, uint256 newUnlockTime);

    event Withdrawn(address indexed account, uint256 amount);

    event CrossChainSent(
        address indexed account,
        uint256 toChainID,
        uint256 amount,
        uint256 unlockTime
    );

    event CrossChainReceived(
        address indexed account,
        uint256 fromChainID,
        uint256 amount,
        uint256 newUnlockTime
    );

    event CrossChainVotingEscrowUpdated(uint256 chainID, address votingEscrow);

    uint8 public constant decimals = 18;

    uint256 public constant MIN_CROSS_CHAIN_SENDER_LOCK_PERIOD = 4 weeks;
    uint256 public constant MIN_CROSS_CHAIN_RECEIVER_LOCK_PERIOD = 3 weeks;

    address public immutable override token;

    /// @notice Address of AnyswapChessPool (on BNB Chain) or AnyswapChess (on other chains).
    address public immutable anyswapChess;

    string public name;
    string public symbol;

    address public addressWhitelist;

    mapping(address => LockedBalance) public locked;

    /// @notice Mapping of unlockTime => total amount that will be unlocked at unlockTime
    mapping(uint256 => uint256) public scheduledUnlock;

    /// @notice max lock time allowed at the moment
    uint256 public maxTimeAllowed;

    /// @notice Contract to be called when an account's locked CHESS is decreased
    address public callback;

    /// @notice Amount of Chess locked now. Expired locks are not included.
    uint256 public totalLocked;

    /// @notice Total veCHESS at the end of the last checkpoint's week
    uint256 public nextWeekSupply;

    /// @notice Mapping of week => vote-locked chess total supplies
    ///
    ///         Key is the start timestamp of a week on each Thursday. Value is
    ///         vote-locked chess total supplies captured at the start of each week
    mapping(uint256 => uint256) public veSupplyPerWeek;

    /// @notice Start timestamp of the trading week in which the last checkpoint is made
    uint256 public checkpointWeek;

    /// @notice Mapping of chain ID => VotingEscrow address on that chain
    mapping(uint256 => address) public crossChainVotingEscrows;

    constructor(
        address token_,
        uint256 maxTime_,
        address anyswapChess_,
        address anyCallProxy_
    ) public VotingEscrowCheckpoint(maxTime_) AnyCallAppBase(anyCallProxy_, true, true) {
        token = token_;
        anyswapChess = anyswapChess_;
    }

    /// @dev Initialize the contract. The contract is designed to be used with OpenZeppelin's
    ///      `TransparentUpgradeableProxy`. This function should be called by the proxy's
    ///      constructor (via the `_data` argument).
    function initialize(
        string memory name_,
        string memory symbol_,
        uint256 maxTimeAllowed_
    ) external initializer {
        __Ownable_init();
        require(maxTimeAllowed_ <= _maxTime, "Cannot exceed max time");
        maxTimeAllowed = maxTimeAllowed_;
        _initializeV2(msg.sender, name_, symbol_);
    }

    /// @dev Initialize the part added in V2. If this contract is upgraded from the previous
    ///      version, call `upgradeToAndCall` of the proxy and put a call to this function
    ///      in the `data` argument.
    ///
    ///      In the previous version, name and symbol were not correctly initialized via proxy.
    function initializeV2(
        address pauser_,
        string memory name_,
        string memory symbol_
    ) external onlyProxyAdmin {
        _initializeV2(pauser_, name_, symbol_);
    }

    function _initializeV2(
        address pauser_,
        string memory name_,
        string memory symbol_
    ) private {
        _initializeManagedPausable(pauser_);
        require(bytes(name).length == 0 && bytes(symbol).length == 0);
        name = name_;
        symbol = symbol_;

        // Initialize totalLocked, nextWeekSupply and checkpointWeek
        uint256 nextWeek = _endOfWeek(block.timestamp);
        uint256 totalLocked_ = 0;
        uint256 nextWeekSupply_ = 0;
        for (
            uint256 weekCursor = nextWeek;
            weekCursor <= nextWeek + _maxTime;
            weekCursor += 1 weeks
        ) {
            totalLocked_ = totalLocked_.add(scheduledUnlock[weekCursor]);
            nextWeekSupply_ = nextWeekSupply_.add(
                (scheduledUnlock[weekCursor].mul(weekCursor - nextWeek)) / _maxTime
            );
        }
        totalLocked = totalLocked_;
        nextWeekSupply = nextWeekSupply_;
        checkpointWeek = nextWeek - 1 weeks;
    }

    function maxTime() external view override returns (uint256) {
        return _maxTime;
    }

    function getTimestampDropBelow(address account, uint256 threshold)
        external
        view
        override
        returns (uint256)
    {
        LockedBalance memory lockedBalance = locked[account];
        if (lockedBalance.amount == 0 || lockedBalance.amount < threshold) {
            return 0;
        }
        return lockedBalance.unlockTime.sub(threshold.mul(_maxTime).div(lockedBalance.amount));
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balanceOfAtTimestamp(account, block.timestamp);
    }

    function totalSupply() external view override returns (uint256) {
        return _veTotalSupply(scheduledUnlock, checkpointWeek, nextWeekSupply, totalLocked);
    }

    function getLockedBalance(address account)
        external
        view
        override
        returns (LockedBalance memory)
    {
        return locked[account];
    }

    function balanceOfAtTimestamp(address account, uint256 timestamp)
        external
        view
        override
        returns (uint256)
    {
        return _balanceOfAtTimestamp(account, timestamp);
    }

    function totalSupplyAtTimestamp(uint256 timestamp) external view returns (uint256) {
        return _totalSupplyAtTimestamp(timestamp);
    }

    function createLock(uint256 amount, uint256 unlockTime) external nonReentrant whenNotPaused {
        _assertNotContract();
        require(
            unlockTime + 1 weeks == _endOfWeek(unlockTime),
            "Unlock time must be end of a week"
        );
        LockedBalance memory lockedBalance = locked[msg.sender];
        require(amount > 0, "Zero value");
        require(lockedBalance.amount == 0, "Withdraw old tokens first");
        require(unlockTime > block.timestamp, "Can only lock until time in the future");
        require(
            unlockTime <= block.timestamp + maxTimeAllowed,
            "Voting lock cannot exceed max lock time"
        );

        _checkpointAndUpdateLock(0, 0, amount, unlockTime);
        locked[msg.sender].unlockTime = unlockTime;
        locked[msg.sender].amount = amount;
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        emit LockCreated(msg.sender, amount, unlockTime);
    }

    function increaseAmount(address account, uint256 amount) external nonReentrant whenNotPaused {
        LockedBalance memory lockedBalance = locked[account];
        require(amount > 0, "Zero value");
        require(lockedBalance.unlockTime > block.timestamp, "Cannot add to expired lock");

        uint256 newAmount = lockedBalance.amount.add(amount);
        _checkpointAndUpdateLock(
            lockedBalance.amount,
            lockedBalance.unlockTime,
            newAmount,
            lockedBalance.unlockTime
        );
        locked[account].amount = newAmount;
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        emit AmountIncreased(account, amount);
    }

    function increaseUnlockTime(uint256 unlockTime) external nonReentrant whenNotPaused {
        require(
            unlockTime + 1 weeks == _endOfWeek(unlockTime),
            "Unlock time must be end of a week"
        );
        LockedBalance memory lockedBalance = locked[msg.sender];

        require(lockedBalance.unlockTime > block.timestamp, "Lock expired");
        require(unlockTime > lockedBalance.unlockTime, "Can only increase lock duration");
        require(
            unlockTime <= block.timestamp + maxTimeAllowed,
            "Voting lock cannot exceed max lock time"
        );

        _checkpointAndUpdateLock(
            lockedBalance.amount,
            lockedBalance.unlockTime,
            lockedBalance.amount,
            unlockTime
        );
        locked[msg.sender].unlockTime = unlockTime;
        emit UnlockTimeIncreased(msg.sender, unlockTime);
    }

    function withdraw() external nonReentrant {
        LockedBalance memory lockedBalance = locked[msg.sender];
        require(block.timestamp >= lockedBalance.unlockTime, "The lock is not expired");
        uint256 amount = uint256(lockedBalance.amount);

        lockedBalance.unlockTime = 0;
        lockedBalance.amount = 0;
        locked[msg.sender] = lockedBalance;

        IERC20(token).safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    /// @notice Transfer locked CHESS to the VotingEscrow on another chain. User should pay cross
    ///         chain fee in native currency (e.g. ETH on Ethereum) when calling this function.
    ///         Exact fee amount can be queried from the AnyCall proxy contract, i.e.
    ///         `IAnyCallV6Proxy(thisContract.anyCallProxy()).calcSrcFees(thisContract, toChainID, 96)`.
    /// @param amount Amount of locked CHESS
    /// @param toChainID Target chain ID
    function veChessCrossChain(uint256 amount, uint256 toChainID)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        LockedBalance memory lockedBalance = locked[msg.sender];
        require(amount > 0, "Zero value");
        require(
            lockedBalance.unlockTime > block.timestamp + MIN_CROSS_CHAIN_SENDER_LOCK_PERIOD,
            "Lock period too short"
        );

        uint256 newAmount = lockedBalance.amount.sub(amount);
        _checkpointAndUpdateLock(
            lockedBalance.amount,
            lockedBalance.unlockTime,
            newAmount,
            lockedBalance.unlockTime
        );
        locked[msg.sender].amount = newAmount;

        // Deposit CHESS to AnySwap pool
        address underlying = IAnyswapV6ERC20(anyswapChess).underlying();
        if (underlying != address(0)) {
            // anyswapChess is an AnyswapChessPool contract
            require(token == underlying);
            IERC20(token).safeTransfer(anyswapChess, amount);
        } else {
            // anyswapChess is an AnyswapChess contract
            IAnyswapV6ERC20(anyswapChess).burn(address(this), amount);
        }

        address to = crossChainVotingEscrows[toChainID];
        require(to != address(0), "Unknown chain ID");
        _anyCall(to, toChainID, abi.encode(msg.sender, amount, lockedBalance.unlockTime));

        if (callback != address(0)) {
            IVotingEscrowCallback(callback).syncWithVotingEscrow(msg.sender);
        }

        // Unlock time can only be reset after the callback is invoked, because some veCHESS-related
        // contracts won't refresh the user's locked balance in `syncWithVotingEscrow()` if
        // unlock time is zero.
        if (newAmount == 0) {
            locked[msg.sender].unlockTime = 0;
        }

        emit AmountDecreased(msg.sender, amount);
        emit CrossChainSent(msg.sender, toChainID, amount, lockedBalance.unlockTime);
    }

    function _checkAnyExecuteFrom(address from, uint256 fromChainID)
        internal
        override
        returns (bool)
    {
        return from == crossChainVotingEscrows[fromChainID];
    }

    function _checkAnyFallbackTo(address to, uint256 fromChainID) internal override returns (bool) {
        return to == crossChainVotingEscrows[fromChainID];
    }

    /// @dev Receive cross chain veCHESS transfer.
    function _anyExecute(uint256 fromChainID, bytes calldata data) internal override {
        (address account, uint256 amount, uint256 unlockTime) =
            abi.decode(data, (address, uint256, uint256));
        _receiveCrossChain(account, amount, unlockTime, fromChainID);
    }

    /// @dev When `veChessCrossChain` failed, this function is called by the anyCall proxy
    ///      to add locked CHESS back to the account.
    function _anyFallback(bytes memory data) internal override {
        (address account, uint256 amount, uint256 unlockTime) =
            abi.decode(data, (address, uint256, uint256));
        _receiveCrossChain(account, amount, unlockTime, 0);
    }

    function _receiveCrossChain(
        address account,
        uint256 amount,
        uint256 unlockTime,
        uint256 fromChainID
    ) private nonReentrant {
        require(
            unlockTime + 1 weeks == _endOfWeek(unlockTime),
            "Unlock time must be end of a week"
        );
        LockedBalance memory lockedBalance = locked[account];
        if (lockedBalance.amount == 0) {
            require(
                !Address.isContract(account) ||
                    (addressWhitelist != address(0) &&
                        IAddressWhitelist(addressWhitelist).check(account)),
                "Smart contract depositors not allowed"
            );
        }
        uint256 newAmount = lockedBalance.amount.add(amount);
        uint256 newUnlockTime =
            lockedBalance.unlockTime.max(unlockTime).max(
                _endOfWeek(block.timestamp) + MIN_CROSS_CHAIN_RECEIVER_LOCK_PERIOD
            );
        _checkpointAndUpdateLock(
            lockedBalance.amount,
            lockedBalance.unlockTime,
            newAmount,
            newUnlockTime
        );
        locked[account].amount = newAmount;
        locked[account].unlockTime = newUnlockTime;

        // Withdraw CHESS from AnySwap pool
        address underlying = IAnyswapV6ERC20(anyswapChess).underlying();
        if (underlying != address(0)) {
            // anyswapChess is an AnyswapChessPool contract
            require(token == underlying);
            AnyswapChessPool(anyswapChess).withdrawUnderlying(amount);
        } else {
            // anyswapChess is an AnyswapChess contract
            IAnyswapV6ERC20(anyswapChess).mint(address(this), amount);
        }
        emit AmountIncreased(account, amount);
        if (newUnlockTime != lockedBalance.unlockTime) {
            emit UnlockTimeIncreased(account, newUnlockTime);
        }
        emit CrossChainReceived(account, fromChainID, amount, newUnlockTime);
    }

    function updateAddressWhitelist(address newWhitelist) external onlyOwner {
        require(
            newWhitelist == address(0) || Address.isContract(newWhitelist),
            "Must be null or a contract"
        );
        addressWhitelist = newWhitelist;
    }

    function updateCallback(address newCallback) external onlyOwner {
        require(
            newCallback == address(0) || Address.isContract(newCallback),
            "Must be null or a contract"
        );
        callback = newCallback;
    }

    function updateCrossChainVotingEscrow(uint256 chainID, address votingEscrow)
        external
        onlyOwner
    {
        crossChainVotingEscrows[chainID] = votingEscrow;
        emit CrossChainVotingEscrowUpdated(chainID, votingEscrow);
    }

    function _assertNotContract() private view {
        if (msg.sender != tx.origin) {
            if (
                addressWhitelist != address(0) &&
                IAddressWhitelist(addressWhitelist).check(msg.sender)
            ) {
                return;
            }
            revert("Smart contract depositors not allowed");
        }
    }

    function _balanceOfAtTimestamp(address account, uint256 timestamp)
        private
        view
        returns (uint256)
    {
        require(timestamp >= block.timestamp, "Must be current or future time");
        LockedBalance memory lockedBalance = locked[account];
        if (timestamp > lockedBalance.unlockTime) {
            return 0;
        }
        return (lockedBalance.amount.mul(lockedBalance.unlockTime - timestamp)) / _maxTime;
    }

    function _totalSupplyAtTimestamp(uint256 timestamp) private view returns (uint256) {
        uint256 weekCursor = _endOfWeek(timestamp);
        uint256 total = 0;
        for (; weekCursor <= timestamp + _maxTime; weekCursor += 1 weeks) {
            total = total.add((scheduledUnlock[weekCursor].mul(weekCursor - timestamp)) / _maxTime);
        }
        return total;
    }

    /// @dev Pre-conditions:
    ///
    ///      - `newAmount > 0`
    ///      - `newUnlockTime > block.timestamp`
    ///      - `newUnlockTime + 1 weeks == _endOfWeek(newUnlockTime)`, i.e. aligned to a trading week
    ///
    ///      The latter two conditions gaurantee that `newUnlockTime` is no smaller than
    ///      `_endOfWeek(block.timestamp)`.
    function _checkpointAndUpdateLock(
        uint256 oldAmount,
        uint256 oldUnlockTime,
        uint256 newAmount,
        uint256 newUnlockTime
    ) private {
        uint256 newNextWeekSupply;
        uint256 newTotalLocked;
        (checkpointWeek, newNextWeekSupply, newTotalLocked) = _veCheckpoint(
            scheduledUnlock,
            checkpointWeek,
            nextWeekSupply,
            totalLocked,
            veSupplyPerWeek
        );
        (nextWeekSupply, totalLocked) = _veUpdateLock(
            newNextWeekSupply,
            newTotalLocked,
            oldAmount,
            oldUnlockTime,
            newAmount,
            newUnlockTime,
            scheduledUnlock
        );
    }

    function updateMaxTimeAllowed(uint256 newMaxTimeAllowed) external onlyOwner {
        require(newMaxTimeAllowed <= _maxTime, "Cannot exceed max time");
        require(newMaxTimeAllowed > maxTimeAllowed, "Cannot shorten max time allowed");
        maxTimeAllowed = newMaxTimeAllowed;
    }

    /// @notice Recalculate `nextWeekSupply` from scratch. This function eliminates accumulated
    ///         rounding errors in `nextWeekSupply`, which is incrementally updated in
    ///         `createLock`, `increaseAmount` and `increaseUnlockTime`. It is almost
    ///         never required.
    /// @dev Search "rounding error" in test cases for details about the rounding errors.
    function calibrateSupply() external {
        uint256 nextWeek = checkpointWeek + 1 weeks;
        nextWeekSupply = _totalSupplyAtTimestamp(nextWeek);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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
library SafeMath {
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

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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

    constructor () internal {
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../utils/CoreUtility.sol";

/// @dev This abstract contract incrementally calculates the total amount of veCHESS in each week.
///      A derived contract should maintain the following state variables:
///
///      * `mapping(uint256 => uint256) scheduledUnlock`, amount of CHESS that will be
///        unlocked in each week in the future.
///      * `mapping(uint256 => uint256) veSupplyPerWeek`, total veCHESS in each week in the past.
///      * `uint256 checkpointWeek`, start timestamp of the week when the checkpoint was updated
///         the last time.
///      * `uint256 nextWeekSupply`, total veCHESS at the end of the last checkpoint's week.
///      * `uint256 totalLocked`, amount of CHESS locked now.
abstract contract VotingEscrowCheckpoint is CoreUtility {
    using SafeMath for uint256;

    uint256 internal immutable _maxTime;

    constructor(uint256 maxTime_) internal {
        _maxTime = maxTime_;
    }

    /// @dev Update checkpoint to the given week and record weekly supply in the past.
    ///      This function should be called before any update to `scheduledUnlock`.
    ///      It writes new values to the `veSupplyPerWeek` mapping. Caller is responsible for
    ///      setting `checkpointWeek`, `nextWeekSupply` and `totalLocked` to the return values.
    /// @param scheduledUnlock amount of CHESS that will be unlocked in each week
    /// @param checkpointWeek the old checkpoint timestamp
    /// @param nextWeekSupply total veCHESS at the end of the last checkpoint's week
    /// @param totalLocked amount of CHESS locked in the last checkpoint
    /// @param veSupplyPerWeek total veCHESS in each week, written by this function
    /// @return newCheckpointWeek the new checkpoint timestamp
    /// @return newNextWeekSupply total veCHESS at the end of this trading week
    /// @return newTotalLocked amount of CHESS locked now
    function _veCheckpoint(
        mapping(uint256 => uint256) storage scheduledUnlock,
        uint256 checkpointWeek,
        uint256 nextWeekSupply,
        uint256 totalLocked,
        mapping(uint256 => uint256) storage veSupplyPerWeek
    )
        internal
        returns (
            uint256 newCheckpointWeek,
            uint256 newNextWeekSupply,
            uint256 newTotalLocked
        )
    {
        uint256 nextWeek = _endOfWeek(block.timestamp);
        for (uint256 w = checkpointWeek + 1 weeks; w < nextWeek; w += 1 weeks) {
            veSupplyPerWeek[w] = nextWeekSupply;
            // Remove CHESS unlocked at the beginning of the next week from total locked amount.
            totalLocked = totalLocked.sub(scheduledUnlock[w]);
            // Calculate supply at the end of the next week.
            nextWeekSupply = nextWeekSupply.sub(totalLocked.mul(1 weeks) / _maxTime);
        }
        newCheckpointWeek = nextWeek - 1 weeks;
        newNextWeekSupply = nextWeekSupply;
        newTotalLocked = totalLocked;
    }

    /// @dev Update `scheduledUnlock` and the checkpoint according to the change of a user's locked CHESS.
    ///      This function should be called after the checkpoint is updated by `veCheckpoint()`.
    ///      It updates the `scheduledUnlock` mapping. Caller is responsible for setting
    ///      `nextWeekSupply` and `totalLocked` to the return values.
    /// @param nextWeekSupply total veCHESS at the end of this trading week before this change
    /// @param totalLocked amount of CHESS locked before this change
    /// @param oldAmount old amount of locked CHESS
    /// @param oldUnlockTime old unlock timestamp
    /// @param newAmount new amount of locked CHESS
    /// @param newUnlockTime new unlock timestamp
    /// @param scheduledUnlock amount of CHESS that will be unlocked in each week, updated by this function
    /// @return newNextWeekSupply total veCHESS at at the end of this trading week after this change
    /// @return newTotalLocked amount of CHESS locked after this change
    function _veUpdateLock(
        uint256 nextWeekSupply,
        uint256 totalLocked,
        uint256 oldAmount,
        uint256 oldUnlockTime,
        uint256 newAmount,
        uint256 newUnlockTime,
        mapping(uint256 => uint256) storage scheduledUnlock
    ) internal returns (uint256 newNextWeekSupply, uint256 newTotalLocked) {
        uint256 nextWeek = _endOfWeek(block.timestamp);
        newTotalLocked = totalLocked;
        newNextWeekSupply = nextWeekSupply;
        // Remove the old schedule if there is one
        if (oldAmount > 0 && oldUnlockTime >= nextWeek) {
            newTotalLocked = newTotalLocked.sub(oldAmount);
            newNextWeekSupply = newNextWeekSupply.sub(
                oldAmount.mul(oldUnlockTime - nextWeek) / _maxTime
            );
        }
        newTotalLocked = newTotalLocked.add(newAmount);
        // Round up on division when added to the total supply, so that the total supply is never
        // smaller than the sum of all accounts' veCHESS balance.
        newNextWeekSupply = newNextWeekSupply.add(
            newAmount.mul(newUnlockTime - nextWeek).add(_maxTime - 1) / _maxTime
        );

        if (oldUnlockTime == newUnlockTime) {
            scheduledUnlock[oldUnlockTime] = scheduledUnlock[oldUnlockTime].sub(oldAmount).add(
                newAmount
            );
        } else {
            if (oldUnlockTime >= nextWeek) {
                scheduledUnlock[oldUnlockTime] = scheduledUnlock[oldUnlockTime].sub(oldAmount);
            }
            scheduledUnlock[newUnlockTime] = scheduledUnlock[newUnlockTime].add(newAmount);
        }
    }

    /// @dev Calculate the current total veCHESS amount from the last checkpoint.
    /// @param scheduledUnlock amount of CHESS that will be unlocked in each week
    /// @param checkpointWeek the last checkpoint timestamp
    /// @param nextWeekSupply total veCHESS at the end of the last checkpoint's week
    /// @param totalLocked amount of CHESS locked in the last checkpoint
    /// @return Current total veCHESS amount
    function _veTotalSupply(
        mapping(uint256 => uint256) storage scheduledUnlock,
        uint256 checkpointWeek,
        uint256 nextWeekSupply,
        uint256 totalLocked
    ) internal view returns (uint256) {
        uint256 nextWeek = _endOfWeek(block.timestamp);
        uint256 thisWeek = nextWeek - 1 weeks;
        if (checkpointWeek + 1 weeks < nextWeek) {
            for (uint256 w = checkpointWeek + 1 weeks; w < thisWeek; w += 1 weeks) {
                // Remove CHESS unlocked at the beginning of the next week from total locked amount.
                totalLocked = totalLocked.sub(scheduledUnlock[w]);
                // Calculate supply at the end of the next week.
                nextWeekSupply = nextWeekSupply.sub(totalLocked.mul(1 weeks) / _maxTime);
            }
            totalLocked = totalLocked.sub(scheduledUnlock[thisWeek]);
            return nextWeekSupply.sub(totalLocked.mul(block.timestamp - thisWeek) / _maxTime);
        } else {
            return nextWeekSupply.add(totalLocked.mul(nextWeek - block.timestamp) / _maxTime);
        }
    }

    /// @dev Calculate the total veCHESS amount at a given trading week boundary. The given week
    ///      start timestamp must be later than the last checkpoint. For older weeks,
    ///      derived contract should read from the `veSupplyPerWeek` mapping instead.
    /// @param week Start timestamp of a trading week, must be greater than `checkpointWeek`
    /// @param scheduledUnlock amount of CHESS that will be unlocked in each week
    /// @param checkpointWeek the last checkpoint timestamp
    /// @param nextWeekSupply total veCHESS at the end of the last checkpoint's week
    /// @param totalLocked amount of CHESS locked in the last checkpoint
    /// @return Total veCHESS amount at `week`
    function _veTotalSupplyAtWeek(
        uint256 week,
        mapping(uint256 => uint256) storage scheduledUnlock,
        uint256 checkpointWeek,
        uint256 nextWeekSupply,
        uint256 totalLocked
    ) internal view returns (uint256) {
        if (checkpointWeek + 1 weeks < week) {
            for (uint256 w = checkpointWeek + 1 weeks; w < week; w += 1 weeks) {
                // Remove CHESS unlocked at the beginning of the next week from total locked amount.
                totalLocked = totalLocked.sub(scheduledUnlock[w]);
                // Calculate supply at the end of the next week.
                nextWeekSupply = nextWeekSupply.sub(totalLocked.mul(1 weeks) / _maxTime);
            }
        }
        return nextWeekSupply;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

abstract contract CoreUtility {
    using SafeMath for uint256;

    /// @dev UTC time of a day when the fund settles.
    uint256 internal constant SETTLEMENT_TIME = 14 hours;

    /// @dev Return end timestamp of the trading week containing a given timestamp.
    ///
    ///      A trading week starts at UTC time `SETTLEMENT_TIME` on a Thursday (inclusive)
    ///      and ends at the same time of the next Thursday (exclusive).
    /// @param timestamp The given timestamp
    /// @return End timestamp of the trading week.
    function _endOfWeek(uint256 timestamp) internal pure returns (uint256) {
        return ((timestamp.add(1 weeks) - SETTLEMENT_TIME) / 1 weeks) * 1 weeks + SETTLEMENT_TIME;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract of an emergency stop mechanism that can be triggered by an authorized account.
 *
 * This module is modified based on Pausable in OpenZeppelin v3.3.0, adding public functions to
 * pause, unpause and manage the pauser role. It is also designed to be used by upgradable
 * contracts, like PausableUpgradable but with compact storage slots and no dependencies.
 */
abstract contract ManagedPausable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    event PauserRoleTransferred(address indexed previousPauser, address indexed newPauser);

    uint256 private constant FALSE = 0;
    uint256 private constant TRUE = 1;

    uint256 private _initialized;

    uint256 private _paused;

    address private _pauser;

    function _initializeManagedPausable(address pauser_) internal {
        require(_initialized == FALSE);
        _initialized = TRUE;
        _paused = FALSE;
        _pauser = pauser_;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused != FALSE;
    }

    function pauser() public view returns (address) {
        return _pauser;
    }

    function renouncePauserRole() external onlyPauser {
        emit PauserRoleTransferred(_pauser, address(0));
        _pauser = address(0);
    }

    function transferPauserRole(address newPauser) external onlyPauser {
        require(newPauser != address(0));
        emit PauserRoleTransferred(_pauser, newPauser);
        _pauser = newPauser;
    }

    modifier onlyPauser() {
        require(_pauser == msg.sender, "Pausable: only pauser");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(_paused == FALSE, "Pausable: paused");
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
        require(_paused != FALSE, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() external onlyPauser whenNotPaused {
        _paused = TRUE;
        emit Paused(msg.sender);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() external onlyPauser whenPaused {
        _paused = FALSE;
        emit Unpaused(msg.sender);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

interface IAddressWhitelist {
    function check(address account) external view returns (bool);
}

interface IVotingEscrowCallback {
    function syncWithVotingEscrow(address account) external;
}

interface IVotingEscrow {
    struct LockedBalance {
        uint256 amount;
        uint256 unlockTime;
    }

    function token() external view returns (address);

    function maxTime() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOfAtTimestamp(address account, uint256 timestamp)
        external
        view
        returns (uint256);

    function getTimestampDropBelow(address account, uint256 threshold)
        external
        view
        returns (uint256);

    function getLockedBalance(address account) external view returns (LockedBalance memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

abstract contract ProxyUtility {
    /// @dev Storage slot with the admin of the contract.
    bytes32 private constant _ADMIN_SLOT = bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);

    /// @dev Revert if the proxy admin is not the caller
    modifier onlyProxyAdmin() {
        bytes32 slot = _ADMIN_SLOT;
        address proxyAdmin;
        assembly {
            proxyAdmin := sload(slot)
        }
        require(msg.sender == proxyAdmin, "Only proxy admin");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../governance/ChessRoles.sol";

import "../interfaces/IAnyswapV6ERC20.sol";

contract AnyswapChessPool is IAnyswapV6ERC20, ERC20, ChessRoles, Ownable {
    using SafeERC20 for IERC20;

    address public immutable override underlying;

    constructor(
        string memory name_,
        string memory symbol_,
        address underlying_
    ) public ERC20(name_, symbol_) {
        require(underlying_ != address(0) && underlying_ != address(this));
        underlying = underlying_;
        require(decimals() == ERC20(underlying_).decimals());
    }

    function addMinter(address account) external onlyOwner {
        _addMinter(account);
    }

    function removeMinter(address account) external onlyOwner {
        _removeMinter(account);
    }

    function mint(address to, uint256 amount) external override onlyMinter returns (bool) {
        _mint(to, amount);
        return true;
    }

    function burn(address from, uint256 amount) external override onlyMinter returns (bool) {
        _burn(from, amount);
        return true;
    }

    function deposit() external returns (uint256) {
        uint256 amount = IERC20(underlying).balanceOf(msg.sender);
        IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount);
        return amount;
    }

    function deposit(uint256 amount) external returns (uint256) {
        IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount);
        return amount;
    }

    function deposit(uint256 amount, address to) external returns (uint256) {
        IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);
        _mint(to, amount);
        return amount;
    }

    function depositVault(uint256 amount, address to) external onlyMinter returns (uint256) {
        _mint(to, amount);
        return amount;
    }

    function withdraw() external returns (uint256) {
        return _withdraw(msg.sender, balanceOf(msg.sender), msg.sender);
    }

    function withdraw(uint256 amount) external returns (uint256) {
        return _withdraw(msg.sender, amount, msg.sender);
    }

    function withdraw(uint256 amount, address to) external returns (uint256) {
        return _withdraw(msg.sender, amount, to);
    }

    function withdrawVault(
        address from,
        uint256 amount,
        address to
    ) external onlyMinter returns (uint256) {
        return _withdraw(from, amount, to);
    }

    function _withdraw(
        address from,
        uint256 amount,
        address to
    ) internal returns (uint256) {
        _burn(from, amount);
        IERC20(underlying).safeTransfer(to, amount);
        return amount;
    }

    function withdrawUnderlying(uint256 amount) external onlyMinter {
        IERC20(underlying).safeTransfer(msg.sender, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAnyswapV6ERC20 is IERC20 {
    function underlying() external view returns (address);

    function mint(address to, uint256 amount) external returns (bool);

    function burn(address from, uint256 amount) external returns (bool);
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

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";

abstract contract ChessRoles {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _minterMembers;

    event MinterAdded(address indexed minter);
    event MinterRemoved(address indexed minter);

    modifier onlyMinter() {
        require(isMinter(msg.sender), "Only minter");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minterMembers.contains(account);
    }

    function getMinterMember(uint256 index) external view returns (address) {
        return _minterMembers.at(index);
    }

    function getMinterCount() external view returns (uint256) {
        return _minterMembers.length();
    }

    function _addMinter(address minter) internal {
        if (_minterMembers.add(minter)) {
            emit MinterAdded(minter);
        }
    }

    function _removeMinter(address minter) internal {
        if (_minterMembers.remove(minter)) {
            emit MinterRemoved(minter);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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
library EnumerableSet {
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/IChessSchedule.sol";
import "../interfaces/IControllerBallotV2.sol";
import "../utils/CoreUtility.sol";

import "./ChessRoles.sol";

import "../anyswap/AnyCallAppBase.sol";
import "../interfaces/IAnyswapV6ERC20.sol";

contract ChessSubSchedule is
    IChessSchedule,
    OwnableUpgradeable,
    ChessRoles,
    CoreUtility,
    AnyCallAppBase
{
    /// @dev Reserved storage slots for future base contract upgrades
    uint256[32] private _reservedSlots;

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public immutable mainChainID;
    address public immutable scheduleRelayer;

    IControllerBallotV2 public immutable controllerBallot;

    IAnyswapV6ERC20 public immutable chess;

    /// @notice Current number of tokens in existence (claimed or unclaimed)
    uint256 public availableSupply;
    uint256 public outstandingSupply;
    uint256 public minted;
    mapping(uint256 => uint256) private _weeklySupplies;

    constructor(
        uint256 mainChainID_,
        address scheduleRelayer_,
        address controllerBallot_,
        address chess_,
        address anyCallProxy_
    ) public AnyCallAppBase(anyCallProxy_, true, false) {
        mainChainID = mainChainID_;
        scheduleRelayer = scheduleRelayer_;
        controllerBallot = IControllerBallotV2(controllerBallot_);
        chess = IAnyswapV6ERC20(chess_);
    }

    function initialize() external initializer {
        __Ownable_init();
    }

    /// @notice Get supply of the week containing the given timestamp. This function usually
    ///         returns zero when called at the beginning of the week. After cross-chain CHESS
    ///         emission is delivered to this contract, this function returns the correct value.
    function getWeeklySupply(uint256 timestamp) public view override returns (uint256) {
        return _weeklySupplies[_endOfWeek(timestamp) - 1 weeks];
    }

    /// @notice Get the release rate of CHESS token at the given timestamp. This function usually
    ///         returns zero when called at the beginning of the week. After cross-chain CHESS
    ///         emission is delivered to this contract, this function returns the average rate over
    ///         a whole week.
    /// @param timestamp Timestamp for release rate
    /// @return Release rate (number of CHESS token per second)
    function getRate(uint256 timestamp) external view override returns (uint256) {
        return _weeklySupplies[_endOfWeek(timestamp) - 1 weeks] / 1 weeks;
    }

    /// @notice Creates `amount` CHESS tokens and assigns them to `account`,
    ///         increasing the total supply. This is guarded by `Minter` role.
    /// @param account recipient of the token
    /// @param amount amount of the token
    function mint(address account, uint256 amount) external override onlyMinter {
        require(minted.add(amount) <= availableSupply, "Exceeds allowable mint amount");
        chess.mint(account, amount);
        minted = minted.add(amount);
    }

    function addMinter(address account) external override onlyOwner {
        _addMinter(account);
    }

    function removeMinter(address account) external onlyOwner {
        _removeMinter(account);
    }

    /// @notice Send the total veCHESS amount voted to all pools on this chain to the main chain.
    function crossChainSync() external payable {
        uint256 week = _endOfWeek(block.timestamp);
        uint256 supply = controllerBallot.totalSupplyAtWeek(week);
        uint256 nextWeekSupply = controllerBallot.totalSupplyAtWeek(week + 1 weeks);
        _anyCall(scheduleRelayer, mainChainID, abi.encode(week, supply, nextWeekSupply));
    }

    function _checkAnyExecuteFrom(address from, uint256 fromChainID)
        internal
        override
        returns (bool)
    {
        return from == scheduleRelayer && fromChainID == mainChainID;
    }

    function _checkAnyFallbackTo(address, uint256) internal override returns (bool) {
        return false;
    }

    /// @dev Receive CHESS emission from the main chain.
    function _anyExecute(
        uint256, // fromChainID
        bytes calldata data
    ) internal override {
        uint256 totalAmount = abi.decode(data, (uint256));
        uint256 currentWeek = _endOfWeek(block.timestamp) - 1 weeks;
        uint256 outstandingSupply_ = outstandingSupply;
        // A non-zero weekly supply indicates the current weekly emission has already gone
        // into effect, so we have to delay the emission to next week.
        if (_weeklySupplies[currentWeek] == 0) {
            if (outstandingSupply_ != 0) {
                totalAmount = totalAmount.add(outstandingSupply_);
                outstandingSupply = 0;
            }
            availableSupply = availableSupply.add(totalAmount);
            _weeklySupplies[currentWeek] = totalAmount;
        } else {
            outstandingSupply = outstandingSupply_.add(totalAmount);
        }
    }

    function _anyFallback(bytes memory) internal override {
        revert("N/A");
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

interface IChessSchedule {
    function getWeeklySupply(uint256 timestamp) external view returns (uint256);

    function getRate(uint256 timestamp) external view returns (uint256);

    function mint(address account, uint256 amount) external;

    function addMinter(address account) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

interface IControllerBallotV2 {
    function totalSupplyAtWeek(uint256 week) external view returns (uint256);

    function sumAtWeek(address pool, uint256 week) external view returns (uint256);

    function count(uint256 week)
        external
        view
        returns (uint256[] memory sums, address[] memory funds);

    function cast(uint256[] memory weights) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/IChessSchedule.sol";
import "../utils/CoreUtility.sol";

import "./ChessRoles.sol";

contract ChessSchedule is IChessSchedule, OwnableUpgradeable, ChessRoles, CoreUtility {
    /// @dev Reserved storage slots for future base contract upgrades
    uint256[32] private _reservedSlots;

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant MAX_SUPPLY = 120_000_000e18;

    /// @dev Hard-coded cumulative weekly supply. Please refer to the whitepaper for details.
    ///      Below are the concrete numbers in this list, which are also tested in "test/chessSchedule.ts".
    ///
    ///      ```
    ///         300000    900000   1800000   3000000   5400000   7704000   9915840  12039206  14077638  16034532
    ///       17913151  19716625  21447960  23110041  24705640  26237414  27707917  29119601  30474817  31775824
    ///       33037801  34261919  35449313  36601086  37718305  38802007  39853199  40872855  41861921  42921315
    ///       43931928  44894622  45810235  46679580  47503444  48302592  49077766  49829685  50559047  51266527
    ///       51959858  52639322  53305197  53957754  54597261  55223977  55838159  56440057  57029917  57607980
    ///       58174482  58729653  59273722  59806909  60329432  60841504  61343336  61835130  62317089  62789409
    ///       63252282  63705898  64150441  64586093  65013033  65431434  65841466  66243298  66637094  67023013
    ///       67405073  67783313  68157770  68528483  68895489  69258824  69618526  69974632  70327176  70676194
    ///       71025213  71374232  71723250  72072269  72421288  72770306  73119325  73468344  73817362  74166381
    ///       74515399  74864418  75213437  75562455  75911474  76260493  76609511  76958530  77307549  77656567
    ///      ```
    bytes private constant CUMULATIVE_SUPPLY_SCHEDULE =
        hex"000000000000000000000000000000000000000000003f870857a3e0e380000000000000000000000000000000000000000000000000be951906eba2aa800000000000000000000000000000000000000000000000017d2a320dd74555000000000000000000000000000000000000000000000000027b46536c66c8e300000000000000000000000000000000000000000000000004777e962985cfff000000000000000000000000000000000000000000000000065f62ad457aa39f0000000000000000000000000000000000000000000000000833c2c374cc129f00000000000000000000000000000000000000000000000009f566aa3e18d928d800000000000000000000000000000000000000000000000ba50e48ffcd3def5800000000000000000000000000000000000000000000000d4371b8b190797d1000000000000000000000000000000000000000000000000ed141dc8c1e6e659c0000000000000000000000000000000000000000000000104f28620947a945a4000000000000000000000000000000000000000000000011bdc83dca5db1a5600000000000000000000000000000000000000000000000131dbdd53a5724eec40000000000000000000000000000000000000000000000146f9f6d938553a8a0000000000000000000000000000000000000000000000015b3fd101e26da27d8000000000000000000000000000000000000000000000016eb6130b8f80c68140000000000000000000000000000000000000000000000181650bbb9e9a9b324000000000000000000000000000000000000000000000019354b23ced790486400000000000000000000000000000000000000000000001a48cadee3f50e3f4000000000000000000000000000000000000000000000001b5406c7ea3059ae0400000000000000000000000000000000000000000000001c573e59c54139431c00000000000000000000000000000000000000000000001d52af1bbf2e3022e400000000000000000000000000000000000000000000001e4694d90b274c853800000000000000000000000000000000000000000000001f33296942ab5917e400000000000000000000000000000000000000000000002018a503a9d012eafc000000000000000000000000000000000000000000000020f73e3f2f422970dc000000000000000000000000000000000000000000000021cf29e8ca212387fc000000000000000000000000000000000000000000000022a09b48dd90e1bfe400000000000000000000000000000000000000000000002380f126009ae94fac00000000000000000000000000000000000000000000002456f296c5adc1756000000000000000000000000000000000000000000000002522ce55d3fa57d3b8000000000000000000000000000000000000000000000025e4b1d0c190c25c0c0000000000000000000000000000000000000000000000269cc91a32a98ba6f00000000000000000000000000000000000000000000000274b3edbf8eeff4cd0000000000000000000000000000000000000000000000027f478c257eb6de800000000000000000000000000000000000000000000000028989f06a12b8ea45800000000000000000000000000000000000000000000002937d8a2f5d1f4a3b4000000000000000000000000000000000000000000000029d24b6e0804764cbc00000000000000000000000000000000000000000000002a681bff597ec5fc1c00000000000000000000000000000000000000000000002afaed8bd921b3118800000000000000000000000000000000000000000000002b8acf5d102f23f12800000000000000000000000000000000000000000000002c17d085050e30619400000000000000000000000000000000000000000000002ca1ffb499270695a800000000000000000000000000000000000000000000002d296b730bbdb9ca1400000000000000000000000000000000000000000000002dae21cab5aa0c590400000000000000000000000000000000000000000000002e3030aa2e56594ddc00000000000000000000000000000000000000000000002eafa59ee82e12204400000000000000000000000000000000000000000000002f2c8dfed2c1d9aa5400000000000000000000000000000000000000000000002fa6f6da7a10d081300000000000000000000000000000000000000000000000301eecfd068894f508000000000000000000000000000000000000000000000030947cde5c4e8f69b400000000000000000000000000000000000000000000003107b2e87ed1749ba8000000000000000000000000000000000000000000000031789b088b13a864d4000000000000000000000000000000000000000000000031e7410fdcaa27506000000000000000000000000000000000000000000000003253b08a6b986ba480000000000000000000000000000000000000000000000032bdf4e86e748858a000000000000000000000000000000000000000000000003326191d35683f81a80000000000000000000000000000000000000000000000338c2829f15406dbe4000000000000000000000000000000000000000000000033f02caeae196a8fe4000000000000000000000000000000000000000000000034523113f4bf2828a8000000000000000000000000000000000000000000000034b23fa68cde95e26800000000000000000000000000000000000000000000003510625ff9c8d40d040000000000000000000000000000000000000000000000356ca31dfd619ba994000000000000000000000000000000000000000000000035c70b94b7688ac3040000000000000000000000000000000000000000000000361fa52503550977e80000000000000000000000000000000000000000000000367679061a7a64f0a8000000000000000000000000000000000000000000000036cb9061557536ae480000000000000000000000000000000000000000000000371ef41aa95095ecd800000000000000000000000000000000000000000000003770acd0a78617a374000000000000000000000000000000000000000000000037c1945443a57511a400000000000000000000000000000000000000000000003811acc2b9840cb7a400000000000000000000000000000000000000000000003860f81d8389d5c6e8000000000000000000000000000000000000000000000038af7881dd8c2ebfac000000000000000000000000000000000000000000000038fd2ff141f30ed3640000000000000000000000000000000000000000000000394a205f4a6fb98c20000000000000000000000000000000000000000000000039964bdb5220d9c2b8000000000000000000000000000000000000000000000039e1b466d36e66a8a000000000000000000000000000000000000000000000003a2c5bd9a69c3c792000000000000000000000000000000000000000000000003a764427655b9ebe4800000000000000000000000000000000000000000000003ac02c8304d1b4aad400000000000000000000000000000000000000000000003b0a14dea447ca976000000000000000000000000000000000000000000000003b53fd2c63072cdc8800000000000000000000000000000000000000000000003b9de588027d42c91400000000000000000000000000000000000000000000003be7cde3a1f358b5a000000000000000000000000000000000000000000000003c31b63160b2bafac800000000000000000000000000000000000000000000003c7b9e8d0028d0e75400000000000000000000000000000000000000000000003cc586e89f9ee6d3e000000000000000000000000000000000000000000000003d0f6f365e5e49190800000000000000000000000000000000000000000000003d595791fdd45f059400000000000000000000000000000000000000000000003da33fdfbc93c14abc00000000000000000000000000000000000000000000003ded283b5c09d7374800000000000000000000000000000000000000000000003e371096fb7fed23d400000000000000000000000000000000000000000000003e80f8e4ba3f4f68fc00000000000000000000000000000000000000000000003ecae14059b565558800000000000000000000000000000000000000000000003f14c99bf92b7b421400000000000000000000000000000000000000000000003f5eb1e9b7eadd873c00000000000000000000000000000000000000000000003fa89a455760f373c800000000000000000000000000000000000000000000003ff282a0f6d70960540000000000000000000000000000000000000000000000403c6aeeb5966ba57c0000";

    IERC20 public immutable chess;
    uint256 public immutable startTimestamp;

    uint256 public minted;

    constructor(address chess_, uint256 startTimestamp_) public ChessRoles() {
        require(
            _endOfWeek(startTimestamp_ - 1) == startTimestamp_,
            "Start timestamp is not start of a trading week"
        );
        chess = IERC20(chess_);
        startTimestamp = startTimestamp_;
    }

    /// @notice Initialize ownership and deposit tokens.
    function initialize() external initializer {
        __Ownable_init();
        chess.safeTransferFrom(msg.sender, address(this), MAX_SUPPLY);
    }

    /// @notice Get length of the supply schedule
    /// @return The length of the supply schedule
    function getScheduleLength() public pure returns (uint256) {
        return CUMULATIVE_SUPPLY_SCHEDULE.length / 32;
    }

    /// @notice Get supply of the week containing the given timestamp.
    /// @param timestamp Any timestamp in the week to be queried
    /// @return weeklySupply Weekly supply
    function getWeeklySupply(uint256 timestamp)
        public
        view
        override
        returns (uint256 weeklySupply)
    {
        if (timestamp < startTimestamp) {
            return 0;
        }
        (, weeklySupply) = _getWeeklySupply((timestamp - startTimestamp) / 1 weeks);
    }

    function _getWeeklySupply(uint256 index)
        private
        pure
        returns (uint256 currentWeekCumulativeSupply, uint256 weeklySupply)
    {
        uint256 length = getScheduleLength();
        bytes memory scheduleBytes = CUMULATIVE_SUPPLY_SCHEDULE;
        if (index == 0) {
            assembly {
                weeklySupply := mload(add(scheduleBytes, 32))
            }
        } else if (index < length) {
            uint256 offset = index * 32;
            uint256 nextWeekCumulativeSupply;
            assembly {
                currentWeekCumulativeSupply := mload(add(scheduleBytes, offset))
                nextWeekCumulativeSupply := mload(add(scheduleBytes, add(offset, 32)))
            }
            weeklySupply = nextWeekCumulativeSupply.sub(currentWeekCumulativeSupply);
        } else {
            uint256 offset = length * 32;
            assembly {
                currentWeekCumulativeSupply := mload(add(scheduleBytes, offset))
            }
        }
    }

    /// @notice Current number of tokens in existence (claimed or unclaimed) by the end of
    ///         the current week.
    function availableSupply() public view returns (uint256) {
        if (block.timestamp < startTimestamp) {
            return 0;
        }
        (uint256 currentWeekCumulativeSupply, uint256 weeklySupply) =
            _getWeeklySupply((block.timestamp - startTimestamp) / 1 weeks);
        return currentWeekCumulativeSupply.add(weeklySupply);
    }

    /// @notice Get the emission rate of CHESS token at the given timestamp
    /// @param timestamp Timestamp for emission rate
    /// @return Release rate (number of CHESS token per second)
    function getRate(uint256 timestamp) external view override returns (uint256) {
        return getWeeklySupply(timestamp) / 1 weeks;
    }

    /// @notice Creates `amount` CHESS tokens and assigns them to `account`,
    ///         increasing the total supply. This is guarded by `Minter` role.
    /// @param account recipient of the token
    /// @param amount amount of the token
    function mint(address account, uint256 amount) external override onlyMinter {
        require(minted.add(amount) <= availableSupply(), "Exceeds allowable mint amount");
        chess.safeTransfer(account, amount);
        minted = minted.add(amount);
    }

    function addMinter(address account) external override onlyOwner {
        _addMinter(account);
    }

    function removeMinter(address account) external onlyOwner {
        _removeMinter(account);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/ILiquidityGauge.sol";
import "../interfaces/IChessSchedule.sol";
import "../interfaces/IChessController.sol";
import "../interfaces/IFundV3.sol";
import "../interfaces/ITrancheIndexV2.sol";
import "../interfaces/IStableSwap.sol";
import "../interfaces/IVotingEscrow.sol";

import "../utils/CoreUtility.sol";
import "../utils/SafeDecimalMath.sol";

interface ISwapBonus {
    function bonusToken() external view returns (address);

    function getBonus() external returns (uint256);
}

contract LiquidityGaugeV2 is ILiquidityGauge, ITrancheIndexV2, CoreUtility, ERC20 {
    using Math for uint256;
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;
    using SafeERC20 for IERC20;

    struct Distribution {
        uint256 amountQ;
        uint256 amountB;
        uint256 amountR;
        uint256 quoteAmount;
    }

    uint256 private constant MAX_ITERATIONS = 500;
    uint256 private constant MAX_BOOSTING_FACTOR = 3e18;
    uint256 private constant MAX_BOOSTING_FACTOR_MINUS_ONE = MAX_BOOSTING_FACTOR - 1e18;

    address public immutable stableSwap;
    IERC20 private immutable _quoteToken;
    IChessSchedule public immutable chessSchedule;
    IChessController public immutable chessController;
    IFundV3 public immutable fund;
    IVotingEscrow private immutable _votingEscrow;
    address public immutable swapBonus;
    IERC20 private immutable _bonusToken;

    uint256 private _workingSupply;
    mapping(address => uint256) private _workingBalances;

    uint256 public latestVersion;
    mapping(uint256 => Distribution) public distributions;
    mapping(uint256 => uint256) public distributionTotalSupplies;
    mapping(address => Distribution) public userDistributions;
    mapping(address => uint256) public userVersions;

    uint256 private _chessIntegral;
    uint256 private _chessIntegralTimestamp;
    mapping(address => uint256) private _chessUserIntegrals;
    mapping(address => uint256) private _claimableChess;

    uint256 private _bonusIntegral;
    mapping(address => uint256) private _bonusUserIntegral;
    mapping(address => uint256) private _claimableBonus;

    /// @dev Per-gauge CHESS emission rate. The product of CHESS emission rate
    ///      and weekly percentage of the gauge
    uint256 private _rate;

    constructor(
        string memory name_,
        string memory symbol_,
        address stableSwap_,
        address chessSchedule_,
        address chessController_,
        address fund_,
        address votingEscrow_,
        address swapBonus_
    ) public ERC20(name_, symbol_) {
        stableSwap = stableSwap_;
        _quoteToken = IERC20(IStableSwap(stableSwap_).quoteAddress());
        chessSchedule = IChessSchedule(chessSchedule_);
        chessController = IChessController(chessController_);
        fund = IFundV3(fund_);
        _votingEscrow = IVotingEscrow(votingEscrow_);
        swapBonus = swapBonus_;
        _bonusToken = IERC20(ISwapBonus(swapBonus_).bonusToken());
        _chessIntegralTimestamp = block.timestamp;
    }

    modifier onlyStableSwap() {
        require(msg.sender == stableSwap, "Only stable swap");
        _;
    }

    function getRate() external view returns (uint256) {
        return _rate / 1e18;
    }

    function mint(address account, uint256 amount) external override onlyStableSwap {
        uint256 oldWorkingBalance = _workingBalances[account];
        uint256 oldWorkingSupply = _workingSupply;
        uint256 oldBalance = balanceOf(account);
        _checkpoint(account, oldBalance, oldWorkingBalance, oldWorkingSupply);

        _mint(account, amount);
        _updateWorkingBalance(account, oldWorkingBalance, oldWorkingSupply, oldBalance.add(amount));
    }

    function burnFrom(address account, uint256 amount) external override onlyStableSwap {
        uint256 oldWorkingBalance = _workingBalances[account];
        uint256 oldWorkingSupply = _workingSupply;
        uint256 oldBalance = balanceOf(account);
        _checkpoint(account, oldBalance, oldWorkingBalance, oldWorkingSupply);

        _burn(account, amount);
        _updateWorkingBalance(account, oldWorkingBalance, oldWorkingSupply, oldBalance.sub(amount));
    }

    function _transfer(
        address,
        address,
        uint256
    ) internal override {
        revert("Transfer is not allowed");
    }

    function workingBalanceOf(address account) external view override returns (uint256) {
        return _workingBalances[account];
    }

    function workingSupply() external view override returns (uint256) {
        return _workingSupply;
    }

    function claimableRewards(address account)
        external
        override
        returns (
            uint256 chessAmount,
            uint256 bonusAmount,
            uint256 amountQ,
            uint256 amountB,
            uint256 amountR,
            uint256 quoteAmount
        )
    {
        return _checkpoint(account, balanceOf(account), _workingBalances[account], _workingSupply);
    }

    function claimRewards(address account) external override {
        uint256 balance = balanceOf(account);
        uint256 oldWorkingBalance = _workingBalances[account];
        uint256 oldWorkingSupply = _workingSupply;
        (
            uint256 chessAmount,
            uint256 bonusAmount,
            uint256 amountQ,
            uint256 amountB,
            uint256 amountR,
            uint256 quoteAmount
        ) = _checkpoint(account, balance, oldWorkingBalance, oldWorkingSupply);
        _updateWorkingBalance(account, oldWorkingBalance, oldWorkingSupply, balance);

        if (chessAmount != 0) {
            chessSchedule.mint(account, chessAmount);
            delete _claimableChess[account];
        }
        if (bonusAmount != 0) {
            _bonusToken.safeTransfer(account, bonusAmount);
            delete _claimableBonus[account];
        }
        if (amountQ != 0 || amountB != 0 || amountR != 0 || quoteAmount != 0) {
            uint256 version = latestVersion;
            if (amountQ != 0) {
                fund.trancheTransfer(TRANCHE_Q, account, amountQ, version);
            }
            if (amountB != 0) {
                fund.trancheTransfer(TRANCHE_B, account, amountB, version);
            }
            if (amountR != 0) {
                fund.trancheTransfer(TRANCHE_R, account, amountR, version);
            }
            if (quoteAmount != 0) {
                _quoteToken.safeTransfer(account, quoteAmount);
            }
            delete userDistributions[account];
        }
    }

    function syncWithVotingEscrow(address account) external {
        uint256 balance = balanceOf(account);
        uint256 oldWorkingBalance = _workingBalances[account];
        uint256 oldWorkingSupply = _workingSupply;
        _checkpoint(account, balance, oldWorkingBalance, oldWorkingSupply);
        _updateWorkingBalance(account, oldWorkingBalance, oldWorkingSupply, balance);
    }

    function distribute(
        uint256 amountQ,
        uint256 amountB,
        uint256 amountR,
        uint256 quoteAmount,
        uint256 version
    ) external override onlyStableSwap {
        // Update global state
        distributions[version].amountQ = amountQ;
        distributions[version].amountB = amountB;
        distributions[version].amountR = amountR;
        distributions[version].quoteAmount = quoteAmount;
        distributionTotalSupplies[version] = totalSupply();
        latestVersion = version;
    }

    function _updateWorkingBalance(
        address account,
        uint256 oldWorkingBalance,
        uint256 oldWorkingSupply,
        uint256 newBalance
    ) private {
        uint256 newWorkingBalance = newBalance;
        uint256 veBalance = _votingEscrow.balanceOf(account);
        if (veBalance > 0) {
            uint256 veTotalSupply = _votingEscrow.totalSupply();
            uint256 maxWorkingBalance = newWorkingBalance.multiplyDecimal(MAX_BOOSTING_FACTOR);
            uint256 boostedWorkingBalance =
                newWorkingBalance.add(
                    totalSupply().mul(veBalance).multiplyDecimal(MAX_BOOSTING_FACTOR_MINUS_ONE).div(
                        veTotalSupply
                    )
                );
            newWorkingBalance = maxWorkingBalance.min(boostedWorkingBalance);
        }
        _workingSupply = oldWorkingSupply.sub(oldWorkingBalance).add(newWorkingBalance);
        _workingBalances[account] = newWorkingBalance;
    }

    function _checkpoint(
        address account,
        uint256 balance,
        uint256 weight,
        uint256 totalWeight
    )
        private
        returns (
            uint256 chessAmount,
            uint256 bonusAmount,
            uint256 amountQ,
            uint256 amountB,
            uint256 amountR,
            uint256 quoteAmount
        )
    {
        chessAmount = _chessCheckpoint(account, weight, totalWeight);
        bonusAmount = _bonusCheckpoint(account, weight, totalWeight);
        (amountQ, amountB, amountR, quoteAmount) = _distributionCheckpoint(account, balance);
    }

    function _chessCheckpoint(
        address account,
        uint256 weight,
        uint256 totalWeight
    ) private returns (uint256 amount) {
        // Update global state
        uint256 timestamp = _chessIntegralTimestamp;
        uint256 integral = _chessIntegral;
        uint256 endWeek = _endOfWeek(timestamp);
        uint256 rate = _rate;
        if (rate == 0) {
            // CHESS emission may update in the middle of a week due to cross-chain lag.
            // We re-calculate the rate if it was zero after the last checkpoint.
            uint256 weeklySupply = chessSchedule.getWeeklySupply(timestamp);
            if (weeklySupply != 0) {
                rate = (weeklySupply / (endWeek - timestamp)).mul(
                    chessController.getFundRelativeWeight(address(this), timestamp)
                );
            }
        }
        for (uint256 i = 0; i < MAX_ITERATIONS && timestamp < block.timestamp; i++) {
            uint256 endTimestamp = endWeek.min(block.timestamp);
            if (totalWeight != 0) {
                integral = integral.add(
                    rate.mul(endTimestamp - timestamp).decimalToPreciseDecimal().div(totalWeight)
                );
            }
            if (endTimestamp == endWeek) {
                rate = chessSchedule.getRate(endWeek).mul(
                    chessController.getFundRelativeWeight(address(this), endWeek)
                );
                endWeek += 1 weeks;
            }
            timestamp = endTimestamp;
        }
        _chessIntegralTimestamp = block.timestamp;
        _chessIntegral = integral;
        _rate = rate;

        // Update per-user state
        amount = _claimableChess[account].add(
            weight.multiplyDecimalPrecise(integral.sub(_chessUserIntegrals[account]))
        );
        _claimableChess[account] = amount;
        _chessUserIntegrals[account] = integral;
    }

    function _bonusCheckpoint(
        address account,
        uint256 weight,
        uint256 totalWeight
    ) private returns (uint256 amount) {
        // Update global state
        uint256 newBonus = ISwapBonus(swapBonus).getBonus();
        uint256 integral = _bonusIntegral;
        if (totalWeight != 0 && newBonus != 0) {
            integral = integral.add(newBonus.divideDecimalPrecise(totalWeight));
            _bonusIntegral = integral;
        }

        // Update per-user state
        uint256 oldUserIntegral = _bonusUserIntegral[account];
        if (oldUserIntegral == integral) {
            return _claimableBonus[account];
        }
        amount = _claimableBonus[account].add(
            weight.multiplyDecimalPrecise(integral.sub(oldUserIntegral))
        );
        _claimableBonus[account] = amount;
        _bonusUserIntegral[account] = integral;
    }

    function _distributionCheckpoint(address account, uint256 balance)
        private
        returns (
            uint256 amountQ,
            uint256 amountB,
            uint256 amountR,
            uint256 quoteAmount
        )
    {
        uint256 version = userVersions[account];
        uint256 newVersion = latestVersion;

        // Update per-user state
        Distribution storage userDist = userDistributions[account];
        amountQ = userDist.amountQ;
        amountB = userDist.amountB;
        amountR = userDist.amountR;
        quoteAmount = userDist.quoteAmount;
        if (version == newVersion) {
            return (amountQ, amountB, amountR, quoteAmount);
        }
        for (uint256 i = version; i < newVersion; i++) {
            if (amountQ != 0 || amountB != 0 || amountR != 0) {
                (amountQ, amountB, amountR) = fund.doRebalance(amountQ, amountB, amountR, i);
            }
            Distribution storage dist = distributions[i + 1];
            uint256 distTotalSupply = distributionTotalSupplies[i + 1];
            if (distTotalSupply != 0) {
                amountQ = amountQ.add(dist.amountQ.mul(balance).div(distTotalSupply));
                amountB = amountB.add(dist.amountB.mul(balance).div(distTotalSupply));
                amountR = amountR.add(dist.amountR.mul(balance).div(distTotalSupply));
                quoteAmount = quoteAmount.add(dist.quoteAmount.mul(balance).div(distTotalSupply));
            }
        }
        userDist.amountQ = amountQ;
        userDist.amountB = amountB;
        userDist.amountR = amountR;
        userDist.quoteAmount = quoteAmount;
        userVersions[account] = newVersion;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface ILiquidityGauge is IERC20 {
    function mint(address account, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function workingSupply() external view returns (uint256);

    function workingBalanceOf(address account) external view returns (uint256);

    function claimableRewards(address account)
        external
        returns (
            uint256 chessAmount,
            uint256 bonusAmount,
            uint256 amountQ,
            uint256 amountB,
            uint256 amountR,
            uint256 quoteAmount
        );

    function claimRewards(address account) external;

    function distribute(
        uint256 amountQ,
        uint256 amountB,
        uint256 amountR,
        uint256 quoteAmount,
        uint256 version
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

interface IChessController {
    function getFundRelativeWeight(address account, uint256 timestamp) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "./ITwapOracleV2.sol";

interface IFundV3 {
    /// @notice A linear transformation matrix that represents a rebalance.
    ///
    ///         ```
    ///             [        1        0        0 ]
    ///         R = [ ratioB2Q  ratioBR        0 ]
    ///             [ ratioR2Q        0  ratioBR ]
    ///         ```
    ///
    ///         Amounts of the three tranches `q`, `b` and `r` can be rebalanced by multiplying the matrix:
    ///
    ///         ```
    ///         [ q', b', r' ] = [ q, b, r ] * R
    ///         ```
    struct Rebalance {
        uint256 ratioB2Q;
        uint256 ratioR2Q;
        uint256 ratioBR;
        uint256 timestamp;
    }

    function tokenUnderlying() external view returns (address);

    function tokenQ() external view returns (address);

    function tokenB() external view returns (address);

    function tokenR() external view returns (address);

    function tokenShare(uint256 tranche) external view returns (address);

    function primaryMarket() external view returns (address);

    function primaryMarketUpdateProposal() external view returns (address, uint256);

    function strategy() external view returns (address);

    function strategyUpdateProposal() external view returns (address, uint256);

    function underlyingDecimalMultiplier() external view returns (uint256);

    function twapOracle() external view returns (ITwapOracleV2);

    function feeCollector() external view returns (address);

    function endOfDay(uint256 timestamp) external pure returns (uint256);

    function trancheTotalSupply(uint256 tranche) external view returns (uint256);

    function trancheBalanceOf(uint256 tranche, address account) external view returns (uint256);

    function trancheAllBalanceOf(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function trancheBalanceVersion(address account) external view returns (uint256);

    function trancheAllowance(
        uint256 tranche,
        address owner,
        address spender
    ) external view returns (uint256);

    function trancheAllowanceVersion(address owner, address spender)
        external
        view
        returns (uint256);

    function trancheTransfer(
        uint256 tranche,
        address recipient,
        uint256 amount,
        uint256 version
    ) external;

    function trancheTransferFrom(
        uint256 tranche,
        address sender,
        address recipient,
        uint256 amount,
        uint256 version
    ) external;

    function trancheApprove(
        uint256 tranche,
        address spender,
        uint256 amount,
        uint256 version
    ) external;

    function getRebalanceSize() external view returns (uint256);

    function getRebalance(uint256 index) external view returns (Rebalance memory);

    function getRebalanceTimestamp(uint256 index) external view returns (uint256);

    function currentDay() external view returns (uint256);

    function splitRatio() external view returns (uint256);

    function historicalSplitRatio(uint256 version) external view returns (uint256);

    function fundActivityStartTime() external view returns (uint256);

    function isFundActive(uint256 timestamp) external view returns (bool);

    function getEquivalentTotalB() external view returns (uint256);

    function getEquivalentTotalQ() external view returns (uint256);

    function historicalEquivalentTotalB(uint256 timestamp) external view returns (uint256);

    function historicalNavs(uint256 timestamp) external view returns (uint256 navB, uint256 navR);

    function extrapolateNav(uint256 price)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function doRebalance(
        uint256 amountQ,
        uint256 amountB,
        uint256 amountR,
        uint256 index
    )
        external
        view
        returns (
            uint256 newAmountQ,
            uint256 newAmountB,
            uint256 newAmountR
        );

    function batchRebalance(
        uint256 amountQ,
        uint256 amountB,
        uint256 amountR,
        uint256 fromIndex,
        uint256 toIndex
    )
        external
        view
        returns (
            uint256 newAmountQ,
            uint256 newAmountB,
            uint256 newAmountR
        );

    function refreshBalance(address account, uint256 targetVersion) external;

    function refreshAllowance(
        address owner,
        address spender,
        uint256 targetVersion
    ) external;

    function shareTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) external;

    function shareTransferFrom(
        address spender,
        address sender,
        address recipient,
        uint256 amount
    ) external returns (uint256 newAllowance);

    function shareIncreaseAllowance(
        address sender,
        address spender,
        uint256 addedValue
    ) external returns (uint256 newAllowance);

    function shareDecreaseAllowance(
        address sender,
        address spender,
        uint256 subtractedValue
    ) external returns (uint256 newAllowance);

    function shareApprove(
        address owner,
        address spender,
        uint256 amount
    ) external;

    function historicalUnderlying(uint256 timestamp) external view returns (uint256);

    function getTotalUnderlying() external view returns (uint256);

    function getStrategyUnderlying() external view returns (uint256);

    function getTotalDebt() external view returns (uint256);

    event RebalanceTriggered(
        uint256 indexed index,
        uint256 indexed day,
        uint256 navSum,
        uint256 navB,
        uint256 navROrZero,
        uint256 ratioB2Q,
        uint256 ratioR2Q,
        uint256 ratioBR
    );
    event Settled(uint256 indexed day, uint256 navB, uint256 navR, uint256 interestRate);
    event InterestRateUpdated(uint256 baseInterestRate, uint256 floatingInterestRate);
    event BalancesRebalanced(
        address indexed account,
        uint256 version,
        uint256 balanceQ,
        uint256 balanceB,
        uint256 balanceR
    );
    event AllowancesRebalanced(
        address indexed owner,
        address indexed spender,
        uint256 version,
        uint256 allowanceQ,
        uint256 allowanceB,
        uint256 allowanceR
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

/// @notice Amounts of QUEEN, BISHOP and ROOK are sometimes stored in a `uint256[3]` array.
///         This contract defines index of each tranche in this array.
///
///         Solidity does not allow constants to be defined in interfaces. So this contract follows
///         the naming convention of interfaces but is implemented as an `abstract contract`.
abstract contract ITrancheIndexV2 {
    uint256 internal constant TRANCHE_Q = 0;
    uint256 internal constant TRANCHE_B = 1;
    uint256 internal constant TRANCHE_R = 2;

    uint256 internal constant TRANCHE_COUNT = 3;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "../interfaces/IFundV3.sol";

interface IStableSwapCore {
    function getQuoteOut(uint256 baseIn) external view returns (uint256 quoteOut);

    function getQuoteIn(uint256 baseOut) external view returns (uint256 quoteIn);

    function getBaseOut(uint256 quoteIn) external view returns (uint256 baseOut);

    function getBaseIn(uint256 quoteOut) external view returns (uint256 baseIn);

    function buy(
        uint256 version,
        uint256 baseOut,
        address recipient,
        bytes calldata data
    ) external returns (uint256 realBaseOut);

    function sell(
        uint256 version,
        uint256 quoteOut,
        address recipient,
        bytes calldata data
    ) external returns (uint256 realQuoteOut);
}

interface IStableSwap is IStableSwapCore {
    function fund() external view returns (IFundV3);

    function baseTranche() external view returns (uint256);

    function baseAddress() external view returns (address);

    function quoteAddress() external view returns (address);

    function allBalances() external view returns (uint256, uint256);

    function getOraclePrice() external view returns (uint256);

    function getCurrentD() external view returns (uint256);

    function getCurrentPriceOverOracle() external view returns (uint256);

    function getCurrentPrice() external view returns (uint256);

    function getPriceOverOracleIntegral() external view returns (uint256);

    function addLiquidity(uint256 version, address recipient) external returns (uint256);

    function removeLiquidity(
        uint256 version,
        uint256 lpIn,
        uint256 minBaseOut,
        uint256 minQuoteOut
    ) external returns (uint256 baseOut, uint256 quoteOut);

    function removeLiquidityUnwrap(
        uint256 version,
        uint256 lpIn,
        uint256 minBaseOut,
        uint256 minQuoteOut
    ) external returns (uint256 baseOut, uint256 quoteOut);

    function removeBaseLiquidity(
        uint256 version,
        uint256 lpIn,
        uint256 minBaseOut
    ) external returns (uint256 baseOut);

    function removeQuoteLiquidity(
        uint256 version,
        uint256 lpIn,
        uint256 minQuoteOut
    ) external returns (uint256 quoteOut);

    function removeQuoteLiquidityUnwrap(
        uint256 version,
        uint256 lpIn,
        uint256 minQuoteOut
    ) external returns (uint256 quoteOut);
}

/// @dev The interface shares the same function names as in `IStableSwapCore`;
///      all getters are defined as non-view functions in order to parse and
///      return the internal revert messages
interface IStableSwapCoreInternalRevertExpected {
    function getQuoteOut(uint256 baseIn) external returns (uint256 quoteOut);

    function getQuoteIn(uint256 baseOut) external returns (uint256 quoteIn);

    function getBaseOut(uint256 quoteIn) external returns (uint256 baseOut);

    function getBaseIn(uint256 quoteOut) external returns (uint256 baseIn);

    function buy(
        uint256 version,
        uint256 baseOut,
        address recipient,
        bytes calldata data
    ) external returns (uint256 realBaseOut);

    function sell(
        uint256 version,
        uint256 quoteOut,
        address recipient,
        bytes calldata data
    ) external returns (uint256 realQuoteOut);
}

// SPDX-License-Identifier: MIT
//
// Copyright (c) 2019 Synthetix
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

library SafeDecimalMath {
    using SafeMath for uint256;

    /* Number of decimal places in the representations. */
    uint256 private constant decimals = 18;
    uint256 private constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    uint256 private constant UNIT = 10**uint256(decimals);

    /* The number representing 1.0 for higher fidelity numbers. */
    uint256 private constant PRECISE_UNIT = 10**uint256(highPrecisionDecimals);
    uint256 private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR =
        10**uint256(highPrecisionDecimals - decimals);

    /**
     * @return The result of multiplying x and y, interpreting the operands as fixed-point
     * decimals.
     *
     * @dev A unit factor is divided out after the product of x and y is evaluated,
     * so that product must be less than 2**256. As this is an integer division,
     * the internal division always rounds down. This helps save on gas. Rounding
     * is more expensive on gas.
     */
    function multiplyDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y).div(UNIT);
    }

    function multiplyDecimalPrecise(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y).div(PRECISE_UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is a high
     * precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and UNIT must be less than 2**256. As
     * this is an integer division, the result is always rounded down.
     * This helps save on gas. Rounding is more expensive on gas.
     */
    function divideDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(UNIT).div(y);
    }

    function divideDecimalPrecise(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(PRECISE_UNIT).div(y);
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
     */
    function decimalToPreciseDecimal(uint256 i) internal pure returns (uint256) {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
     */
    function preciseDecimalToDecimal(uint256 i) internal pure returns (uint256) {
        uint256 quotientTimesTen = i.mul(10).div(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen = quotientTimesTen.add(10);
        }

        return quotientTimesTen.div(10);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, and the max value of
     * uint256 on overflow.
     */
    function saturatingMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        return c / a != b ? type(uint256).max : c;
    }

    function saturatingMultiplyDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return saturatingMul(x, y).div(UNIT);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "./ITwapOracle.sol";

interface ITwapOracleV2 is ITwapOracle {
    function getLatest() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

interface ITwapOracle {
    enum UpdateType {PRIMARY, SECONDARY, OWNER, CHAINLINK, UNISWAP_V2}

    function getTwap(uint256 timestamp) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "../interfaces/ITrancheIndexV2.sol";
import "../utils/SafeDecimalMath.sol";
import "./StableSwap.sol";

contract QueenStableSwap is StableSwap, ITrancheIndexV2 {
    using SafeDecimalMath for uint256;

    constructor(
        address lpToken_,
        address fund_,
        uint256 quoteDecimals_,
        uint256 ampl_,
        address feeCollector_,
        uint256 feeRate_,
        uint256 adminFeeRate_
    )
        public
        StableSwap(
            lpToken_,
            fund_,
            TRANCHE_Q,
            IFundV3(fund_).tokenUnderlying(),
            quoteDecimals_,
            ampl_,
            feeCollector_,
            feeRate_,
            adminFeeRate_
        )
    {
        require(10**(18 - quoteDecimals_) == IFundV3(fund_).underlyingDecimalMultiplier());
    }

    function _getRebalanceResult(uint256)
        internal
        view
        override
        returns (
            uint256 newBase,
            uint256 newQuote,
            uint256 excessiveQ,
            uint256 excessiveB,
            uint256 excessiveR,
            uint256 excessiveQuote,
            bool isRebalanced
        )
    {
        return (baseBalance, quoteBalance, 0, 0, 0, 0, false);
    }

    function _handleRebalance(uint256)
        internal
        override
        returns (uint256 newBase, uint256 newQuote)
    {
        return (baseBalance, quoteBalance);
    }

    function getOraclePrice() public view override returns (uint256) {
        uint256 fundUnderlying = fund.getTotalUnderlying();
        uint256 fundEquivalentTotalQ = fund.getEquivalentTotalQ();
        return fundUnderlying.mul(_quoteDecimalMultiplier).divideDecimal(fundEquivalentTotalQ);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "../interfaces/IStableSwap.sol";
import "../interfaces/ILiquidityGauge.sol";
import "../interfaces/ITranchessSwapCallee.sol";
import "../interfaces/IWrappedERC20.sol";

import "../utils/SafeDecimalMath.sol";
import "../utils/AdvancedMath.sol";
import "../utils/ManagedPausable.sol";

abstract contract StableSwap is IStableSwap, Ownable, ReentrancyGuard, ManagedPausable {
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;
    using SafeERC20 for IERC20;

    event LiquidityAdded(
        address indexed sender,
        address indexed recipient,
        uint256 baseIn,
        uint256 quoteIn,
        uint256 lpOut,
        uint256 fee,
        uint256 adminFee,
        uint256 oraclePrice
    );
    event LiquidityRemoved(
        address indexed account,
        uint256 lpIn,
        uint256 baseOut,
        uint256 quotOut,
        uint256 fee,
        uint256 adminFee,
        uint256 oraclePrice
    );
    event Swap(
        address indexed sender,
        address indexed recipient,
        uint256 baseIn,
        uint256 quoteIn,
        uint256 baseOut,
        uint256 quoteOut,
        uint256 fee,
        uint256 adminFee,
        uint256 oraclePrice
    );
    event Sync(uint256 base, uint256 quote, uint256 oraclePrice);
    event AmplRampUpdated(uint256 start, uint256 end, uint256 startTimestamp, uint256 endTimestamp);
    event FeeCollectorUpdated(address newFeeCollector);
    event FeeRateUpdated(uint256 newFeeRate);
    event AdminFeeRateUpdated(uint256 newAdminFeeRate);

    uint256 private constant AMPL_MAX_VALUE = 1e6;
    uint256 private constant AMPL_RAMP_MIN_TIME = 86400;
    uint256 private constant AMPL_RAMP_MAX_CHANGE = 10;
    uint256 private constant MAX_FEE_RATE = 0.5e18;
    uint256 private constant MAX_ADMIN_FEE_RATE = 1e18;
    uint256 private constant MAX_ITERATION = 255;
    uint256 private constant MINIMUM_LIQUIDITY = 1e3;

    address public immutable lpToken;
    IFundV3 public immutable override fund;
    uint256 public immutable override baseTranche;
    address public immutable override quoteAddress;

    /// @dev A multipler that normalizes a quote asset balance to 18 decimal places.
    uint256 internal immutable _quoteDecimalMultiplier;

    uint256 public baseBalance;
    uint256 public quoteBalance;

    uint256 private _priceOverOracleIntegral;
    uint256 private _priceOverOracleTimestamp;

    uint256 public amplRampStart;
    uint256 public amplRampEnd;
    uint256 public amplRampStartTimestamp;
    uint256 public amplRampEndTimestamp;

    address public feeCollector;
    uint256 public feeRate;
    uint256 public adminFeeRate;
    uint256 public totalAdminFee;

    constructor(
        address lpToken_,
        address fund_,
        uint256 baseTranche_,
        address quoteAddress_,
        uint256 quoteDecimals_,
        uint256 ampl_,
        address feeCollector_,
        uint256 feeRate_,
        uint256 adminFeeRate_
    ) public {
        lpToken = lpToken_;
        fund = IFundV3(fund_);
        baseTranche = baseTranche_;
        quoteAddress = quoteAddress_;
        require(quoteDecimals_ <= 18, "Quote asset decimals larger than 18");
        _quoteDecimalMultiplier = 10**(18 - quoteDecimals_);

        require(ampl_ > 0 && ampl_ < AMPL_MAX_VALUE, "Invalid A");
        amplRampEnd = ampl_;
        emit AmplRampUpdated(ampl_, ampl_, 0, 0);

        _updateFeeCollector(feeCollector_);
        _updateFeeRate(feeRate_);
        _updateAdminFeeRate(adminFeeRate_);

        _initializeManagedPausable(msg.sender);
    }

    receive() external payable {}

    function baseAddress() external view override returns (address) {
        return fund.tokenShare(baseTranche);
    }

    function allBalances() external view override returns (uint256, uint256) {
        (uint256 base, uint256 quote, , , , , ) = _getRebalanceResult(fund.getRebalanceSize());
        return (base, quote);
    }

    function getAmpl() public view returns (uint256) {
        uint256 endTimestamp = amplRampEndTimestamp;
        if (block.timestamp < endTimestamp) {
            uint256 startTimestamp = amplRampStartTimestamp;
            uint256 start = amplRampStart;
            uint256 end = amplRampEnd;
            if (end > start) {
                return
                    start +
                    ((end - start) * (block.timestamp - startTimestamp)) /
                    (endTimestamp - startTimestamp);
            } else {
                return
                    start -
                    ((start - end) * (block.timestamp - startTimestamp)) /
                    (endTimestamp - startTimestamp);
            }
        } else {
            return amplRampEnd;
        }
    }

    function getCurrentD() external view override returns (uint256) {
        (uint256 base, uint256 quote, , , , , ) = _getRebalanceResult(fund.getRebalanceSize());
        return _getD(base, quote, getAmpl(), getOraclePrice());
    }

    function getCurrentPriceOverOracle() public view override returns (uint256) {
        (uint256 base, uint256 quote, , , , , ) = _getRebalanceResult(fund.getRebalanceSize());
        if (base == 0 || quote == 0) {
            return 1e18;
        }
        uint256 ampl = getAmpl();
        uint256 oraclePrice = getOraclePrice();
        uint256 d = _getD(base, quote, ampl, oraclePrice);
        return _getPriceOverOracle(base, quote, ampl, oraclePrice, d);
    }

    /// @notice Get the current swap price, i.e. negative slope at the current point on the curve.
    ///         The returned value is computed after both base and quote balances are normalized to
    ///         18 decimal places. If the quote token does not have 18 decimal places, the returned
    ///         value has a different order of magnitude than the ratio of quote amount to base
    ///         amount in a swap.
    function getCurrentPrice() external view override returns (uint256) {
        (uint256 base, uint256 quote, , , , , ) = _getRebalanceResult(fund.getRebalanceSize());
        uint256 oraclePrice = getOraclePrice();
        if (base == 0 || quote == 0) {
            return oraclePrice;
        }
        uint256 ampl = getAmpl();
        uint256 d = _getD(base, quote, ampl, oraclePrice);
        return _getPriceOverOracle(base, quote, ampl, oraclePrice, d).multiplyDecimal(oraclePrice);
    }

    function getPriceOverOracleIntegral() external view override returns (uint256) {
        return
            _priceOverOracleIntegral +
            getCurrentPriceOverOracle() *
            (block.timestamp - _priceOverOracleTimestamp);
    }

    function getQuoteOut(uint256 baseIn) external view override returns (uint256 quoteOut) {
        (uint256 oldBase, uint256 oldQuote, , , , , ) =
            _getRebalanceResult(fund.getRebalanceSize());
        uint256 newBase = oldBase.add(baseIn);
        uint256 ampl = getAmpl();
        uint256 oraclePrice = getOraclePrice();
        // Add 1 in case of rounding errors
        uint256 d = _getD(oldBase, oldQuote, ampl, oraclePrice) + 1;
        uint256 newQuote = _getQuote(ampl, newBase, oraclePrice, d) + 1;
        quoteOut = oldQuote.sub(newQuote);
        // Round down output after fee
        quoteOut = quoteOut.multiplyDecimal(1e18 - feeRate);
    }

    function getQuoteIn(uint256 baseOut) external view override returns (uint256 quoteIn) {
        (uint256 oldBase, uint256 oldQuote, , , , , ) =
            _getRebalanceResult(fund.getRebalanceSize());
        uint256 newBase = oldBase.sub(baseOut);
        uint256 ampl = getAmpl();
        uint256 oraclePrice = getOraclePrice();
        // Add 1 in case of rounding errors
        uint256 d = _getD(oldBase, oldQuote, ampl, oraclePrice) + 1;
        uint256 newQuote = _getQuote(ampl, newBase, oraclePrice, d) + 1;
        quoteIn = newQuote.sub(oldQuote);
        uint256 feeRate_ = feeRate;
        // Round up input before fee
        quoteIn = quoteIn.mul(1e18).add(1e18 - feeRate_ - 1) / (1e18 - feeRate_);
    }

    function getBaseOut(uint256 quoteIn) external view override returns (uint256 baseOut) {
        (uint256 oldBase, uint256 oldQuote, , , , , ) =
            _getRebalanceResult(fund.getRebalanceSize());
        // Round down input after fee
        uint256 quoteInAfterFee = quoteIn.multiplyDecimal(1e18 - feeRate);
        uint256 newQuote = oldQuote.add(quoteInAfterFee);
        uint256 ampl = getAmpl();
        uint256 oraclePrice = getOraclePrice();
        // Add 1 in case of rounding errors
        uint256 d = _getD(oldBase, oldQuote, ampl, oraclePrice) + 1;
        uint256 newBase = _getBase(ampl, newQuote, oraclePrice, d) + 1;
        baseOut = oldBase.sub(newBase);
    }

    function getBaseIn(uint256 quoteOut) external view override returns (uint256 baseIn) {
        (uint256 oldBase, uint256 oldQuote, , , , , ) =
            _getRebalanceResult(fund.getRebalanceSize());
        uint256 feeRate_ = feeRate;
        // Round up output before fee
        uint256 quoteOutBeforeFee = quoteOut.mul(1e18).add(1e18 - feeRate_ - 1) / (1e18 - feeRate_);
        uint256 newQuote = oldQuote.sub(quoteOutBeforeFee);
        uint256 ampl = getAmpl();
        uint256 oraclePrice = getOraclePrice();
        // Add 1 in case of rounding errors
        uint256 d = _getD(oldBase, oldQuote, ampl, oraclePrice) + 1;
        uint256 newBase = _getBase(ampl, newQuote, oraclePrice, d) + 1;
        baseIn = newBase.sub(oldBase);
    }

    function buy(
        uint256 version,
        uint256 baseOut,
        address recipient,
        bytes calldata data
    )
        external
        override
        nonReentrant
        checkVersion(version)
        whenNotPaused
        returns (uint256 realBaseOut)
    {
        require(baseOut > 0, "Zero output");
        realBaseOut = baseOut;
        (uint256 oldBase, uint256 oldQuote) = _handleRebalance(version);
        require(baseOut < oldBase, "Insufficient liquidity");
        // Optimistically transfer tokens.
        fund.trancheTransfer(baseTranche, recipient, baseOut, version);
        if (data.length > 0) {
            ITranchessSwapCallee(msg.sender).tranchessSwapCallback(baseOut, 0, data);
        }
        uint256 newQuote = _getNewQuoteBalance();
        uint256 quoteIn = newQuote.sub(oldQuote);
        uint256 fee = quoteIn.multiplyDecimal(feeRate);
        uint256 oraclePrice = getOraclePrice();
        {
            uint256 ampl = getAmpl();
            uint256 oldD = _getD(oldBase, oldQuote, ampl, oraclePrice);
            _updatePriceOverOracleIntegral(oldBase, oldQuote, ampl, oraclePrice, oldD);
            uint256 newD = _getD(oldBase - baseOut, newQuote.sub(fee), ampl, oraclePrice);
            require(newD >= oldD, "Invariant mismatch");
        }
        uint256 adminFee = fee.multiplyDecimal(adminFeeRate);
        baseBalance = oldBase - baseOut;
        quoteBalance = newQuote.sub(adminFee);
        totalAdminFee = totalAdminFee.add(adminFee);
        uint256 baseOut_ = baseOut;
        emit Swap(msg.sender, recipient, 0, quoteIn, baseOut_, 0, fee, adminFee, oraclePrice);
    }

    function sell(
        uint256 version,
        uint256 quoteOut,
        address recipient,
        bytes calldata data
    )
        external
        override
        nonReentrant
        checkVersion(version)
        whenNotPaused
        returns (uint256 realQuoteOut)
    {
        require(quoteOut > 0, "Zero output");
        realQuoteOut = quoteOut;
        (uint256 oldBase, uint256 oldQuote) = _handleRebalance(version);
        // Optimistically transfer tokens.
        IERC20(quoteAddress).safeTransfer(recipient, quoteOut);
        if (data.length > 0) {
            ITranchessSwapCallee(msg.sender).tranchessSwapCallback(0, quoteOut, data);
        }
        uint256 newBase = fund.trancheBalanceOf(baseTranche, address(this));
        uint256 baseIn = newBase.sub(oldBase);
        uint256 fee;
        {
            uint256 feeRate_ = feeRate;
            fee = quoteOut.mul(feeRate_).div(1e18 - feeRate_);
        }
        require(quoteOut.add(fee) < oldQuote, "Insufficient liquidity");
        uint256 oraclePrice = getOraclePrice();
        {
            uint256 newQuote = oldQuote - quoteOut;
            uint256 ampl = getAmpl();
            uint256 oldD = _getD(oldBase, oldQuote, ampl, oraclePrice);
            _updatePriceOverOracleIntegral(oldBase, oldQuote, ampl, oraclePrice, oldD);
            uint256 newD = _getD(newBase, newQuote - fee, ampl, oraclePrice);
            require(newD >= oldD, "Invariant mismatch");
        }
        uint256 adminFee = fee.multiplyDecimal(adminFeeRate);
        baseBalance = newBase;
        quoteBalance = oldQuote - quoteOut - adminFee;
        totalAdminFee = totalAdminFee.add(adminFee);
        uint256 quoteOut_ = quoteOut;
        emit Swap(msg.sender, recipient, baseIn, 0, 0, quoteOut_, fee, adminFee, oraclePrice);
    }

    /// @notice Add liquidity. This function should be called by a smart contract, which transfers
    ///         base and quote tokens to this contract in the same transaction.
    /// @param version The latest rebalance version
    /// @param recipient Recipient of minted LP tokens
    /// @param lpOut Amount of minted LP tokens
    function addLiquidity(uint256 version, address recipient)
        external
        override
        nonReentrant
        checkVersion(version)
        whenNotPaused
        returns (uint256 lpOut)
    {
        (uint256 oldBase, uint256 oldQuote) = _handleRebalance(version);
        uint256 newBase = fund.trancheBalanceOf(baseTranche, address(this));
        uint256 newQuote = _getNewQuoteBalance();
        uint256 ampl = getAmpl();
        uint256 oraclePrice = getOraclePrice();
        uint256 lpSupply = IERC20(lpToken).totalSupply();
        if (lpSupply == 0) {
            require(newBase > 0 && newQuote > 0, "Zero initial balance");
            baseBalance = newBase;
            quoteBalance = newQuote;
            // Overflow is desired
            _priceOverOracleIntegral += 1e18 * (block.timestamp - _priceOverOracleTimestamp);
            _priceOverOracleTimestamp = block.timestamp;
            uint256 d1 = _getD(newBase, newQuote, ampl, oraclePrice);
            ILiquidityGauge(lpToken).mint(address(this), MINIMUM_LIQUIDITY);
            ILiquidityGauge(lpToken).mint(recipient, d1.sub(MINIMUM_LIQUIDITY));
            emit LiquidityAdded(msg.sender, recipient, newBase, newQuote, d1, 0, 0, oraclePrice);
            return d1;
        }
        uint256 fee;
        uint256 adminFee;
        {
            // Initial invariant
            uint256 d0 = _getD(oldBase, oldQuote, ampl, oraclePrice);
            _updatePriceOverOracleIntegral(oldBase, oldQuote, ampl, oraclePrice, d0);
            {
                // New invariant before charging fee
                uint256 d1 = _getD(newBase, newQuote, ampl, oraclePrice);
                uint256 idealQuote = d1.mul(oldQuote) / d0;
                uint256 difference =
                    idealQuote > newQuote ? idealQuote - newQuote : newQuote - idealQuote;
                fee = difference.multiplyDecimal(feeRate);
            }
            adminFee = fee.multiplyDecimal(adminFeeRate);
            totalAdminFee = totalAdminFee.add(adminFee);
            baseBalance = newBase;
            quoteBalance = newQuote.sub(adminFee);
            // New invariant after charging fee
            uint256 d2 = _getD(newBase, newQuote.sub(fee), ampl, oraclePrice);
            require(d2 > d0, "No liquidity is added");
            lpOut = lpSupply.mul(d2.sub(d0)).div(d0);
        }
        ILiquidityGauge(lpToken).mint(recipient, lpOut);
        emit LiquidityAdded(
            msg.sender,
            recipient,
            newBase - oldBase,
            newQuote - oldQuote,
            lpOut,
            fee,
            adminFee,
            oraclePrice
        );
    }

    /// @dev Remove liquidity proportionally.
    /// @param lpIn Exact amount of LP token to burn
    /// @param minBaseOut Least amount of base asset to withdraw
    /// @param minQuoteOut Least amount of quote asset to withdraw
    function removeLiquidity(
        uint256 version,
        uint256 lpIn,
        uint256 minBaseOut,
        uint256 minQuoteOut
    )
        external
        override
        nonReentrant
        checkVersion(version)
        returns (uint256 baseOut, uint256 quoteOut)
    {
        (baseOut, quoteOut) = _removeLiquidity(version, lpIn, minBaseOut, minQuoteOut);
        IERC20(quoteAddress).safeTransfer(msg.sender, quoteOut);
    }

    /// @dev Remove liquidity proportionally and unwrap for native token.
    /// @param lpIn Exact amount of LP token to burn
    /// @param minBaseOut Least amount of base asset to withdraw
    /// @param minQuoteOut Least amount of quote asset to withdraw
    function removeLiquidityUnwrap(
        uint256 version,
        uint256 lpIn,
        uint256 minBaseOut,
        uint256 minQuoteOut
    )
        external
        override
        nonReentrant
        checkVersion(version)
        returns (uint256 baseOut, uint256 quoteOut)
    {
        (baseOut, quoteOut) = _removeLiquidity(version, lpIn, minBaseOut, minQuoteOut);
        IWrappedERC20(quoteAddress).withdraw(quoteOut);
        (bool success, ) = msg.sender.call{value: quoteOut}("");
        require(success, "Transfer failed");
    }

    function _removeLiquidity(
        uint256 version,
        uint256 lpIn,
        uint256 minBaseOut,
        uint256 minQuoteOut
    ) private returns (uint256 baseOut, uint256 quoteOut) {
        uint256 lpSupply = IERC20(lpToken).totalSupply();
        (uint256 oldBase, uint256 oldQuote) = _handleRebalance(version);
        baseOut = oldBase.mul(lpIn).div(lpSupply);
        quoteOut = oldQuote.mul(lpIn).div(lpSupply);
        require(baseOut >= minBaseOut, "Insufficient output");
        require(quoteOut >= minQuoteOut, "Insufficient output");
        baseBalance = oldBase.sub(baseOut);
        quoteBalance = oldQuote.sub(quoteOut);
        ILiquidityGauge(lpToken).burnFrom(msg.sender, lpIn);
        fund.trancheTransfer(baseTranche, msg.sender, baseOut, version);
        emit LiquidityRemoved(msg.sender, lpIn, baseOut, quoteOut, 0, 0, 0);
    }

    /// @dev Remove base liquidity only.
    /// @param lpIn Exact amount of LP token to burn
    /// @param minBaseOut Least amount of base asset to withdraw
    function removeBaseLiquidity(
        uint256 version,
        uint256 lpIn,
        uint256 minBaseOut
    ) external override nonReentrant checkVersion(version) whenNotPaused returns (uint256 baseOut) {
        (uint256 oldBase, uint256 oldQuote) = _handleRebalance(version);
        uint256 lpSupply = IERC20(lpToken).totalSupply();
        uint256 ampl = getAmpl();
        uint256 oraclePrice = getOraclePrice();
        uint256 d1;
        {
            uint256 d0 = _getD(oldBase, oldQuote, ampl, oraclePrice);
            _updatePriceOverOracleIntegral(oldBase, oldQuote, ampl, oraclePrice, d0);
            d1 = d0.sub(d0.mul(lpIn).div(lpSupply));
        }
        {
            uint256 fee = oldQuote.mul(lpIn).div(lpSupply).multiplyDecimal(feeRate);
            // Add 1 in case of rounding errors
            uint256 newBase = _getBase(ampl, oldQuote.sub(fee), oraclePrice, d1) + 1;
            baseOut = oldBase.sub(newBase);
            require(baseOut >= minBaseOut, "Insufficient output");
            ILiquidityGauge(lpToken).burnFrom(msg.sender, lpIn);
            baseBalance = newBase;
            uint256 adminFee = fee.multiplyDecimal(adminFeeRate);
            totalAdminFee = totalAdminFee.add(adminFee);
            quoteBalance = oldQuote.sub(adminFee);
            emit LiquidityRemoved(msg.sender, lpIn, baseOut, 0, fee, adminFee, oraclePrice);
        }
        fund.trancheTransfer(baseTranche, msg.sender, baseOut, version);
    }

    /// @dev Remove quote liquidity only.
    /// @param lpIn Exact amount of LP token to burn
    /// @param minQuoteOut Least amount of quote asset to withdraw
    function removeQuoteLiquidity(
        uint256 version,
        uint256 lpIn,
        uint256 minQuoteOut
    )
        external
        override
        nonReentrant
        checkVersion(version)
        whenNotPaused
        returns (uint256 quoteOut)
    {
        quoteOut = _removeQuoteLiquidity(version, lpIn, minQuoteOut);
        IERC20(quoteAddress).safeTransfer(msg.sender, quoteOut);
    }

    /// @dev Remove quote liquidity only and unwrap for native token.
    /// @param lpIn Exact amount of LP token to burn
    /// @param minQuoteOut Least amount of quote asset to withdraw
    function removeQuoteLiquidityUnwrap(
        uint256 version,
        uint256 lpIn,
        uint256 minQuoteOut
    )
        external
        override
        nonReentrant
        checkVersion(version)
        whenNotPaused
        returns (uint256 quoteOut)
    {
        quoteOut = _removeQuoteLiquidity(version, lpIn, minQuoteOut);
        IWrappedERC20(quoteAddress).withdraw(quoteOut);
        (bool success, ) = msg.sender.call{value: quoteOut}("");
        require(success, "Transfer failed");
    }

    function _removeQuoteLiquidity(
        uint256 version,
        uint256 lpIn,
        uint256 minQuoteOut
    ) private returns (uint256 quoteOut) {
        (uint256 oldBase, uint256 oldQuote) = _handleRebalance(version);
        uint256 lpSupply = IERC20(lpToken).totalSupply();
        uint256 ampl = getAmpl();
        uint256 oraclePrice = getOraclePrice();
        uint256 d1;
        {
            uint256 d0 = _getD(oldBase, oldQuote, ampl, oraclePrice);
            _updatePriceOverOracleIntegral(oldBase, oldQuote, ampl, oraclePrice, d0);
            d1 = d0.sub(d0.mul(lpIn).div(lpSupply));
        }
        uint256 idealQuote = oldQuote.mul(lpSupply.sub(lpIn)).div(lpSupply);
        // Add 1 in case of rounding errors
        uint256 newQuote = _getQuote(ampl, oldBase, oraclePrice, d1) + 1;
        uint256 fee = idealQuote.sub(newQuote).multiplyDecimal(feeRate);
        quoteOut = oldQuote.sub(newQuote).sub(fee);
        require(quoteOut >= minQuoteOut, "Insufficient output");
        ILiquidityGauge(lpToken).burnFrom(msg.sender, lpIn);
        uint256 adminFee = fee.multiplyDecimal(adminFeeRate);
        totalAdminFee = totalAdminFee.add(adminFee);
        quoteBalance = newQuote.add(fee).sub(adminFee);
        emit LiquidityRemoved(msg.sender, lpIn, 0, quoteOut, fee, adminFee, oraclePrice);
    }

    /// @notice Force stored values to match balances.
    function sync() external nonReentrant {
        (uint256 oldBase, uint256 oldQuote) = _handleRebalance(fund.getRebalanceSize());
        uint256 ampl = getAmpl();
        uint256 oraclePrice = getOraclePrice();
        uint256 d = _getD(oldBase, oldQuote, ampl, oraclePrice);
        _updatePriceOverOracleIntegral(oldBase, oldQuote, ampl, oraclePrice, d);
        uint256 newBase = fund.trancheBalanceOf(baseTranche, address(this));
        uint256 newQuote = _getNewQuoteBalance();
        baseBalance = newBase;
        quoteBalance = newQuote;
        emit Sync(newBase, newQuote, oraclePrice);
    }

    function collectFee() external {
        IERC20(quoteAddress).safeTransfer(feeCollector, totalAdminFee);
        delete totalAdminFee;
    }

    function _getNewQuoteBalance() private view returns (uint256) {
        return IERC20(quoteAddress).balanceOf(address(this)).sub(totalAdminFee);
    }

    function _updatePriceOverOracleIntegral(
        uint256 base,
        uint256 quote,
        uint256 ampl,
        uint256 oraclePrice,
        uint256 d
    ) private {
        // Overflow is desired
        _priceOverOracleIntegral +=
            _getPriceOverOracle(base, quote, ampl, oraclePrice, d) *
            (block.timestamp - _priceOverOracleTimestamp);
        _priceOverOracleTimestamp = block.timestamp;
    }

    function _getD(
        uint256 base,
        uint256 quote,
        uint256 ampl,
        uint256 oraclePrice
    ) private view returns (uint256) {
        // Newtonian: D' = (4A(kx + y) + D^3 / 2kxy)D / ((4A - 1)D + 3D^3 / 4kxy)
        uint256 normalizedQuote = quote.mul(_quoteDecimalMultiplier);
        uint256 baseValue = base.multiplyDecimal(oraclePrice);
        uint256 sum = baseValue.add(normalizedQuote);
        if (sum == 0) return 0;

        uint256 prev = 0;
        uint256 d = sum;
        for (uint256 i = 0; i < MAX_ITERATION; i++) {
            prev = d;
            uint256 d3 = d.mul(d).div(baseValue).mul(d) / normalizedQuote / 4;
            d = (sum.mul(4 * ampl) + 2 * d3).mul(d) / d.mul(4 * ampl - 1).add(3 * d3);
            if (d <= prev + 1 && prev <= d + 1) {
                break;
            }
        }
        return d;
    }

    function _getPriceOverOracle(
        uint256 base,
        uint256 quote,
        uint256 ampl,
        uint256 oraclePrice,
        uint256 d
    ) private view returns (uint256) {
        uint256 commonExp = d.multiplyDecimal(4e18 - 1e18 / ampl);
        uint256 baseValue = base.multiplyDecimal(oraclePrice);
        uint256 normalizedQuote = quote.mul(_quoteDecimalMultiplier);
        return
            (baseValue.mul(8).add(normalizedQuote.mul(4)).sub(commonExp))
                .multiplyDecimal(normalizedQuote)
                .divideDecimal(normalizedQuote.mul(8).add(baseValue.mul(4)).sub(commonExp))
                .divideDecimal(baseValue);
    }

    function _getBase(
        uint256 ampl,
        uint256 quote,
        uint256 oraclePrice,
        uint256 d
    ) private view returns (uint256 base) {
        // Solve 16Ayk^2·x^2 + 4ky(4Ay - 4AD + D)·x - D^3 = 0
        // Newtonian: kx' = ((kx)^2 + D^3 / 16Ay) / (2kx + y - D + D/4A)
        uint256 normalizedQuote = quote.mul(_quoteDecimalMultiplier);
        uint256 d3 = d.mul(d).div(normalizedQuote).mul(d) / (16 * ampl);
        uint256 prev = 0;
        uint256 baseValue = d;
        for (uint256 i = 0; i < MAX_ITERATION; i++) {
            prev = baseValue;
            baseValue =
                baseValue.mul(baseValue).add(d3) /
                (2 * baseValue).add(normalizedQuote).add(d / (4 * ampl)).sub(d);
            if (baseValue <= prev + 1 && prev <= baseValue + 1) {
                break;
            }
        }
        base = baseValue.divideDecimal(oraclePrice);
    }

    function _getQuote(
        uint256 ampl,
        uint256 base,
        uint256 oraclePrice,
        uint256 d
    ) private view returns (uint256 quote) {
        // Solve 16Axk·y^2 + 4kx(4Akx - 4AD + D)·y - D^3 = 0
        // Newtonian: y' = (y^2 + D^3 / 16Akx) / (2y + kx - D + D/4A)
        uint256 baseValue = base.multiplyDecimal(oraclePrice);
        uint256 d3 = d.mul(d).div(baseValue).mul(d) / (16 * ampl);
        uint256 prev = 0;
        uint256 normalizedQuote = d;
        for (uint256 i = 0; i < MAX_ITERATION; i++) {
            prev = normalizedQuote;
            normalizedQuote =
                normalizedQuote.mul(normalizedQuote).add(d3) /
                (2 * normalizedQuote).add(baseValue).add(d / (4 * ampl)).sub(d);
            if (normalizedQuote <= prev + 1 && prev <= normalizedQuote + 1) {
                break;
            }
        }
        quote = normalizedQuote / _quoteDecimalMultiplier;
    }

    function updateAmplRamp(uint256 endAmpl, uint256 endTimestamp) external onlyOwner {
        require(endAmpl > 0 && endAmpl < AMPL_MAX_VALUE, "Invalid A");
        require(endTimestamp >= block.timestamp + AMPL_RAMP_MIN_TIME, "A ramp time too short");
        uint256 ampl = getAmpl();
        require(
            (endAmpl >= ampl && endAmpl <= ampl * AMPL_RAMP_MAX_CHANGE) ||
                (endAmpl < ampl && endAmpl * AMPL_RAMP_MAX_CHANGE >= ampl),
            "A ramp change too large"
        );
        amplRampStart = ampl;
        amplRampEnd = endAmpl;
        amplRampStartTimestamp = block.timestamp;
        amplRampEndTimestamp = endTimestamp;
        emit AmplRampUpdated(ampl, endAmpl, block.timestamp, endTimestamp);
    }

    function _updateFeeCollector(address newFeeCollector) private {
        feeCollector = newFeeCollector;
        emit FeeCollectorUpdated(newFeeCollector);
    }

    function updateFeeCollector(address newFeeCollector) external onlyOwner {
        _updateFeeCollector(newFeeCollector);
    }

    function _updateFeeRate(uint256 newFeeRate) private {
        require(newFeeRate <= MAX_FEE_RATE, "Exceed max fee rate");
        feeRate = newFeeRate;
        emit FeeRateUpdated(newFeeRate);
    }

    function updateFeeRate(uint256 newFeeRate) external onlyOwner {
        _updateFeeRate(newFeeRate);
    }

    function _updateAdminFeeRate(uint256 newAdminFeeRate) private {
        require(newAdminFeeRate <= MAX_ADMIN_FEE_RATE, "Exceed max admin fee rate");
        adminFeeRate = newAdminFeeRate;
        emit AdminFeeRateUpdated(newAdminFeeRate);
    }

    function updateAdminFeeRate(uint256 newAdminFeeRate) external onlyOwner {
        _updateAdminFeeRate(newAdminFeeRate);
    }

    /// @dev Check if the user-specified version is correct.
    modifier checkVersion(uint256 version) virtual {_;}

    /// @dev Compute the new base and quote amount after rebalanced to the latest version.
    ///      If any tokens should be distributed to LP holders, their amounts are also returned.
    ///
    ///      The latest rebalance version is passed in a parameter and it is caller's responsibility
    ///      to pass the correct version.
    /// @param latestVersion The latest rebalance version
    /// @return newBase Amount of base tokens after rebalance
    /// @return newQuote Amount of quote tokens after rebalance
    /// @return excessiveQ Amount of QUEEN that should be distributed to LP holders due to rebalance
    /// @return excessiveB Amount of BISHOP that should be distributed to LP holders due to rebalance
    /// @return excessiveR Amount of ROOK that should be distributed to LP holders due to rebalance
    /// @return excessiveQuote Amount of quote tokens that should be distributed to LP holders due to rebalance
    /// @return isRebalanced Whether the stored base and quote amount are rebalanced
    function _getRebalanceResult(uint256 latestVersion)
        internal
        view
        virtual
        returns (
            uint256 newBase,
            uint256 newQuote,
            uint256 excessiveQ,
            uint256 excessiveB,
            uint256 excessiveR,
            uint256 excessiveQuote,
            bool isRebalanced
        );

    /// @dev Update the stored base and quote balance to the latest rebalance version and distribute
    ///      any excessive tokens to LP holders.
    ///
    ///      The latest rebalance version is passed in a parameter and it is caller's responsibility
    ///      to pass the correct version.
    /// @param latestVersion The latest rebalance version
    /// @return newBase Amount of stored base tokens after rebalance
    /// @return newQuote Amount of stored quote tokens after rebalance
    function _handleRebalance(uint256 latestVersion)
        internal
        virtual
        returns (uint256 newBase, uint256 newQuote);

    /// @notice Get the base token price from the price oracle. The returned price is normalized
    ///         to 18 decimal places.
    function getOraclePrice() public view virtual override returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

interface ITranchessSwapCallee {
    function tranchessSwapCallback(
        uint256 baseDeltaOut,
        uint256 quoteDeltaOut,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWrappedERC20 is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

library AdvancedMath {
    /// @dev Calculate square root.
    ///
    ///      Reference: https://en.wikipedia.org/wiki/Integer_square_root#Algorithm_using_Newton's_method
    function sqrt(uint256 s) internal pure returns (uint256) {
        if (s == 0) return 0;
        uint256 t = s;
        uint256 x0 = 2;
        if (t >= 1 << 128) {
            t >>= 128;
            x0 <<= 64;
        }
        if (t >= 1 << 64) {
            t >>= 64;
            x0 <<= 32;
        }
        if (t >= 1 << 32) {
            t >>= 32;
            x0 <<= 16;
        }
        if (t >= 1 << 16) {
            t >>= 16;
            x0 <<= 8;
        }
        if (t >= 1 << 8) {
            t >>= 8;
            x0 <<= 4;
        }
        if (t >= 1 << 4) {
            t >>= 4;
            x0 <<= 2;
        }
        if (t >= 1 << 2) {
            x0 <<= 1;
        }
        uint256 x1 = (x0 + s / x0) >> 1;
        while (x1 < x0) {
            x0 = x1;
            x1 = (x0 + s / x0) >> 1;
        }
        return x0;
    }

    /// @notice Calculate cubic root.
    function cbrt(uint256 s) internal pure returns (uint256) {
        if (s == 0) return 0;
        uint256 t = s;
        uint256 x0 = 2;
        if (t >= 1 << 192) {
            t >>= 192;
            x0 <<= 64;
        }
        if (t >= 1 << 96) {
            t >>= 96;
            x0 <<= 32;
        }
        if (t >= 1 << 48) {
            t >>= 48;
            x0 <<= 16;
        }
        if (t >= 1 << 24) {
            t >>= 24;
            x0 <<= 8;
        }
        if (t >= 1 << 12) {
            t >>= 12;
            x0 <<= 4;
        }
        if (t >= 1 << 6) {
            t >>= 6;
            x0 <<= 2;
        }
        if (t >= 1 << 3) {
            x0 <<= 1;
        }
        uint256 x1 = (2 * x0 + s / x0 / x0) / 3;
        while (x1 < x0) {
            x0 = x1;
            x1 = (2 * x0 + s / x0 / x0) / 3;
        }
        return x0;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

import "../interfaces/IPrimaryMarketV3.sol";
import "../interfaces/ITrancheIndexV2.sol";
import "./StableSwap.sol";

contract BishopStableSwap is StableSwap, ITrancheIndexV2 {
    event Rebalanced(uint256 base, uint256 quote, uint256 version);

    uint256 public immutable tradingCurbThreshold;

    uint256 public currentVersion;

    constructor(
        address lpToken_,
        address fund_,
        address quoteAddress_,
        uint256 quoteDecimals_,
        uint256 ampl_,
        address feeCollector_,
        uint256 feeRate_,
        uint256 adminFeeRate_,
        uint256 tradingCurbThreshold_
    )
        public
        StableSwap(
            lpToken_,
            fund_,
            TRANCHE_B,
            quoteAddress_,
            quoteDecimals_,
            ampl_,
            feeCollector_,
            feeRate_,
            adminFeeRate_
        )
    {
        tradingCurbThreshold = tradingCurbThreshold_;
        currentVersion = IFundV3(fund_).getRebalanceSize();
    }

    /// @dev Make sure the user-specified version is the latest rebalance version.
    modifier checkVersion(uint256 version) override {
        require(version == fund.getRebalanceSize(), "Obsolete rebalance version");
        _;
    }

    function _getRebalanceResult(uint256 latestVersion)
        internal
        view
        override
        returns (
            uint256 newBase,
            uint256 newQuote,
            uint256 excessiveQ,
            uint256 excessiveB,
            uint256 excessiveR,
            uint256 excessiveQuote,
            bool isRebalanced
        )
    {
        if (latestVersion == currentVersion) {
            return (baseBalance, quoteBalance, 0, 0, 0, 0, false);
        }
        isRebalanced = true;

        uint256 oldBaseBalance = baseBalance;
        uint256 oldQuoteBalance = quoteBalance;
        (excessiveQ, newBase, ) = fund.batchRebalance(
            0,
            oldBaseBalance,
            0,
            currentVersion,
            latestVersion
        );
        if (newBase < oldBaseBalance) {
            // We split all QUEEN from rebalance if the amount of BISHOP is smaller than before.
            // In almost all cases, the total amount of BISHOP after the split is still smaller
            // than before.
            excessiveR = IPrimaryMarketV3(fund.primaryMarket()).getSplit(excessiveQ);
            newBase = newBase.add(excessiveR);
        }
        if (newBase < oldBaseBalance) {
            // If BISHOP amount is still smaller than before, we remove quote tokens proportionally.
            newQuote = oldQuoteBalance.mul(newBase).div(oldBaseBalance);
            excessiveQuote = oldQuoteBalance - newQuote;
        } else {
            // In most cases when we reach here, the BISHOP amount remains the same (ratioBR = 1).
            newQuote = oldQuoteBalance;
            excessiveB = newBase - oldBaseBalance;
            newBase = oldBaseBalance;
        }
    }

    function _handleRebalance(uint256 latestVersion)
        internal
        override
        returns (uint256 newBase, uint256 newQuote)
    {
        uint256 excessiveQ;
        uint256 excessiveB;
        uint256 excessiveR;
        uint256 excessiveQuote;
        bool isRebalanced;
        (
            newBase,
            newQuote,
            excessiveQ,
            excessiveB,
            excessiveR,
            excessiveQuote,
            isRebalanced
        ) = _getRebalanceResult(latestVersion);
        if (isRebalanced) {
            baseBalance = newBase;
            quoteBalance = newQuote;
            currentVersion = latestVersion;
            emit Rebalanced(newBase, newQuote, latestVersion);
            if (excessiveQ > 0) {
                if (excessiveR > 0) {
                    IPrimaryMarketV3(fund.primaryMarket()).split(
                        address(this),
                        excessiveQ,
                        latestVersion
                    );
                    excessiveQ = 0;
                } else {
                    fund.trancheTransfer(TRANCHE_Q, lpToken, excessiveQ, latestVersion);
                }
            }
            if (excessiveB > 0) {
                fund.trancheTransfer(TRANCHE_B, lpToken, excessiveB, latestVersion);
            }
            if (excessiveR > 0) {
                fund.trancheTransfer(TRANCHE_R, lpToken, excessiveR, latestVersion);
            }
            if (excessiveQuote > 0) {
                IERC20(quoteAddress).safeTransfer(lpToken, excessiveQuote);
            }
            ILiquidityGauge(lpToken).distribute(
                excessiveQ,
                excessiveB,
                excessiveR,
                excessiveQuote,
                latestVersion
            );
        }
    }

    function getOraclePrice() public view override returns (uint256) {
        uint256 price = fund.twapOracle().getLatest();
        (, uint256 navB, uint256 navR) = fund.extrapolateNav(price);
        require(navR >= navB.multiplyDecimal(tradingCurbThreshold), "Trading curb");
        return navB;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

interface IPrimaryMarketV3 {
    function fund() external view returns (address);

    function getCreation(uint256 underlying) external view returns (uint256 outQ);

    function getCreationForQ(uint256 minOutQ) external view returns (uint256 underlying);

    function getRedemption(uint256 inQ) external view returns (uint256 underlying, uint256 fee);

    function getRedemptionForUnderlying(uint256 minUnderlying) external view returns (uint256 inQ);

    function getSplit(uint256 inQ) external view returns (uint256 outB);

    function getSplitForB(uint256 minOutB) external view returns (uint256 inQ);

    function getMerge(uint256 inB) external view returns (uint256 outQ, uint256 feeQ);

    function getMergeForQ(uint256 minOutQ) external view returns (uint256 inB);

    function canBeRemovedFromFund() external view returns (bool);

    function create(
        address recipient,
        uint256 minOutQ,
        uint256 version
    ) external returns (uint256 outQ);

    function redeem(
        address recipient,
        uint256 inQ,
        uint256 minUnderlying,
        uint256 version
    ) external returns (uint256 underlying);

    function redeemAndUnwrap(
        address recipient,
        uint256 inQ,
        uint256 minUnderlying,
        uint256 version
    ) external returns (uint256 underlying);

    function queueRedemption(
        address recipient,
        uint256 inQ,
        uint256 minUnderlying,
        uint256 version
    ) external returns (uint256 underlying, uint256 index);

    function claimRedemptions(address account, uint256[] calldata indices)
        external
        returns (uint256 underlying);

    function claimRedemptionsAndUnwrap(address account, uint256[] calldata indices)
        external
        returns (uint256 underlying);

    function split(
        address recipient,
        uint256 inQ,
        uint256 version
    ) external returns (uint256 outB);

    function merge(
        address recipient,
        uint256 inB,
        uint256 version
    ) external returns (uint256 outQ);

    function settle(uint256 day) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";

import "../fund/ShareStaking.sol";

import "../interfaces/ITranchessSwapCallee.sol";
import "../interfaces/IPrimaryMarketV3.sol";
import "../interfaces/ISwapRouter.sol";
import "../interfaces/ITrancheIndexV2.sol";

/// @title Tranchess Flash Swap Router
/// @notice Router for stateless execution of flash swaps against Tranchess stable swaps
contract FlashSwapRouter is ITranchessSwapCallee, ITrancheIndexV2, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event SwapToggled(address externalRouter, bool enabled);
    event SwapRook(
        address indexed recipient,
        uint256 baseIn,
        uint256 quoteIn,
        uint256 baseOut,
        uint256 quoteOut
    );

    ISwapRouter public immutable tranchessRouter;
    mapping(address => bool) public externalRouterAllowlist;

    constructor(address tranchessRouter_) public {
        tranchessRouter = ISwapRouter(tranchessRouter_);
    }

    /// @dev Only meant for an off-chain client to call with eth_call.
    function getBuyR(
        IFundV3 fund,
        address queenSwapOrPrimaryMarketRouter,
        address tokenQuote,
        address externalRouter,
        address[] memory externalPath,
        uint256 outR
    ) external returns (uint256 quoteDelta, uint256 rookDelta) {
        uint256 underlyingAmount;
        uint256 totalQuoteAmount;
        {
            uint256 inQ = IPrimaryMarketV3(fund.primaryMarket()).getSplitForB(outR);
            underlyingAmount = IStableSwapCoreInternalRevertExpected(queenSwapOrPrimaryMarketRouter)
                .getQuoteIn(inQ);
            // Calculate the exact amount of quote asset to pay
            totalQuoteAmount = IUniswapV2Router01(externalRouter).getAmountsIn(
                underlyingAmount,
                externalPath
            )[0];
            // Calculate the amount of quote asset for selling BISHOP
            IStableSwap tranchessPair = tranchessRouter.getSwap(fund.tokenB(), tokenQuote);
            uint256 quoteAmount = tranchessPair.getQuoteOut(outR);
            // Calculate the user's portion of the payment to Tranchess swap
            quoteDelta = totalQuoteAmount.sub(quoteAmount);
            // Calculate the quote asset for underlying asset
            underlyingAmount = IUniswapV2Router01(externalRouter).getAmountsOut(
                totalQuoteAmount,
                externalPath
            )[externalPath.length - 1];
        }
        // Calculate creation of borrowed underlying for QUEEN
        uint256 outQ =
            IStableSwapCoreInternalRevertExpected(queenSwapOrPrimaryMarketRouter).getBaseOut(
                underlyingAmount
            );
        // Calculate the split result of QUEEN into BISHOP and ROOK
        rookDelta = IPrimaryMarketV3(fund.primaryMarket()).getSplit(outQ);
    }

    /// @dev Only meant for an off-chain client to call with eth_call.
    function getSellR(
        IFundV3 fund,
        address queenSwapOrPrimaryMarketRouter,
        address tokenQuote,
        address externalRouter,
        address[] memory externalPath,
        uint256 inR
    ) external returns (uint256 quoteDelta, uint256 rookDelta) {
        rookDelta = inR;
        uint256 quoteAmount =
            IStableSwap(tranchessRouter.getSwap(fund.tokenB(), tokenQuote)).getQuoteIn(inR);
        // Calculate merge result of BISHOP and ROOK into QUEEN
        (uint256 outQ, ) = IPrimaryMarketV3(fund.primaryMarket()).getMerge(inR);
        // Calculate the redemption from QUEEN to underlying
        uint256 underlyingAmount =
            IStableSwapCoreInternalRevertExpected(queenSwapOrPrimaryMarketRouter).getQuoteOut(outQ);
        // Calculate the underlying for quote asset
        uint256 totalQuoteAmount =
            IUniswapV2Router01(externalRouter).getAmountsOut(underlyingAmount, externalPath)[
                externalPath.length - 1
            ];
        // Calculate the rest of quote asset to user
        quoteDelta = totalQuoteAmount.sub(quoteAmount);
    }

    function toggleExternalRouter(address externalRouter) external onlyOwner {
        bool enabled = !externalRouterAllowlist[externalRouter];
        externalRouterAllowlist[externalRouter] = enabled;
        emit SwapToggled(externalRouter, enabled);
    }

    function buyR(
        IFundV3 fund,
        address queenSwapOrPrimaryMarketRouter,
        uint256 maxQuote,
        address recipient,
        address tokenQuote,
        address externalRouter,
        address[] memory externalPath,
        address staking,
        uint256 version,
        uint256 outR
    ) external {
        require(externalRouterAllowlist[externalRouter], "Invalid external router");
        uint256 underlyingAmount;
        uint256 totalQuoteAmount;
        bytes memory data;
        {
            uint256 inQ = IPrimaryMarketV3(fund.primaryMarket()).getSplitForB(outR);
            underlyingAmount = IStableSwapCoreInternalRevertExpected(queenSwapOrPrimaryMarketRouter)
                .getQuoteIn(inQ);
            // Calculate the exact amount of quote asset to pay
            totalQuoteAmount = IUniswapV2Router01(externalRouter).getAmountsIn(
                underlyingAmount,
                externalPath
            )[0];
            data = abi.encode(
                fund,
                queenSwapOrPrimaryMarketRouter,
                totalQuoteAmount,
                staking == address(0) ? recipient : staking,
                version,
                externalRouter,
                externalPath
            );
        }
        // Arrange the stable swap path
        IStableSwap tranchessPair = tranchessRouter.getSwap(fund.tokenB(), tokenQuote);
        address recipient_ = recipient;
        address tokenQuote_ = tokenQuote;
        // Calculate the amount of quote asset for selling BISHOP
        uint256 quoteAmount = tranchessPair.getQuoteOut(outR);
        // Send the user's portion of the payment to Tranchess swap
        uint256 resultAmount = totalQuoteAmount.sub(quoteAmount);
        require(resultAmount <= maxQuote, "Excessive input");
        IERC20(tokenQuote_).safeTransferFrom(msg.sender, address(this), resultAmount);
        tranchessPair.sell(version, quoteAmount, address(this), data);
        if (staking != address(0)) {
            ShareStaking(staking).deposit(TRANCHE_R, outR, recipient_, version);
        }
        emit SwapRook(recipient_, 0, resultAmount, outR, 0);
    }

    function sellR(
        IFundV3 fund,
        address queenSwapOrPrimaryMarketRouter,
        uint256 minQuote,
        address recipient,
        address tokenQuote,
        address externalRouter,
        address[] memory externalPath,
        uint256 version,
        uint256 inR
    ) external {
        require(externalRouterAllowlist[externalRouter], "Invalid external router");
        // Send the user's ROOK to this router
        fund.trancheTransferFrom(TRANCHE_R, msg.sender, address(this), inR, version);
        bytes memory data =
            abi.encode(
                fund,
                queenSwapOrPrimaryMarketRouter,
                minQuote,
                recipient,
                version,
                externalRouter,
                externalPath
            );
        tranchessRouter.getSwap(fund.tokenB(), tokenQuote).buy(version, inR, address(this), data);
    }

    function tranchessSwapCallback(
        uint256 baseOut,
        uint256 quoteOut,
        bytes calldata data
    ) external override {
        (
            IFundV3 fund,
            address queenSwapOrPrimaryMarketRouter,
            uint256 expectQuoteAmount,
            address recipient,
            uint256 version,
            ,

        ) = abi.decode(data, (IFundV3, address, uint256, address, uint256, address, address[]));
        address tokenQuote = IStableSwap(msg.sender).quoteAddress();
        require(
            msg.sender == address(tranchessRouter.getSwap(tokenQuote, fund.tokenB())),
            "Tranchess Pair check failed"
        );
        if (baseOut > 0) {
            uint256 resultAmount;
            {
                require(quoteOut == 0, "Unidirectional check failed");
                uint256 quoteAmount = IStableSwap(msg.sender).getQuoteIn(baseOut);
                // Merge BISHOP and ROOK into QUEEN
                uint256 outQ =
                    IPrimaryMarketV3(fund.primaryMarket()).merge(
                        queenSwapOrPrimaryMarketRouter,
                        baseOut,
                        version
                    );

                // Redeem or swap QUEEN for underlying
                uint256 underlyingAmount =
                    IStableSwapCoreInternalRevertExpected(queenSwapOrPrimaryMarketRouter)
                        .getQuoteOut(outQ);
                underlyingAmount = IStableSwapCoreInternalRevertExpected(
                    queenSwapOrPrimaryMarketRouter
                )
                    .sell(version, underlyingAmount, address(this), "");

                // Trade underlying for quote asset
                uint256 totalQuoteAmount =
                    _externalSwap(data, underlyingAmount, fund.tokenUnderlying(), tokenQuote);
                // Send back quote asset to tranchess swap
                IERC20(tokenQuote).safeTransfer(msg.sender, quoteAmount);
                // Send the rest of quote asset to user
                resultAmount = totalQuoteAmount.sub(quoteAmount);
                require(resultAmount >= expectQuoteAmount, "Insufficient output");
                IERC20(tokenQuote).safeTransfer(recipient, resultAmount);
            }
            emit SwapRook(recipient, baseOut, 0, 0, resultAmount);
        } else {
            address tokenUnderlying = fund.tokenUnderlying();
            // Trade quote asset for underlying asset
            uint256 underlyingAmount =
                _externalSwap(data, expectQuoteAmount, tokenQuote, tokenUnderlying);

            // Create or swap borrowed underlying for QUEEN
            uint256 outQ =
                IStableSwapCoreInternalRevertExpected(queenSwapOrPrimaryMarketRouter).getBaseOut(
                    underlyingAmount
                );
            IERC20(tokenUnderlying).safeTransfer(queenSwapOrPrimaryMarketRouter, underlyingAmount);
            outQ = IStableSwapCoreInternalRevertExpected(queenSwapOrPrimaryMarketRouter).buy(
                version,
                outQ,
                address(this),
                ""
            );

            // Split QUEEN into BISHOP and ROOK
            uint256 outB =
                IPrimaryMarketV3(fund.primaryMarket()).split(address(this), outQ, version);
            // Send back BISHOP to tranchess swap
            fund.trancheTransfer(TRANCHE_B, msg.sender, outB, version);
            // Send ROOK to user
            fund.trancheTransfer(TRANCHE_R, recipient, outB, version);
        }
    }

    function _externalSwap(
        bytes memory data,
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) private returns (uint256 amountOut) {
        (, , , , , address externalRouter, address[] memory externalPath) =
            abi.decode(data, (address, address, uint256, address, uint256, address, address[]));
        require(externalPath.length > 1, "Invalid external path");
        require(externalPath[0] == tokenIn, "Invalid token in");
        require(externalPath[externalPath.length - 1] == tokenOut, "Invalid token out");
        IERC20(tokenIn).safeApprove(externalRouter, amountIn);
        amountOut = IUniswapV2Router01(externalRouter).swapExactTokensForTokens(
            amountIn,
            0,
            externalPath,
            address(this),
            block.timestamp
        )[externalPath.length - 1];
    }
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../utils/SafeDecimalMath.sol";
import "../utils/CoreUtility.sol";

import "../interfaces/IFundV3.sol";
import "../interfaces/IChessController.sol";
import "../interfaces/IChessSchedule.sol";
import "../interfaces/ITrancheIndexV2.sol";
import "../interfaces/IVotingEscrow.sol";

contract ShareStaking is ITrancheIndexV2, CoreUtility {
    using Math for uint256;
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;
    using SafeERC20 for IERC20;

    event Deposited(uint256 tranche, address account, uint256 amount);
    event Withdrawn(uint256 tranche, address account, uint256 amount);

    uint256 private constant MAX_ITERATIONS = 500;

    uint256 private constant REWARD_WEIGHT_B = 2;
    uint256 private constant REWARD_WEIGHT_R = 1;
    uint256 private constant REWARD_WEIGHT_Q = 3;
    uint256 private constant MAX_BOOSTING_FACTOR = 3e18;
    uint256 private constant MAX_BOOSTING_FACTOR_MINUS_ONE = MAX_BOOSTING_FACTOR - 1e18;

    IFundV3 public immutable fund;

    /// @notice The Chess release schedule contract.
    IChessSchedule public immutable chessSchedule;

    /// @notice The controller contract.
    IChessController public immutable chessController;

    IVotingEscrow private immutable _votingEscrow;

    /// @notice Timestamp when rewards start.
    uint256 public immutable rewardStartTimestamp;

    /// @dev Per-fund CHESS emission rate. The product of CHESS emission rate
    ///      and weekly percentage of the fund
    uint256 private _rate;

    /// @dev Total amount of user shares, i.e. sum of all entries in `_balances`.
    uint256[TRANCHE_COUNT] private _totalSupplies;

    /// @dev Rebalance version of `_totalSupplies`.
    uint256 private _totalSupplyVersion;

    /// @dev Amount of shares staked by each user.
    mapping(address => uint256[TRANCHE_COUNT]) private _balances;

    /// @dev Rebalance version mapping for `_balances`.
    mapping(address => uint256) private _balanceVersions;

    /// @dev Mapping of rebalance version => split ratio.
    mapping(uint256 => uint256) private _historicalSplitRatio;

    /// @dev 1e27 * ∫(rate(t) / totalWeight(t) dt) from the latest rebalance till checkpoint.
    uint256 private _invTotalWeightIntegral;

    /// @dev Final `_invTotalWeightIntegral` before each rebalance.
    ///      These values are accessed in a loop in `_userCheckpoint()` with bounds checking.
    ///      So we store them in a fixed-length array, in order to make compiler-generated
    ///      bounds checking on every access cheaper. The actual length of this array is stored in
    ///      `_historicalIntegralSize` and should be explicitly checked when necessary.
    uint256[65535] private _historicalIntegrals;

    /// @dev Actual length of the `_historicalIntegrals` array, which always equals to the number of
    ///      historical rebalances after `checkpoint()` is called.
    uint256 private _historicalIntegralSize;

    /// @dev Timestamp when checkpoint() is called.
    uint256 private _checkpointTimestamp;

    /// @dev Snapshot of `_invTotalWeightIntegral` per user.
    mapping(address => uint256) private _userIntegrals;

    /// @dev Mapping of account => claimable rewards.
    mapping(address => uint256) private _claimableRewards;

    uint256 private _workingSupply;
    mapping(address => uint256) private _workingBalances;

    constructor(
        address fund_,
        address chessSchedule_,
        address chessController_,
        address votingEscrow_,
        uint256 rewardStartTimestamp_
    ) public {
        fund = IFundV3(fund_);
        chessSchedule = IChessSchedule(chessSchedule_);
        chessController = IChessController(chessController_);
        _votingEscrow = IVotingEscrow(votingEscrow_);
        rewardStartTimestamp = rewardStartTimestamp_;
        _checkpointTimestamp = block.timestamp;
    }

    function getRate() external view returns (uint256) {
        return _rate / 1e18;
    }

    /// @notice Return weight of given balance with respect to rewards.
    /// @param amountQ Amount of QUEEN
    /// @param amountB Amount of BISHOP
    /// @param amountR Amount of ROOK
    /// @param splitRatio Split ratio
    /// @return Rewarding weight of the balance
    function weightedBalance(
        uint256 amountQ,
        uint256 amountB,
        uint256 amountR,
        uint256 splitRatio
    ) public pure returns (uint256) {
        return
            amountQ
                .mul(REWARD_WEIGHT_Q)
                .multiplyDecimal(splitRatio)
                .add(amountB.mul(REWARD_WEIGHT_B))
                .add(amountR.mul(REWARD_WEIGHT_R))
                .div(REWARD_WEIGHT_Q);
    }

    function totalSupply(uint256 tranche) external view returns (uint256) {
        uint256 totalSupplyQ = _totalSupplies[TRANCHE_Q];
        uint256 totalSupplyB = _totalSupplies[TRANCHE_B];
        uint256 totalSupplyR = _totalSupplies[TRANCHE_R];

        uint256 version = _totalSupplyVersion;
        uint256 rebalanceSize = _fundRebalanceSize();
        if (version < rebalanceSize) {
            (totalSupplyQ, totalSupplyB, totalSupplyR) = _fundBatchRebalance(
                totalSupplyQ,
                totalSupplyB,
                totalSupplyR,
                version,
                rebalanceSize
            );
        }

        if (tranche == TRANCHE_Q) {
            return totalSupplyQ;
        } else if (tranche == TRANCHE_B) {
            return totalSupplyB;
        } else {
            return totalSupplyR;
        }
    }

    function trancheBalanceOf(uint256 tranche, address account) external view returns (uint256) {
        uint256 amountQ = _balances[account][TRANCHE_Q];
        uint256 amountB = _balances[account][TRANCHE_B];
        uint256 amountR = _balances[account][TRANCHE_R];

        if (tranche == TRANCHE_Q) {
            if (amountQ == 0 && amountB == 0 && amountR == 0) return 0;
        } else if (tranche == TRANCHE_B) {
            if (amountB == 0) return 0;
        } else {
            if (amountR == 0) return 0;
        }

        uint256 version = _balanceVersions[account];
        uint256 rebalanceSize = _fundRebalanceSize();
        if (version < rebalanceSize) {
            (amountQ, amountB, amountR) = _fundBatchRebalance(
                amountQ,
                amountB,
                amountR,
                version,
                rebalanceSize
            );
        }

        if (tranche == TRANCHE_Q) {
            return amountQ;
        } else if (tranche == TRANCHE_B) {
            return amountB;
        } else {
            return amountR;
        }
    }

    function balanceVersion(address account) external view returns (uint256) {
        return _balanceVersions[account];
    }

    function workingSupply() external view returns (uint256) {
        uint256 version = _totalSupplyVersion;
        uint256 rebalanceSize = _fundRebalanceSize();
        if (version < rebalanceSize) {
            (uint256 totalSupplyQ, uint256 totalSupplyB, uint256 totalSupplyR) =
                _fundBatchRebalance(
                    _totalSupplies[TRANCHE_Q],
                    _totalSupplies[TRANCHE_B],
                    _totalSupplies[TRANCHE_R],
                    version,
                    rebalanceSize
                );
            return weightedBalance(totalSupplyQ, totalSupplyB, totalSupplyR, fund.splitRatio());
        } else {
            return _workingSupply;
        }
    }

    function workingBalanceOf(address account) external view returns (uint256) {
        uint256 version = _balanceVersions[account];
        uint256 rebalanceSize = _fundRebalanceSize();
        uint256 workingBalance = _workingBalances[account]; // gas saver
        if (version < rebalanceSize || workingBalance == 0) {
            uint256[TRANCHE_COUNT] storage balance = _balances[account];
            uint256 amountQ = balance[TRANCHE_Q];
            uint256 amountB = balance[TRANCHE_B];
            uint256 amountR = balance[TRANCHE_R];
            if (version < rebalanceSize) {
                (amountQ, amountB, amountR) = _fundBatchRebalance(
                    amountQ,
                    amountB,
                    amountR,
                    version,
                    rebalanceSize
                );
            }
            return weightedBalance(amountQ, amountB, amountR, fund.splitRatio());
        } else {
            return workingBalance;
        }
    }

    function _fundRebalanceSize() internal view returns (uint256) {
        return fund.getRebalanceSize();
    }

    function _fundDoRebalance(
        uint256 amountQ,
        uint256 amountB,
        uint256 amountR,
        uint256 index
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return fund.doRebalance(amountQ, amountB, amountR, index);
    }

    function _fundBatchRebalance(
        uint256 amountQ,
        uint256 amountB,
        uint256 amountR,
        uint256 fromIndex,
        uint256 toIndex
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return fund.batchRebalance(amountQ, amountB, amountR, fromIndex, toIndex);
    }

    /// @dev Stake share tokens. A user could send QUEEN before deposit().
    ///      The contract first measures how much tranche share it has received,
    ///      then transfer the rest from the user
    /// @param tranche Tranche of the share
    /// @param amount The amount to deposit
    /// @param recipient Address that receives deposit
    /// @param version The current rebalance version
    function deposit(
        uint256 tranche,
        uint256 amount,
        address recipient,
        uint256 version
    ) external {
        _checkpoint(version);
        _userCheckpoint(recipient, version);
        _balances[recipient][tranche] = _balances[recipient][tranche].add(amount);
        uint256 oldTotalSupply = _totalSupplies[tranche];
        _totalSupplies[tranche] = oldTotalSupply.add(amount);
        _updateWorkingBalance(recipient, version);
        uint256 spareAmount = fund.trancheBalanceOf(tranche, address(this)).sub(oldTotalSupply);
        if (spareAmount < amount) {
            // Retain the rest of share token (version is checked by the fund)
            fund.trancheTransferFrom(
                tranche,
                msg.sender,
                address(this),
                amount - spareAmount,
                version
            );
        } else {
            require(version == _fundRebalanceSize(), "Invalid version");
        }
        emit Deposited(tranche, recipient, amount);
    }

    /// @notice Unstake tranche tokens.
    /// @param tranche Tranche of the share
    /// @param amount The amount to withdraw
    /// @param version The current rebalance version
    function withdraw(
        uint256 tranche,
        uint256 amount,
        uint256 version
    ) external {
        _checkpoint(version);
        _userCheckpoint(msg.sender, version);
        _balances[msg.sender][tranche] = _balances[msg.sender][tranche].sub(
            amount,
            "Insufficient balance to withdraw"
        );
        _totalSupplies[tranche] = _totalSupplies[tranche].sub(amount);
        _updateWorkingBalance(msg.sender, version);
        // version is checked by the fund
        fund.trancheTransfer(tranche, msg.sender, amount, version);
        emit Withdrawn(tranche, msg.sender, amount);
    }

    /// @notice Transform share balance to a given rebalance version, or to the latest version
    ///         if `targetVersion` is zero.
    /// @param account Account of the balance to rebalance
    /// @param targetVersion The target rebalance version, or zero for the latest version
    function refreshBalance(address account, uint256 targetVersion) external {
        uint256 rebalanceSize = _fundRebalanceSize();
        if (targetVersion == 0) {
            targetVersion = rebalanceSize;
        } else {
            require(targetVersion <= rebalanceSize, "Target version out of bound");
        }
        _checkpoint(rebalanceSize);
        _userCheckpoint(account, targetVersion);
    }

    /// @notice Return claimable rewards of an account till now.
    ///
    ///         This function should be call as a "view" function off-chain to get
    ///         the return value, e.g. using `contract.claimableRewards.call(account)` in web3
    ///         or `contract.callStatic.claimableRewards(account)` in ethers.js.
    /// @param account Address of an account
    /// @return Amount of claimable rewards
    function claimableRewards(address account) external returns (uint256) {
        uint256 rebalanceSize = _fundRebalanceSize();
        _checkpoint(rebalanceSize);
        _userCheckpoint(account, rebalanceSize);
        return _claimableRewards[account];
    }

    /// @notice Claim the rewards for an account.
    /// @param account Account to claim its rewards
    function claimRewards(address account) external {
        uint256 rebalanceSize = _fundRebalanceSize();
        _checkpoint(rebalanceSize);
        _userCheckpoint(account, rebalanceSize);
        uint256 amount = _claimableRewards[account];
        _claimableRewards[account] = 0;
        chessSchedule.mint(account, amount);
        _updateWorkingBalance(account, rebalanceSize);
    }

    /// @notice Synchronize an account's locked Chess with `VotingEscrow`
    ///         and update its working balance.
    /// @param account Address of the synchronized account
    function syncWithVotingEscrow(address account) external {
        uint256 rebalanceSize = _fundRebalanceSize();
        _checkpoint(rebalanceSize);
        _userCheckpoint(account, rebalanceSize);
        _updateWorkingBalance(account, rebalanceSize);
    }

    /// @dev Transform total supplies to the latest rebalance version and make a global reward checkpoint.
    /// @param rebalanceSize The number of existing rebalances. It must be the same as
    ///                       `fund.getRebalanceSize()`.
    function _checkpoint(uint256 rebalanceSize) private {
        uint256 timestamp = _checkpointTimestamp;
        if (timestamp >= block.timestamp) {
            return;
        }

        uint256 integral = _invTotalWeightIntegral;
        uint256 endWeek = _endOfWeek(timestamp);
        uint256 version = _totalSupplyVersion;
        uint256 rebalanceTimestamp;
        if (version < rebalanceSize) {
            rebalanceTimestamp = fund.getRebalanceTimestamp(version);
        } else {
            rebalanceTimestamp = type(uint256).max;
        }
        uint256 rate = _rate;
        uint256 totalSupplyQ = _totalSupplies[TRANCHE_Q];
        uint256 totalSupplyB = _totalSupplies[TRANCHE_B];
        uint256 totalSupplyR = _totalSupplies[TRANCHE_R];
        uint256 weight = _workingSupply;
        uint256 timestamp_ = timestamp; // avoid stack too deep

        for (uint256 i = 0; i < MAX_ITERATIONS && timestamp_ < block.timestamp; i++) {
            uint256 endTimestamp = rebalanceTimestamp.min(endWeek).min(block.timestamp);

            if (weight > 0 && endTimestamp > rewardStartTimestamp) {
                integral = integral.add(
                    rate
                        .mul(endTimestamp.sub(timestamp_.max(rewardStartTimestamp)))
                        .decimalToPreciseDecimal()
                        .div(weight)
                );
            }

            if (endTimestamp == rebalanceTimestamp) {
                uint256 oldSize = _historicalIntegralSize;
                _historicalIntegrals[oldSize] = integral;
                _historicalIntegralSize = oldSize + 1;

                integral = 0;
                (totalSupplyQ, totalSupplyB, totalSupplyR) = _fundDoRebalance(
                    totalSupplyQ,
                    totalSupplyB,
                    totalSupplyR,
                    version
                );

                version++;
                {
                    // Reset total weight boosting after the first rebalance
                    uint256 splitRatio = fund.historicalSplitRatio(version);
                    weight = weightedBalance(totalSupplyQ, totalSupplyB, totalSupplyR, splitRatio);
                    _historicalSplitRatio[version] = splitRatio;
                }

                if (version < rebalanceSize) {
                    rebalanceTimestamp = fund.getRebalanceTimestamp(version);
                } else {
                    rebalanceTimestamp = type(uint256).max;
                }
            }
            if (endTimestamp == endWeek) {
                rate = chessSchedule.getRate(endWeek).mul(
                    chessController.getFundRelativeWeight(address(this), endWeek)
                );
                if (endWeek < rewardStartTimestamp && endWeek + 1 weeks > rewardStartTimestamp) {
                    // Rewards start in the middle of the next week. We adjust the rate to
                    // compensate for the period between `endWeek` and `rewardStartTimestamp`.
                    rate = rate.mul(1 weeks).div(endWeek + 1 weeks - rewardStartTimestamp);
                }
                endWeek += 1 weeks;
            }

            timestamp_ = endTimestamp;
        }

        _checkpointTimestamp = block.timestamp;
        _invTotalWeightIntegral = integral;
        _rate = rate;
        if (_totalSupplyVersion != rebalanceSize) {
            _totalSupplies[TRANCHE_Q] = totalSupplyQ;
            _totalSupplies[TRANCHE_B] = totalSupplyB;
            _totalSupplies[TRANCHE_R] = totalSupplyR;
            _totalSupplyVersion = rebalanceSize;
            // Reset total working weight before any boosting if rebalance ever triggered
            _workingSupply = weight;
        }
    }

    /// @dev Transform a user's balance to a given rebalance version and update this user's rewards.
    ///
    ///      In most cases, the target version is the latest version and this function cumulates
    ///      rewards till now. When this function is called from `refreshBalance()`,
    ///      `targetVersion` can be an older version, in which case rewards are cumulated till
    ///      the end of that version (i.e. timestamp of the transaction triggering the rebalance
    ///      with index `targetVersion`).
    ///
    ///      This function should always be called after `_checkpoint()` is called, so that
    ///      the global reward checkpoint is guarenteed up to date.
    /// @param account Account to update
    /// @param targetVersion The target rebalance version
    function _userCheckpoint(address account, uint256 targetVersion) private {
        uint256 oldVersion = _balanceVersions[account];
        if (oldVersion > targetVersion) {
            return;
        }
        uint256 userIntegral = _userIntegrals[account];
        uint256 integral;
        // This scope is to avoid the "stack too deep" error.
        {
            // We assume that this function is always called immediately after `_checkpoint()`,
            // which guarantees that `_historicalIntegralSize` equals to the number of historical
            // rebalances.
            uint256 rebalanceSize = _historicalIntegralSize;
            integral = targetVersion == rebalanceSize
                ? _invTotalWeightIntegral
                : _historicalIntegrals[targetVersion];
        }
        if (userIntegral == integral && oldVersion == targetVersion) {
            // Return immediately when the user's rewards have already been updated to
            // the target version.
            return;
        }

        uint256 rewards = _claimableRewards[account];
        uint256[TRANCHE_COUNT] storage balance = _balances[account];
        uint256 weight = _workingBalances[account];
        uint256 balanceQ = balance[TRANCHE_Q];
        uint256 balanceB = balance[TRANCHE_B];
        uint256 balanceR = balance[TRANCHE_R];
        for (uint256 i = oldVersion; i < targetVersion; i++) {
            rewards = rewards.add(
                weight.multiplyDecimalPrecise(_historicalIntegrals[i].sub(userIntegral))
            );
            if (balanceQ != 0 || balanceB != 0 || balanceR != 0) {
                (balanceQ, balanceB, balanceR) = _fundDoRebalance(balanceQ, balanceB, balanceR, i);
            }
            userIntegral = 0;

            // Reset per-user weight boosting after the first rebalance
            weight = weightedBalance(balanceQ, balanceB, balanceR, _historicalSplitRatio[i + 1]);
        }
        rewards = rewards.add(weight.multiplyDecimalPrecise(integral.sub(userIntegral)));
        address account_ = account; // Fix the "stack too deep" error
        _claimableRewards[account_] = rewards;
        _userIntegrals[account_] = integral;

        if (oldVersion < targetVersion) {
            balance[TRANCHE_Q] = balanceQ;
            balance[TRANCHE_B] = balanceB;
            balance[TRANCHE_R] = balanceR;
            _balanceVersions[account_] = targetVersion;
            _workingBalances[account_] = weight;
        }
    }

    /// @dev Calculate working balance, which depends on the amount of staked tokens and veCHESS.
    ///      Before this function is called, both `_checkpoint()` and `_userCheckpoint(account)`
    ///      should be called to update `_workingSupply` and `_workingBalances[account]` to
    ///      the latest rebalance version.
    /// @param account User address
    /// @param rebalanceSize The number of existing rebalances. It must be the same as
    ///                       `fund.getRebalanceSize()`.
    function _updateWorkingBalance(address account, uint256 rebalanceSize) private {
        uint256 splitRatio = _historicalSplitRatio[rebalanceSize];
        if (splitRatio == 0) {
            // Read it from the fund in case that it's not initialized yet, e.g. when we reach here
            // for the first time and `rebalanceSize` is zero.
            splitRatio = fund.historicalSplitRatio(rebalanceSize);
            _historicalSplitRatio[rebalanceSize] = splitRatio;
        }
        uint256 weightedSupply =
            weightedBalance(
                _totalSupplies[TRANCHE_Q],
                _totalSupplies[TRANCHE_B],
                _totalSupplies[TRANCHE_R],
                splitRatio
            );
        uint256[TRANCHE_COUNT] storage balance = _balances[account];
        uint256 newWorkingBalance =
            weightedBalance(balance[TRANCHE_Q], balance[TRANCHE_B], balance[TRANCHE_R], splitRatio);
        uint256 veBalance = _votingEscrow.balanceOf(account);
        if (veBalance > 0) {
            uint256 veTotalSupply = _votingEscrow.totalSupply();
            uint256 maxWorkingBalance = newWorkingBalance.multiplyDecimal(MAX_BOOSTING_FACTOR);
            uint256 boostedWorkingBalance =
                newWorkingBalance.add(
                    weightedSupply
                        .mul(veBalance)
                        .multiplyDecimal(MAX_BOOSTING_FACTOR_MINUS_ONE)
                        .div(veTotalSupply)
                );
            newWorkingBalance = maxWorkingBalance.min(boostedWorkingBalance);
        }

        _workingSupply = _workingSupply.sub(_workingBalances[account]).add(newWorkingBalance);
        _workingBalances[account] = newWorkingBalance;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "./IStableSwap.sol";

interface ISwapRouter {
    function getSwap(address baseToken, address quoteToken) external view returns (IStableSwap);

    function getAmountsOut(uint256 amount, address[] memory path)
        external
        view
        returns (
            uint256[] memory amounts,
            IStableSwap[] memory swaps,
            bool[] memory isBuy
        );

    function getAmountsIn(uint256 amount, address[] memory path)
        external
        view
        returns (
            uint256[] memory amounts,
            IStableSwap[] memory swaps,
            bool[] memory isBuy
        );

    function addLiquidity(
        address baseToken,
        address quoteToken,
        uint256 baseDelta,
        uint256 quoteDelta,
        uint256 minMintAmount,
        uint256 version,
        uint256 deadline
    ) external payable;

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 minAmountOut,
        address[] calldata path,
        address recipient,
        address staking,
        uint256[] calldata versions,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 maxAmountIn,
        address[] calldata path,
        address recipient,
        address staking,
        uint256[] calldata versions,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForTokensUnwrap(
        uint256 amountIn,
        uint256 minAmountOut,
        address[] calldata path,
        address recipient,
        uint256[] calldata versions,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokensUnwrap(
        uint256 amountOut,
        uint256 maxAmountIn,
        address[] calldata path,
        address recipient,
        uint256[] calldata versions,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-core/contracts/libraries/SafeCast.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import "@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol";

import "./FlashSwapRouter.sol";

/// @dev See IQuoterV2.sol under https://github.com/Uniswap/v3-periphery/
interface IUniswapV3QuoterV2 {
    struct QuoteExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
    }

    function quoteExactInputSingle(QuoteExactInputSingleParams memory params)
        external
        returns (
            uint256 amountOut,
            uint160 sqrtPriceX96After,
            uint32 initializedTicksCrossed,
            uint256 gasEstimate
        );

    struct QuoteExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint256 amountOut;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
    }

    function quoteExactOutputSingle(QuoteExactOutputSingleParams memory params)
        external
        returns (
            uint256 amountIn,
            uint160 sqrtPriceX96After,
            uint32 initializedTicksCrossed,
            uint256 gasEstimate
        );
}

/// @title Tranchess Flash Swap Router V2
/// @notice Router for stateless execution of flash swaps against Tranchess stable swaps
contract FlashSwapRouterV2 is FlashSwapRouter, IUniswapV3SwapCallback {
    using SafeMath for uint256;
    using SafeCast for uint256;
    using SafeERC20 for IERC20;

    struct InputParam {
        IFundV3 fund;
        address queenSwapOrPrimaryMarketRouter;
        uint256 resultBoundary;
        address recipient;
        address tokenQuote;
        uint24 externalPoolFee;
        address staking;
        uint256 version;
        uint256 amountR;
    }

    struct SwapCallbackData {
        InputParam inputs;
        address tokenUnderlying;
        PoolAddress.PoolKey poolKey;
        address payer;
    }

    address public immutable uniswapV3Factory;
    IUniswapV3QuoterV2 public immutable uniswapV3Quoter;

    constructor(
        address tranchessRouter_,
        address uniswapV3Factory_,
        address uniswapV3Quoter_
    ) public FlashSwapRouter(tranchessRouter_) {
        uniswapV3Factory = uniswapV3Factory_;
        uniswapV3Quoter = IUniswapV3QuoterV2(uniswapV3Quoter_);
    }

    /// @dev Only meant for an off-chain client to call with eth_call.
    ///      Note that `params.resultBoundary` is ignored.
    function getBuyRV2(InputParam memory params)
        external
        returns (uint256 quoteDelta, uint256 rookDelta)
    {
        // Calculate the exact amount of QUEEN
        uint256 inQ = IPrimaryMarketV3(params.fund.primaryMarket()).getSplitForB(params.amountR);
        // Calculate the exact amount of underlying asset
        uint256 underlyingAmount =
            IStableSwapCoreInternalRevertExpected(params.queenSwapOrPrimaryMarketRouter).getQuoteIn(
                inQ
            );
        // Calculate the exact amount of quote asset to pay
        (uint256 amountToPay, , , ) =
            uniswapV3Quoter.quoteExactOutputSingle(
                IUniswapV3QuoterV2.QuoteExactOutputSingleParams({
                    tokenIn: params.tokenQuote,
                    tokenOut: params.fund.tokenUnderlying(),
                    amountOut: underlyingAmount,
                    fee: params.externalPoolFee,
                    sqrtPriceLimitX96: 0
                })
            );
        // Calculate the QUEEN creation amount from underlying
        IStableSwapCoreInternalRevertExpected swapCore =
            IStableSwapCoreInternalRevertExpected(params.queenSwapOrPrimaryMarketRouter);
        uint256 outQ = swapCore.getBaseOut(underlyingAmount);
        // Get the amount of BISHOP and ROOK in split
        rookDelta = IPrimaryMarketV3(params.fund.primaryMarket()).getSplit(outQ);
        // Calculate the amount of quote from BISHOP sale
        IStableSwap tranchessPair =
            tranchessRouter.getSwap(params.fund.tokenB(), params.tokenQuote);
        uint256 quoteAmount = tranchessPair.getQuoteOut(rookDelta);
        // Subtract the amount of quote asset fulfilled by BISHOP sale
        quoteDelta = amountToPay.sub(quoteAmount);
    }

    /// @dev Only meant for an off-chain client to call with eth_call.
    ///      Note that `params.resultBoundary` is ignored.
    function getSellRV2(InputParam memory params)
        external
        returns (uint256 quoteDelta, uint256 rookDelta)
    {
        rookDelta = params.amountR;
        // Calculate the exact amount of QUEEN
        (uint256 outQ, ) = IPrimaryMarketV3(params.fund.primaryMarket()).getMerge(params.amountR);
        // Calculate the exact amount of underlying asset to pay
        uint256 underlyingAmount =
            IStableSwapCoreInternalRevertExpected(params.queenSwapOrPrimaryMarketRouter)
                .getQuoteOut(outQ);
        // Calculate the exact amount of quote asset to pay
        (uint256 amountToSend, , , ) =
            uniswapV3Quoter.quoteExactInputSingle(
                IUniswapV3QuoterV2.QuoteExactInputSingleParams({
                    tokenIn: params.fund.tokenUnderlying(),
                    tokenOut: params.tokenQuote,
                    amountIn: underlyingAmount,
                    fee: params.externalPoolFee,
                    sqrtPriceLimitX96: 0
                })
            );
        // Calculate the amount of quote needed for BISHOP
        IStableSwap tranchessPair =
            tranchessRouter.getSwap(params.fund.tokenB(), params.tokenQuote);
        uint256 quoteAmount = tranchessPair.getQuoteIn(params.amountR);
        // Subtract the amount of quote asset used to buy BISHOP
        quoteDelta = amountToSend.sub(quoteAmount);
    }

    function buyRV2(InputParam memory params) external {
        // Calculate the exact amount of QUEEN
        uint256 inQ = IPrimaryMarketV3(params.fund.primaryMarket()).getSplitForB(params.amountR);
        // Calculate the exact amount of underlying asset
        uint256 underlyingAmount =
            IStableSwapCoreInternalRevertExpected(params.queenSwapOrPrimaryMarketRouter).getQuoteIn(
                inQ
            );

        address tokenUnderlying = params.fund.tokenUnderlying();
        PoolAddress.PoolKey memory poolKey =
            PoolAddress.getPoolKey(tokenUnderlying, params.tokenQuote, params.externalPoolFee);
        IUniswapV3Pool pool = IUniswapV3Pool(PoolAddress.computeAddress(uniswapV3Factory, poolKey));
        bytes memory data = abi.encode(params, tokenUnderlying, poolKey, msg.sender);
        bool zeroForOne = params.tokenQuote == poolKey.token0;

        pool.swap(
            params.queenSwapOrPrimaryMarketRouter,
            zeroForOne,
            -underlyingAmount.toInt256(),
            zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1,
            data
        );
    }

    function sellRV2(InputParam memory params) external {
        // Transfer user's ROOK to this router
        params.fund.trancheTransferFrom(
            TRANCHE_R,
            msg.sender,
            address(this),
            params.amountR,
            params.version
        );

        // Calculate the exact amount of QUEEN
        (uint256 outQ, ) = IPrimaryMarketV3(params.fund.primaryMarket()).getMerge(params.amountR);
        // Calculate the exact amount of underlying asset to pay
        uint256 underlyingAmount =
            IStableSwapCoreInternalRevertExpected(params.queenSwapOrPrimaryMarketRouter)
                .getQuoteOut(outQ);

        address tokenUnderlying = params.fund.tokenUnderlying();
        PoolAddress.PoolKey memory poolKey =
            PoolAddress.getPoolKey(tokenUnderlying, params.tokenQuote, params.externalPoolFee);
        IUniswapV3Pool pool = IUniswapV3Pool(PoolAddress.computeAddress(uniswapV3Factory, poolKey));
        bytes memory data = abi.encode(params, tokenUnderlying, poolKey, msg.sender);
        bool zeroForOne = params.tokenQuote == poolKey.token1;

        pool.swap(
            address(this),
            zeroForOne,
            underlyingAmount.toInt256(), // Exact input
            zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1,
            data
        );
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external override {
        require(amount0Delta > 0 || amount1Delta > 0); // swaps entirely within 0-liquidity regions are not supported

        SwapCallbackData memory params = abi.decode(data, (SwapCallbackData));

        // Ensure that the pool is the one we expect
        address pool = PoolAddress.computeAddress(uniswapV3Factory, params.poolKey);
        require(msg.sender == pool);

        (address paymentToken, uint256 amountToPay, uint256 amountOut) =
            amount0Delta > 0
                ? (params.poolKey.token0, uint256(amount0Delta), uint256(-amount1Delta))
                : (params.poolKey.token1, uint256(amount1Delta), uint256(-amount0Delta));

        if (paymentToken == params.inputs.tokenQuote) {
            // Create or swap borrowed underlying for QUEEN
            IStableSwapCoreInternalRevertExpected swapCore =
                IStableSwapCoreInternalRevertExpected(params.inputs.queenSwapOrPrimaryMarketRouter);
            uint256 outQ = swapCore.getBaseOut(amountOut);
            outQ = swapCore.buy(params.inputs.version, outQ, address(this), "");
            // Split QUEEN into BISHOP and ROOK
            uint256 outB =
                IPrimaryMarketV3(params.inputs.fund.primaryMarket()).split(
                    address(this),
                    outQ,
                    params.inputs.version
                );
            // Arrange the stable swap path
            IStableSwap tranchessPair =
                tranchessRouter.getSwap(params.inputs.fund.tokenB(), params.inputs.tokenQuote);
            // Sell BISHOP to tranchess swap for quote asset
            uint256 quoteAmount = tranchessPair.getQuoteOut(outB);
            // Calculate the amount of quote asset for selling BISHOP, paying back part of the flashloan
            params.inputs.fund.trancheTransfer(
                TRANCHE_B,
                address(tranchessPair),
                outB,
                params.inputs.version
            );
            tranchessPair.sell(params.inputs.version, quoteAmount, msg.sender, "");
            // Send ROOK to recipient
            params.inputs.fund.trancheTransfer(
                TRANCHE_R,
                params.inputs.staking == address(0)
                    ? params.inputs.recipient
                    : params.inputs.staking,
                outB,
                params.inputs.version
            );
            if (params.inputs.staking != address(0)) {
                ShareStaking(params.inputs.staking).deposit(
                    TRANCHE_R,
                    outB,
                    params.inputs.recipient,
                    params.inputs.version
                );
            }
            // Pay back rest of the flashloan out of user pocket
            require(
                amountToPay.sub(quoteAmount) <= params.inputs.resultBoundary,
                "Excessive input"
            );
            IERC20(paymentToken).safeTransferFrom(
                params.payer,
                msg.sender,
                amountToPay - quoteAmount
            );
            emit SwapRook(params.inputs.recipient, 0, amountToPay - quoteAmount, outB, 0);
        } else if (paymentToken == params.tokenUnderlying) {
            // Arrange the stable swap path
            IStableSwap tranchessPair =
                tranchessRouter.getSwap(params.inputs.fund.tokenB(), params.inputs.tokenQuote);
            // Buy BISHOP from tranchess swap using quote asset
            uint256 quoteAmount = tranchessPair.getQuoteIn(params.inputs.amountR);
            IERC20(params.inputs.tokenQuote).safeTransfer(address(tranchessPair), quoteAmount);
            tranchessPair.buy(params.inputs.version, params.inputs.amountR, address(this), "");
            // Merge BISHOP and ROOK into QUEEN
            IStableSwapCoreInternalRevertExpected swapCore =
                IStableSwapCoreInternalRevertExpected(params.inputs.queenSwapOrPrimaryMarketRouter);
            uint256 outQ =
                IPrimaryMarketV3(params.inputs.fund.primaryMarket()).merge(
                    address(swapCore),
                    params.inputs.amountR,
                    params.inputs.version
                );
            // Redeem or swap QUEEN for underlying, paying back the flashloan
            uint256 underlyingAmount = swapCore.getQuoteOut(outQ);
            swapCore.sell(params.inputs.version, underlyingAmount, msg.sender, "");
            // Send the rest of quote asset to user
            require(
                amountOut.sub(quoteAmount) >= params.inputs.resultBoundary,
                "Insufficient output"
            );
            IERC20(params.inputs.tokenQuote).safeTransfer(
                params.inputs.recipient,
                amountOut - quoteAmount
            );
            emit SwapRook(
                params.inputs.recipient,
                params.inputs.amountR,
                0,
                0,
                amountOut - quoteAmount
            );
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0 <0.8.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(MAX_TICK), 'T');

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint160(uint256 y) internal pure returns (uint160 z) {
        require((z = uint160(y)) == y);
    }

    /// @notice Cast a int256 to a int128, revert on overflow or underflow
    /// @param y The int256 to be downcasted
    /// @return z The downcasted integer, now type int128
    function toInt128(int256 y) internal pure returns (int128 z) {
        require((z = int128(y)) == y);
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        require(y < 2**255);
        z = int256(y);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        factory,
                        keccak256(abi.encode(key.token0, key.token1, key.fee)),
                        POOL_INIT_CODE_HASH
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/ISwapRouter.sol";
import "../interfaces/ITrancheIndexV2.sol";
import "../fund/ShareStaking.sol";
import "../interfaces/IWrappedERC20.sol";

/// @title Tranchess Swap Router
/// @notice Router for stateless execution of swaps against Tranchess stable swaps
contract SwapRouter is ISwapRouter, ITrancheIndexV2, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event SwapAdded(address addr0, address addr1, address swap);

    mapping(address => mapping(address => IStableSwap)) private _swapMap;

    /// @dev Returns the swap for the given token pair and fee. The swap contract may or may not exist.
    function getSwap(address baseAddress, address quoteAddress)
        public
        view
        override
        returns (IStableSwap)
    {
        (address addr0, address addr1) =
            baseAddress < quoteAddress ? (baseAddress, quoteAddress) : (quoteAddress, baseAddress);
        return _swapMap[addr0][addr1];
    }

    function addSwap(
        address baseAddress,
        address quoteAddress,
        address swap
    ) external onlyOwner {
        require(
            swap == address(0) ||
                (baseAddress == IStableSwap(swap).baseAddress() &&
                    quoteAddress == IStableSwap(swap).quoteAddress())
        ); // sanity check
        (address addr0, address addr1) =
            baseAddress < quoteAddress ? (baseAddress, quoteAddress) : (quoteAddress, baseAddress);
        _swapMap[addr0][addr1] = IStableSwap(swap);
        emit SwapAdded(addr0, addr1, swap);
    }

    receive() external payable {}

    function addLiquidity(
        address baseAddress,
        address quoteAddress,
        uint256 baseIn,
        uint256 quoteIn,
        uint256 minLpOut,
        uint256 version,
        uint256 deadline
    ) external payable override checkDeadline(deadline) {
        IStableSwap swap = getSwap(baseAddress, quoteAddress);
        require(address(swap) != address(0), "Unknown swap");

        swap.fund().trancheTransferFrom(
            swap.baseTranche(),
            msg.sender,
            address(swap),
            baseIn,
            version
        );
        if (msg.value > 0) {
            require(msg.value == quoteIn); // sanity check
            IWrappedERC20(quoteAddress).deposit{value: quoteIn}();
            IERC20(quoteAddress).safeTransfer(address(swap), quoteIn);
        } else {
            IERC20(quoteAddress).safeTransferFrom(msg.sender, address(swap), quoteIn);
        }

        uint256 lpOut = swap.addLiquidity(version, msg.sender);
        require(lpOut >= minLpOut, "Insufficient output");
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 minAmountOut,
        address[] calldata path,
        address recipient,
        address staking,
        uint256[] calldata versions,
        uint256 deadline
    ) external payable override checkDeadline(deadline) returns (uint256[] memory amounts) {
        require(path.length >= 2, "Invalid path");
        require(versions.length == path.length - 1, "Invalid versions");
        IStableSwap[] memory swaps;
        bool[] memory isBuy;
        (amounts, swaps, isBuy) = getAmountsOut(amountIn, path);
        require(amounts[amounts.length - 1] >= minAmountOut, "Insufficient output");

        if (msg.value > 0) {
            require(msg.value == amounts[0]); // sanity check
            IWrappedERC20(path[0]).deposit{value: amounts[0]}();
            IERC20(path[0]).safeTransfer(address(swaps[0]), amounts[0]);
        } else {
            if (isBuy[0]) {
                IERC20(path[0]).safeTransferFrom(msg.sender, address(swaps[0]), amounts[0]);
            } else {
                swaps[0].fund().trancheTransferFrom(
                    swaps[0].baseTranche(),
                    msg.sender,
                    address(swaps[0]),
                    amounts[0],
                    versions[0]
                );
            }
        }

        if (staking == address(0)) {
            _swap(amounts, swaps, isBuy, versions, recipient);
        } else {
            _swap(amounts, swaps, isBuy, versions, staking);
            ShareStaking(staking).deposit(
                swaps[swaps.length - 1].baseTranche(),
                amounts[amounts.length - 1],
                recipient,
                versions[versions.length - 1]
            );
        }
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 maxAmountIn,
        address[] calldata path,
        address recipient,
        address staking,
        uint256[] calldata versions,
        uint256 deadline
    ) external payable override checkDeadline(deadline) returns (uint256[] memory amounts) {
        require(path.length >= 2, "Invalid path");
        require(versions.length == path.length - 1, "Invalid versions");
        IStableSwap[] memory swaps;
        bool[] memory isBuy;
        (amounts, swaps, isBuy) = getAmountsIn(amountOut, path);
        require(amounts[0] <= maxAmountIn, "Excessive input");

        if (msg.value > 0) {
            require(msg.value == maxAmountIn); // sanity check
            IWrappedERC20(path[0]).deposit{value: amounts[0]}();
            IERC20(path[0]).safeTransfer(address(swaps[0]), amounts[0]);
        } else {
            if (isBuy[0]) {
                IERC20(path[0]).safeTransferFrom(msg.sender, address(swaps[0]), amounts[0]);
            } else {
                swaps[0].fund().trancheTransferFrom(
                    swaps[0].baseTranche(),
                    msg.sender,
                    address(swaps[0]),
                    amounts[0],
                    versions[0]
                );
            }
        }

        if (staking == address(0)) {
            _swap(amounts, swaps, isBuy, versions, recipient);
        } else {
            _swap(amounts, swaps, isBuy, versions, staking);
            ShareStaking(staking).deposit(
                swaps[swaps.length - 1].baseTranche(),
                amountOut,
                recipient,
                versions[versions.length - 1]
            );
        }
        // refund native token
        if (msg.value > amounts[0]) {
            (bool success, ) = msg.sender.call{value: msg.value - amounts[0]}("");
            require(success, "Transfer failed");
        }
    }

    function swapExactTokensForTokensUnwrap(
        uint256 amountIn,
        uint256 minAmountOut,
        address[] calldata path,
        address recipient,
        uint256[] calldata versions,
        uint256 deadline
    ) external override checkDeadline(deadline) returns (uint256[] memory amounts) {
        require(path.length >= 2, "Invalid path");
        require(versions.length == path.length - 1, "Invalid versions");
        IStableSwap[] memory swaps;
        bool[] memory isBuy;
        (amounts, swaps, isBuy) = getAmountsOut(amountIn, path);
        require(amounts[amounts.length - 1] >= minAmountOut, "Insufficient output");
        if (isBuy[0]) {
            IERC20(path[0]).safeTransferFrom(msg.sender, address(swaps[0]), amounts[0]);
        } else {
            swaps[0].fund().trancheTransferFrom(
                swaps[0].baseTranche(),
                msg.sender,
                address(swaps[0]),
                amounts[0],
                versions[0]
            );
        }
        _swap(amounts, swaps, isBuy, versions, address(this));
        IWrappedERC20(path[path.length - 1]).withdraw(amounts[amounts.length - 1]);
        (bool success, ) = recipient.call{value: amounts[amounts.length - 1]}("");
        require(success, "Transfer failed");
    }

    function swapTokensForExactTokensUnwrap(
        uint256 amountOut,
        uint256 maxAmountIn,
        address[] calldata path,
        address recipient,
        uint256[] calldata versions,
        uint256 deadline
    ) external override checkDeadline(deadline) returns (uint256[] memory amounts) {
        require(path.length >= 2, "Invalid path");
        require(versions.length == path.length - 1, "Invalid versions");
        IStableSwap[] memory swaps;
        bool[] memory isBuy;
        (amounts, swaps, isBuy) = getAmountsIn(amountOut, path);
        require(amounts[0] <= maxAmountIn, "Excessive input");
        if (isBuy[0]) {
            IERC20(path[0]).safeTransferFrom(msg.sender, address(swaps[0]), amounts[0]);
        } else {
            swaps[0].fund().trancheTransferFrom(
                swaps[0].baseTranche(),
                msg.sender,
                address(swaps[0]),
                amounts[0],
                versions[0]
            );
        }
        _swap(amounts, swaps, isBuy, versions, address(this));
        IWrappedERC20(path[path.length - 1]).withdraw(amountOut);
        (bool success, ) = recipient.call{value: amountOut}("");
        require(success, "Transfer failed");
    }

    function getAmountsOut(uint256 amount, address[] memory path)
        public
        view
        override
        returns (
            uint256[] memory amounts,
            IStableSwap[] memory swaps,
            bool[] memory isBuy
        )
    {
        amounts = new uint256[](path.length);
        swaps = new IStableSwap[](path.length - 1);
        isBuy = new bool[](path.length - 1);
        amounts[0] = amount;
        for (uint256 i; i < path.length - 1; i++) {
            swaps[i] = getSwap(path[i], path[i + 1]);
            require(address(swaps[i]) != address(0), "Unknown swap");
            if (path[i] == swaps[i].baseAddress()) {
                amounts[i + 1] = swaps[i].getQuoteOut(amounts[i]);
            } else {
                isBuy[i] = true;
                amounts[i + 1] = swaps[i].getBaseOut(amounts[i]);
            }
        }
    }

    function getAmountsIn(uint256 amount, address[] memory path)
        public
        view
        override
        returns (
            uint256[] memory amounts,
            IStableSwap[] memory swaps,
            bool[] memory isBuy
        )
    {
        amounts = new uint256[](path.length);
        swaps = new IStableSwap[](path.length - 1);
        isBuy = new bool[](path.length - 1);
        amounts[amounts.length - 1] = amount;
        for (uint256 i = path.length - 1; i > 0; i--) {
            swaps[i - 1] = getSwap(path[i - 1], path[i]);
            require(address(swaps[i - 1]) != address(0), "Unknown swap");
            if (path[i] == swaps[i - 1].baseAddress()) {
                isBuy[i - 1] = true;
                amounts[i - 1] = swaps[i - 1].getQuoteIn(amounts[i]);
            } else {
                amounts[i - 1] = swaps[i - 1].getBaseIn(amounts[i]);
            }
        }
    }

    function _swap(
        uint256[] memory amounts,
        IStableSwap[] memory swaps,
        bool[] memory isBuy,
        uint256[] calldata versions,
        address recipient
    ) private {
        for (uint256 i = 0; i < swaps.length; i++) {
            address to = i < swaps.length - 1 ? address(swaps[i + 1]) : recipient;
            if (!isBuy[i]) {
                swaps[i].sell(versions[i], amounts[i + 1], to, new bytes(0));
            } else {
                swaps[i].buy(versions[i], amounts[i + 1], to, new bytes(0));
            }
        }
    }

    modifier checkDeadline(uint256 deadline) {
        require(block.timestamp <= deadline, "Transaction too old");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "../interfaces/IStableSwap.sol";
import "../interfaces/ILiquidityGauge.sol";
import "../interfaces/ITranchessSwapCallee.sol";
import "../interfaces/IWrappedERC20.sol";

import "../utils/SafeDecimalMath.sol";
import "../utils/AdvancedMath.sol";
import "../utils/ManagedPausable.sol";

abstract contract StableSwapV2 is IStableSwap, Ownable, ReentrancyGuard, ManagedPausable {
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;
    using SafeERC20 for IERC20;

    event LiquidityAdded(
        address indexed sender,
        address indexed recipient,
        uint256 baseIn,
        uint256 quoteIn,
        uint256 lpOut,
        uint256 fee,
        uint256 adminFee,
        uint256 oraclePrice
    );
    event LiquidityRemoved(
        address indexed account,
        uint256 lpIn,
        uint256 baseOut,
        uint256 quotOut,
        uint256 fee,
        uint256 adminFee,
        uint256 oraclePrice
    );
    event Swap(
        address indexed sender,
        address indexed recipient,
        uint256 baseIn,
        uint256 quoteIn,
        uint256 baseOut,
        uint256 quoteOut,
        uint256 fee,
        uint256 adminFee,
        uint256 oraclePrice
    );
    event Sync(uint256 base, uint256 quote, uint256 oraclePrice);
    event AmplRampUpdated(uint256 start, uint256 end, uint256 startTimestamp, uint256 endTimestamp);
    event FeeCollectorUpdated(address newFeeCollector);
    event FeeRateUpdated(uint256 newFeeRate);
    event AdminFeeRateUpdated(uint256 newAdminFeeRate);

    uint256 private constant AMPL_MAX_VALUE = 1e6;
    uint256 private constant AMPL_RAMP_MIN_TIME = 86400;
    uint256 private constant AMPL_RAMP_MAX_CHANGE = 10;
    uint256 private constant MAX_FEE_RATE = 0.5e18;
    uint256 private constant MAX_ADMIN_FEE_RATE = 1e18;
    uint256 private constant MAX_ITERATION = 255;
    uint256 private constant MINIMUM_LIQUIDITY = 1e3;

    address public immutable lpToken;
    IFundV3 public immutable override fund;
    uint256 public immutable override baseTranche;
    address public immutable override quoteAddress;

    /// @dev A multipler that normalizes a quote asset balance to 18 decimal places.
    uint256 internal immutable _quoteDecimalMultiplier;

    uint256 public baseBalance;
    uint256 public quoteBalance;

    uint256 private _priceOverOracleIntegral;
    uint256 private _priceOverOracleTimestamp;

    uint256 public amplRampStart;
    uint256 public amplRampEnd;
    uint256 public amplRampStartTimestamp;
    uint256 public amplRampEndTimestamp;

    address public feeCollector;
    uint256 public feeRate;
    uint256 public adminFeeRate;
    uint256 public totalAdminFee;

    constructor(
        address lpToken_,
        address fund_,
        uint256 baseTranche_,
        address quoteAddress_,
        uint256 quoteDecimals_,
        uint256 ampl_,
        address feeCollector_,
        uint256 feeRate_,
        uint256 adminFeeRate_
    ) public {
        lpToken = lpToken_;
        fund = IFundV3(fund_);
        baseTranche = baseTranche_;
        quoteAddress = quoteAddress_;
        require(quoteDecimals_ <= 18, "Quote asset decimals larger than 18");
        _quoteDecimalMultiplier = 10**(18 - quoteDecimals_);

        require(ampl_ > 0 && ampl_ < AMPL_MAX_VALUE, "Invalid A");
        amplRampEnd = ampl_;
        emit AmplRampUpdated(ampl_, ampl_, 0, 0);

        _updateFeeCollector(feeCollector_);
        _updateFeeRate(feeRate_);
        _updateAdminFeeRate(adminFeeRate_);

        _initializeManagedPausable(msg.sender);
    }

    receive() external payable {}

    function baseAddress() external view override returns (address) {
        return fund.tokenShare(baseTranche);
    }

    function allBalances() external view override returns (uint256, uint256) {
        (uint256 base, uint256 quote, , , , , ) = _getRebalanceResult(fund.getRebalanceSize());
        return (base, quote);
    }

    function getAmpl() public view returns (uint256) {
        uint256 endTimestamp = amplRampEndTimestamp;
        if (block.timestamp < endTimestamp) {
            uint256 startTimestamp = amplRampStartTimestamp;
            uint256 start = amplRampStart;
            uint256 end = amplRampEnd;
            if (end > start) {
                return
                    start +
                    ((end - start) * (block.timestamp - startTimestamp)) /
                    (endTimestamp - startTimestamp);
            } else {
                return
                    start -
                    ((start - end) * (block.timestamp - startTimestamp)) /
                    (endTimestamp - startTimestamp);
            }
        } else {
            return amplRampEnd;
        }
    }

    function getCurrentD() external view override returns (uint256) {
        (uint256 base, uint256 quote, , , , , ) = _getRebalanceResult(fund.getRebalanceSize());
        return _getD(base, quote, getAmpl(), getOraclePrice());
    }

    function getCurrentPriceOverOracle() public view override returns (uint256) {
        (uint256 base, uint256 quote, , , , , ) = _getRebalanceResult(fund.getRebalanceSize());
        if (base == 0 || quote == 0) {
            return 1e18;
        }
        uint256 ampl = getAmpl();
        uint256 oraclePrice = getOraclePrice();
        uint256 d = _getD(base, quote, ampl, oraclePrice);
        return _getPriceOverOracle(base, quote, ampl, oraclePrice, d);
    }

    /// @notice Get the current swap price, i.e. negative slope at the current point on the curve.
    ///         The returned value is computed after both base and quote balances are normalized to
    ///         18 decimal places. If the quote token does not have 18 decimal places, the returned
    ///         value has a different order of magnitude than the ratio of quote amount to base
    ///         amount in a swap.
    function getCurrentPrice() external view override returns (uint256) {
        (uint256 base, uint256 quote, , , , , ) = _getRebalanceResult(fund.getRebalanceSize());
        uint256 oraclePrice = getOraclePrice();
        if (base == 0 || quote == 0) {
            return oraclePrice;
        }
        uint256 ampl = getAmpl();
        uint256 d = _getD(base, quote, ampl, oraclePrice);
        return _getPriceOverOracle(base, quote, ampl, oraclePrice, d).multiplyDecimal(oraclePrice);
    }

    function getPriceOverOracleIntegral() external view override returns (uint256) {
        return
            _priceOverOracleIntegral +
            getCurrentPriceOverOracle() *
            (block.timestamp - _priceOverOracleTimestamp);
    }

    function getQuoteOut(uint256 baseIn) external view override returns (uint256 quoteOut) {
        (uint256 oldBase, uint256 oldQuote, , , , , ) =
            _getRebalanceResult(fund.getRebalanceSize());
        uint256 newBase = oldBase.add(baseIn);
        uint256 ampl = getAmpl();
        uint256 oraclePrice = getOraclePrice();
        // Add 1 in case of rounding errors
        uint256 d = _getD(oldBase, oldQuote, ampl, oraclePrice) + 1;
        uint256 newQuote = _getQuote(ampl, newBase, oraclePrice, d) + 1;
        quoteOut = oldQuote.sub(newQuote);
        // Round down output after fee
        quoteOut = quoteOut.multiplyDecimal(1e18 - feeRate);
    }

    function getQuoteIn(uint256 baseOut) external view override returns (uint256 quoteIn) {
        (uint256 oldBase, uint256 oldQuote, , , , , ) =
            _getRebalanceResult(fund.getRebalanceSize());
        uint256 newBase = oldBase.sub(baseOut);
        uint256 ampl = getAmpl();
        uint256 oraclePrice = getOraclePrice();
        // Add 1 in case of rounding errors
        uint256 d = _getD(oldBase, oldQuote, ampl, oraclePrice) + 1;
        uint256 newQuote = _getQuote(ampl, newBase, oraclePrice, d) + 1;
        quoteIn = newQuote.sub(oldQuote);
        uint256 feeRate_ = feeRate;
        // Round up input before fee
        quoteIn = quoteIn.mul(1e18).add(1e18 - feeRate_ - 1) / (1e18 - feeRate_);
    }

    function getBaseOut(uint256 quoteIn) external view override returns (uint256 baseOut) {
        (uint256 oldBase, uint256 oldQuote, , , , , ) =
            _getRebalanceResult(fund.getRebalanceSize());
        // Round down input after fee
        uint256 quoteInAfterFee = quoteIn.multiplyDecimal(1e18 - feeRate);
        uint256 newQuote = oldQuote.add(quoteInAfterFee);
        uint256 ampl = getAmpl();
        uint256 oraclePrice = getOraclePrice();
        // Add 1 in case of rounding errors
        uint256 d = _getD(oldBase, oldQuote, ampl, oraclePrice) + 1;
        uint256 newBase = _getBase(ampl, newQuote, oraclePrice, d) + 1;
        baseOut = oldBase.sub(newBase);
    }

    function getBaseIn(uint256 quoteOut) external view override returns (uint256 baseIn) {
        (uint256 oldBase, uint256 oldQuote, , , , , ) =
            _getRebalanceResult(fund.getRebalanceSize());
        uint256 feeRate_ = feeRate;
        // Round up output before fee
        uint256 quoteOutBeforeFee = quoteOut.mul(1e18).add(1e18 - feeRate_ - 1) / (1e18 - feeRate_);
        uint256 newQuote = oldQuote.sub(quoteOutBeforeFee);
        uint256 ampl = getAmpl();
        uint256 oraclePrice = getOraclePrice();
        // Add 1 in case of rounding errors
        uint256 d = _getD(oldBase, oldQuote, ampl, oraclePrice) + 1;
        uint256 newBase = _getBase(ampl, newQuote, oraclePrice, d) + 1;
        baseIn = newBase.sub(oldBase);
    }

    function buy(
        uint256 version,
        uint256 baseOut,
        address recipient,
        bytes calldata data
    )
        external
        override
        nonReentrant
        checkVersion(version)
        whenNotPaused
        returns (uint256 realBaseOut)
    {
        require(baseOut > 0, "Zero output");
        realBaseOut = baseOut;
        (uint256 oldBase, uint256 oldQuote) = _handleRebalance(version);
        require(baseOut < oldBase, "Insufficient liquidity");
        // Optimistically transfer tokens.
        fund.trancheTransfer(baseTranche, recipient, baseOut, version);
        if (data.length > 0) {
            ITranchessSwapCallee(msg.sender).tranchessSwapCallback(baseOut, 0, data);
            _checkVersion(version); // Make sure no rebalance is triggered in the callback
        }
        uint256 newQuote = _getNewQuoteBalance();
        uint256 quoteIn = newQuote.sub(oldQuote);
        uint256 fee = quoteIn.multiplyDecimal(feeRate);
        uint256 oraclePrice = getOraclePrice();
        {
            uint256 ampl = getAmpl();
            uint256 oldD = _getD(oldBase, oldQuote, ampl, oraclePrice);
            _updatePriceOverOracleIntegral(oldBase, oldQuote, ampl, oraclePrice, oldD);
            uint256 newD = _getD(oldBase - baseOut, newQuote.sub(fee), ampl, oraclePrice);
            require(newD >= oldD, "Invariant mismatch");
        }
        uint256 adminFee = fee.multiplyDecimal(adminFeeRate);
        baseBalance = oldBase - baseOut;
        quoteBalance = newQuote.sub(adminFee);
        totalAdminFee = totalAdminFee.add(adminFee);
        uint256 baseOut_ = baseOut;
        emit Swap(msg.sender, recipient, 0, quoteIn, baseOut_, 0, fee, adminFee, oraclePrice);
    }

    function sell(
        uint256 version,
        uint256 quoteOut,
        address recipient,
        bytes calldata data
    )
        external
        override
        nonReentrant
        checkVersion(version)
        whenNotPaused
        returns (uint256 realQuoteOut)
    {
        require(quoteOut > 0, "Zero output");
        realQuoteOut = quoteOut;
        (uint256 oldBase, uint256 oldQuote) = _handleRebalance(version);
        // Optimistically transfer tokens.
        IERC20(quoteAddress).safeTransfer(recipient, quoteOut);
        if (data.length > 0) {
            ITranchessSwapCallee(msg.sender).tranchessSwapCallback(0, quoteOut, data);
            _checkVersion(version); // Make sure no rebalance is triggered in the callback
        }
        uint256 newBase = fund.trancheBalanceOf(baseTranche, address(this));
        uint256 baseIn = newBase.sub(oldBase);
        uint256 fee;
        {
            uint256 feeRate_ = feeRate;
            fee = quoteOut.mul(feeRate_).div(1e18 - feeRate_);
        }
        require(quoteOut.add(fee) < oldQuote, "Insufficient liquidity");
        uint256 oraclePrice = getOraclePrice();
        {
            uint256 newQuote = oldQuote - quoteOut;
            uint256 ampl = getAmpl();
            uint256 oldD = _getD(oldBase, oldQuote, ampl, oraclePrice);
            _updatePriceOverOracleIntegral(oldBase, oldQuote, ampl, oraclePrice, oldD);
            uint256 newD = _getD(newBase, newQuote - fee, ampl, oraclePrice);
            require(newD >= oldD, "Invariant mismatch");
        }
        uint256 adminFee = fee.multiplyDecimal(adminFeeRate);
        baseBalance = newBase;
        quoteBalance = oldQuote - quoteOut - adminFee;
        totalAdminFee = totalAdminFee.add(adminFee);
        uint256 quoteOut_ = quoteOut;
        emit Swap(msg.sender, recipient, baseIn, 0, 0, quoteOut_, fee, adminFee, oraclePrice);
    }

    /// @notice Add liquidity. This function should be called by a smart contract, which transfers
    ///         base and quote tokens to this contract in the same transaction.
    /// @param version The latest rebalance version
    /// @param recipient Recipient of minted LP tokens
    /// @param lpOut Amount of minted LP tokens
    function addLiquidity(uint256 version, address recipient)
        external
        override
        nonReentrant
        checkVersion(version)
        whenNotPaused
        returns (uint256 lpOut)
    {
        (uint256 oldBase, uint256 oldQuote) = _handleRebalance(version);
        uint256 newBase = fund.trancheBalanceOf(baseTranche, address(this));
        uint256 newQuote = _getNewQuoteBalance();
        uint256 ampl = getAmpl();
        uint256 oraclePrice = getOraclePrice();
        uint256 lpSupply = IERC20(lpToken).totalSupply();
        if (lpSupply == 0) {
            require(newBase > 0 && newQuote > 0, "Zero initial balance");
            baseBalance = newBase;
            quoteBalance = newQuote;
            // Overflow is desired
            _priceOverOracleIntegral += 1e18 * (block.timestamp - _priceOverOracleTimestamp);
            _priceOverOracleTimestamp = block.timestamp;
            uint256 d1 = _getD(newBase, newQuote, ampl, oraclePrice);
            ILiquidityGauge(lpToken).mint(address(this), MINIMUM_LIQUIDITY);
            ILiquidityGauge(lpToken).mint(recipient, d1.sub(MINIMUM_LIQUIDITY));
            emit LiquidityAdded(msg.sender, recipient, newBase, newQuote, d1, 0, 0, oraclePrice);
            return d1;
        }
        uint256 fee;
        uint256 adminFee;
        {
            // Initial invariant
            uint256 d0 = _getD(oldBase, oldQuote, ampl, oraclePrice);
            _updatePriceOverOracleIntegral(oldBase, oldQuote, ampl, oraclePrice, d0);
            {
                // New invariant before charging fee
                uint256 d1 = _getD(newBase, newQuote, ampl, oraclePrice);
                uint256 idealQuote = d1.mul(oldQuote) / d0;
                uint256 difference =
                    idealQuote > newQuote ? idealQuote - newQuote : newQuote - idealQuote;
                fee = difference.multiplyDecimal(feeRate);
            }
            adminFee = fee.multiplyDecimal(adminFeeRate);
            totalAdminFee = totalAdminFee.add(adminFee);
            baseBalance = newBase;
            quoteBalance = newQuote.sub(adminFee);
            // New invariant after charging fee
            uint256 d2 = _getD(newBase, newQuote.sub(fee), ampl, oraclePrice);
            require(d2 > d0, "No liquidity is added");
            lpOut = lpSupply.mul(d2.sub(d0)).div(d0);
        }
        ILiquidityGauge(lpToken).mint(recipient, lpOut);
        emit LiquidityAdded(
            msg.sender,
            recipient,
            newBase - oldBase,
            newQuote - oldQuote,
            lpOut,
            fee,
            adminFee,
            oraclePrice
        );
    }

    /// @dev Remove liquidity proportionally.
    /// @param lpIn Exact amount of LP token to burn
    /// @param minBaseOut Least amount of base asset to withdraw
    /// @param minQuoteOut Least amount of quote asset to withdraw
    function removeLiquidity(
        uint256 version,
        uint256 lpIn,
        uint256 minBaseOut,
        uint256 minQuoteOut
    )
        external
        override
        nonReentrant
        checkVersion(version)
        returns (uint256 baseOut, uint256 quoteOut)
    {
        (baseOut, quoteOut) = _removeLiquidity(version, lpIn, minBaseOut, minQuoteOut);
        IERC20(quoteAddress).safeTransfer(msg.sender, quoteOut);
    }

    /// @dev Remove liquidity proportionally and unwrap for native token.
    /// @param lpIn Exact amount of LP token to burn
    /// @param minBaseOut Least amount of base asset to withdraw
    /// @param minQuoteOut Least amount of quote asset to withdraw
    function removeLiquidityUnwrap(
        uint256 version,
        uint256 lpIn,
        uint256 minBaseOut,
        uint256 minQuoteOut
    )
        external
        override
        nonReentrant
        checkVersion(version)
        returns (uint256 baseOut, uint256 quoteOut)
    {
        (baseOut, quoteOut) = _removeLiquidity(version, lpIn, minBaseOut, minQuoteOut);
        IWrappedERC20(quoteAddress).withdraw(quoteOut);
        (bool success, ) = msg.sender.call{value: quoteOut}("");
        require(success, "Transfer failed");
    }

    function _removeLiquidity(
        uint256 version,
        uint256 lpIn,
        uint256 minBaseOut,
        uint256 minQuoteOut
    ) private returns (uint256 baseOut, uint256 quoteOut) {
        uint256 lpSupply = IERC20(lpToken).totalSupply();
        (uint256 oldBase, uint256 oldQuote) = _handleRebalance(version);
        baseOut = oldBase.mul(lpIn).div(lpSupply);
        quoteOut = oldQuote.mul(lpIn).div(lpSupply);
        require(baseOut >= minBaseOut, "Insufficient output");
        require(quoteOut >= minQuoteOut, "Insufficient output");
        baseBalance = oldBase.sub(baseOut);
        quoteBalance = oldQuote.sub(quoteOut);
        ILiquidityGauge(lpToken).burnFrom(msg.sender, lpIn);
        fund.trancheTransfer(baseTranche, msg.sender, baseOut, version);
        emit LiquidityRemoved(msg.sender, lpIn, baseOut, quoteOut, 0, 0, 0);
    }

    /// @dev Remove base liquidity only.
    /// @param lpIn Exact amount of LP token to burn
    /// @param minBaseOut Least amount of base asset to withdraw
    function removeBaseLiquidity(
        uint256 version,
        uint256 lpIn,
        uint256 minBaseOut
    ) external override nonReentrant checkVersion(version) whenNotPaused returns (uint256 baseOut) {
        (uint256 oldBase, uint256 oldQuote) = _handleRebalance(version);
        uint256 lpSupply = IERC20(lpToken).totalSupply();
        uint256 ampl = getAmpl();
        uint256 oraclePrice = getOraclePrice();
        uint256 d1;
        {
            uint256 d0 = _getD(oldBase, oldQuote, ampl, oraclePrice);
            _updatePriceOverOracleIntegral(oldBase, oldQuote, ampl, oraclePrice, d0);
            d1 = d0.sub(d0.mul(lpIn).div(lpSupply));
        }
        {
            uint256 fee = oldQuote.mul(lpIn).div(lpSupply).multiplyDecimal(feeRate);
            // Add 1 in case of rounding errors
            uint256 newBase = _getBase(ampl, oldQuote.sub(fee), oraclePrice, d1) + 1;
            baseOut = oldBase.sub(newBase);
            require(baseOut >= minBaseOut, "Insufficient output");
            ILiquidityGauge(lpToken).burnFrom(msg.sender, lpIn);
            baseBalance = newBase;
            uint256 adminFee = fee.multiplyDecimal(adminFeeRate);
            totalAdminFee = totalAdminFee.add(adminFee);
            quoteBalance = oldQuote.sub(adminFee);
            emit LiquidityRemoved(msg.sender, lpIn, baseOut, 0, fee, adminFee, oraclePrice);
        }
        fund.trancheTransfer(baseTranche, msg.sender, baseOut, version);
    }

    /// @dev Remove quote liquidity only.
    /// @param lpIn Exact amount of LP token to burn
    /// @param minQuoteOut Least amount of quote asset to withdraw
    function removeQuoteLiquidity(
        uint256 version,
        uint256 lpIn,
        uint256 minQuoteOut
    )
        external
        override
        nonReentrant
        checkVersion(version)
        whenNotPaused
        returns (uint256 quoteOut)
    {
        quoteOut = _removeQuoteLiquidity(version, lpIn, minQuoteOut);
        IERC20(quoteAddress).safeTransfer(msg.sender, quoteOut);
    }

    /// @dev Remove quote liquidity only and unwrap for native token.
    /// @param lpIn Exact amount of LP token to burn
    /// @param minQuoteOut Least amount of quote asset to withdraw
    function removeQuoteLiquidityUnwrap(
        uint256 version,
        uint256 lpIn,
        uint256 minQuoteOut
    )
        external
        override
        nonReentrant
        checkVersion(version)
        whenNotPaused
        returns (uint256 quoteOut)
    {
        quoteOut = _removeQuoteLiquidity(version, lpIn, minQuoteOut);
        IWrappedERC20(quoteAddress).withdraw(quoteOut);
        (bool success, ) = msg.sender.call{value: quoteOut}("");
        require(success, "Transfer failed");
    }

    function _removeQuoteLiquidity(
        uint256 version,
        uint256 lpIn,
        uint256 minQuoteOut
    ) private returns (uint256 quoteOut) {
        (uint256 oldBase, uint256 oldQuote) = _handleRebalance(version);
        uint256 lpSupply = IERC20(lpToken).totalSupply();
        uint256 ampl = getAmpl();
        uint256 oraclePrice = getOraclePrice();
        uint256 d1;
        {
            uint256 d0 = _getD(oldBase, oldQuote, ampl, oraclePrice);
            _updatePriceOverOracleIntegral(oldBase, oldQuote, ampl, oraclePrice, d0);
            d1 = d0.sub(d0.mul(lpIn).div(lpSupply));
        }
        uint256 idealQuote = oldQuote.mul(lpSupply.sub(lpIn)).div(lpSupply);
        // Add 1 in case of rounding errors
        uint256 newQuote = _getQuote(ampl, oldBase, oraclePrice, d1) + 1;
        uint256 fee = idealQuote.sub(newQuote).multiplyDecimal(feeRate);
        quoteOut = oldQuote.sub(newQuote).sub(fee);
        require(quoteOut >= minQuoteOut, "Insufficient output");
        ILiquidityGauge(lpToken).burnFrom(msg.sender, lpIn);
        uint256 adminFee = fee.multiplyDecimal(adminFeeRate);
        totalAdminFee = totalAdminFee.add(adminFee);
        quoteBalance = newQuote.add(fee).sub(adminFee);
        emit LiquidityRemoved(msg.sender, lpIn, 0, quoteOut, fee, adminFee, oraclePrice);
    }

    /// @notice Force stored values to match balances.
    function sync() external nonReentrant {
        (uint256 oldBase, uint256 oldQuote) = _handleRebalance(fund.getRebalanceSize());
        uint256 ampl = getAmpl();
        uint256 oraclePrice = getOraclePrice();
        uint256 d = _getD(oldBase, oldQuote, ampl, oraclePrice);
        _updatePriceOverOracleIntegral(oldBase, oldQuote, ampl, oraclePrice, d);
        uint256 newBase = fund.trancheBalanceOf(baseTranche, address(this));
        uint256 newQuote = _getNewQuoteBalance();
        baseBalance = newBase;
        quoteBalance = newQuote;
        emit Sync(newBase, newQuote, oraclePrice);
    }

    function collectFee() external {
        uint256 totalAdminFee_ = totalAdminFee;
        delete totalAdminFee;
        IERC20(quoteAddress).safeTransfer(feeCollector, totalAdminFee_);
    }

    function _getNewQuoteBalance() private view returns (uint256) {
        return IERC20(quoteAddress).balanceOf(address(this)).sub(totalAdminFee);
    }

    function _updatePriceOverOracleIntegral(
        uint256 base,
        uint256 quote,
        uint256 ampl,
        uint256 oraclePrice,
        uint256 d
    ) private {
        // Overflow is desired
        _priceOverOracleIntegral +=
            _getPriceOverOracle(base, quote, ampl, oraclePrice, d) *
            (block.timestamp - _priceOverOracleTimestamp);
        _priceOverOracleTimestamp = block.timestamp;
    }

    function _getD(
        uint256 base,
        uint256 quote,
        uint256 ampl,
        uint256 oraclePrice
    ) private view returns (uint256) {
        // Newtonian: D' = (4A(kx + y) + D^3 / 2kxy)D / ((4A - 1)D + 3D^3 / 4kxy)
        uint256 normalizedQuote = quote.mul(_quoteDecimalMultiplier);
        uint256 baseValue = base.multiplyDecimal(oraclePrice);
        uint256 sum = baseValue.add(normalizedQuote);
        if (sum == 0) return 0;

        uint256 prev = 0;
        uint256 d = sum;
        for (uint256 i = 0; i < MAX_ITERATION; i++) {
            prev = d;
            uint256 d3 = d.mul(d).div(baseValue).mul(d) / normalizedQuote / 4;
            d = (sum.mul(4 * ampl) + 2 * d3).mul(d) / d.mul(4 * ampl - 1).add(3 * d3);
            if (d <= prev + 1 && prev <= d + 1) {
                break;
            }
        }
        return d;
    }

    function _getPriceOverOracle(
        uint256 base,
        uint256 quote,
        uint256 ampl,
        uint256 oraclePrice,
        uint256 d
    ) private view returns (uint256) {
        uint256 commonExp = d.multiplyDecimal(4e18 - 1e18 / ampl);
        uint256 baseValue = base.multiplyDecimal(oraclePrice);
        uint256 normalizedQuote = quote.mul(_quoteDecimalMultiplier);
        return
            (baseValue.mul(8).add(normalizedQuote.mul(4)).sub(commonExp))
                .multiplyDecimal(normalizedQuote)
                .divideDecimal(normalizedQuote.mul(8).add(baseValue.mul(4)).sub(commonExp))
                .divideDecimal(baseValue);
    }

    function _getBase(
        uint256 ampl,
        uint256 quote,
        uint256 oraclePrice,
        uint256 d
    ) private view returns (uint256 base) {
        // Solve 16Ayk^2·x^2 + 4ky(4Ay - 4AD + D)·x - D^3 = 0
        // Newtonian: kx' = ((kx)^2 + D^3 / 16Ay) / (2kx + y - D + D/4A)
        uint256 normalizedQuote = quote.mul(_quoteDecimalMultiplier);
        uint256 d3 = d.mul(d).div(normalizedQuote).mul(d) / (16 * ampl);
        uint256 prev = 0;
        uint256 baseValue = d;
        for (uint256 i = 0; i < MAX_ITERATION; i++) {
            prev = baseValue;
            baseValue =
                baseValue.mul(baseValue).add(d3) /
                (2 * baseValue).add(normalizedQuote).add(d / (4 * ampl)).sub(d);
            if (baseValue <= prev + 1 && prev <= baseValue + 1) {
                break;
            }
        }
        base = baseValue.divideDecimal(oraclePrice);
    }

    function _getQuote(
        uint256 ampl,
        uint256 base,
        uint256 oraclePrice,
        uint256 d
    ) private view returns (uint256 quote) {
        // Solve 16Axk·y^2 + 4kx(4Akx - 4AD + D)·y - D^3 = 0
        // Newtonian: y' = (y^2 + D^3 / 16Akx) / (2y + kx - D + D/4A)
        uint256 baseValue = base.multiplyDecimal(oraclePrice);
        uint256 d3 = d.mul(d).div(baseValue).mul(d) / (16 * ampl);
        uint256 prev = 0;
        uint256 normalizedQuote = d;
        for (uint256 i = 0; i < MAX_ITERATION; i++) {
            prev = normalizedQuote;
            normalizedQuote =
                normalizedQuote.mul(normalizedQuote).add(d3) /
                (2 * normalizedQuote).add(baseValue).add(d / (4 * ampl)).sub(d);
            if (normalizedQuote <= prev + 1 && prev <= normalizedQuote + 1) {
                break;
            }
        }
        quote = normalizedQuote / _quoteDecimalMultiplier;
    }

    function updateAmplRamp(uint256 endAmpl, uint256 endTimestamp) external onlyOwner {
        require(endAmpl > 0 && endAmpl < AMPL_MAX_VALUE, "Invalid A");
        require(endTimestamp >= block.timestamp + AMPL_RAMP_MIN_TIME, "A ramp time too short");
        uint256 ampl = getAmpl();
        require(
            (endAmpl >= ampl && endAmpl <= ampl * AMPL_RAMP_MAX_CHANGE) ||
                (endAmpl < ampl && endAmpl * AMPL_RAMP_MAX_CHANGE >= ampl),
            "A ramp change too large"
        );
        amplRampStart = ampl;
        amplRampEnd = endAmpl;
        amplRampStartTimestamp = block.timestamp;
        amplRampEndTimestamp = endTimestamp;
        emit AmplRampUpdated(ampl, endAmpl, block.timestamp, endTimestamp);
    }

    function _updateFeeCollector(address newFeeCollector) private {
        feeCollector = newFeeCollector;
        emit FeeCollectorUpdated(newFeeCollector);
    }

    function updateFeeCollector(address newFeeCollector) external onlyOwner {
        _updateFeeCollector(newFeeCollector);
    }

    function _updateFeeRate(uint256 newFeeRate) private {
        require(newFeeRate <= MAX_FEE_RATE, "Exceed max fee rate");
        feeRate = newFeeRate;
        emit FeeRateUpdated(newFeeRate);
    }

    function updateFeeRate(uint256 newFeeRate) external onlyOwner {
        _updateFeeRate(newFeeRate);
    }

    function _updateAdminFeeRate(uint256 newAdminFeeRate) private {
        require(newAdminFeeRate <= MAX_ADMIN_FEE_RATE, "Exceed max admin fee rate");
        adminFeeRate = newAdminFeeRate;
        emit AdminFeeRateUpdated(newAdminFeeRate);
    }

    function updateAdminFeeRate(uint256 newAdminFeeRate) external onlyOwner {
        _updateAdminFeeRate(newAdminFeeRate);
    }

    /// @dev Check if the user-specified version is correct.
    modifier checkVersion(uint256 version) {
        _checkVersion(version);
        _;
    }

    /// @dev Revert if the user-specified version is not correct.
    function _checkVersion(uint256 version) internal view virtual {}

    /// @dev Compute the new base and quote amount after rebalanced to the latest version.
    ///      If any tokens should be distributed to LP holders, their amounts are also returned.
    ///
    ///      The latest rebalance version is passed in a parameter and it is caller's responsibility
    ///      to pass the correct version.
    /// @param latestVersion The latest rebalance version
    /// @return newBase Amount of base tokens after rebalance
    /// @return newQuote Amount of quote tokens after rebalance
    /// @return excessiveQ Amount of QUEEN that should be distributed to LP holders due to rebalance
    /// @return excessiveB Amount of BISHOP that should be distributed to LP holders due to rebalance
    /// @return excessiveR Amount of ROOK that should be distributed to LP holders due to rebalance
    /// @return excessiveQuote Amount of quote tokens that should be distributed to LP holders due to rebalance
    /// @return isRebalanced Whether the stored base and quote amount are rebalanced
    function _getRebalanceResult(uint256 latestVersion)
        internal
        view
        virtual
        returns (
            uint256 newBase,
            uint256 newQuote,
            uint256 excessiveQ,
            uint256 excessiveB,
            uint256 excessiveR,
            uint256 excessiveQuote,
            bool isRebalanced
        );

    /// @dev Update the stored base and quote balance to the latest rebalance version and distribute
    ///      any excessive tokens to LP holders.
    ///
    ///      The latest rebalance version is passed in a parameter and it is caller's responsibility
    ///      to pass the correct version.
    /// @param latestVersion The latest rebalance version
    /// @return newBase Amount of stored base tokens after rebalance
    /// @return newQuote Amount of stored quote tokens after rebalance
    function _handleRebalance(uint256 latestVersion)
        internal
        virtual
        returns (uint256 newBase, uint256 newQuote);

    /// @notice Get the base token price from the price oracle. The returned price is normalized
    ///         to 18 decimal places.
    function getOraclePrice() public view virtual override returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../utils/CoreUtility.sol";
import "../utils/ManagedPausable.sol";
import "../interfaces/IVotingEscrow.sol";
import "../utils/ProxyUtility.sol";

contract VotingEscrowV2 is
    IVotingEscrow,
    OwnableUpgradeable,
    ReentrancyGuard,
    CoreUtility,
    ManagedPausable,
    ProxyUtility
{
    /// @dev Reserved storage slots for future base contract upgrades
    uint256[29] private _reservedSlots;

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event LockCreated(address indexed account, uint256 amount, uint256 unlockTime);

    event AmountIncreased(address indexed account, uint256 increasedAmount);

    event UnlockTimeIncreased(address indexed account, uint256 newUnlockTime);

    event Withdrawn(address indexed account, uint256 amount);

    uint8 public constant decimals = 18;

    uint256 public immutable override maxTime;

    address public immutable override token;

    string public name;
    string public symbol;

    address public addressWhitelist;

    mapping(address => LockedBalance) public locked;

    /// @notice Mapping of unlockTime => total amount that will be unlocked at unlockTime
    mapping(uint256 => uint256) public scheduledUnlock;

    /// @notice max lock time allowed at the moment
    uint256 public maxTimeAllowed;

    /// @notice Contract to be call when an account's locked CHESS is updated
    address public callback;

    /// @notice Amount of Chess locked now. Expired locks are not included.
    uint256 public totalLocked;

    /// @notice Total veCHESS at the end of the last checkpoint's week
    uint256 public nextWeekSupply;

    /// @notice Mapping of week => vote-locked chess total supplies
    ///
    ///         Key is the start timestamp of a week on each Thursday. Value is
    ///         vote-locked chess total supplies captured at the start of each week
    mapping(uint256 => uint256) public veSupplyPerWeek;

    /// @notice Start timestamp of the trading week in which the last checkpoint is made
    uint256 public checkpointWeek;

    constructor(address token_, uint256 maxTime_) public {
        token = token_;
        maxTime = maxTime_;
    }

    /// @dev Initialize the contract. The contract is designed to be used with OpenZeppelin's
    ///      `TransparentUpgradeableProxy`. This function should be called by the proxy's
    ///      constructor (via the `_data` argument).
    function initialize(
        string memory name_,
        string memory symbol_,
        uint256 maxTimeAllowed_
    ) external initializer {
        __Ownable_init();
        require(maxTimeAllowed_ <= maxTime, "Cannot exceed max time");
        maxTimeAllowed = maxTimeAllowed_;
        _initializeV2(msg.sender, name_, symbol_);
    }

    /// @dev Initialize the part added in V2. If this contract is upgraded from the previous
    ///      version, call `upgradeToAndCall` of the proxy and put a call to this function
    ///      in the `data` argument.
    ///
    ///      In the previous version, name and symbol were not correctly initialized via proxy.
    function initializeV2(
        address pauser_,
        string memory name_,
        string memory symbol_
    ) external onlyProxyAdmin {
        _initializeV2(pauser_, name_, symbol_);
    }

    function _initializeV2(
        address pauser_,
        string memory name_,
        string memory symbol_
    ) private {
        _initializeManagedPausable(pauser_);
        require(bytes(name).length == 0 && bytes(symbol).length == 0);
        name = name_;
        symbol = symbol_;

        // Initialize totalLocked, nextWeekSupply and checkpointWeek
        uint256 nextWeek = _endOfWeek(block.timestamp);
        uint256 totalLocked_ = 0;
        uint256 nextWeekSupply_ = 0;
        for (
            uint256 weekCursor = nextWeek;
            weekCursor <= nextWeek + maxTime;
            weekCursor += 1 weeks
        ) {
            totalLocked_ = totalLocked_.add(scheduledUnlock[weekCursor]);
            nextWeekSupply_ = nextWeekSupply_.add(
                (scheduledUnlock[weekCursor].mul(weekCursor - nextWeek)) / maxTime
            );
        }
        totalLocked = totalLocked_;
        nextWeekSupply = nextWeekSupply_;
        checkpointWeek = nextWeek - 1 weeks;
    }

    function getTimestampDropBelow(address account, uint256 threshold)
        external
        view
        override
        returns (uint256)
    {
        LockedBalance memory lockedBalance = locked[account];
        if (lockedBalance.amount == 0 || lockedBalance.amount < threshold) {
            return 0;
        }
        return lockedBalance.unlockTime.sub(threshold.mul(maxTime).div(lockedBalance.amount));
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balanceOfAtTimestamp(account, block.timestamp);
    }

    function totalSupply() external view override returns (uint256) {
        uint256 weekCursor = checkpointWeek;
        uint256 nextWeek = _endOfWeek(block.timestamp);
        uint256 currentWeek = nextWeek - 1 weeks;
        uint256 newNextWeekSupply = nextWeekSupply;
        uint256 newTotalLocked = totalLocked;
        if (weekCursor < currentWeek) {
            weekCursor += 1 weeks;
            for (; weekCursor < currentWeek; weekCursor += 1 weeks) {
                // Remove Chess unlocked at the beginning of the next week from total locked amount.
                newTotalLocked = newTotalLocked.sub(scheduledUnlock[weekCursor]);
                // Calculate supply at the end of the next week.
                newNextWeekSupply = newNextWeekSupply.sub(newTotalLocked.mul(1 weeks) / maxTime);
            }
            newTotalLocked = newTotalLocked.sub(scheduledUnlock[weekCursor]);
            newNextWeekSupply = newNextWeekSupply.sub(
                newTotalLocked.mul(block.timestamp - currentWeek) / maxTime
            );
        } else {
            newNextWeekSupply = newNextWeekSupply.add(
                newTotalLocked.mul(nextWeek - block.timestamp) / maxTime
            );
        }

        return newNextWeekSupply;
    }

    function getLockedBalance(address account)
        external
        view
        override
        returns (LockedBalance memory)
    {
        return locked[account];
    }

    function balanceOfAtTimestamp(address account, uint256 timestamp)
        external
        view
        override
        returns (uint256)
    {
        return _balanceOfAtTimestamp(account, timestamp);
    }

    function totalSupplyAtTimestamp(uint256 timestamp) external view returns (uint256) {
        return _totalSupplyAtTimestamp(timestamp);
    }

    function createLock(uint256 amount, uint256 unlockTime) external nonReentrant whenNotPaused {
        _assertNotContract();
        require(
            unlockTime + 1 weeks == _endOfWeek(unlockTime),
            "Unlock time must be end of a week"
        );

        LockedBalance memory lockedBalance = locked[msg.sender];

        require(amount > 0, "Zero value");
        require(lockedBalance.amount == 0, "Withdraw old tokens first");
        require(unlockTime > block.timestamp, "Can only lock until time in the future");
        require(
            unlockTime <= block.timestamp + maxTimeAllowed,
            "Voting lock cannot exceed max lock time"
        );

        _checkpoint(lockedBalance.amount, lockedBalance.unlockTime, amount, unlockTime);
        scheduledUnlock[unlockTime] = scheduledUnlock[unlockTime].add(amount);
        locked[msg.sender].unlockTime = unlockTime;
        locked[msg.sender].amount = amount;

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        if (callback != address(0)) {
            IVotingEscrowCallback(callback).syncWithVotingEscrow(msg.sender);
        }

        emit LockCreated(msg.sender, amount, unlockTime);
    }

    function increaseAmount(address account, uint256 amount) external nonReentrant whenNotPaused {
        LockedBalance memory lockedBalance = locked[account];

        require(amount > 0, "Zero value");
        require(lockedBalance.unlockTime > block.timestamp, "Cannot add to expired lock");

        uint256 newAmount = lockedBalance.amount.add(amount);
        _checkpoint(
            lockedBalance.amount,
            lockedBalance.unlockTime,
            newAmount,
            lockedBalance.unlockTime
        );
        scheduledUnlock[lockedBalance.unlockTime] = scheduledUnlock[lockedBalance.unlockTime].add(
            amount
        );
        locked[account].amount = newAmount;

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        if (callback != address(0)) {
            IVotingEscrowCallback(callback).syncWithVotingEscrow(msg.sender);
        }

        emit AmountIncreased(account, amount);
    }

    function increaseUnlockTime(uint256 unlockTime) external nonReentrant whenNotPaused {
        require(
            unlockTime + 1 weeks == _endOfWeek(unlockTime),
            "Unlock time must be end of a week"
        );
        LockedBalance memory lockedBalance = locked[msg.sender];

        require(lockedBalance.unlockTime > block.timestamp, "Lock expired");
        require(unlockTime > lockedBalance.unlockTime, "Can only increase lock duration");
        require(
            unlockTime <= block.timestamp + maxTimeAllowed,
            "Voting lock cannot exceed max lock time"
        );

        _checkpoint(
            lockedBalance.amount,
            lockedBalance.unlockTime,
            lockedBalance.amount,
            unlockTime
        );
        scheduledUnlock[lockedBalance.unlockTime] = scheduledUnlock[lockedBalance.unlockTime].sub(
            lockedBalance.amount
        );
        scheduledUnlock[unlockTime] = scheduledUnlock[unlockTime].add(lockedBalance.amount);
        locked[msg.sender].unlockTime = unlockTime;

        if (callback != address(0)) {
            IVotingEscrowCallback(callback).syncWithVotingEscrow(msg.sender);
        }

        emit UnlockTimeIncreased(msg.sender, unlockTime);
    }

    function withdraw() external nonReentrant {
        LockedBalance memory lockedBalance = locked[msg.sender];
        require(block.timestamp >= lockedBalance.unlockTime, "The lock is not expired");
        uint256 amount = uint256(lockedBalance.amount);

        lockedBalance.unlockTime = 0;
        lockedBalance.amount = 0;
        locked[msg.sender] = lockedBalance;

        IERC20(token).safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    function updateAddressWhitelist(address newWhitelist) external onlyOwner {
        require(
            newWhitelist == address(0) || Address.isContract(newWhitelist),
            "Must be null or a contract"
        );
        addressWhitelist = newWhitelist;
    }

    function updateCallback(address newCallback) external onlyOwner {
        require(
            newCallback == address(0) || Address.isContract(newCallback),
            "Must be null or a contract"
        );
        callback = newCallback;
    }

    function _assertNotContract() private view {
        if (msg.sender != tx.origin) {
            if (
                addressWhitelist != address(0) &&
                IAddressWhitelist(addressWhitelist).check(msg.sender)
            ) {
                return;
            }
            revert("Smart contract depositors not allowed");
        }
    }

    function _balanceOfAtTimestamp(address account, uint256 timestamp)
        private
        view
        returns (uint256)
    {
        require(timestamp >= block.timestamp, "Must be current or future time");
        LockedBalance memory lockedBalance = locked[account];
        if (timestamp > lockedBalance.unlockTime) {
            return 0;
        }
        return (lockedBalance.amount.mul(lockedBalance.unlockTime - timestamp)) / maxTime;
    }

    function _totalSupplyAtTimestamp(uint256 timestamp) private view returns (uint256) {
        uint256 weekCursor = _endOfWeek(timestamp);
        uint256 total = 0;
        for (; weekCursor <= timestamp + maxTime; weekCursor += 1 weeks) {
            total = total.add((scheduledUnlock[weekCursor].mul(weekCursor - timestamp)) / maxTime);
        }
        return total;
    }

    /// @dev Pre-conditions:
    ///
    ///      - `newAmount > 0`
    ///      - `newUnlockTime > block.timestamp`
    ///      - `newUnlockTime + 1 weeks == _endOfWeek(newUnlockTime)`, i.e. aligned to a trading week
    ///
    ///      The latter two conditions gaurantee that `newUnlockTime` is no smaller than the local
    ///      variable `nextWeek` in the function.
    function _checkpoint(
        uint256 oldAmount,
        uint256 oldUnlockTime,
        uint256 newAmount,
        uint256 newUnlockTime
    ) private {
        // Update veCHESS supply at the beginning of each week since the last checkpoint.
        uint256 weekCursor = checkpointWeek;
        uint256 nextWeek = _endOfWeek(block.timestamp);
        uint256 currentWeek = nextWeek - 1 weeks;
        uint256 newTotalLocked = totalLocked;
        uint256 newNextWeekSupply = nextWeekSupply;
        if (weekCursor < currentWeek) {
            for (uint256 w = weekCursor + 1 weeks; w <= currentWeek; w += 1 weeks) {
                veSupplyPerWeek[w] = newNextWeekSupply;
                // Remove Chess unlocked at the beginning of this week from total locked amount.
                newTotalLocked = newTotalLocked.sub(scheduledUnlock[w]);
                // Calculate supply at the end of the next week.
                newNextWeekSupply = newNextWeekSupply.sub(newTotalLocked.mul(1 weeks) / maxTime);
            }
            checkpointWeek = currentWeek;
        }

        // Remove the old schedule if there is one
        if (oldAmount > 0 && oldUnlockTime >= nextWeek) {
            newTotalLocked = newTotalLocked.sub(oldAmount);
            newNextWeekSupply = newNextWeekSupply.sub(
                oldAmount.mul(oldUnlockTime - nextWeek) / maxTime
            );
        }

        totalLocked = newTotalLocked.add(newAmount);
        // Round up on division when added to the total supply, so that the total supply is never
        // smaller than the sum of all accounts' veCHESS balance.
        nextWeekSupply = newNextWeekSupply.add(
            newAmount.mul(newUnlockTime - nextWeek).add(maxTime - 1) / maxTime
        );
    }

    function updateMaxTimeAllowed(uint256 newMaxTimeAllowed) external onlyOwner {
        require(newMaxTimeAllowed <= maxTime, "Cannot exceed max time");
        require(newMaxTimeAllowed > maxTimeAllowed, "Cannot shorten max time allowed");
        maxTimeAllowed = newMaxTimeAllowed;
    }

    /// @notice Recalculate `nextWeekSupply` from scratch. This function eliminates accumulated
    ///         rounding errors in `nextWeekSupply`, which is incrementally updated in
    ///         `createLock`, `increaseAmount` and `increaseUnlockTime`. It is almost
    ///         never required.
    /// @dev Search "rounding error" in test cases for details about the rounding errors.
    function calibrateSupply() external {
        uint256 nextWeek = checkpointWeek + 1 weeks;
        nextWeekSupply = _totalSupplyAtTimestamp(nextWeek);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";

import "../interfaces/ITrancheIndexV2.sol";
import "../interfaces/IChessSchedule.sol";
import "../utils/CoreUtility.sol";

import "../fund/FundV3.sol";
import "../fund/PrimaryMarketV3.sol";
import "../fund/PrimaryMarketRouter.sol";
import "../fund/ShareStaking.sol";
import "../swap/StableSwap.sol";
import "../swap/LiquidityGauge.sol";
import "../swap/SwapBonus.sol";
import "../swap/SwapRouter.sol";
import "../swap/LiquidityGaugeCurve.sol";
import "../swap/CurveRouter.sol";
import "../governance/InterestRateBallotV2.sol";
import "../governance/FeeDistributor.sol";
import "../governance/VotingEscrowV2.sol";
import "../governance/ControllerBallotV2.sol";

library LowLevelCheckedCall {
    function get(address target, bytes memory data) internal view returns (bytes memory ret) {
        bool success;
        (success, ret) = target.staticcall(data);
        require(success, "Low-level call failed");
    }

    function post(address target, bytes memory data) internal returns (bytes memory ret) {
        bool success;
        (success, ret) = target.call(data);
        require(success, "Low-level call failed");
    }
}

library LowLevelDecoder {
    function toUint(bytes memory data) internal pure returns (uint256) {
        return abi.decode(data, (uint256));
    }

    function toUints(bytes memory data) internal pure returns (uint256[] memory) {
        return abi.decode(data, (uint256[]));
    }

    function toUintUint(bytes memory data) internal pure returns (uint256, uint256) {
        return abi.decode(data, (uint256, uint256));
    }

    function toUintUintUint(bytes memory data)
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return abi.decode(data, (uint256, uint256, uint256));
    }

    function toUintUintUintUint(bytes memory data)
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return abi.decode(data, (uint256, uint256, uint256, uint256));
    }

    function toUintUintUintUintUintUint(bytes memory data)
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return abi.decode(data, (uint256, uint256, uint256, uint256, uint256, uint256));
    }

    function toBool(bytes memory data) internal pure returns (bool) {
        return abi.decode(data, (bool));
    }

    function toAddr(bytes memory data) internal pure returns (address) {
        return abi.decode(data, (address));
    }

    function toAddrs(bytes memory data) internal pure returns (address[] memory) {
        return abi.decode(data, (address[]));
    }

    function toString(bytes memory data) internal pure returns (string memory) {
        return abi.decode(data, (string));
    }
}

contract DataAggregator is ITrancheIndexV2, CoreUtility {
    using LowLevelCheckedCall for address;
    using LowLevelDecoder for bytes;

    struct Data {
        uint256 blockNumber;
        uint256 blockTimestamp;
        FundAllData[] funds;
        GovernanceData governance;
        FeeDistributorData[] feeDistributors;
        ExternalSwapData[] externalSwaps;
        CurveData[] curvePools;
    }

    struct FundAllData {
        FundData fund;
        PrimaryMarketData primaryMarket;
        ShareStakingData shareStaking;
        StableSwapData bishopStableSwap;
        StableSwapData queenStableSwap;
        FundAccountData account;
    }

    struct FundData {
        bool isFundActive;
        uint256 fundActivityStartTime;
        uint256 activityDelayTimeAfterRebalance;
        uint256 currentDay;
        uint256 dailyProtocolFeeRate;
        uint256 totalSupplyQ;
        uint256 totalSupplyB;
        uint256 totalUnderlying;
        uint256 strategyUnderlying;
        uint256 rebalanceSize;
        uint256 upperRebalanceThreshold;
        uint256 lowerRebalanceThreshold;
        uint256 splitRatio;
        uint256 latestUnderlyingPrice;
        uint256 navB;
        uint256 navR;
        uint256 currentInterestRate;
        FundV3.Rebalance lastRebalance;
    }

    struct PrimaryMarketData {
        uint256 fundCap;
        uint256 redemptionFeeRate;
        uint256 mergeFeeRate;
        uint256 redemptionQueueHead;
    }

    struct ShareStakingData {
        uint256 totalSupplyQ;
        uint256 totalSupplyB;
        uint256 totalSupplyR;
        uint256 weightedSupply;
        uint256 workingSupply;
        uint256 chessRate;
        ShareStakingAccountData account;
    }

    struct ShareStakingAccountData {
        uint256 balanceQ;
        uint256 balanceB;
        uint256 balanceR;
        uint256 weightedBalance;
        uint256 workingBalance;
        uint256 claimableChess;
    }

    struct StableSwapData {
        uint256 feeRate;
        uint256 adminFeeRate;
        uint256 ampl;
        uint256 currentD;
        uint256 currentPrice;
        uint256 baseBalance;
        uint256 quoteBalance;
        uint256 oraclePrice;
        uint256 lpTotalSupply;
        uint256 lpWorkingSupply;
        uint256 chessRate;
        uint256 lastDistributionQ;
        uint256 lastDistributionB;
        uint256 lastDistributionR;
        uint256 lastDistributionQuote;
        uint256 lastDistributionTotalSupply;
        address bonusToken;
        uint256 bonusRate;
        StableSwapAccountData account;
    }

    struct StableSwapAccountData {
        uint256 lpBalance;
        uint256 workingBalance;
        uint256 claimableChess;
        uint256 claimableBonus;
        uint256 claimableQ;
        uint256 claimableB;
        uint256 claimableR;
        uint256 claimableQuote;
    }

    struct FundAccountData {
        FundAccountBalanceData balance;
        FundAccountAllowanceData allowance;
    }

    struct FundAccountBalanceData {
        uint256 underlying;
        uint256 quote;
        uint256 trancheQ;
        uint256 trancheB;
        uint256 trancheR;
    }

    struct FundAccountAllowanceData {
        uint256 primaryMarketRouterUnderlying;
        uint256 primaryMarketRouterTrancheQ;
        uint256 swapRouterUnderlying;
        uint256 swapRouterTrancheQ;
        uint256 swapRouterTrancheB;
        uint256 swapRouterQuote;
        uint256 flashSwapRouterTrancheR;
        uint256 flashSwapRouterQuote;
        uint256 shareStakingTrancheQ;
        uint256 shareStakingTrancheB;
        uint256 shareStakingTrancheR;
    }

    struct GovernanceData {
        uint256 chessRate;
        uint256 nextWeekChessRate;
        VotingEscrowData votingEscrow;
        InterestRateBallotData interestRateBallot;
        ControllerBallotData controllerBallot;
        GovernanceAccountData account;
    }

    struct VotingEscrowData {
        uint256 totalLocked;
        uint256 totalSupply;
        uint256 tradingWeekTotalSupply;
        AnyCallSrcFee[] crossChainFees;
        IVotingEscrow.LockedBalance account;
    }

    struct InterestRateBallotData {
        uint256 tradingWeekTotalSupply;
        uint256 tradingWeekAverage;
        uint256 lastWeekAverage;
        IBallot.Voter account;
    }

    struct ControllerBallotData {
        address[] pools;
        uint256[] currentSums;
        uint256[] lastWeekSums;
        ControllerBallotAccountData account;
    }

    struct ControllerBallotAccountData {
        uint256 amount;
        uint256 unlockTime;
        uint256[] weights;
    }

    struct GovernanceAccountData {
        GovernanceAccountBalanceData balance;
        GovernanceAccountAllowanceData allowance;
    }

    struct GovernanceAccountBalanceData {
        uint256 nativeCurrency;
        uint256 chess;
    }

    struct GovernanceAccountAllowanceData {
        uint256 votingEscrowChess;
    }

    struct FeeDistributorData {
        uint256 currentRewards;
        uint256 currentSupply;
        uint256 tradingWeekTotalSupply;
        uint256 adminFeeRate;
        FeeDistributorAccountData account;
    }

    struct FeeDistributorAccountData {
        uint256 claimableRewards;
        uint256 currentBalance;
        uint256 amount;
        uint256 unlockTime;
    }

    struct AnyCallSrcFee {
        uint256 chainId;
        uint256 fee;
    }

    struct ExternalSwapData {
        string symbol0;
        string symbol1;
        uint112 reserve0;
        uint112 reserve1;
    }

    struct CurveData {
        CurvePoolData pool;
        CurveGaugeData gauge;
    }

    struct CurvePoolData {
        address pool;
        uint256 fee;
        address lpToken;
        address[2] coins;
        uint256[2] balances;
        uint256[2] prices;
        uint256 lpTotalSupply;
        uint256 lpPrice;
        CurvePoolAccountData account;
    }

    struct CurvePoolAccountData {
        uint256[2] balances;
        uint256[2] allowances;
        uint256 lpBalance;
    }

    struct CurveGaugeData {
        address gauge;
        uint256 chessRate;
        uint256 totalSupply;
        uint256 workingSupply;
        CurveGaugeAccountData account;
    }

    struct CurveGaugeAccountData {
        uint256 balance;
        uint256 allowance;
        uint256 workingBalance;
        uint256 claimableChess;
        uint256 claimableBonus;
    }

    string public constant VERSION = "2.1.1";

    address public immutable votingEscrow;
    address public immutable chessSchedule;
    address public immutable chess;
    address public immutable controllerBallot;
    address public immutable interestRateBallot;
    address public immutable swapRouter;
    address public immutable flashSwapRouter;
    address public immutable bishopQuoteToken;
    address public immutable anyCallProxy;
    uint256 private immutable _otherChainCount;

    uint256[255] public otherChainIds;

    constructor(
        address votingEscrow_,
        address chessSchedule_,
        address controllerBallot_,
        address interestRateBallot_,
        address swapRouter_,
        address flashSwapRouter_,
        address bishopQuoteToken_,
        address anyCallProxy_,
        uint256[] memory otherChainIds_
    ) public {
        votingEscrow = votingEscrow_;
        chessSchedule = chessSchedule_;
        chess = VotingEscrowV2(votingEscrow_).token();
        controllerBallot = controllerBallot_;
        interestRateBallot = interestRateBallot_;
        swapRouter = swapRouter_;
        flashSwapRouter = flashSwapRouter_;
        bishopQuoteToken = bishopQuoteToken_;
        anyCallProxy = anyCallProxy_;
        _otherChainCount = otherChainIds_.length;
        for (uint256 i = 0; i < otherChainIds_.length; i++) {
            otherChainIds[i] = otherChainIds_[i];
        }
    }

    function getData(
        address[] calldata primaryMarketRouters,
        address[] calldata shareStakings,
        address[] calldata feeDistributors,
        address[] calldata externalSwaps,
        address[] calldata curveRouters,
        address account
    ) public returns (Data memory data) {
        data.blockNumber = block.number;
        data.blockTimestamp = block.timestamp;

        data.funds = new FundAllData[](primaryMarketRouters.length);
        for (uint256 i = 0; i < primaryMarketRouters.length; i++) {
            data.funds[i] = getFundAllData(primaryMarketRouters[i], shareStakings[i], account);
        }

        data.governance = getGovernanceData(account);

        data.feeDistributors = new FeeDistributorData[](feeDistributors.length);
        for (uint256 i = 0; i < feeDistributors.length; i++) {
            data.feeDistributors[i] = getFeeDistributorData(feeDistributors[i], account);
        }

        data.externalSwaps = new ExternalSwapData[](externalSwaps.length / 3);
        for (uint256 i = 0; i < externalSwaps.length / 3; i++) {
            data.externalSwaps[i] = getExternalSwapData(
                externalSwaps[i * 3],
                externalSwaps[i * 3 + 1],
                externalSwaps[i * 3 + 2]
            );
        }

        data.curvePools = new CurveData[](curveRouters.length);
        for (uint256 i = 0; i < curveRouters.length; i++) {
            data.curvePools[i] = getCurveData(curveRouters[i], account);
        }
    }

    function getFundAllData(
        address primaryMarketRouter,
        address shareStaking,
        address account
    ) public returns (FundAllData memory data) {
        address fund =
            primaryMarketRouter
                .get(abi.encodeWithSelector(PrimaryMarketRouter(0).fund.selector))
                .toAddr();
        data.fund = getFundData(fund);

        address primaryMarket =
            primaryMarketRouter
                .get(abi.encodeWithSelector(PrimaryMarketRouter(0).primaryMarket.selector))
                .toAddr();
        data.primaryMarket = getPrimaryMarketData(primaryMarket);

        data.shareStaking = getShareStakingData(shareStaking, data.fund.splitRatio, account);
        address underlyingToken =
            fund.get(abi.encodeWithSelector(FundV3(0).tokenUnderlying.selector)).toAddr();

        if (swapRouter != address(0)) {
            address bishopStableSwap =
                swapRouter
                    .get(
                    abi.encodeWithSelector(
                        SwapRouter.getSwap.selector,
                        fund
                            .get(abi.encodeWithSelector(FundV3.tokenShare.selector, TRANCHE_B))
                            .toAddr(),
                        bishopQuoteToken
                    )
                )
                    .toAddr();
            data.bishopStableSwap = getStableSwapData(bishopStableSwap, account);

            address queenStableSwap =
                swapRouter
                    .get(
                    abi.encodeWithSelector(
                        SwapRouter.getSwap.selector,
                        fund
                            .get(abi.encodeWithSelector(FundV3.tokenShare.selector, TRANCHE_Q))
                            .toAddr(),
                        underlyingToken
                    )
                )
                    .toAddr();
            data.queenStableSwap = getStableSwapData(queenStableSwap, account);
        }

        data.account.balance.underlying = underlyingToken
            .get(abi.encodeWithSelector(IERC20.balanceOf.selector, account))
            .toUint();
        data.account.balance.quote = bishopQuoteToken
            .get(abi.encodeWithSelector(IERC20.balanceOf.selector, account))
            .toUint();
        (
            data.account.balance.trancheQ,
            data.account.balance.trancheB,
            data.account.balance.trancheR
        ) = fund
            .get(abi.encodeWithSelector(FundV3.trancheAllBalanceOf.selector, account))
            .toUintUintUint();

        data.account.allowance.primaryMarketRouterUnderlying = underlyingToken
            .get(abi.encodeWithSelector(IERC20.allowance.selector, account, primaryMarketRouter))
            .toUint();
        data.account.allowance.primaryMarketRouterTrancheQ = fund
            .get(
            abi.encodeWithSelector(
                FundV3.trancheAllowance.selector,
                TRANCHE_Q,
                account,
                primaryMarketRouter
            )
        )
            .toUint();
        data.account.allowance.swapRouterUnderlying = underlyingToken
            .get(abi.encodeWithSelector(IERC20.allowance.selector, account, swapRouter))
            .toUint();
        data.account.allowance.swapRouterTrancheQ = fund
            .get(
            abi.encodeWithSelector(FundV3.trancheAllowance.selector, TRANCHE_Q, account, swapRouter)
        )
            .toUint();
        data.account.allowance.swapRouterTrancheB = fund
            .get(
            abi.encodeWithSelector(FundV3.trancheAllowance.selector, TRANCHE_B, account, swapRouter)
        )
            .toUint();
        data.account.allowance.swapRouterQuote = bishopQuoteToken
            .get(abi.encodeWithSelector(IERC20.allowance.selector, account, swapRouter))
            .toUint();
        data.account.allowance.flashSwapRouterTrancheR = fund
            .get(
            abi.encodeWithSelector(
                FundV3.trancheAllowance.selector,
                TRANCHE_R,
                account,
                flashSwapRouter
            )
        )
            .toUint();
        data.account.allowance.flashSwapRouterQuote = bishopQuoteToken
            .get(abi.encodeWithSelector(IERC20.allowance.selector, account, flashSwapRouter))
            .toUint();
        data.account.allowance.shareStakingTrancheQ = fund
            .get(
            abi.encodeWithSelector(
                FundV3.trancheAllowance.selector,
                TRANCHE_Q,
                account,
                shareStaking
            )
        )
            .toUint();
        data.account.allowance.shareStakingTrancheB = fund
            .get(
            abi.encodeWithSelector(
                FundV3.trancheAllowance.selector,
                TRANCHE_B,
                account,
                shareStaking
            )
        )
            .toUint();
        data.account.allowance.shareStakingTrancheR = fund
            .get(
            abi.encodeWithSelector(
                FundV3.trancheAllowance.selector,
                TRANCHE_R,
                account,
                shareStaking
            )
        )
            .toUint();
    }

    function getFundData(address fund) public view returns (FundData memory data) {
        address twapOracle =
            fund.get(abi.encodeWithSelector(FundV3(0).twapOracle.selector)).toAddr();

        data.isFundActive = fund
            .get(abi.encodeWithSelector(FundV3.isFundActive.selector, block.timestamp))
            .toBool();
        data.fundActivityStartTime = fund
            .get(abi.encodeWithSelector(FundV3(0).fundActivityStartTime.selector))
            .toUint();
        data.activityDelayTimeAfterRebalance = fund
            .get(abi.encodeWithSelector(FundV3(0).activityDelayTimeAfterRebalance.selector))
            .toUint();
        data.currentDay = fund.get(abi.encodeWithSelector(FundV3(0).currentDay.selector)).toUint();
        data.dailyProtocolFeeRate = fund
            .get(abi.encodeWithSelector(FundV3(0).dailyProtocolFeeRate.selector))
            .toUint();
        data.totalSupplyQ = fund
            .get(abi.encodeWithSelector(FundV3.trancheTotalSupply.selector, TRANCHE_Q))
            .toUint();
        data.totalSupplyB = fund
            .get(abi.encodeWithSelector(FundV3.trancheTotalSupply.selector, TRANCHE_B))
            .toUint();
        data.totalUnderlying = fund
            .get(abi.encodeWithSelector(FundV3.getTotalUnderlying.selector))
            .toUint();
        data.strategyUnderlying = fund
            .get(abi.encodeWithSelector(FundV3.getStrategyUnderlying.selector))
            .toUint();
        data.rebalanceSize = fund
            .get(abi.encodeWithSelector(FundV3.getRebalanceSize.selector))
            .toUint();
        data.upperRebalanceThreshold = fund
            .get(abi.encodeWithSelector(FundV3(0).upperRebalanceThreshold.selector))
            .toUint();
        data.lowerRebalanceThreshold = fund
            .get(abi.encodeWithSelector(FundV3(0).lowerRebalanceThreshold.selector))
            .toUint();
        data.splitRatio = fund.get(abi.encodeWithSelector(FundV3(0).splitRatio.selector)).toUint();
        data.latestUnderlyingPrice = getLatestPrice(twapOracle);
        if (data.splitRatio != 0) {
            (, data.navB, data.navR) = fund
                .get(
                abi.encodeWithSelector(FundV3.extrapolateNav.selector, data.latestUnderlyingPrice)
            )
                .toUintUintUint();
            data.currentInterestRate = fund
                .get(
                abi.encodeWithSelector(
                    FundV3(0).historicalInterestRate.selector,
                    data.currentDay - 1 days
                )
            )
                .toUint();
        }
        (
            data.lastRebalance.ratioB2Q,
            data.lastRebalance.ratioR2Q,
            data.lastRebalance.ratioBR,
            data.lastRebalance.timestamp
        ) = fund
            .get(
            abi.encodeWithSelector(
                FundV3.getRebalance.selector,
                data.rebalanceSize == 0 ? 0 : data.rebalanceSize - 1
            )
        )
            .toUintUintUintUint();
    }

    function getLatestPrice(address twapOracle) public view returns (uint256) {
        (bool success, bytes memory encodedPrice) =
            twapOracle.staticcall(abi.encodeWithSelector(ITwapOracleV2.getLatest.selector));
        if (success) {
            return abi.decode(encodedPrice, (uint256));
        } else {
            uint256 lastEpoch = (block.timestamp / 30 minutes) * 30 minutes;
            for (uint256 i = 0; i < 48; i++) {
                // Search for the latest TWAP
                uint256 twap =
                    twapOracle
                        .get(
                        abi.encodeWithSelector(
                            ITwapOracle.getTwap.selector,
                            lastEpoch - i * 30 minutes
                        )
                    )
                        .toUint();
                if (twap != 0) {
                    return twap;
                }
            }
        }
    }

    function getPrimaryMarketData(address primaryMarket)
        public
        view
        returns (PrimaryMarketData memory data)
    {
        data.fundCap = primaryMarket
            .get(abi.encodeWithSelector(PrimaryMarketV3(0).fundCap.selector))
            .toUint();
        data.redemptionFeeRate = primaryMarket
            .get(abi.encodeWithSelector(PrimaryMarketV3(0).redemptionFeeRate.selector))
            .toUint();
        data.mergeFeeRate = primaryMarket
            .get(abi.encodeWithSelector(PrimaryMarketV3(0).mergeFeeRate.selector))
            .toUint();
        data.redemptionQueueHead = primaryMarket
            .get(abi.encodeWithSelector(PrimaryMarketV3.getNewRedemptionQueueHead.selector))
            .toUint();
    }

    function getShareStakingData(
        address shareStaking,
        uint256 splitRatio,
        address account
    ) public returns (ShareStakingData memory data) {
        if (shareStaking == address(0)) {
            return data;
        }
        data.account.claimableChess = shareStaking
            .post(abi.encodeWithSelector(ShareStaking.claimableRewards.selector, account))
            .toUint();
        data.totalSupplyQ = shareStaking
            .get(abi.encodeWithSelector(ShareStaking.totalSupply.selector, TRANCHE_Q))
            .toUint();
        data.totalSupplyB = shareStaking
            .get(abi.encodeWithSelector(ShareStaking.totalSupply.selector, TRANCHE_B))
            .toUint();
        data.totalSupplyR = shareStaking
            .get(abi.encodeWithSelector(ShareStaking.totalSupply.selector, TRANCHE_R))
            .toUint();
        data.weightedSupply = shareStaking
            .get(
            abi.encodeWithSelector(
                ShareStaking.weightedBalance.selector,
                data.totalSupplyQ,
                data.totalSupplyB,
                data.totalSupplyR,
                splitRatio
            )
        )
            .toUint();
        data.workingSupply = shareStaking
            .get(abi.encodeWithSelector(ShareStaking.workingSupply.selector))
            .toUint();
        data.chessRate = shareStaking
            .get(abi.encodeWithSelector(ShareStaking.getRate.selector))
            .toUint();
        data.account.balanceQ = shareStaking
            .get(abi.encodeWithSelector(ShareStaking.trancheBalanceOf.selector, TRANCHE_Q, account))
            .toUint();
        data.account.balanceB = shareStaking
            .get(abi.encodeWithSelector(ShareStaking.trancheBalanceOf.selector, TRANCHE_B, account))
            .toUint();
        data.account.balanceR = shareStaking
            .get(abi.encodeWithSelector(ShareStaking.trancheBalanceOf.selector, TRANCHE_R, account))
            .toUint();
        data.account.weightedBalance = shareStaking
            .get(
            abi.encodeWithSelector(
                ShareStaking.weightedBalance.selector,
                data.account.balanceQ,
                data.account.balanceB,
                data.account.balanceR,
                splitRatio
            )
        )
            .toUint();
        data.account.workingBalance = shareStaking
            .get(abi.encodeWithSelector(ShareStaking.workingBalanceOf.selector, account))
            .toUint();
    }

    function getStableSwapData(address stableSwap, address account)
        public
        returns (StableSwapData memory data)
    {
        if (stableSwap == address(0)) {
            return data;
        }
        address lp =
            stableSwap.get(abi.encodeWithSelector(StableSwap(0).lpToken.selector)).toAddr();
        address swapBonus =
            lp.get(abi.encodeWithSelector(LiquidityGauge(0).swapBonus.selector)).toAddr();

        // Trigger checkpoint
        (
            data.account.claimableChess,
            data.account.claimableBonus,
            data.account.claimableQ,
            data.account.claimableB,
            data.account.claimableR,
            data.account.claimableQuote
        ) = lp
            .post(abi.encodeWithSelector(LiquidityGauge.claimableRewards.selector, account))
            .toUintUintUintUintUintUint();
        data.account.lpBalance = lp
            .get(abi.encodeWithSelector(LiquidityGauge(0).balanceOf.selector, account))
            .toUint();
        data.account.workingBalance = lp
            .get(abi.encodeWithSelector(LiquidityGauge.workingBalanceOf.selector, account))
            .toUint();

        data.feeRate = stableSwap
            .get(abi.encodeWithSelector(StableSwap(0).feeRate.selector))
            .toUint();
        data.adminFeeRate = stableSwap
            .get(abi.encodeWithSelector(StableSwap(0).adminFeeRate.selector))
            .toUint();
        data.ampl = stableSwap.get(abi.encodeWithSelector(StableSwap.getAmpl.selector)).toUint();
        data.lpTotalSupply = lp
            .get(abi.encodeWithSelector(LiquidityGauge(0).totalSupply.selector))
            .toUint();
        (bool success, bytes memory encodedOraclePrice) =
            stableSwap.staticcall(abi.encodeWithSelector(StableSwap.getOraclePrice.selector));
        if (success) {
            data.currentD = stableSwap
                .get(abi.encodeWithSelector(StableSwap.getCurrentD.selector))
                .toUint();
            data.currentPrice = stableSwap
                .get(abi.encodeWithSelector(StableSwap.getCurrentPrice.selector))
                .toUint();
            data.oraclePrice = abi.decode(encodedOraclePrice, (uint256));
            if (data.lpTotalSupply != 0) {
                // Handle rebalance
                stableSwap.post(abi.encodeWithSelector(StableSwap.sync.selector));
            }
        }
        data.lpWorkingSupply = lp
            .get(abi.encodeWithSelector(LiquidityGauge.workingSupply.selector))
            .toUint();
        (data.baseBalance, data.quoteBalance) = stableSwap
            .get(abi.encodeWithSelector(StableSwap.allBalances.selector))
            .toUintUint();
        data.chessRate = lp.get(abi.encodeWithSelector(LiquidityGauge.getRate.selector)).toUint();
        uint256 lpVersion =
            lp.get(abi.encodeWithSelector(LiquidityGauge(0).latestVersion.selector)).toUint();
        (
            data.lastDistributionQ,
            data.lastDistributionB,
            data.lastDistributionR,
            data.lastDistributionQuote
        ) = lp
            .get(abi.encodeWithSelector(LiquidityGauge(0).distributions.selector, lpVersion))
            .toUintUintUintUint();
        data.lastDistributionTotalSupply = lp
            .get(
            abi.encodeWithSelector(LiquidityGauge(0).distributionTotalSupplies.selector, lpVersion)
        )
            .toUint();
        data.bonusToken = swapBonus
            .get(abi.encodeWithSelector(SwapBonus(0).bonusToken.selector))
            .toAddr();
        data.bonusRate = block.timestamp <
            swapBonus.get(abi.encodeWithSelector(SwapBonus(0).endTimestamp.selector)).toUint()
            ? swapBonus.get(abi.encodeWithSelector(SwapBonus(0).ratePerSecond.selector)).toUint()
            : 0;
    }

    function getGovernanceData(address account) public view returns (GovernanceData memory data) {
        uint256 blockCurrentWeek = _endOfWeek(block.timestamp);

        data.chessRate = chessSchedule
            .get(abi.encodeWithSelector(IChessSchedule.getRate.selector, block.timestamp))
            .toUint();
        data.nextWeekChessRate = chessSchedule
            .get(abi.encodeWithSelector(IChessSchedule.getRate.selector, block.timestamp + 1 weeks))
            .toUint();

        data.votingEscrow.totalLocked = votingEscrow
            .get(abi.encodeWithSelector(VotingEscrowV2(0).totalLocked.selector))
            .toUint();
        data.votingEscrow.totalSupply = votingEscrow
            .get(abi.encodeWithSelector(VotingEscrowV2.totalSupply.selector))
            .toUint();
        data.votingEscrow.tradingWeekTotalSupply = votingEscrow
            .get(
            abi.encodeWithSelector(VotingEscrowV2.totalSupplyAtTimestamp.selector, blockCurrentWeek)
        )
            .toUint();
        data.votingEscrow.crossChainFees = new AnyCallSrcFee[](_otherChainCount);
        for (uint256 i = 0; i < _otherChainCount; i++) {
            AnyCallSrcFee memory fee = data.votingEscrow.crossChainFees[i];
            fee.chainId = otherChainIds[i];
            fee.fee = anyCallProxy
                .get(
                abi.encodeWithSignature(
                    "calcSrcFees(address,uint256,uint256)",
                    votingEscrow,
                    fee.chainId,
                    96
                )
            )
                .toUint();
        }
        (data.votingEscrow.account.amount, data.votingEscrow.account.unlockTime) = votingEscrow
            .get(abi.encodeWithSelector(VotingEscrowV2.getLockedBalance.selector, account))
            .toUintUint();

        data.interestRateBallot.tradingWeekTotalSupply = interestRateBallot
            .get(
            abi.encodeWithSelector(
                InterestRateBallotV2.totalSupplyAtWeek.selector,
                blockCurrentWeek
            )
        )
            .toUint();
        data.interestRateBallot.tradingWeekAverage = interestRateBallot
            .get(
            abi.encodeWithSelector(InterestRateBallotV2.averageAtWeek.selector, blockCurrentWeek)
        )
            .toUint();
        data.interestRateBallot.lastWeekAverage = interestRateBallot
            .get(
            abi.encodeWithSelector(
                InterestRateBallotV2.averageAtWeek.selector,
                blockCurrentWeek - 1 weeks
            )
        )
            .toUint();
        (
            data.interestRateBallot.account.amount,
            data.interestRateBallot.account.unlockTime,
            data.interestRateBallot.account.weight
        ) = interestRateBallot
            .get(abi.encodeWithSelector(InterestRateBallotV2.getReceipt.selector, account))
            .toUintUintUint();

        data.controllerBallot = getControllerBallotData(account);

        data.account.balance.nativeCurrency = account.balance;
        data.account.balance.chess = chess
            .get(abi.encodeWithSelector(IERC20.balanceOf.selector, account))
            .toUint();
        data.account.allowance.votingEscrowChess = chess
            .get(abi.encodeWithSelector(IERC20.allowance.selector, account, votingEscrow))
            .toUint();
    }

    function getControllerBallotData(address account)
        public
        view
        returns (ControllerBallotData memory data)
    {
        data.pools = controllerBallot
            .get(abi.encodeWithSelector(ControllerBallotV2.getPools.selector))
            .toAddrs();
        data.currentSums = new uint256[](data.pools.length);
        data.lastWeekSums = new uint256[](data.pools.length);
        (data.account.amount, data.account.unlockTime) = controllerBallot
            .get(abi.encodeWithSelector(ControllerBallotV2(0).userLockedBalances.selector, account))
            .toUintUint();
        data.account.weights = new uint256[](data.pools.length);
        uint256 blockCurrentWeek = _endOfWeek(block.timestamp);
        for (uint256 i = 0; i < data.pools.length; i++) {
            address pool = data.pools[i];
            data.currentSums[i] = controllerBallot
                .get(
                abi.encodeWithSelector(
                    ControllerBallotV2.sumAtWeek.selector,
                    pool,
                    blockCurrentWeek
                )
            )
                .toUint();
            data.lastWeekSums[i] = controllerBallot
                .get(
                abi.encodeWithSelector(
                    ControllerBallotV2.sumAtWeek.selector,
                    pool,
                    blockCurrentWeek - 1 weeks
                )
            )
                .toUint();
            data.account.weights[i] = controllerBallot
                .get(
                abi.encodeWithSelector(ControllerBallotV2(0).userWeights.selector, account, pool)
            )
                .toUint();
        }
    }

    function getFeeDistributorData(address feeDistributor, address account)
        public
        returns (FeeDistributorData memory data)
    {
        data.account.claimableRewards = feeDistributor
            .post(abi.encodeWithSelector(FeeDistributor.userCheckpoint.selector, account))
            .toUint();
        data.account.currentBalance = feeDistributor
            .get(abi.encodeWithSelector(FeeDistributor(0).userLastBalances.selector, account))
            .toUint();
        (data.account.amount, data.account.unlockTime) = feeDistributor
            .get(abi.encodeWithSelector(FeeDistributor(0).userLockedBalances.selector, account))
            .toUintUint();
        uint256 blockCurrentWeek = _endOfWeek(block.timestamp);
        data.currentRewards = feeDistributor
            .get(
            abi.encodeWithSelector(
                FeeDistributor(0).rewardsPerWeek.selector,
                blockCurrentWeek - 1 weeks
            )
        )
            .toUint();
        data.currentSupply = feeDistributor
            .get(
            abi.encodeWithSelector(
                FeeDistributor(0).veSupplyPerWeek.selector,
                blockCurrentWeek - 1 weeks
            )
        )
            .toUint();
        data.tradingWeekTotalSupply = feeDistributor
            .get(
            abi.encodeWithSelector(FeeDistributor.totalSupplyAtTimestamp.selector, blockCurrentWeek)
        )
            .toUint();
        data.adminFeeRate = feeDistributor
            .get(abi.encodeWithSelector(FeeDistributor(0).adminFeeRate.selector))
            .toUint();
    }

    function getExternalSwapData(
        address router,
        address token0,
        address token1
    ) public view returns (ExternalSwapData memory data) {
        IUniswapV2Pair pair =
            IUniswapV2Pair(
                router
                    .get(abi.encodeWithSelector(IUniswapV2Router01.factory.selector))
                    .toAddr()
                    .get(abi.encodeWithSelector(IUniswapV2Factory.getPair.selector, token0, token1))
                    .toAddr()
            );
        data.symbol0 = token0
            .get(abi.encodeWithSelector(IUniswapV2Pair.symbol.selector))
            .toString();
        data.symbol1 = token1
            .get(abi.encodeWithSelector(IUniswapV2Pair.symbol.selector))
            .toString();
        if (
            address(pair).get(abi.encodeWithSelector(IUniswapV2Pair.token0.selector)).toAddr() ==
            token0
        ) {
            (data.reserve0, data.reserve1, ) = pair.getReserves();
        } else {
            (data.reserve1, data.reserve0, ) = pair.getReserves();
        }
    }

    function getCurveData(address curveRouter, address account)
        public
        returns (CurveData memory data)
    {
        data.pool = getCurvePoolData(curveRouter, account);
        data.gauge = getCurveGaugeData(curveRouter, account);
    }

    function getCurvePoolData(address curveRouter, address account)
        public
        view
        returns (CurvePoolData memory data)
    {
        address pool =
            curveRouter.get(abi.encodeWithSelector(CurveRouter(0).curvePool.selector)).toAddr();
        address lp =
            curveRouter
                .get(abi.encodeWithSelector(CurveRouter(0).curveLiquidityToken.selector))
                .toAddr();
        data.pool = pool;
        data.lpToken = lp;
        data.lpTotalSupply = lp.get(abi.encodeWithSignature("totalSupply()")).toUint();
        data.coins[0] = pool.get(abi.encodeWithSignature("coins(uint256)", 0)).toAddr();
        data.coins[1] = pool.get(abi.encodeWithSignature("coins(uint256)", 1)).toAddr();
        data.balances[0] = pool.get(abi.encodeWithSignature("balances(uint256)", 0)).toUint();
        data.balances[1] = pool.get(abi.encodeWithSignature("balances(uint256)", 1)).toUint();
        if (data.lpTotalSupply > 0) {
            data.fee = pool.get(abi.encodeWithSignature("fee()")).toUint();
            data.prices[0] =
                pool
                    .get(abi.encodeWithSignature("get_dy(uint256,uint256,uint256)", 0, 1, 1e14))
                    .toUint() *
                1e4;
            data.prices[1] =
                pool
                    .get(abi.encodeWithSignature("get_dy(uint256,uint256,uint256)", 1, 0, 1e14))
                    .toUint() *
                1e4;
            data.lpPrice = pool.get(abi.encodeWithSignature("lp_price()")).toUint();
        }

        data.account.balances[0] = data.coins[0]
            .get(abi.encodeWithSelector(IERC20.balanceOf.selector, account))
            .toUint();
        data.account.balances[1] = data.coins[1]
            .get(abi.encodeWithSelector(IERC20.balanceOf.selector, account))
            .toUint();
        data.account.allowances[0] = data.coins[0]
            .get(abi.encodeWithSelector(IERC20.allowance.selector, account, curveRouter))
            .toUint();
        data.account.allowances[1] = data.coins[1]
            .get(abi.encodeWithSelector(IERC20.allowance.selector, account, curveRouter))
            .toUint();
        data.account.lpBalance = lp
            .get(abi.encodeWithSelector(IERC20.balanceOf.selector, account))
            .toUint();
    }

    function getCurveGaugeData(address curveRouter, address account)
        public
        returns (CurveGaugeData memory data)
    {
        address gauge =
            curveRouter
                .get(abi.encodeWithSelector(CurveRouter(0).tranchessLiquidityGauge.selector))
                .toAddr();
        address lp =
            curveRouter
                .get(abi.encodeWithSelector(CurveRouter(0).curveLiquidityToken.selector))
                .toAddr();
        (data.account.claimableChess, data.account.claimableBonus) = gauge
            .post(abi.encodeWithSelector(LiquidityGaugeCurve.claimableRewards.selector, account))
            .toUintUint();
        data.account.balance = gauge
            .post(abi.encodeWithSelector(LiquidityGaugeCurve(0).balanceOf.selector, account))
            .toUint();
        data.account.allowance = lp
            .get(abi.encodeWithSelector(IERC20.allowance.selector, account, gauge))
            .toUint();
        data.account.workingBalance = gauge
            .post(abi.encodeWithSelector(LiquidityGaugeCurve.workingBalanceOf.selector, account))
            .toUint();

        data.gauge = gauge;
        data.chessRate = gauge
            .get(abi.encodeWithSelector(LiquidityGaugeCurve.getRate.selector))
            .toUint();
        data.totalSupply = gauge
            .get(abi.encodeWithSelector(LiquidityGaugeCurve(0).totalSupply.selector))
            .toUint();
        data.workingSupply = gauge
            .get(abi.encodeWithSelector(LiquidityGaugeCurve.workingSupply.selector))
            .toUint();
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "../utils/SafeDecimalMath.sol";
import "../utils/CoreUtility.sol";

import "../interfaces/IPrimaryMarketV3.sol";
import "../interfaces/IFundV3.sol";
import "../interfaces/IFundForPrimaryMarketV3.sol";
import "../interfaces/IFundForStrategy.sol";
import "../interfaces/IShareV2.sol";
import "../interfaces/ITwapOracleV2.sol";
import "../interfaces/IAprOracle.sol";
import "../interfaces/IBallot.sol";
import "../interfaces/IVotingEscrow.sol";

import "./FundRolesV2.sol";

contract FundV3 is
    IFundV3,
    IFundForPrimaryMarketV3,
    IFundForStrategy,
    Ownable,
    ReentrancyGuard,
    FundRolesV2,
    CoreUtility
{
    using Math for uint256;
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;
    using SafeERC20 for IERC20;

    event ProfitReported(uint256 profit, uint256 performanceFee);
    event LossReported(uint256 loss);
    event DailyProtocolFeeRateUpdated(uint256 newDailyProtocolFeeRate);
    event TwapOracleUpdated(address newTwapOracle);
    event AprOracleUpdated(address newAprOracle);
    event BallotUpdated(address newBallot);
    event FeeCollectorUpdated(address newFeeCollector);
    event ActivityDelayTimeUpdated(uint256 delayTime);
    event SplitRatioUpdated(uint256 newSplitRatio);
    event FeeDebtPaid(uint256 amount);
    event TotalDebtUpdated(uint256 newTotalDebt);

    uint256 private constant UNIT = 1e18;
    uint256 private constant MAX_INTEREST_RATE = 0.2e18; // 20% daily
    uint256 private constant MAX_DAILY_PROTOCOL_FEE_RATE = 0.05e18; // 5% daily rate

    /// @notice Upper bound of `NAV_R / NAV_B` to trigger a rebalance.
    uint256 public immutable upperRebalanceThreshold;

    /// @notice Lower bound of `NAV_R / NAV_B` to trigger a rebalance.
    uint256 public immutable lowerRebalanceThreshold;

    /// @notice Address of the underlying token.
    address public immutable override tokenUnderlying;

    /// @notice A multipler that normalizes an underlying balance to 18 decimal places.
    uint256 public immutable override underlyingDecimalMultiplier;

    /// @notice Daily protocol fee rate.
    uint256 public dailyProtocolFeeRate;

    /// @notice TwapOracle address for the underlying asset.
    ITwapOracleV2 public override twapOracle;

    /// @notice AprOracle address.
    IAprOracle public aprOracle;

    /// @notice Address of the interest rate ballot.
    IBallot public ballot;

    /// @notice Fee Collector address.
    address public override feeCollector;

    /// @notice End timestamp of the current trading day.
    ///         A trading day starts at UTC time `SETTLEMENT_TIME` of a day (inclusive)
    ///         and ends at the same time of the next day (exclusive).
    uint256 public override currentDay;

    /// @notice The amount of BISHOP received by splitting one QUEEN.
    ///         This ratio changes on every rebalance.
    uint256 public override splitRatio;

    /// @dev Mapping of rebalance version => splitRatio.
    mapping(uint256 => uint256) private _historicalSplitRatio;

    /// @notice Start timestamp of the current primary market activity window.
    uint256 public override fundActivityStartTime;

    uint256 public activityDelayTimeAfterRebalance;

    /// @dev Historical rebalances. Rebalances are often accessed in loops with bounds checking.
    ///      So we store them in a fixed-length array, in order to make compiler-generated
    ///      bounds checking on every access cheaper. The actual length of this array is stored in
    ///      `_rebalanceSize` and should be explicitly checked when necessary.
    Rebalance[65535] private _rebalances;

    /// @dev Historical rebalance count.
    uint256 private _rebalanceSize;

    /// @dev Total share supply of the three tranches. They are always rebalanced to the latest
    ///      version.
    uint256[TRANCHE_COUNT] private _totalSupplies;

    /// @dev Mapping of account => share balance of the three tranches.
    ///      Rebalance versions are stored in a separate mapping `_balanceVersions`.
    mapping(address => uint256[TRANCHE_COUNT]) private _balances;

    /// @dev Rebalance version mapping for `_balances`.
    mapping(address => uint256) private _balanceVersions;

    /// @dev Mapping of owner => spender => share allowance of the three tranches.
    ///      Rebalance versions are stored in a separate mapping `_allowanceVersions`.
    mapping(address => mapping(address => uint256[TRANCHE_COUNT])) private _allowances;

    /// @dev Rebalance version mapping for `_allowances`.
    mapping(address => mapping(address => uint256)) private _allowanceVersions;

    /// @dev Mapping of trading day => NAV of BISHOP.
    mapping(uint256 => uint256) private _historicalNavB;

    /// @dev Mapping of trading day => NAV of ROOK.
    mapping(uint256 => uint256) private _historicalNavR;

    /// @notice Mapping of trading day => equivalent BISHOP supply.
    ///
    ///         Key is the end timestamp of a trading day. Value is the total supply of BISHOP,
    ///         as if all QUEEN are split.
    mapping(uint256 => uint256) public override historicalEquivalentTotalB;

    /// @notice Mapping of trading day => underlying assets in the fund.
    ///
    ///         Key is the end timestamp of a trading day. Value is the underlying assets in
    ///         the fund after settlement of that trading day.
    mapping(uint256 => uint256) public override historicalUnderlying;

    /// @notice Mapping of trading week => interest rate of BISHOP.
    ///
    ///         Key is the end timestamp of a trading day. Value is the interest rate captured
    ///         after settlement of that day, which will be effective in the following trading day.
    mapping(uint256 => uint256) public historicalInterestRate;

    /// @notice Amount of fee not transfered to the fee collector yet.
    uint256 public feeDebt;

    /// @notice Amount of redemption underlying that the fund owes the primary market
    uint256 public redemptionDebt;

    /// @dev Sum of the fee debt and redemption debts of all primary markets.
    uint256 private _totalDebt;

    uint256 private _strategyUnderlying;

    struct ConstructorParameters {
        address tokenUnderlying;
        uint256 underlyingDecimals;
        address tokenQ;
        address tokenB;
        address tokenR;
        address primaryMarket;
        address strategy;
        uint256 dailyProtocolFeeRate;
        uint256 upperRebalanceThreshold;
        uint256 lowerRebalanceThreshold;
        address twapOracle;
        address aprOracle;
        address ballot;
        address feeCollector;
    }

    constructor(ConstructorParameters memory params)
        public
        Ownable()
        FundRolesV2(
            params.tokenQ,
            params.tokenB,
            params.tokenR,
            params.primaryMarket,
            params.strategy
        )
    {
        tokenUnderlying = params.tokenUnderlying;
        require(params.underlyingDecimals <= 18, "Underlying decimals larger than 18");
        underlyingDecimalMultiplier = 10**(18 - params.underlyingDecimals);
        _updateDailyProtocolFeeRate(params.dailyProtocolFeeRate);
        upperRebalanceThreshold = params.upperRebalanceThreshold;
        lowerRebalanceThreshold = params.lowerRebalanceThreshold;
        _updateTwapOracle(params.twapOracle);
        _updateAprOracle(params.aprOracle);
        _updateBallot(params.ballot);
        _updateFeeCollector(params.feeCollector);
        _updateActivityDelayTime(30 minutes);
    }

    function initialize(
        uint256 newSplitRatio,
        uint256 lastNavB,
        uint256 lastNavR,
        uint256 strategyUnderlying
    ) external onlyOwner {
        require(splitRatio == 0 && currentDay == 0, "Already initialized");
        require(
            newSplitRatio != 0 && lastNavB >= UNIT && !_shouldTriggerRebalance(lastNavB, lastNavR),
            "Invalid parameters"
        );
        currentDay = endOfDay(block.timestamp);
        splitRatio = newSplitRatio;
        _historicalSplitRatio[0] = newSplitRatio;
        emit SplitRatioUpdated(newSplitRatio);
        uint256 lastDay = currentDay - 1 days;
        uint256 lastDayPrice = twapOracle.getTwap(lastDay);
        require(lastDayPrice != 0, "Price not available"); // required to do the first creation
        _historicalNavB[lastDay] = lastNavB;
        _historicalNavR[lastDay] = lastNavR;
        _strategyUnderlying = strategyUnderlying;
        uint256 lastInterestRate = _updateInterestRate(lastDay);
        historicalInterestRate[lastDay] = lastInterestRate;
        emit Settled(lastDay, lastNavB, lastNavR, lastInterestRate);
        fundActivityStartTime = lastDay;
    }

    /// @notice UTC time of a day when the fund settles.
    function settlementTime() external pure returns (uint256) {
        return SETTLEMENT_TIME;
    }

    /// @notice Return end timestamp of the trading day containing a given timestamp.
    ///
    ///         A trading day starts at UTC time `SETTLEMENT_TIME` of a day (inclusive)
    ///         and ends at the same time of the next day (exclusive).
    /// @param timestamp The given timestamp
    /// @return End timestamp of the trading day.
    function endOfDay(uint256 timestamp) public pure override returns (uint256) {
        return ((timestamp.add(1 days) - SETTLEMENT_TIME) / 1 days) * 1 days + SETTLEMENT_TIME;
    }

    /// @notice Return end timestamp of the trading week containing a given timestamp.
    ///
    ///         A trading week starts at UTC time `SETTLEMENT_TIME` on a Thursday (inclusive)
    ///         and ends at the same time of the next Thursday (exclusive).
    /// @param timestamp The given timestamp
    /// @return End timestamp of the trading week.
    function endOfWeek(uint256 timestamp) external pure returns (uint256) {
        return _endOfWeek(timestamp);
    }

    function tokenQ() external view override returns (address) {
        return _tokenQ;
    }

    function tokenB() external view override returns (address) {
        return _tokenB;
    }

    function tokenR() external view override returns (address) {
        return _tokenR;
    }

    function tokenShare(uint256 tranche) external view override returns (address) {
        return _getShare(tranche);
    }

    function primaryMarket() external view override returns (address) {
        return _primaryMarket;
    }

    function primaryMarketUpdateProposal() external view override returns (address, uint256) {
        return (_proposedPrimaryMarket, _proposedPrimaryMarketTimestamp);
    }

    function strategy() external view override returns (address) {
        return _strategy;
    }

    function strategyUpdateProposal() external view override returns (address, uint256) {
        return (_proposedStrategy, _proposedStrategyTimestamp);
    }

    /// @notice Return the status of the fund contract.
    /// @param timestamp Timestamp to assess
    /// @return True if the fund contract is active
    function isFundActive(uint256 timestamp) public view override returns (bool) {
        return timestamp >= fundActivityStartTime;
    }

    function getTotalUnderlying() public view override returns (uint256) {
        uint256 hot = IERC20(tokenUnderlying).balanceOf(address(this));
        return hot.add(_strategyUnderlying).sub(_totalDebt);
    }

    function getStrategyUnderlying() external view override returns (uint256) {
        return _strategyUnderlying;
    }

    function getTotalDebt() external view override returns (uint256) {
        return _totalDebt;
    }

    /// @notice Equivalent BISHOP supply, as if all QUEEN are split.
    function getEquivalentTotalB() public view override returns (uint256) {
        return _totalSupplies[TRANCHE_Q].multiplyDecimal(splitRatio).add(_totalSupplies[TRANCHE_B]);
    }

    /// @notice Equivalent QUEEN supply, as if all BISHOP and ROOK are merged.
    function getEquivalentTotalQ() external view override returns (uint256) {
        return _totalSupplies[TRANCHE_B].divideDecimal(splitRatio).add(_totalSupplies[TRANCHE_Q]);
    }

    /// @notice Return the rebalance matrix at a given index. A zero struct is returned
    ///         if `index` is out of bound.
    /// @param index Rebalance index
    /// @return A rebalance matrix
    function getRebalance(uint256 index) external view override returns (Rebalance memory) {
        return _rebalances[index];
    }

    /// @notice Return timestamp of the transaction triggering the rebalance at a given index.
    ///         Zero is returned if `index` is out of bound.
    /// @param index Rebalance index
    /// @return Timestamp of the rebalance
    function getRebalanceTimestamp(uint256 index) external view override returns (uint256) {
        return _rebalances[index].timestamp;
    }

    /// @notice Return the number of historical rebalances.
    function getRebalanceSize() external view override returns (uint256) {
        return _rebalanceSize;
    }

    /// @notice Return split ratio at a given version.
    ///         Zero is returned if `version` is invalid.
    /// @param version Rebalance version
    /// @return Split ratio of the version
    function historicalSplitRatio(uint256 version) external view override returns (uint256) {
        return _historicalSplitRatio[version];
    }

    /// @notice Return NAV of BISHOP and ROOK of the given trading day.
    /// @param day End timestamp of a trading day
    /// @return navB NAV of BISHOP
    /// @return navR NAV of ROOK
    function historicalNavs(uint256 day)
        external
        view
        override
        returns (uint256 navB, uint256 navR)
    {
        return (_historicalNavB[day], _historicalNavR[day]);
    }

    /// @notice Estimate the current NAV of all tranches, considering underlying price change,
    ///         accrued protocol fee and accrued interest since the previous settlement.
    ///
    ///         The extrapolation uses simple interest instead of daily compound interest in
    ///         calculating protocol fee and BISHOP's interest. There may be significant error
    ///         in the returned values when `timestamp` is far beyond the last settlement.
    /// @param price Price of the underlying asset (18 decimal places)
    /// @return navSum Sum of the estimated NAV of BISHOP and ROOK
    /// @return navB Estimated NAV of BISHOP
    /// @return navROrZero Estimated NAV of ROOK, or zero if the NAV is negative
    function extrapolateNav(uint256 price)
        external
        view
        override
        returns (
            uint256 navSum,
            uint256 navB,
            uint256 navROrZero
        )
    {
        uint256 settledDay = currentDay - 1 days;
        uint256 underlying = getTotalUnderlying();
        uint256 protocolFee =
            underlying.multiplyDecimal(dailyProtocolFeeRate).mul(block.timestamp - settledDay).div(
                1 days
            );
        underlying = underlying.sub(protocolFee);
        return
            _extrapolateNav(block.timestamp, settledDay, price, getEquivalentTotalB(), underlying);
    }

    function _extrapolateNav(
        uint256 timestamp,
        uint256 settledDay,
        uint256 price,
        uint256 equivalentTotalB,
        uint256 underlying
    )
        private
        view
        returns (
            uint256 navSum,
            uint256 navB,
            uint256 navROrZero
        )
    {
        navB = _historicalNavB[settledDay];
        if (equivalentTotalB > 0) {
            navSum = price.mul(underlying.mul(underlyingDecimalMultiplier)).div(equivalentTotalB);
            navB = navB.multiplyDecimal(
                historicalInterestRate[settledDay].mul(timestamp - settledDay).div(1 days).add(UNIT)
            );
            navROrZero = navSum >= navB ? navSum - navB : 0;
        } else {
            // If the fund is empty, use NAV in the last day
            navROrZero = _historicalNavR[settledDay];
            navSum = navB + navROrZero;
        }
    }

    /// @notice Transform share amounts according to the rebalance at a given index.
    ///         This function performs no bounds checking on the given index. A non-existent
    ///         rebalance transforms anything to a zero vector.
    /// @param amountQ Amount of QUEEN before the rebalance
    /// @param amountB Amount of BISHOP before the rebalance
    /// @param amountR Amount of ROOK before the rebalance
    /// @param index Rebalance index
    /// @return newAmountQ Amount of QUEEN after the rebalance
    /// @return newAmountB Amount of BISHOP after the rebalance
    /// @return newAmountR Amount of ROOK after the rebalance
    function doRebalance(
        uint256 amountQ,
        uint256 amountB,
        uint256 amountR,
        uint256 index
    )
        public
        view
        override
        returns (
            uint256 newAmountQ,
            uint256 newAmountB,
            uint256 newAmountR
        )
    {
        Rebalance storage rebalance = _rebalances[index];
        newAmountQ = amountQ.add(amountB.multiplyDecimal(rebalance.ratioB2Q)).add(
            amountR.multiplyDecimal(rebalance.ratioR2Q)
        );
        uint256 ratioBR = rebalance.ratioBR; // Gas saver
        newAmountB = amountB.multiplyDecimal(ratioBR);
        newAmountR = amountR.multiplyDecimal(ratioBR);
    }

    /// @notice Transform share amounts according to rebalances in a given index range,
    ///         This function performs no bounds checking on the given indices. The original amounts
    ///         are returned if `fromIndex` is no less than `toIndex`. A zero vector is returned
    ///         if `toIndex` is greater than the number of existing rebalances.
    /// @param amountQ Amount of QUEEN before the rebalance
    /// @param amountB Amount of BISHOP before the rebalance
    /// @param amountR Amount of ROOK before the rebalance
    /// @param fromIndex Starting of the rebalance index range, inclusive
    /// @param toIndex End of the rebalance index range, exclusive
    /// @return newAmountQ Amount of QUEEN after the rebalance
    /// @return newAmountB Amount of BISHOP after the rebalance
    /// @return newAmountR Amount of ROOK after the rebalance
    function batchRebalance(
        uint256 amountQ,
        uint256 amountB,
        uint256 amountR,
        uint256 fromIndex,
        uint256 toIndex
    )
        external
        view
        override
        returns (
            uint256 newAmountQ,
            uint256 newAmountB,
            uint256 newAmountR
        )
    {
        for (uint256 i = fromIndex; i < toIndex; i++) {
            (amountQ, amountB, amountR) = doRebalance(amountQ, amountB, amountR, i);
        }
        newAmountQ = amountQ;
        newAmountB = amountB;
        newAmountR = amountR;
    }

    /// @notice Transform share balance to a given rebalance version, or to the latest version
    ///         if `targetVersion` is zero.
    /// @param account Account of the balance to rebalance
    /// @param targetVersion The target rebalance version, or zero for the latest version
    function refreshBalance(address account, uint256 targetVersion) external override {
        if (targetVersion > 0) {
            require(targetVersion <= _rebalanceSize, "Target version out of bound");
        }
        _refreshBalance(account, targetVersion);
    }

    /// @notice Transform allowance to a given rebalance version, or to the latest version
    ///         if `targetVersion` is zero.
    /// @param owner Owner of the allowance to rebalance
    /// @param spender Spender of the allowance to rebalance
    /// @param targetVersion The target rebalance version, or zero for the latest version
    function refreshAllowance(
        address owner,
        address spender,
        uint256 targetVersion
    ) external override {
        if (targetVersion > 0) {
            require(targetVersion <= _rebalanceSize, "Target version out of bound");
        }
        _refreshAllowance(owner, spender, targetVersion);
    }

    function trancheBalanceOf(uint256 tranche, address account)
        external
        view
        override
        returns (uint256)
    {
        uint256 amountQ = _balances[account][TRANCHE_Q];
        uint256 amountB = _balances[account][TRANCHE_B];
        uint256 amountR = _balances[account][TRANCHE_R];

        if (tranche == TRANCHE_Q) {
            if (amountQ == 0 && amountB == 0 && amountR == 0) return 0;
        } else if (tranche == TRANCHE_B) {
            if (amountB == 0) return 0;
        } else {
            if (amountR == 0) return 0;
        }

        uint256 size = _rebalanceSize; // Gas saver
        for (uint256 i = _balanceVersions[account]; i < size; i++) {
            (amountQ, amountB, amountR) = doRebalance(amountQ, amountB, amountR, i);
        }

        if (tranche == TRANCHE_Q) {
            return amountQ;
        } else if (tranche == TRANCHE_B) {
            return amountB;
        } else {
            return amountR;
        }
    }

    /// @notice Return all three share balances transformed to the latest rebalance version.
    /// @param account Owner of the shares
    function trancheAllBalanceOf(address account)
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 amountQ = _balances[account][TRANCHE_Q];
        uint256 amountB = _balances[account][TRANCHE_B];
        uint256 amountR = _balances[account][TRANCHE_R];

        uint256 size = _rebalanceSize; // Gas saver
        for (uint256 i = _balanceVersions[account]; i < size; i++) {
            (amountQ, amountB, amountR) = doRebalance(amountQ, amountB, amountR, i);
        }

        return (amountQ, amountB, amountR);
    }

    function trancheBalanceVersion(address account) external view override returns (uint256) {
        return _balanceVersions[account];
    }

    function trancheAllowance(
        uint256 tranche,
        address owner,
        address spender
    ) external view override returns (uint256) {
        uint256 allowanceQ = _allowances[owner][spender][TRANCHE_Q];
        uint256 allowanceB = _allowances[owner][spender][TRANCHE_B];
        uint256 allowanceR = _allowances[owner][spender][TRANCHE_R];

        if (tranche == TRANCHE_Q) {
            if (allowanceQ == 0) return 0;
        } else if (tranche == TRANCHE_B) {
            if (allowanceB == 0) return 0;
        } else {
            if (allowanceR == 0) return 0;
        }

        uint256 size = _rebalanceSize; // Gas saver
        for (uint256 i = _allowanceVersions[owner][spender]; i < size; i++) {
            (allowanceQ, allowanceB, allowanceR) = _rebalanceAllowance(
                allowanceQ,
                allowanceB,
                allowanceR,
                i
            );
        }

        if (tranche == TRANCHE_Q) {
            return allowanceQ;
        } else if (tranche == TRANCHE_B) {
            return allowanceB;
        } else {
            return allowanceR;
        }
    }

    function trancheAllowanceVersion(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowanceVersions[owner][spender];
    }

    function trancheTransfer(
        uint256 tranche,
        address recipient,
        uint256 amount,
        uint256 version
    ) external override onlyCurrentVersion(version) {
        _refreshBalance(msg.sender, version);
        _refreshBalance(recipient, version);
        _transfer(tranche, msg.sender, recipient, amount);
    }

    function trancheTransferFrom(
        uint256 tranche,
        address sender,
        address recipient,
        uint256 amount,
        uint256 version
    ) external override onlyCurrentVersion(version) {
        _refreshAllowance(sender, msg.sender, version);
        uint256 newAllowance =
            _allowances[sender][msg.sender][tranche].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            );
        _approve(tranche, sender, msg.sender, newAllowance);
        _refreshBalance(sender, version);
        _refreshBalance(recipient, version);
        _transfer(tranche, sender, recipient, amount);
    }

    function trancheApprove(
        uint256 tranche,
        address spender,
        uint256 amount,
        uint256 version
    ) external override onlyCurrentVersion(version) {
        _refreshAllowance(msg.sender, spender, version);
        _approve(tranche, msg.sender, spender, amount);
    }

    function trancheTotalSupply(uint256 tranche) external view override returns (uint256) {
        return _totalSupplies[tranche];
    }

    function primaryMarketMint(
        uint256 tranche,
        address account,
        uint256 amount,
        uint256 version
    ) external override onlyPrimaryMarket onlyCurrentVersion(version) {
        _refreshBalance(account, version);
        _mint(tranche, account, amount);
    }

    function primaryMarketBurn(
        uint256 tranche,
        address account,
        uint256 amount,
        uint256 version
    ) external override onlyPrimaryMarket onlyCurrentVersion(version) {
        _refreshBalance(account, version);
        _burn(tranche, account, amount);
    }

    function shareTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) public override {
        uint256 tranche = _getTranche(msg.sender);
        if (tranche != TRANCHE_Q) {
            require(isFundActive(block.timestamp), "Transfer is inactive");
        }
        _refreshBalance(sender, _rebalanceSize);
        _refreshBalance(recipient, _rebalanceSize);
        _transfer(tranche, sender, recipient, amount);
    }

    function shareTransferFrom(
        address spender,
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (uint256 newAllowance) {
        uint256 tranche = _getTranche(msg.sender);
        shareTransfer(sender, recipient, amount);
        _refreshAllowance(sender, spender, _rebalanceSize);
        newAllowance = _allowances[sender][spender][tranche].sub(
            amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(tranche, sender, spender, newAllowance);
    }

    function shareApprove(
        address owner,
        address spender,
        uint256 amount
    ) external override {
        uint256 tranche = _getTranche(msg.sender);
        _refreshAllowance(owner, spender, _rebalanceSize);
        _approve(tranche, owner, spender, amount);
    }

    function shareIncreaseAllowance(
        address sender,
        address spender,
        uint256 addedValue
    ) external override returns (uint256 newAllowance) {
        uint256 tranche = _getTranche(msg.sender);
        _refreshAllowance(sender, spender, _rebalanceSize);
        newAllowance = _allowances[sender][spender][tranche].add(addedValue);
        _approve(tranche, sender, spender, newAllowance);
    }

    function shareDecreaseAllowance(
        address sender,
        address spender,
        uint256 subtractedValue
    ) external override returns (uint256 newAllowance) {
        uint256 tranche = _getTranche(msg.sender);
        _refreshAllowance(sender, spender, _rebalanceSize);
        newAllowance = _allowances[sender][spender][tranche].sub(subtractedValue);
        _approve(tranche, sender, spender, newAllowance);
    }

    function _transfer(
        uint256 tranche,
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender][tranche] = _balances[sender][tranche].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient][tranche] = _balances[recipient][tranche].add(amount);
        IShareV2(_getShare(tranche)).fundEmitTransfer(sender, recipient, amount);
    }

    function _mint(
        uint256 tranche,
        address account,
        uint256 amount
    ) private {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupplies[tranche] = _totalSupplies[tranche].add(amount);
        _balances[account][tranche] = _balances[account][tranche].add(amount);
        IShareV2(_getShare(tranche)).fundEmitTransfer(address(0), account, amount);
    }

    function _burn(
        uint256 tranche,
        address account,
        uint256 amount
    ) private {
        require(account != address(0), "ERC20: burn from the zero address");
        _balances[account][tranche] = _balances[account][tranche].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupplies[tranche] = _totalSupplies[tranche].sub(amount);
        IShareV2(_getShare(tranche)).fundEmitTransfer(account, address(0), amount);
    }

    function _approve(
        uint256 tranche,
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender][tranche] = amount;
        IShareV2(_getShare(tranche)).fundEmitApproval(owner, spender, amount);
    }

    /// @notice Settle the current trading day. Settlement includes the following changes
    ///         to the fund.
    ///
    ///         1. Charge protocol fee of the day.
    ///         2. Settle all pending creations and redemptions from the primary market.
    ///         3. Calculate NAV of the day and trigger rebalance if necessary.
    ///         4. Capture new interest rate for BISHOP.
    function settle() external nonReentrant {
        uint256 day = currentDay;
        require(day != 0, "Not initialized");
        require(block.timestamp >= day, "The current trading day does not end yet");
        uint256 price = twapOracle.getTwap(day);
        require(price != 0, "Underlying price for settlement is not ready yet");

        _collectFee();

        IPrimaryMarketV3(_primaryMarket).settle(day);

        _payFeeDebt();

        // Calculate NAV
        uint256 equivalentTotalB = getEquivalentTotalB();
        uint256 underlying = getTotalUnderlying();
        (uint256 navSum, uint256 navB, uint256 navR) =
            _extrapolateNav(day, day - 1 days, price, equivalentTotalB, underlying);

        if (_shouldTriggerRebalance(navB, navR)) {
            uint256 newSplitRatio = splitRatio.multiplyDecimal(navSum) / 2;
            _triggerRebalance(day, navSum, navB, navR, newSplitRatio);
            navB = UNIT;
            navR = UNIT;
            equivalentTotalB = getEquivalentTotalB();
            fundActivityStartTime = day + activityDelayTimeAfterRebalance;
        } else {
            fundActivityStartTime = day;
        }

        uint256 interestRate = _updateInterestRate(day);
        historicalInterestRate[day] = interestRate;

        historicalEquivalentTotalB[day] = equivalentTotalB;
        historicalUnderlying[day] = underlying;
        _historicalNavB[day] = navB;
        _historicalNavR[day] = navR;
        currentDay = day + 1 days;

        emit Settled(day, navB, navR, interestRate);
    }

    function transferToStrategy(uint256 amount) external override onlyStrategy {
        _strategyUnderlying = _strategyUnderlying.add(amount);
        IERC20(tokenUnderlying).safeTransfer(_strategy, amount);
    }

    function transferFromStrategy(uint256 amount) external override onlyStrategy {
        _strategyUnderlying = _strategyUnderlying.sub(amount);
        IERC20(tokenUnderlying).safeTransferFrom(_strategy, address(this), amount);
        _payFeeDebt();
    }

    function primaryMarketTransferUnderlying(
        address recipient,
        uint256 amount,
        uint256 fee
    ) external override onlyPrimaryMarket {
        IERC20(tokenUnderlying).safeTransfer(recipient, amount);
        feeDebt = feeDebt.add(fee);
        _updateTotalDebt(_totalDebt.add(fee));
    }

    function primaryMarketAddDebt(uint256 amount, uint256 fee) external override onlyPrimaryMarket {
        redemptionDebt = redemptionDebt.add(amount);
        feeDebt = feeDebt.add(fee);
        _updateTotalDebt(_totalDebt.add(amount).add(fee));
    }

    function primaryMarketPayDebt(uint256 amount) external override onlyPrimaryMarket {
        redemptionDebt = redemptionDebt.sub(amount);
        _updateTotalDebt(_totalDebt.sub(amount));
        IERC20(tokenUnderlying).safeTransfer(msg.sender, amount);
    }

    function reportProfit(uint256 profit, uint256 performanceFee) external override onlyStrategy {
        require(profit >= performanceFee, "Performance fee cannot exceed profit");
        _strategyUnderlying = _strategyUnderlying.add(profit);
        feeDebt = feeDebt.add(performanceFee);
        _updateTotalDebt(_totalDebt.add(performanceFee));
        emit ProfitReported(profit, performanceFee);
    }

    function reportLoss(uint256 loss) external override onlyStrategy {
        _strategyUnderlying = _strategyUnderlying.sub(loss);
        emit LossReported(loss);
    }

    function proposePrimaryMarketUpdate(address newPrimaryMarket) external onlyOwner {
        _proposePrimaryMarketUpdate(newPrimaryMarket);
    }

    function applyPrimaryMarketUpdate(address newPrimaryMarket) external onlyOwner {
        require(
            IPrimaryMarketV3(_primaryMarket).canBeRemovedFromFund(),
            "Cannot update primary market"
        );
        _applyPrimaryMarketUpdate(newPrimaryMarket);
    }

    function proposeStrategyUpdate(address newStrategy) external onlyOwner {
        _proposeStrategyUpdate(newStrategy);
    }

    function applyStrategyUpdate(address newStrategy) external onlyOwner {
        require(_totalDebt == 0, "Cannot update strategy with debt");
        _applyStrategyUpdate(newStrategy);
    }

    function _updateDailyProtocolFeeRate(uint256 newDailyProtocolFeeRate) private {
        require(
            newDailyProtocolFeeRate <= MAX_DAILY_PROTOCOL_FEE_RATE,
            "Exceed max protocol fee rate"
        );
        dailyProtocolFeeRate = newDailyProtocolFeeRate;
        emit DailyProtocolFeeRateUpdated(newDailyProtocolFeeRate);
    }

    function updateDailyProtocolFeeRate(uint256 newDailyProtocolFeeRate) external onlyOwner {
        _updateDailyProtocolFeeRate(newDailyProtocolFeeRate);
    }

    function _updateTwapOracle(address newTwapOracle) private {
        twapOracle = ITwapOracleV2(newTwapOracle);
        emit TwapOracleUpdated(newTwapOracle);
    }

    function updateTwapOracle(address newTwapOracle) external onlyOwner {
        _updateTwapOracle(newTwapOracle);
    }

    function _updateAprOracle(address newAprOracle) private {
        aprOracle = IAprOracle(newAprOracle);
        emit AprOracleUpdated(newAprOracle);
    }

    function updateAprOracle(address newAprOracle) external onlyOwner {
        _updateAprOracle(newAprOracle);
    }

    function _updateBallot(address newBallot) private {
        ballot = IBallot(newBallot);
        emit BallotUpdated(newBallot);
    }

    function updateBallot(address newBallot) external onlyOwner {
        _updateBallot(newBallot);
    }

    function _updateFeeCollector(address newFeeCollector) private {
        feeCollector = newFeeCollector;
        emit FeeCollectorUpdated(newFeeCollector);
    }

    function updateFeeCollector(address newFeeCollector) external onlyOwner {
        _updateFeeCollector(newFeeCollector);
    }

    function _updateActivityDelayTime(uint256 delayTime) private {
        require(
            delayTime >= 30 minutes && delayTime <= 12 hours,
            "Exceed allowed delay time range"
        );
        activityDelayTimeAfterRebalance = delayTime;
        emit ActivityDelayTimeUpdated(delayTime);
    }

    function updateActivityDelayTime(uint256 delayTime) external onlyOwner {
        _updateActivityDelayTime(delayTime);
    }

    /// @dev Transfer protocol fee of the current trading day to the fee collector.
    ///      This function should be called before creation and redemption on the same day
    ///      are settled.
    function _collectFee() private {
        uint256 currentUnderlying = getTotalUnderlying();
        uint256 fee = currentUnderlying.multiplyDecimal(dailyProtocolFeeRate);
        if (fee > 0) {
            feeDebt = feeDebt.add(fee);
            _updateTotalDebt(_totalDebt.add(fee));
        }
    }

    function _payFeeDebt() private {
        uint256 total = _totalDebt;
        if (total == 0) {
            return;
        }
        uint256 hot = IERC20(tokenUnderlying).balanceOf(address(this));
        if (hot == 0) {
            return;
        }
        uint256 fee = feeDebt;
        if (fee > 0) {
            uint256 amount = hot.min(fee);
            feeDebt = fee - amount;
            _updateTotalDebt(total - amount);
            // Call `feeCollector.checkpoint()` without errors.
            // This is a intended behavior because `feeCollector` may not have `checkpoint()`.
            (bool success, ) = feeCollector.call(abi.encodeWithSignature("checkpoint()"));
            if (!success) {
                // ignore
            }
            IERC20(tokenUnderlying).safeTransfer(feeCollector, amount);
            emit FeeDebtPaid(amount);
        }
    }

    /// @dev Check whether a new rebalance should be triggered. Rebalance is triggered if
    ///      ROOK's NAV over BISHOP's NAV is greater than the upper threshold or
    ///      less than the lower threshold.
    /// @param navB BISHOP's NAV before the rebalance
    /// @param navROrZero ROOK's NAV before the rebalance or zero if the NAV is negative
    /// @return Whether a new rebalance should be triggered
    function _shouldTriggerRebalance(uint256 navB, uint256 navROrZero) private view returns (bool) {
        uint256 rOverB = navROrZero.divideDecimal(navB);
        return rOverB < lowerRebalanceThreshold || rOverB > upperRebalanceThreshold;
    }

    /// @dev Create a new rebalance that resets NAV of all tranches to 1. Total supplies are
    ///      rebalanced immediately.
    /// @param day Trading day that triggers this rebalance
    /// @param navSum Sum of BISHOP and ROOK's NAV
    /// @param navB BISHOP's NAV before this rebalance
    /// @param navROrZero ROOK's NAV before this rebalance or zero if the NAV is negative
    /// @param newSplitRatio The new split ratio after this rebalance
    function _triggerRebalance(
        uint256 day,
        uint256 navSum,
        uint256 navB,
        uint256 navROrZero,
        uint256 newSplitRatio
    ) private {
        Rebalance memory rebalance = _calculateRebalance(navSum, navB, navROrZero, newSplitRatio);
        uint256 oldSize = _rebalanceSize;
        splitRatio = newSplitRatio;
        _historicalSplitRatio[oldSize + 1] = newSplitRatio;
        emit SplitRatioUpdated(newSplitRatio);
        _rebalances[oldSize] = rebalance;
        _rebalanceSize = oldSize + 1;
        emit RebalanceTriggered(
            oldSize,
            day,
            navSum,
            navB,
            navROrZero,
            rebalance.ratioB2Q,
            rebalance.ratioR2Q,
            rebalance.ratioBR
        );

        (
            _totalSupplies[TRANCHE_Q],
            _totalSupplies[TRANCHE_B],
            _totalSupplies[TRANCHE_R]
        ) = doRebalance(
            _totalSupplies[TRANCHE_Q],
            _totalSupplies[TRANCHE_B],
            _totalSupplies[TRANCHE_R],
            oldSize
        );
        _refreshBalance(address(this), oldSize + 1);
    }

    /// @dev Create a new rebalance matrix that resets given NAVs to (1, 1).
    ///
    ///      Note that ROOK's NAV can be negative before the rebalance when the underlying price
    ///      drops dramatically in a single trading day, in which case zero should be passed to
    ///      this function instead of the negative NAV.
    /// @param navSum Sum of BISHOP and ROOK's NAV
    /// @param navB BISHOP's NAV before the rebalance
    /// @param navROrZero ROOK's NAV before the rebalance or zero if the NAV is negative
    /// @param newSplitRatio The new split ratio after this rebalance
    /// @return The rebalance matrix
    function _calculateRebalance(
        uint256 navSum,
        uint256 navB,
        uint256 navROrZero,
        uint256 newSplitRatio
    ) private view returns (Rebalance memory) {
        uint256 ratioBR;
        uint256 ratioB2Q;
        uint256 ratioR2Q;
        if (navROrZero <= navB) {
            // Lower rebalance
            ratioBR = navROrZero;
            ratioB2Q = (navSum / 2 - navROrZero).divideDecimal(newSplitRatio);
            ratioR2Q = 0;
        } else {
            // Upper rebalance
            ratioBR = UNIT;
            ratioB2Q = (navB - UNIT).divideDecimal(newSplitRatio) / 2;
            ratioR2Q = (navROrZero - UNIT).divideDecimal(newSplitRatio) / 2;
        }
        return
            Rebalance({
                ratioB2Q: ratioB2Q,
                ratioR2Q: ratioR2Q,
                ratioBR: ratioBR,
                timestamp: block.timestamp
            });
    }

    function _updateInterestRate(uint256 week) private returns (uint256) {
        uint256 baseInterestRate = MAX_INTEREST_RATE.min(aprOracle.capture());
        uint256 floatingInterestRate = ballot.count(week).div(365);
        uint256 rate = baseInterestRate.add(floatingInterestRate);

        emit InterestRateUpdated(baseInterestRate, floatingInterestRate);

        return rate;
    }

    function _updateTotalDebt(uint256 newTotalDebt) private {
        _totalDebt = newTotalDebt;
        emit TotalDebtUpdated(newTotalDebt);
    }

    /// @dev Transform share balance to a given rebalance version, or to the latest version
    ///      if `targetVersion` is zero. This function does no bound check on `targetVersion`.
    /// @param account Account of the balance to rebalance
    /// @param targetVersion The target rebalance version, or zero for the latest version
    function _refreshBalance(address account, uint256 targetVersion) private {
        if (targetVersion == 0) {
            targetVersion = _rebalanceSize;
        }
        uint256 oldVersion = _balanceVersions[account];
        if (oldVersion >= targetVersion) {
            return;
        }

        uint256[TRANCHE_COUNT] storage balanceTuple = _balances[account];
        uint256 balanceQ = balanceTuple[TRANCHE_Q];
        uint256 balanceB = balanceTuple[TRANCHE_B];
        uint256 balanceR = balanceTuple[TRANCHE_R];
        _balanceVersions[account] = targetVersion;

        if (balanceQ == 0 && balanceB == 0 && balanceR == 0) {
            // Fast path for an empty account
            return;
        }

        for (uint256 i = oldVersion; i < targetVersion; i++) {
            (balanceQ, balanceB, balanceR) = doRebalance(balanceQ, balanceB, balanceR, i);
        }
        balanceTuple[TRANCHE_Q] = balanceQ;
        balanceTuple[TRANCHE_B] = balanceB;
        balanceTuple[TRANCHE_R] = balanceR;

        emit BalancesRebalanced(account, targetVersion, balanceQ, balanceB, balanceR);
    }

    /// @dev Transform allowance to a given rebalance version, or to the latest version
    ///      if `targetVersion` is zero. This function does no bound check on `targetVersion`.
    /// @param owner Owner of the allowance to rebalance
    /// @param spender Spender of the allowance to rebalance
    /// @param targetVersion The target rebalance version, or zero for the latest version
    function _refreshAllowance(
        address owner,
        address spender,
        uint256 targetVersion
    ) private {
        if (targetVersion == 0) {
            targetVersion = _rebalanceSize;
        }
        uint256 oldVersion = _allowanceVersions[owner][spender];
        if (oldVersion >= targetVersion) {
            return;
        }

        uint256[TRANCHE_COUNT] storage allowanceTuple = _allowances[owner][spender];
        uint256 allowanceQ = allowanceTuple[TRANCHE_Q];
        uint256 allowanceB = allowanceTuple[TRANCHE_B];
        uint256 allowanceR = allowanceTuple[TRANCHE_R];
        _allowanceVersions[owner][spender] = targetVersion;

        if (allowanceQ == 0 && allowanceB == 0 && allowanceR == 0) {
            // Fast path for an empty allowance
            return;
        }

        for (uint256 i = oldVersion; i < targetVersion; i++) {
            (allowanceQ, allowanceB, allowanceR) = _rebalanceAllowance(
                allowanceQ,
                allowanceB,
                allowanceR,
                i
            );
        }
        allowanceTuple[TRANCHE_Q] = allowanceQ;
        allowanceTuple[TRANCHE_B] = allowanceB;
        allowanceTuple[TRANCHE_R] = allowanceR;

        emit AllowancesRebalanced(
            owner,
            spender,
            targetVersion,
            allowanceQ,
            allowanceB,
            allowanceR
        );
    }

    function _rebalanceAllowance(
        uint256 allowanceQ,
        uint256 allowanceB,
        uint256 allowanceR,
        uint256 index
    )
        private
        view
        returns (
            uint256 newAllowanceQ,
            uint256 newAllowanceB,
            uint256 newAllowanceR
        )
    {
        Rebalance storage rebalance = _rebalances[index];

        /// @dev using saturating arithmetic to avoid unconscious overflow revert
        newAllowanceQ = allowanceQ;
        newAllowanceB = allowanceB.saturatingMultiplyDecimal(rebalance.ratioBR);
        newAllowanceR = allowanceR.saturatingMultiplyDecimal(rebalance.ratioBR);
    }

    modifier onlyCurrentVersion(uint256 version) {
        require(_rebalanceSize == version, "Only current version");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../utils/SafeDecimalMath.sol";

import "../interfaces/IPrimaryMarketV3.sol";
import "../interfaces/IFundV3.sol";
import "../interfaces/IFundForPrimaryMarketV3.sol";
import "../interfaces/ITrancheIndexV2.sol";
import "../interfaces/IWrappedERC20.sol";

contract PrimaryMarketV3 is IPrimaryMarketV3, ReentrancyGuard, ITrancheIndexV2, Ownable {
    event Created(address indexed account, uint256 underlying, uint256 outQ);
    event Redeemed(address indexed account, uint256 inQ, uint256 underlying, uint256 fee);
    event Split(address indexed account, uint256 inQ, uint256 outB, uint256 outR);
    event Merged(
        address indexed account,
        uint256 outQ,
        uint256 inB,
        uint256 inR,
        uint256 feeUnderlying
    );
    event RedemptionQueued(address indexed account, uint256 index, uint256 underlying);
    event RedemptionPopped(uint256 count, uint256 newHead, uint256 requiredUnderlying);
    event RedemptionClaimed(address indexed account, uint256 index, uint256 underlying);
    event FundCapUpdated(uint256 newCap);
    event RedemptionFeeRateUpdated(uint256 newRedemptionFeeRate);
    event MergeFeeRateUpdated(uint256 newMergeFeeRate);

    using SafeMath for uint256;
    using SafeDecimalMath for uint256;
    using SafeERC20 for IERC20;

    struct QueuedRedemption {
        address account;
        uint256 underlying;
        uint256 previousPrefixSum;
    }

    uint256 private constant MAX_REDEMPTION_FEE_RATE = 0.01e18;
    uint256 private constant MAX_MERGE_FEE_RATE = 0.01e18;

    address public immutable override fund;
    IERC20 private immutable _tokenUnderlying;

    uint256 public redemptionFeeRate;
    uint256 public mergeFeeRate;

    /// @notice The upper limit of underlying that the fund can hold. This contract rejects
    ///         creations that may break this limit.
    /// @dev This limit can be bypassed if the fund has multiple primary markets.
    ///
    ///      Set it to uint(-1) to skip the check and save gas.
    uint256 public fundCap;

    /// @notice Queue of redemptions that cannot be claimed yet. Key is a sequential index
    ///         starting from zero. Value is a tuple of user address, redeemed underlying and
    ///         prefix sum before this entry.
    mapping(uint256 => QueuedRedemption) public queuedRedemptions;

    /// @notice Total underlying tokens of claimable queued redemptions.
    uint256 public claimableUnderlying;

    /// @notice Index of the redemption queue head. All redemptions with index smaller than
    ///         this value can be claimed now.
    uint256 public redemptionQueueHead;

    /// @notice Index of the redemption following the last entry of the queue. The next queued
    ///         redemption will be written at this index.
    uint256 public redemptionQueueTail;

    constructor(
        address fund_,
        uint256 redemptionFeeRate_,
        uint256 mergeFeeRate_,
        uint256 fundCap_
    ) public Ownable() {
        fund = fund_;
        _tokenUnderlying = IERC20(IFundV3(fund_).tokenUnderlying());
        _updateRedemptionFeeRate(redemptionFeeRate_);
        _updateMergeFeeRate(mergeFeeRate_);
        _updateFundCap(fundCap_);
    }

    /// @notice Calculate the result of a creation.
    /// @param underlying Underlying amount spent for the creation
    /// @return outQ Created QUEEN amount
    function getCreation(uint256 underlying) public view override returns (uint256 outQ) {
        uint256 fundUnderlying = IFundV3(fund).getTotalUnderlying();
        uint256 fundEquivalentTotalQ = IFundV3(fund).getEquivalentTotalQ();
        require(fundUnderlying.add(underlying) <= fundCap, "Exceed fund cap");
        if (fundEquivalentTotalQ == 0) {
            outQ = underlying.mul(IFundV3(fund).underlyingDecimalMultiplier());
            uint256 splitRatio = IFundV3(fund).splitRatio();
            require(splitRatio != 0, "Fund is not initialized");
            uint256 settledDay = IFundV3(fund).currentDay() - 1 days;
            uint256 underlyingPrice = IFundV3(fund).twapOracle().getTwap(settledDay);
            (uint256 navB, uint256 navR) = IFundV3(fund).historicalNavs(settledDay);
            outQ = outQ.mul(underlyingPrice).div(splitRatio).divideDecimal(navB.add(navR));
        } else {
            require(
                fundUnderlying != 0,
                "Cannot create QUEEN for fund with shares but no underlying"
            );
            outQ = underlying.mul(fundEquivalentTotalQ).div(fundUnderlying);
        }
    }

    /// @notice Calculate the amount of underlying tokens to create at least the given QUEEN amount.
    ///         This only works with non-empty fund for simplicity.
    /// @param minOutQ Minimum received QUEEN amount
    /// @return underlying Underlying amount that should be used for creation
    function getCreationForQ(uint256 minOutQ) external view override returns (uint256 underlying) {
        // Assume:
        //   minOutQ * fundUnderlying = a * fundEquivalentTotalQ - b
        // where a and b are integers and 0 <= b < fundEquivalentTotalQ
        // Then
        //   underlying = a
        //   getCreation(underlying)
        //     = floor(a * fundEquivalentTotalQ / fundUnderlying)
        //    >= floor((a * fundEquivalentTotalQ - b) / fundUnderlying)
        //     = minOutQ
        //   getCreation(underlying - 1)
        //     = floor((a * fundEquivalentTotalQ - fundEquivalentTotalQ) / fundUnderlying)
        //     < (a * fundEquivalentTotalQ - b) / fundUnderlying
        //     = minOutQ
        uint256 fundUnderlying = IFundV3(fund).getTotalUnderlying();
        uint256 fundEquivalentTotalQ = IFundV3(fund).getEquivalentTotalQ();
        require(fundEquivalentTotalQ > 0, "Cannot calculate creation for empty fund");
        return minOutQ.mul(fundUnderlying).add(fundEquivalentTotalQ - 1).div(fundEquivalentTotalQ);
    }

    function _getRedemptionBeforeFee(uint256 inQ) private view returns (uint256 underlying) {
        uint256 fundUnderlying = IFundV3(fund).getTotalUnderlying();
        uint256 fundEquivalentTotalQ = IFundV3(fund).getEquivalentTotalQ();
        underlying = inQ.mul(fundUnderlying).div(fundEquivalentTotalQ);
    }

    /// @notice Calculate the result of a redemption.
    /// @param inQ QUEEN amount spent for the redemption
    /// @return underlying Redeemed underlying amount
    /// @return fee Underlying amount charged as redemption fee
    function getRedemption(uint256 inQ)
        public
        view
        override
        returns (uint256 underlying, uint256 fee)
    {
        underlying = _getRedemptionBeforeFee(inQ);
        fee = underlying.multiplyDecimal(redemptionFeeRate);
        underlying = underlying.sub(fee);
    }

    /// @notice Calculate the amount of QUEEN that can be redeemed for at least the given amount
    ///         of underlying tokens.
    /// @dev The return value may not be the minimum solution due to rounding errors.
    /// @param minUnderlying Minimum received underlying amount
    /// @return inQ QUEEN amount that should be redeemed
    function getRedemptionForUnderlying(uint256 minUnderlying)
        external
        view
        override
        returns (uint256 inQ)
    {
        // Assume:
        //   minUnderlying * 1e18 = a * (1e18 - redemptionFeeRate) + b
        //   a * fundEquivalentTotalQ = c * fundUnderlying - d
        // where
        //   a, b, c, d are integers
        //   0 <= b < 1e18 - redemptionFeeRate
        //   0 <= d < fundUnderlying
        // Then
        //   underlyingBeforeFee = a
        //   inQ = c
        //   getRedemption(inQ).underlying
        //     = floor(c * fundUnderlying / fundEquivalentTotalQ) -
        //       - floor(floor(c * fundUnderlying / fundEquivalentTotalQ) * redemptionFeeRate / 1e18)
        //     = ceil(floor(c * fundUnderlying / fundEquivalentTotalQ) * (1e18 - redemptionFeeRate) / 1e18)
        //    >= ceil(floor((c * fundUnderlying - d) / fundEquivalentTotalQ) * (1e18 - redemptionFeeRate) / 1e18)
        //     = ceil(a * (1e18 - redemptionFeeRate) / 1e18)
        //     = (a * (1e18 - redemptionFeeRate) + b) / 1e18        // because b < 1e18
        //     = minUnderlying
        uint256 fundUnderlying = IFundV3(fund).getTotalUnderlying();
        uint256 fundEquivalentTotalQ = IFundV3(fund).getEquivalentTotalQ();
        uint256 underlyingBeforeFee = minUnderlying.divideDecimal(1e18 - redemptionFeeRate);
        return
            underlyingBeforeFee.mul(fundEquivalentTotalQ).add(fundUnderlying - 1).div(
                fundUnderlying
            );
    }

    /// @notice Calculate the result of a split.
    /// @param inQ QUEEN amount to be split
    /// @return outB Received BISHOP amount, which is also received ROOK amount
    function getSplit(uint256 inQ) public view override returns (uint256 outB) {
        return inQ.multiplyDecimal(IFundV3(fund).splitRatio());
    }

    /// @notice Calculate the amount of QUEEN that can be split into at least the given amount of
    ///         BISHOP and ROOK.
    /// @param minOutB Received BISHOP amount, which is also received ROOK amount
    /// @return inQ QUEEN amount that should be split
    function getSplitForB(uint256 minOutB) external view override returns (uint256 inQ) {
        uint256 splitRatio = IFundV3(fund).splitRatio();
        return minOutB.mul(1e18).add(splitRatio.sub(1)).div(splitRatio);
    }

    /// @notice Calculate the result of a merge.
    /// @param inB Spent BISHOP amount, which is also spent ROOK amount
    /// @return outQ Received QUEEN amount
    /// @return feeQ QUEEN amount charged as merge fee
    function getMerge(uint256 inB) public view override returns (uint256 outQ, uint256 feeQ) {
        uint256 outQBeforeFee = inB.divideDecimal(IFundV3(fund).splitRatio());
        feeQ = outQBeforeFee.multiplyDecimal(mergeFeeRate);
        outQ = outQBeforeFee.sub(feeQ);
    }

    /// @notice Calculate the amount of BISHOP and ROOK that can be merged into at least
    ///      the given amount of QUEEN.
    /// @dev The return value may not be the minimum solution due to rounding errors.
    /// @param minOutQ Minimum received QUEEN amount
    /// @return inB BISHOP amount that should be merged, which is also spent ROOK amount
    function getMergeForQ(uint256 minOutQ) external view override returns (uint256 inB) {
        // Assume:
        //   minOutQ * 1e18 = a * (1e18 - mergeFeeRate) + b
        //   c = ceil(a * splitRatio / 1e18)
        // where a and b are integers and 0 <= b < 1e18 - mergeFeeRate
        // Then
        //   outQBeforeFee = a
        //   inB = c
        //   getMerge(inB).outQ
        //     = c * 1e18 / splitRatio - floor(c * 1e18 / splitRatio * mergeFeeRate / 1e18)
        //     = ceil(c * 1e18 / splitRatio * (1e18 - mergeFeeRate) / 1e18)
        //    >= ceil(a * (1e18 - mergeFeeRate) / 1e18)
        //     = (a * (1e18 - mergeFeeRate) + b) / 1e18         // because b < 1e18
        //     = minOutQ
        uint256 outQBeforeFee = minOutQ.divideDecimal(1e18 - mergeFeeRate);
        inB = outQBeforeFee.mul(IFundV3(fund).splitRatio()).add(1e18 - 1).div(1e18);
    }

    /// @notice Return index of the first queued redemption that cannot be claimed now.
    ///         Users can use this function to determine which indices can be passed to
    ///         `claimRedemptions()`.
    /// @return Index of the first redemption that cannot be claimed now
    function getNewRedemptionQueueHead() external view returns (uint256) {
        uint256 available = _tokenUnderlying.balanceOf(fund);
        uint256 l = redemptionQueueHead;
        uint256 r = redemptionQueueTail;
        uint256 startPrefixSum = queuedRedemptions[l].previousPrefixSum;
        // overflow is desired
        if (queuedRedemptions[r].previousPrefixSum - startPrefixSum <= available) {
            return r;
        }
        // Iteration count is bounded by log2(tail - head), which is at most 256.
        while (l + 1 < r) {
            uint256 m = (l + r) / 2;
            if (queuedRedemptions[m].previousPrefixSum - startPrefixSum <= available) {
                l = m;
            } else {
                r = m;
            }
        }
        return l;
    }

    /// @notice Search in the redemption queue.
    /// @param account Owner of the redemptions, or zero address to return all redemptions
    /// @param startIndex Redemption index where the search starts, or zero to start from the head
    /// @param maxIterationCount Maximum number of redemptions to be scanned, or zero for no limit
    /// @return indices Indices of found redemptions
    /// @return underlying Total underlying of found redemptions
    function getQueuedRedemptions(
        address account,
        uint256 startIndex,
        uint256 maxIterationCount
    ) external view returns (uint256[] memory indices, uint256 underlying) {
        uint256 head = redemptionQueueHead;
        uint256 tail = redemptionQueueTail;
        if (startIndex == 0) {
            startIndex = head;
        } else {
            require(startIndex >= head && startIndex <= tail, "startIndex out of bound");
        }
        uint256 endIndex = tail;
        if (maxIterationCount != 0 && tail - startIndex > maxIterationCount) {
            endIndex = startIndex + maxIterationCount;
        }
        indices = new uint256[](endIndex - startIndex);
        uint256 count = 0;
        for (uint256 i = startIndex; i < endIndex; i++) {
            if (account == address(0) || queuedRedemptions[i].account == account) {
                indices[count] = i;
                underlying += queuedRedemptions[i].underlying;
                count++;
            }
        }
        if (count != endIndex - startIndex) {
            // Shrink the array
            assembly {
                mstore(indices, count)
            }
        }
    }

    /// @notice Return whether the fund can change its primary market to another contract.
    function canBeRemovedFromFund() external view override returns (bool) {
        return redemptionQueueHead == redemptionQueueTail;
    }

    /// @notice Create QUEEN using underlying tokens. This function should be called by
    ///         a smart contract, which transfers underlying tokens to this contract
    ///         in the same transaction.
    /// @param recipient Address that will receive created QUEEN
    /// @param minOutQ Minimum QUEEN amount to be received
    /// @param version The latest rebalance version
    /// @return outQ Received QUEEN amount
    function create(
        address recipient,
        uint256 minOutQ,
        uint256 version
    ) external override nonReentrant returns (uint256 outQ) {
        uint256 underlying = _tokenUnderlying.balanceOf(address(this)).sub(claimableUnderlying);
        outQ = getCreation(underlying);
        require(outQ >= minOutQ && outQ > 0, "Min QUEEN created");
        IFundForPrimaryMarketV3(fund).primaryMarketMint(TRANCHE_Q, recipient, outQ, version);
        _tokenUnderlying.safeTransfer(fund, underlying);
        emit Created(recipient, underlying, outQ);
    }

    /// @notice Redeem QUEEN to get underlying tokens back. Revert if there are still some
    ///         queued redemptions that cannot be claimed now.
    /// @param recipient Address that will receive redeemed underlying tokens
    /// @param inQ Spent QUEEN amount
    /// @param minUnderlying Minimum amount of underlying tokens to be received
    /// @param version The latest rebalance version
    /// @return underlying Received underlying amount
    function redeem(
        address recipient,
        uint256 inQ,
        uint256 minUnderlying,
        uint256 version
    ) external override nonReentrant returns (uint256 underlying) {
        underlying = _redeem(recipient, inQ, minUnderlying, version);
    }

    /// @notice Redeem QUEEN to get native currency back. The underlying must be wrapped token
    ///         of the native currency. Revert if there are still some queued redemptions that
    ///         cannot be claimed now.
    /// @param recipient Address that will receive redeemed underlying tokens
    /// @param inQ Spent QUEEN amount
    /// @param minUnderlying Minimum amount of underlying tokens to be received
    /// @param version The latest rebalance version
    /// @return underlying Received underlying amount
    function redeemAndUnwrap(
        address recipient,
        uint256 inQ,
        uint256 minUnderlying,
        uint256 version
    ) external override nonReentrant returns (uint256 underlying) {
        underlying = _redeem(address(this), inQ, minUnderlying, version);
        IWrappedERC20(address(_tokenUnderlying)).withdraw(underlying);
        (bool success, ) = recipient.call{value: underlying}("");
        require(success, "Transfer failed");
    }

    function _redeem(
        address recipient,
        uint256 inQ,
        uint256 minUnderlying,
        uint256 version
    ) private returns (uint256 underlying) {
        uint256 fee;
        (underlying, fee) = getRedemption(inQ);
        IFundForPrimaryMarketV3(fund).primaryMarketBurn(TRANCHE_Q, msg.sender, inQ, version);
        _popRedemptionQueue(0);
        require(underlying >= minUnderlying && underlying > 0, "Min underlying redeemed");
        // Redundant check for user-friendly revert message.
        require(underlying <= _tokenUnderlying.balanceOf(fund), "Not enough underlying in fund");
        IFundForPrimaryMarketV3(fund).primaryMarketTransferUnderlying(recipient, underlying, fee);
        emit Redeemed(recipient, inQ, underlying, fee);
    }

    /// @notice Redeem QUEEN and wait in the redemption queue. Redeemed underlying tokens will
    ///         be claimable when the fund has enough balance to pay this redemption and all
    ///         previous ones in the queue.
    /// @param recipient Address that will receive redeemed underlying tokens
    /// @param inQ Spent QUEEN amount
    /// @param minUnderlying Minimum amount of underlying tokens to be received
    /// @param version The latest rebalance version
    /// @return underlying Received underlying amount
    /// @return index Index of the queued redemption
    function queueRedemption(
        address recipient,
        uint256 inQ,
        uint256 minUnderlying,
        uint256 version
    ) external override nonReentrant returns (uint256 underlying, uint256 index) {
        uint256 fee;
        (underlying, fee) = getRedemption(inQ);
        IFundForPrimaryMarketV3(fund).primaryMarketBurn(TRANCHE_Q, msg.sender, inQ, version);
        require(underlying >= minUnderlying && underlying > 0, "Min underlying redeemed");
        index = redemptionQueueTail;
        QueuedRedemption storage newRedemption = queuedRedemptions[index];
        newRedemption.account = recipient;
        newRedemption.underlying = underlying;
        // overflow is desired
        queuedRedemptions[index + 1].previousPrefixSum =
            newRedemption.previousPrefixSum +
            underlying;
        redemptionQueueTail = index + 1;
        IFundForPrimaryMarketV3(fund).primaryMarketAddDebt(underlying, fee);
        emit Redeemed(recipient, inQ, underlying, fee);
        emit RedemptionQueued(recipient, index, underlying);
    }

    /// @notice Remove a given number of redemptions from the front of the redemption queue and
    ///         fetch underlying tokens of these redemptions from the fund. Revert if the fund
    ///         cannot pay these redemptions now.
    /// @param count The number of redemptions to be removed, or zero to completely empty the queue
    function popRedemptionQueue(uint256 count) external nonReentrant {
        _popRedemptionQueue(count);
    }

    function _popRedemptionQueue(uint256 count) private {
        uint256 oldHead = redemptionQueueHead;
        uint256 oldTail = redemptionQueueTail;
        uint256 newHead;
        if (count == 0) {
            if (oldHead == oldTail) {
                return;
            }
            newHead = oldTail;
        } else {
            newHead = oldHead.add(count);
            require(newHead <= oldTail, "Redemption queue out of bound");
        }
        // overflow is desired
        uint256 requiredUnderlying =
            queuedRedemptions[newHead].previousPrefixSum -
                queuedRedemptions[oldHead].previousPrefixSum;
        // Redundant check for user-friendly revert message.
        require(
            requiredUnderlying <= _tokenUnderlying.balanceOf(fund),
            "Not enough underlying in fund"
        );
        claimableUnderlying = claimableUnderlying.add(requiredUnderlying);
        IFundForPrimaryMarketV3(fund).primaryMarketPayDebt(requiredUnderlying);
        redemptionQueueHead = newHead;
        emit RedemptionPopped(newHead - oldHead, newHead, requiredUnderlying);
    }

    /// @notice Claim underlying tokens of queued redemptions. All these redemptions must
    ///         belong to the same account.
    /// @param account Recipient of the redemptions
    /// @param indices Indices of the redemptions in the queue, which must be in increasing order
    /// @return underlying Total claimed underlying amount
    function claimRedemptions(address account, uint256[] calldata indices)
        external
        override
        nonReentrant
        returns (uint256 underlying)
    {
        underlying = _claimRedemptions(account, indices);
        _tokenUnderlying.safeTransfer(account, underlying);
    }

    /// @notice Claim native currency of queued redemptions. The underlying must be wrapped token
    ///         of the native currency. All these redemptions must belong to the same account.
    /// @param account Recipient of the redemptions
    /// @param indices Indices of the redemptions in the queue, which must be in increasing order
    /// @return underlying Total claimed underlying amount
    function claimRedemptionsAndUnwrap(address account, uint256[] calldata indices)
        external
        override
        nonReentrant
        returns (uint256 underlying)
    {
        underlying = _claimRedemptions(account, indices);
        IWrappedERC20(address(_tokenUnderlying)).withdraw(underlying);
        (bool success, ) = account.call{value: underlying}("");
        require(success, "Transfer failed");
    }

    function _claimRedemptions(address account, uint256[] calldata indices)
        private
        returns (uint256 underlying)
    {
        uint256 count = indices.length;
        if (count == 0) {
            return 0;
        }
        uint256 head = redemptionQueueHead;
        if (indices[count - 1] >= head) {
            _popRedemptionQueue(indices[count - 1] - head + 1);
        }
        for (uint256 i = 0; i < count; i++) {
            require(i == 0 || indices[i] > indices[i - 1], "Indices out of order");
            QueuedRedemption storage redemption = queuedRedemptions[indices[i]];
            uint256 redemptionUnderlying = redemption.underlying;
            require(
                redemption.account == account && redemptionUnderlying != 0,
                "Invalid redemption index"
            );
            underlying = underlying.add(redemptionUnderlying);
            emit RedemptionClaimed(account, indices[i], redemptionUnderlying);
            delete queuedRedemptions[indices[i]];
        }
        claimableUnderlying = claimableUnderlying.sub(underlying);
    }

    function split(
        address recipient,
        uint256 inQ,
        uint256 version
    ) external override returns (uint256 outB) {
        outB = getSplit(inQ);
        IFundForPrimaryMarketV3(fund).primaryMarketBurn(TRANCHE_Q, msg.sender, inQ, version);
        IFundForPrimaryMarketV3(fund).primaryMarketMint(TRANCHE_B, recipient, outB, version);
        IFundForPrimaryMarketV3(fund).primaryMarketMint(TRANCHE_R, recipient, outB, version);
        emit Split(recipient, inQ, outB, outB);
    }

    function merge(
        address recipient,
        uint256 inB,
        uint256 version
    ) external override returns (uint256 outQ) {
        uint256 feeQ;
        (outQ, feeQ) = getMerge(inB);
        uint256 feeUnderlying = _getRedemptionBeforeFee(feeQ);
        IFundForPrimaryMarketV3(fund).primaryMarketBurn(TRANCHE_B, msg.sender, inB, version);
        IFundForPrimaryMarketV3(fund).primaryMarketBurn(TRANCHE_R, msg.sender, inB, version);
        IFundForPrimaryMarketV3(fund).primaryMarketMint(TRANCHE_Q, recipient, outQ, version);
        IFundForPrimaryMarketV3(fund).primaryMarketAddDebt(0, feeUnderlying);
        emit Merged(recipient, outQ, inB, inB, feeUnderlying);
    }

    /// @dev Nothing to do for daily fund settlement.
    function settle(uint256 day) external override onlyFund {}

    function _updateFundCap(uint256 newCap) private {
        fundCap = newCap;
        emit FundCapUpdated(newCap);
    }

    function updateFundCap(uint256 newCap) external onlyOwner {
        _updateFundCap(newCap);
    }

    function _updateRedemptionFeeRate(uint256 newRedemptionFeeRate) private {
        require(newRedemptionFeeRate <= MAX_REDEMPTION_FEE_RATE, "Exceed max redemption fee rate");
        redemptionFeeRate = newRedemptionFeeRate;
        emit RedemptionFeeRateUpdated(newRedemptionFeeRate);
    }

    function updateRedemptionFeeRate(uint256 newRedemptionFeeRate) external onlyOwner {
        _updateRedemptionFeeRate(newRedemptionFeeRate);
    }

    function _updateMergeFeeRate(uint256 newMergeFeeRate) private {
        require(newMergeFeeRate <= MAX_MERGE_FEE_RATE, "Exceed max merge fee rate");
        mergeFeeRate = newMergeFeeRate;
        emit MergeFeeRateUpdated(newMergeFeeRate);
    }

    function updateMergeFeeRate(uint256 newMergeFeeRate) external onlyOwner {
        _updateMergeFeeRate(newMergeFeeRate);
    }

    /// @notice Receive unwrapped transfer from the wrapped token.
    receive() external payable {}

    modifier onlyFund() {
        require(msg.sender == fund, "Only fund");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "../fund/ShareStaking.sol";

import "../interfaces/IPrimaryMarketRouter.sol";
import "../interfaces/IPrimaryMarketV3.sol";
import "../interfaces/ISwapRouter.sol";
import "../interfaces/IStableSwap.sol";
import "../interfaces/IWrappedERC20.sol";

contract PrimaryMarketRouter is IPrimaryMarketRouter, ITrancheIndexV2 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IPrimaryMarketV3 public immutable primaryMarket;
    IFundV3 public immutable fund;
    IERC20 private immutable _tokenUnderlying;
    address private immutable _tokenB;

    constructor(address pm) public {
        primaryMarket = IPrimaryMarketV3(pm);
        IFundV3 fund_ = IFundV3(IPrimaryMarketV3(pm).fund());
        fund = fund_;
        _tokenUnderlying = IERC20(fund_.tokenUnderlying());
        _tokenB = fund_.tokenB();
    }

    /// @dev Get redemption with StableSwap getQuoteOut interface.
    function getQuoteOut(uint256 baseIn) external view override returns (uint256 quoteOut) {
        (quoteOut, ) = primaryMarket.getRedemption(baseIn);
    }

    /// @dev Get creation for QUEEN with StableSwap getQuoteIn interface.
    function getQuoteIn(uint256 baseOut) external view override returns (uint256 quoteIn) {
        quoteIn = primaryMarket.getCreationForQ(baseOut);
    }

    /// @dev Get creation with StableSwap getBaseOut interface.
    function getBaseOut(uint256 quoteIn) external view override returns (uint256 baseOut) {
        baseOut = primaryMarket.getCreation(quoteIn);
    }

    /// @dev Get redemption for underlying with StableSwap getBaseIn interface.
    function getBaseIn(uint256 quoteOut) external view override returns (uint256 baseIn) {
        baseIn = primaryMarket.getRedemptionForUnderlying(quoteOut);
    }

    /// @dev Create QUEEN with StableSwap buy interface.
    ///      Underlying should have already been sent to this contract
    function buy(
        uint256 version,
        uint256 baseOut,
        address recipient,
        bytes calldata
    ) external override returns (uint256 realBaseOut) {
        uint256 routerQuoteBalance = IERC20(_tokenUnderlying).balanceOf(address(this));
        IERC20(_tokenUnderlying).safeTransfer(address(primaryMarket), routerQuoteBalance);
        realBaseOut = primaryMarket.create(recipient, baseOut, version);
    }

    /// @dev Redeem QUEEN with StableSwap sell interface.
    ///      QUEEN should have already been sent to this contract
    function sell(
        uint256 version,
        uint256 quoteOut,
        address recipient,
        bytes calldata
    ) external override returns (uint256 realQuoteOut) {
        uint256 routerBaseBalance = fund.trancheBalanceOf(TRANCHE_Q, address(this));
        realQuoteOut = primaryMarket.redeem(recipient, routerBaseBalance, quoteOut, version);
    }

    function create(
        address recipient,
        uint256 underlying,
        uint256 minOutQ,
        uint256 version
    ) public payable override returns (uint256 outQ) {
        if (msg.value > 0) {
            require(msg.value == underlying); // sanity check
            IWrappedERC20(address(_tokenUnderlying)).deposit{value: msg.value}();
            _tokenUnderlying.safeTransfer(address(primaryMarket), msg.value);
        } else {
            IERC20(_tokenUnderlying).safeTransferFrom(
                msg.sender,
                address(primaryMarket),
                underlying
            );
        }

        outQ = primaryMarket.create(recipient, minOutQ, version);
    }

    function createAndStake(
        uint256 underlying,
        uint256 minOutQ,
        address staking,
        uint256 version
    ) external payable override {
        // Create QUEEN
        uint256 outQ = create(staking, underlying, minOutQ, version);
        // Stake QUEEN
        ShareStaking(staking).deposit(TRANCHE_Q, outQ, msg.sender, version);
    }

    function createSplitAndStake(
        uint256 underlying,
        uint256 minOutQ,
        address router,
        address quoteAddress,
        uint256 minLpOut,
        address staking,
        uint256 version
    ) external payable override {
        // Create QUEEN
        uint256 outQ = create(address(this), underlying, minOutQ, version);
        _splitAndStake(outQ, router, quoteAddress, minLpOut, staking, version);
    }

    function splitAndStake(
        uint256 inQ,
        address router,
        address quoteAddress,
        uint256 minLpOut,
        address staking,
        uint256 version
    ) external override {
        fund.trancheTransferFrom(TRANCHE_Q, msg.sender, address(this), inQ, version);
        _splitAndStake(inQ, router, quoteAddress, minLpOut, staking, version);
    }

    function _splitAndStake(
        uint256 inQ,
        address router,
        address quoteAddress,
        uint256 minLpOut,
        address staking,
        uint256 version
    ) private {
        // Split QUEEN into BISHOP and ROOK
        uint256 outB = primaryMarket.split(address(this), inQ, version);
        // Add BISHOP to stable swap
        {
            IStableSwap swap = ISwapRouter(router).getSwap(_tokenB, quoteAddress);
            fund.trancheTransfer(TRANCHE_B, address(swap), outB, version);
            uint256 lpOut = swap.addLiquidity(version, msg.sender);
            require(lpOut >= minLpOut, "Insufficient output");
        }

        if (staking == address(0)) {
            fund.trancheTransfer(TRANCHE_R, msg.sender, outB, version);
        } else {
            // Stake rook
            fund.trancheTransfer(TRANCHE_R, staking, outB, version);
            ShareStaking(staking).deposit(TRANCHE_R, outB, msg.sender, version);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/ILiquidityGauge.sol";
import "../interfaces/IChessSchedule.sol";
import "../interfaces/IChessController.sol";
import "../interfaces/IFundV3.sol";
import "../interfaces/ITrancheIndexV2.sol";
import "../interfaces/IStableSwap.sol";
import "../interfaces/IVotingEscrow.sol";

import "../utils/CoreUtility.sol";
import "../utils/SafeDecimalMath.sol";

interface ISwapBonus {
    function bonusToken() external view returns (address);

    function getBonus() external returns (uint256);
}

contract LiquidityGauge is ILiquidityGauge, ITrancheIndexV2, CoreUtility, ERC20 {
    using Math for uint256;
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;
    using SafeERC20 for IERC20;

    struct Distribution {
        uint256 amountQ;
        uint256 amountB;
        uint256 amountR;
        uint256 quoteAmount;
    }

    uint256 private constant MAX_ITERATIONS = 500;
    uint256 private constant MAX_BOOSTING_FACTOR = 3e18;
    uint256 private constant MAX_BOOSTING_FACTOR_MINUS_ONE = MAX_BOOSTING_FACTOR - 1e18;

    address public immutable stableSwap;
    IERC20 private immutable _quoteToken;
    IChessSchedule public immutable chessSchedule;
    IChessController public immutable chessController;
    IFundV3 public immutable fund;
    IVotingEscrow private immutable _votingEscrow;
    address public immutable swapBonus;
    IERC20 private immutable _bonusToken;
    /// @notice Timestamp when rewards start.
    uint256 public immutable rewardStartTimestamp;

    uint256 private _workingSupply;
    mapping(address => uint256) private _workingBalances;

    uint256 public latestVersion;
    mapping(uint256 => Distribution) public distributions;
    mapping(uint256 => uint256) public distributionTotalSupplies;
    mapping(address => Distribution) public userDistributions;
    mapping(address => uint256) public userVersions;

    uint256 private _chessIntegral;
    uint256 private _chessIntegralTimestamp;
    mapping(address => uint256) private _chessUserIntegrals;
    mapping(address => uint256) private _claimableChess;

    uint256 private _bonusIntegral;
    mapping(address => uint256) private _bonusUserIntegral;
    mapping(address => uint256) private _claimableBonus;

    /// @dev Per-gauge CHESS emission rate. The product of CHESS emission rate
    ///      and weekly percentage of the gauge
    uint256 private _rate;

    constructor(
        string memory name_,
        string memory symbol_,
        address stableSwap_,
        address chessSchedule_,
        address chessController_,
        address fund_,
        address votingEscrow_,
        address swapBonus_,
        uint256 rewardStartTimestamp_
    ) public ERC20(name_, symbol_) {
        stableSwap = stableSwap_;
        _quoteToken = IERC20(IStableSwap(stableSwap_).quoteAddress());
        chessSchedule = IChessSchedule(chessSchedule_);
        chessController = IChessController(chessController_);
        fund = IFundV3(fund_);
        _votingEscrow = IVotingEscrow(votingEscrow_);
        swapBonus = swapBonus_;
        _bonusToken = IERC20(ISwapBonus(swapBonus_).bonusToken());
        rewardStartTimestamp = rewardStartTimestamp_;
        _chessIntegralTimestamp = block.timestamp;
    }

    modifier onlyStableSwap() {
        require(msg.sender == stableSwap, "Only stable swap");
        _;
    }

    function getRate() external view returns (uint256) {
        return _rate / 1e18;
    }

    function mint(address account, uint256 amount) external override onlyStableSwap {
        uint256 oldWorkingBalance = _workingBalances[account];
        uint256 oldWorkingSupply = _workingSupply;
        uint256 oldBalance = balanceOf(account);
        _checkpoint(account, oldBalance, oldWorkingBalance, oldWorkingSupply);

        _mint(account, amount);
        _updateWorkingBalance(
            account,
            oldWorkingBalance,
            oldWorkingSupply,
            oldBalance.add(amount),
            totalSupply()
        );
    }

    function burnFrom(address account, uint256 amount) external override onlyStableSwap {
        uint256 oldWorkingBalance = _workingBalances[account];
        uint256 oldWorkingSupply = _workingSupply;
        uint256 oldBalance = balanceOf(account);
        _checkpoint(account, oldBalance, oldWorkingBalance, oldWorkingSupply);

        _burn(account, amount);
        _updateWorkingBalance(
            account,
            oldWorkingBalance,
            oldWorkingSupply,
            oldBalance.sub(amount),
            totalSupply()
        );
    }

    function _transfer(
        address,
        address,
        uint256
    ) internal override {
        revert("Transfer is not allowed");
    }

    function workingBalanceOf(address account) external view override returns (uint256) {
        return _workingBalances[account];
    }

    function workingSupply() external view override returns (uint256) {
        return _workingSupply;
    }

    function claimableRewards(address account)
        external
        override
        returns (
            uint256 chessAmount,
            uint256 bonusAmount,
            uint256 amountQ,
            uint256 amountB,
            uint256 amountR,
            uint256 quoteAmount
        )
    {
        return _checkpoint(account, balanceOf(account), _workingBalances[account], _workingSupply);
    }

    function claimRewards(address account) external override {
        uint256 balance = balanceOf(account);
        uint256 oldWorkingBalance = _workingBalances[account];
        uint256 oldWorkingSupply = _workingSupply;
        (
            uint256 chessAmount,
            uint256 bonusAmount,
            uint256 amountQ,
            uint256 amountB,
            uint256 amountR,
            uint256 quoteAmount
        ) = _checkpoint(account, balance, oldWorkingBalance, oldWorkingSupply);
        _updateWorkingBalance(account, oldWorkingBalance, oldWorkingSupply, balance, totalSupply());

        if (chessAmount != 0) {
            chessSchedule.mint(account, chessAmount);
            delete _claimableChess[account];
        }
        if (bonusAmount != 0) {
            _bonusToken.safeTransfer(account, bonusAmount);
            delete _claimableBonus[account];
        }
        if (amountQ != 0 || amountB != 0 || amountR != 0 || quoteAmount != 0) {
            uint256 version = latestVersion;
            if (amountQ != 0) {
                fund.trancheTransfer(TRANCHE_Q, account, amountQ, version);
            }
            if (amountB != 0) {
                fund.trancheTransfer(TRANCHE_B, account, amountB, version);
            }
            if (amountR != 0) {
                fund.trancheTransfer(TRANCHE_R, account, amountR, version);
            }
            if (quoteAmount != 0) {
                _quoteToken.safeTransfer(account, quoteAmount);
            }
            delete userDistributions[account];
        }
    }

    function syncWithVotingEscrow(address account) external {
        uint256 balance = balanceOf(account);
        uint256 oldWorkingBalance = _workingBalances[account];
        uint256 oldWorkingSupply = _workingSupply;
        _checkpoint(account, balance, oldWorkingBalance, oldWorkingSupply);
        _updateWorkingBalance(account, oldWorkingBalance, oldWorkingSupply, balance, totalSupply());
    }

    function distribute(
        uint256 amountQ,
        uint256 amountB,
        uint256 amountR,
        uint256 quoteAmount,
        uint256 version
    ) external override onlyStableSwap {
        // Update global state
        distributions[version].amountQ = amountQ;
        distributions[version].amountB = amountB;
        distributions[version].amountR = amountR;
        distributions[version].quoteAmount = quoteAmount;
        distributionTotalSupplies[version] = totalSupply();
        latestVersion = version;
    }

    function _updateWorkingBalance(
        address account,
        uint256 oldWorkingBalance,
        uint256 oldWorkingSupply,
        uint256 newBalance,
        uint256 newTotalSupply
    ) private {
        uint256 newWorkingBalance = newBalance;
        uint256 veBalance = _votingEscrow.balanceOf(account);
        if (veBalance > 0) {
            uint256 veTotalSupply = _votingEscrow.totalSupply();
            uint256 maxWorkingBalance = newWorkingBalance.multiplyDecimal(MAX_BOOSTING_FACTOR);
            uint256 boostedWorkingBalance =
                newWorkingBalance.add(
                    newTotalSupply
                        .mul(veBalance)
                        .multiplyDecimal(MAX_BOOSTING_FACTOR_MINUS_ONE)
                        .div(veTotalSupply)
                );
            newWorkingBalance = maxWorkingBalance.min(boostedWorkingBalance);
        }
        _workingSupply = oldWorkingSupply.sub(oldWorkingBalance).add(newWorkingBalance);
        _workingBalances[account] = newWorkingBalance;
    }

    function _checkpoint(
        address account,
        uint256 balance,
        uint256 weight,
        uint256 totalWeight
    )
        private
        returns (
            uint256 chessAmount,
            uint256 bonusAmount,
            uint256 amountQ,
            uint256 amountB,
            uint256 amountR,
            uint256 quoteAmount
        )
    {
        chessAmount = _chessCheckpoint(account, weight, totalWeight);
        bonusAmount = _bonusCheckpoint(account, weight, totalWeight);
        (amountQ, amountB, amountR, quoteAmount) = _distributionCheckpoint(account, balance);
    }

    function _chessCheckpoint(
        address account,
        uint256 weight,
        uint256 totalWeight
    ) private returns (uint256 amount) {
        // Update global state
        uint256 timestamp = _chessIntegralTimestamp;
        uint256 integral = _chessIntegral;
        uint256 endWeek = _endOfWeek(timestamp);
        uint256 rate = _rate;
        for (uint256 i = 0; i < MAX_ITERATIONS && timestamp < block.timestamp; i++) {
            uint256 endTimestamp = endWeek.min(block.timestamp);
            if (totalWeight != 0 && endTimestamp > rewardStartTimestamp) {
                integral = integral.add(
                    rate
                        .mul(endTimestamp.sub(timestamp.max(rewardStartTimestamp)))
                        .decimalToPreciseDecimal()
                        .div(totalWeight)
                );
            }
            if (endTimestamp == endWeek) {
                rate = chessSchedule.getRate(endWeek).mul(
                    chessController.getFundRelativeWeight(address(this), endWeek)
                );
                if (endWeek < rewardStartTimestamp && endWeek + 1 weeks > rewardStartTimestamp) {
                    // Rewards start in the middle of the next week. We adjust the rate to
                    // compensate for the period between `endWeek` and `rewardStartTimestamp`.
                    rate = rate.mul(1 weeks).div(endWeek + 1 weeks - rewardStartTimestamp);
                }
                endWeek += 1 weeks;
            }
            timestamp = endTimestamp;
        }
        _chessIntegralTimestamp = block.timestamp;
        _chessIntegral = integral;
        _rate = rate;

        // Update per-user state
        amount = _claimableChess[account].add(
            weight.multiplyDecimalPrecise(integral.sub(_chessUserIntegrals[account]))
        );
        _claimableChess[account] = amount;
        _chessUserIntegrals[account] = integral;
    }

    function _bonusCheckpoint(
        address account,
        uint256 weight,
        uint256 totalWeight
    ) private returns (uint256 amount) {
        // Update global state
        uint256 newBonus = ISwapBonus(swapBonus).getBonus();
        uint256 integral = _bonusIntegral;
        if (totalWeight != 0 && newBonus != 0) {
            integral = integral.add(newBonus.divideDecimalPrecise(totalWeight));
            _bonusIntegral = integral;
        }

        // Update per-user state
        uint256 oldUserIntegral = _bonusUserIntegral[account];
        if (oldUserIntegral == integral) {
            return _claimableBonus[account];
        }
        amount = _claimableBonus[account].add(
            weight.multiplyDecimalPrecise(integral.sub(oldUserIntegral))
        );
        _claimableBonus[account] = amount;
        _bonusUserIntegral[account] = integral;
    }

    function _distributionCheckpoint(address account, uint256 balance)
        private
        returns (
            uint256 amountQ,
            uint256 amountB,
            uint256 amountR,
            uint256 quoteAmount
        )
    {
        uint256 version = userVersions[account];
        uint256 newVersion = latestVersion;

        // Update per-user state
        Distribution storage userDist = userDistributions[account];
        amountQ = userDist.amountQ;
        amountB = userDist.amountB;
        amountR = userDist.amountR;
        quoteAmount = userDist.quoteAmount;
        if (version == newVersion) {
            return (amountQ, amountB, amountR, quoteAmount);
        }
        for (uint256 i = version; i < newVersion; i++) {
            if (amountQ != 0 || amountB != 0 || amountR != 0) {
                (amountQ, amountB, amountR) = fund.doRebalance(amountQ, amountB, amountR, i);
            }
            Distribution storage dist = distributions[i + 1];
            uint256 distTotalSupply = distributionTotalSupplies[i + 1];
            if (distTotalSupply != 0) {
                amountQ = amountQ.add(dist.amountQ.mul(balance).div(distTotalSupply));
                amountB = amountB.add(dist.amountB.mul(balance).div(distTotalSupply));
                amountR = amountR.add(dist.amountR.mul(balance).div(distTotalSupply));
                quoteAmount = quoteAmount.add(dist.quoteAmount.mul(balance).div(distTotalSupply));
            }
        }
        userDist.amountQ = amountQ;
        userDist.amountB = amountB;
        userDist.amountR = amountR;
        userDist.quoteAmount = quoteAmount;
        userVersions[account] = newVersion;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract SwapBonus is Ownable {
    using Math for uint256;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public immutable liquidityGauge;
    address public immutable bonusToken;
    uint256 public ratePerSecond;
    uint256 public startTimestamp;
    uint256 public endTimestamp;
    uint256 public lastTimestamp;

    constructor(address liquidityGauge_, address bonusToken_) public {
        liquidityGauge = liquidityGauge_;
        bonusToken = bonusToken_;
    }

    function updateBonus(
        uint256 amount,
        uint256 start,
        uint256 interval
    ) external onlyOwner {
        require(start >= block.timestamp, "Start time in the past");
        require(
            endTimestamp < block.timestamp && endTimestamp == lastTimestamp,
            "Last reward not yet expired"
        );
        ratePerSecond = amount.div(interval);
        startTimestamp = start;
        endTimestamp = start.add(interval);
        lastTimestamp = startTimestamp;
        IERC20(bonusToken).safeTransferFrom(msg.sender, address(this), ratePerSecond.mul(interval));
    }

    function getBonus() external returns (uint256) {
        require(msg.sender == liquidityGauge);
        uint256 currentTimestamp = endTimestamp.min(block.timestamp);
        uint256 reward = ratePerSecond.mul(currentTimestamp - lastTimestamp);
        lastTimestamp = currentTimestamp;
        if (reward > 0) {
            IERC20(bonusToken).safeTransfer(liquidityGauge, reward);
        }
        return reward;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IChessSchedule.sol";
import "../interfaces/IChessController.sol";
import "../interfaces/IVotingEscrow.sol";

import "../utils/CoreUtility.sol";
import "../utils/SafeDecimalMath.sol";

interface ICurveLiquidityGauge {
    function lp_token() external view returns (address);

    function deposit(
        uint256 _value,
        address _addr,
        bool _claim_rewards
    ) external;

    function withdraw(uint256 _value, bool _claim_rewards) external;

    function set_rewards_receiver(address _receiver) external;
}

interface ICurveMinter {
    function token() external view returns (address);

    function mint(address gauge_addr) external;
}

contract LiquidityGaugeCurve is CoreUtility, ERC20, Ownable {
    using Math for uint256;
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;
    using SafeERC20 for IERC20;

    event ReceiverUpdated(address receiver);

    uint256 private constant MAX_ITERATIONS = 500;
    uint256 private constant MAX_BOOSTING_FACTOR = 3e18;
    uint256 private constant MAX_BOOSTING_FACTOR_MINUS_ONE = MAX_BOOSTING_FACTOR - 1e18;

    ICurveLiquidityGauge public immutable curveLiquidityGauge;
    IERC20 public immutable curveLiquidityToken;
    IChessSchedule public immutable chessSchedule;
    IChessController public immutable chessController;
    ICurveMinter private immutable _curveMinter;
    IVotingEscrow private immutable _votingEscrow;
    IERC20 private immutable _bonusToken;

    uint256 private _workingSupply;
    mapping(address => uint256) private _workingBalances;

    uint256 private _chessIntegral;
    uint256 private _chessIntegralTimestamp;
    mapping(address => uint256) private _chessUserIntegrals;
    mapping(address => uint256) private _claimableChess;

    uint256 public totalBonus;
    uint256 private _bonusIntegral;
    mapping(address => uint256) private _bonusUserIntegral;
    mapping(address => uint256) private _claimableBonus;

    /// @dev Per-gauge CHESS emission rate. The product of CHESS emission rate
    ///      and weekly percentage of the gauge
    uint256 private _rate;

    bool public allowDepositFurther;

    constructor(
        string memory name_,
        string memory symbol_,
        address curveLiquidityGauge_,
        address curveMinter_,
        address chessSchedule_,
        address chessController_,
        address votingEscrow_
    ) public ERC20(name_, symbol_) {
        curveLiquidityGauge = ICurveLiquidityGauge(curveLiquidityGauge_);
        curveLiquidityToken = IERC20(ICurveLiquidityGauge(curveLiquidityGauge_).lp_token());
        chessSchedule = IChessSchedule(chessSchedule_);
        chessController = IChessController(chessController_);
        _curveMinter = ICurveMinter(curveMinter_);
        _bonusToken = IERC20(ICurveMinter(curveMinter_).token());
        _votingEscrow = IVotingEscrow(votingEscrow_);
        _chessIntegralTimestamp = block.timestamp;
    }

    function getRate() external view returns (uint256) {
        return _rate / 1e18;
    }

    function deposit(uint256 amount, address recipient) external {
        curveLiquidityToken.safeTransferFrom(msg.sender, address(this), amount);
        if (allowDepositFurther) {
            // Deposit and claim CRV rewards before gauge checkpoint
            curveLiquidityToken.safeApprove(address(curveLiquidityGauge), amount);
            curveLiquidityGauge.deposit(amount, address(this), true);
        }

        uint256 oldWorkingBalance = _workingBalances[recipient];
        uint256 oldWorkingSupply = _workingSupply;
        _checkpoint(recipient, oldWorkingBalance, oldWorkingSupply);

        _mint(recipient, amount);
        _updateWorkingBalance(recipient, oldWorkingBalance, oldWorkingSupply);
    }

    function withdraw(uint256 amount) external {
        uint256 lpBalance = curveLiquidityToken.balanceOf(address(this));
        if (lpBalance < amount) {
            // Withdraw and claim CRV rewards before gauge checkpoint
            curveLiquidityGauge.withdraw(amount - lpBalance, true);
        }
        curveLiquidityToken.safeTransfer(msg.sender, amount);

        uint256 oldWorkingBalance = _workingBalances[msg.sender];
        uint256 oldWorkingSupply = _workingSupply;
        _checkpoint(msg.sender, oldWorkingBalance, oldWorkingSupply);

        _burn(msg.sender, amount);
        _updateWorkingBalance(msg.sender, oldWorkingBalance, oldWorkingSupply);
    }

    function _transfer(
        address,
        address,
        uint256
    ) internal override {
        revert("Transfer is not allowed");
    }

    function workingBalanceOf(address account) external view returns (uint256) {
        return _workingBalances[account];
    }

    function workingSupply() external view returns (uint256) {
        return _workingSupply;
    }

    function claimableRewards(address account)
        external
        returns (uint256 chessAmount, uint256 bonusAmount)
    {
        return _checkpoint(account, _workingBalances[account], _workingSupply);
    }

    function claimRewards(address account) external {
        uint256 oldWorkingBalance = _workingBalances[account];
        uint256 oldWorkingSupply = _workingSupply;
        (uint256 chessAmount, uint256 bonusAmount) =
            _checkpoint(account, oldWorkingBalance, oldWorkingSupply);
        _updateWorkingBalance(account, oldWorkingBalance, oldWorkingSupply);

        if (chessAmount != 0) {
            chessSchedule.mint(account, chessAmount);
            delete _claimableChess[account];
        }
        if (bonusAmount != 0) {
            totalBonus = totalBonus.sub(bonusAmount);
            _bonusToken.safeTransfer(account, bonusAmount);
            delete _claimableBonus[account];
        }
    }

    function syncWithVotingEscrow(address account) external {
        uint256 oldWorkingBalance = _workingBalances[account];
        uint256 oldWorkingSupply = _workingSupply;
        _checkpoint(account, oldWorkingBalance, oldWorkingSupply);
        _updateWorkingBalance(account, oldWorkingBalance, oldWorkingSupply);
    }

    function depositToGauge() external onlyOwner {
        uint256 lpBalance = curveLiquidityToken.balanceOf(address(this));
        curveLiquidityToken.safeApprove(address(curveLiquidityGauge), lpBalance);
        curveLiquidityGauge.deposit(lpBalance, address(this), true);
    }

    function setDepositFurther(bool allowDepositFurther_) external onlyOwner {
        allowDepositFurther = allowDepositFurther_;
    }

    function setRewardsReceiver(address receiver) external onlyOwner {
        curveLiquidityGauge.set_rewards_receiver(receiver);
        emit ReceiverUpdated(receiver);
    }

    function _updateWorkingBalance(
        address account,
        uint256 oldWorkingBalance,
        uint256 oldWorkingSupply
    ) private {
        uint256 newWorkingBalance = balanceOf(account);
        uint256 veBalance = _votingEscrow.balanceOf(account);
        if (veBalance > 0) {
            uint256 veTotalSupply = _votingEscrow.totalSupply();
            uint256 maxWorkingBalance = newWorkingBalance.multiplyDecimal(MAX_BOOSTING_FACTOR);
            uint256 boostedWorkingBalance =
                newWorkingBalance.add(
                    totalSupply().mul(veBalance).multiplyDecimal(MAX_BOOSTING_FACTOR_MINUS_ONE).div(
                        veTotalSupply
                    )
                );
            newWorkingBalance = maxWorkingBalance.min(boostedWorkingBalance);
        }
        _workingSupply = oldWorkingSupply.sub(oldWorkingBalance).add(newWorkingBalance);
        _workingBalances[account] = newWorkingBalance;
    }

    function _checkpoint(
        address account,
        uint256 weight,
        uint256 totalWeight
    ) private returns (uint256 chessAmount, uint256 bonusAmount) {
        chessAmount = _chessCheckpoint(account, weight, totalWeight);
        bonusAmount = _bonusCheckpoint(account, weight, totalWeight);
    }

    function _chessCheckpoint(
        address account,
        uint256 weight,
        uint256 totalWeight
    ) private returns (uint256 amount) {
        // Update global state
        uint256 timestamp = _chessIntegralTimestamp;
        uint256 integral = _chessIntegral;
        uint256 endWeek = _endOfWeek(timestamp);
        uint256 rate = _rate;
        if (rate == 0) {
            // CHESS emission may update in the middle of a week due to cross-chain lag.
            // We re-calculate the rate if it was zero after the last checkpoint.
            uint256 weeklySupply = chessSchedule.getWeeklySupply(timestamp);
            if (weeklySupply != 0) {
                rate = (weeklySupply / (endWeek - timestamp)).mul(
                    chessController.getFundRelativeWeight(address(this), timestamp)
                );
            }
        }
        for (uint256 i = 0; i < MAX_ITERATIONS && timestamp < block.timestamp; i++) {
            uint256 endTimestamp = endWeek.min(block.timestamp);
            if (totalWeight != 0) {
                integral = integral.add(
                    rate.mul(endTimestamp - timestamp).decimalToPreciseDecimal().div(totalWeight)
                );
            }
            if (endTimestamp == endWeek) {
                rate = chessSchedule.getRate(endWeek).mul(
                    chessController.getFundRelativeWeight(address(this), endWeek)
                );
                endWeek += 1 weeks;
            }
            timestamp = endTimestamp;
        }
        _chessIntegralTimestamp = block.timestamp;
        _chessIntegral = integral;
        _rate = rate;

        // Update per-user state
        amount = _claimableChess[account].add(
            weight.multiplyDecimalPrecise(integral.sub(_chessUserIntegrals[account]))
        );
        _claimableChess[account] = amount;
        _chessUserIntegrals[account] = integral;
    }

    function _bonusCheckpoint(
        address account,
        uint256 weight,
        uint256 totalWeight
    ) private returns (uint256 amount) {
        // Update global state
        _curveMinter.mint(address(curveLiquidityGauge));
        uint256 currentBonus = _bonusToken.balanceOf(address(this));
        uint256 newBonus = currentBonus.sub(totalBonus);
        uint256 integral = _bonusIntegral;
        if (totalWeight != 0 && newBonus != 0) {
            integral = integral.add(newBonus.divideDecimalPrecise(totalWeight));
            _bonusIntegral = integral;
        }
        totalBonus = currentBonus;

        // Update per-user state
        uint256 oldUserIntegral = _bonusUserIntegral[account];
        if (oldUserIntegral == integral) {
            return _claimableBonus[account];
        }
        amount = _claimableBonus[account].add(
            weight.multiplyDecimalPrecise(integral.sub(oldUserIntegral))
        );
        _claimableBonus[account] = amount;
        _bonusUserIntegral[account] = integral;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./LiquidityGaugeCurve.sol";

interface ICurvePool {
    function coins(uint256 index) external view returns (address);

    function add_liquidity(
        uint256[2] memory amounts,
        uint256 min_mint_amount,
        bool use_eth,
        address receiver
    ) external payable returns (uint256);
}

interface ICurveLiquidityToken {
    function minter() external view returns (address);
}

contract CurveRouter {
    using SafeERC20 for IERC20;

    LiquidityGaugeCurve public immutable tranchessLiquidityGauge;
    address public immutable wrappedToken;
    IERC20 public immutable curveLiquidityToken;
    ICurvePool public immutable curvePool;
    address[2] public coins;

    constructor(address tranchessLiquidityGauge_, address wrappedToken_) public {
        tranchessLiquidityGauge = LiquidityGaugeCurve(tranchessLiquidityGauge_);
        wrappedToken = wrappedToken_;

        IERC20 liquidityToken = LiquidityGaugeCurve(tranchessLiquidityGauge_).curveLiquidityToken();
        curveLiquidityToken = liquidityToken;
        ICurvePool pool = ICurvePool(ICurveLiquidityToken(address(liquidityToken)).minter());
        curvePool = pool;
        coins[0] = pool.coins(0);
        coins[1] = pool.coins(1);
    }

    receive() external payable {}

    function addLiquidity(
        uint256[2] memory amounts,
        uint256 minMintAmount,
        bool stakeFurther
    ) external payable returns (uint256 lpToken) {
        for (uint256 i = 0; i < coins.length; i++) {
            if (coins[i] != wrappedToken) {
                IERC20(coins[i]).safeTransferFrom(msg.sender, address(this), amounts[i]);
                IERC20(coins[i]).safeApprove(address(curvePool), amounts[i]);
            }
        }

        if (stakeFurther) {
            lpToken = curvePool.add_liquidity{value: msg.value}(
                amounts,
                minMintAmount,
                true,
                address(this)
            );
            curveLiquidityToken.safeApprove(address(tranchessLiquidityGauge), lpToken);
            tranchessLiquidityGauge.deposit(lpToken, msg.sender);
        } else {
            lpToken = curvePool.add_liquidity{value: msg.value}(
                amounts,
                minMintAmount,
                true,
                msg.sender
            );
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./VotingEscrowCheckpoint.sol";
import "../utils/CoreUtility.sol";
import "../utils/SafeDecimalMath.sol";

import "../interfaces/IBallot.sol";
import "../interfaces/IFundV3.sol";
import "../interfaces/ITwapOracleV2.sol";
import "../interfaces/IVotingEscrow.sol";

contract InterestRateBallotV2 is IBallot, CoreUtility, VotingEscrowCheckpoint {
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;

    event Voted(
        address indexed account,
        uint256 oldAmount,
        uint256 oldUnlockTime,
        uint256 oldWeight,
        uint256 amount,
        uint256 indexed unlockTime,
        uint256 indexed weight
    );

    IVotingEscrow public immutable votingEscrow;

    mapping(address => Voter) public voters;

    // unlockTime => amount that will be unlocked at unlockTime
    mapping(uint256 => uint256) public scheduledUnlock;
    mapping(uint256 => uint256) public veSupplyPerWeek;
    uint256 public totalLocked;
    uint256 public nextWeekSupply;

    mapping(uint256 => uint256) public weightedScheduledUnlock;
    mapping(uint256 => uint256) public weightedVeSupplyPerWeek;
    uint256 public weightedTotalLocked;
    uint256 public weightedNextWeekSupply;

    uint256 public checkpointWeek;

    constructor(address votingEscrow_)
        public
        VotingEscrowCheckpoint(IVotingEscrow(votingEscrow_).maxTime())
    {
        votingEscrow = IVotingEscrow(votingEscrow_);
        checkpointWeek = _endOfWeek(block.timestamp) - 1 weeks;
    }

    function getReceipt(address account) external view returns (Voter memory) {
        return voters[account];
    }

    function totalSupplyAtWeek(uint256 week) external view returns (uint256) {
        return _totalSupplyAtWeek(week);
    }

    function weightedTotalSupplyAtWeek(uint256 week) external view returns (uint256) {
        return _weightedTotalSupplyAtWeek(week);
    }

    function averageAtWeek(uint256 week) external view returns (uint256) {
        return _averageAtWeek(week);
    }

    /// @notice Return a fund's relative income since the last settlement. Note that denominators
    ///         of the returned ratios are the latest value instead of that at the last settlement.
    ///         If the amount of underlying token increases from 100 to 110 and assume that there's
    ///         no creation/redemption or underlying price change, return value `incomeOverQ` will
    ///         be 1/11 rather than 1/10.
    /// @param fund Address of the fund
    /// @return incomeOverQ The ratio of income to the fund's total value
    /// @return incomeOverB The ratio of income to equivalent BISHOP total value if all QUEEN are split
    function getFundRelativeIncome(IFundV3 fund)
        public
        view
        returns (uint256 incomeOverQ, uint256 incomeOverB)
    {
        (bool success, bytes memory encodedDay) =
            address(fund).staticcall(abi.encodeWithSignature("currentDay()"));
        if (!success || encodedDay.length != 0x20) {
            return (0, 0);
        }
        uint256 currentDay = abi.decode(encodedDay, (uint256));
        if (currentDay == 0) {
            return (0, 0);
        }
        uint256 version = fund.getRebalanceSize();
        if (version != 0 && fund.getRebalanceTimestamp(version - 1) == block.timestamp) {
            return (0, 0); // Rebalance is triggered
        }
        uint256 lastUnderlying = fund.historicalUnderlying(currentDay - 1 days);
        uint256 lastEquivalentTotalB = fund.historicalEquivalentTotalB(currentDay - 1 days);
        if (lastUnderlying == 0 || lastEquivalentTotalB == 0) {
            return (0, 0);
        }
        uint256 currentUnderlying = fund.getTotalUnderlying();
        uint256 currentEquivalentTotalB = fund.getEquivalentTotalB();
        if (currentUnderlying == 0 || currentEquivalentTotalB == 0) {
            return (0, 0);
        }
        {
            uint256 ratio =
                ((lastUnderlying * currentEquivalentTotalB) / currentUnderlying).divideDecimal(
                    lastEquivalentTotalB
                );
            incomeOverQ = ratio > 1e18 ? 0 : 1e18 - ratio;
        }
        uint256 underlyingPrice = ITwapOracleV2(fund.twapOracle()).getTwap(currentDay);
        (uint256 navSum, uint256 navB, ) = fund.extrapolateNav(underlyingPrice);
        incomeOverB = incomeOverQ.mul(navSum) / navB;
    }

    /// @notice Return the fraction of annualized relative income of the calling fund that should
    ///         be added to BISHOP NAV. Zero is returned when this function is not called by
    ///         an `IFundV3` contract or the fund is just rebalanced in the same block.
    function count(uint256 timestamp) external view override returns (uint256) {
        (, uint256 incomeOverB) = getFundRelativeIncome(IFundV3(msg.sender));
        if (incomeOverB == 0) {
            return 0;
        } else {
            return
                incomeOverB.multiplyDecimal(_averageAtWeek(_endOfWeek(timestamp) - 1 weeks) * 365);
        }
    }

    function cast(uint256 weight) external {
        require(weight <= 1e18, "Invalid weight");

        IVotingEscrow.LockedBalance memory lockedBalance =
            votingEscrow.getLockedBalance(msg.sender);
        Voter memory voter = voters[msg.sender];
        require(
            lockedBalance.amount > 0 && lockedBalance.unlockTime > block.timestamp,
            "No veCHESS"
        );

        _checkpointAndUpdateLock(
            voter.amount,
            voter.unlockTime,
            voter.weight,
            lockedBalance.amount,
            lockedBalance.unlockTime,
            weight
        );

        emit Voted(
            msg.sender,
            voter.amount,
            voter.unlockTime,
            voter.weight,
            lockedBalance.amount,
            lockedBalance.unlockTime,
            weight
        );

        // update voter amount per account
        voters[msg.sender] = Voter({
            amount: lockedBalance.amount,
            unlockTime: lockedBalance.unlockTime,
            weight: weight
        });
    }

    function syncWithVotingEscrow(address account) external override {
        Voter memory voter = voters[account];
        if (voter.amount == 0) {
            return; // The account did not voted before
        }

        IVotingEscrow.LockedBalance memory lockedBalance = votingEscrow.getLockedBalance(account);
        if (lockedBalance.unlockTime <= block.timestamp) {
            return;
        }

        _checkpointAndUpdateLock(
            voter.amount,
            voter.unlockTime,
            voter.weight,
            lockedBalance.amount,
            lockedBalance.unlockTime,
            voter.weight
        );

        emit Voted(
            account,
            voter.amount,
            voter.unlockTime,
            voter.weight,
            lockedBalance.amount,
            lockedBalance.unlockTime,
            voter.weight
        );

        // update voter amount per account
        voters[account].amount = lockedBalance.amount;
        voters[account].unlockTime = lockedBalance.unlockTime;
    }

    function _totalSupplyAtWeek(uint256 week) private view returns (uint256) {
        return
            week <= checkpointWeek
                ? veSupplyPerWeek[week]
                : _veTotalSupplyAtWeek(
                    week,
                    scheduledUnlock,
                    checkpointWeek,
                    nextWeekSupply,
                    totalLocked
                );
    }

    function _weightedTotalSupplyAtWeek(uint256 week) private view returns (uint256) {
        return
            week <= checkpointWeek
                ? weightedVeSupplyPerWeek[week]
                : _veTotalSupplyAtWeek(
                    week,
                    weightedScheduledUnlock,
                    checkpointWeek,
                    weightedNextWeekSupply,
                    weightedTotalLocked
                );
    }

    function _averageAtWeek(uint256 week) private view returns (uint256) {
        uint256 total = _totalSupplyAtWeek(week);
        if (total == 0) {
            return 0.5e18;
        }
        return _weightedTotalSupplyAtWeek(week) / total;
    }

    function _checkpointAndUpdateLock(
        uint256 oldAmount,
        uint256 oldUnlockTime,
        uint256 oldWeight,
        uint256 newAmount,
        uint256 newUnlockTime,
        uint256 newWeight
    ) private {
        uint256 oldCheckpointWeek = checkpointWeek;
        (, uint256 newNextWeekSupply, uint256 newTotalLocked) =
            _veCheckpoint(
                scheduledUnlock,
                oldCheckpointWeek,
                nextWeekSupply,
                totalLocked,
                veSupplyPerWeek
            );
        (nextWeekSupply, totalLocked) = _veUpdateLock(
            newNextWeekSupply,
            newTotalLocked,
            oldAmount,
            oldUnlockTime,
            newAmount,
            newUnlockTime,
            scheduledUnlock
        );
        uint256 newWeightedNextWeekSupply;
        uint256 newWeightedTotalLocked;
        (checkpointWeek, newWeightedNextWeekSupply, newWeightedTotalLocked) = _veCheckpoint(
            weightedScheduledUnlock,
            oldCheckpointWeek,
            weightedNextWeekSupply,
            weightedTotalLocked,
            weightedVeSupplyPerWeek
        );
        (weightedNextWeekSupply, weightedTotalLocked) = _veUpdateLock(
            newWeightedNextWeekSupply,
            newWeightedTotalLocked,
            oldAmount * oldWeight,
            oldUnlockTime,
            newAmount * newWeight,
            newUnlockTime,
            weightedScheduledUnlock
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../utils/SafeDecimalMath.sol";
import "../utils/CoreUtility.sol";

import "../interfaces/IVotingEscrow.sol";
import "../interfaces/IWrappedERC20.sol";

contract FeeDistributor is CoreUtility, Ownable {
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;
    using SafeERC20 for IERC20;

    event AdminUpdated(address newAdmin);
    event AdminFeeRateUpdated(uint256 newAdminFeeRate);

    /// @notice 60% as the max admin fee rate
    uint256 public constant MAX_ADMIN_FEE_RATE = 6e17;

    uint256 private immutable _maxTime;
    IERC20 public immutable rewardToken;
    IVotingEscrow public immutable votingEscrow;

    /// @notice Receiver for admin fee
    address public admin;

    /// @notice Admin fee rate
    uint256 public adminFeeRate;

    /// @notice Timestamp of the last checkpoint
    uint256 public checkpointTimestamp;

    /// @notice Mapping of unlockTime => total amount that will be unlocked at unlockTime
    mapping(uint256 => uint256) public scheduledUnlock;

    /// @notice Amount of Chess locked at the end of the last checkpoint's week
    uint256 public nextWeekLocked;

    /// @notice Total veCHESS at the end of the last checkpoint's week
    uint256 public nextWeekSupply;

    /// @notice Cumulative rewards received until the last checkpoint minus cumulative rewards
    ///         claimed until now
    uint256 public lastRewardBalance;

    /// @notice Mapping of week => total rewards accumulated
    ///
    ///         Key is the start timestamp of a week on each Thursday. Value is
    ///         the rewards collected from the corresponding fund in rewardToken's unit
    mapping(uint256 => uint256) public rewardsPerWeek;

    /// @notice Mapping of week => vote-locked chess total supplies
    ///
    ///         Key is the start timestamp of a week on each Thursday. Value is
    ///         vote-locked chess total supplies captured at the start of each week
    mapping(uint256 => uint256) public veSupplyPerWeek;

    /// @notice Locked balance of an account, which is synchronized with `VotingEscrow` when
    ///         `syncWithVotingEscrow()` is called
    mapping(address => IVotingEscrow.LockedBalance) public userLockedBalances;

    /// @notice Start timestamp of the week of a user's last checkpoint
    mapping(address => uint256) public userWeekCursors;

    /// @notice An account's veCHESS amount at the beginning of the week of this user's
    ///         last checkpoint
    mapping(address => uint256) public userLastBalances;

    /// @notice Mapping of account => amount of claimable Chess
    mapping(address => uint256) public claimableRewards;

    event Synchronized(
        address indexed account,
        uint256 oldAmount,
        uint256 oldUnlockTime,
        uint256 newAmount,
        uint256 newUnlockTime
    );

    constructor(
        address rewardToken_,
        address votingEscrow_,
        address admin_,
        uint256 adminFeeRate_
    ) public {
        rewardToken = IERC20(rewardToken_);
        votingEscrow = IVotingEscrow(votingEscrow_);
        _maxTime = IVotingEscrow(votingEscrow_).maxTime();
        _updateAdmin(admin_);
        _updateAdminFeeRate(adminFeeRate_);
        checkpointTimestamp = block.timestamp;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balanceAtTimestamp(userLockedBalances[account], block.timestamp);
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupplyAtTimestamp(block.timestamp);
    }

    function balanceOfAtTimestamp(address account, uint256 timestamp)
        external
        view
        returns (uint256)
    {
        require(timestamp >= checkpointTimestamp, "Must be current or future time");
        return _balanceAtTimestamp(userLockedBalances[account], timestamp);
    }

    function totalSupplyAtTimestamp(uint256 timestamp) external view returns (uint256) {
        require(timestamp >= checkpointTimestamp, "Must be current or future time");
        return _totalSupplyAtTimestamp(timestamp);
    }

    /// @dev Calculate the amount of veCHESS of a `LockedBalance` at a given timestamp
    function _balanceAtTimestamp(
        IVotingEscrow.LockedBalance memory lockedBalance,
        uint256 timestamp
    ) private view returns (uint256) {
        if (timestamp >= lockedBalance.unlockTime) {
            return 0;
        }
        return lockedBalance.amount.mul(lockedBalance.unlockTime - timestamp) / _maxTime;
    }

    function _totalSupplyAtTimestamp(uint256 timestamp) private view returns (uint256) {
        uint256 total = 0;
        for (
            uint256 weekCursor = _endOfWeek(timestamp);
            weekCursor <= timestamp + _maxTime;
            weekCursor += 1 weeks
        ) {
            total = total.add((scheduledUnlock[weekCursor].mul(weekCursor - timestamp)) / _maxTime);
        }
        return total;
    }

    /// @notice Synchronize an account's locked Chess with `VotingEscrow`.
    /// @param account Address of the synchronized account
    function syncWithVotingEscrow(address account) external {
        userCheckpoint(account);

        uint256 nextWeek = _endOfWeek(block.timestamp);
        IVotingEscrow.LockedBalance memory newLockedBalance =
            votingEscrow.getLockedBalance(account);
        if (newLockedBalance.unlockTime <= nextWeek) {
            return;
        }
        IVotingEscrow.LockedBalance memory oldLockedBalance = userLockedBalances[account];
        uint256 newNextWeekLocked = nextWeekLocked;
        uint256 newNextWeekSupply = nextWeekSupply;

        // Remove the old schedule if there is one
        if (oldLockedBalance.amount > 0 && oldLockedBalance.unlockTime > nextWeek) {
            scheduledUnlock[oldLockedBalance.unlockTime] = scheduledUnlock[
                oldLockedBalance.unlockTime
            ]
                .sub(oldLockedBalance.amount);
            newNextWeekLocked = newNextWeekLocked.sub(oldLockedBalance.amount);
            newNextWeekSupply = newNextWeekSupply.sub(
                oldLockedBalance.amount.mul(oldLockedBalance.unlockTime - nextWeek) / _maxTime
            );
        }

        scheduledUnlock[newLockedBalance.unlockTime] = scheduledUnlock[newLockedBalance.unlockTime]
            .add(newLockedBalance.amount);
        nextWeekLocked = newNextWeekLocked.add(newLockedBalance.amount);
        // Round up on division when added to the total supply, so that the total supply is never
        // smaller than the sum of all accounts' veCHESS balance.
        nextWeekSupply = newNextWeekSupply.add(
            newLockedBalance.amount.mul(newLockedBalance.unlockTime - nextWeek).add(_maxTime - 1) /
                _maxTime
        );
        userLockedBalances[account] = newLockedBalance;

        emit Synchronized(
            account,
            oldLockedBalance.amount,
            oldLockedBalance.unlockTime,
            newLockedBalance.amount,
            newLockedBalance.unlockTime
        );
    }

    function userCheckpoint(address account) public returns (uint256 rewards) {
        checkpoint();
        rewards = claimableRewards[account].add(_rewardCheckpoint(account));
        claimableRewards[account] = rewards;
    }

    function claimRewards(address account) external returns (uint256 rewards) {
        rewards = _claimRewards(account);
        rewardToken.safeTransfer(account, rewards);
    }

    function claimRewardsAndUnwrap(address account) external returns (uint256 rewards) {
        rewards = _claimRewards(account);
        IWrappedERC20(address(rewardToken)).withdraw(rewards);
        (bool success, ) = account.call{value: rewards}("");
        require(success, "Transfer failed");
    }

    /// @notice Receive unwrapped transfer from the wrapped token.
    receive() external payable {}

    function _claimRewards(address account) private returns (uint256 rewards) {
        checkpoint();
        rewards = claimableRewards[account].add(_rewardCheckpoint(account));
        claimableRewards[account] = 0;
        lastRewardBalance = lastRewardBalance.sub(rewards);
    }

    /// @notice Make a global checkpoint. If the period since the last checkpoint spans over
    ///         multiple weeks, rewards received in this period are split into these weeks
    ///         proportional to the time in each week.
    /// @dev Post-conditions:
    ///
    ///      - `checkpointTimestamp == block.timestamp`
    ///      - `lastRewardBalance == rewardToken.balanceOf(address(this))`
    ///      - All `rewardsPerWeek[t]` are updated, where `t <= checkpointTimestamp`
    ///      - All `veSupplyPerWeek[t]` are set, where `t <= checkpointTimestamp`
    ///      - `nextWeekSupply` is the total veCHESS at the end of this week
    ///      - `nextWeekLocked` is the total locked Chess at the end of this week
    function checkpoint() public {
        uint256 tokenBalance = rewardToken.balanceOf(address(this));
        uint256 tokensToDistribute = tokenBalance.sub(lastRewardBalance);
        lastRewardBalance = tokenBalance;

        uint256 adminFee = tokensToDistribute.multiplyDecimal(adminFeeRate);
        if (adminFee > 0) {
            claimableRewards[admin] = claimableRewards[admin].add(adminFee);
            tokensToDistribute = tokensToDistribute.sub(adminFee);
        }
        uint256 rewardTime = checkpointTimestamp;
        uint256 weekCursor = _endOfWeek(rewardTime) - 1 weeks;
        uint256 currentWeek = _endOfWeek(block.timestamp) - 1 weeks;

        // Update veCHESS supply at the beginning of each week since the last checkpoint.
        if (weekCursor < currentWeek) {
            uint256 newLocked = nextWeekLocked;
            uint256 newSupply = nextWeekSupply;
            for (uint256 w = weekCursor + 1 weeks; w <= currentWeek; w += 1 weeks) {
                veSupplyPerWeek[w] = newSupply;
                // Calculate supply at the end of the next week.
                newSupply = newSupply.sub(newLocked.mul(1 weeks) / _maxTime);
                // Remove Chess unlocked at the end of the next week from total locked amount.
                newLocked = newLocked.sub(scheduledUnlock[w + 1 weeks]);
            }
            nextWeekLocked = newLocked;
            nextWeekSupply = newSupply;
        }

        // Distribute rewards received since the last checkpoint.
        if (tokensToDistribute > 0) {
            if (weekCursor >= currentWeek) {
                rewardsPerWeek[weekCursor] = rewardsPerWeek[weekCursor].add(tokensToDistribute);
            } else {
                uint256 sinceLast = block.timestamp - rewardTime;
                // Calculate the fraction of rewards proportional to the time from
                // the last checkpoint to the end of that week.
                rewardsPerWeek[weekCursor] = rewardsPerWeek[weekCursor].add(
                    tokensToDistribute.mul(weekCursor + 1 weeks - rewardTime) / sinceLast
                );
                weekCursor += 1 weeks;
                // Calculate the fraction of rewards for intermediate whole weeks.
                while (weekCursor < currentWeek) {
                    rewardsPerWeek[weekCursor] = tokensToDistribute.mul(1 weeks) / sinceLast;
                    weekCursor += 1 weeks;
                }
                // Calculate the fraction of rewards proportional to the time from
                // the beginning of the current week to the current block timestamp.
                rewardsPerWeek[weekCursor] =
                    tokensToDistribute.mul(block.timestamp - weekCursor) /
                    sinceLast;
            }
        }

        checkpointTimestamp = block.timestamp;
    }

    function _updateAdmin(address newAdmin) private {
        admin = newAdmin;
        emit AdminUpdated(newAdmin);
    }

    function updateAdmin(address newAdmin) external onlyOwner {
        _updateAdmin(newAdmin);
    }

    function _updateAdminFeeRate(uint256 newAdminFeeRate) private {
        require(newAdminFeeRate <= MAX_ADMIN_FEE_RATE, "Cannot exceed max admin fee rate");
        adminFeeRate = newAdminFeeRate;
        emit AdminFeeRateUpdated(newAdminFeeRate);
    }

    function updateAdminFeeRate(uint256 newAdminFeeRate) external onlyOwner {
        _updateAdminFeeRate(newAdminFeeRate);
    }

    /// @dev Calculate rewards since a user's last checkpoint and make a new checkpoint.
    ///
    ///      Post-conditions:
    ///
    ///      - `userWeekCursor[account]` is the start timestamp of the current week
    ///      - `userLastBalances[account]` is amount of veCHESS at the beginning of the current week
    /// @param account Address of the account
    /// @return Rewards since the last checkpoint
    function _rewardCheckpoint(address account) private returns (uint256) {
        uint256 currentWeek = _endOfWeek(block.timestamp) - 1 weeks;
        uint256 weekCursor = userWeekCursors[account];
        if (weekCursor >= currentWeek) {
            return 0;
        }
        if (weekCursor == 0) {
            userWeekCursors[account] = currentWeek;
            return 0;
        }

        // The week of the last user checkpoint has ended.
        uint256 lastBalance = userLastBalances[account];
        uint256 rewards =
            lastBalance > 0
                ? lastBalance.mul(rewardsPerWeek[weekCursor]) / veSupplyPerWeek[weekCursor]
                : 0;
        weekCursor += 1 weeks;

        // Iterate over succeeding weeks and calculate rewards.
        IVotingEscrow.LockedBalance memory lockedBalance = userLockedBalances[account];
        while (weekCursor < currentWeek) {
            uint256 veChessBalance = _balanceAtTimestamp(lockedBalance, weekCursor);
            if (veChessBalance == 0) {
                break;
            }
            // A positive veChessBalance guarentees that veSupply of that week is also positive
            rewards = rewards.add(
                veChessBalance.mul(rewardsPerWeek[weekCursor]) / veSupplyPerWeek[weekCursor]
            );
            weekCursor += 1 weeks;
        }

        userWeekCursors[account] = currentWeek;
        userLastBalances[account] = _balanceAtTimestamp(lockedBalance, currentWeek);
        return rewards;
    }

    /// @notice Recalculate `nextWeekSupply` from scratch. This function eliminates accumulated
    ///         rounding errors in `nextWeekSupply`, which is incrementally updated in
    ///         `syncWithVotingEscrow()` and `checkpoint()`. It is almost never required.
    /// @dev See related test cases for details about the rounding errors.
    function calibrateSupply() external {
        uint256 nextWeek = _endOfWeek(checkpointTimestamp);
        nextWeekSupply = _totalSupplyAtTimestamp(nextWeek);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../utils/CoreUtility.sol";
import "../utils/SafeDecimalMath.sol";

import "../governance/VotingEscrowCheckpoint.sol";
import "../interfaces/IControllerBallotV2.sol";
import "../interfaces/IVotingEscrow.sol";

contract ControllerBallotV2 is
    IControllerBallotV2,
    IVotingEscrowCallback,
    Ownable,
    CoreUtility,
    VotingEscrowCheckpoint
{
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;

    event PoolAdded(address pool);
    event PoolToggled(address indexed pool, bool isDisabled);
    event Voted(
        address indexed account,
        uint256 oldAmount,
        uint256 oldUnlockTime,
        uint256[] oldWeights,
        uint256 amount,
        uint256 unlockTime,
        uint256[] weights
    );

    IVotingEscrow public immutable votingEscrow;

    address[65535] private _pools;
    uint256 public poolSize;
    uint256 public disabledPoolSize;

    /// @notice Locked balance of an account, which is synchronized with `VotingEscrow` when
    ///         `syncWithVotingEscrow()` is called
    mapping(address => IVotingEscrow.LockedBalance) public userLockedBalances;

    /// @notice Mapping of account => pool => fraction of the user's veCHESS voted to the pool
    mapping(address => mapping(address => uint256)) public userWeights;

    /// @notice Mapping of pool => unlockTime => CHESS amount voted to the pool that will be
    ///         unlocked at unlockTime
    mapping(address => mapping(uint256 => uint256)) public poolScheduledUnlock;

    mapping(address => mapping(uint256 => uint256)) public poolVeSupplyPerWeek;
    mapping(address => uint256) public poolTotalLocked;
    mapping(address => uint256) public poolNextWeekSupply;
    uint256 public checkpointWeek;

    /// @notice Mapping of pool => status of the pool
    mapping(uint256 => bool) public disabledPools;

    constructor(address votingEscrow_)
        public
        VotingEscrowCheckpoint(IVotingEscrow(votingEscrow_).maxTime())
    {
        votingEscrow = IVotingEscrow(votingEscrow_);
        checkpointWeek = _endOfWeek(block.timestamp) - 1 weeks;
    }

    function getPools() external view returns (address[] memory) {
        uint256 size = poolSize;
        address[] memory pools = new address[](size);
        for (uint256 i = 0; i < size; i++) {
            pools[i] = _pools[i];
        }
        return pools;
    }

    function addPool(address newPool) external onlyOwner {
        uint256 size = poolSize;
        _pools[size] = newPool;
        poolSize = size + 1;
        emit PoolAdded(newPool);
    }

    function togglePool(uint256 index) external onlyOwner {
        require(index < poolSize, "Invalid index");
        if (disabledPools[index]) {
            disabledPools[index] = false;
            disabledPoolSize--;
        } else {
            disabledPools[index] = true;
            disabledPoolSize++;
        }
        emit PoolToggled(_pools[index], disabledPools[index]);
    }

    function balanceOf(address account) external view returns (uint256) {
        return balanceOfAtTimestamp(account, block.timestamp);
    }

    function balanceOfAtTimestamp(address account, uint256 timestamp)
        public
        view
        returns (uint256)
    {
        require(timestamp >= block.timestamp, "Must be current or future time");
        IVotingEscrow.LockedBalance memory locked = userLockedBalances[account];
        if (timestamp >= locked.unlockTime) {
            return 0;
        }
        return locked.amount.mul(locked.unlockTime - timestamp) / _maxTime;
    }

    function totalSupplyAtWeek(uint256 week) public view override returns (uint256) {
        uint256 size = poolSize;
        uint256 total = 0;
        for (uint256 i = 0; i < size; i++) {
            if (!disabledPools[i]) {
                total = total.add(sumAtWeek(_pools[i], week));
            }
        }
        return total;
    }

    function sumAtWeek(address pool, uint256 week) public view override returns (uint256) {
        return
            week <= checkpointWeek
                ? poolVeSupplyPerWeek[pool][week]
                : _veTotalSupplyAtWeek(
                    week,
                    poolScheduledUnlock[pool],
                    checkpointWeek,
                    poolNextWeekSupply[pool],
                    poolTotalLocked[pool]
                );
    }

    function count(uint256 week)
        external
        view
        override
        returns (uint256[] memory sums, address[] memory pools)
    {
        uint256 poolSize_ = poolSize;
        uint256 size = poolSize_ - disabledPoolSize;
        pools = new address[](size);
        uint256 j = 0;
        for (uint256 i = 0; i < poolSize_ && j < size; i++) {
            address pool = _pools[i];
            if (!disabledPools[i]) pools[j++] = pool;
        }

        sums = new uint256[](size);
        for (uint256 i = 0; i < size; i++) {
            uint256 sum = sumAtWeek(pools[i], week);
            sums[i] = sum;
        }
    }

    function cast(uint256[] memory weights) external override {
        uint256 size = poolSize;
        require(weights.length == size, "Invalid number of weights");
        uint256 totalWeight;
        for (uint256 i = 0; i < size; i++) {
            totalWeight = totalWeight.add(weights[i]);
        }
        require(totalWeight == 1e18, "Invalid weights");

        uint256[] memory oldWeights = new uint256[](size);
        for (uint256 i = 0; i < size; i++) {
            oldWeights[i] = userWeights[msg.sender][_pools[i]];
        }

        IVotingEscrow.LockedBalance memory oldLockedBalance = userLockedBalances[msg.sender];
        IVotingEscrow.LockedBalance memory lockedBalance =
            votingEscrow.getLockedBalance(msg.sender);
        require(
            lockedBalance.amount > 0 && lockedBalance.unlockTime > block.timestamp,
            "No veCHESS"
        );

        _updateVoteStatus(msg.sender, size, oldWeights, weights, oldLockedBalance, lockedBalance);
    }

    function syncWithVotingEscrow(address account) external override {
        IVotingEscrow.LockedBalance memory oldLockedBalance = userLockedBalances[account];
        if (oldLockedBalance.amount == 0) {
            return; // The account did not vote before
        }
        IVotingEscrow.LockedBalance memory lockedBalance = votingEscrow.getLockedBalance(account);
        if (lockedBalance.unlockTime <= block.timestamp) {
            return;
        }

        uint256 size = poolSize;
        uint256[] memory weights = new uint256[](size);
        for (uint256 i = 0; i < size; i++) {
            weights[i] = userWeights[account][_pools[i]];
        }

        _updateVoteStatus(account, size, weights, weights, oldLockedBalance, lockedBalance);
    }

    function _updateVoteStatus(
        address account,
        uint256 size,
        uint256[] memory oldWeights,
        uint256[] memory weights,
        IVotingEscrow.LockedBalance memory oldLockedBalance,
        IVotingEscrow.LockedBalance memory lockedBalance
    ) private {
        uint256 oldCheckpointWeek = checkpointWeek;
        uint256 newCheckpointWeek;
        for (uint256 i = 0; i < size; i++) {
            address pool = _pools[i];
            uint256 newNextWeekSupply;
            uint256 newTotalLocked;
            (newCheckpointWeek, newNextWeekSupply, newTotalLocked) = _veCheckpoint(
                poolScheduledUnlock[pool],
                oldCheckpointWeek,
                poolNextWeekSupply[pool],
                poolTotalLocked[pool],
                poolVeSupplyPerWeek[pool]
            );
            (poolNextWeekSupply[pool], poolTotalLocked[pool]) = _veUpdateLock(
                newNextWeekSupply,
                newTotalLocked,
                oldLockedBalance.amount.multiplyDecimal(oldWeights[i]),
                oldLockedBalance.unlockTime,
                lockedBalance.amount.multiplyDecimal(weights[i]),
                lockedBalance.unlockTime,
                poolScheduledUnlock[pool]
            );
            userWeights[account][pool] = weights[i];
        }
        checkpointWeek = newCheckpointWeek;
        userLockedBalances[account] = lockedBalance;
        emit Voted(
            account,
            oldLockedBalance.amount,
            oldLockedBalance.unlockTime,
            oldWeights,
            lockedBalance.amount,
            lockedBalance.unlockTime,
            weights
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

interface IFundForPrimaryMarketV3 {
    function primaryMarketMint(
        uint256 tranche,
        address account,
        uint256 amount,
        uint256 version
    ) external;

    function primaryMarketBurn(
        uint256 tranche,
        address account,
        uint256 amount,
        uint256 version
    ) external;

    function primaryMarketTransferUnderlying(
        address recipient,
        uint256 amount,
        uint256 fee
    ) external;

    function primaryMarketAddDebt(uint256 amount, uint256 fee) external;

    function primaryMarketPayDebt(uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

interface IFundForStrategy {
    function transferToStrategy(uint256 amount) external;

    function transferFromStrategy(uint256 amount) external;

    function reportProfit(uint256 profit, uint256 performanceFee) external;

    function reportLoss(uint256 loss) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IShareV2 is IERC20 {
    function fundEmitTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) external;

    function fundEmitApproval(
        address owner,
        address spender,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

interface IAprOracle {
    function capture() external returns (uint256 dailyRate);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

interface IBallot {
    struct Voter {
        uint256 amount;
        uint256 unlockTime;
        uint256 weight;
    }

    function count(uint256 timestamp) external view returns (uint256);

    function syncWithVotingEscrow(address account) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "../interfaces/ITrancheIndexV2.sol";

abstract contract FundRolesV2 is ITrancheIndexV2 {
    event PrimaryMarketUpdateProposed(
        address indexed newPrimaryMarket,
        uint256 minTimestamp,
        uint256 maxTimestamp
    );
    event PrimaryMarketUpdated(
        address indexed previousPrimaryMarket,
        address indexed newPrimaryMarket
    );
    event StrategyUpdateProposed(
        address indexed newStrategy,
        uint256 minTimestamp,
        uint256 maxTimestamp
    );
    event StrategyUpdated(address indexed previousStrategy, address indexed newStrategy);

    uint256 private constant ROLE_UPDATE_MIN_DELAY = 3 days;
    uint256 private constant ROLE_UPDATE_MAX_DELAY = 15 days;

    address internal immutable _tokenQ;
    address internal immutable _tokenB;
    address internal immutable _tokenR;

    address internal _primaryMarket;
    address internal _proposedPrimaryMarket;
    uint256 internal _proposedPrimaryMarketTimestamp;

    address internal _strategy;
    address internal _proposedStrategy;
    uint256 internal _proposedStrategyTimestamp;

    constructor(
        address tokenQ_,
        address tokenB_,
        address tokenR_,
        address primaryMarket_,
        address strategy_
    ) public {
        _tokenQ = tokenQ_;
        _tokenB = tokenB_;
        _tokenR = tokenR_;
        _primaryMarket = primaryMarket_;
        _strategy = strategy_;
        emit PrimaryMarketUpdated(address(0), primaryMarket_);
        emit StrategyUpdated(address(0), strategy_);
    }

    function _getTranche(address share) internal view returns (uint256) {
        if (share == _tokenQ) {
            return TRANCHE_Q;
        } else if (share == _tokenB) {
            return TRANCHE_B;
        } else if (share == _tokenR) {
            return TRANCHE_R;
        } else {
            revert("Only share");
        }
    }

    function _getShare(uint256 tranche) internal view returns (address) {
        if (tranche == TRANCHE_Q) {
            return _tokenQ;
        } else if (tranche == TRANCHE_B) {
            return _tokenB;
        } else if (tranche == TRANCHE_R) {
            return _tokenR;
        } else {
            revert("Invalid tranche");
        }
    }

    modifier onlyPrimaryMarket() {
        require(msg.sender == _primaryMarket, "Only primary market");
        _;
    }

    function _proposePrimaryMarketUpdate(address newPrimaryMarket) internal {
        require(newPrimaryMarket != _primaryMarket);
        _proposedPrimaryMarket = newPrimaryMarket;
        _proposedPrimaryMarketTimestamp = block.timestamp;
        emit PrimaryMarketUpdateProposed(
            newPrimaryMarket,
            block.timestamp + ROLE_UPDATE_MIN_DELAY,
            block.timestamp + ROLE_UPDATE_MAX_DELAY
        );
    }

    function _applyPrimaryMarketUpdate(address newPrimaryMarket) internal {
        require(_proposedPrimaryMarket == newPrimaryMarket, "Proposed address mismatch");
        require(
            block.timestamp >= _proposedPrimaryMarketTimestamp + ROLE_UPDATE_MIN_DELAY &&
                block.timestamp < _proposedPrimaryMarketTimestamp + ROLE_UPDATE_MAX_DELAY,
            "Not ready to update"
        );
        emit PrimaryMarketUpdated(_primaryMarket, newPrimaryMarket);
        _primaryMarket = newPrimaryMarket;
        _proposedPrimaryMarket = address(0);
        _proposedPrimaryMarketTimestamp = 0;
    }

    modifier onlyStrategy() {
        require(msg.sender == _strategy, "Only strategy");
        _;
    }

    function _proposeStrategyUpdate(address newStrategy) internal {
        require(newStrategy != _strategy);
        _proposedStrategy = newStrategy;
        _proposedStrategyTimestamp = block.timestamp;
        emit StrategyUpdateProposed(
            newStrategy,
            block.timestamp + ROLE_UPDATE_MIN_DELAY,
            block.timestamp + ROLE_UPDATE_MAX_DELAY
        );
    }

    function _applyStrategyUpdate(address newStrategy) internal {
        require(_proposedStrategy == newStrategy, "Proposed address mismatch");
        require(
            block.timestamp >= _proposedStrategyTimestamp + ROLE_UPDATE_MIN_DELAY &&
                block.timestamp < _proposedStrategyTimestamp + ROLE_UPDATE_MAX_DELAY,
            "Not ready to update"
        );
        emit StrategyUpdated(_strategy, newStrategy);
        _strategy = newStrategy;
        _proposedStrategy = address(0);
        _proposedStrategyTimestamp = 0;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "../interfaces/IFundV3.sol";
import "../interfaces/IStableSwap.sol";

interface IPrimaryMarketRouter is IStableSwapCore {
    function create(
        address recipient,
        uint256 underlying,
        uint256 minOutQ,
        uint256 version
    ) external payable returns (uint256 outQ);

    function createAndStake(
        uint256 underlying,
        uint256 minOutQ,
        address staking,
        uint256 version
    ) external payable;

    function createSplitAndStake(
        uint256 underlying,
        uint256 minOutQ,
        address router,
        address quoteAddress,
        uint256 minLpOut,
        address staking,
        uint256 version
    ) external payable;

    function splitAndStake(
        uint256 inQ,
        address router,
        address quoteAddress,
        uint256 minLpOut,
        address staking,
        uint256 version
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../../utils/SafeDecimalMath.sol";
import "../../interfaces/IFundV3.sol";
import "../../interfaces/IFundForStrategyV2.sol";
import "../../interfaces/IWrappedERC20.sol";
import "../../interfaces/ITrancheIndexV2.sol";

import "./IWithdrawalManager.sol";
import "./NodeOperatorRegistry.sol";

interface IDepositContract {
    function deposit(
        bytes memory pubkey,
        bytes memory withdrawal_credentials,
        bytes memory signature,
        bytes32 deposit_data_root
    ) external payable;
}

/// @notice Strategy for delegating ETH to ETH2 validators and earn rewards.
contract EthStakingStrategy is Ownable, ITrancheIndexV2 {
    using Math for uint256;
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;
    using SafeERC20 for IWrappedERC20;

    event ReporterUpdated(address reporter);
    event SafeStakingUpdated(address safeStaking);
    event Received(address from, uint256 amount);
    event FeeRateUpdated(uint256 newTotalFeeRate, uint256 newOperatorFeeRate);
    event OperatorWeightUpdated(uint256 indexed id, uint256 newWeight);
    event BalanceReported(
        uint256 indexed epoch,
        uint256 indexed id,
        uint256 beaconBalance,
        uint256 validatorCount,
        uint256 executionLayerRewards
    );

    uint256 private constant MAX_TOTAL_FEE_RATE = 0.5e18;
    uint256 private constant MAX_OPERATOR_WEIGHT = 1e18;
    uint256 private constant DEPOSIT_AMOUNT = 32 ether;
    uint256 private constant MAX_AUTO_DEPOSIT_COUNT = 100;

    /// @dev Little endian representation of the deposit amount in Gwei.
    bytes32 private constant LITTLE_ENDIAN_DEPOSIT_AMOUNT =
        bytes32(
            uint256(
                ((((32e9 >> (8 * 0)) & 0xFF) << (8 * 7)) |
                    (((32e9 >> (8 * 1)) & 0xFF) << (8 * 6)) |
                    (((32e9 >> (8 * 2)) & 0xFF) << (8 * 5)) |
                    (((32e9 >> (8 * 3)) & 0xFF) << (8 * 4)) |
                    (((32e9 >> (8 * 4)) & 0xFF) << (8 * 3)) |
                    (((32e9 >> (8 * 5)) & 0xFF) << (8 * 2)) |
                    (((32e9 >> (8 * 6)) & 0xFF) << (8 * 1)) |
                    (((32e9 >> (8 * 7)) & 0xFF) << (8 * 0))) << 192
            )
        );

    address public immutable fund;
    address private immutable _tokenUnderlying;
    IDepositContract public immutable depositContract;
    NodeOperatorRegistry public immutable registry;

    /// @notice Fraction of profit that goes to the fund's fee collector and node operators.
    uint256 public totalFeeRate;

    /// @notice Fraction of profit that directly goes to node operators.
    uint256 public operatorFeeRate;

    /// @notice Mapping of node operator ID => amount of underlying lost since the last peak.
    ///         Performance fee is charged only when this value is zero.
    mapping(uint256 => uint256) public currentDrawdowns;

    mapping(uint256 => uint256) public operatorWeights;

    /// @notice Reporter that reports validator balances on the Beacon Chain
    address public reporter;

    uint256 public totalValidatorCount;
    uint256 public operatorCursor;
    mapping(uint256 => uint256) public lastBeaconBalances;
    mapping(uint256 => uint256) public lastValidatorCounts;

    address public safeStaking;

    constructor(
        address fund_,
        address depositContract_,
        address registry_,
        uint256 totalFeeRate_,
        uint256 operatorFeeRate_
    ) public {
        fund = fund_;
        _tokenUnderlying = IFundV3(fund_).tokenUnderlying();
        depositContract = IDepositContract(depositContract_);
        registry = NodeOperatorRegistry(registry_);
        _updateFeeRate(totalFeeRate_, operatorFeeRate_);
    }

    function initialize(address payable oldStrategy) external onlyOwner {
        require(totalValidatorCount == 0);

        totalValidatorCount = EthStakingStrategy(oldStrategy).totalValidatorCount();
        operatorCursor = EthStakingStrategy(oldStrategy).operatorCursor();
        uint256 operatorCount = registry.operatorCount();
        for (uint256 i = 0; i < operatorCount; i++) {
            lastBeaconBalances[i] = EthStakingStrategy(oldStrategy).lastBeaconBalances(i);
            lastValidatorCounts[i] = EthStakingStrategy(oldStrategy).lastValidatorCounts(i);
            currentDrawdowns[i] = EthStakingStrategy(oldStrategy).currentDrawdowns(i);
        }
    }

    receive() external payable {}

    modifier onlyReporter() {
        require(reporter == msg.sender, "Only reporter");
        _;
    }

    function updateReporter(address reporter_) public onlyOwner {
        reporter = reporter_;
        emit ReporterUpdated(reporter);
    }

    function updateSafeStaking(address safeStaking_) public onlyOwner {
        safeStaking = safeStaking_;
        emit SafeStakingUpdated(safeStaking_);
    }

    /// @notice Report profit to the fund for an individual node operator.
    function report(
        uint256 epoch,
        uint256 id,
        uint256 beaconBalance,
        uint256 validatorCount
    ) external onlyReporter {
        (uint256 profit, uint256 loss, uint256 totalFee, uint256 operatorFee) =
            _report(epoch, id, beaconBalance, validatorCount);
        if (profit != 0) {
            uint256 feeQ = IFundForStrategyV2(fund).reportProfit(profit, totalFee, operatorFee);
            IFundV3(fund).trancheTransfer(
                TRANCHE_Q,
                registry.getRewardAddress(id),
                feeQ,
                IFundV3(fund).getRebalanceSize()
            );
        }
        if (loss != 0) {
            IFundForStrategyV2(fund).reportLoss(loss);
        }
    }

    /// @notice Report profit to the fund for multiple node operators.
    function batchReport(
        uint256 epoch,
        uint256[] memory ids,
        uint256[] memory beaconBalances,
        uint256[] memory validatorCounts
    ) external onlyReporter {
        uint256 size = ids.length;
        require(
            beaconBalances.length == size && validatorCounts.length == size,
            "Unaligned params"
        );
        uint256 sumProfit;
        uint256 sumLoss;
        uint256 sumTotalFee;
        uint256 sumOperatorFee;
        uint256[] memory operatorFees = new uint256[](size);
        for (uint256 i = 0; i < size; i++) {
            require(i == 0 || ids[i] > ids[i - 1], "IDs out of order");
            (uint256 profit, uint256 loss, uint256 totalFee, uint256 operatorFee) =
                _report(epoch, ids[i], beaconBalances[i], validatorCounts[i]);
            sumProfit = sumProfit.add(profit);
            sumLoss = sumLoss.add(loss);
            sumTotalFee = sumTotalFee.add(totalFee);
            sumOperatorFee = sumOperatorFee.add(operatorFee);
            operatorFees[i] = operatorFee;
        }
        if (sumLoss != 0) {
            IFundForStrategyV2(fund).reportLoss(sumLoss);
        }
        if (sumProfit != 0) {
            uint256 totalFeeQ =
                IFundForStrategyV2(fund).reportProfit(sumProfit, sumTotalFee, sumOperatorFee);
            if (sumOperatorFee != 0) {
                uint256 version = IFundV3(fund).getRebalanceSize();
                for (uint256 i = 0; i < size; i++) {
                    if (operatorFees[i] == 0) {
                        continue;
                    }
                    address rewardAddress = registry.getRewardAddress(ids[i]);
                    IFundV3(fund).trancheTransfer(
                        TRANCHE_Q,
                        rewardAddress,
                        totalFeeQ.mul(operatorFees[i]) / sumOperatorFee,
                        version
                    );
                }
            }
        }
    }

    function _report(
        uint256 epoch,
        uint256 id,
        uint256 beaconBalance,
        uint256 validatorCount
    )
        private
        returns (
            uint256 profit,
            uint256 loss,
            uint256 totalFee,
            uint256 operatorFee
        )
    {
        address withdrawalAddress = registry.getWithdrawalAddress(id);
        require(withdrawalAddress != address(0), "Invalid operator id");
        uint256 lastValidatorCount = lastValidatorCounts[id];
        require(validatorCount <= registry.getKeyStat(id).usedCount, "More than deposited");
        require(validatorCount >= lastValidatorCount, "Less than previous");

        uint256 oldBalance =
            (validatorCount - lastValidatorCount).mul(DEPOSIT_AMOUNT).add(lastBeaconBalances[id]);
        lastBeaconBalances[id] = beaconBalance;
        lastValidatorCounts[id] = validatorCount;

        // Get the exectuion layer rewards
        uint256 executionLayerRewards = withdrawalAddress.balance;
        if (executionLayerRewards != 0) {
            IWithdrawalManager(withdrawalAddress).transferToStrategy(executionLayerRewards);
        }
        emit BalanceReported(epoch, id, beaconBalance, validatorCount, executionLayerRewards);
        uint256 newBalance = beaconBalance.add(executionLayerRewards);

        // Update drawdown and calculate fees
        uint256 oldDrawdown = currentDrawdowns[id];
        if (newBalance >= oldBalance) {
            profit = newBalance - oldBalance;
            if (profit <= oldDrawdown) {
                currentDrawdowns[id] = oldDrawdown - profit;
            } else {
                if (oldDrawdown > 0) {
                    currentDrawdowns[id] = 0;
                }
                totalFee = (profit - oldDrawdown).multiplyDecimal(totalFeeRate);
                operatorFee = (profit - oldDrawdown).multiplyDecimal(operatorFeeRate);
            }
        } else {
            loss = oldBalance - newBalance;
            currentDrawdowns[id] = oldDrawdown.add(loss);
        }
    }

    function updateFeeRate(uint256 newTotalFeeRate, uint256 newOperatorFeeRate) external onlyOwner {
        _updateFeeRate(newTotalFeeRate, newOperatorFeeRate);
    }

    function _updateFeeRate(uint256 newTotalFeeRate, uint256 newOperatorFeeRate) private {
        require(newTotalFeeRate <= MAX_TOTAL_FEE_RATE && newTotalFeeRate >= newOperatorFeeRate);
        totalFeeRate = newTotalFeeRate;
        operatorFeeRate = newOperatorFeeRate;
        emit FeeRateUpdated(newTotalFeeRate, newOperatorFeeRate);
    }

    function updateOperatorWeight(uint256 id, uint256 newWeight) external onlyOwner {
        require(newWeight <= MAX_OPERATOR_WEIGHT, "Max weight exceeded");
        require(id < registry.operatorCount(), "Invalid operator ID");
        operatorWeights[id] = newWeight;
        emit OperatorWeightUpdated(id, newWeight);
    }

    /// @notice Select node operators for the given number of new validators. Sum of the returned
    ///         key counts may be less than the parameter.
    /// @param total Number of new validators
    /// @return keyCounts Number of pubkeys to be used from each node operator
    /// @return cursor New cursor of the selection algorithm
    function selectOperators(uint256 total)
        public
        view
        returns (uint256[] memory keyCounts, uint256 cursor)
    {
        uint256 operatorCount = registry.operatorCount();
        keyCounts = new uint256[](operatorCount);
        uint256[] memory limits = new uint256[](operatorCount);
        uint256 totalWeights;
        for (uint256 i = 0; i < operatorCount; i++) {
            uint256 w = operatorWeights[i];
            limits[i] = w;
            totalWeights = totalWeights + w;
        }
        if (totalWeights == 0) {
            return (keyCounts, operatorCursor);
        }
        uint256 newValidatorCount = totalValidatorCount + total;
        for (uint256 i = 0; i < operatorCount; i++) {
            // Round up the limit
            uint256 totalLimit = (limits[i] * newValidatorCount + totalWeights - 1) / totalWeights;
            NodeOperatorRegistry.KeyStat memory stat = registry.getKeyStat(i);
            totalLimit = totalLimit.min(stat.totalCount).min(stat.depositLimit).min(
                stat.verifiedCount
            );
            limits[i] = totalLimit <= stat.usedCount ? 0 : totalLimit - stat.usedCount;
        }

        cursor = operatorCursor;
        uint256 failure = 0;
        while (total > 0 && failure < operatorCount) {
            if (limits[cursor] == 0) {
                failure++;
            } else {
                keyCounts[cursor]++;
                limits[cursor]--;
                total--;
                failure = 0;
            }
            cursor = (cursor + 1) % operatorCount;
        }
    }

    /// @notice Deposit underlying tokens from the fund to the ETH2 deposit contract.
    /// @param amount Amount of underlying transfered from the fund, including cross-chain relay fee
    function deposit(uint256 amount) public {
        require(msg.sender == safeStaking, "Only safe staking");

        require(amount % DEPOSIT_AMOUNT == 0);
        if (address(this).balance < amount) {
            IFundForStrategyV2(fund).transferToStrategy(amount - address(this).balance);
            _unwrap(IERC20(_tokenUnderlying).balanceOf(address(this)));
        }

        uint256[] memory keyCounts;
        (keyCounts, operatorCursor) = selectOperators(amount / DEPOSIT_AMOUNT);
        uint256 total;
        for (uint256 i = 0; i < keyCounts.length; i++) {
            uint256 keyCount = keyCounts[i];
            if (keyCount == 0) {
                continue;
            }
            total += keyCount;
            (NodeOperatorRegistry.Key[] memory vs, bytes32 withdrawalCredential) =
                registry.useKeys(i, keyCount);
            for (uint256 j = 0; j < keyCount; j++) {
                _deposit(vs[j], withdrawalCredential);
            }
        }
        totalValidatorCount = totalValidatorCount + total;
    }

    /// @dev Nothing to do on primary market creation.
    function onPrimaryMarketCreate() external {}

    /// @notice Transfer all underlying tokens, both wrapped and unwrapped, to the fund.
    function transferToFund() external onlyOwner {
        uint256 unwrapped = address(this).balance;
        if (unwrapped > 0) {
            _wrap(unwrapped);
        }
        uint256 amount = IWrappedERC20(_tokenUnderlying).balanceOf(address(this));
        IWrappedERC20(_tokenUnderlying).safeApprove(fund, amount);
        IFundForStrategyV2(fund).transferFromStrategy(amount);
    }

    /// @dev Convert ETH into WETH
    function _wrap(uint256 amount) private {
        IWrappedERC20(_tokenUnderlying).deposit{value: amount}();
    }

    /// @dev Convert WETH into ETH
    function _unwrap(uint256 amount) private {
        IWrappedERC20(_tokenUnderlying).withdraw(amount);
    }

    function _deposit(NodeOperatorRegistry.Key memory key, bytes32 withdrawalCredential) private {
        bytes memory pubkey = abi.encodePacked(key.pubkey0, bytes16(key.pubkey1));
        bytes memory signature = abi.encode(key.signature0, key.signature1, key.signature2);
        // Lower 16 bytes of pubkey1 are cleared by the registry
        bytes32 pubkeyRoot = sha256(abi.encode(key.pubkey0, key.pubkey1));
        bytes32 signatureRoot =
            sha256(
                abi.encodePacked(
                    sha256(abi.encode(key.signature0, key.signature1)),
                    sha256(abi.encode(key.signature2, bytes32(0)))
                )
            );
        bytes32 depositDataRoot =
            sha256(
                abi.encodePacked(
                    sha256(abi.encodePacked(pubkeyRoot, withdrawalCredential)),
                    sha256(abi.encodePacked(LITTLE_ENDIAN_DEPOSIT_AMOUNT, signatureRoot))
                )
            );
        depositContract.deposit{value: DEPOSIT_AMOUNT}(
            pubkey,
            abi.encode(withdrawalCredential),
            signature,
            depositDataRoot
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

interface IFundForStrategyV2 {
    function transferToStrategy(uint256 amount) external;

    function transferFromStrategy(uint256 amount) external;

    function reportProfit(
        uint256 profit,
        uint256 totalFee,
        uint256 strategyFee
    ) external returns (uint256 outQ);

    function reportLoss(uint256 loss) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

interface IWithdrawalManager {
    function getWithdrawalCredential() external view returns (bytes32);

    function transferToStrategy(uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./IWithdrawalManager.sol";
import "./WithdrawalManagerFactory.sol";

interface IEthStakingStrategy {
    function safeStaking() external view returns (address);

    function registry() external view returns (address);

    function depositContract() external view returns (address);

    function deposit(uint256 amount) external;
}

contract NodeOperatorRegistry is Ownable {
    event OperatorAdded(uint256 indexed id, string name, address operatorOwner);
    event OperatorOwnerUpdated(uint256 indexed id, address newOperatorOwner);
    event RewardAddressUpdated(uint256 indexed id, address newRewardAddress);
    event VerifiedCountUpdated(uint256 indexed id, uint256 newVerifiedCount);
    event DepositLimitUpdated(uint256 indexed id, uint256 newDepositLimit);
    event KeyAdded(uint256 indexed id, bytes pubkey, uint256 index);
    event KeyUsed(uint256 indexed id, uint256 count);
    event KeyTruncated(uint256 indexed id, uint256 newTotalCount);
    event StrategyUpdated(address newStrategy);

    /// @notice Statistics of validator pubkeys from a node operator.
    /// @param totalCount Total number of validator pubkeys uploaded to this contract
    /// @param usedCount Number of validator pubkeys that are already used
    /// @param verifiedCount Number of validator pubkeys that are verified by the contract owner
    /// @param depositLimit Maximum number of usable validator pubkeys, set by the node operator
    struct KeyStat {
        uint64 totalCount;
        uint64 usedCount;
        uint64 verifiedCount;
        uint64 depositLimit;
    }

    /// @notice Node operator parameters and internal state
    /// @param operatorOwner Admin address of the node operator
    /// @param name Human-readable name
    /// @param withdrawalAddress Address receiving withdrawals and execution layer rewards
    /// @param rewardAddress Address receiving performance rewards
    struct Operator {
        address operatorOwner;
        string name;
        address rewardAddress;
        address withdrawalAddress;
        KeyStat keyStat;
    }

    struct Key {
        bytes32 pubkey0;
        bytes32 pubkey1; // Only the higher 16 bytes of the second slot are used
        bytes32 signature0;
        bytes32 signature1;
        bytes32 signature2;
    }

    uint256 private constant PUBKEY_LENGTH = 48;
    uint256 private constant SIGNATURE_LENGTH = 96;

    WithdrawalManagerFactory public immutable factory;

    address public strategy;

    /// @notice Number of node operators.
    uint256 public operatorCount;

    /// @dev Mapping of node operator ID => node operator.
    mapping(uint256 => Operator) private _operators;

    /// @dev Mapping of node operator ID => index => validator pubkey and deposit signature.
    mapping(uint256 => mapping(uint256 => Key)) private _keys;

    uint256 public registryVersion;

    constructor(address strategy_, address withdrawalManagerFactory_) public {
        _updateStrategy(strategy_);
        factory = WithdrawalManagerFactory(withdrawalManagerFactory_);
    }

    function initialize(address oldRegistry) external onlyOwner {
        require(operatorCount == 0);

        operatorCount = NodeOperatorRegistry(oldRegistry).operatorCount();
        for (uint256 i = 0; i < operatorCount; i++) {
            Operator memory operator = NodeOperatorRegistry(oldRegistry).getOperator(i);
            operator.operatorOwner = msg.sender;
            uint64 usedCount = operator.keyStat.usedCount;
            operator.keyStat.totalCount = usedCount;
            operator.keyStat.verifiedCount = usedCount;
            _operators[i] = operator;
            emit OperatorAdded(i, operator.name, msg.sender);
            if (operator.rewardAddress != msg.sender) {
                emit RewardAddressUpdated(i, operator.rewardAddress);
            }
            emit DepositLimitUpdated(i, operator.keyStat.depositLimit);

            Key[] memory keys = NodeOperatorRegistry(oldRegistry).getKeys(i, 0, usedCount);
            for (uint256 j = 0; j < usedCount; j++) {
                bytes32 pk0 = keys[j].pubkey0;
                bytes32 pk1 = keys[j].pubkey1;
                _keys[i][j].pubkey0 = pk0;
                _keys[i][j].pubkey1 = pk1;
                emit KeyAdded(i, abi.encodePacked(pk0, bytes16(pk1)), j);
            }
            emit VerifiedCountUpdated(i, usedCount);
            emit KeyUsed(i, usedCount);
        }
    }

    function getOperator(uint256 id) external view returns (Operator memory) {
        return _operators[id];
    }

    function getOperators() external view returns (Operator[] memory operators) {
        uint256 count = operatorCount;
        operators = new Operator[](count);
        for (uint256 i = 0; i < count; i++) {
            operators[i] = _operators[i];
        }
    }

    function getRewardAddress(uint256 id) external view returns (address) {
        return _operators[id].rewardAddress;
    }

    function getRewardAddresses() external view returns (address[] memory addresses) {
        uint256 count = operatorCount;
        addresses = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            addresses[i] = _operators[i].rewardAddress;
        }
    }

    function getWithdrawalAddress(uint256 id) external view returns (address) {
        return _operators[id].withdrawalAddress;
    }

    function getWithdrawalAddresses() external view returns (address[] memory addresses) {
        uint256 count = operatorCount;
        addresses = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            addresses[i] = _operators[i].withdrawalAddress;
        }
    }

    function getWithdrawalCredential(uint256 id) external view returns (bytes32) {
        return IWithdrawalManager(_operators[id].withdrawalAddress).getWithdrawalCredential();
    }

    function getKeyStat(uint256 id) external view returns (KeyStat memory) {
        return _operators[id].keyStat;
    }

    function getKeyStats() external view returns (KeyStat[] memory keyStats) {
        uint256 count = operatorCount;
        keyStats = new KeyStat[](count);
        for (uint256 i = 0; i < count; i++) {
            keyStats[i] = _operators[i].keyStat;
        }
    }

    function getKey(uint256 id, uint256 index) external view returns (Key memory) {
        return _keys[id][index];
    }

    function getKeys(
        uint256 id,
        uint256 start,
        uint256 count
    ) external view returns (Key[] memory keys) {
        keys = new Key[](count);
        mapping(uint256 => Key) storage operatorKeys = _keys[id];
        for (uint256 i = 0; i < count; i++) {
            keys[i] = operatorKeys[start + i];
        }
    }

    function getPubkeys(
        uint256 id,
        uint256 start,
        uint256 count
    ) external view returns (bytes[] memory pubkeys) {
        pubkeys = new bytes[](count);
        mapping(uint256 => Key) storage operatorKeys = _keys[id];
        for (uint256 i = 0; i < count; i++) {
            Key storage key = operatorKeys[start + i];
            pubkeys[i] = abi.encodePacked(key.pubkey0, bytes16(key.pubkey1));
        }
    }

    function getSignatures(
        uint256 id,
        uint256 start,
        uint256 count
    ) external view returns (bytes[] memory signatures) {
        signatures = new bytes[](count);
        mapping(uint256 => Key) storage operatorKeys = _keys[id];
        for (uint256 i = 0; i < count; i++) {
            Key storage key = operatorKeys[start + i];
            signatures[i] = abi.encode(key.signature0, key.signature1, key.signature2);
        }
    }

    function addKeys(
        uint256 id,
        bytes calldata pubkeys,
        bytes calldata signatures
    ) external onlyOperatorOwner(id) {
        uint256 count = pubkeys.length / PUBKEY_LENGTH;
        require(
            pubkeys.length == count * PUBKEY_LENGTH &&
                signatures.length == count * SIGNATURE_LENGTH,
            "Invalid param length"
        );
        mapping(uint256 => Key) storage operatorKeys = _keys[id];
        Operator storage operator = _operators[id];
        KeyStat memory stat = operator.keyStat;
        for (uint256 i = 0; i < count; ++i) {
            Key memory key;
            key.pubkey0 = abi.decode(pubkeys[i * PUBKEY_LENGTH:i * PUBKEY_LENGTH + 32], (bytes32));
            key.pubkey1 = abi.decode(
                pubkeys[i * PUBKEY_LENGTH + 16:i * PUBKEY_LENGTH + 48],
                (bytes32)
            );
            key.pubkey1 = bytes32(uint256(key.pubkey1) << 128);
            (key.signature0, key.signature1, key.signature2) = abi.decode(
                signatures[i * SIGNATURE_LENGTH:(i + 1) * SIGNATURE_LENGTH],
                (bytes32, bytes32, bytes32)
            );
            require(
                key.pubkey0 | key.pubkey1 != 0 &&
                    key.signature0 | key.signature1 | key.signature2 != 0,
                "Empty pubkey or signature"
            );
            operatorKeys[stat.totalCount + i] = key;
            emit KeyAdded(
                id,
                abi.encodePacked(key.pubkey0, bytes16(key.pubkey1)),
                stat.totalCount + i
            );
        }
        stat.totalCount += uint64(count);
        operator.keyStat = stat;
        registryVersion++;
    }

    function truncateUnusedKeys(uint256 id) external onlyOperatorOwner(id) {
        _truncateUnusedKeys(id);
    }

    function updateRewardAddress(uint256 id, address newRewardAddress)
        external
        onlyOperatorOwner(id)
    {
        _operators[id].rewardAddress = newRewardAddress;
        emit RewardAddressUpdated(id, newRewardAddress);
    }

    function updateDepositLimit(uint256 id, uint64 newDepositLimit) external onlyOperatorOwner(id) {
        _operators[id].keyStat.depositLimit = newDepositLimit;
        registryVersion++;
        emit DepositLimitUpdated(id, newDepositLimit);
    }

    function useKeys(uint256 id, uint256 count)
        external
        onlyStrategy
        returns (Key[] memory keys, bytes32 withdrawalCredential)
    {
        Operator storage operator = _operators[id];
        KeyStat memory stat = operator.keyStat;
        mapping(uint256 => Key) storage operatorKeys = _keys[id];
        uint256 usedCount = stat.usedCount;
        uint256 newUsedCount = usedCount + count;
        require(
            newUsedCount <= stat.totalCount &&
                newUsedCount <= stat.depositLimit &&
                newUsedCount <= stat.verifiedCount,
            "No enough pubkeys"
        );
        keys = new Key[](count);
        for (uint256 i = 0; i < count; i++) {
            Key storage k = operatorKeys[usedCount + i];
            keys[i] = k;
            // Clear storage for gas refund
            k.signature0 = 0;
            k.signature1 = 0;
            k.signature2 = 0;
        }
        stat.usedCount = uint64(newUsedCount);
        operator.keyStat = stat;
        withdrawalCredential = IWithdrawalManager(operator.withdrawalAddress)
            .getWithdrawalCredential();
        registryVersion++;
        emit KeyUsed(id, count);
    }

    function addOperator(string calldata name, address operatorOwner)
        external
        onlyOwner
        returns (uint256 id, address withdrawalAddress)
    {
        id = operatorCount++;
        withdrawalAddress = factory.deployContract(id);
        Operator storage operator = _operators[id];
        operator.operatorOwner = operatorOwner;
        operator.name = name;
        operator.withdrawalAddress = withdrawalAddress;
        operator.rewardAddress = operatorOwner;
        emit OperatorAdded(id, name, operatorOwner);
    }

    function updateOperatorOwner(uint256 id, address newOperatorOwner) external onlyOwner {
        require(id < operatorCount, "Invalid operator ID");
        _operators[id].operatorOwner = newOperatorOwner;
        emit OperatorOwnerUpdated(id, newOperatorOwner);
    }

    function updateVerifiedCount(
        uint256 id,
        uint64 newVerifiedCount,
        uint256 offchainregistryVersion
    ) external {
        require(msg.sender == IEthStakingStrategy(strategy).safeStaking(), "Only safe staking");
        require(registryVersion == offchainregistryVersion, "Registry version changed");

        _operators[id].keyStat.verifiedCount = newVerifiedCount;
        registryVersion++;
        emit VerifiedCountUpdated(id, newVerifiedCount);
    }

    function truncateAllUnusedKeys() external onlyOwner {
        uint256 count = operatorCount;
        for (uint256 i = 0; i < count; i++) {
            _truncateUnusedKeys(i);
        }
    }

    function _truncateUnusedKeys(uint256 id) private {
        Operator storage operator = _operators[id];
        KeyStat memory stat = operator.keyStat;
        stat.totalCount = stat.usedCount;
        stat.verifiedCount = stat.usedCount;
        operator.keyStat = stat;
        emit KeyTruncated(id, stat.totalCount);
    }

    function updateStrategy(address newStrategy) external onlyOwner {
        _updateStrategy(newStrategy);
    }

    function _updateStrategy(address newStrategy) private {
        strategy = newStrategy;
        emit StrategyUpdated(newStrategy);
    }

    modifier onlyOperatorOwner(uint256 id) {
        require(msg.sender == _operators[id].operatorOwner, "Only operator owner");
        _;
    }

    modifier onlyStrategy() {
        require(msg.sender == strategy, "Only strategy");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./WithdrawalManagerProxy.sol";

contract WithdrawalManagerFactory is Ownable {
    event ImplementationUpdated(address indexed newImplementation);

    address public implementation;

    constructor(address implementation_) public {
        _updateImplementation(implementation_);
    }

    function deployContract(uint256 id) external returns (address) {
        WithdrawalManagerProxy proxy = new WithdrawalManagerProxy(this, id);
        return address(proxy);
    }

    function updateImplementation(address newImplementation) external onlyOwner {
        _updateImplementation(newImplementation);
    }

    function _updateImplementation(address newImplementation) private {
        implementation = newImplementation;
        emit ImplementationUpdated(newImplementation);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/proxy/Proxy.sol";

import "./WithdrawalManagerFactory.sol";

// An individual withdraw maanger for a node operator

contract WithdrawalManagerProxy is Proxy {
    using Address for address;

    WithdrawalManagerFactory internal immutable withdrawalManagerFactory;

    constructor(WithdrawalManagerFactory withdrawalManagerFactory_, uint256 operatorID_) public {
        // Initialize withdrawalManagerFactory
        require(address(withdrawalManagerFactory_) != address(0x0), "Invalid factory address");
        withdrawalManagerFactory = withdrawalManagerFactory_;
        // Check for contract existence
        address implAddress = withdrawalManagerFactory_.implementation();
        require(implAddress.isContract(), "Delegate contract does not exist");
        // Call Initialize on delegate
        (bool success, ) =
            implAddress.delegatecall(abi.encodeWithSignature("initialize(uint256)", operatorID_));
        if (!success) {
            revert("Failed delegatecall");
        }
    }

    function _implementation() internal view override returns (address) {
        return withdrawalManagerFactory.implementation();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

import "../../interfaces/IWrappedERC20.sol";
import "./IWithdrawalManager.sol";
import "./EthStakingStrategy.sol";

contract WithdrawalManager is IWithdrawalManager, Initializable {
    event EtherReceived(address indexed from, uint256 amount, uint256 time);

    EthStakingStrategy public immutable strategy;
    IWrappedERC20 private immutable _tokenUnderlying;

    uint256 public operatorID;

    constructor(address payable strategy_) public {
        strategy = EthStakingStrategy(strategy_);
        _tokenUnderlying = IWrappedERC20(
            IFundV3(EthStakingStrategy(strategy_).fund()).tokenUnderlying()
        );
    }

    function initialize(uint256 operatorID_) external initializer {
        operatorID = operatorID_;
    }

    receive() external payable {
        emit EtherReceived(msg.sender, msg.value, block.timestamp);
    }

    function getWithdrawalCredential() external view override returns (bytes32) {
        return bytes32(uint256(address(payable(this))) | (1 << 248));
    }

    function transferToStrategy(uint256 amount) external override onlyStrategy {
        (bool success, ) = address(strategy).call{value: amount}("");
        require(success);
    }

    modifier onlyStrategy() {
        require(address(strategy) == msg.sender, "Only strategy");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

import "./NodeOperatorRegistry.sol";

interface IDepositContractView {
    function get_deposit_root() external view returns (bytes32 rootHash);
}

contract SafeStaking is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    event MaxDepositAmountUpdated(uint256 newMaxDepositAmount);
    event MinDepositTimeIntervalUpdated(uint256 newMinDepositTimeInterval);
    event SafeguardAndQuorumUpdated(address[] newSafeguards, uint256 newQuorum);
    event Paused(address safeguard);
    event Unpaused();

    bytes32 private immutable DEPOSIT_MESSAGE_PREFIX;
    bytes32 private immutable KEY_VERIFY_MESSAGE_PREFIX;
    bytes32 private immutable PAUSE_MESSAGE_PREFIX;

    IEthStakingStrategy public immutable strategy;
    IDepositContractView public immutable depositContract;
    NodeOperatorRegistry public immutable registry;

    uint256 public maxDepositAmount;
    uint256 public minDepositTimeInterval;

    EnumerableSet.AddressSet private _safeguards;
    uint256 public quorum;

    bool public paused;
    uint256 public lastDepositTimestamp;

    constructor(
        address strategy_,
        uint256 maxDepositAmount_,
        uint256 minDepositTimeInterval_
    ) public {
        strategy = IEthStakingStrategy(strategy_);
        depositContract = IDepositContractView(IEthStakingStrategy(strategy_).depositContract());
        registry = NodeOperatorRegistry(IEthStakingStrategy(strategy_).registry());
        uint256 chainID = _getChainID();
        DEPOSIT_MESSAGE_PREFIX = keccak256(
            abi.encodePacked(keccak256("chess.SafeStaking.DEPOSIT_MESSAGE"), chainID)
        );
        KEY_VERIFY_MESSAGE_PREFIX = keccak256(
            abi.encodePacked(keccak256("chess.SafeStaking.KEY_VERIFY_MESSAGE"), chainID)
        );
        PAUSE_MESSAGE_PREFIX = keccak256(
            abi.encodePacked(keccak256("chess.SafeStaking.PAUSE_MESSAGE"), chainID)
        );

        _updateMaxDepositAmount(maxDepositAmount_);
        _updateMinDepositTimeInterval(minDepositTimeInterval_);
    }

    function _getChainID() private pure returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function getSafeguards() external view returns (address[] memory guards) {
        uint256 length = _safeguards.length();
        guards = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            guards[i] = _safeguards.at(i);
        }
    }

    function isSafeguard(address addr) public view returns (bool) {
        return _safeguards.contains(addr);
    }

    function updateMaxDepositAmount(uint256 newMaxDepositAmount) external onlyOwner {
        _updateMaxDepositAmount(newMaxDepositAmount);
    }

    function updateMinDepositTimeInterval(uint256 newMinDepositTimeInterval) external onlyOwner {
        _updateMinDepositTimeInterval(newMinDepositTimeInterval);
    }

    function updateSafeguardAndQuorum(address[] calldata newSafeguards, uint256 newQuorum)
        external
        onlyOwner
    {
        // Deletion in reverse order
        uint256 length = _safeguards.length();
        for (uint256 i = 0; i < length; i++) {
            _safeguards.remove(_safeguards.at(length - i - 1));
        }

        for (uint256 i = 0; i < newSafeguards.length; i++) {
            _safeguards.add(newSafeguards[i]);
        }

        require(newQuorum > 0, "Invalid quorum");
        quorum = newQuorum;

        emit SafeguardAndQuorumUpdated(newSafeguards, newQuorum);
    }

    function _updateMaxDepositAmount(uint256 newMaxDepositAmount) private {
        maxDepositAmount = newMaxDepositAmount;
        emit MaxDepositAmountUpdated(newMaxDepositAmount);
    }

    function _updateMinDepositTimeInterval(uint256 newMinDepositTimeInterval) private {
        require(newMinDepositTimeInterval > 0, "Invalid value");
        minDepositTimeInterval = newMinDepositTimeInterval;
        emit MinDepositTimeIntervalUpdated(newMinDepositTimeInterval);
    }

    modifier whenNotPaused() {
        require(!paused, "Paused");
        _;
    }

    /// @dev Pauses the contract given that both conditions:
    ///         1. The function is called by the safeguard OR the signature is valid
    ///         2. block.timestamp <= timestamp
    ///
    ///      The signature, if present, must be produced for keccak256 hash of the following
    ///      message (each component taking 32 bytes):
    ///
    ///      | PAUSE_MESSAGE_PREFIX | timestamp |
    function pause(uint256 timestamp, bytes memory signature) external whenNotPaused {
        address safeguardAddr = msg.sender;
        if (!isSafeguard(safeguardAddr)) {
            bytes32 msgHash = keccak256(abi.encodePacked(PAUSE_MESSAGE_PREFIX, timestamp));
            safeguardAddr = ECDSA.recover(msgHash, signature);
            require(isSafeguard(safeguardAddr), "Invalid signature");
        }

        require(block.timestamp <= timestamp, "Pause intent expired");

        paused = true;
        emit Paused(safeguardAddr);
    }

    function unpause() external onlyOwner {
        if (paused) {
            paused = false;
            emit Unpaused();
        }
    }

    /// @dev whether `safeDeposit` can be called, given that
    ///         1. The contract is not paused
    ///         2. The contract has been initalized
    ///         3. the last deposit was made at least `minDepositTimeInterval` seconds ago
    /// @return canDeposit whether `safeDeposit` can be called
    function canDeposit() external view returns (bool) {
        return
            !paused &&
            quorum > 0 &&
            block.timestamp - lastDepositTimestamp >= minDepositTimeInterval;
    }

    /// @dev Calls EthStakingStrategy.deposit(amount).
    ///      Reverts if any of the following is true:
    ///         1. depositRoot != depositContract.get_deposit_root()
    ///         2. registryVersion != registry.version()
    ///         3. The number of safeguard signatures is less than safeguard quorum
    ///         4. An invalid or non-safeguard signature received
    ///         5. depositAmount > maxDepositAmount
    ///         6. block.timestamp - getlastDepositTimestamp() < minDepositTimeInterval
    ///         7. blockHash != blockhash(blockNumber)
    ///
    ///      Signatures must be sorted in ascending order by address of the safeguards. Each signature must
    ///      be produced for keccak256 hash of the following message (each component taking 32 bytes):
    ///
    ///      | DEPOSIT_MESSAGE_PREFIX | depositRoot | registryVersion | blockNumber | blockHash | depositAmount
    function safeDeposit(
        bytes32 depositRoot,
        uint256 registryVersion,
        uint256 blockNumber,
        bytes32 blockHash,
        uint256 depositAmount,
        bytes memory signatures
    ) external whenNotPaused {
        require(depositRoot == depositContract.get_deposit_root(), "Deposit root changed");
        require(registryVersion == registry.registryVersion(), "Registry version changed");
        require(depositAmount <= maxDepositAmount, "Deposit amount exceeds max one-time deposit");
        require(
            block.timestamp - lastDepositTimestamp >= minDepositTimeInterval,
            "Too frequent deposits"
        );
        require(
            blockHash != bytes32(0) && blockhash(blockNumber) == blockHash,
            "Unexpected blockhash"
        );

        bytes32 msgHash =
            keccak256(
                abi.encodePacked(
                    DEPOSIT_MESSAGE_PREFIX,
                    depositRoot,
                    registryVersion,
                    blockNumber,
                    blockHash,
                    depositAmount
                )
            );
        _verifySignatures(msgHash, signatures);

        strategy.deposit(depositAmount);
        lastDepositTimestamp = block.timestamp;
    }

    function safeVerifyKeys(
        uint256 id,
        uint64 newVerifiedCount,
        uint256 registryVersion,
        bytes memory signatures
    ) external whenNotPaused {
        bytes32 msgHash =
            keccak256(
                abi.encodePacked(KEY_VERIFY_MESSAGE_PREFIX, id, newVerifiedCount, registryVersion)
            );
        _verifySignatures(msgHash, signatures);

        registry.updateVerifiedCount(id, newVerifiedCount, registryVersion);
    }

    function _verifySignatures(bytes32 msgHash, bytes memory signatures) private view {
        uint256 length = signatures.length / 65;
        require(
            quorum > 0 && length >= quorum && signatures.length % 65 == 0,
            "No safeguard quorum"
        );
        address prevSignerAddr = address(0);
        for (uint256 i = 0; i < length; ++i) {
            (uint8 v, bytes32 r, bytes32 s) = _splitSignature(signatures, i);
            address signerAddr = ECDSA.recover(msgHash, v, r, s);
            require(isSafeguard(signerAddr), "Invalid signature");
            require(signerAddr > prevSignerAddr, "Signatures not sorted");
            prevSignerAddr = signerAddr;
        }
    }

    /// @dev divides compact bytes signature {bytes32 r}{bytes32 s}{uint8 v} into `uint8 v, bytes32 r, bytes32 s`.
    ///      Make sure to peform a bounds check for @param pos, to avoid out of bounds access on @param signatures
    /// @param pos which signature to read. A prior bounds check of this parameter should be performed, to avoid out of bounds access
    /// @param signatures concatenated rsv signatures
    function _splitSignature(bytes memory signatures, uint256 pos)
        private
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        assembly {
            let signaturePos := add(signatures, mul(0x41, pos))
            r := mload(add(signaturePos, 0x20))
            s := mload(add(signaturePos, 0x40))
            v := byte(0, mload(add(signaturePos, 0x60)))
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../../utils/SafeDecimalMath.sol";
import "../../interfaces/IFundV3.sol";

interface IEthStakingStrategy {
    function fund() external view returns (address);

    function batchReport(
        uint256 epoch,
        uint256[] memory ids,
        uint256[] memory beaconBalances,
        uint256[] memory validatorCounts
    ) external;
}

contract BeaconStakingOracle is Ownable {
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    event BeaconReported(
        uint256 epochId,
        uint256[] ids,
        uint256[] beaconBalance,
        uint256[] beaconValidators,
        address caller
    );
    event MemberAdded(address member);
    event MemberRemoved(address member);
    event AnnualMaxChangeUpdated(uint256 newAnnualMaxChange);
    event QuorumUpdated(uint256 newQuorum);

    IEthStakingStrategy public immutable strategy;
    IFundV3 public immutable fund;

    /// @notice Number of epochs between adjacent reports
    uint256 public immutable reportableEpochInterval;

    uint256 public immutable secondsPerEpoch;

    /// @notice Timestamp of epoch 0
    uint256 public immutable genesisTime;

    uint256 public annualMaxChange;

    /// @notice Number of exactly the same reports needed to finalize the epoch
    uint256 public quorum;
    uint256 public nonce;
    uint256 public lastCompletedEpoch;

    /// @notice Epoch => report hash => received count
    mapping(uint256 => mapping(bytes32 => uint256)) public reports;

    /// @dev Oracle member => epoch of the most recent report
    mapping(address => uint256) public lastReportedEpoch;

    EnumerableSet.AddressSet private _members;

    constructor(
        address strategy_,
        uint256 reportableEpochInterval_,
        uint256 secondsPerEpoch_,
        uint256 genesisTime_,
        uint256 annualMaxChange_
    ) public {
        strategy = IEthStakingStrategy(strategy_);
        fund = IFundV3(IEthStakingStrategy(strategy_).fund());
        reportableEpochInterval = reportableEpochInterval_;
        secondsPerEpoch = secondsPerEpoch_;
        require(genesisTime_ < block.timestamp);
        genesisTime = genesisTime_;
        _updateAnnualMaxChange(annualMaxChange_);
    }

    /// @notice Report validator balances on Beacon chain
    /// @param epoch Beacon chain epoch
    /// @param ids Node operator IDs, which must be sorted in ascending order
    /// @param beaconBalances Balance in wei of all validators of each node operator
    /// @param validatorCounts Number of validators visible in this epoch
    function batchReport(
        uint256 epoch,
        uint256[] memory ids,
        uint256[] memory beaconBalances,
        uint256[] memory validatorCounts
    ) external onlyMember {
        require(
            epoch <= getLatestReportableEpoch() &&
                epoch > lastCompletedEpoch &&
                epoch % reportableEpochInterval == 0,
            "Invalid epoch"
        );
        require(lastReportedEpoch[msg.sender] < epoch, "Already reported");
        lastReportedEpoch[msg.sender] = epoch;

        // Push the result to `reports` queue, report to strategy if counts exceed `quorum`
        bytes32 report = encodeBatchReport(ids, beaconBalances, validatorCounts);
        uint256 currentCount = reports[epoch][report] + 1;
        emit BeaconReported(epoch, ids, beaconBalances, validatorCounts, msg.sender);

        if (currentCount >= quorum) {
            uint256 preTotalUnderlying = fund.getTotalUnderlying();
            strategy.batchReport(epoch, ids, beaconBalances, validatorCounts);
            uint256 postTotalUnderlying = fund.getTotalUnderlying();

            uint256 timeElapsed = (epoch - lastCompletedEpoch) * secondsPerEpoch;
            _sanityCheck(postTotalUnderlying, preTotalUnderlying, timeElapsed);
            lastCompletedEpoch = epoch;

            if (currentCount > 1) {
                reports[epoch][report] = 0; // Clear storage for gas refund
            }
        } else {
            reports[epoch][report] = currentCount;
        }
    }

    /// @dev Performs logical consistency check of the underlying changes as the result of reports push
    function _sanityCheck(
        uint256 postTotalUnderlying,
        uint256 preTotalUnderlying,
        uint256 timeElapsed
    ) private view {
        uint256 delta =
            postTotalUnderlying >= preTotalUnderlying
                ? postTotalUnderlying - preTotalUnderlying
                : preTotalUnderlying - postTotalUnderlying;
        require(
            delta.mul(365 days) / timeElapsed <=
                preTotalUnderlying.multiplyDecimal(annualMaxChange),
            "Annual max delta"
        );
    }

    /// @notice Return the latest reportable epoch
    function getLatestReportableEpoch() public view returns (uint256) {
        uint256 latestEpoch = (block.timestamp - genesisTime) / secondsPerEpoch;
        return (latestEpoch / reportableEpochInterval) * reportableEpochInterval;
    }

    function encodeBatchReport(
        uint256[] memory ids,
        uint256[] memory beaconBalances,
        uint256[] memory validatorCounts
    ) public view returns (bytes32) {
        return keccak256(abi.encodePacked(ids, beaconBalances, validatorCounts, nonce));
    }

    /// @notice Return the epoch that an oracle member should report now,
    ///         or zero if the latest reportable epoch is already reported.
    function getNextEpochByMember(address member) external view returns (uint256) {
        uint256 epoch = getLatestReportableEpoch();
        uint256 last = lastReportedEpoch[member];
        return epoch > last ? epoch : 0;
    }

    modifier onlyMember() {
        require(_members.contains(msg.sender), "Member not found");
        _;
    }

    function getMemberCount() external view returns (uint256) {
        return _members.length();
    }

    function getMembers() external view returns (address[] memory members) {
        uint256 length = _members.length();
        members = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            members[i] = _members.at(i);
        }
    }

    function addMember(address member, uint256 newQuorum) external onlyOwner {
        require(member != address(0), "Invalid address");
        require(!_members.contains(member), "Already a member");
        _members.add(member);
        emit MemberAdded(member);

        _updateQuorum(newQuorum);
    }

    function removeMember(address member, uint256 newQuorum) external onlyOwner {
        require(_members.contains(member), "Not a member");
        _members.remove(member);
        emit MemberRemoved(member);

        _updateQuorum(newQuorum);

        // Force out the previous records, and allow the remained oracles to report it again
        nonce++;
    }

    function updateAnnualMaxChange(uint256 newAnnualMaxChange) external onlyOwner {
        _updateAnnualMaxChange(newAnnualMaxChange);
    }

    function updateQuorum(uint256 newQuorum) external onlyOwner {
        _updateQuorum(newQuorum);
    }

    function _updateAnnualMaxChange(uint256 newAnnualMaxChange) private {
        annualMaxChange = newAnnualMaxChange;
        emit AnnualMaxChangeUpdated(newAnnualMaxChange);
    }

    function _updateQuorum(uint256 newQuorum) private {
        quorum = newQuorum;
        emit QuorumUpdated(newQuorum);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../utils/SafeDecimalMath.sol";

import "../interfaces/IFundV3.sol";
import "../interfaces/IFundForStrategy.sol";
import "../interfaces/IWrappedERC20.sol";

interface ITokenHub {
    function getMiniRelayFee() external view returns (uint256);

    function transferOut(
        address contractAddr,
        address recipient,
        uint256 amount,
        uint64 expireTime
    ) external payable returns (bool);
}

/// @notice Strategy for delegating BNB to BSC validators and earn rewards.
///
///         BSC validator delegation and reward distribution happens on the Binance Chain (BC).
///         A staker address, which is securely managed by multi-signature, executes
///         delegation-related transactions and periodically transfer rewards back to this contract
///         on BSC.
///
///         This contract is a bridge between the fund and the staker. It performs cross-chain
///         transfers from the fund to the staker and forward transfers from the staker back to
///         the fund. It is also in charge of profit bookkeeping, which is either automatcially
///         reported by reporters using scripts or manually calibrated by the owner.
contract BscStakingStrategy is Ownable {
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;
    using SafeERC20 for IWrappedERC20;

    event ReporterAdded(address reporter);
    event ReporterRemoved(address reporter);
    event StakerUpdated(address staker);
    event Received(address from, uint256 amount);

    ITokenHub private constant TOKEN_HUB = ITokenHub(0x0000000000000000000000000000000000001004);
    uint256 private constant BRIDGE_EXPIRE_TIME = 1 hours;
    uint256 private constant MAX_ESTIMATED_DAILY_PROFIT_RATE = 0.1e18;
    uint256 private constant MAX_PERFORMANCE_FEE_RATE = 0.5e18;

    address public immutable fund;
    address private immutable _tokenUnderlying;

    /// @notice BEP2 address that does the actual staking on Binance Chain.
    ///         DO NOT transfer any asset to this address on Binance Smart Chain.
    address public staker;

    /// @notice Fraction of profit that goes to the fund's fee collector.
    uint256 public performanceFeeRate;

    /// @notice Estimated daily profit rate. This value limits the maximum daily profit that can be
    ///         reported by a reporter.
    uint256 public estimatedDailyProfitRate;

    /// @notice Amount of underlying lost since the last peak. Performance fee is charged
    ///         only when this value is zero.
    uint256 public currentDrawdown;

    /// @notice The set of reporters. Reporters can report profit within a pre-configured range
    ///         once a day.
    mapping(address => bool) public reporters;

    /// @notice The last trading day when a reporter reports daily profit.
    uint256 public reportedDay;

    constructor(
        address fund_,
        address staker_,
        uint256 performanceFeeRate_
    ) public {
        fund = fund_;
        _tokenUnderlying = IFundV3(fund_).tokenUnderlying();
        staker = staker_;
        performanceFeeRate = performanceFeeRate_;
        emit StakerUpdated(staker_);
    }

    modifier onlyReporter() {
        require(reporters[msg.sender], "Only reporter");
        _;
    }

    function addReporter(address reporter) external onlyOwner {
        require(!reporters[reporter]);
        reporters[reporter] = true;
        emit ReporterAdded(reporter);
    }

    function removeReporter(address reporter) external onlyOwner {
        require(reporters[reporter]);
        reporters[reporter] = false;
        emit ReporterRemoved(reporter);
    }

    /// @notice Report daily profit to the fund by a reporter.
    /// @param amount Absolute profit, which must be no greater than twice the estimation
    function accrueProfit(uint256 amount) external onlyReporter {
        uint256 total = IFundV3(fund).getStrategyUnderlying();
        require(
            amount / 2 <= total.multiplyDecimal(estimatedDailyProfitRate),
            "Profit out of range"
        );
        _accrueProfit(amount);
    }

    /// @notice Report daily profit according to the pre-configured rate by a reporter.
    function accrueEstimatedProfit() external onlyReporter {
        uint256 total = IFundV3(fund).getStrategyUnderlying();
        _accrueProfit(total.multiplyDecimal(estimatedDailyProfitRate));
    }

    function _accrueProfit(uint256 amount) private {
        uint256 currentDay = IFundV3(fund).currentDay();
        uint256 oldReportedDay = reportedDay;
        require(oldReportedDay < currentDay, "Already reported");
        reportedDay = oldReportedDay + 1 days;
        _reportProfit(amount);
    }

    function updateEstimatedDailyProfitRate(uint256 rate) external onlyOwner {
        require(rate < MAX_ESTIMATED_DAILY_PROFIT_RATE);
        estimatedDailyProfitRate = rate;
        reportedDay = IFundV3(fund).currentDay();
    }

    /// @notice Report profit to the fund by the owner.
    function reportProfit(uint256 amount) external onlyOwner {
        reportedDay = IFundV3(fund).currentDay();
        _reportProfit(amount);
    }

    /// @dev Report profit and performance fee to the fund. Performance fee is charged only when
    ///      there's no previous loss to cover.
    function _reportProfit(uint256 amount) private {
        uint256 oldDrawdown = currentDrawdown;
        if (amount < oldDrawdown) {
            currentDrawdown = oldDrawdown - amount;
            IFundForStrategy(fund).reportProfit(amount, 0);
        } else {
            if (oldDrawdown > 0) {
                currentDrawdown = 0;
            }
            uint256 performanceFee = (amount - oldDrawdown).multiplyDecimal(performanceFeeRate);
            IFundForStrategy(fund).reportProfit(amount, performanceFee);
        }
    }

    /// @notice Report loss to the fund. Performance fee will not be charged until
    ///         the current drawdown is covered.
    function reportLoss(uint256 amount) external onlyOwner {
        reportedDay = IFundV3(fund).currentDay();
        currentDrawdown = currentDrawdown.add(amount);
        IFundForStrategy(fund).reportLoss(amount);
    }

    function updateStaker(address newStaker) external onlyOwner {
        require(newStaker != address(0));
        staker = newStaker;
        emit StakerUpdated(newStaker);
    }

    function updatePerformanceFeeRate(uint256 newRate) external onlyOwner {
        require(newRate <= MAX_PERFORMANCE_FEE_RATE);
        performanceFeeRate = newRate;
    }

    /// @notice Transfer underlying tokens from the fund to the staker on Binance Chain.
    /// @param amount Amount of underlying transfered from the fund, including cross-chain relay fee
    function transferToStaker(uint256 amount) external onlyOwner {
        IFundForStrategy(fund).transferToStrategy(amount);
        _unwrap(amount);
        uint256 relayFee = TOKEN_HUB.getMiniRelayFee();
        require(
            TOKEN_HUB.transferOut{value: amount}(
                address(0),
                staker,
                amount.sub(relayFee),
                uint64(block.timestamp + BRIDGE_EXPIRE_TIME)
            ),
            "BSC bridge failed"
        );
    }

    /// @notice Transfer all underlying tokens, both wrapped and unwrapped, to the fund.
    function transferToFund() external onlyOwner {
        uint256 unwrapped = address(this).balance;
        if (unwrapped > 0) {
            _wrap(unwrapped);
        }
        uint256 amount = IWrappedERC20(_tokenUnderlying).balanceOf(address(this));
        IWrappedERC20(_tokenUnderlying).safeApprove(fund, amount);
        IFundForStrategy(fund).transferFromStrategy(amount);
    }

    /// @notice Receive cross-chain transfer from the staker.
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /// @dev Convert BNB into WBNB
    function _wrap(uint256 amount) private {
        IWrappedERC20(_tokenUnderlying).deposit{value: amount}();
    }

    /// @dev Convert WBNB into BNB
    function _unwrap(uint256 amount) private {
        IWrappedERC20(_tokenUnderlying).withdraw(amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "../utils/SafeDecimalMath.sol";
import "../utils/CoreUtility.sol";

import "../interfaces/IPrimaryMarketV3.sol";
import "../interfaces/IFundV4.sol";
import "../interfaces/IFundForPrimaryMarketV4.sol";
import "../interfaces/IFundForStrategyV2.sol";
import "../interfaces/IShareV2.sol";
import "../interfaces/ITwapOracleV2.sol";
import "../interfaces/IAprOracle.sol";
import "../interfaces/IBallot.sol";
import "../interfaces/IVotingEscrow.sol";

import "./FundRolesV2.sol";

contract FundV4 is
    IFundV4,
    IFundForPrimaryMarketV4,
    IFundForStrategyV2,
    Ownable,
    ReentrancyGuard,
    FundRolesV2,
    CoreUtility
{
    using Math for uint256;
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;
    using SafeERC20 for IERC20;

    event ProfitReported(uint256 profit, uint256 totalFee, uint256 totalFeeQ, uint256 strategyFeeQ);
    event LossReported(uint256 loss);
    event DailyProtocolFeeRateUpdated(uint256 newDailyProtocolFeeRate);
    event TwapOracleUpdated(address newTwapOracle);
    event AprOracleUpdated(address newAprOracle);
    event BallotUpdated(address newBallot);
    event FeeCollectorUpdated(address newFeeCollector);
    event ActivityDelayTimeUpdated(uint256 delayTime);
    event SplitRatioUpdated(uint256 newSplitRatio);
    event TotalDebtUpdated(uint256 newTotalDebt);

    uint256 private constant UNIT = 1e18;
    uint256 private constant MAX_INTEREST_RATE = 0.2e18; // 20% daily
    uint256 private constant MAX_DAILY_PROTOCOL_FEE_RATE = 0.05e18; // 5% daily rate

    /// @notice Upper bound of `NAV_R / NAV_B` to trigger a rebalance.
    uint256 public immutable upperRebalanceThreshold;

    /// @notice Lower bound of `NAV_R / NAV_B` to trigger a rebalance.
    uint256 public immutable lowerRebalanceThreshold;

    /// @notice Address of the underlying token.
    address public immutable override tokenUnderlying;

    /// @notice A multipler that normalizes an underlying balance to 18 decimal places.
    uint256 public immutable override underlyingDecimalMultiplier;

    /// @notice Daily protocol fee rate.
    uint256 public dailyProtocolFeeRate;

    /// @notice TwapOracle address for the underlying asset.
    ITwapOracleV2 public override twapOracle;

    /// @notice AprOracle address.
    IAprOracle public aprOracle;

    /// @notice Address of the interest rate ballot.
    IBallot public ballot;

    /// @notice Fee Collector address.
    address public override feeCollector;

    /// @notice End timestamp of the current trading day.
    ///         A trading day starts at UTC time `SETTLEMENT_TIME` of a day (inclusive)
    ///         and ends at the same time of the next day (exclusive).
    uint256 public override currentDay;

    /// @notice The amount of BISHOP received by splitting one QUEEN.
    ///         This ratio changes on every rebalance.
    uint256 public override splitRatio;

    /// @dev Mapping of rebalance version => splitRatio.
    mapping(uint256 => uint256) private _historicalSplitRatio;

    /// @notice Start timestamp of the current activity window.
    uint256 public override fundActivityStartTime;

    uint256 public activityDelayTimeAfterRebalance;

    /// @dev Historical rebalances. Rebalances are often accessed in loops with bounds checking.
    ///      So we store them in a fixed-length array, in order to make compiler-generated
    ///      bounds checking on every access cheaper. The actual length of this array is stored in
    ///      `_rebalanceSize` and should be explicitly checked when necessary.
    Rebalance[65535] private _rebalances;

    /// @dev Historical rebalance count.
    uint256 private _rebalanceSize;

    /// @dev Total share supply of the three tranches. They are always rebalanced to the latest
    ///      version.
    uint256[TRANCHE_COUNT] private _totalSupplies;

    /// @dev Mapping of account => share balance of the three tranches.
    ///      Rebalance versions are stored in a separate mapping `_balanceVersions`.
    mapping(address => uint256[TRANCHE_COUNT]) private _balances;

    /// @dev Rebalance version mapping for `_balances`.
    mapping(address => uint256) private _balanceVersions;

    /// @dev Mapping of owner => spender => share allowance of the three tranches.
    ///      Rebalance versions are stored in a separate mapping `_allowanceVersions`.
    mapping(address => mapping(address => uint256[TRANCHE_COUNT])) private _allowances;

    /// @dev Rebalance version mapping for `_allowances`.
    mapping(address => mapping(address => uint256)) private _allowanceVersions;

    /// @dev Mapping of trading day => NAV of BISHOP.
    mapping(uint256 => uint256) private _historicalNavB;

    /// @dev Mapping of trading day => NAV of ROOK.
    mapping(uint256 => uint256) private _historicalNavR;

    /// @notice Mapping of trading day => equivalent BISHOP supply.
    ///
    ///         Key is the end timestamp of a trading day. Value is the total supply of BISHOP,
    ///         as if all QUEEN are split.
    mapping(uint256 => uint256) public override historicalEquivalentTotalB;

    /// @notice Mapping of trading day => underlying assets in the fund.
    ///
    ///         Key is the end timestamp of a trading day. Value is the underlying assets in
    ///         the fund after settlement of that trading day.
    mapping(uint256 => uint256) public override historicalUnderlying;

    /// @notice Mapping of trading week => interest rate of BISHOP.
    ///
    ///         Key is the end timestamp of a trading day. Value is the interest rate captured
    ///         after settlement of that day, which will be effective in the following trading day.
    mapping(uint256 => uint256) public historicalInterestRate;

    /// @dev Amount of redemption underlying that the fund owes the primary market
    uint256 private _totalDebt;

    uint256 private _strategyUnderlying;

    struct ConstructorParameters {
        address tokenUnderlying;
        uint256 underlyingDecimals;
        address tokenQ;
        address tokenB;
        address tokenR;
        address primaryMarket;
        address strategy;
        uint256 dailyProtocolFeeRate;
        uint256 upperRebalanceThreshold;
        uint256 lowerRebalanceThreshold;
        address twapOracle;
        address aprOracle;
        address ballot;
        address feeCollector;
    }

    constructor(ConstructorParameters memory params)
        public
        Ownable()
        FundRolesV2(
            params.tokenQ,
            params.tokenB,
            params.tokenR,
            params.primaryMarket,
            params.strategy
        )
    {
        tokenUnderlying = params.tokenUnderlying;
        require(params.underlyingDecimals <= 18, "Underlying decimals larger than 18");
        underlyingDecimalMultiplier = 10**(18 - params.underlyingDecimals);
        _updateDailyProtocolFeeRate(params.dailyProtocolFeeRate);
        upperRebalanceThreshold = params.upperRebalanceThreshold;
        lowerRebalanceThreshold = params.lowerRebalanceThreshold;
        _updateTwapOracle(params.twapOracle);
        _updateAprOracle(params.aprOracle);
        _updateBallot(params.ballot);
        _updateFeeCollector(params.feeCollector);
        _updateActivityDelayTime(30 minutes);
    }

    function initialize(
        uint256 newSplitRatio,
        uint256 lastNavB,
        uint256 lastNavR,
        uint256 strategyUnderlying
    ) external onlyOwner {
        require(splitRatio == 0 && currentDay == 0, "Already initialized");
        require(
            newSplitRatio != 0 && lastNavB >= UNIT && !_shouldTriggerRebalance(lastNavB, lastNavR),
            "Invalid parameters"
        );
        currentDay = endOfDay(block.timestamp);
        splitRatio = newSplitRatio;
        _historicalSplitRatio[0] = newSplitRatio;
        emit SplitRatioUpdated(newSplitRatio);
        uint256 lastDay = currentDay - 1 days;
        uint256 lastDayPrice = twapOracle.getTwap(lastDay);
        require(lastDayPrice != 0, "Price not available"); // required to do the first creation
        _historicalNavB[lastDay] = lastNavB;
        _historicalNavR[lastDay] = lastNavR;
        _strategyUnderlying = strategyUnderlying;
        uint256 lastInterestRate = _updateInterestRate(lastDay);
        historicalInterestRate[lastDay] = lastInterestRate;
        emit Settled(lastDay, lastNavB, lastNavR, lastInterestRate);
        fundActivityStartTime = lastDay;
    }

    /// @notice UTC time of a day when the fund settles.
    function settlementTime() external pure returns (uint256) {
        return SETTLEMENT_TIME;
    }

    /// @notice Return end timestamp of the trading day containing a given timestamp.
    ///
    ///         A trading day starts at UTC time `SETTLEMENT_TIME` of a day (inclusive)
    ///         and ends at the same time of the next day (exclusive).
    /// @param timestamp The given timestamp
    /// @return End timestamp of the trading day.
    function endOfDay(uint256 timestamp) public pure override returns (uint256) {
        return ((timestamp.add(1 days) - SETTLEMENT_TIME) / 1 days) * 1 days + SETTLEMENT_TIME;
    }

    /// @notice Return end timestamp of the trading week containing a given timestamp.
    ///
    ///         A trading week starts at UTC time `SETTLEMENT_TIME` on a Thursday (inclusive)
    ///         and ends at the same time of the next Thursday (exclusive).
    /// @param timestamp The given timestamp
    /// @return End timestamp of the trading week.
    function endOfWeek(uint256 timestamp) external pure returns (uint256) {
        return _endOfWeek(timestamp);
    }

    function tokenQ() external view override returns (address) {
        return _tokenQ;
    }

    function tokenB() external view override returns (address) {
        return _tokenB;
    }

    function tokenR() external view override returns (address) {
        return _tokenR;
    }

    function tokenShare(uint256 tranche) external view override returns (address) {
        return _getShare(tranche);
    }

    function primaryMarket() external view override returns (address) {
        return _primaryMarket;
    }

    function primaryMarketUpdateProposal() external view override returns (address, uint256) {
        return (_proposedPrimaryMarket, _proposedPrimaryMarketTimestamp);
    }

    function strategy() external view override returns (address) {
        return _strategy;
    }

    function strategyUpdateProposal() external view override returns (address, uint256) {
        return (_proposedStrategy, _proposedStrategyTimestamp);
    }

    /// @notice Return the status of the fund contract.
    /// @param timestamp Timestamp to assess
    /// @return True if the fund contract is active
    function isFundActive(uint256 timestamp) public view override returns (bool) {
        return timestamp >= fundActivityStartTime;
    }

    function getTotalUnderlying() public view override returns (uint256) {
        uint256 hot = IERC20(tokenUnderlying).balanceOf(address(this));
        return hot.add(_strategyUnderlying).sub(_totalDebt);
    }

    function getStrategyUnderlying() external view override returns (uint256) {
        return _strategyUnderlying;
    }

    /// @notice Get the amount of redemption underlying that the fund owes the primary market.
    function getTotalDebt() external view override returns (uint256) {
        return _totalDebt;
    }

    /// @notice Equivalent BISHOP supply, as if all QUEEN are split.
    function getEquivalentTotalB() public view override returns (uint256) {
        return _totalSupplies[TRANCHE_Q].multiplyDecimal(splitRatio).add(_totalSupplies[TRANCHE_B]);
    }

    /// @notice Equivalent QUEEN supply, as if all BISHOP and ROOK are merged.
    function getEquivalentTotalQ() public view override returns (uint256) {
        return _totalSupplies[TRANCHE_B].divideDecimal(splitRatio).add(_totalSupplies[TRANCHE_Q]);
    }

    /// @notice Return the rebalance matrix at a given index. A zero struct is returned
    ///         if `index` is out of bound.
    /// @param index Rebalance index
    /// @return A rebalance matrix
    function getRebalance(uint256 index) external view override returns (Rebalance memory) {
        return _rebalances[index];
    }

    /// @notice Return timestamp of the transaction triggering the rebalance at a given index.
    ///         Zero is returned if `index` is out of bound.
    /// @param index Rebalance index
    /// @return Timestamp of the rebalance
    function getRebalanceTimestamp(uint256 index) external view override returns (uint256) {
        return _rebalances[index].timestamp;
    }

    /// @notice Return the number of historical rebalances.
    function getRebalanceSize() external view override returns (uint256) {
        return _rebalanceSize;
    }

    /// @notice Return split ratio at a given version.
    ///         Zero is returned if `version` is invalid.
    /// @param version Rebalance version
    /// @return Split ratio of the version
    function historicalSplitRatio(uint256 version) external view override returns (uint256) {
        return _historicalSplitRatio[version];
    }

    /// @notice Return NAV of BISHOP and ROOK of the given trading day.
    /// @param day End timestamp of a trading day
    /// @return navB NAV of BISHOP
    /// @return navR NAV of ROOK
    function historicalNavs(uint256 day)
        external
        view
        override
        returns (uint256 navB, uint256 navR)
    {
        return (_historicalNavB[day], _historicalNavR[day]);
    }

    /// @notice Estimate the current NAV of all tranches, considering underlying price change,
    ///         accrued protocol fee and accrued interest since the previous settlement.
    ///
    ///         The extrapolation uses simple interest instead of daily compound interest in
    ///         calculating protocol fee and BISHOP's interest. There may be significant error
    ///         in the returned values when `timestamp` is far beyond the last settlement.
    /// @param price Price of the underlying asset (18 decimal places)
    /// @return navSum Sum of the estimated NAV of BISHOP and ROOK
    /// @return navB Estimated NAV of BISHOP
    /// @return navROrZero Estimated NAV of ROOK, or zero if the NAV is negative
    function extrapolateNav(uint256 price)
        external
        view
        override
        returns (
            uint256 navSum,
            uint256 navB,
            uint256 navROrZero
        )
    {
        uint256 settledDay = currentDay - 1 days;
        uint256 underlying = getTotalUnderlying();
        uint256 protocolFee =
            underlying.multiplyDecimal(dailyProtocolFeeRate).mul(block.timestamp - settledDay).div(
                1 days
            );
        underlying = underlying.sub(protocolFee);
        return
            _extrapolateNav(block.timestamp, settledDay, price, getEquivalentTotalB(), underlying);
    }

    function _extrapolateNav(
        uint256 timestamp,
        uint256 settledDay,
        uint256 price,
        uint256 equivalentTotalB,
        uint256 underlying
    )
        private
        view
        returns (
            uint256 navSum,
            uint256 navB,
            uint256 navROrZero
        )
    {
        navB = _historicalNavB[settledDay];
        if (equivalentTotalB > 0) {
            navSum = price.mul(underlying.mul(underlyingDecimalMultiplier)).div(equivalentTotalB);
            navB = navB.multiplyDecimal(
                historicalInterestRate[settledDay].mul(timestamp - settledDay).div(1 days).add(UNIT)
            );
            navROrZero = navSum >= navB ? navSum - navB : 0;
        } else {
            // If the fund is empty, use NAV in the last day
            navROrZero = _historicalNavR[settledDay];
            navSum = navB + navROrZero;
        }
    }

    /// @notice Return the fund's relative income in a trading day. Note that denominators
    ///         of the returned ratios are the latest value instead of that at the last settlement.
    ///         If the amount of underlying token increases from 100 to 110 and assume that there's
    ///         no creation/redemption or underlying price change, return value `incomeOverQ` will
    ///         be 1/11 rather than 1/10.
    /// @param day End timestamp of a trading day
    /// @return incomeOverQ The ratio of income to the fund's total value
    /// @return incomeOverB The ratio of income to equivalent BISHOP total value if all QUEEN are split
    function getRelativeIncome(uint256 day)
        external
        view
        override
        returns (uint256 incomeOverQ, uint256 incomeOverB)
    {
        uint256 navB = _historicalNavB[day];
        if (navB == 0) {
            return (0, 0);
        }
        uint256 navR = _historicalNavR[day];
        if (navB == UNIT && navR == UNIT) {
            return (0, 0); // Rebalance is triggered
        }
        uint256 lastUnderlying = historicalUnderlying[day - 1 days];
        uint256 lastEquivalentTotalB = historicalEquivalentTotalB[day - 1 days];
        if (lastUnderlying == 0 || lastEquivalentTotalB == 0) {
            return (0, 0);
        }
        uint256 currentUnderlying = historicalUnderlying[day];
        uint256 currentEquivalentTotalB = historicalEquivalentTotalB[day];
        if (currentUnderlying == 0 || currentEquivalentTotalB == 0) {
            return (0, 0);
        }
        {
            uint256 ratio =
                ((lastUnderlying * currentEquivalentTotalB) / currentUnderlying).divideDecimal(
                    lastEquivalentTotalB
                );
            incomeOverQ = ratio > 1e18 ? 0 : 1e18 - ratio;
        }
        incomeOverB = incomeOverQ.mul(navB + navR) / navB;
    }

    /// @notice Transform share amounts according to the rebalance at a given index.
    ///         This function performs no bounds checking on the given index. A non-existent
    ///         rebalance transforms anything to a zero vector.
    /// @param amountQ Amount of QUEEN before the rebalance
    /// @param amountB Amount of BISHOP before the rebalance
    /// @param amountR Amount of ROOK before the rebalance
    /// @param index Rebalance index
    /// @return newAmountQ Amount of QUEEN after the rebalance
    /// @return newAmountB Amount of BISHOP after the rebalance
    /// @return newAmountR Amount of ROOK after the rebalance
    function doRebalance(
        uint256 amountQ,
        uint256 amountB,
        uint256 amountR,
        uint256 index
    )
        public
        view
        override
        returns (
            uint256 newAmountQ,
            uint256 newAmountB,
            uint256 newAmountR
        )
    {
        Rebalance storage rebalance = _rebalances[index];
        newAmountQ = amountQ.add(amountB.multiplyDecimal(rebalance.ratioB2Q)).add(
            amountR.multiplyDecimal(rebalance.ratioR2Q)
        );
        uint256 ratioBR = rebalance.ratioBR; // Gas saver
        newAmountB = amountB.multiplyDecimal(ratioBR);
        newAmountR = amountR.multiplyDecimal(ratioBR);
    }

    /// @notice Transform share amounts according to rebalances in a given index range,
    ///         This function performs no bounds checking on the given indices. The original amounts
    ///         are returned if `fromIndex` is no less than `toIndex`. A zero vector is returned
    ///         if `toIndex` is greater than the number of existing rebalances.
    /// @param amountQ Amount of QUEEN before the rebalance
    /// @param amountB Amount of BISHOP before the rebalance
    /// @param amountR Amount of ROOK before the rebalance
    /// @param fromIndex Starting of the rebalance index range, inclusive
    /// @param toIndex End of the rebalance index range, exclusive
    /// @return newAmountQ Amount of QUEEN after the rebalance
    /// @return newAmountB Amount of BISHOP after the rebalance
    /// @return newAmountR Amount of ROOK after the rebalance
    function batchRebalance(
        uint256 amountQ,
        uint256 amountB,
        uint256 amountR,
        uint256 fromIndex,
        uint256 toIndex
    )
        external
        view
        override
        returns (
            uint256 newAmountQ,
            uint256 newAmountB,
            uint256 newAmountR
        )
    {
        for (uint256 i = fromIndex; i < toIndex; i++) {
            (amountQ, amountB, amountR) = doRebalance(amountQ, amountB, amountR, i);
        }
        newAmountQ = amountQ;
        newAmountB = amountB;
        newAmountR = amountR;
    }

    /// @notice Transform share balance to a given rebalance version, or to the latest version
    ///         if `targetVersion` is zero.
    /// @param account Account of the balance to rebalance
    /// @param targetVersion The target rebalance version, or zero for the latest version
    function refreshBalance(address account, uint256 targetVersion) external override {
        if (targetVersion > 0) {
            require(targetVersion <= _rebalanceSize, "Target version out of bound");
        }
        _refreshBalance(account, targetVersion);
    }

    /// @notice Transform allowance to a given rebalance version, or to the latest version
    ///         if `targetVersion` is zero.
    /// @param owner Owner of the allowance to rebalance
    /// @param spender Spender of the allowance to rebalance
    /// @param targetVersion The target rebalance version, or zero for the latest version
    function refreshAllowance(
        address owner,
        address spender,
        uint256 targetVersion
    ) external override {
        if (targetVersion > 0) {
            require(targetVersion <= _rebalanceSize, "Target version out of bound");
        }
        _refreshAllowance(owner, spender, targetVersion);
    }

    function trancheBalanceOf(uint256 tranche, address account)
        external
        view
        override
        returns (uint256)
    {
        uint256 latestVersion = _rebalanceSize;
        uint256 userVersion = _balanceVersions[account];
        if (userVersion == latestVersion) {
            // Fast path
            return _balances[account][tranche];
        }

        uint256 amountQ = _balances[account][TRANCHE_Q];
        uint256 amountB = _balances[account][TRANCHE_B];
        uint256 amountR = _balances[account][TRANCHE_R];
        for (uint256 i = userVersion; i < latestVersion; i++) {
            (amountQ, amountB, amountR) = doRebalance(amountQ, amountB, amountR, i);
        }
        if (tranche == TRANCHE_Q) {
            return amountQ;
        } else if (tranche == TRANCHE_B) {
            return amountB;
        } else if (tranche == TRANCHE_R) {
            return amountR;
        } else {
            revert("Invalid tranche");
        }
    }

    /// @notice Return all three share balances transformed to the latest rebalance version.
    /// @param account Owner of the shares
    function trancheAllBalanceOf(address account)
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 amountQ = _balances[account][TRANCHE_Q];
        uint256 amountB = _balances[account][TRANCHE_B];
        uint256 amountR = _balances[account][TRANCHE_R];

        uint256 size = _rebalanceSize; // Gas saver
        for (uint256 i = _balanceVersions[account]; i < size; i++) {
            (amountQ, amountB, amountR) = doRebalance(amountQ, amountB, amountR, i);
        }

        return (amountQ, amountB, amountR);
    }

    function trancheBalanceVersion(address account) external view override returns (uint256) {
        return _balanceVersions[account];
    }

    function trancheAllowance(
        uint256 tranche,
        address owner,
        address spender
    ) external view override returns (uint256) {
        uint256 allowance = _allowances[owner][spender][tranche];
        if (tranche != TRANCHE_Q) {
            uint256 size = _rebalanceSize; // Gas saver
            for (uint256 i = _allowanceVersions[owner][spender]; i < size; i++) {
                allowance = _rebalanceAllowanceBR(allowance, i);
            }
        }
        return allowance;
    }

    function trancheAllowanceVersion(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowanceVersions[owner][spender];
    }

    function trancheTransfer(
        uint256 tranche,
        address recipient,
        uint256 amount,
        uint256 version
    ) external override onlyCurrentVersion(version) {
        _refreshBalance(msg.sender, version);
        if (tranche != TRANCHE_Q) {
            _refreshBalance(recipient, version);
        }
        _transfer(tranche, msg.sender, recipient, amount);
    }

    function trancheTransferFrom(
        uint256 tranche,
        address sender,
        address recipient,
        uint256 amount,
        uint256 version
    ) external override onlyCurrentVersion(version) {
        _refreshBalance(sender, version);
        if (tranche != TRANCHE_Q) {
            _refreshAllowance(sender, msg.sender, version);
            _refreshBalance(recipient, version);
        }
        uint256 newAllowance =
            _allowances[sender][msg.sender][tranche].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            );
        _approve(tranche, sender, msg.sender, newAllowance);
        _transfer(tranche, sender, recipient, amount);
    }

    function trancheApprove(
        uint256 tranche,
        address spender,
        uint256 amount,
        uint256 version
    ) external override onlyCurrentVersion(version) {
        if (tranche != TRANCHE_Q) {
            _refreshAllowance(msg.sender, spender, version);
        }
        _approve(tranche, msg.sender, spender, amount);
    }

    function trancheTotalSupply(uint256 tranche) external view override returns (uint256) {
        return _totalSupplies[tranche];
    }

    function primaryMarketMint(
        uint256 tranche,
        address account,
        uint256 amount,
        uint256 version
    ) external override onlyPrimaryMarket onlyCurrentVersion(version) {
        if (tranche != TRANCHE_Q) {
            _refreshBalance(account, version);
        }
        _mint(tranche, account, amount);
    }

    function primaryMarketBurn(
        uint256 tranche,
        address account,
        uint256 amount,
        uint256 version
    ) external override onlyPrimaryMarket onlyCurrentVersion(version) {
        // Unlike `primaryMarketMint()`, `_refreshBalance()` is required even if we are burning
        // QUEEN tokens, because a rebalance may increase the user's QUEEN balance if the user
        // owns BISHOP or ROOK tokens beforehand.
        _refreshBalance(account, version);
        _burn(tranche, account, amount);
    }

    function shareTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) public override {
        uint256 tranche = _getTranche(msg.sender);
        if (tranche != TRANCHE_Q) {
            require(isFundActive(block.timestamp), "Transfer is inactive");
            _refreshBalance(recipient, _rebalanceSize);
        }
        _refreshBalance(sender, _rebalanceSize);
        _transfer(tranche, sender, recipient, amount);
    }

    function shareTransferFrom(
        address spender,
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (uint256 newAllowance) {
        uint256 tranche = _getTranche(msg.sender);
        shareTransfer(sender, recipient, amount);
        if (tranche != TRANCHE_Q) {
            _refreshAllowance(sender, spender, _rebalanceSize);
        }
        newAllowance = _allowances[sender][spender][tranche].sub(
            amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(tranche, sender, spender, newAllowance);
    }

    function shareApprove(
        address owner,
        address spender,
        uint256 amount
    ) external override {
        uint256 tranche = _getTranche(msg.sender);
        if (tranche != TRANCHE_Q) {
            _refreshAllowance(owner, spender, _rebalanceSize);
        }
        _approve(tranche, owner, spender, amount);
    }

    function shareIncreaseAllowance(
        address sender,
        address spender,
        uint256 addedValue
    ) external override returns (uint256 newAllowance) {
        uint256 tranche = _getTranche(msg.sender);
        if (tranche != TRANCHE_Q) {
            _refreshAllowance(sender, spender, _rebalanceSize);
        }
        newAllowance = _allowances[sender][spender][tranche].add(addedValue);
        _approve(tranche, sender, spender, newAllowance);
    }

    function shareDecreaseAllowance(
        address sender,
        address spender,
        uint256 subtractedValue
    ) external override returns (uint256 newAllowance) {
        uint256 tranche = _getTranche(msg.sender);
        if (tranche != TRANCHE_Q) {
            _refreshAllowance(sender, spender, _rebalanceSize);
        }
        newAllowance = _allowances[sender][spender][tranche].sub(subtractedValue);
        _approve(tranche, sender, spender, newAllowance);
    }

    function _transfer(
        uint256 tranche,
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender][tranche] = _balances[sender][tranche].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient][tranche] = _balances[recipient][tranche].add(amount);
        IShareV2(_getShare(tranche)).fundEmitTransfer(sender, recipient, amount);
    }

    function _mint(
        uint256 tranche,
        address account,
        uint256 amount
    ) private {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupplies[tranche] = _totalSupplies[tranche].add(amount);
        _balances[account][tranche] = _balances[account][tranche].add(amount);
        IShareV2(_getShare(tranche)).fundEmitTransfer(address(0), account, amount);
    }

    function _burn(
        uint256 tranche,
        address account,
        uint256 amount
    ) private {
        require(account != address(0), "ERC20: burn from the zero address");
        _balances[account][tranche] = _balances[account][tranche].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupplies[tranche] = _totalSupplies[tranche].sub(amount);
        IShareV2(_getShare(tranche)).fundEmitTransfer(account, address(0), amount);
    }

    function _approve(
        uint256 tranche,
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender][tranche] = amount;
        IShareV2(_getShare(tranche)).fundEmitApproval(owner, spender, amount);
    }

    /// @notice Settle the current trading day. Settlement includes the following changes
    ///         to the fund.
    ///
    ///         1. Charge protocol fee of the day.
    ///         2. Settle all pending creations and redemptions from the primary market.
    ///         3. Calculate NAV of the day and trigger rebalance if necessary.
    ///         4. Capture new interest rate for BISHOP.
    function settle() external nonReentrant {
        uint256 day = currentDay;
        require(day != 0, "Not initialized");
        require(block.timestamp >= day, "The current trading day does not end yet");
        uint256 price = twapOracle.getTwap(day);
        require(price != 0, "Underlying price for settlement is not ready yet");

        _collectFee();

        IPrimaryMarketV3(_primaryMarket).settle(day);

        // Calculate NAV
        uint256 equivalentTotalB = getEquivalentTotalB();
        uint256 underlying = getTotalUnderlying();
        (uint256 navSum, uint256 navB, uint256 navR) =
            _extrapolateNav(day, day - 1 days, price, equivalentTotalB, underlying);

        if (_shouldTriggerRebalance(navB, navR)) {
            uint256 newSplitRatio = splitRatio.multiplyDecimal(navSum) / 2;
            _triggerRebalance(day, navSum, navB, navR, newSplitRatio);
            navB = UNIT;
            navR = UNIT;
            equivalentTotalB = getEquivalentTotalB();
            fundActivityStartTime = day + activityDelayTimeAfterRebalance;
        } else {
            fundActivityStartTime = day;
        }

        historicalEquivalentTotalB[day] = equivalentTotalB;
        historicalUnderlying[day] = underlying;
        _historicalNavB[day] = navB;
        _historicalNavR[day] = navR;
        uint256 interestRate = _updateInterestRate(day);
        historicalInterestRate[day] = interestRate;
        currentDay = day + 1 days;

        emit Settled(day, navB, navR, interestRate);
    }

    function transferToStrategy(uint256 amount) external override onlyStrategy {
        _strategyUnderlying = _strategyUnderlying.add(amount);
        IERC20(tokenUnderlying).safeTransfer(_strategy, amount);
    }

    function transferFromStrategy(uint256 amount) external override onlyStrategy {
        _strategyUnderlying = _strategyUnderlying.sub(amount);
        IERC20(tokenUnderlying).safeTransferFrom(_strategy, address(this), amount);
    }

    function primaryMarketTransferUnderlying(
        address recipient,
        uint256 amount,
        uint256 feeQ
    ) external override onlyPrimaryMarket {
        IERC20(tokenUnderlying).safeTransfer(recipient, amount);
        _mint(TRANCHE_Q, feeCollector, feeQ);
    }

    function primaryMarketAddDebtAndFee(uint256 amount, uint256 feeQ)
        external
        override
        onlyPrimaryMarket
    {
        _mint(TRANCHE_Q, feeCollector, feeQ);
        _updateTotalDebt(_totalDebt.add(amount));
    }

    function primaryMarketPayDebt(uint256 amount) external override onlyPrimaryMarket {
        _updateTotalDebt(_totalDebt.sub(amount));
        IERC20(tokenUnderlying).safeTransfer(msg.sender, amount);
    }

    function reportProfit(
        uint256 profit,
        uint256 totalFee,
        uint256 strategyFee
    ) external override onlyStrategy returns (uint256 strategyFeeQ) {
        require(profit >= totalFee && totalFee >= strategyFee, "Fee cannot exceed profit");
        _strategyUnderlying = _strategyUnderlying.add(profit);
        uint256 equivalentTotalQ = getEquivalentTotalQ();
        uint256 totalUnderlyingAfterFee = getTotalUnderlying() - totalFee;
        uint256 totalFeeQ = totalFee.mul(equivalentTotalQ).div(totalUnderlyingAfterFee);
        strategyFeeQ = strategyFee.mul(equivalentTotalQ).div(totalUnderlyingAfterFee);
        _mint(TRANCHE_Q, feeCollector, totalFeeQ.sub(strategyFeeQ));
        _mint(TRANCHE_Q, msg.sender, strategyFeeQ);
        emit ProfitReported(profit, totalFee, totalFeeQ, strategyFeeQ);
    }

    function reportLoss(uint256 loss) external override onlyStrategy {
        _strategyUnderlying = _strategyUnderlying.sub(loss);
        emit LossReported(loss);
    }

    function proposePrimaryMarketUpdate(address newPrimaryMarket) external onlyOwner {
        _proposePrimaryMarketUpdate(newPrimaryMarket);
    }

    function applyPrimaryMarketUpdate(address newPrimaryMarket) external onlyOwner {
        require(
            IPrimaryMarketV3(_primaryMarket).canBeRemovedFromFund(),
            "Cannot update primary market"
        );
        _applyPrimaryMarketUpdate(newPrimaryMarket);
    }

    function proposeStrategyUpdate(address newStrategy) external onlyOwner {
        _proposeStrategyUpdate(newStrategy);
    }

    function applyStrategyUpdate(address newStrategy) external onlyOwner {
        require(_totalDebt == 0, "Cannot update strategy with debt");
        _applyStrategyUpdate(newStrategy);
    }

    function _updateDailyProtocolFeeRate(uint256 newDailyProtocolFeeRate) private {
        require(
            newDailyProtocolFeeRate <= MAX_DAILY_PROTOCOL_FEE_RATE,
            "Exceed max protocol fee rate"
        );
        dailyProtocolFeeRate = newDailyProtocolFeeRate;
        emit DailyProtocolFeeRateUpdated(newDailyProtocolFeeRate);
    }

    function updateDailyProtocolFeeRate(uint256 newDailyProtocolFeeRate) external onlyOwner {
        _updateDailyProtocolFeeRate(newDailyProtocolFeeRate);
    }

    function _updateTwapOracle(address newTwapOracle) private {
        twapOracle = ITwapOracleV2(newTwapOracle);
        emit TwapOracleUpdated(newTwapOracle);
    }

    function updateTwapOracle(address newTwapOracle) external onlyOwner {
        _updateTwapOracle(newTwapOracle);
    }

    function _updateAprOracle(address newAprOracle) private {
        aprOracle = IAprOracle(newAprOracle);
        emit AprOracleUpdated(newAprOracle);
    }

    function updateAprOracle(address newAprOracle) external onlyOwner {
        _updateAprOracle(newAprOracle);
    }

    function _updateBallot(address newBallot) private {
        ballot = IBallot(newBallot);
        emit BallotUpdated(newBallot);
    }

    function updateBallot(address newBallot) external onlyOwner {
        _updateBallot(newBallot);
    }

    function _updateFeeCollector(address newFeeCollector) private {
        feeCollector = newFeeCollector;
        emit FeeCollectorUpdated(newFeeCollector);
    }

    function updateFeeCollector(address newFeeCollector) external onlyOwner {
        _updateFeeCollector(newFeeCollector);
    }

    function _updateActivityDelayTime(uint256 delayTime) private {
        require(
            delayTime >= 30 minutes && delayTime <= 12 hours,
            "Exceed allowed delay time range"
        );
        activityDelayTimeAfterRebalance = delayTime;
        emit ActivityDelayTimeUpdated(delayTime);
    }

    function updateActivityDelayTime(uint256 delayTime) external onlyOwner {
        _updateActivityDelayTime(delayTime);
    }

    /// @dev Collect protocol fee by minting QUEEN tokens to the fee collector.
    function _collectFee() private {
        uint256 feeRate = dailyProtocolFeeRate;
        if (feeRate == 0) {
            return;
        }
        uint256 feeQ = getEquivalentTotalQ().mul(feeRate) / (1e18 - feeRate);
        if (feeQ > 0) {
            _mint(TRANCHE_Q, feeCollector, feeQ);
        }
    }

    /// @dev Check whether a new rebalance should be triggered. Rebalance is triggered if
    ///      ROOK's NAV over BISHOP's NAV is greater than the upper threshold or
    ///      less than the lower threshold.
    /// @param navB BISHOP's NAV before the rebalance
    /// @param navROrZero ROOK's NAV before the rebalance or zero if the NAV is negative
    /// @return Whether a new rebalance should be triggered
    function _shouldTriggerRebalance(uint256 navB, uint256 navROrZero) private view returns (bool) {
        uint256 rOverB = navROrZero.divideDecimal(navB);
        return rOverB < lowerRebalanceThreshold || rOverB > upperRebalanceThreshold;
    }

    /// @dev Create a new rebalance that resets NAV of all tranches to 1. Total supplies are
    ///      rebalanced immediately.
    /// @param day Trading day that triggers this rebalance
    /// @param navSum Sum of BISHOP and ROOK's NAV
    /// @param navB BISHOP's NAV before this rebalance
    /// @param navROrZero ROOK's NAV before this rebalance or zero if the NAV is negative
    /// @param newSplitRatio The new split ratio after this rebalance
    function _triggerRebalance(
        uint256 day,
        uint256 navSum,
        uint256 navB,
        uint256 navROrZero,
        uint256 newSplitRatio
    ) private {
        Rebalance memory rebalance = _calculateRebalance(navSum, navB, navROrZero, newSplitRatio);
        uint256 oldSize = _rebalanceSize;
        splitRatio = newSplitRatio;
        _historicalSplitRatio[oldSize + 1] = newSplitRatio;
        emit SplitRatioUpdated(newSplitRatio);
        _rebalances[oldSize] = rebalance;
        _rebalanceSize = oldSize + 1;
        emit RebalanceTriggered(
            oldSize,
            day,
            navSum,
            navB,
            navROrZero,
            rebalance.ratioB2Q,
            rebalance.ratioR2Q,
            rebalance.ratioBR
        );

        (
            _totalSupplies[TRANCHE_Q],
            _totalSupplies[TRANCHE_B],
            _totalSupplies[TRANCHE_R]
        ) = doRebalance(
            _totalSupplies[TRANCHE_Q],
            _totalSupplies[TRANCHE_B],
            _totalSupplies[TRANCHE_R],
            oldSize
        );
        _refreshBalance(address(this), oldSize + 1);
    }

    /// @dev Create a new rebalance matrix that resets given NAVs to (1, 1).
    ///
    ///      Note that ROOK's NAV can be negative before the rebalance when the underlying price
    ///      drops dramatically in a single trading day, in which case zero should be passed to
    ///      this function instead of the negative NAV.
    /// @param navSum Sum of BISHOP and ROOK's NAV
    /// @param navB BISHOP's NAV before the rebalance
    /// @param navROrZero ROOK's NAV before the rebalance or zero if the NAV is negative
    /// @param newSplitRatio The new split ratio after this rebalance
    /// @return The rebalance matrix
    function _calculateRebalance(
        uint256 navSum,
        uint256 navB,
        uint256 navROrZero,
        uint256 newSplitRatio
    ) private view returns (Rebalance memory) {
        uint256 ratioBR;
        uint256 ratioB2Q;
        uint256 ratioR2Q;
        if (navROrZero <= navB) {
            // Lower rebalance
            ratioBR = navROrZero;
            ratioB2Q = (navSum / 2 - navROrZero).divideDecimal(newSplitRatio);
            ratioR2Q = 0;
        } else {
            // Upper rebalance
            ratioBR = UNIT;
            ratioB2Q = (navB - UNIT).divideDecimal(newSplitRatio) / 2;
            ratioR2Q = (navROrZero - UNIT).divideDecimal(newSplitRatio) / 2;
        }
        return
            Rebalance({
                ratioB2Q: ratioB2Q,
                ratioR2Q: ratioR2Q,
                ratioBR: ratioBR,
                timestamp: block.timestamp
            });
    }

    function _updateInterestRate(uint256 day) private returns (uint256) {
        uint256 baseInterestRate = MAX_INTEREST_RATE.min(aprOracle.capture());
        uint256 floatingInterestRate = ballot.count(day).div(365);
        uint256 rate = baseInterestRate.add(floatingInterestRate);

        emit InterestRateUpdated(baseInterestRate, floatingInterestRate);

        return rate;
    }

    function _updateTotalDebt(uint256 newTotalDebt) private {
        _totalDebt = newTotalDebt;
        emit TotalDebtUpdated(newTotalDebt);
    }

    /// @dev Transform share balance to a given rebalance version, or to the latest version
    ///      if `targetVersion` is zero. This function does no bound check on `targetVersion`.
    /// @param account Account of the balance to rebalance
    /// @param targetVersion The target rebalance version, or zero for the latest version
    function _refreshBalance(address account, uint256 targetVersion) private {
        if (targetVersion == 0) {
            targetVersion = _rebalanceSize;
        }
        uint256 oldVersion = _balanceVersions[account];
        if (oldVersion >= targetVersion) {
            return;
        }

        uint256[TRANCHE_COUNT] storage balanceTuple = _balances[account];
        uint256 balanceQ = balanceTuple[TRANCHE_Q];
        uint256 balanceB = balanceTuple[TRANCHE_B];
        uint256 balanceR = balanceTuple[TRANCHE_R];
        _balanceVersions[account] = targetVersion;

        if (balanceB == 0 && balanceR == 0) {
            // Fast path for zero BISHOP and ROOK balance
            return;
        }

        for (uint256 i = oldVersion; i < targetVersion; i++) {
            (balanceQ, balanceB, balanceR) = doRebalance(balanceQ, balanceB, balanceR, i);
        }
        balanceTuple[TRANCHE_Q] = balanceQ;
        balanceTuple[TRANCHE_B] = balanceB;
        balanceTuple[TRANCHE_R] = balanceR;

        emit BalancesRebalanced(account, targetVersion, balanceQ, balanceB, balanceR);
    }

    /// @dev Transform allowance to a given rebalance version, or to the latest version
    ///      if `targetVersion` is zero. This function does no bound check on `targetVersion`.
    /// @param owner Owner of the allowance to rebalance
    /// @param spender Spender of the allowance to rebalance
    /// @param targetVersion The target rebalance version, or zero for the latest version
    function _refreshAllowance(
        address owner,
        address spender,
        uint256 targetVersion
    ) private {
        if (targetVersion == 0) {
            targetVersion = _rebalanceSize;
        }
        uint256 oldVersion = _allowanceVersions[owner][spender];
        if (oldVersion >= targetVersion) {
            return;
        }

        uint256[TRANCHE_COUNT] storage allowanceTuple = _allowances[owner][spender];
        uint256 allowanceB = allowanceTuple[TRANCHE_B];
        uint256 allowanceR = allowanceTuple[TRANCHE_R];
        _allowanceVersions[owner][spender] = targetVersion;

        if (allowanceB == 0 && allowanceR == 0) {
            // Fast path for empty BISHOP and ROOK allowance
            return;
        }

        for (uint256 i = oldVersion; i < targetVersion; i++) {
            allowanceB = _rebalanceAllowanceBR(allowanceB, i);
            allowanceR = _rebalanceAllowanceBR(allowanceR, i);
        }
        allowanceTuple[TRANCHE_B] = allowanceB;
        allowanceTuple[TRANCHE_R] = allowanceR;

        emit AllowancesRebalanced(
            owner,
            spender,
            targetVersion,
            allowanceTuple[TRANCHE_Q],
            allowanceB,
            allowanceR
        );
    }

    function _rebalanceAllowanceBR(uint256 allowance, uint256 index)
        private
        view
        returns (uint256)
    {
        Rebalance storage rebalance = _rebalances[index];
        /// @dev using saturating arithmetic to avoid unconscious overflow revert
        return allowance.saturatingMultiplyDecimal(rebalance.ratioBR);
    }

    modifier onlyCurrentVersion(uint256 version) {
        require(_rebalanceSize == version, "Only current version");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "./IFundV3.sol";

interface IFundV4 is IFundV3 {
    function getRelativeIncome(uint256 day)
        external
        view
        returns (uint256 incomeOverQ, uint256 incomeOverB);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

interface IFundForPrimaryMarketV4 {
    function primaryMarketMint(
        uint256 tranche,
        address account,
        uint256 amount,
        uint256 version
    ) external;

    function primaryMarketBurn(
        uint256 tranche,
        address account,
        uint256 amount,
        uint256 version
    ) external;

    function primaryMarketTransferUnderlying(
        address recipient,
        uint256 amount,
        uint256 feeQ
    ) external;

    function primaryMarketAddDebtAndFee(uint256 amount, uint256 feeQ) external;

    function primaryMarketPayDebt(uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./VotingEscrowCheckpoint.sol";
import "../utils/CoreUtility.sol";
import "../utils/SafeDecimalMath.sol";

import "../interfaces/IBallot.sol";
import "../interfaces/IFundV4.sol";
import "../interfaces/ITwapOracleV2.sol";
import "../interfaces/IVotingEscrow.sol";

contract InterestRateBallotV3 is IBallot, CoreUtility, VotingEscrowCheckpoint {
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;

    event Voted(
        address indexed account,
        uint256 oldAmount,
        uint256 oldUnlockTime,
        uint256 oldWeight,
        uint256 amount,
        uint256 indexed unlockTime,
        uint256 indexed weight
    );

    IVotingEscrow public immutable votingEscrow;

    mapping(address => Voter) public voters;

    // unlockTime => amount that will be unlocked at unlockTime
    mapping(uint256 => uint256) public scheduledUnlock;
    mapping(uint256 => uint256) public veSupplyPerWeek;
    uint256 public totalLocked;
    uint256 public nextWeekSupply;

    mapping(uint256 => uint256) public weightedScheduledUnlock;
    mapping(uint256 => uint256) public weightedVeSupplyPerWeek;
    uint256 public weightedTotalLocked;
    uint256 public weightedNextWeekSupply;

    uint256 public checkpointWeek;

    constructor(address votingEscrow_)
        public
        VotingEscrowCheckpoint(IVotingEscrow(votingEscrow_).maxTime())
    {
        votingEscrow = IVotingEscrow(votingEscrow_);
        checkpointWeek = _endOfWeek(block.timestamp) - 1 weeks;
    }

    function getReceipt(address account) external view returns (Voter memory) {
        return voters[account];
    }

    function totalSupplyAtWeek(uint256 week) external view returns (uint256) {
        return _totalSupplyAtWeek(week);
    }

    function weightedTotalSupplyAtWeek(uint256 week) external view returns (uint256) {
        return _weightedTotalSupplyAtWeek(week);
    }

    function averageAtWeek(uint256 week) external view returns (uint256) {
        return _averageAtWeek(week);
    }

    /// @notice Return a fund's relative income since the last settlement. Note that denominators
    ///         of the returned ratios are the latest value instead of that at the last settlement.
    ///         If the amount of underlying token increases from 100 to 110 and assume that there's
    ///         no creation/redemption or underlying price change, return value `incomeOverQ` will
    ///         be 1/11 rather than 1/10.
    /// @param fund Address of the fund
    /// @param day End timestamp of a trading day
    /// @return incomeOverQ The ratio of income to the fund's total value
    /// @return incomeOverB The ratio of income to equivalent BISHOP total value if all QUEEN are split
    function getFundRelativeIncome(address fund, uint256 day)
        public
        view
        returns (uint256 incomeOverQ, uint256 incomeOverB)
    {
        (bool success, bytes memory encodedDay) =
            address(fund).staticcall(
                abi.encodeWithSelector(IFundV4.getRelativeIncome.selector, day)
            );
        if (!success || encodedDay.length != 0x40) {
            return (0, 0);
        } else {
            return abi.decode(encodedDay, (uint256, uint256));
        }
    }

    /// @notice Return the fraction of annualized relative income of the calling fund that should
    ///         be added to BISHOP NAV. Zero is returned when this function is not called by
    ///         an `IFundV3` contract or the fund is just rebalanced in the same block.
    function count(uint256 timestamp) external view override returns (uint256) {
        (, uint256 incomeOverB) = getFundRelativeIncome(msg.sender, timestamp);
        if (incomeOverB == 0) {
            return 0;
        } else {
            return
                incomeOverB.multiplyDecimal(_averageAtWeek(_endOfWeek(timestamp) - 1 weeks) * 365);
        }
    }

    function cast(uint256 weight) external {
        require(weight <= 1e18, "Invalid weight");

        IVotingEscrow.LockedBalance memory lockedBalance =
            votingEscrow.getLockedBalance(msg.sender);
        Voter memory voter = voters[msg.sender];
        require(
            lockedBalance.amount > 0 && lockedBalance.unlockTime > block.timestamp,
            "No veCHESS"
        );

        _checkpointAndUpdateLock(
            voter.amount,
            voter.unlockTime,
            voter.weight,
            lockedBalance.amount,
            lockedBalance.unlockTime,
            weight
        );

        emit Voted(
            msg.sender,
            voter.amount,
            voter.unlockTime,
            voter.weight,
            lockedBalance.amount,
            lockedBalance.unlockTime,
            weight
        );

        // update voter amount per account
        voters[msg.sender] = Voter({
            amount: lockedBalance.amount,
            unlockTime: lockedBalance.unlockTime,
            weight: weight
        });
    }

    function syncWithVotingEscrow(address account) external override {
        Voter memory voter = voters[account];
        if (voter.amount == 0) {
            return; // The account did not voted before
        }

        IVotingEscrow.LockedBalance memory lockedBalance = votingEscrow.getLockedBalance(account);
        if (lockedBalance.unlockTime <= block.timestamp) {
            return;
        }

        _checkpointAndUpdateLock(
            voter.amount,
            voter.unlockTime,
            voter.weight,
            lockedBalance.amount,
            lockedBalance.unlockTime,
            voter.weight
        );

        emit Voted(
            account,
            voter.amount,
            voter.unlockTime,
            voter.weight,
            lockedBalance.amount,
            lockedBalance.unlockTime,
            voter.weight
        );

        // update voter amount per account
        voters[account].amount = lockedBalance.amount;
        voters[account].unlockTime = lockedBalance.unlockTime;
    }

    function _totalSupplyAtWeek(uint256 week) private view returns (uint256) {
        return
            week <= checkpointWeek
                ? veSupplyPerWeek[week]
                : _veTotalSupplyAtWeek(
                    week,
                    scheduledUnlock,
                    checkpointWeek,
                    nextWeekSupply,
                    totalLocked
                );
    }

    function _weightedTotalSupplyAtWeek(uint256 week) private view returns (uint256) {
        return
            week <= checkpointWeek
                ? weightedVeSupplyPerWeek[week]
                : _veTotalSupplyAtWeek(
                    week,
                    weightedScheduledUnlock,
                    checkpointWeek,
                    weightedNextWeekSupply,
                    weightedTotalLocked
                );
    }

    function _averageAtWeek(uint256 week) private view returns (uint256) {
        uint256 total = _totalSupplyAtWeek(week);
        if (total == 0) {
            return 0.5e18;
        }
        return _weightedTotalSupplyAtWeek(week) / total;
    }

    function _checkpointAndUpdateLock(
        uint256 oldAmount,
        uint256 oldUnlockTime,
        uint256 oldWeight,
        uint256 newAmount,
        uint256 newUnlockTime,
        uint256 newWeight
    ) private {
        uint256 oldCheckpointWeek = checkpointWeek;
        (, uint256 newNextWeekSupply, uint256 newTotalLocked) =
            _veCheckpoint(
                scheduledUnlock,
                oldCheckpointWeek,
                nextWeekSupply,
                totalLocked,
                veSupplyPerWeek
            );
        (nextWeekSupply, totalLocked) = _veUpdateLock(
            newNextWeekSupply,
            newTotalLocked,
            oldAmount,
            oldUnlockTime,
            newAmount,
            newUnlockTime,
            scheduledUnlock
        );
        uint256 newWeightedNextWeekSupply;
        uint256 newWeightedTotalLocked;
        (checkpointWeek, newWeightedNextWeekSupply, newWeightedTotalLocked) = _veCheckpoint(
            weightedScheduledUnlock,
            oldCheckpointWeek,
            weightedNextWeekSupply,
            weightedTotalLocked,
            weightedVeSupplyPerWeek
        );
        (weightedNextWeekSupply, weightedTotalLocked) = _veUpdateLock(
            newWeightedNextWeekSupply,
            newWeightedTotalLocked,
            oldAmount * oldWeight,
            oldUnlockTime,
            newAmount * newWeight,
            newUnlockTime,
            weightedScheduledUnlock
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../utils/CoreUtility.sol";

import "../interfaces/IBallot.sol";
import "../interfaces/IVotingEscrow.sol";

contract InterestRateBallot is IBallot, CoreUtility {
    using SafeMath for uint256;

    event Voted(
        address indexed account,
        uint256 oldAmount,
        uint256 oldUnlockTime,
        uint256 oldWeight,
        uint256 amount,
        uint256 indexed unlockTime,
        uint256 indexed weight
    );

    uint256 private immutable _maxTime;

    uint256 public constant stepSize = 0.02e18;
    uint256 public constant minRange = 0;
    uint256 public constant maxOption = 3;

    IVotingEscrow public immutable votingEscrow;

    mapping(address => Voter) public voters;

    // unlockTime => amount that will be unlocked at unlockTime
    mapping(uint256 => uint256) public scheduledUnlock;
    mapping(uint256 => uint256) public scheduledWeightedUnlock;

    constructor(address votingEscrow_) public {
        votingEscrow = IVotingEscrow(votingEscrow_);
        _maxTime = IVotingEscrow(votingEscrow_).maxTime();
    }

    function getWeight(uint256 index) public pure returns (uint256) {
        uint256 delta = stepSize.mul(index);
        return minRange.add(delta);
    }

    function getReceipt(address account) external view returns (Voter memory) {
        return voters[account];
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balanceOfAtTimestamp(account, block.timestamp);
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupplyAtTimestamp(block.timestamp);
    }

    function balanceOfAtTimestamp(address account, uint256 timestamp)
        external
        view
        returns (uint256)
    {
        return _balanceOfAtTimestamp(account, timestamp);
    }

    function totalSupplyAtTimestamp(uint256 timestamp) external view returns (uint256) {
        return _totalSupplyAtTimestamp(timestamp);
    }

    function sumAtTimestamp(uint256 timestamp) external view returns (uint256) {
        return _sumAtTimestamp(timestamp);
    }

    function count(uint256 timestamp) external view override returns (uint256) {
        return _averageAtTimestamp(timestamp);
    }

    function cast(uint256 option) external {
        require(option < maxOption, "Invalid option");

        IVotingEscrow.LockedBalance memory lockedBalance =
            votingEscrow.getLockedBalance(msg.sender);
        Voter memory voter = voters[msg.sender];
        uint256 weight = getWeight(option);
        require(lockedBalance.amount > 0, "Zero value");

        // update scheduled unlock
        scheduledUnlock[voter.unlockTime] = scheduledUnlock[voter.unlockTime].sub(voter.amount);
        scheduledUnlock[lockedBalance.unlockTime] = scheduledUnlock[lockedBalance.unlockTime].add(
            lockedBalance.amount
        );

        scheduledWeightedUnlock[voter.unlockTime] = scheduledWeightedUnlock[voter.unlockTime].sub(
            voter.amount * voter.weight
        );
        scheduledWeightedUnlock[lockedBalance.unlockTime] = scheduledWeightedUnlock[
            lockedBalance.unlockTime
        ]
            .add(lockedBalance.amount * weight);

        emit Voted(
            msg.sender,
            voter.amount,
            voter.unlockTime,
            voter.weight,
            lockedBalance.amount,
            lockedBalance.unlockTime,
            weight
        );

        // update voter amount per account
        voters[msg.sender] = Voter({
            amount: lockedBalance.amount,
            unlockTime: lockedBalance.unlockTime,
            weight: weight
        });
    }

    function syncWithVotingEscrow(address account) external override {
        Voter memory voter = voters[account];
        if (voter.amount == 0) {
            return; // The account did not voted before
        }

        IVotingEscrow.LockedBalance memory lockedBalance = votingEscrow.getLockedBalance(account);
        if (lockedBalance.unlockTime <= block.timestamp) {
            return;
        }

        // update scheduled unlock
        scheduledUnlock[voter.unlockTime] = scheduledUnlock[voter.unlockTime].sub(voter.amount);
        scheduledUnlock[lockedBalance.unlockTime] = scheduledUnlock[lockedBalance.unlockTime].add(
            lockedBalance.amount
        );

        scheduledWeightedUnlock[voter.unlockTime] = scheduledWeightedUnlock[voter.unlockTime].sub(
            voter.amount * voter.weight
        );
        scheduledWeightedUnlock[lockedBalance.unlockTime] = scheduledWeightedUnlock[
            lockedBalance.unlockTime
        ]
            .add(lockedBalance.amount * voter.weight);

        emit Voted(
            account,
            voter.amount,
            voter.unlockTime,
            voter.weight,
            lockedBalance.amount,
            lockedBalance.unlockTime,
            voter.weight
        );

        // update voter amount per account
        voters[account].amount = lockedBalance.amount;
        voters[account].unlockTime = lockedBalance.unlockTime;
    }

    function _balanceOfAtTimestamp(address account, uint256 timestamp)
        private
        view
        returns (uint256)
    {
        require(timestamp >= block.timestamp, "Must be current or future time");
        Voter memory voter = voters[account];
        if (timestamp > voter.unlockTime) {
            return 0;
        }
        return (voter.amount * (voter.unlockTime - timestamp)) / _maxTime;
    }

    function _totalSupplyAtTimestamp(uint256 timestamp) private view returns (uint256) {
        uint256 total = 0;
        for (
            uint256 weekCursor = _endOfWeek(timestamp);
            weekCursor <= timestamp + _maxTime;
            weekCursor += 1 weeks
        ) {
            total += (scheduledUnlock[weekCursor] * (weekCursor - timestamp)) / _maxTime;
        }

        return total;
    }

    function _sumAtTimestamp(uint256 timestamp) private view returns (uint256) {
        uint256 sum = 0;
        for (
            uint256 weekCursor = _endOfWeek(timestamp);
            weekCursor <= timestamp + _maxTime;
            weekCursor += 1 weeks
        ) {
            sum += (scheduledWeightedUnlock[weekCursor] * (weekCursor - timestamp)) / _maxTime;
        }

        return sum;
    }

    function _averageAtTimestamp(uint256 timestamp) private view returns (uint256) {
        uint256 sum = 0;
        uint256 total = 0;
        for (
            uint256 weekCursor = _endOfWeek(timestamp);
            weekCursor <= timestamp + _maxTime;
            weekCursor += 1 weeks
        ) {
            sum += (scheduledWeightedUnlock[weekCursor] * (weekCursor - timestamp)) / _maxTime;
            total += (scheduledUnlock[weekCursor] * (weekCursor - timestamp)) / _maxTime;
        }

        if (total == 0) {
            return getWeight(maxOption.sub(1) / 2);
        }
        return sum / total;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "../interfaces/IFundV3.sol";
import "../interfaces/IShareV2.sol";

contract ShareV2 is IShareV2 {
    uint8 public constant decimals = 18;
    IFundV3 public immutable fund;
    uint256 public immutable tranche;

    string public name;
    string public symbol;

    constructor(
        string memory name_,
        string memory symbol_,
        address fund_,
        uint256 tranche_
    ) public {
        name = name_;
        symbol = symbol_;
        fund = IFundV3(fund_);
        tranche = tranche_;
    }

    function totalSupply() external view override returns (uint256) {
        return fund.trancheTotalSupply(tranche);
    }

    function balanceOf(address account) external view override returns (uint256) {
        return fund.trancheBalanceOf(tranche, account);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        fund.shareTransfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return fund.trancheAllowance(tranche, owner, spender);
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        fund.shareApprove(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        fund.shareTransferFrom(msg.sender, sender, recipient, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        fund.shareIncreaseAllowance(msg.sender, spender, addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        fund.shareDecreaseAllowance(msg.sender, spender, subtractedValue);
        return true;
    }

    modifier onlyFund() {
        require(msg.sender == address(fund), "Only fund");
        _;
    }

    function fundEmitTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) external override onlyFund {
        emit Transfer(sender, recipient, amount);
    }

    function fundEmitApproval(
        address owner,
        address spender,
        uint256 amount
    ) external override onlyFund {
        emit Approval(owner, spender, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../utils/SafeDecimalMath.sol";

import "../interfaces/IPrimaryMarketV3.sol";
import "../interfaces/IFundV3.sol";
import "../interfaces/IFundForPrimaryMarketV4.sol";
import "../interfaces/ITrancheIndexV2.sol";
import "../interfaces/IWrappedERC20.sol";

contract PrimaryMarketV4 is IPrimaryMarketV3, ReentrancyGuard, ITrancheIndexV2, Ownable {
    event Created(address indexed account, uint256 underlying, uint256 outQ);
    event Redeemed(address indexed account, uint256 inQ, uint256 underlying, uint256 feeQ);
    event Split(address indexed account, uint256 inQ, uint256 outB, uint256 outR);
    event Merged(
        address indexed account,
        uint256 outQ,
        uint256 inB,
        uint256 inR,
        uint256 feeUnderlying
    );
    event RedemptionQueued(address indexed account, uint256 index, uint256 underlying);
    event RedemptionPopped(uint256 count, uint256 newHead, uint256 requiredUnderlying);
    event RedemptionClaimed(address indexed account, uint256 index, uint256 underlying);
    event FundCapUpdated(uint256 newCap);
    event RedemptionFeeRateUpdated(uint256 newRedemptionFeeRate);
    event MergeFeeRateUpdated(uint256 newMergeFeeRate);

    using SafeMath for uint256;
    using SafeDecimalMath for uint256;
    using SafeERC20 for IERC20;

    struct QueuedRedemption {
        address account;
        uint256 underlying;
        uint256 previousPrefixSum;
    }

    uint256 private constant MAX_REDEMPTION_FEE_RATE = 0.01e18;
    uint256 private constant MAX_MERGE_FEE_RATE = 0.01e18;

    address public immutable override fund;
    bool public immutable redemptionFlag;
    IERC20 private immutable _tokenUnderlying;

    uint256 public redemptionFeeRate;
    uint256 public mergeFeeRate;

    /// @notice The upper limit of underlying that the fund can hold. This contract rejects
    ///         creations that may break this limit.
    /// @dev This limit can be bypassed if the fund has multiple primary markets.
    ///
    ///      Set it to uint(-1) to skip the check and save gas.
    uint256 public fundCap;

    /// @notice Queue of redemptions that cannot be claimed yet. Key is a sequential index
    ///         starting from zero. Value is a tuple of user address, redeemed underlying and
    ///         prefix sum before this entry.
    mapping(uint256 => QueuedRedemption) public queuedRedemptions;

    /// @notice Total underlying tokens of claimable queued redemptions.
    uint256 public claimableUnderlying;

    /// @notice Index of the redemption queue head. All redemptions with index smaller than
    ///         this value can be claimed now.
    uint256 public redemptionQueueHead;

    /// @notice Index of the redemption following the last entry of the queue. The next queued
    ///         redemption will be written at this index.
    uint256 public redemptionQueueTail;

    constructor(
        address fund_,
        uint256 redemptionFeeRate_,
        uint256 mergeFeeRate_,
        uint256 fundCap_,
        bool redemptionFlag_
    ) public Ownable() {
        fund = fund_;
        _tokenUnderlying = IERC20(IFundV3(fund_).tokenUnderlying());
        _updateRedemptionFeeRate(redemptionFeeRate_);
        _updateMergeFeeRate(mergeFeeRate_);
        _updateFundCap(fundCap_);
        redemptionFlag = redemptionFlag_;
    }

    /// @notice Calculate the result of a creation.
    /// @param underlying Underlying amount spent for the creation
    /// @return outQ Created QUEEN amount
    function getCreation(uint256 underlying) public view override returns (uint256 outQ) {
        uint256 fundUnderlying = IFundV3(fund).getTotalUnderlying();
        uint256 fundEquivalentTotalQ = IFundV3(fund).getEquivalentTotalQ();
        require(fundUnderlying.add(underlying) <= fundCap, "Exceed fund cap");
        if (fundEquivalentTotalQ == 0) {
            outQ = underlying.mul(IFundV3(fund).underlyingDecimalMultiplier());
            uint256 splitRatio = IFundV3(fund).splitRatio();
            require(splitRatio != 0, "Fund is not initialized");
            uint256 settledDay = IFundV3(fund).currentDay() - 1 days;
            uint256 underlyingPrice = IFundV3(fund).twapOracle().getTwap(settledDay);
            (uint256 navB, uint256 navR) = IFundV3(fund).historicalNavs(settledDay);
            outQ = outQ.mul(underlyingPrice).div(splitRatio).divideDecimal(navB.add(navR));
        } else {
            require(
                fundUnderlying != 0,
                "Cannot create QUEEN for fund with shares but no underlying"
            );
            outQ = underlying.mul(fundEquivalentTotalQ).div(fundUnderlying);
        }
    }

    /// @notice Calculate the amount of underlying tokens to create at least the given QUEEN amount.
    ///         This only works with non-empty fund for simplicity.
    /// @param minOutQ Minimum received QUEEN amount
    /// @return underlying Underlying amount that should be used for creation
    function getCreationForQ(uint256 minOutQ) external view override returns (uint256 underlying) {
        // Assume:
        //   minOutQ * fundUnderlying = a * fundEquivalentTotalQ - b
        // where a and b are integers and 0 <= b < fundEquivalentTotalQ
        // Then
        //   underlying = a
        //   getCreation(underlying)
        //     = floor(a * fundEquivalentTotalQ / fundUnderlying)
        //    >= floor((a * fundEquivalentTotalQ - b) / fundUnderlying)
        //     = minOutQ
        //   getCreation(underlying - 1)
        //     = floor((a * fundEquivalentTotalQ - fundEquivalentTotalQ) / fundUnderlying)
        //     < (a * fundEquivalentTotalQ - b) / fundUnderlying
        //     = minOutQ
        uint256 fundUnderlying = IFundV3(fund).getTotalUnderlying();
        uint256 fundEquivalentTotalQ = IFundV3(fund).getEquivalentTotalQ();
        require(fundEquivalentTotalQ > 0, "Cannot calculate creation for empty fund");
        return minOutQ.mul(fundUnderlying).add(fundEquivalentTotalQ - 1).div(fundEquivalentTotalQ);
    }

    function _getRedemption(uint256 inQ) private view returns (uint256 underlying) {
        uint256 fundUnderlying = IFundV3(fund).getTotalUnderlying();
        uint256 fundEquivalentTotalQ = IFundV3(fund).getEquivalentTotalQ();
        underlying = inQ.mul(fundUnderlying).div(fundEquivalentTotalQ);
    }

    /// @notice Calculate the result of a redemption.
    /// @param inQ QUEEN amount spent for the redemption
    /// @return underlying Redeemed underlying amount
    /// @return feeQ QUEEN amount charged as redemption fee
    function getRedemption(uint256 inQ)
        public
        view
        override
        returns (uint256 underlying, uint256 feeQ)
    {
        feeQ = inQ.multiplyDecimal(redemptionFeeRate);
        underlying = _getRedemption(inQ - feeQ);
    }

    /// @notice Calculate the amount of QUEEN that can be redeemed for at least the given amount
    ///         of underlying tokens.
    /// @dev The return value may not be the minimum solution due to rounding errors.
    /// @param minUnderlying Minimum received underlying amount
    /// @return inQ QUEEN amount that should be redeemed
    function getRedemptionForUnderlying(uint256 minUnderlying)
        external
        view
        override
        returns (uint256 inQ)
    {
        // Assume:
        //   minUnderlying * fundEquivalentTotalQ = a * fundUnderlying - b
        //   a * 1e18 = c * (1e18 - redemptionFeeRate) + d
        // where
        //   a, b, c, d are integers
        //   0 <= b < fundUnderlying
        //   0 <= d < 1e18 - redemeptionFeeRate
        // Then
        //   inQAfterFee = a
        //   inQ = c
        //   getRedemption(inQ).underlying
        //     = floor((c - floor(c * redemptionFeeRate / 1e18)) * fundUnderlying / fundEquivalentTotalQ)
        //     = floor(ceil(c * (1e18 - redemptionFeeRate) / 1e18) * fundUnderlying / fundEquivalentTotalQ)
        //     = floor(((c * (1e18 - redemptionFeeRate) + d) / 1e18) * fundUnderlying / fundEquivalentTotalQ)
        //     = floor(a * fundUnderlying / fundEquivalentTotalQ)
        //     => floor((a * fundUnderlying - b) / fundEquivalentTotalQ)
        //     = minUnderlying
        uint256 fundUnderlying = IFundV3(fund).getTotalUnderlying();
        uint256 fundEquivalentTotalQ = IFundV3(fund).getEquivalentTotalQ();
        uint256 inQAfterFee =
            minUnderlying.mul(fundEquivalentTotalQ).add(fundUnderlying - 1).div(fundUnderlying);
        return inQAfterFee.divideDecimal(1e18 - redemptionFeeRate);
    }

    /// @notice Calculate the result of a split.
    /// @param inQ QUEEN amount to be split
    /// @return outB Received BISHOP amount, which is also received ROOK amount
    function getSplit(uint256 inQ) public view override returns (uint256 outB) {
        return inQ.multiplyDecimal(IFundV3(fund).splitRatio());
    }

    /// @notice Calculate the amount of QUEEN that can be split into at least the given amount of
    ///         BISHOP and ROOK.
    /// @param minOutB Received BISHOP amount, which is also received ROOK amount
    /// @return inQ QUEEN amount that should be split
    function getSplitForB(uint256 minOutB) external view override returns (uint256 inQ) {
        uint256 splitRatio = IFundV3(fund).splitRatio();
        return minOutB.mul(1e18).add(splitRatio.sub(1)).div(splitRatio);
    }

    /// @notice Calculate the result of a merge.
    /// @param inB Spent BISHOP amount, which is also spent ROOK amount
    /// @return outQ Received QUEEN amount
    /// @return feeQ QUEEN amount charged as merge fee
    function getMerge(uint256 inB) public view override returns (uint256 outQ, uint256 feeQ) {
        uint256 outQBeforeFee = inB.divideDecimal(IFundV3(fund).splitRatio());
        feeQ = outQBeforeFee.multiplyDecimal(mergeFeeRate);
        outQ = outQBeforeFee.sub(feeQ);
    }

    /// @notice Calculate the amount of BISHOP and ROOK that can be merged into at least
    ///      the given amount of QUEEN.
    /// @dev The return value may not be the minimum solution due to rounding errors.
    /// @param minOutQ Minimum received QUEEN amount
    /// @return inB BISHOP amount that should be merged, which is also spent ROOK amount
    function getMergeForQ(uint256 minOutQ) external view override returns (uint256 inB) {
        // Assume:
        //   minOutQ * 1e18 = a * (1e18 - mergeFeeRate) + b
        //   c = ceil(a * splitRatio / 1e18)
        // where a and b are integers and 0 <= b < 1e18 - mergeFeeRate
        // Then
        //   outQBeforeFee = a
        //   inB = c
        //   getMerge(inB).outQ
        //     = c * 1e18 / splitRatio - floor(c * 1e18 / splitRatio * mergeFeeRate / 1e18)
        //     = ceil(c * 1e18 / splitRatio * (1e18 - mergeFeeRate) / 1e18)
        //    >= ceil(a * (1e18 - mergeFeeRate) / 1e18)
        //     = (a * (1e18 - mergeFeeRate) + b) / 1e18         // because b < 1e18
        //     = minOutQ
        uint256 outQBeforeFee = minOutQ.divideDecimal(1e18 - mergeFeeRate);
        inB = outQBeforeFee.mul(IFundV3(fund).splitRatio()).add(1e18 - 1).div(1e18);
    }

    /// @notice Return index of the first queued redemption that cannot be claimed now.
    ///         Users can use this function to determine which indices can be passed to
    ///         `claimRedemptions()`.
    /// @return Index of the first redemption that cannot be claimed now
    function getNewRedemptionQueueHead() external view returns (uint256) {
        uint256 available = _tokenUnderlying.balanceOf(fund);
        uint256 l = redemptionQueueHead;
        uint256 r = redemptionQueueTail;
        uint256 startPrefixSum = queuedRedemptions[l].previousPrefixSum;
        // overflow is desired
        if (queuedRedemptions[r].previousPrefixSum - startPrefixSum <= available) {
            return r;
        }
        // Iteration count is bounded by log2(tail - head), which is at most 256.
        while (l + 1 < r) {
            uint256 m = (l + r) / 2;
            if (queuedRedemptions[m].previousPrefixSum - startPrefixSum <= available) {
                l = m;
            } else {
                r = m;
            }
        }
        return l;
    }

    /// @notice Search in the redemption queue.
    /// @param account Owner of the redemptions, or zero address to return all redemptions
    /// @param startIndex Redemption index where the search starts, or zero to start from the head
    /// @param maxIterationCount Maximum number of redemptions to be scanned, or zero for no limit
    /// @return indices Indices of found redemptions
    /// @return underlying Total underlying of found redemptions
    function getQueuedRedemptions(
        address account,
        uint256 startIndex,
        uint256 maxIterationCount
    ) external view returns (uint256[] memory indices, uint256 underlying) {
        uint256 head = redemptionQueueHead;
        uint256 tail = redemptionQueueTail;
        if (startIndex == 0) {
            startIndex = head;
        } else {
            require(startIndex >= head && startIndex <= tail, "startIndex out of bound");
        }
        uint256 endIndex = tail;
        if (maxIterationCount != 0 && tail - startIndex > maxIterationCount) {
            endIndex = startIndex + maxIterationCount;
        }
        indices = new uint256[](endIndex - startIndex);
        uint256 count = 0;
        for (uint256 i = startIndex; i < endIndex; i++) {
            if (account == address(0) || queuedRedemptions[i].account == account) {
                indices[count] = i;
                underlying += queuedRedemptions[i].underlying;
                count++;
            }
        }
        if (count != endIndex - startIndex) {
            // Shrink the array
            assembly {
                mstore(indices, count)
            }
        }
    }

    /// @notice Return whether the fund can change its primary market to another contract.
    function canBeRemovedFromFund() external view override returns (bool) {
        return redemptionQueueHead == redemptionQueueTail;
    }

    /// @notice Create QUEEN using underlying tokens. This function should be called by
    ///         a smart contract, which transfers underlying tokens to this contract
    ///         in the same transaction.
    /// @param recipient Address that will receive created QUEEN
    /// @param minOutQ Minimum QUEEN amount to be received
    /// @param version The latest rebalance version
    /// @return outQ Received QUEEN amount
    function create(
        address recipient,
        uint256 minOutQ,
        uint256 version
    ) external override nonReentrant returns (uint256 outQ) {
        uint256 underlying = _tokenUnderlying.balanceOf(address(this)).sub(claimableUnderlying);
        outQ = getCreation(underlying);
        require(outQ >= minOutQ && outQ > 0, "Min QUEEN created");
        IFundForPrimaryMarketV4(fund).primaryMarketMint(TRANCHE_Q, recipient, outQ, version);
        _tokenUnderlying.safeTransfer(fund, underlying);
        emit Created(recipient, underlying, outQ);

        // Call an optional hook in the strategy and ignore errors.
        (bool success, ) =
            IFundV3(fund).strategy().call(abi.encodeWithSignature("onPrimaryMarketCreate()"));
        if (!success) {
            // ignore
        }
    }

    /// @notice Redeem QUEEN to get underlying tokens back. Revert if there are still some
    ///         queued redemptions that cannot be claimed now.
    /// @param recipient Address that will receive redeemed underlying tokens
    /// @param inQ Spent QUEEN amount
    /// @param minUnderlying Minimum amount of underlying tokens to be received
    /// @param version The latest rebalance version
    /// @return underlying Received underlying amount
    function redeem(
        address recipient,
        uint256 inQ,
        uint256 minUnderlying,
        uint256 version
    ) external override nonReentrant returns (uint256 underlying) {
        underlying = _redeem(recipient, inQ, minUnderlying, version);
    }

    /// @notice Redeem QUEEN to get native currency back. The underlying must be wrapped token
    ///         of the native currency. Revert if there are still some queued redemptions that
    ///         cannot be claimed now.
    /// @param recipient Address that will receive redeemed underlying tokens
    /// @param inQ Spent QUEEN amount
    /// @param minUnderlying Minimum amount of underlying tokens to be received
    /// @param version The latest rebalance version
    /// @return underlying Received underlying amount
    function redeemAndUnwrap(
        address recipient,
        uint256 inQ,
        uint256 minUnderlying,
        uint256 version
    ) external override nonReentrant returns (uint256 underlying) {
        underlying = _redeem(address(this), inQ, minUnderlying, version);
        IWrappedERC20(address(_tokenUnderlying)).withdraw(underlying);
        (bool success, ) = recipient.call{value: underlying}("");
        require(success, "Transfer failed");
    }

    function _redeem(
        address recipient,
        uint256 inQ,
        uint256 minUnderlying,
        uint256 version
    ) private allowRedemption returns (uint256 underlying) {
        uint256 feeQ;
        (underlying, feeQ) = getRedemption(inQ);
        IFundForPrimaryMarketV4(fund).primaryMarketBurn(TRANCHE_Q, msg.sender, inQ, version);
        _popRedemptionQueue(0);
        require(underlying >= minUnderlying && underlying > 0, "Min underlying redeemed");
        // Redundant check for user-friendly revert message.
        require(underlying <= _tokenUnderlying.balanceOf(fund), "Not enough underlying in fund");
        IFundForPrimaryMarketV4(fund).primaryMarketTransferUnderlying(recipient, underlying, feeQ);
        emit Redeemed(recipient, inQ, underlying, feeQ);

        // Call an optional hook in the strategy and ignore errors.
        (bool success, ) =
            IFundV3(fund).strategy().call(abi.encodeWithSignature("onPrimaryMarketRedeem()"));
        if (!success) {
            // ignore
        }
    }

    /// @notice Redeem QUEEN and wait in the redemption queue. Redeemed underlying tokens will
    ///         be claimable when the fund has enough balance to pay this redemption and all
    ///         previous ones in the queue.
    /// @param recipient Address that will receive redeemed underlying tokens
    /// @param inQ Spent QUEEN amount
    /// @param minUnderlying Minimum amount of underlying tokens to be received
    /// @param version The latest rebalance version
    /// @return underlying Received underlying amount
    /// @return index Index of the queued redemption
    function queueRedemption(
        address recipient,
        uint256 inQ,
        uint256 minUnderlying,
        uint256 version
    ) external override nonReentrant allowRedemption returns (uint256 underlying, uint256 index) {
        uint256 feeQ;
        (underlying, feeQ) = getRedemption(inQ);
        IFundForPrimaryMarketV4(fund).primaryMarketBurn(TRANCHE_Q, msg.sender, inQ, version);
        require(underlying >= minUnderlying && underlying > 0, "Min underlying redeemed");
        index = redemptionQueueTail;
        QueuedRedemption storage newRedemption = queuedRedemptions[index];
        newRedemption.account = recipient;
        newRedemption.underlying = underlying;
        // overflow is desired
        queuedRedemptions[index + 1].previousPrefixSum =
            newRedemption.previousPrefixSum +
            underlying;
        redemptionQueueTail = index + 1;
        IFundForPrimaryMarketV4(fund).primaryMarketAddDebtAndFee(underlying, feeQ);
        emit Redeemed(recipient, inQ, underlying, feeQ);
        emit RedemptionQueued(recipient, index, underlying);
    }

    /// @notice Remove a given number of redemptions from the front of the redemption queue and
    ///         fetch underlying tokens of these redemptions from the fund. Revert if the fund
    ///         cannot pay these redemptions now.
    /// @param count The number of redemptions to be removed, or zero to completely empty the queue
    function popRedemptionQueue(uint256 count) external nonReentrant {
        _popRedemptionQueue(count);
    }

    function _popRedemptionQueue(uint256 count) private {
        uint256 oldHead = redemptionQueueHead;
        uint256 oldTail = redemptionQueueTail;
        uint256 newHead;
        if (count == 0) {
            if (oldHead == oldTail) {
                return;
            }
            newHead = oldTail;
        } else {
            newHead = oldHead.add(count);
            require(newHead <= oldTail, "Redemption queue out of bound");
        }
        // overflow is desired
        uint256 requiredUnderlying =
            queuedRedemptions[newHead].previousPrefixSum -
                queuedRedemptions[oldHead].previousPrefixSum;
        // Redundant check for user-friendly revert message.
        require(
            requiredUnderlying <= _tokenUnderlying.balanceOf(fund),
            "Not enough underlying in fund"
        );
        claimableUnderlying = claimableUnderlying.add(requiredUnderlying);
        IFundForPrimaryMarketV4(fund).primaryMarketPayDebt(requiredUnderlying);
        redemptionQueueHead = newHead;
        emit RedemptionPopped(newHead - oldHead, newHead, requiredUnderlying);
    }

    /// @notice Claim underlying tokens of queued redemptions. All these redemptions must
    ///         belong to the same account.
    /// @param account Recipient of the redemptions
    /// @param indices Indices of the redemptions in the queue, which must be in increasing order
    /// @return underlying Total claimed underlying amount
    function claimRedemptions(address account, uint256[] calldata indices)
        external
        override
        nonReentrant
        returns (uint256 underlying)
    {
        underlying = _claimRedemptions(account, indices);
        _tokenUnderlying.safeTransfer(account, underlying);
    }

    /// @notice Claim native currency of queued redemptions. The underlying must be wrapped token
    ///         of the native currency. All these redemptions must belong to the same account.
    /// @param account Recipient of the redemptions
    /// @param indices Indices of the redemptions in the queue, which must be in increasing order
    /// @return underlying Total claimed underlying amount
    function claimRedemptionsAndUnwrap(address account, uint256[] calldata indices)
        external
        override
        nonReentrant
        returns (uint256 underlying)
    {
        underlying = _claimRedemptions(account, indices);
        IWrappedERC20(address(_tokenUnderlying)).withdraw(underlying);
        (bool success, ) = account.call{value: underlying}("");
        require(success, "Transfer failed");
    }

    function _claimRedemptions(address account, uint256[] calldata indices)
        private
        returns (uint256 underlying)
    {
        uint256 count = indices.length;
        if (count == 0) {
            return 0;
        }
        uint256 head = redemptionQueueHead;
        if (indices[count - 1] >= head) {
            _popRedemptionQueue(indices[count - 1] - head + 1);
        }
        for (uint256 i = 0; i < count; i++) {
            require(i == 0 || indices[i] > indices[i - 1], "Indices out of order");
            QueuedRedemption storage redemption = queuedRedemptions[indices[i]];
            uint256 redemptionUnderlying = redemption.underlying;
            require(
                redemption.account == account && redemptionUnderlying != 0,
                "Invalid redemption index"
            );
            underlying = underlying.add(redemptionUnderlying);
            emit RedemptionClaimed(account, indices[i], redemptionUnderlying);
            delete queuedRedemptions[indices[i]];
        }
        claimableUnderlying = claimableUnderlying.sub(underlying);
    }

    function split(
        address recipient,
        uint256 inQ,
        uint256 version
    ) external override returns (uint256 outB) {
        outB = getSplit(inQ);
        IFundForPrimaryMarketV4(fund).primaryMarketBurn(TRANCHE_Q, msg.sender, inQ, version);
        IFundForPrimaryMarketV4(fund).primaryMarketMint(TRANCHE_B, recipient, outB, version);
        IFundForPrimaryMarketV4(fund).primaryMarketMint(TRANCHE_R, recipient, outB, version);
        emit Split(recipient, inQ, outB, outB);
    }

    function merge(
        address recipient,
        uint256 inB,
        uint256 version
    ) external override returns (uint256 outQ) {
        uint256 feeQ;
        (outQ, feeQ) = getMerge(inB);
        IFundForPrimaryMarketV4(fund).primaryMarketBurn(TRANCHE_B, msg.sender, inB, version);
        IFundForPrimaryMarketV4(fund).primaryMarketBurn(TRANCHE_R, msg.sender, inB, version);
        IFundForPrimaryMarketV4(fund).primaryMarketMint(TRANCHE_Q, recipient, outQ, version);
        IFundForPrimaryMarketV4(fund).primaryMarketAddDebtAndFee(0, feeQ);
        emit Merged(recipient, outQ, inB, inB, feeQ);
    }

    /// @dev Nothing to do for daily fund settlement.
    function settle(uint256 day) external override onlyFund {}

    function _updateFundCap(uint256 newCap) private {
        fundCap = newCap;
        emit FundCapUpdated(newCap);
    }

    function updateFundCap(uint256 newCap) external onlyOwner {
        _updateFundCap(newCap);
    }

    function _updateRedemptionFeeRate(uint256 newRedemptionFeeRate) private {
        require(newRedemptionFeeRate <= MAX_REDEMPTION_FEE_RATE, "Exceed max redemption fee rate");
        redemptionFeeRate = newRedemptionFeeRate;
        emit RedemptionFeeRateUpdated(newRedemptionFeeRate);
    }

    function updateRedemptionFeeRate(uint256 newRedemptionFeeRate) external onlyOwner {
        _updateRedemptionFeeRate(newRedemptionFeeRate);
    }

    function _updateMergeFeeRate(uint256 newMergeFeeRate) private {
        require(newMergeFeeRate <= MAX_MERGE_FEE_RATE, "Exceed max merge fee rate");
        mergeFeeRate = newMergeFeeRate;
        emit MergeFeeRateUpdated(newMergeFeeRate);
    }

    function updateMergeFeeRate(uint256 newMergeFeeRate) external onlyOwner {
        _updateMergeFeeRate(newMergeFeeRate);
    }

    /// @notice Receive unwrapped transfer from the wrapped token.
    receive() external payable {}

    modifier onlyFund() {
        require(msg.sender == fund, "Only fund");
        _;
    }

    modifier allowRedemption() {
        require(redemptionFlag, "Redemption N/A");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

import "../interfaces/IPrimaryMarketV3.sol";
import "../interfaces/ITrancheIndexV2.sol";
import "./StableSwapV2.sol";

contract BishopStableSwapV2 is StableSwapV2, ITrancheIndexV2 {
    event Rebalanced(uint256 base, uint256 quote, uint256 version);

    uint256 public immutable tradingCurbThreshold;

    uint256 public currentVersion;

    constructor(
        address lpToken_,
        address fund_,
        address quoteAddress_,
        uint256 quoteDecimals_,
        uint256 ampl_,
        address feeCollector_,
        uint256 feeRate_,
        uint256 adminFeeRate_,
        uint256 tradingCurbThreshold_
    )
        public
        StableSwapV2(
            lpToken_,
            fund_,
            TRANCHE_B,
            quoteAddress_,
            quoteDecimals_,
            ampl_,
            feeCollector_,
            feeRate_,
            adminFeeRate_
        )
    {
        tradingCurbThreshold = tradingCurbThreshold_;
        currentVersion = IFundV3(fund_).getRebalanceSize();
    }

    /// @dev Make sure the user-specified version is the latest rebalance version.
    function _checkVersion(uint256 version) internal view override {
        require(version == fund.getRebalanceSize(), "Obsolete rebalance version");
    }

    function _getRebalanceResult(uint256 latestVersion)
        internal
        view
        override
        returns (
            uint256 newBase,
            uint256 newQuote,
            uint256 excessiveQ,
            uint256 excessiveB,
            uint256 excessiveR,
            uint256 excessiveQuote,
            bool isRebalanced
        )
    {
        if (latestVersion == currentVersion) {
            return (baseBalance, quoteBalance, 0, 0, 0, 0, false);
        }
        isRebalanced = true;

        uint256 oldBaseBalance = baseBalance;
        uint256 oldQuoteBalance = quoteBalance;
        (excessiveQ, newBase, ) = fund.batchRebalance(
            0,
            oldBaseBalance,
            0,
            currentVersion,
            latestVersion
        );
        if (newBase < oldBaseBalance) {
            // We split all QUEEN from rebalance if the amount of BISHOP is smaller than before.
            // In almost all cases, the total amount of BISHOP after the split is still smaller
            // than before.
            excessiveR = IPrimaryMarketV3(fund.primaryMarket()).getSplit(excessiveQ);
            newBase = newBase.add(excessiveR);
        }
        if (newBase < oldBaseBalance) {
            // If BISHOP amount is still smaller than before, we remove quote tokens proportionally.
            newQuote = oldQuoteBalance.mul(newBase).div(oldBaseBalance);
            excessiveQuote = oldQuoteBalance - newQuote;
        } else {
            // In most cases when we reach here, the BISHOP amount remains the same (ratioBR = 1).
            newQuote = oldQuoteBalance;
            excessiveB = newBase - oldBaseBalance;
            newBase = oldBaseBalance;
        }
    }

    function _handleRebalance(uint256 latestVersion)
        internal
        override
        returns (uint256 newBase, uint256 newQuote)
    {
        uint256 excessiveQ;
        uint256 excessiveB;
        uint256 excessiveR;
        uint256 excessiveQuote;
        bool isRebalanced;
        (
            newBase,
            newQuote,
            excessiveQ,
            excessiveB,
            excessiveR,
            excessiveQuote,
            isRebalanced
        ) = _getRebalanceResult(latestVersion);
        if (isRebalanced) {
            baseBalance = newBase;
            quoteBalance = newQuote;
            currentVersion = latestVersion;
            emit Rebalanced(newBase, newQuote, latestVersion);
            if (excessiveQ > 0) {
                if (excessiveR > 0) {
                    IPrimaryMarketV3(fund.primaryMarket()).split(
                        address(this),
                        excessiveQ,
                        latestVersion
                    );
                    excessiveQ = 0;
                } else {
                    fund.trancheTransfer(TRANCHE_Q, lpToken, excessiveQ, latestVersion);
                }
            }
            if (excessiveB > 0) {
                fund.trancheTransfer(TRANCHE_B, lpToken, excessiveB, latestVersion);
            }
            if (excessiveR > 0) {
                fund.trancheTransfer(TRANCHE_R, lpToken, excessiveR, latestVersion);
            }
            if (excessiveQuote > 0) {
                IERC20(quoteAddress).safeTransfer(lpToken, excessiveQuote);
            }
            ILiquidityGauge(lpToken).distribute(
                excessiveQ,
                excessiveB,
                excessiveR,
                excessiveQuote,
                latestVersion
            );
        }
    }

    function getOraclePrice() public view override returns (uint256) {
        uint256 price = fund.twapOracle().getLatest();
        (, uint256 navB, uint256 navR) = fund.extrapolateNav(price);
        require(navR >= navB.multiplyDecimal(tradingCurbThreshold), "Trading curb");
        return navB;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Proxy.sol";
import "../utils/Address.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 *
 * Upgradeability is only provided internally through {_upgradeTo}. For an externally upgradeable proxy see
 * {TransparentUpgradeableProxy}.
 */
contract UpgradeableProxy is Proxy {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) public payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _setImplementation(_logic);
        if(_data.length > 0) {
            Address.functionDelegateCall(_logic, _data);
        }
    }

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @dev Upgrades the proxy to a new implementation.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal virtual {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableProxy: new implementation is not a contract");

        bytes32 slot = _IMPLEMENTATION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newImplementation)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
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
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * bearer except when using {_setupRole}.
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
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
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
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

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
    function renounceRole(bytes32 role, address account) public virtual {
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
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
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
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../interfaces/IStableSwap.sol";
import "../interfaces/ITrancheIndexV2.sol";

/// @dev See IVault.sol under https://github.com/balancer-labs/balancer-v2-monorepo/
interface IBalancerVault {
    enum SwapKind {GIVEN_IN, GIVEN_OUT}

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        address assetIn;
        address assetOut;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address recipient;
        bool toInternalBalance;
    }

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    function WETH() external view returns (address);

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        address[] memory assets,
        FundManagement memory funds
    ) external returns (int256[] memory assetDeltas);
}

contract BalancerV2Router is IStableSwapCoreInternalRevertExpected, ITrancheIndexV2 {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 public constant UP_ROUNDING_FACTOR = 1e10;

    IFundV3 public immutable fund;
    address private immutable _tokenUnderlying;
    address private immutable _tokenQ;
    IBalancerVault public immutable vault;
    bytes32 public immutable poolId;

    constructor(
        address fund_,
        address vault_,
        bytes32 poolId_
    ) public {
        fund = IFundV3(fund_);
        _tokenUnderlying = IFundV3(fund_).tokenUnderlying();
        _tokenQ = IFundV3(fund_).tokenQ();
        vault = IBalancerVault(vault_);
        poolId = poolId_;
    }

    /// @dev Get redemption with StableSwap getQuoteOut interface.
    function getQuoteOut(uint256 baseIn) external override returns (uint256 quoteOut) {
        quoteOut = querySwap(
            IBalancerVault.SingleSwap({
                poolId: poolId,
                kind: IBalancerVault.SwapKind.GIVEN_IN,
                assetIn: _tokenQ,
                assetOut: _tokenUnderlying,
                amount: baseIn,
                userData: ""
            })
        );
    }

    /// @dev Get creation for QUEEN with StableSwap getQuoteIn interface.
    function getQuoteIn(uint256 baseOut) external override returns (uint256 quoteIn) {
        quoteIn = querySwap(
            IBalancerVault.SingleSwap({
                poolId: poolId,
                kind: IBalancerVault.SwapKind.GIVEN_OUT,
                assetIn: _tokenUnderlying,
                assetOut: _tokenQ,
                amount: baseOut,
                userData: ""
            })
        );
        // Round up by (1 + factor)x + 1 in case of rounding errors
        quoteIn = quoteIn.add(quoteIn / UP_ROUNDING_FACTOR).add(1);
    }

    /// @dev Get creation with StableSwap getBaseOut interface.
    function getBaseOut(uint256 quoteIn) external override returns (uint256 baseOut) {
        baseOut = querySwap(
            IBalancerVault.SingleSwap({
                poolId: poolId,
                kind: IBalancerVault.SwapKind.GIVEN_IN,
                assetIn: _tokenUnderlying,
                assetOut: _tokenQ,
                amount: quoteIn,
                userData: ""
            })
        );
    }

    /// @dev Get redemption for underlying with StableSwap getBaseIn interface.
    function getBaseIn(uint256 quoteOut) external override returns (uint256 baseIn) {
        baseIn = querySwap(
            IBalancerVault.SingleSwap({
                poolId: poolId,
                kind: IBalancerVault.SwapKind.GIVEN_OUT,
                assetIn: _tokenQ,
                assetOut: _tokenUnderlying,
                amount: quoteOut,
                userData: ""
            })
        );
        // Round up by (1 + factor)x + 1 in case of rounding errors
        baseIn = baseIn.add(baseIn / UP_ROUNDING_FACTOR).add(1);
    }

    /// @dev Create QUEEN with StableSwap buy interface.
    ///      Underlying should have already been sent to this contract
    function buy(
        uint256,
        uint256 baseOut,
        address recipient,
        bytes calldata
    ) external override returns (uint256 realBaseOut) {
        uint256 routerQuoteBalance = IERC20(_tokenUnderlying).balanceOf(address(this));
        IERC20(_tokenUnderlying).safeApprove(address(vault), routerQuoteBalance);

        IBalancerVault.SingleSwap memory singleSwap =
            IBalancerVault.SingleSwap({
                poolId: poolId,
                kind: IBalancerVault.SwapKind.GIVEN_IN,
                assetIn: _tokenUnderlying,
                assetOut: _tokenQ,
                amount: routerQuoteBalance,
                userData: ""
            });
        IBalancerVault.FundManagement memory funds =
            IBalancerVault.FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: recipient,
                toInternalBalance: false
            });

        realBaseOut = vault.swap(singleSwap, funds, baseOut, block.timestamp);
    }

    /// @dev Redeem QUEEN with StableSwap sell interface.
    ///      QUEEN should have already been sent to this contract
    function sell(
        uint256,
        uint256 quoteOut,
        address recipient,
        bytes calldata
    ) external override returns (uint256 realQuoteOut) {
        uint256 routerBaseBalance = fund.trancheBalanceOf(TRANCHE_Q, address(this));
        fund.trancheApprove(TRANCHE_Q, address(vault), routerBaseBalance, fund.getRebalanceSize());

        IBalancerVault.SingleSwap memory singleSwap =
            IBalancerVault.SingleSwap({
                poolId: poolId,
                kind: IBalancerVault.SwapKind.GIVEN_IN,
                assetIn: _tokenQ,
                assetOut: _tokenUnderlying,
                amount: routerBaseBalance,
                userData: ""
            });
        IBalancerVault.FundManagement memory funds =
            IBalancerVault.FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: recipient,
                toInternalBalance: false
            });

        realQuoteOut = vault.swap(singleSwap, funds, quoteOut, block.timestamp);
    }

    /// @dev See BalancerQueries.sol under https://github.com/balancer-labs/balancer-v2-monorepo/
    function querySwap(IBalancerVault.SingleSwap memory singleSwap) public returns (uint256) {
        // The Vault only supports batch swap queries, so we need to convert the swap call into an equivalent batch
        // swap. The result will be identical.

        // The main difference between swaps and batch swaps is that batch swaps require an assets array. We're going
        // to place the asset in at index 0, and asset out at index 1.
        address[] memory assets = new address[](2);
        assets[0] = singleSwap.assetIn;
        assets[1] = singleSwap.assetOut;

        IBalancerVault.BatchSwapStep[] memory swaps = new IBalancerVault.BatchSwapStep[](1);
        swaps[0] = IBalancerVault.BatchSwapStep({
            poolId: singleSwap.poolId,
            assetInIndex: 0,
            assetOutIndex: 1,
            amount: singleSwap.amount,
            userData: singleSwap.userData
        });

        IBalancerVault.FundManagement memory funds =
            IBalancerVault.FundManagement({
                sender: address(0),
                fromInternalBalance: false,
                recipient: address(0),
                toInternalBalance: false
            });

        int256[] memory assetDeltas = queryBatchSwap(singleSwap.kind, swaps, assets, funds);

        // Batch swaps return the full Vault asset deltas, which in the special case of a single step swap contains more
        // information than we need (as the amount in is known in a GIVEN_IN swap, and the amount out is known in a
        // GIVEN_OUT swap). We extract the information we're interested in.
        if (singleSwap.kind == IBalancerVault.SwapKind.GIVEN_IN) {
            // The asset out will have a negative Vault delta (the assets are coming out of the Pool and the user is
            // receiving them), so make it positive to match the `swap` interface.

            require(assetDeltas[1] <= 0, "SHOULD_NOT_HAPPEN");
            return uint256(-assetDeltas[1]);
        } else {
            // The asset in will have a positive Vault delta (the assets are going into the Pool and the user is
            // sending them), so we don't need to do anything.
            return uint256(assetDeltas[0]);
        }
    }

    function queryBatchSwap(
        IBalancerVault.SwapKind kind,
        IBalancerVault.BatchSwapStep[] memory swaps,
        address[] memory assets,
        IBalancerVault.FundManagement memory funds
    ) public returns (int256[] memory assetDeltas) {
        (, bytes memory returnData) =
            address(vault).call(
                abi.encodeWithSelector(
                    IBalancerVault.queryBatchSwap.selector,
                    kind,
                    swaps,
                    assets,
                    funds
                )
            );
        assetDeltas = abi.decode(returnData, (int256[]));
        require(assetDeltas.length == swaps.length.add(1), "Unexpected length");
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

/// @notice Vests `Chess` tokens for a single address

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract VestingEscrow is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Fund(uint256 amount);
    event Claim(uint256 amount);
    event ToggleDisable(bool disabled);

    address public immutable token;
    address public immutable recipient;
    uint256 public immutable startTime;
    uint256 public immutable endTime;
    bool public canDisable;

    uint256 public initialLocked;
    uint256 public vestedAtStart;
    uint256 public totalClaimed;
    uint256 public disabledAt;

    constructor(
        address token_,
        address recipient_,
        uint256 startTime_,
        uint256 endTime_,
        bool canDisable_
    ) public {
        token = token_;
        recipient = recipient_;
        startTime = startTime_;
        endTime = endTime_;
        canDisable = canDisable_;
    }

    function initialize(uint256 amount, uint256 vestedAtStart_) external {
        require(amount != 0 && amount >= vestedAtStart_, "Invalid amount or vestedAtStart");
        require(initialLocked == 0, "Already initialized");

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        initialLocked = amount;
        vestedAtStart = vestedAtStart_;
        emit Fund(amount);
    }

    /// @notice Get the total number of tokens which have vested, that are held
    ///         by this contract
    function vestedSupply() external view returns (uint256) {
        return _totalVestedOf(block.timestamp);
    }

    /// @notice Get the total number of tokens which are still locked
    ///         (have not yet vested)
    function lockedSupply() external view returns (uint256) {
        return initialLocked.sub(_totalVestedOf(block.timestamp));
    }

    /// @notice Get the number of unclaimed, vested tokens for a given address
    /// @param account address to check
    function balanceOf(address account) external view returns (uint256) {
        if (account != recipient) {
            return 0;
        }
        return _totalVestedOf(block.timestamp).sub(totalClaimed);
    }

    /// @notice Disable or re-enable a vested address's ability to claim tokens
    /// @dev When disabled, the address is only unable to claim tokens which are still
    ///      locked at the time of this call. It is not possible to block the claim
    ///      of tokens which have already vested.
    function toggleDisable() external onlyOwner {
        require(canDisable, "Cannot disable");

        bool isDisabled = disabledAt == 0;
        if (isDisabled) {
            disabledAt = block.timestamp;
        } else {
            disabledAt = 0;
        }

        emit ToggleDisable(isDisabled);
    }

    /// @notice Disable the ability to call `toggleDisable`
    function disableCanDisable() external onlyOwner {
        canDisable = false;
    }

    /// @notice Claim tokens which have vested
    function claim() external {
        uint256 timestamp = disabledAt;
        if (timestamp == 0) {
            timestamp = block.timestamp;
        }
        uint256 claimable = _totalVestedOf(timestamp).sub(totalClaimed);
        totalClaimed = totalClaimed.add(claimable);
        IERC20(token).safeTransfer(recipient, claimable);

        emit Claim(claimable);
    }

    function _totalVestedOf(uint256 timestamp) internal view returns (uint256) {
        uint256 start = startTime;
        uint256 end = endTime;
        uint256 locked = initialLocked;
        if (timestamp < start) {
            return 0;
        } else if (timestamp > end) {
            return locked;
        }
        uint256 vestedAtStart_ = vestedAtStart;
        return
            locked.sub(vestedAtStart_).mul(timestamp - start).div(end - start).add(vestedAtStart_);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../interfaces/IChessSchedule.sol";
import "../interfaces/IChessController.sol";
import "../utils/CoreUtility.sol";
import "../utils/SafeDecimalMath.sol";
import "../anyswap/AnyCallAppBase.sol";
import "../interfaces/IAnyswapV6ERC20.sol";

contract ChessScheduleRelayer is CoreUtility, AnyCallAppBase {
    using SafeDecimalMath for uint256;
    using SafeERC20 for IERC20;

    event CrossChainMinted(uint256 chainID, uint256 amount);
    event CrossChainSynced(uint256 chainID, uint256 week, uint256 veSupply);

    uint256 public immutable subChainID;

    address public immutable subSchedule;

    IChessSchedule public immutable chessSchedule;

    IChessController public immutable chessController;

    address public immutable anyswapChessPool;

    address public immutable chess;

    mapping(uint256 => uint256) public veSupplyPerWeek;

    uint256 public lastWeek;

    constructor(
        uint256 subChainID_,
        address subSchedule_,
        address chessSchedule_,
        address chessController_,
        address anyswapChessPool_,
        address anyCallProxy_
    ) public AnyCallAppBase(anyCallProxy_, false, false) {
        subChainID = subChainID_;
        subSchedule = subSchedule_;
        chessSchedule = IChessSchedule(chessSchedule_);
        chessController = IChessController(chessController_);
        anyswapChessPool = anyswapChessPool_;
        chess = IAnyswapV6ERC20(anyswapChessPool_).underlying();
    }

    function crossChainMint() external {
        uint256 startWeek = _endOfWeek(block.timestamp) - 1 weeks;
        if (startWeek <= lastWeek) {
            return;
        }
        lastWeek = startWeek;
        uint256 amount =
            chessSchedule.getWeeklySupply(startWeek).multiplyDecimal(
                chessController.getFundRelativeWeight(address(this), startWeek)
            );
        if (amount != 0) {
            chessSchedule.mint(anyswapChessPool, amount);
        }
        uint256 balance = IERC20(chess).balanceOf(address(this));
        if (balance != 0) {
            // Additional CHESS rewards directly transferred to this contract
            IERC20(chess).safeTransfer(anyswapChessPool, balance);
            amount += balance;
        }
        if (amount != 0) {
            _anyCall(subSchedule, subChainID, abi.encode(amount));
            emit CrossChainMinted(subChainID, amount);
        }
    }

    function _checkAnyExecuteFrom(address from, uint256 fromChainID)
        internal
        override
        returns (bool)
    {
        return from == subSchedule && fromChainID == subChainID;
    }

    function _checkAnyFallbackTo(address, uint256) internal override returns (bool) {
        return false;
    }

    function _anyExecute(uint256, bytes calldata data) internal override {
        (uint256 week, uint256 supply, uint256 nextWeekSupply) =
            abi.decode(data, (uint256, uint256, uint256));
        veSupplyPerWeek[week] = supply;
        veSupplyPerWeek[week + 1 weeks] = nextWeekSupply;
        emit CrossChainSynced(subChainID, week, supply);
        emit CrossChainSynced(subChainID, week + 1 weeks, nextWeekSupply);
    }

    function _anyFallback(bytes calldata) internal override {
        revert("N/A");
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

import "../utils/CoreUtility.sol";
import "../utils/SafeDecimalMath.sol";
import "../interfaces/IChessController.sol";
import "../interfaces/IControllerBallotV2.sol";

interface IChessScheduleRelayer {
    function veSupplyPerWeek(uint256 week) external view returns (uint256);
}

contract ChessControllerV6 is IChessController, CoreUtility {
    /// @dev Reserved storage slots for future base contract upgrades
    uint256[192] private _reservedSlots;

    using SafeMath for uint256;
    using SafeDecimalMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    event WeightUpdated(address indexed fund, uint256 indexed timestamp, uint256 weight);
    event ScheduleRelayerAdded(address scheduleRelayer);
    event ScheduleRelayerRemoved(address scheduleRelayer);

    address public immutable fund0;
    uint256 public immutable guardedLaunchStart;
    IControllerBallotV2 public immutable controllerBallot;

    mapping(uint256 => mapping(address => uint256)) public weights;

    /// @notice Start timestamp of the last trading week that has weights updated.
    uint256 public lastTimestamp;

    EnumerableSet.AddressSet private _scheduleRelayers;

    constructor(
        address fund0_,
        uint256 guardedLaunchStart_,
        address controllerBallot_
    ) public {
        fund0 = fund0_;
        guardedLaunchStart = guardedLaunchStart_;
        require(_endOfWeek(guardedLaunchStart_) == guardedLaunchStart_ + 1 weeks);
        controllerBallot = IControllerBallotV2(controllerBallot_);
    }

    /// @dev Initialize the part added in V4. The contract is designed to be used with OpenZeppelin's
    ///      `TransparentUpgradeableProxy`. If this contract is upgraded from the previous version,
    ///      call `upgradeToAndCall` of the proxy and put a call to this function in the `data`
    ///      argument with `lastTimestamp_` set to the last updated week. If this contract is
    ///      the first implementation of the proxy, This function should be called by the proxy's
    ///      constructor (via the `_data` argument) with `lastTimestamp_` set to one week before
    ///      `guardedLaunchStart`.
    function initializeV4(uint256 lastTimestamp_) external {
        require(lastTimestamp == 0, "Already initialized");
        require(
            _endOfWeek(lastTimestamp_) == lastTimestamp_ + 1 weeks &&
                lastTimestamp_ >= guardedLaunchStart - 1 weeks
        );
        require(weights[lastTimestamp_ + 1 weeks][fund0] == 0, "Next week already updated");
        if (lastTimestamp_ >= guardedLaunchStart) {
            require(weights[lastTimestamp_][fund0] > 0, "Last week not updated");
        }
        lastTimestamp = lastTimestamp_;
    }

    function owner() public view returns (address) {
        // Use the ballot's owner as this contract's owner.
        return Ownable(address(controllerBallot)).owner();
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function getScheduleRelayers() public view returns (address[] memory relayers) {
        uint256 length = _scheduleRelayers.length();
        relayers = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            relayers[i] = _scheduleRelayers.at(i);
        }
    }

    /// @notice Get relative weight (not more than 1.0) normalized to 1e18
    ///         (e.g. 1.0 == 1e18).
    /// @return weight Value of relative weight normalized to 1e18
    function getFundRelativeWeight(address pool, uint256 timestamp)
        external
        override
        returns (uint256)
    {
        require(timestamp <= block.timestamp, "Too soon");
        if (timestamp < guardedLaunchStart) {
            return pool == fund0 ? 1e18 : 0;
        }
        uint256 weekTimestamp = _endOfWeek(timestamp).sub(1 weeks);
        uint256 lastTimestamp_ = lastTimestamp; // gas saver
        require(weekTimestamp <= lastTimestamp_ + 1 weeks, "Previous week is empty");
        if (weekTimestamp <= lastTimestamp_) {
            return weights[weekTimestamp][pool];
        }
        lastTimestamp = lastTimestamp_ + 1 weeks;
        return _updateWeight(weekTimestamp, pool);
    }

    function _updateWeight(uint256 weekTimestamp, address pool) private returns (uint256 weight) {
        uint256 total = 0;
        (uint256[] memory sums, address[] memory pools) = controllerBallot.count(weekTimestamp);
        for (uint256 i = 0; i < pools.length; i++) {
            total = total.add(sums[i]);
        }
        address[] memory relayers = getScheduleRelayers();
        uint256[] memory relayerSupplies = new uint256[](relayers.length);
        for (uint256 i = 0; i < relayers.length; i++) {
            uint256 relayerSupply =
                IChessScheduleRelayer(relayers[i]).veSupplyPerWeek(weekTimestamp);
            relayerSupplies[i] = relayerSupply;
            total = total.add(relayerSupply);
        }

        for (uint256 i = 0; i < pools.length; i++) {
            uint256 w =
                total != 0 ? sums[i].divideDecimal(total) : 1e18 / (pools.length + relayers.length);
            weights[weekTimestamp][pools[i]] = w;
            emit WeightUpdated(pools[i], weekTimestamp, w);
            if (pools[i] == pool) {
                weight = w;
            }
        }
        for (uint256 i = 0; i < relayers.length; i++) {
            uint256 w =
                total != 0
                    ? relayerSupplies[i].divideDecimal(total)
                    : 1e18 / (pools.length + relayers.length);
            weights[weekTimestamp][relayers[i]] = w;
            emit WeightUpdated(relayers[i], weekTimestamp, w);
            if (relayers[i] == pool) {
                weight = w;
            }
        }
    }

    function addScheduleRelayer(address scheduleRelayer) external onlyOwner {
        if (_scheduleRelayers.add(scheduleRelayer)) {
            emit ScheduleRelayerAdded(scheduleRelayer);
        }
    }

    function removeScheduleRelayer(address scheduleRelayer) external onlyOwner {
        if (_scheduleRelayers.remove(scheduleRelayer)) {
            emit ScheduleRelayerRemoved(scheduleRelayer);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../utils/CoreUtility.sol";
import "../utils/SafeDecimalMath.sol";
import "../interfaces/IChessController.sol";
import "../interfaces/IControllerBallot.sol";

contract ChessControllerV5 is IChessController, CoreUtility {
    /// @dev Reserved storage slots for future base contract upgrades
    uint256[192] private _reservedSlots;

    using Math for uint256;
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;

    event WeightUpdated(address indexed fund, uint256 indexed timestamp, uint256 weight);

    address public immutable fund0;
    uint256 public immutable guardedLaunchStart;
    address public immutable controllerBallot;

    mapping(uint256 => mapping(address => uint256)) public weights;

    /// @notice Start timestamp of the last trading week that has weights updated.
    uint256 public lastTimestamp;

    constructor(
        address fund0_,
        uint256 guardedLaunchStart_,
        address controllerBallot_
    ) public {
        fund0 = fund0_;
        guardedLaunchStart = guardedLaunchStart_;
        require(_endOfWeek(guardedLaunchStart_) == guardedLaunchStart_ + 1 weeks);
        controllerBallot = controllerBallot_;
    }

    /// @dev Initialize the part added in V4. The contract is designed to be used with OpenZeppelin's
    ///      `TransparentUpgradeableProxy`. If this contract is upgraded from the previous version,
    ///      call `upgradeToAndCall` of the proxy and put a call to this function in the `data`
    ///      argument with `lastTimestamp_` set to the last updated week. If this contract is
    ///      the first implementation of the proxy, This function should be called by the proxy's
    ///      constructor (via the `_data` argument) with `lastTimestamp_` set to one week before
    ///      `guardedLaunchStart`.
    function initializeV4(uint256 lastTimestamp_) external {
        require(lastTimestamp == 0, "Already initialized");
        require(
            _endOfWeek(lastTimestamp_) == lastTimestamp_ + 1 weeks &&
                lastTimestamp_ >= guardedLaunchStart - 1 weeks
        );
        require(weights[lastTimestamp_ + 1 weeks][fund0] == 0, "Next week already updated");
        if (lastTimestamp_ >= guardedLaunchStart) {
            require(weights[lastTimestamp_][fund0] > 0, "Last week not updated");
        }
        lastTimestamp = lastTimestamp_;
    }

    /// @notice Get Fund relative weight (not more than 1.0) normalized to 1e18
    ///         (e.g. 1.0 == 1e18).
    /// @return weight Value of relative weight normalized to 1e18
    function getFundRelativeWeight(address fundAddress, uint256 timestamp)
        external
        override
        returns (uint256)
    {
        require(timestamp <= block.timestamp, "Too soon");
        if (timestamp < guardedLaunchStart) {
            return fundAddress == fund0 ? 1e18 : 0;
        }
        uint256 weekTimestamp = _endOfWeek(timestamp).sub(1 weeks);
        uint256 lastTimestamp_ = lastTimestamp; // gas saver
        require(weekTimestamp <= lastTimestamp_ + 1 weeks, "Previous week is empty");
        if (weekTimestamp <= lastTimestamp_) {
            return weights[weekTimestamp][fundAddress];
        }
        lastTimestamp = lastTimestamp_ + 1 weeks;
        return _updateFundWeight(weekTimestamp, fundAddress);
    }

    function _updateFundWeight(uint256 weekTimestamp, address fundAddress)
        private
        returns (uint256 weight)
    {
        (uint256[] memory ballotWeights, address[] memory funds) =
            IControllerBallot(controllerBallot).count(weekTimestamp);

        uint256 totalWeight;
        for (uint256 i = 0; i < ballotWeights.length; i++) {
            uint256 fundWeight = ballotWeights[i];
            weights[weekTimestamp][funds[i]] = fundWeight;
            emit WeightUpdated(funds[i], weekTimestamp, fundWeight);
            if (funds[i] == fundAddress) {
                weight = fundWeight;
            }
            totalWeight = totalWeight.add(fundWeight);
        }
        require(totalWeight <= 1e18, "Total weight exceeds 100%");
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

interface IControllerBallot {
    function count(uint256 timestamp)
        external
        view
        returns (uint256[] memory ratios, address[] memory funds);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../utils/CoreUtility.sol";
import "../utils/SafeDecimalMath.sol";

import "../interfaces/IControllerBallot.sol";
import "../interfaces/IVotingEscrow.sol";

contract ControllerBallot is IControllerBallot, IVotingEscrowCallback, Ownable, CoreUtility {
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;

    event PoolAdded(address pool);
    event PoolToggled(address indexed pool, bool isDisabled);
    event Voted(
        address indexed account,
        uint256 oldAmount,
        uint256 oldUnlockTime,
        uint256[] oldWeights,
        uint256 amount,
        uint256 unlockTime,
        uint256[] weights
    );

    IVotingEscrow public immutable votingEscrow;
    uint256 private immutable _maxTime;

    address[65535] private _pools;
    uint256 public poolSize;
    uint256 public disabledPoolSize;

    /// @notice Locked balance of an account, which is synchronized with `VotingEscrow` when
    ///         `syncWithVotingEscrow()` is called
    mapping(address => IVotingEscrow.LockedBalance) public userLockedBalances;

    /// @notice Mapping of account => pool => fraction of the user's veCHESS voted to the pool
    mapping(address => mapping(address => uint256)) public userWeights;

    /// @notice Mapping of pool => unlockTime => CHESS amount voted to the pool that will be
    ///         unlocked at unlockTime
    mapping(address => mapping(uint256 => uint256)) public poolScheduledUnlock;

    /// @notice Mapping of pool => status of the pool
    mapping(uint256 => bool) public disabledPools;

    constructor(address votingEscrow_) public {
        votingEscrow = IVotingEscrow(votingEscrow_);
        _maxTime = IVotingEscrow(votingEscrow_).maxTime();
    }

    function getPools() external view returns (address[] memory) {
        uint256 size = poolSize;
        address[] memory pools = new address[](size);
        for (uint256 i = 0; i < size; i++) {
            pools[i] = _pools[i];
        }
        return pools;
    }

    function addPool(address newPool) external onlyOwner {
        uint256 size = poolSize;
        _pools[size] = newPool;
        poolSize = size + 1;
        emit PoolAdded(newPool);
    }

    function togglePool(uint256 index) external onlyOwner {
        require(index < poolSize, "Invalid index");
        if (disabledPools[index]) {
            disabledPools[index] = false;
            disabledPoolSize--;
        } else {
            disabledPools[index] = true;
            disabledPoolSize++;
        }
        emit PoolToggled(_pools[index], disabledPools[index]);
    }

    function balanceOf(address account) external view returns (uint256) {
        return balanceOfAtTimestamp(account, block.timestamp);
    }

    function balanceOfAtTimestamp(address account, uint256 timestamp)
        public
        view
        returns (uint256)
    {
        require(timestamp >= block.timestamp, "Must be current or future time");
        IVotingEscrow.LockedBalance memory locked = userLockedBalances[account];
        if (timestamp >= locked.unlockTime) {
            return 0;
        }
        return locked.amount.mul(locked.unlockTime - timestamp) / _maxTime;
    }

    function totalSupply() external view returns (uint256) {
        return totalSupplyAtTimestamp(block.timestamp);
    }

    function totalSupplyAtTimestamp(uint256 timestamp) public view returns (uint256) {
        uint256 size = poolSize;
        uint256 total = 0;
        for (uint256 i = 0; i < size; i++) {
            total = total.add(sumAtTimestamp(_pools[i], timestamp));
        }
        return total;
    }

    function sumAtTimestamp(address pool, uint256 timestamp) public view returns (uint256) {
        uint256 sum = 0;
        for (
            uint256 weekCursor = _endOfWeek(timestamp);
            weekCursor <= timestamp + _maxTime;
            weekCursor += 1 weeks
        ) {
            sum = sum.add(
                poolScheduledUnlock[pool][weekCursor].mul(weekCursor - timestamp) / _maxTime
            );
        }
        return sum;
    }

    function count(uint256 timestamp)
        external
        view
        override
        returns (uint256[] memory weights, address[] memory pools)
    {
        uint256 poolSize_ = poolSize;
        uint256 size = poolSize_ - disabledPoolSize;
        pools = new address[](size);
        uint256 j = 0;
        for (uint256 i = 0; i < poolSize_ && j < size; i++) {
            address pool = _pools[i];
            if (!disabledPools[i]) pools[j++] = pool;
        }

        uint256[] memory sums = new uint256[](size);
        uint256 total = 0;
        for (uint256 i = 0; i < size; i++) {
            uint256 sum = sumAtTimestamp(pools[i], timestamp);
            sums[i] = sum;
            total = total.add(sum);
        }

        weights = new uint256[](size);
        if (total == 0) {
            for (uint256 i = 0; i < size; i++) {
                weights[i] = 1e18 / size;
            }
        } else {
            for (uint256 i = 0; i < size; i++) {
                weights[i] = sums[i].divideDecimal(total);
            }
        }
    }

    function cast(uint256[] memory weights) external {
        uint256 size = poolSize;
        require(weights.length == size, "Invalid number of weights");
        uint256 totalWeight;
        for (uint256 i = 0; i < size; i++) {
            totalWeight = totalWeight.add(weights[i]);
        }
        require(totalWeight == 1e18, "Invalid weights");

        uint256[] memory oldWeights = new uint256[](size);
        for (uint256 i = 0; i < size; i++) {
            oldWeights[i] = userWeights[msg.sender][_pools[i]];
        }

        IVotingEscrow.LockedBalance memory oldLockedBalance = userLockedBalances[msg.sender];
        IVotingEscrow.LockedBalance memory lockedBalance =
            votingEscrow.getLockedBalance(msg.sender);
        require(
            lockedBalance.amount > 0 && lockedBalance.unlockTime > block.timestamp,
            "No veCHESS"
        );

        _updateVoteStatus(msg.sender, size, oldWeights, weights, oldLockedBalance, lockedBalance);
    }

    function syncWithVotingEscrow(address account) external override {
        IVotingEscrow.LockedBalance memory oldLockedBalance = userLockedBalances[account];
        if (oldLockedBalance.amount == 0) {
            return; // The account did not voted before
        }
        IVotingEscrow.LockedBalance memory lockedBalance = votingEscrow.getLockedBalance(account);
        if (lockedBalance.unlockTime <= block.timestamp) {
            return;
        }

        uint256 size = poolSize;
        uint256[] memory weights = new uint256[](size);
        for (uint256 i = 0; i < size; i++) {
            weights[i] = userWeights[account][_pools[i]];
        }

        _updateVoteStatus(account, size, weights, weights, oldLockedBalance, lockedBalance);
    }

    function _updateVoteStatus(
        address account,
        uint256 size,
        uint256[] memory oldWeights,
        uint256[] memory weights,
        IVotingEscrow.LockedBalance memory oldLockedBalance,
        IVotingEscrow.LockedBalance memory lockedBalance
    ) private {
        for (uint256 i = 0; i < size; i++) {
            address pool = _pools[i];
            poolScheduledUnlock[pool][oldLockedBalance.unlockTime] = poolScheduledUnlock[pool][
                oldLockedBalance.unlockTime
            ]
                .sub(oldLockedBalance.amount.multiplyDecimal(oldWeights[i]));

            poolScheduledUnlock[pool][lockedBalance.unlockTime] = poolScheduledUnlock[pool][
                lockedBalance.unlockTime
            ]
                .add(lockedBalance.amount.multiplyDecimal(weights[i]));
            userWeights[account][pool] = weights[i];
        }
        userLockedBalances[account] = lockedBalance;
        emit Voted(
            account,
            oldLockedBalance.amount,
            oldLockedBalance.unlockTime,
            oldWeights,
            lockedBalance.amount,
            lockedBalance.unlockTime,
            weights
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../utils/SafeDecimalMath.sol";
import "../utils/CoreUtility.sol";

import "../interfaces/IFundV3.sol";
import "../interfaces/IChessController.sol";
import "../interfaces/IChessSchedule.sol";
import "../interfaces/ITrancheIndexV2.sol";
import "../interfaces/IVotingEscrow.sol";

contract ShareStakingV2 is ITrancheIndexV2, CoreUtility {
    using Math for uint256;
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;
    using SafeERC20 for IERC20;

    event Deposited(uint256 tranche, address account, uint256 amount);
    event Withdrawn(uint256 tranche, address account, uint256 amount);

    uint256 private constant MAX_ITERATIONS = 500;

    uint256 private constant REWARD_WEIGHT_B = 2;
    uint256 private constant REWARD_WEIGHT_R = 1;
    uint256 private constant REWARD_WEIGHT_Q = 3;
    uint256 private constant MAX_BOOSTING_FACTOR = 3e18;
    uint256 private constant MAX_BOOSTING_FACTOR_MINUS_ONE = MAX_BOOSTING_FACTOR - 1e18;

    IFundV3 public immutable fund;

    /// @notice The Chess release schedule contract.
    IChessSchedule public immutable chessSchedule;

    /// @notice The controller contract.
    IChessController public immutable chessController;

    IVotingEscrow private immutable _votingEscrow;

    /// @dev Per-fund CHESS emission rate. The product of CHESS emission rate
    ///      and weekly percentage of the fund
    uint256 private _rate;

    /// @dev Total amount of user shares, i.e. sum of all entries in `_balances`.
    uint256[TRANCHE_COUNT] private _totalSupplies;

    /// @dev Rebalance version of `_totalSupplies`.
    uint256 private _totalSupplyVersion;

    /// @dev Amount of shares staked by each user.
    mapping(address => uint256[TRANCHE_COUNT]) private _balances;

    /// @dev Rebalance version mapping for `_balances`.
    mapping(address => uint256) private _balanceVersions;

    /// @dev Mapping of rebalance version => split ratio.
    mapping(uint256 => uint256) private _historicalSplitRatio;

    /// @dev 1e27 * ∫(rate(t) / totalWeight(t) dt) from the latest rebalance till checkpoint.
    uint256 private _invTotalWeightIntegral;

    /// @dev Final `_invTotalWeightIntegral` before each rebalance.
    ///      These values are accessed in a loop in `_userCheckpoint()` with bounds checking.
    ///      So we store them in a fixed-length array, in order to make compiler-generated
    ///      bounds checking on every access cheaper. The actual length of this array is stored in
    ///      `_historicalIntegralSize` and should be explicitly checked when necessary.
    uint256[65535] private _historicalIntegrals;

    /// @dev Actual length of the `_historicalIntegrals` array, which always equals to the number of
    ///      historical rebalances after `checkpoint()` is called.
    uint256 private _historicalIntegralSize;

    /// @dev Timestamp when checkpoint() is called.
    uint256 private _checkpointTimestamp;

    /// @dev Snapshot of `_invTotalWeightIntegral` per user.
    mapping(address => uint256) private _userIntegrals;

    /// @dev Mapping of account => claimable rewards.
    mapping(address => uint256) private _claimableRewards;

    uint256 private _workingSupply;
    mapping(address => uint256) private _workingBalances;

    constructor(
        address fund_,
        address chessSchedule_,
        address chessController_,
        address votingEscrow_
    ) public {
        fund = IFundV3(fund_);
        chessSchedule = IChessSchedule(chessSchedule_);
        chessController = IChessController(chessController_);
        _votingEscrow = IVotingEscrow(votingEscrow_);
        _checkpointTimestamp = block.timestamp;
    }

    function getRate() external view returns (uint256) {
        return _rate / 1e18;
    }

    /// @notice Return weight of given balance with respect to rewards.
    /// @param amountQ Amount of QUEEN
    /// @param amountB Amount of BISHOP
    /// @param amountR Amount of ROOK
    /// @param splitRatio Split ratio
    /// @return Rewarding weight of the balance
    function weightedBalance(
        uint256 amountQ,
        uint256 amountB,
        uint256 amountR,
        uint256 splitRatio
    ) public pure returns (uint256) {
        return
            amountQ
                .mul(REWARD_WEIGHT_Q)
                .multiplyDecimal(splitRatio)
                .add(amountB.mul(REWARD_WEIGHT_B))
                .add(amountR.mul(REWARD_WEIGHT_R))
                .div(REWARD_WEIGHT_Q);
    }

    function totalSupply(uint256 tranche) external view returns (uint256) {
        uint256 totalSupplyQ = _totalSupplies[TRANCHE_Q];
        uint256 totalSupplyB = _totalSupplies[TRANCHE_B];
        uint256 totalSupplyR = _totalSupplies[TRANCHE_R];

        uint256 version = _totalSupplyVersion;
        uint256 rebalanceSize = _fundRebalanceSize();
        if (version < rebalanceSize) {
            (totalSupplyQ, totalSupplyB, totalSupplyR) = _fundBatchRebalance(
                totalSupplyQ,
                totalSupplyB,
                totalSupplyR,
                version,
                rebalanceSize
            );
        }

        if (tranche == TRANCHE_Q) {
            return totalSupplyQ;
        } else if (tranche == TRANCHE_B) {
            return totalSupplyB;
        } else {
            return totalSupplyR;
        }
    }

    function trancheBalanceOf(uint256 tranche, address account) external view returns (uint256) {
        uint256 amountQ = _balances[account][TRANCHE_Q];
        uint256 amountB = _balances[account][TRANCHE_B];
        uint256 amountR = _balances[account][TRANCHE_R];

        if (tranche == TRANCHE_Q) {
            if (amountQ == 0 && amountB == 0 && amountR == 0) return 0;
        } else if (tranche == TRANCHE_B) {
            if (amountB == 0) return 0;
        } else {
            if (amountR == 0) return 0;
        }

        uint256 version = _balanceVersions[account];
        uint256 rebalanceSize = _fundRebalanceSize();
        if (version < rebalanceSize) {
            (amountQ, amountB, amountR) = _fundBatchRebalance(
                amountQ,
                amountB,
                amountR,
                version,
                rebalanceSize
            );
        }

        if (tranche == TRANCHE_Q) {
            return amountQ;
        } else if (tranche == TRANCHE_B) {
            return amountB;
        } else {
            return amountR;
        }
    }

    function balanceVersion(address account) external view returns (uint256) {
        return _balanceVersions[account];
    }

    function workingSupply() external view returns (uint256) {
        uint256 version = _totalSupplyVersion;
        uint256 rebalanceSize = _fundRebalanceSize();
        if (version < rebalanceSize) {
            (uint256 totalSupplyQ, uint256 totalSupplyB, uint256 totalSupplyR) =
                _fundBatchRebalance(
                    _totalSupplies[TRANCHE_Q],
                    _totalSupplies[TRANCHE_B],
                    _totalSupplies[TRANCHE_R],
                    version,
                    rebalanceSize
                );
            return weightedBalance(totalSupplyQ, totalSupplyB, totalSupplyR, fund.splitRatio());
        } else {
            return _workingSupply;
        }
    }

    function workingBalanceOf(address account) external view returns (uint256) {
        uint256 version = _balanceVersions[account];
        uint256 rebalanceSize = _fundRebalanceSize();
        uint256 workingBalance = _workingBalances[account]; // gas saver
        if (version < rebalanceSize || workingBalance == 0) {
            uint256[TRANCHE_COUNT] storage balance = _balances[account];
            uint256 amountQ = balance[TRANCHE_Q];
            uint256 amountB = balance[TRANCHE_B];
            uint256 amountR = balance[TRANCHE_R];
            if (version < rebalanceSize) {
                (amountQ, amountB, amountR) = _fundBatchRebalance(
                    amountQ,
                    amountB,
                    amountR,
                    version,
                    rebalanceSize
                );
            }
            return weightedBalance(amountQ, amountB, amountR, fund.splitRatio());
        } else {
            return workingBalance;
        }
    }

    function _fundRebalanceSize() internal view returns (uint256) {
        return fund.getRebalanceSize();
    }

    function _fundDoRebalance(
        uint256 amountQ,
        uint256 amountB,
        uint256 amountR,
        uint256 index
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return fund.doRebalance(amountQ, amountB, amountR, index);
    }

    function _fundBatchRebalance(
        uint256 amountQ,
        uint256 amountB,
        uint256 amountR,
        uint256 fromIndex,
        uint256 toIndex
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return fund.batchRebalance(amountQ, amountB, amountR, fromIndex, toIndex);
    }

    /// @dev Stake share tokens. A user could send QUEEN before deposit().
    ///      The contract first measures how much tranche share it has received,
    ///      then transfer the rest from the user
    /// @param tranche Tranche of the share
    /// @param amount The amount to deposit
    /// @param recipient Address that receives deposit
    /// @param version The current rebalance version
    function deposit(
        uint256 tranche,
        uint256 amount,
        address recipient,
        uint256 version
    ) external {
        _checkpoint(version);
        _userCheckpoint(recipient, version);
        _balances[recipient][tranche] = _balances[recipient][tranche].add(amount);
        uint256 oldTotalSupply = _totalSupplies[tranche];
        _totalSupplies[tranche] = oldTotalSupply.add(amount);
        _updateWorkingBalance(recipient, version);
        uint256 spareAmount = fund.trancheBalanceOf(tranche, address(this)).sub(oldTotalSupply);
        if (spareAmount < amount) {
            // Retain the rest of share token (version is checked by the fund)
            fund.trancheTransferFrom(
                tranche,
                msg.sender,
                address(this),
                amount - spareAmount,
                version
            );
        } else {
            require(version == _fundRebalanceSize(), "Invalid version");
        }
        emit Deposited(tranche, recipient, amount);
    }

    /// @notice Unstake tranche tokens.
    /// @param tranche Tranche of the share
    /// @param amount The amount to withdraw
    /// @param version The current rebalance version
    function withdraw(
        uint256 tranche,
        uint256 amount,
        uint256 version
    ) external {
        _checkpoint(version);
        _userCheckpoint(msg.sender, version);
        _balances[msg.sender][tranche] = _balances[msg.sender][tranche].sub(
            amount,
            "Insufficient balance to withdraw"
        );
        _totalSupplies[tranche] = _totalSupplies[tranche].sub(amount);
        _updateWorkingBalance(msg.sender, version);
        // version is checked by the fund
        fund.trancheTransfer(tranche, msg.sender, amount, version);
        emit Withdrawn(tranche, msg.sender, amount);
    }

    /// @notice Transform share balance to a given rebalance version, or to the latest version
    ///         if `targetVersion` is zero.
    /// @param account Account of the balance to rebalance
    /// @param targetVersion The target rebalance version, or zero for the latest version
    function refreshBalance(address account, uint256 targetVersion) external {
        uint256 rebalanceSize = _fundRebalanceSize();
        if (targetVersion == 0) {
            targetVersion = rebalanceSize;
        } else {
            require(targetVersion <= rebalanceSize, "Target version out of bound");
        }
        _checkpoint(rebalanceSize);
        _userCheckpoint(account, targetVersion);
    }

    /// @notice Return claimable rewards of an account till now.
    ///
    ///         This function should be call as a "view" function off-chain to get
    ///         the return value, e.g. using `contract.claimableRewards.call(account)` in web3
    ///         or `contract.callStatic.claimableRewards(account)` in ethers.js.
    /// @param account Address of an account
    /// @return Amount of claimable rewards
    function claimableRewards(address account) external returns (uint256) {
        uint256 rebalanceSize = _fundRebalanceSize();
        _checkpoint(rebalanceSize);
        _userCheckpoint(account, rebalanceSize);
        return _claimableRewards[account];
    }

    /// @notice Claim the rewards for an account.
    /// @param account Account to claim its rewards
    function claimRewards(address account) external {
        uint256 rebalanceSize = _fundRebalanceSize();
        _checkpoint(rebalanceSize);
        _userCheckpoint(account, rebalanceSize);
        uint256 amount = _claimableRewards[account];
        _claimableRewards[account] = 0;
        chessSchedule.mint(account, amount);
        _updateWorkingBalance(account, rebalanceSize);
    }

    /// @notice Synchronize an account's locked Chess with `VotingEscrow`
    ///         and update its working balance.
    /// @param account Address of the synchronized account
    function syncWithVotingEscrow(address account) external {
        uint256 rebalanceSize = _fundRebalanceSize();
        _checkpoint(rebalanceSize);
        _userCheckpoint(account, rebalanceSize);
        _updateWorkingBalance(account, rebalanceSize);
    }

    /// @dev Transform total supplies to the latest rebalance version and make a global reward checkpoint.
    /// @param rebalanceSize The number of existing rebalances. It must be the same as
    ///                       `fund.getRebalanceSize()`.
    function _checkpoint(uint256 rebalanceSize) private {
        uint256 timestamp = _checkpointTimestamp;
        if (timestamp >= block.timestamp) {
            return;
        }

        uint256 integral = _invTotalWeightIntegral;
        uint256 endWeek = _endOfWeek(timestamp);
        uint256 version = _totalSupplyVersion;
        uint256 rebalanceTimestamp;
        if (version < rebalanceSize) {
            rebalanceTimestamp = fund.getRebalanceTimestamp(version);
        } else {
            rebalanceTimestamp = type(uint256).max;
        }
        uint256 rate = _rate;
        if (rate == 0) {
            // CHESS emission may update in the middle of a week due to cross-chain lag.
            // We re-calculate the rate if it was zero after the last checkpoint.
            uint256 weeklySupply = chessSchedule.getWeeklySupply(timestamp);
            if (weeklySupply != 0) {
                rate = (weeklySupply / (endWeek - timestamp)).mul(
                    chessController.getFundRelativeWeight(address(this), timestamp)
                );
            }
        }
        uint256 totalSupplyQ = _totalSupplies[TRANCHE_Q];
        uint256 totalSupplyB = _totalSupplies[TRANCHE_B];
        uint256 totalSupplyR = _totalSupplies[TRANCHE_R];
        uint256 weight = _workingSupply;
        uint256 timestamp_ = timestamp; // avoid stack too deep

        for (uint256 i = 0; i < MAX_ITERATIONS && timestamp_ < block.timestamp; i++) {
            uint256 endTimestamp = rebalanceTimestamp.min(endWeek).min(block.timestamp);

            if (weight > 0) {
                integral = integral.add(
                    rate.mul(endTimestamp - timestamp_).decimalToPreciseDecimal().div(weight)
                );
            }

            if (endTimestamp == rebalanceTimestamp) {
                uint256 oldSize = _historicalIntegralSize;
                _historicalIntegrals[oldSize] = integral;
                _historicalIntegralSize = oldSize + 1;

                integral = 0;
                (totalSupplyQ, totalSupplyB, totalSupplyR) = _fundDoRebalance(
                    totalSupplyQ,
                    totalSupplyB,
                    totalSupplyR,
                    version
                );

                version++;
                {
                    // Reset total weight boosting after the first rebalance
                    uint256 splitRatio = fund.historicalSplitRatio(version);
                    weight = weightedBalance(totalSupplyQ, totalSupplyB, totalSupplyR, splitRatio);
                    _historicalSplitRatio[version] = splitRatio;
                }

                if (version < rebalanceSize) {
                    rebalanceTimestamp = fund.getRebalanceTimestamp(version);
                } else {
                    rebalanceTimestamp = type(uint256).max;
                }
            }
            if (endTimestamp == endWeek) {
                rate = chessSchedule.getRate(endWeek).mul(
                    chessController.getFundRelativeWeight(address(this), endWeek)
                );
                endWeek += 1 weeks;
            }

            timestamp_ = endTimestamp;
        }

        _checkpointTimestamp = block.timestamp;
        _invTotalWeightIntegral = integral;
        _rate = rate;
        if (_totalSupplyVersion != rebalanceSize) {
            _totalSupplies[TRANCHE_Q] = totalSupplyQ;
            _totalSupplies[TRANCHE_B] = totalSupplyB;
            _totalSupplies[TRANCHE_R] = totalSupplyR;
            _totalSupplyVersion = rebalanceSize;
            // Reset total working weight before any boosting if rebalance ever triggered
            _workingSupply = weight;
        }
    }

    /// @dev Transform a user's balance to a given rebalance version and update this user's rewards.
    ///
    ///      In most cases, the target version is the latest version and this function cumulates
    ///      rewards till now. When this function is called from `refreshBalance()`,
    ///      `targetVersion` can be an older version, in which case rewards are cumulated till
    ///      the end of that version (i.e. timestamp of the transaction triggering the rebalance
    ///      with index `targetVersion`).
    ///
    ///      This function should always be called after `_checkpoint()` is called, so that
    ///      the global reward checkpoint is guarenteed up to date.
    /// @param account Account to update
    /// @param targetVersion The target rebalance version
    function _userCheckpoint(address account, uint256 targetVersion) private {
        uint256 oldVersion = _balanceVersions[account];
        if (oldVersion > targetVersion) {
            return;
        }
        uint256 userIntegral = _userIntegrals[account];
        uint256 integral;
        // This scope is to avoid the "stack too deep" error.
        {
            // We assume that this function is always called immediately after `_checkpoint()`,
            // which guarantees that `_historicalIntegralSize` equals to the number of historical
            // rebalances.
            uint256 rebalanceSize = _historicalIntegralSize;
            integral = targetVersion == rebalanceSize
                ? _invTotalWeightIntegral
                : _historicalIntegrals[targetVersion];
        }
        if (userIntegral == integral && oldVersion == targetVersion) {
            // Return immediately when the user's rewards have already been updated to
            // the target version.
            return;
        }

        uint256 rewards = _claimableRewards[account];
        uint256[TRANCHE_COUNT] storage balance = _balances[account];
        uint256 weight = _workingBalances[account];
        uint256 balanceQ = balance[TRANCHE_Q];
        uint256 balanceB = balance[TRANCHE_B];
        uint256 balanceR = balance[TRANCHE_R];
        for (uint256 i = oldVersion; i < targetVersion; i++) {
            rewards = rewards.add(
                weight.multiplyDecimalPrecise(_historicalIntegrals[i].sub(userIntegral))
            );
            if (balanceQ != 0 || balanceB != 0 || balanceR != 0) {
                (balanceQ, balanceB, balanceR) = _fundDoRebalance(balanceQ, balanceB, balanceR, i);
            }
            userIntegral = 0;

            // Reset per-user weight boosting after the first rebalance
            weight = weightedBalance(balanceQ, balanceB, balanceR, _historicalSplitRatio[i + 1]);
        }
        rewards = rewards.add(weight.multiplyDecimalPrecise(integral.sub(userIntegral)));
        address account_ = account; // Fix the "stack too deep" error
        _claimableRewards[account_] = rewards;
        _userIntegrals[account_] = integral;

        if (oldVersion < targetVersion) {
            balance[TRANCHE_Q] = balanceQ;
            balance[TRANCHE_B] = balanceB;
            balance[TRANCHE_R] = balanceR;
            _balanceVersions[account_] = targetVersion;
            _workingBalances[account_] = weight;
        }
    }

    /// @dev Calculate working balance, which depends on the amount of staked tokens and veCHESS.
    ///      Before this function is called, both `_checkpoint()` and `_userCheckpoint(account)`
    ///      should be called to update `_workingSupply` and `_workingBalances[account]` to
    ///      the latest rebalance version.
    /// @param account User address
    /// @param rebalanceSize The number of existing rebalances. It must be the same as
    ///                       `fund.getRebalanceSize()`.
    function _updateWorkingBalance(address account, uint256 rebalanceSize) private {
        uint256 splitRatio = _historicalSplitRatio[rebalanceSize];
        if (splitRatio == 0) {
            // Read it from the fund in case that it's not initialized yet, e.g. when we reach here
            // for the first time and `rebalanceSize` is zero.
            splitRatio = fund.historicalSplitRatio(rebalanceSize);
            _historicalSplitRatio[rebalanceSize] = splitRatio;
        }
        uint256 weightedSupply =
            weightedBalance(
                _totalSupplies[TRANCHE_Q],
                _totalSupplies[TRANCHE_B],
                _totalSupplies[TRANCHE_R],
                splitRatio
            );
        uint256[TRANCHE_COUNT] storage balance = _balances[account];
        uint256 newWorkingBalance =
            weightedBalance(balance[TRANCHE_Q], balance[TRANCHE_B], balance[TRANCHE_R], splitRatio);
        uint256 veBalance = _votingEscrow.balanceOf(account);
        if (veBalance > 0) {
            uint256 veTotalSupply = _votingEscrow.totalSupply();
            uint256 maxWorkingBalance = newWorkingBalance.multiplyDecimal(MAX_BOOSTING_FACTOR);
            uint256 boostedWorkingBalance =
                newWorkingBalance.add(
                    weightedSupply
                        .mul(veBalance)
                        .multiplyDecimal(MAX_BOOSTING_FACTOR_MINUS_ONE)
                        .div(veTotalSupply)
                );
            newWorkingBalance = maxWorkingBalance.min(boostedWorkingBalance);
        }

        _workingSupply = _workingSupply.sub(_workingBalances[account]).add(newWorkingBalance);
        _workingBalances[account] = newWorkingBalance;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IChessSchedule.sol";
import "../interfaces/IChessController.sol";
import "../utils/CoreUtility.sol";
import "../utils/SafeDecimalMath.sol";

contract RewardClaimer is Ownable, CoreUtility {
    using SafeDecimalMath for uint256;

    event ClaimerUpdated(address newClaimer);

    IChessSchedule public immutable chessSchedule;
    IChessController public immutable chessController;

    address public rewardClaimer;
    uint256 public lastWeek;

    constructor(address chessSchedule_, address chessController_) public {
        chessSchedule = IChessSchedule(chessSchedule_);
        chessController = IChessController(chessController_);
        lastWeek = _endOfWeek(block.timestamp);
    }

    function updateClaimer(address newClaimer) external onlyOwner {
        rewardClaimer = newClaimer;
        emit ClaimerUpdated(newClaimer);
    }

    modifier onlyClaimer() {
        require(msg.sender == rewardClaimer, "Only reward claimer");
        _;
    }

    function claimRewards() external onlyClaimer {
        uint256 amount = _checkpoint();
        chessSchedule.mint(msg.sender, amount);
    }

    function _checkpoint() private returns (uint256 amount) {
        uint256 w = lastWeek;
        uint256 currWeek = _endOfWeek(block.timestamp) - 1 weeks;

        for (; w < block.timestamp; w += 1 weeks) {
            uint256 weeklySupply = chessSchedule.getWeeklySupply(w);
            if (weeklySupply == 0) {
                // CHESS emission may update in the middle of a week due to cross-chain lag,
                // so we have to revisit the zero value as long as it is in the current week.
                if (w == currWeek) break;
                continue;
            }

            uint256 weeklyWeight = chessController.getFundRelativeWeight(address(this), w);
            if (weeklyWeight == 0) {
                continue;
            }

            amount = amount.add(weeklySupply.multiplyDecimal(weeklyWeight));
        }

        // Update global state
        lastWeek = w;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./RewardClaimer.sol";

interface IBribeVault {
    function BRIBE_VAULT() external view returns (address);

    function depositBribeERC20(
        bytes32 proposal,
        address token,
        uint256 amount
    ) external;
}

contract Briber is Ownable {
    using SafeERC20 for IERC20;

    IBribeVault public immutable bribeVault;
    RewardClaimer public immutable rewardClaimer;
    address public immutable token;

    constructor(
        address bribeVault_,
        address rewardClaimer_,
        address token_
    ) public {
        bribeVault = IBribeVault(bribeVault_);
        rewardClaimer = RewardClaimer(rewardClaimer_);
        token = token_;
    }

    function bribe(uint256 proposalIndex, uint256 choiceIndex) external onlyOwner {
        bytes32 proposal = keccak256(abi.encodePacked(proposalIndex, choiceIndex));
        rewardClaimer.claimRewards();
        uint256 bribeAmount = IERC20(token).balanceOf(address(this));
        IERC20(token).safeApprove(bribeVault.BRIBE_VAULT(), bribeAmount);
        bribeVault.depositBribeERC20(proposal, token, bribeAmount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Chess is ERC20 {
    constructor(uint256 initialSupply) public ERC20("Chess", "CHESS") {
        _mint(msg.sender, initialSupply);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../governance/ChessRoles.sol";

import "../interfaces/IAnyswapV6ERC20.sol";

contract AnyswapChess is IAnyswapV6ERC20, ERC20, ChessRoles, Ownable {
    address public constant override underlying = address(0);

    uint256 public immutable maxTotalSupply;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxTotalSupply_
    ) public ERC20(name_, symbol_) {
        maxTotalSupply = maxTotalSupply_;
    }

    function addMinter(address account) external onlyOwner {
        _addMinter(account);
    }

    function removeMinter(address account) external onlyOwner {
        _removeMinter(account);
    }

    function mint(address to, uint256 amount) external override onlyMinter returns (bool) {
        _mint(to, amount);
        return true;
    }

    function burn(address from, uint256 amount) external override onlyMinter returns (bool) {
        _burn(from, amount);
        return true;
    }

    function _beforeTokenTransfer(
        address from,
        address, // to
        uint256 amount
    ) internal override {
        if (from == address(0)) {
            // When minting tokens
            require(totalSupply().add(amount) <= maxTotalSupply, "Max total supply exceeded");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.9 <0.8.0;
pragma experimental ABIEncoderV2;

import "./../math/SafeMath.sol";
import "./AccessControl.sol";

/**
 * @dev Contract module which acts as a timelocked controller. When set as the
 * owner of an `Ownable` smart contract, it enforces a timelock on all
 * `onlyOwner` maintenance operations. This gives time for users of the
 * controlled contract to exit before a potentially dangerous maintenance
 * operation is applied.
 *
 * By default, this contract is self administered, meaning administration tasks
 * have to go through the timelock process. The proposer (resp executor) role
 * is in charge of proposing (resp executing) operations. A common use case is
 * to position this {TimelockController} as the owner of a smart contract, with
 * a multisig or a DAO as the sole proposer.
 *
 * _Available since v3.3._
 */
contract TimelockController is AccessControl {

    bytes32 public constant TIMELOCK_ADMIN_ROLE = keccak256("TIMELOCK_ADMIN_ROLE");
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    uint256 internal constant _DONE_TIMESTAMP = uint256(1);

    mapping(bytes32 => uint256) private _timestamps;
    uint256 private _minDelay;

    /**
     * @dev Emitted when a call is scheduled as part of operation `id`.
     */
    event CallScheduled(bytes32 indexed id, uint256 indexed index, address target, uint256 value, bytes data, bytes32 predecessor, uint256 delay);

    /**
     * @dev Emitted when a call is performed as part of operation `id`.
     */
    event CallExecuted(bytes32 indexed id, uint256 indexed index, address target, uint256 value, bytes data);

    /**
     * @dev Emitted when operation `id` is cancelled.
     */
    event Cancelled(bytes32 indexed id);

    /**
     * @dev Emitted when the minimum delay for future operations is modified.
     */
    event MinDelayChange(uint256 oldDuration, uint256 newDuration);

    /**
     * @dev Initializes the contract with a given `minDelay`.
     */
    constructor(uint256 minDelay, address[] memory proposers, address[] memory executors) public {
        _setRoleAdmin(TIMELOCK_ADMIN_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(PROPOSER_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(EXECUTOR_ROLE, TIMELOCK_ADMIN_ROLE);

        // deployer + self administration
        _setupRole(TIMELOCK_ADMIN_ROLE, _msgSender());
        _setupRole(TIMELOCK_ADMIN_ROLE, address(this));

        // register proposers
        for (uint256 i = 0; i < proposers.length; ++i) {
            _setupRole(PROPOSER_ROLE, proposers[i]);
        }

        // register executors
        for (uint256 i = 0; i < executors.length; ++i) {
            _setupRole(EXECUTOR_ROLE, executors[i]);
        }

        _minDelay = minDelay;
        emit MinDelayChange(0, minDelay);
    }

    /**
     * @dev Modifier to make a function callable only by a certain role. In
     * addition to checking the sender's role, `address(0)` 's role is also
     * considered. Granting a role to `address(0)` is equivalent to enabling
     * this role for everyone.
     */
    modifier onlyRole(bytes32 role) {
        require(hasRole(role, _msgSender()) || hasRole(role, address(0)), "TimelockController: sender requires permission");
        _;
    }

    /**
     * @dev Contract might receive/hold ETH as part of the maintenance process.
     */
    receive() external payable {}

    /**
     * @dev Returns whether an id correspond to a registered operation. This
     * includes both Pending, Ready and Done operations.
     */
    function isOperation(bytes32 id) public view virtual returns (bool pending) {
        return getTimestamp(id) > 0;
    }

    /**
     * @dev Returns whether an operation is pending or not.
     */
    function isOperationPending(bytes32 id) public view virtual returns (bool pending) {
        return getTimestamp(id) > _DONE_TIMESTAMP;
    }

    /**
     * @dev Returns whether an operation is ready or not.
     */
    function isOperationReady(bytes32 id) public view virtual returns (bool ready) {
        uint256 timestamp = getTimestamp(id);
        // solhint-disable-next-line not-rely-on-time
        return timestamp > _DONE_TIMESTAMP && timestamp <= block.timestamp;
    }

    /**
     * @dev Returns whether an operation is done or not.
     */
    function isOperationDone(bytes32 id) public view virtual returns (bool done) {
        return getTimestamp(id) == _DONE_TIMESTAMP;
    }

    /**
     * @dev Returns the timestamp at with an operation becomes ready (0 for
     * unset operations, 1 for done operations).
     */
    function getTimestamp(bytes32 id) public view virtual returns (uint256 timestamp) {
        return _timestamps[id];
    }

    /**
     * @dev Returns the minimum delay for an operation to become valid.
     *
     * This value can be changed by executing an operation that calls `updateDelay`.
     */
    function getMinDelay() public view virtual returns (uint256 duration) {
        return _minDelay;
    }

    /**
     * @dev Returns the identifier of an operation containing a single
     * transaction.
     */
    function hashOperation(address target, uint256 value, bytes calldata data, bytes32 predecessor, bytes32 salt) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(target, value, data, predecessor, salt));
    }

    /**
     * @dev Returns the identifier of an operation containing a batch of
     * transactions.
     */
    function hashOperationBatch(address[] calldata targets, uint256[] calldata values, bytes[] calldata datas, bytes32 predecessor, bytes32 salt) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(targets, values, datas, predecessor, salt));
    }

    /**
     * @dev Schedule an operation containing a single transaction.
     *
     * Emits a {CallScheduled} event.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function schedule(address target, uint256 value, bytes calldata data, bytes32 predecessor, bytes32 salt, uint256 delay) public virtual onlyRole(PROPOSER_ROLE) {
        bytes32 id = hashOperation(target, value, data, predecessor, salt);
        _schedule(id, delay);
        emit CallScheduled(id, 0, target, value, data, predecessor, delay);
    }

    /**
     * @dev Schedule an operation containing a batch of transactions.
     *
     * Emits one {CallScheduled} event per transaction in the batch.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function scheduleBatch(address[] calldata targets, uint256[] calldata values, bytes[] calldata datas, bytes32 predecessor, bytes32 salt, uint256 delay) public virtual onlyRole(PROPOSER_ROLE) {
        require(targets.length == values.length, "TimelockController: length mismatch");
        require(targets.length == datas.length, "TimelockController: length mismatch");

        bytes32 id = hashOperationBatch(targets, values, datas, predecessor, salt);
        _schedule(id, delay);
        for (uint256 i = 0; i < targets.length; ++i) {
            emit CallScheduled(id, i, targets[i], values[i], datas[i], predecessor, delay);
        }
    }

    /**
     * @dev Schedule an operation that is to becomes valid after a given delay.
     */
    function _schedule(bytes32 id, uint256 delay) private {
        require(!isOperation(id), "TimelockController: operation already scheduled");
        require(delay >= getMinDelay(), "TimelockController: insufficient delay");
        // solhint-disable-next-line not-rely-on-time
        _timestamps[id] = SafeMath.add(block.timestamp, delay);
    }

    /**
     * @dev Cancel an operation.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function cancel(bytes32 id) public virtual onlyRole(PROPOSER_ROLE) {
        require(isOperationPending(id), "TimelockController: operation cannot be cancelled");
        delete _timestamps[id];

        emit Cancelled(id);
    }

    /**
     * @dev Execute an (ready) operation containing a single transaction.
     *
     * Emits a {CallExecuted} event.
     *
     * Requirements:
     *
     * - the caller must have the 'executor' role.
     */
    function execute(address target, uint256 value, bytes calldata data, bytes32 predecessor, bytes32 salt) public payable virtual onlyRole(EXECUTOR_ROLE) {
        bytes32 id = hashOperation(target, value, data, predecessor, salt);
        _beforeCall(id, predecessor);
        _call(id, 0, target, value, data);
        _afterCall(id);
    }

    /**
     * @dev Execute an (ready) operation containing a batch of transactions.
     *
     * Emits one {CallExecuted} event per transaction in the batch.
     *
     * Requirements:
     *
     * - the caller must have the 'executor' role.
     */
    function executeBatch(address[] calldata targets, uint256[] calldata values, bytes[] calldata datas, bytes32 predecessor, bytes32 salt) public payable virtual onlyRole(EXECUTOR_ROLE) {
        require(targets.length == values.length, "TimelockController: length mismatch");
        require(targets.length == datas.length, "TimelockController: length mismatch");

        bytes32 id = hashOperationBatch(targets, values, datas, predecessor, salt);
        _beforeCall(id, predecessor);
        for (uint256 i = 0; i < targets.length; ++i) {
            _call(id, i, targets[i], values[i], datas[i]);
        }
        _afterCall(id);
    }

    /**
     * @dev Checks before execution of an operation's calls.
     */
    function _beforeCall(bytes32 id, bytes32 predecessor) private view {
        require(isOperationReady(id), "TimelockController: operation is not ready");
        require(predecessor == bytes32(0) || isOperationDone(predecessor), "TimelockController: missing dependency");
    }

    /**
     * @dev Checks after execution of an operation's calls.
     */
    function _afterCall(bytes32 id) private {
        require(isOperationReady(id), "TimelockController: operation is not ready");
        _timestamps[id] = _DONE_TIMESTAMP;
    }

    /**
     * @dev Execute an operation's call.
     *
     * Emits a {CallExecuted} event.
     */
    function _call(bytes32 id, uint256 index, address target, uint256 value, bytes calldata data) private {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success,) = target.call{value: value}(data);
        require(success, "TimelockController: underlying transaction reverted");

        emit CallExecuted(id, index, target, value, data);
    }

    /**
     * @dev Changes the minimum timelock duration for future operations.
     *
     * Emits a {MinDelayChange} event.
     *
     * Requirements:
     *
     * - the caller must be the timelock itself. This can only be achieved by scheduling and later executing
     * an operation where the timelock is the target and the data is the ABI-encoded call to this function.
     */
    function updateDelay(uint256 newDelay) external virtual {
        require(msg.sender == address(this), "TimelockController: caller must be timelock");
        emit MinDelayChange(_minDelay, newDelay);
        _minDelay = newDelay;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

// This file imports external contracts that are used by this project,
// forcing Hardhat to compile them.

import "@openzeppelin/contracts/access/TimelockController.sol";
import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/ProxyAdmin.sol";

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./UpgradeableProxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is UpgradeableProxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {UpgradeableProxy-constructor}.
     */
    constructor(address _logic, address admin_, bytes memory _data) public payable UpgradeableProxy(_logic, _data) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _setAdmin(admin_);
    }

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _admin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        require(newAdmin != address(0), "TransparentUpgradeableProxy: new admin is the zero address");
        emit AdminChanged(_admin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external virtual ifAdmin {
        _upgradeTo(newImplementation);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable virtual ifAdmin {
        _upgradeTo(newImplementation);
        Address.functionDelegateCall(newImplementation, data);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address adm) {
        bytes32 slot = _ADMIN_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            adm := sload(slot)
        }
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        bytes32 slot = _ADMIN_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newAdmin)
        }
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _admin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../access/Ownable.sol";
import "./TransparentUpgradeableProxy.sol";

/**
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 */
contract ProxyAdmin is Ownable {

    /**
     * @dev Returns the current implementation of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyImplementation(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"5c60da1b");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the current admin of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyAdmin(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"f851a440");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Changes the admin of `proxy` to `newAdmin`.
     *
     * Requirements:
     *
     * - This contract must be the current admin of `proxy`.
     */
    function changeProxyAdmin(TransparentUpgradeableProxy proxy, address newAdmin) public virtual onlyOwner {
        proxy.changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgrade(TransparentUpgradeableProxy proxy, address implementation) public virtual onlyOwner {
        proxy.upgradeTo(implementation);
    }

    /**
     * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation. See
     * {TransparentUpgradeableProxy-upgradeToAndCall}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgradeAndCall(TransparentUpgradeableProxy proxy, address implementation, bytes memory data) public payable virtual onlyOwner {
        proxy.upgradeToAndCall{value: msg.value}(implementation, data);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

import "../interfaces/IVotingEscrow.sol";

contract VotingEscrowCallback is IVotingEscrowCallback, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    event CallbackHandleAdded(address callbackHandle);
    event CallbackHandleRemoved(address callbackHandle);

    EnumerableSet.AddressSet private _handles;

    function getCallbackHandles() external view returns (address[] memory handles) {
        uint256 length = _handles.length();
        handles = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            handles[i] = _handles.at(i);
        }
    }

    function addCallbackHandle(address callbackHandle) external onlyOwner {
        if (_handles.add(callbackHandle)) {
            emit CallbackHandleAdded(callbackHandle);
        }
    }

    function removeCallbackHandle(address callbackHandle) external onlyOwner {
        if (_handles.remove(callbackHandle)) {
            emit CallbackHandleRemoved(callbackHandle);
        }
    }

    function syncWithVotingEscrow(address account) external override {
        uint256 count = _handles.length();
        for (uint256 i = 0; i < count; i++) {
            IVotingEscrowCallback(_handles.at(i)).syncWithVotingEscrow(account);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "../interfaces/IVotingEscrow.sol";

interface IClaimRewards {
    function claimRewards(address account) external;

    function claimRewardsAndUnwrap(address account) external;
}

contract BatchOperationHelper {
    string public constant VERSION = "2.0.0";

    function batchClaimRewards(address[] calldata contracts, address account) public {
        uint256 count = contracts.length;
        for (uint256 i = 0; i < count; i++) {
            IClaimRewards(contracts[i]).claimRewards(account);
        }
    }

    function batchClaimRewardsAndUnwrap(
        address[] calldata contracts,
        address[] calldata wrappedContracts,
        address account
    ) external {
        batchClaimRewards(contracts, account);
        uint256 count = wrappedContracts.length;
        for (uint256 i = 0; i < count; i++) {
            IClaimRewards(wrappedContracts[i]).claimRewardsAndUnwrap(account);
        }
    }

    function batchSyncWithVotingEscrow(address[] calldata contracts, address account) external {
        uint256 count = contracts.length;
        for (uint256 i = 0; i < count; i++) {
            IVotingEscrowCallback(contracts[i]).syncWithVotingEscrow(account);
        }
    }
}