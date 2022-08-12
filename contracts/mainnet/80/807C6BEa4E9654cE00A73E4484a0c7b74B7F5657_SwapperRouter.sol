/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

// SPDX-License-Identifier: GPL-3.0-or-later
// Sources flattened with hardhat v2.6.1 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;


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


// File interfaces/IRoleManager.sol

pragma solidity 0.8.10;

interface IRoleManager {
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    function initialize() external;

    function grantRole(bytes32 role, address account) external;

    function addGovernor(address newGovernor) external;

    function renounceGovernance() external;

    function addGaugeZap(address zap) external;

    function removeGaugeZap(address zap) external;

    function revokeRole(bytes32 role, address account) external;

    function hasRole(bytes32 role, address account) external view returns (bool);

    function hasAnyRole(bytes32[] memory roles, address account) external view returns (bool);

    function hasAnyRole(
        bytes32 role1,
        bytes32 role2,
        address account
    ) external view returns (bool);

    function hasAnyRole(
        bytes32 role1,
        bytes32 role2,
        bytes32 role3,
        address account
    ) external view returns (bool);

    function getRoleMemberCount(bytes32 role) external view returns (uint256);

    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
}


// File libraries/Errors.sol

pragma solidity 0.8.10;

// solhint-disable private-vars-leading-underscore

library Error {
    string internal constant ADDRESS_WHITELISTED = "address already whitelisted";
    string internal constant ADMIN_ALREADY_SET = "admin has already been set once";
    string internal constant ADDRESS_NOT_WHITELISTED = "address not whitelisted";
    string internal constant ADDRESS_NOT_FOUND = "address not found";
    string internal constant CONTRACT_INITIALIZED = "contract can only be initialized once";
    string internal constant CONTRACT_PAUSED = "contract is paused";
    string internal constant UNAUTHORIZED_PAUSE = "not authorized to pause";
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
    string internal constant INSUFFICIENT_ALLOWANCE = "insufficient allowance";
    string internal constant INSUFFICIENT_BALANCE = "insufficient balance";
    string internal constant INSUFFICIENT_AMOUNT_OUT = "Amount received less than min amount";
    string internal constant PROXY_CALL_FAILED = "proxy call failed";
    string internal constant INSUFFICIENT_AMOUNT_IN = "Amount spent more than max amount";
    string internal constant ADDRESS_ALREADY_SET = "Address is already set";
    string internal constant INSUFFICIENT_STRATEGY_BALANCE = "insufficient strategy balance";
    string internal constant INSUFFICIENT_FUNDS_RECEIVED = "insufficient funds received";
    string internal constant ADDRESS_DOES_NOT_EXIST = "address does not exist";
    string internal constant ADDRESS_FROZEN = "address is frozen";
    string internal constant ROLE_EXISTS = "role already exists";
    string internal constant CANNOT_REVOKE_ROLE = "cannot revoke role";
    string internal constant UNAUTHORIZED_ACCESS = "unauthorized access";
    string internal constant SAME_ADDRESS_NOT_ALLOWED = "same address not allowed";
    string internal constant SELF_TRANSFER_NOT_ALLOWED = "self-transfer not allowed";
    string internal constant ZERO_ADDRESS_NOT_ALLOWED = "zero address not allowed";
    string internal constant ZERO_TRANSFER_NOT_ALLOWED = "zero transfer not allowed";
    string internal constant THRESHOLD_TOO_HIGH = "threshold is too high, must be under 10";
    string internal constant INSUFFICIENT_THRESHOLD = "insufficient threshold";
    string internal constant NO_POSITION_EXISTS = "no position exists";
    string internal constant POSITION_ALREADY_EXISTS = "position already exists";
    string internal constant CANNOT_EXECUTE_IN_SAME_BLOCK = "cannot execute action in same block";
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
    string internal constant NOTHING_PENDING = "no pending change to reset";
    string internal constant DEADLINE_NOT_SET = "deadline is 0";
    string internal constant DEADLINE_NOT_REACHED = "deadline has not been reached yet";
    string internal constant DELAY_TOO_SHORT = "delay must be at least 3 days";
    string internal constant INSUFFICIENT_UPDATE_BALANCE =
        "insufficient funds for updating the position";
    string internal constant SAME_AS_CURRENT = "value must be different to existing value";
    string internal constant NOT_CAPPED = "the pool is not currently capped";
    string internal constant ALREADY_CAPPED = "the pool is already capped";
    string internal constant ALREADY_SHUTDOWN = "already shutdown";
    string internal constant EXCEEDS_DEPOSIT_CAP = "deposit exceeds deposit cap";
    string internal constant VALUE_TOO_LOW_FOR_GAS = "value too low to cover gas";
    string internal constant NOT_ENOUGH_FUNDS = "not enough funds to withdraw";
    string internal constant ESTIMATED_GAS_TOO_HIGH = "too much ETH will be used for gas";
    string internal constant GAUGE_KILLED = "gauge killed";
    string internal constant INVALID_TARGET = "Invalid Target";
    string internal constant DEPOSIT_FAILED = "deposit failed";
    string internal constant GAS_TOO_HIGH = "too much ETH used for gas";
    string internal constant GAS_BANK_BALANCE_TOO_LOW = "not enough ETH in gas bank to cover gas";
    string internal constant INVALID_TOKEN_TO_ADD = "Invalid token to add";
    string internal constant INVALID_TOKEN_TO_REMOVE = "token can not be removed";
    string internal constant TIME_DELAY_NOT_EXPIRED = "time delay not expired yet";
    string internal constant UNDERLYING_NOT_WITHDRAWABLE =
        "pool does not support additional underlying coins to be withdrawn";
    string internal constant STRATEGY_SHUTDOWN = "Strategy is shutdown";
    string internal constant POOL_SHUTDOWN = "Pool is shutdown";
    string internal constant ACTION_SHUTDOWN = "Action is shutdown";
    string internal constant ACTION_PAUSED = "Action is paused";
    string internal constant STRATEGY_DOES_NOT_EXIST = "Strategy does not exist";
    string internal constant GAUGE_STILL_ACTIVE = "Gauge still active";
    string internal constant UNSUPPORTED_UNDERLYING = "Underlying not supported";
    string internal constant NO_DEX_SET = "no dex has been set for token";
    string internal constant INVALID_TOKEN_PAIR = "invalid token pair";
    string internal constant TOKEN_NOT_USABLE = "token not usable for the specific action";
    string internal constant ADDRESS_NOT_ACTION = "address is not registered action";
    string internal constant ACTION_NOT_ACTIVE = "address is not active action";
    string internal constant INVALID_SLIPPAGE_TOLERANCE = "Invalid slippage tolerance";
    string internal constant INVALID_MAX_FEE = "invalid max fee";
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
    string internal constant ROUND_NOT_COMPLETE = "Round not complete";
    string internal constant NOT_ENOUGH_MERO_STAKED = "Not enough MERO tokens staked";
    string internal constant RESERVE_ACCESS_EXCEEDED = "Reserve access exceeded";
}


