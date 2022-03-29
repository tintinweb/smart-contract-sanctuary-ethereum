/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.7.0;


// 
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

// 
interface ICricStoxMaster {
    function quote(address stox_, uint256 quantity_) external view returns (uint256);
    function buyExactStoxForTokens(address stox_, address token_, uint amountMax_, uint256 quantity_) external returns (bool);
    function buyStoxForExactTokens(address stox_, address token_, uint256 amount_, uint256 quantityMin_) external returns (bool);
    function sellExactStoxForTokens(address stox_, address token_, uint256 amountMin_, uint256 quantity_) external returns (bool);
    function sellStoxForExactTokens(address stox_, address token_, uint256 amount_, uint256 quantityMax_) external returns (bool);
}

// 
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

// 
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

// 
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

// 
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

// 
contract PlayerStoxToken is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply = 0;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) public transferAllowances;
    bool public transferEnabled;
    address public cricStoxMasterAddress;
    address public adminWallet;

    /**
     * @dev Constructor function.
     * @param name_ The name of the token.
     * @param symbol_ The symbol of the token.
     * @param decimals_ The number of decimals for the token.
     * @param cricStoxMasterAddress_ The address of master contract.
     * @param adminWallet_ The address of admin wallet.
     */
    constructor (string memory name_, string memory symbol_, uint8 decimals_, address cricStoxMasterAddress_, address adminWallet_, address[] memory allowTransferFrom_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        cricStoxMasterAddress = address(cricStoxMasterAddress_);
        adminWallet = address(adminWallet_);
        for(uint8 i=0; i<allowTransferFrom_.length; i++) {
            transferAllowances[allowTransferFrom_[i]] = true;
        }
        transferEnabled = false;
        transferOwnership(adminWallet);
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
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the total supply of the token.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the balance of a particular `account_`.
     * @param account_ The account to check balance.
     */
    function balanceOf(address account_) public view virtual override returns (uint256) {
        return _balances[account_];
    }

    /**
     * @dev Move `amount_` of token to `recipient_`.
     * @param recipient_ The address to transfer to transfer token.
     * @param amount_ The amount of token to be transferred.
     *
     */
    function transfer(address recipient_, uint256 amount_) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient_, amount_);
        return true;
    }

    /**
     * @dev Returns allowance for a particular `spender_` to transfer tokens that belong to `owner_`.
     * @param owner_ The owner of the token.
     * @param spender_ The address of the spender to check allowance for.
     */
    function allowance(address owner_, address spender_) public view virtual override returns (uint256) {
        return _allowances[owner_][spender_];
    }

    /**
     * @dev Approve `spender_` address to transfer `amount_` tokens.
     * @param spender_ The address to approve for transferring tokens.
     * @param amount_ The amount of token to be approved.
     */
    function approve(address spender_, uint256 amount_) public virtual override returns (bool) {
        _approve(_msgSender(), spender_, amount_);
        return true;
    }

    /**
     * @dev Move `amount_` tokens from `sender_` address to `recipient_` address.
     * @param sender_ The address from which token has to be transferred.
     * @param recipient_ The address to which token has to be transferred.
     * @param amount_ The amount of token to be transferred.
     */
    function transferFrom(address sender_, address recipient_, uint256 amount_) public virtual override returns (bool) {
        _transfer(sender_, recipient_, amount_);
        _approve(sender_, _msgSender(), _allowances[sender_][_msgSender()].sub(amount_));
        return true;
    }

    function mint(address account_, uint256 amount_) external returns (bool) {
        require(_msgSender() == cricStoxMasterAddress, "Callable only by Master");
        _mint(account_, amount_);
        return true;
    }

    function burn(address account_, uint256 amount_) external returns (bool) {
        require(_msgSender() == cricStoxMasterAddress, "Callable only by Master");
        _burn(account_, amount_);
        return true;
    }

    /**
     * @dev Moves `amount_` tokens from `sender_` to `recipient_`.
     * @param sender_ The address from which token has to be transferred.
     * @param recipient_ The address to which token has to be transferred.
     * @param amount_ The amount of token to be transferred.
     */
    function _transfer(address sender_, address recipient_, uint256 amount_) internal virtual {
        require(sender_ != address(0), "ERC20: transfer from the zero address");
        if(!transferEnabled) {
            require(transferAllowances[sender_], "Transfer is not allowed");
        }
        require(recipient_ != address(0), "ERC20: transfer to the zero address");

        _balances[sender_] = _balances[sender_].sub(amount_);
        _balances[recipient_] = _balances[recipient_].add(amount_);
        emit Transfer(sender_, recipient_, amount_);
    }

    /** @dev Creates `amount_` tokens and assigns them to `account_`, increasing
     * the total supply.
     * @param account_ The account to assign tokens to.
     * @param amount_ The amount of token to be minted and assigned.
     */
    function _mint(address account_, uint256 amount_) internal virtual {
        require(account_ != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount_);
        _balances[account_] = _balances[account_].add(amount_);
        emit Transfer(address(0), account_, amount_);
    }

    /**
     * @dev Destroys `amount_` tokens from `account_`, reducing the
     * total supply.
     * @param account_ The account to destroy token from.
     * @param amount_ The amount of token to be destroyed.
     */
    function _burn(address account_, uint256 amount_) internal virtual {
        require(account_ != address(0), "ERC20: burn from the zero address");

        _balances[account_] = _balances[account_].sub(amount_);
        _totalSupply = _totalSupply.sub(amount_);
        emit Transfer(account_, address(0), amount_);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     * @param owner_ The owner of the token.
     * @param spender_ The address to approve for transferring tokens.
     * @param amount_ The amount of token to be approved.
     */
    function _approve(address owner_, address spender_, uint256 amount_) internal virtual {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender_ != address(0), "ERC20: approve to the zero address");

        _allowances[owner_][spender_] = amount_;
        emit Approval(owner_, spender_, amount_);
    }

    /**
     * @dev Enable transfer of tokens.
     * @param value_ The bool value for enable.
     */
    function enableTransfer(bool value_) external onlyOwner {
        require(transferEnabled != value_);
        transferEnabled = value_;
    }

    /**
     * @dev Allow transfer from a particular sender (This is to give special permission to our pools).
     * @param sender_ The address to give permission to.
     * @param value_ The bool value for permission.
     */
    function allowTransferFrom(address sender_, bool value_) external onlyOwner {
        require(transferEnabled != value_);
        transferAllowances[sender_] = value_;
    }
}

