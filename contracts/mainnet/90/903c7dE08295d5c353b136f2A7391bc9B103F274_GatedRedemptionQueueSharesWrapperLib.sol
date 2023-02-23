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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


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

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IGlobalConfig1 Interface
/// @author Enzyme Council <[email protected]>
/// @dev Each interface should inherit the previous interface,
/// e.g., `IGlobalConfig2 is IGlobalConfig1`
interface IGlobalConfig1 {
    function isValidRedeemSharesCall(
        address _vaultProxy,
        address _recipientToValidate,
        uint256 _sharesAmountToValidate,
        address _redeemContract,
        bytes4 _redeemSelector,
        bytes calldata _redeemData
    ) external view returns (bool isValid_);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "./IGlobalConfig1.sol";

/// @title IGlobalConfig2 Interface
/// @author Enzyme Council <[email protected]>
/// @dev Each interface should inherit the previous interface,
/// e.g., `IGlobalConfig2 is IGlobalConfig1`
interface IGlobalConfig2 is IGlobalConfig1 {
    function formatDepositCall(
        address _vaultProxy,
        address _depositAsset,
        uint256 _depositAssetAmount
    ) external view returns (address target_, bytes memory payload_);

    function formatSingleAssetRedemptionCall(
        address _vaultProxy,
        address _recipient,
        address _asset,
        uint256 _amount,
        bool _amountIsShares
    ) external view returns (address target_, bytes memory payload_);
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

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/SafeCast.sol";
import "../../global-config/interfaces/IGlobalConfig2.sol";
import "../../vault/interfaces/IVaultCore.sol";
import "./bases/GatedRedemptionQueueSharesWrapperLibBase1.sol";

/// @title GatedRedemptionQueueSharesWrapperLib Contract
/// @author Enzyme Council <[email protected]>
/// @notice A release-agnostic ERC20 wrapper for Enzyme vault shares that facilitates queued,
/// single-asset redemptions, as well as misc participation controls
contract GatedRedemptionQueueSharesWrapperLib is GatedRedemptionQueueSharesWrapperLibBase1 {
    using Address for address;
    using SafeCast for uint256;
    using SafeERC20 for ERC20;

    uint256 private constant ONE_HUNDRED_PERCENT = 1e18;

    IGlobalConfig2 private immutable GLOBAL_CONFIG_CONTRACT;
    address private immutable THIS_LIB;

    modifier onlyManagerOrOwner() {
        require(
            isManager(msg.sender) || msg.sender == IVaultCore(getVaultProxy()).getOwner(),
            "onlyManagerOrOwner: Unauthorized"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == IVaultCore(getVaultProxy()).getOwner(), "onlyOwner: Unauthorized");
        _;
    }

    constructor(address _globalConfigProxy)
        public
        ERC20("Wrapped Enzyme Shares Lib", "wENZF-lib")
    {
        GLOBAL_CONFIG_CONTRACT = IGlobalConfig2(_globalConfigProxy);
        THIS_LIB = address(this);
    }

    /// @notice Initializes a proxy instance
    /// @param _vaultProxy The VaultProxy that will have its shares wrapped
    /// @param _managers Users to give the role of manager for the wrapper
    /// @param _redemptionAsset The asset to receive during shares redemptions
    /// @param _useDepositApprovals True if deposit pre-approvals are required
    /// @param _useRedemptionApprovals True if the redemption request pre-approvals are required
    /// @param _useTransferApprovals True if shares transfer pre-approvals are required
    /// @param _windowConfig Initial redemption window configuration
    function init(
        address _vaultProxy,
        address[] calldata _managers,
        address _redemptionAsset,
        bool _useDepositApprovals,
        bool _useRedemptionApprovals,
        bool _useTransferApprovals,
        GatedRedemptionQueueSharesWrapperLibBase1.RedemptionWindowConfig calldata _windowConfig
    ) external override {
        require(vaultProxy == address(0), "init: Initialized");

        vaultProxy = _vaultProxy;

        __addManagers(_managers);
        __setRedemptionAsset(_redemptionAsset);
        __setUseDepositApprovals(_useDepositApprovals);
        __setUseRedemptionApprovals(_useRedemptionApprovals);
        __setUseTransferApprovals(_useTransferApprovals);
        __setRedemptionWindowConfig(_windowConfig);

        emit Initialized(_vaultProxy);
    }

    /////////////////////
    // ERC20 OVERRIDES //
    /////////////////////

    /// @notice Gets the name of the wrapped shares token
    /// @return name_ The name
    function name() public view override returns (string memory name_) {
        if (address(this) == THIS_LIB) {
            return super.name();
        }

        return string(abi.encodePacked("Wrapped ", ERC20(getVaultProxy()).name()));
    }

    /// @notice Gets the symbol of the wrapped shares token
    /// @return symbol_ The symbol
    function symbol() public view override returns (string memory symbol_) {
        if (address(this) == THIS_LIB) {
            return super.symbol();
        }

        return string(abi.encodePacked("w", ERC20(getVaultProxy()).symbol()));
    }

    /// @notice Gets the number of decimals of the wrapped shares token
    /// @return decimals_ The number of decimals
    function decimals() public view override returns (uint8 decimals_) {
        return 18;
    }

    /// @notice Standard implementation of ERC20's transfer() with additional validations
    function transfer(address _recipient, uint256 _amount)
        public
        override
        returns (bool success_)
    {
        __preProcessTransfer({_sender: msg.sender, _recipient: _recipient, _amount: _amount});

        return super.transfer(_recipient, _amount);
    }

    /// @notice Standard implementation of ERC20's transferFrom() with additional validations
    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) public override returns (bool success_) {
        __preProcessTransfer({_sender: _sender, _recipient: _recipient, _amount: _amount});

        return super.transferFrom(_sender, _recipient, _amount);
    }

