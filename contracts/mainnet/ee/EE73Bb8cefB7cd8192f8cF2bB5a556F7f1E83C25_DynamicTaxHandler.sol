// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./ITaxHandler.sol";
import "../utils/ExchangePoolProcessor.sol";

/**
 * @title Dynamic tax handler
 * @notice Processes tax for a given token transfer. Checks for the following:
 * - Is the address on the static blacklist? If so, it can only transfer to the
 *   `receiver` address. In all other cases, the transfer will fail.
 * - Is the address exempt from taxes, if so, the number of taxed tokens is
 *   always zero.
 * - Is it a transfer between "regular" users? This means they are not on the
 *   list of either blacklisted or exempt addresses, nor are they an address
 *   designated as an exchange pool.
 * - Is it a transfer towards or from an exchange pool? If so, the transaction
 *   is taxed according to its relative size to the exchange pool.
 */
contract DynamicTaxHandler is ITaxHandler, ExchangePoolProcessor {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct TaxCheckpoint {
        uint256 threshold;
        uint256 basisPoints;
    }

    /// @notice The default buy tax in basis points.
    uint256 public baseBuyTaxBasisPoints;

    /// @notice The default sell tax in basis points.
    uint256 public baseSellTaxBasisPoints;

    /// @dev The registry of buy tax checkpoints. Used to keep track of the
    /// correct number of tokens to deduct as tax when buying.
    mapping(uint256 => TaxCheckpoint) private _buyTaxBasisPoints;

    /// @dev The number of buy tax checkpoints in the registry.
    uint256 private _buyTaxPoints;

    /// @dev The registry of sell tax checkpoints. Used to keep track of the
    /// correct number of tokens to deduct as tax when selling.
    mapping(uint256 => TaxCheckpoint) private _sellTaxBasisPoints;

    /// @dev The number of sell tax checkpoints in the registry.
    uint256 private _sellTaxPoints;

    /// @dev Immutable list of blacklisted addresses.
    address[] private blacklisted;

    /// @notice The only address the blacklisted addresses can still transfer tokens to.
    address public immutable receiver;

    /// @dev The set of addresses exempt from tax.
    EnumerableSet.AddressSet private _exempted;

    /// @notice The token to account for.
    IERC20 public token;

    /// @notice Emitted whenever the base buy tax basis points value is changed.
    event BaseBuyTaxBasisPointsChanged(uint256 previousValue, uint256 newValue);

    /// @notice Emitted whenever the base sell tax basis points value is changed.
    event BaseSellTaxBasisPointsChanged(uint256 previousValue, uint256 newValue);

    /// @notice Emitted whenever a buy tax checkpoint is added.
    event BuyTaxCheckpointAdded(uint256 threshold, uint256 basisPoints);

    /// @notice Emitted whenever a buy tax checkpoint is removed.
    event BuyTaxCheckpointRemoved(uint256 threshold, uint256 basisPoints);

    /// @notice Emitted whenever a sell tax checkpoint is added.
    event SellTaxCheckpointAdded(uint256 threshold, uint256 basisPoints);

    /// @notice Emitted whenever a sell tax checkpoint is removed.
    event SellTaxCheckpointRemoved(uint256 threshold, uint256 basisPoints);

    /// @notice Emitted when an address is added to or removed from the exempted addresses set.
    event TaxExemptionUpdated(address indexed wallet, bool exempted);

    /**
     * @param tokenAddress Address of the token to account for when interacting
     * with exchange pools.
     * @param receiverAddress The only address the blacklisted addresses can
     * send tokens to.
     * @param blacklistedAddresses The list of addresses that are banned from
     * performing transfers. They can still receive tokens however.
     */
    constructor(
        address tokenAddress,
        address receiverAddress,
        address[] memory blacklistedAddresses
    ) {
        token = IERC20(tokenAddress);
        receiver = receiverAddress;
        blacklisted = blacklistedAddresses;
    }

    /**
     * @notice Get number of tokens to pay as tax.
     * @dev There is no easy way to differentiate between a user swapping
     * tokens and a user adding or removing liquidity to the pool. In both
     * cases tokens are transferred to or from the pool. This is an unfortunate
     * case where users have to accept being taxed on liquidity additions and
     * removal. To get around this issue a separate liquidity addition contract
     * can be deployed. This contract could be exempt from taxes if its
     * functionality is verified to only add and remove liquidity.
     * @param benefactor Address of the benefactor.
     * @param beneficiary Address of the beneficiary.
     * @param amount Number of tokens in the transfer.
     * @return Number of tokens to pay as tax.
     */
    function getTax(
        address benefactor,
        address beneficiary,
        uint256 amount
    ) external view returns (uint256) {
        // Blacklisted addresses are only allowed to transfer to the receiver.
        if (isBlacklisted(benefactor)) {
            if (beneficiary == receiver) {
                return 0;
            } else {
                revert("DynamicTaxHandler:getTax:BLACKLISTED: Benefactor has been blacklisted");
            }
        }

        // Exempted addresses don't pay tax.
        if (_exempted.contains(benefactor) || _exempted.contains(beneficiary)) {
            return 0;
        }

        // Transactions between regular users (this includes contracts) aren't taxed.
        if (!_exchangePools.contains(benefactor) && !_exchangePools.contains(beneficiary)) {
            return 0;
        }

        // Transactions between pools aren't taxed.
        if (_exchangePools.contains(benefactor) && _exchangePools.contains(beneficiary)) {
            return 0;
        }

        uint256 poolBalance = token.balanceOf(primaryPool);
        uint256 basisPoints;

        // If the benefactor is found in the set of exchange pools, then it's a buy transactions, otherwise a sell
        // transactions, because the other use cases have already been checked above.
        if (_exchangePools.contains(benefactor)) {
            basisPoints = _getBuyTaxBasisPoints(amount, poolBalance);
        } else {
            basisPoints = _getSellTaxBasisPoints(amount, poolBalance);
        }

        return (amount * basisPoints) / 10000;
    }

    /**
     * @notice Set buy tax basis points value.
     * @param basisPoints The new buy tax basis points base value.
     */
    function setBaseBuyTaxBasisPoints(uint256 basisPoints) external onlyOwner {
        uint256 previousBuyTaxBasisPoints = baseBuyTaxBasisPoints;
        baseBuyTaxBasisPoints = basisPoints;

        emit BaseBuyTaxBasisPointsChanged(previousBuyTaxBasisPoints, basisPoints);
    }

    /**
     * @notice Set base sell tax basis points value.
     * @param basisPoints The new sell tax basis points base value.
     */
    function setBaseSellTaxBasisPoints(uint256 basisPoints) external onlyOwner {
        uint256 previousSellTaxBasisPoints = baseSellTaxBasisPoints;
        baseSellTaxBasisPoints = basisPoints;

        emit BaseSellTaxBasisPointsChanged(previousSellTaxBasisPoints, basisPoints);
    }

    /**
     * @notice Set buy tax checkpoints
     * @param thresholds Array containing the threshold values of the buy tax checkpoints.
     * @param basisPoints Array containing the basis points values of the buy tax checkpoints.
     */
    function setBuyTaxCheckpoints(uint256[] memory thresholds, uint256[] memory basisPoints) external onlyOwner {
        require(
            thresholds.length == basisPoints.length,
            "DynamicTaxHandler:setBuyTaxBasisPoints:UNEQUAL_LENGTHS: Array lengths should be equal."
        );

        // Reset previous points
        for (uint256 i = 0; i < _buyTaxPoints; i++) {
            emit BuyTaxCheckpointRemoved(_buyTaxBasisPoints[i].threshold, _buyTaxBasisPoints[i].basisPoints);

            _buyTaxBasisPoints[i].basisPoints = 0;
            _buyTaxBasisPoints[i].threshold = 0;
        }

        _buyTaxPoints = thresholds.length;
        for (uint256 i = 0; i < thresholds.length; i++) {
            _buyTaxBasisPoints[i] = TaxCheckpoint({ basisPoints: basisPoints[i], threshold: thresholds[i] });

            emit BuyTaxCheckpointAdded(_buyTaxBasisPoints[i].threshold, _buyTaxBasisPoints[i].basisPoints);
        }
    }

    /**
     * @notice Set sell tax checkpoints
     * @param thresholds Array containing the threshold values of the sell tax checkpoints.
     * @param basisPoints Array containing the basis points values of the sell tax checkpoints.
     */
    function setSellTaxCheckpoints(uint256[] memory thresholds, uint256[] memory basisPoints) external onlyOwner {
        require(
            thresholds.length == basisPoints.length,
            "DynamicTaxHandler:setSellTaxBasisPoints:UNEQUAL_LENGTHS: Array lengths should be equal."
        );

        // Reset previous points
        for (uint256 i = 0; i < _sellTaxPoints; i++) {
            emit SellTaxCheckpointRemoved(_sellTaxBasisPoints[i].threshold, _sellTaxBasisPoints[i].basisPoints);

            _sellTaxBasisPoints[i].basisPoints = 0;
            _sellTaxBasisPoints[i].threshold = 0;
        }

        _sellTaxPoints = thresholds.length;
        for (uint256 i = 0; i < thresholds.length; i++) {
            _sellTaxBasisPoints[i] = TaxCheckpoint({ basisPoints: basisPoints[i], threshold: thresholds[i] });

            emit SellTaxCheckpointAdded(_sellTaxBasisPoints[i].threshold, _sellTaxBasisPoints[i].basisPoints);
        }
    }

    /**
     * @notice Add address to set of tax-exempted addresses.
     * @param exemption Address to add to set of tax-exempted addresses.
     */
    function addExemption(address exemption) external onlyOwner {
        if (_exempted.add(exemption)) {
            emit TaxExemptionUpdated(exemption, true);
        }
    }

    /**
     * @notice Remove address from set of tax-exempted addresses.
     * @param exemption Address to remove from set of tax-exempted addresses.
     */
    function removeExemption(address exemption) external onlyOwner {
        if (_exempted.remove(exemption)) {
            emit TaxExemptionUpdated(exemption, false);
        }
    }

    /**
     * @notice Get blacklist status of a given wallet.
     * @param wallet Address to check blacklist status of.
     * @return True if address is blacklisted, else False.
     */
    function isBlacklisted(address wallet) public view returns (bool) {
        for (uint256 i = 0; i < blacklisted.length; i++) {
            if (wallet == blacklisted[i]) {
                return true;
            }
        }

        return false;
    }

    function _getBuyTaxBasisPoints(uint256 amount, uint256 poolBalance) private view returns (uint256 taxBasisPoints) {
        taxBasisPoints = baseBuyTaxBasisPoints;
        uint256 basisPoints = (amount * 10000) / poolBalance;

        for (uint256 i = 0; i < _buyTaxPoints; i++) {
            if (_buyTaxBasisPoints[i].threshold <= basisPoints) {
                taxBasisPoints = _buyTaxBasisPoints[i].basisPoints;
            }
        }
    }

    function _getSellTaxBasisPoints(uint256 amount, uint256 poolBalance) private view returns (uint256 taxBasisPoints) {
        taxBasisPoints = baseSellTaxBasisPoints;
        uint256 basisPoints = (amount * 10000) / poolBalance;

        for (uint256 i = 0; i < _sellTaxPoints; i++) {
            if (_sellTaxBasisPoints[i].threshold <= basisPoints) {
                taxBasisPoints = _sellTaxBasisPoints[i].basisPoints;
            }
        }
    }
}