// File libraries/Roles.sol

pragma solidity 0.8.10;

// solhint-disable private-vars-leading-underscore

library Roles {
    bytes32 internal constant GOVERNANCE = "governance";
    bytes32 internal constant ADDRESS_PROVIDER = "address_provider";
    bytes32 internal constant POOL_FACTORY = "pool_factory";
    bytes32 internal constant CONTROLLER = "controller";
    bytes32 internal constant GAUGE_ZAP = "gauge_zap";
    bytes32 internal constant MAINTENANCE = "maintenance";
    bytes32 internal constant INFLATION_ADMIN = "inflation_admin";
    bytes32 internal constant INFLATION_MANAGER = "inflation_manager";
    bytes32 internal constant POOL = "pool";
    bytes32 internal constant VAULT = "vault";
    bytes32 internal constant ACTION = "action";
}


// File contracts/access/AuthorizationBase.sol

pragma solidity 0.8.10;


/**
 * @notice Provides modifiers for authorization
 */
abstract contract AuthorizationBase {
    /**
     * @notice Only allows a sender with `role` to perform the given action
     */
    modifier onlyRole(bytes32 role) {
        require(_roleManager().hasRole(role, msg.sender), Error.UNAUTHORIZED_ACCESS);
        _;
    }

    /**
     * @notice Only allows a sender with GOVERNANCE role to perform the given action
     */
    modifier onlyGovernance() {
        require(_roleManager().hasRole(Roles.GOVERNANCE, msg.sender), Error.UNAUTHORIZED_ACCESS);
        _;
    }

    /**
     * @notice Only allows a sender with any of `roles` to perform the given action
     */
    modifier onlyRoles2(bytes32 role1, bytes32 role2) {
        require(_roleManager().hasAnyRole(role1, role2, msg.sender), Error.UNAUTHORIZED_ACCESS);
        _;
    }

    /**
     * @notice Only allows a sender with any of `roles` to perform the given action
     */
    modifier onlyRoles3(
        bytes32 role1,
        bytes32 role2,
        bytes32 role3
    ) {
        require(
            _roleManager().hasAnyRole(role1, role2, role3, msg.sender),
            Error.UNAUTHORIZED_ACCESS
        );
        _;
    }

    function roleManager() external view virtual returns (IRoleManager) {
        return _roleManager();
    }

    function _roleManager() internal view virtual returns (IRoleManager);
}


// File contracts/access/Authorization.sol

pragma solidity 0.8.10;

contract Authorization is AuthorizationBase {
    IRoleManager internal immutable __roleManager;

    constructor(IRoleManager roleManager) {
        __roleManager = roleManager;
    }

    function _roleManager() internal view override returns (IRoleManager) {
        return __roleManager;
    }
}


// File interfaces/IGasBank.sol

pragma solidity 0.8.10;

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


// File interfaces/IVaultReserve.sol

pragma solidity 0.8.10;

interface IVaultReserve {
    event Deposit(address indexed vault, address indexed token, uint256 amount);
    event Withdraw(address indexed vault, address indexed token, uint256 amount);
    event VaultListed(address indexed vault);

    function deposit(address token, uint256 amount) external payable;

    function withdraw(address token, uint256 amount) external;

    function getBalance(address vault, address token) external view returns (uint256);

    function canWithdraw(address vault) external view returns (bool);
}


// File interfaces/oracles/IOracleProvider.sol

pragma solidity 0.8.10;

interface IOracleProvider {
    /// @notice Checks whether the asset is supported
    /// @param baseAsset the asset of which the price is to be quoted
    /// @return true if the asset is supported
    function isAssetSupported(address baseAsset) external view returns (bool);

    /// @notice Quotes the USD price of `baseAsset`
    /// @param baseAsset the asset of which the price is to be quoted
    /// @return the USD price of the asset
    function getPriceUSD(address baseAsset) external view returns (uint256);

    /// @notice Quotes the ETH price of `baseAsset`
    /// @param baseAsset the asset of which the price is to be quoted
    /// @return the ETH price of the asset
    function getPriceETH(address baseAsset) external view returns (uint256);
}


// File interfaces/strategies/IStrategy.sol

pragma solidity 0.8.10;

interface IStrategy {
    function deposit() external payable returns (bool);

    function withdraw(uint256 amount) external returns (bool);

    function withdrawAll() external returns (uint256);

    function harvest() external returns (uint256);

    function shutdown() external;

    function setCommunityReserve(address _communityReserve) external;

    function setStrategist(address strategist_) external;

    function name() external view returns (string memory);

    function balance() external view returns (uint256);

    function harvestable() external view returns (uint256);

    function strategist() external view returns (address);

    function hasPendingFunds() external view returns (bool);
}


// File interfaces/IVault.sol

pragma solidity 0.8.10;

/**
 * @title Interface for a Vault
 */

interface IVault {
    event StrategyActivated(address indexed strategy);

    event StrategyDeactivated(address indexed strategy);

    /**
     * @dev 'netProfit' is the profit after all fees have been deducted
     */
    event Harvest(uint256 indexed netProfit, uint256 indexed loss);

    function initialize(
        address _pool,
        uint256 _debtLimit,
        uint256 _targetAllocation,
        uint256 _bound
    ) external;

    function withdrawFromStrategyWaitingForRemoval(address strategy) external returns (uint256);

    function deposit() external payable;

