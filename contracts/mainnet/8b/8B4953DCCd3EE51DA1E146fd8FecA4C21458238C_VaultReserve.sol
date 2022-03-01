// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import "SafeERC20.sol";
import "IERC20.sol";

import "IVaultReserve.sol";
import "Errors.sol";

import "Admin.sol";
import "Vault.sol";

/**
 * @notice Contract holding vault reserves
 * @dev ETH reserves are stored under address(0)
 */
contract VaultReserve is IVaultReserve, Admin {
    using SafeERC20 for IERC20;

    mapping(address => bool) private _whitelistedVaults;
    mapping(address => mapping(address => uint256)) private _balances;

    modifier onlyVault() {
        require(_whitelistedVaults[msg.sender], Error.UNAUTHORIZED_ACCESS);
        _;
    }

    constructor() Admin(msg.sender) {}

    /**
     * @notice Deposit funds into vault reserve.
     * @notice Only callable by a whitelisted vault.
     * @param token Token to deposit.
     * @param amount Amount to deposit.
     * @return True if deposit was successful.
     */
    function deposit(address token, uint256 amount)
        external
        payable
        override
        onlyVault
        returns (bool)
    {
        if (token == address(0)) {
            require(msg.value == amount, Error.INVALID_AMOUNT);
            _balances[msg.sender][token] += msg.value;
            return true;
        }
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        uint256 newBalance = IERC20(token).balanceOf(address(this));
        uint256 received = newBalance - balance;
        require(received >= amount, Error.INVALID_AMOUNT);
        _balances[msg.sender][token] += received;
        emit Deposit(msg.sender, token, amount);
        return true;
    }

    /**
     * @notice Withdraw funds from vault reserve.
     * @notice Only callable by a whitelisted vault.
     * @param token Token to withdraw.
     * @param amount Amount to withdraw.
     * @return True if withdrawal was successful.
     */
    function withdraw(address token, uint256 amount) external override onlyVault returns (bool) {
        uint256 accountBalance = _balances[msg.sender][token];
        require(accountBalance >= amount, Error.INSUFFICIENT_BALANCE);

        _balances[msg.sender][token] -= amount;
        if (token == address(0)) {
            payable(msg.sender).transfer(amount);
        } else {
            IERC20(token).safeTransfer(msg.sender, amount);
        }
        emit Withdraw(msg.sender, token, amount);
        return true;
    }

    /**
     * @notice Whitelist a new vault.
     * @notice Only callable by admin.
     * @param vault Vault to whitelist.
     * @return True if whitelisting was successful.
     */
    function whitelistVault(address vault) external onlyAdmin returns (bool) {
        require(_whitelistedVaults[vault] == false, Error.ADDRESS_WHITELISTED);
        _whitelistedVaults[vault] = true;
        emit VaultListed(vault);
        return true;
    }

    /**
     * @notice Check if a vault is whitelisted.
     * @param vault Vault to whitelist.
     * @return If vault is whitelisted.
     */
    function isWhitelisted(address vault) public view override returns (bool) {
        return _whitelistedVaults[vault];
    }

    /**
     * @notice Check token balance of a specific vault.
     * @param vault Vault to check balance of.
     * @param token Token to check balance in.
     * @return Token balance of vault.
     */
    function getBalance(address vault, address token) public view override returns (uint256) {
        return _balances[vault][token];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

interface IVaultReserve {
    event Deposit(address indexed vault, address indexed token, uint256 amount);
    event Withdraw(address indexed vault, address indexed token, uint256 amount);
    event VaultListed(address indexed vault);

    function deposit(address token, uint256 amount) external payable returns (bool);

    function whitelistVault(address vault) external returns (bool);

    function withdraw(address token, uint256 amount) external returns (bool);

    function isWhitelisted(address vault) external view returns (bool);

    function getBalance(address vault, address token) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

// solhint-disable private-vars-leading-underscore

library Error {
    string internal constant ADDRESS_WHITELISTED = "address already whitelisted";
    string internal constant ADMIN_ALREADY_SET = "admin has already been set once";
    string internal constant ADDRESS_NOT_WHITELISTED = "address not whitelisted";
    string internal constant ADDRESS_NOT_FOUND = "address not found";
    string internal constant CONTRACT_INITIALIZED = "contract can only be initialized once";
    string internal constant CONTRACT_PAUSED = "contract is paused";
    string internal constant INVALID_AMOUNT = "invalid amount";
    string internal constant INVALID_INDEX = "invalid index";
    string internal constant INVALID_VALUE = "invalid msg.value";
    string internal constant INVALID_SENDER = "invalid msg.sender";
    string internal constant INVALID_TOKEN = "token address does not match pool's LP token address";
    string internal constant INVALID_DECIMALS = "incorrect number of decimals";
    string internal constant INVALID_ARGUMENT = "invalid argument";
    string internal constant INVALID_PARAMETER_VALUE = "invalid parameter value attempted";
    string internal constant INVALID_IMPLEMENTATION = "invalid pool implementation for given coin";
    string internal constant INVALID_POOL_IMPLEMENTATION =
        "invalid pool implementation for given coin";
    string internal constant INVALID_LP_TOKEN_IMPLEMENTATION =
        "invalid LP Token implementation for given coin";
    string internal constant INVALID_VAULT_IMPLEMENTATION =
        "invalid vault implementation for given coin";
    string internal constant INVALID_STAKER_VAULT_IMPLEMENTATION =
        "invalid stakerVault implementation for given coin";
    string internal constant INSUFFICIENT_BALANCE = "insufficient balance";
    string internal constant ADDRESS_ALREADY_SET = "Address is already set";
    string internal constant INSUFFICIENT_STRATEGY_BALANCE = "insufficient strategy balance";
    string internal constant INSUFFICIENT_FUNDS_RECEIVED = "insufficient funds received";
    string internal constant ROLE_EXISTS = "role already exists";
    string internal constant UNAUTHORIZED_ACCESS = "unauthorized access";
    string internal constant SAME_ADDRESS_NOT_ALLOWED = "same address not allowed";
    string internal constant SELF_TRANSFER_NOT_ALLOWED = "self-transfer not allowed";
    string internal constant ZERO_ADDRESS_NOT_ALLOWED = "zero address not allowed";
    string internal constant ZERO_TRANSFER_NOT_ALLOWED = "zero transfer not allowed";
    string internal constant THRESHOLD_TOO_HIGH = "threshold is too high, must be under 10";
    string internal constant INSUFFICIENT_THRESHOLD = "insufficient threshold";
    string internal constant NO_POSITION_EXISTS = "no position exists";
    string internal constant POSITION_ALREADY_EXISTS = "position already exists";
    string internal constant PROTOCOL_NOT_FOUND = "protocol not found";
    string internal constant TOP_UP_FAILED = "top up failed";
    string internal constant SWAP_PATH_NOT_FOUND = "swap path not found";
    string internal constant UNDERLYING_NOT_SUPPORTED = "underlying token not supported";
    string internal constant NOT_ENOUGH_FUNDS_WITHDRAWN =
        "not enough funds were withdrawn from the pool";
    string internal constant FAILED_TRANSFER = "transfer failed";
    string internal constant FAILED_MINT = "mint failed";
    string internal constant FAILED_REPAY_BORROW = "repay borrow failed";
    string internal constant FAILED_METHOD_CALL = "method call failed";
    string internal constant NOTHING_TO_CLAIM = "there is no claimable balance";
    string internal constant ERC20_BALANCE_EXCEEDED = "ERC20: transfer amount exceeds balance";
    string internal constant INVALID_MINTER =
        "the minter address of the LP token and the pool address do not match";
    string internal constant STAKER_VAULT_EXISTS = "a staker vault already exists for the token";
    string internal constant DEADLINE_NOT_ZERO = "deadline must be 0";
    string internal constant DEADLINE_NOT_SET = "deadline is 0";
    string internal constant DEADLINE_NOT_REACHED = "deadline has not been reached yet";
    string internal constant DELAY_TOO_SHORT = "delay be at least 3 days";
    string internal constant INSUFFICIENT_UPDATE_BALANCE =
        "insufficient funds for updating the position";
    string internal constant SAME_AS_CURRENT = "value must be different to existing value";
    string internal constant NOT_CAPPED = "the pool is not currently capped";
    string internal constant ALREADY_CAPPED = "the pool is already capped";
    string internal constant EXCEEDS_DEPOSIT_CAP = "deposit exceeds deposit cap";
    string internal constant VALUE_TOO_LOW_FOR_GAS = "value too low to cover gas";
    string internal constant NOT_ENOUGH_FUNDS = "not enough funds to withdraw";
    string internal constant ESTIMATED_GAS_TOO_HIGH = "too much ETH will be used for gas";
    string internal constant DEPOSIT_FAILED = "deposit failed";
    string internal constant GAS_TOO_HIGH = "too much ETH used for gas";
    string internal constant GAS_BANK_BALANCE_TOO_LOW = "not enough ETH in gas bank to cover gas";
    string internal constant INVALID_TOKEN_TO_ADD = "Invalid token to add";
    string internal constant INVALID_TOKEN_TO_REMOVE = "token can not be removed";
    string internal constant TIME_DELAY_NOT_EXPIRED = "time delay not expired yet";
    string internal constant UNDERLYING_NOT_WITHDRAWABLE =
        "pool does not support additional underlying coins to be withdrawn";
    string internal constant STRATEGY_SHUT_DOWN = "Strategy is shut down";
    string internal constant STRATEGY_DOES_NOT_EXIST = "Strategy does not exist";
    string internal constant UNSUPPORTED_UNDERLYING = "Underlying not supported";
    string internal constant NO_DEX_SET = "no dex has been set for token";
    string internal constant INVALID_TOKEN_PAIR = "invalid token pair";
    string internal constant TOKEN_NOT_USABLE = "token not usable for the specific action";
    string internal constant ADDRESS_NOT_ACTION = "address is not registered action";
    string internal constant INVALID_SLIPPAGE_TOLERANCE = "Invalid slippage tolerance";
    string internal constant POOL_NOT_PAUSED = "Pool must be paused to withdraw from reserve";
    string internal constant INTERACTION_LIMIT = "Max of one deposit and withdraw per block";
    string internal constant GAUGE_EXISTS = "Gauge already exists";
    string internal constant GAUGE_DOES_NOT_EXIST = "Gauge does not exist";
    string internal constant EXCEEDS_MAX_BOOST = "Not allowed to exceed maximum boost on Convex";
    string internal constant PREPARED_WITHDRAWAL =
        "Cannot relock funds when withdrawal is being prepared";
    string internal constant ASSET_NOT_SUPPORTED = "Asset not supported";
    string internal constant STALE_PRICE = "Price is stale";
    string internal constant NEGATIVE_PRICE = "Price is negative";
    string internal constant NOT_ENOUGH_BKD_STAKED = "Not enough BKD tokens staked";
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import "AdminBase.sol";

contract Admin is AdminBase {
    constructor(address _admin) {
        _addAdmin(_admin);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import "EnumerableSet.sol";

import "Errors.sol";
import "IAdmin.sol";

abstract contract AdminBase is IAdmin {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet internal _admins;

    /**
     * @notice Make a function only callable by admins.
     * @dev Fails if msg.sender is not an admin.
     */
    modifier onlyAdmin() {
        require(isAdmin(msg.sender), Error.UNAUTHORIZED_ACCESS);
        _;
    }

    /**
     * @notice Remove msg.sender from admin list.
     * @return `true` if sucessful.
     */
    function renounceAdmin() external override onlyAdmin returns (bool) {
        _admins.remove(msg.sender);
        emit AdminRenounced(msg.sender);
        return true;
    }

    /**
     * @notice Add a new admin.
     * @dev This fails if the newAdmin was added previously.
     * @param newAdmin Address to add as admin.
     * @return `true` if successful.
     */
    function addAdmin(address newAdmin) public override onlyAdmin returns (bool) {
        require(_addAdmin(newAdmin), Error.ROLE_EXISTS);
        return true;
    }

    /**
     * @return a list of all admins for this contract
     */
    function admins() public view override returns (address[] memory) {
        uint256 len = _admins.length();
        address[] memory allAdmins = new address[](len);
        for (uint256 i = 0; i < len; i++) {
            allAdmins[i] = _admins.at(i);
        }
        return allAdmins;
    }

    /**
     * @notice Check if an account is admin.
     * @param account Address to check.
     * @return `true` if account is an admin.
     */
    function isAdmin(address account) public view override returns (bool) {
        return _isAdmin(account);
    }

    function _addAdmin(address newAdmin) internal returns (bool) {
        if (_admins.add(newAdmin)) {
            emit NewAdminAdded(newAdmin);
            return true;
        }
        return false;
    }

    function _isAdmin(address account) internal view returns (bool) {
        return _admins.contains(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

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
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

interface IAdmin {
    event NewAdminAdded(address newAdmin);
    event AdminRenounced(address oldAdmin);

    function admins() external view returns (address[] memory);

    function addAdmin(address newAdmin) external returns (bool);

    function renounceAdmin() external returns (bool);

    function isAdmin(address account) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import "SafeERC20.sol";
import "Initializable.sol";
import "IERC20.sol";

import "ILiquidityPool.sol";
import "IVault.sol";
import "IVaultReserve.sol";
import "IController.sol";
import "IStrategy.sol";

import "ScaledMath.sol";
import "Errors.sol";
import "EnumerableExtensions.sol";
import "AddressProviderHelpers.sol";

import "VaultStorage.sol";
import "Preparable.sol";
import "IPausable.sol";
import "AdminUpgradeable.sol";

abstract contract Vault is IVault, AdminUpgradeable, VaultStorageV1, Preparable, Initializable {
    using ScaledMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableExtensions for EnumerableSet.AddressSet;
    using EnumerableMapping for EnumerableMapping.AddressToUintMap;
    using EnumerableExtensions for EnumerableMapping.AddressToUintMap;
    using AddressProviderHelpers for IAddressProvider;

    bytes32 internal constant _STRATEGY_KEY = "Strategy";
    bytes32 internal constant _PERFORMANCE_FEE_KEY = "PerformanceFee";
    bytes32 internal constant _STRATEGIST_FEE_KEY = "StrategistFee";
    bytes32 internal constant _DEBT_LIMIT_KEY = "DebtLimit";
    bytes32 internal constant _TARGET_ALLOCATION_KEY = "TargetAllocation";
    bytes32 internal constant _RESERVE_FEE_KEY = "ReserveFee";
    bytes32 internal constant _BOUND_KEY = "Bound";

    uint256 internal constant _INITIAL_RESERVE_FEE = DECIMAL_SCALE / 100;
    uint256 internal constant _INITIAL_STRATEGIST_FEE = DECIMAL_SCALE / 10;
    uint256 internal constant _INITIAL_PERFORMANCE_FEE = (DECIMAL_SCALE * 5) / 100;

    uint256 public constant DECIMAL_SCALE = 1e18;
    uint256 public constant MAX_PERFORMANCE_FEE = 0.5e18;
    uint256 public constant MAX_DEVIATION_BOUND = 0.5e18;
    uint256 public constant STRATEGY_DELAY = 5 days;

    IController public immutable controller;
    IVaultReserve public immutable reserve;

    constructor(address _controller) {
        controller = IController(_controller);
        reserve = IVaultReserve(IController(_controller).addressProvider().getVaultReserve());
    }

    function initialize(
        address _pool,
        uint256 _debtLimit,
        uint256 _targetAllocation,
        uint256 _bound
    ) external virtual override initializer {
        require(_debtLimit <= DECIMAL_SCALE, Error.INVALID_AMOUNT);
        require(_targetAllocation <= DECIMAL_SCALE, Error.INVALID_AMOUNT);
        require(_bound <= MAX_DEVIATION_BOUND, Error.INVALID_AMOUNT);

        _initializeAdmin(msg.sender);
        pool = _pool;

        _setConfig(_DEBT_LIMIT_KEY, _debtLimit);
        _setConfig(_TARGET_ALLOCATION_KEY, _targetAllocation);
        _setConfig(_BOUND_KEY, _bound);
        _setConfig(_RESERVE_FEE_KEY, _INITIAL_RESERVE_FEE);
        _setConfig(_STRATEGIST_FEE_KEY, _INITIAL_STRATEGIST_FEE);
        _setConfig(_PERFORMANCE_FEE_KEY, _INITIAL_PERFORMANCE_FEE);
    }

    /**
     * @notice Handles deposits from the liquidity pool
     */
    function deposit() external payable override onlyAdmin {
        _deposit();
    }

    /**
     * @notice Withdraws specified amount of underlying from vault.
     * @dev If the specified amount exceeds idle funds, an amount of funds is withdrawn
     *      from the strategy such that it will achieve a target allocation for after the
     *      amount has been withdrawn.
     * @param amount Amount to withdraw.
     * @return `true` if successful.
     */
    function withdraw(uint256 amount) external override onlyAdmin returns (bool) {
        IStrategy strategy = getStrategy();
        uint256 availableUnderlying_ = _availableUnderlying();

        if (availableUnderlying_ < amount) {
            if (address(strategy) == address(0)) return false;
            uint256 allocated = strategy.balance();
            uint256 requiredWithdrawal = amount - availableUnderlying_;

            if (requiredWithdrawal > allocated) return false;

            // compute withdrawal amount to sustain target allocation
            uint256 newTarget = (allocated - requiredWithdrawal).scaledMul(getTargetAllocation());
            uint256 excessAmount = allocated - newTarget;
            strategy.withdraw(excessAmount);
            currentAllocated = _computeNewAllocated(currentAllocated, excessAmount);
        } else {
            uint256 allocatedUnderlying = 0;
            if (address(strategy) != address(0))
                allocatedUnderlying = IStrategy(strategy).balance();
            uint256 totalUnderlying = availableUnderlying_ +
                allocatedUnderlying +
                waitingForRemovalAllocated;
            uint256 totalUnderlyingAfterWithdraw = totalUnderlying - amount;
            _rebalance(totalUnderlyingAfterWithdraw, allocatedUnderlying);
        }

        _transfer(pool, amount);
        return true;
    }

    /**
     * @notice Withdraws all funds from vault and strategy and transfer them to the pool.
     */
    function withdrawAll() external override onlyAdmin {
        withdrawAllFromStrategy();
        uint256 balance = _availableUnderlying();
        _transfer(pool, balance);
    }

    /**
     * @notice Withdraws specified amount of underlying from reserve to vault.
     * @dev Withdraws from reserve will cause a spike in pool exchange rate.
     *  Pool deposits should be paused during this to prevent front running
     * @param amount Amount to withdraw.
     */
    function withdrawFromReserve(uint256 amount) external override onlyAdmin {
        require(amount > 0, Error.INVALID_AMOUNT);
        require(IPausable(pool).isPaused(), Error.POOL_NOT_PAUSED);
        uint256 reserveBalance_ = _reserveBalance();
        require(amount <= reserveBalance_, Error.INSUFFICIENT_BALANCE);
        reserve.withdraw(getUnderlying(), amount);
    }

    /**
     * @notice Activate the current strategy set for the vault.
     * @return `true` if strategy has been activated
     */
    function activateStrategy() external onlyAdmin returns (bool) {
        return _activateStrategy();
    }

    /**
     * @notice Deactivates a strategy.
     * @return `true` if strategy has been deactivated
     */
    function deactivateStrategy() external onlyAdmin returns (bool) {
        return _deactivateStrategy();
    }

    /**
     * @notice Initializes the vault's strategy.
     * @dev Bypasses the time delay, but can only be called if strategy is not set already.
     * @param strategy_ Address of the strategy.
     * @return `true` if successful.
     */
    function initializeStrategy(address strategy_) external override onlyAdmin returns (bool) {
        require(currentAddresses[_STRATEGY_KEY] == address(0), Error.ADDRESS_ALREADY_SET);
        require(strategy_ != address(0), Error.ZERO_ADDRESS_NOT_ALLOWED);
        _setConfig(_STRATEGY_KEY, strategy_);
        _activateStrategy();
        address strategist_ = IStrategy(strategy_).strategist();
        require(strategist_ != address(0), Error.ZERO_ADDRESS_NOT_ALLOWED);
        strategist = strategist_;
        emit NewStrategist(strategist_);
        return true;
    }

    /**
     * @notice Prepare update of the vault's strategy (with time delay enforced).
     * @param newStrategy Address of the new strategy.
     * @return `true` if successful.
     */
    function prepareNewStrategy(address newStrategy) external onlyAdmin returns (bool) {
        return _prepare(_STRATEGY_KEY, newStrategy, STRATEGY_DELAY);
    }

    /**
     * @notice Execute strategy update (with time delay enforced).
     * @dev Needs to be called after the update was prepraed. Fails if called before time delay is met.
     * @return New strategy address.
     */
    function executeNewStrategy() external returns (address) {
        _executeDeadline(_STRATEGY_KEY);
        IStrategy strategy = getStrategy();
        if (address(strategy) != address(0)) {
            harvest();
            strategy.shutdown();
            strategy.withdrawAll();

            // there might still be some balance left if the strategy did not
            // manage to withdraw all funds (e.g. due to locking)
            uint256 remainingStrategyBalance = strategy.balance();
            if (remainingStrategyBalance > 0) {
                _strategiesWaitingForRemoval.set(address(strategy), remainingStrategyBalance);
                waitingForRemovalAllocated += remainingStrategyBalance;
            }
        }
        _deactivateStrategy();
        currentAllocated = 0;
        totalDebt = 0;
        address newStrategy = pendingAddresses[_STRATEGY_KEY];
        _setConfig(_STRATEGY_KEY, newStrategy);

        address newStrategist;

        if (newStrategy == address(0)) {
            newStrategist = address(0);
        } else {
            newStrategist = IStrategy(newStrategy).strategist();
            _activateStrategy();
        }

        if (newStrategist != strategist) {
            strategist = newStrategist;
            emit NewStrategist(newStrategist);
        }

        return newStrategy;
    }

    function resetNewStrategy() external onlyAdmin returns (bool) {
        return _resetAddressConfig(_STRATEGY_KEY);
    }

    /**
     * @notice Prepare update of performance fee (with time delay enforced).
     * @param newPerformanceFee New performance fee value.
     * @return `true` if successful.
     */
    function preparePerformanceFee(uint256 newPerformanceFee) external onlyAdmin returns (bool) {
        require(newPerformanceFee <= MAX_PERFORMANCE_FEE, Error.INVALID_AMOUNT);
        return _prepare(_PERFORMANCE_FEE_KEY, newPerformanceFee);
    }

    /**
     * @notice Execute update of performance fee (with time delay enforced).
     * @dev Needs to be called after the update was prepraed. Fails if called before time delay is met.
     * @return New performance fee.
     */
    function executePerformanceFee() external returns (uint256) {
        return _executeUInt256(_PERFORMANCE_FEE_KEY);
    }

    function resetPerformanceFee() external onlyAdmin returns (bool) {
        return _resetUInt256Config(_PERFORMANCE_FEE_KEY);
    }

    /**
     * @notice Prepare update of strategist fee (with time delay enforced).
     * @param newStrategistFee New strategist fee value.
     * @return `true` if successful.
     */
    function prepareStrategistFee(uint256 newStrategistFee) external onlyAdmin returns (bool) {
        _checkFeesInvariant(getReserveFee(), newStrategistFee);
        return _prepare(_STRATEGIST_FEE_KEY, newStrategistFee);
    }

    /**
     * @notice Execute update of strategist fee (with time delay enforced).
     * @dev Needs to be called after the update was prepraed. Fails if called before time delay is met.
     * @return New strategist fee.
     */
    function executeStrategistFee() external returns (uint256) {
        uint256 newStrategistFee = _executeUInt256(_STRATEGIST_FEE_KEY);
        _checkFeesInvariant(getReserveFee(), newStrategistFee);
        return newStrategistFee;
    }

    function resetStrategistFee() external onlyAdmin returns (bool) {
        return _resetUInt256Config(_STRATEGIST_FEE_KEY);
    }

    /**
     * @notice Prepare update of debt limit (with time delay enforced).
     * @param newDebtLimit New debt limit.
     * @return `true` if successful.
     */
    function prepareDebtLimit(uint256 newDebtLimit) external onlyAdmin returns (bool) {
        return _prepare(_DEBT_LIMIT_KEY, newDebtLimit);
    }

    /**
     * @notice Execute update of debt limit (with time delay enforced).
     * @dev Needs to be called after the update was prepraed. Fails if called before time delay is met.
     * @return New debt limit.
     */
    function executeDebtLimit() external returns (uint256) {
        uint256 debtLimit = _executeUInt256(_DEBT_LIMIT_KEY);
        uint256 debtLimitAllocated = currentAllocated.scaledMul(debtLimit);
        if (totalDebt >= debtLimitAllocated) {
            _handleExcessDebt();
        }
        return debtLimit;
    }

    function resetDebtLimit() external onlyAdmin returns (bool) {
        return _resetUInt256Config(_DEBT_LIMIT_KEY);
    }

    /**
     * @notice Prepare update of target allocation (with time delay enforced).
     * @param newTargetAllocation New target allocation.
     * @return `true` if successful.
     */
    function prepareTargetAllocation(uint256 newTargetAllocation)
        external
        onlyAdmin
        returns (bool)
    {
        return _prepare(_TARGET_ALLOCATION_KEY, newTargetAllocation);
    }

    /**
     * @notice Execute update of target allocation (with time delay enforced).
     * @dev Needs to be called after the update was prepraed. Fails if called before time delay is met.
     * @return New target allocation.
     */
    function executeTargetAllocation() external returns (uint256) {
        uint256 targetAllocation = _executeUInt256(_TARGET_ALLOCATION_KEY);
        _deposit();
        return targetAllocation;
    }

    function resetTargetAllocation() external onlyAdmin returns (bool) {
        return _resetUInt256Config(_TARGET_ALLOCATION_KEY);
    }

    /**
     * @notice Prepare update of reserve fee (with time delay enforced).
     * @param newReserveFee New reserve fee.
     * @return `true` if successful.
     */
    function prepareReserveFee(uint256 newReserveFee) external onlyAdmin returns (bool) {
        _checkFeesInvariant(newReserveFee, getStrategistFee());
        return _prepare(_RESERVE_FEE_KEY, newReserveFee);
    }

    /**
     * @notice Execute update of reserve fee (with time delay enforced).
     * @dev Needs to be called after the update was prepraed. Fails if called before time delay is met.
     * @return New reserve fee.
     */
    function executeReserveFee() external returns (uint256) {
        uint256 newReserveFee = _executeUInt256(_RESERVE_FEE_KEY);
        _checkFeesInvariant(newReserveFee, getStrategistFee());
        return newReserveFee;
    }

    function resetReserveFee() external onlyAdmin returns (bool) {
        return _resetUInt256Config(_RESERVE_FEE_KEY);
    }

    /**
     * @notice Prepare update of deviation bound for strategy allocation (with time delay enforced).
     * @param newBound New deviation bound for target allocation.
     * @return `true` if successful.
     */
    function prepareBound(uint256 newBound) external onlyAdmin returns (bool) {
        require(newBound <= MAX_DEVIATION_BOUND, Error.INVALID_AMOUNT);
        return _prepare(_BOUND_KEY, newBound);
    }

    /**
     * @notice Execute update of deviation bound for strategy allocation (with time delay enforced).
     * @dev Needs to be called after the update was prepraed. Fails if called before time delay is met.
     * @return New deviation bound.
     */
    function executeBound() external returns (uint256) {
        uint256 bound = _executeUInt256(_BOUND_KEY);
        _deposit();
        return bound;
    }

    function resetBound() external onlyAdmin returns (bool) {
        return _resetUInt256Config(_BOUND_KEY);
    }

    /**
     * @notice Withdraws an amount of underlying from the strategy to the vault.
     * @param amount Amount of underlying to withdraw.
     * @return True if successful withdrawal.
     */
    function withdrawFromStrategy(uint256 amount) external onlyAdmin returns (bool) {
        IStrategy strategy = getStrategy();
        if (address(strategy) == address(0)) return false;
        if (strategy.balance() < amount) return false;
        uint256 oldBalance = _availableUnderlying();
        strategy.withdraw(amount);
        uint256 newBalance = _availableUnderlying();
        currentAllocated -= newBalance - oldBalance;
        return true;
    }

    function withdrawFromStrategyWaitingForRemoval(address strategy) external returns (uint256) {
        (bool exists, uint256 allocated) = _strategiesWaitingForRemoval.tryGet(strategy);
        require(exists, Error.STRATEGY_DOES_NOT_EXIST);

        IStrategy istrategy = IStrategy(strategy);

        istrategy.harvest();
        uint256 withdrawn = istrategy.withdrawAll();

        uint256 _waitingForRemovalAllocated = waitingForRemovalAllocated;
        if (withdrawn >= _waitingForRemovalAllocated) {
            waitingForRemovalAllocated = 0;
        } else {
            waitingForRemovalAllocated = _waitingForRemovalAllocated - withdrawn;
        }

        if (withdrawn > allocated) {
            uint256 profit = withdrawn - allocated;
            uint256 strategistShare = _shareFees(profit.scaledMul(getPerformanceFee()));
            if (strategistShare > 0) {
                _payStrategist(strategistShare, istrategy.strategist());
            }
            allocated = 0;
            emit Harvest(profit, 0);
        } else {
            allocated -= withdrawn;
        }

        if (istrategy.balance() == 0) {
            _strategiesWaitingForRemoval.remove(strategy);
        } else {
            _strategiesWaitingForRemoval.set(strategy, allocated);
        }

        return withdrawn;
    }

    function getStrategiesWaitingForRemoval() external view returns (address[] memory) {
        return _strategiesWaitingForRemoval.keysArray();
    }

    /**
     * @notice Computes the total underlying of the vault: idle funds + allocated funds - debt
     * @return Total amount of underlying.
     */
    function getTotalUnderlying() external view override returns (uint256) {
        IStrategy strategy = getStrategy();
        uint256 availableUnderlying_ = _availableUnderlying();

        if (address(strategy) == address(0)) {
            return availableUnderlying_;
        }

        uint256 netUnderlying = availableUnderlying_ +
            currentAllocated +
            waitingForRemovalAllocated;
        if (totalDebt <= netUnderlying) return netUnderlying - totalDebt;
        return 0;
    }

    function getAllocatedToStrategyWaitingForRemoval(address strategy)
        external
        view
        returns (uint256)
    {
        return _strategiesWaitingForRemoval.get(strategy);
    }

    /**
     * @notice Withdraws all funds from strategy to vault.
     * @dev Harvests profits before withdrawing. Deactivates strategy after withdrawing.
     * @return `true` if successful.
     */
    function withdrawAllFromStrategy() public onlyAdmin returns (bool) {
        IStrategy strategy = getStrategy();
        if (address(strategy) == address(0)) return false;
        harvest();
        uint256 oldBalance = _availableUnderlying();
        strategy.withdrawAll();
        uint256 newBalance = _availableUnderlying();
        uint256 withdrawnAmount = newBalance - oldBalance;

        currentAllocated = _computeNewAllocated(currentAllocated, withdrawnAmount);
        _deactivateStrategy();
        return true;
    }

    /**
     * @notice Harvest profits from the vault's strategy.
     * @dev Harvesting adds profits to the vault's balance and deducts fees.
     *  No performance fees are charged on profit used to repay debt.
     * @return `true` if successful.
     */
    function harvest() public onlyAdmin returns (bool) {
        IStrategy strategy = getStrategy();
        if (address(strategy) == address(0)) {
            return false;
        }

        strategy.harvest();

        uint256 strategistShare = 0;

        uint256 allocatedUnderlying = strategy.balance();
        uint256 amountAllocated = currentAllocated;
        uint256 currentDebt = totalDebt;

        if (allocatedUnderlying > amountAllocated) {
            // we made profits
            uint256 profit = allocatedUnderlying - amountAllocated;

            if (profit > currentDebt) {
                if (currentDebt > 0) {
                    profit -= currentDebt;
                    currentDebt = 0;
                }
                (profit, strategistShare) = _shareProfit(profit);
            } else {
                currentDebt -= profit;
            }
            emit Harvest(profit, 0);
        } else if (allocatedUnderlying < amountAllocated) {
            // we made a loss
            uint256 loss = amountAllocated - allocatedUnderlying;
            currentDebt += loss;

            // check debt limit and withdraw funds if exceeded
            uint256 debtLimit = getDebtLimit();
            uint256 debtLimitAllocated = amountAllocated.scaledMul(debtLimit);
            if (currentDebt > debtLimitAllocated) {
                currentDebt = _handleExcessDebt(currentDebt);
            }
            emit Harvest(0, loss);
        } else {
            // nothing to declare
            return true;
        }

        totalDebt = currentDebt;
        currentAllocated = strategy.balance();

        if (strategistShare > 0) {
            _payStrategist(strategistShare);
        }

        return true;
    }

    /**
     * @notice Returns the percentage of the performance fee that goes to the strategist.
     */
    function getStrategistFee() public view returns (uint256) {
        return currentUInts256[_STRATEGIST_FEE_KEY];
    }

    function getStrategy() public view override returns (IStrategy) {
        return IStrategy(currentAddresses[_STRATEGY_KEY]);
    }

    /**
     * @notice Returns the percentage of the performance fee which is allocated to the vault reserve
     */
    function getReserveFee() public view returns (uint256) {
        return currentUInts256[_RESERVE_FEE_KEY];
    }

    /**
     * @notice Returns the fee charged on a strategy's generated profits.
     * @dev The strategist is paid in LP tokens, while the remainder of the profit stays in the vault.
     *      Default performance fee is set to 5% of harvested profits.
     */
    function getPerformanceFee() public view returns (uint256) {
        return currentUInts256[_PERFORMANCE_FEE_KEY];
    }

    /**
     * @notice Returns the allowed symmetric bound for target allocation (e.g. +- 5%)
     */
    function getBound() public view returns (uint256) {
        return currentUInts256[_BOUND_KEY];
    }

    /**
     * @notice The target percentage of total underlying funds to be allocated towards a strategy.
     * @dev this is to reduce gas costs. Withdrawals first come from idle funds and can therefore
     *      avoid unnecessary gas costs.
     */
    function getTargetAllocation() public view returns (uint256) {
        return currentUInts256[_TARGET_ALLOCATION_KEY];
    }

    /**
     * @notice The debt limit that the total debt of a strategy may not exceed.
     */
    function getDebtLimit() public view returns (uint256) {
        return currentUInts256[_DEBT_LIMIT_KEY];
    }

    function getUnderlying() public view virtual override returns (address);

    function _activateStrategy() internal returns (bool) {
        IStrategy strategy = getStrategy();
        if (address(strategy) == address(0)) return false;

        strategyActive = true;
        emit StrategyActivated(address(strategy));
        _deposit();
        return true;
    }

    function _handleExcessDebt(uint256 currentDebt) internal returns (uint256) {
        uint256 underlyingReserves = _reserveBalance();
        if (currentDebt > underlyingReserves) {
            _emergencyStop(underlyingReserves);
        } else {
            reserve.withdraw(getUnderlying(), currentDebt);
            currentDebt = 0;
            _deposit();
        }
        return currentDebt;
    }

    function _handleExcessDebt() internal {
        uint256 currentDebt = totalDebt;
        uint256 newDebt = _handleExcessDebt(totalDebt);
        if (currentDebt != newDebt) {
            totalDebt = newDebt;
        }
    }

    /**
     * @notice Invest the underlying money in the vault after a deposit from the pool is made.
     * @dev After each deposit, the vault checks whether it needs to rebalance underlying funds allocated to strategy.
     * If no strategy is set then all deposited funds will be idle.
     */
    function _deposit() internal {
        if (!strategyActive) return;

        uint256 availableUnderlying_ = _availableUnderlying();
        uint256 allocatedUnderlying = getStrategy().balance();
        uint256 totalUnderlying = availableUnderlying_ +
            allocatedUnderlying +
            waitingForRemovalAllocated;

        if (totalUnderlying == 0) return;
        _rebalance(totalUnderlying, allocatedUnderlying);
    }

    function _shareProfit(uint256 profit) internal returns (uint256, uint256) {
        uint256 totalFeeAmount = profit.scaledMul(getPerformanceFee());
        getStrategy().withdraw(totalFeeAmount);
        uint256 strategistShare = _shareFees(totalFeeAmount);

        return ((profit - totalFeeAmount), strategistShare);
    }

    function _shareFees(uint256 totalFeeAmount) internal returns (uint256) {
        uint256 strategistShare = totalFeeAmount.scaledMul(getStrategistFee());

        uint256 reserveShare = totalFeeAmount.scaledMul(getReserveFee());
        uint256 treasuryShare = totalFeeAmount - strategistShare - reserveShare;

        _depositToReserve(reserveShare);
        if (treasuryShare > 0) {
            _depositToTreasury(treasuryShare);
        }
        return strategistShare;
    }

    function _emergencyStop(uint256 underlyingReserves) internal {
        // debt limit exceeded: withdraw funds from strategy
        uint256 withdrawn = getStrategy().withdrawAll();

        uint256 actualDebt = _computeNewAllocated(currentAllocated, withdrawn);

        // check if debt can be covered with reserve funds
        if (underlyingReserves >= actualDebt) {
            reserve.withdraw(getUnderlying(), actualDebt);
        } else if (underlyingReserves > 0) {
            // debt can not be covered with reserves
            reserve.withdraw(getUnderlying(), underlyingReserves);
        }
        // too much money lost, stop the strategy
        _deactivateStrategy();
    }

    /**
     * @notice Deactivates a strategy. All positions of the strategy are exited.
     * @return `true` if strategy has been deactivated
     */
    function _deactivateStrategy() internal returns (bool) {
        if (!strategyActive) return false;

        strategyActive = false;
        emit StrategyDeactivated(address(getStrategy()));
        return true;
    }

    function _payStrategist(uint256 amount) internal {
        _payStrategist(amount, strategist);
    }

    function _payStrategist(uint256 amount, address strategist) internal virtual;

    function _transfer(address to, uint256 amount) internal virtual;

    function _depositToReserve(uint256 amount) internal virtual;

    function _depositToTreasury(uint256 amount) internal virtual;

    function _availableUnderlying() internal view virtual returns (uint256);

    function _reserveBalance() internal view virtual returns (uint256);

    function _computeNewAllocated(uint256 allocated, uint256 withdrawn)
        internal
        pure
        returns (uint256)
    {
        if (allocated > withdrawn) {
            return allocated - withdrawn;
        }
        return 0;
    }

    function _checkFeesInvariant(uint256 reserveFee, uint256 strategistFee) internal pure {
        require(
            reserveFee + strategistFee <= DECIMAL_SCALE,
            "sum of strategist fee and reserve fee should be below 1"
        );
    }

    function _rebalance(uint256 totalUnderlying, uint256 allocatedUnderlying)
        private
        returns (bool)
    {
        if (!strategyActive) return false;
        // check if strategy should receive any funds
        uint256 targetAllocation = getTargetAllocation();
        if (targetAllocation == 0) return false;

        IStrategy strategy = getStrategy();
        uint256 bound = getBound();

        uint256 target = totalUnderlying.scaledMul(targetAllocation);
        uint256 upperBound = targetAllocation + bound;
        upperBound = upperBound > DECIMAL_SCALE ? DECIMAL_SCALE : upperBound;
        uint256 lowerBound = bound > targetAllocation ? 0 : targetAllocation - bound;
        if (allocatedUnderlying > totalUnderlying.scaledMul(upperBound)) {
            // withdraw funds from strategy
            uint256 withdrawAmount = allocatedUnderlying - target;
            strategy.withdraw(withdrawAmount);

            currentAllocated = _computeNewAllocated(currentAllocated, withdrawAmount);
        } else if (allocatedUnderlying < totalUnderlying.scaledMul(lowerBound)) {
            // allocate more funds to strategy
            uint256 depositAmount = target - allocatedUnderlying;
            _transfer(address(strategy), depositAmount);
            currentAllocated += depositAmount;
            strategy.deposit();
        }
        return true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import "IERC20.sol";

import "IPreparable.sol";
import "IVault.sol";

interface ILiquidityPool is IPreparable {
    event Deposit(address indexed minter, uint256 mintAmount, uint256 mintTokens);

    event DepositFor(
        address indexed minter,
        address indexed mintee,
        uint256 mintAmount,
        uint256 mintTokens
    );

    event Redeem(address indexed redeemer, uint256 redeemAmount, uint256 redeemTokens);

    event LpTokenSet(address indexed lpToken);

    event StakerVaultSet(address indexed stakerVault);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeem(uint256 redeemTokens, uint256 minRedeemAmount) external returns (uint256);

    function calcRedeem(address account, uint256 underlyingAmount) external returns (uint256);

    function deposit(uint256 mintAmount) external payable returns (uint256);

    function deposit(uint256 mintAmount, uint256 minTokenAmount) external payable returns (uint256);

    function depositAndStake(uint256 depositAmount, uint256 minTokenAmount)
        external
        payable
        returns (uint256);

    function depositFor(address account, uint256 depositAmount) external payable returns (uint256);

    function depositFor(
        address account,
        uint256 depositAmount,
        uint256 minTokenAmount
    ) external payable returns (uint256);

    function unstakeAndRedeem(uint256 redeemLpTokens, uint256 minRedeemAmount)
        external
        returns (uint256);

    function handleLpTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) external;

    function executeNewVault() external returns (address);

    function executeNewMaxWithdrawalFee() external returns (uint256);

    function executeNewRequiredReserves() external returns (uint256);

    function executeNewReserveDeviation() external returns (uint256);

    function setLpToken(address _lpToken) external returns (bool);

    function setStaker() external returns (bool);

    function isCapped() external returns (bool);

    function uncap() external returns (bool);

    function updateDepositCap(uint256 _depositCap) external returns (bool);

    function getUnderlying() external view returns (address);

    function getLpToken() external view returns (address);

    function getWithdrawalFee(address account, uint256 amount) external view returns (uint256);

    function getVault() external view returns (IVault);

    function exchangeRate() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

interface IPreparable {
    event ConfigPreparedAddress(bytes32 indexed key, address value, uint256 delay);
    event ConfigPreparedNumber(bytes32 indexed key, uint256 value, uint256 delay);

    event ConfigUpdatedAddress(bytes32 indexed key, address oldValue, address newValue);
    event ConfigUpdatedNumber(bytes32 indexed key, uint256 oldValue, uint256 newValue);

    event ConfigReset(bytes32 indexed key);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import "IStrategy.sol";
import "IPreparable.sol";

/**
 * @title Interface for a Vault
 */

interface IVault is IPreparable {
    function initialize(
        address _pool,
        uint256 _debtLimit,
        uint256 _targetAllocation,
        uint256 _bound
    ) external;

    function getStrategy() external view returns (IStrategy);

    function withdrawFromStrategyWaitingForRemoval(address strategy) external returns (uint256);

    function getStrategiesWaitingForRemoval() external view returns (address[] memory);

    function getAllocatedToStrategyWaitingForRemoval(address strategy)
        external
        view
        returns (uint256);

    function withdraw(uint256 amount) external returns (bool);

    function initializeStrategy(address strategy_) external returns (bool);

    function withdrawAll() external;

    function withdrawFromReserve(uint256 amount) external;

    function getTotalUnderlying() external view returns (uint256);

    function getUnderlying() external view returns (address);

    function deposit() external payable;

    event StrategyActivated(address indexed strategy);

    event StrategyDeactivated(address indexed strategy);

    event NewStrategist(address indexed strategist);

    /**
     * @dev 'netProfit' is the profit after all fees have been deducted
     */
    event Harvest(uint256 indexed netProfit, uint256 indexed loss);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

interface IStrategy {
    function deposit() external payable returns (bool);

    function balance() external view returns (uint256);

    function withdraw(uint256 amount) external returns (bool);

    function withdrawAll() external returns (uint256);

    function harvestable() external view returns (uint256);

    function harvest() external returns (uint256);

    function strategist() external view returns (address);

    function shutdown() external returns (bool);

    function hasPendingFunds() external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import "IAddressProvider.sol";
import "IPreparable.sol";
import "IGasBank.sol";
import "ILiquidityPool.sol";
import "IInflationManager.sol";

// solhint-disable ordering

interface IController is IPreparable {
    function addressProvider() external view returns (IAddressProvider);

    function inflationManager() external view returns (IInflationManager);

    function addStakerVault(address stakerVault) external returns (bool);

    function removePool(address pool) external returns (bool);

    /** Keeper functions */
    function prepareKeeperRequiredStakedBKD(uint256 amount) external;

    function executeKeeperRequiredStakedBKD() external;

    function getKeeperRequiredStakedBKD() external view returns (uint256);

    function canKeeperExecuteAction(address keeper) external view returns (bool);

    /** Miscellaneous functions */

    function getTotalEthRequiredForGas(address payer) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import "ILiquidityPool.sol";
import "IPreparable.sol";
import "IGasBank.sol";
import "IOracleProvider.sol";

// solhint-disable ordering

interface IAddressProvider is IPreparable {
    event KnownAddressKeyAdded(bytes32 indexed key);
    event StakerVaultListed(address indexed stakerVault);
    event StakerVaultDelisted(address indexed stakerVault);
    event ActionListed(address indexed action);
    event PoolListed(address indexed pool);
    event PoolDelisted(address indexed pool);

    /** Key functions */
    function getKnownAddressKeys() external view returns (bytes32[] memory);

    function addKnownAddressKey(bytes32 key) external;

    /** Pool functions */

    function allPools() external view returns (address[] memory);

    function addPool(address pool) external;

    function removePool(address pool) external returns (bool);

    function getPoolForToken(address token) external view returns (ILiquidityPool);

    function safeGetPoolForToken(address token) external view returns (ILiquidityPool);

    /** Action functions */

    function allActions() external view returns (address[] memory);

    function addAction(address action) external returns (bool);

    function isAction(address action) external view returns (bool);

    /** Address functions */
    function getAddress(bytes32 key) external view returns (address);

    function prepareAddress(bytes32 key, address newAddress) external returns (bool);

    function executeAddress(bytes32 key) external returns (address);

    function resetAddress(bytes32 key) external returns (bool);

    /** Staker vault functions */
    function allStakerVaults() external view returns (address[] memory);

    function tryGetStakerVault(address token) external view returns (bool, address);

    function getStakerVault(address token) external view returns (address);

    function addStakerVault(address stakerVault) external returns (bool);

    function isStakerVault(address stakerVault, address token) external view returns (bool);

    function isStakerVaultRegistered(address stakerVault) external view returns (bool);

    function isWhiteListedFeeHandler(address feeHandler) external view returns (bool);

    /** BKD Locker functions */

    function getBKDLocker() external view returns (address);

    function setBKDLocker(address bkdLocker) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

interface IGasBank {
    event Deposit(address indexed account, uint256 value);
    event Withdraw(address indexed account, address indexed receiver, uint256 value);

    function depositFor(address account) external payable;

    function withdrawUnused(address account) external;

    function withdrawFrom(address account, uint256 amount) external;

    function withdrawFrom(
        address account,
        address payable to,
        uint256 amount
    ) external;

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

interface IOracleProvider {
    /// @notice Quotes the USD price of `baseAsset`
    /// @param baseAsset the asset of which the price is to be quoted
    /// @return the USD price of the asset
    function getPriceUSD(address baseAsset) external view returns (uint256);

    /// @notice Quotes the ETH price of `baseAsset`
    /// @param baseAsset the asset of which the price is to be quoted
    /// @return the ETH price of the asset
    function getPriceETH(address baseAsset) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

interface IInflationManager {
    event KeeperGaugeListed(address indexed pool, address indexed keeperGauge);
    event AmmGaugeListed(address indexed token, address indexed ammGauge);
    event KeeperGaugeDelisted(address indexed pool, address indexed keeperGauge);
    event AmmGaugeDelisted(address indexed token, address indexed ammGauge);

    /** Pool functions */

    function setKeeperGauge(address pool, address _keeperGauge) external returns (bool);

    function setAmmGauge(address token, address _ammGauge) external returns (bool);

    function getAllAmmGauges() external view returns (address[] memory);

    function getLpRateForStakerVault(address stakerVault) external view returns (uint256);

    function getKeeperRateForPool(address pool) external view returns (uint256);

    function getAmmRateForToken(address token) external view returns (uint256);

    function getKeeperWeightForPool(address pool) external view returns (uint256);

    function getAmmWeightForToken(address pool) external view returns (uint256);

    function getLpPoolWeight(address pool) external view returns (uint256);

    function getKeeperGaugeForPool(address pool) external view returns (address);

    function getAmmGaugeForToken(address token) external view returns (address);

    function setGovernanceProxy(address _governanceProxy) external returns (bool);

    function isGovernanceProxy(address account) external view returns (bool);

    function removeStakerVaultFromInflation(address stakerVault, address lpToken) external;

    function addGaugeForVault(address lpToken) external returns (bool);

    function whitelistGauge(address gauge) external;

    function checkpointAllGauges() external returns (bool);

    function mintRewards(address beneficiary, uint256 amount) external;

    function addStrategyToDepositStakerVault(address depositStakerVault, address strategyPool)
        external
        returns (bool);

    /** Weight setter functions **/

    function prepareLpPoolWeight(address lpToken, uint256 newPoolWeight) external returns (bool);

    function prepareAmmTokenWeight(address token, uint256 newTokenWeight) external returns (bool);

    function prepareKeeperPoolWeight(address pool, uint256 newPoolWeight) external returns (bool);

    function executeLpPoolWeight(address lpToken) external returns (uint256);

    function executeAmmTokenWeight(address token) external returns (uint256);

    function executeKeeperPoolWeight(address pool) external returns (uint256);

    function batchPrepareLpPoolWeights(address[] calldata lpTokens, uint256[] calldata weights)
        external
        returns (bool);

    function batchPrepareAmmTokenWeights(address[] calldata tokens, uint256[] calldata weights)
        external
        returns (bool);

    function batchPrepareKeeperPoolWeights(address[] calldata pools, uint256[] calldata weights)
        external
        returns (bool);

    function batchExecuteLpPoolWeights(address[] calldata lpTokens) external returns (bool);

    function batchExecuteAmmTokenWeights(address[] calldata tokens) external returns (bool);

    function batchExecuteKeeperPoolWeights(address[] calldata pools) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/*
 * @dev To use functions of this contract, at least one of the numbers must
 * be scaled to `DECIMAL_SCALE`. The result will scaled to `DECIMAL_SCALE`
 * if both numbers are scaled to `DECIMAL_SCALE`, otherwise to the scale
 * of the number not scaled by `DECIMAL_SCALE`
 */
library ScaledMath {
    // solhint-disable-next-line private-vars-leading-underscore
    uint256 internal constant DECIMAL_SCALE = 1e18;
    // solhint-disable-next-line private-vars-leading-underscore
    uint256 internal constant ONE = 1e18;

    /**
     * @notice Performs a multiplication between two scaled numbers
     */
    function scaledMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) / DECIMAL_SCALE;
    }

    /**
     * @notice Performs a division between two scaled numbers
     */
    function scaledDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * DECIMAL_SCALE) / b;
    }

    /**
     * @notice Performs a division between two numbers, rounding up the result
     */
    function scaledDivRoundUp(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * DECIMAL_SCALE + b - 1) / b;
    }

    /**
     * @notice Performs a division between two numbers, ignoring any scaling and rounding up the result
     */
    function divRoundUp(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a + b - 1) / b;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import "EnumerableSet.sol";
import "EnumerableMapping.sol";

library EnumerableExtensions {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableMapping for EnumerableMapping.AddressToAddressMap;
    using EnumerableMapping for EnumerableMapping.AddressToUintMap;

    function toArray(EnumerableSet.AddressSet storage addresses)
        internal
        view
        returns (address[] memory)
    {
        uint256 len = addresses.length();
        address[] memory result = new address[](len);
        for (uint256 i = 0; i < len; i++) {
            result[i] = addresses.at(i);
        }
        return result;
    }

    function toArray(EnumerableSet.Bytes32Set storage values)
        internal
        view
        returns (bytes32[] memory)
    {
        uint256 len = values.length();
        bytes32[] memory result = new bytes32[](len);
        for (uint256 i = 0; i < len; i++) {
            result[i] = values.at(i);
        }
        return result;
    }

    function keyAt(EnumerableMapping.AddressToAddressMap storage map, uint256 index)
        internal
        view
        returns (address)
    {
        (address key, ) = map.at(index);
        return key;
    }

    function valueAt(EnumerableMapping.AddressToAddressMap storage map, uint256 index)
        internal
        view
        returns (address)
    {
        (, address value) = map.at(index);
        return value;
    }

    function keyAt(EnumerableMapping.AddressToUintMap storage map, uint256 index)
        internal
        view
        returns (address)
    {
        (address key, ) = map.at(index);
        return key;
    }

    function valueAt(EnumerableMapping.AddressToUintMap storage map, uint256 index)
        internal
        view
        returns (uint256)
    {
        (, uint256 value) = map.at(index);
        return value;
    }

    function keysArray(EnumerableMapping.AddressToAddressMap storage map)
        internal
        view
        returns (address[] memory)
    {
        uint256 len = map.length();
        address[] memory result = new address[](len);
        for (uint256 i = 0; i < len; i++) {
            result[i] = keyAt(map, i);
        }
        return result;
    }

    function valuesArray(EnumerableMapping.AddressToAddressMap storage map)
        internal
        view
        returns (address[] memory)
    {
        uint256 len = map.length();
        address[] memory result = new address[](len);
        for (uint256 i = 0; i < len; i++) {
            result[i] = valueAt(map, i);
        }
        return result;
    }

    function keysArray(EnumerableMapping.AddressToUintMap storage map)
        internal
        view
        returns (address[] memory)
    {
        uint256 len = map.length();
        address[] memory result = new address[](len);
        for (uint256 i = 0; i < len; i++) {
            result[i] = keyAt(map, i);
        }
        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import "EnumerableSet.sol";

library EnumerableMapping {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // Code take from contracts/utils/structs/EnumerableMap.sol
    // because the helper functions are private

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(
        Map storage map,
        bytes32 key,
        bytes32 value
    ) private returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (_contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || _contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    // AddressToAddressMap

    struct AddressToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        AddressToAddressMap storage map,
        address key,
        address value
    ) internal returns (bool) {
        return _set(map._inner, bytes32(uint256(uint160(key))), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToAddressMap storage map, address key) internal returns (bool) {
        return _remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToAddressMap storage map, address key) internal view returns (bool) {
        return _contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToAddressMap storage map, uint256 index)
        internal
        view
        returns (address, address)
    {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (address(uint160(uint256(key))), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(AddressToAddressMap storage map, address key)
        internal
        view
        returns (bool, address)
    {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToAddressMap storage map, address key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(uint256(uint160(key)))))));
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        AddressToUintMap storage map,
        address key,
        uint256 value
    ) internal returns (bool) {
        return _set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return _remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return _contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToUintMap storage map, uint256 index)
        internal
        view
        returns (address, uint256)
    {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(AddressToUintMap storage map, address key)
        internal
        view
        returns (bool, uint256)
    {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(_get(map._inner, bytes32(uint256(uint160(key)))));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import "IGasBank.sol";
import "IVaultReserve.sol";
import "IOracleProvider.sol";
import "IAddressProvider.sol";

import "AddressProviderKeys.sol";

library AddressProviderHelpers {
    /**
     * @return The address of the treasury.
     */
    function getTreasury(IAddressProvider provider) internal view returns (address) {
        return provider.getAddress(AddressProviderKeys._TREASURY_KEY);
    }

    /**
     * @return The gas bank.
     */
    function getGasBank(IAddressProvider provider) internal view returns (IGasBank) {
        return IGasBank(provider.getAddress(AddressProviderKeys._GAS_BANK_KEY));
    }

    /**
     * @return The address of the vault reserve.
     */
    function getVaultReserve(IAddressProvider provider) internal view returns (IVaultReserve) {
        return IVaultReserve(provider.getAddress(AddressProviderKeys._VAULT_RESERVE_KEY));
    }

    /**
     * @return The address of the swapperRegistry.
     */
    function getSwapperRegistry(IAddressProvider provider) internal view returns (address) {
        return provider.getAddress(AddressProviderKeys._SWAPPER_REGISTRY_KEY);
    }

    /**
     * @return The oracleProvider.
     */
    function getOracleProvider(IAddressProvider provider) internal view returns (IOracleProvider) {
        return IOracleProvider(provider.getAddress(AddressProviderKeys._ORACLE_PROVIDER_KEY));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

library AddressProviderKeys {
    bytes32 internal constant _TREASURY_KEY = "treasury";
    bytes32 internal constant _GAS_BANK_KEY = "gasBank";
    bytes32 internal constant _VAULT_RESERVE_KEY = "vaultReserve";
    bytes32 internal constant _SWAPPER_REGISTRY_KEY = "swapperRegistry";
    bytes32 internal constant _ORACLE_PROVIDER_KEY = "oracleProvider";
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import "EnumerableMapping.sol";
import "IVaultReserve.sol";
import "IStrategy.sol";

contract VaultStorage {
    uint256 public currentAllocated;
    uint256 public waitingForRemovalAllocated;
    address public pool;

    /**
     * @notice The address of the strategist for the vault
     * @dev This should be updated as strategies are replaced
     */
    address public strategist;

    uint256 public totalDebt;
    bool public strategyActive;

    EnumerableMapping.AddressToUintMap internal _strategiesWaitingForRemoval;
}

contract VaultStorageV1 is VaultStorage {
    /**
     * @dev This is to avoid breaking contracts inheriting from `VaultStorage`
     * such as `Erc20Vault`, especially if they have storage variables
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     * for more details
     *
     * A new field can be added using a new contract such as
     *
     * ```solidity
     * contract VaultStorageV2 is VaultStorage {
     *   uint256 someNewField;
     *   uint256[49] private __gap;
     * }
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import "IPreparable.sol";
import "Errors.sol";

/**
 * @notice Implements the base logic for a two-phase commit
 * @dev This does not implements any access-control so publicly exposed
 * callers should make sure to have the proper checks in palce
 */
contract Preparable is IPreparable {
    uint256 private constant _MIN_DELAY = 3 days;

    mapping(bytes32 => address) public pendingAddresses;
    mapping(bytes32 => uint256) public pendingUInts256;

    mapping(bytes32 => address) public currentAddresses;
    mapping(bytes32 => uint256) public currentUInts256;

    /**
     * @dev Deadlines shares the same namespace regardless of the type
     * of the pending variable so this needs to be enforced in the caller
     */
    mapping(bytes32 => uint256) public deadlines;

    function _prepareDeadline(bytes32 key, uint256 delay) internal {
        require(deadlines[key] == 0, Error.DEADLINE_NOT_ZERO);
        require(delay >= _MIN_DELAY, Error.DELAY_TOO_SHORT);
        deadlines[key] = block.timestamp + delay;
    }

    /**
     * @notice Prepares an uint256 that should be commited to the contract
     * after `_MIN_DELAY` elapsed
     * @param value The value to prepare
     * @return `true` if success.
     */
    function _prepare(
        bytes32 key,
        uint256 value,
        uint256 delay
    ) internal returns (bool) {
        _prepareDeadline(key, delay);
        pendingUInts256[key] = value;
        emit ConfigPreparedNumber(key, value, delay);
        return true;
    }

    /**
     * @notice Same as `_prepare(bytes32,uint256,uint256)` but uses a default delay
     */
    function _prepare(bytes32 key, uint256 value) internal returns (bool) {
        return _prepare(key, value, _MIN_DELAY);
    }

    /**
     * @notice Prepares an address that should be commited to the contract
     * after `_MIN_DELAY` elapsed
     * @param value The value to prepare
     * @return `true` if success.
     */
    function _prepare(
        bytes32 key,
        address value,
        uint256 delay
    ) internal returns (bool) {
        _prepareDeadline(key, delay);
        pendingAddresses[key] = value;
        emit ConfigPreparedAddress(key, value, delay);
        return true;
    }

    /**
     * @notice Same as `_prepare(bytes32,address,uint256)` but uses a default delay
     */
    function _prepare(bytes32 key, address value) internal returns (bool) {
        return _prepare(key, value, _MIN_DELAY);
    }

    /**
     * @notice Reset a uint256 key
     * @return `true` if success.
     */
    function _resetUInt256Config(bytes32 key) internal returns (bool) {
        require(deadlines[key] != 0, Error.DEADLINE_NOT_ZERO);
        deadlines[key] = 0;
        pendingUInts256[key] = 0;
        emit ConfigReset(key);
        return true;
    }

    /**
     * @notice Reset an address key
     * @return `true` if success.
     */
    function _resetAddressConfig(bytes32 key) internal returns (bool) {
        require(deadlines[key] != 0, Error.DEADLINE_NOT_ZERO);
        deadlines[key] = 0;
        pendingAddresses[key] = address(0);
        emit ConfigReset(key);
        return true;
    }

    /**
     * @dev Checks the deadline of the key and reset it
     */
    function _executeDeadline(bytes32 key) internal {
        uint256 deadline = deadlines[key];
        require(block.timestamp >= deadline, Error.DEADLINE_NOT_REACHED);
        require(deadline != 0, Error.DEADLINE_NOT_SET);
        deadlines[key] = 0;
    }

    /**
     * @notice Execute uint256 config update (with time delay enforced).
     * @dev Needs to be called after the update was prepared. Fails if called before time delay is met.
     * @return New value.
     */
    function _executeUInt256(bytes32 key) internal returns (uint256) {
        _executeDeadline(key);
        uint256 newValue = pendingUInts256[key];
        _setConfig(key, newValue);
        return newValue;
    }

    /**
     * @notice Execute address config update (with time delay enforced).
     * @dev Needs to be called after the update was prepared. Fails if called before time delay is met.
     * @return New value.
     */
    function _executeAddress(bytes32 key) internal returns (address) {
        _executeDeadline(key);
        address newValue = pendingAddresses[key];
        _setConfig(key, newValue);
        return newValue;
    }

    function _setConfig(bytes32 key, address value) internal returns (address) {
        address oldValue = currentAddresses[key];
        currentAddresses[key] = value;
        pendingAddresses[key] = address(0);
        deadlines[key] = 0;
        emit ConfigUpdatedAddress(key, oldValue, value);
        return value;
    }

    function _setConfig(bytes32 key, uint256 value) internal returns (uint256) {
        uint256 oldValue = currentUInts256[key];
        currentUInts256[key] = value;
        pendingUInts256[key] = 0;
        deadlines[key] = 0;
        emit ConfigUpdatedNumber(key, oldValue, value);
        return value;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

interface IPausable {
    function pause() external returns (bool);

    function unpause() external returns (bool);

    function isPaused() external view returns (bool);

    function isAuthorizedToPause(address account) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import "AdminBase.sol";

contract AdminUpgradeable is AdminBase {
    /**
     * @dev This is to avoid breaking contracts inheriting from `AdminUpgradeable
     * in case we need to add more variables to the admin contract, although unlikely
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     * for more details
     */
    uint256[50] private __gap;

    function _initializeAdmin(address _admin) internal {
        _addAdmin(_admin);
    }
}