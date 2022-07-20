// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./libraries/Errors.sol";

/*
This contract is used for distributing staking rewards for staking to various nodes.
At each rewards distribution for given node, they are distributed proportionate to "stake powers".

Stake power for a given stake is a value calculated following way:
1. At first distribution (after staking) it is share of stake amount equal to share of time passed between stake 
and this distribution to time passed between previous distribution and this distribution. This is named partial power.
2. At subsequent distributions stake power is equal to staked amount. This is named full power.

Therefore, reward calculations are split into 2 parts: for full stakes and for partial stakes.

Calculations for full stakes is node through increasing node's "rewardPerPower" value 
(that equals to total accrued reward per 1 unit of power, then magnified by MAGNITUDE to calculate small values correct)
Therefore for a stake reward for periods where it was full is it's amount multiplied by difference of
node's current rewardPerPower and value of rewardPerPower at distribution where stake happened (first distribution)

To calculate partial stake reward (happenes only 1 for each stake) other mechanism is used.
At first distribution share of reward for given stake among all rewards for partial stakes in that distribution
is equal to share of product of stake amount and time passed between stake and distribution to sum of such products
for all partial stakes. These products are named "powerXTime" in the codebase;
For correct calculation of sum of powerXTimes we calculate it as difference of maxTotalPowerXTime 
(sum of powerXTimes if all partial stakes were immediately after previous distribution) and sum of powerXTime deltas
(differences between maximal possible powerXTime and real powerXTime for each stake).
Such way allows to calculate all values using O(1) of operations in one transaction
*/