    function withdraw(uint256 amount) external returns (bool);

    function withdrawAvailableToPool() external;

    function initializeStrategy(address strategy_) external;

    function shutdownStrategy() external;

    function withdrawFromReserve(uint256 amount) external;

    function updateStrategy(address newStrategy) external;

    function activateStrategy() external returns (bool);

    function deactivateStrategy() external returns (bool);

    function updatePerformanceFee(uint256 newPerformanceFee) external;

    function updateStrategistFee(uint256 newStrategistFee) external;

    function updateDebtLimit(uint256 newDebtLimit) external;

    function updateTargetAllocation(uint256 newTargetAllocation) external;

    function updateReserveFee(uint256 newReserveFee) external;

    function updateBound(uint256 newBound) external;

    function withdrawFromStrategy(uint256 amount) external returns (bool);

    function withdrawAllFromStrategy() external returns (bool);

    function harvest() external returns (bool);

    function getStrategiesWaitingForRemoval() external view returns (address[] memory);

    function getAllocatedToStrategyWaitingForRemoval(address strategy)
        external
        view
        returns (uint256);

    function getTotalUnderlying() external view returns (uint256);

    function getUnderlying() external view returns (address);

    function strategy() external view returns (IStrategy);
}


// File interfaces/IStakerVault.sol

pragma solidity 0.8.10;

interface IStakerVault {
    event Staked(address indexed account, uint256 amount);
    event Unstaked(address indexed account, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function initialize(address _token) external;

    function initializeLpGauge(address _lpGauge) external;

    function stake(uint256 amount) external;

    function stakeFor(address account, uint256 amount) external;

    function unstake(uint256 amount) external;

    function unstakeFor(
        address src,
        address dst,
        uint256 amount
    ) external;

    function approve(address spender, uint256 amount) external;

    function transfer(address account, uint256 amount) external;

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external;

    function increaseActionLockedBalance(address account, uint256 amount) external;

    function decreaseActionLockedBalance(address account, uint256 amount) external;

    function updateLpGauge(address _lpGauge) external;

    function poolCheckpoint() external returns (bool);

    function poolCheckpoint(uint256 updateEndTime) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function getToken() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function stakedAndActionLockedBalanceOf(address account) external view returns (uint256);

    function actionLockedBalanceOf(address account) external view returns (uint256);

    function getStakedByActions() external view returns (uint256);

    function getPoolTotalStaked() external view returns (uint256);

    function decimals() external view returns (uint8);

    function lpGauge() external view returns (address);
}


// File interfaces/pool/ILiquidityPool.sol

pragma solidity 0.8.10;


interface ILiquidityPool {
    event Deposit(address indexed minter, uint256 depositAmount, uint256 mintedLpTokens);

    event DepositFor(
        address indexed minter,
        address indexed mintee,
        uint256 depositAmount,
        uint256 mintedLpTokens
    );

    event Redeem(address indexed redeemer, uint256 redeemAmount, uint256 redeemTokens);

    event LpTokenSet(address indexed lpToken);

    event StakerVaultSet(address indexed stakerVault);

    event Shutdown();

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

    function updateVault(address _vault) external;

    function setLpToken(address _lpToken) external;

    function setStaker() external;

    function shutdownPool(bool shutdownStrategy) external;

    function shutdownStrategy() external;

    function updateRequiredReserves(uint256 _newRatio) external;

    function updateReserveDeviation(uint256 newRatio) external;

    function updateMinWithdrawalFee(uint256 newFee) external;

    function updateMaxWithdrawalFee(uint256 newFee) external;

    function updateWithdrawalFeeDecreasePeriod(uint256 newPeriod) external;

    function rebalanceVault() external;

    function getNewCurrentFees(
        uint256 timeToWait,
        uint256 lastActionTimestamp,
        uint256 feeRatio
    ) external view returns (uint256);

    function vault() external view returns (IVault);

    function staker() external view returns (IStakerVault);

    function getUnderlying() external view returns (address);

    function getLpToken() external view returns (address);

    function getWithdrawalFee(address account, uint256 amount) external view returns (uint256);

    function exchangeRate() external view returns (uint256);

    function totalUnderlying() external view returns (uint256);

    function name() external view returns (string memory);

    function isShutdown() external view returns (bool);
}


// File libraries/AddressProviderMeta.sol

pragma solidity 0.8.10;

library AddressProviderMeta {
    struct Meta {
        bool freezable;
        bool frozen;
    }

    function fromUInt(uint256 value) internal pure returns (Meta memory) {
        Meta memory meta;
        meta.freezable = (value & 1) == 1;
        meta.frozen = ((value >> 1) & 1) == 1;
        return meta;
    }

    function toUInt(Meta memory meta) internal pure returns (uint256) {
        uint256 value;
        value |= meta.freezable ? 1 : 0;
        value |= meta.frozen ? 1 << 1 : 0;
        return value;
    }
}


// File interfaces/IAddressProvider.sol

pragma solidity 0.8.10;




// solhint-disable ordering

interface IAddressProvider {
    event KnownAddressKeyAdded(bytes32 indexed key);
    event StakerVaultListed(address indexed stakerVault);
    event StakerVaultDelisted(address indexed stakerVault);
    event ActionListed(address indexed action);
    event ActionShutdown(address indexed action);
    event PoolListed(address indexed pool);
    event VaultUpdated(address indexed previousVault, address indexed newVault);
    event FeeHandlerAdded(address feeHandler);
    event FeeHandlerRemoved(address feeHandler);

    /** Key functions */
    function getKnownAddressKeys() external view returns (bytes32[] memory);

    function freezeAddress(bytes32 key) external;

    /** Pool functions */

    function allPools() external view returns (address[] memory);

    function addPool(address pool) external;

    function poolsCount() external view returns (uint256);

    function getPoolAtIndex(uint256 index) external view returns (address);

    function isPool(address pool) external view returns (bool);

    function getPoolForToken(address token) external view returns (ILiquidityPool);

    function safeGetPoolForToken(address token) external view returns (address);

    /** Vault functions  */

    function updateVault(address previousVault, address newVault) external;

    function allVaults() external view returns (address[] memory);

    function vaultsCount() external view returns (uint256);

