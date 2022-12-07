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

/// @title IDispatcher Interface
/// @author Enzyme Council <[email protected]>
interface IDispatcher {
    function cancelMigration(address _vaultProxy, bool _bypassFailure) external;

    function claimOwnership() external;

    function deployVaultProxy(
        address _vaultLib,
        address _owner,
        address _vaultAccessor,
        string calldata _fundName
    ) external returns (address vaultProxy_);

    function executeMigration(address _vaultProxy, bool _bypassFailure) external;

    function getCurrentFundDeployer() external view returns (address currentFundDeployer_);

    function getFundDeployerForVaultProxy(address _vaultProxy)
        external
        view
        returns (address fundDeployer_);

    function getMigrationRequestDetailsForVaultProxy(address _vaultProxy)
        external
        view
        returns (
            address nextFundDeployer_,
            address nextVaultAccessor_,
            address nextVaultLib_,
            uint256 executableTimestamp_
        );

    function getMigrationTimelock() external view returns (uint256 migrationTimelock_);

    function getNominatedOwner() external view returns (address nominatedOwner_);

    function getOwner() external view returns (address owner_);

    function getSharesTokenSymbol() external view returns (string memory sharesTokenSymbol_);

    function getTimelockRemainingForMigrationRequest(address _vaultProxy)
        external
        view
        returns (uint256 secondsRemaining_);

    function hasExecutableMigrationRequest(address _vaultProxy)
        external
        view
        returns (bool hasExecutableRequest_);

    function hasMigrationRequest(address _vaultProxy)
        external
        view
        returns (bool hasMigrationRequest_);

    function removeNominatedOwner() external;

    function setCurrentFundDeployer(address _nextFundDeployer) external;

    function setMigrationTimelock(uint256 _nextTimelock) external;

    function setNominatedOwner(address _nextNominatedOwner) external;

    function setSharesTokenSymbol(string calldata _nextSymbol) external;

