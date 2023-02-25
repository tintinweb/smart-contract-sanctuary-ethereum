// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
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
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
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
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "contracts/revenue-share-contracts/RSCValve.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract XLARSCValveFactory is Ownable {
    address payable public immutable contractImplementation;
    uint256 constant version = 1;
    uint256 public platformFee;
    address payable public platformWallet;

    // creationId unique ID for each contract creation TX, it prevents users to submit tx twice
    mapping(bytes32 => bool) public processedCreationIds;

    struct RSCCreateData {
        address controller;
        address[] distributors;
        bool immutableController;
        bool autoNativeTokenDistribution;
        uint256 minAutoDistributeAmount;
        address payable [] initialRecipients;
        uint256[] percentages;
        bytes32 creationId;
    }

    event RSCValveCreated(
        address contractAddress,
        address controller,
        address[] distributor,
        uint256 version,
        bool immutableController,
        bool autoNativeTokenDistribution,
        uint256 minAutoDistributeAmount,
        bytes32 creationId
    );

    event PlatformFeeChanged(
        uint256 oldFee,
        uint256 newFee
    );

    event PlatformWalletChanged(
        address payable oldPlatformWallet,
        address payable newPlatformWallet
    );

    // Throw when Fee Percentage is more than 100%
    error InvalidFeePercentage();

    // Throw when creationId was already created
    error CreationIdAlreadyProcessed();


    constructor() {
        contractImplementation = payable(new XLARSCValve());
    }

    /**
     * @dev Public function for creating clone proxy pointing to RSC Percentage
     * @param _data Initial data for creating new RSC Valve contract
     */
    function createRSCValve(RSCCreateData memory _data) external returns(address) {

        // check and register creationId
        bytes32 creationId = _data.creationId;
        if (creationId != bytes32(0)) {
            bool processed = processedCreationIds[creationId];
            if (processed) {
                revert CreationIdAlreadyProcessed();
            } else {
                processedCreationIds[creationId] = true;
            }
        }

        address payable clone = payable(Clones.clone(contractImplementation));

        XLARSCValve(clone).initialize(
            msg.sender,
            _data.controller,
            _data.distributors,
            _data.immutableController,
            _data.autoNativeTokenDistribution,
            _data.minAutoDistributeAmount,
            platformFee,
            address(this),
            _data.initialRecipients,
            _data.percentages
        );

        emit RSCValveCreated(
            clone,
            _data.controller,
            _data.distributors,
            version,
            _data.immutableController,
            _data.autoNativeTokenDistribution,
            _data.minAutoDistributeAmount,
            creationId
        );

        return clone;
    }

    /**
     * @dev Only Owner function for setting platform fee
     * @param _fee Percentage define platform fee 100% == 10000000
     */
    function setPlatformFee(uint256 _fee) external onlyOwner {
        if (_fee > 10000000) {
            revert InvalidFeePercentage();
        }
        emit PlatformFeeChanged(platformFee, _fee);
        platformFee = _fee;
    }

    /**
     * @dev Only Owner function for setting platform fee
     * @param _platformWallet New native token wallet which will receive fee
     */
    function setPlatformWallet(address payable _platformWallet) external onlyOwner {
        emit PlatformWalletChanged(platformWallet, _platformWallet);
        platformWallet = _platformWallet;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IFeeFactory {
    function platformWallet() external returns(address payable);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IRecursiveRSC {
    function distributors(address _distributor) external returns(bool);
    function redistributeToken(address _token) external;
    function redistributeNativeToken() external;
    function autoNativeTokenDistribution() external returns(bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/IFeeFactory.sol";
import "../interfaces/IRecursiveRSC.sol";


contract XLARSCValve is OwnableUpgradeable {
    mapping(address => bool) public distributors;
    address public controller;
    bool public immutableController;
    bool public autoNativeTokenDistribution;
    uint256 public minAutoDistributionAmount;
    uint256 public platformFee;
    IFeeFactory public factory;

    address payable [] public recipients;
    mapping(address => uint256) public recipientsPercentage;

    event SetRecipients(address payable [] recipients, uint256[] percentages);
    event DistributeToken(address token, uint256 amount);
    event DistributorChanged(address distributor, bool isDistributor);
    event ControllerChanged(address oldController, address newController);

    // Throw when if sender is not distributor
    error OnlyDistributorError();

    // Throw when sender is not controller
    error OnlyControllerError();

    // Throw when transaction fails
    error TransferFailedError();

    // Throw when submitted recipient with address(0)
    error NullAddressRecipientError();

    // Throw if recipient is already in contract
    error RecipientAlreadyAddedError();

    // Throw when arrays are submit without same length
    error InconsistentDataLengthError();

    // Throw when sum of percentage is not 100%
    error InvalidPercentageError();

    // Throw when distributor address is same as submit one
    error DistributorAlreadyConfiguredError();

    // Throw when distributor address is same as submit one
    error ControllerAlreadyConfiguredError();

    // Throw when change is triggered for immutable controller
    error ImmutableControllerError();


    /**
     * @dev Checks whether sender is distributor
     */
    modifier onlyDistributor {
        if (distributors[msg.sender] == false) {
            revert OnlyDistributorError();
        }
        _;
    }

    /**
     * @dev Checks whether sender is controller
     */
    modifier onlyController {
        if (msg.sender != controller) {
            revert OnlyControllerError();
        }
        _;
    }

     /**
     * @dev Constructor function, can be called only once
     * @param _owner Owner of the contract
     * @param _controller address which control setting / removing recipients
     * @param _distributors list of addresses which can distribute ERC20 tokens or native token
     * @param _immutableController flag indicating whether controller could be changed
     * @param _autoNativeTokenDistribution flag indicating whether native token will be automatically distributed or manually
     * @param _minAutoDistributionAmount Minimum native token amount to trigger auto native token distribution
     * @param _platformFee Percentage defining fee for distribution services
     * @param _factoryAddress Address of the factory used for creating this RSC
     * @param _initialRecipients Initial recipient addresses
     * @param _percentages initial percentages for recipients
     */
    function initialize(
        address _owner,
        address _controller,
        address[] memory _distributors,
        bool _immutableController,
        bool _autoNativeTokenDistribution,
        uint256 _minAutoDistributionAmount,
        uint256 _platformFee,
        address _factoryAddress,
        address payable [] memory _initialRecipients,
        uint256[] memory _percentages
    ) public initializer {

        uint256 distributorsLength = _distributors.length;
        for (uint256 i = 0; i < distributorsLength;) {
            distributors[_distributors[i]] = true;
            unchecked{i++;}
        }

        controller = _controller;
        immutableController = _immutableController;
        autoNativeTokenDistribution = _autoNativeTokenDistribution;
        minAutoDistributionAmount = _minAutoDistributionAmount;
        factory = IFeeFactory(_factoryAddress);
        platformFee = _platformFee;

        _setRecipients(_initialRecipients, _percentages);
        _transferOwnership(_owner);
    }

    fallback() external payable {
        // Check whether automatic native token distribution is enabled
        // and that contractBalance is more than automatic distribution trash hold
        uint256 contractBalance = address(this).balance;
        if (autoNativeTokenDistribution && contractBalance >= minAutoDistributionAmount) {
            _redistributeNativeToken(contractBalance);
        }
    }

    receive() external payable {
        // Check whether automatic native token distribution is enabled
        // and that contractBalance is more than automatic distribution trash hold
        uint256 contractBalance = address(this).balance;
        if (autoNativeTokenDistribution && contractBalance >= minAutoDistributionAmount) {
            _redistributeNativeToken(contractBalance);
        }
    }

    /**
     * @notice External function to return number of recipients
     */
    function numberOfRecipients() external view returns(uint256) {
        return recipients.length;
    }

    /**
     * @notice Internal function to redistribute native token based on percentages assign to the recipients
     * @param _valueToDistribute native token amount to be distributed
     */
    function _redistributeNativeToken(uint256 _valueToDistribute) internal {
        if (platformFee > 0) {
            uint256 fee = _valueToDistribute / 10000000 * platformFee;
            _valueToDistribute -= fee;
            address payable platformWallet = factory.platformWallet();
            (bool success,) = platformWallet.call{value: fee}("");
            if (success == false) {
                revert TransferFailedError();
            }
        }

        uint256 recipientsLength = recipients.length;
        for (uint256 i = 0; i < recipientsLength;) {
            address payable recipient = recipients[i];
            uint256 percentage = recipientsPercentage[recipient];
            uint256 amountToReceive = _valueToDistribute / 10000000 * percentage;
            (bool success,) = payable(recipient).call{value: amountToReceive}("");
            if (success == false) {
                revert TransferFailedError();
            }
            _recursiveNativeTokenDistribution(recipient);
            unchecked{i++;}
        }
    }

    /**
     * @notice External function to redistribute native token based on percentages assign to the recipients
     */
    function redistributeNativeToken() external onlyDistributor {
        _redistributeNativeToken(address(this).balance);
    }


    /**
     * @notice Internal function to check whether percentages are equal to 100%
     * @return valid boolean indicating whether sum of percentage == 100% (10000000)
     */
    function _percentageIsValid() internal view returns (bool valid){
        uint256 recipientsLength = recipients.length;
        uint256 percentageSum;

        for (uint256 i = 0; i < recipientsLength;) {
            address recipient = recipients[i];
            percentageSum += recipientsPercentage[recipient];
            unchecked {i++;}
        }

        return percentageSum == 10000000;
    }

    /**
     * @notice Internal function for adding recipient to revenue share
     * @param _recipient Fixed amount of token user want to buy
     * @param _percentage code of the affiliation partner
     */
    function _addRecipient(address payable _recipient, uint256 _percentage) internal {
        if (_recipient == address(0)) {
            revert NullAddressRecipientError();
        }
        if (recipientsPercentage[_recipient] != 0) {
            revert RecipientAlreadyAddedError();
        }
        recipients.push(_recipient);
        recipientsPercentage[_recipient] = _percentage;
    }

    /**
     * @notice Internal function for removing all recipients
     */
    function _removeAll() internal {
        uint256 recipientsLength = recipients.length;

        if (recipientsLength == 0) {
            return;
        }

        for (uint256 i = 0; i < recipientsLength;) {
            address recipient = recipients[i];
            recipientsPercentage[recipient] = 0;
            unchecked{i++;}
        }
        delete recipients;
    }

    /**
     * @notice Internal function for setting recipients
     * @param _newRecipients Addresses to be added
     * @param _percentages new percentages for recipients
     */
    function _setRecipients(
        address payable [] memory _newRecipients,
        uint256[] memory _percentages
    ) internal {
        uint256 newRecipientsLength = _newRecipients.length;

        if (newRecipientsLength != _percentages.length) {
            revert InconsistentDataLengthError();
        }

        _removeAll();

        for (uint256 i = 0; i < newRecipientsLength;) {
            _addRecipient(_newRecipients[i], _percentages[i]);
            unchecked{i++;}
        }

        if (_percentageIsValid() == false) {
            revert InvalidPercentageError();
        }

        emit SetRecipients(_newRecipients, _percentages);
    }

    /**
     * @notice External function for setting recipients
     * @param _newRecipients Addresses to be added
     * @param _percentages new percentages for recipients
     */
    function setRecipients(
        address payable [] memory _newRecipients,
        uint256[] memory _percentages
    ) public onlyController {
        _setRecipients(_newRecipients, _percentages);
    }


    /**
     * @notice External function to redistribute ERC20 token based on percentages assign to the recipients
     * @param _token Address of the ERC20 token to be distribute
     */
    function redistributeToken(address _token) external onlyDistributor {
        uint256 recipientsLength = recipients.length;

        IERC20 erc20Token = IERC20(_token);
        uint256 contractBalance = erc20Token.balanceOf(address(this));
        if (contractBalance == 0) {
            return;
        }

         if (platformFee > 0) {
            uint256 fee = contractBalance / 10000000 * platformFee;
            contractBalance -= fee;
            address payable platformWallet = factory.platformWallet();
             erc20Token.transfer(platformWallet, fee);
        }

        for (uint256 i = 0; i < recipientsLength;) {
            address payable recipient = recipients[i];
            uint256 percentage = recipientsPercentage[recipient];
            uint256 amountToReceive = contractBalance / 10000000 * percentage;
            erc20Token.transfer(recipient, amountToReceive);
            _recursiveERC20Distribution(recipient, _token);
            unchecked{i++;}
        }
        emit DistributeToken(_token, contractBalance);
    }

    /**
     * @notice External function to set distributor address
     * @param _distributor address of new distributor
     * @param _isDistributor bool indicating whether address is / isn't distributor
     */
    function setDistributor(address _distributor, bool _isDistributor) external onlyOwner {
        emit DistributorChanged(_distributor, _isDistributor);
        distributors[_distributor] = _isDistributor;
    }

    /**
     * @notice External function to set controller address, if set to address(0), unable to change it
     * @param _controller address of new controller
     */
    function setController(address _controller) external onlyOwner {
        if (controller == address(0) || immutableController) {
            revert ImmutableControllerError();
        }
        emit ControllerChanged(controller, _controller);
        controller = _controller;
    }

    /**
     * @notice Internal function to check whether recipient should be recursively distributed
     * @param _recipient Address of recipient to recursively distribute
     * @param _token token to be distributed
     */
    function _recursiveERC20Distribution(address _recipient, address _token) internal {
        // Handle Recursive token distribution
        IRecursiveRSC recursiveRecipient = IRecursiveRSC(_recipient);

        // Wallets have size 0 and contracts > 0. This way we can distinguish them.
        uint256 recipientSize;
        assembly {recipientSize := extcodesize(_recipient)}
        if (recipientSize > 0) {
            // Validate this contract is distributor in child recipient
            try recursiveRecipient.distributors(address(this)) returns(bool isBranchDistributor) {
                if (isBranchDistributor) {
                    recursiveRecipient.redistributeToken(_token);
                }
            } catch {return;}  // unable to recursively distribute
        }
    }

    /**
     * @notice Internal function to check whether recipient should be recursively distributed
     * @param _recipient Address of recipient to recursively distribute
     */
    function _recursiveNativeTokenDistribution(address _recipient) internal {
        // Handle Recursive token distribution
        IRecursiveRSC recursiveRecipient = IRecursiveRSC(_recipient);

        // Wallets have size 0 and contracts > 0. This way we can distinguish them.
        uint256 recipientSize;
        assembly {recipientSize := extcodesize(_recipient)}
        if (recipientSize > 0) {

            // Check whether child recipient have autoNativeTokenDistribution set to true,
            // if yes tokens will be recursively distributed automatically
            try recursiveRecipient.autoNativeTokenDistribution() returns(bool childAutoNativeTokenDistribution) {
                if (childAutoNativeTokenDistribution == true) {
                    return;
                }
            } catch {return;}

            // Validate this contract is distributor in child recipient
            try recursiveRecipient.distributors(address(this)) returns(bool isBranchDistributor) {
                if (isBranchDistributor) {
                    recursiveRecipient.redistributeNativeToken();
                }
            } catch {return;}  // unable to recursively distribute
        }
    }
}