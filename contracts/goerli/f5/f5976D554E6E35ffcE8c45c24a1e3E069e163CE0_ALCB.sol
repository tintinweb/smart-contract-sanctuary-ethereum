// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "contracts/interfaces/IBridgeRouter.sol";
import "contracts/utils/Admin.sol";
import "contracts/utils/Mutex.sol";
import "contracts/utils/MagicEthTransfer.sol";
import "contracts/utils/EthSafeTransfer.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutableDistribution.sol";
import "contracts/interfaces/IUtilityToken.sol";
import "contracts/libraries/errors/UtilityTokenErrors.sol";
import "contracts/libraries/math/Sigmoid.sol";

/// @custom:salt ALCB
/// @custom:deploy-type deployCreateAndRegister
/// @custom:deploy-group alcb
/// @custom:deploy-group-index 0
contract ALCB is
    IUtilityToken,
    ERC20,
    Mutex,
    MagicEthTransfer,
    EthSafeTransfer,
    Sigmoid,
    ImmutableFactory,
    ImmutableDistribution
{
    using Address for address;

    // multiply factor for the selling/minting bonding curve
    uint256 internal constant _MARKET_SPREAD = 4;

    // Address of the central bridge router contract
    address internal immutable _centralBridgeRouter;

    // Balance in ether that is hold in the contract after minting and burning
    uint256 internal _poolBalance;

    // Monotonically increasing variable to track the ALCBs deposits.
    uint256 internal _depositID;

    // Total amount of ALCBs that were deposited in the AliceNet chain. The
    // ALCBs deposited in the AliceNet are burned by this contract.
    uint256 internal _totalDeposited;

    // Tracks the amount of each deposit. Key is deposit id, value is amount
    // deposited.
    mapping(uint256 => Deposit) internal _deposits;

    // mapping to store allowed account types
    mapping(uint8 => bool) internal _accountTypes;

    /**
     * @notice Event emitted when a deposit is received
     */
    event DepositReceived(
        uint256 indexed depositID,
        uint8 indexed accountType,
        address indexed depositor,
        uint256 amount
    );

    constructor(
        address centralBridgeRouterAddress_
    ) ERC20("AliceNet Utility Token", "ALCB") ImmutableFactory(msg.sender) ImmutableDistribution() {
        if (centralBridgeRouterAddress_ == address(0)) {
            revert UtilityTokenErrors.CannotSetRouterToZeroAddress();
        }
        // initializing allowed account types: 1 for secp256k1 and 2 for BLS
        _accountTypes[1] = true;
        _accountTypes[2] = true;
        _centralBridgeRouter = centralBridgeRouterAddress_;
        _virtualDeposit(1, 0xba7809A4114eEF598132461f3202b5013e834CD5, 500000000000);
    }

    /**
     * @notice function to allow factory to add/set the allowed account types supported by AliceNet
     * blockchain.
     * @param accountType_ uint8 account type id to be added
     * @param allowed_ bool if a type should be enabled/disabled
     */
    function setAccountType(uint8 accountType_, bool allowed_) public onlyFactory {
        _accountTypes[accountType_] = allowed_;
    }

    /**
     * @notice Distributes the yields of the ALCB sale to all stakeholders
     * @return true if the method succeeded
     * */
    function distribute() public returns (bool) {
        return _distribute();
    }

    /**
     * @notice Deposits a ALCB amount into the AliceNet blockchain. The ALCBs amount is deducted
     * from the sender and it is burned by this contract. The created deposit Id is owned by the
     * `to_` address.
     * @param accountType_ The type of account the to_ address must be equivalent with ( 1 for Eth native, 2 for BN )
     * @param to_ The address of the account that will own the deposit
     * @param amount_ The amount of ALCBs to be deposited
     * @return The deposit ID of the deposit created
     */
    function deposit(uint8 accountType_, address to_, uint256 amount_) public returns (uint256) {
        return _deposit(accountType_, to_, amount_);
    }

    /**
     * @notice Allows deposits to be minted in a virtual manner and sent to the AliceNet chain by
     * simply emitting a Deposit event without actually minting or burning any tokens, must only be
     * called by _admin.
     * @param accountType_ The type of account the to_ address must be equivalent with ( 1 for Eth native, 2 for BN )
     * @param to_ The address of the account that will own the deposit
     * @param amount_ The amount of ALCBs to be deposited
     * @return The deposit ID of the deposit created
     */
    function virtualMintDeposit(
        uint8 accountType_,
        address to_,
        uint256 amount_
    ) public onlyFactory returns (uint256) {
        return _virtualDeposit(accountType_, to_, amount_);
    }

    /**
     * @notice Allows deposits to be minted and sent to the AliceNet chain without actually minting
     * or burning any ALCBs. This function receives ether and converts them directly into ALCB
     * and then deposit them into the AliceNet chain. This function has the same effect as calling
     * mint (creating the tokens) + deposit (burning the tokens) functions but it costs less gas.
     * @param accountType_ The type of account the to_ address must be equivalent with ( 1 for Eth native, 2 for BN )
     * @param to_ The address of the account that will own the deposit
     * @param minBTK_ The amount of ALCBs to be deposited
     * @return The deposit ID of the deposit created
     */
    function mintDeposit(
        uint8 accountType_,
        address to_,
        uint256 minBTK_
    ) public payable returns (uint256) {
        return _mintDeposit(accountType_, to_, minBTK_, msg.value);
    }

    /**
     * @notice Mints ALCB. This function receives ether in the transaction and converts them into
     * ALCB using a bonding price curve.
     * @param minBTK_ Minimum amount of ALCB that you wish to mint given an amount of ether. If
     * its not possible to mint the desired amount with the current price in the bonding curve, the
     * transaction is reverted. If the minBTK_ is met, the whole amount of ether sent will be
     * converted in ALCB.
     * @return numBTK the number of ALCB minted
     */
    function mint(uint256 minBTK_) public payable returns (uint256 numBTK) {
        numBTK = _mint(msg.sender, msg.value, minBTK_);
        return numBTK;
    }

    /**
     * @notice Mints ALCB. This function receives ether in the transaction and converts them into
     * ALCB using a bonding price curve.
     * @param to_ The account to where the tokens will be minted
     * @param minBTK_ Minimum amount of ALCB that you wish to mint given an
     * amount of ether. If its not possible to mint the desired amount with the
     * current price in the bonding curve, the transaction is reverted. If the
     * minBTK_ is met, the whole amount of ether sent will be converted in ALCB.
     * @return numBTK the number of ALCB minted
     */
    function mintTo(address to_, uint256 minBTK_) public payable returns (uint256 numBTK) {
        numBTK = _mint(to_, msg.value, minBTK_);
        return numBTK;
    }

    /**
     * @notice Burn the tokens without sending ether back to user as the normal burn
     * function. The generated ether will be distributed in the distribute method. This function can
     * be used to charge ALCBs fees in other systems.
     * @param numBTK_ the number of ALCB to be burned
     * @return true if the burn succeeded
     */
    function destroyTokens(uint256 numBTK_) public returns (bool) {
        _destroyTokens(msg.sender, numBTK_);
        return true;
    }

    /**
     * @notice Deposits arbitrary tokens in the bridge contracts. This function is an entry
     * point to deposit tokens (ERC20, ERC721, ERC1155) in the bridges and have
     * access to them in the side chain. This function will deduce from the user's
     * balance the corresponding amount of fees to deposit the tokens. The user has
     * the option to pay the fees in ALCB or Ether. If any ether is sent, the
     * function will deduce the fee amount and refund any extra amount. If no ether
     * is sent, the function will deduce the amount of ALCB corresponding to the
     * fees directly from the user's balance.
     * @param routerVersion_ The bridge version where to deposit the tokens.
     * @param data_ Encoded data necessary to deposit the arbitrary tokens in the bridges.
     * */
    function depositTokensOnBridges(uint8 routerVersion_, bytes calldata data_) public payable {
        //forward call to router
        uint256 alcbFee = IBridgeRouter(_centralBridgeRouter).routeDeposit(
            msg.sender,
            routerVersion_,
            data_
        );
        if (msg.value > 0) {
            uint256 ethFee = _getEthToMintTokens(totalSupply(), alcbFee);
            if (ethFee > msg.value) {
                revert UtilityTokenErrors.InsufficientFee(msg.value, ethFee);
            }
            uint256 refund;
            unchecked {
                refund = msg.value - ethFee;
            }
            if (refund > 0) {
                _safeTransferEth(msg.sender, refund);
            }
            return;
        }
        _destroyTokens(msg.sender, alcbFee);
    }

    /**
     * @notice Burn ALCB. This function sends ether corresponding to the amount of ALCBs being
     * burned using a bonding price curve.
     * @param amount_ The amount of ALCB being burned
     * @param minEth_ Minimum amount ether that you expect to receive given the
     * amount of ALCB being burned. If the amount of ALCB being burned
     * worth less than this amount the transaction is reverted.
     * @return numEth The number of ether being received
     * */
    function burn(uint256 amount_, uint256 minEth_) public returns (uint256 numEth) {
        numEth = _burn(msg.sender, msg.sender, amount_, minEth_);
        return numEth;
    }

    /**
     * @notice Burn ALCBs and send the ether received to an other account. This
     * function sends ether corresponding to the amount of ALCBs being
     * burned using a bonding price curve.
     * @param to_ The account to where the ether from the burning will be send
     * @param amount_ The amount of ALCBs being burned
     * @param minEth_ Minimum amount ether that you expect to receive given the
     * amount of ALCBs being burned. If the amount of ALCBs being burned
     * worth less than this amount the transaction is reverted.
     * @return numEth the number of ether being received
     * */
    function burnTo(address to_, uint256 amount_, uint256 minEth_) public returns (uint256 numEth) {
        numEth = _burn(msg.sender, to_, amount_, minEth_);
        return numEth;
    }

    /**
     * @notice Gets the address to the central router for the bridge system
     * @return The address to the central router
     */
    function getCentralBridgeRouterAddress() public view returns (address) {
        return _centralBridgeRouter;
    }

    /**
     * @notice Gets the amount that can be distributed as profits to the stakeholders contracts.
     * @return The amount that can be distributed as yield
     */
    function getYield() public view returns (uint256) {
        return address(this).balance - _poolBalance;
    }

    /**
     * @notice Gets the latest deposit ID emitted.
     * @return The latest deposit ID emitted
     */
    function getDepositID() public view returns (uint256) {
        return _depositID;
    }

    /**
     * @notice Gets the pool balance in ether.
     * @return The pool balance in ether
     */
    function getPoolBalance() public view returns (uint256) {
        return _poolBalance;
    }

    /**
     * @notice Gets the total amount of ALCBs that were deposited in the AliceNet
     * blockchain. Since ALCBs are burned when deposited, this value will be
     * different from the total supply of ALCBs.
     * @return The total amount of ALCBs that were deposited into the AliceNet chain.
     */
    function getTotalTokensDeposited() public view returns (uint256) {
        return _totalDeposited;
    }

    /**
     * @notice Gets the deposited amount given a depositID.
     * @param depositID The Id of the deposit
     * @return the deposit info given a depositID
     */
    function getDeposit(uint256 depositID) public view returns (Deposit memory) {
        Deposit memory d = _deposits[depositID];
        if (d.account == address(0)) {
            revert UtilityTokenErrors.InvalidDepositId(depositID);
        }

        return d;
    }

    /**
     * @notice Compute how many ether will be necessary to mint an amount of ALCBs in the
     * current state of the contract. Should be used carefully if its being called
     * outside an smart contract transaction, as the bonding curve state can change
     * before a future transaction is sent.
     * @param numBTK_ Amount of ALCBs that we want to convert in ether
     * @return numEth the number of ether necessary to mint an amount of ALCB
     */
    function getLatestEthToMintTokens(uint256 numBTK_) public view returns (uint256 numEth) {
        return _getEthToMintTokens(totalSupply(), numBTK_);
    }

    /**
     * @notice Compute how many ether will be received during a ALCB burn at the current
     * bonding curve state. Should be used carefully if its being called outside an
     * smart contract transaction, as the bonding curve state can change before a
     * future transaction is sent.
     * @param numBTK_ Amount of ALCBs to convert in ether
     * @return numEth the amount of ether will be received during a ALCB burn at the current
     * bonding curve state
     */
    function getLatestEthFromTokensBurn(uint256 numBTK_) public view returns (uint256 numEth) {
        return _tokensToEth(_poolBalance, totalSupply(), numBTK_);
    }

    /**
     * @notice Gets an amount of ALCBs that will be minted at the current state of the
     * bonding curve. Should be used carefully if its being called outside an smart
     * contract transaction, as the bonding curve state can change before a future
     * transaction is sent.
     * @param numEth_ Amount of ether to convert in ALCBs
     * @return the amount of ALCBs that will be minted at the current state of the
     * bonding curve
     * */
    function getLatestMintedTokensFromEth(uint256 numEth_) public view returns (uint256) {
        return _ethToTokens(_poolBalance, numEth_ / _MARKET_SPREAD);
    }

    /**
     * @notice Gets the market spread (difference between the minting and burning bonding
     * curves).
     * @return the market spread (difference between the minting and burning bonding
     * curves).
     * */
    function getMarketSpread() public pure returns (uint256) {
        return _MARKET_SPREAD;
    }

    /**
     * @notice Compute how many ether will be necessary to mint an amount of ALCBs at a
     * certain point in the bonding curve.
     * @param totalSupply_ The total supply of ALCB at a given moment where we
     * want to compute the amount of ether necessary to mint.
     * @param numBTK_ Amount of ALCBs that we want to convert in ether
     * @return numEth the amount ether that will be necessary to mint an amount of ALCBs at a
     * certain point in the bonding curve
     * */
    function getEthToMintTokens(
        uint256 totalSupply_,
        uint256 numBTK_
    ) public pure returns (uint256 numEth) {
        return _getEthToMintTokens(totalSupply_, numBTK_);
    }

    /**
     * @notice Compute how many ether will be received during a ALCB burn.
     * @param poolBalance_ The pool balance (in ether) at the moment
     * that of the conversion.
     * @param totalSupply_ The total supply of ALCB at the moment
     * that of the conversion.
     * @param numBTK_ Amount of ALCBs to convert in ether
     * @return numEth the ether that will be received during a ALCB burn
     * */
    function getEthFromTokensBurn(
        uint256 poolBalance_,
        uint256 totalSupply_,
        uint256 numBTK_
    ) public pure returns (uint256 numEth) {
        return _tokensToEth(poolBalance_, totalSupply_, numBTK_);
    }

    /**
     * @notice Gets an amount of ALCBs that will be minted at given a point in the bonding
     * curve.
     * @param poolBalance_ The pool balance (in ether) at the moment
     * that of the conversion.
     * @param numEth_ Amount of ether to convert in ALCBs
     * @return the amount of ALCBs that will be minted at given a point in the bonding
     * curve.
     * */
    function getMintedTokensFromEth(
        uint256 poolBalance_,
        uint256 numEth_
    ) public pure returns (uint256) {
        return _ethToTokens(poolBalance_, numEth_ / _MARKET_SPREAD);
    }

    /// Distributes the yields from the ALCB minting to all stake holders.
    function _distribute() internal withLock returns (bool) {
        // make a local copy to save gas
        uint256 poolBalance = _poolBalance;
        // find all value in excess of what is needed in pool
        uint256 excess = address(this).balance - poolBalance;
        if (excess == 0) {
            return true;
        }
        _safeTransferEthWithMagic(IMagicEthTransfer(_distributionAddress()), excess);
        if (address(this).balance < poolBalance) {
            revert UtilityTokenErrors.InvalidBalance(address(this).balance, poolBalance);
        }
        return true;
    }

    // Burn the tokens during deposits without sending ether back to user as the
    // normal burn function. The ether will be distributed in the distribute
    // method.
    function _destroyTokens(address account, uint256 numBTK_) internal returns (bool) {
        if (numBTK_ == 0) {
            revert UtilityTokenErrors.InvalidBurnAmount(numBTK_);
        }
        _poolBalance -= _tokensToEth(_poolBalance, totalSupply(), numBTK_);
        ERC20._burn(account, numBTK_);
        return true;
    }

    // Internal function that does the deposit in the AliceNet Chain, i.e emit the
    // event DepositReceived. All the ALCBs sent to this function are burned.
    function _deposit(uint8 accountType_, address to_, uint256 amount_) internal returns (uint256) {
        if (to_.isContract()) {
            revert UtilityTokenErrors.ContractsDisallowedDeposits(to_);
        }

        if (amount_ == 0) {
            revert UtilityTokenErrors.DepositAmountZero();
        }

        if (!_destroyTokens(msg.sender, amount_)) {
            revert UtilityTokenErrors.DepositBurnFail(amount_);
        }

        // copying state to save gas
        return _doDepositCommon(accountType_, to_, amount_);
    }

    // does a virtual deposit into the AliceNet Chain without actually minting or
    // burning any token.
    function _virtualDeposit(
        uint8 accountType_,
        address to_,
        uint256 amount_
    ) internal returns (uint256) {
        if (to_.isContract()) {
            revert UtilityTokenErrors.ContractsDisallowedDeposits(to_);
        }

        if (amount_ == 0) {
            revert UtilityTokenErrors.DepositAmountZero();
        }

        // copying state to save gas
        return _doDepositCommon(accountType_, to_, amount_);
    }

    // Mints a virtual deposit into the AliceNet Chain without actually minting or
    // burning any token. This function converts ether sent in ALCBs.
    function _mintDeposit(
        uint8 accountType_,
        address to_,
        uint256 minBTK_,
        uint256 numEth_
    ) internal returns (uint256) {
        if (to_.isContract()) {
            revert UtilityTokenErrors.ContractsDisallowedDeposits(to_);
        }
        if (numEth_ < _MARKET_SPREAD) {
            revert UtilityTokenErrors.MinimumValueNotMet(numEth_, _MARKET_SPREAD);
        }

        numEth_ = numEth_ / _MARKET_SPREAD;
        uint256 amount_ = _ethToTokens(_poolBalance, numEth_);
        if (amount_ < minBTK_) {
            revert UtilityTokenErrors.InsufficientEth(amount_, minBTK_);
        }

        return _doDepositCommon(accountType_, to_, amount_);
    }

    function _doDepositCommon(
        uint8 accountType_,
        address to_,
        uint256 amount_
    ) internal returns (uint256) {
        if (!_accountTypes[accountType_]) {
            revert UtilityTokenErrors.AccountTypeNotSupported(accountType_);
        }
        uint256 depositID = _depositID + 1;
        _deposits[depositID] = _newDeposit(accountType_, to_, amount_);
        _totalDeposited += amount_;
        _depositID = depositID;
        emit DepositReceived(depositID, accountType_, to_, amount_);
        return depositID;
    }

    // Internal function that mints the ALCB tokens following the bounding
    // price curve.
    function _mint(
        address to_,
        uint256 numEth_,
        uint256 minBTK_
    ) internal returns (uint256 numBTK) {
        if (numEth_ < _MARKET_SPREAD) {
            revert UtilityTokenErrors.MinimumValueNotMet(numEth_, _MARKET_SPREAD);
        }

        numEth_ = numEth_ / _MARKET_SPREAD;
        uint256 poolBalance = _poolBalance;
        numBTK = _ethToTokens(poolBalance, numEth_);
        if (numBTK < minBTK_) {
            revert UtilityTokenErrors.MinimumMintNotMet(numBTK, minBTK_);
        }

        poolBalance += numEth_;
        _poolBalance = poolBalance;
        ERC20._mint(to_, numBTK);
        return numBTK;
    }

    // Internal function that burns the ALCB tokens following the bounding
    // price curve.
    function _burn(
        address from_,
        address to_,
        uint256 numBTK_,
        uint256 minEth_
    ) internal returns (uint256 numEth) {
        if (numBTK_ == 0) {
            revert UtilityTokenErrors.InvalidBurnAmount(numBTK_);
        }

        uint256 poolBalance = _poolBalance;
        numEth = _tokensToEth(poolBalance, totalSupply(), numBTK_);

        if (numEth < minEth_) {
            revert UtilityTokenErrors.MinimumBurnNotMet(numEth, minEth_);
        }

        poolBalance -= numEth;
        _poolBalance = poolBalance;
        ERC20._burn(from_, numBTK_);
        _safeTransferEth(to_, numEth);
        return numEth;
    }

    // Internal function that converts an ether amount into ALCB tokens
    // following the bounding price curve.
    function _ethToTokens(uint256 poolBalance_, uint256 numEth_) internal pure returns (uint256) {
        return _p(poolBalance_ + numEth_) - _p(poolBalance_);
    }

    // Internal function that converts a ALCB amount into ether following the
    // bounding price curve.
    function _tokensToEth(
        uint256 poolBalance_,
        uint256 totalSupply_,
        uint256 numBTK_
    ) internal pure returns (uint256 numEth) {
        if (totalSupply_ < numBTK_) {
            revert UtilityTokenErrors.BurnAmountExceedsSupply(numBTK_, totalSupply_);
        }
        return _min(poolBalance_, _pInverse(totalSupply_) - _pInverse(totalSupply_ - numBTK_));
    }

    // Internal function to compute the amount of ether required to mint an amount
    // of ALCBs. Inverse of the _ethToALCBs function.
    function _getEthToMintTokens(
        uint256 totalSupply_,
        uint256 numBTK_
    ) internal pure returns (uint256 numEth) {
        return (_pInverse(totalSupply_ + numBTK_) - _pInverse(totalSupply_)) * _MARKET_SPREAD;
    }

    function _newDeposit(
        uint8 accountType_,
        address account_,
        uint256 value_
    ) internal pure returns (Deposit memory) {
        Deposit memory d = Deposit(accountType_, account_, value_);
        return d;
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface IBridgeRouter {
    function routeDeposit(
        address account_,
        uint8 routerVersion_,
        bytes calldata data_
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface IMagicEthTransfer {
    function depositEth(uint8 magic_) external payable;
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

struct Deposit {
    uint8 accountType;
    address account;
    uint256 value;
}

interface IUtilityToken {
    function distribute() external returns (bool);

    function deposit(uint8 accountType_, address to_, uint256 amount_) external returns (uint256);

    function virtualMintDeposit(
        uint8 accountType_,
        address to_,
        uint256 amount_
    ) external returns (uint256);

    function mintDeposit(
        uint8 accountType_,
        address to_,
        uint256 minBTK_
    ) external payable returns (uint256);

    function mint(uint256 minBTK_) external payable returns (uint256 numBTK);

    function mintTo(address to_, uint256 minBTK_) external payable returns (uint256 numBTK);

    function destroyTokens(uint256 numBTK_) external returns (bool);

    function depositTokensOnBridges(uint8 routerVersion_, bytes calldata data_) external payable;

    function burn(uint256 amount_, uint256 minEth_) external returns (uint256 numEth);

    function burnTo(
        address to_,
        uint256 amount_,
        uint256 minEth_
    ) external returns (uint256 numEth);

    function getYield() external view returns (uint256);

    function getDepositID() external view returns (uint256);

    function getPoolBalance() external view returns (uint256);

    function getTotalTokensDeposited() external view returns (uint256);

    function getDeposit(uint256 depositID) external view returns (Deposit memory);

    function getLatestEthToMintTokens(uint256 numBTK_) external view returns (uint256 numEth);

    function getLatestEthFromTokensBurn(uint256 numBTK_) external view returns (uint256 numEth);

    function getLatestMintedTokensFromEth(uint256 numEth_) external view returns (uint256);

    function getMarketSpread() external pure returns (uint256);

    function getEthToMintTokens(
        uint256 totalSupply_,
        uint256 numBTK_
    ) external pure returns (uint256 numEth);

    function getEthFromTokensBurn(
        uint256 poolBalance_,
        uint256 totalSupply_,
        uint256 numBTK_
    ) external pure returns (uint256 numEth);

    function getMintedTokensFromEth(
        uint256 poolBalance_,
        uint256 numEth_
    ) external pure returns (uint256);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library AdminErrors {
    error SenderNotAdmin(address sender);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library ETHSafeTransferErrors {
    error CannotTransferToZeroAddress();
    error EthTransferFailed(address from, address to, uint256 amount);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library MagicValueErrors {
    error BadMagic(uint256 magic);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library MutexErrors {
    error MutexLocked();
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library UtilityTokenErrors {
    error InvalidDepositId(uint256 depositID);
    error InvalidBalance(uint256 contractBalance, uint256 poolBalance);
    error InvalidBurnAmount(uint256 amount);
    error ContractsDisallowedDeposits(address toAddress);
    error DepositAmountZero();
    error DepositBurnFail(uint256 amount);
    error MinimumValueNotMet(uint256 amount, uint256 minimumValue);
    error InsufficientEth(uint256 amount, uint256 minimum);
    error MinimumMintNotMet(uint256 amount, uint256 minimum);
    error MinimumBurnNotMet(uint256 amount, uint256 minimum);
    error BurnAmountExceedsSupply(uint256 amount, uint256 supply);
    error InexistentRouterContract(address contractAddr);
    error InsufficientFee(uint256 amount, uint256 fee);
    error CannotSetRouterToZeroAddress();
    error AccountTypeNotSupported(uint8 accountType);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

abstract contract Sigmoid {
    // Constants for P function
    uint256 internal constant _P_A = 200;
    uint256 internal constant _P_B = 2500 * 10 ** 18;
    uint256 internal constant _P_C = 5611050234958650739260304 + 125 * 10 ** 39;
    uint256 internal constant _P_D = 4;
    uint256 internal constant _P_S = 2524876234590519489452;

    // Constants for P Inverse function
    uint256 internal constant _P_INV_C_1 = _P_A * ((_P_A + _P_D) * _P_S + _P_A * _P_B);
    uint256 internal constant _P_INV_C_2 = _P_A + _P_D;
    uint256 internal constant _P_INV_C_3 = _P_D * (2 * _P_A + _P_D);
    uint256 internal constant _P_INV_D_0 = ((_P_A + _P_D) * _P_S + _P_A * _P_B) ** 2;
    uint256 internal constant _P_INV_D_1 = 2 * (_P_A * _P_S + (_P_A + _P_D) * _P_B);

    function _p(uint256 t) internal pure returns (uint256) {
        return
            (_P_A + _P_D) *
            t +
            (_P_A * _P_S) -
            _sqrt(_P_A ** 2 * ((_safeAbsSub(_P_B, t)) ** 2 + _P_C));
    }

    function _pInverse(uint256 m) internal pure returns (uint256) {
        return
            (_P_INV_C_2 *
                m +
                _sqrt(_P_A ** 2 * (m ** 2 + _P_INV_D_0 - _P_INV_D_1 * m)) -
                _P_INV_C_1) / _P_INV_C_3;
    }

    function _safeAbsSub(uint256 a, uint256 b) internal pure returns (uint256) {
        return _max(a, b) - _min(a, b);
    }

    function _min(uint256 a_, uint256 b_) internal pure returns (uint256) {
        if (a_ <= b_) {
            return a_;
        }
        return b_;
    }

    function _max(uint256 a_, uint256 b_) internal pure returns (uint256) {
        if (a_ >= b_) {
            return a_;
        }
        return b_;
    }

    function _sqrt(uint256 x) internal pure returns (uint256) {
        unchecked {
            if (x <= 1) {
                return x;
            }
            if (x >= ((1 << 128) - 1) ** 2) {
                return (1 << 128) - 1;
            }
            // Here, e represents the bit length;
            // its value is at most 256, so it could fit in a uint16.
            uint256 e = 1;
            // Here, result is a copy of x to compute the bit length
            uint256 result = x;
            if (result >= (1 << 128)) {
                result >>= 128;
                e += 128;
            }
            if (result >= (1 << 64)) {
                result >>= 64;
                e += 64;
            }
            if (result >= (1 << 32)) {
                result >>= 32;
                e += 32;
            }
            if (result >= (1 << 16)) {
                result >>= 16;
                e += 16;
            }
            if (result >= (1 << 8)) {
                result >>= 8;
                e += 8;
            }
            if (result >= (1 << 4)) {
                result >>= 4;
                e += 4;
            }
            if (result >= (1 << 2)) {
                result >>= 2;
                e += 2;
            }
            if (result >= (1 << 1)) {
                e += 1;
            }
            // e is currently bit length; we overwrite it to scale x
            e = (256 - e) >> 1;
            // m now satisfies 2**254 <= m < 2**256
            uint256 m = x << (2 * e);
            // result now stores the result
            result = 1 + (m >> 254);
            result = (result << 1) + (m >> 251) / result;
            result = (result << 3) + (m >> 245) / result;
            result = (result << 7) + (m >> 233) / result;
            result = (result << 15) + (m >> 209) / result;
            result = (result << 31) + (m >> 161) / result;
            result = (result << 63) + (m >> 65) / result;
            result >>= e;
            return result * result <= x ? result : (result - 1);
        }
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;
import "contracts/libraries/errors/AdminErrors.sol";

abstract contract Admin {
    // _admin is a privileged role
    address internal _admin;

    /// @dev onlyAdmin enforces msg.sender is _admin
    modifier onlyAdmin() {
        if (msg.sender != _admin) {
            revert AdminErrors.SenderNotAdmin(msg.sender);
        }
        _;
    }

    constructor(address admin_) {
        _admin = admin_;
    }

    /// @dev assigns a new admin may only be called by _admin
    function setAdmin(address admin_) public virtual onlyAdmin {
        _setAdmin(admin_);
    }

    /// @dev getAdmin returns the current _admin
    function getAdmin() public view returns (address) {
        return _admin;
    }

    // assigns a new admin may only be called by _admin
    function _setAdmin(address admin_) internal {
        _admin = admin_;
    }
}

// This file is auto-generated by hardhat generate-immutable-auth-contract task. DO NOT EDIT.
// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/DeterministicAddress.sol";
import "contracts/utils/auth/ImmutableFactory.sol";

abstract contract ImmutableDistribution is ImmutableFactory {
    address private immutable _distribution;
    error OnlyDistribution(address sender, address expected);

    modifier onlyDistribution() {
        if (msg.sender != _distribution) {
            revert OnlyDistribution(msg.sender, _distribution);
        }
        _;
    }

    constructor() {
        _distribution = getMetamorphicContractAddress(
            0x446973747269627574696f6e0000000000000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _distributionAddress() internal view returns (address) {
        return _distribution;
    }

    function _saltForDistribution() internal pure returns (bytes32) {
        return 0x446973747269627574696f6e0000000000000000000000000000000000000000;
    }
}

// This file is auto-generated by hardhat generate-immutable-auth-contract task. DO NOT EDIT.
// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/DeterministicAddress.sol";

abstract contract ImmutableFactory is DeterministicAddress {
    address private immutable _factory;
    error OnlyFactory(address sender, address expected);

    modifier onlyFactory() {
        if (msg.sender != _factory) {
            revert OnlyFactory(msg.sender, _factory);
        }
        _;
    }

    constructor(address factory_) {
        _factory = factory_;
    }

    function _factoryAddress() internal view returns (address) {
        return _factory;
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

abstract contract DeterministicAddress {
    function getMetamorphicContractAddress(
        bytes32 _salt,
        address _factory
    ) public pure returns (address) {
        // byte code for metamorphic contract
        // 6020363636335afa1536363636515af43d36363e3d36f3
        bytes32 metamorphicContractBytecodeHash_ = 0x1c0bf703a3415cada9785e89e9d70314c3111ae7d8e04f33bb42eb1d264088be;
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                hex"ff",
                                _factory,
                                _salt,
                                metamorphicContractBytecodeHash_
                            )
                        )
                    )
                )
            );
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;
import "contracts/libraries/errors/ETHSafeTransferErrors.sol";

abstract contract EthSafeTransfer {
    /// @notice _safeTransferEth performs a transfer of Eth using the call
    /// method / this function is resistant to breaking gas price changes and /
    /// performs call in a safe manner by reverting on failure. / this function
    /// will return without performing a call or reverting, / if amount_ is zero
    function _safeTransferEth(address to_, uint256 amount_) internal {
        if (amount_ == 0) {
            return;
        }
        if (to_ == address(0)) {
            revert ETHSafeTransferErrors.CannotTransferToZeroAddress();
        }
        address payable caller = payable(to_);
        (bool success, ) = caller.call{value: amount_}("");
        if (!success) {
            revert ETHSafeTransferErrors.EthTransferFailed(address(this), to_, amount_);
        }
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/MagicValue.sol";
import "contracts/interfaces/IMagicEthTransfer.sol";

abstract contract MagicEthTransfer is MagicValue {
    function _safeTransferEthWithMagic(IMagicEthTransfer to_, uint256 amount_) internal {
        to_.depositEth{value: amount_}(_getMagic());
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;
import "contracts/libraries/errors/MagicValueErrors.sol";

abstract contract MagicValue {
    // _MAGIC_VALUE is a constant that may be used to prevent
    // a user from calling a dangerous method without significant
    // effort or ( hopefully ) reading the code to understand the risk
    uint8 internal constant _MAGIC_VALUE = 42;

    modifier checkMagic(uint8 magic_) {
        if (magic_ != _getMagic()) {
            revert MagicValueErrors.BadMagic(magic_);
        }
        _;
    }

    // _getMagic returns the magic constant
    function _getMagic() internal pure returns (uint8) {
        return _MAGIC_VALUE;
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/errors/MutexErrors.sol";

abstract contract Mutex {
    uint256 internal constant _LOCKED = 1;
    uint256 internal constant _UNLOCKED = 2;
    uint256 internal _mutex;

    modifier withLock() {
        if (_mutex == _LOCKED) {
            revert MutexErrors.MutexLocked();
        }
        _mutex = _LOCKED;
        _;
        _mutex = _UNLOCKED;
    }
}