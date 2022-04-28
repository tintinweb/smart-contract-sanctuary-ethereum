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
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
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

/// @title IFundDeployer Interface
/// @author Enzyme Council <[email protected]>
interface IFundDeployer {
    function getOwner() external view returns (address);

    function hasReconfigurationRequest(address) external view returns (bool);

    function isAllowedBuySharesOnBehalfCaller(address) external view returns (bool);

    function isAllowedVaultCall(
        address,
        bytes4,
        bytes32
    ) external view returns (bool);
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
    enum SpendAssetsHandleType {None, Approve, Transfer}
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
pragma solidity 0.6.12;

import "../../../../infrastructure/price-feeds/derivatives/feeds/CurvePriceFeed.sol";
import "../utils/actions/CurveGaugeV2RewardsHandlerMixin.sol";
import "../utils/bases/CurveLiquidityAdapterBase.sol";

/// @title CurveLiquidityAdapter Contract
/// @author Enzyme Council <[email protected]>
/// @notice Adapter for liquidity provision in Curve pools that adhere to pool templates,
/// as well as some old pools that have almost the same required interface (e.g., 3pool).
/// Allows staking via Curve gauges.
/// @dev Rewards tokens are not included as incoming assets for claimRewards()
/// Rationale:
/// - rewards tokens can be claimed to the vault outside of the IntegrationManager, so no need
/// to enforce policy management or emit an event
/// - rewards tokens can be outside of the asset universe, in which case they cannot be tracked
contract CurveLiquidityAdapter is CurveLiquidityAdapterBase, CurveGaugeV2RewardsHandlerMixin {
    CurvePriceFeed private immutable CURVE_PRICE_FEED_CONTRACT;

    constructor(
        address _integrationManager,
        address _curvePriceFeed,
        address _wrappedNativeAsset,
        address _curveMinter,
        address _crvToken,
        address _nativeAssetAddress
    )
        public
        CurveLiquidityAdapterBase(_integrationManager, _wrappedNativeAsset, _nativeAssetAddress)
        CurveGaugeV2RewardsHandlerMixin(_curveMinter, _crvToken)
    {
        CURVE_PRICE_FEED_CONTRACT = CurvePriceFeed(_curvePriceFeed);
    }

    // EXTERNAL FUNCTIONS

    /// @notice Claims rewards from the Curve Minter as well as pool-specific rewards
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    /// @dev Pool must have an ERC20 liquidity gauge (e.g., v2, v3, v4) or an ERC20 wrapper (e.g., v1)
    function claimRewards(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata
    ) external onlyIntegrationManager {
        __curveGaugeV2ClaimAllRewards(__decodeClaimRewardsCallArgs(_actionData), _vaultProxy);
    }

    /// @notice Lends assets for LP tokens (not staked)
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    /// @param _assetData Parsed spend assets and incoming assets data for this action
    function lend(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata _assetData
    )
        external
        onlyIntegrationManager
        postActionIncomingAssetsTransferHandler(_vaultProxy, _assetData)
    {
        (
            address pool,
            uint256[] memory orderedOutgoingAssetAmounts,
            uint256 minIncomingLpTokenAmount,
            bool useUnderlyings
        ) = __decodeLendCallArgs(_actionData);
        (address[] memory spendAssets, , ) = __decodeAssetData(_assetData);

        __curveAddLiquidity(
            pool,
            spendAssets,
            orderedOutgoingAssetAmounts,
            minIncomingLpTokenAmount,
            useUnderlyings
        );
    }

    /// @notice Lends assets for LP tokens, then stakes the received LP tokens
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    /// @param _assetData Parsed spend assets and incoming assets data for this action
    function lendAndStake(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata _assetData
    )
        external
        onlyIntegrationManager
        postActionIncomingAssetsTransferHandler(_vaultProxy, _assetData)
    {
        (
            address pool,
            uint256[] memory orderedOutgoingAssetAmounts,
            address incomingStakingToken,
            uint256 minIncomingStakingTokenAmount,
            bool useUnderlyings
        ) = __decodeLendAndStakeCallArgs(_actionData);
        (address[] memory spendAssets, , ) = __decodeAssetData(_assetData);

        address lpToken = CURVE_PRICE_FEED_CONTRACT.getLpTokenForPool(pool);

        __curveAddLiquidity(
            pool,
            spendAssets,
            orderedOutgoingAssetAmounts,
            minIncomingStakingTokenAmount,
            useUnderlyings
        );

        __curveGaugeV2Stake(
            incomingStakingToken,
            lpToken,
            ERC20(lpToken).balanceOf(address(this))
        );
    }

    /// @notice Redeems LP tokens
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    /// @param _assetData Parsed spend assets and incoming assets data for this action
    function redeem(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata _assetData
    )
        external
        onlyIntegrationManager
        postActionIncomingAssetsTransferHandler(_vaultProxy, _assetData)
    {
        (
            address pool,
            uint256 outgoingLpTokenAmount,
            bool useUnderlyings,
            RedeemType redeemType,
            bytes memory incomingAssetsData
        ) = __decodeRedeemCallArgs(_actionData);

        __curveRedeem(pool, outgoingLpTokenAmount, useUnderlyings, redeemType, incomingAssetsData);
    }

    /// @notice Stakes LP tokens
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _assetData Parsed spend assets and incoming assets data for this action
    function stake(
        address _vaultProxy,
        bytes calldata,
        bytes calldata _assetData
    )
        external
        onlyIntegrationManager
        postActionIncomingAssetsTransferHandler(_vaultProxy, _assetData)
    {
        (
            address[] memory spendAssets,
            uint256[] memory spendAssetAmounts,
            address[] memory incomingAssets
        ) = __decodeAssetData(_assetData);

        __curveGaugeV2Stake(incomingAssets[0], spendAssets[0], spendAssetAmounts[0]);
    }

    /// @notice Unstakes LP tokens
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    /// @param _assetData Parsed spend assets and incoming assets data for this action
    function unstake(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata _assetData
    )
        external
        onlyIntegrationManager
        postActionIncomingAssetsTransferHandler(_vaultProxy, _assetData)
    {
        (, address outgoingStakingToken, uint256 amount) = __decodeUnstakeCallArgs(_actionData);

        __curveGaugeV2Unstake(outgoingStakingToken, amount);
    }

    /// @notice Unstakes LP tokens, then redeems them
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    /// @param _assetData Parsed spend assets and incoming assets data for this action
    function unstakeAndRedeem(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata _assetData
    )
        external
        onlyIntegrationManager
        postActionIncomingAssetsTransferHandler(_vaultProxy, _assetData)
    {
        (
            address pool,
            address outgoingStakingToken,
            uint256 outgoingStakingTokenAmount,
            bool useUnderlyings,
            RedeemType redeemType,
            bytes memory incomingAssetsData
        ) = __decodeUnstakeAndRedeemCallArgs(_actionData);

        __curveGaugeV2Unstake(outgoingStakingToken, outgoingStakingTokenAmount);

        __curveRedeem(
            pool,
            outgoingStakingTokenAmount,
            useUnderlyings,
            redeemType,
            incomingAssetsData
        );
    }

    /////////////////////////////
    // PARSE ASSETS FOR METHOD //
    /////////////////////////////

    /// @notice Parses the expected assets in a particular action
    /// @param _selector The function selector for the callOnIntegration
    /// @param _actionData Data specific to this action
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
        external
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
        if (_selector == CLAIM_REWARDS_SELECTOR) {
            return __parseAssetsForClaimRewards();
        } else if (_selector == LEND_SELECTOR) {
            return __parseAssetsForLend(_actionData);
        } else if (_selector == LEND_AND_STAKE_SELECTOR) {
            return __parseAssetsForLendAndStake(_actionData);
        } else if (_selector == REDEEM_SELECTOR) {
            return __parseAssetsForRedeem(_actionData);
        } else if (_selector == STAKE_SELECTOR) {
            return __parseAssetsForStake(_actionData);
        } else if (_selector == UNSTAKE_SELECTOR) {
            return __parseAssetsForUnstake(_actionData);
        } else if (_selector == UNSTAKE_AND_REDEEM_SELECTOR) {
            return __parseAssetsForUnstakeAndRedeem(_actionData);
        }

        revert("parseAssetsForAction: _selector invalid");
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during claimRewards() calls.
    /// No action required, all values empty.
    function __parseAssetsForClaimRewards()
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
    function __parseAssetsForLend(bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        (
            address pool,
            uint256[] memory orderedOutgoingAssetAmounts,
            uint256 minIncomingLpTokenAmount,
            bool useUnderlyings
        ) = __decodeLendCallArgs(_actionData);

        incomingAssets_ = new address[](1);
        incomingAssets_[0] = CURVE_PRICE_FEED_CONTRACT.getLpTokenForPool(pool);

        minIncomingAssetAmounts_ = new uint256[](1);
        minIncomingAssetAmounts_[0] = minIncomingLpTokenAmount;

        (spendAssets_, spendAssetAmounts_) = __parseSpendAssetsForLendingCalls(
            pool,
            orderedOutgoingAssetAmounts,
            useUnderlyings
        );

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during lendAndStake() calls
    function __parseAssetsForLendAndStake(bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        (
            address pool,
            uint256[] memory orderedOutgoingAssetAmounts,
            address incomingStakingToken,
            uint256 minIncomingStakingTokenAmount,
            bool useUnderlyings
        ) = __decodeLendAndStakeCallArgs(_actionData);

        __validatePoolForGauge(pool, incomingStakingToken);

        (spendAssets_, spendAssetAmounts_) = __parseSpendAssetsForLendingCalls(
            pool,
            orderedOutgoingAssetAmounts,
            useUnderlyings
        );

        incomingAssets_ = new address[](1);
        incomingAssets_[0] = incomingStakingToken;

        minIncomingAssetAmounts_ = new uint256[](1);
        minIncomingAssetAmounts_[0] = minIncomingStakingTokenAmount;

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
    function __parseAssetsForRedeem(bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        (
            address pool,
            uint256 outgoingLpTokenAmount,
            bool useUnderlyings,
            RedeemType redeemType,
            bytes memory incomingAssetsData
        ) = __decodeRedeemCallArgs(_actionData);

        spendAssets_ = new address[](1);
        spendAssets_[0] = CURVE_PRICE_FEED_CONTRACT.getLpTokenForPool(pool);

        spendAssetAmounts_ = new uint256[](1);
        spendAssetAmounts_[0] = outgoingLpTokenAmount;

        (incomingAssets_, minIncomingAssetAmounts_) = __parseIncomingAssetsForRedemptionCalls(
            pool,
            useUnderlyings,
            redeemType,
            incomingAssetsData
        );

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
    function __parseAssetsForStake(bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        (address pool, address incomingStakingToken, uint256 amount) = __decodeStakeCallArgs(
            _actionData
        );

        __validatePoolForGauge(pool, incomingStakingToken);

        spendAssets_ = new address[](1);
        spendAssets_[0] = CURVE_PRICE_FEED_CONTRACT.getLpTokenForPool(pool);

        spendAssetAmounts_ = new uint256[](1);
        spendAssetAmounts_[0] = amount;

        incomingAssets_ = new address[](1);
        incomingAssets_[0] = incomingStakingToken;

        minIncomingAssetAmounts_ = new uint256[](1);
        minIncomingAssetAmounts_[0] = amount;

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
    function __parseAssetsForUnstake(bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        (address pool, address outgoingStakingToken, uint256 amount) = __decodeUnstakeCallArgs(
            _actionData
        );

        __validatePoolForGauge(pool, outgoingStakingToken);

        spendAssets_ = new address[](1);
        spendAssets_[0] = outgoingStakingToken;

        spendAssetAmounts_ = new uint256[](1);
        spendAssetAmounts_[0] = amount;

        incomingAssets_ = new address[](1);
        incomingAssets_[0] = CURVE_PRICE_FEED_CONTRACT.getLpTokenForPool(pool);

        minIncomingAssetAmounts_ = new uint256[](1);
        minIncomingAssetAmounts_[0] = amount;

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
    function __parseAssetsForUnstakeAndRedeem(bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        (
            address pool,
            address outgoingStakingToken,
            uint256 outgoingStakingTokenAmount,
            bool useUnderlyings,
            RedeemType redeemType,
            bytes memory incomingAssetsData
        ) = __decodeUnstakeAndRedeemCallArgs(_actionData);

        __validatePoolForGauge(pool, outgoingStakingToken);

        spendAssets_ = new address[](1);
        spendAssets_[0] = outgoingStakingToken;

        spendAssetAmounts_ = new uint256[](1);
        spendAssetAmounts_[0] = outgoingStakingTokenAmount;

        (incomingAssets_, minIncomingAssetAmounts_) = __parseIncomingAssetsForRedemptionCalls(
            pool,
            useUnderlyings,
            redeemType,
            incomingAssetsData
        );

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @dev Helper to validate that a gauge belongs to a given pool
    function __validatePoolForGauge(address _pool, address _gauge) private view {
        require(
            CURVE_PRICE_FEED_CONTRACT.getPoolForDerivative(_gauge) == _pool,
            "__validateGauge: Invalid"
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

    modifier onlyIntegrationManager {
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
    bytes4 public constant TAKE_ORDER_SELECTOR = bytes4(
        keccak256("takeOrder(address,bytes,bytes)")
    );

    // Lending
    bytes4 public constant LEND_SELECTOR = bytes4(keccak256("lend(address,bytes,bytes)"));
    bytes4 public constant REDEEM_SELECTOR = bytes4(keccak256("redeem(address,bytes,bytes)"));

    // Staking
    bytes4 public constant STAKE_SELECTOR = bytes4(keccak256("stake(address,bytes,bytes)"));
    bytes4 public constant UNSTAKE_SELECTOR = bytes4(keccak256("unstake(address,bytes,bytes)"));

    // Rewards
    bytes4 public constant CLAIM_REWARDS_SELECTOR = bytes4(
        keccak256("claimRewards(address,bytes,bytes)")
    );

    // Combined
    bytes4 public constant LEND_AND_STAKE_SELECTOR = bytes4(
        keccak256("lendAndStake(address,bytes,bytes)")
    );
    bytes4 public constant UNSTAKE_AND_REDEEM_SELECTOR = bytes4(
        keccak256("unstakeAndRedeem(address,bytes,bytes)")
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

import "@openzeppelin/contracts/utils/Strings.sol";
import "../../../../../interfaces/IWETH.sol";
import "../../../../../utils/AssetHelpers.sol";

/// @title CurveLiquidityActionsMixin Contract
/// @author Enzyme Council <[email protected]>
/// @notice Mixin contract for interacting with the Curve pool liquidity functions
/// @dev Inheriting contract must have a receive() function if lending or redeeming for the native asset
abstract contract CurveLiquidityActionsMixin is AssetHelpers {
    using Strings for uint256;

    uint256 private constant ASSET_APPROVAL_TOP_UP_THRESHOLD = 1e76; // Arbitrary, slightly less than 1/11 of max uint256

    bytes4 private constant CURVE_REMOVE_LIQUIDITY_ONE_COIN_SELECTOR = 0x1a4d01d2;
    bytes4 private constant CURVE_REMOVE_LIQUIDITY_ONE_COIN_USE_UNDERLYINGS_SELECTOR = 0x517a55a3;

    address private immutable CURVE_LIQUIDITY_WRAPPED_NATIVE_ASSET;

    constructor(address _wrappedNativeAsset) public {
        CURVE_LIQUIDITY_WRAPPED_NATIVE_ASSET = _wrappedNativeAsset;
    }

    /// @dev Helper to add liquidity to the pool.
    /// _squashedOutgoingAssets are only those pool assets that are actually used to add liquidity,
    /// which can be verbose and ordered, but it is more gas-efficient to only include non-0 amounts.
    function __curveAddLiquidity(
        address _pool,
        address[] memory _squashedOutgoingAssets,
        uint256[] memory _orderedOutgoingAssetAmounts,
        uint256 _minIncomingLpTokenAmount,
        bool _useUnderlyings
    ) internal {
        // Approve and/or unwrap native asset as necessary.
        // Rather than using exact amounts for approvals,
        // this tops up to max approval if 1/2 max is reached.
        uint256 outgoingNativeAssetAmount;
        for (uint256 i; i < _squashedOutgoingAssets.length; i++) {
            if (_squashedOutgoingAssets[i] == getCurveLiquidityWrappedNativeAsset()) {
                // It is never the case that a pool has multiple slots for the same native asset,
                // so this is not additive
                outgoingNativeAssetAmount = ERC20(getCurveLiquidityWrappedNativeAsset()).balanceOf(
                    address(this)
                );
                IWETH(getCurveLiquidityWrappedNativeAsset()).withdraw(outgoingNativeAssetAmount);
            } else {
                // Once an asset it approved for a given pool, it will almost definitely
                // never need approval again, but it is topped up to max once an arbitrary
                // threshold is reached
                __approveAssetMaxAsNeeded(
                    _squashedOutgoingAssets[i],
                    _pool,
                    ASSET_APPROVAL_TOP_UP_THRESHOLD
                );
            }
        }

        // Dynamically call the appropriate selector
        (bool success, bytes memory returnData) = _pool.call{value: outgoingNativeAssetAmount}(
            __curveAddLiquidityEncodeCalldata(
                _orderedOutgoingAssetAmounts,
                _minIncomingLpTokenAmount,
                _useUnderlyings
            )
        );
        require(success, string(returnData));
    }

    /// @dev Helper to remove liquidity from the pool.
    /// if using _redeemSingleAsset, must pre-validate that one - and only one - asset
    /// has a non-zero _orderedMinIncomingAssetAmounts value.
    function __curveRemoveLiquidity(
        address _pool,
        uint256 _outgoingLpTokenAmount,
        uint256[] memory _orderedMinIncomingAssetAmounts,
        bool _useUnderlyings
    ) internal {
        // Dynamically call the appropriate selector
        (bool success, bytes memory returnData) = _pool.call(
            __curveRemoveLiquidityEncodeCalldata(
                _outgoingLpTokenAmount,
                _orderedMinIncomingAssetAmounts,
                _useUnderlyings
            )
        );
        require(success, string(returnData));

        // Wrap native asset
        __curveLiquidityWrapNativeAssetBalance();
    }

    /// @dev Helper to remove liquidity from the pool and receive all value owed in one specified token
    function __curveRemoveLiquidityOneCoin(
        address _pool,
        uint256 _outgoingLpTokenAmount,
        int128 _incomingAssetPoolIndex,
        uint256 _minIncomingAssetAmount,
        bool _useUnderlyings
    ) internal {
        bytes memory callData;
        if (_useUnderlyings) {
            callData = abi.encodeWithSelector(
                CURVE_REMOVE_LIQUIDITY_ONE_COIN_USE_UNDERLYINGS_SELECTOR,
                _outgoingLpTokenAmount,
                _incomingAssetPoolIndex,
                _minIncomingAssetAmount,
                true
            );
        } else {
            callData = abi.encodeWithSelector(
                CURVE_REMOVE_LIQUIDITY_ONE_COIN_SELECTOR,
                _outgoingLpTokenAmount,
                _incomingAssetPoolIndex,
                _minIncomingAssetAmount
            );
        }

        // Dynamically call the appropriate selector
        (bool success, bytes memory returnData) = _pool.call(callData);
        require(success, string(returnData));

        // Wrap native asset
        __curveLiquidityWrapNativeAssetBalance();
    }

    // PRIVATE FUNCTIONS

    /// @dev Helper to encode calldata for a call to add liquidity on Curve
    function __curveAddLiquidityEncodeCalldata(
        uint256[] memory _orderedOutgoingAssetAmounts,
        uint256 _minIncomingLpTokenAmount,
        bool _useUnderlyings
    ) private pure returns (bytes memory callData_) {
        bytes memory finalEncodedArgOrEmpty;
        if (_useUnderlyings) {
            finalEncodedArgOrEmpty = abi.encode(true);
        }

        return
            abi.encodePacked(
                __curveAddLiquidityEncodeSelector(
                    _orderedOutgoingAssetAmounts.length,
                    _useUnderlyings
                ),
                abi.encodePacked(_orderedOutgoingAssetAmounts),
                _minIncomingLpTokenAmount,
                finalEncodedArgOrEmpty
            );
    }

    /// @dev Helper to encode selector for a call to add liquidity on Curve
    function __curveAddLiquidityEncodeSelector(uint256 _numberOfCoins, bool _useUnderlyings)
        private
        pure
        returns (bytes4 selector_)
    {
        string memory finalArgOrEmpty;
        if (_useUnderlyings) {
            finalArgOrEmpty = ",bool";
        }

        return
            bytes4(
                keccak256(
                    abi.encodePacked(
                        "add_liquidity(uint256[",
                        _numberOfCoins.toString(),
                        "],",
                        "uint256",
                        finalArgOrEmpty,
                        ")"
                    )
                )
            );
    }

    /// @dev Helper to wrap the full native asset balance of the current contract
    function __curveLiquidityWrapNativeAssetBalance() private {
        uint256 nativeAssetBalance = payable(address(this)).balance;
        if (nativeAssetBalance > 0) {
            IWETH(payable(getCurveLiquidityWrappedNativeAsset())).deposit{
                value: nativeAssetBalance
            }();
        }
    }

    /// @dev Helper to encode calldata for a call to remove liquidity from Curve
    function __curveRemoveLiquidityEncodeCalldata(
        uint256 _outgoingLpTokenAmount,
        uint256[] memory _orderedMinIncomingAssetAmounts,
        bool _useUnderlyings
    ) private pure returns (bytes memory callData_) {
        bytes memory finalEncodedArgOrEmpty;
        if (_useUnderlyings) {
            finalEncodedArgOrEmpty = abi.encode(true);
        }

        return
            abi.encodePacked(
                __curveRemoveLiquidityEncodeSelector(
                    _orderedMinIncomingAssetAmounts.length,
                    _useUnderlyings
                ),
                _outgoingLpTokenAmount,
                abi.encodePacked(_orderedMinIncomingAssetAmounts),
                finalEncodedArgOrEmpty
            );
    }

    /// @dev Helper to encode selector for a call to remove liquidity on Curve
    function __curveRemoveLiquidityEncodeSelector(uint256 _numberOfCoins, bool _useUnderlyings)
        private
        pure
        returns (bytes4 selector_)
    {
        string memory finalArgOrEmpty;
        if (_useUnderlyings) {
            finalArgOrEmpty = ",bool";
        }

        return
            bytes4(
                keccak256(
                    abi.encodePacked(
                        "remove_liquidity(uint256,",
                        "uint256[",
                        _numberOfCoins.toString(),
                        "]",
                        finalArgOrEmpty,
                        ")"
                    )
                )
            );
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `CURVE_LIQUIDITY_WRAPPED_NATIVE_ASSET` variable
    /// @return addressProvider_ The `CURVE_LIQUIDITY_WRAPPED_NATIVE_ASSET` variable value
    function getCurveLiquidityWrappedNativeAsset() public view returns (address addressProvider_) {
        return CURVE_LIQUIDITY_WRAPPED_NATIVE_ASSET;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "../../../../../interfaces/ICurveLiquidityPool.sol";
import "../actions/CurveLiquidityActionsMixin.sol";
import "../AdapterBase.sol";

/// @title CurveLiquidityAdapterBase Contract
/// @author Enzyme Council <[email protected]>
/// @notice Base adapter for liquidity provision in Curve pools that adhere to pool templates,
/// as well as some old pools that have almost the same required interface (e.g., 3pool).
/// Implementing contracts can allow staking via Curve gauges, Convex, etc.
abstract contract CurveLiquidityAdapterBase is AdapterBase, CurveLiquidityActionsMixin {
    enum RedeemType {Standard, OneCoin}

    address private immutable CURVE_LIQUIDITY_NATIVE_ASSET_ADDRESS;

    constructor(
        address _integrationManager,
        address _wrappedNativeAsset,
        address _nativeAssetAddress
    ) public AdapterBase(_integrationManager) CurveLiquidityActionsMixin(_wrappedNativeAsset) {
        CURVE_LIQUIDITY_NATIVE_ASSET_ADDRESS = _nativeAssetAddress;
    }

    /// @dev Needed to unwrap and receive the native asset
    receive() external payable {}

    // INTERNAL FUNCTIONS

    /// @dev Helper to return the wrappedNativeAsset if the input is the native asset
    function __castWrappedIfNativeAsset(address _tokenOrNativeAsset)
        internal
        view
        returns (address token_)
    {
        if (_tokenOrNativeAsset == CURVE_LIQUIDITY_NATIVE_ASSET_ADDRESS) {
            return getCurveLiquidityWrappedNativeAsset();
        }

        return _tokenOrNativeAsset;
    }

    /// @dev Helper to correctly call the relevant redeem function based on RedeemType
    function __curveRedeem(
        address _pool,
        uint256 _outgoingLpTokenAmount,
        bool _useUnderlyings,
        RedeemType _redeemType,
        bytes memory _incomingAssetsData
    ) internal {
        if (_redeemType == RedeemType.OneCoin) {
            (
                uint256 incomingAssetPoolIndex,
                uint256 minIncomingAssetAmount
            ) = __decodeIncomingAssetsDataRedeemOneCoin(_incomingAssetsData);

            __curveRemoveLiquidityOneCoin(
                _pool,
                _outgoingLpTokenAmount,
                int128(incomingAssetPoolIndex),
                minIncomingAssetAmount,
                _useUnderlyings
            );
        } else {
            __curveRemoveLiquidity(
                _pool,
                _outgoingLpTokenAmount,
                __decodeIncomingAssetsDataRedeemStandard(_incomingAssetsData),
                _useUnderlyings
            );
        }
    }

    /// @dev Helper function to parse spend assets for redeem() and unstakeAndRedeem() calls
    function __parseIncomingAssetsForRedemptionCalls(
        address _pool,
        bool _useUnderlyings,
        RedeemType _redeemType,
        bytes memory _incomingAssetsData
    )
        internal
        view
        returns (address[] memory incomingAssets_, uint256[] memory minIncomingAssetAmounts_)
    {
        if (_redeemType == RedeemType.OneCoin) {
            (
                uint256 incomingAssetPoolIndex,
                uint256 minIncomingAssetAmount
            ) = __decodeIncomingAssetsDataRedeemOneCoin(_incomingAssetsData);

            // No need to validate incomingAssetPoolIndex,
            // as an out-of-bounds index will fail in the call to Curve
            incomingAssets_ = new address[](1);
            incomingAssets_[0] = __getPoolAsset(_pool, incomingAssetPoolIndex, _useUnderlyings);

            minIncomingAssetAmounts_ = new uint256[](1);
            minIncomingAssetAmounts_[0] = minIncomingAssetAmount;
        } else {
            minIncomingAssetAmounts_ = __decodeIncomingAssetsDataRedeemStandard(
                _incomingAssetsData
            );

            // No need to validate minIncomingAssetAmounts_.length,
            // as an incorrect length will fail with the wrong n_tokens in the call to Curve
            incomingAssets_ = new address[](minIncomingAssetAmounts_.length);
            for (uint256 i; i < incomingAssets_.length; i++) {
                incomingAssets_[i] = __getPoolAsset(_pool, i, _useUnderlyings);
            }
        }

        return (incomingAssets_, minIncomingAssetAmounts_);
    }

    /// @dev Helper function to parse spend assets for lend() and lendAndStake() calls
    function __parseSpendAssetsForLendingCalls(
        address _pool,
        uint256[] memory _orderedOutgoingAssetAmounts,
        bool _useUnderlyings
    ) internal view returns (address[] memory spendAssets_, uint256[] memory spendAssetAmounts_) {
        uint256 spendAssetsCount;
        for (uint256 i; i < _orderedOutgoingAssetAmounts.length; i++) {
            if (_orderedOutgoingAssetAmounts[i] > 0) {
                spendAssetsCount++;
            }
        }

        spendAssets_ = new address[](spendAssetsCount);
        spendAssetAmounts_ = new uint256[](spendAssetsCount);
        uint256 spendAssetsIndex;
        for (uint256 i; i < _orderedOutgoingAssetAmounts.length; i++) {
            if (_orderedOutgoingAssetAmounts[i] > 0) {
                spendAssets_[spendAssetsIndex] = __getPoolAsset(_pool, i, _useUnderlyings);
                spendAssetAmounts_[spendAssetsIndex] = _orderedOutgoingAssetAmounts[i];
                spendAssetsIndex++;

                if (spendAssetsIndex == spendAssetsCount) {
                    break;
                }
            }
        }

        return (spendAssets_, spendAssetAmounts_);
    }

    /// @dev Helper to get a pool asset at a given index
    function __getPoolAsset(
        address _pool,
        uint256 _index,
        bool _useUnderlying
    ) internal view returns (address asset_) {
        if (_useUnderlying) {
            try ICurveLiquidityPool(_pool).underlying_coins(_index) returns (
                address underlyingCoin
            ) {
                asset_ = underlyingCoin;
            } catch {
                asset_ = ICurveLiquidityPool(_pool).underlying_coins(int128(_index));
            }
        } else {
            try ICurveLiquidityPool(_pool).coins(_index) returns (address coin) {
                asset_ = coin;
            } catch {
                asset_ = ICurveLiquidityPool(_pool).coins(int128(_index));
            }
        }

        return __castWrappedIfNativeAsset(asset_);
    }

    ///////////////////////
    // ENCODED CALL ARGS //
    ///////////////////////

    // Some of these decodings are not relevant to inheriting contracts,
    // and some parameters will be ignored, but this keeps the payloads
    // consistent for all inheriting adapters.

    /// @dev Helper to decode the encoded call arguments for claiming rewards
    function __decodeClaimRewardsCallArgs(bytes memory _actionData)
        internal
        pure
        returns (address stakingToken_)
    {
        return abi.decode(_actionData, (address));
    }

    /// @dev Helper to decode the encoded call arguments for lending and then staking
    function __decodeLendAndStakeCallArgs(bytes memory _actionData)
        internal
        pure
        returns (
            address pool_,
            uint256[] memory orderedOutgoingAssetAmounts_,
            address incomingStakingToken_,
            uint256 minIncomingStakingTokenAmount_,
            bool useUnderlyings_
        )
    {
        return abi.decode(_actionData, (address, uint256[], address, uint256, bool));
    }

    /// @dev Helper to decode the encoded call arguments for lending
    function __decodeLendCallArgs(bytes memory _actionData)
        internal
        pure
        returns (
            address pool_,
            uint256[] memory orderedOutgoingAssetAmounts_,
            uint256 minIncomingLpTokenAmount_,
            bool useUnderlyings_
        )
    {
        return abi.decode(_actionData, (address, uint256[], uint256, bool));
    }

    /// @dev Helper to decode the encoded call arguments for redeeming
    function __decodeRedeemCallArgs(bytes memory _actionData)
        internal
        pure
        returns (
            address pool_,
            uint256 outgoingLpTokenAmount_,
            bool useUnderlyings_,
            RedeemType redeemType_,
            bytes memory incomingAssetsData_
        )
    {
        return abi.decode(_actionData, (address, uint256, bool, RedeemType, bytes));
    }

    /// @dev Helper to decode the encoded incoming assets arguments for RedeemType.OneCoin
    function __decodeIncomingAssetsDataRedeemOneCoin(bytes memory _incomingAssetsData)
        internal
        pure
        returns (uint256 incomingAssetPoolIndex_, uint256 minIncomingAssetAmount_)
    {
        return abi.decode(_incomingAssetsData, (uint256, uint256));
    }

    /// @dev Helper to decode the encoded incoming assets arguments for RedeemType.Standard
    function __decodeIncomingAssetsDataRedeemStandard(bytes memory _incomingAssetsData)
        internal
        pure
        returns (uint256[] memory orderedMinIncomingAssetAmounts_)
    {
        return abi.decode(_incomingAssetsData, (uint256[]));
    }

    /// @dev Helper to decode the encoded call arguments for staking
    function __decodeStakeCallArgs(bytes memory _actionData)
        internal
        pure
        returns (
            address pool_,
            address incomingStakingToken_,
            uint256 amount_
        )
    {
        return abi.decode(_actionData, (address, address, uint256));
    }

    /// @dev Helper to decode the encoded call arguments for unstaking and then redeeming
    function __decodeUnstakeAndRedeemCallArgs(bytes memory _actionData)
        internal
        pure
        returns (
            address pool_,
            address outgoingStakingToken_,
            uint256 outgoingStakingTokenAmount_,
            bool useUnderlyings_,
            RedeemType redeemType_,
            bytes memory incomingAssetsData_
        )
    {
        return abi.decode(_actionData, (address, address, uint256, bool, RedeemType, bytes));
    }

    /// @dev Helper to decode the encoded call arguments for unstaking
    function __decodeUnstakeCallArgs(bytes memory _actionData)
        internal
        pure
        returns (
            address pool_,
            address outgoingStakingToken_,
            uint256 amount_
        )
    {
        return abi.decode(_actionData, (address, address, uint256));
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

/// @title IDerivativePriceFeed Interface
/// @author Enzyme Council <[email protected]>
/// @notice Simple interface for derivative price source oracle implementations
interface IDerivativePriceFeed {
    function calcUnderlyingValues(address, uint256)
        external
        returns (address[] memory, uint256[] memory);

    function isSupportedAsset(address) external view returns (bool);
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
import "../../../../interfaces/ICurveAddressProvider.sol";
import "../../../../interfaces/ICurveLiquidityPool.sol";
import "../../../../interfaces/ICurvePoolOwner.sol";
import "../../../../interfaces/ICurveRegistryMain.sol";
import "../../../../interfaces/ICurveRegistryMetapoolFactory.sol";
import "../../../../utils/FundDeployerOwnerMixin.sol";
import "../IDerivativePriceFeed.sol";

/// @title CurvePriceFeed Contract
/// @author Enzyme Council <[email protected]>
/// @notice Price feed for Curve pool tokens
contract CurvePriceFeed is IDerivativePriceFeed, FundDeployerOwnerMixin {
    using SafeMath for uint256;

    event CurvePoolOwnerSet(address poolOwner);

    event DerivativeAdded(address indexed derivative, address indexed pool);

    event DerivativeRemoved(address indexed derivative);

    event InvariantProxyAssetForPoolSet(address indexed pool, address indexed invariantProxyAsset);

    event PoolRemoved(address indexed pool);

    event ValidatedVirtualPriceForPoolUpdated(address indexed pool, uint256 virtualPrice);

    uint256 private constant ADDRESS_PROVIDER_METAPOOL_FACTORY_ID = 3;
    uint256 private constant VIRTUAL_PRICE_DEVIATION_DIVISOR = 10000;
    uint256 private constant VIRTUAL_PRICE_UNIT = 10**18;

    ICurveAddressProvider private immutable ADDRESS_PROVIDER_CONTRACT;
    uint256 private immutable VIRTUAL_PRICE_DEVIATION_THRESHOLD;

    // We take one asset as representative of the pool's invariant, e.g., WETH for ETH-based pools.
    // Caching invariantProxyAssetDecimals in a packed storage slot
    // removes an additional external call and cold SLOAD operation during value lookups.
    struct PoolInfo {
        address invariantProxyAsset; // 20 bytes
        uint8 invariantProxyAssetDecimals; // 1 byte
        uint88 lastValidatedVirtualPrice; // 11 bytes (could safely be 8-10 bytes)
    }

    address private curvePoolOwner;

    // Pool tokens and liquidity gauge tokens are treated the same for pricing purposes
    mapping(address => address) private derivativeToPool;
    mapping(address => PoolInfo) private poolToPoolInfo;

    // Not necessary for this contract, but used by Curve liquidity adapters
    mapping(address => address) private poolToLpToken;

    constructor(
        address _fundDeployer,
        address _addressProvider,
        address _poolOwner,
        uint256 _virtualPriceDeviationThreshold
    ) public FundDeployerOwnerMixin(_fundDeployer) {
        ADDRESS_PROVIDER_CONTRACT = ICurveAddressProvider(_addressProvider);
        VIRTUAL_PRICE_DEVIATION_THRESHOLD = _virtualPriceDeviationThreshold;

        __setCurvePoolOwner(_poolOwner);
    }

    /// @notice Converts a given amount of a derivative to its underlying asset values
    /// @param _derivative The derivative to convert
    /// @param _derivativeAmount The amount of the derivative to convert
    /// @return underlyings_ The underlying assets for the _derivative
    /// @return underlyingAmounts_ The amount of each underlying asset for the equivalent derivative amount
    function calcUnderlyingValues(address _derivative, uint256 _derivativeAmount)
        external
        override
        returns (address[] memory underlyings_, uint256[] memory underlyingAmounts_)
    {
        address pool = getPoolForDerivative(_derivative);
        require(pool != address(0), "calcUnderlyingValues: _derivative is not supported");

        PoolInfo memory poolInfo = getPoolInfo(pool);

        uint256 virtualPrice = ICurveLiquidityPool(pool).get_virtual_price();

        // Validate and update the cached lastValidatedVirtualPrice if:
        /// 1. a pool requires virtual price validation, and
        /// 2. the unvalidated `virtualPrice` deviates from the PoolInfo.lastValidatedVirtualPrice value
        /// by more than the tolerated "deviation threshold" (e.g., 1%).
        /// This is an optimization to save gas on validating non-reentrancy during the virtual price query,
        /// since the virtual price increases relatively slowly as the pool accrues fees over time.
        if (
            poolInfo.lastValidatedVirtualPrice > 0 &&
            __virtualPriceDiffExceedsThreshold(
                virtualPrice,
                uint256(poolInfo.lastValidatedVirtualPrice)
            )
        ) {
            __updateValidatedVirtualPrice(pool, virtualPrice);
        }

        underlyings_ = new address[](1);
        underlyings_[0] = poolInfo.invariantProxyAsset;

        underlyingAmounts_ = new uint256[](1);
        if (poolInfo.invariantProxyAssetDecimals == 18) {
            underlyingAmounts_[0] = _derivativeAmount.mul(virtualPrice).div(VIRTUAL_PRICE_UNIT);
        } else {
            underlyingAmounts_[0] = _derivativeAmount
                .mul(virtualPrice)
                .mul(10**uint256(poolInfo.invariantProxyAssetDecimals))
                .div(VIRTUAL_PRICE_UNIT)
                .div(VIRTUAL_PRICE_UNIT);
        }

        return (underlyings_, underlyingAmounts_);
    }

    /// @notice Checks if an asset is supported by the price feed
    /// @param _asset The asset to check
    /// @return isSupported_ True if the asset is supported
    function isSupportedAsset(address _asset) external view override returns (bool isSupported_) {
        return getPoolForDerivative(_asset) != address(0);
    }

    //////////////////////////
    // DERIVATIVES REGISTRY //
    //////////////////////////

    // addPools() is the primary action to add validated lpTokens and gaugeTokens as derivatives.
    // addGaugeTokens() can be used to add validated gauge tokens for an already-registered pool.
    // addPoolsWithoutValidation() and addGaugeTokensWithoutValidation() can be used as overrides.
    // It is possible to remove all pool data and derivatives (separately).
    // It is possible to update the invariant proxy asset for any pool.
    // It is possible to update whether the pool's virtual price is reenterable.

    /// @notice Adds validated gaugeTokens to the price feed
    /// @param _gaugeTokens The ordered gauge tokens
    /// @param _pools The ordered pools corresponding to _gaugeTokens
    /// @dev All params are corresponding, equal length arrays.
    /// _pools must already have been added via an addPools~() function
    function addGaugeTokens(address[] calldata _gaugeTokens, address[] calldata _pools)
        external
        onlyFundDeployerOwner
    {
        ICurveRegistryMain registryContract = __getRegistryMainContract();
        ICurveRegistryMetapoolFactory factoryContract = __getRegistryMetapoolFactoryContract();

        for (uint256 i; i < _gaugeTokens.length; i++) {
            if (factoryContract.get_gauge(_pools[i]) != _gaugeTokens[i]) {
                __validateGaugeMainRegistry(_gaugeTokens[i], _pools[i], registryContract);
            }
        }

        __addGaugeTokens(_gaugeTokens, _pools);
    }

    /// @notice Adds unvalidated gaugeTokens to the price feed
    /// @param _gaugeTokens The ordered gauge tokens
    /// @param _pools The ordered pools corresponding to _gaugeTokens
    /// @dev Should only be used if something is incorrectly failing in the registry validation,
    /// or if gauge tokens exist outside of the registries supported by this price feed,
    /// e.g., a wrapper for non-tokenized gauges.
    /// All params are corresponding, equal length arrays.
    /// _pools must already have been added via an addPools~() function.
    function addGaugeTokensWithoutValidation(
        address[] calldata _gaugeTokens,
        address[] calldata _pools
    ) external onlyFundDeployerOwner {
        __addGaugeTokens(_gaugeTokens, _pools);
    }

    /// @notice Adds validated Curve pool info, lpTokens, and gaugeTokens to the price feed
    /// @param _pools The ordered Curve pools
    /// @param _invariantProxyAssets The ordered invariant proxy assets corresponding to _pools,
    /// e.g., WETH for ETH-based pools
    /// @param _reentrantVirtualPrices The ordered flags corresponding to _pools,
    /// true if the get_virtual_price() function is potentially reenterable
    /// @param _lpTokens The ordered lpToken corresponding to _pools
    /// @param _gaugeTokens The ordered gauge token corresponding to _pools
    /// @dev All params are corresponding, equal length arrays.
    /// address(0) can be used for any _gaugeTokens index to omit the gauge (e.g., no gauge token exists).
    /// _lpTokens is not technically necessary since it is knowable from a Curve registry,
    /// but it's better to use Curve's upgradable contracts as an input validation rather than fully-trusted.
    function addPools(
        address[] calldata _pools,
        address[] calldata _invariantProxyAssets,
        bool[] calldata _reentrantVirtualPrices,
        address[] calldata _lpTokens,
        address[] calldata _gaugeTokens
    ) external onlyFundDeployerOwner {
        ICurveRegistryMain registryContract = __getRegistryMainContract();
        ICurveRegistryMetapoolFactory factoryContract = __getRegistryMetapoolFactoryContract();

        for (uint256 i; i < _pools.length; i++) {
            // Validate the lpToken and gauge token based on registry
            if (_lpTokens[i] == registryContract.get_lp_token(_pools[i])) {
                // Main registry

                if (_gaugeTokens[i] != address(0)) {
                    __validateGaugeMainRegistry(_gaugeTokens[i], _pools[i], registryContract);
                }
            } else if (_lpTokens[i] == _pools[i] && factoryContract.get_n_coins(_pools[i]) > 0) {
                // Metapool factory registry
                // lpToken and pool are the same address
                // get_n_coins() is arbitrarily used to validate the pool is on this registry

                if (_gaugeTokens[i] != address(0)) {
                    __validateGaugeMetapoolFactoryRegistry(
                        _gaugeTokens[i],
                        _pools[i],
                        factoryContract
                    );
                }
            } else {
                revert("addPools: Invalid inputs");
            }
        }

        __addPools(
            _pools,
            _invariantProxyAssets,
            _reentrantVirtualPrices,
            _lpTokens,
            _gaugeTokens
        );
    }

    /// @notice Adds unvalidated Curve pool info, lpTokens, and gaugeTokens to the price feed
    /// @param _pools The ordered Curve pools
    /// @param _invariantProxyAssets The ordered invariant proxy assets corresponding to _pools,
    /// e.g., WETH for ETH-based pools
    /// @param _reentrantVirtualPrices The ordered flags corresponding to _pools,
    /// true if the get_virtual_price() function is potentially reenterable
    /// @param _lpTokens The ordered lpToken corresponding to _pools
    /// @param _gaugeTokens The ordered gauge token corresponding to _pools
    /// @dev Should only be used if something is incorrectly failing in the registry validation,
    /// or if pools exist outside of the registries supported by this price feed.
    /// All params are corresponding, equal length arrays.
    /// address(0) can be used for any _gaugeTokens index to omit the gauge (e.g., no gauge token exists).
    function addPoolsWithoutValidation(
        address[] calldata _pools,
        address[] calldata _invariantProxyAssets,
        bool[] calldata _reentrantVirtualPrices,
        address[] calldata _lpTokens,
        address[] calldata _gaugeTokens
    ) external onlyFundDeployerOwner {
        __addPools(
            _pools,
            _invariantProxyAssets,
            _reentrantVirtualPrices,
            _lpTokens,
            _gaugeTokens
        );
    }

    /// @notice Removes derivatives from the price feed
    /// @param _derivatives The derivatives to remove
    /// @dev Unlikely to be needed, just in case of bad storage entry.
    /// Can remove both lpToken and gaugeToken from derivatives list,
    /// but does not remove lpToken from pool info cache.
    function removeDerivatives(address[] calldata _derivatives) external onlyFundDeployerOwner {
        for (uint256 i; i < _derivatives.length; i++) {
            delete derivativeToPool[_derivatives[i]];

            emit DerivativeRemoved(_derivatives[i]);
        }
    }

    /// @notice Removes pools from the price feed
    /// @param _pools The pools to remove
    /// @dev Unlikely to be needed, just in case of bad storage entry.
    /// Does not remove lpToken nor gauge tokens from derivatives list.
    function removePools(address[] calldata _pools) external onlyFundDeployerOwner {
        for (uint256 i; i < _pools.length; i++) {
            delete poolToPoolInfo[_pools[i]];
            delete poolToLpToken[_pools[i]];

            emit PoolRemoved(_pools[i]);
        }
    }

    /// @notice Sets the Curve pool owner
    /// @param _nextPoolOwner The next pool owner value
    function setCurvePoolOwner(address _nextPoolOwner) external onlyFundDeployerOwner {
        __setCurvePoolOwner(_nextPoolOwner);
    }

    /// @notice Updates the PoolInfo for the given pools
    /// @param _pools The ordered pools
    /// @param _invariantProxyAssets The ordered invariant asset proxy assets
    /// @param _reentrantVirtualPrices The ordered flags corresponding to _pools,
    /// true if the get_virtual_price() function is potentially reenterable
    function updatePoolInfo(
        address[] calldata _pools,
        address[] calldata _invariantProxyAssets,
        bool[] calldata _reentrantVirtualPrices
    ) external onlyFundDeployerOwner {
        require(
            _pools.length == _invariantProxyAssets.length &&
                _pools.length == _reentrantVirtualPrices.length,
            "updatePoolInfo: Unequal arrays"
        );

        for (uint256 i; i < _pools.length; i++) {
            __setPoolInfo(_pools[i], _invariantProxyAssets[i], _reentrantVirtualPrices[i]);
        }
    }

    // PRIVATE FUNCTIONS

    /// @dev Helper to add a derivative to the price feed
    function __addDerivative(address _derivative, address _pool) private {
        require(
            getPoolForDerivative(_derivative) == address(0),
            "__addDerivative: Already exists"
        );

        // Assert that the assumption that all Curve pool tokens are 18 decimals
        require(ERC20(_derivative).decimals() == 18, "__addDerivative: Not 18-decimal");

        derivativeToPool[_derivative] = _pool;

        emit DerivativeAdded(_derivative, _pool);
    }

    /// @dev Helper for common logic in addGauges~() functions
    function __addGaugeTokens(address[] calldata _gaugeTokens, address[] calldata _pools) private {
        require(_gaugeTokens.length == _pools.length, "__addGaugeTokens: Unequal arrays");

        for (uint256 i; i < _gaugeTokens.length; i++) {
            require(
                getLpTokenForPool(_pools[i]) != address(0),
                "__addGaugeTokens: Pool not registered"
            );
            // Not-yet-registered _gaugeTokens[i] tested in __addDerivative()

            __addDerivative(_gaugeTokens[i], _pools[i]);
        }
    }

    /// @dev Helper for common logic in addPools~() functions
    function __addPools(
        address[] calldata _pools,
        address[] calldata _invariantProxyAssets,
        bool[] calldata _reentrantVirtualPrices,
        address[] calldata _lpTokens,
        address[] calldata _gaugeTokens
    ) private {
        require(
            _pools.length == _invariantProxyAssets.length &&
                _pools.length == _reentrantVirtualPrices.length &&
                _pools.length == _lpTokens.length &&
                _pools.length == _gaugeTokens.length,
            "__addPools: Unequal arrays"
        );

        for (uint256 i; i < _pools.length; i++) {
            // Redundant for validated addPools()
            require(_lpTokens[i] != address(0), "__addPools: Empty lpToken");
            // Empty _pools[i] reverts during __validatePoolCompatibility
            // Empty _invariantProxyAssets[i] reverts during __setPoolInfo

            // Validate new pool's compatibility with price feed
            require(getLpTokenForPool(_pools[i]) == address(0), "__addPools: Already registered");
            __validatePoolCompatibility(_pools[i]);

            // Register pool info
            __setPoolInfo(_pools[i], _invariantProxyAssets[i], _reentrantVirtualPrices[i]);
            poolToLpToken[_pools[i]] = _lpTokens[i];

            // Add lpToken and gauge token as derivatives
            __addDerivative(_lpTokens[i], _pools[i]);
            if (_gaugeTokens[i] != address(0)) {
                __addDerivative(_gaugeTokens[i], _pools[i]);
            }
        }
    }

    /// @dev Helper to get the main Curve registry contract
    function __getRegistryMainContract() private view returns (ICurveRegistryMain contract_) {
        return ICurveRegistryMain(ADDRESS_PROVIDER_CONTRACT.get_registry());
    }

    /// @dev Helper to get the Curve metapool factory registry contract
    function __getRegistryMetapoolFactoryContract()
        private
        view
        returns (ICurveRegistryMetapoolFactory contract_)
    {
        return
            ICurveRegistryMetapoolFactory(
                ADDRESS_PROVIDER_CONTRACT.get_address(ADDRESS_PROVIDER_METAPOOL_FACTORY_ID)
            );
    }

    /// @dev Helper to call a known non-reenterable pool function
    function __makeNonReentrantPoolCall(address _pool) private {
        ICurvePoolOwner(getCurvePoolOwner()).withdraw_admin_fees(_pool);
    }

    /// @dev Helper to set the Curve pool owner
    function __setCurvePoolOwner(address _nextPoolOwner) private {
        curvePoolOwner = _nextPoolOwner;

        emit CurvePoolOwnerSet(_nextPoolOwner);
    }

    /// @dev Helper to set the PoolInfo for a given pool
    function __setPoolInfo(
        address _pool,
        address _invariantProxyAsset,
        bool _reentrantVirtualPrice
    ) private {
        uint256 lastValidatedVirtualPrice;
        if (_reentrantVirtualPrice) {
            // Validate the virtual price by calling a non-reentrant pool function
            __makeNonReentrantPoolCall(_pool);

            lastValidatedVirtualPrice = ICurveLiquidityPool(_pool).get_virtual_price();

            emit ValidatedVirtualPriceForPoolUpdated(_pool, lastValidatedVirtualPrice);
        }

        poolToPoolInfo[_pool] = PoolInfo({
            invariantProxyAsset: _invariantProxyAsset,
            invariantProxyAssetDecimals: ERC20(_invariantProxyAsset).decimals(),
            lastValidatedVirtualPrice: uint88(lastValidatedVirtualPrice)
        });

        emit InvariantProxyAssetForPoolSet(_pool, _invariantProxyAsset);
    }

    /// @dev Helper to update the last validated virtual price for a given pool
    function __updateValidatedVirtualPrice(address _pool, uint256 _virtualPrice) private {
        // Validate the virtual price by calling a non-reentrant pool function
        __makeNonReentrantPoolCall(_pool);

        // _virtualPrice is now considered valid
        poolToPoolInfo[_pool].lastValidatedVirtualPrice = uint88(_virtualPrice);

        emit ValidatedVirtualPriceForPoolUpdated(_pool, _virtualPrice);
    }

    /// @dev Helper to validate a gauge on the main Curve registry
    function __validateGaugeMainRegistry(
        address _gauge,
        address _pool,
        ICurveRegistryMain _mainRegistryContract
    ) private view {
        (address[10] memory gauges, ) = _mainRegistryContract.get_gauges(_pool);
        for (uint256 i; i < gauges.length; i++) {
            if (_gauge == gauges[i]) {
                return;
            }
        }

        revert("__validateGaugeMainRegistry: Invalid gauge");
    }

    /// @dev Helper to validate a gauge on the Curve metapool factory registry
    function __validateGaugeMetapoolFactoryRegistry(
        address _gauge,
        address _pool,
        ICurveRegistryMetapoolFactory _metapoolFactoryRegistryContract
    ) private view {
        require(
            _gauge == _metapoolFactoryRegistryContract.get_gauge(_pool),
            "__validateGaugeMetapoolFactoryRegistry: Invalid gauge"
        );
    }

    /// @dev Helper to validate a pool's compatibility with the price feed.
    /// Pool must implement expected get_virtual_price() function.
    function __validatePoolCompatibility(address _pool) private view {
        require(
            ICurveLiquidityPool(_pool).get_virtual_price() > 0,
            "__validatePoolCompatibility: Incompatible"
        );
    }

    /// @dev Helper to check if the difference between lastValidatedVirtualPrice and the current virtual price
    /// exceeds the allowed threshold before the current virtual price must be validated and stored
    function __virtualPriceDiffExceedsThreshold(
        uint256 _currentVirtualPrice,
        uint256 _lastValidatedVirtualPrice
    ) private view returns (bool exceedsThreshold_) {
        // Uses the absolute delta between current and last validated virtual prices for the rare
        // case where a virtual price might have decreased (e.g., rounding, slashing, yet unknown
        // manipulation vector, etc)
        uint256 absDiff;
        if (_currentVirtualPrice > _lastValidatedVirtualPrice) {
            absDiff = _currentVirtualPrice.sub(_lastValidatedVirtualPrice);
        } else {
            absDiff = _lastValidatedVirtualPrice.sub(_currentVirtualPrice);
        }

        return
            absDiff >
            _lastValidatedVirtualPrice.mul(VIRTUAL_PRICE_DEVIATION_THRESHOLD).div(
                VIRTUAL_PRICE_DEVIATION_DIVISOR
            );
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the Curve pool owner
    /// @return poolOwner_ The Curve pool owner
    function getCurvePoolOwner() public view returns (address poolOwner_) {
        return curvePoolOwner;
    }

    /// @notice Gets the lpToken for a given pool
    /// @param _pool The pool
    /// @return lpToken_ The lpToken
    function getLpTokenForPool(address _pool) public view returns (address lpToken_) {
        return poolToLpToken[_pool];
    }

    /// @notice Gets the stored PoolInfo for a given pool
    /// @param _pool The pool
    /// @return poolInfo_ The PoolInfo
    function getPoolInfo(address _pool) public view returns (PoolInfo memory poolInfo_) {
        return poolToPoolInfo[_pool];
    }

    /// @notice Gets the pool for a given derivative
    /// @param _derivative The derivative
    /// @return pool_ The pool
    function getPoolForDerivative(address _derivative) public view returns (address pool_) {
        return derivativeToPool[_derivative];
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

/// @title ICurveAddressProvider interface
/// @author Enzyme Council <[email protected]>
interface ICurveAddressProvider {
    function get_address(uint256) external view returns (address);

    function get_registry() external view returns (address);
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

/// @title ICurveLiquidityPool interface
/// @author Enzyme Council <[email protected]>
interface ICurveLiquidityPool {
    function coins(int128) external view returns (address);

    function coins(uint256) external view returns (address);

    function get_virtual_price() external view returns (uint256);

    function underlying_coins(int128) external view returns (address);

    function underlying_coins(uint256) external view returns (address);
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

/// @title ICurvePoolOwner interface
/// @author Enzyme Council <[email protected]>
interface ICurvePoolOwner {
    function withdraw_admin_fees(address) external;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title ICurveRegistryMain interface
/// @author Enzyme Council <[email protected]>
/// @notice Limited interface for the Curve Registry contract at ICurveAddressProvider.get_address(0)
interface ICurveRegistryMain {
    function get_gauges(address) external view returns (address[10] memory, int128[10] memory);

    function get_lp_token(address) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title ICurveRegistryMetapoolFactory interface
/// @author Enzyme Council <[email protected]>
/// @notice Limited interface for the Curve Registry contract at ICurveAddressProvider.get_address(3)
interface ICurveRegistryMetapoolFactory {
    function get_gauge(address) external view returns (address);

    function get_n_coins(address) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title WETH Interface
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

import "../core/fund-deployer/IFundDeployer.sol";

/// @title FundDeployerOwnerMixin Contract
/// @author Enzyme Council <[email protected]>
/// @notice A mixin contract that defers ownership to the owner of FundDeployer
abstract contract FundDeployerOwnerMixin {
    address internal immutable FUND_DEPLOYER;

    modifier onlyFundDeployerOwner() {
        require(
            msg.sender == getOwner(),
            "onlyFundDeployerOwner: Only the FundDeployer owner can call this function"
        );
        _;
    }

    constructor(address _fundDeployer) public {
        FUND_DEPLOYER = _fundDeployer;
    }

    /// @notice Gets the owner of this contract
    /// @return owner_ The owner
    /// @dev Ownership is deferred to the owner of the FundDeployer contract
    function getOwner() public view returns (address owner_) {
        return IFundDeployer(FUND_DEPLOYER).getOwner();
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `FUND_DEPLOYER` variable
    /// @return fundDeployer_ The `FUND_DEPLOYER` variable value
    function getFundDeployer() public view returns (address fundDeployer_) {
        return FUND_DEPLOYER;
    }
}