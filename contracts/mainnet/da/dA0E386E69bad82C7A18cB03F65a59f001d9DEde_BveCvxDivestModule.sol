// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "EnumerableSet.sol";
import "Pausable.sol";
import "ReentrancyGuard.sol";
import "IERC20.sol";
import "Math.sol";
import "KeeperCompatibleInterface.sol";

import "IGnosisSafe.sol";
import "ICurvePool.sol";
import "IUniswapRouterV3.sol";
import "IBvecvx.sol";

import {ModuleUtils} from "ModuleUtils.sol";

/// @title   BveCvxDivestModule
/// @dev  Allows whitelisted executors to trigger `performUpkeep` with limited scoped
/// in our case to carry the divesting of bveCVX into USDC whenever unlocks in schedules
/// occurs with a breathing factor determined by `factorWd` to allow users to withdraw
contract BveCvxDivestModule is
    ModuleUtils,
    KeeperCompatibleInterface,
    Pausable,
    ReentrancyGuard
{
    using EnumerableSet for EnumerableSet.AddressSet;

    /* ========== STATE VARIABLES ========== */
    address public guardian;
    uint256 public factorWd;
    uint256 public weeklyCvxSpotAmount;
    uint256 public lastEpochIdWithdraw;
    uint256 public minOutBps;

    EnumerableSet.AddressSet internal _executors;

    /* ========== EVENT ========== */

    event ExecutorAdded(address indexed _user, uint256 _timestamp);
    event ExecutorRemoved(address indexed _user, uint256 _timestamp);

    event GuardianUpdated(
        address indexed newGuardian,
        address indexed oldGuardian,
        uint256 timestamp
    );
    event FactorWdUpdated(
        uint256 newMaxFactorWd,
        uint256 oldMaxFactorWd,
        uint256 timestamp
    );
    event WeeklyCvxSpotAmountUpdated(
        uint256 newWeeklyCvxSpotAmount,
        uint256 oldWeeklyCvxSpotAmount,
        uint256 timestamp
    );
    event MinOutBpsUpdated(
        uint256 newMinOutBps,
        uint256 oldMinOutBps,
        uint256 timestamp
    );

    constructor(address _guardian) {
        guardian = _guardian;

        // as per decision defaulted to 70%
        factorWd = 7_000;
        // as per decision defaulted to 5k/weekly
        weeklyCvxSpotAmount = 5_000e18;
        // min bps out defaulted to 9_750
        // significant due to curve cvx-eth pool and CL oracle divergences in min amount
        minOutBps = 9_750;
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
        address oldGuardian = guardian;
        guardian = _guardian;
        emit GuardianUpdated(_guardian, oldGuardian, block.timestamp);
    }

    /// @dev Updates the withdrawable factor
    /// @notice Only callable by governance or guardian. Guardian for agility.
    /// @param _factor New factor value to be set for `factorWd`
    function setWithdrawableFactor(uint256 _factor)
        external
        onlyGovernanceOrGuardian
    {
        require(_factor <= MAX_FACTOR_WD, ">MAX_FACTOR_WD!");
        uint256 oldmaxFactorWd = factorWd;
        factorWd = _factor;
        emit FactorWdUpdated(_factor, oldmaxFactorWd, block.timestamp);
    }

    /// @dev Updates weekly cvx amount allowance to sell in spot
    /// @notice Only callable by governance or guardian. Guardian for agility.
    /// @param _amount New amount value to be set for `weeklyCvxSpotAmount`
    function setWeeklyCvxSpotAmount(uint256 _amount)
        external
        onlyGovernanceOrGuardian
    {
        uint256 oldWeeklyCvxSpotAmount = weeklyCvxSpotAmount;
        weeklyCvxSpotAmount = _amount;
        emit WeeklyCvxSpotAmountUpdated(
            _amount,
            oldWeeklyCvxSpotAmount,
            block.timestamp
        );
    }

    /// @dev Updates `minOutBps` for providing flexibility slippage control in swaps
    /// @notice Only callable by governance or guardian. Guardian for agility.
    /// @param _minBps New min bps out value for swaps
    function setMinOutBps(uint256 _minBps) external onlyGovernanceOrGuardian {
        require(_minBps >= MIN_OUT_SWAP, "<MIN_OUT_SWAP!");
        uint256 oldMinOutBps = minOutBps;
        minOutBps = _minBps;
        emit MinOutBpsUpdated(_minBps, oldMinOutBps, block.timestamp);
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
        // NOTE: if there is anything available to wd, keeper will proceed & ts lower than 00:00 utc 6th Jan
        if (
            totalCvxWithdrawable() > 0 &&
            BVE_CVX.balanceOf(address(SAFE)) > 0 &&
            LOCKER.epochCount() > lastEpochIdWithdraw &&
            block.timestamp <= KEEPER_DEADLINE
        ) {
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
        if (LOCKER.epochCount() > lastEpochIdWithdraw) {
            // 1. wd bvecvx with factor threshold set in `factorWd`
            _withdrawBveCvx();
            // 2. swap cvx balance to weth
            _swapCvxForWeth();
            // 3. swap weth to usdc and send to treasury
            _swapWethToUsdc();
        }
    }

    /***************************************
                INTERNAL
    ****************************************/

    function _withdrawBveCvx() internal {
        uint256 bveCVXSafeBal = BVE_CVX.balanceOf(address(SAFE));
        if (bveCVXSafeBal > 0) {
            uint256 totalCvxWithdrawable = totalCvxWithdrawable();
            /// @dev covers corner case when nothing might be withdrawable
            if (totalCvxWithdrawable > 0) {
                uint256 bveCvxBalance = BVE_CVX.balance();
                uint256 bveCvxTotalSupply = BVE_CVX.totalSupply();

                uint256 totalWdBveCvx = (((totalCvxWithdrawable *
                    bveCvxTotalSupply) / bveCvxBalance) * factorWd) / MAX_BPS;

                uint256 toWithdraw = Math.min(totalWdBveCvx, bveCVXSafeBal);

                _checkTransactionAndExecute(
                    address(BVE_CVX),
                    abi.encodeCall(IBveCvx.withdraw, toWithdraw)
                );
            }
        }
    }

    function _swapCvxForWeth() internal {
        uint256 cvxBal = CVX.balanceOf(address(SAFE));
        if (cvxBal > 0) {
            uint256 cvxSpotSell = weeklyCvxSpotAmount > cvxBal
                ? cvxBal
                : weeklyCvxSpotAmount;
            lastEpochIdWithdraw = LOCKER.epochCount();

            if (cvxSpotSell > 0) {
                // 1. Approve CVX into curve pool
                _checkTransactionAndExecute(
                    address(CVX),
                    abi.encodeCall(
                        IERC20.approve,
                        (CVX_ETH_CURVE_POOL, cvxSpotSell)
                    )
                );
                // 2. Swap CVX -> WETH
                _checkTransactionAndExecute(
                    CVX_ETH_CURVE_POOL,
                    abi.encodeCall(
                        ICurvePool.exchange,
                        (
                            1,
                            0,
                            cvxSpotSell,
                            (getCvxAmountInEth(cvxSpotSell) * minOutBps) /
                                MAX_BPS
                        )
                    )
                );
            }
        }
    }

    function _swapWethToUsdc() internal {
        // Swap WETH -> USDC
        uint256 wethBal = WETH.balanceOf(address(SAFE));
        if (wethBal > 0) {
            // 1. Approve WETH into univ3 router
            _checkTransactionAndExecute(
                address(WETH),
                abi.encodeCall(IERC20.approve, (UNIV3_ROUTER, wethBal))
            );
            // 2. Swap WETH to USDC
            IUniswapRouterV3.ExactInputSingleParams memory params = IUniswapRouterV3
                .ExactInputSingleParams({
                    tokenIn: address(WETH),
                    tokenOut: address(USDC),
                    fee: uint24(500),
                    recipient: TREASURY,
                    deadline: type(uint256).max,
                    amountIn: wethBal,
                    amountOutMinimum: (getWethAmountInUsdc(wethBal) *
                        minOutBps) / MAX_BPS,
                    sqrtPriceLimitX96: 0 // Inactive param
                });
            _checkTransactionAndExecute(
                UNIV3_ROUTER,
                abi.encodeCall(IUniswapRouterV3.exactInputSingle, (params))
            );
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

    /// @dev returns the total amount withdrawable at current moment
    /// @return totalWdCvx Total amount of CVX withdrawable, summation of available in vault, strat and unlockable
    function totalCvxWithdrawable() public view returns (uint256 totalWdCvx) {
        /// @dev check avail CONVEX to avoid wd reverts
        uint256 cvxInVault = CVX.balanceOf(address(BVE_CVX));
        uint256 cvxInStrat = CVX.balanceOf(BVECVX_STRAT);
        (, uint256 unlockableStrat, , ) = LOCKER.lockedBalances(BVECVX_STRAT);
        totalWdCvx = cvxInVault + cvxInStrat + unlockableStrat;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

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
        return a / b + (a % b == 0 ? 0 : 1);
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
pragma solidity ^0.8.0;

interface ICurvePool {
    // Exchange using WETH by default
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external returns (uint256);

    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy, address receiver)
        external
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapRouterV3 {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBveCvx {
    function approveContractAccess(address account) external;

    function balanceOf(address account) external view returns (uint256);

    function balance() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function withdraw(uint256 _amount) external;

    function withdrawAll() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "IAggregatorV3.sol";

import {ModuleConstants} from "ModuleConstants.sol";

contract ModuleUtils is ModuleConstants {
    /* ========== ERRORS ========== */

    error StalePriceFeed(
        uint256 currentTime,
        uint256 updateTime,
        uint256 maxPeriod
    );

    function getCvxAmountInEth(uint256 _cvxAmount)
        internal
        view
        returns (uint256 ethAmount_)
    {
        uint256 cvxInEth = fetchPriceFromClFeed(
            CVX_ETH_FEED,
            CL_FEED_DAY_HEARTBEAT
        );
        // Divisor is 10^18 and uint256 max ~ 10^77 so this shouldn't overflow for normal amounts
        ethAmount_ = (_cvxAmount * cvxInEth) / FEED_DIVISOR_ETH;
    }

    function getWethAmountInUsdc(uint256 _wethAmount)
        internal
        view
        returns (uint256 usdcAmount_)
    {
        uint256 usdcInWeth = fetchPriceFromClFeed(
            USDC_ETH_FEED,
            CL_FEED_DAY_HEARTBEAT
        );
        // Divide by the rate from oracle since it is dai expressed in eth
        // FEED_USDC_MULTIPLIER has 1e6 precision
        usdcAmount_ = (_wethAmount * FEED_USDC_MULTIPLIER) / usdcInWeth;
    }

    function fetchPriceFromClFeed(IAggregatorV3 _feed, uint256 _maxStalePeriod)
        internal
        view
        returns (uint256 answerUint256_)
    {
        (, int256 answer, , uint256 updateTime, ) = _feed.latestRoundData();

        if (block.timestamp - updateTime > _maxStalePeriod) {
            revert StalePriceFeed(block.timestamp, updateTime, _maxStalePeriod);
        }

        answerUint256_ = uint256(answer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAggregatorV3 {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestTimestamp() external view returns (uint256);

    function latestAnswer() external view returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "IERC20.sol";
import "IAggregatorV3.sol";

import "IGnosisSafe.sol";
import "IBveCvx.sol";
import "ICvxLocker.sol";

abstract contract ModuleConstants {
    address public constant TREASURY =
        0xD0A7A8B98957b9CD3cFB9c0425AbE44551158e9e;
    address public constant GOVERNANCE =
        0xA9ed98B5Fb8428d68664f3C5027c62A10d45826b;
    IGnosisSafe public constant SAFE = IGnosisSafe(GOVERNANCE);

    // badger product
    IBveCvx internal constant BVE_CVX =
        IBveCvx(0xfd05D3C7fe2924020620A8bE4961bBaA747e6305);
    address internal constant BVECVX_STRAT =
        0x898111d1F4eB55025D0036568212425EE2274082;

    // convex locker v2
    ICvxLocker internal constant LOCKER =
        ICvxLocker(0x72a19342e8F1838460eBFCCEf09F6585e32db86E);

    // tokens involved
    IERC20 internal constant CVX =
        IERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    IERC20 internal constant WETH =
        IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 internal constant USDC =
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    // curve pools
    address internal constant CVX_ETH_CURVE_POOL =
        0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4;

    // uniswap v3
    address internal constant UNIV3_ROUTER =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;

    // CL feed oracles
    IAggregatorV3 internal constant CVX_ETH_FEED =
        IAggregatorV3(0xC9CbF687f43176B302F03f5e58470b77D07c61c6);
    IAggregatorV3 internal constant USDC_ETH_FEED =
        IAggregatorV3(0x986b5E1e1755e3C2440e960477f25201B0a8bbD4);
    uint256 internal constant CL_FEED_DAY_HEARTBEAT = 24 hours;

    // NOTE: all CL eth feeds are expressed in 18 decimals
    uint256 internal constant FEED_DIVISOR_ETH = 1e18;
    uint256 internal constant FEED_USDC_MULTIPLIER = 1e6;

    uint256 constant MAX_BPS = 10_000;
    uint256 constant MAX_FACTOR_WD = 7_000;
    uint256 constant MIN_OUT_SWAP = 9_500;

    // hardcoded timestamp where keeper always should return `false`
    uint256 constant KEEPER_DEADLINE = 1672963200;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBveCvx {
    function approveContractAccess(address account) external;

    function balanceOf(address account) external view returns (uint256);

    function balance() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function withdraw(uint256 _amount) external;

    function withdrawAll() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICvxLocker {
    struct LockedBalance {
        uint112 amount;
        uint112 boosted;
        uint32 unlockTime;
    }

    function checkpointEpoch() external;

    function epochCount() external view returns (uint256);

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