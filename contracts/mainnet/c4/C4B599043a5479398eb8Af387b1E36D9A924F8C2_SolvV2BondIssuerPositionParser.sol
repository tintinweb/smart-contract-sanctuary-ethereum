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

pragma solidity 0.6.12;

/// @title SolvV2BondIssuerPositionLibBase1 Contract
/// @author Enzyme Council <[email protected]>
/// @notice A persistent contract containing all required storage variables and
/// required functions for a SolvV2BondIssuerPositionLib implementation
/// @dev DO NOT EDIT CONTRACT. If new events or storage are necessary, they should be added to
/// a numbered SolvV2BondIssuerPositionLibBaseXXX that inherits the previous base.
/// e.g., `SolvV2BondIssuerPositionLibBase2 is SolvV2BondIssuerPositionLibBase1`
contract SolvV2BondIssuerPositionLibBase1 {
    event IssuedVoucherAdded(address indexed voucher);

    event IssuedVoucherRemoved(address indexed voucher);

    event OfferAdded(uint24 indexed offerId);

    event OfferRemoved(uint24 indexed offerId);

    // Issued vouchers
    address[] internal issuedVouchers;

    // Created offers
    uint24[] internal offers;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IExternalPositionParser Interface
/// @author Enzyme Council <[email protected]>
/// @notice Interface for all external position parsers
interface IExternalPositionParser {
    function parseAssetsForAction(
        address _externalPosition,
        uint256 _actionId,
        bytes memory _encodedActionArgs
    )
        external
        returns (
            address[] memory assetsToTransfer_,
            uint256[] memory amountsToTransfer_,
            address[] memory assetsToReceive_
        );

    function parseInitArgs(address _vaultProxy, bytes memory _initializationData)
        external
        returns (bytes memory initArgs_);
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
pragma experimental ABIEncoderV2;

/// @title ISolvV2BondIssuerPosition Interface
/// @author Enzyme Council <[email protected]>
interface ISolvV2BondIssuerPosition is IExternalPosition {
    enum Actions {
        CreateOffer,
        Reconcile,
        Refund,
        RemoveOffer,
        Withdraw
    }

    function getOffers() external view returns (uint24[] memory offers_);
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

import "../../../../interfaces/ISolvV2InitialConvertibleOfferingMarket.sol";

/// @title SolvV2BondIssuerPositionDataDecoder Contract
/// @author Enzyme Council <[email protected]>
/// @notice Abstract contract containing data decodings for SolvV2BondIssuerPosition payloads
abstract contract SolvV2BondIssuerPositionDataDecoder {
    /// @dev Helper to decode args used during the CreateOffer action
    function __decodeCreateOfferActionArgs(bytes memory _actionArgs)
        internal
        pure
        returns (
            address voucher_,
            address currency_,
            uint128 min_,
            uint128 max_,
            uint32 startTime_,
            uint32 endTime_,
            bool useAllowList_,
            ISolvV2InitialConvertibleOfferingMarket.PriceType priceType_,
            bytes memory priceData,
            ISolvV2InitialConvertibleOfferingMarket.MintParameter memory mintParameter_
        )
    {
        return (
            abi.decode(
                _actionArgs,
                (
                    address,
                    address,
                    uint128,
                    uint128,
                    uint32,
                    uint32,
                    bool,
                    ISolvV2InitialConvertibleOfferingMarket.PriceType,
                    bytes,
                    ISolvV2InitialConvertibleOfferingMarket.MintParameter
                )
            )
        );
    }

    /// @dev Helper to decode args used during the Refund action
    function __decodeRefundActionArgs(bytes memory _actionArgs)
        internal
        pure
        returns (address voucher_, uint256 slotId_)
    {
        return (abi.decode(_actionArgs, (address, uint256)));
    }

    /// @dev Helper to decode args used during the RemoveOffer action
    function __decodeRemoveOfferActionArgs(bytes memory _actionArgs)
        internal
        pure
        returns (uint24 offerId_)
    {
        return (abi.decode(_actionArgs, (uint24)));
    }

    /// @dev Helper to decode args used during the Withdraw action
    function __decodeWithdrawActionArgs(bytes memory _actionArgs)
        internal
        pure
        returns (address voucher_, uint256 slotId_)
    {
        return (abi.decode(_actionArgs, (address, uint256)));
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
import "../../../../../persistent/external-positions/solv-v2-bond-issuer/SolvV2BondIssuerPositionLibBase1.sol";
import "../../../../interfaces/ISolvV2BondPool.sol";
import "../../../../interfaces/ISolvV2BondVoucher.sol";
import "../../../../interfaces/ISolvV2InitialConvertibleOfferingMarket.sol";
import "../../../../utils/AddressArrayLib.sol";
import "../../../../utils/AssetHelpers.sol";
import "../../../../utils/Uint256ArrayLib.sol";
import "./ISolvV2BondIssuerPosition.sol";
import "./SolvV2BondIssuerPositionDataDecoder.sol";

/// @title SolvV2BondIssuerPositionLib Contract
/// @author Enzyme Council <[email protected]>
/// @notice Library contract for Solv V2 Bond Issuer Positions
contract SolvV2BondIssuerPositionLib is
    ISolvV2BondIssuerPosition,
    SolvV2BondIssuerPositionLibBase1,
    SolvV2BondIssuerPositionDataDecoder,
    AssetHelpers
{
    using AddressArrayLib for address[];
    using SafeERC20 for ERC20;
    using SafeMath for uint256;
    using Uint256ArrayLib for uint256[];

    ISolvV2InitialConvertibleOfferingMarket
        private immutable INITIAL_BOND_OFFERING_MARKET_CONTRACT;

    constructor(address _initialBondOfferingMarket) public {
        INITIAL_BOND_OFFERING_MARKET_CONTRACT = ISolvV2InitialConvertibleOfferingMarket(
            _initialBondOfferingMarket
        );
    }

    /// @notice Initializes the external position
    /// @dev Nothing to initialize for this contract
    function init(bytes memory) external override {}

    /// @notice Receives and executes a call from the Vault
    /// @param _actionData Encoded data to execute the action
    function receiveCallFromVault(bytes memory _actionData) external override {
        (uint256 actionId, bytes memory actionArgs) = abi.decode(_actionData, (uint256, bytes));

        if (actionId == uint256(Actions.CreateOffer)) {
            __actionCreateOffer(actionArgs);
        } else if (actionId == uint256(Actions.Reconcile)) {
            __actionReconcile();
        } else if (actionId == uint256(Actions.Refund)) {
            __actionRefund(actionArgs);
        } else if (actionId == uint256(Actions.RemoveOffer)) {
            __actionRemoveOffer(actionArgs);
        } else if (actionId == uint256(Actions.Withdraw)) {
            __actionWithdraw(actionArgs);
        } else {
            revert("receiveCallFromVault: Invalid actionId");
        }
    }

    /// @dev Helper to create an Initial Voucher Offering
    function __actionCreateOffer(bytes memory _actionArgs) private {
        (
            address voucher,
            address currency,
            uint128 min,
            uint128 max,
            uint32 startTime,
            uint32 endTime,
            bool useAllowList,
            ISolvV2InitialConvertibleOfferingMarket.PriceType priceType,
            bytes memory priceData,
            ISolvV2InitialConvertibleOfferingMarket.MintParameter memory mintParameter
        ) = __decodeCreateOfferActionArgs(_actionArgs);

        ERC20(ISolvV2BondVoucher(voucher).underlying()).safeApprove(
            address(INITIAL_BOND_OFFERING_MARKET_CONTRACT),
            mintParameter.tokenInAmount
        );

        uint24 offerId = INITIAL_BOND_OFFERING_MARKET_CONTRACT.offer(
            voucher,
            currency,
            min,
            max,
            startTime,
            endTime,
            useAllowList,
            priceType,
            priceData,
            mintParameter
        );

        if (!issuedVouchers.storageArrayContains(voucher)) {
            issuedVouchers.push(voucher);
            emit IssuedVoucherAdded(voucher);
        }

        offers.push(offerId);
        emit OfferAdded(offerId);
    }

    /// @dev Helper to reconcile receivable currencies
    function __actionReconcile() private {
        uint24[] memory offersMem = getOffers();

        // Build an array of unique receivableCurrencies from created offers
        address[] memory receivableCurrencies;
        uint256 offersLength = offersMem.length;
        for (uint256 i; i < offersLength; i++) {
            receivableCurrencies = receivableCurrencies.addUniqueItem(
                INITIAL_BOND_OFFERING_MARKET_CONTRACT.offerings(offersMem[i]).currency
            );
        }

        __pushFullAssetBalances(msg.sender, receivableCurrencies);
    }

    /// @dev Helper to refund a voucher slot
    function __actionRefund(bytes memory _actionArgs) private {
        (address voucher, uint256 slotId) = __decodeRefundActionArgs(_actionArgs);
        ISolvV2BondPool voucherPoolContract = ISolvV2BondPool(
            ISolvV2BondVoucher(voucher).bondPool()
        );

        ISolvV2BondPool.SlotDetail memory slotDetail = voucherPoolContract.getSlotDetail(slotId);

        ERC20 currencyToken = ERC20(slotDetail.fundCurrency);

        currencyToken.safeApprove(address(voucherPoolContract), type(uint256).max);
        voucherPoolContract.refund(slotId);
        currencyToken.safeApprove(address(voucherPoolContract), 0);
    }

    /// @dev Helper to remove an IVO
    function __actionRemoveOffer(bytes memory _actionArgs) private {
        uint24 offerId = __decodeRemoveOfferActionArgs(_actionArgs);

        // Retrieve offer details before removal

        ISolvV2InitialConvertibleOfferingMarket.Offering
            memory offer = INITIAL_BOND_OFFERING_MARKET_CONTRACT.offerings(offerId);

        ERC20 currencyToken = ERC20(offer.currency);
        ERC20 underlyingToken = ERC20(ISolvV2BondVoucher(offer.voucher).underlying());

        INITIAL_BOND_OFFERING_MARKET_CONTRACT.remove(offerId);

        uint256 offersLength = offers.length;

        // Remove the offerId from the offers array
        for (uint256 i; i < offersLength; i++) {
            if (offers[i] == offerId) {
                // Reconcile offer currency before it is removed from storage
                uint256 currencyBalance = currencyToken.balanceOf(address(this));
                if (currencyBalance > 0) {
                    currencyToken.safeTransfer(msg.sender, currencyBalance);
                }

                // Reconcile underlying before voucher is removed from storage
                uint256 underlyingBalance = underlyingToken.balanceOf(address(this));
                if (underlyingBalance > 0) {
                    underlyingToken.safeTransfer(msg.sender, underlyingBalance);
                }

                // Remove offer from storage
                if (i < offersLength - 1) {
                    offers[i] = offers[offersLength - 1];
                }
                offers.pop();

                emit OfferRemoved(offerId);

                break;
            }
        }
    }

    /// @dev Helper to withdraw outstanding underlying from a post-maturity issued voucher
    function __actionWithdraw(bytes memory _actionArgs) private {
        (address voucher, uint256 slotId) = __decodeWithdrawActionArgs(_actionArgs);

        ISolvV2BondVoucher voucherContract = ISolvV2BondVoucher(voucher);
        ISolvV2BondPool(voucherContract.bondPool()).withdraw(slotId);

        ERC20 underlyingToken = ERC20(voucherContract.underlying());
        uint256 underlyingBalance = underlyingToken.balanceOf(address(this));

        if (underlyingBalance > 0) {
            underlyingToken.safeTransfer(msg.sender, underlyingBalance);
        }
    }

    ////////////////////
    // POSITION VALUE //
    ////////////////////

    /// @notice Retrieves the debt assets (negative value) of the external position
    /// @return assets_ Debt assets
    /// @return amounts_ Debt asset amounts
    function getDebtAssets()
        external
        override
        returns (address[] memory assets_, uint256[] memory amounts_)
    {
        return (assets_, amounts_);
    }

    /// @notice Retrieves the managed assets (positive value) of the external position
    /// @return assets_ Managed assets
    /// @return amounts_ Managed asset amounts
    /// @dev There are 3 types of assets that contribute value to this position:
    /// 1. Underlying balance outstanding in IVO offers (collateral not yet used for minting)
    /// 2. Unreconciled assets received for an IVO sale
    /// 3. Outstanding assets that are withdrawable from issued vouchers (post-maturity)
    function getManagedAssets()
        external
        override
        returns (address[] memory assets_, uint256[] memory amounts_)
    {
        uint24[] memory offersMem = getOffers();

        // Balance of assets that are withdrawable from issued vouchers (post-maturity)
        (assets_, amounts_) = __getWithdrawableAssetAmountsAndRemoveWithdrawnVouchers();

        // Underlying balance outstanding in non-closed IVO offers
        (
            address[] memory underlyingAssets,
            uint256[] memory underlyingAmounts
        ) = __getOffersUnderlyingBalance(offersMem);
        uint256 underlyingAssetsLength = underlyingAssets.length;
        for (uint256 i; i < underlyingAssetsLength; i++) {
            assets_ = assets_.addItem(underlyingAssets[i]);
            amounts_ = amounts_.addItem(underlyingAmounts[i]);
        }

        // Balance of currencies that could have been received on IVOs sales
        (
            address[] memory currencies,
            uint256[] memory currencyBalances
        ) = __getReceivableCurrencyBalances(offersMem);

        uint256 currenciesLength = currencies.length;
        for (uint256 i; i < currenciesLength; i++) {
            assets_ = assets_.addItem(currencies[i]);
            amounts_ = amounts_.addItem(currencyBalances[i]);
        }

        return __aggregateAssetAmounts(assets_, amounts_);
    }

    /// @dev Gets the outstanding underlying balances from unsold IVO vouchers on offer
    function __getOffersUnderlyingBalance(uint24[] memory _offers)
        private
        view
        returns (address[] memory underlyings_, uint256[] memory amounts_)
    {
        uint256 offersLength = _offers.length;

        underlyings_ = new address[](offersLength);
        amounts_ = new uint256[](offersLength);

        for (uint256 i; i < offersLength; i++) {
            ISolvV2InitialConvertibleOfferingMarket.Offering
                memory offering = INITIAL_BOND_OFFERING_MARKET_CONTRACT.offerings(_offers[i]);

            ISolvV2InitialConvertibleOfferingMarket.MintParameter
                memory mintParameters = INITIAL_BOND_OFFERING_MARKET_CONTRACT.mintParameters(
                    _offers[i]
                );

            uint256 refundAmount = uint256(offering.units).div(mintParameters.lowestPrice);

            underlyings_[i] = ISolvV2BondVoucher(offering.voucher).underlying();
            amounts_[i] = refundAmount;
        }

        return (underlyings_, amounts_);
    }

    /// @dev Retrieves the receivable (proceeds from IVO sales) currencies balances of the external position
    function __getReceivableCurrencyBalances(uint24[] memory _offers)
        private
        view
        returns (address[] memory currencies_, uint256[] memory balances_)
    {
        uint256 offersLength = _offers.length;

        for (uint256 i; i < offersLength; i++) {
            address currency = INITIAL_BOND_OFFERING_MARKET_CONTRACT
                .offerings(_offers[i])
                .currency;
            // Go to next item if currency has already been checked
            if (currencies_.contains(currency)) {
                continue;
            }
            uint256 balance = ERC20(currency).balanceOf(address(this));
            if (balance > 0) {
                currencies_ = currencies_.addItem(currency);
                balances_ = balances_.addItem(balance);
            }
        }

        return (currencies_, balances_);
    }

    /// @dev Retrieves the withdrawable assets by the issuer (post voucher maturity)
    /// Reverts if one of the issued voucher slots has not reached maturity
    /// Removes stored issued vouchers that have been fully withdrawn
    function __getWithdrawableAssetAmountsAndRemoveWithdrawnVouchers()
        private
        returns (address[] memory assets_, uint256[] memory amounts_)
    {
        address[] memory vouchersMem = getIssuedVouchers();
        uint256 vouchersLength = vouchersMem.length;

        for (uint256 i; i < vouchersLength; i++) {
            uint256 preAssetsLength = assets_.length;

            ISolvV2BondPool voucherPoolContract = ISolvV2BondPool(
                ISolvV2BondVoucher(vouchersMem[i]).bondPool()
            );
            uint256[] memory slots = voucherPoolContract.getIssuerSlots(address(this));

            uint256 withdrawableUnderlying;

            for (uint256 j; j < slots.length; j++) {
                ISolvV2BondPool.SlotDetail memory slotDetail = ISolvV2BondVoucher(vouchersMem[i])
                    .getSlotDetail(slots[j]);

                // If the vault has issued at least one voucher that has not reached maturity, revert
                require(
                    block.timestamp >= slotDetail.maturity,
                    "__getWithdrawableAssetAmountsAndRemoveWithdrawnVouchers: pre-mature issued voucher slot"
                );
                uint256 withdrawTokenAmount = voucherPoolContract.getWithdrawableAmount(slots[j]);

                if (withdrawTokenAmount > 0) {
                    withdrawableUnderlying = withdrawableUnderlying.add(withdrawTokenAmount);
                }
            }

            if (withdrawableUnderlying > 0) {
                assets_ = assets_.addItem(ISolvV2BondVoucher(vouchersMem[i]).underlying());
                amounts_ = amounts_.addItem(withdrawableUnderlying);
            }

            // If assets length is the same as before iterating through the issued slots.
            // All issued slots are withdrawn and the voucher can be removed from storage.
            if (assets_.length == preAssetsLength) {
                // Remove the voucher from the vouchers array
                issuedVouchers.removeStorageItem(vouchersMem[i]);

                emit IssuedVoucherRemoved(vouchersMem[i]);
            }
        }
        return (assets_, amounts_);
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the issued vouchers
    /// @return vouchers_ The array of issued voucher addresses
    function getIssuedVouchers() public view returns (address[] memory vouchers_) {
        return issuedVouchers;
    }

    /// @notice Gets the created offers
    /// @return offers_ The array of created offer ids
    function getOffers() public view override returns (uint24[] memory offers_) {
        return offers;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <[email protected]>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../../../interfaces/ISolvV2BondPool.sol";
import "../../../../interfaces/ISolvV2InitialConvertibleOfferingMarket.sol";
import "../../../../utils/AddressArrayLib.sol";
import "../IExternalPositionParser.sol";
import "./ISolvV2BondIssuerPosition.sol";
import "./SolvV2BondIssuerPositionDataDecoder.sol";
import "./SolvV2BondIssuerPositionLib.sol";

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/// @title SolvV2BondIssuerPositionParser
/// @author Enzyme Council <[email protected]>
/// @notice Parser for Solv V2 Bond Issuer positions
contract SolvV2BondIssuerPositionParser is
    IExternalPositionParser,
    SolvV2BondIssuerPositionDataDecoder
{
    using AddressArrayLib for address[];
    using SafeMath for uint256;

    address private constant NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    ISolvV2InitialConvertibleOfferingMarket
        private immutable INITIAL_BOND_OFFERING_MARKET_CONTRACT;

    constructor(address _initialBondOfferingMarket) public {
        INITIAL_BOND_OFFERING_MARKET_CONTRACT = ISolvV2InitialConvertibleOfferingMarket(
            _initialBondOfferingMarket
        );
    }

    /// @notice Parses the assets to send and receive for the callOnExternalPosition
    /// @param _externalPosition The _externalPosition to be called
    /// @param _actionId The _actionId for the callOnExternalPosition
    /// @param _encodedActionArgs The encoded parameters for the callOnExternalPosition
    /// @return assetsToTransfer_ The assets to be transferred from the Vault
    /// @return amountsToTransfer_ The amounts to be transferred from the Vault
    /// @return assetsToReceive_ The assets to be received at the Vault
    function parseAssetsForAction(
        address _externalPosition,
        uint256 _actionId,
        bytes memory _encodedActionArgs
    )
        external
        override
        returns (
            address[] memory assetsToTransfer_,
            uint256[] memory amountsToTransfer_,
            address[] memory assetsToReceive_
        )
    {
        if (_actionId == uint256(ISolvV2BondIssuerPosition.Actions.CreateOffer)) {
            (
                address voucher,
                address currency,
                ,
                ,
                ,
                ,
                ,
                ,
                ,
                ISolvV2InitialConvertibleOfferingMarket.MintParameter memory mintParameter
            ) = __decodeCreateOfferActionArgs(_encodedActionArgs);

            __validateNotNativeToken(currency);

            assetsToTransfer_ = new address[](1);
            assetsToTransfer_[0] = ISolvV2BondVoucher(voucher).underlying();
            amountsToTransfer_ = new uint256[](1);
            amountsToTransfer_[0] = mintParameter.tokenInAmount;
        } else if (_actionId == uint256(ISolvV2BondIssuerPosition.Actions.Reconcile)) {
            uint24[] memory offersMem = ISolvV2BondIssuerPosition(_externalPosition).getOffers();
            uint256 offersLength = offersMem.length;
            for (uint256 i; i < offersLength; i++) {
                address currency = INITIAL_BOND_OFFERING_MARKET_CONTRACT
                    .offerings(offersMem[i])
                    .currency;
                if (ERC20(currency).balanceOf(_externalPosition) > 0) {
                    assetsToReceive_ = assetsToReceive_.addUniqueItem(currency);
                }
            }
        } else if (_actionId == uint256(ISolvV2BondIssuerPosition.Actions.Refund)) {
            (address voucher, uint256 slotId) = __decodeRefundActionArgs(_encodedActionArgs);

            ISolvV2BondPool voucherPoolContract = ISolvV2BondPool(
                ISolvV2BondVoucher(voucher).bondPool()
            );

            ISolvV2BondPool.SlotDetail memory slotDetail = voucherPoolContract.getSlotDetail(
                slotId
            );

            uint256 currencyAmount = slotDetail
                .totalValue
                .mul(10**uint256(ERC20(slotDetail.fundCurrency).decimals()))
                .div(10**uint256(voucherPoolContract.valueDecimals()));

            assetsToTransfer_ = new address[](1);
            assetsToTransfer_[0] = slotDetail.fundCurrency;
            amountsToTransfer_ = new uint256[](1);
            amountsToTransfer_[0] = currencyAmount;
        } else if (_actionId == uint256(ISolvV2BondIssuerPosition.Actions.RemoveOffer)) {
            uint24 offerId = __decodeRemoveOfferActionArgs(_encodedActionArgs);

            ISolvV2InitialConvertibleOfferingMarket.Offering
                memory offer = INITIAL_BOND_OFFERING_MARKET_CONTRACT.offerings(offerId);

            // If offer has remaining unsold units, some underlying is refunded
            if (offer.units > 0) {
                assetsToReceive_ = new address[](1);
                assetsToReceive_[0] = ISolvV2BondVoucher(offer.voucher).underlying();
            }

            if (ERC20(offer.currency).balanceOf(_externalPosition) > 0) {
                assetsToReceive_ = assetsToReceive_.addItem(offer.currency);
            }
        } else if (_actionId == uint256(ISolvV2BondIssuerPosition.Actions.Withdraw)) {
            (address voucher, ) = __decodeWithdrawActionArgs(_encodedActionArgs);

            assetsToReceive_ = new address[](1);
            assetsToReceive_[0] = ISolvV2BondVoucher(voucher).underlying();
        }

        return (assetsToTransfer_, amountsToTransfer_, assetsToReceive_);
    }

    /// @notice Parse and validate input arguments to be used when initializing a newly-deployed ExternalPositionProxy
    /// @dev Empty for this external position type
    function parseInitArgs(address, bytes memory) external override returns (bytes memory) {}

    // PRIVATE FUNCTIONS

    /// @dev Helper to validate that assets are not the NATIVE_TOKEN_ADDRESS
    function __validateNotNativeToken(address _asset) private pure {
        require(
            _asset != NATIVE_TOKEN_ADDRESS,
            "__validateNotNativeToken: Native asset is unsupported"
        );
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

/// @title ISolvV2BondPool Interface
/// @author Enzyme Council <[email protected]>
/// @dev Source: https://github.com/solv-finance/solv-v2-ivo/blob/main/vouchers/bond-voucher/contracts/BondPool.sol
interface ISolvV2BondPool {
    enum CollateralType {
        ERC20,
        VESTING_VOUCHER
    }

    struct SlotDetail {
        address issuer;
        address fundCurrency;
        uint256 totalValue;
        uint128 lowestPrice;
        uint128 highestPrice;
        uint128 settlePrice;
        uint64 effectiveTime;
        uint64 maturity;
        CollateralType collateralType;
        bool isIssuerRefunded;
        bool isIssuerWithdrawn;
        bool isClaimed;
        bool isValid;
    }

    function getIssuerSlots(address _issuer) external view returns (uint256[] memory slots_);

    function getSettlePrice(uint256 _slot) external view returns (uint128 settlePrice_);

    function getSlotDetail(uint256 _slot) external view returns (SlotDetail memory slotDetail_);

    function getWithdrawableAmount(uint256 _slot)
        external
        view
        returns (uint256 withdrawTokenAmount_);

    function refund(uint256 _slot) external;

    function slotBalances(uint256 _slotId, address _currency)
        external
        view
        returns (uint256 balance_);

    function valueDecimals() external view returns (uint8 decimals_);

    function withdraw(uint256 _slot) external returns (uint256 withdrawTokenAmount_);
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

import "./ISolvV2BondPool.sol";

/// @title ISolvV2BondVoucher Interface
/// @author Enzyme Council <[email protected]>
/// @dev Source: https://github.com/solv-finance/solv-v2-ivo/blob/main/vouchers/bond-voucher/contracts/BondVoucher.sol
interface ISolvV2BondVoucher {
    function approve(address _to, uint256 _tokenId) external;

    function bondPool() external view returns (address bondPool_);

    function claimTo(
        uint256 _tokenId,
        address _to,
        uint256 _claimUnits
    ) external;

    function getSlot(
        address _issuer,
        address _fundCurrency,
        uint128 _lowestPrice,
        uint128 _highestPrice,
        uint64 _effectiveTime,
        uint64 _maturity
    ) external view returns (uint256 slot_);

    function getSlotDetail(uint256 _slot)
        external
        view
        returns (ISolvV2BondPool.SlotDetail memory slotDetail_);

    function nextTokenId() external view returns (uint32 nextTokenId_);

    function ownerOf(uint256 _tokenId) external view returns (address owner_);

    function slotOf(uint256 _tokenId) external view returns (uint256 slotId_);

    function underlying() external view returns (address underlying_);

    function unitsInToken(uint256 tokenId_) external view returns (uint256 units_);

    function voucherSlotMapping(uint256 _tokenId) external returns (uint256 slotId_);
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

/// @title ISolvV2InitialConvertibleOfferingMarket Interface
/// @author Enzyme Council <[email protected]>
/// @dev Source: https://github.com/solv-finance/solv-v2-ivo/blob/main/markets/convertible-offering-market/contracts/InitialConvertibleOfferingMarket.sol
interface ISolvV2InitialConvertibleOfferingMarket {
    enum VoucherType {
        STANDARD_VESTING,
        FLEXIBLE_DATE_VESTING,
        BOUNDING
    }

    struct Market {
        VoucherType voucherType;
        address voucherPool;
        address asset;
        uint8 decimals;
        uint16 feeRate;
        bool onlyManangerOffer;
        bool isValid;
    }

    /**
     * @param lowestPrice Lower price bound of the voucher (8 decimals)
     * @param highestPrice Upper price bound of the voucher (8 decimals)
     * @param tokenInAmount Amount of underlying tokens sent as collateral for minting (determined the amount of tokens )
     * @param effectiveTime Effective timestamp. Refers to when the bond takes effect (like startTime)
     * @param maturity Maturity timestamp of the voucher
     */
    struct MintParameter {
        uint128 lowestPrice;
        uint128 highestPrice;
        uint128 tokenInAmount;
        uint64 effectiveTime;
        uint64 maturity;
    }

    enum PriceType {
        FIXED,
        DECLIINING_BY_TIME
    }

    struct Offering {
        uint24 offeringId;
        uint32 startTime;
        uint32 endTime;
        PriceType priceType;
        uint128 totalUnits;
        uint128 units;
        uint128 min;
        uint128 max;
        address voucher;
        address currency;
        address issuer;
        bool useAllowList;
        bool isValid;
    }

    function buy(uint24 _offeringId, uint128 _units)
        external
        payable
        returns (uint256 amount_, uint128 fee_);

    function getPrice(uint24 _offeringId) external view returns (uint256 price_);

    function markets(address _voucher) external view returns (Market memory market_);

    function mintParameters(uint24 _offeringId)
        external
        view
        returns (MintParameter memory mintParameter_);

    function offer(
        address _voucher,
        address _currency,
        uint128 _min,
        uint128 _max,
        uint32 _startTime,
        uint32 _endTime,
        bool _useAllowList,
        PriceType _priceType,
        bytes calldata _priceData,
        MintParameter calldata _mintParameter
    ) external returns (uint24 offeringId_);

    function offerings(uint24 _offerId) external view returns (Offering memory offering_);

    function remove(uint24 _offeringId) external;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title AddressArray Library
/// @author Enzyme Council <[email protected]>
/// @notice A library to extend the address array data type
library AddressArrayLib {
    /////////////
    // STORAGE //
    /////////////

    /// @dev Helper to remove an item from a storage array
    function removeStorageItem(address[] storage _self, address _itemToRemove)
        internal
        returns (bool removed_)
    {
        uint256 itemCount = _self.length;
        for (uint256 i; i < itemCount; i++) {
            if (_self[i] == _itemToRemove) {
                if (i < itemCount - 1) {
                    _self[i] = _self[itemCount - 1];
                }
                _self.pop();
                removed_ = true;
                break;
            }
        }

        return removed_;
    }

    /// @dev Helper to verify if a storage array contains a particular value
    function storageArrayContains(address[] storage _self, address _target)
        internal
        view
        returns (bool doesContain_)
    {
        uint256 arrLength = _self.length;
        for (uint256 i; i < arrLength; i++) {
            if (_target == _self[i]) {
                return true;
            }
        }
        return false;
    }

    ////////////
    // MEMORY //
    ////////////

    /// @dev Helper to add an item to an array. Does not assert uniqueness of the new item.
    function addItem(address[] memory _self, address _itemToAdd)
        internal
        pure
        returns (address[] memory nextArray_)
    {
        nextArray_ = new address[](_self.length + 1);
        for (uint256 i; i < _self.length; i++) {
            nextArray_[i] = _self[i];
        }
        nextArray_[_self.length] = _itemToAdd;

        return nextArray_;
    }

    /// @dev Helper to add an item to an array, only if it is not already in the array.
    function addUniqueItem(address[] memory _self, address _itemToAdd)
        internal
        pure
        returns (address[] memory nextArray_)
    {
        if (contains(_self, _itemToAdd)) {
            return _self;
        }

        return addItem(_self, _itemToAdd);
    }

    /// @dev Helper to verify if an array contains a particular value
    function contains(address[] memory _self, address _target)
        internal
        pure
        returns (bool doesContain_)
    {
        for (uint256 i; i < _self.length; i++) {
            if (_target == _self[i]) {
                return true;
            }
        }
        return false;
    }

    /// @dev Helper to merge the unique items of a second array.
    /// Does not consider uniqueness of either array, only relative uniqueness.
    /// Preserves ordering.
    function mergeArray(address[] memory _self, address[] memory _arrayToMerge)
        internal
        pure
        returns (address[] memory nextArray_)
    {
        uint256 newUniqueItemCount;
        for (uint256 i; i < _arrayToMerge.length; i++) {
            if (!contains(_self, _arrayToMerge[i])) {
                newUniqueItemCount++;
            }
        }

        if (newUniqueItemCount == 0) {
            return _self;
        }

        nextArray_ = new address[](_self.length + newUniqueItemCount);
        for (uint256 i; i < _self.length; i++) {
            nextArray_[i] = _self[i];
        }
        uint256 nextArrayIndex = _self.length;
        for (uint256 i; i < _arrayToMerge.length; i++) {
            if (!contains(_self, _arrayToMerge[i])) {
                nextArray_[nextArrayIndex] = _arrayToMerge[i];
                nextArrayIndex++;
            }
        }

        return nextArray_;
    }

    /// @dev Helper to verify if array is a set of unique values.
    /// Does not assert length > 0.
    function isUniqueSet(address[] memory _self) internal pure returns (bool isUnique_) {
        if (_self.length <= 1) {
            return true;
        }

        uint256 arrayLength = _self.length;
        for (uint256 i; i < arrayLength; i++) {
            for (uint256 j = i + 1; j < arrayLength; j++) {
                if (_self[i] == _self[j]) {
                    return false;
                }
            }
        }

        return true;
    }

    /// @dev Helper to remove items from an array. Removes all matching occurrences of each item.
    /// Does not assert uniqueness of either array.
    function removeItems(address[] memory _self, address[] memory _itemsToRemove)
        internal
        pure
        returns (address[] memory nextArray_)
    {
        if (_itemsToRemove.length == 0) {
            return _self;
        }

        bool[] memory indexesToRemove = new bool[](_self.length);
        uint256 remainingItemsCount = _self.length;
        for (uint256 i; i < _self.length; i++) {
            if (contains(_itemsToRemove, _self[i])) {
                indexesToRemove[i] = true;
                remainingItemsCount--;
            }
        }

        if (remainingItemsCount == _self.length) {
            nextArray_ = _self;
        } else if (remainingItemsCount > 0) {
            nextArray_ = new address[](remainingItemsCount);
            uint256 nextArrayIndex;
            for (uint256 i; i < _self.length; i++) {
                if (!indexesToRemove[i]) {
                    nextArray_[nextArrayIndex] = _self[i];
                    nextArrayIndex++;
                }
            }
        }

        return nextArray_;
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

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title Uint256Array Library
/// @author Enzyme Council <[email protected]>
/// @notice A library to extend the uint256 array data type
library Uint256ArrayLib {
    /////////////
    // STORAGE //
    /////////////

    /// @dev Helper to remove an item from a storage array
    function removeStorageItem(uint256[] storage _self, uint256 _itemToRemove)
        internal
        returns (bool removed_)
    {
        uint256 itemCount = _self.length;
        for (uint256 i; i < itemCount; i++) {
            if (_self[i] == _itemToRemove) {
                if (i < itemCount - 1) {
                    _self[i] = _self[itemCount - 1];
                }
                _self.pop();
                removed_ = true;
                break;
            }
        }

        return removed_;
    }

    /// @dev Helper to verify if a storage array contains a particular value
    function storageArrayContains(uint256[] storage _self, uint256 _target)
        internal
        view
        returns (bool doesContain_)
    {
        uint256 arrLength = _self.length;
        for (uint256 i; i < arrLength; i++) {
            if (_target == _self[i]) {
                return true;
            }
        }
        return false;
    }

    ////////////
    // MEMORY //
    ////////////

    /// @dev Helper to add an item to an array. Does not assert uniqueness of the new item.
    function addItem(uint256[] memory _self, uint256 _itemToAdd)
        internal
        pure
        returns (uint256[] memory nextArray_)
    {
        nextArray_ = new uint256[](_self.length + 1);
        for (uint256 i; i < _self.length; i++) {
            nextArray_[i] = _self[i];
        }
        nextArray_[_self.length] = _itemToAdd;

        return nextArray_;
    }

    /// @dev Helper to add an item to an array, only if it is not already in the array.
    function addUniqueItem(uint256[] memory _self, uint256 _itemToAdd)
        internal
        pure
        returns (uint256[] memory nextArray_)
    {
        if (contains(_self, _itemToAdd)) {
            return _self;
        }

        return addItem(_self, _itemToAdd);
    }

    /// @dev Helper to verify if an array contains a particular value
    function contains(uint256[] memory _self, uint256 _target)
        internal
        pure
        returns (bool doesContain_)
    {
        for (uint256 i; i < _self.length; i++) {
            if (_target == _self[i]) {
                return true;
            }
        }
        return false;
    }

    /// @dev Helper to merge the unique items of a second array.
    /// Does not consider uniqueness of either array, only relative uniqueness.
    /// Preserves ordering.
    function mergeArray(uint256[] memory _self, uint256[] memory _arrayToMerge)
        internal
        pure
        returns (uint256[] memory nextArray_)
    {
        uint256 newUniqueItemCount;
        for (uint256 i; i < _arrayToMerge.length; i++) {
            if (!contains(_self, _arrayToMerge[i])) {
                newUniqueItemCount++;
            }
        }

        if (newUniqueItemCount == 0) {
            return _self;
        }

        nextArray_ = new uint256[](_self.length + newUniqueItemCount);
        for (uint256 i; i < _self.length; i++) {
            nextArray_[i] = _self[i];
        }
        uint256 nextArrayIndex = _self.length;
        for (uint256 i; i < _arrayToMerge.length; i++) {
            if (!contains(_self, _arrayToMerge[i])) {
                nextArray_[nextArrayIndex] = _arrayToMerge[i];
                nextArrayIndex++;
            }
        }

        return nextArray_;
    }

    /// @dev Helper to verify if array is a set of unique values.
    /// Does not assert length > 0.
    function isUniqueSet(uint256[] memory _self) internal pure returns (bool isUnique_) {
        if (_self.length <= 1) {
            return true;
        }

        uint256 arrayLength = _self.length;
        for (uint256 i; i < arrayLength; i++) {
            for (uint256 j = i + 1; j < arrayLength; j++) {
                if (_self[i] == _self[j]) {
                    return false;
                }
            }
        }

        return true;
    }

    /// @dev Helper to remove items from an array. Removes all matching occurrences of each item.
    /// Does not assert uniqueness of either array.
    function removeItems(uint256[] memory _self, uint256[] memory _itemsToRemove)
        internal
        pure
        returns (uint256[] memory nextArray_)
    {
        if (_itemsToRemove.length == 0) {
            return _self;
        }

        bool[] memory indexesToRemove = new bool[](_self.length);
        uint256 remainingItemsCount = _self.length;
        for (uint256 i; i < _self.length; i++) {
            if (contains(_itemsToRemove, _self[i])) {
                indexesToRemove[i] = true;
                remainingItemsCount--;
            }
        }

        if (remainingItemsCount == _self.length) {
            nextArray_ = _self;
        } else if (remainingItemsCount > 0) {
            nextArray_ = new uint256[](remainingItemsCount);
            uint256 nextArrayIndex;
            for (uint256 i; i < _self.length; i++) {
                if (!indexesToRemove[i]) {
                    nextArray_[nextArrayIndex] = _self[i];
                    nextArrayIndex++;
                }
            }
        }

        return nextArray_;
    }
}