    /// @dev Helper to validate transfer
    function __preProcessTransfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) private {
        require(
            _amount <=
                balanceOf(_sender).sub(redemptionQueue.userToRequest[_sender].sharesPending),
            "__preProcessTransfer: In redemption queue"
        );

        if (transferApprovalsAreUsed()) {
            uint256 transferApproval = getTransferApproval({
                _sender: _sender,
                _recipient: _recipient
            });

            if (transferApproval != type(uint256).max) {
                require(transferApproval == _amount, "__preProcessTransfer: Approval mismatch");

                delete userToRecipientToTransferApproval[_sender][_recipient];
            }
        }
    }

    //////////////////////////////////////
    // SUBSCRIPTION ACTIONS - DEPOSITOR //
    //////////////////////////////////////

    /// @notice Cancels the caller's redemption request
    function cancelRequestRedeem() external nonReentrant {
        require(
            !__isInLatestRedemptionWindow(block.timestamp),
            "cancelRequestRedeem: Inside redemption window"
        );

        RedemptionQueue storage queue = redemptionQueue;
        uint256 userSharesPending = queue.userToRequest[msg.sender].sharesPending;
        require(userSharesPending > 0, "cancelRequestRedeem: No request");

        // Remove user from queue
        queue.totalSharesPending = uint256(queue.totalSharesPending)
            .sub(userSharesPending)
            .toUint128();

        __removeRedemptionRequest({_user: msg.sender, _queueLength: queue.users.length});
    }

    /// @notice Deposits a token to mint wrapped Enzyme vault shares
    /// @param _depositAssetContract The token to deposit
    /// @param _depositAssetAmount The amount of the token to deposit
    /// @param _minSharesAmount The min shares to mint
    /// @return sharesReceived_ The amount of wrapped shares received
    /// @dev Does not support deposits in fee-on-transfer tokens
    function deposit(
        ERC20 _depositAssetContract,
        uint256 _depositAssetAmount,
        uint256 _minSharesAmount
    ) external nonReentrant returns (uint256 sharesReceived_) {
        if (depositApprovalsAreUsed()) {
            uint256 depositApproval = getDepositApproval({
                _user: msg.sender,
                _asset: address(_depositAssetContract)
            });

            // If deposit approval is not max, validate and remove exact approval
            if (depositApproval != type(uint256).max) {
                require(depositApproval == _depositAssetAmount, "deposit: Approval mismatch");
                delete userToAssetToDepositApproval[msg.sender][address(_depositAssetContract)];
            }
        }

        // Checkpoint redemption queue relativeSharesAllowed before changing the shares supply
        if (__isInLatestRedemptionWindow(block.timestamp)) {
            __checkpointRelativeSharesAllowed();
        }

        // Pull token from user
        _depositAssetContract.safeTransferFrom(msg.sender, address(this), _depositAssetAmount);

        ERC20 sharesTokenContract = ERC20(getVaultProxy());
        uint256 preSharesBal = sharesTokenContract.balanceOf(address(this));

        // Format the call to deposit for shares
        (address depositTarget, bytes memory depositPayload) = GLOBAL_CONFIG_CONTRACT
            .formatDepositCall({
                _vaultProxy: address(sharesTokenContract),
                _depositAsset: address(_depositAssetContract),
                _depositAssetAmount: _depositAssetAmount
            });

        // Approve the deposit target as necessary
        if (_depositAssetContract.allowance(address(this), depositTarget) == 0) {
            _depositAssetContract.safeApprove(depositTarget, type(uint256).max);
        }

        // Deposit and receive shares
        depositTarget.functionCall(depositPayload);

        // Mint wrapped shares for the actual shares received
        sharesReceived_ = sharesTokenContract.balanceOf(address(this)).sub(preSharesBal);
        require(sharesReceived_ >= _minSharesAmount, "deposit: Insufficient shares");

        _mint(msg.sender, sharesReceived_);

        emit Deposited(
            msg.sender,
            address(_depositAssetContract),
            _depositAssetAmount,
            sharesReceived_
        );

        return sharesReceived_;
    }

