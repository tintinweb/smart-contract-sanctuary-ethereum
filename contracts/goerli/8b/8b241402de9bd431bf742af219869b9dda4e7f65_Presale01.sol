/**
 *Submitted for verification at Etherscan.io on 2022-12-09
*/

// File: Proxiable.sol



pragma solidity ^0.6.12;

contract Proxiable {
    // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"

    function updateCodeAddress(address newAddress) internal {
        require(
            bytes32(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7) == Proxiable(newAddress).proxiableUUID(),
            "Not compatible"
        );
        assembly { // solium-disable-line
            sstore(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7, newAddress)
        }
    }
    
    function proxiableUUID() public pure returns (bytes32) {
        return 0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;
    }
}
// File: IERC20.sol



pragma solidity ^0.6.12;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}
// File: ReentrancyGuard.sol



pragma solidity ^0.6.12;

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
// File: SafeMath.sol



pragma solidity ^0.6.12;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}
// File: EnumerableSet.sol



pragma solidity ^0.6.12;

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
// File: TransferHelper.sol



pragma solidity ^0.6.12;

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
    
    // sends ETH or an erc20 token
    function safeTransferBaseToken(address token, address payable to, uint value, bool isERC20) internal {
        if (!isERC20) {
            to.transfer(value);
        } else {
            (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
            require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
        }
    }
}
// File: Presale01.sol



pragma solidity ^0.6.12;







interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IPresaleLockForwarder {
    function lockLiquidity (IERC20 _baseToken, IERC20 _saleToken, uint256 _baseAmount, uint256 _saleAmount, uint256 _unlock_date, address payable _withdrawer) external;
    function uniswapPairIsInitialised (address _token0, address _token1) external view returns (bool);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface IPresaleSettings {
    function getBaseFee () external view returns (uint256);
    function getTokenFee () external view returns (uint256);
    function getEthAddress () external view returns (address payable);
    function getTokenAddress () external view returns (address payable);
    function getEthCreationFee () external view returns (uint256);
}

contract Presale01 is ReentrancyGuard, Proxiable{
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    
    /// @notice Presale Contract Version, used to choose the correct ABI to decode the contract
    uint256 public CONTRACT_VERSION = 1;
    
    struct PresaleInfo {
        address payable PRESALE_OWNER;
        IERC20 S_TOKEN; // sale token
        IERC20 B_TOKEN; // base token // usually WETH (ETH)
        uint256 TOKEN_PRICE; // 1 base token = ? s_tokens, fixed price
        uint256 MAX_SPEND_PER_BUYER; // maximum base token BUY amount per account
        uint256 AMOUNT; // the amount of presale tokens up for presale
        uint256 HARDCAP;
        uint256 SOFTCAP;
        uint256 LIQUIDITY_PERCENT; // divided by 1000
        uint256 LISTING_RATE; // fixed rate at which the token will list on uniswap
        uint256 START_BLOCK;
        uint256 END_BLOCK;
        uint256 LOCK_PERIOD; // unix timestamp -> e.g. 2 weeks
        bool PRESALE_IN_ETH; // if this flag is true the presale is raising ETH, otherwise an ERC20 token such as DAI
    }
    
    struct PresaleFeeInfo {
        uint256 NOMOPOLY_BASE_FEE; // divided by 1000
        uint256 NOMOPOLY_TOKEN_FEE; // divided by 1000
        address payable BASE_FEE_ADDRESS;
        address payable TOKEN_FEE_ADDRESS;
    }
    
    struct PresaleStatus {
        bool WHITELIST_ONLY; // if set to true only whitelisted members may participate
        bool LP_GENERATION_COMPLETE; // final flag required to end a presale and enable withdrawls
        bool FORCE_FAILED; // set this flag to force fail the presale
        bool IS_OWNER_WITHDRAWN;
        bool IS_TRANSFERED_FEE;
        bool LIST_ON_UNISWAP;
        uint256 TOTAL_BASE_COLLECTED; // total base currency raised (usually ETH)
        uint256 TOTAL_TOKENS_SOLD; // total presale tokens sold
        uint256 TOTAL_TOKENS_WITHDRAWN; // total tokens withdrawn post successful presale
        uint256 TOTAL_BASE_WITHDRAWN; // total base tokens withdrawn on presale failure
        uint256 ROUND1_LENGTH; // in blocks
        uint256 NUM_BUYERS; // number of unique participants
    }

    struct BuyerInfo {
        uint256 baseDeposited; // total base token (usually ETH) deposited by user, can be withdrawn on presale failure
        uint256 tokensOwed; // num presale tokens a user is owed, can be withdrawn on presale success
        uint256 lastWithdraw; // day of the last withdrawing. If first time => = firstDistributionType
        uint256 totalTokenWithdraw; // number of tokens withdraw
        bool isWithdrawnBase; // is withdraw base
    }

    struct VestingPeriod {
        uint256 distributionTime; 
        uint256 unlockRate;
        bool statusWithDraw;
    }

    struct RefundInfo {
        bool isRefund;
        uint256 refundFee;
    }

    event AlertPurchase (
        address indexed buyerAddress,
        uint256 baseAmount,
        uint256 tokenAmount
    );

    event AlertClaimSaleToken (
        address indexed buyerAddress,
        uint256 amountClaimSaleToken
    );

    event AlertRefundBaseTokens (
        address indexed buyerAddress,
        uint256 amountRefundBaseToken
    );

    event AlertWithdrawBaseTokens (
        address indexed buyerAddress,
        uint256 amountWithdrawBaseToken,
        uint256 timeWithdraw
    );

    event AlertOwnerWithdrawTokensWhenFailed (
        address indexed saleOwnerAddress,
        uint256 amountSaleToken,
        uint256 amountBaseToken
    );

    event AlertOwnerWithdrawTokensWhenSuccess (
        address indexed saleOwnerAddress,
        uint256 amountSaleToken,
        uint256 amountBaseToken
    );

    event AlertFinalize(
        address indexed saleOwnerAddress,
        uint256 amountSaleToken,
        uint256 amountBaseToken
    );

    event AlertAddNewVestingPeriod(
        address indexed saleOwnerAddress,
        uint256[] distributionTime,
        uint256[] unlockrate
    );
    
    PresaleInfo public PRESALE_INFO;
    PresaleFeeInfo public PRESALE_FEE_INFO;
    PresaleStatus public STATUS;
    address public PRESALE_GENERATOR;
    IPresaleLockForwarder public PRESALE_LOCK_FORWARDER;
    IPresaleSettings public PRESALE_SETTINGS;
    address NOMOPOLY_FEE_ADDRESS;
    IUniswapV2Factory public UNI_FACTORY;
    IWETH public WETH;
    mapping(address => BuyerInfo) public BUYERS;
    uint256 public TOTAL_FEE;
    uint256 public PERCENT_FEE;
    uint256 public REFUND_FEE;
    VestingPeriod[] private LIST_VESTING_PERIOD;
    mapping(address => uint256) public USER_FEES; 
    uint256 public TOTAL_TOKENS_REFUNDED;
    uint256 public TOTAL_FEES_REFUNDED;
    RefundInfo public REFUND_INFO;
    mapping(address => bool) public BUYER_REFUND;
    mapping(string => bool) public VERIFY_MESSAGE;
    address private CALLER; 
    
    //Apply in goerly test net
    constructor(address _presaleGenerator) public payable {
        PRESALE_GENERATOR = _presaleGenerator;
        UNI_FACTORY = IUniswapV2Factory(0x4763cC63dDd55A6D0a3E09D048e2a86e3Cf863D2);
        WETH = IWETH(0x41b4eb90A6662fE91AC905BaAaE5F2e4d7399469);
        PRESALE_SETTINGS = IPresaleSettings(0x97f0E47e9dE204546FF3b3D466999Cee7Fd2fdd0);
        PRESALE_LOCK_FORWARDER = IPresaleLockForwarder(0x365978D1dA26d1312B1d9C5B1420E8D3Cc85c2Ce);
        NOMOPOLY_FEE_ADDRESS = 0x968be46d13f94224c514028e5A5deE3EC400db1b;
    }

    modifier onlyPresaleOwner() {
        require(PRESALE_INFO.PRESALE_OWNER == msg.sender, "NOT PRESALE OWNER.");
        _;
    }

    modifier verifySignature(string memory message, uint8 v, bytes32 r, bytes32 s) {
        require(CALLER == verifyString(message, v, r, s), "VERIFY SIGNATURE FAILED.");
        _;
    }

    modifier rejectDoubleMessage(string memory message) {
        require(!VERIFY_MESSAGE[message], "REJECT DOUBLE MESSAGE.");
        _;
    }

    function init1 (
        address payable _presaleOwner, 
        uint256 _amount,
        uint256 _tokenPrice, 
        uint256 _maxEthPerBuyer, 
        uint256 _hardcap, 
        uint256 _softcap,
        uint256 _liquidityPercent,
        uint256 _listingRate,
        uint256 _startblock,
        uint256 _endblock,
        uint256 _lockPeriod
      ) external {
            
        require(msg.sender == PRESALE_GENERATOR, "FORBIDDEN.");
        PRESALE_INFO.PRESALE_OWNER = _presaleOwner;
        PRESALE_INFO.AMOUNT = _amount;
        PRESALE_INFO.TOKEN_PRICE = _tokenPrice;
        PRESALE_INFO.MAX_SPEND_PER_BUYER = _maxEthPerBuyer;
        PRESALE_INFO.HARDCAP = _hardcap;
        PRESALE_INFO.SOFTCAP = _softcap;
        PRESALE_INFO.LIQUIDITY_PERCENT = _liquidityPercent;
        PRESALE_INFO.LISTING_RATE = _listingRate;
        PRESALE_INFO.START_BLOCK = _startblock;
        PRESALE_INFO.END_BLOCK = _endblock;
        PRESALE_INFO.LOCK_PERIOD = _lockPeriod;
    }
    
    function init2 (
        IERC20 _baseToken,
        IERC20 _presaleToken,
        uint256 _unicryptBaseFee,
        uint256 _unicryptTokenFee,
        address payable _baseFeeAddress,
        address payable _tokenFeeAddress
      ) external {
        require(msg.sender == PRESALE_GENERATOR, "FORBIDDEN.");
        PRESALE_INFO.PRESALE_IN_ETH = address(_baseToken) == address(WETH);
        PRESALE_INFO.S_TOKEN = _presaleToken;
        PRESALE_INFO.B_TOKEN = _baseToken;
        PRESALE_FEE_INFO.NOMOPOLY_BASE_FEE = _unicryptBaseFee;
        PRESALE_FEE_INFO.NOMOPOLY_TOKEN_FEE = _unicryptTokenFee;
        PRESALE_FEE_INFO.BASE_FEE_ADDRESS = _baseFeeAddress;
        PRESALE_FEE_INFO.TOKEN_FEE_ADDRESS = _tokenFeeAddress;
    }

    function init3(
        bool is_white_list,
        address payable _caller,
        uint256 _percentFee,
        uint256[] memory _distributionTime,
        uint256[] memory _unlockRate,
        bool _isRefund,
        uint256 _refundFee
    ) external {
        require(msg.sender == PRESALE_GENERATOR, "FORBIDDEN.");
        require(_distributionTime.length == _unlockRate.length,"ARRAY MUST BE SAME LENGTH.");
        STATUS.WHITELIST_ONLY = is_white_list;
        CALLER = _caller;
        PERCENT_FEE = _percentFee;
        for(uint i = 0 ; i < _distributionTime.length ; i++) {
            VestingPeriod memory newVestingPeriod;
            newVestingPeriod.distributionTime = _distributionTime[i];
            newVestingPeriod.unlockRate = _unlockRate[i];
            newVestingPeriod.statusWithDraw = false;
            LIST_VESTING_PERIOD.push(newVestingPeriod);
        }   
        REFUND_INFO.isRefund = _isRefund;
        REFUND_INFO.refundFee = _refundFee;
    }     
    
    function presaleStatus() public view returns (uint256) {
        if (STATUS.FORCE_FAILED) {
          return 3; // FAILED - force fail
        }
        if ((block.number > PRESALE_INFO.END_BLOCK) && (STATUS.TOTAL_BASE_COLLECTED < PRESALE_INFO.SOFTCAP)) {
          return 3; // FAILED - softcap not met by end block
        }
        if (STATUS.TOTAL_BASE_COLLECTED >= PRESALE_INFO.HARDCAP) {
          return 2; // SUCCESS - hardcap met
        }
        if ((block.number > PRESALE_INFO.END_BLOCK) && (STATUS.TOTAL_BASE_COLLECTED >= PRESALE_INFO.SOFTCAP)) {
          return 2; // SUCCESS - endblock and soft cap reached
        }
        if ((block.number >= PRESALE_INFO.START_BLOCK) && (block.number <= PRESALE_INFO.END_BLOCK)) {
          return 1; // ACTIVE - deposits enabled
        }
        return 0; // QUED - awaiting start block
    }
    
    // accepts msg.value for eth or _amount for ERC20 tokens
    function purchase(uint256 _amount, string memory _message, uint8 _v, bytes32 _r, bytes32 _s) 
      external 
      payable 
      nonReentrant 
      verifySignature(_message, _v, _r, _s)
      rejectDoubleMessage(_message)
    {
        VERIFY_MESSAGE[_message] = true;
        require(presaleStatus() == 1, "NOT ACTIVE."); // ACTIVE
        BuyerInfo storage buyer = BUYERS[msg.sender];
        uint256 amount_in = PRESALE_INFO.PRESALE_IN_ETH ? msg.value : _amount;
        uint256 real_amount_in = amount_in;
        uint256 fee = 0;
        
        if (!STATUS.WHITELIST_ONLY) {
            real_amount_in = real_amount_in * (1000 - PERCENT_FEE)/ 1000;
            fee = amount_in - real_amount_in;
        }

        uint256 allowance = PRESALE_INFO.MAX_SPEND_PER_BUYER - buyer.baseDeposited;
        uint256 remaining = PRESALE_INFO.HARDCAP - STATUS.TOTAL_BASE_COLLECTED;
        allowance = allowance > remaining ? remaining : allowance;
        if (real_amount_in > allowance) {
            real_amount_in = allowance;
        }
        uint256 tokensSold = (real_amount_in * PRESALE_INFO.TOKEN_PRICE) / (10**uint256(PRESALE_INFO.B_TOKEN.decimals()));
        require(tokensSold > 0, "ZERO TOKENS.");
        if (buyer.baseDeposited == 0) {
            STATUS.NUM_BUYERS++;
        }
        buyer.baseDeposited += real_amount_in + fee;
        buyer.tokensOwed += tokensSold;
        STATUS.TOTAL_BASE_COLLECTED += real_amount_in;
        STATUS.TOTAL_TOKENS_SOLD += tokensSold;
        USER_FEES[msg.sender] += fee;
        TOTAL_FEE += fee;

        // return unused ETH
        if (PRESALE_INFO.PRESALE_IN_ETH && real_amount_in + fee < msg.value) {
            payable(msg.sender).transfer(msg.value - real_amount_in - fee);
        }
        // deduct non ETH token from user
        if (!PRESALE_INFO.PRESALE_IN_ETH) {
            TransferHelper.safeTransferFrom(
                address(PRESALE_INFO.B_TOKEN),
                msg.sender,
                address(this),
                real_amount_in + fee
            );
        }
        
        emit AlertPurchase(
            msg.sender,
            buyer.baseDeposited,
            buyer.tokensOwed
        );
    }
    
    // withdraw presale tokens
    // percentile withdrawls allows fee on transfer or rebasing tokens to still work
    function userClaimSaleTokens() external nonReentrant {
        BuyerInfo storage buyer = BUYERS[msg.sender];
        require(
            presaleStatus() == 2 ||  buyer.lastWithdraw == 0, 
            "CAN'T CLAIM SALE TOKEN."
        ); 

        uint rateWithdrawRemaining;

        for(uint i = 0 ; i < LIST_VESTING_PERIOD.length ; i++) {
            rateWithdrawRemaining += LIST_VESTING_PERIOD[i].unlockRate;
        } 
        
        require(
            rateWithdrawRemaining == 100,
            "TOTAL RATE WITHDRAW REMAINING MUST EQUAL 100."
        );

        require(
            STATUS.TOTAL_TOKENS_SOLD - STATUS.TOTAL_TOKENS_WITHDRAWN > 0,
            "ALL TOKEN HAS BEEN WITHDRAWN."
        );

        require(!buyer.isWithdrawnBase, "NOTHING TO CLAIM.");
        uint256 rateWithdrawAfter;
        uint256 currentTime = block.timestamp;
        uint256 tokensOwed = buyer.tokensOwed;
        require(tokensOwed > 0, "TOKEN OWNER MUST BE GREAT MORE THEN ZERO.");

        for(uint i = 0 ; i < LIST_VESTING_PERIOD.length ; i++) {
            if(currentTime >= LIST_VESTING_PERIOD[i].distributionTime && !LIST_VESTING_PERIOD[i].statusWithDraw){
                rateWithdrawAfter += LIST_VESTING_PERIOD[i].unlockRate;
                LIST_VESTING_PERIOD[i].statusWithDraw = true;
            }
        }

        require(
            rateWithdrawAfter > 0,
            "USER WITHDRAW ALL TOKEN SUCCESS."
        );

        buyer.lastWithdraw = currentTime;
        uint256 amountWithdraw = (tokensOwed * rateWithdrawAfter) / 100; 

        if (buyer.totalTokenWithdraw + amountWithdraw > buyer.tokensOwed) {
            amountWithdraw = buyer.tokensOwed - buyer.totalTokenWithdraw;
        }

        STATUS.TOTAL_TOKENS_WITHDRAWN += amountWithdraw;
        buyer.totalTokenWithdraw += amountWithdraw; // update total token withdraw of buyer address
        TransferHelper.safeTransfer(
            address(PRESALE_INFO.S_TOKEN),
            msg.sender,
            amountWithdraw
        );

        emit AlertClaimSaleToken(
            msg.sender,
            amountWithdraw
        );
    }

    function userRefundBaseTokens() external nonReentrant {
        require(REFUND_INFO.isRefund, "CANNOT REFUND.");
        require(presaleStatus() == 2, "NOT SUCCESS."); // SUCCESS

        BuyerInfo storage buyer = BUYERS[msg.sender];
        require(!BUYER_REFUND[msg.sender], "NOTHING TO REFUND.");
        require(buyer.totalTokenWithdraw == 0, "CANNOT REFUND.");

        uint256 whitelistDeposited = buyer.baseDeposited - (USER_FEES[msg.sender] * 1000) / PERCENT_FEE;
        uint256 refundAmount = (whitelistDeposited * (1000 - REFUND_INFO.refundFee)) / 1000;
        require(refundAmount > 0, "NOTHING TO REFUND.");

        TOTAL_TOKENS_REFUNDED += refundAmount;
        uint256 tokensRefunded = (whitelistDeposited * PRESALE_INFO.TOKEN_PRICE) / (10**uint256(PRESALE_INFO.B_TOKEN.decimals()));
        buyer.baseDeposited -= whitelistDeposited;
        buyer.tokensOwed -= tokensRefunded;

        TransferHelper.safeTransferBaseToken(
            address(PRESALE_INFO.B_TOKEN),
            payable(msg.sender),
            refundAmount,
            !PRESALE_INFO.PRESALE_IN_ETH
        );

        BUYER_REFUND[msg.sender] = true;

        emit AlertClaimSaleToken(
            msg.sender,
            refundAmount
        );
    }
    
    // on presale failure
    // percentile withdrawls allows fee on transfer or rebasing tokens to still work
    function userWithdrawBaseTokens() external nonReentrant {
        require(presaleStatus() == 3, "NOT FAILED."); // FAILED
        BuyerInfo storage buyer = BUYERS[msg.sender];
        require(!buyer.isWithdrawnBase, "NOTHING TO REFUND.");
        require(buyer.baseDeposited > 0, "INVALID BASE DEPOSITED.");
        STATUS.TOTAL_BASE_WITHDRAWN += buyer.baseDeposited;

        TransferHelper.safeTransferBaseToken(
            address(PRESALE_INFO.B_TOKEN),
            payable(msg.sender),
            buyer.baseDeposited,
            !PRESALE_INFO.PRESALE_IN_ETH
        );
        buyer.isWithdrawnBase = true;

        emit AlertWithdrawBaseTokens(
            msg.sender,
            buyer.baseDeposited,
            block.timestamp
        );
    }

    // on presale failure
    // allows the owner to withdraw the tokens they sent for presale & initial liquidity
    function ownerWithdrawTokensWhenFailed() external onlyPresaleOwner {
        require(!STATUS.IS_OWNER_WITHDRAWN, "GENERATION COMPLETE.");
        require(presaleStatus() == 3, "SALE FAILED."); // FAILED
        uint256 balanceSaleToken = PRESALE_INFO.S_TOKEN.balanceOf(address(this));
        uint256 balanceBaseToken = PRESALE_INFO.B_TOKEN.balanceOf(address(this));

        TransferHelper.safeTransfer(
            address(PRESALE_INFO.S_TOKEN), 
            PRESALE_INFO.PRESALE_OWNER, 
            PRESALE_INFO.S_TOKEN.balanceOf(address(this))
        );

        TransferHelper.safeTransferBaseToken(
            address(PRESALE_INFO.B_TOKEN),
            PRESALE_INFO.PRESALE_OWNER,
            PRESALE_INFO.B_TOKEN.balanceOf(address(this)),
            !PRESALE_INFO.PRESALE_IN_ETH
        );
        
        STATUS.IS_OWNER_WITHDRAWN = true;

        emit AlertOwnerWithdrawTokensWhenFailed(
            msg.sender,
            balanceSaleToken,
            balanceBaseToken
        );
    }

    function ownerWithdrawTokensWhenSuccess() external nonReentrant onlyPresaleOwner {
        require(!STATUS.IS_OWNER_WITHDRAWN, "GENERATION COMPLETE.");
        require(presaleStatus() == 2, "NOT SUCCESS."); // SUCCESS
        uint256 NomopolyBaseFee = ((STATUS.TOTAL_BASE_COLLECTED - TOTAL_TOKENS_REFUNDED) * PRESALE_FEE_INFO.NOMOPOLY_BASE_FEE) / 1000;
        uint256 baseLiquidity = (((STATUS.TOTAL_BASE_COLLECTED - TOTAL_TOKENS_REFUNDED) - NomopolyBaseFee) * PRESALE_INFO.LIQUIDITY_PERCENT) / 1000;
        uint256 NomopolyTokenFee = (STATUS.TOTAL_TOKENS_SOLD *PRESALE_FEE_INFO.NOMOPOLY_TOKEN_FEE) / 1000;
        uint256 tokenLiquidity = (baseLiquidity * PRESALE_INFO.LISTING_RATE) / (10**uint256(PRESALE_INFO.B_TOKEN.decimals()));
        uint256 remainingSBalance = PRESALE_INFO.S_TOKEN.balanceOf(address(this)) + STATUS.TOTAL_TOKENS_WITHDRAWN - STATUS.TOTAL_TOKENS_SOLD;
        uint256 remainingBaseBalance = PRESALE_INFO.PRESALE_IN_ETH ? address(this).balance : PRESALE_INFO.B_TOKEN.balanceOf(address(this));
     
        if (!STATUS.IS_TRANSFERED_FEE) {
            remainingBaseBalance -= NomopolyBaseFee;
            remainingSBalance -= NomopolyTokenFee;
            remainingBaseBalance -= TOTAL_FEE;
        }

        if (!STATUS.LIST_ON_UNISWAP) {
            if (PRESALE_INFO.PRESALE_IN_ETH) {
                remainingBaseBalance -= baseLiquidity + PRESALE_SETTINGS.getEthCreationFee();
            } else {
                remainingBaseBalance -= baseLiquidity;
            }
            remainingSBalance -= tokenLiquidity;
        }

        // add refund
        uint256 baseRefund = TOTAL_TOKENS_REFUNDED * 1000 / (1000 - REFUND_INFO.refundFee);
        uint256 tokenRefunded = (baseRefund * PRESALE_INFO.TOKEN_PRICE) / (10**uint256(PRESALE_INFO.B_TOKEN.decimals()));
        remainingSBalance += tokenRefunded;
        if (remainingSBalance > 0) {
            TransferHelper.safeTransfer(
                address(PRESALE_INFO.S_TOKEN),
                PRESALE_INFO.PRESALE_OWNER,
                remainingSBalance
            );
        }

        TransferHelper.safeTransferBaseToken(
            address(PRESALE_INFO.B_TOKEN),
            PRESALE_INFO.PRESALE_OWNER,
            remainingBaseBalance,
            !PRESALE_INFO.PRESALE_IN_ETH
        );
        
        STATUS.IS_OWNER_WITHDRAWN = true;

        emit AlertOwnerWithdrawTokensWhenSuccess(
            msg.sender,
            remainingSBalance,
            remainingBaseBalance
        );
    }

    // if uniswap listing fails, call this function to release eth
    function finalize() external onlyPresaleOwner{
        uint256 remainingBBalance;
        if (!PRESALE_INFO.PRESALE_IN_ETH) {
            remainingBBalance = PRESALE_INFO.B_TOKEN.balanceOf(
                address(this)
            );
        } else {
            remainingBBalance = address(this).balance;
        }
        if(remainingBBalance > 0) {
            TransferHelper.safeTransferBaseToken(
                address(PRESALE_INFO.B_TOKEN),
                PRESALE_FEE_INFO.BASE_FEE_ADDRESS,
                remainingBBalance,
                !PRESALE_INFO.PRESALE_IN_ETH
            );
        }

        uint256 remainingSBalance = PRESALE_INFO.S_TOKEN.balanceOf(
            address(this)
        );
        if(remainingSBalance > 0) {
            TransferHelper.safeTransfer(
                address(PRESALE_INFO.S_TOKEN),
                PRESALE_FEE_INFO.BASE_FEE_ADDRESS,
                remainingSBalance
            );
        }
        selfdestruct(PRESALE_FEE_INFO.BASE_FEE_ADDRESS);

        emit AlertFinalize(
            msg.sender,
            remainingSBalance,
            remainingBBalance
        );
    }
    
    // Can be called at any stage before or during the presale to cancel it before it ends.
    // If the pair already exists on uniswap and it contains the presale token as liquidity 
    // the final stage of the presale "addLiquidity()" will fail. This function 
    // allows anyone to end the presale prematurely to release funds in such a case.
    function forceFailIfPairExists () onlyPresaleOwner external onlyPresaleOwner{
        require(!STATUS.LP_GENERATION_COMPLETE && !STATUS.FORCE_FAILED, "INVALID FORCE FAILED.");
        if (PRESALE_LOCK_FORWARDER.uniswapPairIsInitialised(address(PRESALE_INFO.S_TOKEN), address(PRESALE_INFO.B_TOKEN))) {
            STATUS.FORCE_FAILED = true;
        }
    }
    
    // if something goes wrong in LP generation
    function forceFailByOctofi () external onlyPresaleOwner{
        STATUS.FORCE_FAILED = true;
    }
    
    // on presale success, this is the final step to end the presale, lock liquidity and enable withdrawls of the sale token.
    // This function does not use percentile distribution. Rebasing mechanisms, fee on transfers, or any deflationary logic
    // are not taken into account at this stage to ensure stated liquidity is locked and the pool is initialised according to 
    // the presale parameters and fixed prices.
    function addLiquidity() external nonReentrant {
        require(!STATUS.LP_GENERATION_COMPLETE, "GENERATION COMPLETE.");
        require(presaleStatus() == 2, "NOT SUCCESS."); // SUCCESS
        require(msg.sender == CALLER, "ONLY NOMOPOLY CALLER.");
        // Fail the presale if the pair exists and contains presale token liquidity
        if (PRESALE_LOCK_FORWARDER.uniswapPairIsInitialised(address(PRESALE_INFO.S_TOKEN), address(PRESALE_INFO.B_TOKEN))) {
            STATUS.FORCE_FAILED = true;
            return;
        }
        
        uint256 unicryptBaseFee = STATUS.TOTAL_BASE_COLLECTED.mul(PRESALE_FEE_INFO.NOMOPOLY_BASE_FEE).div(1000);
        
        // base token liquidity
        uint256 baseLiquidity = STATUS.TOTAL_BASE_COLLECTED.sub(unicryptBaseFee).mul(PRESALE_INFO.LIQUIDITY_PERCENT).div(1000);
        if (PRESALE_INFO.PRESALE_IN_ETH) {
            WETH.deposit{value : baseLiquidity}();
        }
        TransferHelper.safeApprove(address(PRESALE_INFO.B_TOKEN), address(PRESALE_LOCK_FORWARDER), baseLiquidity);
        
        // sale token liquidity
        uint256 tokenLiquidity = baseLiquidity.mul(PRESALE_INFO.LISTING_RATE).div(10 ** uint256(PRESALE_INFO.B_TOKEN.decimals()));
        TransferHelper.safeApprove(address(PRESALE_INFO.S_TOKEN), address(PRESALE_LOCK_FORWARDER), tokenLiquidity);
        
        PRESALE_LOCK_FORWARDER.lockLiquidity(PRESALE_INFO.B_TOKEN, PRESALE_INFO.S_TOKEN, baseLiquidity, tokenLiquidity, block.timestamp + PRESALE_INFO.LOCK_PERIOD, PRESALE_INFO.PRESALE_OWNER);
        
        // transfer fees
        uint256 unicryptTokenFee = STATUS.TOTAL_TOKENS_SOLD.mul(PRESALE_FEE_INFO.NOMOPOLY_TOKEN_FEE).div(1000);
        // referrals are checked for validity in the presale generator
        TransferHelper.safeTransferBaseToken(address(PRESALE_INFO.B_TOKEN), PRESALE_FEE_INFO.BASE_FEE_ADDRESS, unicryptBaseFee, !PRESALE_INFO.PRESALE_IN_ETH);
        TransferHelper.safeTransfer(address(PRESALE_INFO.S_TOKEN), PRESALE_FEE_INFO.TOKEN_FEE_ADDRESS, unicryptTokenFee);
        
        // burn unsold tokens
        uint256 remainingSBalance = PRESALE_INFO.S_TOKEN.balanceOf(address(this));
        if (remainingSBalance > STATUS.TOTAL_TOKENS_SOLD) {
            uint256 burnAmount = remainingSBalance.sub(STATUS.TOTAL_TOKENS_SOLD);
            TransferHelper.safeTransfer(address(PRESALE_INFO.S_TOKEN), address(0), burnAmount);
        }
        
        // send remaining base tokens to presale owner
        uint256 remainingBaseBalance = PRESALE_INFO.PRESALE_IN_ETH ? address(this).balance : PRESALE_INFO.B_TOKEN.balanceOf(address(this));
        TransferHelper.safeTransferBaseToken(address(PRESALE_INFO.B_TOKEN), PRESALE_INFO.PRESALE_OWNER, remainingBaseBalance, !PRESALE_INFO.PRESALE_IN_ETH);
        
        STATUS.LP_GENERATION_COMPLETE = true;
    }
    

    function verifyString(string memory message, uint8 v, bytes32 r, bytes32 s) public pure returns(address signer)
      {
          string memory header = "\x19Ethereum Signed Message:\n000000";
          uint256 lengthOffset;
          uint256 length;
          assembly {
              length:= mload(message)
              lengthOffset:= add(header, 57)
          }
          require(length <= 999999, "NOT PROVIDED.");
          uint256 lengthLength = 0;
          uint256 divisor = 100000;
          while (divisor != 0) {
              uint256 digit = length / divisor;
              if (digit == 0) {
                  if (lengthLength == 0) {
                      divisor /= 10;
                      continue;
                  }
              }
              lengthLength++;
              length -= digit * divisor;
              divisor /= 10;
              digit += 0x30;
              lengthOffset++;
              assembly {
                  mstore8(lengthOffset, digit)
              }
          }
          if (lengthLength == 0) {
              lengthLength = 1 + 0x19 + 1;
          } else {
              lengthLength += 1 + 0x19;
          }
          assembly {
              mstore(header, lengthLength)
          }
          bytes32 check = keccak256(abi.encodePacked(header, message));
          return ecrecover(check, v, r, s);
      }
    
    // postpone or bring a presale forward, this will only work when a presale is inactive.
    // i.e. current start block > block.number
    function updateBlocks(uint256 _startBlock, uint256 _endBlock) external onlyPresaleOwner {
        require(
            PRESALE_INFO.START_BLOCK > block.number,
            "INVALID START BLOCK."
        );
        PRESALE_INFO.START_BLOCK = _startBlock;
        PRESALE_INFO.END_BLOCK = _endBlock;
    }

    // function addNewVestingPeriod(uint256[] memory _distributionTime, uint256[] memory _unlockRate) public onlyPresaleOwner {
    //     require(_distributionTime.length == _unlockRate.length,"ARRAY MUST BE SAME LENGTH.");
    //     for(uint i = 0 ; i < _distributionTime.length ; i++) {
    //         VestingPeriod memory newVestingPeriod;
    //         newVestingPeriod.distributionTime = _distributionTime[i];
    //         newVestingPeriod.unlockRate = _unlockRate[i];
    //         newVestingPeriod.statusWithDraw = false;
    //         if(LIST_VESTING_PERIOD.length > 0) {
    //             uint256 lengthVestingPeriod = LIST_VESTING_PERIOD.length -1;
    //             uint256 totalRateWithdraw;
    //             for(uint j = 0 ; j < LIST_VESTING_PERIOD.length ; j++) {
    //                 totalRateWithdraw += LIST_VESTING_PERIOD[j].unlockRate;
    //             }
    //             if(LIST_VESTING_PERIOD[lengthVestingPeriod].distributionTime < _distributionTime[i] && 100 - totalRateWithdraw - _unlockRate[i] >= 0){
    //                 LIST_VESTING_PERIOD.push(newVestingPeriod);
    //             }else {
    //                 revert("WRONG DISTRIBUTION TIME OR UNLOCKRATE OVERFLOW.");
    //             }
    //         }else{
    //             LIST_VESTING_PERIOD.push(newVestingPeriod);
    //         }
    //     }
    // }

    function updateNewVestingPeriod(uint256[] memory _distributionTime, uint256[] memory _unlockRate) public onlyPresaleOwner {
        for (uint256 i = 0; i < LIST_VESTING_PERIOD.length; i++) {
            if(LIST_VESTING_PERIOD[i].statusWithDraw){
                revert("CAN'T UPDATE NEW VESTING PERIOD.");
            }
        }

        require(_distributionTime.length == _unlockRate.length, "ARRAY MUST BE SAME LENGTH.");
        
        delete LIST_VESTING_PERIOD;
        for (uint256 i = 0; i < _distributionTime.length; i++) {
            VestingPeriod memory newVestingPeriod;
            newVestingPeriod.distributionTime = _distributionTime[i];
            newVestingPeriod.unlockRate = _unlockRate[i];
            LIST_VESTING_PERIOD.push(newVestingPeriod);
        }

        emit AlertAddNewVestingPeriod(
            msg.sender,
            _distributionTime,
            _unlockRate
        );
    }

    function updateCode(address _presaleAddress) external onlyPresaleOwner {
        updateCodeAddress(_presaleAddress);
    }

    function getVetingPeriodInfo() public view returns(
        uint256[] memory,
        uint256[] memory,
        bool[] memory
    ) {
        uint256 lengthVetingPeriod = LIST_VESTING_PERIOD.length;
        uint256[] memory distributionTime = new uint256[](lengthVetingPeriod);
        uint256[] memory unlockRate = new uint256[](lengthVetingPeriod);
        bool[] memory statusWithdraw = new bool[](lengthVetingPeriod);

        for(uint256 i = 0; i < lengthVetingPeriod; i++) {
            distributionTime[i] = LIST_VESTING_PERIOD[i].distributionTime;
            unlockRate[i] = LIST_VESTING_PERIOD[i].unlockRate;
            statusWithdraw[i] = LIST_VESTING_PERIOD[i].statusWithDraw;
        } 
        
        return(distributionTime, unlockRate, statusWithdraw);
    }
}