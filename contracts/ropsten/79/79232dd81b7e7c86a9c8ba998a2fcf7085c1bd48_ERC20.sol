/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

/**
 *Submitted for verification at Etherscan.io on 2020-12-02
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.1;

// File: @openzeppelin/contracts/GSN/Context.sol

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/math/SafeMath.sol

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

// File: @openzeppelin/contracts/utils/Address.sol

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol





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
    using Address for address;

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
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
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
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
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
     * Requirements
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
     * Requirements
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
    function _setupDecimals(uint8 decimals_) internal {
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

// File: @openzeppelin/contracts/utils/SafeCast.sol


/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// File: contracts/util/AddressList.sol

library AddressList {
    /**
     * @dev Inserts token address in addressList except for zero address.
     */
    function insert(address[] storage addressList, address token) internal {
        if (token == address(0)) {
            return;
        }

        for (uint256 i = 0; i < addressList.length; i++) {
            if (addressList[i] == address(0)) {
                addressList[i] = token;
                return;
            }
        }

        addressList.push(token);
    }

    /**
     * @dev Removes token address from addressList except for zero address.
     */
    function remove(address[] storage addressList, address token) internal returns (bool success) {
        if (token == address(0)) {
            return true;
        }

        for (uint256 i = 0; i < addressList.length; i++) {
            if (addressList[i] == token) {
                delete addressList[i];
                return true;
            }
        }
    }

    /**
     * @dev Returns the addresses included in addressList except for zero address.
     */
    function get(address[] storage addressList)
        internal
        view
        returns (address[] memory denseAddressList)
    {
        uint256 numOfElements = 0;
        for (uint256 i = 0; i < addressList.length; i++) {
            if (addressList[i] != address(0)) {
                numOfElements++;
            }
        }

        denseAddressList = new address[](numOfElements);
        uint256 j = 0;
        for (uint256 i = 0; i < addressList.length; i++) {
            if (addressList[i] != address(0)) {
                denseAddressList[j] = addressList[i];
                j++;
            }
        }
    }
}

// File: contracts/token/Whitelist.sol


contract Whitelist {
    using AddressList for address[];

    /* ========== STATE VARIABLES ========== */

    /**
     * @dev mapping from user address to whitelist token addresses
     */
    address[] internal _whitelist;

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @dev Inserts token address in _whitelist except for ETH (= address(0)).
     */
    function _addWhitelist(address token) internal {
        return _whitelist.insert(token);
    }

    /**
     * @dev Removes token address from _whitelist except for ETH (= address(0)).
     */
    function _removeWhitelist(address token) internal returns (bool success) {
        return _whitelist.remove(token);
    }

    /**
     * @dev Returns the addresses included in _whitelist except for zero address.
     */
    function _getWhitelist() internal view returns (address[] memory) {
        return _whitelist.get();
    }
}

// File: contracts/oracle/OracleInterface.sol

/**
 * @dev Oracle referenced by OracleProxy must implement this interface.
 */
interface OracleInterface {
    function latestAnswer() external view returns (int256);

    function decimals() external view returns (uint8);
}

// File: contracts/token/TaxToken.sol






