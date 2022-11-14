// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "EnumerableSet.sol";
import "Pausable.sol";
import "ReentrancyGuard.sol";
import "IERC20.sol";
import "KeeperCompatible.sol";

import "IGnosisSafe.sol";
import "ILockAura.sol";
import "IGravi.sol";

/// @title   VoterModule
/// @author  Petrovska @ BadgerDAO
/// @dev  Allows whitelisted executors to trigger `performUpkeep` with limited scoped
/// in our case to carry voter weekly chores
/// Inspired from: https://github.com/gnosis/zodiac-guard-scope
contract VoterModule is KeeperCompatibleInterface, Pausable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;

    /* ========== CONSTANTS VARIABLES ========== */
    address public constant GOVERNANCE =
        0xA9ed98B5Fb8428d68664f3C5027c62A10d45826b;
    IGnosisSafe public constant SAFE = IGnosisSafe(GOVERNANCE);
    IERC20 public constant AURA =
        IERC20(0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF);
    IERC20 public constant AURABAL =
        IERC20(0x616e8BfA43F920657B3497DBf40D6b1A02D4608d);
    ILockAura public constant LOCKER =
        ILockAura(0x3Fa73f1E5d8A792C80F426fc8F84FBF7Ce9bBCAC);
    IGravi constant GRAVI = IGravi(0xBA485b556399123261a5F9c95d413B4f93107407);
    address constant TROPS = 0x042B32Ac6b453485e357938bdC38e0340d4b9276;
    address constant GRAVI_STRAT = 0x3c0989eF27e3e3fAb87a2d7C38B35880C90E63b5;

    /* ========== STATE VARIABLES ========== */
    address public guardian;
    uint256 public lastRewardClaimTimestamp;
    uint256 public claimingInterval;

    EnumerableSet.AddressSet internal _executors;

    /* ========== EVENT ========== */
    event RewardPaid(
        address indexed _user,
        address indexed _rewardToken,
        uint256 _amount,
        uint256 _timestamp
    );
    event ExecutorAdded(address indexed _user, uint256 _timestamp);
    event ExecutorRemoved(address indexed _user, uint256 _timestamp);
    event GuardianUpdated(
        address indexed newGuardian,
        address indexed oldGuardian,
        uint256 timestamp
    );

    constructor(
        address _guardian,
        uint64 _startTimestamp,
        uint256 _claimingIntervalSeconds
    ) {
        guardian = _guardian;
        lastRewardClaimTimestamp = _startTimestamp;
        claimingInterval = _claimingIntervalSeconds;
    }

    /***************************************
                    MODIFIERS
    ****************************************/
    modifier onlyGovernance() {
        require(msg.sender == GOVERNANCE, "not-governance!");
        _;
    }

    modifier onlyExecutors() {
        require(_executors.contains(msg.sender), "not-executor!");
        _;
    }

    modifier onlyGovernanceOrGuardian() {
        require(
            msg.sender == GOVERNANCE || msg.sender == guardian,
            "not-gov-or-guardian"
        );
        _;
    }

    /***************************************
               ADMIN - GOVERNANCE
    ****************************************/
    /// @dev Adds an executor to the Set of allowed addresses.
    /// @notice Only callable by governance.
    /// @param _executor Address which will have rights to call `checkTransactionAndExecute`.
    function addExecutor(address _executor) external onlyGovernance {
        require(_executor != address(0), "zero-address!");
        require(_executors.add(_executor), "not-add-in-set!");
        emit ExecutorAdded(_executor, block.timestamp);
    }

    /// @dev Removes an executor to the Set of allowed addresses.
    /// @notice Only callable by governance.
    /// @param _executor Address which will not have rights to call `checkTransactionAndExecute`.
    function removeExecutor(address _executor) external onlyGovernance {
        require(_executor != address(0), "zero-address!");
        require(_executors.remove(_executor), "not-remove-in-set!");
        emit ExecutorRemoved(_executor, block.timestamp);
    }

    /// @dev Updates the guardian address
    /// @notice Only callable by governance.
    /// @param _guardian Address which will beccome guardian
    function setGuardian(address _guardian) external onlyGovernance {
        require(_guardian != address(0), "zero-address!");
        address oldGuardian = _guardian;
        guardian = _guardian;
        emit GuardianUpdated(_guardian, oldGuardian, block.timestamp);
    }

    /// @dev Pauses the contract, which prevents executing performUpkeep.
    function pause() external onlyGovernanceOrGuardian {
        _pause();
    }

    /// @dev Unpauses the contract.
    function unpause() external onlyGovernance {
        _unpause();
    }

    /***************************************
                KEEPERS - EXECUTORS
    ****************************************/
    /// @dev Runs off-chain at every block to determine if the `performUpkeep`
    /// function should be called on-chain.
    function checkUpkeep(bytes calldata)
        external
        view
        override
        whenNotPaused
        returns (bool upkeepNeeded, bytes memory checkData)
    {
        (
            uint256 unlockable,
            uint256 rewards,
            uint256 aurabalSafeBal,
            bool isGraviWithdrawable
        ) = checkUpKeepConditions();

        if (unlockable > 0) {
            // prio expired locks
            upkeepNeeded = true;
        } else if (isRewardClaimable(rewards, aurabalSafeBal)) {
            upkeepNeeded = true;
        } else if (isGraviWithdrawable) {
            upkeepNeeded = true;
        }
    }

    /// @dev Contains the logic that should be executed on-chain when
    /// `checkUpkeep` returns true.
    function performUpkeep(bytes calldata performData)
        external
        override
        onlyExecutors
        whenNotPaused
        nonReentrant
    {
        /// @dev safety check, ensuring onchain module is config
        require(SAFE.isModuleEnabled(address(this)), "no-module-enabled!");
        // 1. process unlocks
        _processExpiredLocks();
        // 2. claim vlaura rewards and transfer aurabal to trops
        _claimRewardsAndSweep();
        // 3. wd gravi and lock aura in voter
        _withdrawGraviAndLockAura();
    }

    /// @dev method will process expired locks if available
    function _processExpiredLocks() internal {
        (, uint256 unlockable, , ) = LOCKER.lockedBalances(address(SAFE));
        if (unlockable > 0) {
            _checkTransactionAndExecute(
                address(LOCKER),
                abi.encodeCall(ILockAura.processExpiredLocks, true)
            );
        }
    }

    /// @dev method will claim auraBAL & transfer balance to trops
    function _claimRewardsAndSweep() internal {
        ILockAura.EarnedData[] memory earnData = LOCKER.claimableRewards(
            address(SAFE)
        );
        uint256 aurabalSafeBal = AURABAL.balanceOf(address(SAFE));
        if (isRewardClaimable(earnData[0].amount, aurabalSafeBal)) {
            /// @dev will be used as condition, so rewards are not claim that often, leave time for accum
            lastRewardClaimTimestamp = block.timestamp;
            if (earnData[0].amount > 0) {
                _checkTransactionAndExecute(
                    address(LOCKER),
                    abi.encodeCall(ILockAura.getReward, address(SAFE))
                );
                aurabalSafeBal = AURABAL.balanceOf(address(SAFE));
            }
            _checkTransactionAndExecute(
                address(AURABAL),
                abi.encodeCall(IERC20.transfer, (TROPS, aurabalSafeBal))
            );
            emit RewardPaid(
                address(SAFE),
                address(AURABAL),
                aurabalSafeBal,
                lastRewardClaimTimestamp
            );
        }
    }

    /// @dev method will wd from graviaura and lock aura in voter msig
    function _withdrawGraviAndLockAura() internal {
        uint256 graviSafeBal = GRAVI.balanceOf(address(SAFE));
        if (graviSafeBal > 0) {
            uint256 totalWdAura = totalAuraWithdrawable();
            /// @dev covers corner case when nothing might be withdrawable
            if (totalWdAura > 0) {
                uint256 graviBalance = GRAVI.balance();
                uint256 graviTotalSupply = GRAVI.totalSupply();
                /// @dev depends on condition we will do a full wd or partial
                if (
                    totalWdAura <
                    (graviSafeBal * graviBalance) / graviTotalSupply
                ) {
                    _checkTransactionAndExecute(
                        address(GRAVI),
                        abi.encodeCall(
                            IGravi.withdraw,
                            (totalWdAura * graviTotalSupply) / graviBalance
                        )
                    );
                } else {
                    _checkTransactionAndExecute(
                        address(GRAVI),
                        abi.encodeWithSelector(IGravi.withdrawAll.selector)
                    );
                }
            }

            uint256 auraSafeBal = AURA.balanceOf(address(SAFE));
            if (auraSafeBal > 0) {
                /// @dev approves aura to process in locker
                _checkTransactionAndExecute(
                    address(AURA),
                    abi.encodeCall(
                        IERC20.approve,
                        (address(LOCKER), auraSafeBal)
                    )
                );
                /// @dev lock aura in locker
                _checkTransactionAndExecute(
                    address(LOCKER),
                    abi.encodeCall(ILockAura.lock, (address(SAFE), auraSafeBal))
                );
            }
        }
    }

    /// @dev Allows executing specific calldata into an address thru a gnosis-safe, which have enable this contract as module.
    /// @notice Only callable by executors.
    /// @param to Contract address where we will execute the calldata.
    /// @param data Calldata to be executed within the boundaries of the `allowedFunctions`.
    function _checkTransactionAndExecute(address to, bytes memory data)
        internal
    {
        if (data.length >= 4) {
            require(
                SAFE.execTransactionFromModule(
                    to,
                    0,
                    data,
                    IGnosisSafe.Operation.Call
                ),
                "exec-error!"
            );
        }
    }

    /***************************************
               PUBLIC FUNCTION
    ****************************************/

    /// @dev Returns all addresses which have executor role
    function getExecutors() public view returns (address[] memory) {
        return _executors.values();
    }

    /// @dev uint256 value-conditions to trigger `performUpKeep`
    /// @return Values for `unlockable` locks expired, `rewards` auraBAL accumulated & `graviAURA` balance in voter
    function checkUpKeepConditions()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            bool
        )
    {
        /// @dev multi-conditional upkeep checks
        (, uint256 unlockable, , ) = LOCKER.lockedBalances(address(SAFE));
        ILockAura.EarnedData[] memory earnData = LOCKER.claimableRewards(
            address(SAFE)
        );
        uint256 aurabalSafeBal = AURABAL.balanceOf(address(SAFE));
        uint256 graviBal = GRAVI.balanceOf(address(SAFE));

        return (
            unlockable,
            earnData[0].amount,
            aurabalSafeBal,
            graviBal > 0 && totalAuraWithdrawable() > 0
        );
    }

    /// @dev reusable view method for checking if auraBAL rewards are claimable
    /// @param claimableRewards available auraBAL rewards amount
    /// @param safeRewardsBal current value of auraBAL in the voter safe
    /// @return boolean conditional to determine if we should trigger `_claimRewardsAndSweep` section
    function isRewardClaimable(uint256 claimableRewards, uint256 safeRewardsBal)
        public
        view
        returns (bool)
    {
        return
            (claimableRewards > 0 || safeRewardsBal > 0) &&
            (block.timestamp - lastRewardClaimTimestamp) > claimingInterval;
    }

    /// @dev returns the total amount withdrawable at current moment
    /// @return totalWdAura Total amount of AURA withdrawable, summation of available in vault, strat and unlockable
    function totalAuraWithdrawable() public view returns (uint256 totalWdAura) {
        /// @dev check avail aura to avoid wd reverts
        uint256 auraInVault = AURA.balanceOf(address(GRAVI));
        uint256 auraInStrat = AURA.balanceOf(address(GRAVI_STRAT));
        (, uint256 unlockableStrat, , ) = LOCKER.lockedBalances(GRAVI_STRAT);
        totalWdAura = auraInVault + auraInStrat + unlockableStrat;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

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
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
pragma solidity ^0.8.0;

import "KeeperBase.sol";
import "KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IGnosisSafe {
    event DisabledModule(address module);
    event EnabledModule(address module);

    enum Operation {
        Call,
        DelegateCall
    }

    /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes calldata data,
        Operation operation
    ) external returns (bool success);

    function enableModule(address module) external;
    
    function disableModule(address prevModule, address module) external;

    function getModules() external view returns (address[] memory);

    function isModuleEnabled(address module) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ILockAura {
    struct LockedBalance {
        uint112 amount;
        uint32 unlockTime;
    }

    struct EarnedData {
        address token;
        uint256 amount;
    }

    function getReward(address _account) external;

    function processExpiredLocks(bool _relock) external;

    function lock(address _account, uint256 _amount) external;

    function claimableRewards(address _account)
        external
        view
        returns (EarnedData[] memory userRewards);

    function lockedBalances(address _user)
        external
        view
        returns (
            uint256 total,
            uint256 unlockable,
            uint256 locked,
            LockedBalance[] memory lockData
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IGravi {
    function balanceOf(address account) external view returns (uint256);

    function balance() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function withdraw(uint256 _amount) external;

    function withdrawAll() external;
}