/**
 *Submitted for verification at Etherscan.io on 2023-01-20
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: contracts/lib/SafeERC20.sol



pragma solidity 0.8.17;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
// File: contracts/lib/Ownable.sol



pragma solidity 0.8.17;

/**
 * @title Ownable
 * @dev This contract has the owner address providing basic authorization control
 */
contract Ownable {
  /**
   * @dev Event to show ownership has been transferred
   * @param previousOwner representing the address of the previous owner
   * @param newOwner representing the address of the new owner
   */
  event OwnershipTransferred(address previousOwner, address newOwner);

  // Owner of the contract
  address private _owner;

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner());
    _;
  }

  /**
   * @dev The constructor sets the original owner of the contract to the sender account.
   */
  constructor () {
    setOwner(msg.sender);
  }

  /**
   * @dev Tells the address of the owner
   * @return the address of the owner
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Sets a new owner address
   */
  function setOwner(address newOwner) internal {
    _owner = newOwner;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner(), newOwner);
    setOwner(newOwner);
  }
}

// File: contracts/erc20/MobyPoolErc20.sol



pragma solidity 0.8.17;







/**
 * User account struct.
 * Common type used to store user's deposits in contract. Contains arrays of deposits properties.
 */
struct Account {
    // Deposit creation time.
    uint[] createdAt;
    // Deposit token index in tokens array.
    uint[] token;
    // Deposit amount.
    uint[] amount;
    // Withdrawal order creation time.
    uint[] orderCreatedAt;
    // Withdrawal order amount.
    uint[] orderAmount;
}

// Iterable mapping value struct.
struct IndexValue { uint keyIndex; Account value; }

// Iterable mapping flag struct.
struct KeyFlag { address key; bool deleted; }

/**
 * Iterable mapping struct.
 * Used to make iterable user accounts list.
 */
struct ItMap {
    mapping(address => IndexValue) data;
    KeyFlag[] keys;
    uint size;
}

// Iterator type for iterable mapping.
type Iterator is uint;

/**
 * @notice Iterable mapping is used to provide both a mapping and array properties,
 * allowing the mapping to be iterated sequentially.
 */
library IterableMapping {
    function insert(ItMap storage self, address key, Account memory value) internal returns (bool replaced) {
        uint keyIndex = self.data[key].keyIndex;
        self.data[key].value = value;
        if (keyIndex > 0)
            return true;
        else {
            keyIndex = self.keys.length;
            self.keys.push();
            self.data[key].keyIndex = keyIndex + 1;
            self.keys[keyIndex].key = key;
            self.size++;
            return false;
        }
    }

    function remove(ItMap storage self, address key) internal returns (bool success) {
        uint keyIndex = self.data[key].keyIndex;
        if (keyIndex == 0)
            return false;
        delete self.data[key];
        self.keys[keyIndex - 1].deleted = true;
        self.size --;
    }

    function contains(ItMap storage self, address key) internal view returns (bool) {
        return self.data[key].keyIndex > 0;
    }

    function iterateStart(ItMap storage self) internal view returns (Iterator) {
        return iteratorSkipDeleted(self, 0);
    }

    function iterateValid(ItMap storage self, Iterator iterator) internal view returns (bool) {
        return Iterator.unwrap(iterator) < self.keys.length;
    }

    function iterateNext(ItMap storage self, Iterator iterator) internal view returns (Iterator) {
        return iteratorSkipDeleted(self, Iterator.unwrap(iterator) + 1);
    }

    function iterateGet(ItMap storage self, Iterator iterator) internal view returns (address key, Account memory value) {
        uint keyIndex = Iterator.unwrap(iterator);
        key = self.keys[keyIndex].key;
        value = self.data[key].value;
    }

    function iteratorSkipDeleted(ItMap storage self, uint keyIndex) private view returns (Iterator) {
        while (keyIndex < self.keys.length && self.keys[keyIndex].deleted)
            keyIndex++;
        return Iterator.wrap(keyIndex);
    }
}


/**
 * @title MobyPoolErc20
 * @notice MobyBridge contract pool performs deposits and withdrawals of user's investments.
 */