contract Staking is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice Magnitude by which values are multiplied in reward calculations
    uint256 private constant MAGNITUDE = 2**128;

    /// @notice Denominator used for decimal calculations
    uint256 public constant DENOMINATOR = 10**18;

    /// @notice One year duration, used for APR calculations
    uint256 public constant YEAR = 365 days;

    /// @notice Token user in staking
    IERC20Upgradeable public token;

    /// @notice Structure describing one staking node
    struct NodeInfo {
        address validator;
        uint256 rewardPerPower;
        uint256 lastDistributionId;
        uint256 totalStaked;
        uint256 fee;
        uint256 collectedFee;
    }

    /// @notice Mapping of node ID's to their info
    mapping(uint256 => NodeInfo) public nodeInfo;

    /// @notice Last node ID
    uint256 public lastNodeId;

    /// @notice Structure describing one reward distribution for node
    struct DistributionInfo {
        uint256 timestamp;
        uint256 reward;
        uint256 powerXTimeDelta;
        uint256 stakedIn;
        uint256 rewardPerPower;
        uint256 rewardForPartialPower;
    }

    /// @notice Mapping of node ID's to mappings of distribution ID's to their information
    mapping(uint256 => mapping(uint256 => DistributionInfo))
        public distributions;

    /// @notice Structure describing stake information
    struct StakeInfo {
        address owner;
        uint256 nodeId;
        uint256 amount;
        uint256 timestamp;
        uint256 firstDistributionId;
        uint256 withdrawnReward;
    }

    /// @notice Mapping of stake ID's to their information
    mapping(uint256 => StakeInfo) public stakeInfo;

    /// @notice Last stake ID
    uint256 public lastStakeId;

    // EVENTS

    /// @notice Event emitted when new staking node is created
    event NodeCreated(uint256 indexed nodeId, address indexed validator);

    /// @notice Event emitted when new stake is created
    event Staked(
        uint256 indexed stakeId,
        address indexed staker,
        uint256 indexed nodeId,
        uint256 amount
    );

    /// @notice Event emitted when reward is wihdrawn for some stake
    event RewardWithdrawn(uint256 indexed stakeId, uint256 reward);

    /// @notice Event emitted when some stake is withdrawn
    event Unstaked(
        uint256 indexed stakeId,
        address indexed staker,
        uint256 indexed nodeId,
        uint256 amount
    );

    /// @notice Event emitted when reward is distributed for some node
    event RewardDistributed(
        uint256 indexed nodeId,
        uint256 reward,
        uint256 fee
    );

    /// @notice Event emitted when fee is withdrawn for some node
    event FeeWithdrawn(uint256 indexed nodeId, address collector, uint256 fee);

    // INITIALIZER

    /// @notice Contract's initializer
    /// @param token_ Contract of token used in staking
    function initialize(IERC20Upgradeable token_) external initializer {
        __Ownable_init();

        token = token_;
    }

    // RESTRICTED FUNCTIONS

    /// @notice Owner's function that is used to create new node
    /// @param validator Address of the node's validator
    /// @param fee NUmberator of the fee value
    /// @return nodeId ID of new node
    function createNode(address validator, uint256 fee)
        external
        onlyOwner
        returns (uint256 nodeId)
    {
        require(validator != address(0), Errors.ZERO_VALIDATOR);

        nodeId = ++lastNodeId;
        nodeInfo[nodeId].validator = validator;
        nodeInfo[nodeId].fee = fee;
        distributions[nodeId][0].timestamp = block.timestamp;

        emit NodeCreated(nodeId, validator);
    }

    /// @notice Owner's function that is used to distribute rewards to a set of nodes
    /// @param nodeIds List of node ID's
    /// @param rewards List of respective rewards to those nodes
    /// @dev Function transfers distributed reward to contract, approval is required in prior
    function distributeReward(
        uint256[] memory nodeIds,
        uint256[] memory rewards
    ) external onlyOwner {
        require(nodeIds.length == rewards.length, Errors.LENGHTS_MISMATCH);

        uint256 totalReward;
        for (uint256 i = 0; i < rewards.length; i++) {
            totalReward += rewards[i];

            uint256 feeAmount = (rewards[i] * nodeInfo[nodeIds[i]].fee) /
                DENOMINATOR;
            nodeInfo[nodeIds[i]].collectedFee += feeAmount;

            _distributeReward(nodeIds[i], rewards[i] - feeAmount);

            emit RewardDistributed(
                nodeIds[i],
                rewards[i] - feeAmount,
                feeAmount
            );
        }

        token.safeTransferFrom(msg.sender, address(this), totalReward);
    }

    // PUBLIC FUNCTIONS

    /// @notice Creates new stake
    /// @param nodeId ID of the node to stake for
    /// @param amount Amount to stake
    /// @dev Transfers `amount` of `token` to the contract, approval is required in prior
    /// @return stakeId ID of the created stake
    function stakeFor(uint256 nodeId, uint256 amount)
        external
        returns (uint256 stakeId)
    {
        require(nodeInfo[nodeId].validator != address(0), Errors.INVALID_NODE);

        token.safeTransferFrom(msg.sender, address(this), amount);

        // This stake's first distribution will be next distribution
        uint256 distributionId = nodeInfo[nodeId].lastDistributionId + 1;

        stakeId = ++lastStakeId;
        stakeInfo[stakeId] = StakeInfo({
            owner: msg.sender,
            nodeId: nodeId,
            amount: amount,
            timestamp: block.timestamp,
            firstDistributionId: distributionId,
            withdrawnReward: 0
        });

        nodeInfo[nodeId].totalStaked += amount;

        // Amount staked in current distribution is stored to calculate total reward for partial power in future
        distributions[nodeId][distributionId].stakedIn += amount;

        // Sum of powerXTimeDeltas is increased
        distributions[nodeId][distributionId].powerXTimeDelta +=
            amount *
            (block.timestamp -
                distributions[nodeId][distributionId - 1].timestamp);

        emit Staked(stakeId, msg.sender, nodeId, amount);
    }

    /// @notice Withdraws accumulated reward for given stake
    /// @param stakeId ID of the stake to collect reward for
    function withdrawReward(uint256 stakeId) public {
        require(stakeInfo[stakeId].owner == msg.sender, Errors.NOT_STAKE_OWNER);

        uint256 reward = rewardOf(stakeId);
        stakeInfo[stakeId].withdrawnReward += reward;
        token.safeTransfer(msg.sender, reward);

        emit RewardWithdrawn(stakeId, reward);
    }

    /// @notice Unstakes given stake (and collects reward in process)
    /// @param stakeId ID of the stake to withdraw
    function unstake(uint256 stakeId) external {
        withdrawReward(stakeId);

        uint256 nodeId = stakeInfo[stakeId].nodeId;
        uint256 amount = stakeInfo[stakeId].amount;
        nodeInfo[nodeId].totalStaked -= amount;
        delete stakeInfo[stakeId];

        emit Unstaked(stakeId, msg.sender, nodeId, amount);
    }

    /// @notice Collects fee for a given node (can only be called by validator)
    /// @param nodeId ID of the node to collect fee for
    function withdrawFee(uint256 nodeId) external {
        require(
            msg.sender == nodeInfo[nodeId].validator,
            Errors.NOT_NODE_VALIDATOR
        );

        uint256 fee = nodeInfo[nodeId].collectedFee;
        if (fee > 0) {
            nodeInfo[nodeId].collectedFee = 0;

            token.safeTransfer(msg.sender, fee);

            emit FeeWithdrawn(nodeId, msg.sender, fee);
        }
    }

    // PUBLIC VIEW FUNCTIONS

    /// @notice Returns current reward of given stake
    /// @param stakeId ID of the stake to get reward for
    /// @return Current reward
    function rewardOf(uint256 stakeId) public view returns (uint256) {
        return
            _accumulatedRewardOf(stakeId) - stakeInfo[stakeId].withdrawnReward;
    }

    /// @notice Estimated reward APR for given node
    /// @param nodeId ID of the node
    /// @return _ Estimated APR (as 18-digit decimal)
    function getEstimatedAPR(uint256 nodeId) external view returns (uint256) {
        NodeInfo memory node = nodeInfo[nodeId];

        // If there were no distributions, there is not way to estimare APR
        if (node.lastDistributionId == 0) {
            return 0;
        }

        // Extrapolate reward rate in last period to estimate yearly reward
        DistributionInfo memory distribution = distributions[nodeId][
            node.lastDistributionId
        ];
        uint256 lastDistributionTs = distributions[nodeId][
            node.lastDistributionId - 1
        ].timestamp;
        uint256 estimatedYearlyReward = (distribution.reward * YEAR) /
            (distribution.timestamp - lastDistributionTs);

        // Based on yearly reward, calculate estimated APR
        return (DENOMINATOR * estimatedYearlyReward) / node.totalStaked;
    }

    // PRIVATE FUNCTIONS

    /// @notice Internal function that processes reward distribution for one node
    /// @param nodeId ID of the node
    /// @param reward Distributed reward
    function _distributeReward(uint256 nodeId, uint256 reward) private {
        require(nodeInfo[nodeId].validator != address(0), Errors.INVALID_NODE);

        uint256 distributionId = ++nodeInfo[nodeId].lastDistributionId;
        DistributionInfo storage distribution = distributions[nodeId][
            distributionId
        ];

        // Total full power is simply sum of all stakes before this distribution
        uint256 fullPower = nodeInfo[nodeId].totalStaked -
            distribution.stakedIn;

        // Maximal possible (not actual) sum of powerXTimes in this distribution
        uint256 maxTotalPowerXTime = distribution.stakedIn *
            (block.timestamp -
                distributions[nodeId][distributionId - 1].timestamp);

        // Total partial power is share of staked amount equal to share of real totalPowerXTime to maximal
        uint256 partialPower = (distribution.stakedIn *
            (maxTotalPowerXTime - distribution.powerXTimeDelta)) /
            maxTotalPowerXTime;

        // Reward for full powers is calculated proporionate to total full and partial powers
        uint256 rewardForFullPower = (reward * fullPower) /
            (fullPower + partialPower);

        // If full powers actually exist in this distribution we calculate (magnified) rewardPerPower delta
        uint256 rewardPerPowerDelta;
        if (fullPower > 0) {
            rewardPerPowerDelta = (MAGNITUDE * rewardForFullPower) / fullPower;
        }

        nodeInfo[nodeId].rewardPerPower += rewardPerPowerDelta;
        distribution.timestamp = block.timestamp;
        distribution.reward = reward;
        distribution.rewardPerPower = nodeInfo[nodeId].rewardPerPower;
        // We store only total reward for partial powers
        distribution.rewardForPartialPower = reward - rewardForFullPower;
    }

    // PRIVATE VIEW FUNCTION

    /// @notice Internal function that calculates total accumulated reward for stake (without withdrawals)
    /// @param stakeId ID of the stake
    /// @return Total reward
    function _accumulatedRewardOf(uint256 stakeId)
        private
        view
        returns (uint256)
    {
        StakeInfo memory stake = stakeInfo[stakeId];
        DistributionInfo memory firstDistribution = distributions[stake.nodeId][
            stake.firstDistributionId
        ];

        // Reward for periods when stake was full, calculated straightforward
        uint256 fullReward = (stakeInfo[stakeId].amount *
            (nodeInfo[stake.nodeId].rewardPerPower -
                firstDistribution.rewardPerPower)) / MAGNITUDE;

        // Timestamp of previous distribution
        uint256 previousTimestamp = distributions[stake.nodeId][
            stake.firstDistributionId - 1
        ].timestamp;

        //  Maximal possible (not actual) sum of powerXTimes in first distribution for stake
        uint256 maxTotalPowerXTime = firstDistribution.stakedIn *
            (firstDistribution.timestamp - previousTimestamp);

        // Real sum of powerXTimes in first distribution for stake
        uint256 realTotalPowerXTime = maxTotalPowerXTime -
            firstDistribution.powerXTimeDelta;

        // PowerXTime of this stake in first distribution
        uint256 stakePowerXTime = stake.amount *
            (firstDistribution.timestamp - stake.timestamp);

        // Reward when stake was partial as propotionate share of total reward for partial stakes in distribution
        uint256 partialReward = (firstDistribution.rewardForPartialPower *
            stakePowerXTime) / realTotalPowerXTime;

        return fullReward + partialReward;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

library Errors {
    string internal constant ZERO_VALIDATOR = "ZV";

    string internal constant LENGHTS_MISMATCH = "LM";

    string internal constant INVALID_NODE = "IN";

    string internal constant NOT_STAKE_OWNER = "NSO";

    string internal constant NOT_NODE_VALIDATOR = "NND";
}