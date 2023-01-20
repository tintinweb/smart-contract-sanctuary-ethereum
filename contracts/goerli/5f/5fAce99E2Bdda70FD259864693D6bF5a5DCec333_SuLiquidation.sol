// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

// SPDX-License-Identifier: BSL 1.1

pragma solidity ^0.8.0;

import "../interfaces/ISuAccessControl.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title SuAuthenticated
 * @dev other contracts should inherit to be authenticated
 */
abstract contract SuAuthenticated is Initializable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant VAULT_ACCESS_ROLE = keccak256("VAULT_ACCESS_ROLE");
    bytes32 public constant LIQUIDATION_ACCESS_ROLE = keccak256("LIQUIDATION_ACCESS_ROLE");
    bytes32 private constant DEFAULT_ADMIN_ROLE = 0x00;

    // @dev the address of SuAccessControlSingleton - it should be one for all contract that inherits SuAuthenticated
    ISuAccessControl public ACCESS_CONTROL_SINGLETON;

    // @dev should be passed in constructor
    function __SuAuthenticated_init(address _accessControlSingleton) internal onlyInitializing {
        ACCESS_CONTROL_SINGLETON = ISuAccessControl(_accessControlSingleton);
        // TODO: check that _accessControlSingleton points to ISuAccessControl instance
        // require(ISuAccessControl(_accessControlSingleton).supportsInterface(ISuAccessControl.hasRole.selector), "bad dependency");
    }

    // @dev check DEFAULT_ADMIN_ROLE
    modifier onlyOwner() {
        require(ACCESS_CONTROL_SINGLETON.hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "SuAuth: onlyOwner AUTH_FAILED");
        _;
    }

    // @dev check VAULT_ACCESS_ROLE
    modifier onlyVaultAccess() {
        require(ACCESS_CONTROL_SINGLETON.hasRole(VAULT_ACCESS_ROLE, msg.sender), "SuAuth: onlyVaultAccess AUTH_FAILED");
        _;
    }

    // @dev check VAULT_ACCESS_ROLE
    modifier onlyLiquidationAccess() {
        require(ACCESS_CONTROL_SINGLETON.hasRole(LIQUIDATION_ACCESS_ROLE, msg.sender), "SuAuth: onlyLiquidationAccess AUTH_FAILED");
        _;
    }

    // @dev check MINTER_ROLE
    modifier onlyMinter() {
        require(ACCESS_CONTROL_SINGLETON.hasRole(MINTER_ROLE, msg.sender), "SuAuth: onlyMinter AUTH_FAILED");
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./ISuOracle.sol";

/**
 * @title RewardChefV2
 * @notice fork of MasterChefV2(May-13-2021) https://etherscan.io/address/0xef0881ec094552b2e128cf945ef17a6752b4ec5d#code
 * @dev This contract is based on MVC2, but uses "virtual" balances instead of storing real ERC20 tokens
 * and uses address of this assets instead of pid.
 * Rewards that are distributed have to be deposited using refillReward(uint256 amount, uint64 endBlock)
 **/
interface IRewardChefV2 {
    // @notice Info of each reward pool.
    // `allocPoint` The amount of allocation points assigned to the pool.
    // Also known as the amount of REWARD_TOKEN to distribute per block.
    struct PoolInfo {
        uint128 accSushiPerShare;
        uint64 lastRewardBlock;
        uint64 allocPoint;
        uint256 lpSupply;
    }

    // @notice Info of each user.
    // `amount` token amount the user has provided.
    // `rewardDebt` The amount of rewards entitled to the user.
    struct UserInfo {
        uint256 amount;
        int256 rewardDebt;

        uint256 multiplicator1e18;
        uint256 lockupPeriodSeconds;
        uint256 lockupStartTimestamp;
    }

    struct ILockupPeriod {
        uint256 lockupPeriodSeconds;
        uint256 multiplicator1e18;
    }

    // =======================================EVENTS=============================================
    event VirtualDeposit(address indexed user, address indexed asset, uint256 amount);
    event VirtualWithdraw(address indexed user, address indexed asset, uint256 amount);
    event ResetAmount(address indexed user, address indexed asset, address indexed to, uint256 amount, uint256 lockupPeriodSeconds);
    event Harvest(address indexed user, address indexed asset, uint256 amount);
    event LogPoolAddition(address indexed asset, uint256 allocPoint);
    event LogSetPool(address indexed asset, uint256 allocPoint);
    event LogUpdatePool(address indexed asset, uint64 lastRewardBlock, uint256 lpSupply, uint256 accSushiPerShare);

    // =========================================VARS====================_=========================
    // @dev Total allocation points. Must be the sum of all allocation points in all pools.
    // The good practice, to always keep this variable is equal 1000.
    function totalAllocPoint() external view returns ( uint256 );

    // =======================================REWARDER=============================================
    function REWARD_TOKEN() external view returns ( IERC20Upgradeable );
    function ORACLE() external view returns ( ISuOracle );
    function rewardPerBlock() external view returns ( uint256 );
    function rewardEndBlock() external view returns ( uint256 );

    function refillReward(uint256 amount, uint64 endBlock) external;
    /**
     *  @dev returns total amount of rewards allocated to the all pools on the rage (startBlock, endBlock]
     *      i.e. excluding startBlock but including endBlock
     */
    function rewardsBetweenBlocks(uint256 startBlock, uint256 endBlock) external returns ( uint256 );

    //=======================================LOCKUP LOGIC===========================================
    function getPossibleLockupPeriodsSeconds() external view returns (ILockupPeriod[] memory);
    function setPossibleLockupPeriodsSeconds(uint256 lockupPeriodSeconds, uint256 multiplicator1e18) external;

    //================================CORE REWARD CHEF METHODS======================================
    // @notice Add a new reward pool. Can only be called by the owner.
    // DO NOT add the same LP token more than once.
    // @param allocPoint AP of the new pool.
    // @param _asset Address of the ERC-20 token.
    function add(uint256 allocPoint, address _asset) external;

    // @notice Update the given pool's REWARD_TOKEN allocation point. Can only be called by the owner.
    // @param _asset Address of the ERC-20 token.
    // @param _allocPoint New AP of the pool.
    function set(address _asset, uint256 _allocPoint) external;

    // @notice View function to see pending REWARD_TOKEN on frontend.
    // @param _asset Address of the ERC-20 token.
    // @param _user Address of user.
    // @return pending REWARD_TOKEN reward for a given user.
    function pendingSushi(address _asset, address _user) external view returns ( uint256 );

    // @notice Update reward variables of the given pool.
    // @param asset Asset address
    // @return pool Returns the pool that was updated.
    function updatePool(address asset) external returns ( PoolInfo memory );

    // @notice Update reward variables for all pools. Be careful of gas spending!
    function updateAllPools() external;

    // @notice analogues to MCV2 Deposit method, but can be called only by trusted address
    // that is trusted to honestly calc how many "virtual" tokens have to be allocated for each user.
    function increaseAmount(address asset, address to, uint256 amountEDecimal, uint256 lockupPeriodSeconds) external;

    // @notice Analogues to MVC2 Withdraw method, that can be called only by trusted address
    // that is trusted to honestly calc how many "virtual" tokens have to be allocated for each user.
    function decreaseAmount(address asset, address to, uint256 amountEDecimal) external;

    function decreaseAmountRewardPenalty(address asset, address to, uint256 amountEDecimal) external view returns (uint256);

    // @notice Harvest proceeds for transaction sender to `to`.
    // @param asset Asset address
    // @param to Receiver of REWARD_TOKEN rewards.
    function harvest(address asset, address to, uint256 newLockupPeriodSeconds) external;

    // TODO: check for exploits
    // @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    // @param asset Asset address
    // @param to The address of the user whose information will be cleared
    function resetAmount(address asset, address to) external;

    //================================VIEW METHODS======================================
    function getPoolApr(address asset) external view  returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";

/**
 * @notice Access control for contracts
 * @dev External interface of AccessControl declared to support ERC165 detection.
 **/
interface ISuAccessControl is IAccessControlUpgradeable {
    /**
     * @dev Transfers all roles from caller to owner, and revoke all roles from the caller.
     **/
    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title SuLendingHelpers
 * @notice Abstract contract that should be in SuManager. Here we have all view and ui-helpers methods.
 * Here we don't change any values.
 **/
interface ISuLendingHelpers {
    /* ===================== ERRORS ===================== */

    error InvalidArgs();

    /* ==================== VIEW METHODS ==================== */

    // @notice view function to check if position is liquidatable
    function isLiquidatablePosition(address asset, address owner) external view returns (bool);

    // @notice Returns information about a liquidating position
    // @param asset The address of the main collateral token of a position
    // @param owner The owner of the collateral
    // @return liquidationBlock The block number when the liquidation was triggered
    // @return collateralEDecimal The amount of collateral
    // @return debtWithFeesE18 The amount of borrowed stablecoins with accumulated fee
    function getPositionInfo(address asset, address owner) external view returns (uint256 liquidationBlock, uint256 collateralEDecimal, uint256 debtWithFeesE18);

    // @notice Returns information about a liquidating position
    // @param asset The address of the main collateral token of a position
    // @param owner The owner of the collateral
    // @return liquidationBlock The block number when the liquidation was triggered
    function getLiquidationBlock(address asset, address owner) external view returns (uint256);

    // @notice USD value of collateral of owner
    function getCollateralUsdValueE18(address asset, address owner) external view returns (uint);

    /* ==================== UI HELPERS ==================== */

    // @notice Returns Loan-To-Value in e18
    function getLTVE18(address asset, address owner) external view returns (uint256);

    // @notice Returns Available to Borrow
    // we have invariant: (collateralAmountEDecimal * collateralPriceE18 / 1e18) * initialCollateralRatioE18 <= debtE18
    // Has similar logic like in _ensurePositionCollateralization
    function getAvailableToBorrowE18(address asset, address owner) external view returns (uint256);

    // @notice Returns Available to Withdraw
    // Has similar invariant like in getAvailableToBorrowE18
    function getAvailableToWithdrawE18(address asset, address owner) external view returns (uint256);

    // @notice calculate liquidation price
    // @dev can be used inside of _isLiquidatablePosition
    function liquidationPriceE18(address asset, address owner) external view returns (uint256);

    function liquidationPriceByAmount(
        address asset,
        address owner,
        uint256 additionalCollateralAmount,
        uint256 additionalStablecoinAmount
    ) external view returns (uint256);

    // @notice view function to show utilization ratio
    // the same function can be used inside of _isLiquidatablePosition
    function utilizationRatioE18(address asset, address owner) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title SuLendingLiquidation
 * @notice Abstract contract that should be in SuManager.
 * Here we have all support mutable methods that will be used in SuLiquidation.
 **/
interface ISuLendingLiquidation {
    /* ===================== ERRORS ===================== */

    error PositionIsSafe();
    error LiquidationIsTriggered();
    error LiquidationIsNotTriggered();
    error SmallCollateral();

    /* ==================== MUTABLE METHODS ==================== */

    // @notice Marks a position as to be liquidated
    // @param asset The address of the main collateral token of a position
    // @param owner The owner of a position
    /** @dev
    Emits LiquidationTriggered event.
    Sets the current block as liquidationBlock for the position.
    Can be triggered only once for the position.
    */
    function triggerLiquidation(address asset, address owner) external;

    // @notice Liquidates a position, just cut debt and withdraw user collateral without asking USDPro
    // @dev Supports a partial liquidation
    // @param asset The address of the main collateral token of a position
    // @param owner The owner of the collateral
    // @param repayer The person who repaies by debt and transfers stablecoins to the foundation
    // @param stablecoinsToRepaymentE18 The amount of stablecoins which will be burned as a debt repaymention
    // @param assetAmountEDecimal The position's collateral which be recieved by repayer
    function liquidate(
        address asset,
        address owner,
        address repayer,
        uint256 stablecoinsToRepaymentE18,
        uint256 assetAmountEDecimal
    ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "../interfaces/ISuLiquidationDiscount.sol";

interface ISuLiquidation is ISuLiquidationDiscount {
    // @notice Calculates a liquidation discount. Depends on a block number
    function calculateLiquidationDiscount(address asset, address owner) external view returns (uint256);

    // @notice Swaps stablecoins from the whitelist to an asset which is liquidating
    //     The liquidator specifies a position(asset, owner) which is liquidating
    //
    //     The liquidator specifies an amount of stablecoins which he wants to swap to an asset.
    //     The amount of asset is determined from current price and liquidation discount.
    //     Also, the liquidator specifies the minimum amount of asset which he agrees to recieve.
    //
    //     The list of available stablecoins is restricted by whitelist.
    //
    //     The liquidator transfers his stablecoins to the address of this contract.
    //     Further(see swapUsdProToStablecoin()) it can be swapped to USDPro.
    //     At the same moment, the SuVault contract decreases the amount of debt by position and
    //     withdraws the collateral to the liquidator
    function swapStablecoinToAsset(
        address asset,
        address owner,
        address stablecoinToken,
        uint256 stablecoinAmountEDecimal,
        uint256 minAssetAmountEDecimal
    ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import "../liquidator/SuLiquidationStructs.sol";

interface ISuLiquidationDiscount {
    // @notice Sets percentages of discounts for different asset and discount types(aggressive/middle/conservative)
    //     We can set different discounts for the first block and for other blocks per minute
    function setDiscountInfo(
        address asset,
        DiscountType discountType,
        DiscountInfo calldata discountInfo
    ) external;

    // @notice Returns information about discount percentages which are used for discount calculation
    function getDiscountInfo(
        address asset,
        DiscountType discountType
    ) external view returns (DiscountInfo memory discountInfo);
    
    // @notice Calculates the liquidation discount in percents by passed blocks.
    //     We have three discount types(see SuLiquidationStruct.sol)
    function calculateDiscountE18(
        address asset,
        DiscountType discountType,
        uint256 liquidationBlock
    ) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ISuManagerParameters.sol";
import "./ISuLendingHelpers.sol";
import "./ISuLendingLiquidation.sol";

/**
 * @title SuManager
 * @notice Manager mighty over the vault. Allows users to interact with their CDPs.
 * User does only interact with manager as proxy to the vault.
 **/
interface ISuManager is ISuManagerParameters, ISuLendingHelpers, ISuLendingLiquidation {
    /* ===================== EVENTS ===================== */
    // @notice Even triggered when user deposit collateral
    event Join(address indexed asset, address indexed owner, uint256 main, uint256 stablecoin);

    // @notice Event triggered when user withdraws collateral
    event Exit(address indexed asset, address indexed owner, uint256 main, uint256 stablecoin);

    /* ===================== ERRORS ===================== */
    error Restricted();
    error UselessTransaction();
    error UnsupportedDecimals();
    error UnderCollateralized();

    /* ==================== METHODS ==================== */
    // @notice this function is called by user to deposit collateral and receive stablecoin
    // @dev before calling this function user has to approve the Vault to take his collateral
    function join(address asset, uint256 assetAmountEDecimal, uint256 stablecoinAmountE18, uint256 lockupPeriodSeconds) external;

    // @notice user can pay back the stablecoin and take his collateral
    // instead of passing both assetAmount and stablecoinAmount
    // better user just to pass one of them
    // also pass preferred rate and maybe acceptable diff percent
    // that's the purpose of passing both to protect user from rate fluctuations
    function exit(address asset, uint256 assetAmountEDecimal, uint256 stablecoinAmountE18) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface ISuManagerParameters {
    /* ====================== VARS ====================== */
    // @notice When ratio (debt / usdValue) goes below it user can't withdraw or borrow.
    // Should be >= liquidationRatioE18. 1e18 = 100% ratio. Should be less than 1e18.
    // Is used to calculate available to withdraw and borrow.
    // For example, user can borrow <= usdValue * initialCollateralRatio
    function initialCollateralRatioE18 (address asset) external view returns ( uint256 );

    // @notice Ratio when cdp can be liquidated.
    // 1e18 = 100% ratio. Should be less than 1e18.
    // Is used in isLiquidatablePosition(). It's true when debt / usdValue >= liquidationRatio
    function liquidationRatioE18 (address asset) external view returns ( uint256 );

    // @notice The minimum value of collateral in USD which allowed to be left after partial closure
    function minCollateralInUsdE18 ( ) external view returns ( uint256 );

    /* ===================== ERRORS ===================== */
    error BadLiquidationRatioValue();
    error BadInitialCollateralRatioValue();

    /* ==================== METHODS ==================== */
    function setCollateral (
        address asset,
        uint256 stabilityFeeValueE18,
        uint256 initialCollateralRatioValueE18,
        uint256 liquidationRatioValueE18,
        uint256 stablecoinLimitE18,
        uint256 minCollateralInUsdValueE18
    ) external;

    /**
     * @notice Only manager is able to call this function
     * @dev Sets the initial collateral ratio
     * @param asset The address of the main collateral token
     * @param newValueE18 The collateralization ratio (1e18 = 100%)
     **/
    function setInitialCollateralRatioE18 ( address asset, uint256 newValueE18 ) external;

    /**
     * @notice Only manager is able to call this function
     * @dev Sets the liquidation ratio
     * @param asset The address of the main collateral token
     * @param newValueE18 The liquidation ratio (1e18 = 100%).
     **/
    function setLiquidationRatioE18 ( address asset, uint256 newValueE18 ) external;

    /**
     * @notice Only manager is able to call this function
     * @dev Sets a minimum value of collateral in USD which allowed to be left after partial closure
     * @param newValueE18 The minimum value of collateral in USD
     */
    function setMinCollateralInUsdE18 ( uint256 newValueE18 ) external;
}

// SPDX-License-Identifier: UNLICENSED

// solhint-disable compiler-version
pragma solidity >=0.7.6;

interface ISuOracle {
    /**
     * @notice WARNING! Read this description very carefully!
     *      function getUsdPrice1e18(address asset) returns (uint256) that:
     *          basicAmountOfAsset * getUsdPrice1e18(asset) / 1e18 === $$ * 1e18
     *      in other words, it doesn't matter what's the erc20.decimals is,
     *      you just multiply token balance in basic units on value from oracle and get dollar amount multiplied on 1e18.
     *
     * different assets have different deviation threshold (errors)
     *      for wBTC it's <= 0.5%, read more https://data.chain.link/ethereum/mainnet/crypto-usd/btc-usd
     *      for other asset is can be larger based on particular oracle implementation.
     *
     * examples:
     *       market price of btc = $30k,
     *       for 0.1 wBTC the unit256 amount is 0.1 * 1e18
     *       0.1 * 1e18 * (price1e18 / 1e18) == $3000 == uint256(3000*1e18)
     *       => price1e18 = 30000 * 1e18;
     *
     *       market price of usdt = $0.97,
     *       for 1 usdt uint256 = 1 * 1e6
     *       so 1*1e6 * price1e18 / 1e18 == $0.97 == uint256(0.97*1e18)
     *       => 1*1e6 * (price1e18 / 1e18) / (0.97*1e18)   = 1
     *       =>  price1e18 = 0.97 * (1e18/1e6) * 1e18
     *
     *      assume market price of wBTC = $31,503.77, oracle error = $158
     *
     *       case #1: small amount of wBTC
     *           we have 0.0,000,001 wBTC that is worth v = $0.00315 ± $0.00001 = 0.00315*1e18 = 315*1e13 ± 1*1e13
     *           actual balance on the asset b = wBTC.balanceOf() =  0.0000001*1e18 = 1e11
     *           oracle should return or = oracle.getUsdPrice1e18(wBTC) <=>
     *           <=> b*or = v => v/b = 315*1e13 / 1e11 = 315*1e2 ± 1e2
     *           error = or.error * b = 1e2 * 1e11 = 1e13 => 1e13/1e18 usd = 1e-5 = 0.00001 usd
     *
     *       case #2: large amount of wBTC
     *           v = 2,000,000 wBTC = $31,503.77 * 2m ± 158*2m = $63,007,540,000 ± $316,000,000 = 63,007*1e24 ± 316*1e24
     *           for calc convenience we increase error on 0.05 and have v = 63,000*24 ± 300*1e24 = (630 ± 3)*1e26
     *           b = 2*1e6 * 1e18 = 2*1e24
     *           or = v/b = (630 ± 3)*1e26 / 2*1e24 = 315*1e2 ± 1.5*1e2
     *           error = or.error * b = 1.5*100 * 2*1e24 = 3*1e26 = 3*1e8*1e18 = $300,000,000 ~ $316,000,000
     *
     *      assume the market price of USDT = $0.97 ± $0.00485,
     *
     *       case #3: little amount of USDT
     *           v = USDT amount 0.005 = 0.005*(0.97 ± 0.00485) = 0.00485*1e18 ± 0.00002425*1e18 = 485*1e13 ± 3*1e13
     *           we rounded error up on (3000-2425)/2425 ~= +24% for calculation convenience.
     *           b = USDT.balanceOf() = 0.005*1e6 = 5*1e3
     *           b*or = v => or = v/b = (485*1e13 ± 3*1e13) / 5*1e3 = 970*1e9 ± 6*1e9
     *           error = 6*1e9 * 5*1e3 / 1e18 = 30*1e12/1e18 = 3*1e-5 = $0,00005
     *
     *       case #4: lot of USDT
     *           v = we have 100,000,000,000 USDT = $97B = 97*1e9*1e18 ± 0.5*1e9*1e18
     *           b = USDT.balanceOf() = 1e11*1e6 = 1e17
     *           or = v/b = (97*1e9*1e18 ± 0.5*1e9*1e18) / 1e17 = 970*1e9 ± 5*1e9
     *           error = 5*1e9 * 1e17 = 5*1e26 = 0.5 * 1e8*1e18
     *
     * @param asset - address of erc20 token contract
     * @return usdPrice1e18 such that asset.balanceOf() * getUsdPrice1e18(asset) / 1e18 == $$ * 1e18
     **/
    function getUsdPrice1e18(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: BSL 1.1
/*
  Copyright 2022 StableUnit: Artem Belozerov
*/
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "hardhat/console.sol";
import "../interfaces/ISuLiquidation.sol";
import "../interfaces/ISuOracle.sol";
import "../interfaces/IRewardChefV2.sol";
import "../interfaces/ISuManager.sol";
import "./SuLiquidationDiscount.sol";
import "./SuLiquidationStructs.sol";

contract SuLiquidation is SuLiquidationDiscount, ISuLiquidation {
    error ZeroAddress();
    error LessThanMinimum();
    error NotEnoughAmount();
    error NotEnoughDeferredAmount();
    error TooMuchAmount();

    // solhint-disable var-name-mixedcase
    ISuManager internal SU_MANAGER;
    ISuOracle internal SU_ORACLE;
    IRewardChefV2 internal SU_REWARD;
    // solhint-enable var-name-mixedcase

    // asset => structure of deferred stablecoin amount:
    // - liquidationBlock - the block number when the liquidation was triggered.
    // - toRepaymentE18 - amount of stablecoins which will be burned as debt repayment.
    // - toFoundationE18 - amount of stablecoins which will be transfered to the foundation
    //      as an excess of stablecoins over debt repayment
    mapping(address => DeferredStablecoinAmount) internal _deferredStablecoinAmounts;

    function initialize(
        address _authControl,
        address _suManager,
        address _suOracle,
        address _suReward
    ) public initializer {
        SuLiquidationDiscount.init(_authControl);

        if (_suManager == address(0) || _suOracle == address(0)) revert ZeroAddress();

        SU_MANAGER = ISuManager(_suManager);
        SU_ORACLE = ISuOracle(_suOracle);
        SU_REWARD = IRewardChefV2(_suReward);
    }

    // @notice Calculates a liquidation discount
    // @param asset The address of the collateral token
    // @param owner The owner of the collateral
    function calculateLiquidationDiscount(
        address asset,
        address owner
    ) external view returns (uint256) {

        // get the block number when the liquidation was triggered
        uint256 liquidationBlock = SU_MANAGER.getLiquidationBlock(asset, owner);

        // discount depends on a block number
        return _getAggressiveOrMiddleDiscountE18(asset, owner, liquidationBlock);
    }

    // @notice Swaps stablecoins from the whitelist to the collateral
    // @dev This is a first step of two
    // @param asset The address of the collateral token
    // @param owner The owner of the collateral
    // @param stablecoinToken The address of the stablecoin token
    // @param stablecoinAmountEDecimal The amount of stablecoins for the collateral buyout
    // @param minAssetAmountEDecimal The minimum amount of collateral which the liquidator desires to obtain
    function swapStablecoinToAsset(
        address asset,
        address owner,
        address stablecoinToken,
        uint256 stablecoinAmountEDecimal,
        uint256 minAssetAmountEDecimal
    ) external {
        // TODO: whitelist

        // calculate the price in usd
        uint256 usdPriceOfStablecoinE18 = SU_ORACLE.getUsdPrice1e18(stablecoinToken);
        uint256 stablecoinAmountE18 = usdPriceOfStablecoinE18 * stablecoinAmountEDecimal / 1e18;

        // prepare parameters of the liquidation
        (
            uint256 assetAmountE18,
            uint256 usdProToRepaymentE18,
            uint256 usdProToFoundationE18
        ) = _prepareLiquidationParams(asset, owner, stablecoinAmountE18, minAssetAmountEDecimal);

        // store the stablecoins of the liquidator to this contract
        uint256 paidStablecoinAmountEDecimal = (usdProToRepaymentE18 + usdProToFoundationE18) * 1e18 / usdPriceOfStablecoinE18;
        SafeERC20Upgradeable.safeTransferFrom(
            IERC20Upgradeable(stablecoinToken),
            msg.sender,
            address(this),
            paidStablecoinAmountEDecimal
        );

        // get the block number when the liquidation was triggered
        // it will be needed to calculate the conservative discount
        // TODO: replace to _deferStablecoinsE18()
        uint256 liquidationBlock = SU_MANAGER.getLiquidationBlock(asset, owner);

        // save the stablecoin amounts for the future payments
        // when another actor will swap USDPro to the stablecoins(second step)
        _deferStablecoinsE18(
            stablecoinToken,
            liquidationBlock,
            usdProToRepaymentE18,
            usdProToFoundationE18
        );

        // cut the part of debt repayment and withdraw the part of collateral to the liquidator
        SU_MANAGER.liquidate(asset, owner, msg.sender, usdProToRepaymentE18, assetAmountE18);
    }

    // @notice Returns parameters for future liquidation
    // @param asset The address of the collateral token
    // @param owner The owner of the collateral
    // @param stablecoinAmountE18 The amount of stablecoins for the collateral buyout
    // @param minAssetAmountEDecimal The minimum amount of collateral which the liquidator desires to obtain
    function _prepareLiquidationParams(
        address asset,
        address owner,
        uint256 stablecoinAmountE18,
        uint256 minAssetAmountEDecimal
    ) internal view returns (uint256, uint256, uint256) {
        // get CDP info from the vault
        // TODO: remove liquidationBlock from response
        (
            uint256 liquidationBlock,
            uint256 collateralEDecimal,
            uint256 debtWithFeesE18
        ) = SU_MANAGER.getPositionInfo(asset, owner);

        console.log("LIQUIDATION PARAMS (block, collaterl, debt):", liquidationBlock, collateralEDecimal, debtWithFeesE18);

        // discount depends on a block number
        uint256 discountE18 = _getAggressiveOrMiddleDiscountE18(asset, owner, liquidationBlock);

        // calculate the price of asset in USD
        uint256 usdPriceOfAssetE18 = SU_ORACLE.getUsdPrice1e18(asset);

        // calculate the amount of asset which will be withdrawn to the liquidator
        (uint256 assetAmountEDecimal, uint256 discountedStablecoinAmountE18) = _calculateLiquidationAssetAmount(
            usdPriceOfAssetE18,
            stablecoinAmountE18,
            collateralEDecimal,
            discountE18
        );
        if (assetAmountEDecimal < minAssetAmountEDecimal) revert LessThanMinimum();

        // an excess amount will be transfered to the foundation
        // the rest - will be burned as the debt repayment
        (uint256 repaymentE18, uint256 excessE18) = _calculateLiquidationStablecoinAmount(
            debtWithFeesE18,
            discountedStablecoinAmountE18
        );
        return (assetAmountEDecimal, repaymentE18, excessE18);
    }

    // @notice Calculates the amount of asset which will be liquidated
    // @param usdPriceOfAssetE18 The price of collateral in worth of stablecoins
    // @param stablecoinAmountE18 The amount of stablecoins for the collateral buyout
    // @param collateralEDecimal The amount of collateral
    // @param discountE18 The percentage of discount for a liquidator
    function _calculateLiquidationAssetAmount(
        uint256 usdPriceOfAssetE18,
        uint256 stablecoinAmountE18,
        uint256 collateralEDecimal,
        uint256 discountE18
    ) internal view returns (uint256, uint256) {

        // calculate value of collateral
        uint256 collateralValueE18 = usdPriceOfAssetE18 * collateralEDecimal / 1e18;

        console.log("CALC_BONUS collateral(amount * price = assetValue):", collateralEDecimal, usdPriceOfAssetE18, collateralValueE18);
        console.log("CALC_BONUS stablecoin (stablecoinAmountE18, discountE18):", stablecoinAmountE18, discountE18);

        // apply the discount. the amount of stablecoins could be decreased after the discount applying.
        uint256 stablecoinAmountWithBonusE18;
        (stablecoinAmountE18, stablecoinAmountWithBonusE18) = _applyDiscount(
            collateralValueE18,
            stablecoinAmountE18,
            discountE18
        );

        console.log("CALC_BONUS stablecoin remainder:", collateralValueE18 - stablecoinAmountWithBonusE18);
        console.log("CALC_BONUS stablecoin bonus:", stablecoinAmountWithBonusE18 - stablecoinAmountE18);
        console.log("CALC_BONUS stablecoin payment:", stablecoinAmountE18);

        // calculate an amount of asset which a liquidator could take for his stablecoins
        // including bonus
        uint256 assetAmountEDecimal = stablecoinAmountWithBonusE18 * 1e18 / usdPriceOfAssetE18;
        return (assetAmountEDecimal, stablecoinAmountE18);
    }

    // @notice Returns the bonus and the amount of stablecoins after applying the discount
    // @param collateralValueE18 The amount of collateral in worth of the stablecoins
    // @param stablecoinAmountE18 The amount of stablecoins for the collateral buyout
    // @param discountE18 The percentage of discount for a liquidator
    function _applyDiscount(
        uint256 collateralValueE18,
        uint256 stablecoinAmountE18,
        uint256 discountE18
    ) internal pure returns (
        uint256 stablecoinAmountWithoutBonusE18,
        uint256 stablecoinAmountWithBonusE18
    ) {
        stablecoinAmountWithBonusE18 = stablecoinAmountE18 * (1e18 + discountE18) / 1e18;

        // decrease the amount of stablecoins which will be withdrawn from the liquidator
        // if the total amount(with bonus) more then the collateral value
        if (stablecoinAmountWithBonusE18 > collateralValueE18) {
            stablecoinAmountWithBonusE18 = collateralValueE18;
            stablecoinAmountWithoutBonusE18 = collateralValueE18 * 1e18 / (1e18 + discountE18);
        } else {
            stablecoinAmountWithoutBonusE18 = stablecoinAmountE18;
        }
    }

    // @notice Calculates what the amount of stablecoins goes to repay the debt
    // @param debtE18 The amount of borrowed stablecoins
    // @param amountE18 The amount of the sender's stablecoins
    function _calculateLiquidationStablecoinAmount(
        uint256 debtE18,
        uint256 amountE18
    ) internal pure returns (
        uint256 repaymentE18,
        uint256 excessE18
    ) {
        if (amountE18 > debtE18) {
            excessE18 = amountE18 - debtE18;
            repaymentE18 = debtE18;
        } else {
            repaymentE18 = amountE18;
        }
    }

    // @notice Stores stablecoins for the future payments
    // @param stablecoinToken The address of the stablecoin token
    // @param liquidationBlock The block number when the liquidation was triggered
    // @param toRepaymentE18 The amount of stablecoins which will be burned as a debt repayment
    // @param toFoundationE18 The amount of stablecoins which will be transfered to the foundation
    //     (fees and the excess of stablecoins over the debt amount)
    function _deferStablecoinsE18(
        address stablecoinToken,
        uint256 liquidationBlock,
        uint256 toRepaymentE18,
        uint256 toFoundationE18
    ) internal {
        DeferredStablecoinAmount storage deferredAmount = _deferredStablecoinAmounts[stablecoinToken];
        deferredAmount.toRepaymentE18 += toRepaymentE18;
        deferredAmount.toFoundationE18 += toFoundationE18;
        if (deferredAmount.liquidationBlock == 0) {
            deferredAmount.liquidationBlock = liquidationBlock;
        }
    }

    function _getAggressiveOrMiddleDiscountE18(
        address asset,
        address owner,
        uint256 liquidationBlock
    ) internal view returns (uint256) {
        DiscountType discountType = (owner == address(SU_REWARD)) ? DiscountType.middle : DiscountType.aggressive;
        return calculateDiscountE18(asset, discountType, liquidationBlock);
    }

    /**
    // @notice Swaps USDPro to the collateral
    // @param asset The address of the collateral token
    // @param owner The owner of the collateral
    // @param stablecoinAmountE18 The amount of stablecoins for the collateral buyout
    // @param minAssetAmountEDecimal The minimum amount of collateral which the liquidator desires to obtain
    function swapUsdProToAsset(
        address asset,
        address owner,
        uint256 stablecoinAmountE18,
        uint256 minAssetAmountEDecimal
    ) external {

        // prepare parameters of the liquidation
        (
        uint256 assetAmountE18,
        uint256 stablecoinsToRepaymentE18,
        uint256 stablecoinsToFoundationE18
        ) = _prepareLiquidationParams(asset, owner, stablecoinAmountE18, minAssetAmountEDecimal);

        // repay the part of debt and withdraw the part of collateral to the liquidator
        SU_LENDING_LIQUIDATION.liquidateAndRepay(
            asset,
            owner,
            msg.sender,
            stablecoinsToRepaymentE18,
            stablecoinsToFoundationE18,
            assetAmountE18
        );
    }

    // @notice Swaps USDPro to stablecoins from the whitelist
    // @dev This is a second step of two
    // @param stablecoinToken The address of the stablecoin token
    // @param stablecoinAmountEDecimal The amount of stablecoins
    function swapUsdProToStablecoin(
        address stablecoinToken,
        uint256 stablecoinAmountEDecimal
    ) external {
        // TODO: whitelist

        // calculate the prices in usd
        uint256 stablecoinAmountE18 = SU_ORACLE.getUsdPrice1e18(stablecoinToken) * stablecoinAmountEDecimal / 1e18;

        // reduce an amount of deferred stablecoins by "stablecoinAmountEDecimal"
        (uint256 usdProToRepaymentE18, uint256 usdProToFoundationE18) = _popDeferredStablecoinsE18(
            stablecoinToken,
            stablecoinAmountE18
        );

        SU_LENDING_LIQUIDATION.payFeeAndBurn(msg.sender, usdProToRepaymentE18, usdProToFoundationE18);

        // the contract transfers the stablecoins to the sender
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(stablecoinToken), msg.sender, stablecoinAmountEDecimal);
        SU_MANAGER.liquidate(asset, owner, msg.sender, usdProToRepaymentE18, assetAmountE18);
    }

    // @notice Returns deferred stablecoins for burning and transferring to the foundation
    // @param stablecoinToken The address of the stablecoin token
    // @param amountE18 The total number of stablecoins which will be returned
    // @return toRepaymentE18 The amount of stablecoins which will be burned as a debt repayment
    // @return toFoundationE18 The amount of stablecoins which will be transfered to the foundation
    function _popDeferredStablecoinsE18(
        address stablecoinToken,
        uint256 amountE18
    ) internal returns (uint256 toRepaymentE18, uint256 toFoundationE18) {
        if (amountE18 == 0) revert NotEnoughAmount();

        DeferredStablecoinAmount storage deferredAmount = _deferredStablecoinAmounts[stablecoinToken];
        if (deferredAmount.liquidationBlock == 0) revert NotEnoughDeferredAmount();

        // calculate conservative discount
        uint256 discountE18 = calculateDiscountE18(
            stablecoinToken,
            DiscountType.conservative,
            deferredAmount.liquidationBlock
        );

        (toRepaymentE18, toFoundationE18) = _calculateProportion(deferredAmount, amountE18);

        // decrease an amount of deferred stablecoins
        if (toRepaymentE18 != 0) {
            deferredAmount.toRepaymentE18 -= toRepaymentE18;
        }
        if (toFoundationE18 != 0) {
            deferredAmount.toFoundationE18 -= toFoundationE18;
        }

        if (deferredAmount.toRepaymentE18 == 0 && deferredAmount.toFoundationE18 == 0) {
            delete _deferredStablecoinAmounts[stablecoinToken];
        }

        // apply the conservative discount. it reduces a payment in USDPro which pays the sender
        toRepaymentE18 = toRepaymentE18 * 1e18 / (1e18 + discountE18);
        toFoundationE18 = toFoundationE18 * 1e18 / (1e18 + discountE18);
        console.log("DISCOUNTS (discountE18, suToRepayment, suToFoundation)", discountE18, toRepaymentE18, toFoundationE18);
    }

    function _calculateProportion(
        DeferredStablecoinAmount memory deferredAmount,
        uint256 amountE18
    ) internal pure returns (uint256 toRepaymentE18, uint256 toFoundationE18) {
        // Firstly we try to empty the "toRepaymentE18"
        // TODO: should find out the correct proportion between toRepayment and toFoundation

        if (amountE18 <= deferredAmount.toRepaymentE18) {
            toRepaymentE18 = amountE18;
        } else {
            amountE18 -= deferredAmount.toRepaymentE18;
            if (amountE18 > deferredAmount.toFoundationE18) revert TooMuchAmount();

            toRepaymentE18 = deferredAmount.toRepaymentE18;
            toFoundationE18 = amountE18;
        }
    }
    **/
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library SuLiquidationConstants {
    uint256 internal constant AGGRESSIVE_DISCOUNT_LIMIT_PERCENT_E18 = 5e16;
    uint256 internal constant ONE_HUNDRED_PERCENT_E18 = 1e18;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../access-control/SuAuthenticated.sol";
import "../interfaces/ISuLiquidationDiscount.sol";
import "./SuLiquidationConstants.sol";
import "./SuLiquidationStructs.sol";

contract SuLiquidationDiscount is ISuLiquidationDiscount, SuAuthenticated {
    error IncorrectDiscount();

    // asset => discountType(aggressive, middle, conservative) => discount info:
    //    - percent of discount at the first block
    //    - increment of discount per block in percentages
    mapping(address => mapping(DiscountType => DiscountInfo)) internal _discountsInfo;

    function init(address _authControl) public initializer {
        __SuAuthenticated_init(_authControl);
    }

    // @notice Only owner is able to call this function
    // @dev Sets the liquidation discount
    // @param asset The address of the asset token
    // @param discountType Determines how aggressively the lending module offers a discount
    // @param discountInfo Determines discount percentages depending on a block number
    function setDiscountInfo(
        address asset,
        DiscountType discountType,
        DiscountInfo calldata discountInfo
    ) external onlyOwner {
        // check that discount percentage less than a limit(e.g. 100%)
        _verifyDiscountInfo(discountType, discountInfo);
        _discountsInfo[asset][discountType] = discountInfo;
    }

    // @notice Returns information about discount percentages depending on a block number
    // @param asset The address of the asset token
    // @param discountType Type of discount determines how aggressively the lending module offers a discount
    function getDiscountInfo(
        address asset,
        DiscountType discountType
    ) external view returns (DiscountInfo memory discountInfo) {
        return _discountsInfo[asset][discountType];
    }

    // @dev This is a linear function of the discount change.
    //     Calculates the liquidation discount by passed blocks.
    // @param asset The address of the main collateral token
    // @param discountType Determines how aggressively the lending module offers a discount
    // @param liquidationBlock The block number when the liquidation was triggered
    // @return Amount of discount in percents, E18 format
    function calculateDiscountE18(
        address asset,
        DiscountType discountType,
        uint256 liquidationBlock
    ) public view returns (uint256) {
        DiscountInfo storage discountInfo = _discountsInfo[asset][discountType];

        // number of blocks between the liquidation starts and now
        uint256 blocksPast = block.number - liquidationBlock;

        if (blocksPast == 0) {
            return 0;
        } else if (blocksPast == 1) {
            return discountInfo.firstBlockE18;
        } else {

            if (discountType == DiscountType.aggressive) {
                // the aggressive discount starts the second block with a number equals the stepPerBlockE18
                return _discountFormula(
                    blocksPast,
                    SuLiquidationConstants.AGGRESSIVE_DISCOUNT_LIMIT_PERCENT_E18,
                    discountInfo.stepPerBlockE18,
                    discountInfo.stepPerBlockE18,
                    2
                );
            } else {
                return _discountFormula(
                    blocksPast,
                    SuLiquidationConstants.ONE_HUNDRED_PERCENT_E18,
                    discountInfo.firstBlockE18,
                    discountInfo.stepPerBlockE18,
                    1
                );
            }
        }
    }

    // @notice Returns percentages of discount by passed blocks from liquidation start
    // @param blocksPast The number of blocks passed after the liquidation was triggered
    // @param limitDiscountE18 The upper limit of discount in percentage
    // @param initialDiscountE18 Starting discount
    // @param stepPerBlockE18 Increment of discount per block in percentages
    // @param initialBlockNumber The block number which the increment of discount starts from
    function _discountFormula(
        uint256 blocksPast,
        uint256 limitDiscountE18,
        uint256 initialDiscountE18,
        uint256 stepPerBlockE18,
        uint256 initialBlockNumber
    ) internal pure returns (uint256) {
        uint256 discountE18 = initialDiscountE18 + (blocksPast - initialBlockNumber) * stepPerBlockE18;

        // return the limit discount if the block number went over the limit
        return (discountE18 > limitDiscountE18) ? limitDiscountE18 : discountE18;
    }

    function _verifyDiscountInfo(DiscountType discountType, DiscountInfo calldata discountInfo) internal pure {

        // the aggressive discount has a special upper limit
        uint256 limitDiscountE18;
        if (discountType == DiscountType.aggressive) {
            limitDiscountE18 = SuLiquidationConstants.AGGRESSIVE_DISCOUNT_LIMIT_PERCENT_E18;
        } else {
            limitDiscountE18 = SuLiquidationConstants.ONE_HUNDRED_PERCENT_E18;
        }

        if (discountInfo.firstBlockE18 >= limitDiscountE18 || discountInfo.stepPerBlockE18 >= limitDiscountE18) {
            revert IncorrectDiscount();
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// We have three discount strategies(numbers as an example):
//
// Mode #1 - aggressive: The lending module sells ASAP
// Discount goes from 0.1% first block, 1% second block, goes linear +1% minute
//
// Mode #2 - middle: The lending module sells some asset for whitelisted stablecoin as expensive as possible, no rush
// Discount goes from 0.1% first block, liner increase +0.1% minute
//
// Mode #3 - conservative: The lending module sells stablecoin(USDC) for USDPro as expensive as possible, no rush
// Discount goes from 0.01% first block, goes linear until 5% max in one day or so

enum DiscountType {
    aggressive,
    middle,
    conservative
}

// firstBlockE18 - percent of discount at the first block
// stepPerBlockE18 - percent of discount which will be incremented per block after N>=2 block
struct DiscountInfo {
    uint256 firstBlockE18;
    uint256 stepPerBlockE18;
}

// liquidationBlock - the block number when the liquidation was triggered.
//      It will turn into zero when all deferred stablecoins(toRepaymentE18 and toFoundationE18) be sold.
// toRepaymentE18 - amount of stablecoins which will be burned as debt repayment.
//      Actually, we can not burn it, because it is not a USDPro. So, we deferred that amounts of stablecoins
//      until someone swaps the stablecoins to USDPro(see swapUsdProToStablecoin())
// toFoundationE18 - amount of stablecoins which will be transfered to the foundation.
//      Has the same idea like "toRepaymentE18",
//      but about an excess of stablecoins over debt repayment
struct DeferredStablecoinAmount {
    uint256 liquidationBlock;
    uint256 toRepaymentE18;
    uint256 toFoundationE18;
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}