contract TaxToken is ERC20("TAX", "TAX"), Whitelist {
    using SafeMath for uint256;
    using SafeMath for uint128;
    using SafeCast for uint256;

    /* ========== CONSTANT VARIABLES ========== */

    address internal immutable _deployer;
    uint256 internal immutable _halvingStartLendValue;
    uint256 internal immutable _maxTotalSupply;
    uint256 internal immutable _initialMintUnit;
    uint256 internal immutable _developerFundRateE8;
    uint256 internal immutable _incentiveFundRateE8;

    /* ========== STATE VARIABLES ========== */

    address[] internal _incentiveFundAddresses;
    uint256[] internal _incentiveFundAllocationE8;

    uint128 internal _developerFund;
    uint128 internal _incentiveFund;
    uint128 internal _totalLendValue;

    address internal _governanceAddress;
    address internal _developer;
    address internal _lendingAddress;

    mapping(address => address) internal _tokenPriceOracle;

    /* ========== EVENTS ========== */

    event LogUpdateGovernanceAddress(address newAddress);
    event LogUpdateLendingAddress(address newAddress);
    event LogRegisterWhitelist(address tokenAddress, address oracleAddress);
    event LogUnregisterWhitelist(address tokenAddress);
    event LogUpdateIncentiveAddresses(
        address[] newIncentiveAddresses,
        uint256[] newIncentiveAllocationE8
    );

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address governanceAddress,
        address developer,
        address[] memory incentiveFundAddresses,
        uint256[] memory incentiveFundAllocationE8,
        uint256 developerFundRateE8,
        uint256 incentiveFundRateE8,
        address lendingAddress,
        uint256 halvingStartLendValue,
        uint256 maxTotalSupply,
        uint256 initialMintUnit
    ) {
        _deployer = msg.sender;
        _governanceAddress = governanceAddress; // governance address can update or delete whitelist
        _developer = developer; // developer fund address
        _incentiveFundAddresses = incentiveFundAddresses; // incentive fund addresses. ex) uniswap share token staking contract address
        _incentiveFundAllocationE8 = incentiveFundAllocationE8; //[0.3 * 10**8, 0.7 * 10**8]. sum should be 10**8
        _developerFundRateE8 = developerFundRateE8; // developer fund rate. when 5%, should be set as 0.05 * 10**8
        _incentiveFundRateE8 = incentiveFundRateE8; // incentive fund rate. when 10%, should be set as 0.1 * 10**8
        _lendingAddress = lendingAddress; // lending contract address
        _halvingStartLendValue = halvingStartLendValue; // the amount of totalLendValue that initial halving occurs. set at 2 * 10**8 = 200M dollar
        _maxTotalSupply = maxTotalSupply; // total supply of tax token, set at 1 * 10**9 * 10**18 = 1B tax
        _initialMintUnit = initialMintUnit; // amount to mint per unit, set at 1 * 10**18

        require(
            _incentiveFundAddresses.length == _incentiveFundAllocationE8.length,
            "the length of the addresses and their allocation should be the same"
        );
        uint256 sumcheck = 0;
        for (uint256 i = 0; i < _incentiveFundAllocationE8.length; i++) {
            sumcheck = sumcheck.add(_incentiveFundAllocationE8[i]);
        }
        require(sumcheck == 10**8, "the sum of the allocation should be 10**8");
    }

    /* ========== MODIFIERS ========== */

    modifier onlyGovernance() {
        require(msg.sender == _governanceAddress, "only governance address can call");
        _;
    }

    modifier onlyLending() {
        require(msg.sender == _lendingAddress, "only lending contract address can call");
        _;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice mint token only when the lended ERC20 is whitelisted.
     * @dev this contract will not function when the total lend value of whitelisted tokens exceeds 2**128 dollar.
     * this contract will lose value when the oracle of the whitelisted tokens collapses and returns an extraordinary large number.
     */
    function mintToken(
        address tokenAddress,
        uint256 lendAmount,
        address recipient
    ) external onlyLending {
        if (_maxTotalSupply == totalSupply()) {
            return;
        }
        uint8 decimalsOfLendingToken = 18; // decimals of ETH
        if (tokenAddress != address(0)) {
            decimalsOfLendingToken = ERC20(tokenAddress).decimals();
        }

        address oracle = _tokenPriceOracle[tokenAddress];
        uint256 mintAmount = 0;
        if (oracle != address(0)) {
            OracleInterface oracleContract = OracleInterface(oracle);
            uint256 price = uint256(oracleContract.latestAnswer());
            uint8 decimalsOfOraclePrice = oracleContract.decimals();
            uint256 asOfMintUnit = _getMintUnit();
            uint256 lendValue = lendAmount.mul(price).div(
                10**uint256(decimalsOfOraclePrice + decimalsOfLendingToken)
            );
            _totalLendValue = _totalLendValue.add(lendValue).toUint128();
            mintAmount = lendValue.mul(asOfMintUnit);
            uint256 remainingMintableAmount = _maxTotalSupply.sub(
                totalSupply().add(_developerFund).add(_incentiveFund)
            );
            mintAmount = remainingMintableAmount >= mintAmount
                ? mintAmount
                : remainingMintableAmount;
        }
        if (mintAmount != 0) {
            uint256 devFund = mintAmount.mul(_developerFundRateE8) / 10**8;
            uint256 incFund = mintAmount.mul(_incentiveFundRateE8) / 10**8;
            _developerFund = _developerFund.add(devFund).toUint128();
            _incentiveFund = _incentiveFund.add(incFund).toUint128();
            _mint(recipient, mintAmount.sub(devFund).sub(incFund));
        }
    }

    /**
     * @notice governanceAddress can add/override ERC20 token to the whitelist with the oracle address.
     * any ERC20 token can use the lending contract, but only the whitelisted addresses can earn tax token.
     */
    function registerWhitelist(address tokenAddress, address oracleAddress)
        external
        onlyGovernance
    {
        OracleInterface oracleContract = OracleInterface(oracleAddress);
        oracleContract.decimals();
        oracleContract.latestAnswer();

        _tokenPriceOracle[tokenAddress] = oracleAddress;
        _addWhitelist(tokenAddress);

        emit LogRegisterWhitelist(tokenAddress, oracleAddress);
    }

    /**
     * @notice governanceAddress can delist from the whitelist.
     */
    function unregisterWhitelist(address tokenAddress) external onlyGovernance {
        delete _tokenPriceOracle[tokenAddress];
        _removeWhitelist(tokenAddress);

        emit LogUnregisterWhitelist(tokenAddress);
    }

    /**
     * @notice lendingAddress can be updated by the deployer.
     * @dev can be used only before the deployer transfers the rights of governance
     */
    function updateLendingAddress(address newLendingAddress) external onlyGovernance {
        _lendingAddress = newLendingAddress;

        emit LogUpdateLendingAddress(newLendingAddress);
    }

    /**
     * @notice only governance contract can update incentive addresses and their allocation.
     */
    function updateIncentiveAddresses(
        address[] memory newIncentiveAddresses,
        uint256[] memory newIncentiveAllocation
    ) external onlyGovernance {
        require(
            newIncentiveAddresses.length == newIncentiveAllocation.length,
            "the length of the addresses and the allocation should be the same"
        );
        uint256 sumcheck = 0;
        for (uint256 i = 0; i < newIncentiveAllocation.length; i++) {
            sumcheck = sumcheck.add(newIncentiveAllocation[i]);
        }
        require(sumcheck == 10**8, "the sum of the allocation should be 10**8");

        _incentiveFundAddresses = newIncentiveAddresses;
        _incentiveFundAllocationE8 = newIncentiveAllocation;

        emit LogUpdateIncentiveAddresses(newIncentiveAddresses, newIncentiveAllocation);
    }

    /**
     * @notice governanceAddress can be updated by the deployer.
     * @dev can be used only before the deployer transfers the rights of governance
     */
    function updateGovernanceAddress(address newGovernanceAddress) external onlyGovernance {
        _governanceAddress = newGovernanceAddress;

        emit LogUpdateGovernanceAddress(newGovernanceAddress);
    }

    /**
     * @notice mint tax token to the developer address up to the available amount.
     */
    function mintDeveloperFund() external {
        uint256 amount = _developerFund;
        _developerFund = 0;
        require(amount != 0, "no mintable amount");
        _mint(_developer, amount);
    }

    /**
     * @notice mint tax token to the incentive fund addresses up to the available amount.
     */
    function mintIncentiveFund() external {
        uint256 amount = _incentiveFund;
        _incentiveFund = 0;
        require(amount != 0, "no mintable amount");
        require(_incentiveFundAddresses.length != 0, "incentive fund addresses have not been set");
        for (uint256 i = 0; i < _incentiveFundAddresses.length; i++) {
            _mint(_incentiveFundAddresses[i], amount.mul(_incentiveFundAllocationE8[i]).div(10**8));
        }
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _getMintUnit() internal view returns (uint256 asOfMintUnit) {
        uint256 totalLendValue = _totalLendValue;
        asOfMintUnit = _initialMintUnit;
        while (totalLendValue >= _halvingStartLendValue) {
            asOfMintUnit = asOfMintUnit / 2;
            totalLendValue = totalLendValue / 2;
        }
        asOfMintUnit = totalSupply() == _maxTotalSupply ? 0 : asOfMintUnit;
    }

    /* ========== CALL FUNCTIONS ========== */

    /**
     * @return governance contract address
     */
    function getGovernanceAddress() external view returns (address) {
        return _governanceAddress;
    }

    /**
     * @return developer fund address
     */
    function getDeveloperAddress() external view returns (address) {
        return _developer;
    }

    /**
     * @return lending contract address.
     */
    function getLendingAddress() external view returns (address) {
        return _lendingAddress;
    }

    /**
     * @notice get the immutable initial config values.
     */
    function getConfigs()
        external
        view
        returns (
            uint256 maxTotalSupply,
            uint256 halvingStartLendValue,
            uint256 initialMintUnit,
            uint256 developerFundRateE8,
            uint256 incentiveFundRateE8
        )
    {
        maxTotalSupply = _maxTotalSupply;
        halvingStartLendValue = _halvingStartLendValue;
        initialMintUnit = _initialMintUnit;
        developerFundRateE8 = _developerFundRateE8;
        incentiveFundRateE8 = _incentiveFundRateE8;
    }

    function getWhitelist() external view returns (address[] memory) {
        return _getWhitelist();
    }

    /**
     * @notice Get the incentive addresses and their allocation.
     */
    function getIncentiveFundAddresses()
        external
        view
        returns (
            address[] memory incentiveFundAddresses,
            uint256[] memory incentiveFundAllocationE8
        )
    {
        incentiveFundAddresses = _incentiveFundAddresses;
        incentiveFundAllocationE8 = _incentiveFundAllocationE8;
    }

    /**
     * @notice Get the current mintable amount for developer fund and incentive fund.
     */
    function getFunds() external view returns (uint256 developerFund, uint256 incentiveFund) {
        developerFund = _developerFund;
        incentiveFund = _incentiveFund;
    }

    /**
     * @notice Get the current amount to be minted per a dollar of lending.
     * @dev the amount to mint per a dollar of lending decays exponentially.
     */
    function getMintUnit() external view returns (uint256) {
        return _getMintUnit();
    }

    /**
     * @return oracle address of the erc20.
     * @dev returns zero address when the erc20 is not whitelisted.
     */
    function getOracleAddress(address tokenAddress) external view returns (address) {
        return _tokenPriceOracle[tokenAddress];
    }
}