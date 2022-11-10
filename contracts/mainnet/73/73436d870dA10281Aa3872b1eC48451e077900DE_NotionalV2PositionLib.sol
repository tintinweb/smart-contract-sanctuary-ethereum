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

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <[email protected]>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IExternalPosition Contract
/// @author Enzyme Council <[email protected]>
interface IExternalPosition {
    function getDebtAssets() external returns (address[] memory, uint256[] memory);

    function getManagedAssets() external returns (address[] memory, uint256[] memory);

    function init(bytes memory) external;

    function receiveCallFromVault(bytes memory) external;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <[email protected]>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

import "../../../../../persistent/external-positions/IExternalPosition.sol";

pragma solidity 0.6.12;

/// @title INotionalV2Position Interface
/// @author Enzyme Council <[email protected]>
interface INotionalV2Position is IExternalPosition {
    enum Actions {
        AddCollateral,
        Lend,
        Redeem,
        Borrow
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <[email protected]>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title NotionalV2PositionDataDecoder Contract
/// @author Enzyme Council <[email protected]>
/// @notice Abstract contract containing data decodings for NotionalV2Position payloads
abstract contract NotionalV2PositionDataDecoder {
    /// @dev Helper to decode args used during the AddCollateral action
    function __decodeAddCollateralActionArgs(bytes memory _actionArgs)
        internal
        pure
        returns (uint16 currencyId_, uint256 collateralAssetAmount_)
    {
        return abi.decode(_actionArgs, (uint16, uint256));
    }

    /// @dev Helper to decode args used during the Borrow action
    function __decodeBorrowActionArgs(bytes memory _actionArgs)
        internal
        pure
        returns (
            uint16 borrowCurrencyId_,
            bytes32 encodedBorrowTrade_,
            uint16 collateralCurrencyId_,
            uint256 collateralAssetAmount_
        )
    {
        return abi.decode(_actionArgs, (uint16, bytes32, uint16, uint256));
    }

    /// @dev Helper to decode args used during the Lend action
    function __decodeLendActionArgs(bytes memory _actionArgs)
        internal
        pure
        returns (
            uint16 currencyId_,
            uint256 underlyingTokenAmount_,
            bytes32 encodedLendTrade_
        )
    {
        return abi.decode(_actionArgs, (uint16, uint256, bytes32));
    }

    /// @dev Helper to decode args used during the Redeem action
    function __decodeRedeemActionArgs(bytes memory _actionArgs)
        internal
        pure
        returns (uint16 currencyId_, uint88 yieldTokenAmount_)
    {
        return abi.decode(_actionArgs, (uint16, uint88));
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <[email protected]>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../../../interfaces/INotionalV2Router.sol";
import "../../../../interfaces/IWETH.sol";
import "../../../../utils/AssetHelpers.sol";
import "./INotionalV2Position.sol";
import "./NotionalV2PositionDataDecoder.sol";

/// @title NotionalV2PositionLib Contract
/// @author Enzyme Council <[email protected]>
/// @notice An External Position library contract for Notional V2 Positions
contract NotionalV2PositionLib is
    INotionalV2Position,
    NotionalV2PositionDataDecoder,
    AssetHelpers
{
    using SafeERC20 for ERC20;
    using SafeMath for uint256;

    uint16 private constant ETH_CURRENCY_ID = 1;
    uint256 private constant FCASH_DECIMALS_FACTOR = 10**8;

    INotionalV2Router private immutable NOTIONAL_V2_ROUTER_CONTRACT;
    address private immutable WETH_TOKEN;

    constructor(address _notionalV2Router, address _wethToken) public {
        NOTIONAL_V2_ROUTER_CONTRACT = INotionalV2Router(_notionalV2Router);
        WETH_TOKEN = _wethToken;
    }

    /// @notice Initializes the external position
    /// @dev Nothing to initialize for this contract
    function init(bytes memory) external override {}

    /// @notice Receives and executes a call from the Vault
    /// @param _actionData Encoded data to execute the action
    function receiveCallFromVault(bytes memory _actionData) external override {
        (uint256 actionId, bytes memory actionArgs) = abi.decode(_actionData, (uint256, bytes));

        if (actionId == uint256(Actions.AddCollateral)) {
            __actionAddCollateral(actionArgs);
        } else if (actionId == uint256(Actions.Lend)) {
            __actionLend(actionArgs);
        } else if (actionId == uint256(Actions.Redeem)) {
            __actionRedeem(actionArgs);
        } else if (actionId == uint256(Actions.Borrow)) {
            __actionBorrow(actionArgs);
        } else {
            revert("receiveCallFromVault: Invalid actionId");
        }
    }

    /// @dev Adds collateral to Notional V2 account
    function __actionAddCollateral(bytes memory _actionArgs) private {
        (uint16 currencyId, uint256 collateralAssetAmount) = __decodeAddCollateralActionArgs(
            _actionArgs
        );

        __addCollateral(currencyId, collateralAssetAmount);
    }

    /// @dev Borrows assets from a Notional V2 market
    function __actionBorrow(bytes memory _actionArgs) private {
        (
            uint16 borrowCurrencyId,
            bytes32 encodedTrade,
            uint16 collateralCurrencyId,
            uint256 collateralAssetAmount
        ) = __decodeBorrowActionArgs(_actionArgs);

        if (collateralAssetAmount > 0) {
            __addCollateral(collateralCurrencyId, collateralAssetAmount);
        }

        bytes32[] memory encodedTrades = new bytes32[](1);
        encodedTrades[0] = encodedTrade;

        INotionalV2Router.BalanceActionWithTrades[]
            memory actionsWithTrades = new INotionalV2Router.BalanceActionWithTrades[](1);

        // `withdrawEntireCashBalance: true` sends the borrowed asset to this contract
        // `redeemToUnderlying: true` sends the borrowed asset as the underlying token (e.g., DAI rather than cDAI)
        actionsWithTrades[0] = INotionalV2Router.BalanceActionWithTrades({
            actionType: INotionalV2Router.DepositActionType.None,
            currencyId: borrowCurrencyId,
            depositActionAmount: 0,
            withdrawAmountInternalPrecision: 0,
            withdrawEntireCashBalance: true,
            redeemToUnderlying: true,
            trades: encodedTrades
        });

        NOTIONAL_V2_ROUTER_CONTRACT.batchBalanceAndTradeAction(address(this), actionsWithTrades);

        if (borrowCurrencyId == ETH_CURRENCY_ID) {
            uint256 etherBalance = payable(address(this)).balance;

            IWETH(payable(address(WETH_TOKEN))).deposit{value: etherBalance}();

            // Send borrowed ETH to the vault wrapped as WETH
            ERC20(WETH_TOKEN).safeTransfer(msg.sender, etherBalance);
        } else {
            (, INotionalV2Router.Token memory underlyingAsset) = NOTIONAL_V2_ROUTER_CONTRACT
                .getCurrency(borrowCurrencyId);

            // Send borrowed asset tokens to the vault
            ERC20(underlyingAsset.tokenAddress).safeTransfer(
                msg.sender,
                ERC20(underlyingAsset.tokenAddress).balanceOf(address(this))
            );
        }
    }

    /// @dev Lends assets to a Notional V2 market
    function __actionLend(bytes memory _actionArgs) private {
        (
            uint16 currencyId,
            uint256 underlyingAssetAmount,
            bytes32 encodedTrade
        ) = __decodeLendActionArgs(_actionArgs);

        bytes32[] memory encodedTrades = new bytes32[](1);
        encodedTrades[0] = encodedTrade;

        INotionalV2Router.BalanceActionWithTrades[]
            memory actionsWithTrades = new INotionalV2Router.BalanceActionWithTrades[](1);

        // It is recommended that `depositActionAmount` is larger than the desired amount to lend,
        // as rates can change between blocks. `withdrawEntireCashBalance = true` will send any
        // excess `underlyingTokenAmount` balance back to this contract.
        actionsWithTrades[0] = INotionalV2Router.BalanceActionWithTrades({
            actionType: INotionalV2Router.DepositActionType.DepositUnderlying,
            currencyId: currencyId,
            depositActionAmount: underlyingAssetAmount,
            withdrawAmountInternalPrecision: 0,
            withdrawEntireCashBalance: true,
            redeemToUnderlying: true,
            trades: encodedTrades
        });

        if (currencyId == ETH_CURRENCY_ID) {
            IWETH(payable(address(WETH_TOKEN))).withdraw(underlyingAssetAmount);

            NOTIONAL_V2_ROUTER_CONTRACT.batchBalanceAndTradeAction{value: underlyingAssetAmount}(
                address(this),
                actionsWithTrades
            );

            uint256 etherBalance = payable(address(this)).balance;

            IWETH(payable(address(WETH_TOKEN))).deposit{value: etherBalance}();

            if (etherBalance > 0) {
                // Send residual ETH back to the vault wrapped as WETH
                ERC20(WETH_TOKEN).safeTransfer(msg.sender, etherBalance);
            }
        } else {
            (, INotionalV2Router.Token memory underlyingAsset) = NOTIONAL_V2_ROUTER_CONTRACT
                .getCurrency(currencyId);

            __approveAssetMaxAsNeeded(
                underlyingAsset.tokenAddress,
                address(NOTIONAL_V2_ROUTER_CONTRACT),
                underlyingAssetAmount
            );

            NOTIONAL_V2_ROUTER_CONTRACT.batchBalanceAndTradeAction(
                address(this),
                actionsWithTrades
            );

            uint256 underlyingAssetBalance = ERC20(underlyingAsset.tokenAddress).balanceOf(
                address(this)
            );

            if (underlyingAssetBalance > 0) {
                // Send residual underlying asset tokens back to the vault
                ERC20(underlyingAsset.tokenAddress).safeTransfer(
                    msg.sender,
                    underlyingAssetBalance
                );
            }
        }
    }

    /// @dev Redeems an amount of yieldTokens from Notional V2 account balances after fCash maturity
    function __actionRedeem(bytes memory _actionArgs) private {
        (uint16 currencyId, uint88 yieldTokenAmount) = __decodeRedeemActionArgs(_actionArgs);

        NOTIONAL_V2_ROUTER_CONTRACT.withdraw(currencyId, yieldTokenAmount, true);

        // Send tokens back to the vault
        if (currencyId == ETH_CURRENCY_ID) {
            IWETH(payable(address(WETH_TOKEN))).deposit{value: payable(address(this)).balance}();

            ERC20(WETH_TOKEN).safeTransfer(msg.sender, ERC20(WETH_TOKEN).balanceOf(address(this)));
        } else {
            (, INotionalV2Router.Token memory underlyingAsset) = NOTIONAL_V2_ROUTER_CONTRACT
                .getCurrency(currencyId);

            ERC20(underlyingAsset.tokenAddress).safeTransfer(
                msg.sender,
                ERC20(underlyingAsset.tokenAddress).balanceOf(address(this))
            );
        }
    }

    /// @dev Helper to add non-fCash collateral
    function __addCollateral(uint16 _currencyId, uint256 _amount) private {
        if (_currencyId == ETH_CURRENCY_ID) {
            IWETH(payable(address(WETH_TOKEN))).withdraw(_amount);

            NOTIONAL_V2_ROUTER_CONTRACT.depositUnderlyingToken{value: _amount}(
                address(this),
                _currencyId,
                _amount
            );
        } else {
            (, INotionalV2Router.Token memory collateralAsset) = NOTIONAL_V2_ROUTER_CONTRACT
                .getCurrency(_currencyId);

            __approveAssetMaxAsNeeded(
                collateralAsset.tokenAddress,
                address(NOTIONAL_V2_ROUTER_CONTRACT),
                _amount
            );
            NOTIONAL_V2_ROUTER_CONTRACT.depositUnderlyingToken(
                address(this),
                _currencyId,
                _amount
            );
        }
    }

    ////////////////////
    // POSITION VALUE //
    ////////////////////

    /// @notice Retrieves the debt assets (negative value) of the external position
    /// @return assets_ Debt assets
    /// @return amounts_ Debt asset amounts
    /// @dev Debt assets are composed by two type of balances: account portfolio and account assets
    /// Both concepts can be found here: https://docs.notional.finance/developer-documentation/how-to/lend-and-borrow-fcash
    function getDebtAssets()
        external
        override
        returns (address[] memory assets_, uint256[] memory amounts_)
    {
        (assets_, amounts_) = __getPositiveOrNegativeAssets(false);
        return (assets_, amounts_);
    }

    /// @notice Retrieves the managed assets (positive value) of the external position
    /// @return assets_ Managed assets
    /// @return amounts_ Managed asset amounts
    /// @dev Managed assets are composed by two type of balances: account portfolio and account assets
    /// Both concepts can be found here: https://docs.notional.finance/developer-documentation/how-to/lend-and-borrow-fcash
    function getManagedAssets()
        external
        override
        returns (address[] memory assets_, uint256[] memory amounts_)
    {
        return __getPositiveOrNegativeAssets(true);
    }

    // PRIVATE FUNCTIONS

    /// @dev Helper to get all positive or all negative assets within Notional
    function __getPositiveOrNegativeAssets(bool _positiveAssets)
        private
        view
        returns (address[] memory assets_, uint256[] memory amounts_)
    {
        (
            ,
            INotionalV2Router.AccountBalance[] memory accountBalances,
            INotionalV2Router.PortfolioAsset[] memory portfolioAssets
        ) = NOTIONAL_V2_ROUTER_CONTRACT.getAccount(address(this));

        // Calculate total assets length

        uint256 totalAssetsLength;

        for (uint256 i; i < portfolioAssets.length; i++) {
            int256 notionalValue = portfolioAssets[i].notional;

            if (_positiveAssets) {
                if (notionalValue <= 0) {
                    continue;
                }
            } else {
                if (notionalValue >= 0) {
                    continue;
                }
            }

            totalAssetsLength++;
        }

        for (uint256 i; i < accountBalances.length; i++) {
            // A currencyId = 0 signals end of used array slots
            if (accountBalances[i].currencyId == 0) {
                break;
            }

            if (_positiveAssets) {
                if (accountBalances[i].cashBalance <= 0) {
                    continue;
                }
            } else {
                if (accountBalances[i].cashBalance >= 0) {
                    continue;
                }
            }

            totalAssetsLength++;
        }

        assets_ = new address[](totalAssetsLength);
        amounts_ = new uint256[](totalAssetsLength);

        // Calculate amounts of portfolio assets

        uint256 assetsIndexCounter;

        for (uint256 i; i < portfolioAssets.length; i++) {
            if (
                (_positiveAssets && portfolioAssets[i].notional > 0) ||
                (!_positiveAssets && portfolioAssets[i].notional < 0)
            ) {
                uint16 currencyId = uint16(portfolioAssets[i].currencyId);

                (, INotionalV2Router.Token memory underlyingAsset) = NOTIONAL_V2_ROUTER_CONTRACT
                    .getCurrency(currencyId);

                assets_[assetsIndexCounter] = underlyingAsset.tokenAddress;

                int256 presentValue;

                uint256 underlyingAssetDecimalsFactor = 10 **
                    uint256(ERC20(underlyingAsset.tokenAddress).decimals());

                if (block.timestamp >= portfolioAssets[i].maturity) {
                    presentValue = portfolioAssets[i].notional;
                } else {
                    presentValue = NOTIONAL_V2_ROUTER_CONTRACT.getPresentfCashValue(
                        currencyId,
                        portfolioAssets[i].maturity,
                        portfolioAssets[i].notional,
                        block.timestamp,
                        false
                    );
                }

                // Convert negative amounts to positive if dealing with debt assets
                if (!_positiveAssets) {
                    presentValue = -presentValue;
                }

                amounts_[assetsIndexCounter] = uint256(presentValue)
                    .mul(underlyingAssetDecimalsFactor)
                    .div(FCASH_DECIMALS_FACTOR);

                assetsIndexCounter++;
            }
        }

        // Calculate amounts of account balance assets

        for (uint256 i; i < accountBalances.length; i++) {
            // A currencyId = 0 signals end of used array slots
            if (accountBalances[i].currencyId == 0) {
                break;
            }

            if (
                (_positiveAssets && accountBalances[i].cashBalance > 0) ||
                (!_positiveAssets && accountBalances[i].cashBalance < 0)
            ) {
                (INotionalV2Router.Token memory cashToken, ) = NOTIONAL_V2_ROUTER_CONTRACT
                    .getCurrency(accountBalances[i].currencyId);

                assets_[assetsIndexCounter] = cashToken.tokenAddress;

                if (_positiveAssets) {
                    amounts_[assetsIndexCounter] = uint256(accountBalances[i].cashBalance);
                } else {
                    amounts_[assetsIndexCounter] = uint256(-accountBalances[i].cashBalance);
                }

                assetsIndexCounter++;
            }
        }

        // Aggregate similar asset amounts
        if (assets_.length > 1) {
            (assets_, amounts_) = __aggregateAssetAmounts(assets_, amounts_);
        }

        return (assets_, amounts_);
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/// @title INotionalV2Router Interface
/// @author Enzyme Council <[email protected]>
/// @dev This interface is a combination of different interfaces: NotionalProxy, NotionalViews, NotionalCalculations
interface INotionalV2Router {
    enum AssetStorageState {
        NoChange,
        Update,
        Delete,
        RevertIfStored
    }
    enum DepositActionType {
        None,
        DepositAsset,
        DepositUnderlying,
        DepositAssetAndMintNToken,
        DepositUnderlyingAndMintNToken,
        RedeemNToken,
        ConvertCashToNToken
    }
    enum TokenType {
        UnderlyingToken,
        cToken,
        cETH,
        Ether,
        NonMintable,
        aToken
    }

    struct AccountBalance {
        uint16 currencyId;
        int256 cashBalance;
        int256 nTokenBalance;
        uint256 lastClaimTime;
        uint256 accountIncentiveDebt;
    }

    struct AccountContext {
        uint40 nextSettleTime;
        bytes1 hasDebt;
        uint8 assetArrayLength;
        uint16 bitmapCurrencyId;
        bytes18 activeCurrencies;
    }

    struct BalanceActionWithTrades {
        DepositActionType actionType;
        uint16 currencyId;
        uint256 depositActionAmount;
        uint256 withdrawAmountInternalPrecision;
        bool withdrawEntireCashBalance;
        bool redeemToUnderlying;
        bytes32[] trades;
    }

    struct PortfolioAsset {
        uint256 currencyId;
        uint256 maturity;
        uint256 assetType;
        int256 notional;
        uint256 storageSlot;
        AssetStorageState storageState;
    }

    struct Token {
        address tokenAddress;
        bool hasTransferFee;
        int256 decimals;
        TokenType tokenType;
        uint256 maxCollateralBalance;
    }

    function batchBalanceAndTradeAction(
        address _account,
        BalanceActionWithTrades[] calldata _actions
    ) external payable;

    function depositUnderlyingToken(
        address _account,
        uint16 _currencyId,
        uint256 _amountExternalPrecision
    ) external payable returns (uint256);

    function getAccount(address _account)
        external
        view
        returns (
            AccountContext memory accountContext_,
            AccountBalance[] memory accountBalances_,
            PortfolioAsset[] memory portfolio_
        );

    function getAccountBalance(uint16 _currencyId, address _account)
        external
        view
        returns (
            int256 cashBalance_,
            int256 nTokenBalance_,
            uint256 lastClaimTime_
        );

    function getAccountPortfolio(address _account)
        external
        view
        returns (PortfolioAsset[] memory portfolio_);

    function getCurrency(uint16 _currencyId)
        external
        view
        returns (Token memory assetToken_, Token memory underlyingToken_);

    function getPresentfCashValue(
        uint16 _currencyId,
        uint256 _maturity,
        int256 _notional,
        uint256 _blockTime,
        bool _riskAdjusted
    ) external view returns (int256 presentValue_);

    function withdraw(
        uint16 _currencyId,
        uint88 _amountInternalPrecision,
        bool _redeemToUnderlying
    ) external returns (uint256 amount_);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IWETH Interface
/// @author Enzyme Council <[email protected]>
interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/// @title AssetHelpers Contract
/// @author Enzyme Council <[email protected]>
/// @notice A util contract for common token actions
abstract contract AssetHelpers {
    using SafeERC20 for ERC20;
    using SafeMath for uint256;

    /// @dev Helper to aggregate amounts of the same assets
    function __aggregateAssetAmounts(address[] memory _rawAssets, uint256[] memory _rawAmounts)
        internal
        pure
        returns (address[] memory aggregatedAssets_, uint256[] memory aggregatedAmounts_)
    {
        if (_rawAssets.length == 0) {
            return (aggregatedAssets_, aggregatedAmounts_);
        }

        uint256 aggregatedAssetCount = 1;
        for (uint256 i = 1; i < _rawAssets.length; i++) {
            bool contains;
            for (uint256 j; j < i; j++) {
                if (_rawAssets[i] == _rawAssets[j]) {
                    contains = true;
                    break;
                }
            }
            if (!contains) {
                aggregatedAssetCount++;
            }
        }

        aggregatedAssets_ = new address[](aggregatedAssetCount);
        aggregatedAmounts_ = new uint256[](aggregatedAssetCount);
        uint256 aggregatedAssetIndex;
        for (uint256 i; i < _rawAssets.length; i++) {
            bool contains;
            for (uint256 j; j < aggregatedAssetIndex; j++) {
                if (_rawAssets[i] == aggregatedAssets_[j]) {
                    contains = true;

                    aggregatedAmounts_[j] += _rawAmounts[i];

                    break;
                }
            }
            if (!contains) {
                aggregatedAssets_[aggregatedAssetIndex] = _rawAssets[i];
                aggregatedAmounts_[aggregatedAssetIndex] = _rawAmounts[i];
                aggregatedAssetIndex++;
            }
        }

        return (aggregatedAssets_, aggregatedAmounts_);
    }

    /// @dev Helper to approve a target account with the max amount of an asset.
    /// This is helpful for fully trusted contracts, such as adapters that
    /// interact with external protocol like Uniswap, Compound, etc.
    function __approveAssetMaxAsNeeded(
        address _asset,
        address _target,
        uint256 _neededAmount
    ) internal {
        uint256 allowance = ERC20(_asset).allowance(address(this), _target);
        if (allowance < _neededAmount) {
            if (allowance > 0) {
                ERC20(_asset).safeApprove(_target, 0);
            }
            ERC20(_asset).safeApprove(_target, type(uint256).max);
        }
    }

    /// @dev Helper to transfer full asset balance from the current contract to a target
    function __pushFullAssetBalance(address _target, address _asset)
        internal
        returns (uint256 amountTransferred_)
    {
        amountTransferred_ = ERC20(_asset).balanceOf(address(this));
        if (amountTransferred_ > 0) {
            ERC20(_asset).safeTransfer(_target, amountTransferred_);
        }

        return amountTransferred_;
    }

    /// @dev Helper to transfer full asset balances from the current contract to a target
    function __pushFullAssetBalances(address _target, address[] memory _assets)
        internal
        returns (uint256[] memory amountsTransferred_)
    {
        amountsTransferred_ = new uint256[](_assets.length);
        for (uint256 i; i < _assets.length; i++) {
            ERC20 assetContract = ERC20(_assets[i]);
            amountsTransferred_[i] = assetContract.balanceOf(address(this));
            if (amountsTransferred_[i] > 0) {
                assetContract.safeTransfer(_target, amountsTransferred_[i]);
            }
        }

        return amountsTransferred_;
    }
}