    /// @notice Requests to join the queue for redeeming wrapped shares
    /// @param _sharesAmount The amount of shares to add to the queue
    /// @dev Each request is additive
    function requestRedeem(uint256 _sharesAmount) external nonReentrant {
        require(
            !__isInLatestRedemptionWindow(block.timestamp),
            "requestRedeem: Inside redemption window"
        );

        // Validate user redemption approval and revoke remaining approval
        if (redemptionApprovalsAreUsed()) {
            uint256 redemptionApproval = getRedemptionApproval(msg.sender);

            if (redemptionApproval != type(uint256).max) {
                require(_sharesAmount <= redemptionApproval, "requestRedeem: Exceeds approval");
                delete userToRedemptionApproval[msg.sender];
            }
        }

        RedemptionQueue storage queue = redemptionQueue;
        RedemptionRequest storage request = queue.userToRequest[msg.sender];

        uint256 nextTotalSharesPending = uint256(queue.totalSharesPending).add(_sharesAmount);
        uint256 nextUserSharesPending = uint256(request.sharesPending).add(_sharesAmount);

        // Validate user has enough balance
        require(nextUserSharesPending <= balanceOf(msg.sender), "requestRedeem: Exceeds balance");

        // Update queue and user request
        queue.totalSharesPending = nextTotalSharesPending.toUint128();
        request.sharesPending = nextUserSharesPending.toUint128();
        // Add to users array if no previous request exists
        if (_sharesAmount == nextUserSharesPending) {
            request.index = uint64(queue.users.length);
            queue.users.push(msg.sender);
        }

        emit RedemptionRequestAdded(msg.sender, _sharesAmount);
    }

    //////////////////////////////////////////////////
    // SUBSCRIPTION ACTIONS - MANAGER - REDEMPTIONS //
    //////////////////////////////////////////////////

    /// @notice Kicks a user from the wrapper, redeeming their wrapped shares
    /// @param _user The user
    /// @param sharesRedeemed_ The amount of shares redeemed
    /// @dev Must cleanup any approvals separately
    function kick(address _user)
        external
        onlyManagerOrOwner
        nonReentrant
        returns (uint256 sharesRedeemed_)
    {
        // Checkpoint redemption queue relativeSharesAllowed before updating the queue or shares supply
        if (__isInLatestRedemptionWindow(block.timestamp)) {
            __checkpointRelativeSharesAllowed();
        }

        // Remove user from queue
        RedemptionQueue storage queue = redemptionQueue;
        uint256 userSharesPending = queue.userToRequest[_user].sharesPending;
        if (userSharesPending > 0) {
            queue.totalSharesPending = uint256(queue.totalSharesPending)
                .sub(userSharesPending)
                .toUint128();
            __removeRedemptionRequest({_user: _user, _queueLength: queue.users.length});
        }

        // Burn and redeem the shares
        sharesRedeemed_ = balanceOf(_user);
        _burn({account: _user, amount: sharesRedeemed_});

        __redeemCall({
            _recipient: _user,
            _sharesAmount: sharesRedeemed_,
            _redemptionAsset: getRedemptionAsset()
        });

        emit Kicked(_user, sharesRedeemed_);

        return sharesRedeemed_;
    }