    function getVaultAtIndex(uint256 index) external view returns (address);

    function isVault(address vault) external view returns (bool);

    /** Action functions */

    function allActions() external view returns (address[] memory);

    function actionsCount() external view returns (uint256);

    function getActionAtIndex(uint256 index) external view returns (address);

    function allActiveActions() external view returns (address[] memory);

    function addAction(address action) external returns (bool);

    function shutdownAction(address action) external;

    function isAction(address action) external view returns (bool);

    function isActiveAction(address action) external view returns (bool);

    /** Address functions */

    function initialize(address roleManager_, address treasury_) external;

    function initializeAddress(bytes32 key, address initialAddress) external;

    function initializeAddress(
        bytes32 key,
        address initialAddress,
        bool frezable
    ) external;

    function initializeAndFreezeAddress(bytes32 key, address initialAddress) external;

    function getAddress(bytes32 key) external view returns (address);

    function getAddress(bytes32 key, bool checkExists) external view returns (address);

    function getAddressMeta(bytes32 key) external view returns (AddressProviderMeta.Meta memory);

    function updateAddress(bytes32 key, address newAddress) external;

    function initializeInflationManager(address initialAddress) external;

    /** Staker vault functions */
    function allStakerVaults() external view returns (address[] memory);

    function tryGetStakerVault(address token) external view returns (bool, address);

    function getStakerVault(address token) external view returns (address);

    function addStakerVault(address stakerVault) external;

    function isStakerVault(address stakerVault, address token) external view returns (bool);

    function isStakerVaultRegistered(address stakerVault) external view returns (bool);

    function isWhiteListedFeeHandler(address feeHandler) external view returns (bool);

    /** Fee Handler function */
    function addFeeHandler(address feeHandler) external;

    function removeFeeHandler(address feeHandler) external;
}


// File interfaces/IFeeBurner.sol

pragma solidity 0.8.10;

interface IFeeBurner {
    function burnToTarget(address[] memory tokens, address targetLpToken)
        external
        payable
        returns (uint256);
}


// File interfaces/tokenomics/IMeroToken.sol

pragma solidity 0.8.10;

interface IMeroToken is IERC20 {
    function mint(address account, uint256 amount) external;

    function cap() external view returns (uint256);
}


// File interfaces/actions/IAction.sol

pragma solidity 0.8.10;

interface IAction {
    event UsableTokenAdded(address token);
    event UsableTokenRemoved(address token);
    event Paused();
    event Unpaused();
    event Shutdown();

    function addUsableToken(address token) external;

    function removeUsableToken(address token) external;

    function updateActionFee(uint256 actionFee) external;

    function updateFeeHandler(address feeHandler) external;

    function shutdownAction() external;

    function pause() external;

    function unpause() external;

    function getEthRequiredForGas(address payer) external view returns (uint256);

    function getUsableTokens() external view returns (address[] memory);

    function isUsable(address token) external view returns (bool);

    function feeHandler() external view returns (address);

    function isShutdown() external view returns (bool);

    function isPaused() external view returns (bool);
}


// File interfaces/tokenomics/IInflationManager.sol

pragma solidity 0.8.10;

interface IInflationManager {
    event KeeperGaugeListed(address indexed pool, address indexed keeperGauge);
    event AmmGaugeListed(address indexed token, address indexed ammGauge);
    event KeeperGaugeDelisted(address indexed pool, address indexed keeperGauge);
    event AmmGaugeDelisted(address indexed token, address indexed ammGauge);

    /** Pool functions */

    function setKeeperGauge(address pool, address _keeperGauge) external returns (bool);

    function setAmmGauge(address token, address _ammGauge) external returns (bool);

    function setMinter(address _minter) external;

    function advanceKeeperGaugeEpoch(address pool) external;

    function whitelistGauge(address gauge) external;

    function removeStakerVaultFromInflation(address lpToken) external;

    function removeAmmGauge(address token) external returns (bool);

    function addGaugeForVault(address lpToken) external;

    function checkpointAllGauges(uint256 updateEndTime) external;

    function mintRewards(address beneficiary, uint256 amount) external;

    function checkPointInflation() external;

    function removeKeeperGauge(address pool) external;

    function getAllAmmGauges() external view returns (address[] memory);

    function getLpRateForStakerVault(address stakerVault) external view returns (uint256);

    function getKeeperRateForPool(address pool) external view returns (uint256);

    function getAmmRateForToken(address token) external view returns (uint256);

    function getLpPoolWeight(address pool) external view returns (uint256);

    function getKeeperGaugeForPool(address pool) external view returns (address);

    function getAmmGaugeForToken(address token) external view returns (address);

    function gauges(address lpToken) external view returns (bool);

    function ammWeights(address gauge) external view returns (uint256);

    function lpPoolWeights(address gauge) external view returns (uint256);

    function keeperPoolWeights(address gauge) external view returns (uint256);

    function minter() external view returns (address);

    function weightBasedKeeperDistributionDeactivated() external view returns (bool);

    function totalKeeperPoolWeight() external view returns (uint256);

    function totalLpPoolWeight() external view returns (uint256);

    function totalAmmTokenWeight() external view returns (uint256);

    /** Weight setter functions **/

    function updateLpPoolWeight(address lpToken, uint256 newPoolWeight) external;

    function updateAmmTokenWeight(address token, uint256 newTokenWeight) external;

    function updateKeeperPoolWeight(address pool, uint256 newPoolWeight) external;

    function batchUpdateLpPoolWeights(address[] calldata lpTokens, uint256[] calldata weights)
        external;

    function batchUpdateAmmTokenWeights(address[] calldata tokens, uint256[] calldata weights)
        external;

    function batchUpdateKeeperPoolWeights(address[] calldata pools, uint256[] calldata weights)
        external;

    function deactivateWeightBasedKeeperDistribution() external;
}


// File interfaces/IController.sol

pragma solidity 0.8.10;





// solhint-disable ordering

interface IController {
    function addressProvider() external view returns (IAddressProvider);

    function addStakerVault(address stakerVault) external;

    function shutdownPool(ILiquidityPool pool, bool shutdownStrategy) external returns (bool);

    function shutdownAction(IAction action) external;

