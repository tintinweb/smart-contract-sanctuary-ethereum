/**
 *Submitted for verification at Etherscan.io on 2023-01-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
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


abstract contract OwnerOperator is Ownable {
    mapping(address => bool) public operators;

    constructor() Ownable() {}

    modifier operatorOrOwner() {
        require(
            operators[msg.sender] || owner() == msg.sender,
            "OwnerOperator: !operator, !owner"
        );
        _;
    }

    modifier onlyOperator() {
        require(operators[msg.sender], "OwnerOperator: !operator");
        _;
    }

    function addOperator(address operator) external virtual onlyOwner {
        require(
            operator != address(0),
            "OwnerOperator: operator is the zero address"
        );
        operators[operator] = true;
    }

    function removeOperator(address operator) external virtual onlyOwner {
        require(
            operator != address(0),
            "OwnerOperator: operator is the zero address"
        );
        operators[operator] = false;
    }
}


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external;

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external;
}


abstract contract VerifySignature {
    function getMessageHash(
        address _to,
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        uint256 _amountOutMin,
        uint256 _timestamp,
        string memory _msgHash
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _to,
                    _tokenIn,
                    _amountIn,
                    _tokenOut,
                    _amountOutMin,
                    _timestamp,
                    _msgHash
                )
            );
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function verifySignature(
        address _signer,
        address _to,
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        uint256 _amountOutMin,
        uint256 _timestamp,
        string memory _msgHash,
        bytes memory _signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(
            _to,
            _tokenIn,
            _amountIn,
            _tokenOut,
            _amountOutMin,
            _timestamp,
            _msgHash
        );
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, _signature) == _signer;
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory _sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(_sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            v := byte(0, mload(add(_sig, 96)))
        }
    }
}


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)
// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.
/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.
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
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
     * @dev Returns the number of values in the set. O(1).
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


contract Exchange is OwnerOperator, VerifySignature {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.UintSet;

    event DepositExchange(TxnInfo txnInfo);
    event WithdrawExchange(TxnInfo txnInfo);

    enum TypeFee {
        PERCENT,
        FIXED
    }

    enum TxnStatus {
        Initialize,
        Completed
    }

    struct TxnInfo {
        bytes32 txnId;
        address sender;
        address tokenIn;
        uint256 amountIn;
        address tokenOut;
        uint256 amountOut;
        ExchangeInfo exchangeInfo;
        TxnStatus status;
        uint256 timestamp;
    }

    struct ExchangeInfo {
        uint256 rate;
        uint256 fee;
        TypeFee typeFee; // default is percent
        uint256 amountBonus;
        uint8 decimalsIn;
        uint8 decimalsOut;
        uint256 amountLimit;
    }

    struct ExchangeToken {
        address from;
        address to;
    }

    uint256 public timeExpiredSignature = 30 minutes;
    uint256 public limitTime = 24 hours;
    uint256 private constant PRICE_PRECISION = 1e9;
    string private constant MESSAGE_HASH = "EXCHANGE";

    address public signerAddress;
    address public adminReceiver;
    address public adminTransfer;

    // exchange token address => token address: ExchangeInfo
    mapping(address => mapping(address => ExchangeInfo)) internal exchangeInfos;

    // address user => [timestamp by date => amount]
    mapping(address => mapping(uint256 => uint256)) internal amountSwapByUsers;

    // address user => hash (token from - token to) => timestamps[]
    mapping(address => mapping(bytes32 => EnumerableSet.UintSet))
        internal timeSwapByUsers;

    // hashTxnId => TxnInfo
    mapping(bytes32 => TxnInfo) public txnInfos;

    EnumerableSet.Bytes32Set internal arrTxnInfos;

    constructor(
        address _signerAddress,
        address _adminReceiver,
        address _adminTransfer
    ) OwnerOperator() {
        signerAddress = _signerAddress;
        adminReceiver = _adminReceiver;
        adminTransfer = _adminTransfer;
    }

    /**
        @dev get exchange info
        @param from address
        @param to address
        @return ExchangeInfo
     */
    function getExchangeInfo(address from, address to)
        external
        view
        returns (ExchangeInfo memory)
    {
        return exchangeInfos[from][to];
    }

    /**
        @dev set exchange info
        @param from address
        @param to address
        @param exchangeInfo ExchangeInfo
     */
    function setExchangeInfo(
        address from,
        address to,
        ExchangeInfo memory exchangeInfo
    ) external onlyOperator {
        exchangeInfos[from][to] = exchangeInfo;
    }

    /**
        @dev set signer address
        @param _address address
     */
    function setSignerAddress(address _address) external onlyOperator {
        signerAddress = _address;
    }

    /**
        @dev set admin receiver
        @param _address address
     */
    function setAdminReceiver(address _address) external onlyOperator {
        adminReceiver = _address;
    }

    /**
        @dev set admin transfer
        @param _address address
     */
    function setAdminTransfer(address _address) external onlyOperator {
        adminTransfer = _address;
    }

    /**
        @dev set time expired signature
        @param time uint256
     */
    function setTimeExpiredSignature(uint256 time) external onlyOperator {
        timeExpiredSignature = time;
    }

    /**
        @dev get txn info
        @param txnId bytes32
     */
    function getTxnInfo(bytes32 txnId) external view returns (TxnInfo memory) {
        return txnInfos[txnId];
    }

    /**
        @dev get txn infos
        @return bytes32[]
     */
    function getTxnInfos() external view returns (bytes32[] memory) {
        return arrTxnInfos.values();
    }

    /**
        @dev hash transaction id
     */
    function hashTxnId(
        address sender,
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOut,
        uint256 timestamp
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    sender,
                    tokenIn,
                    amountIn,
                    tokenOut,
                    amountOut,
                    timestamp
                )
            );
    }

    /**
        @dev remove txn info
        @param txnId bytes32
     */
    function removeTxnInfo(bytes32 txnId) external onlyOperator {
        require(
            txnInfos[txnId].txnId != bytes32(0),
            "Transaction doesn't exists"
        );
        delete txnInfos[txnId];
    }

    /**
        @dev parse decimals
        @param decimals uint8
        @return uint256
     */
    function parseDecimals(uint8 decimals) internal pure returns (uint256) {
        return 10**decimals;
    }

    /**
        @dev encode exchange
        @param from address
        @param to address
     */
    function encodeExchange(address from, address to)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(from, to));
    }

    /**
        @dev calc total amount by user
        @param sender address
        @param bytesAddress bytes32
     */
    function calcTotalAmountByUser(address sender, bytes32 bytesAddress)
        internal
        returns (uint256)
    {
        uint256 totalAmount = 0;
        uint256[] memory timeSwapByUser = timeSwapByUsers[sender][bytesAddress]
            .values();

        // if timenow - timeSwap > 24 hours: then remove item
        // else: totalAmount += amount swap
        for (uint256 idx = 0; idx < timeSwapByUser.length; idx++) {
            if ((block.timestamp - timeSwapByUser[idx]) > limitTime) {
                delete amountSwapByUsers[sender][timeSwapByUser[idx]];
                timeSwapByUsers[sender][bytesAddress].remove(
                    timeSwapByUser[idx]
                );
            } else {
                totalAmount = totalAmount.add(
                    amountSwapByUsers[sender][timeSwapByUser[idx]]
                );
            }
        }
        return totalAmount;
    }

    /**
        @dev Get total amount by user
        @param user address
        @param tokenFrom address
        @param tokenTo address
        @return uint256
     */
    function getTotalAmountByUser(
        address user,
        address tokenFrom,
        address tokenTo
    ) external view returns (uint256) {
        uint256 totalAmount = 0;
        bytes32 bytesAddress = encodeExchange(tokenFrom, tokenTo);
        uint256[] memory timeSwapByUser = timeSwapByUsers[user][bytesAddress]
            .values();

        for (uint256 idx = 0; idx < timeSwapByUser.length; idx++) {
            if ((block.timestamp - timeSwapByUser[idx]) <= limitTime) {
                totalAmount = totalAmount.add(
                    amountSwapByUsers[user][timeSwapByUser[idx]]
                );
            }
        }
        return totalAmount;
    }

    /**
        @dev exchange token to token
     */
    function depositExchange(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOutMin,
        uint256 timestamp,
        bytes memory signature
    ) external payable {
        require(
            verifySignature(
                signerAddress,
                msg.sender,
                tokenIn,
                amountIn,
                tokenOut,
                amountOutMin,
                timestamp,
                MESSAGE_HASH,
                signature
            ),
            "Signature is invalid"
        );
        require(timestamp <= block.timestamp, "Timestamp is invalid");
        require(
            block.timestamp - timestamp <= timeExpiredSignature,
            "Signature is expired"
        );

        ExchangeInfo memory exchangeInfo = exchangeInfos[tokenIn][tokenOut];
        require(exchangeInfo.rate > 0, "Rate token can't be zero");

        uint256 amountFee = exchangeInfo.typeFee == TypeFee.FIXED
            ? exchangeInfo.fee
            : amountIn.mul(exchangeInfo.fee).div(PRICE_PRECISION);
        require(amountFee < amountIn, "Amount fee must be less than amount");
        uint256 amountInSubFee = amountIn.sub(amountFee);
        uint256 amountOutWithoutDecimals = (
            amountInSubFee.mul(exchangeInfo.rate)
        ).div(PRICE_PRECISION);
        uint256 amountOut = (
            amountOutWithoutDecimals.mul(
                parseDecimals(exchangeInfo.decimalsOut)
            )
        ).div(parseDecimals(exchangeInfo.decimalsIn));
        require(amountOut >= amountOutMin, "Slippage exceeded");

        if (tokenIn != address(0x0)) {
            IERC20 erc20Token = IERC20(tokenIn);
            require(
                erc20Token.allowance(msg.sender, address(this)) >= amountIn,
                "Allowance insufficient."
            );
            erc20Token.transferFrom(msg.sender, adminReceiver, amountIn);
        }

        bytes32 bytesAddress = encodeExchange(tokenIn, tokenOut);
        uint256 totalAmount = calcTotalAmountByUser(msg.sender, bytesAddress);
        require(
            totalAmount + amountIn <= exchangeInfo.amountLimit,
            "Amount exceeded limit"
        );
        if (
            !timeSwapByUsers[msg.sender][bytesAddress].contains(block.timestamp)
        ) {
            timeSwapByUsers[msg.sender][bytesAddress].add(block.timestamp);
        }
        amountSwapByUsers[msg.sender][block.timestamp] += amountIn;
        bytes32 txnId = hashTxnId(
            msg.sender,
            tokenIn,
            amountIn,
            tokenOut,
            amountOut,
            timestamp
        );
        require(
            txnInfos[txnId].txnId == bytes32(0),
            "Transaction is already exists"
        );
        txnInfos[txnId] = TxnInfo(
            txnId,
            msg.sender,
            tokenIn,
            amountIn,
            tokenOut,
            amountOut,
            exchangeInfo,
            TxnStatus.Initialize,
            timestamp
        );
        arrTxnInfos.add(txnId);
        emit DepositExchange(txnInfos[txnId]);
    }

    /**
        @dev withdraw exchange
        @param txnId bytes32
     */
    function withdrawExchange(
        bytes32 txnId,
        address sender,
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOut,
        ExchangeInfo memory exchangeInfo,
        uint256 timestamp
    ) external payable onlyOperator {
        TxnInfo memory txnInfo = TxnInfo(
            txnId,
            sender,
            tokenIn,
            amountIn,
            tokenOut,
            amountOut,
            exchangeInfo,
            TxnStatus.Completed,
            timestamp
        );
        require(
            txnInfos[txnId].txnId == bytes32(0),
            "Transaction is already exists"
        );
        bytes32 newTxnId = hashTxnId(
            sender,
            tokenIn,
            amountIn,
            tokenOut,
            amountOut,
            timestamp
        );
        require(newTxnId == txnId, "TxnId is invalid");

        if (exchangeInfo.amountBonus > 0) {
            require(
                msg.value >= exchangeInfo.amountBonus,
                "Amount bonus is not enough"
            );
            payable(sender).transfer(exchangeInfo.amountBonus);
        }
        arrTxnInfos.add(txnId);
        txnInfos[txnId] = txnInfo;

        if (txnInfo.tokenOut != address(0x0)) {
            IERC20 erc20Token = IERC20(txnInfo.tokenOut);
            require(
                erc20Token.allowance(adminTransfer, address(this)) >= amountOut,
                "Insufficient allowance"
            );
            erc20Token.transferFrom(adminTransfer, txnInfo.sender, amountOut);
        } else {
            require(
                msg.value >= (amountOut + exchangeInfo.amountBonus),
                "Amount out is not enough"
            );
            // native token
            payable(txnInfo.sender).transfer(amountOut);
        }
        txnInfos[txnId].status = TxnStatus.Completed;
        emit WithdrawExchange(txnInfo);
    }

    /**
        @dev clear txn infos
        @param timestamp uint256
     */
    function clearTxnInfos(uint256 timestamp) external onlyOperator {
        uint256 txnLength = arrTxnInfos.length();
        uint256 countNotDel;
        for (uint256 idx = 0; idx < txnLength; idx++) {
            bytes32 txnInfo = arrTxnInfos.at(countNotDel);
            if (txnInfos[txnInfo].timestamp <= timestamp) {
                delete txnInfos[txnInfo];
                arrTxnInfos.remove(txnInfo);
            } else {
                countNotDel += 1;
            }
        }
    }

    /**
        @dev remove exchange info
        @param from addess
        @param to address
     */
    function removeExchangeInfo(address from, address to)
        external
        onlyOperator
    {
        delete exchangeInfos[from][to];
    }

    /**
        @dev withdraw native token
        @param amount uint256
     */
    function withdraw(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
    }

    /**
        @dev withdraw erc20 token
        @param tokenAddress address
        @param amount uint256
     */
    function withdrawToken(address tokenAddress, uint256 amount)
        external
        onlyOwner
    {
        IERC20 erc20Token = IERC20(tokenAddress);
        require(
            erc20Token.balanceOf(address(this)) >= amount,
            "Insufficient balance"
        );
        erc20Token.transfer(msg.sender, amount);
    }

    receive() external payable {}
}