// 
contract CricStoxFactory is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;

    address public adminWallet;
    EnumerableSet.AddressSet private playerStoxs;
    address public cricStoxMasterAddress;
    address public baseCurrency;

    /**
     * @dev Constructor function.
     * @param adminWallet_ The address of admin wallet.
     * @param baseCurrency_ The address of base currency for all trades.
     */
    constructor(address adminWallet_, address baseCurrency_) {
        adminWallet = address(adminWallet_);
        transferOwnership(adminWallet);
        baseCurrency = address(baseCurrency_);
    }

    event stoxCreated(address stoxContract);

    /**
     * @dev Initializes cricStoxMasterAddress.
     * @param cricStoxMasterAddress_ The address of CricStox Master contract.
     */
    function initMaster(address cricStoxMasterAddress_) external {
        require(
            cricStoxMasterAddress == address(0),
            "Master already initialized"
        );
        cricStoxMasterAddress = address(cricStoxMasterAddress_);
    }

    /**
     * @dev Returns the number of player stox in our directory.
     * @return count of player stox token.
     */
    function playerStoxsLength() external view returns (uint256) {
        return playerStoxs.length();
    }

    /**
     * @dev Get address of player stox token at a particular index.
     * @param index_ The index to get player stox token.
     * @return address of player stox token.
     */
    function playerStoxAtIndex(uint256 index_) external view returns (address) {
        return playerStoxs.at(index_);
    }

    /**
     * @dev Get if a player stox token exist in directory.
     * @param playerStox_ The address of player stox token.
     * @return bool value based on whether stox exist.
     */
    function getPlayerStox(address playerStox_) external view returns (bool) {
        return playerStoxs.contains(playerStox_);
    }

    /**
     * @dev Get if a player stox token exist in directory.
     * @param name_ The name of player stox token.
     * @param symbol_ The symbol of player stox token.
     * @param decimals_ The number of decimals for player stox token.
     * @param pools_ The array of addresses of pools.
     * @param poolShares_ The array of shares for every pool.
     */
    function createPlayerStox(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address[] memory pools_,
        uint256[] memory poolShares_
    ) external onlyOwner {
        require(
            pools_.length == poolShares_.length,
            "Mismatched array lengths for pools and pool shares"
        );
        address[] memory transferAllowances = new address[](pools_.length + 1);
        for (uint8 i = 0; i < pools_.length; i++) {
            transferAllowances[i] = pools_[i];
        }
        transferAllowances[pools_.length] = address(this);
        PlayerStoxToken playerStox = new PlayerStoxToken(
            name_,
            symbol_,
            decimals_,
            cricStoxMasterAddress,
            adminWallet,
            transferAllowances
        );
        playerStoxs.add(address(playerStox));
        if (pools_.length > 0) {
            uint256 totalShares = 0;
            for (uint8 i = 0; i < poolShares_.length; i++) {
                totalShares = totalShares.add(poolShares_[i]);
            }
            uint256 quote = ICricStoxMaster(cricStoxMasterAddress).quote(
                address(playerStox),
                totalShares
            );
            uint256 amount = totalShares.mul(quote);
            // if (amount > 0) {
            //     bool success = ICricStoxMaster(cricStoxMasterAddress)
            //         .buyExactStoxForTokens(
            //             address(playerStox),
            //             baseCurrency,
            //             amount,
            //             totalShares
            //         );
            //     require(success, "Couldn't buy stox tokens");
            //     IERC20 token = IERC20(address(playerStox));
            //     for (uint8 i = 0; i < pools_.length; i++) {
            //         token.transfer(pools_[i], poolShares_[i]);
            //     }
            // }
        }
        emit stoxCreated(address(playerStox));
    }
}