    /// @notice Redeems a slice of requests from the queue
    /// @param _startIndex The first index of the slice
    /// @param _endIndex The final index of the slice
    /// @return usersRedeemed_ The users redeemed
    /// @return sharesRedeemed_ The amount of shares redeemed for each user
    /// @dev If redemptions are not throttled by relativeSharesAllowed, always slice from the end
    /// of the queue (more efficient to remove all users from the queue)
    function redeemFromQueue(uint256 _startIndex, uint256 _endIndex)
        external
        nonReentrant
        onlyManagerOrOwner
        returns (address[] memory usersRedeemed_, uint256[] memory sharesRedeemed_)
    {
        (uint256 windowStart, uint256 windowEnd) = calcLatestRedemptionWindow();
        require(
            __isWithinRange({
                _value: block.timestamp,
                _rangeStart: windowStart,
                _rangeEnd: windowEnd
            }),
            "redeemFromQueue: Outside redemption window"
        );

        RedemptionQueue storage queue = redemptionQueue;

        // Sanitize queue slice
        uint256 queueLength = queue.users.length;
        if (_endIndex == type(uint256).max) {
            _endIndex = queueLength - 1;
        }
        require(_endIndex < queueLength, "redeemFromQueue: Out-of-range _endIndex");
        require(_startIndex <= _endIndex, "redeemFromQueue: Misordered indexes");

        __checkpointRelativeSharesAllowed();

        // Calculate throttling
        bool throttled = queue.relativeSharesAllowed < ONE_HUNDRED_PERCENT;

        // Calculate redemption amounts and update each redemption request
        uint256 totalSharesRedeemed;
        uint256 usersToRedeemCount = _endIndex - _startIndex + 1;
        usersRedeemed_ = new address[](usersToRedeemCount);
        sharesRedeemed_ = new uint256[](usersToRedeemCount);
        // Step backwards from end of queue, so that removal of queue.users items is efficient
        // and does not disrupt next user indexes while in the loop
        for (uint256 i = _endIndex; usersToRedeemCount > 0; i--) {
            address user = queue.users[i];
            RedemptionRequest storage request = queue.userToRequest[user];

            require(
                !__isWithinRange({
                    _value: request.lastRedeemed,
                    _rangeStart: windowStart,
                    _rangeEnd: windowEnd
                }),
                "redeemFromQueue: Already redeemed in window"
            );

            // Based on whether redemptions are throttled:
            // (1) calculate the redeemable amount of shares
            // (2) update or remove request from queue
            uint256 userRedemptionAmount;
            if (throttled) {
                uint256 userSharesPending = request.sharesPending;

                userRedemptionAmount =
                    userSharesPending.mul(queue.relativeSharesAllowed) /
                    ONE_HUNDRED_PERCENT;

                request.sharesPending = userSharesPending.sub(userRedemptionAmount).toUint128();
                request.lastRedeemed = uint64(block.timestamp);
            } else {
                userRedemptionAmount = request.sharesPending;

                __removeRedemptionRequest({_user: user, _queueLength: queueLength});
                queueLength--;
            }

            // Burn shares
            _burn({account: user, amount: userRedemptionAmount});

            // Decrement users-to-redeem count and use it as the index for the redemption return arrays
            usersToRedeemCount--;
            usersRedeemed_[usersToRedeemCount] = user;
            sharesRedeemed_[usersToRedeemCount] = userRedemptionAmount;
            totalSharesRedeemed = totalSharesRedeemed.add(userRedemptionAmount);

            emit Redeemed(user, userRedemptionAmount);
        }

        // Update queue
        queue.totalSharesPending = uint256(queue.totalSharesPending)
            .sub(totalSharesRedeemed)
            .toUint128();

        // Redeem shares to this contract
        ERC20 redemptionAssetContract = ERC20(getRedemptionAsset());
        __redeemCall({
            _recipient: address(this),
            _sharesAmount: totalSharesRedeemed,
            _redemptionAsset: address(redemptionAssetContract)
        });

        // Disperse received asset
        uint256 balanceToDisperse = redemptionAssetContract.balanceOf(address(this));
        for (uint256 i; i < usersRedeemed_.length; i++) {
            redemptionAssetContract.safeTransfer(
                usersRedeemed_[i],
                balanceToDisperse.mul(sharesRedeemed_[i]).div(totalSharesRedeemed)
            );
        }
    }

    /// @dev Helper to checkpoint the relative shares allowed per user.
    /// Calling function should check whether the block.timestamp is currently
    /// within a redemption window (for gas efficiency).
    function __checkpointRelativeSharesAllowed() private {
        RedemptionQueue storage queue = redemptionQueue;

        // Skip if nothing in queue, or if already checkpointed in last window
        if (
            queue.totalSharesPending == 0 ||
            __isInLatestRedemptionWindow(queue.relativeSharesCheckpointed)
        ) {
            return;
        }

        // Calculate fresh if first redemption in window.
        // Use wrapped shares supply only instead of vault supply to prevent fee-related supply movements
        // between final request and first redemption.
        uint256 absoluteCap = totalSupply().mul(getRedemptionWindowConfig().relativeSharesCap) /
            ONE_HUNDRED_PERCENT;

        uint256 nextRelativeSharesAllowed;
        if (queue.totalSharesPending > absoluteCap) {
            nextRelativeSharesAllowed = ONE_HUNDRED_PERCENT.mul(absoluteCap).div(
                queue.totalSharesPending
            );
        } else {
            nextRelativeSharesAllowed = ONE_HUNDRED_PERCENT;
        }

        queue.relativeSharesAllowed = uint64(nextRelativeSharesAllowed);
        queue.relativeSharesCheckpointed = uint64(block.timestamp);
    }