contract MobyPoolErc20 is Ownable, Pausable {
    using SafeMath for uint;
    using IterableMapping for ItMap;
    using SafeERC20 for IERC20;


    /**
     * Contract available tokens count.
     * Contract operates with several tokens including the base ETH token with index 0
     */
    uint constant public TOKENS_COUNT = 3;

    /**
     * Percent values divider degree.
     * All percent values of this contract are measured in percent units = 1 / 10 ^ PERCENT_DECIMALS
     */
    uint constant public PERCENT_DECIMALS = 2;

    /**
     * Part of a new deposits allocated to business process in percent units.
     * This funds will be added to a working capital reserve and can be transferred outside the contract.
     */
    uint constant public WORKING_CAPITAL_PERCENT = 8000;

    /**
     * Period of a withdraw commission application in days.
     * At the start of each deposit, commission percent will be equal to
     * WITHDRAW_COMMISSION_PERIOD_DAYS * WITHDRAW_COMMISSION_PERCENT_STEP_PER_DAY percent units.
     */
    uint constant public WITHDRAW_COMMISSION_PERIOD_DAYS = 90;

    /**
     * Withdraw commission percent decrement in percent units per day.
     * Commission will be decreased every day by WITHDRAW_COMMISSION_PERCENT_STEP_PER_DAY percent units.
     */
    uint constant public WITHDRAW_COMMISSION_PERCENT_STEP_PER_DAY = 100;

    /**
     * Withdrawal order confirmation period.
     * Withdrawal orders are waiting for automatic confirmation during this period before transfer.
     */
    uint constant public ORDER_CONFIRMATION_TIME = 3 days;

    // Initialization flag.
    bool private initialized;

    // Contract events ID counter.
    uint private eventId;

    /**
     * Contract available tokens contracts addresses.
     * The first token if reserved for ETH.
     */
    address[] private tokens;

    /**
     * Tokens availability flags.
     * Deposit and withdrawal operations in token are not allowed when tokens are disabled.
     */
    bool[] private tokensEnabled;

    /**
     * Tokens min deposit amounts.
     * The first deposit in tokens must be greater than or equal to these values.
     */
    uint[] private tokensMinDepositAmount;

    /**
     * Tokens min refill amounts.
     * Subsequent deposits in tokens must be greater than or equal to these values.
     */
    uint[] private tokensMinRefillAmount;

    /**
     * Tokens max deposit amounts.
     * Deposit in tokens must be less than or equal to these values.
     */
    uint[] private tokensMaxDepositAmount;

    /**
     * Tokens min withdrawal amounts.
     * Withdrawal orders in tokens must be greater than or equal to these values.
     */
    uint[] private tokensMinWithdrawalAmount;

    /**
     * Tokens min withdrawal amounts.
     * Withdrawal orders in tokens must be less than or equal to these values.
     */
    uint[] private tokensMaxWithdrawalAmount;

    /**
     * Working capital in tokens.
     * Contains amounts of working capital reserves in tokens.
     */
    uint[] private workingCapital;

    /**
     * User's accounts iterable map.
     * Contains iterable mapping of user's accounts.
     */
    ItMap private accounts;

    /**
     * @notice Event to show a new user has been registered.
     * @param eventId representing the ID of event
     * @param user representing the address of the new user
     */
    event Registration(uint eventId, address user);

    /**
     * @notice Event to show a new deposit has been invested.
     * @param eventId representing the ID of event
     * @param user representing the address of the investor
     * @param depositIndex representing the index of a new deposit in user`s account
     * @param tokenIndex representing the index of a new deposit's token in tokens array
     * @param amount representing the amount deposited
     * @param workingCapitalAmount representing the amount of a new deposit, reserved for working capital
     * @param isWorkingCapital representing whether the deposit was a working capital
     */
    event Deposit(
        uint eventId,
        address user,
        uint depositIndex,
        uint tokenIndex,
        uint amount,
        uint workingCapitalAmount,
        bool isWorkingCapital
    );

    /**
     * @notice Event to show a new withdrawal order has been created.
     * @param eventId representing the ID of event
     * @param user representing the address of the investor
     * @param depositIndex representing the index of a deposit to be withdrawn from in user`s account
     * @param tokenIndex representing the index of a deposit's token to be withdrawn from in tokens array
     * @param amount representing the amount to be withdrawn
     * @param commissionAmount representing the commission amount computed
     */
    event WithdrawOrder(
        uint eventId,
        address user,
        uint depositIndex,
        uint tokenIndex,
        uint amount,
        uint commissionAmount
    );

    /**
     * @notice Event to show a new withdrawal was processed.
     * @param eventId representing the ID of event
     * @param user representing the address of the investor
     * @param depositIndex representing the index of a deposit withdrawn from in user`s account
     * @param tokenIndex representing the index of a deposit's withdrawn from token in tokens array
     * @param amount representing the amount withdrawn
     * @param commissionAmount representing the commission amount retained
     * @param isWorkingCapital representing whether the withdrawal was a working capital
     */
    event Withdraw(
        uint eventId,
        address user,
        uint depositIndex,
        uint tokenIndex,
        uint amount,
        uint commissionAmount,
        bool isWorkingCapital
    );

    /**
     * @notice Event to show enabling/disabling of tokens.
     * @param eventId representing the ID of event
     * @param tokenIndex representing the index of token in tokens array
     * @param value representing the token state
     */
    event SetTokenEnabled(uint eventId, uint tokenIndex, bool value);

    /**
     * @notice Error of insufficient funds for operation.
     * @param available representing the available amount
     * @param required representing the required amount
     */
    error InsufficientFunds(uint available, uint required);

    /**
     * @notice Error of insufficient working capital for operation.
     * @param available representing the available working capital amount
     * @param required representing the required working capital amount
     */
    error InsufficientWorkingCapital(uint available, uint required);

    /**
     * @notice Error of plain Ether transfers to contract.
     */
    error PlainTransfersDisabled();

    /**
     * @notice Plain Ether transfer handler.
     * @dev Plain Ether transfers to contract are not allowed.
     */
    receive() external payable {
        revert PlainTransfersDisabled();
    }

    /**
     * @notice Initializes contract parameters on first implementation.
     * @param owner representing the contract owner address
     * @param _tokens representing contract tokens addresses
     * @param _minDepositAmount representing contract tokens min deposit amounts
     * @param _minRefillAmount representing contract tokens min refill amounts
     * @param _maxDepositAmount representing contract tokens max deposit amounts
     * @param _minWithdrawalAmount representing contract tokens min withdrawal amounts
     * @param _maxWithdrawalAmount representing contract tokens max withdrawal amounts
     */
    function initialize(
        address owner,
        address[] memory _tokens,
        uint[] memory _minDepositAmount,
        uint[] memory _minRefillAmount,
        uint[] memory _maxDepositAmount,
        uint[] memory _minWithdrawalAmount,
        uint[] memory _maxWithdrawalAmount
    ) external {
        if (initialized) return;
        setOwner(owner);
        for (uint i=0; i<TOKENS_COUNT; i++) {
            tokens.push(_tokens[i]);
            tokensMinDepositAmount.push(_minDepositAmount[i]);
            tokensMinRefillAmount.push(_minRefillAmount[i]);
            tokensMaxDepositAmount.push(_maxDepositAmount[i]);
            tokensMinWithdrawalAmount.push(_minWithdrawalAmount[i]);
            tokensMaxWithdrawalAmount.push(_maxWithdrawalAmount[i]);
            tokensEnabled.push(true);
            workingCapital.push(0);
        }
        initialized = true;
    }

    /**
     * @notice Pauses the contact.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contact.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Sets token enabled flag.
     * @param tokenIndex representing the index of token in tokens array
     * @param value representing the enabled flag value
     */
    function setTokenEnabled(uint tokenIndex, bool value) external onlyOwner {
        require(
            tokenIndex < TOKENS_COUNT,
            "Invalid token index."
        );
        require(
            tokensEnabled[tokenIndex] != value,
            "Token state already set."
        );
        tokensEnabled[tokenIndex] = value;
        emit SetTokenEnabled(nextEventId(), tokenIndex, value);
    }

    /**
     * @notice Creates the deposit.
     * @param tokenIndex representing the index of new deposit's token in tokens array
     * @param amount representing the amount to be deposited
     */
    function createDeposit(uint tokenIndex, uint amount) external payable whenNotPaused {
        require(
            (msg.value > 0) == (tokenIndex == 0),
            "Incorrect message value."
        );
        require(
            tokenIndex < TOKENS_COUNT,
            "Invalid token index."
        );
        require(
            tokensEnabled[tokenIndex],
            "Token disabled."
        );
        uint amountToDeposit;
        if (tokenIndex==0) {
            amountToDeposit = msg.value;
        } else {
            amountToDeposit = amount;
        }
        uint minAmount;
        if (accounts.data[msg.sender].value.createdAt.length > 0) {
            minAmount = tokensMinRefillAmount[tokenIndex];
        } else {
            minAmount = tokensMinDepositAmount[tokenIndex];
        }
        require(
            amountToDeposit >= minAmount,
            "Amount too small."
        );
        require(
            amountToDeposit <= tokensMaxDepositAmount[tokenIndex],
            "Amount too big."
        );
        depositAmount(tokenIndex, amountToDeposit, false);
    }

    /**
     * @notice Creates the withdrawal order.
     * @param depositIndex representing the index of a deposit to be withdrawn from in user`s account
     * @param amount representing the amount to be ordered
     */
    function createOrder(uint depositIndex, uint amount) external whenNotPaused {
        require(
            depositIndex < accounts.data[msg.sender].value.createdAt.length,
            "Invalid deposit index."
        );
        uint tokenIndex = accounts.data[msg.sender].value.token[depositIndex];
        require(
            accounts.data[msg.sender].value.orderCreatedAt[depositIndex] == 0,
            "Withdrawal already ordered."
        );
        require(
            amount >= tokensMinWithdrawalAmount[tokenIndex],
            "Amount too small."
        );
        require(
            amount <= tokensMaxWithdrawalAmount[tokenIndex],
            "Amount too big."
        );
        accounts.data[msg.sender].value.orderCreatedAt[depositIndex] = block.timestamp;
        accounts.data[msg.sender].value.orderAmount[depositIndex] = amount;
        uint commissionAmount = getCommissionAmount(
            accounts.data[msg.sender].value.createdAt[depositIndex],
            accounts.data[msg.sender].value.orderCreatedAt[depositIndex],
            amount
        );

        emit WithdrawOrder(nextEventId(), msg.sender, depositIndex, tokenIndex, amount, commissionAmount);
    }

    /**
     * @notice Creates the withdrawal.
     * @param depositIndex representing the index of a deposit to be withdrawn from in user`s account
     */
    function createWithdraw(uint depositIndex) external whenNotPaused {
        require(
            depositIndex < accounts.data[msg.sender].value.createdAt.length,
            "Invalid deposit index."
        );
        require(
            accounts.data[msg.sender].value.orderCreatedAt[depositIndex] > 0,
            "Withdraw not ordered."
        );
        uint approvedTime = block.timestamp.sub(ORDER_CONFIRMATION_TIME);
        require(
            accounts.data[msg.sender].value.orderCreatedAt[depositIndex] <= approvedTime,
            "Withdraw order not approved."
        );
        uint amount = accounts.data[msg.sender].value.orderAmount[depositIndex];
        uint commissionAmount = getCommissionAmount(
            accounts.data[msg.sender].value.createdAt[depositIndex],
            accounts.data[msg.sender].value.orderCreatedAt[depositIndex],
            amount
        );

        accounts.data[msg.sender].value.orderCreatedAt[depositIndex] = 0;
        accounts.data[msg.sender].value.orderAmount[depositIndex] = 0;
        withdrawAmount(depositIndex, amount, commissionAmount, false);
    }

    /**
     * @notice Deposits working capital to contract.
     * @param tokenIndex representing the index of working capital deposit token in tokens array
     * @param amount representing the amount to be deposited
    */
    function depositWorkingCapital(uint tokenIndex, uint amount) external payable onlyOwner {
        uint amountToDeposit;
        if (tokenIndex==0) {
            amountToDeposit = msg.value;
        } else {
            amountToDeposit = amount;
        }
        depositAmount(tokenIndex, amountToDeposit, true);
    }

    /**
     * @notice Withdraws working capital from contract.
     * @param tokenIndex representing the index of working capital withdrawal token in tokens array
     * @param amount representing the amount to be withdrawn
    */
    function withdrawWorkingCapital(uint tokenIndex, uint amount) external onlyOwner {
        withdrawAmount(tokenIndex, amount, 0, true);
    }

    /**
     * @notice Provides the account information
     * @return the struct of caller account
    */
    function getAccountData() external view returns (Account memory) {
        return accounts.data[msg.sender].value;
    }

    /**
     * @notice Provides the available tokens and token's settings information.
     * @return the tokens addresses array
     * @return the min deposit amounts array
     * @return the min refill amounts array
     * @return the max deposit amounts array
     * @return the min withdrawal amounts array
     * @return the max withdrawal amounts array
     * @return the tokens enabled flags array
    */
    function getTokens()
        external
        view
        returns (
            address[] memory,
            uint[] memory,
            uint[] memory,
            uint[] memory,
            uint[] memory,
            uint[] memory,
            bool[] memory
        )
    {
        return (
        tokens,
        tokensMinDepositAmount,
        tokensMinRefillAmount,
        tokensMaxDepositAmount,
        tokensMinWithdrawalAmount,
        tokensMaxWithdrawalAmount,
        tokensEnabled
        );
    }

    /**
     * @notice Provides user accounts list.
     * @return the user's addresses array
     * @return the deposits creation time array
     * @return the deposits tokens indexes array
     * @return the deposits amounts array
     * @return the deposits withdrawal orders creation time array
     * @return the deposits withdrawal orders amounts array
    */
    function getAccounts()
        external
        view
        onlyOwner
        returns(
            address[] memory,
            uint[][] memory,
            uint[][] memory,
            uint[][] memory,
            uint[][] memory,
            uint[][] memory
        )
    {
        uint count = accounts.size;
        address[] memory addresses = new address[](count);
        uint[][] memory createdAt = new uint[][](count);
        uint[][] memory token = new uint[][](count);
        uint[][] memory amount = new uint[][](count);
        uint[][] memory orderCreatedAt = new uint[][](count);
        uint[][] memory orderAmount = new uint[][](count);
        uint index = 0;
        for (
            Iterator i = accounts.iterateStart();
            accounts.iterateValid(i);
            i = accounts.iterateNext(i)
        ) {
            (address key, ) = accounts.iterateGet(i);
            addresses[index] = key;
            createdAt[index] = accounts.data[key].value.createdAt;
            token[index] = accounts.data[key].value.token;
            amount[index] = accounts.data[key].value.amount;
            orderCreatedAt[index] = accounts.data[key].value.orderCreatedAt;
            orderAmount[index] = accounts.data[key].value.orderAmount;
            index++;
        }
        return (
            addresses,
            createdAt,
            token,
            amount,
            orderCreatedAt,
            orderAmount
        );
    }

    /**
     * @notice Provides the list of working capital amounts in tokens.
     * @return the working capital amounts array
    */
    function getWorkingCapital() external view onlyOwner returns(uint[] memory) {
        return workingCapital;
    }

    /**
     * @notice Checks whether the user is registered in the pool.
     * @return the registration status of user
    */
    function isRegistered(address user) public view returns (bool) {
        return accounts.contains(user);
    }

    /**
     * @notice Deposits amount to contract, registers an account if user is new.
     * @param tokenIndex representing the index of the new deposit's token in tokens array
     * @param amount representing the amount to be deposited
     * @param isWorkingCapital representing whether the deposit was a working capital
    */
    function depositAmount(uint tokenIndex, uint amount, bool isWorkingCapital) private {
        if (tokenIndex > 0) {
            IERC20 token = IERC20(tokens[tokenIndex]);
            uint allowance = token.allowance(msg.sender, address(this));
            uint balanceBeforeTransfer = token.balanceOf(address(this));
            require(
                allowance >= amount,
                "Check token allowance."
            );
            token.safeTransferFrom(msg.sender, address(this), amount);
            assert(
                token.balanceOf(address(this)) == balanceBeforeTransfer.add(amount)
            );
        }
        uint workingCapitalAmount;
        if (isWorkingCapital) {
            workingCapitalAmount = amount;
        } else {
            if (!accounts.contains(msg.sender)) {
                createNewAccount(msg.sender);
            }
            accounts.data[msg.sender].value.createdAt.push(block.timestamp);
            accounts.data[msg.sender].value.token.push(tokenIndex);
            accounts.data[msg.sender].value.amount.push(amount);
            accounts.data[msg.sender].value.orderCreatedAt.push(0);
            accounts.data[msg.sender].value.orderAmount.push(0);
            workingCapitalAmount = amount.mul(WORKING_CAPITAL_PERCENT).div(10**PERCENT_DECIMALS).div(100);
        }
        workingCapital[tokenIndex] = workingCapital[tokenIndex].add(workingCapitalAmount);
        uint depositIndex;
        if (!isWorkingCapital) {
            depositIndex = accounts.data[msg.sender].value.createdAt.length-1;
        }
        emit Deposit(
            nextEventId(),
            msg.sender,
            depositIndex,
            tokenIndex,
            amount,
            workingCapitalAmount,
            isWorkingCapital
        );
    }

    /**
     * @notice Withdraws amount from contract.
     * @param depositOrTokenIndex representing the index of deposit to be withdrawn in user's account
     * if the withdrawal is not working capital, or the index of token in tokens array if it is
     * @param amount representing the amount to be withdrawn
     * @param commissionAmount representing the commission amount to be retained
     * @param isWorkingCapital representing whether the withdrawal was a working capital
    */
    function withdrawAmount(
        uint depositOrTokenIndex,
        uint amount,
        uint commissionAmount,
        bool isWorkingCapital
    )
        private
    {
        uint tokenIndex;
        if (isWorkingCapital) {
            if (amount > workingCapital[depositOrTokenIndex]) revert InsufficientWorkingCapital({
                available: workingCapital[depositOrTokenIndex],
                required: amount
                });
            workingCapital[depositOrTokenIndex] = workingCapital[depositOrTokenIndex].sub(amount);
            tokenIndex = depositOrTokenIndex;
        } else {
            if (amount > accounts.data[msg.sender].value.amount[depositOrTokenIndex]) revert InsufficientFunds({
                available: accounts.data[msg.sender].value.amount[depositOrTokenIndex],
                required: amount
                });
            accounts.data[msg.sender].value.amount[depositOrTokenIndex] = accounts.data[msg.sender].value.amount[depositOrTokenIndex].sub(amount);
            tokenIndex = accounts.data[msg.sender].value.token[depositOrTokenIndex];
            if (commissionAmount > 0) {
                workingCapital[tokenIndex] = workingCapital[tokenIndex].add(commissionAmount);
            }
        }
        uint amountToTransfer = amount.sub(commissionAmount);
        if (tokenIndex == 0) {
            uint balanceBeforeTransfer = address(this).balance;
            (bool success, ) = payable(msg.sender).call{value: amountToTransfer}("");
            require(
                success,
                "Ether transfer failed."
                );
            assert(
                address(this).balance == balanceBeforeTransfer.sub(amountToTransfer)
                );
        } else {
            IERC20 token = IERC20(tokens[tokenIndex]);
            uint balanceBeforeTransfer = token.balanceOf(address(this));
            token.safeTransfer(msg.sender, amountToTransfer);
            assert(
                token.balanceOf(address(this)) == balanceBeforeTransfer.sub(amountToTransfer)
                );
        }
        emit Withdraw(
            nextEventId(),
            msg.sender,
            depositOrTokenIndex,
            tokenIndex,
            amount,
            commissionAmount,
            isWorkingCapital
        );
    }

    /**
     * @notice Creates a new user account.
     * @param user represents a new user's address
    */
    function createNewAccount(address user) private {
        Account memory newAccount;
        newAccount.createdAt = new uint[](0);
        newAccount.token = new uint[](0);
        newAccount.amount = new uint[](0);
        newAccount.orderCreatedAt = new uint[](0);
        newAccount.orderAmount = new uint[](0);
        accounts.insert(user, newAccount);
        emit Registration(nextEventId(), user);
    }

    /**
     * @notice Increments and provides a new event ID.
     * @return the new event ID
    */
    function nextEventId() private returns (uint) {
        eventId++;
        return eventId;
    }

    /**
     * @notice Computes commission amount at the current time.
     * @param depositAt representing the deposit creation time
     * @param orderAt representing the withdrawal order creation time
     * @param amount representing the amount to be withdrawn
     * @return the commission amount
    */
    function getCommissionAmount(uint depositAt, uint orderAt, uint amount) private view returns (uint) {
    uint result = 0;
        uint daysCount = orderAt.sub(depositAt).div(86400);
        if (daysCount < WITHDRAW_COMMISSION_PERIOD_DAYS) {
            result = amount
            .mul(WITHDRAW_COMMISSION_PERCENT_STEP_PER_DAY)
            .div(10 ** PERCENT_DECIMALS)
            .div(100)
            .mul(WITHDRAW_COMMISSION_PERIOD_DAYS - daysCount);
        }
    return result;
    }
}