    /** Keeper functions */
    function updateKeeperRequiredStakedMERO(uint256 amount) external;

    function canKeeperExecuteAction(address keeper) external view returns (bool);

    function keeperRequireStakedMero() external view returns (uint256);

    /** Miscellaneous functions */

    function getTotalEthRequiredForGas(address payer) external view returns (uint256);
}


// File interfaces/ISwapperRouter.sol

pragma solidity 0.8.10;

interface ISwapperRouter {
    function swapAll(address fromToken, address toToken) external payable returns (uint256);

    function setSlippageTolerance(uint256 slippageTolerance_) external;

    function setCurvePool(address token_, address curvePool_) external;

    function swap(
        address fromToken,
        address toToken,
        uint256 amountIn
    ) external payable returns (uint256);

    function getAmountOut(
        address fromToken,
        address toToken,
        uint256 amountIn
    ) external view returns (uint256 amountOut);
}


// File libraries/AddressProviderKeys.sol

pragma solidity 0.8.10;

library AddressProviderKeys {
    bytes32 internal constant _TREASURY_KEY = "treasury";
    bytes32 internal constant _REWARD_HANDLER_KEY = "rewardHandler";
    bytes32 internal constant _GAS_BANK_KEY = "gasBank";
    bytes32 internal constant _VAULT_RESERVE_KEY = "vaultReserve";
    bytes32 internal constant _ORACLE_PROVIDER_KEY = "oracleProvider";
    bytes32 internal constant _POOL_FACTORY_KEY = "poolFactory";
    bytes32 internal constant _CONTROLLER_KEY = "controller";
    bytes32 internal constant _MERO_LOCKER_KEY = "meroLocker";
    bytes32 internal constant _INFLATION_MANAGER_KEY = "inflationManager";
    bytes32 internal constant _FEE_BURNER_KEY = "feeBurner";
    bytes32 internal constant _ROLE_MANAGER_KEY = "roleManager";
    bytes32 internal constant _SWAPPER_ROUTER_KEY = "swapperRouter";
}


// File libraries/AddressProviderHelpers.sol

pragma solidity 0.8.10;









library AddressProviderHelpers {
    /**
     * @return The address of the treasury.
     */
    function getTreasury(IAddressProvider provider) internal view returns (address) {
        return provider.getAddress(AddressProviderKeys._TREASURY_KEY);
    }

    /**
     * @return The address of the reward handler.
     */
    function getRewardHandler(IAddressProvider provider) internal view returns (address) {
        return provider.getAddress(AddressProviderKeys._REWARD_HANDLER_KEY);
    }

    /**
     * @dev Returns zero address if no reward handler is set.
     * @return The address of the reward handler.
     */
    function getSafeRewardHandler(IAddressProvider provider) internal view returns (address) {
        return provider.getAddress(AddressProviderKeys._REWARD_HANDLER_KEY, false);
    }

    /**
     * @return The address of the fee burner.
     */
    function getFeeBurner(IAddressProvider provider) internal view returns (IFeeBurner) {
        return IFeeBurner(provider.getAddress(AddressProviderKeys._FEE_BURNER_KEY));
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
     * @return The oracleProvider.
     */
    function getOracleProvider(IAddressProvider provider) internal view returns (IOracleProvider) {
        return IOracleProvider(provider.getAddress(AddressProviderKeys._ORACLE_PROVIDER_KEY));
    }

    /**
     * @return the address of the MERO locker
     */
    function getMEROLocker(IAddressProvider provider) internal view returns (address) {
        return provider.getAddress(AddressProviderKeys._MERO_LOCKER_KEY);
    }

    /**
     * @return the address of the MERO locker
     */
    function getRoleManager(IAddressProvider provider) internal view returns (IRoleManager) {
        return IRoleManager(provider.getAddress(AddressProviderKeys._ROLE_MANAGER_KEY));
    }

    /**
     * @return the controller
     */
    function getController(IAddressProvider provider) internal view returns (IController) {
        return IController(provider.getAddress(AddressProviderKeys._CONTROLLER_KEY));
    }

    /**
     * @return the inflation manager
     */
    function getInflationManager(IAddressProvider provider)
        internal
        view
        returns (IInflationManager)
    {
        return IInflationManager(provider.getAddress(AddressProviderKeys._INFLATION_MANAGER_KEY));
    }

    /**
     * @return the inflation manager or `address(0)` if it does not exist
     */
    function safeGetInflationManager(IAddressProvider provider)
        internal
        view
        returns (IInflationManager)
    {
        return
            IInflationManager(
                provider.getAddress(AddressProviderKeys._INFLATION_MANAGER_KEY, false)
            );
    }

    /**
     * @return the swapper router
     */
    function getSwapperRouter(IAddressProvider provider) internal view returns (ISwapperRouter) {
        return ISwapperRouter(provider.getAddress(AddressProviderKeys._SWAPPER_ROUTER_KEY));
    }
}


// File libraries/DecimalScale.sol

pragma solidity ^0.8.4;

library DecimalScale {
    uint8 internal constant _DECIMALS = 18; // 18 decimal places

    function scaleFrom(uint256 value, uint8 decimals) internal pure returns (uint256) {
        if (decimals == _DECIMALS) {
            return value;
        } else if (decimals > _DECIMALS) {
            return value / 10**(decimals - _DECIMALS);
        } else {
            return value * 10**(_DECIMALS - decimals);
        }
    }

    function scaleTo(uint256 value, uint8 decimals) internal pure returns (uint256) {
        if (decimals == _DECIMALS) {
            return value;
        } else if (decimals > _DECIMALS) {
            return value * 10**(decimals - _DECIMALS);
        } else {
            return value / 10**(_DECIMALS - decimals);
        }
    }
}


// File libraries/ScaledMath.sol

pragma solidity 0.8.10;

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


// File interfaces/vendor/UniswapRouter02.sol

pragma solidity 0.8.10;

interface UniswapRouter02 {
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external view returns (uint256 amountIn);

    function getAmountsIn(uint256 amountOut) external view returns (uint256[] memory amounts);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external view returns (uint256 amountOut);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) external view returns (uint256 reserveA, uint256 reserveB);

    function WETH() external pure returns (address);
}

interface UniswapV2Pair {
    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );
}