    /// @dev Helper to redeem vault shares for the redemption asset
    function __redeemCall(
        address _recipient,
        uint256 _sharesAmount,
        address _redemptionAsset
    ) private {
        require(_redemptionAsset != address(0), "__redeemCall: No redemption asset");

        (address target, bytes memory payload) = GLOBAL_CONFIG_CONTRACT
            .formatSingleAssetRedemptionCall({
                _vaultProxy: getVaultProxy(),
                _recipient: _recipient,
                _asset: _redemptionAsset,
                _amount: _sharesAmount,
                _amountIsShares: true
            });

        target.functionCall(payload);
    }

    /// @dev Helper to remove a redemption request from the queue
    function __removeRedemptionRequest(address _user, uint256 _queueLength) private {
        RedemptionQueue storage queue = redemptionQueue;

        uint256 userIndex = queue.userToRequest[_user].index;

        if (userIndex < _queueLength - 1) {
            address userToMove = queue.users[_queueLength - 1];

            queue.users[userIndex] = userToMove;
            queue.userToRequest[userToMove].index = uint64(userIndex);
        }

        delete queue.userToRequest[_user];
        queue.users.pop();

        emit RedemptionRequestRemoved(_user);
    }

    /////////////////////////////
    // REDEMPTION WINDOW CALCS //
    /////////////////////////////

    /// @notice Helper to calculate the most recent redemption window
    /// @return windowStart_ The start of the latest window
    /// @return windowEnd_ The end of the latest window
    /// @dev Prior to first redemption window, returns no window (i.e., start and end are 0).
    /// After that, returns the last (or current) window, until a new window is reached.
    function calcLatestRedemptionWindow()
        public
        view
        returns (uint256 windowStart_, uint256 windowEnd_)
    {
        RedemptionWindowConfig memory windowConfig = getRedemptionWindowConfig();

        // Return early if no window has been reached
        if (
            block.timestamp < windowConfig.firstWindowStart || windowConfig.firstWindowStart == 0
        ) {
            return (0, 0);
        }

        uint256 cyclesCompleted = (block.timestamp.sub(windowConfig.firstWindowStart)).div(
            windowConfig.frequency
        );

        windowStart_ = uint256(windowConfig.firstWindowStart).add(
            cyclesCompleted.mul(windowConfig.frequency)
        );
        windowEnd_ = windowStart_.add(windowConfig.duration);

        return (windowStart_, windowEnd_);
    }

    /// @dev Helper to check whether a timestamp is in the current redemption window
    function __isInLatestRedemptionWindow(uint256 _timestamp)
        private
        view
        returns (bool inWindow_)
    {
        (uint256 windowStart, uint256 windowEnd) = calcLatestRedemptionWindow();

        if (windowStart == 0) {
            return false;
        }

        return
            __isWithinRange({_value: _timestamp, _rangeStart: windowStart, _rangeEnd: windowEnd});
    }

    /// @dev Helper to check whether a value is between two ends of a range.
    /// Used for efficiency when the redemption window start and end are already in memory.
    function __isWithinRange(
        uint256 _value,
        uint256 _rangeStart,
        uint256 _rangeEnd
    ) private pure returns (bool withinRange_) {
        return _value >= _rangeStart && _value <= _rangeEnd;
    }

    ///////////////////////////////
    // MANAGER CALLS - APPROVALS //
    ///////////////////////////////

    // Managers should consider resetting approvals to 0 before updating to the new amount.
    // Approvals can only be used once and are all-or-nothing (i.e., the full amount must be used),
    // with the following exceptions:
    // - any approval with type(uint256).max allows any amount any number of times
    // - redemption approvals can be used partially, but any remaining amount is revoked

    /// @notice Sets deposit approvals for a list of users
    /// @param _users The users
    /// @param _assets The deposit token for each approval
    /// @param _amounts The amount of each approval
    function setDepositApprovals(
        address[] calldata _users,
        address[] calldata _assets,
        uint256[] calldata _amounts
    ) external onlyManagerOrOwner {
        require(
            _users.length == _assets.length && _users.length == _amounts.length,
            "setDepositApprovals: Unequal arrays"
        );

        for (uint256 i; i < _users.length; i++) {
            userToAssetToDepositApproval[_users[i]][_assets[i]] = _amounts[i];

            emit DepositApproval(_users[i], _assets[i], _amounts[i]);
        }
    }

    /// @notice Sets redemption approvals for a list of users
    /// @param _users The users
    /// @param _amounts The amount of each approval
    function setRedemptionApprovals(address[] calldata _users, uint256[] calldata _amounts)
        external
        onlyManagerOrOwner
    {
        require(_users.length == _amounts.length, "setRedemptionApprovals: Unequal arrays");

        for (uint256 i; i < _users.length; i++) {
            userToRedemptionApproval[_users[i]] = _amounts[i];

            emit RedemptionApproval(_users[i], _amounts[i]);
        }
    }

