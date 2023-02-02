// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/UpgradeableBeacon.sol)

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../../access/Ownable.sol";
import "../../utils/Address.sol";

/**
 * @dev This contract is used in conjunction with one or more instances of {BeaconProxy} to determine their
 * implementation contract, which is where they will delegate all function calls.
 *
 * An owner is able to change the implementation the beacon points to, thus upgrading the proxies that use this beacon.
 */
contract UpgradeableBeacon is IBeacon, Ownable {
    address private _implementation;

    /**
     * @dev Emitted when the implementation returned by the beacon is changed.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Sets the address of the initial implementation, and the deployer account as the owner who can upgrade the
     * beacon.
     */
    constructor(address implementation_) {
        _setImplementation(implementation_);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view virtual override returns (address) {
        return _implementation;
    }

    /**
     * @dev Upgrades the beacon to a new implementation.
     *
     * Emits an {Upgraded} event.
     *
     * Requirements:
     *
     * - msg.sender must be the owner of the contract.
     * - `newImplementation` must be a contract.
     */
    function upgradeTo(address newImplementation) public virtual onlyOwner {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Sets the implementation contract address for this beacon
     *
     * Requirements:
     *
     * - `newImplementation` must be a contract.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableBeacon: implementation is not a contract");
        _implementation = newImplementation;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

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
        return !Address.isContract(address(this));
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    event OwnerUpdated(address indexed user, address indexed newOwner);

    event AuthorityUpdated(address indexed user, Authority indexed newAuthority);

    address public owner;

    Authority public authority;

    constructor(address _owner, Authority _authority) {
        owner = _owner;
        authority = _authority;

        emit OwnerUpdated(msg.sender, _owner);
        emit AuthorityUpdated(msg.sender, _authority);
    }

    modifier requiresAuth() virtual {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");

        _;
    }

    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        Authority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return (address(auth) != address(0) && auth.canCall(user, address(this), functionSig)) || user == owner;
    }

    function setAuthority(Authority newAuthority) public virtual {
        // We check if the caller is the owner first because we want to ensure they can
        // always swap out the authority even if it's reverting or using up a lot of gas.
        require(msg.sender == owner || authority.canCall(msg.sender, address(this), msg.sig));

        authority = newAuthority;

        emit AuthorityUpdated(msg.sender, newAuthority);
    }

    function setOwner(address newOwner) public virtual requiresAuth {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {Auth, Authority} from "../Auth.sol";

/// @notice Role based Authority that supports up to 256 roles.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/authorities/RolesAuthority.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-roles/blob/master/src/roles.sol)
contract RolesAuthority is Auth, Authority {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event UserRoleUpdated(address indexed user, uint8 indexed role, bool enabled);

    event PublicCapabilityUpdated(address indexed target, bytes4 indexed functionSig, bool enabled);

    event RoleCapabilityUpdated(uint8 indexed role, address indexed target, bytes4 indexed functionSig, bool enabled);

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner, Authority _authority) Auth(_owner, _authority) {}

    /*//////////////////////////////////////////////////////////////
                            ROLE/USER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => bytes32) public getUserRoles;

    mapping(address => mapping(bytes4 => bool)) public isCapabilityPublic;

    mapping(address => mapping(bytes4 => bytes32)) public getRolesWithCapability;

    function doesUserHaveRole(address user, uint8 role) public view virtual returns (bool) {
        return (uint256(getUserRoles[user]) >> role) & 1 != 0;
    }

    function doesRoleHaveCapability(
        uint8 role,
        address target,
        bytes4 functionSig
    ) public view virtual returns (bool) {
        return (uint256(getRolesWithCapability[target][functionSig]) >> role) & 1 != 0;
    }

    /*//////////////////////////////////////////////////////////////
                           AUTHORIZATION LOGIC
    //////////////////////////////////////////////////////////////*/

    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) public view virtual override returns (bool) {
        return
            isCapabilityPublic[target][functionSig] ||
            bytes32(0) != getUserRoles[user] & getRolesWithCapability[target][functionSig];
    }

    /*//////////////////////////////////////////////////////////////
                   ROLE CAPABILITY CONFIGURATION LOGIC
    //////////////////////////////////////////////////////////////*/

    function setPublicCapability(
        address target,
        bytes4 functionSig,
        bool enabled
    ) public virtual requiresAuth {
        isCapabilityPublic[target][functionSig] = enabled;

        emit PublicCapabilityUpdated(target, functionSig, enabled);
    }

    function setRoleCapability(
        uint8 role,
        address target,
        bytes4 functionSig,
        bool enabled
    ) public virtual requiresAuth {
        if (enabled) {
            getRolesWithCapability[target][functionSig] |= bytes32(1 << role);
        } else {
            getRolesWithCapability[target][functionSig] &= ~bytes32(1 << role);
        }

        emit RoleCapabilityUpdated(role, target, functionSig, enabled);
    }

    /*//////////////////////////////////////////////////////////////
                       USER ROLE ASSIGNMENT LOGIC
    //////////////////////////////////////////////////////////////*/

    function setUserRole(
        address user,
        uint8 role,
        bool enabled
    ) public virtual requiresAuth {
        if (enabled) {
            getUserRoles[user] |= bytes32(1 << role);
        } else {
            getUserRoles[user] &= ~bytes32(1 << role);
        }

        emit UserRoleUpdated(user, role, enabled);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';


/**
 * @notice Main storage structs
 */
struct AppStorage { 
    //Contracts
    address tricrypto;
    address crvTricrypto; 
    address mimPool;
    address crv2Pool;
    address yTriPool;
    address fraxPool;
    address executor;

    //ERC20s
    address USDT;
    address WBTC;
    address USDC;
    address MIM;
    address WETH;
    address FRAX;
    address ETH;

    //Token infrastructure
    address oz20;
    OZLERC20 oz;

    //System config
    uint protocolFee;
    uint defaultSlippage;
    mapping(address => bool) tokenDatabase;
    mapping(address => address) tokenL1ToTokenL2;

    //Internal accounting vars
    uint totalVolume;
    uint ozelIndex;
    uint feesVault;
    uint failedFees;
    mapping(address => uint) usersPayments;
    mapping(address => uint) accountPayments;
    mapping(address => address) accountToUser;
    mapping(address => bool) isAuthorized;

    //Curve swaps config
    TradeOps mimSwap;
    TradeOps usdcSwap;
    TradeOps fraxSwap;
    TradeOps[] swaps;

    //Mutex locks
    mapping(uint => uint) bitLocks;

    //Stabilizing mechanism (for ozelIndex)
    uint invariant;
    uint invariant2;
    uint indexRegulator;
    uint invariantRegulator;
    bool indexFlag;
    uint stabilizer;
    uint invariantRegulatorLimit;
    uint regulatorCounter;

    //Revenue vars
    ISwapRouter swapRouter;
    AggregatorV3Interface priceFeed;
    address revenueToken;
    uint24 poolFee;
    uint[] revenueAmounts;

    //Misc vars
    bool isEnabled;
    bool l1Check;
    bytes checkForRevenueSelec;
    address nullAddress;

}

/// @dev Reference for oz20Facet storage
struct OZLERC20 {
    mapping(address => mapping(address => uint256)) allowances;
    string  name;
    string  symbol;
}

/// @dev Reference for swaps and the addition/removal of account tokens
struct TradeOps {
    int128 tokenIn;
    int128 tokenOut;
    address baseToken;
    address token;  
    address pool;
}

/// @dev Reference for the details of each account
struct AccountConfig { 
    address user;
    address token;
    uint16 slippage; 
    string name;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14; 


/// @dev Thrown when comparisson has a zero value
/// @param nonZeroValue Type of the zero value
error CantBeZero(string nonZeroValue);

/// @dev When a low-level call fails
/// @param errorMsg Custom error message
error CallFailed(string errorMsg); 

/// @dev Thrown when the queried token is not in the database
/// @param token Address of queried token
error TokenNotInDatabase(address token);

/// @dev For when the queried token is in the database
/// @param token Address of queried token
error TokenAlreadyInDatabase(address token);

/// @dev Thrown when an user is not in the database
/// @param user Address of the queried user
error UserNotInDatabase(address user);

/// @dev Thrown when the call is done by a non-account/proxy
error NotAccount();

/// @dev Thrown when a custom condition is not fulfilled
/// @param errorMsg Custom error message
error ConditionNotMet(string errorMsg);

/// @dev Thrown when an unahoritzed user makes the call
/// @param unauthorizedUser Address of the msg.sender
error NotAuthorized(address unauthorizedUser);

/// @dev When reentrance occurs
error NoReentrance();

/// @dev When a particular action hasn't been enabled yet
error NotEnabled();

/// @dev Thrown when the account name is too long
error NameTooLong();

/// @dev Thrown when the queried Gelato task is invalid
/// @param taskId Gelato task
error InvalidTask(bytes32 taskId);

/// @dev Thrown if an attempt to add a L1 token is done after it's been disabled
/// @param l1Token L1 token address
error L1TokenDisabled(address l1Token);

/// @dev Thrown when a Gelato's task ID doesn't exist
error NoTaskId();

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14; 


import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import './StorageBeacon.sol';
import '../Errors.sol';


/**
 * @title Forwarding contract for manual redeems.
 * @notice Forwards the address of the account that received a transfer, for a check-up
 * of the tx in case it needs a manual redeem
 */
contract Emitter is Initializable, Ownable {
    address private _beacon;

    event ShowTicket(address indexed proxy, address indexed owner);

    /// @dev Stores the beacon (ozUpgradableBeacon)
    function storeBeacon(address beacon_) external initializer {
        _beacon = beacon_;
    }

    /// @dev Gets the first version of the Storage Beacon
    function _getStorageBeacon() private view returns(StorageBeacon) {
        return StorageBeacon(ozUpgradeableBeacon(_beacon).storageBeacon(0));
    }
    
    /**
     * @dev Forwards the account/proxy to the offchain script that checks for 
     * manual redeems.
     */
    function forwardEvent(address user_) external { 
        bytes20 account = bytes20(msg.sender);
        bytes12 userFirst12 = bytes12(bytes20(user_));
        bytes32 acc_user = bytes32(bytes.concat(account, userFirst12));

        if (!_getStorageBeacon().verify(user_, acc_user)) revert NotAccount();
        emit ShowTicket(msg.sender, user_);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14; 


import '@rari-capital/solmate/src/auth/authorities/RolesAuthority.sol';
import '@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol';
import '../interfaces/ethereum/ozIUpgradeableBeacon.sol';


/**
 * @title Middleware beacon proxy
 * @notice Holds the current version of the beacon and possible multiple versions
 * of the Storage beacon. It also hosts the control access methods for some actions
 */
contract ozUpgradeableBeacon is ozIUpgradeableBeacon, UpgradeableBeacon { 
    /// @dev Holds all the versions of the Storage Beacon
    address[] private _storageBeacons;

    RolesAuthority auth;

    event UpgradedStorageBeacon(address newStorageBeacon);
    event NewAuthority(address newAuthority);


    constructor(address impl_, address storageBeacon_) UpgradeableBeacon(impl_) {
        _storageBeacons.push(storageBeacon_);
    }


    /*///////////////////////////////////////////////////////////////
                        Storage Beacon methods
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ozIUpgradeableBeacon
    function storageBeacon(uint version_) external view returns(address) {
        return _storageBeacons[version_];
    }

    /// @inheritdoc ozIUpgradeableBeacon
    function upgradeStorageBeacon(address newStorageBeacon_) external onlyOwner {
        _storageBeacons.push(newStorageBeacon_);
        emit UpgradedStorageBeacon(newStorageBeacon_);
    }

    /*///////////////////////////////////////////////////////////////
                              Access Control
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ozIUpgradeableBeacon
    function setAuth(address auth_) external onlyOwner {
        auth = RolesAuthority(auth_);
        emit NewAuthority(auth_);
    }

    /// @inheritdoc ozIUpgradeableBeacon
    function canCall( 
        address user_,
        address target_,
        bytes4 functionSig_
    ) external view returns(bool) {
        bool isAuth = auth.canCall(user_, target_, functionSig_);
        return isAuth;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14;


import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '../interfaces/ethereum/IStorageBeacon.sol';
import '../libraries/LibCommon.sol';
import './ozUpgradeableBeacon.sol';
import '../Errors.sol';


/**
 * @title Main storage contract for the L1 side of the system.
 * @notice It acts as a separate centralized beacon that functions query for state
 * variables. It can be upgraded into different versions while keeping the older ones.
 */
contract StorageBeacon is IStorageBeacon, Initializable, Ownable {

    EmergencyMode eMode;

    mapping(address => bool) tokenDatabase;
    mapping(address => AccData) userToData;
    mapping(bytes4 => bool) authorizedSelectors;

    address[] tokenDatabaseArray;

    uint gasPriceBid;

    ozUpgradeableBeacon beacon;

    bool isEmitter;

    event L2GasPriceChanged(uint newGasPriceBid);
    event NewToken(address token);
    event TokenRemoved(address token);

    /// @dev Checks -using RolesAuthority- if the sender can call certain method
    modifier hasRole(bytes4 functionSig_) {
        require(beacon.canCall(msg.sender, address(this), functionSig_));
        _;
    }


    constructor(
        EmergencyMode memory eMode_,
        address[] memory tokens_,
        bytes4[] memory selectors_,
        uint gasPriceBid_
    ) {
        eMode = EmergencyMode({
            swapRouter: ISwapRouter(eMode_.swapRouter),
            priceFeed: AggregatorV3Interface(eMode_.priceFeed),
            poolFee: eMode_.poolFee,
            tokenIn: eMode_.tokenIn,
            tokenOut: eMode_.tokenOut
        });

        uint length = tokens_.length;
        for (uint i=0; i < length;) {
            tokenDatabase[tokens_[i]] = true;
            tokenDatabaseArray.push(tokens_[i]);
            unchecked { ++i; }
        }

        for (uint i=0; i < selectors_.length;) {
            authorizedSelectors[selectors_[i]] = true;
            unchecked { ++i; }
        }

        gasPriceBid = gasPriceBid_;
    }


    /*///////////////////////////////////////////////////////////////
                        State-changing functions
    //////////////////////////////////////////////////////////////*/

    //@inheritdoc IStorageBeacon
    function multiSave(
        bytes20 account_,
        AccountConfig calldata acc_,
        bytes32 taskId_
    ) external hasRole(0x0854b85f) { 
        address user = acc_.user;
        bytes32 acc_user = bytes32(bytes.concat(account_, bytes12(bytes20(user))));
        bytes memory task_name = bytes.concat(taskId_, bytes32(bytes(acc_.name)));

        if (userToData[user].accounts.length == 0) {
            AccData storage data = userToData[user];
            data.accounts.push(address(account_));
            data.acc_userToTask_name[acc_user] = task_name;
        } else {
            userToData[user].accounts.push(address(account_));
            userToData[user].acc_userToTask_name[acc_user] = task_name;
        }
    }

    //@inheritdoc IStorageBeacon
    function changeGasPriceBid(uint newGasPriceBid_) external onlyOwner {
        gasPriceBid = newGasPriceBid_;
        emit L2GasPriceChanged(newGasPriceBid_);
    }

    //@inheritdoc IStorageBeacon
    function addTokenToDatabase(address newToken_) external onlyOwner {
        if (queryTokenDatabase(newToken_)) revert TokenAlreadyInDatabase(newToken_);
        tokenDatabase[newToken_] = true;
        tokenDatabaseArray.push(newToken_);
        emit NewToken(newToken_);
    }

    //@inheritdoc IStorageBeacon
    function removeTokenFromDatabase(address toRemove_) external onlyOwner {
        if (!queryTokenDatabase(toRemove_)) revert TokenNotInDatabase(toRemove_);
        tokenDatabase[toRemove_] = false;
        LibCommon.remove(tokenDatabaseArray, toRemove_);
        emit TokenRemoved(toRemove_);
    }

    //@inheritdoc IStorageBeacon
    function storeBeacon(address beacon_) external initializer { 
        beacon = ozUpgradeableBeacon(beacon_);
    }

    //@inheritdoc IStorageBeacon
    function changeEmergencyMode(EmergencyMode calldata newEmode_) external onlyOwner {
        eMode = newEmode_;
    }

    //@inheritdoc IStorageBeacon
    function changeEmitterStatus(bool newStatus_) external onlyOwner {
        isEmitter = newStatus_;
    }

    //@inheritdoc IStorageBeacon
    function addAuthorizedSelector(bytes4 selector_) external onlyOwner {
        authorizedSelectors[selector_] = true;
    }


    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    //@inheritdoc IStorageBeacon
    function isSelectorAuthorized(bytes4 selector_) external view returns(bool) {
        return authorizedSelectors[selector_];
    }

    //@inheritdoc IStorageBeacon
    function getGasPriceBid() external view returns(uint) {
        return gasPriceBid; 
    }
    
    //@inheritdoc IStorageBeacon
    function getEmergencyMode() external view returns(EmergencyMode memory) {
        return eMode;
    }

    //@inheritdoc IStorageBeacon
    function getAccountsByUser(
        address user_
    ) external view returns(address[] memory, string[] memory) {
        AccData storage data = userToData[user_];
        address[] memory accounts = data.accounts;
        string[] memory names = new string[](accounts.length);

        for (uint i=0; i < accounts.length; i++) {
            bytes memory task_name = 
                _getTask_Name(accounts[i], user_, data.acc_userToTask_name);
            bytes32 nameBytes;

            assembly {
                nameBytes := mload(add(task_name, 64))
            }
            names[i] = string(bytes.concat(nameBytes));
        }

        return (accounts, names);
    }

    /**
     * @dev Gets the bytes array compounded of the Account's name and its Gelato's task id
     */
    function _getTask_Name(
        address account_, 
        address owner_,
        mapping(bytes32 => bytes) storage acc_userToTask_name_
    ) private view returns(bytes memory) {
        bytes32 acc_user = bytes32(bytes.concat(bytes20(account_), bytes12(bytes20(owner_))));
        bytes memory task_name = acc_userToTask_name_[acc_user];
        return task_name;
    }

    //@inheritdoc IStorageBeacon
    function getTaskID(address account_, address owner_) external view returns(bytes32) {
        AccData storage data = userToData[owner_];
        if (data.accounts.length == 0) revert UserNotInDatabase(owner_);

        bytes memory task_name = _getTask_Name(account_, owner_, data.acc_userToTask_name);
        bytes32 taskId;
        assembly {
            taskId := mload(add(task_name, 32))
        }

        if (taskId == bytes32(0)) revert NoTaskId();
        return taskId;
    }

    /// @dev If token_ exists in L1 database
    function queryTokenDatabase(address token_) public view returns(bool) {
        return tokenDatabase[token_];
    }
    
    //@inheritdoc IStorageBeacon
    function isUser(address user_) external view returns(bool) {
        return userToData[user_].accounts.length > 0;
    }

    //@inheritdoc IStorageBeacon
    function getEmitterStatus() external view returns(bool) {
        return isEmitter;
    }

    //@inheritdoc IStorageBeacon
    function getTokenDatabase() external view returns(address[] memory) {
        return tokenDatabaseArray;
    }

    //@inheritdoc IStorageBeacon
    function verify(address user_, bytes32 acc_user_) external view returns(bool) {
        AccData storage data = userToData[user_];
        bytes memory task_name = data.acc_userToTask_name[acc_user_];
        return bytes32(task_name) != bytes32(0);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14;


import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';


interface IStorageBeacon {

    struct AccountConfig {
        address user;
        address token;
        uint slippage; 
        string name;
    }

    struct EmergencyMode {
        ISwapRouter swapRouter;
        AggregatorV3Interface priceFeed; 
        uint24 poolFee;
        address tokenIn;
        address tokenOut; 
    }

    struct AccData {
        address[] accounts;
        mapping(bytes32 => bytes) acc_userToTask_name;
    }

    /**
     * @dev Saves and connects the address of the account to its details.
     * @param account_ The account/proxy
     * @param acc_ Details of the account/proxy
     * @param taskId_ Gelato's task id
     */
    function multiSave(
        bytes20 account_,
        AccountConfig calldata acc_,
        bytes32 taskId_
    ) external;

    /**
     * @dev Changes the hard-coded L2 gas price
     * @param newGasPriceBid_ New gas price expressed in gwei
     */
    function changeGasPriceBid(uint newGasPriceBid_) external;

    /// @dev Adds a new token to L1 database
    function addTokenToDatabase(address newToken_) external;

    /// @dev Removes a token from L1 database
    function removeTokenFromDatabase(address toRemove_) external;

    /// @dev Stores the beacon (ozUpgradableBeacon)
    function storeBeacon(address beacon_) external;

    /**
     * @dev Changes all the params on the Emergency Mode struct
     * @param newEmode_ New eMode struct
     */
    function changeEmergencyMode(EmergencyMode calldata newEmode_) external;

    /**
     * @dev Disables/Enables the forwarding to Emitter on ozPayMe 
     * @param newStatus_ New boolean for the forwading to the Emitter
     */
    function changeEmitterStatus(bool newStatus_) external;

    /**
     * @dev Authorizes a new function so it can get called with its original 
     * calldata -on ozAccountProxy (each user's account/proxy)- to the implementation (ozPayMe)
     * instead of just forwarding the account details for briding to L2. 
     * @param selector_ Selector of new authorized function
     */
    function addAuthorizedSelector(bytes4 selector_) external;

    /**
     * @notice View method related to the one above
     * @dev Queries if a function's payload will get to the implementation or if it'll be 
     * substituted by the bridging payload on ozAccountProxy. If it's authorized, it'll keep
     * the original calldata.
     * @param selector_ Selector of the authorized function in the implementation
     * @return bool If the target function is authorized to keep its calldata
     */
    function isSelectorAuthorized(bytes4 selector_) external view returns(bool);

    /// @dev Gets the L2 gas price
    function getGasPriceBid() external view returns(uint);

    /// @dev Gets the Emergency Mode struct
    function getEmergencyMode() external view returns(EmergencyMode memory);

    /**
     * @notice Gets the accounts/proxies created by an user
     * @dev Gets the addresses and names of the accounts
     * @param user_ Address of the user
     * @return address[] Addresses of the accounts
     * @return string[] Names of the accounts
     */
    function getAccountsByUser(
        address user_
    ) external view returns(address[] memory, string[] memory);

    /**
     * @dev Gets the Gelato task of an account/proxy
     * @param account_ Account
     * @param owner_ Owner of the task
     * @return bytes32 Gelato Task ID
     */
    function getTaskID(address account_, address owner_) external view returns(bytes32);

    /// @dev Gets the owner of an account
    // function getUserByAccount(address account_) external view returns(address);

    /// @dev If user_ has previously created an account/proxy
    function isUser(address user_) external view returns(bool);

    /// @dev Queries if the forwarding to the Emitter is enabled
    function getEmitterStatus() external view returns(bool);

    /// @dev Gets all the tokens in the database
    function getTokenDatabase() external view returns(address[] memory);

    /**
     * @dev Verifies that an Account was created in Ozel
     * @param user_ Owner of the Account to query
     * @param acc_user_ Bytes20 made of the 20 bytes of the Account and 12 of the owner
     * @return bool If the Account was created in Ozel
     */
     function verify(address user_, bytes32 acc_user_) external view returns(bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14;



interface ozIUpgradeableBeacon {

    /**
     * @dev Returns the queried version of the Storage Beacon
     */
    function storageBeacon(uint version_) external view returns(address);

    /**
     * @dev Stores a new version of the Storage Beacon
     */
    function upgradeStorageBeacon(address newStorageBeacon_) external;

    /**
     * @dev Designates a new authority for access control on certain methods
     * @param auth_ New RolesAuthority contract 
     */
    function setAuth(address auth_) external;

    /**
     * @notice Authorizing function
     * @dev To be queried in order to know if an user can call a certain function
     * @param user_ Entity to be queried in regards to authorization
     * @param target_ Contract where the function to be called is
     * @param functionSig_ Selector of function to be called
     * @return bool If user_ is authorized 
     */
    function canCall( 
        address user_,
        address target_,
        bytes4 functionSig_
    ) external view returns(bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14;


import { TradeOps } from '../arbitrum/AppStorage.sol';


/**
 * @notice Library of common methods using in both L1 and L2 contracts
 */
library LibCommon {

    /**
     * @notice L1 removal method
     * @dev Removes a token from the token database
     * @param tokensDB_ Array of addresses where the removal will occur
     * @param toRemove_ Token to remove
     */
    function remove(address[] storage tokensDB_, address toRemove_) internal {
        uint index;
        for (uint i=0; i < tokensDB_.length;) {
            if (tokensDB_[i] == toRemove_)  {
                index = i;
                break;
            }
            unchecked { ++i; }
        }
        for (uint i=index; i < tokensDB_.length - 1;){
            tokensDB_[i] = tokensDB_[i+1];
            unchecked { ++i; }
        }
        delete tokensDB_[tokensDB_.length-1];
        tokensDB_.pop();
    }

    /**
     * @notice Overloaded L2 removal method
     * @dev Removes a token and its swap config from the token database
     * @param swaps_ Array of structs where the removal will occur
     * @param swapToRemove_ Config struct to be removed
     */
    function remove(
        TradeOps[] storage swaps_, 
        TradeOps memory swapToRemove_
    ) internal {
        uint index;
        for (uint i=0; i < swaps_.length;) {
            if (swaps_[i].token == swapToRemove_.token)  {
                index = i;
                break;
            }
            unchecked { ++i; }
        }
        for (uint i=index; i < swaps_.length - 1;){
            swaps_[i] = swaps_[i+1];
            unchecked { ++i; }
        }
        delete swaps_[swaps_.length-1];
        swaps_.pop();
    }

    /**
     * @dev Extracts the details of an Account
     * @param data_ Bytes array containing the details
     * @return user Owner of the Account
     * @return token Token of the Account
     * @return slippage Slippage of the Account
     */
    function extract(bytes memory data_) internal pure returns(
        address user, 
        address token, 
        uint16 slippage
    ) {
        assembly {
            user := shr(96, mload(add(data_, 32)))
            token := shr(96, mload(add(data_, 52)))
            slippage := and(0xff, mload(add(mload(data_), data_)))
        }
    }
}