interface UniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}


// File interfaces/vendor/IWETH.sol

pragma solidity 0.8.10;

/**
 * @notice Interface for WETH9
 * @dev https://etherscan.io/address/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2#code
 */
interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}


// File interfaces/IERC20Full.sol

pragma solidity 0.8.10;

/// @notice This is the ERC20 interface including optional getter functions
/// The interface is used in the frontend through the generated typechain wrapper
interface IERC20Full is IERC20 {
    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function decimals() external view returns (uint8);
}


// File interfaces/vendor/ICurveSwapEth.sol

pragma solidity 0.8.10;

interface ICurveSwapEth {
    function get_virtual_price() external view returns (uint256);

    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount) external payable;

    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount) external payable;

    function remove_liquidity_imbalance(uint256[3] calldata amounts, uint256 max_burn_amount)
        external;

    function remove_liquidity_imbalance(uint256[2] calldata amounts, uint256 max_burn_amount)
        external;

    function remove_liquidity(uint256 _amount, uint256[3] calldata min_amounts) external;

    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external payable;

    function coins(uint256 i) external view returns (address);

    function get_dy(
        uint256 i,
        uint256 j,
        uint256 dx
    ) external view returns (uint256);

    function calc_token_amount(uint256[3] calldata amounts, bool deposit)
        external
        view
        returns (uint256);

    function calc_token_amount(uint256[2] calldata amounts, bool deposit)
        external
        view
        returns (uint256);

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i)
        external
        view
        returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;
}


// File contracts/swappers/SwapperRouter.sol

pragma solidity 0.8.10;










/**
 * The swapper router handles the swapping from one token to another.
 * By default it does all swaps through WETH, in two steps checking which DEX is better for each stage of the swap.
 * It also supports ETH in or out and handles it by converting to WETH and back.
 */
