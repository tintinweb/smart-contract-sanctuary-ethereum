/**
 *Submitted for verification at Etherscan.io on 2022-08-06
*/

// Sources flattened with hardhat v2.10.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
}


// File contracts/lib/ConveyorBase.sol

pragma solidity ^0.8.0;


contract ConveyorBase is Ownable {
    bool public conveyorIsEnabled = true;
    address public forwarder;

    constructor(address _forwarder) {
        forwarder = _forwarder;
    }

    modifier onlyConveyor() {
        if (conveyorIsEnabled) {
            require(isTrustedForwarder(msg.sender), "ConveyorBaseError: Unauthorized Caller!");
        }
        _;
    }

    function disableConveyorProtection() external onlyOwner {
        conveyorIsEnabled = false;
    }

    function enableConveyorProtection() external onlyOwner {
        conveyorIsEnabled = true;
    }

    function setForwarder(address _forwarder) external onlyOwner {
        forwarder = _forwarder;
    }

    // EIP 2771
    function isTrustedForwarder(address _forwarder) public view returns (bool) {
        return _forwarder == forwarder;
    }

    // EIP 2771: https://eips.ethereum.org/EIPS/eip-2771
    // Append sender address to metaTx call data
    function _msgSender() internal view override returns (address signer) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            assembly {
                signer := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            signer = msg.sender;
        }
    }

    // Ref: https://github.com/GNSPS/solidity-bytes-utils/blob/6458fb2780a3092bc756e737f246be1de6d3d362/contracts/BytesLib.sol#L228-L295
    function _extractData() internal view returns (bytes memory paramData) {
        if (isTrustedForwarder(msg.sender)) {
            bytes memory tempBytes;
            bytes memory _bytes = msg.data;
            assembly {
                let len := calldataload(sub(calldatasize(), 52))
                let start := sub(calldatasize(), add(len, 52))
                switch iszero(len)
                case 0 {
                    // Get a location of some free memory and store it in tempBytes as
                    // Solidity does for memory variables.
                    tempBytes := mload(0x40)

                    // The first word of the slice result is potentially a partial
                    // word read from the original array. To read it, we calculate
                    // the length of that partial word and start copying that many
                    // bytes into the array. The first word we copy will start with
                    // data we don't care about, but the last `lengthmod` bytes will
                    // land at the beginning of the contents of the new array. When
                    // we're done copying, we overwrite the full first word with
                    // the actual length of the slice.
                    let lengthmod := and(len, 31)

                    // The multiplication in the next line is necessary
                    // because when slicing multiples of 32 bytes (lengthmod == 0)
                    // the following copy loop was copying the origin's length
                    // and then ending prematurely not copying everything it should.
                    let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                    let end := add(mc, len)

                    for {
                        // The multiplication in the next line has the same exact purpose
                        // as the one above.
                        let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), start)
                    } lt(mc, end) {
                        mc := add(mc, 0x20)
                        cc := add(cc, 0x20)
                    } {
                        mstore(mc, mload(cc))
                    }

                    mstore(tempBytes, len)

                    //update free-memory pointer
                    //allocating the array padded to 32 bytes like the compiler does now
                    mstore(0x40, and(add(mc, 31), not(31)))
                }
                default {
                    tempBytes := mload(0x40)
                    //zero out the 32 bytes slice we are about to return
                    //we need to do it because Solidity does not garbage collect
                    mstore(tempBytes, 0)

                    mstore(0x40, add(tempBytes, 0x20))
                }
            }
            paramData = tempBytes;
        } else {
            // Revert with error message if !conveyorIsEnabled
            revert("Fatal: Conveyor must be enabled to invoke _extractData");
        }
    }
}


// File @openzeppelin/contracts/utils/structs/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
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
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
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

        /// @solidity memory-safe-assembly
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}


