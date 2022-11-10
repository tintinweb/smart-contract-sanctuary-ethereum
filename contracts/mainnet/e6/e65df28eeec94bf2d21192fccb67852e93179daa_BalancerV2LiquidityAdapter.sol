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

/// @title IIntegrationManager interface
/// @author Enzyme Council <[email protected]>
/// @notice Interface for the IntegrationManager
interface IIntegrationManager {
    enum SpendAssetsHandleType {
        None,
        Approve,
        Transfer
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

import "../IIntegrationManager.sol";

/// @title Integration Adapter interface
/// @author Enzyme Council <[email protected]>
/// @notice Interface for all integration adapters
interface IIntegrationAdapter {
    function parseAssetsForAction(
        address _vaultProxy,
        bytes4 _selector,
        bytes calldata _encodedCallArgs
    )
        external
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        );
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

import "../../../../interfaces/IBalancerV2LiquidityGauge.sol";
import "../utils/actions/CurveGaugeV2RewardsHandlerMixin.sol";
import "../utils/bases/BalancerV2LiquidityAdapterBase.sol";

/// @title BalancerV2LiquidityAdapter Contract
/// @author Enzyme Council <[email protected]>
/// @notice Adapter for Balancer V2 pool liquidity provision and native staking
contract BalancerV2LiquidityAdapter is
    BalancerV2LiquidityAdapterBase,
    CurveGaugeV2RewardsHandlerMixin
{
    constructor(
        address _integrationManager,
        address _balancerVault,
        address _balancerMinter,
        address _balToken
    )
        public
        BalancerV2LiquidityAdapterBase(_integrationManager, _balancerVault)
        CurveGaugeV2RewardsHandlerMixin(_balancerMinter, _balToken)
    {}

    ////////////////////////////////
    // REQUIRED VIRTUAL FUNCTIONS //
    ////////////////////////////////

    /// @dev Logic to claim rewards for a given staking token
    function __claimRewards(address _vaultProxy, address _stakingToken) internal override {
        __curveGaugeV2ClaimAllRewards(_stakingToken, _vaultProxy);
    }

    /// @dev Logic to get the BPT address for a given staking token.
    /// For this adapter, the staking token is not validated herein to be a real Balancer gauge,
    /// only to have the required interface.
    function __getBptForStakingToken(address _stakingToken)
        internal
        view
        override
        returns (address bpt_)
    {
        return IBalancerV2LiquidityGauge(_stakingToken).lp_token();
    }

    /// @dev Logic to stake BPT to a given staking token.
    /// Staking is always the last action and thus always sent to the _vaultProxy
    /// (rather than a more generically-named `_recipient`).
    function __stake(
        address _vaultProxy,
        address _stakingToken,
        uint256 _bptAmount
    ) internal override {
        __curveGaugeV2Stake(_stakingToken, __getBptForStakingToken(_stakingToken), _bptAmount);

        ERC20(_stakingToken).safeTransfer(_vaultProxy, _bptAmount);
    }

    /// @dev Logic to unstake BPT from a given staking token
    function __unstake(
        address,
        address _recipient,
        address _stakingToken,
        uint256 _bptAmount
    ) internal override {
        __curveGaugeV2Unstake(_stakingToken, _bptAmount);

        if (_recipient != address(this)) {
            ERC20(__getBptForStakingToken(_stakingToken)).safeTransfer(_recipient, _bptAmount);
        }
    }

    ///////////////////
    // EXTRA ACTIONS //
    ///////////////////

    /// @notice Lends assets for pool tokens on BalancerV2
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    function lend(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata
    ) external onlyIntegrationManager {
        (
            bytes32 poolId,
            ,
            address[] memory spendAssets,
            uint256[] memory spendAssetAmounts,
            IBalancerV2Vault.PoolBalanceChange memory request
        ) = __decodeLpActionCallArgs(_actionData);

        __lend(_vaultProxy, poolId, spendAssets, spendAssetAmounts, request);

        // There can be different join/exit options per Balancer pool type,
        // some of which involve spending only up-to-max amounts
        __pushFullAssetBalances(_vaultProxy, spendAssets);
    }

    /// @notice Redeems pool tokens on BalancerV2
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    function redeem(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata
    ) external onlyIntegrationManager {
        (
            bytes32 poolId,
            uint256 spendBptAmount,
            address[] memory expectedIncomingTokens,
            ,
            IBalancerV2Vault.PoolBalanceChange memory request
        ) = __decodeLpActionCallArgs(_actionData);

        __redeem(_vaultProxy, poolId, spendBptAmount, expectedIncomingTokens, request);

        // There can be different join/exit options per Balancer pool type,
        // some of which involve spending only up-to-max amounts
        __pushFullAssetBalance(_vaultProxy, __parseBalancerPoolAddress(poolId));
    }

    /////////////////////////////
    // PARSE ASSETS FOR ACTION //
    /////////////////////////////

    /// @notice Parses the expected assets to receive from a call on integration
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _selector The function selector for the callOnIntegration
    /// @param _actionData The encoded parameters for the callOnIntegration
    /// @return spendAssetsHandleType_ A type that dictates how to handle granting
    /// the adapter access to spend assets (`None` by default)
    /// @return spendAssets_ The assets to spend in the call
    /// @return spendAssetAmounts_ The max asset amounts to spend in the call
    /// @return incomingAssets_ The assets to receive in the call
    /// @return minIncomingAssetAmounts_ The min asset amounts to receive in the call
    function parseAssetsForAction(
        address _vaultProxy,
        bytes4 _selector,
        bytes calldata _actionData
    )
        public
        view
        override
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        if (_selector == LEND_SELECTOR) {
            return __parseAssetsForLend(_actionData);
        } else if (_selector == REDEEM_SELECTOR) {
            return __parseAssetsForRedeem(_actionData);
        }

        return super.parseAssetsForAction(_vaultProxy, _selector, _actionData);
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during lend() calls
    function __parseAssetsForLend(bytes calldata _encodedCallArgs)
        private
        pure
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        incomingAssets_ = new address[](1);
        minIncomingAssetAmounts_ = new uint256[](1);

        bytes32 poolId;
        IBalancerV2Vault.PoolBalanceChange memory request;
        (
            poolId,
            minIncomingAssetAmounts_[0],
            spendAssets_,
            spendAssetAmounts_,
            request
        ) = __decodeLpActionCallArgs(_encodedCallArgs);

        __validateNoInternalBalances(request.useInternalBalance);

        incomingAssets_[0] = __parseBalancerPoolAddress(poolId);

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during redeem() calls
    function __parseAssetsForRedeem(bytes calldata _encodedCallArgs)
        private
        pure
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        spendAssets_ = new address[](1);
        spendAssetAmounts_ = new uint256[](1);

        bytes32 poolId;
        IBalancerV2Vault.PoolBalanceChange memory request;
        (
            poolId,
            spendAssetAmounts_[0],
            incomingAssets_,
            minIncomingAssetAmounts_,
            request
        ) = __decodeLpActionCallArgs(_encodedCallArgs);

        __validateNoInternalBalances(request.useInternalBalance);

        spendAssets_[0] = __parseBalancerPoolAddress(poolId);

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    //////////////
    // DECODERS //
    //////////////

    /// @dev Helper to decode callArgs for lend and redeem
    function __decodeLpActionCallArgs(bytes memory _encodedCallArgs)
        private
        pure
        returns (
            bytes32 poolId_,
            uint256 bptAmount_,
            address[] memory usedTokens_, // only the assets that will actually be spent/received
            uint256[] memory usedTokenAmounts_, // only the assets that will actually be spent/received
            IBalancerV2Vault.PoolBalanceChange memory request_
        )
    {
        return
            abi.decode(
                _encodedCallArgs,
                (bytes32, uint256, address[], uint256[], IBalancerV2Vault.PoolBalanceChange)
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

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../../../utils/AssetHelpers.sol";
import "../IIntegrationAdapter.sol";
import "./IntegrationSelectors.sol";

/// @title AdapterBase Contract
/// @author Enzyme Council <[email protected]>
/// @notice A base contract for integration adapters
abstract contract AdapterBase is IIntegrationAdapter, IntegrationSelectors, AssetHelpers {
    using SafeERC20 for ERC20;

    address internal immutable INTEGRATION_MANAGER;

    /// @dev Provides a standard implementation for transferring incoming assets
    /// from an adapter to a VaultProxy at the end of an adapter action
    modifier postActionIncomingAssetsTransferHandler(
        address _vaultProxy,
        bytes memory _assetData
    ) {
        _;

        (, , address[] memory incomingAssets) = __decodeAssetData(_assetData);

        __pushFullAssetBalances(_vaultProxy, incomingAssets);
    }

    /// @dev Provides a standard implementation for transferring unspent spend assets
    /// from an adapter to a VaultProxy at the end of an adapter action
    modifier postActionSpendAssetsTransferHandler(address _vaultProxy, bytes memory _assetData) {
        _;

        (address[] memory spendAssets, , ) = __decodeAssetData(_assetData);

        __pushFullAssetBalances(_vaultProxy, spendAssets);
    }

    modifier onlyIntegrationManager() {
        require(
            msg.sender == INTEGRATION_MANAGER,
            "Only the IntegrationManager can call this function"
        );
        _;
    }

    constructor(address _integrationManager) public {
        INTEGRATION_MANAGER = _integrationManager;
    }

    // INTERNAL FUNCTIONS

    /// @dev Helper to decode the _assetData param passed to adapter call
    function __decodeAssetData(bytes memory _assetData)
        internal
        pure
        returns (
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_
        )
    {
        return abi.decode(_assetData, (address[], uint256[], address[]));
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `INTEGRATION_MANAGER` variable
    /// @return integrationManager_ The `INTEGRATION_MANAGER` variable value
    function getIntegrationManager() external view returns (address integrationManager_) {
        return INTEGRATION_MANAGER;
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

/// @title IntegrationSelectors Contract
/// @author Enzyme Council <[email protected]>
/// @notice Selectors for integration actions
/// @dev Selectors are created from their signatures rather than hardcoded for easy verification
abstract contract IntegrationSelectors {
    // Trading
    bytes4 public constant TAKE_MULTIPLE_ORDERS_SELECTOR =
        bytes4(keccak256("takeMultipleOrders(address,bytes,bytes)"));
    bytes4 public constant TAKE_ORDER_SELECTOR =
        bytes4(keccak256("takeOrder(address,bytes,bytes)"));

    // Lending
    bytes4 public constant LEND_SELECTOR = bytes4(keccak256("lend(address,bytes,bytes)"));
    bytes4 public constant REDEEM_SELECTOR = bytes4(keccak256("redeem(address,bytes,bytes)"));

    // Staking
    bytes4 public constant STAKE_SELECTOR = bytes4(keccak256("stake(address,bytes,bytes)"));
    bytes4 public constant UNSTAKE_SELECTOR = bytes4(keccak256("unstake(address,bytes,bytes)"));

    // Rewards
    bytes4 public constant CLAIM_REWARDS_SELECTOR =
        bytes4(keccak256("claimRewards(address,bytes,bytes)"));

    // Combined
    bytes4 public constant LEND_AND_STAKE_SELECTOR =
        bytes4(keccak256("lendAndStake(address,bytes,bytes)"));
    bytes4 public constant UNSTAKE_AND_REDEEM_SELECTOR =
        bytes4(keccak256("unstakeAndRedeem(address,bytes,bytes)"));
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <[email protected]>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../../../../interfaces/IBalancerV2Vault.sol";

/// @title BalancerV2ActionsMixin Contract
/// @author Enzyme Council <[email protected]>
/// @notice Mixin contract for interacting with BalancerV2
abstract contract BalancerV2ActionsMixin {
    IBalancerV2Vault internal immutable BALANCER_VAULT_CONTRACT;

    constructor(address _balancerVault) public {
        BALANCER_VAULT_CONTRACT = IBalancerV2Vault(_balancerVault);
    }

    /// @dev Helper to add liquidity
    function __balancerV2Lend(
        bytes32 _poolId,
        address _sender,
        address _recipient,
        IBalancerV2Vault.PoolBalanceChange memory _request
    ) internal {
        BALANCER_VAULT_CONTRACT.joinPool(_poolId, _sender, _recipient, _request);
    }

    /// @dev Helper to remove liquidity
    function __balancerV2Redeem(
        bytes32 _poolId,
        address _sender,
        address payable _recipient,
        IBalancerV2Vault.PoolBalanceChange memory _request
    ) internal {
        BALANCER_VAULT_CONTRACT.exitPool(_poolId, _sender, _recipient, _request);
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

import "../../../../../interfaces/ICurveLiquidityGaugeV2.sol";
import "../../../../../utils/AssetHelpers.sol";

/// @title CurveGaugeV2ActionsMixin Contract
/// @author Enzyme Council <[email protected]>
/// @notice Mixin contract for interacting with any Curve LiquidityGaugeV2 contract
abstract contract CurveGaugeV2ActionsMixin is AssetHelpers {
    uint256 private constant CURVE_GAUGE_V2_MAX_REWARDS = 8;

    /// @dev Helper to claim pool-specific rewards
    function __curveGaugeV2ClaimRewards(address _gauge, address _target) internal {
        ICurveLiquidityGaugeV2(_gauge).claim_rewards(_target);
    }

    /// @dev Helper to get list of pool-specific rewards tokens
    function __curveGaugeV2GetRewardsTokens(address _gauge)
        internal
        view
        returns (address[] memory rewardsTokens_)
    {
        address[] memory lpRewardsTokensWithEmpties = new address[](CURVE_GAUGE_V2_MAX_REWARDS);
        uint256 rewardsTokensCount;
        for (uint256 i; i < CURVE_GAUGE_V2_MAX_REWARDS; i++) {
            address rewardToken = ICurveLiquidityGaugeV2(_gauge).reward_tokens(i);
            if (rewardToken != address(0)) {
                lpRewardsTokensWithEmpties[i] = rewardToken;
                rewardsTokensCount++;
            } else {
                break;
            }
        }

        rewardsTokens_ = new address[](rewardsTokensCount);
        for (uint256 i; i < rewardsTokensCount; i++) {
            rewardsTokens_[i] = lpRewardsTokensWithEmpties[i];
        }

        return rewardsTokens_;
    }

    /// @dev Helper to stake LP tokens
    function __curveGaugeV2Stake(
        address _gauge,
        address _lpToken,
        uint256 _amount
    ) internal {
        __approveAssetMaxAsNeeded(_lpToken, _gauge, _amount);
        ICurveLiquidityGaugeV2(_gauge).deposit(_amount, address(this));
    }

    /// @dev Helper to unstake LP tokens
    function __curveGaugeV2Unstake(address _gauge, uint256 _amount) internal {
        ICurveLiquidityGaugeV2(_gauge).withdraw(_amount);
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

import "../../../../../interfaces/ICurveMinter.sol";
import "../../../../../utils/AddressArrayLib.sol";
import "./CurveGaugeV2ActionsMixin.sol";

/// @title CurveGaugeV2RewardsHandlerMixin Contract
/// @author Enzyme Council <[email protected]>
/// @notice Mixin contract for handling claiming and reinvesting rewards for a Curve pool
/// that uses the LiquidityGaugeV2 contract
abstract contract CurveGaugeV2RewardsHandlerMixin is CurveGaugeV2ActionsMixin {
    using AddressArrayLib for address[];

    address private immutable CURVE_GAUGE_V2_REWARDS_HANDLER_CRV_TOKEN;
    address private immutable CURVE_GAUGE_V2_REWARDS_HANDLER_MINTER;

    constructor(address _minter, address _crvToken) public {
        CURVE_GAUGE_V2_REWARDS_HANDLER_CRV_TOKEN = _crvToken;
        CURVE_GAUGE_V2_REWARDS_HANDLER_MINTER = _minter;
    }

    /// @dev Helper to claim all rewards (CRV and pool-specific).
    /// Requires contract to be approved to use ICurveMinter.mint_for().
    function __curveGaugeV2ClaimAllRewards(address _gauge, address _target) internal {
        if (__curveGaugeV2MinterExists()) {
            // Claim owed $CRV via Minter (only on Ethereum mainnet)
            ICurveMinter(CURVE_GAUGE_V2_REWARDS_HANDLER_MINTER).mint_for(_gauge, _target);
        }

        // Claim owed pool-specific rewards
        __curveGaugeV2ClaimRewards(_gauge, _target);
    }

    /// @dev Helper to check if the Curve Minter contract is used on the network
    function __curveGaugeV2MinterExists() internal view returns (bool exists_) {
        return CURVE_GAUGE_V2_REWARDS_HANDLER_MINTER != address(0);
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `CURVE_GAUGE_V2_REWARDS_HANDLER_CRV_TOKEN` variable
    /// @return crvToken_ The `CURVE_GAUGE_V2_REWARDS_HANDLER_CRV_TOKEN` variable value
    function getCurveGaugeV2RewardsHandlerCrvToken() public view returns (address crvToken_) {
        return CURVE_GAUGE_V2_REWARDS_HANDLER_CRV_TOKEN;
    }

    /// @notice Gets the `CURVE_GAUGE_V2_REWARDS_HANDLER_MINTER` variable
    /// @return minter_ The `CURVE_GAUGE_V2_REWARDS_HANDLER_MINTER` variable value
    function getCurveGaugeV2RewardsHandlerMinter() public view returns (address minter_) {
        return CURVE_GAUGE_V2_REWARDS_HANDLER_MINTER;
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

import "../../../../../interfaces/IBalancerV2Vault.sol";
import "../../../../../utils/AddressArrayLib.sol";
import "../../utils/actions/BalancerV2ActionsMixin.sol";
import "../../utils/AdapterBase.sol";

/// @title BalancerV2LiquidityAdapterBase Contract
/// @author Enzyme Council <[email protected]>
/// @notice Base adapter for liquidity provision in Balancer V2 pools.
/// Implementing contracts can allow staking via Balancer gauges, Aura, etc.
/// @dev Rewards tokens are not included as incoming assets for claimRewards()
abstract contract BalancerV2LiquidityAdapterBase is AdapterBase, BalancerV2ActionsMixin {
    using AddressArrayLib for address[];

    constructor(address _integrationManager, address _balancerVault)
        public
        AdapterBase(_integrationManager)
        BalancerV2ActionsMixin(_balancerVault)
    {}

    ////////////////////////////////
    // REQUIRED VIRTUAL FUNCTIONS //
    ////////////////////////////////

    /// @dev Logic to claim rewards for a given staking token
    function __claimRewards(address _vaultProxy, address _stakingToken) internal virtual;

    /// @dev Logic to get the BPT address for a given staking token.
    /// Implementations should pre-validate whether the staking token is valid,
    /// when reasonable.
    function __getBptForStakingToken(address _stakingToken)
        internal
        view
        virtual
        returns (address bpt_);

    /// @dev Logic to stake BPT to a given staking token.
    /// Staking is always the last action and thus always sent to the _vaultProxy
    /// (rather than a more generically-named `_recipient`).
    function __stake(
        address _vaultProxy,
        address _stakingToken,
        uint256 _bptAmount
    ) internal virtual;

    /// @dev Logic to unstake BPT from a given staking token
    function __unstake(
        address _vaultProxy,
        address _recipient,
        address _stakingToken,
        uint256 _bptAmount
    ) internal virtual;

    /////////////
    // ACTIONS //
    /////////////

    // EXTERNAL FUNCTIONS

    /// @notice Claims all rewards
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    /// @dev Needs `onlyIntegrationManager` because Minter claiming permission is given by the fund
    function claimRewards(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata
    ) external onlyIntegrationManager {
        __claimRewards(_vaultProxy, __decodeClaimRewardsCallArgs(_actionData));
    }

    /// @notice Lends assets for LP tokens, then stakes the received LP tokens
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    function lendAndStake(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata
    ) external onlyIntegrationManager {
        (
            address stakingToken,
            bytes32 poolId,
            ,
            address[] memory spendAssets,
            uint256[] memory spendAssetAmounts,
            IBalancerV2Vault.PoolBalanceChange memory request
        ) = __decodeCombinedActionCallArgs(_actionData);

        __lend(address(this), poolId, spendAssets, spendAssetAmounts, request);

        __stake(
            _vaultProxy,
            stakingToken,
            ERC20(__parseBalancerPoolAddress(poolId)).balanceOf(address(this))
        );

        // There can be different join/exit options per Balancer pool type,
        // some of which involve spending only up-to-max amounts
        __pushFullAssetBalances(_vaultProxy, spendAssets);
    }

    /// @notice Stakes LP tokens
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    function stake(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata
    ) external onlyIntegrationManager {
        (address stakingToken, uint256 bptAmount) = __decodeStakingActionCallArgs(_actionData);

        __stake(_vaultProxy, stakingToken, bptAmount);
    }

    /// @notice Unstakes LP tokens
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    function unstake(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata
    ) external onlyIntegrationManager {
        (address stakingToken, uint256 bptAmount) = __decodeStakingActionCallArgs(_actionData);

        __unstake(_vaultProxy, _vaultProxy, stakingToken, bptAmount);
    }

    /// @notice Unstakes LP tokens, then redeems them
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    function unstakeAndRedeem(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata
    ) external onlyIntegrationManager {
        (
            address stakingToken,
            bytes32 poolId,
            uint256 bptAmount,
            address[] memory expectedIncomingTokens,
            ,
            IBalancerV2Vault.PoolBalanceChange memory request
        ) = __decodeCombinedActionCallArgs(_actionData);

        __unstake(_vaultProxy, address(this), stakingToken, bptAmount);

        __redeem(_vaultProxy, poolId, bptAmount, expectedIncomingTokens, request);

        // The full amount of unstaked bpt might not be used in a redemption for exact underlyings
        // (with max bpt specified). In that case, re-stake the unused bpt.
        address bpt = __parseBalancerPoolAddress(poolId);
        uint256 remainingBpt = ERC20(bpt).balanceOf(address(this));
        if (remainingBpt > 0) {
            __stake(_vaultProxy, stakingToken, remainingBpt);
        }

        // The full amount of staked bpt will always have been used
    }

    // INTERNAL FUNCTIONS

    /// @dev Helper to perform all logic to LP on Balancer
    function __lend(
        address _recipient,
        bytes32 _poolId,
        address[] memory _spendAssets,
        uint256[] memory _spendAssetAmounts,
        IBalancerV2Vault.PoolBalanceChange memory _request
    ) internal {
        for (uint256 i; i < _spendAssets.length; i++) {
            __approveAssetMaxAsNeeded(
                _spendAssets[i],
                address(BALANCER_VAULT_CONTRACT),
                _spendAssetAmounts[i]
            );
        }

        __balancerV2Lend(_poolId, address(this), _recipient, _request);
    }

    /// @dev Helper to perform all logic to redeem Balancer BPTs
    function __redeem(
        address _vaultProxy,
        bytes32 _poolId,
        uint256 _spendBptAmount,
        address[] memory _expectedIncomingTokens,
        IBalancerV2Vault.PoolBalanceChange memory _request
    ) internal {
        __approveAssetMaxAsNeeded(
            __parseBalancerPoolAddress(_poolId),
            address(BALANCER_VAULT_CONTRACT),
            _spendBptAmount
        );

        // Since we are not parsing request.userData, we do not know with certainty which tokens
        // will be received. We are relying on the user-input _expectedIncomingTokens up to this point.
        // But, to guarantee that no unexpected tokens are received, we need to monitor those balances.
        uint256 unusedTokensCount = _request.assets.length - _expectedIncomingTokens.length;
        uint256[] memory preTxTokenBalancesIfUnused;
        if (unusedTokensCount > 0) {
            preTxTokenBalancesIfUnused = new uint256[](_request.assets.length);
            uint256 remainingCount = unusedTokensCount;
            for (uint256 i; remainingCount > 0; i++) {
                if (!_expectedIncomingTokens.contains(_request.assets[i])) {
                    preTxTokenBalancesIfUnused[i] = ERC20(_request.assets[i]).balanceOf(
                        _vaultProxy
                    );
                    remainingCount--;
                }
            }
        }

        __balancerV2Redeem(_poolId, address(this), payable(_vaultProxy), _request);

        if (unusedTokensCount > 0) {
            for (uint256 i; unusedTokensCount > 0; i++) {
                if (!_expectedIncomingTokens.contains(_request.assets[i])) {
                    require(
                        ERC20(_request.assets[i]).balanceOf(_vaultProxy) ==
                            preTxTokenBalancesIfUnused[i],
                        "__balancerRedeem: Unexpected asset received"
                    );
                    unusedTokensCount--;
                }
            }
        }
    }

    /////////////////////////////
    // PARSE ASSETS FOR METHOD //
    /////////////////////////////

    /// @notice Parses the expected assets to receive from a call on integration
    /// @param _selector The function selector for the callOnIntegration
    /// @param _actionData The encoded parameters for the callOnIntegration
    /// @return spendAssetsHandleType_ A type that dictates how to handle granting
    /// the adapter access to spend assets (`None` by default)
    /// @return spendAssets_ The assets to spend in the call
    /// @return spendAssetAmounts_ The max asset amounts to spend in the call
    /// @return incomingAssets_ The assets to receive in the call
    /// @return minIncomingAssetAmounts_ The min asset amounts to receive in the call
    function parseAssetsForAction(
        address,
        bytes4 _selector,
        bytes calldata _actionData
    )
        public
        view
        virtual
        override
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        if (_selector == CLAIM_REWARDS_SELECTOR) {
            return __parseAssetsForClaimRewards();
        } else if (_selector == LEND_AND_STAKE_SELECTOR) {
            return __parseAssetsForLendAndStake(_actionData);
        } else if (_selector == UNSTAKE_AND_REDEEM_SELECTOR) {
            return __parseAssetsForUnstakeAndRedeem(_actionData);
        } else if (_selector == STAKE_SELECTOR) {
            return __parseAssetsForStake(_actionData);
        } else if (_selector == UNSTAKE_SELECTOR) {
            return __parseAssetsForUnstake(_actionData);
        }

        revert("parseAssetsForAction: _selector invalid");
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during claimRewards() calls.
    /// No action required, all values empty.
    function __parseAssetsForClaimRewards()
        internal
        pure
        virtual
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        return (
            IIntegrationManager.SpendAssetsHandleType.None,
            new address[](0),
            new uint256[](0),
            new address[](0),
            new uint256[](0)
        );
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during lend() calls
    function __parseAssetsForLendAndStake(bytes calldata _encodedCallArgs)
        internal
        view
        virtual
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        incomingAssets_ = new address[](1);
        minIncomingAssetAmounts_ = new uint256[](1);

        bytes32 poolId;
        address stakingToken;
        IBalancerV2Vault.PoolBalanceChange memory request;
        (
            stakingToken,
            poolId,
            minIncomingAssetAmounts_[0],
            spendAssets_,
            spendAssetAmounts_,
            request
        ) = __decodeCombinedActionCallArgs(_encodedCallArgs);

        __validatePoolForStakingToken(stakingToken, poolId);
        __validateNoInternalBalances(request.useInternalBalance);

        incomingAssets_[0] = stakingToken;

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during stake() calls
    function __parseAssetsForStake(bytes calldata _encodedCallArgs)
        internal
        view
        virtual
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        (address stakingToken, uint256 bptAmount) = __decodeStakingActionCallArgs(
            _encodedCallArgs
        );

        spendAssets_ = new address[](1);
        spendAssetAmounts_ = new uint256[](1);
        incomingAssets_ = new address[](1);
        minIncomingAssetAmounts_ = new uint256[](1);

        spendAssets_[0] = __getBptForStakingToken(stakingToken);
        spendAssetAmounts_[0] = bptAmount;

        incomingAssets_[0] = stakingToken;
        minIncomingAssetAmounts_[0] = bptAmount;

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during unstake() calls
    function __parseAssetsForUnstake(bytes calldata _encodedCallArgs)
        internal
        view
        virtual
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        (address stakingToken, uint256 bptAmount) = __decodeStakingActionCallArgs(
            _encodedCallArgs
        );

        spendAssets_ = new address[](1);
        spendAssetAmounts_ = new uint256[](1);
        incomingAssets_ = new address[](1);
        minIncomingAssetAmounts_ = new uint256[](1);

        spendAssets_[0] = stakingToken;
        spendAssetAmounts_[0] = bptAmount;

        incomingAssets_[0] = __getBptForStakingToken(stakingToken);
        minIncomingAssetAmounts_[0] = bptAmount;

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during unstakeAndRedeem() calls
    function __parseAssetsForUnstakeAndRedeem(bytes calldata _encodedCallArgs)
        internal
        view
        virtual
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        spendAssets_ = new address[](1);
        spendAssetAmounts_ = new uint256[](1);

        bytes32 poolId;
        address stakingToken;
        IBalancerV2Vault.PoolBalanceChange memory request;
        (
            stakingToken,
            poolId,
            spendAssetAmounts_[0],
            incomingAssets_,
            minIncomingAssetAmounts_,
            request
        ) = __decodeCombinedActionCallArgs(_encodedCallArgs);

        __validatePoolForStakingToken(stakingToken, poolId);
        __validateNoInternalBalances(request.useInternalBalance);

        spendAssets_[0] = stakingToken;

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @dev Helper to get a Balancer pool address (i.e., Balancer Pool Token) for a given id.
    /// See: https://github.com/balancer-labs/balancer-v2-monorepo/blob/42906226223f29e4489975eb3c0d5014dea83b66/pkg/vault/contracts/PoolRegistry.sol#L130-L139
    function __parseBalancerPoolAddress(bytes32 _poolId)
        internal
        pure
        returns (address poolAddress_)
    {
        return address(uint256(_poolId) >> (12 * 8));
    }

    /// @dev Helper to validate a given poolId for a given staking token.
    /// Does not validate the staking token itself, unless handled in the implementing contract
    /// during __getBptForStakingToken().
    function __validatePoolForStakingToken(address _stakingToken, bytes32 _poolId) internal view {
        require(
            __getBptForStakingToken(_stakingToken) == __parseBalancerPoolAddress(_poolId),
            "__validateBptForStakingToken: Invalid"
        );
    }

    /// @dev Helper to validate Balancer internal balances are not used
    function __validateNoInternalBalances(bool _useInternalBalances) internal pure {
        require(!_useInternalBalances, "__validateNoInternalBalances: Invalid");
    }

    //////////////
    // DECODERS //
    //////////////

    /// @dev Helper to decode callArgs for lend and redeem
    function __decodeCombinedActionCallArgs(bytes memory _encodedCallArgs)
        internal
        pure
        returns (
            address stakingToken_,
            bytes32 poolId_,
            uint256 bptAmount_,
            address[] memory usedTokens_, // only the assets that will actually be spent/received
            uint256[] memory usedTokenAmounts_, // only the assets that will actually be spent/received
            IBalancerV2Vault.PoolBalanceChange memory request_
        )
    {
        return
            abi.decode(
                _encodedCallArgs,
                (
                    address,
                    bytes32,
                    uint256,
                    address[],
                    uint256[],
                    IBalancerV2Vault.PoolBalanceChange
                )
            );
    }

    /// @dev Helper to decode the encoded call arguments for claiming rewards
    function __decodeClaimRewardsCallArgs(bytes memory _actionData)
        internal
        pure
        returns (address stakingToken_)
    {
        return abi.decode(_actionData, (address));
    }

    /// @dev Helper to decode callArgs for stake and unstake
    function __decodeStakingActionCallArgs(bytes memory _encodedCallArgs)
        internal
        pure
        returns (address stakingToken_, uint256 bptAmount_)
    {
        return abi.decode(_encodedCallArgs, (address, uint256));
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

/// @title IBalancerV2LiquidityGauge interface
/// @author Enzyme Council <[email protected]>
/// @dev Applies to both LiquidityGauge (L1) and ChildChainLiquidityGauge (L2/sidechains)
interface IBalancerV2LiquidityGauge {
    function lp_token() external view returns (address lpToken_);
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

/// @title IBalancerV2Vault interface
/// @author Enzyme Council <[email protected]>
interface IBalancerV2Vault {
    // JoinPoolRequest and ExitPoolRequest are just differently labeled versions of PoolBalanceChange.
    // See: https://github.com/balancer-labs/balancer-v2-monorepo/blob/42906226223f29e4489975eb3c0d5014dea83b66/pkg/vault/contracts/PoolBalances.sol#L70
    struct PoolBalanceChange {
        address[] assets;
        uint256[] limits;
        bytes userData;
        bool useInternalBalance;
    }

    function exitPool(
        bytes32 _poolId,
        address _sender,
        address payable _recipient,
        PoolBalanceChange memory _request
    ) external;

    function getPoolTokens(bytes32 _poolId)
        external
        view
        returns (
            address[] memory tokens_,
            uint256[] memory balances_,
            uint256 lastChangeBlock_
        );

    function joinPool(
        bytes32 _poolId,
        address _sender,
        address _recipient,
        PoolBalanceChange memory _request
    ) external payable;

    function setRelayerApproval(
        address _sender,
        address _relayer,
        bool _approved
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

/// @title ICurveLiquidityGaugeV2 interface
/// @author Enzyme Council <[email protected]>
interface ICurveLiquidityGaugeV2 {
    function claim_rewards(address) external;

    function deposit(uint256, address) external;

    function reward_tokens(uint256) external view returns (address);

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

/// @title ICurveMinter interface
/// @author Enzyme Council <[email protected]>
interface ICurveMinter {
    function mint_for(address, address) external;
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