contract SwapperRouter is ISwapperRouter, Authorization {
    using SafeERC20 for IERC20;
    using DecimalScale for uint256;
    using ScaledMath for uint256;
    using AddressProviderHelpers for IAddressProvider;

    // Dex contracts
    address private constant _UNISWAP = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // Uniswap Router, used for swapping tokens on Uniswap
    address private constant _SUSHISWAP = address(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F); // Sushiswap Router, used for swapping tokens on Sushiswap
    IWETH private constant _WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // WETH, used for wrapping and unwrapping ETH for swaps

    IAddressProvider private immutable _addressProvider; // Address provider used for getting oracle provider

    uint256 public slippageTolerance; // The amount of slippage to allow from the oracle price of an asset
    mapping(address => ICurveSwapEth) public curvePools; // Curve Pool to use for swapping with WETH

    event Swapped(
        address indexed fromToken,
        address indexed toToken,
        uint256 amountIn,
        uint256 amountOut
    ); // Emitted after a successfull swap
    event SetSlippageTolerance(uint256 value); // Emitted after a successful setting of slippage tolerance
    event SetCurvePool(address token, address curvePool); // Emitted after a successful setting of a Curve Pool

    constructor(address addressProvider_)
        Authorization(IAddressProvider(addressProvider_).getRoleManager())
    {
        _addressProvider = IAddressProvider(addressProvider_);
        slippageTolerance = 0.97e18;
    }

    receive() external payable {} // Used for receiving ETH when unwrapping WETH

    /**
     * @notice Swaps all of the users balance of fromToken for toToken.
     * @param fromToken_ The token to swap from.
     * @param toToken_ The token to swap to.
     * @return amountOut The amount of toToken received.
     */
    function swapAll(address fromToken_, address toToken_)
        external
        payable
        override
        returns (uint256 amountOut)
    {
        // Swapping if from token is ETH
        if (fromToken_ == address(0)) {
            return swap(fromToken_, toToken_, address(this).balance);
        }

        // Swapping if from token is ERC20
        return swap(fromToken_, toToken_, IERC20(fromToken_).balanceOf(address(msg.sender)));
    }

    /**
     * @notice Set slippage tolerance for swaps.
     * @dev Stored as a multiplier, e.g. 2% would be set as 0.98.
     * @param slippageTolerance_ New slippage tolerance.
     */
    function setSlippageTolerance(uint256 slippageTolerance_) external override onlyGovernance {
        require(slippageTolerance_ <= ScaledMath.ONE, Error.INVALID_SLIPPAGE_TOLERANCE);
        slippageTolerance = slippageTolerance_;
        emit SetSlippageTolerance(slippageTolerance_);
    }

    /**
     * @notice Sets the Curve Pool to use for swapping a token with WETH.
     * @dev To use Uniswap or Sushiswap instead, set the Curve Pool to the zero address.
     * @param token_ The token to set the Curve Pool for.
     * @param curvePool_ The address of the Curve Pool.
     */
    function setCurvePool(address token_, address curvePool_) external override onlyGovernance {
        require(token_ != address(0), Error.ZERO_ADDRESS_NOT_ALLOWED);
        require(curvePool_ != address(curvePools[token_]), Error.SAME_ADDRESS_NOT_ALLOWED);
        curvePools[token_] = ICurveSwapEth(curvePool_);
        emit SetCurvePool(token_, curvePool_);
    }

    /**
     * @notice Gets the amount of toToken received by swapping amountIn of fromToken.
     * @dev In the case where a custom swapper is used, return value may not be precise.
     * @param fromToken_ The token to swap from.
     * @param toToken_ The token to swap to.
     * @param amountIn_ The amount of fromToken being swapped.
     * @return amountOut The amount of toToken received by swapping amountIn of fromToken.
     */
    function getAmountOut(
        address fromToken_,
        address toToken_,
        uint256 amountIn_
    ) external view override returns (uint256 amountOut) {
        if (fromToken_ == toToken_ || amountIn_ == 0) return amountIn_;

        return _getTokenOut(toToken_, _getWethOut(fromToken_, amountIn_));
    }

    /**
     * @notice Swaps an amount of fromToken to toToken.
     * @param fromToken_ The token to swap from.
     * @param toToken_ The token to swap to.
     * @param amountIn_ The amount of fromToken to swap for toToken.
     * @return amountOut The amount of toToken received.
     */
    function swap(
        address fromToken_,
        address toToken_,
        uint256 amountIn_
    ) public payable override returns (uint256 amountOut) {
        // Validating ETH value sent
        require(msg.value == (fromToken_ == address(0) ? amountIn_ : 0), Error.INVALID_AMOUNT);
        if (amountIn_ == 0) {
            emit Swapped(fromToken_, toToken_, 0, 0);
            return 0;
        }

        // Handling swap between the same token
        if (fromToken_ == toToken_) {
            if (fromToken_ == address(0)) {
                // solhint-disable-next-line avoid-low-level-calls
                (bool success, ) = payable(msg.sender).call{value: amountIn_}("");
                require(success, Error.FAILED_TRANSFER);
            }
            emit Swapped(fromToken_, toToken_, amountIn_, amountIn_);
            return amountIn_;
        }

        // Transferring to contract if ERC20
        if (fromToken_ != address(0)) {
            IERC20(fromToken_).safeTransferFrom(msg.sender, address(this), amountIn_);
        }

        // Swapping token via WETH
        uint256 amountOut_ = _swapWethForToken(toToken_, _swapForWeth(fromToken_));
        emit Swapped(fromToken_, toToken_, amountIn_, amountOut_);
        return _returnTokens(toToken_, amountOut_);
    }

    /**
     * @dev Swaps the full contract balance of token to WETH.
     * @param token_ The token to swap to WETH.
     * @return amountOut The amount of WETH received from the swap.
     */
    function _swapForWeth(address token_) internal returns (uint256 amountOut) {
        if (token_ == address(_WETH)) return _WETH.balanceOf(address(this));

        // Handling ETH -> WETH
        if (token_ == address(0)) {
            uint256 ethBalance_ = address(this).balance;
            if (ethBalance_ == 0) return 0;
            _WETH.deposit{value: ethBalance_}();
            return ethBalance_;
        }

        // Handling Curve Pool swaps
        ICurveSwapEth curvePool_ = curvePools[token_];
        if (address(curvePool_) != address(0)) {
            uint256 amount_ = IERC20(token_).balanceOf(address(this));
            if (amount_ == 0) return 0;
            _approve(token_, address(curvePool_));
            (uint256 wethIndex_, uint256 tokenIndex_) = _getIndices(curvePool_, token_);
            curvePool_.exchange(
                tokenIndex_,
                wethIndex_,
                amount_,
                _minWethAmountOut(amount_, token_)
            );
            return _WETH.balanceOf(address(this));
        }

        // Handling ERC20 -> WETH
        return _swap(token_, address(_WETH), IERC20(token_).balanceOf(address(this)));
    }

    /**
     * @dev Swaps the full contract balance of WETH to token.
     * @param token_ The token to swap WETH to.
     * @return amountOut The amount of token received from the swap.
     */
    function _swapWethForToken(address token_, uint256 amount_)
        internal
        returns (uint256 amountOut)
    {
        if (amount_ == 0) return 0;
        if (token_ == address(_WETH)) return amount_;

        // Handling WETH -> ETH
        if (token_ == address(0)) {
            _WETH.withdraw(amount_);
            return amount_;
        }

        // Handling Curve Pool swaps
        ICurveSwapEth curvePool_ = curvePools[token_];
        if (address(curvePool_) != address(0)) {
            _approve(address(_WETH), address(curvePool_));
            (uint256 wethIndex_, uint256 tokenIndex_) = _getIndices(curvePool_, token_);
            curvePool_.exchange(
                wethIndex_,
                tokenIndex_,
                amount_,
                _minTokenAmountOut(amount_, token_)
            );
            return IERC20(token_).balanceOf(address(this));
        }

        // Handling WETH -> ERC20
        return _swap(address(_WETH), token_, amount_);
    }

    /**
     * @dev Swaps an amount of fromToken to toToken.
     * @param fromToken_ The token to swap from.
     * @param toToken_ The token to swap to.
     * @param amount_ The amount of fromToken to swap.
     * @return amountOut The amount of toToken received from the swap.
     */
    function _swap(
        address fromToken_,
        address toToken_,
        uint256 amount_
    ) internal returns (uint256 amountOut) {
        if (amount_ == 0) return 0;
        if (fromToken_ == toToken_) return amount_;
        address dex_ = _getBestDex(fromToken_, toToken_, amount_);
        _approve(fromToken_, dex_);
        address[] memory path_ = new address[](2);
        path_[0] = fromToken_;
        path_[1] = toToken_;
        return
            UniswapRouter02(dex_).swapExactTokensForTokens(
                amount_,
                _getAmountOutMin(amount_, fromToken_, toToken_),
                path_,
                address(this),
                block.timestamp
            )[1];
    }

    /**
     * @dev Approves infinite spending for the given spender.
     * @param token_ The token to approve for.
     * @param spender_ The spender to approve.
     */
    function _approve(address token_, address spender_) internal {
        if (IERC20(token_).allowance(address(this), spender_) > 0) return;
        IERC20(token_).safeApprove(spender_, type(uint256).max);
    }

    /**
     * @dev Returns an amount of tokens to the sender.
     * @param token_ The token to return to sender.
     * @param amount_ The amount of tokens to return to sender.
     * @return amountReturned The amount of tokens returned to sender.
     */
    function _returnTokens(address token_, uint256 amount_)
        internal
        returns (uint256 amountReturned)
    {
        // Returning if ETH
        if (token_ == address(0)) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = payable(msg.sender).call{value: amount_}("");
            require(success, Error.FAILED_TRANSFER);
            return amount_;
        }

        // Returning if ERC20
        IERC20(token_).safeTransfer(msg.sender, amount_);
        return amount_;
    }

    /**
     * @dev Gets the amount of WETH received by swapping amount of token
     *      In the case where a custom swapper is used, return value may not be precise.
     * @param token_ The token to swap from.
     * @param amount_ The mount of token being swapped.
     * @return amountOut The amount of WETH received by swapping amount of token.
     */
    function _getWethOut(address token_, uint256 amount_)
        internal
        view
        returns (uint256 amountOut)
    {
        if (token_ == address(_WETH) || token_ == address(0)) return amount_;

        // Handling Curve Pool swaps
        ICurveSwapEth curvePool_ = curvePools[token_];
        if (address(curvePool_) != address(0)) {
            (uint256 wethIndex_, uint256 tokenIndex_) = _getIndices(curvePool_, token_);
            return curvePool_.get_dy(tokenIndex_, wethIndex_, amount_);
        }

        return
            _tokenAmountOut(
                token_,
                address(_WETH),
                amount_,
                _getBestDex(token_, address(_WETH), amount_)
            );
    }

    /**
     * @dev Gets the amount of token received by swapping amount of WETH
     *      In the case where a custom swapper is used, return value may not be precise.
     * @param token_ The token to swap to.
     * @param amount_ The amount of WETH being swapped.
     * @return amountOut The amount of token received by swapping amount of WETH.
     */
    function _getTokenOut(address token_, uint256 amount_)
        internal
        view
        returns (uint256 amountOut)
    {
        if (token_ == address(_WETH) || token_ == address(0)) return amount_;

        // Handling Curve Pool swaps
        ICurveSwapEth curvePool_ = curvePools[token_];
        if (address(curvePool_) != address(0)) {
            (uint256 wethIndex_, uint256 tokenIndex_) = _getIndices(curvePool_, token_);
            return curvePool_.get_dy(wethIndex_, tokenIndex_, amount_);
        }

        return
            _tokenAmountOut(
                address(_WETH),
                token_,
                amount_,
                _getBestDex(address(_WETH), token_, amount_)
            );
    }

    /**
     * @dev Gets the best dex to use for swapping tokens based on which gives the highest amount out.
     * @param fromToken_ The token to swap from.
     * @param toToken_ The token to swap to.
     * @param amount_ The amount of fromToken to swap.
     * @return bestDex The best dex to use for swapping tokens based on which gives the highest amount out
     */
    function _getBestDex(
        address fromToken_,
        address toToken_,
        uint256 amount_
    ) internal view returns (address bestDex) {
        address uniswap_ = _UNISWAP;
        address sushiswap_ = _SUSHISWAP;
        return
            _tokenAmountOut(fromToken_, toToken_, amount_, uniswap_) >=
                _tokenAmountOut(fromToken_, toToken_, amount_, sushiswap_)
                ? uniswap_
                : sushiswap_;
    }

    /**
     * @notice Gets the amount of toToken received by swapping amountIn of fromToken.
     * @param fromToken_ The token to swap from.
     * @param toToken_ The token to swap to.
     * @param amountIn_ The amount of fromToken being swapped.
     * @param dex_ The DEX to use for the swap.
     * @return amountOut The amount of toToken received by swapping amountIn of fromToken.
     */
    function _tokenAmountOut(
        address fromToken_,
        address toToken_,
        uint256 amountIn_,
        address dex_
    ) internal view returns (uint256 amountOut) {
        address[] memory path_ = new address[](2);
        path_[0] = fromToken_;
        path_[1] = toToken_;
        return UniswapRouter02(dex_).getAmountsOut(amountIn_, path_)[1];
    }

    /**
     * @dev Returns the minimum amount of toToken_ to receive from swap.
     * @param amount_ The amount of fromToken_ being swapped.
     * @param fromToken_ The Token being swapped from.
     * @param toToken_ The Token being swapped to.
     * @return amountOutMin The minimum amount of toToken_ to receive from swap.
     */
    function _getAmountOutMin(
        uint256 amount_,
        address fromToken_,
        address toToken_
    ) internal view returns (uint256 amountOutMin) {
        return
            fromToken_ == address(_WETH)
                ? _minTokenAmountOut(amount_, toToken_)
                : _minWethAmountOut(amount_, fromToken_);
    }

    /**
     * @dev Returns the minimum amount of Token to receive from swap.
     * @param wethAmount_ The amount of WETH being swapped.
     * @param token_ The Token the WETH is being swapped to.
     * @return minAmountOut The minimum amount of Token to receive from swap.
     */
    function _minTokenAmountOut(uint256 wethAmount_, address token_)
        internal
        view
        returns (uint256 minAmountOut)
    {
        uint256 priceInEth_ = _getPriceInEth(token_);
        if (priceInEth_ == 0) return 0;
        return
            wethAmount_.scaledDiv(priceInEth_).scaledMul(slippageTolerance).scaleTo(
                IERC20Full(token_).decimals()
            );
    }

    /**
     * @dev Returns the minimum amount of WETH to receive from swap.
     * @param tokenAmount_ The amount of Token being swapped.
     * @param token_ The Token that is being swapped for WETH.
     * @return minAmountOut The minimum amount of WETH to receive from swap.
     */
    function _minWethAmountOut(uint256 tokenAmount_, address token_)
        internal
        view
        returns (uint256 minAmountOut)
    {
        uint256 priceInEth_ = _getPriceInEth(token_);
        if (priceInEth_ == 0) return 0;
        return
            tokenAmount_.scaledMul(priceInEth_).scaledMul(slippageTolerance).scaleFrom(
                IERC20Full(token_).decimals()
            );
    }

    /**
     * @dev Returns the price in ETH of the given token.
     * If no oracle exists for the token, returns 0.
     * Only very minor assets should only ever return 0, which is why we choose
     * to accept the risk of not having proper slippage in place later
     * @param token_ The token to get the price for.
     * @return tokenPriceInEth The price of the token in ETH.
     */
    function _getPriceInEth(address token_) internal view returns (uint256 tokenPriceInEth) {
        IOracleProvider oracleProvider = _addressProvider.getOracleProvider();
        if (oracleProvider.isAssetSupported(token_)) {
            return oracleProvider.getPriceETH(token_);
        }

        return 0;
    }

    /**
     * @dev Returns the Curve Pool coin indices for a given Token.
     * @param curvePool_ The Curve Pool to return the indices for.
     * @param token_ The Token to get the indices for.
     * @return wethIndex_ The coin index for WETH.
     * @return tokenIndex_ The coin index for the Token.
     */
    function _getIndices(ICurveSwapEth curvePool_, address token_)
        internal
        view
        returns (uint256 wethIndex_, uint256 tokenIndex_)
    {
        return curvePool_.coins(1) == token_ ? (0, 1) : (1, 0);
    }
}