// File @openzeppelin/contracts/utils/[email protected]


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
library Counters {
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


// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]


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
interface IERC20Permit {
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


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
        IERC20Permit token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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


// File contracts/NFTFairVaultStorageBase.sol



pragma solidity ^0.8.0;




abstract contract NFTFairVaultStorageBase is ConveyorBase {
    using EnumerableSet for *;
    using Counters for Counters.Counter;

    enum TokenType {
        ERC721,
        ERC1155
    }

    /**
     * @notice A category is an object with a set of configurable properties to organize a collection of NFTs
     * @dev At least one category must be initialized before any NFTs can be transferred/minted to vaults.
     * @param nft The address of the NFT contract. This is configured upon initialization and CANNOT be changed after.
     * @param ids The set of all NFT ids that belong to this category. This value can only be modified by the {recover} method and {onERC721Received} hook
     * @param claimable_ids The set of NFT ids available to claim.
     * @param purchaseLimit The maximum number of NFTs that a user is eligible to claim.
     * @param price The amount of {paymentToken} that the user must pay to purchase an NFT.
     */
    struct CategoryInfo {
        TokenType tokenType;
        address nft; // configured upon initialization
        EnumerableSet.UintSet ids; // cannot be configured externally
        mapping(uint256 => uint256) id_values; // only used FOR ERC1155 tokens,
        EnumerableSet.UintSet claimable_ids; // cannot be configured externally
        mapping(uint256 => uint256) claimable_id_values; // only used FOR ERC1155 tokens,
        uint256 purchaseLimit;
        uint256 price;
    }

    // === STORAGE ===
    mapping(address => mapping(uint256 => uint256[])) internal _userClaimedInfo;
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) internal _userClaimedBalance;
    Counters.Counter internal _categoriesCount;
    mapping(uint256 => CategoryInfo) internal _categories;

    // === VIEWERS ===
    address public treasury;
    address public paymentToken;
}


// File contracts/interfaces/INFTFairVault.sol



pragma solidity >=0.8.0;

interface INFTFairVault {
    function paymentToken() external view returns (address);

    function treasury() external view returns (address);

    function getCategoryNft(uint256 _category) external view returns (address);

    function getCategoryNftIds(uint256 _category) external view returns (uint256[] memory);

    function getCategoryNftCountByIds(uint256 _category, uint256[] memory _tokenIds)
        external
        view
        returns (uint256[] memory);

    function getCategoryPurchaseLimit(uint256 _category) external view returns (uint256);

    function getCategoryPrice(uint256 _category) external view returns (uint256);

    function getClaimableIds(uint256 _category) external view returns (uint256[] memory);

    function getClaimableCountByIds(uint256 _category, uint256[] calldata tokenIds)
        external
        view
        returns (uint256[] memory);

    function claimed(address _user, uint256 _category) external view returns (uint256[] memory);

    function claimedCount(address _user, uint256 _category) external view returns (uint256);

    function claimableCount(uint256 _category) external view returns (uint256);

    function configurePayment(address _newToken, uint256[] memory _prices) external;

    function updateCategory(
        uint256 _category,
        uint256 _maxPurchase,
        uint256 _price
    ) external;

    function recover(uint256[] memory _categoryArr, address _recipient) external;
}


// File contracts/interfaces/INFTFairTreasury.sol



pragma solidity >=0.8.0;

interface INFTFairTreasury {
    struct Permit {
        address owner;
        address spender;
        address token;
        uint256 value;
        uint256 nonce;
        uint256 deadline;
    }

    function nonces(address _signer) external view returns (uint256);

    function collectPayment(
        address _buyer,
        address _token,
        uint256 _amount,
        uint256 _deadline,
        bytes calldata _signature
    ) external;
}


// File @openzeppelin/contracts/utils/introspection/[email protected]


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


// File @openzeppelin/contracts/token/ERC721/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}


// File contracts/interfaces/tokens/IERC721Mintable.sol


pragma solidity >=0.8.0;

interface IERC721Mintable is IERC721 {
    /**
     * @return The total supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @return The maximum supply of tokens
     */
    function maxSupply() external view returns (uint256);

    /**
     * @notice Mints a new NFT upon claiming
     */
    function safeMint(
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    ) external;
}


// File @openzeppelin/contracts/token/ERC1155/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}


// File contracts/interfaces/tokens/IERC1155Mintable.sol


pragma solidity >=0.8.0;

interface IERC1155Mintable is IERC1155 {
    /**
     * @return the maximum supply of tokens for every tokenID
     */
    function MAX_SUPPLY_CAP() external view returns (uint256);

    /**
     * @return the total supply of tokens for a specified tokenID
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @notice Mints a new token upon claiming
     */
    function safeMint(
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes calldata _data
    ) external;

    /**
     * @notice Batch minting tokens upon claiming
     */
    function safeBatchMint(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes calldata _data
    ) external;
}


// File @openzeppelin/contracts/token/ERC721/[email protected]


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


// File @openzeppelin/contracts/token/ERC1155/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}


// File @openzeppelin/contracts/utils/introspection/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

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


// File contracts/NFTFairVaultLogicBase.sol



pragma solidity ^0.8.0;









abstract contract NFTFairVaultLogicBase is NFTFairVaultStorageBase, IERC721Receiver, IERC1155Receiver, ERC165 {
    // === EVENT LOGGERS ===
    event NFTReceived(address _nft, uint256 _id);
    event NFTReceived1155(address _nft, uint256 _id, uint256 _count);
    event NFTClaimed(address indexed _claimer, address _nft, uint256[] _tokenIds);
    event ERC1155Claimed(address indexed _claimer, address _nft, uint256[] _tokenIds);
    event NFTRecovered(address _nft, uint256 _id);
    event PaymentTokenUpdated(address _token);
    event CategoryCreated(uint256 _category, address _nft, uint256 _max, uint256 _price);
    event PricingUpdated(uint256 _category, uint256 _price);
    event MaxPurchaseUpdated(uint256 _category, uint256 _max);
    event RevenueWithdrawn(address _beneficiary, address _token, uint256 _amount);

    using EnumerableSet for *;
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    /**
     * since logic contract will only be used as a proxy implementation
     * the contructor will not have any effect
     */
    constructor() ConveyorBase(address(0)) {}

    bool public initialized = false;

    modifier onlyInitialized() {
        require(initialized);
        _;
    }

    /**
     * Minter vault will mint nft when claimed
     * Store only transfer ntf stored to the claimer
     */
    enum VaultType {
        HOLDER,
        MINTER
    }

    VaultType public vaultType;

    function initialize(
        address _forwarder,
        address _treasury,
        VaultType _vaultType
    ) public {
        require(!initialized);
        initialized = true;

        forwarder = _forwarder;
        _transferOwnership(_msgSender());
        treasury = _treasury;
        vaultType = _vaultType;

        //needs to be explicit set
        conveyorIsEnabled = true;
    }

    /**
     * @return a list of token IDs that has been claimed by the _user from a specified _category
     */
    function claimed(address _user, uint256 _category) public view virtual returns (uint256[] memory) {
        CategoryInfo storage category = _categories[_category];
        uint256[] memory ids = _userClaimedInfo[_user][_category];
        if (category.tokenType == TokenType.ERC721) {
            return ids;
        } else {
            uint256 n = claimedCount(_user, _category);
            uint256[] memory result = new uint256[](n);
            uint256 it = 0;
            for (uint256 i = 0; i < ids.length; i++) {
                uint256 id = ids[i];
                uint256 count = _userClaimedBalance[_user][_category][id];
                for (uint256 j = it; j < it + count; j++) {
                    result[j] = id;
                }
                it += count;
            }
            assert(it == n);
            return result;
        }
    }

    /**
     * @dev Provided category must contain a valid ERC1155 contract address
     * @notice Returns the total number of NFTs that have been claimed by the _user from a specified _category
     */
    function claimedCount(address _user, uint256 _category) public view virtual returns (uint256) {
        CategoryInfo storage category = _categories[_category];
        if (category.tokenType == TokenType.ERC721) {
            return _userClaimedInfo[_user][_category].length;
        } else {
            uint256[] memory ids = _userClaimedInfo[_user][_category];
            uint256 sum = 0;
            for (uint256 i = 0; i < ids.length; i++) {
                sum += _userClaimedBalance[_user][_category][ids[i]];
            }
            return sum;
        }
    }

    /**
     * @return {category.claimable_ids}
     */
    function getClaimableIds(uint256 _category) public view virtual returns (uint256[] memory) {
        CategoryInfo storage category = _categories[_category];
        return category.claimable_ids.values();
    }

    /**
     * @dev Provided category must contain a valid ERC1155 contract address
     * @notice Returns the total number of NFTs that are available to claim from a specified _category
     */
    function getClaimableCountByIds(uint256 _category, uint256[] calldata tokenIds)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        CategoryInfo storage category = _categories[_category];
        uint256[] memory ret = new uint256[](tokenIds.length);
        if (category.tokenType == TokenType.ERC721) {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                if (category.claimable_ids.contains(tokenIds[i])) {
                    ret[i] = 1;
                }
            }
        } else {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                ret[i] = category.claimable_id_values[tokenIds[i]];
            }
        }

        return ret;
    }

    /**
     * @return the length of {category.ids} for erc721, sum of {category.claimable_id_values} for erc1155
     */
    function claimableCount(uint256 _category) public view virtual returns (uint256) {
        CategoryInfo storage category = _categories[_category];
        if (category.tokenType == TokenType.ERC721) {
            return category.claimable_ids.length();
        } else {
            uint256 count = 0;
            uint256[] memory ids = category.claimable_ids.values();
            for (uint256 i = 0; i < ids.length; i++) {
                count += category.claimable_id_values[ids[i]];
            }
            return count;
        }
    }

    /**
     * @return {category.purchaseLimit}
     */
    function getCategoryPurchaseLimit(uint256 _category) public view virtual returns (uint256) {
        CategoryInfo storage category = _categories[_category];
        return category.purchaseLimit;
    }

    /**
     * @return {category.price}
     */
    function getCategoryPrice(uint256 _category) public view virtual returns (uint256) {
        CategoryInfo storage category = _categories[_category];
        return category.price;
    }

    /**
     * @return {category.nft}
     */
    function getCategoryNft(uint256 _category) public view virtual returns (address) {
        CategoryInfo storage category = _categories[_category];
        return category.nft;
    }

    /**
     * @return {category.ids}
     */

    function getCategoryNftIds(uint256 _category) public view virtual returns (uint256[] memory) {
        CategoryInfo storage category = _categories[_category];

        return category.ids.values();
    }

    /**
     * @dev Provided category must contain a valid ERC1155 contract address
     * @notice Returns the total amount of tokens given by the specified _category and list of _tokenIds
     */
    function getCategoryNftCountByIds(uint256 _category, uint256[] memory _tokenIds)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        CategoryInfo storage category = _categories[_category];
        require(category.tokenType == TokenType.ERC1155, "NFTFairVaultError: invalid token type");
        uint256[] memory ret = new uint256[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            ret[i] = category.id_values[_tokenIds[i]];
        }
        return ret;
    }

    function categoryCount() public view returns (uint256) {
        return _categoriesCount.current();
    }

    // === ADMIN FUNCTIONS ===

    /**
     * @notice Creates a new category, configures the NFT address, sets the purchase limit and price.
     */
    function createCategory(
        address _nft,
        uint256 _max,
        uint256 _price,
        TokenType _tokenType
    ) public virtual onlyOwner onlyInitialized {
        uint256 i = _categoriesCount.current();
        CategoryInfo storage categoryStruct = _categories[i];
        categoryStruct.nft = _nft;
        categoryStruct.purchaseLimit = _max;
        categoryStruct.price = _price;
        categoryStruct.tokenType = _tokenType;
        _categoriesCount.increment();
        emit CategoryCreated(i, _nft, _max, _price);
    }

    /**
     * @notice Updates the {paymentToken}
     * This function also allows changing the token price for all categories in a single call.
     */
    function configurePayment(address _newToken, uint256[] memory _prices) external virtual onlyOwner onlyInitialized {
        paymentToken = _newToken;
        _updateCategoryPricing(_prices);
        emit PaymentTokenUpdated(_newToken);
    }

    /**
     * @notice Updates the properties of a specified category, except for the NFT address. A new category must be created separately for a different NFT contract.
     */
    function updateCategory(
        uint256 _category,
        uint256 _maxPurchase,
        uint256 _price
    ) public virtual onlyOwner onlyInitialized {
        CategoryInfo storage category = _categories[_category];
        if (category.purchaseLimit != _maxPurchase) {
            category.purchaseLimit = _maxPurchase;
            emit MaxPurchaseUpdated(_category, _maxPurchase);
        }
        if (category.price != _price) {
            category.price = _price;
            emit PricingUpdated(_category, _price);
        }
    }

    /**
     * @notice Allows the owner to retrieve NFTs that are not claimed by the user.
     * This function call effectively empties all categories that are being recovered.
     * @param _categoryArr An array of catogries to recover NFTs from
     * @param _recipient The address that will receive the recovered NFTs
     */
    function recover(uint256[] memory _categoryArr, address _recipient) external virtual onlyOwner onlyInitialized {
        require(vaultType != VaultType.MINTER, "NFTFairVaultError: Cannot recover NFTs from a MinterVault");

        for (uint256 i = 0; i < _categoryArr.length; i++) {
            uint256 cat = _categoryArr[i];
            require(cat < _categoriesCount.current(), "NFTFairVaultError: invalid category provided");
            CategoryInfo storage category = _categories[cat];
            for (uint256 j = category.claimable_ids.length(); j > 0; j--) {
                uint256 id = category.claimable_ids.at(j - 1);
                category.ids.remove(id);

                if (category.tokenType == TokenType.ERC721) {
                    category.claimable_ids.remove(id);
                    IERC721(category.nft).safeTransferFrom(address(this), _recipient, id);
                } else if (category.tokenType == TokenType.ERC1155) {
                    category.claimable_ids.remove(id);
                    uint256 count = category.claimable_id_values[id];
                    category.claimable_id_values[id] = 0;
                    IERC1155(category.nft).safeTransferFrom(address(this), _recipient, id, count, "");
                } else {
                    revert("NFTFairVaultError: Invalid Token Type");
                }

                emit NFTRecovered(category.nft, id);
            }
        }
    }

    /**
     * @notice Allows the owner to withdraw the sales revenue from the vault.
     * @param _beneficiary The address that will receive the revenue
     * @param _token The token address of the revenue
     */
    function revenuePayout(address _beneficiary, address _token) external onlyOwner onlyInitialized {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(_beneficiary, amount);
        emit RevenueWithdrawn(_beneficiary, _token, amount);
    }

    /**
     * @dev pass an empty uint256[] to _amounts for ERC721 category.
     */
    function setCategoryIds(
        uint256 _category,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) external onlyOwner {
        require(vaultType == VaultType.MINTER, "NFTFairVaultError: UNSUPPORTED VAULT TYPE");
        require(_category < _categoriesCount.current(), "NFTFairVaultError: invalid category provided");

        CategoryInfo storage category = _categories[_category];

        if (category.tokenType == TokenType.ERC721) {
            IERC721Mintable mintableNft = IERC721Mintable(category.nft);
            uint256 tokenMax = mintableNft.maxSupply() - mintableNft.totalSupply();
            uint256 categoryMax = mintableNft.maxSupply() - category.claimable_ids.length();
            uint256 max = tokenMax > categoryMax ? categoryMax : tokenMax; // min(tokenMax, categoryMax)
            require(_ids.length <= max, "NFTFairVaultError: Length of IDs exceeded NFT mint allowance");
            for (uint256 i = 0; i < _ids.length; i++) {
                require(!category.ids.contains(_ids[i]), "NFTFairVaultError: ID is no longer valid");
                category.ids.add(_ids[i]);
                category.claimable_ids.add(_ids[i]);
            }
        } else {
            IERC1155Mintable mintableErc1155 = IERC1155Mintable(category.nft);
            uint256 totalSupply = mintableErc1155.MAX_SUPPLY_CAP();

            for (uint256 i = 0; i < _ids.length; i++) {
                uint256 _id = _ids[i];
                uint256 _amount = _amounts[i];
                uint256 issued = category.id_values[_id];
                uint256 categoryMax = totalSupply - issued;
                uint256 tokenMax = totalSupply - mintableErc1155.totalSupply(_id);
                uint256 max = tokenMax > categoryMax ? categoryMax : tokenMax; // min(tokenMax, categoryMax)
                require(max >= _amount, "NFTFairVaultError: ERC1155 exceeded MAX_SUPPLY_CAP");
                category.claimable_ids.add(_id);
                category.claimable_id_values[_id] += _amount;
                category.ids.add(_id);
                category.id_values[_id] += _amount;
            }
        }
    }

    // === HELPER FUNCTION ===

    /**
     * @notice This hook is called upon {IERC721.safeTransferFrom} or {IERC721.safeMint}
     * @dev The data parameter is the ABI-encoded of the category's uint representation.
     * For example, if the category is 0, then the encoded data would be 0x0000000000000000000000000000000000000000000000000000000000000000.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external virtual override onlyInitialized returns (bytes4) {
        require(vaultType != VaultType.MINTER, "NFTFairVaultError: This vault does not accept inbound NFTs");

        require(data.length > 0, "NFTFairVaultError: Data cannot be empty");
        uint256 category = abi.decode(data, (uint256));
        require(category < _categoriesCount.current(), "NFTFairVaultError: invalid category provided");
        CategoryInfo storage categoryStruct = _categories[category];
        require(categoryStruct.tokenType == TokenType.ERC721);
        require(_nftIsValid(_msgSender(), categoryStruct), "NFTFairVaultError: Invalid NFT");
        categoryStruct.ids.add(tokenId);
        categoryStruct.claimable_ids.add(tokenId);
        emit NFTReceived(_msgSender(), tokenId);
        return this.onERC721Received.selector;
    }

    /**
     * @notice This hook is called upon {IERC1155.safeTransferFrom} or {IERC1155.safeMint}
     * @dev The data parameter is the ABI-encoded of the category's uint representation.
     * For example, if the category is 0, then the encoded data would be 0x0000000000000000000000000000000000000000000000000000000000000000.
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external virtual onlyInitialized returns (bytes4) {
        require(vaultType != VaultType.MINTER, "NFTFairVaultError: This vault does not accept inbound NFTs");
        require(data.length > 0, "NFTFairVaultError: Data cannot be empty");

        uint256 category = abi.decode(data, (uint256));
        require(category < _categoriesCount.current(), "NFTFairVaultError: invalid category provided");
        CategoryInfo storage categoryStruct = _categories[category];
        require(categoryStruct.tokenType == TokenType.ERC1155);
        require(_nftIsValid(_msgSender(), categoryStruct), "NFTFairVaultError: Invalid NFT");
        categoryStruct.ids.add(id);
        categoryStruct.id_values[id] = categoryStruct.id_values[id] + value;
        categoryStruct.claimable_ids.add(id);
        categoryStruct.claimable_id_values[id] = categoryStruct.claimable_id_values[id] + value;
        emit NFTReceived1155(_msgSender(), id, value);
        return this.onERC1155Received.selector;
    }

    /**
     * @notice This hook is called upon {IERC1155.safeBatchTransferFrom} or {IERC1155.safeBatchMint}
     * @dev The data parameter is the ABI-encoded of the category's uint representation.
     * For example, if the category is 0, then the encoded data would be 0x0000000000000000000000000000000000000000000000000000000000000000.
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external virtual onlyInitialized returns (bytes4) {
        require(vaultType != VaultType.MINTER, "NFTFairVaultError: This vault does not accept inbound NFTs");
        require(data.length > 0, "NFTFairVaultError: Data cannot be empty");

        uint256 category = abi.decode(data, (uint256));
        require(category < _categoriesCount.current(), "NFTFairVaultError: invalid category provided");
        CategoryInfo storage categoryStruct = _categories[category];
        require(categoryStruct.tokenType == TokenType.ERC1155);
        require(_nftIsValid(_msgSender(), categoryStruct), "NFTFairVaultError: Invalid NFT");
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 value = values[i];
            categoryStruct.ids.add(id);
            categoryStruct.id_values[id] = categoryStruct.id_values[id] + value;
            categoryStruct.claimable_ids.add(id);
            categoryStruct.claimable_id_values[id] = categoryStruct.claimable_id_values[id] + value;
            emit NFTReceived1155(_msgSender(), id, value);
        }
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @notice ERC165 interface check.
     * This contract detects the following interfaces:
     * - {IERC721Receiver.onERC721Received}
     * - {IERC1155Receiver.onERC1155Received}
     * - {IERC1155Receiver.onERC1155BatchReceived}
     * - {IERC165.supportInterface}
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(IERC1155Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // === INTERNAL FUNCTIONS ===

    /**
     * @notice Checks if the incoming NFT is valid for the specified _category
     */
    function _nftIsValid(address _nft, CategoryInfo storage _category) internal view returns (bool res) {
        res = _nft == _category.nft;
    }

    /**
     * @notice Computes the NFT ID to claim based on a given random seed.
     */
    function _getIdFromSeed(uint256 _seed, CategoryInfo storage _category) internal view returns (uint256) {
        uint256 index = _seed % _category.claimable_ids.length();
        return _category.claimable_ids.at(index);
    }

    /**
     * @notice Iterates through the categories and individually updates the price.
     * This call reverts if the length of the price array is not equal to the number of categories.
     */
    function _updateCategoryPricing(uint256[] memory _prices) internal virtual onlyInitialized {
        uint256 n = _prices.length;
        if (n > 0) {
            require(n == _categoriesCount.current(), "NFTFairVaultError: Pricing must be provided for all categories");
            for (uint256 i = 0; i < n; i++) {
                CategoryInfo storage category = _categories[i];
                category.price = _prices[i];
                emit PricingUpdated(i, _prices[i]);
            }
        }
    }

    /**
     * @notice Invokes the treasury's {collectPayment} method to collect sales payment from users.
     */
    function _charge(
        uint256 _amount,
        uint256 _deadline,
        bytes memory _sig
    ) internal onlyInitialized {
        INFTFairTreasury(treasury).collectPayment(_msgSender(), paymentToken, _amount, _deadline, _sig);
    }
}


