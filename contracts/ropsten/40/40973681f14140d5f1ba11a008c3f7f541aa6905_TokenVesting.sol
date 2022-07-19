/**
 *Submitted for verification at Etherscan.io on 2022-07-19
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/structs/EnumerableSet.sol


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

// File: vesting/FullMath.sol


pragma solidity ^0.8.0;

// Sourced from https://gist.github.com/paulrberg/439ebe860cd2f9893852e2cab5655b65, credits to Paulrberg for porting to solidity v0.8
/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        unchecked {
            uint256 twos = (type(uint256).max - denominator + 1) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }
}
// File: vesting/VestingMathLibrary.sol


// ALL RIGHTS RESERVED
// Unicrypt by SDDTech reserves all rights on this code. You may NOT copy these contracts.

pragma solidity ^0.8.0;


// Allows a seperate contract with a unlockTokens() function to be used to override unlock dates
interface IUnlockCondition {
    function unlockTokens() external view returns (bool);
}

library VestingMathLibrary {

  // gets the withdrawable amount from a lock
  function getWithdrawableAmount (uint256 startEmission, uint256 endEmission, uint256 amount, uint256 timeStamp) internal pure returns (uint256) {
    // It is possible in some cases IUnlockCondition(condition).unlockTokens() will fail (func changes state or does not return a bool)
    // for this reason we implemented revokeCondition per lock so funds are never stuck in the contract.

    // Lock type 1 logic block (Normal Unlock on due date)
    if (startEmission == 0 || startEmission == endEmission) {
        return endEmission < timeStamp ? amount : 0;
    }
    // Lock type 2 logic block (Linear scaling lock)
    uint256 timeClamp = timeStamp;
    if (timeClamp > endEmission) {
        timeClamp = endEmission;
    }
    if (timeClamp < startEmission) {
        timeClamp = startEmission;
    }
    uint256 elapsed = timeClamp - startEmission;
    uint256 fullPeriod = endEmission - startEmission;
    return FullMath.mulDiv(amount, elapsed, fullPeriod); // fullPeriod cannot equal zero due to earlier checks and restraints when locking tokens (startEmission < endEmission)
  }
}
// File: vesting/TransferHelper.sol



pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}
// File: vesting/TokenVesting.sol


// ALL RIGHTS RESERVED
// {Unicrypt by SDDTech reserves} all rights on this code. You may NOT copy these contracts.

// This contract locks ERC20 tokens. This can be used for:
// - Token developers to prove they have locked tokens
// - Presale projects or investors to lock a portion of tokens for a vesting period
// - Farming platforms to lock a percentage of the farmed rewards for a period of time
// - To lock tokens until a specific unlock date.
// - To send tokens to someone under a time lock.

// This contract is for ERC20 tokens, and supports high deflationary and rebasing tokens by using a pooling and share issuing mechanism.
// This is NOT for AMM LP tokens (such as UNIV2), Please use our liquidity lockers for this.
// Locking LP tokens in this contract will not show in the {Unicrypt browser}.

// *** LOCK TYPES ***
// Lock Type 1: when startEmission == 0 the lock is considered lockType 1. This is a normal lock
// whereby tokens can be withdrawn on the due date (endEmission).

// Lock Type 2: when startEmission != 0. Lock tokens over a period, with an amount withdrawable every block. 
// This scales linearly over time from startEmission -> endEmission. 
// e.g. If the lock period is 100 seconds, 50 seconds after the startEmission you can withdraw 50% of the lock.
// Instead of making 10 locks for 10 months to withdraw tokens at the end of each month, you can now make 1 linear scaling lock with a period
// of 10 months and withdraw the relative share every block.

pragma solidity ^0.8.0;








interface IMigrator {
    function migrate(address token, uint256 sharesDeposited, uint256 sharesWithdrawn, uint256 startEmission, uint256 endEmission, uint256 lockID, address owner, uint256 amountInTokens, uint256 option) external returns (bool);
}

interface IAdmin {
    function userIsAdmin(address _user) external view returns (bool);
}

interface ITokenBlacklist {
    function checkToken(address _token) external view;
}

contract TokenVesting is Ownable, ReentrancyGuard {
  using EnumerableSet for EnumerableSet.AddressSet;

  struct UserInfo {
    EnumerableSet.AddressSet lockedTokens; // records all token addresses the user has locked
    mapping(address => uint256[]) locksForToken; // map erc20 address to lockId for that token
  }

  struct TokenLock {
    address tokenAddress; // The token address
    uint256 sharesDeposited; // the total amount of shares deposited
    uint256 sharesWithdrawn; // amount of shares withdrawn
    uint256 startEmission; // date token emission begins
    uint256 endEmission; // the date the tokens can be withdrawn
    uint256 lockID; // lock id per token lock
    address owner; // the owner who can edit or withdraw the lock
  }
  
  struct LockParams {
    address payable owner; // the user who can withdraw tokens once the lock expires.
    uint256 amount; // amount of tokens to lock
    uint256 startEmission; // 0 if lock type 1, else a unix timestamp
    uint256 endEmission; // the unlock date as a unix timestamp (in seconds)
  }

  EnumerableSet.AddressSet private TOKENS; // list of all unique tokens that have a lock
  mapping(uint256 => TokenLock) public LOCKS; // map lockID nonce to the lock
  uint256 public NONCE = 0; // incremental lock nonce counter, this is the unique ID for the next lock
  uint256 public MINIMUM_DEPOSIT = 100; // minimum divisibility per lock at time of locking
  
  mapping(address => uint256[]) private TOKEN_LOCKS; // map token address to array of lockIDs for that token
  mapping(address => UserInfo) private USERS;

  mapping(address => uint) public SHARES; // map token to number of shares per token, shares allow rebasing and deflationary tokens to compute correctly
  
  EnumerableSet.AddressSet private ZERO_FEE_WHITELIST; // Tokens that have been whitelisted to bypass all fees
  EnumerableSet.AddressSet private TOKEN_WHITELISTERS; // whitelisting contracts and users who can enable no fee for tokens.

  struct FeeStruct {
    uint256 tokenFee;
    uint256 freeLockingFee;
    address payable feeAddress;
    address freeLockingToken; // if this is address(0) then it is the gas token of the network (e.g ETH, BNB, Matic)
  }
  
  FeeStruct public FEES;
  
  IAdmin ADMINS;
  IMigrator public MIGRATOR;
  ITokenBlacklist public BLACKLIST; // prevent AMM tokens with a blacklisting contract

  event onLock(uint256 lockID, address token, address owner, uint256 amountInTokens, uint256 startEmission, uint256 endEmission);
  event onWithdraw(uint256 lockID, uint256 amountInTokens);
  event onRelock(uint256 lockID, uint256 unlockDate);
  event onTransferLock(uint256 lockIDFrom, uint256 lockIDto, address oldOwner, address newOwner);
  event onSplitLock(uint256 fromLockID, uint256 toLockID, uint256 amountInTokens);
  event onMigrate(uint256 lockID, uint256 amountInTokens);
  event BlacklistContract(ITokenBlacklist token);
  event Fees(uint256 tokenFee, uint256 freeLockingFee, address feeAddress, address freeLockingAddress);
  event Whitelister(address user, bool flag);
  event ZeroFeeLock(address token, uint256 freeLockingFee);
  event ZeroFeeWhitelist(address token, bool flag);

  constructor (IAdmin _admins) {
    ADMINS = _admins;
    FEES.tokenFee = 0;
    FEES.feeAddress = payable(0x477947191Bd17D90B0E7667085f2f33f1d382a44);
    FEES.freeLockingFee = 0;
  }
  
  /**
   * @notice set the migrator contract which allows the lock to be migrated
   */
  function setMigrator(IMigrator _migrator) external onlyOwner {
    MIGRATOR = _migrator;
  }
  
  function setBlacklistContract(ITokenBlacklist _contract) external onlyOwner {
    BLACKLIST = _contract;
    emit BlacklistContract(_contract);
  }
  
  function setFees(uint256 _tokenFee, uint256 _freeLockingFee, address payable _feeAddress, address _freeLockingToken) external onlyOwner {
    FEES.tokenFee = _tokenFee;
    FEES.freeLockingFee = _freeLockingFee;
    FEES.feeAddress = _feeAddress;
    FEES.freeLockingToken = _freeLockingToken;
    emit Fees(_tokenFee, _freeLockingFee, _feeAddress, _freeLockingToken);
  }
  
  /**
   * @notice whitelisted accounts and contracts who can call the editZeroFeeWhitelist function
   */
  function adminSetWhitelister(address _user, bool _add) external onlyOwner {
    if (_add) {
      TOKEN_WHITELISTERS.add(_user);
    } else {
      TOKEN_WHITELISTERS.remove(_user);
    }
    emit Whitelister(_user, _add);
  }
  
  // Pay a once off fee to have free use of the lockers for the token
  function payForFreeTokenLocks (address _token) external payable {
      require(!ZERO_FEE_WHITELIST.contains(_token), 'PAID');
      require(msg.value == FEES.freeLockingFee, 'FEE NOT MET');
      // charge Fee
      if (FEES.freeLockingToken == address(0)) {
          
          FEES.feeAddress.transfer(FEES.freeLockingFee);
      } else {
         payable(FEES.freeLockingToken).transfer(FEES.freeLockingFee);
      }
      ZERO_FEE_WHITELIST.add(_token);
      emit ZeroFeeLock(_token, FEES.freeLockingFee);
  }
  
  // Callable by ADMINS or whitelisted contracts (such as presale contracts)
  function editZeroFeeWhitelist (address _token, bool _add) external {
    require(ADMINS.userIsAdmin(msg.sender) || TOKEN_WHITELISTERS.contains(msg.sender), 'ADMIN');
    if (_add) {
      ZERO_FEE_WHITELIST.add(_token);
    } else {
      ZERO_FEE_WHITELIST.remove(_token);
    }
    emit ZeroFeeWhitelist(_token, _add);
  }

  /**
   * @notice Creates one or multiple locks for the specified token
   * @param _token the erc20 token address
   * @param _lock_params an array of locks with format: [LockParams[owner, amount, startEmission, endEmission]]
   * owner: user or contract who can withdraw the tokens
   * amount: must be >= 100 units
   * startEmission = 0 : LockType 1
   * startEmission != 0 : LockType 2 (linear scaling lock)
   * Fails if startEmission is not less than EndEmission
   * Fails is amount < 100
   */
  function lock (address _token, LockParams[] calldata _lock_params) external payable nonReentrant {
    require(_lock_params.length > 0, 'NO PARAMS');
    if (address(BLACKLIST) != address(0)) {
        BLACKLIST.checkToken(_token);
    }
    uint256 totalAmount = 0;
    for (uint256 i = 0; i < _lock_params.length; i++) {
        totalAmount += _lock_params[i].amount;
    }

    uint256 balanceBefore = IERC20(_token).balanceOf(address(this));
    TransferHelper.safeTransferFrom(_token, address(msg.sender), address(this), totalAmount);
    uint256 amountIn = IERC20(_token).balanceOf(address(this)) - balanceBefore;

    // Remove this method and check wether the user sent the required 'msg.value' or not, if yes, then transfer
    // the 'msg.value' to the 'FEES.feeAddress'
    // Fees
    if (!ZERO_FEE_WHITELIST.contains(_token)) {
      uint256 lockFee = FullMath.mulDiv(amountIn, FEES.tokenFee, 10000);
      require(msg.value == lockFee, "fee requirments not met");
      payable(FEES.feeAddress).transfer(msg.value);
    }
    
    uint256 shares = 0;
    for (uint256 i = 0; i < _lock_params.length; i++) {
        LockParams memory lock_param = _lock_params[i];
        require(lock_param.startEmission < lock_param.endEmission, 'PERIOD');
        require(lock_param.endEmission < 1e10, 'TIMESTAMP INVALID'); // prevents errors when timestamp entered in milliseconds
        require(lock_param.amount >= MINIMUM_DEPOSIT, 'MIN DEPOSIT');
        uint256 amountInTokens = FullMath.mulDiv(lock_param.amount, amountIn, totalAmount);

        if (SHARES[_token] == 0) {
          shares = amountInTokens;
        } else {
          shares = FullMath.mulDiv(amountInTokens, SHARES[_token], balanceBefore == 0 ? 1 : balanceBefore);
        }
        require(shares > 0, 'SHARES');
        SHARES[_token] += shares;
        balanceBefore += amountInTokens;

        TokenLock memory token_lock;
        token_lock.tokenAddress = _token;
        token_lock.sharesDeposited = shares;
        token_lock.startEmission = lock_param.startEmission;
        token_lock.endEmission = lock_param.endEmission;
        token_lock.lockID = NONCE;
        token_lock.owner = lock_param.owner;
    
        // record the lock globally
        LOCKS[NONCE] = token_lock;
        TOKENS.add(_token);
        TOKEN_LOCKS[_token].push(NONCE);
    
        // record the lock for the user
        UserInfo storage user = USERS[lock_param.owner];
        user.lockedTokens.add(_token);
        user.locksForToken[_token].push(NONCE);
        
        NONCE ++;
        emit onLock(token_lock.lockID, _token, token_lock.owner, amountInTokens, token_lock.startEmission, token_lock.endEmission);
    }
  }
  
   /**
   * @notice withdraw a specified amount from a lock. _amount is the ideal amount to be withdrawn.
   * however, this amount might be slightly different in rebasing tokens due to the conversion to shares,
   * then back into an amount
   * @param _lockID the lockID of the lock to be withdrawn
   * @param _amount amount of tokens to withdraw
   */
  function withdraw (uint256 _lockID, uint256 _amount) external nonReentrant {
    TokenLock storage userLock = LOCKS[_lockID];
    require(userLock.owner == msg.sender, 'OWNER');
    // convert _amount to its representation in shares
    uint256 balance = IERC20(userLock.tokenAddress).balanceOf(address(this));
    uint256 shareDebit = FullMath.mulDiv(SHARES[userLock.tokenAddress], _amount, balance);
    // round _amount up to the nearest whole share if the amount of tokens specified does not translate to
    // at least 1 share.
    if (shareDebit == 0 && _amount > 0) {
      shareDebit ++;
    }
    require(shareDebit > 0, 'ZERO WITHDRAWL');
    uint256 withdrawableShares = getWithdrawableShares(userLock.lockID);
    // dust clearance block, as mulDiv rounds down leaving one share stuck, clear all shares for dust amounts
    if (shareDebit + 1 == withdrawableShares) {
      if (FullMath.mulDiv(SHARES[userLock.tokenAddress], balance / SHARES[userLock.tokenAddress], balance) == 0){
        shareDebit++;
      }
    }
    require(withdrawableShares >= shareDebit, 'AMOUNT');
    userLock.sharesWithdrawn += shareDebit;

    // now convert shares to the actual _amount it represents, this may differ slightly from the 
    // _amount supplied in this methods arguments.
    uint256 amountInTokens = FullMath.mulDiv(shareDebit, balance, SHARES[userLock.tokenAddress]);
    SHARES[userLock.tokenAddress] -= shareDebit;
    
    TransferHelper.safeTransfer(userLock.tokenAddress, msg.sender, amountInTokens);
    emit onWithdraw(_lockID, amountInTokens);
  }
  
  /**
   * @notice extend a lock with a new unlock date, if lock is Type 2 it extends the emission end date
   */
  function relock (uint256 _lockID, uint256 _unlock_date) external payable nonReentrant {
    require(_unlock_date < 1e10, 'TIME'); // prevents errors when timestamp entered in milliseconds
    TokenLock storage userLock = LOCKS[_lockID];
    require(userLock.owner == msg.sender, 'OWNER');
    require(userLock.endEmission < _unlock_date, 'END');
    // percent fee
    if (!ZERO_FEE_WHITELIST.contains(userLock.tokenAddress)) {
        uint256 remainingShares = userLock.sharesDeposited - userLock.sharesWithdrawn;
        uint256 feeInShares = FullMath.mulDiv(remainingShares, FEES.tokenFee, 10000);  // Instead of tokens, we will again charge the fee in 'msg.value'
        uint256 balance = IERC20(userLock.tokenAddress).balanceOf(address(this));
        uint256 feeInTokens = FullMath.mulDiv(feeInShares, balance, SHARES[userLock.tokenAddress] == 0 ? 1 : SHARES[userLock.tokenAddress]);
        require(msg.value == feeInTokens, "fee requirments not met");
        payable(FEES.feeAddress).transfer(msg.value);

    }
    userLock.endEmission = _unlock_date;
    emit onRelock(_lockID, _unlock_date);
  }
  
  /**
   * @notice increase the amount of tokens per a specific lock, this is preferable to creating a new lock
   * Its possible to increase someone elses lock here it does not need to be your own, useful for contracts
   */
  function incrementLock (uint256 _lockID, uint256 _amount) external payable nonReentrant {
    TokenLock storage userLock = LOCKS[_lockID];
    require(_amount >= MINIMUM_DEPOSIT, 'MIN DEPOSIT');
    
    uint256 balanceBefore = IERC20(userLock.tokenAddress).balanceOf(address(this));
    TransferHelper.safeTransferFrom(userLock.tokenAddress, address(msg.sender), address(this), _amount);
    uint256 amountInTokens = IERC20(userLock.tokenAddress).balanceOf(address(this)) - balanceBefore;


    // remove this method and do the same logic which will be implemented in 'lock' function
    // percent fee
    if (!ZERO_FEE_WHITELIST.contains(userLock.tokenAddress)) {
        uint256 lockFee = FullMath.mulDiv(amountInTokens, FEES.tokenFee, 10000);
      require(msg.value == lockFee, "fee requirments not met");
      payable(FEES.feeAddress).transfer(msg.value);
    }
    uint256 shares;
    if (SHARES[userLock.tokenAddress] == 0) {
      shares = amountInTokens;
    } else {
      shares = FullMath.mulDiv(amountInTokens, SHARES[userLock.tokenAddress], balanceBefore);
    }
    require(shares > 0, 'SHARES');
    SHARES[userLock.tokenAddress] += shares;
    userLock.sharesDeposited += shares;
    emit onLock(userLock.lockID, userLock.tokenAddress, userLock.owner, amountInTokens, userLock.startEmission, userLock.endEmission);
  }
  
  /**
   * @notice transfer a lock to a new owner, e.g. presale project -> project owner
   * Please be aware this generates a new lock, and nulls the old lock, so a new ID is assigned to the new lock.
   */
  function transferLockOwnership (uint256 _lockID, address payable _newOwner) external nonReentrant {
    require(msg.sender != _newOwner, 'SELF');
    TokenLock storage transferredLock = LOCKS[_lockID];
    require(transferredLock.owner == msg.sender, 'OWNER');
    
    TokenLock memory token_lock;
    token_lock.tokenAddress = transferredLock.tokenAddress;
    token_lock.sharesDeposited = transferredLock.sharesDeposited;
    token_lock.sharesWithdrawn = transferredLock.sharesWithdrawn;
    token_lock.startEmission = transferredLock.startEmission;
    token_lock.endEmission = transferredLock.endEmission;
    token_lock.lockID = NONCE;
    token_lock.owner = _newOwner;
    
    // record the lock globally
    LOCKS[NONCE] = token_lock;
    TOKEN_LOCKS[transferredLock.tokenAddress].push(NONCE);
    
    // record the lock for the new owner 
    UserInfo storage newOwner = USERS[_newOwner];
    newOwner.lockedTokens.add(transferredLock.tokenAddress);
    newOwner.locksForToken[transferredLock.tokenAddress].push(token_lock.lockID);
    NONCE ++;
    
    // zero the lock from the old owner
    transferredLock.sharesWithdrawn = transferredLock.sharesDeposited;
    emit onTransferLock(_lockID, token_lock.lockID, msg.sender, _newOwner);
  }
  
  /**
   * @notice split a lock into two seperate locks, useful when a lock is about to expire and youd like to relock a portion
   * and withdraw a smaller portion
   * Only works on lock type 1, this feature does not work with lock type 2
   * @param _amount the amount in tokens
   */
  function splitLock (uint256 _lockID, uint256 _amount) external nonReentrant {
    require(_amount > 0, 'ZERO AMOUNT');
    TokenLock storage userLock = LOCKS[_lockID];
    require(userLock.owner == msg.sender, 'OWNER');
    require(userLock.startEmission == 0, 'LOCK TYPE 2');

    // convert _amount to its representation in shares
    uint256 balance = IERC20(userLock.tokenAddress).balanceOf(address(this));
    uint256 amountInShares = FullMath.mulDiv(SHARES[userLock.tokenAddress], _amount, balance);

    require(userLock.sharesWithdrawn + amountInShares <= userLock.sharesDeposited);
    
    TokenLock memory token_lock;
    token_lock.tokenAddress = userLock.tokenAddress;
    token_lock.sharesDeposited = amountInShares;
    token_lock.endEmission = userLock.endEmission;
    token_lock.lockID = NONCE;
    token_lock.owner = msg.sender;
    
    // debit previous lock
    userLock.sharesWithdrawn += amountInShares;
    
    // record the new lock globally
    LOCKS[NONCE] = token_lock;
    TOKEN_LOCKS[userLock.tokenAddress].push(NONCE);
    
    // record the new lock for the owner 
    USERS[msg.sender].locksForToken[userLock.tokenAddress].push(token_lock.lockID);
    NONCE ++;
    emit onSplitLock(_lockID, token_lock.lockID, _amount);
  }
  
  /**
   * @notice migrates to the next locker version, only callable by lock owners
   */
  function migrate (uint256 _lockID, uint256 _option) external nonReentrant {
    require(address(MIGRATOR) != address(0), "NOT SET");
    TokenLock storage userLock = LOCKS[_lockID];
    require(userLock.owner == msg.sender, 'OWNER');
    uint256 sharesAvailable = userLock.sharesDeposited - userLock.sharesWithdrawn;
    require(sharesAvailable > 0, 'AMOUNT');

    uint256 balance = IERC20(userLock.tokenAddress).balanceOf(address(this));
    uint256 amountInTokens = FullMath.mulDiv(sharesAvailable, balance, SHARES[userLock.tokenAddress]);
    
    TransferHelper.safeApprove(userLock.tokenAddress, address(MIGRATOR), amountInTokens);
    MIGRATOR.migrate(userLock.tokenAddress, userLock.sharesDeposited, userLock.sharesWithdrawn, userLock.startEmission,
    userLock.endEmission, userLock.lockID, userLock.owner, amountInTokens, _option);
    
    userLock.sharesWithdrawn = userLock.sharesDeposited;
    SHARES[userLock.tokenAddress] -= sharesAvailable;
    emit onMigrate(_lockID, amountInTokens);
  }
  
  // returns withdrawable share amount from the lock, taking into consideration start and end emission
  function getWithdrawableShares (uint256 _lockID) public view returns (uint256) {
    TokenLock storage userLock = LOCKS[_lockID];
    uint8 lockType = userLock.startEmission == 0 ? 1 : 2;
    uint256 amount = lockType == 1 ? userLock.sharesDeposited - userLock.sharesWithdrawn : userLock.sharesDeposited;
    uint256 withdrawable;
    withdrawable = VestingMathLibrary.getWithdrawableAmount (
      userLock.startEmission, 
      userLock.endEmission, 
      amount, 
      block.timestamp
    );
    if (lockType == 2) {
      withdrawable -= userLock.sharesWithdrawn;
    }
    return withdrawable;
  }
  
  // convenience function for UI, converts shares to the current amount in tokens
  function getWithdrawableTokens (uint256 _lockID) external view returns (uint256) {
    TokenLock storage userLock = LOCKS[_lockID];
    uint256 withdrawableShares = getWithdrawableShares(userLock.lockID);
    uint256 balance = IERC20(userLock.tokenAddress).balanceOf(address(this));
    uint256 amountTokens = FullMath.mulDiv(withdrawableShares, balance, SHARES[userLock.tokenAddress] == 0 ? 1 : SHARES[userLock.tokenAddress]);
    return amountTokens;
  }

  // For UI use
  function convertSharesToTokens (address _token, uint256 _shares) external view returns (uint256) {
    uint256 balance = IERC20(_token).balanceOf(address(this));
    return FullMath.mulDiv(_shares, balance, SHARES[_token]);
  }

  function convertTokensToShares (address _token, uint256 _tokens) external view returns (uint256) {
    uint256 balance = IERC20(_token).balanceOf(address(this));
    return FullMath.mulDiv(SHARES[_token], _tokens, balance);
  }
  
  function getNumLockedTokens () external view returns (uint256) {
    return TOKENS.length();
  }

  function getTokenLocksLength (address _token) external view returns (uint256) {
    return TOKEN_LOCKS[_token].length;
  }
  
  // user functions
  function getUserLockedTokensLength (address _user) external view returns (uint256) {
    return USERS[_user].lockedTokens.length();
  }
  
  function getUserLocksForTokenLength (address _user, address _token) external view returns (uint256) {
    return USERS[_user].locksForToken[_token].length;
  }
  
  // no Fee Tokens
  function getZeroFeeTokensLength () external view returns (uint256) {
    return ZERO_FEE_WHITELIST.length();
  }
  
  // whitelist
  function getTokenWhitelisterLength () external view returns (uint256) {
    return TOKEN_WHITELISTERS.length();
  }
}