    /// @notice Sets transfer approvals for a list of users
    /// @param _users The users (senders)
    /// @param _recipients The recipient for each approval
    /// @param _amounts The amount of each approval
    function setTransferApprovals(
        address[] calldata _users,
        address[] calldata _recipients,
        uint256[] calldata _amounts
    ) external onlyManagerOrOwner {
        require(
            _users.length == _recipients.length && _users.length == _amounts.length,
            "setTransferApprovals: Unequal arrays"
        );

        for (uint256 i; i < _users.length; i++) {
            userToRecipientToTransferApproval[_users[i]][_recipients[i]] = _amounts[i];

            emit TransferApproval(_users[i], _recipients[i], _amounts[i]);
        }
    }

    /// @notice Sets whether deposit approvals are required
    /// @param _nextUseDepositApprovals True if required
    function setUseDepositApprovals(bool _nextUseDepositApprovals) external onlyManagerOrOwner {
        __setUseDepositApprovals(_nextUseDepositApprovals);
    }

    /// @notice Sets whether redemption approvals are required
    /// @param _nextUseRedemptionApprovals True if required
    function setUseRedemptionApprovals(bool _nextUseRedemptionApprovals)
        external
        onlyManagerOrOwner
    {
        __setUseRedemptionApprovals(_nextUseRedemptionApprovals);
    }

    /// @notice Sets whether transfer approvals are required
    /// @param _nextUseTransferApprovals True if required
    function setUseTransferApprovals(bool _nextUseTransferApprovals) external onlyManagerOrOwner {
        __setUseTransferApprovals(_nextUseTransferApprovals);
    }

    // PRIVATE FUNCTIONS

    /// @dev Helper to set useDepositApprovals
    function __setUseDepositApprovals(bool _nextUseDepositApprovals) private {
        useDepositApprovals = _nextUseDepositApprovals;

        emit UseDepositApprovalsSet(_nextUseDepositApprovals);
    }

    /// @dev Helper to set useRedemptionApprovals
    function __setUseRedemptionApprovals(bool _nextUseRedemptionApprovals) private {
        useRedemptionApprovals = _nextUseRedemptionApprovals;

        emit UseRedemptionApprovalsSet(_nextUseRedemptionApprovals);
    }

    /// @dev Helper to set useTransferApprovals
    function __setUseTransferApprovals(bool _nextUseTransferApprovals) private {
        useTransferApprovals = _nextUseTransferApprovals;

        emit UseTransferApprovalsSet(_nextUseTransferApprovals);
    }

    //////////////////////////
    // MANAGER CALLS - MISC //
    //////////////////////////

    /// @notice Sets the configuration for the redemption window
    /// @param _nextWindowConfig The RedemptionWindowConfig
    function setRedemptionWindowConfig(RedemptionWindowConfig calldata _nextWindowConfig)
        external
        onlyManagerOrOwner
    {
        __setRedemptionWindowConfig(_nextWindowConfig);
    }

    /// @notice Sets the asset received during redemptions
    /// @param _nextRedemptionAsset The asset
    function setRedemptionAsset(address _nextRedemptionAsset) external onlyManagerOrOwner {
        __setRedemptionAsset(_nextRedemptionAsset);
    }

    // PRIVATE FUNCTIONS

    /// @dev Helper to set redemptionAsset
    function __setRedemptionAsset(address _nextRedemptionAsset) private {
        redemptionAsset = _nextRedemptionAsset;

        emit RedemptionAssetSet(_nextRedemptionAsset);
    }

    /// @dev Helper to set redemptionWindowConfig
    function __setRedemptionWindowConfig(RedemptionWindowConfig memory _nextWindowConfig) private {
        // Config can either be all empty, or all valid
        if (
            !(_nextWindowConfig.firstWindowStart == 0 &&
                _nextWindowConfig.duration == 0 &&
                _nextWindowConfig.frequency == 0 &&
                _nextWindowConfig.relativeSharesCap == 0)
        ) {
            require(
                _nextWindowConfig.firstWindowStart > block.timestamp,
                "__setRedemptionWindowConfig: Invalid firstWindowStart"
            );
            require(_nextWindowConfig.duration > 0, "__setRedemptionWindowConfig: No duration");
            require(
                _nextWindowConfig.frequency > _nextWindowConfig.duration,
                "__setRedemptionWindowConfig: duration exceeds frequency"
            );
            require(
                _nextWindowConfig.relativeSharesCap <= ONE_HUNDRED_PERCENT,
                "__setRedemptionWindowConfig: relativeSharesCap exceeds 100%"
            );
        }

        redemptionWindowConfig = _nextWindowConfig;

        // Changing the window config completely resets the relativeSharesCap
        RedemptionQueue storage queue = redemptionQueue;
        delete queue.relativeSharesAllowed;
        delete queue.relativeSharesCheckpointed;

        emit RedemptionWindowConfigSet(
            _nextWindowConfig.firstWindowStart,
            _nextWindowConfig.frequency,
            _nextWindowConfig.duration,
            _nextWindowConfig.relativeSharesCap
        );
    }