    function signalMigration(
        address _vaultProxy,
        address _nextVaultAccessor,
        address _nextVaultLib,
        bool _bypassFailure
    ) external;
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

/// @title MapleLiquidityPositionLibBase1 Contract
/// @author Enzyme Council <[email protected]>
/// @notice A persistent contract containing all required storage variables and
/// required functions for a MapleLiquidityPositionLib implementation
/// @dev DO NOT EDIT CONTRACT. If new events or storage are necessary, they should be added to
/// a numbered MapleLiquidityPositionLibBaseXXX that inherits the previous base.
/// e.g., `MapleLiquidityPositionLibBase2 is MapleLiquidityPositionLibBase1`
abstract contract MapleLiquidityPositionLibBase1 {
    event UsedLendingPoolAdded(address indexed lendingPool);

    event UsedLendingPoolRemoved(address indexed lendingPool);

    address[] internal usedLendingPoolsV1;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "./MapleLiquidityPositionLibBase1.sol";

/// @title MapleLiquidityPositionLibBase2 Contract
/// @author Enzyme Council <[email protected]>
/// @notice A persistent contract containing all required storage variables and
/// required functions for a MapleLiquidityPositionLib implementation
/// @dev DO NOT EDIT CONTRACT. If new events or storage are necessary, they should be added to
/// a numbered MapleLiquidityPositionLibBaseXXX that inherits the previous base.
/// e.g., `MapleLiquidityPositionLibBase2 is MapleLiquidityPositionLibBase1`
abstract contract MapleLiquidityPositionLibBase2 is MapleLiquidityPositionLibBase1 {
    event PoolTokenV1PreMigrationValueSnapshotted(address indexed lendingPoolV1, uint256 value);

    event UsedLendingPoolV2Added(address indexed lendingPoolV2);

    event UsedLendingPoolV2Removed(address indexed lendingPoolV2);

    address[] internal usedLendingPoolsV2;

    mapping(address => uint256) internal poolTokenV1ToPreMigrationValueSnapshot;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../../release/extensions/external-position-manager/external-positions/maple-liquidity/MapleLiquidityPositionLib.sol";
import "../../dispatcher/IDispatcher.sol";

/// @title MapleV1ToV2PoolMapper Contract
/// @author Enzyme Council <[email protected]>
/// @notice A contract for associating Maple v1 to Maple v2 pools
contract MapleV1ToV2PoolMapper {
    event MigrationAllowed();

    event PoolMapped(address poolTokenV1, address poolTokenV2);

    event SnapshotsFrozen();

    address private immutable DISPATCHER;

    bool private migrationDisallowed;
    bool private snapshotsAllowed;

    mapping(address => address) private poolTokenV1ToPoolTokenV2;

    modifier onlyDispatcherOwner() {
        require(
            msg.sender == IDispatcher(DISPATCHER).getOwner(),
            "Only the Dispatcher owner can call this function"
        );
        _;
    }

    constructor(address _dispacher) public {
        DISPATCHER = _dispacher;

        migrationDisallowed = true;
        snapshotsAllowed = true;
    }

    ////////////////////////////
    // BULK MIGRATION HELPERS //
    ////////////////////////////

    /// @notice Runs pool migration logic on the proxy of each MapleLiquidityPosition
    /// @dev No need to validate _proxies
    function migrateExternalPositions(address[] calldata _proxies) external {
        for (uint256 i; i < _proxies.length; i++) {
            MapleLiquidityPositionLib(_proxies[i]).migratePoolsV1ToV2();
        }
    }

    /// @notice Runs MPTv1 snapshotting logic on the proxy of each MapleLiquidityPosition
    /// @dev No need to validate _proxies
    function snapshotExternalPositions(address[] calldata _proxies) external {
        for (uint256 i; i < _proxies.length; i++) {
            MapleLiquidityPositionLib(_proxies[i]).snapshotPoolTokenV1BalanceValues();
        }
    }

    ///////////
    // ADMIN //
    ///////////

    /// @notice Allows external positions to migrate their pools using the pool mapping
    function allowMigration() external onlyDispatcherOwner {
        migrationDisallowed = false;

        emit MigrationAllowed();
    }

    /// @notice Associates Maple Pool Tokens v1 to their v2 equivalent
    /// @param _poolTokensV1 The Maple Pool Tokens v1
    /// @param _poolTokensV2 The Maple Pool Tokens v2
    function mapPools(address[] calldata _poolTokensV1, address[] calldata _poolTokensV2)
        external
        onlyDispatcherOwner
    {
        for (uint256 i; i < _poolTokensV1.length; i++) {
            address poolTokenV1 = _poolTokensV1[i];
            address poolTokenV2 = _poolTokensV2[i];

            poolTokenV1ToPoolTokenV2[poolTokenV1] = poolTokenV2;

            emit PoolMapped(poolTokenV1, poolTokenV2);
        }
    }

    /// @notice Freezes snapshots
    function freezeSnapshots() external onlyDispatcherOwner {
        snapshotsAllowed = false;

        emit SnapshotsFrozen();
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the Maple Pool Token v2 associated to a given Maple Pool Token v1
    /// @param _poolTokenV1 The Maple Pool Token v1
    /// @return poolTokenV2_ The Maple Pool Token v2
    function getPoolTokenV2FromPoolTokenV1(address _poolTokenV1)
        external
        view
        returns (address poolTokenV2_)
    {
        return poolTokenV1ToPoolTokenV2[_poolTokenV1];
    }

    /// @notice Checks whether pool migration is allowed for Enzyme external positions
    /// @return allowed_ True if migration is allowed
    function migrationIsAllowed() external view returns (bool allowed_) {
        return !migrationDisallowed;
    }

    /// @notice Checks whether pool v1 snapshots are allowed for Enzyme external positions
    /// @return allowed_ True if snapshots are allowed
    function snapshotsAreAllowed() external view returns (bool allowed_) {
        return snapshotsAllowed;
    }
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

/// @title IMapleLiquidityPosition Interface
/// @author Enzyme Council <[email protected]>
interface IMapleLiquidityPosition is IExternalPosition {
    enum Actions {
        DEPRECATED_LendV1,
        DEPRECATED_LendAndStakeV1,
        DEPRECATED_IntendToRedeemV1,
        DEPRECATED_RedeemV1,
        DEPRECATED_StakeV1,
        DEPRECATED_UnstakeV1,
        DEPRECATED_UnstakeAndRedeemV1,
        DEPRECATED_ClaimInterestV1,
        ClaimRewardsV1,
        LendV2,
        RequestRedeemV2,
        RedeemV2,
        CancelRedeemV2
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

/// @title MapleLiquidityPositionDataDecoder Contract
/// @author Enzyme Council <[email protected]>
/// @notice Abstract contract containing data decodings for MapleLiquidityPosition payloads
abstract contract MapleLiquidityPositionDataDecoder {
    ////////////////
    // V1 ACTIONS //
    ////////////////

    /// @dev Helper to decode args used during the ClaimRewardsV1 action
    function __decodeClaimRewardsV1ActionArgs(bytes memory _actionArgs)
        internal
        pure
        returns (address rewardsContract_)
    {
        return abi.decode(_actionArgs, (address));
    }

    ////////////////
    // V2 ACTIONS //
    ////////////////

    /// @dev Helper to decode args used during the CancelRedeemV2 action
    function __decodeCancelRedeemV2ActionArgs(bytes memory _actionArgs)
        internal
        pure
        returns (address pool_, uint256 poolTokenAmount_)
    {
        return abi.decode(_actionArgs, (address, uint256));
    }

    /// @dev Helper to decode args used during the LendV2 action
    function __decodeLendV2ActionArgs(bytes memory _actionArgs)
        internal
        pure
        returns (address pool_, uint256 liquidityAssetAmount_)
    {
        return abi.decode(_actionArgs, (address, uint256));
    }

    /// @dev Helper to decode args used during the RedeemV2 action
    function __decodeRedeemV2ActionArgs(bytes memory _actionArgs)
        internal
        pure
        returns (address pool_, uint256 poolTokenAmount_)
    {
        return abi.decode(_actionArgs, (address, uint256));
    }

    /// @dev Helper to decode args used during the RequestRedeemV2 action
    function __decodeRequestRedeemV2ActionArgs(bytes memory _actionArgs)
        internal
        pure
        returns (address pool_, uint256 poolTokenAmount_)
    {
        return abi.decode(_actionArgs, (address, uint256));
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
import "../../../../../persistent/external-positions/maple-liquidity/MapleLiquidityPositionLibBase2.sol";
import "../../../../../persistent/external-positions/maple-liquidity/MapleV1ToV2PoolMapper.sol";
import "../../../../interfaces/IMapleV1MplRewards.sol";
import "../../../../interfaces/IMapleV1Pool.sol";
import "../../../../interfaces/IMapleV2Pool.sol";
import "../../../../interfaces/IMapleV2PoolManager.sol";
import "../../../../interfaces/IMapleV2WithdrawalManager.sol";
import "../../../../utils/AddressArrayLib.sol";
import "../../../../utils/AssetHelpers.sol";
import "../../../../utils/Uint256ArrayLib.sol";
import "./IMapleLiquidityPosition.sol";
import "./MapleLiquidityPositionDataDecoder.sol";

/// @title MapleLiquidityPositionLib Contract
/// @author Enzyme Council <[email protected]>
/// @notice An External Position library contract for Maple liquidity positions
contract MapleLiquidityPositionLib is
    IMapleLiquidityPosition,
    MapleLiquidityPositionDataDecoder,
    MapleLiquidityPositionLibBase2,
    AssetHelpers
{
    using AddressArrayLib for address[];
    using SafeERC20 for ERC20;
    using SafeMath for uint256;
    using Uint256ArrayLib for uint256[];

    uint256 private constant MPT_V1_DECIMALS_FACTOR = 10**18;

    MapleV1ToV2PoolMapper private immutable MAPLE_V1_TO_V2_POOL_MAPPER_CONTRACT;

    constructor(address _mapleV1ToV2PoolMapper) public {
        MAPLE_V1_TO_V2_POOL_MAPPER_CONTRACT = MapleV1ToV2PoolMapper(_mapleV1ToV2PoolMapper);
    }

    /// @notice Initializes the external position
    /// @dev Nothing to initialize for this contract
    function init(bytes memory) external override {}

    /////////////
    // ACTIONS //
    /////////////

    /// @notice Receives and executes a call from the Vault
    /// @param _actionData Encoded data to execute the action
    function receiveCallFromVault(bytes memory _actionData) external override {
        (uint256 actionId, bytes memory actionArgs) = abi.decode(_actionData, (uint256, bytes));

        if (actionId == uint256(Actions.LendV2)) {
            __lendV2Action(actionArgs);
        } else if (actionId == uint256(Actions.RequestRedeemV2)) {
            __requestRedeemV2Action(actionArgs);
        } else if (actionId == uint256(Actions.RedeemV2)) {
            __redeemV2Action(actionArgs);
        } else if (actionId == uint256(Actions.CancelRedeemV2)) {
            __cancelRedeemV2Action(actionArgs);
        } else if (actionId == uint256(Actions.ClaimRewardsV1)) {
            __claimRewardsV1Action(actionArgs);
        } else {
            revert("receiveCallFromVault: Invalid actionId");
        }
    }

    ////////////////
    // V1 ACTIONS //
    ////////////////

    /// @dev Claims all rewards accrued and send it to the Vault
    function __claimRewardsV1Action(bytes memory _actionArgs) private {
        address rewardsContract = __decodeClaimRewardsV1ActionArgs(_actionArgs);

        IMapleV1MplRewards mapleRewards = IMapleV1MplRewards(rewardsContract);
        ERC20 rewardToken = ERC20(mapleRewards.rewardsToken());
        mapleRewards.getReward();

        rewardToken.safeTransfer(msg.sender, rewardToken.balanceOf(address(this)));
    }

    ////////////////
    // V2 ACTIONS //
    ////////////////

    /// @dev Helper to add a Maple v2 pool used by the position
    function __addUsedPoolV2IfUntracked(address _pool) private {
        if (!isUsedLendingPoolV2(_pool)) {
            usedLendingPoolsV2.push(_pool);

            emit UsedLendingPoolV2Added(_pool);
        }
    }

    /// @dev Cancels redemption request from a Maple V2 pool by removing shares from escrow (action)
    function __cancelRedeemV2Action(bytes memory _actionArgs) private {
        (address pool, uint256 poolTokenAmount) = __decodeCancelRedeemV2ActionArgs(_actionArgs);

        IMapleV2Pool(pool).removeShares({_shares: poolTokenAmount, _owner: address(this)});
    }

    /// @dev Lends assets to a Maple V2 pool (action)
    function __lendV2Action(bytes memory _actionArgs) private {
        // v1 pools must all be migrated before lending is allowed,
        // otherwise a situation could arise where airdropped MPTv2 are double-counted
        // since their corresponding v1 snapshot balance is still included in position value.
        if (usedLendingPoolsV1.length > 0) {
            migratePoolsV1ToV2();
        }

        (address pool, uint256 liquidityAssetAmount) = __decodeLendV2ActionArgs(_actionArgs);

        __approveAssetMaxAsNeeded({
            _asset: IMapleV2Pool(pool).asset(),
            _target: pool,
            _neededAmount: liquidityAssetAmount
        });

        IMapleV2Pool(pool).deposit({_assets: liquidityAssetAmount, _receiver: address(this)});

        __addUsedPoolV2IfUntracked(pool);
    }

    /// @dev Redeems assets from a Maple V2 pool (action)
    function __redeemV2Action(bytes memory _actionArgs) private {
        (address pool, uint256 poolTokenAmount) = __decodeRedeemV2ActionArgs(_actionArgs);

        IMapleV2Pool(pool).redeem({
            _shares: poolTokenAmount,
            _receiver: msg.sender,
            _owner: address(this)
        });

        // If the full amount of pool tokens has been redeemed, it can be removed from usedLendingPoolsV2
        if (__getTotalPoolTokenV2Balance(pool) == 0) {
            usedLendingPoolsV2.removeStorageItem(pool);

            emit UsedLendingPoolV2Removed(pool);
        }
    }

    /// @dev Request to Redeem assets from a Maple V2 pool (action)
    function __requestRedeemV2Action(bytes memory _actionArgs) private {
        // v1 pools must all be migrated before any redemptions are made,
        // otherwise a situation could arise where airdropped MPTv2 are redeemed
        // while their corresponding v1 snapshot balance is still included in position value.
        if (usedLendingPoolsV1.length > 0) {
            migratePoolsV1ToV2();
        }

        (address pool, uint256 poolTokenAmount) = __decodeRequestRedeemV2ActionArgs(_actionArgs);

        IMapleV2Pool(pool).requestRedeem({_shares: poolTokenAmount, _owner: address(this)});
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
    /// @dev Since lending is not allowed until all v1 pools are migrated,
    /// tracked pools will either be all v1 or all v2, never a mix
    function getManagedAssets()
        external
        override
        returns (address[] memory assets_, uint256[] memory amounts_)
    {
        uint256 poolsV1Length = usedLendingPoolsV1.length;
        if (poolsV1Length > 0) {
            if (MAPLE_V1_TO_V2_POOL_MAPPER_CONTRACT.migrationIsAllowed()) {
                // Once v1 => v2 migration is allowed, require it
                migratePoolsV1ToV2();

                // If migration does not revert, there are no more v1 pools
                poolsV1Length = 0;
            } else {
                // All pools are v1

                // If snapshots are still allowed, update all snapshots
                try this.snapshotPoolTokenV1BalanceValues() {} catch {}

                address[] memory poolsV1 = getUsedLendingPoolsV1();
                assets_ = new address[](poolsV1Length);
                amounts_ = new uint256[](poolsV1Length);
                for (uint256 i; i < poolsV1Length; i++) {
                    address poolV1 = poolsV1[i];

                    // Require there to be a snapshotted pool token v1 value,
                    // as we either have a snapshot at this point or no further snapshots are allowed
                    uint256 amount = getPreMigrationValueSnapshotOfPoolTokenV1(poolV1);
                    require(amount > 0, "getManagedAssets: No pool v1 snapshot");

                    assets_[i] = IMapleV1Pool(poolV1).liquidityAsset();
                    amounts_[i] = amount;
                }
            }
        }

        if (poolsV1Length == 0) {
            // All pools are v2
            address[] memory poolsV2 = getUsedLendingPoolsV2();
            uint256 poolsV2Length = poolsV2.length;
            assets_ = new address[](poolsV2Length);
            amounts_ = new uint256[](poolsV2Length);
            for (uint256 i; i < poolsV2Length; i++) {
                address poolV2 = poolsV2[i];

                assets_[i] = IMapleV2Pool(poolV2).asset();
                amounts_[i] = IMapleV2Pool(poolV2).convertToExitAssets(
                    __getTotalPoolTokenV2Balance(poolV2)
                );
            }
        }

        // If more than 1 pool position, combine amounts of the same asset.
        // We can remove this if/when we aggregate asset amounts at the ComptrollerLib level.
        if (assets_.length > 1) {
            (assets_, amounts_) = __aggregateAssetAmounts(assets_, amounts_);
        }

        return (assets_, amounts_);
    }

    /// @dev Helper to get total pool token v2 balance, including escrowed amount
    function __getTotalPoolTokenV2Balance(address _pool) private view returns (uint256 balance_) {
        balance_ = IERC20(_pool).balanceOf(address(this));

        // According to Maple's WithdrawalManager code comments, IMapleV2PoolManager.withdrawalManager
        // can be set to address(0) in order to pause redemptions, which would cause this to revert.
        address withdrawalManager = IMapleV2PoolManager(IMapleV2Pool(_pool).manager())
            .withdrawalManager();

        return
            balance_.add(IMapleV2WithdrawalManager(withdrawalManager).lockedShares(address(this)));
    }

    ////////////////////////
    // V1-TO-V2 MIGRATION //
    ////////////////////////

    // @dev We can remove all of these post-migration in a future version

    // EXTERNAL FUNCTIONS

    /// @notice Creates a snapshot of all Maple Pool Token v1 balance values
    /// @dev Callable by anybody
    function snapshotPoolTokenV1BalanceValues() external {
        require(
            MAPLE_V1_TO_V2_POOL_MAPPER_CONTRACT.snapshotsAreAllowed(),
            "snapshotPoolTokenV1BalanceValues: Snapshots frozen"
        );

        address[] memory poolsV1 = getUsedLendingPoolsV1();
        uint256 poolsV1Length = poolsV1.length;
        for (uint256 i; i < poolsV1Length; i++) {
            address poolV1 = poolsV1[i];
            uint256 value = __calcPoolV1TokenBalanceValue(poolV1);

            poolTokenV1ToPreMigrationValueSnapshot[poolV1] = value;

            emit PoolTokenV1PreMigrationValueSnapshotted(poolV1, value);
        }
    }

    // PUBLIC FUNCTIONS

    /// @notice Gets the snapshotted value of a given Maple Pool Token v1 in terms of its liquidity asset,
    /// taken prior to migration
    /// @param _poolV1 The Maple Pool v1
    /// @return valueSnapshot_ The snapshotted Maple Pool Token v1 value
    function getPreMigrationValueSnapshotOfPoolTokenV1(address _poolV1)
        public
        view
        returns (uint256 valueSnapshot_)
    {
        return poolTokenV1ToPreMigrationValueSnapshot[_poolV1];
    }

    /// @notice Migrates tracked v1 pools to tracked v2 pools
    /// @dev Callable by anybody.
    function migratePoolsV1ToV2() public {
        require(
            MAPLE_V1_TO_V2_POOL_MAPPER_CONTRACT.migrationIsAllowed(),
            "migratePoolsV1ToV2: Migration not allowed"
        );

        address[] memory poolsV1 = getUsedLendingPoolsV1();
        uint256 poolsV1Length = poolsV1.length;

        for (uint256 i; i < poolsV1Length; i++) {
            address poolV1 = poolsV1[i];
            address poolV2 = MAPLE_V1_TO_V2_POOL_MAPPER_CONTRACT.getPoolTokenV2FromPoolTokenV1(
                poolV1
            );
            require(poolV2 != address(0), "migratePoolsV1ToV2: No mapping");

            __addUsedPoolV2IfUntracked(poolV2);

            // Remove the old v1 pool from storage
            usedLendingPoolsV1.removeStorageItem(poolV1);
            emit UsedLendingPoolRemoved(poolV1);

            // Free up no-longer-needed snapshot storage
            delete poolTokenV1ToPreMigrationValueSnapshot[poolV1];
        }
    }

    // PRIVATE FUNCTIONS

    /// @dev Calculates the value of pool tokens referenced in liquidityAsset
    function __calcLiquidityAssetValueOfPoolTokensV1(
        address _liquidityAsset,
        uint256 _poolTokenAmount
    ) private view returns (uint256 liquidityValue_) {
        uint256 liquidityAssetDecimalsFactor = 10**(uint256(ERC20(_liquidityAsset).decimals()));

        liquidityValue_ = _poolTokenAmount.mul(liquidityAssetDecimalsFactor).div(
            MPT_V1_DECIMALS_FACTOR
        );

        return liquidityValue_;
    }

    /// @dev Helper to calculate the value of a v1 pool token balance of this contract,
    /// in terms of the pool's liquidityAsset
    function __calcPoolV1TokenBalanceValue(address _pool) private returns (uint256 value_) {
        IMapleV1Pool poolContract = IMapleV1Pool(_pool);

        // The liquidity asset balance is derived from the pool token balance (which is stored as a wad),
        // while interest and losses are already returned in terms of the liquidity asset (not pool token)
        uint256 liquidityAssetBalance = __calcLiquidityAssetValueOfPoolTokensV1(
            poolContract.liquidityAsset(),
            ERC20(_pool).balanceOf(address(this))
        );

        uint256 accumulatedInterest = poolContract.withdrawableFundsOf(address(this));
        uint256 accumulatedLosses = poolContract.recognizableLossesOf(address(this));

        value_ = liquidityAssetBalance.add(accumulatedInterest).sub(accumulatedLosses);

        return value_;
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets all Maple V1 pools currently lent to
    /// @return poolsV1_ The Maple V1 pools currently lent to
    function getUsedLendingPoolsV1() public view returns (address[] memory poolsV1_) {
        return usedLendingPoolsV1;
    }

    /// @notice Gets all Maple V2 pools currently lent to
    /// @return poolsV2_ The Maple V2 pools currently lent to
    function getUsedLendingPoolsV2() public view returns (address[] memory poolsV2_) {
        return usedLendingPoolsV2;
    }

    /// @notice Checks whether a pool V2 is currently lent to
    /// @param _poolV2 The pool
    /// @return isUsed_ True if the pool is lent to
    function isUsedLendingPoolV2(address _poolV2) public view returns (bool isUsed_) {
        return usedLendingPoolsV2.storageArrayContains(_poolV2);
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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title IERC4626 Interface
/// @author Enzyme Council <[email protected]>
/// @notice Minimal interface for interactions with IERC4626 tokens
interface IERC4626 is IERC20 {
    function asset() external view returns (address asset_);

    function deposit(uint256 _assets, address _receiver) external returns (uint256 shares_);

    function mint(uint256 shares_, address _receiver) external returns (uint256 assets_);

    function redeem(
        uint256 _shares,
        address _receiver,
        address _owner
    ) external returns (uint256 assets_);

    function withdraw(
        uint256 _assets,
        address _receiver,
        address _owner
    ) external returns (uint256 shares_);

    function convertToAssets(uint256 _shares) external view returns (uint256 assets_);

    function convertToShares(uint256 _assets) external view returns (uint256 shares_);

    function maxDeposit(address _receiver) external view returns (uint256 assets_);

    function maxMint(address _receiver) external view returns (uint256 shares_);

    function maxRedeem(address _owner) external view returns (uint256 shares_);

    function maxWithdraw(address _owner) external view returns (uint256 _assets);

    function previewDeposit(uint256 _assets) external view returns (uint256 shares_);

    function previewMint(uint256 _shares) external view returns (uint256 assets_);

    function previewRedeem(uint256 _shares) external view returns (uint256 assets_);

    function previewWithdraw(uint256 _assets) external view returns (uint256 shares_);

    function totalAssets() external view returns (uint256 totalAssets_);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IMapleV1MplRewards Interface
/// @author Enzyme Council <[email protected]>
interface IMapleV1MplRewards {
    function getReward() external;

    function rewardsToken() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IMapleV1Pool Interface
/// @author Enzyme Council <[email protected]>
interface IMapleV1Pool {
    function liquidityAsset() external view returns (address);

    function recognizableLossesOf(address) external returns (uint256);

    function withdrawableFundsOf(address) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/
import "./IERC4626.sol";

pragma solidity 0.6.12;

/// @title IMapleV2Pool Interface
/// @author Enzyme Council <[email protected]>
interface IMapleV2Pool is IERC4626 {
    function convertToExitAssets(uint256 _shares) external view returns (uint256 assets_);

    function removeShares(uint256 _shares, address _owner) external;

    function requestRedeem(uint256 _shares, address _owner) external;

    function manager() external view returns (address poolManager_);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IMapleV2PoolManager Interface
/// @author Enzyme Council <[email protected]>
interface IMapleV2PoolManager {
    function factory() external view returns (address factory_);

    function pool() external view returns (address pool_);

    function withdrawalManager() external view returns (address withdrawalManager_);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IMapleV2WithdrawalManager Interface
/// @author Enzyme Council <[email protected]>
interface IMapleV2WithdrawalManager {
    function lockedShares(address _account) external view returns (uint256);
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