// SPDX-License-Identifier: MIT

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
pragma solidity 0.8.11;

/**
 * @title Tax handler interface
 * @dev Any class that implements this interface can be used for protocol-specific tax calculations.
 */
interface ITaxHandler {
    /**
     * @notice Get number of tokens to pay as tax.
     * @param benefactor Address of the benefactor.
     * @param beneficiary Address of the beneficiary.
     * @param amount Number of tokens in the transfer.
     * @return Number of tokens to pay as tax.
     */
    function getTax(
        address benefactor,
        address beneficiary,
        uint256 amount
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @title Exchange pool processor abstract contract.
 * @dev Keeps an enumerable set of designated exchange addresses as well as a single primary pool address.
 */
abstract contract ExchangePoolProcessor is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @dev Set of exchange pool addresses.
    EnumerableSet.AddressSet internal _exchangePools;

    /// @notice Primary exchange pool address.
    address public primaryPool;

    /// @notice Emitted when an exchange pool address is added to the set of tracked pool addresses.
    event ExchangePoolAdded(address exchangePool);

    /// @notice Emitted when an exchange pool address is removed from the set of tracked pool addresses.
    event ExchangePoolRemoved(address exchangePool);

    /// @notice Emitted when the primary pool address is updated.
    event PrimaryPoolUpdated(address oldPrimaryPool, address newPrimaryPool);

    /**
     * @notice Get list of addresses designated as exchange pools.
     * @return An array of exchange pool addresses.
     */
    function getExchangePoolAddresses() external view returns (address[] memory) {
        return _exchangePools.values();
    }

    /**
     * @notice Add an address to the set of exchange pool addresses.
     * @dev Nothing happens if the pool already exists in the set.
     * @param exchangePool Address of exchange pool to add.
     */
    function addExchangePool(address exchangePool) external onlyOwner {
        if (_exchangePools.add(exchangePool)) {
            emit ExchangePoolAdded(exchangePool);
        }
    }

    /**
     * @notice Remove an address from the set of exchange pool addresses.
     * @dev Nothing happens if the pool doesn't exist in the set..
     * @param exchangePool Address of exchange pool to remove.
     */
    function removeExchangePool(address exchangePool) external onlyOwner {
        if (_exchangePools.remove(exchangePool)) {
            emit ExchangePoolRemoved(exchangePool);
        }
    }

    /**
     * @notice Set exchange pool address as primary pool.
     * @dev To prevent issues, only addresses inside the set of exchange pool addresses can be selected as primary pool.
     * @param exchangePool Address of exchange pool to set as primary pool.
     */
    function setPrimaryPool(address exchangePool) external onlyOwner {
        require(
            _exchangePools.contains(exchangePool),
            "ExchangePoolProcessor:setPrimaryPool:INVALID_POOL: Given address is not registered as exchange pool."
        );
        require(
            primaryPool != exchangePool,
            "ExchangePoolProcessor:setPrimaryPool:ALREADY_SET: This address is already the primary pool address."
        );

        address oldPrimaryPool = primaryPool;
        primaryPool = exchangePool;

        emit PrimaryPoolUpdated(oldPrimaryPool, exchangePool);
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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