// File contracts/templates/FifoVaultV2.sol


pragma solidity ^0.8.0;

contract FifoVaultV2 is NFTFairVaultLogicBase {
    using EnumerableSet for EnumerableSet.UintSet;

    function claim(
        uint256 _category,
        uint256 _id,
        uint256 _deadline,
        bytes calldata _sig
    ) external onlyConveyor onlyInitialized {
        CategoryInfo storage category = _categories[_category];
        require(
            category.claimable_ids.contains(_id),
            "NFTFairVaultError: Provided category does not match with the available NFT address or ID"
        );

        if (paymentToken != address(0)) {
            _charge(category.price, _deadline, _sig);
        }

        // comform to logs return type
        // TODO: Subject to update, when batch claiming is being implemented here
        uint256[] memory ids = new uint256[](1);
        ids[0] = _id;

        if (category.tokenType == TokenType.ERC721) {
            uint256 userClaimedCount = claimed(_msgSender(), _category).length;
            uint256 availableToClaimCount = getClaimableIds(_category).length;
            require(availableToClaimCount > 0, "NFTFairVaultError: There are no NFTs available for this category");
            require(
                userClaimedCount < category.purchaseLimit,
                "NFTFairVaultError: User has already claimed the maximum number of NFTs for this category"
            );
            _userClaimedInfo[_msgSender()][_category].push(_id);
            category.claimable_ids.remove(_id);

            if (vaultType == VaultType.HOLDER) {
                IERC721(category.nft).safeTransferFrom(address(this), _msgSender(), _id);
            } else {
                IERC721Mintable(category.nft).safeMint(_msgSender(), _id, "");
            }

            emit NFTClaimed(_msgSender(), category.nft, ids);
        } else {
            uint256 userClaimedCount = claimedCount(_msgSender(), _category);
            require(
                userClaimedCount < category.purchaseLimit,
                "NFTFairVaultError: User has already claimed the maximum number of NFTs for this category"
            );
            // Balance check
            assert(category.claimable_id_values[_id] >= 1);
            category.claimable_id_values[_id] = category.claimable_id_values[_id] - 1;
            if (category.claimable_id_values[_id] == 0) {
                category.claimable_ids.remove(_id);
            }
            if (_userClaimedBalance[_msgSender()][_category][_id] == 0) {
                _userClaimedInfo[_msgSender()][_category].push(_id);
            }
            _userClaimedBalance[_msgSender()][_category][_id] = _userClaimedBalance[_msgSender()][_category][_id] + 1;

            if (vaultType == VaultType.HOLDER) {
                IERC1155(category.nft).safeTransferFrom(address(this), _msgSender(), _id, 1, "");
            } else {
                IERC1155Mintable(category.nft).safeMint(_msgSender(), _id, 1, "");
            }

            emit ERC1155Claimed(_msgSender(), category.nft, ids);
        }
    }
}