    /////////////////
    // OWNER CALLS //
    /////////////////

    /// @notice Adds managers
    /// @param _managers Managers to add
    function addManagers(address[] calldata _managers) external onlyOwner {
        __addManagers(_managers);
    }

    /// @notice Removes managers
    /// @param _managers Managers to remove
    function removeManagers(address[] calldata _managers) external onlyOwner {
        for (uint256 i; i < _managers.length; i++) {
            address manager = _managers[i];

            require(isManager(manager), "removeManagers: Not a manager");

            userToIsManager[manager] = false;

            emit ManagerRemoved(manager);
        }
    }

    /// @dev Helper to add wrapper managers
    function __addManagers(address[] calldata _managers) internal {
        for (uint256 i; i < _managers.length; i++) {
            address manager = _managers[i];

            require(!isManager(manager), "__addManagers: Already manager");

            userToIsManager[manager] = true;

            emit ManagerAdded(manager);
        }
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    // EXTERNAL FUNCTIONS

    /// @notice Gets the redemption queue state
    /// @return totalSharesPending_ The total shares pending in the queue
    /// @return relativeSharesAllowed_ The relative shares allowed per-user during the window, as of the last checkpoint
    /// @return relativeSharesCheckpointed_ The last checkpoint of relativeSharesAllowed_
    /// @dev Can't return a struct with a mapping in solc 0.6.12
    function getRedemptionQueue()
        external
        view
        returns (
            uint256 totalSharesPending_,
            uint256 relativeSharesAllowed_,
            uint256 relativeSharesCheckpointed_
        )
    {
        return (
            redemptionQueue.totalSharesPending,
            redemptionQueue.relativeSharesAllowed,
            redemptionQueue.relativeSharesCheckpointed
        );
    }

    /// @notice Gets the user at the specified index in the redemption queue list of users
    /// @param _index The index
    /// @return user_ The user
    function getRedemptionQueueUserByIndex(uint256 _index) external view returns (address user_) {
        return redemptionQueue.users[_index];
    }

    /// @notice Gets the redemption request for a specified user
    /// @param _user The user
    /// @return request_ The RedemptionRequest
    function getRedemptionQueueUserRequest(address _user)
        external
        view
        returns (RedemptionRequest memory request_)
    {
        return redemptionQueue.userToRequest[_user];
    }

    /// @notice Gets the list of all users in the redemption queue
    /// @return users_ The list of users
    function getRedemptionQueueUsers() external view returns (address[] memory users_) {
        return redemptionQueue.users;
    }

    /// @notice Gets the count of users in the redemption queue
    /// @return length_ The count of users
    function getRedemptionQueueUsersLength() external view returns (uint256 length_) {
        return redemptionQueue.users.length;
    }

    // PUBLIC FUNCTIONS

    /// @notice Checks whether deposit approvals are required
    /// @return approvalsUsed_ True if required
    function depositApprovalsAreUsed() public view returns (bool approvalsUsed_) {
        return useDepositApprovals;
    }

    /// @notice Gets the deposit approval for a given user and asset
    /// @param _user The user
    /// @param _asset The asset
    /// @return amount_ The approval amount
    function getDepositApproval(address _user, address _asset)
        public
        view
        returns (uint256 amount_)
    {
        return userToAssetToDepositApproval[_user][_asset];
    }

    /// @notice Gets the redemption approval for a given user
    /// @param _user The user
    /// @return amount_ The approval amount
    function getRedemptionApproval(address _user) public view returns (uint256 amount_) {
        return userToRedemptionApproval[_user];
    }

    /// @notice Gets the asset received during redemptions
    /// @return asset_ The asset
    function getRedemptionAsset() public view returns (address asset_) {
        return redemptionAsset;
    }

    /// @notice Gets the redemption window configuration
    /// @return redemptionWindowConfig_ The RedemptionWindowConfig
    function getRedemptionWindowConfig()
        public
        view
        returns (RedemptionWindowConfig memory redemptionWindowConfig_)
    {
        return redemptionWindowConfig;
    }

    /// @notice Gets the deposit approval for a given sender and recipient
    /// @param _sender The sender
    /// @param _recipient The recipient
    /// @return amount_ The approval amount
    function getTransferApproval(address _sender, address _recipient)
        public
        view
        returns (uint256 amount_)
    {
        return userToRecipientToTransferApproval[_sender][_recipient];
    }

    /// @notice Gets the vaultProxy var
    /// @return vaultProxy_ The vaultProxy value
    function getVaultProxy() public view returns (address vaultProxy_) {
        return vaultProxy;
    }

    /// @notice Checks whether a user is a wrapper manager
    /// @param _user The user to check
    /// @return isManager_ True if _user is a wrapper manager
    function isManager(address _user) public view returns (bool isManager_) {
        return userToIsManager[_user];
    }

    /// @notice Checks whether redemption approvals are required
    /// @return approvalsUsed_ True if required
    function redemptionApprovalsAreUsed() public view returns (bool approvalsUsed_) {
        return useRedemptionApprovals;
    }

    /// @notice Checks whether approvals are required for transferring wrapped shares
    /// @return approvalsUsed_ True if required
    function transferApprovalsAreUsed() public view returns (bool approvalsUsed_) {
        return useTransferApprovals;
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

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title GatedRedemptionQueueSharesWrapperLibBase1 Contract
/// @author Enzyme Council <[email protected]>
/// @notice A base implementation for GatedRedemptionQueueSharesWrapperLib
/// @dev Each next base implementation inherits the previous base implementation,
/// e.g., `GatedRedemptionQueueSharesWrapperLibBase2 is GatedRedemptionQueueSharesWrapperLibBase1`
/// DO NOT EDIT CONTRACT.
abstract contract GatedRedemptionQueueSharesWrapperLibBase1 is ERC20, ReentrancyGuard {
    event DepositApproval(address indexed user, address indexed asset, uint256 amount);

    event Deposited(
        address indexed user,
        address indexed depositToken,
        uint256 depositTokenAmount,
        uint256 sharesReceived
    );

    event Initialized(address indexed vaultProxy);

    event Kicked(address indexed user, uint256 sharesAmount);

    event ManagerAdded(address indexed user);

    event ManagerRemoved(address indexed user);

    event Redeemed(address indexed user, uint256 sharesAmount);

    event RedemptionApproval(address indexed user, uint256 amount);

    event RedemptionAssetSet(address indexed asset);

    event RedemptionRequestAdded(address indexed user, uint256 sharesAmount);

    event RedemptionRequestRemoved(address indexed user);

    event RedemptionWindowConfigSet(
        uint256 firstWindowStart,
        uint256 frequency,
        uint256 duration,
        uint256 relativeSharesCap
    );

    event TransferApproval(address indexed sender, address indexed recipient, uint256 amount);

    event UseDepositApprovalsSet(bool useApprovals);

    event UseRedemptionApprovalsSet(bool useApprovals);

    event UseTransferApprovalsSet(bool useApprovals);

    struct RedemptionQueue {
        uint128 totalSharesPending;
        uint64 relativeSharesAllowed;
        uint64 relativeSharesCheckpointed;
        mapping(address => RedemptionRequest) userToRequest;
        address[] users;
    }

    struct RedemptionRequest {
        uint64 index;
        uint64 lastRedeemed;
        uint128 sharesPending;
    }

    struct RedemptionWindowConfig {
        uint64 firstWindowStart; // e.g., Jan 1, 2022; as timestamp
        uint32 frequency; // e.g., every 2 weeks; in seconds
        uint32 duration; // e.g., 1 week long; in seconds
        uint64 relativeSharesCap; // 100% is 1e18; e.g., 50% is 0.5e18
    }

    // Packing vaultProxy with useDepositApprovals makes deposits slightly cheaper
    address internal vaultProxy;
    bool internal useDepositApprovals;
    bool internal useRedemptionApprovals;
    bool internal useTransferApprovals;
    address internal redemptionAsset;

    RedemptionQueue internal redemptionQueue;
    RedemptionWindowConfig internal redemptionWindowConfig;

    mapping(address => bool) internal userToIsManager;

    // Per-user approvals for wrapped shares balance changes
    mapping(address => mapping(address => uint256)) internal userToAssetToDepositApproval;
    mapping(address => mapping(address => uint256)) internal userToRecipientToTransferApproval;
    mapping(address => uint256) internal userToRedemptionApproval;

    // Define init() shape so it is guaranteed for factory
    function init(
        address _vaultProxy,
        address[] calldata _managers,
        address _redemptionAsset,
        bool _useDepositApprovals,
        bool _useRedemptionApprovals,
        bool _useTransferApprovals,
        GatedRedemptionQueueSharesWrapperLibBase1.RedemptionWindowConfig calldata _windowConfig
    ) external virtual;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IVaultCore interface
/// @author Enzyme Council <[email protected]>
/// @notice Interface for getters of core vault storage
/// @dev DO NOT EDIT CONTRACT
interface IVaultCore {
    function getAccessor() external view returns (address accessor_);

    function getCreator() external view returns (address creator_);

    function getMigrator() external view returns (address migrator_);

    function getOwner() external view returns (address owner_);
}