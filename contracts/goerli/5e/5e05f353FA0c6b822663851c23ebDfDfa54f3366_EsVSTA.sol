// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

import "./IBaseVesta.sol";

import "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

/**
@title BaseVesta
@notice Inherited by most of our contracts. It has a permission system & reentrency protection inside it.
@dev Binary Roles Recommended Slots
0x01  |  0x10
0x02  |  0x20
0x04  |  0x40
0x08  |  0x80

Don't use other slots unless you are familiar with bitewise operations
*/

abstract contract BaseVesta is IBaseVesta, OwnableUpgradeable {
	address internal SELF = address(this);
	address internal constant RESERVED_ETH_ADDRESS = address(0);
	uint256 internal constant MAX_UINT256 = type(uint256).max;
	bool private reentrencyStatus = false;

	mapping(address => bytes1) internal permissions;

	uint256[49] private __gap;

	modifier onlyContract(address _address) {
		if (_address.code.length == 0) revert InvalidContract();
		_;
	}

	modifier onlyContracts(address _address, address _address2) {
		if (_address.code.length == 0 || _address2.code.length == 0) {
			revert InvalidContract();
		}
		_;
	}

	modifier onlyValidAddress(address _address) {
		if (_address == address(0)) {
			revert InvalidAddress();
		}

		_;
	}

	modifier nonReentrant() {
		if (reentrencyStatus) revert NonReentrancy();
		reentrencyStatus = true;
		_;
		reentrencyStatus = false;
	}

	modifier hasPermission(bytes1 access) {
		if (permissions[msg.sender] & access == 0) revert InvalidPermission();
		_;
	}

	modifier hasPermissionOrOwner(bytes1 access) {
		if (permissions[msg.sender] & access == 0 && msg.sender != owner()) {
			revert InvalidPermission();
		}

		_;
	}

	modifier notZero(uint256 _amount) {
		if (_amount == 0) revert NumberIsZero();
		_;
	}

	function __BASE_VESTA_INIT() internal onlyInitializing {
		__Ownable_init();
	}

	function setPermission(address _address, bytes1 _permission)
		external
		override
		onlyOwner
	{
		_setPermission(_address, _permission);
	}

	function _clearPermission(address _address) internal virtual {
		_setPermission(_address, 0x00);
	}

	function _setPermission(address _address, bytes1 _permission) internal virtual {
		permissions[_address] = _permission;
		emit PermissionChanged(_address, _permission);
	}

	function getPermissionLevel(address _address)
		external
		view
		override
		returns (bytes1)
	{
		return permissions[_address];
	}

	function hasPermissionLevel(address _address, bytes1 accessLevel)
		public
		view
		override
		returns (bool)
	{
		return permissions[_address] & accessLevel != 0;
	}

	/** 
	@notice _sanitizeMsgValueWithParam is for multi-token payable function.
	@dev msg.value should be set to zero if the token used isn't a native token.
		address(0) is reserved for Native Chain Token.
		if fails, it will reverts with SanitizeMsgValueFailed(address _token, uint256 _paramValue, uint256 _msgValue).
	@return sanitizeValue which is the sanitize value you should use in your code.
	*/
	function _sanitizeMsgValueWithParam(address _token, uint256 _paramValue)
		internal
		view
		returns (uint256)
	{
		if (RESERVED_ETH_ADDRESS == _token) {
			return msg.value;
		} else if (msg.value == 0) {
			return _paramValue;
		}

		revert SanitizeMsgValueFailed(_token, _paramValue, msg.value);
	}

	function isContract(address _address) internal view returns (bool) {
		return _address.code.length > 0;
	}
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.0;

interface IBaseVesta {
	error NonReentrancy();
	error InvalidPermission();
	error InvalidAddress();
	error CannotBeNativeChainToken();
	error InvalidContract();
	error NumberIsZero();
	error SanitizeMsgValueFailed(
		address _token,
		uint256 _paramValue,
		uint256 _msgValue
	);

	event PermissionChanged(address indexed _address, bytes1 newPermission);

	/** 
	@notice setPermission to an address so they have access to specific functions.
	@dev can add multiple permission by using | between them
	@param _address the address that will receive the permissions
	@param _permission the bytes permission(s)
	*/
	function setPermission(address _address, bytes1 _permission) external;

	/** 
	@notice get the permission level on an address
	@param _address the address you want to check the permission on
	@return accessLevel the bytes code of the address permission
	*/
	function getPermissionLevel(address _address) external view returns (bytes1);

	/** 
	@notice Verify if an address has specific permissions
	@param _address the address you want to check
	@param _accessLevel the access level you want to verify on
	@return hasAccess return true if the address has access
	*/
	function hasPermissionLevel(address _address, bytes1 _accessLevel)
		external
		view
		returns (bool);
}

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

import "./ILendingWallet.sol";
import "../../interface/IERC20Callback.sol";

import { TokenTransferrer } from "../../lib/token/TokenTransferrer.sol";
import "../../BaseVesta.sol";
import "../../StableCoin.sol";

/**
@title LendingWallet
@notice 
	Lending Wallet is basically the wallet of our protocol "Lending Service". 
	All the funds are held inside this and only this contract will handle the transfers.
*/

contract LendingWallet is
	ILendingWallet,
	IERC20Callback,
	TokenTransferrer,
	BaseVesta
{
	using AddressUpgradeable for address;

	bytes1 public constant DEPOSIT = 0x01;
	bytes1 public constant WITHDRAW = 0x02;
	bytes1 public constant DEBT_ACCESS = 0x04;
	bytes1 public constant REDISTRIBUTION_ACCESS = 0x08;
	bytes1 public constant LENDING_MANAGER = 0x10;
	bytes1 public constant STABILITY_POOL_MANAGER = 0x20;
	// bytes1 public constant WITHDRAWER_HANDLER = 0x80;  VApp

	StableCoin public VST_TOKEN;

	uint256 internal gasCompensation;

	// asset => amount
	mapping(address => uint256) internal totalSurplusCollaterals;

	// wallet => asset => amount
	mapping(address => mapping(address => uint256)) internal userSurplusCollaterals;

	mapping(address => uint256) internal collaterals;
	mapping(address => uint256) internal debts;

	mapping(address => uint256) internal redistributionCollaterals;
	mapping(address => uint256) internal redistributionDebts;

	function setUp(
		address _vstToken,
		address _lendingManager,
		address _stabilityPoolManager
	) external initializer {
		if (
			!_vstToken.isContract() ||
			!_lendingManager.isContract() ||
			!_stabilityPoolManager.isContract()
		) revert InvalidContract();

		__BASE_VESTA_INIT();

		VST_TOKEN = StableCoin(_vstToken);

		_setPermission(_lendingManager, LENDING_MANAGER);
		_setPermission(_stabilityPoolManager, STABILITY_POOL_MANAGER);
	}

	function registerNewLendingEntity(address _entity)
		external
		hasPermission(LENDING_MANAGER)
		onlyContract(_entity)
	{
		_setPermission(_entity, WITHDRAW | DEPOSIT | DEBT_ACCESS);
	}

	function unregisterLendingEntity(address _entity)
		external
		hasPermissionOrOwner(LENDING_MANAGER)
	{
		_clearPermission(_entity);
	}

	function registerNewStabilityPoolEntity(address _entity)
		external
		hasPermission(STABILITY_POOL_MANAGER)
		onlyContract(_entity)
	{
		_setPermission(_entity, WITHDRAW);
	}

	function unregisterStabilityPoolEntity(address _entity)
		external
		hasPermissionOrOwner(STABILITY_POOL_MANAGER)
	{
		_clearPermission(_entity);
	}

	function transfer(
		address _token,
		address _to,
		uint256 _amount
	) external override hasPermission(WITHDRAW) {
		_transfer(_token, _to, _amount, true);

		emit CollateralChanged(_token, collaterals[RESERVED_ETH_ADDRESS]);
	}

	function _transfer(
		address _token,
		address _to,
		uint256 _amount,
		bool _vaultBalance
	) internal nonReentrant {
		uint256 sanitizedAmount = _sanitizeValue(_token, _amount);

		if (sanitizedAmount == 0) return;

		if (_vaultBalance) {
			collaterals[_token] -= _amount;
		}

		_performTokenTransfer(_token, _to, sanitizedAmount, true);

		emit Withdraw(_token, _to, _amount);
	}

	receive() external payable {
		if (hasPermissionLevel(msg.sender, DEPOSIT)) {
			collaterals[RESERVED_ETH_ADDRESS] += msg.value;
			emit Deposit(RESERVED_ETH_ADDRESS, msg.value);
			emit CollateralChanged(
				RESERVED_ETH_ADDRESS,
				collaterals[RESERVED_ETH_ADDRESS]
			);
		}
	}

	function receiveERC20(address _token, uint256 _amount)
		external
		override
		hasPermission(DEPOSIT)
	{
		if (RESERVED_ETH_ADDRESS == _token) {
			revert CannotBeNativeChainToken();
		}

		collaterals[_token] += _amount;
		emit Deposit(_token, _amount);
		emit CollateralChanged(_token, collaterals[_token]);
	}

	function decreaseDebt(
		address _token,
		address _from,
		uint256 _amount
	) external override hasPermission(DEBT_ACCESS) {
		debts[_token] -= _amount;
		VST_TOKEN.burn(_from, _amount);

		emit DebtChanged(_token, debts[_token]);
	}

	function increaseDebt(
		address _token,
		address _to,
		uint256 _amountToMint,
		uint256 _amountToDebt
	) external override hasPermission(DEBT_ACCESS) {
		debts[_token] += _amountToDebt;
		VST_TOKEN.mintDebt(_token, _to, _amountToMint);

		emit DebtChanged(_token, debts[_token]);
	}

	function moveCollateralToRedistribution(address _token, uint256 _amount)
		external
		override
		hasPermission(REDISTRIBUTION_ACCESS)
	{
		collaterals[_token] -= _amount;
		redistributionCollaterals[_token] += _amount;

		emit CollateralChanged(_token, collaterals[_token]);
		emit RedistributionCollateralChanged(_token, redistributionCollaterals[_token]);
	}

	function moveDebtToRedistribution(address _token, uint256 _amount)
		external
		override
		hasPermission(REDISTRIBUTION_ACCESS)
	{
		debts[_token] -= _amount;
		redistributionDebts[_token] += _amount;

		emit DebtChanged(_token, debts[_token]);
		emit RedistributionDebtChanged(_token, redistributionDebts[_token]);
	}

	function returnRedistributionCollateral(address _token, uint256 _amount)
		external
		override
		hasPermission(REDISTRIBUTION_ACCESS)
	{
		redistributionCollaterals[_token] -= _amount;
		collaterals[_token] += _amount;

		emit CollateralChanged(_token, collaterals[_token]);
		emit RedistributionCollateralChanged(_token, redistributionCollaterals[_token]);
	}

	function returnRedistributionDebt(address _token, uint256 _amount)
		external
		override
		hasPermission(REDISTRIBUTION_ACCESS)
	{
		redistributionDebts[_token] -= _amount;
		debts[_token] += _amount;

		emit DebtChanged(_token, debts[_token]);
		emit RedistributionDebtChanged(_token, redistributionDebts[_token]);
	}

	function mintGasCompensation(uint256 _amount)
		external
		override
		hasPermission(DEPOSIT)
	{
		gasCompensation += _amount;
		VST_TOKEN.mint(address(this), _amount);
		emit GasCompensationChanged(gasCompensation);
	}

	function burnGasCompensation(uint256 _amount)
		external
		override
		hasPermission(WITHDRAW)
	{
		gasCompensation -= _amount;
		VST_TOKEN.burn(address(this), _amount);
		emit GasCompensationChanged(gasCompensation);
	}

	function refundGasCompensation(address _user, uint256 _amount)
		external
		override
		hasPermission(WITHDRAW)
	{
		gasCompensation -= _amount;
		_transfer(address(VST_TOKEN), _user, _amount, false);
		emit GasCompensationChanged(gasCompensation);
	}

	function mintVstTo(
		address _token,
		address _to,
		uint256 _amount,
		bool _depositCallback
	) external override hasPermission(WITHDRAW) nonReentrant {
		VST_TOKEN.mintDebt(_token, _to, _amount);

		if (_depositCallback && _to.isContract()) {
			IERC20Callback(_to).receiveERC20(_token, _amount);
		}

		emit VstMinted(_to, _amount);
	}

	function addSurplusCollateral(
		address _token,
		address _user,
		uint256 _amount
	) external override hasPermission(DEPOSIT) {
		uint256 newSurplusTotal = totalSurplusCollaterals[_token] += _amount;
		uint256 newUserSurplusTotal = userSurplusCollaterals[_user][_token] += _amount;

		emit SurplusCollateralChanged(newSurplusTotal);
		emit UserSurplusCollateralChanged(_user, newUserSurplusTotal);
	}

	function claimSurplusCollateral(address _token) external override {
		uint256 supply = userSurplusCollaterals[msg.sender][_token];

		if (supply == 0) return;

		uint256 newSurplusTotal = totalSurplusCollaterals[_token] -= supply;
		userSurplusCollaterals[msg.sender][_token] = 0;

		_transfer(_token, msg.sender, supply, false);

		emit SurplusCollateralChanged(newSurplusTotal);
		emit UserSurplusCollateralChanged(msg.sender, 0);
	}

	function getGasCompensation() external view override returns (uint256) {
		return gasCompensation;
	}

	function getLendingBalance(address _token)
		external
		view
		override
		returns (uint256 collaterals_, uint256 debts_)
	{
		return (collaterals[_token], debts[_token]);
	}

	function getLendingCollateral(address _token)
		external
		view
		override
		returns (uint256)
	{
		return collaterals[_token];
	}

	function getLendingDebts(address _token) external view override returns (uint256) {
		return debts[_token];
	}

	function getRedistributionCollateral(address _token)
		external
		view
		override
		returns (uint256)
	{
		return redistributionCollaterals[_token];
	}

	function getRedistributionDebt(address _token)
		external
		view
		override
		returns (uint256)
	{
		return redistributionDebts[_token];
	}

	function getTotalSurplusCollateral(address _token)
		external
		view
		override
		returns (uint256)
	{
		return totalSurplusCollaterals[_token];
	}

	function getUserSurplusCollateral(address _token, address _user)
		external
		view
		override
		returns (uint256)
	{
		return userSurplusCollaterals[_user][_token];
	}
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.0;

interface ILendingWallet {
	event Deposit(address indexed _token, uint256 _value);
	event Withdraw(address indexed _token, address _to, uint256 _value);
	event CollateralChanged(address indexed _token, uint256 _newValue);
	event DebtChanged(address indexed _token, uint256 _newValue);
	event RedistributionCollateralChanged(address indexed _token, uint256 _newValue);
	event RedistributionDebtChanged(address indexed _token, uint256 _newValue);
	event GasCompensationChanged(uint256 _newValue);
	event VstMinted(address indexed _to, uint256 _value);
	event SurplusCollateralChanged(uint256 _newValue);
	event UserSurplusCollateralChanged(address indexed _user, uint256 _newValue);

	/** 
	@notice Transfer any tokens from the contract to an address
	@dev requires WITHDRAW permission to execute this function
	@param _token address of the token you want to withdraw
	@param _to address you want to send to
	@param _amount the amount you want to send
	 */
	function transfer(
		address _token,
		address _to,
		uint256 _amount
	) external;

	/** 
	@notice Decrease the debt of a vault and burn the stable token of `_from` (normally, it's the vault's owner)
		*Normally: since we have a feature that allows a friend of the vault's owner to pay off the debts for the owner.
	@dev requires DEBT_ACCESS permission to execute this function
	@param _token address of the token used by the vault
	@param _from the address you want to burn the stable token from
	@param _amount the amount of debt you want to remove
	 */
	function decreaseDebt(
		address _token,
		address _from,
		uint256 _amount
	) external;

	/** 
	@notice Increase debt of a vault and mint the stable token to the vault's owner
	@dev requires DEBT_ACCESS permission to execute this function
	@param _token address of the token used by the vault
	@param _to the address you want to mint to
	@param _amountToMint the exact number you want to mint
	@param _amountToDebt the amount of debt you want to add to the vault. 
		e.g: 100 to mint + X for the fee. You don't want to send the fee to the user but want to include it
	 */
	function increaseDebt(
		address _token,
		address _to,
		uint256 _amountToMint,
		uint256 _amountToDebt
	) external;

	/** 
	@notice Move the collateral from the lending service to the Redistribution data.
	@dev requires REDISTRIBUTION_ACCESS permission to execute this function
	@param _token address of the token used by the vault
	@param _amount the amount we want to redistribute
	 */
	function moveCollateralToRedistribution(address _token, uint256 _amount) external;

	/** 
	@notice Move the debts from the lending service to the Redistribution data.
	@dev requires REDISTRIBUTION_ACCESS permission to execute this function
	@param _token address of the token used by the vault
	@param _amount the amount we want to redistribute
	 */
	function moveDebtToRedistribution(address _token, uint256 _amount) external;

	/** 
	@notice Move back the collateral from Redistribution to the lending service data.
	@dev requires REDISTRIBUTION_ACCESS permission to execute this function
	@param _token address of the token used by the vault
	@param _amount the amount we want to return
	 */
	function returnRedistributionCollateral(address _token, uint256 _amount) external;

	/** 
	@notice Move back the debt from Redistribution to the lending service data.
	@dev requires REDISTRIBUTION_ACCESS permission to execute this function
	@param _token address of the token used by the vault
	@param _amount the amount we want to return
	 */
	function returnRedistributionDebt(address _token, uint256 _amount) external;

	/** 
	@notice Mint an extra of stable token for gas compensation.
	@dev requires DEPOSIT permission to execute this function
	@param _amount the amount we want to mint
	 */
	function mintGasCompensation(uint256 _amount) external;

	/** 
	@notice Burn the gas compensation.
	@dev requires DEPOSIT permission to execute this function
	@param _amount the amount we want to burn
	 */
	function burnGasCompensation(uint256 _amount) external;

	/** 
	@notice Send gas compensation to a user
	@dev requires WITHDRAW permission to execute this function
	@param _user the address you want to send the gas compensation
	@param _amount the amount you want to send
	 */
	function refundGasCompensation(address _user, uint256 _amount) external;

	/** 
	@notice Mint directly into an account via a lending service. e.g for the fee when opening a vault.
	@dev requires WITHDRAW permission to execute this function
	@param _to the address you want to mint to.
	@param _amount the amount you want to mint
	@param _depositCallback trigger the callback function receiveERC20(address _token, uint256 _amount) if it's a contract
		IERC20Callback has been created for Vesta protocol's contracts to track the ERC20 flow.
	 */
	function mintVstTo(
		address _token,
		address _to,
		uint256 _amount,
		bool _depositCallback
	) external;

	/** 
	@notice Add surplus collateral to a user.
	@dev requires DEPOSIT permission to execute this function
		Most of the time, a surplus collateral happens on an execution of a third party user / service.
		It is not their job to pay the transfer fee of the collateral. 
		That's why we store it and the user will need to manually claim it.
	@param _token the address used by the lending service / vault
	@param _user the user that will be able to claim this surplus collateral
	@param _amount the amount of the surplus collateral
	 */
	function addSurplusCollateral(
		address _token,
		address _user,
		uint256 _amount
	) external;

	/** 
	@notice Claim the pending surplus collateral.
	@param _token the address used by the lending service / vault
	 */
	function claimSurplusCollateral(address _token) external;

	/** 
	@notice Total amount of gas compensation stored in the contract.
	@return _value total amount for the gas compensation
	 */
	function getGasCompensation() external view returns (uint256);

	/** 
	@notice Total amount of collateral by a lending service stored in the contract.
	@param _token address of the token used by the lending service
	@return _value total collateral from the lending service
	 */
	function getLendingCollateral(address _token) external view returns (uint256);

	/** 
	@notice Total amount of debts by a lending service stored in the contract.
	@param _token address of the token used by the lending service
	@return _value total debts of from the lending service
	 */
	function getLendingDebts(address _token) external view returns (uint256);

	/** 
	@notice Get both collateral and debts of a Lending Service
	@param _token address of the token used by the lending service
	@return collateral_ total collateral from the lending service
	@return debts_ total debts of from the lending service
	 */
	function getLendingBalance(address _token)
		external
		view
		returns (uint256 collateral_, uint256 debts_);

	/** 
	@notice Total stored collateral for redistribution from the lending service
	@param _token address of the token used by the lending service
	@return _value total collateral of the lending service
	 */
	function getRedistributionCollateral(address _token)
		external
		view
		returns (uint256);

	/** 
	@notice Total stored debts for redistribution from the lending service
	@param _token address of the token used by the lending service
	@return _value total debts of the lending service
	 */
	function getRedistributionDebt(address _token) external view returns (uint256);

	/** 
	@notice Total surplus collateral waiting to be claimed by the Lending Service
	@param _token address of the token used by the lending service
	@return _value total collateral of the lending service
	 */
	function getTotalSurplusCollateral(address _token) external view returns (uint256);

	/** 
	@notice Total surplus collateral of an user waiting to be claimed by the Lending Service
	@param _token address of the token used by the lending service
	@param _user address to look for surplus collateral
	@return _value total collateral waiting to be claimed by the user
	 */
	function getUserSurplusCollateral(address _token, address _user)
		external
		view
		returns (uint256);
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.0;

interface IERC20Callback {
	/// @notice receiveERC20 should be used as the "receive" callback of native token but for erc20
	/// @dev Be sure to limit the access of this call.
	/// @param _token transfered token
	/// @param _value The value of the transfer
	function receiveERC20(address _token, uint256 _value) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./TokenTransferrerConstants.sol";
import { TokenTransferrerErrors } from "./TokenTransferrerErrors.sol";
import { IERC20 } from "../../interface/IERC20.sol";
import { IERC20Callback } from "../../interface/IERC20Callback.sol";

/**
 * @title TokenTransferrer
 * @custom:source https://github.com/ProjectOpenSea/seaport
 * @dev Modified version of Seaport.
 */
abstract contract TokenTransferrer is TokenTransferrerErrors {
	function _performTokenTransfer(
		address token,
		address to,
		uint256 amount,
		bool sendCallback
	) internal {
		if (token == address(0)) {
			(bool success, ) = to.call{ value: amount }(new bytes(0));

			if (!success) revert ErrorTransferETH(address(this), token, amount);

			return;
		}

		address from = address(this);

		// Utilize assembly to perform an optimized ERC20 token transfer.
		assembly {
			// The free memory pointer memory slot will be used when populating
			// call data for the transfer; read the value and restore it later.
			let memPointer := mload(FreeMemoryPointerSlot)

			// Write call data into memory, starting with function selector.
			mstore(ERC20_transfer_sig_ptr, ERC20_transfer_signature)
			mstore(ERC20_transfer_to_ptr, to)
			mstore(ERC20_transfer_amount_ptr, amount)

			// Make call & copy up to 32 bytes of return data to scratch space.
			// Scratch space does not need to be cleared ahead of time, as the
			// subsequent check will ensure that either at least a full word of
			// return data is received (in which case it will be overwritten) or
			// that no data is received (in which case scratch space will be
			// ignored) on a successful call to the given token.
			let callStatus := call(
				gas(),
				token,
				0,
				ERC20_transfer_sig_ptr,
				ERC20_transfer_length,
				0,
				OneWord
			)

			// Determine whether transfer was successful using status & result.
			let success := and(
				// Set success to whether the call reverted, if not check it
				// either returned exactly 1 (can't just be non-zero data), or
				// had no return data.
				or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
				callStatus
			)

			// Handle cases where either the transfer failed or no data was
			// returned. Group these, as most transfers will succeed with data.
			// Equivalent to `or(iszero(success), iszero(returndatasize()))`
			// but after it's inverted for JUMPI this expression is cheaper.
			if iszero(and(success, iszero(iszero(returndatasize())))) {
				// If the token has no code or the transfer failed: Equivalent
				// to `or(iszero(success), iszero(extcodesize(token)))` but
				// after it's inverted for JUMPI this expression is cheaper.
				if iszero(and(iszero(iszero(extcodesize(token))), success)) {
					// If the transfer failed:
					if iszero(success) {
						// If it was due to a revert:
						if iszero(callStatus) {
							// If it returned a message, bubble it up as long as
							// sufficient gas remains to do so:
							if returndatasize() {
								// Ensure that sufficient gas is available to
								// copy returndata while expanding memory where
								// necessary. Start by computing the word size
								// of returndata and allocated memory. Round up
								// to the nearest full word.
								let returnDataWords := div(
									add(returndatasize(), AlmostOneWord),
									OneWord
								)

								// Note: use the free memory pointer in place of
								// msize() to work around a Yul warning that
								// prevents accessing msize directly when the IR
								// pipeline is activated.
								let msizeWords := div(memPointer, OneWord)

								// Next, compute the cost of the returndatacopy.
								let cost := mul(CostPerWord, returnDataWords)

								// Then, compute cost of new memory allocation.
								if gt(returnDataWords, msizeWords) {
									cost := add(
										cost,
										add(
											mul(sub(returnDataWords, msizeWords), CostPerWord),
											div(
												sub(
													mul(returnDataWords, returnDataWords),
													mul(msizeWords, msizeWords)
												),
												MemoryExpansionCoefficient
											)
										)
									)
								}

								// Finally, add a small constant and compare to
								// gas remaining; bubble up the revert data if
								// enough gas is still available.
								if lt(add(cost, ExtraGasBuffer), gas()) {
									// Copy returndata to memory; overwrite
									// existing memory.
									returndatacopy(0, 0, returndatasize())

									// Revert, specifying memory region with
									// copied returndata.
									revert(0, returndatasize())
								}
							}

							// Otherwise revert with a generic error message.
							mstore(
								TokenTransferGenericFailure_error_sig_ptr,
								TokenTransferGenericFailure_error_signature
							)
							mstore(TokenTransferGenericFailure_error_token_ptr, token)
							mstore(TokenTransferGenericFailure_error_from_ptr, from)
							mstore(TokenTransferGenericFailure_error_to_ptr, to)
							mstore(TokenTransferGenericFailure_error_id_ptr, 0)
							mstore(TokenTransferGenericFailure_error_amount_ptr, amount)
							revert(
								TokenTransferGenericFailure_error_sig_ptr,
								TokenTransferGenericFailure_error_length
							)
						}

						// Otherwise revert with a message about the token
						// returning false or non-compliant return values.
						mstore(
							BadReturnValueFromERC20OnTransfer_error_sig_ptr,
							BadReturnValueFromERC20OnTransfer_error_signature
						)
						mstore(BadReturnValueFromERC20OnTransfer_error_token_ptr, token)
						mstore(BadReturnValueFromERC20OnTransfer_error_from_ptr, from)
						mstore(BadReturnValueFromERC20OnTransfer_error_to_ptr, to)
						mstore(BadReturnValueFromERC20OnTransfer_error_amount_ptr, amount)
						revert(
							BadReturnValueFromERC20OnTransfer_error_sig_ptr,
							BadReturnValueFromERC20OnTransfer_error_length
						)
					}

					// Otherwise, revert with error about token not having code:
					mstore(NoContract_error_sig_ptr, NoContract_error_signature)
					mstore(NoContract_error_token_ptr, token)
					revert(NoContract_error_sig_ptr, NoContract_error_length)
				}

				// Otherwise, the token just returned no data despite the call
				// having succeeded; no need to optimize for this as it's not
				// technically ERC20 compliant.
			}

			// Restore the original free memory pointer.
			mstore(FreeMemoryPointerSlot, memPointer)

			// Restore the zero slot to zero.
			mstore(ZeroSlot, 0)
		}

		_tryPerformCallback(token, to, amount, sendCallback);
	}

	function _performTokenTransferFrom(
		address token,
		address from,
		address to,
		uint256 amount,
		bool sendCallback
	) internal {
		// Utilize assembly to perform an optimized ERC20 token transfer.
		assembly {
			// The free memory pointer memory slot will be used when populating
			// call data for the transfer; read the value and restore it later.
			let memPointer := mload(FreeMemoryPointerSlot)

			// Write call data into memory, starting with function selector.
			mstore(ERC20_transferFrom_sig_ptr, ERC20_transferFrom_signature)
			mstore(ERC20_transferFrom_from_ptr, from)
			mstore(ERC20_transferFrom_to_ptr, to)
			mstore(ERC20_transferFrom_amount_ptr, amount)

			// Make call & copy up to 32 bytes of return data to scratch space.
			// Scratch space does not need to be cleared ahead of time, as the
			// subsequent check will ensure that either at least a full word of
			// return data is received (in which case it will be overwritten) or
			// that no data is received (in which case scratch space will be
			// ignored) on a successful call to the given token.
			let callStatus := call(
				gas(),
				token,
				0,
				ERC20_transferFrom_sig_ptr,
				ERC20_transferFrom_length,
				0,
				OneWord
			)

			// Determine whether transfer was successful using status & result.
			let success := and(
				// Set success to whether the call reverted, if not check it
				// either returned exactly 1 (can't just be non-zero data), or
				// had no return data.
				or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
				callStatus
			)

			// Handle cases where either the transfer failed or no data was
			// returned. Group these, as most transfers will succeed with data.
			// Equivalent to `or(iszero(success), iszero(returndatasize()))`
			// but after it's inverted for JUMPI this expression is cheaper.
			if iszero(and(success, iszero(iszero(returndatasize())))) {
				// If the token has no code or the transfer failed: Equivalent
				// to `or(iszero(success), iszero(extcodesize(token)))` but
				// after it's inverted for JUMPI this expression is cheaper.
				if iszero(and(iszero(iszero(extcodesize(token))), success)) {
					// If the transfer failed:
					if iszero(success) {
						// If it was due to a revert:
						if iszero(callStatus) {
							// If it returned a message, bubble it up as long as
							// sufficient gas remains to do so:
							if returndatasize() {
								// Ensure that sufficient gas is available to
								// copy returndata while expanding memory where
								// necessary. Start by computing the word size
								// of returndata and allocated memory. Round up
								// to the nearest full word.
								let returnDataWords := div(
									add(returndatasize(), AlmostOneWord),
									OneWord
								)

								// Note: use the free memory pointer in place of
								// msize() to work around a Yul warning that
								// prevents accessing msize directly when the IR
								// pipeline is activated.
								let msizeWords := div(memPointer, OneWord)

								// Next, compute the cost of the returndatacopy.
								let cost := mul(CostPerWord, returnDataWords)

								// Then, compute cost of new memory allocation.
								if gt(returnDataWords, msizeWords) {
									cost := add(
										cost,
										add(
											mul(sub(returnDataWords, msizeWords), CostPerWord),
											div(
												sub(
													mul(returnDataWords, returnDataWords),
													mul(msizeWords, msizeWords)
												),
												MemoryExpansionCoefficient
											)
										)
									)
								}

								// Finally, add a small constant and compare to
								// gas remaining; bubble up the revert data if
								// enough gas is still available.
								if lt(add(cost, ExtraGasBuffer), gas()) {
									// Copy returndata to memory; overwrite
									// existing memory.
									returndatacopy(0, 0, returndatasize())

									// Revert, specifying memory region with
									// copied returndata.
									revert(0, returndatasize())
								}
							}

							// Otherwise revert with a generic error message.
							mstore(
								TokenTransferGenericFailure_error_sig_ptr,
								TokenTransferGenericFailure_error_signature
							)
							mstore(TokenTransferGenericFailure_error_token_ptr, token)
							mstore(TokenTransferGenericFailure_error_from_ptr, from)
							mstore(TokenTransferGenericFailure_error_to_ptr, to)
							mstore(TokenTransferGenericFailure_error_id_ptr, 0)
							mstore(TokenTransferGenericFailure_error_amount_ptr, amount)
							revert(
								TokenTransferGenericFailure_error_sig_ptr,
								TokenTransferGenericFailure_error_length
							)
						}

						// Otherwise revert with a message about the token
						// returning false or non-compliant return values.
						mstore(
							BadReturnValueFromERC20OnTransfer_error_sig_ptr,
							BadReturnValueFromERC20OnTransfer_error_signature
						)
						mstore(BadReturnValueFromERC20OnTransfer_error_token_ptr, token)
						mstore(BadReturnValueFromERC20OnTransfer_error_from_ptr, from)
						mstore(BadReturnValueFromERC20OnTransfer_error_to_ptr, to)
						mstore(BadReturnValueFromERC20OnTransfer_error_amount_ptr, amount)
						revert(
							BadReturnValueFromERC20OnTransfer_error_sig_ptr,
							BadReturnValueFromERC20OnTransfer_error_length
						)
					}

					// Otherwise, revert with error about token not having code:
					mstore(NoContract_error_sig_ptr, NoContract_error_signature)
					mstore(NoContract_error_token_ptr, token)
					revert(NoContract_error_sig_ptr, NoContract_error_length)
				}

				// Otherwise, the token just returned no data despite the call
				// having succeeded; no need to optimize for this as it's not
				// technically ERC20 compliant.
			}

			// Restore the original free memory pointer.
			mstore(FreeMemoryPointerSlot, memPointer)

			// Restore the zero slot to zero.
			mstore(ZeroSlot, 0)
		}

		_tryPerformCallback(token, to, amount, sendCallback);
	}

	function _tryPerformCallback(
		address _token,
		address _to,
		uint256 _amount,
		bool _useCallback
	) private {
		if (!_useCallback || _to.code.length == 0) return;

		if (address(this) == _to) {
			revert SelfCallbackTransfer();
		}

		IERC20Callback(_to).receiveERC20(_token, _amount);
	}

	/**
		@notice SanitizeAmount allows to convert an 1e18 value to the token decimals
		@dev only supports 18 and lower
		@param token The contract address of the token
		@param value The value you want to sanitize
	*/
	function _sanitizeValue(address token, uint256 value)
		internal
		view
		returns (uint256)
	{
		if (token == address(0) || value == 0) return value;

		(bool success, bytes memory data) = token.staticcall(
			abi.encodeWithSignature("decimals()")
		);

		if (!success) return value;

		uint8 decimals = abi.decode(data, (uint8));

		if (decimals < 18) {
			return value / (10**(18 - decimals));
		}

		return value;
	}

	function _tryPerformMaxApprove(address _token, address _to) internal {
		if (IERC20(_token).allowance(address(this), _to) == type(uint256).max) {
			return;
		}

		_performApprove(_token, _to, type(uint256).max);
	}

	function _performApprove(
		address _token,
		address _spender,
		uint256 _value
	) internal {
		IERC20(_token).approve(_spender, _value);
	}

	function _balanceOf(address _token, address _of) internal view returns (uint256) {
		return IERC20(_token).balanceOf(_of);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IStableCoin.sol";

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/**
@title StableCoin
*/
contract StableCoin is ERC20, IStableCoin {
	address public override owner;

	mapping(address => bool) internal mintBurnAccess;
	mapping(address => bool) internal emergencyStopMintingCollateral;

	modifier hasPermission() {
		if (!mintBurnAccess[msg.sender]) revert NoAccess();
		_;
	}

	modifier onlyOwner() {
		if (owner != msg.sender) revert NotOwner();
		_;
	}

	constructor(address _wallet) ERC20("Vesta Stable", "v-usd") {
		owner = msg.sender;
		mintBurnAccess[_wallet] = true;
	}

	function setOwner(address _newOwner) external override onlyOwner {
		owner = _newOwner;
		emit TransferOwnership(_newOwner);
	}

	function setMintBurnAccess(address _address, bool _status)
		external
		override
		onlyOwner
	{
		mintBurnAccess[_address] = _status;
		emit MintBurnAccessChanged(_address, _status);
	}

	function emergencyStopMinting(address _asset, bool _status)
		external
		override
		onlyOwner
	{
		emergencyStopMintingCollateral[_asset] = _status;
		emit EmergencyStopMintingCollateral(_asset, _status);
	}

	function mintDebt(
		address _asset,
		address _account,
		uint256 _amount
	) external override hasPermission {
		if (emergencyStopMintingCollateral[_asset]) {
			revert MintingBlocked();
		}

		_mint(_account, _amount);
	}

	function mint(address _account, uint256 _amount) external override hasPermission {
		_mint(_account, _amount);
	}

	function burn(address _account, uint256 _amount) external override hasPermission {
		_burn(_account, _amount);
	}

	function isCollateralStopFromMinting(address _token)
		external
		view
		override
		returns (bool)
	{
		return emergencyStopMintingCollateral[_token];
	}

	function hasMintAndBurnPermission(address _address)
		external
		view
		override
		returns (bool)
	{
		return mintBurnAccess[_address];
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/*
 * -------------------------- Disambiguation & Other Notes ---------------------
 *    - The term "head" is used as it is in the documentation for ABI encoding,
 *      but only in reference to dynamic types, i.e. it always refers to the
 *      offset or pointer to the body of a dynamic type. In calldata, the head
 *      is always an offset (relative to the parent object), while in memory,
 *      the head is always the pointer to the body. More information found here:
 *      https://docs.soliditylang.org/en/v0.8.14/abi-spec.html#argument-encoding
 *        - Note that the length of an array is separate from and precedes the
 *          head of the array.
 *
 *    - The term "body" is used in place of the term "head" used in the ABI
 *      documentation. It refers to the start of the data for a dynamic type,
 *      e.g. the first word of a struct or the first word of the first element
 *      in an array.
 *
 *    - The term "pointer" is used to describe the absolute position of a value
 *      and never an offset relative to another value.
 *        - The suffix "_ptr" refers to a memory pointer.
 *        - The suffix "_cdPtr" refers to a calldata pointer.
 *
 *    - The term "offset" is used to describe the position of a value relative
 *      to some parent value. For example, OrderParameters_conduit_offset is the
 *      offset to the "conduit" value in the OrderParameters struct relative to
 *      the start of the body.
 *        - Note: Offsets are used to derive pointers.
 *
 *    - Some structs have pointers defined for all of their fields in this file.
 *      Lines which are commented out are fields that are not used in the
 *      codebase but have been left in for readability.
 */

uint256 constant AlmostOneWord = 0x1f;
uint256 constant OneWord = 0x20;
uint256 constant TwoWords = 0x40;
uint256 constant ThreeWords = 0x60;

uint256 constant FreeMemoryPointerSlot = 0x40;
uint256 constant ZeroSlot = 0x60;
uint256 constant DefaultFreeMemoryPointer = 0x80;

uint256 constant Slot0x80 = 0x80;
uint256 constant Slot0xA0 = 0xa0;
uint256 constant Slot0xC0 = 0xc0;

// abi.encodeWithSignature("transferFrom(address,address,uint256)")
uint256 constant ERC20_transferFrom_signature = (
	0x23b872dd00000000000000000000000000000000000000000000000000000000
);
uint256 constant ERC20_transferFrom_sig_ptr = 0x0;
uint256 constant ERC20_transferFrom_from_ptr = 0x04;
uint256 constant ERC20_transferFrom_to_ptr = 0x24;
uint256 constant ERC20_transferFrom_amount_ptr = 0x44;
uint256 constant ERC20_transferFrom_length = 0x64; // 4 + 32 * 3 == 100

// abi.encodeWithSignature("transfer(address,uint256)")
uint256 constant ERC20_transfer_signature = (
	0xa9059cbb00000000000000000000000000000000000000000000000000000000
);

uint256 constant ERC20_transfer_sig_ptr = 0x0;
uint256 constant ERC20_transfer_to_ptr = 0x04;
uint256 constant ERC20_transfer_amount_ptr = 0x24;
uint256 constant ERC20_transfer_length = 0x44; // 4 + 32 * 3 == 100

// abi.encodeWithSignature("NoContract(address)")
uint256 constant NoContract_error_signature = (
	0x5f15d67200000000000000000000000000000000000000000000000000000000
);
uint256 constant NoContract_error_sig_ptr = 0x0;
uint256 constant NoContract_error_token_ptr = 0x4;
uint256 constant NoContract_error_length = 0x24; // 4 + 32 == 36

// abi.encodeWithSignature(
//     "TokenTransferGenericFailure(address,address,address,uint256,uint256)"
// )
uint256 constant TokenTransferGenericFailure_error_signature = (
	0xf486bc8700000000000000000000000000000000000000000000000000000000
);
uint256 constant TokenTransferGenericFailure_error_sig_ptr = 0x0;
uint256 constant TokenTransferGenericFailure_error_token_ptr = 0x4;
uint256 constant TokenTransferGenericFailure_error_from_ptr = 0x24;
uint256 constant TokenTransferGenericFailure_error_to_ptr = 0x44;
uint256 constant TokenTransferGenericFailure_error_id_ptr = 0x64;
uint256 constant TokenTransferGenericFailure_error_amount_ptr = 0x84;

// 4 + 32 * 5 == 164
uint256 constant TokenTransferGenericFailure_error_length = 0xa4;

// abi.encodeWithSignature(
//     "BadReturnValueFromERC20OnTransfer(address,address,address,uint256)"
// )
uint256 constant BadReturnValueFromERC20OnTransfer_error_signature = (
	0x9889192300000000000000000000000000000000000000000000000000000000
);
uint256 constant BadReturnValueFromERC20OnTransfer_error_sig_ptr = 0x0;
uint256 constant BadReturnValueFromERC20OnTransfer_error_token_ptr = 0x4;
uint256 constant BadReturnValueFromERC20OnTransfer_error_from_ptr = 0x24;
uint256 constant BadReturnValueFromERC20OnTransfer_error_to_ptr = 0x44;
uint256 constant BadReturnValueFromERC20OnTransfer_error_amount_ptr = 0x64;

// 4 + 32 * 4 == 132
uint256 constant BadReturnValueFromERC20OnTransfer_error_length = 0x84;

uint256 constant ExtraGasBuffer = 0x20;
uint256 constant CostPerWord = 3;
uint256 constant MemoryExpansionCoefficient = 0x200;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title TokenTransferrerErrors
 */
interface TokenTransferrerErrors {
	error ErrorTransferETH(address caller, address to, uint256 value);

	/**
	 * @dev Revert with an error when an ERC20, ERC721, or ERC1155 token
	 *      transfer reverts.
	 *
	 * @param token      The token for which the transfer was attempted.
	 * @param from       The source of the attempted transfer.
	 * @param to         The recipient of the attempted transfer.
	 * @param identifier The identifier for the attempted transfer.
	 * @param amount     The amount for the attempted transfer.
	 */
	error TokenTransferGenericFailure(
		address token,
		address from,
		address to,
		uint256 identifier,
		uint256 amount
	);

	/**
	 * @dev Revert with an error when an ERC20 token transfer returns a falsey
	 *      value.
	 *
	 * @param token      The token for which the ERC20 transfer was attempted.
	 * @param from       The source of the attempted ERC20 transfer.
	 * @param to         The recipient of the attempted ERC20 transfer.
	 * @param amount     The amount for the attempted ERC20 transfer.
	 */
	error BadReturnValueFromERC20OnTransfer(
		address token,
		address from,
		address to,
		uint256 amount
	);

	/**
	 * @dev Revert with an error when an account being called as an assumed
	 *      contract does not have code and returns no data.
	 *
	 * @param account The account that should contain code.
	 */
	error NoContract(address account);

	/**
	@dev Revert if the {_to} callback is the same as the souce (address(this))
	*/
	error SelfCallbackTransfer();
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IERC20 {
	function totalSupply() external view returns (uint256);

	function balanceOf(address account) external view returns (uint256);

	function transfer(address recipient, uint256 amount) external returns (bool);

	function allowance(address owner, address spender) external view returns (uint256);

	function approve(address spender, uint256 amount) external returns (bool);

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool);

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IStableCoin {
	event EmergencyStopMintingCollateral(address indexed _asset, bool state);
	event MintBurnAccessChanged(address indexed _address, bool state);
	event TransferOwnership(address indexed newOwner);

	error NoAccess();
	error NotOwner();
	error MintingBlocked();

	function owner() external view returns (address);

	function setOwner(address _newOwner) external;

	function setMintBurnAccess(address _address, bool _status) external;

	function emergencyStopMinting(address _asset, bool _status) external;

	function mintDebt(
		address _asset,
		address _account,
		uint256 _amount
	) external;

	function mint(address _account, uint256 _amount) external;

	function burn(address _account, uint256 _amount) external;

	function isCollateralStopFromMinting(address _token) external view returns (bool);

	function hasMintAndBurnPermission(address _address) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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
pragma solidity ^0.8.7;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract StakeToken is ERC20 {
	address public minter;

	constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
		minter = msg.sender;
	}

	modifier onlyMinter() {
		require(minter == msg.sender);
		_;
	}

	function mint(address to, uint256 value) public onlyMinter returns (bool) {
		_mint(to, value);
		return true;
	}

	function burn(address to, uint256 value) public onlyMinter returns (bool) {
		_burn(to, value);
		return true;
	}
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import { TokenTransferrer } from "../../lib/token/TokenTransferrer.sol";
import "../../lib/VestaMath.sol";
import "../../BaseVesta.sol";
import "./StakingFarmModel.sol";
import "./IVstaStakingFarm.sol";
import "./StakeToken.sol";

contract VstaStakingFarm is IVstaStakingFarm, TokenTransferrer, BaseVesta {
	// user -> deposit token -> amount
	mapping(address => mapping(address => uint256)) private depositBalances;
	mapping(address => bool) private isDepositTokenLookup;
	address[] public depositTokens;
	address public esVSTA;

	// user -> reward token -> amount
	mapping(address => mapping(address => uint256)) private userRewardPerTokenPaid;
	mapping(address => mapping(address => uint256)) private rewards;
	mapping(address => Reward) private rewardData;
	mapping(address => bool) private isRewardAssetLookup;
	address[] public rewardTokens;

	mapping(address => uint256) private stakedAmount;
	uint256 public totalStakedAmount;
	StakeToken public stakeToken;

	modifier updateReward(address _account) {
		_updateReward(_account);
		_;
	}

	function _updateReward(address _account) internal {
		uint256 rewardTokensLength = rewardTokens.length;
		address token;
		for (uint256 i; i < rewardTokensLength; ++i) {
			token = rewardTokens[i];
			rewardData[token].rewardPerTokenStored = rewardPerToken(token);
			rewardData[token].lastUpdateTime = uint128(getLastTimeRewardApplicable(token));
			if (_account != address(0)) {
				rewards[_account][token] = earned(_account, token);
				userRewardPerTokenPaid[_account][token] = rewardData[token]
					.rewardPerTokenStored;
			}
		}
	}

	modifier ensureIsNotDepositToken(address _token) {
		if (isDepositTokenLookup[_token]) revert IsAlreadyDepositToken();
		_;
	}

	modifier ensureIsNotRewardAsset(address _token) {
		if (isRewardAssetLookup[_token]) revert IsAlreadyRewardAsset();
		_;
	}

	modifier ensureIsDepositToken(address _token) {
		if (!isDepositTokenLookup[_token]) revert IsNotDepositToken();
		_;
	}

	modifier ensureIsRewardAsset(address _token) {
		if (!isRewardAssetLookup[_token]) revert IsNotRewardAsset();
		_;
	}

	function setUp(
		string calldata _name,
		string calldata _symbol,
		address _esVSTA
	) external initializer {
		__BASE_VESTA_INIT();
		stakeToken = new StakeToken(_name, _symbol);
		esVSTA = _esVSTA;

		depositTokens.push(_esVSTA);
		isDepositTokenLookup[_esVSTA] = true;
	}

	function stake(address _depositToken, uint256 _amount)
		external
		override
		notZero(_amount)
		ensureIsDepositToken(_depositToken)
		updateReward(msg.sender)
	{
		stakedAmount[msg.sender] += _amount;
		depositBalances[msg.sender][_depositToken] += _amount;
		totalStakedAmount += _amount;

		_performTokenTransferFrom(
			_depositToken,
			msg.sender,
			address(this),
			_amount,
			false
		);

		if (_depositToken == esVSTA) stakeToken.mint(msg.sender, _amount);

		emit Staked(msg.sender, _depositToken, _amount);
	}

	function withdraw(address _depositToken, uint256 _amount)
		public
		override
		nonReentrant
		notZero(_amount)
		ensureIsDepositToken(_depositToken)
		updateReward(msg.sender)
	{
		stakedAmount[msg.sender] -= _amount;
		depositBalances[msg.sender][_depositToken] -= _amount;
		totalStakedAmount -= _amount;

		if (_depositToken == esVSTA) stakeToken.burn(msg.sender, _amount);

		_performTokenTransfer(_depositToken, msg.sender, _amount, false);

		emit Withdrawn(msg.sender, _depositToken, _amount);
	}

	function claimRewards() public override nonReentrant updateReward(msg.sender) {
		uint256 rewardTokensLength = rewardTokens.length;
		address rewardsToken;
		uint256 reward;
		for (uint256 i; i < rewardTokensLength; ++i) {
			rewardsToken = rewardTokens[i];
			reward = rewards[msg.sender][rewardsToken];
			if (reward > 0) {
				rewards[msg.sender][rewardsToken] = 0;
				_performTokenTransfer(rewardsToken, msg.sender, reward, false);
				emit RewardPaid(msg.sender, rewardsToken, reward);
			}
		}
	}

	function exit() external override {
		claimRewards();

		stakedAmount[msg.sender] = 0;

		uint256 depositTokensLength = depositTokens.length;
		address currentDepositToken;
		uint256 currentAmount;
		for (uint256 i; i < depositTokensLength; ++i) {
			currentDepositToken = depositTokens[i];
			currentAmount = depositBalances[msg.sender][currentDepositToken];

			if (currentAmount > 0) {
				if (currentDepositToken == esVSTA)
					stakeToken.burn(msg.sender, currentAmount);

				depositBalances[msg.sender][currentDepositToken] = 0;
				_performTokenTransfer(currentDepositToken, msg.sender, currentAmount, false);
				emit Withdrawn(msg.sender, currentDepositToken, currentAmount);
			}
		}
	}

	function addReward(address _rewardsToken, uint128 _rewardsDuration)
		public
		onlyOwner
		ensureIsNotRewardAsset(_rewardsToken)
	{
		rewardTokens.push(_rewardsToken);
		rewardData[_rewardsToken].rewardsDuration = _rewardsDuration;
		isRewardAssetLookup[_rewardsToken] = true;
	}

	function addDepositToken(address _depositToken)
		external
		onlyOwner
		ensureIsNotDepositToken(_depositToken)
	{
		depositTokens.push(_depositToken);
		isDepositTokenLookup[_depositToken] = true;
	}

	function notifyRewardAmount(address _rewardsToken, uint128 reward)
		external
		onlyOwner
		ensureIsRewardAsset(_rewardsToken)
		updateReward(address(0))
	{
		_performTokenTransferFrom(
			_rewardsToken,
			msg.sender,
			address(this),
			reward,
			false
		);

		Reward storage userRewardData = rewardData[_rewardsToken];

		if (block.timestamp >= userRewardData.periodFinish) {
			userRewardData.rewardRate = reward / userRewardData.rewardsDuration;
		} else {
			uint128 remaining = userRewardData.periodFinish - uint128(block.timestamp);
			uint128 leftover = remaining * userRewardData.rewardRate;
			userRewardData.rewardRate =
				(reward + leftover) /
				userRewardData.rewardsDuration;
		}

		userRewardData.lastUpdateTime = uint128(block.timestamp);
		userRewardData.periodFinish =
			uint128(block.timestamp) +
			userRewardData.rewardsDuration;

		emit RewardAdded(reward);
	}

	function recoverERC20(address _tokenAddress, uint256 _tokenAmount)
		external
		onlyOwner
		ensureIsNotDepositToken(_tokenAddress)
		ensureIsNotRewardAsset(_tokenAddress)
	{
		_performTokenTransfer(_tokenAddress, msg.sender, _tokenAmount, false);

		emit Recovered(_tokenAddress, _tokenAmount);
	}

	function setRewardsDuration(address _rewardsToken, uint128 _rewardsDuration)
		external
		notZero(_rewardsDuration)
		onlyOwner
	{
		Reward storage userRewardData = rewardData[_rewardsToken];

		if (block.timestamp <= userRewardData.periodFinish)
			revert RewardPeriodStillActive();

		userRewardData.rewardsDuration = _rewardsDuration;

		emit RewardsDurationUpdated(_rewardsToken, _rewardsDuration);
	}

	function getStakedAmount(address _account)
		external
		view
		override
		returns (uint256)
	{
		return stakedAmount[_account];
	}

	function isDepositToken(address _tokenAddress)
		external
		view
		override
		returns (bool)
	{
		return isDepositTokenLookup[_tokenAddress];
	}

	function isRewardAsset(address _tokenAddress)
		external
		view
		override
		returns (bool)
	{
		return isRewardAssetLookup[_tokenAddress];
	}

	function getRewardData(address _tokenAddress)
		external
		view
		override
		returns (Reward memory)
	{
		return rewardData[_tokenAddress];
	}

	function getDepositBalance(address _user, address _tokenAddress)
		external
		view
		override
		returns (uint256)
	{
		return depositBalances[_user][_tokenAddress];
	}

	function getUserRewards(address _user, address _tokenAddress)
		external
		view
		override
		returns (uint256)
	{
		return rewards[_user][_tokenAddress];
	}

	function getLastTimeRewardApplicable(address _rewardsToken)
		public
		view
		override
		returns (uint256)
	{
		return VestaMath.min(block.timestamp, rewardData[_rewardsToken].periodFinish);
	}

	function rewardPerToken(address _rewardsToken)
		public
		view
		override
		returns (uint256)
	{
		uint256 currentTotalStaked = totalStakedAmount;
		Reward memory tokenRewardData = rewardData[_rewardsToken];

		if (currentTotalStaked == 0) {
			return tokenRewardData.rewardPerTokenStored;
		}

		return
			tokenRewardData.rewardPerTokenStored +
			(((getLastTimeRewardApplicable(_rewardsToken) -
				tokenRewardData.lastUpdateTime) *
				tokenRewardData.rewardRate *
				1 ether) / currentTotalStaked);
	}

	function earned(address _account, address _rewardsToken)
		public
		view
		override
		returns (uint256)
	{
		return
			// prettier-ignore
			(rewardPerToken(_rewardsToken) - userRewardPerTokenPaid[_account][_rewardsToken]) 
			* stakedAmount[_account] 
			/ 1 ether 
			+ rewards[_account][_rewardsToken];
	}

	function getRewardForDuration(address _rewardsToken)
		external
		view
		override
		returns (uint256)
	{
		Reward memory userRewardData = rewardData[_rewardsToken];
		return userRewardData.rewardRate * userRewardData.rewardsDuration;
	}
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.0;

library VestaMath {
	uint256 internal constant DECIMAL_PRECISION = 1 ether;
	uint256 internal constant MINUTE_CAP = 525600000; // cap to avoid overflow

	/* Precision for Nominal ICR (independent of price). Rationale for the value:
	 *
	 * - Making it “too high” could lead to overflows.
	 * - Making it “too low” could lead to an ICR equal to zero, due to truncation from Solidity floor division.
	 *
	 * This value of 1e20 is chosen for safety: the NICR will only overflow for numerator > ~1e39 ETH,
	 * and will only truncate to 0 if the denominator is at least 1e20 times greater than the numerator.
	 *
	 */
	uint256 internal constant NICR_PRECISION = 1e20;

	function min(uint256 _a, uint256 _b) internal pure returns (uint256) {
		return (_a < _b) ? _a : _b;
	}

	function max(uint256 _a, uint256 _b) internal pure returns (uint256) {
		return (_a >= _b) ? _a : _b;
	}

	/*
	 * Multiply two decimal numbers and use normal rounding rules:
	 * -round product up if 19'th mantissa digit >= 5
	 * -round product down if 19'th mantissa digit < 5
	 *
	 * Used only inside the exponentiation, decPow().
	 */
	function decMul(uint256 x, uint256 y) internal pure returns (uint256 decProd) {
		return ((x * y) + (DECIMAL_PRECISION / 2)) / (DECIMAL_PRECISION);
	}

	/*
	 * decPow: Exponentiation function for 18-digit decimal base, and integer exponent n.
	 *
	 * Uses the efficient "exponentiation by squaring" algorithm. O(log(n)) complexity.
	 *
	 * Called by two functions that represent time in units of minutes:
	 * 1) TroveManager._calcDecayedBaseRate
	 * 2) CommunityIssuance._getCumulativeIssuanceFraction
	 *
	 * The exponent is capped to avoid reverting due to overflow. The cap 525600000 equals
	 * "minutes in 1000 years": 60 * 24 * 365 * 1000
	 *
	 * If a period of > 1000 years is ever used as an exponent in either of the above functions, the result will be
	 * negligibly different from just passing the cap, since:
	 *
	 * In function 1), the decayed base rate will be 0 for 1000 years or > 1000 years
	 * In function 2), the difference in tokens issued at 1000 years and any time > 1000 years, will be negligible
	 */
	function decPow(uint256 _base, uint256 _minutes) internal pure returns (uint256) {
		if (_minutes > MINUTE_CAP) {
			_minutes = MINUTE_CAP;
		}

		if (_minutes == 0) {
			return DECIMAL_PRECISION;
		}

		uint256 y = DECIMAL_PRECISION;
		uint256 x = _base;
		uint256 n = _minutes;

		// Exponentiation-by-squaring
		while (n > 1) {
			if (n % 2 == 0) {
				x = decMul(x, x);
				n /= 2;
			} else {
				y = decMul(x, y);
				x = decMul(x, x);
				n = (n - 1) / 2;
			}
		}

		return decMul(x, y);
	}

	function getAbsoluteDifference(uint256 _a, uint256 _b)
		internal
		pure
		returns (uint256)
	{
		return (_a >= _b) ? (_a - _b) : (_b - _a);
	}

	function computeNominalCR(uint256 _coll, uint256 _debt)
		internal
		pure
		returns (uint256)
	{
		if (_debt > 0) {
			return mulDiv(_coll, NICR_PRECISION, _debt);
		} else {
			return type(uint256).max;
		}
	}

	function computeCR(
		uint256 _coll,
		uint256 _debt,
		uint256 _price
	) internal pure returns (uint256) {
		if (_debt > 0) {
			return mulDiv(_coll, _price, _debt);
		} else {
			return type(uint256).max;
		}
	}

	/// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
	/// @param a The multiplicand
	/// @param b The multiplier
	/// @param denominator The divisor
	/// @return result The 256-bit result
	/// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
	function mulDiv(
		uint256 a,
		uint256 b,
		uint256 denominator
	) internal pure returns (uint256 result) {
		unchecked {
			// 512-bit multiply [prod1 prod0] = a * b
			// Compute the product mod 2**256 and mod 2**256 - 1
			// then use the Chinese Remainder Theorem to reconstruct
			// the 512 bit result. The result is stored in two 256
			// variables such that product = prod1 * 2**256 + prod0
			uint256 prod0; // Least significant 256 bits of the product
			uint256 prod1; // Most significant 256 bits of the product
			assembly {
				let mm := mulmod(a, b, not(0))
				prod0 := mul(a, b)
				prod1 := sub(sub(mm, prod0), lt(mm, prod0))
			}

			// Handle non-overflow cases, 256 by 256 division
			if (prod1 == 0) {
				require(denominator > 0);
				assembly {
					result := div(prod0, denominator)
				}
				return result;
			}

			// Make sure the result is less than 2**256.
			// Also prevents denominator == 0
			require(denominator > prod1);

			///////////////////////////////////////////////
			// 512 by 256 division.
			///////////////////////////////////////////////

			// Make division exact by subtracting the remainder from [prod1 prod0]
			// Compute remainder using mulmod
			uint256 remainder;
			assembly {
				remainder := mulmod(a, b, denominator)
			}
			// Subtract 256 bit number from 512 bit number
			assembly {
				prod1 := sub(prod1, gt(remainder, prod0))
				prod0 := sub(prod0, remainder)
			}

			// Factor powers of two out of denominator
			// Compute largest power of two divisor of denominator.
			// Always >= 1.
			uint256 twos = (type(uint256).max - denominator + 1) & denominator;
			// Divide denominator by power of two
			assembly {
				denominator := div(denominator, twos)
			}

			// Divide [prod1 prod0] by the factors of two
			assembly {
				prod0 := div(prod0, twos)
			}
			// Shift in bits from prod1 into prod0. For this we need
			// to flip `twos` such that it is 2**256 / twos.
			// If twos is zero, then it becomes one
			assembly {
				twos := add(div(sub(0, twos), twos), 1)
			}
			prod0 |= prod1 * twos;

			// Invert denominator mod 2**256
			// Now that denominator is an odd number, it has an inverse
			// modulo 2**256 such that denominator * inv = 1 mod 2**256.
			// Compute the inverse by starting with a seed that is correct
			// correct for four bits. That is, denominator * inv = 1 mod 2**4
			uint256 inv = (3 * denominator) ^ 2;
			// Now use Newton-Raphson iteration to improve the precision.
			// Thanks to Hensel's lifting lemma, this also works in modular
			// arithmetic, doubling the correct bits in each step.
			inv *= 2 - denominator * inv; // inverse mod 2**8
			inv *= 2 - denominator * inv; // inverse mod 2**16
			inv *= 2 - denominator * inv; // inverse mod 2**32
			inv *= 2 - denominator * inv; // inverse mod 2**64
			inv *= 2 - denominator * inv; // inverse mod 2**128
			inv *= 2 - denominator * inv; // inverse mod 2**256

			// Because the division is now exact we can divide by multiplying
			// with the modular inverse of denominator. This will give us the
			// correct result modulo 2**256. Since the precoditions guarantee
			// that the outcome is less than 2**256, this is the final result.
			// We don't need to compute the high bits of the result and prod1
			// is no longer required.
			result = prod0 * inv;
			return result;
		}
	}

	/// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
	/// @param a The multiplicand
	/// @param b The multiplier
	/// @param denominator The divisor
	/// @return result The 256-bit result
	function mulDivRoundingUp(
		uint256 a,
		uint256 b,
		uint256 denominator
	) internal pure returns (uint256 result) {
		result = mulDiv(a, b, denominator);
		unchecked {
			if (mulmod(a, b, denominator) > 0) {
				require(result < type(uint256).max);
				result++;
			}
		}
	}
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.0;

struct Reward {
	uint128 rewardsDuration;
	uint128 periodFinish;
	uint128 rewardRate;
	uint128 lastUpdateTime;
	uint256 rewardPerTokenStored;
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "./StakingFarmModel.sol";

interface IVstaStakingFarm {
	error IsAlreadyRewardAsset();
	error IsAlreadyDepositToken();
	error IsNotRewardAsset();
	error IsNotDepositToken();
	error RewardPeriodStillActive();

	event RewardAdded(uint256 _reward);
	event Staked(
		address indexed _user,
		address indexed _depositAsset,
		uint256 _amount
	);
	event Withdrawn(
		address indexed _user,
		address indexed _depositAsset,
		uint256 _amount
	);
	event RewardPaid(
		address indexed _user,
		address indexed _rewardsToken,
		uint256 _reward
	);
	event RewardsDurationUpdated(address _token, uint256 _newDuration);
	event Recovered(address _token, uint256 _amount);

	function stake(address _depositToken, uint256 _amount) external;

	function withdraw(address _depositToken, uint256 _amount) external;

	function claimRewards() external;

	function exit() external;

	function getStakedAmount(address account) external view returns (uint256);

	function isDepositToken(address _tokenAddress) external view returns (bool);

	function isRewardAsset(address _tokenAddress) external view returns (bool);

	function getRewardData(address _tokenAddress)
		external
		view
		returns (Reward memory);

	function getDepositBalance(address _user, address _tokenAddress)
		external
		view
		returns (uint256);

	function getUserRewards(address _user, address _tokenAddress)
		external
		view
		returns (uint256);

	function getLastTimeRewardApplicable(address _rewardsToken)
		external
		view
		returns (uint256);

	function rewardPerToken(address _rewardsToken) external view returns (uint256);

	function earned(address account, address _rewardsToken)
		external
		view
		returns (uint256);

	function getRewardForDuration(address _rewardsToken)
		external
		view
		returns (uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import { TokenTransferrer } from "../../lib/token/TokenTransferrer.sol";
import "../../lib/VestaMath.sol";
import "../../BaseVesta.sol";
import "./StakingFarmModel.sol";
import "./IMultiRewardsStaking.sol";
import "./StakeToken.sol";

contract MultiRewardsStaking is IMultiRewardsStaking, TokenTransferrer, BaseVesta {
	address public depositToken;
	StakeToken public stakeToken;

	// user -> reward token -> amount
	mapping(address => mapping(address => uint256)) private userRewardPerTokenPaid;
	mapping(address => mapping(address => uint256)) private rewards;
	mapping(address => Reward) private rewardData;
	mapping(address => bool) private isRewardAssetLookup;
	address[] public rewardTokens;

	mapping(address => uint256) private stakedAmount;
	uint256 public totalStakedAmount;

	modifier updateReward(address _account) {
		_updateReward(_account);
		_;
	}

	function _updateReward(address _account) internal {
		uint256 rewardTokensLength = rewardTokens.length;
		address token;
		for (uint256 i; i < rewardTokensLength; ++i) {
			token = rewardTokens[i];
			rewardData[token].rewardPerTokenStored = rewardPerToken(token);
			rewardData[token].lastUpdateTime = uint128(getLastTimeRewardApplicable(token));
			if (_account != address(0)) {
				rewards[_account][token] = earned(_account, token);
				userRewardPerTokenPaid[_account][token] = rewardData[token]
					.rewardPerTokenStored;
			}
		}
	}

	modifier ensureIsNotDepositToken(address _token) {
		if (_token == depositToken) revert IsAlreadyDepositToken();
		_;
	}

	modifier ensureIsNotRewardAsset(address _token) {
		if (isRewardAssetLookup[_token]) revert IsAlreadyRewardAsset();
		_;
	}

	modifier ensureIsRewardAsset(address _token) {
		if (!isRewardAssetLookup[_token]) revert IsNotRewardAsset();
		_;
	}

	function setUp(
		string calldata _name,
		string calldata _symbol,
		address _depositToken
	) external initializer {
		__BASE_VESTA_INIT();
		stakeToken = new StakeToken(_name, _symbol);
		depositToken = _depositToken;
	}

	function stake(uint256 _amount)
		external
		override
		notZero(_amount)
		updateReward(msg.sender)
	{
		stakedAmount[msg.sender] += _amount;

		totalStakedAmount += _amount;

		_performTokenTransferFrom(
			depositToken,
			msg.sender,
			address(this),
			_amount,
			false
		);

		stakeToken.mint(msg.sender, _amount);

		emit Staked(msg.sender, _amount);
	}

	function withdraw(uint256 _amount)
		public
		override
		nonReentrant
		notZero(_amount)
		updateReward(msg.sender)
	{
		stakedAmount[msg.sender] -= _amount;

		totalStakedAmount -= _amount;

		stakeToken.burn(msg.sender, _amount);

		_performTokenTransfer(depositToken, msg.sender, _amount, false);

		emit Withdrawn(msg.sender, _amount);
	}

	function claimRewards() public override nonReentrant updateReward(msg.sender) {
		uint256 rewardTokensLength = rewardTokens.length;
		address rewardsToken;
		uint256 reward;
		for (uint256 i; i < rewardTokensLength; ++i) {
			rewardsToken = rewardTokens[i];
			reward = rewards[msg.sender][rewardsToken];
			if (reward > 0) {
				rewards[msg.sender][rewardsToken] = 0;
				_performTokenTransfer(rewardsToken, msg.sender, reward, false);
				emit RewardPaid(msg.sender, rewardsToken, reward);
			}
		}
	}

	function exit() external override {
		withdraw(stakedAmount[msg.sender]);
		claimRewards();
	}

	function addReward(address _rewardsToken, uint128 _rewardsDuration)
		public
		onlyOwner
		ensureIsNotRewardAsset(_rewardsToken)
	{
		rewardTokens.push(_rewardsToken);
		rewardData[_rewardsToken].rewardsDuration = _rewardsDuration;
		isRewardAssetLookup[_rewardsToken] = true;
	}

	function notifyRewardAmount(address _rewardsToken, uint128 reward)
		external
		onlyOwner
		ensureIsRewardAsset(_rewardsToken)
		updateReward(address(0))
	{
		_performTokenTransferFrom(
			_rewardsToken,
			msg.sender,
			address(this),
			reward,
			false
		);

		Reward storage userRewardData = rewardData[_rewardsToken];

		if (block.timestamp >= userRewardData.periodFinish) {
			userRewardData.rewardRate = reward / userRewardData.rewardsDuration;
		} else {
			uint128 remaining = userRewardData.periodFinish - uint128(block.timestamp);
			uint128 leftover = remaining * userRewardData.rewardRate;
			userRewardData.rewardRate =
				(reward + leftover) /
				userRewardData.rewardsDuration;
		}

		userRewardData.lastUpdateTime = uint128(block.timestamp);
		userRewardData.periodFinish =
			uint128(block.timestamp) +
			userRewardData.rewardsDuration;

		emit RewardAdded(reward);
	}

	function recoverERC20(address _tokenAddress, uint256 _tokenAmount)
		external
		onlyOwner
		ensureIsNotRewardAsset(_tokenAddress)
		ensureIsNotDepositToken(_tokenAddress)
	{
		_performTokenTransfer(_tokenAddress, msg.sender, _tokenAmount, false);

		emit Recovered(_tokenAddress, _tokenAmount);
	}

	function setRewardsDuration(address _rewardsToken, uint128 _rewardsDuration)
		external
		notZero(_rewardsDuration)
		onlyOwner
	{
		Reward storage userRewardData = rewardData[_rewardsToken];

		if (block.timestamp <= userRewardData.periodFinish)
			revert RewardPeriodStillActive();

		userRewardData.rewardsDuration = _rewardsDuration;

		emit RewardsDurationUpdated(_rewardsToken, _rewardsDuration);
	}

	function getStakedAmount(address _account)
		external
		view
		override
		returns (uint256)
	{
		return stakedAmount[_account];
	}

	function isRewardAsset(address _tokenAddress)
		external
		view
		override
		returns (bool)
	{
		return isRewardAssetLookup[_tokenAddress];
	}

	function getRewardData(address _tokenAddress)
		external
		view
		override
		returns (Reward memory)
	{
		return rewardData[_tokenAddress];
	}

	function getUserRewards(address _user, address _tokenAddress)
		external
		view
		override
		returns (uint256)
	{
		return rewards[_user][_tokenAddress];
	}

	function getLastTimeRewardApplicable(address _rewardsToken)
		public
		view
		override
		returns (uint256)
	{
		return VestaMath.min(block.timestamp, rewardData[_rewardsToken].periodFinish);
	}

	function rewardPerToken(address _rewardsToken)
		public
		view
		override
		returns (uint256)
	{
		uint256 currentTotalSupply = totalStakedAmount;
		Reward memory tokenRewardData = rewardData[_rewardsToken];

		if (currentTotalSupply == 0) {
			return tokenRewardData.rewardPerTokenStored;
		}

		return
			tokenRewardData.rewardPerTokenStored +
			(((getLastTimeRewardApplicable(_rewardsToken) -
				tokenRewardData.lastUpdateTime) *
				tokenRewardData.rewardRate *
				1 ether) / currentTotalSupply);
	}

	function earned(address _account, address _rewardsToken)
		public
		view
		override
		returns (uint256)
	{
		return
			// prettier-ignore
			(rewardPerToken(_rewardsToken) - userRewardPerTokenPaid[_account][_rewardsToken]) 
			* stakedAmount[_account] 
			/ 1 ether 
			+ rewards[_account][_rewardsToken];
	}

	function getRewardForDuration(address _rewardsToken)
		external
		view
		override
		returns (uint256)
	{
		Reward memory userRewardData = rewardData[_rewardsToken];
		return userRewardData.rewardRate * userRewardData.rewardsDuration;
	}
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "./StakingFarmModel.sol";

interface IMultiRewardsStaking {
	error IsAlreadyDepositToken();
	error IsAlreadyRewardAsset();
	error IsNotRewardAsset();
	error RewardPeriodStillActive();

	event RewardAdded(uint256 _reward);
	event Staked(address indexed _user, uint256 _amount);
	event Withdrawn(address indexed _user, uint256 _amount);
	event RewardPaid(
		address indexed _user,
		address indexed _rewardsToken,
		uint256 _reward
	);
	event RewardsDurationUpdated(address _token, uint256 _newDuration);
	event Recovered(address _token, uint256 _amount);

	function stake(uint256 _amount) external;

	function withdraw(uint256 _amount) external;

	function claimRewards() external;

	function exit() external;

	function getStakedAmount(address account) external view returns (uint256);

	function isRewardAsset(address _tokenAddress) external view returns (bool);

	function getRewardData(address _tokenAddress)
		external
		view
		returns (Reward memory);

	function getUserRewards(address _user, address _tokenAddress)
		external
		view
		returns (uint256);

	function getLastTimeRewardApplicable(address _rewardsToken)
		external
		view
		returns (uint256);

	function rewardPerToken(address _rewardsToken) external view returns (uint256);

	function earned(address account, address _rewardsToken)
		external
		view
		returns (uint256);

	function getRewardForDuration(address _rewardsToken)
		external
		view
		returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import { TokenTransferrer } from "../../lib/token/TokenTransferrer.sol";
import "../../lib/VestaMath.sol";
import "./EsVSTAModel.sol";
import "./IEsVSTA.sol";

contract EsVSTA is ERC20Upgradeable, OwnableUpgradeable, TokenTransferrer, IEsVSTA {
	address public vstaToken;
	uint128 public vestingDuration;

	mapping(address => bool) private isHandler;
	mapping(address => VestingDetails) private vestingDetails;

	function setUp(address _vsta, uint128 _vestingDuration) external initializer {
		__Ownable_init();
		__ERC20_init("Escrowed VSTA", "EsVSTA");
		vstaToken = _vsta;
		vestingDuration = _vestingDuration;
	}

	modifier validateHandler() {
		if (!isHandler[msg.sender]) revert Unauthorized();
		_;
	}

	function transfer(address to, uint256 amount)
		public
		override
		validateHandler
		returns (bool)
	{
		address owner = _msgSender();
		_transfer(owner, to, amount);
		return true;
	}

	function transferFrom(
		address from,
		address to,
		uint256 amount
	) public override validateHandler returns (bool) {
		address spender = _msgSender();
		_spendAllowance(from, spender, amount);
		_transfer(from, to, amount);
		return true;
	}

	function convertVSTAToEsVSTA(uint128 _amount) external override validateHandler {
		_performTokenTransferFrom(vstaToken, msg.sender, address(this), _amount, false);
		_mint(msg.sender, _amount);
		emit EsVSTAMinted(_amount);
	}

	function vestEsVSTA(uint128 _amount) external override {
		VestingDetails storage userVestingDetails = vestingDetails[msg.sender];

		if (userVestingDetails.amount > 0) {
			claimVSTA();
		}

		userVestingDetails.amount += _amount;
		userVestingDetails.startDate = uint128(block.timestamp);
		userVestingDetails.duration = vestingDuration;

		_burn(msg.sender, _amount);

		emit UpdateVestingDetails(msg.sender, _amount, block.timestamp, vestingDuration);
	}

	function claimVSTA() public override {
		VestingDetails memory userVestingDetails = vestingDetails[msg.sender];

		uint128 timeVested = uint128(block.timestamp) - userVestingDetails.startDate;
		uint128 amountClaimable;

		if (timeVested < userVestingDetails.duration) {
			uint128 currentEntitledAmount = uint128(
				VestaMath.mulDiv(
					userVestingDetails.amount,
					timeVested,
					userVestingDetails.duration
				)
			);

			amountClaimable = currentEntitledAmount - userVestingDetails.amountClaimed;

			vestingDetails[msg.sender].amountClaimed = currentEntitledAmount;
		} else {
			amountClaimable = userVestingDetails.amount - userVestingDetails.amountClaimed;

			vestingDetails[msg.sender].amountClaimed = 0;
			vestingDetails[msg.sender].amount = 0;

			emit FinishVesting(msg.sender);
		}

		if (amountClaimable > 0) {
			_performTokenTransfer(vstaToken, msg.sender, amountClaimable, false);

			emit ClaimVSTA(msg.sender, amountClaimable);
		}
	}

	function setHandler(address _handler, bool _isActive) external override onlyOwner {
		isHandler[_handler] = _isActive;
	}

	function setVestingDuration(uint128 _vestingDuration) external override onlyOwner {
		vestingDuration = _vestingDuration;
	}

	function claimableVSTA()
		external
		view
		override
		returns (uint256 amountClaimable_)
	{
		VestingDetails memory userVestingDetails = vestingDetails[msg.sender];

		uint256 timeVested = block.timestamp - userVestingDetails.startDate;

		if (timeVested < userVestingDetails.duration) {
			uint256 currentEntitledAmount = (userVestingDetails.amount * timeVested) /
				userVestingDetails.duration;

			amountClaimable_ = currentEntitledAmount - userVestingDetails.amountClaimed;
		} else {
			amountClaimable_ =
				userVestingDetails.amount -
				userVestingDetails.amountClaimed;
		}
	}

	function getIsHandler(address _user) external view returns (bool) {
		return isHandler[_user];
	}

	function getVestingDetails(address _user)
		external
		view
		override
		returns (VestingDetails memory)
	{
		return vestingDetails[_user];
	}

	function getUserVestedAmount(address _user)
		external
		view
		override
		returns (uint256)
	{
		return vestingDetails[_user].amount;
	}

	function getUserVestedAmountClaimed(address _user)
		external
		view
		override
		returns (uint256)
	{
		return vestingDetails[_user].amountClaimed;
	}

	function getUserVestingStartDate(address _user)
		external
		view
		override
		returns (uint128)
	{
		return vestingDetails[_user].startDate;
	}

	function getUserVestingDuration(address _user)
		external
		view
		override
		returns (uint128)
	{
		return vestingDetails[_user].duration;
	}
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.0;

struct VestingDetails {
	uint128 amount;
	uint128 amountClaimed;
	uint128 startDate;
	uint128 duration;
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.0;

import "./EsVSTAModel.sol";

interface IEsVSTA {
	error Unauthorized();

	event EsVSTAMinted(uint256 _amount);
	event UpdateVestingDetails(
		address indexed _user,
		uint256 _amountAdded,
		uint256 startDate,
		uint256 duration
	);
	event FinishVesting(address indexed _user);
	event ClaimVSTA(address indexed _user, uint256 _amount);

	function setHandler(address _handler, bool _isActive) external;

	function setVestingDuration(uint128 _vestingDuration) external;

	function convertVSTAToEsVSTA(uint128 _amount) external;

	function vestEsVSTA(uint128 _amount) external;

	function claimVSTA() external;

	function claimableVSTA() external view returns (uint256 amountClaimable_);

	function getVestingDetails(address _user)
		external
		view
		returns (VestingDetails memory);

	function getUserVestedAmount(address _user) external view returns (uint256);

	function getUserVestedAmountClaimed(address _user) external view returns (uint256);

	function getUserVestingStartDate(address _user) external view returns (uint128);

	function getUserVestingDuration(address _user) external view returns (uint128);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

import "../../BaseVesta.sol";
import { TokenTransferrer } from "../../lib/token/TokenTransferrer.sol";
import "../../lib/VestaMath.sol";
import "./IStabilityPool.sol";
import "./StabilityPoolModel.sol";
import "./ICommunityIssuance.sol";
import "../../IStableCoin.sol";

contract StabilityPool is IStabilityPool, TokenTransferrer, BaseVesta {
	bytes1 public constant LENDING = 0x01;
	uint256 public constant DECIMAL_PRECISION = 1 ether;

	ICommunityIssuance public communityIssuance;
	address public VST;

	mapping(address => uint256) internal deposits; // depositor address -> amount
	mapping(address => Snapshots) internal depositSnapshots; // depositor address -> snapshot
	mapping(uint256 => address) internal assetAddresses;
	mapping(address => uint256) internal assetBalances;
	mapping(address => bool) internal isStabilityPoolAsset;

	uint256 public numberOfAssets;
	uint256 public totalVSTDeposits;

	/*  Product 'P': Running product by which to multiply an initial deposit, in order to find the current compounded deposit,
	 * after a series of liquidations have occurred, each of which cancel some VST debt with the deposit.
	 *
	 * During its lifetime, a deposit's value evolves from d_t to d_t * P / P_t , where P_t
	 * is the snapshot of P taken at the instant the deposit was made. 18-digit decimal.
	 */
	uint256 public P;

	uint256 public constant SCALE_FACTOR = 1e9;

	// Each time the scale of P shifts by SCALE_FACTOR, the scale is incremented by 1
	uint128 public currentScale;

	// With each offset that fully empties the Pool, the epoch is incremented by 1
	uint128 public currentEpoch;

	/* ETH Gain sum 'S': During its lifetime, each deposit d_t earns an ETH gain of ( d_t * [S - S_t] )/P_t, where S_t
	 * is the depositor's snapshot of S taken at the time t when the deposit was made.
	 *
	 * The 'S' sums are stored in a nested mapping (epoch => scale => sum):
	 *
	 * - The inner mapping records the sum S at different scales
	 * - The outer mapping records the (scale => sum) mappings, for different epochs.
	 */
	mapping(address => mapping(uint128 => mapping(uint128 => uint256)))
		internal epochToScaleToSum;

	/*
	 * Similarly, the sum 'G' is used to calculate VSTA gains. During it's lifetime, each deposit d_t earns a VSTA gain of
	 *  ( d_t * [G - G_t] )/P_t, where G_t is the depositor's snapshot of G taken at time t when  the deposit was made.
	 *
	 *  VSTA reward events occur are triggered by depositor operations (new deposit, topup, withdrawal), and liquidations.
	 *  In each case, the VSTA reward is issued (i.e. G is updated), before other state changes are made.
	 */
	mapping(address => mapping(uint128 => mapping(uint128 => uint256)))
		internal epochToScaleToG;

	// Error tracker for the error correction in the VSTA issuance calculation
	mapping(address => uint256) internal lastRewardError;
	// Error trackers for the error correction in the offset calculation
	mapping(address => uint256) internal lastAssetError_Offset;
	uint256 public lastVSTLossError_Offset;

	modifier ensureNotPoolAsset(address _asset) {
		if (isStabilityPoolAsset[_asset]) revert IsAlreadyPoolAsset();
		_;
	}

	modifier ensureIsPoolAsset(address _asset) {
		if (!isStabilityPoolAsset[_asset]) revert IsNotPoolAsset();
		_;
	}

	function setUp(
		address _lendingAddress,
		address _communityIssuanceAddress,
		address _vst
	)
		external
		initializer
		onlyContracts(_lendingAddress, _communityIssuanceAddress)
		onlyContract(_vst)
	{
		__BASE_VESTA_INIT();

		communityIssuance = ICommunityIssuance(_communityIssuanceAddress);
		VST = _vst;
		_setPermission(_lendingAddress, LENDING);
		P = DECIMAL_PRECISION;
	}

	function addAsset(address _asset)
		external
		override
		onlyOwner
		ensureNotPoolAsset(_asset)
	{
		isStabilityPoolAsset[_asset] = true;
		assetAddresses[numberOfAssets] = _asset;
		++numberOfAssets;

		emit AssetAddedToStabilityPool(_asset);
	}

	function provideToSP(uint256 _amount)
		external
		override
		nonReentrant
		notZero(_amount)
	{
		_triggerRewardsIssuance();
		_payOutRewardGains();

		_payOutDepositorAssetGains();

		uint256 compoundedVSTDeposit = getCompoundedVSTDeposit(msg.sender);
		_announceVSTLoss(compoundedVSTDeposit);

		_updateDepositAndSnapshots(msg.sender, compoundedVSTDeposit + _amount);

		_sendVSTtoStabilityPool(msg.sender, _amount);
	}

	/*  withdrawFromSP():
	 *
	 * - Triggers a VSTA issuance, based on time passed since the last issuance. The VSTA issuance is shared between *all* depositors
	 * - Sends all depositor's accumulated gains (VSTA, ETH) to depositor
	 * - Decreases deposit and system stake, and takes new snapshots for each.
	 *
	 * If _amount > userDeposit, the user withdraws all of their compounded deposit.
	 */
	function withdrawFromSP(uint256 _amount) external override nonReentrant {
		_triggerRewardsIssuance();
		_payOutRewardGains();

		_payOutDepositorAssetGains();

		uint256 compoundedVSTDeposit = getCompoundedVSTDeposit(msg.sender);
		_announceVSTLoss(compoundedVSTDeposit);

		uint256 VSTtoWithdraw = VestaMath.min(_amount, compoundedVSTDeposit);
		_updateDepositAndSnapshots(msg.sender, compoundedVSTDeposit - VSTtoWithdraw);

		_sendVSTToDepositor(msg.sender, VSTtoWithdraw);
	}

	//TODO VFS-91
	/*
	 * Cancels out the specified debt against the VST contained in the Stability Pool (as far as possible)
	 * and transfers the Trove's ETH collateral from ActivePool to StabilityPool.
	 * Only called by liquidation functions in the TroveManager.
	 */
	function offset(
		address _asset,
		uint256 _debtToOffset,
		uint256 _collToAdd
	) external override hasPermissionOrOwner(LENDING) ensureIsPoolAsset(_asset) {
		uint256 totalVST = totalVSTDeposits;
		if (totalVST == 0 || _debtToOffset == 0) {
			return;
		}

		_triggerRewardsIssuance();

		(
			uint256 AssetGainPerUnitStaked,
			uint256 VSTLossPerUnitStaked
		) = _computeRewardsPerUnitStaked(_asset, _collToAdd, _debtToOffset, totalVST);

		_updateRewardSumAndProduct(_asset, AssetGainPerUnitStaked, VSTLossPerUnitStaked);

		_moveOffsetCollAndDebt(_asset, _collToAdd, _debtToOffset);
	}

	/*
	 * Compute the VST and ETH rewards. Uses a "feedback" error correction, to keep
	 * the cumulative error in the P and S state variables low:
	 *
	 * 1) Form numerators which compensate for the floor division errors that occurred the last time this
	 * function was called.
	 * 2) Calculate "per-unit-staked" ratios.
	 * 3) Multiply each ratio back by its denominator, to reveal the current floor division error.
	 * 4) Store these errors for use in the next correction when this function is called.
	 * 5) Note: static analysis tools complain about this "division before multiplication", however, it is intended.
	 */
	function _computeRewardsPerUnitStaked(
		address _asset,
		uint256 _collToAdd,
		uint256 _debtToOffset,
		uint256 _totalVSTDeposits
	)
		internal
		returns (uint256 assetGainPerUnitStaked_, uint256 vstLossPerUnitStaked_)
	{
		uint256 AssetNumerator = _collToAdd *
			DECIMAL_PRECISION +
			lastAssetError_Offset[_asset];

		assert(_debtToOffset <= _totalVSTDeposits);

		if (_debtToOffset == _totalVSTDeposits) {
			vstLossPerUnitStaked_ = DECIMAL_PRECISION; // When the Pool depletes to 0, so does each deposit
			lastVSTLossError_Offset = 0;
		} else {
			uint256 VSTLossNumerator = _debtToOffset *
				DECIMAL_PRECISION -
				lastVSTLossError_Offset;
			/*
			 * Add 1 to make error in quotient positive. We want "slightly too much" VST loss,
			 * which ensures the error in any given compoundedVSTDeposit favors the Stability Pool.
			 */
			vstLossPerUnitStaked_ = VSTLossNumerator / _totalVSTDeposits + 1;
			lastVSTLossError_Offset =
				vstLossPerUnitStaked_ *
				_totalVSTDeposits -
				VSTLossNumerator;
		}

		assetGainPerUnitStaked_ = AssetNumerator / _totalVSTDeposits;
		lastAssetError_Offset[_asset] =
			AssetNumerator -
			(assetGainPerUnitStaked_ * _totalVSTDeposits);

		return (assetGainPerUnitStaked_, vstLossPerUnitStaked_);
	}

	// Update the Stability Pool reward sum S and product P
	function _updateRewardSumAndProduct(
		address _asset,
		uint256 _AssetGainPerUnitStaked,
		uint256 _VSTLossPerUnitStaked
	) internal {
		uint256 currentP = P;
		uint256 newP;

		assert(_VSTLossPerUnitStaked <= DECIMAL_PRECISION);
		/*
		 * The newProductFactor is the factor by which to change all deposits, due to the depletion of Stability Pool VST in the liquidation.
		 * We make the product factor 0 if there was a pool-emptying. Otherwise, it is (1 - VSTLossPerUnitStaked)
		 */
		uint256 newProductFactor = uint256(DECIMAL_PRECISION) - _VSTLossPerUnitStaked;

		uint128 currentScaleCached = currentScale;
		uint128 currentEpochCached = currentEpoch;
		uint256 currentS = epochToScaleToSum[_asset][currentEpochCached][
			currentScaleCached
		];

		/*
		 * Calculate the new S first, before we update P.
		 * The ETH gain for any given depositor from a liquidation depends on the value of their deposit
		 * (and the value of totalDeposits) prior to the Stability being depleted by the debt in the liquidation.
		 *
		 * Since S corresponds to ETH gain, and P to deposit loss, we update S first.
		 */
		uint256 marginalAssetGain = _AssetGainPerUnitStaked * currentP;
		uint256 newS = currentS + marginalAssetGain;
		epochToScaleToSum[_asset][currentEpochCached][currentScaleCached] = newS;
		emit S_Updated(_asset, newS, currentEpochCached, currentScaleCached);

		// If the Stability Pool was emptied, increment the epoch, and reset the scale and product P
		if (newProductFactor == 0) {
			currentEpoch = currentEpochCached + 1;
			emit EpochUpdated(currentEpoch);
			currentScale = 0;
			emit ScaleUpdated(currentScale);
			newP = DECIMAL_PRECISION;

			// If multiplying P by a non-zero product factor would reduce P below the scale boundary, increment the scale
		} else if ((currentP * newProductFactor) / DECIMAL_PRECISION < SCALE_FACTOR) {
			newP = (currentP * newProductFactor * SCALE_FACTOR) / DECIMAL_PRECISION;
			currentScale = currentScaleCached + 1;
			emit ScaleUpdated(currentScale);
		} else {
			newP = (currentP * newProductFactor) / DECIMAL_PRECISION;
		}

		assert(newP > 0);
		P = newP;

		emit P_Updated(newP);
	}

	function _moveOffsetCollAndDebt(
		address _asset,
		uint256 _collToAdd,
		uint256 _debtToOffset
	) internal {
		// Call lending to cancel the debt
		_decreaseVST(_debtToOffset);

		// add to balance
		assetBalances[_asset] += _collToAdd;

		// burn vst
		IStableCoin(VST).burn(address(this), _debtToOffset);

		// send assets from lending to this address
		if (_asset == address(0)) {
			// send through payable in tests. In production will call function from LENDING instead.
			return;
		} else {
			_performTokenTransferFrom(
				_asset,
				msg.sender,
				address(this),
				_collToAdd,
				false
			);
		}
	}

	function _triggerRewardsIssuance() internal {
		(address[] memory assets, uint256[] memory issuanceAmounts) = communityIssuance
			.issueAssets();
		_updateG(assets, issuanceAmounts);
	}

	function _updateG(
		address[] memory _assetAddresses,
		uint256[] memory _issuanceAmounts
	) internal {
		address[] memory cachedAssetAddresses = _assetAddresses;
		uint256[] memory cachedIssuanceAmounts = _issuanceAmounts;

		uint256 totalVST = totalVSTDeposits;
		/*
		 * When total deposits is 0, G is not updated. In this case, the VSTA issued can not be obtained by later
		 * depositors - it is missed out on, and remains in the balanceof the CommunityIssuance contract.
		 *
		 */
		if (totalVST == 0) {
			return;
		}

		uint256 addressLength = cachedAssetAddresses.length;
		for (uint256 i = 0; i < addressLength; ++i) {
			if (cachedIssuanceAmounts[i] > 0) {
				address assetAddress = cachedAssetAddresses[i];
				uint256 perUnitStaked = _computeRewardTokenPerUnitStaked(
					assetAddress,
					cachedIssuanceAmounts[i],
					totalVST
				);

				uint256 newEpochToScaleToG = epochToScaleToG[assetAddress][currentEpoch][
					currentScale
				] += (perUnitStaked * P);

				emit G_Updated(
					assetAddresses[i],
					newEpochToScaleToG,
					currentEpoch,
					currentScale
				);
			}
		}
	}

	function _computeRewardTokenPerUnitStaked(
		address _asset,
		uint256 _issuance,
		uint256 _totalVSTDeposits
	) internal returns (uint256 _vSTAPerUnitStaked) {
		/*
		 * Calculate the VSTA-per-unit staked.  Division uses a "feedback" error correction, to keep the
		 * cumulative error low in the running total G:
		 *
		 * 1) Form a numerator which compensates for the floor division error that occurred the last time this
		 * function was called.
		 * 2) Calculate "per-unit-staked" ratio.
		 * 3) Multiply the ratio back by its denominator, to reveal the current floor division error.
		 * 4) Store this error for use in the next correction when this function is called.
		 * 5) Note: static analysis tools complain about this "division before multiplication", however, it is intended.
		 */
		uint256 VSTANumerator = _issuance * DECIMAL_PRECISION + lastRewardError[_asset];

		_vSTAPerUnitStaked = VSTANumerator / _totalVSTDeposits;
		lastRewardError[_asset] =
			VSTANumerator -
			(_vSTAPerUnitStaked * _totalVSTDeposits);

		return _vSTAPerUnitStaked;
	}

	function _payOutRewardGains() internal {
		uint256 initialDeposit = deposits[msg.sender];
		if (initialDeposit == 0) return;

		address[] memory rewardAssets = communityIssuance.getAllRewardAssets();
		uint256 rewardLength = rewardAssets.length;
		for (uint256 i = 0; i < rewardLength; ++i) {
			uint256 depositorGain = _getRewardGainFromSnapshots(
				rewardAssets[i],
				initialDeposit,
				msg.sender
			);
			if (depositorGain > 0) {
				communityIssuance.sendAsset(rewardAssets[i], msg.sender, depositorGain);
				emit RewardsPaidToDepositor(msg.sender, rewardAssets[i], depositorGain);
			}
		}
	}

	/*
	 * Calculate the VSTA gain earned by a deposit since its last snapshots were taken.
	 * Given by the formula:  VSTA = d0 * (G - G(0))/P(0)
	 * where G(0) and P(0) are the depositor's snapshots of the sum G and product P, respectively.
	 * d0 is the last recorded deposit value.
	 */
	function _getRewardGainFromSnapshots(
		address _asset,
		uint256 _initialStake,
		address _depositor
	) internal view returns (uint256 rewardGain_) {
		/*
		 * Grab the sum 'G' from the epoch at which the stake was made. The VSTA gain may span up to one scale change.
		 * If it does, the second portion of the VSTA gain is scaled by 1e9.
		 * If the gain spans no scale change, the second portion will be 0.
		 */
		Snapshots storage snapshots = depositSnapshots[_depositor];
		uint128 epochSnapshot = snapshots.epoch;
		uint128 scaleSnapshot = snapshots.scale;
		uint256 G_Snapshot = snapshots.G[_asset];
		uint256 P_Snapshot = snapshots.P;

		uint256 firstPortion = epochToScaleToG[_asset][epochSnapshot][scaleSnapshot] -
			G_Snapshot;
		uint256 secondPortion = epochToScaleToG[_asset][epochSnapshot][
			scaleSnapshot + 1
		] / SCALE_FACTOR;

		rewardGain_ =
			((_initialStake * (firstPortion + secondPortion)) / P_Snapshot) /
			DECIMAL_PRECISION;

		return rewardGain_;
	}

	function _payOutDepositorAssetGains() internal {
		uint256 numberOfPoolAssets = numberOfAssets;
		for (uint256 i = 0; i < numberOfPoolAssets; ++i) {
			uint256 depositorAssetGain = getDepositorAssetGain(
				assetAddresses[i],
				msg.sender
			);

			if (depositorAssetGain > 0) {
				_sendAssetToDepositor(assetAddresses[i], depositorAssetGain);
			}
		}
	}

	/* Calculates the ETH gain earned by the deposit since its last snapshots were taken.
	 * Given by the formula:  E = d0 * (S - S(0))/P(0)
	 * where S(0) and P(0) are the depositor's snapshots of the sum S and product P, respectively.
	 * d0 is the last recorded deposit value.
	 */
	function getDepositorAssetGain(address _asset, address _depositor)
		public
		view
		override
		returns (
			uint256 assetGain_ // Used as regular variable for gas optimisation
		)
	{
		uint256 initialDeposit = deposits[_depositor];
		if (initialDeposit == 0) {
			return 0;
		}

		/*
		 * Grab the sum 'S' from the epoch at which the stake was made. The ETH gain may span up to one scale change.
		 * If it does, the second portion of the ETH gain is scaled by 1e9.
		 * If the gain spans no scale change, the second portion will be 0.
		 */
		Snapshots storage snapshots = depositSnapshots[_depositor];
		uint128 epochSnapshot = snapshots.epoch;
		uint128 scaleSnapshot = snapshots.scale;
		uint256 S_Snapshot = snapshots.S[_asset];
		uint256 P_Snapshot = snapshots.P;

		uint256 firstPortion = epochToScaleToSum[_asset][epochSnapshot][scaleSnapshot] -
			S_Snapshot;
		uint256 secondPortion = epochToScaleToSum[_asset][epochSnapshot][
			scaleSnapshot + 1
		] / (SCALE_FACTOR);

		assetGain_ =
			((initialDeposit * (firstPortion + secondPortion)) / P_Snapshot) /
			DECIMAL_PRECISION;

		return _sanitizeValue(_asset, assetGain_);
	}

	function _sendAssetToDepositor(address _asset, uint256 _amount) internal {
		assetBalances[_asset] = assetBalances[_asset] - _amount;

		if (_asset == RESERVED_ETH_ADDRESS) {
			(bool success, ) = msg.sender.call{ value: _amount }("");
			if (!success) revert SendEthFailed();
		} else {
			_performTokenTransfer(_asset, msg.sender, _amount, false);
		}

		emit AssetSent(msg.sender, _asset, _amount);
	}

	function _announceVSTLoss(uint256 _compoundedVSTDeposit) internal {
		uint256 vstLoss = deposits[msg.sender] - _compoundedVSTDeposit;
		if (vstLoss > 0) emit VSTLoss(msg.sender, vstLoss);
	}

	function _increaseVST(uint256 _amount) internal {
		uint256 newTotalVSTDeposits = totalVSTDeposits + _amount;
		totalVSTDeposits = newTotalVSTDeposits;
		emit StabilityPoolVSTBalanceUpdated(newTotalVSTDeposits);
	}

	function _decreaseVST(uint256 _amount) internal {
		uint256 newTotalVSTDeposits = totalVSTDeposits - _amount;
		totalVSTDeposits = newTotalVSTDeposits;
		emit StabilityPoolVSTBalanceUpdated(newTotalVSTDeposits);
	}

	function _sendVSTtoStabilityPool(address _address, uint256 _amount) internal {
		if (_amount == 0) {
			return;
		}

		_increaseVST(_amount);

		_performTokenTransferFrom(VST, _address, address(this), _amount, false);
	}

	function _sendVSTToDepositor(address _depositor, uint256 _amount) internal {
		if (_amount == 0) {
			return;
		}

		_decreaseVST(_amount);

		_performTokenTransfer(VST, _depositor, _amount, false);
	}

	/*
	 * Return the user's compounded deposit. Given by the formula:  d = d0 * P/P(0)
	 * where P(0) is the depositor's snapshot of the product P, taken when they last updated their deposit.
	 */
	function getCompoundedVSTDeposit(address _depositor)
		public
		view
		override
		returns (uint256)
	{
		uint256 initialDeposit = deposits[_depositor];
		if (initialDeposit == 0) {
			return 0;
		}

		return _getCompoundedStakeFromSnapshots(initialDeposit, _depositor);
	}

	function _getCompoundedStakeFromSnapshots(uint256 initialStake, address depositor)
		internal
		view
		returns (uint256)
	{
		Snapshots storage snapshots = depositSnapshots[depositor];
		uint256 snapshot_P = snapshots.P;
		uint128 scaleSnapshot = snapshots.scale;
		uint128 epochSnapshot = snapshots.epoch;

		// If stake was made before a pool-emptying event, then it has been fully cancelled with debt -- so, return 0
		if (epochSnapshot < currentEpoch) {
			return 0;
		}

		uint256 compoundedStake;
		uint128 scaleDiff = currentScale - scaleSnapshot;

		/* Compute the compounded stake. If a scale change in P was made during the stake's lifetime,
		 * account for it. If more than one scale change was made, then the stake has decreased by a factor of
		 * at least 1e-9 -- so return 0.
		 */
		if (scaleDiff == 0) {
			compoundedStake = (initialStake * P) / snapshot_P;
		} else if (scaleDiff == 1) {
			compoundedStake = (initialStake * P) / snapshot_P / SCALE_FACTOR;
		} else {
			compoundedStake = 0;
		}

		/*
		 * If compounded deposit is less than a billionth of the initial deposit, return 0.
		 *
		 * NOTE: originally, this line was in place to stop rounding errors making the deposit too large. However, the error
		 * corrections should ensure the error in P "favors the Pool", i.e. any given compounded deposit should slightly less
		 * than it's theoretical value.
		 *
		 * Thus it's unclear whether this line is still really needed.
		 */
		if (compoundedStake < initialStake / 1e9) {
			return 0;
		}

		return compoundedStake;
	}

	function _updateDepositAndSnapshots(address _depositor, uint256 _newValue)
		internal
	{
		deposits[_depositor] = _newValue;

		if (_newValue == 0) {
			delete depositSnapshots[_depositor];
			emit UserDepositChanged(_depositor, 0);
			return;
		}

		uint128 currentScaleCached = currentScale;
		uint128 currentEpochCached = currentEpoch;
		uint256 currentP = P;

		Snapshots storage depositSnap = depositSnapshots[_depositor];
		depositSnap.P = currentP;
		depositSnap.scale = currentScaleCached;
		depositSnap.epoch = currentEpochCached;

		address[] memory rewardAssets = communityIssuance.getAllRewardAssets();
		uint256 rewardAssetsLength = rewardAssets.length;
		for (uint256 i = 0; i < rewardAssetsLength; ++i) {
			depositSnap.G[rewardAssets[i]] = epochToScaleToG[rewardAssets[i]][
				currentEpochCached
			][currentScaleCached];
		}

		uint256 numberOfPoolAssets = numberOfAssets;
		for (uint256 i = 0; i < numberOfPoolAssets; ++i) {
			address currentAsset = assetAddresses[i];
			depositSnap.S[currentAsset] = epochToScaleToSum[currentAsset][
				currentEpochCached
			][currentScaleCached];
		}

		emit UserDepositChanged(_depositor, _newValue);
	}

	function isStabilityPoolAssetLookup(address _asset)
		external
		view
		override
		returns (bool)
	{
		return isStabilityPoolAsset[_asset];
	}

	function getPoolAssets() external view returns (address[] memory poolAssets_) {
		uint256 poolAssetLength = numberOfAssets;
		poolAssets_ = new address[](poolAssetLength);
		for (uint256 i = 0; i < poolAssetLength; ++i) {
			poolAssets_[i] = assetAddresses[i];
		}
	}

	function getUserG(address _user, address _asset) external view returns (uint256) {
		return depositSnapshots[_user].G[_asset];
	}

	function getUserS(address _user, address _asset) external view returns (uint256) {
		return depositSnapshots[_user].S[_asset];
	}

	function getUserP(address _user) external view returns (uint256) {
		return depositSnapshots[_user].P;
	}

	function getUserEpoch(address _user) external view returns (uint256) {
		return depositSnapshots[_user].epoch;
	}

	function getUserScale(address _user) external view returns (uint256) {
		return depositSnapshots[_user].scale;
	}

	// add to interface
	function snapshotG(
		address _asset,
		uint128 _epoch,
		uint128 _scale
	) external view returns (uint256) {
		return epochToScaleToG[_asset][_epoch][_scale];
	}

	function snapshotS(
		address _asset,
		uint128 _epoch,
		uint128 _scale
	) external view returns (uint256) {
		return epochToScaleToSum[_asset][_epoch][_scale];
	}
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.0;

interface IStabilityPool {
	// --- Errors ---
	error IsAlreadyPoolAsset();
	error IsNotPoolAsset();
	error SendEthFailed();

	// --- Events ---
	event AssetAddedToStabilityPool(address _asset);
	event RewardsPaidToDepositor(
		address indexed _depositor,
		address _asset,
		uint256 _amount
	);
	event AssetSent(address _to, address _asset, uint256 _amount);
	event VSTLoss(address _depositor, uint256 _vstLoss);
	event UserDepositChanged(address indexed _depositor, uint256 _newDeposit);
	event StabilityPoolVSTBalanceUpdated(uint256 _newBalance);
	event P_Updated(uint256 _P);
	event S_Updated(address _asset, uint256 _S, uint128 _epoch, uint128 _scale);
	event G_Updated(address _asset, uint256 _G, uint128 _epoch, uint128 _scale);
	event EpochUpdated(uint128 _currentEpoch);
	event ScaleUpdated(uint128 _currentScale);

	function addAsset(address _asset) external;

	function provideToSP(uint256 _amount) external;

	function withdrawFromSP(uint256 _amount) external;

	function offset(
		address _asset,
		uint256 _debt,
		uint256 _coll
	) external;

	function getDepositorAssetGain(address _asset, address _depositor)
		external
		view
		returns (uint256);

	function getCompoundedVSTDeposit(address _depositor)
		external
		view
		returns (uint256);

	function isStabilityPoolAssetLookup(address _asset) external view returns (bool);
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.0;

struct Snapshots {
	mapping(address => uint256) S; // asset address -> S value
	uint256 P;
	mapping(address => uint256) G; // asset address -> G value
	uint128 scale;
	uint128 epoch;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./CommunityIssuanceModel.sol";

interface ICommunityIssuance {
	error IsNotRewardAsset();
	error IsAlreadyRewardAsset();
	error RewardSupplyCannotBeBelowIssued();
	error BalanceMustBeZero();
	error RewardsStillActive();

	event StabilityPoolAddressSet(address _stabilityPoolAddress);
	event AssetIssuanceUpdated(
		address indexed _asset,
		uint256 _issuanceSinceLastUpdate,
		uint256 _totalIssued,
		uint256 lastUpdateTime
	);
	event SetNewWeeklyRewardDistribution(
		address indexed _asset,
		uint256 _weeklyReward
	);
	event AddRewardAsset(address _asset);
	event DisableRewardAsset(address _asset);
	event RemoveRewardAsset(address _asset);
	event AddFundsToStabilityPool(address _asset, uint256 _amount);
	event RemoveFundsToStabilityPool(address _asset, uint256 _amount);

	/** 
	@notice addRewardAsset add an asset to array of supported reward assets to distribute.
	@param _asset asset address
	@param _weeklyReward weekly reward amount
	 */
	function addRewardAsset(address _asset, uint256 _weeklyReward) external;

	/** 
	@notice disableRewardAsset stops an reward asset from issueing more rewards.
	@dev If there are still a bit of unissued assets might want to call issueassets before disabling so last little bit is issued.
	@param _asset asset address
	 */
	function disableRewardAsset(address _asset) external;

	/** 
	@notice removeRewardAsset remove an asset from the array of supported reward assets to distribute.
	@dev Can only remove reward asset if balance of asset in this address is 0. Meaning no more rewards left to claim.
	@param _asset asset address
	 */
	function removeRewardAsset(address _asset) external;

	/** 
	@notice addFundsToStabilityPool add funds to stability pool.
	@dev Can only add assets that are reward assets.
	@param _asset asset address
	@param _amount amount of tokens
	 */
	function addFundsToStabilityPool(address _asset, uint256 _amount) external;

	/** 
	@notice removeFundsFromStabilityPool remove funds from stabilitypool.
	@dev Cannot remove funds such that totalRewardIssued > totalRewardSupply
	@param _asset asset address
	@param _amount amount of tokens
	 */
	function removeFundsFromStabilityPool(address _asset, uint256 _amount) external;

	/** 
	@notice issueAssets go through all reward assets and update the amount issued based on set reward rate and last update time.
	@dev Used to return total amount of reward tokens issued to StabilityPool.
	@return assetAddresses_ array of addresses of assets that got updated
	@return issuanceAmounts_ amount of tokens issued since last update
	 */
	function issueAssets()
		external
		returns (address[] memory assetAddresses_, uint256[] memory issuanceAmounts_);

	/** 
	@notice sendAsset send assets to a user.
	@dev Can only be called by StabilityPool. Relies on StabilityPool to calculate how much tokens each user is entitled to.
	@param _asset asset address
	@param _account address of user
	@param _amount amount of tokens
	 */
	function sendAsset(
		address _asset,
		address _account,
		uint256 _amount
	) external;

	/** 
	@notice setWeeklyAssetDistribution sets how much reward tokens distributed per week.
	@param _asset asset address
	@param _weeklyReward amount of tokens per week
	 */
	function setWeeklyAssetDistribution(address _asset, uint256 _weeklyReward)
		external;

	/** 
	@notice getLastUpdateIssuance returns amount of rewards issued from last update till now.
	@param _asset asset address
	 */
	function getLastUpdateIssuance(address _asset)
		external
		view
		returns (uint256, uint256);

	/** 
	@notice getRewardsLeftInStabilityPool returns total amount of tokens that have not been issued to users. 
	@dev This is calculated using current timestamp assuming issueAssets is called right now.
	@param _asset asset address
	 */
	function getRewardsLeftInStabilityPool(address _asset)
		external
		view
		returns (uint256);

	/** 
	@notice getRewardDistribution returns the reward distribution details of a reward asset.
	@param _asset asset address
	 */
	function getRewardDistribution(address _asset)
		external
		view
		returns (DistributionRewards memory);

	/** 
	@notice getAllRewardAssets returns an array of all reward asset addresses.
	 */
	function getAllRewardAssets() external view returns (address[] memory);

	/** 
	@notice isRewardAsset returns whether address is a reward asset or not.
	@param _asset asset address
	 */
	function isRewardAsset(address _asset) external view returns (bool);
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.0;

struct DistributionRewards {
	address rewardToken;
	uint256 totalRewardIssued;
	uint256 lastUpdateTime;
	uint256 totalRewardSupply;
	uint256 rewardDistributionPerMin;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "../../BaseVesta.sol";
import { TokenTransferrer } from "../../lib/token/TokenTransferrer.sol";
import "./ICommunityIssuance.sol";
import "./CommunityIssuanceModel.sol";

/**
@title CommunityIssuance
@notice Holds and issues rewards for stability pool. New reward asset types and distribution amounts are also set here.
*/
contract CommunityIssuance is ICommunityIssuance, TokenTransferrer, BaseVesta {
	bytes1 public constant STABILITY_POOL = 0x01;
	uint256 public constant DISTRIBUTION_DURATION = 7 days / 60;
	uint256 public constant SECONDS_IN_ONE_MINUTE = 60;

	address public stabilityPoolAddress;
	mapping(address => DistributionRewards) internal stabilityPoolRewards; // asset -> DistributionRewards
	mapping(address => bool) internal isRewardAssetLookup; // asset -> whether it is a reward asset or not
	address[] internal rewardAssets;

	modifier ensureRewardAsset(address _asset) {
		if (!isRewardAssetLookup[_asset]) revert IsNotRewardAsset();
		_;
	}

	modifier ensureNotRewardAsset(address _asset) {
		if (isRewardAssetLookup[_asset]) revert IsAlreadyRewardAsset();
		_;
	}

	function setUp(address _stabilityPoolAddress)
		external
		initializer
		onlyContract(_stabilityPoolAddress)
	{
		__BASE_VESTA_INIT();

		_setPermission(_stabilityPoolAddress, STABILITY_POOL);

		emit StabilityPoolAddressSet(_stabilityPoolAddress);
	}

	function addRewardAsset(address _asset, uint256 _weeklyReward)
		external
		override
		onlyOwner
		ensureNotRewardAsset(_asset)
	{
		isRewardAssetLookup[_asset] = true;

		rewardAssets.push(_asset);

		stabilityPoolRewards[_asset] = DistributionRewards(
			_asset,
			0,
			0,
			0,
			_weeklyReward / DISTRIBUTION_DURATION
		);

		emit AddRewardAsset(_asset);
	}

	function disableRewardAsset(address _asset)
		external
		override
		onlyOwner
		ensureRewardAsset(_asset)
	{
		stabilityPoolRewards[_asset].lastUpdateTime = 0;
		emit DisableRewardAsset(_asset);
	}

	// FIXME: Not best solution since its very rare an inactive pool will be empty.
	function removeRewardAsset(address _asset)
		external
		override
		onlyOwner
		ensureRewardAsset(_asset)
	{
		if (_balanceOf(_asset, address(this)) > 0) revert BalanceMustBeZero();
		if (stabilityPoolRewards[_asset].lastUpdateTime > 0) revert RewardsStillActive();

		isRewardAssetLookup[_asset] = false;

		uint256 rewardLength = rewardAssets.length;
		for (uint256 i = 0; i < rewardLength; i++) {
			// Delete address from array by swapping with last element and calling pop()
			if (rewardAssets[i] == _asset) {
				rewardAssets[i] = rewardAssets[rewardLength - 1];
				rewardAssets.pop();
				break;
			}
		}

		delete stabilityPoolRewards[_asset];

		emit RemoveRewardAsset(_asset);
	}

	function addFundsToStabilityPool(address _asset, uint256 _amount)
		external
		override
		onlyOwner
		ensureRewardAsset(_asset)
	{
		DistributionRewards storage distributionRewards = stabilityPoolRewards[_asset];

		if (distributionRewards.lastUpdateTime == 0) {
			distributionRewards.lastUpdateTime = block.timestamp;
		}

		distributionRewards.totalRewardSupply += _amount;

		_performTokenTransferFrom(_asset, msg.sender, address(this), _amount, false);

		emit AddFundsToStabilityPool(_asset, _amount);
	}

	function removeFundsFromStabilityPool(address _asset, uint256 _amount)
		external
		override
		onlyOwner
		ensureRewardAsset(_asset)
	{
		DistributionRewards storage distributionRewards = stabilityPoolRewards[_asset];

		if (
			distributionRewards.totalRewardSupply - _amount <
			distributionRewards.totalRewardIssued
		) revert RewardSupplyCannotBeBelowIssued();

		distributionRewards.totalRewardSupply -= _amount;

		_performTokenTransfer(_asset, msg.sender, _amount, false);

		emit RemoveFundsToStabilityPool(_asset, _amount);
	}

	function issueAssets()
		external
		override
		hasPermission(STABILITY_POOL)
		returns (address[] memory assetAddresses_, uint256[] memory issuanceAmounts_)
	{
		uint256 arrayLengthCache = rewardAssets.length;
		assetAddresses_ = new address[](arrayLengthCache);
		issuanceAmounts_ = new uint256[](arrayLengthCache);

		for (uint256 i = 0; i < arrayLengthCache; ++i) {
			assetAddresses_[i] = rewardAssets[i];
			issuanceAmounts_[i] = _issueAsset(assetAddresses_[i]);
		}

		return (assetAddresses_, issuanceAmounts_);
	}

	function _issueAsset(address _asset) internal returns (uint256 issuance_) {
		uint256 totalIssuance;
		(issuance_, totalIssuance) = getLastUpdateIssuance(_asset);

		if (issuance_ == 0) return 0;

		DistributionRewards storage distributionRewards = stabilityPoolRewards[_asset];
		distributionRewards.lastUpdateTime = block.timestamp;
		distributionRewards.totalRewardIssued = totalIssuance;

		emit AssetIssuanceUpdated(_asset, issuance_, totalIssuance, block.timestamp);

		return issuance_;
	}

	function sendAsset(
		address _asset,
		address _account,
		uint256 _amount
	) external override hasPermission(STABILITY_POOL) ensureRewardAsset(_asset) {
		uint256 balance = _balanceOf(_asset, address(this));
		uint256 safeAmount = balance >= _amount ? _amount : balance;

		if (safeAmount == 0) return;

		_performTokenTransfer(_asset, _account, safeAmount, false);
	}

	function setWeeklyAssetDistribution(address _asset, uint256 _weeklyReward)
		external
		override
		onlyOwner
		ensureRewardAsset(_asset)
	{
		stabilityPoolRewards[_asset].rewardDistributionPerMin =
			_weeklyReward /
			DISTRIBUTION_DURATION;

		emit SetNewWeeklyRewardDistribution(_asset, _weeklyReward);
	}

	function getLastUpdateIssuance(address _asset)
		public
		view
		override
		returns (uint256 issuance_, uint256 totalIssuance_)
	{
		DistributionRewards memory distributionRewards = stabilityPoolRewards[_asset];

		if (distributionRewards.lastUpdateTime == 0)
			return (0, distributionRewards.totalRewardIssued);

		uint256 timePassedInMinutes = (block.timestamp -
			distributionRewards.lastUpdateTime) / SECONDS_IN_ONE_MINUTE;
		issuance_ = distributionRewards.rewardDistributionPerMin * timePassedInMinutes;
		totalIssuance_ = issuance_ + distributionRewards.totalRewardIssued;

		if (totalIssuance_ > distributionRewards.totalRewardSupply) {
			issuance_ =
				distributionRewards.totalRewardSupply -
				distributionRewards.totalRewardIssued;
			totalIssuance_ = distributionRewards.totalRewardSupply;
		}

		return (issuance_, totalIssuance_);
	}

	function getRewardsLeftInStabilityPool(address _asset)
		external
		view
		override
		returns (uint256)
	{
		(, uint256 totalIssuance) = getLastUpdateIssuance(_asset);

		return stabilityPoolRewards[_asset].totalRewardSupply - totalIssuance;
	}

	function getRewardDistribution(address _asset)
		external
		view
		override
		returns (DistributionRewards memory)
	{
		return stabilityPoolRewards[_asset];
	}

	function getAllRewardAssets() external view override returns (address[] memory) {
		return rewardAssets;
	}

	function isRewardAsset(address _asset) external view override returns (bool) {
		return isRewardAssetLookup[_asset];
	}
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

import "./IProtocolRevenue.sol";

import "../../BaseVesta.sol";
import "../../interface/IERC20Callback.sol";
import { TokenTransferrer } from "../../lib/token/TokenTransferrer.sol";

/**
@title ProtocolRevenue
@notice All the protocol's revenues are held here
*/
contract ProtocolRevenue is
	IProtocolRevenue,
	IERC20Callback,
	TokenTransferrer,
	BaseVesta
{
	bytes1 public constant DEPOSIT = 0x01;

	bool public isPaused;
	address public treasury;

	mapping(address => uint256) internal rewards;
	mapping(address => uint256) internal rewardsSentToTreasury;

	function setUp(address _treasury)
		external
		initializer
		onlyValidAddress(_treasury)
	{
		__BASE_VESTA_INIT();
		treasury = _treasury;
	}

	function claimRewards(address _token) external override nonReentrant {
		//TODO -> Once veModel is defined.
		emit RewardsChanged(_token, rewards[_token]);
	}

	function setTreasury(address _newTreasury)
		external
		override
		onlyOwner
		onlyValidAddress(_newTreasury)
	{
		treasury = _newTreasury;
	}

	function withdraw(address _token, uint256 _amount) external override onlyOwner {
		uint256 sanitizedValue = _sanitizeValue(_token, _amount);
		if (sanitizedValue == 0) return;

		uint256 newTotal = rewards[_token] -= _amount;

		_performTokenTransfer(_token, msg.sender, sanitizedValue, false);
		emit RewardsChanged(_token, newTotal);
	}

	function setPause(bool _pause) external override onlyOwner {
		isPaused = _pause;
	}

	function receiveERC20(address _token, uint256 _amount)
		external
		override
		hasPermission(DEPOSIT)
	{
		if (isPaused) {
			_performTokenTransfer(_token, treasury, _amount, false);
			rewardsSentToTreasury[_token] += _amount;
		} else {
			uint256 newTotal = rewards[_token] += _amount;
			emit RewardsChanged(_token, newTotal);
		}
	}

	receive() external payable {
		if (isPaused) {
			_performTokenTransfer(RESERVED_ETH_ADDRESS, treasury, msg.value, false);
			rewardsSentToTreasury[RESERVED_ETH_ADDRESS] += msg.value;
		} else {
			uint256 newTotal = rewards[RESERVED_ETH_ADDRESS] += msg.value;
			emit RewardsChanged(RESERVED_ETH_ADDRESS, newTotal);
		}
	}

	function getRewardBalance(address _token)
		external
		view
		override
		returns (uint256)
	{
		return rewards[_token];
	}

	function getRewardBalanceSentToTreasury(address _token)
		external
		view
		override
		returns (uint256)
	{
		return rewardsSentToTreasury[_token];
	}
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.0;

interface IProtocolRevenue {
	event RewardsChanged(address indexed _token, uint256 _newValue);

	/**
    @notice VeHolders can call this function to reclaim their share of revenue
    @param _token the token they want to claim
     */
	function claimRewards(address _token) external;

	/**
    @notice Change vesta's treasury address
    @dev Only Owner can call this
    @param _newTreasury new treasury address
     */
	function setTreasury(address _newTreasury) external;

	/**
    @notice withdraw token from the contract
    @dev Only Owner can call this
    @param _token the token address
    @param _amount the amount to withdraw
     */
	function withdraw(address _token, uint256 _amount) external;

	/**
    @notice Pause the contract, all new revenue will automatically go to the treasury.
    @dev This option is just for the time we deploy veVsta
    @dev Only Owner can call this
    @param _pause pause status
     */
	function setPause(bool _pause) external;

	/**
    @notice Get total rewards by token inside the contract
    @param _token The address of the token
     */
	function getRewardBalance(address _token) external view returns (uint256);

	/**
    @notice Get total reward sent to the treasury
    @param _token The address of the token
     */
	function getRewardBalanceSentToTreasury(address _token)
		external
		view
		returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "../../interface/IERC20.sol";
import "../../interface/IERC20Metadata.sol";

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
contract ERC20 is IERC20, IERC20Metadata {
	mapping(address => uint256) private _balances;

	mapping(address => mapping(address => uint256)) private _allowances;

	uint256 private _totalSupply;

	string internal _name;
	string internal _symbol;

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
	function balanceOf(address account)
		public
		view
		virtual
		override
		returns (uint256)
	{
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
	function transfer(address to, uint256 amount)
		public
		virtual
		override
		returns (bool)
	{
		_transfer(msg.sender, to, amount);
		return true;
	}

	/**
	 * @dev See {IERC20-allowance}.
	 */
	function allowance(address owner, address spender)
		public
		view
		virtual
		override
		returns (uint256)
	{
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
	function approve(address spender, uint256 amount)
		public
		virtual
		override
		returns (bool)
	{
		_approve(msg.sender, spender, amount);
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
		_spendAllowance(from, msg.sender, amount);
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
	function increaseAllowance(address spender, uint256 addedValue)
		public
		virtual
		returns (bool)
	{
		_approve(msg.sender, spender, allowance(msg.sender, spender) + addedValue);
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
	function decreaseAllowance(address spender, uint256 subtractedValue)
		public
		virtual
		returns (bool)
	{
		uint256 currentAllowance = allowance(msg.sender, spender);
		require(
			currentAllowance >= subtractedValue,
			"ERC20: decreased allowance below zero"
		);
		unchecked {
			_approve(msg.sender, spender, currentAllowance - subtractedValue);
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

import "./IERC20.sol";

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

pragma solidity ^0.8.7;

import { BaseWrapper } from "./BaseWrapper.sol";
import { ITwapOracleWrapper } from "../interface/wrapper/ITwapOracleWrapper.sol";

import { OracleLibrary } from "../lib/vendor/OracleLibrary.sol";
import { VestaMath } from "../../../lib/VestaMath.sol";
import { OracleAnswer } from "../model/OracleModels.sol";

import { AggregatorV2V3Interface } from "lib/chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";
import { FlagsInterface } from "lib/chainlink/contracts/src/v0.8/interfaces/FlagsInterface.sol";

contract TwapOracleWrapper is BaseWrapper, ITwapOracleWrapper {
	uint8 public constant ethDecimals = 8;

	address public weth;
	AggregatorV2V3Interface public sequencerUptimeFeed;
	AggregatorV2V3Interface public ethChainlinkAggregator;

	uint32 public twapPeriodInSeconds;

	mapping(address => address) internal pools;

	function setUp(
		address _weth,
		address _ethChainlinkAggregator,
		address _sequencerUptimeFeed
	)
		external
		initializer
		onlyContract(_weth)
		onlyContracts(_ethChainlinkAggregator, _sequencerUptimeFeed)
	{
		__BASE_VESTA_INIT();

		weth = _weth;
		ethChainlinkAggregator = AggregatorV2V3Interface(_ethChainlinkAggregator);
		sequencerUptimeFeed = AggregatorV2V3Interface(_sequencerUptimeFeed);
		twapPeriodInSeconds = 1800;
	}

	function getPrice(address _token)
		external
		view
		override
		returns (OracleAnswer memory answer_)
	{
		try this.getTokenPriceInETH(_token, twapPeriodInSeconds) returns (
			uint256 priceInETH
		) {
			uint256 ethPriceInUSD = getETHPrice();
			uint256 tokenPrice = VestaMath.mulDiv(priceInETH, ethPriceInUSD, 1e18);

			if (tokenPrice == 0) return answer_;

			answer_.currentPrice = tokenPrice;
			answer_.lastPrice = tokenPrice;
			answer_.lastUpdate = block.timestamp;
		} catch {}

		return answer_;
	}

	function getTokenPriceInETH(address _token, uint32 _twapPeriod)
		external
		view
		override
		notZero(_twapPeriod)
		returns (uint256)
	{
		address v3Pool = pools[_token];
		if (v3Pool == address(0)) revert TokenIsNotRegistered(_token);

		(int24 arithmeticMeanTick, ) = OracleLibrary.consult(v3Pool, _twapPeriod);
		return OracleLibrary.getQuoteAtTick(arithmeticMeanTick, 1e18, _token, weth);
	}

	function getETHPrice() public view override returns (uint256) {
		if (!_isSequencerUp()) {
			return 0;
		}

		try ethChainlinkAggregator.latestAnswer() returns (int256 price) {
			if (price <= 0) return 0;
			return scalePriceByDigits(uint256(price), ethDecimals);
		} catch {
			return 0;
		}
	}

	function _isSequencerUp() internal view returns (bool sequencerIsUp) {
		(, int256 answer, , uint256 updatedAt, ) = sequencerUptimeFeed.latestRoundData();

		// Answer -> 0: Sequencer is up  |  1: Sequencer is down
		return (answer == 0 && (block.timestamp - updatedAt) < 3600);
	}

	function changeTwapPeriod(uint32 _timeInSecond)
		external
		notZero(_timeInSecond)
		onlyOwner
	{
		twapPeriodInSeconds = _timeInSecond;

		emit TwapChanged(_timeInSecond);
	}

	function addOracle(address _token, address _pool)
		external
		onlyContract(_pool)
		onlyOwner
	{
		pools[_token] = _pool;

		if (this.getPrice(_token).currentPrice == 0) {
			revert UniswapFailedToGetPrice();
		}

		emit OracleAdded(_token, _pool);
	}

	function removeOracle(address _token) external onlyOwner {
		delete pools[_token];

		emit OracleRemoved(_token);
	}

	function getPool(address _token) external view returns (address) {
		return pools[_token];
	}
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

import { BaseVesta } from "../../../BaseVesta.sol";
import { IOracleWrapper } from "../interface/IOracleWrapper.sol";

abstract contract BaseWrapper is BaseVesta, IOracleWrapper {
	uint256 public constant TARGET_DIGITS = 18;

	function scalePriceByDigits(uint256 _price, uint256 _answerDigits)
		internal
		pure
		returns (uint256)
	{
		return
			_answerDigits < TARGET_DIGITS
				? _price * (10**(TARGET_DIGITS - _answerDigits))
				: _price / (10**(_answerDigits - TARGET_DIGITS));
	}
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.0;

interface ITwapOracleWrapper {
	error UniswapFailedToGetPrice();

	event TwapChanged(uint32 newTwap);
	event OracleAdded(address indexed token, address pool);
	event OracleRemoved(address indexed token);

	/**
	 * @notice getTokenPriceInETH returns the value of the token in ETH
	 * @dev {_twapPeriodInSeconds} cannot be zero, recommended value is 1800 (30 minutes)
	 * @param _token the address of the token
	 * @param _twapPeriodInSeconds the amount of seconds you want to go back
	 * @return The value of the token in ETH
	 */
	function getTokenPriceInETH(address _token, uint32 _twapPeriodInSeconds)
		external
		view
		returns (uint256);

	/**
	 * @notice getETHPrice returns the value of ETH in USD from chainlink
	 * @return Value in USD
	 */
	function getETHPrice() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import "../../../../lib/VestaMath.sol";
import "./TickMath.sol";
import "../../interface/vendor/IUniswapV3Pool.sol";

/// @title Oracle library
/// @notice Provides functions to integrate with V3 pool oracle
library OracleLibrary {
	/// @notice Calculates time-weighted means of tick and liquidity for a given Uniswap V3 pool
	/// @param pool Address of the pool that we want to observe
	/// @param secondsAgo Number of seconds in the past from which to calculate the time-weighted means
	/// @return arithmeticMeanTick The arithmetic mean tick from (block.timestamp - secondsAgo) to block.timestamp
	/// @return harmonicMeanLiquidity The harmonic mean liquidity from (block.timestamp - secondsAgo) to block.timestamp
	function consult(address pool, uint32 secondsAgo)
		internal
		view
		returns (int24 arithmeticMeanTick, uint128 harmonicMeanLiquidity)
	{
		require(secondsAgo != 0, "BP");

		uint32[] memory secondsAgos = new uint32[](2);
		secondsAgos[0] = secondsAgo;
		secondsAgos[1] = 0;

		(
			int56[] memory tickCumulatives,
			uint160[] memory secondsPerLiquidityCumulativeX128s
		) = IUniswapV3Pool(pool).observe(secondsAgos);

		int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
		uint160 secondsPerLiquidityCumulativesDelta = secondsPerLiquidityCumulativeX128s[
			1
		] - secondsPerLiquidityCumulativeX128s[0];

		arithmeticMeanTick = int24(tickCumulativesDelta / int32(secondsAgo));
		// Always round to negative infinity
		if (tickCumulativesDelta < 0 && (tickCumulativesDelta % int32(secondsAgo) != 0))
			arithmeticMeanTick--;

		// We are multiplying here instead of shifting to ensure that harmonicMeanLiquidity doesn't overflow uint128
		uint192 secondsAgoX160 = uint192(secondsAgo) * type(uint160).max;
		harmonicMeanLiquidity = uint128(
			secondsAgoX160 / (uint192(secondsPerLiquidityCumulativesDelta) << 32)
		);
	}

	/// @notice Given a tick and a token amount, calculates the amount of token received in exchange
	/// @param tick Tick value used to calculate the quote
	/// @param baseAmount Amount of token to be converted
	/// @param baseToken Address of an ERC20 token contract used as the baseAmount denomination
	/// @param quoteToken Address of an ERC20 token contract used as the quoteAmount denomination
	/// @return quoteAmount Amount of quoteToken received for baseAmount of baseToken
	function getQuoteAtTick(
		int24 tick,
		uint128 baseAmount,
		address baseToken,
		address quoteToken
	) internal pure returns (uint256 quoteAmount) {
		uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);

		// Calculate quoteAmount with better precision if it doesn't overflow when multiplied by itself
		if (sqrtRatioX96 <= type(uint128).max) {
			uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
			quoteAmount = baseToken < quoteToken
				? VestaMath.mulDiv(ratioX192, baseAmount, 1 << 192)
				: VestaMath.mulDiv(1 << 192, baseAmount, ratioX192);
		} else {
			uint256 ratioX128 = VestaMath.mulDiv(sqrtRatioX96, sqrtRatioX96, 1 << 64);
			quoteAmount = baseToken < quoteToken
				? VestaMath.mulDiv(ratioX128, baseAmount, 1 << 128)
				: VestaMath.mulDiv(1 << 128, baseAmount, ratioX128);
		}
	}

	/// @notice Given a pool, it returns the number of seconds ago of the oldest stored observation
	/// @param pool Address of Uniswap V3 pool that we want to observe
	/// @return secondsAgo The number of seconds ago of the oldest observation stored for the pool
	function getOldestObservationSecondsAgo(address pool)
		internal
		view
		returns (uint32 secondsAgo)
	{
		(
			,
			,
			uint16 observationIndex,
			uint16 observationCardinality,
			,
			,

		) = IUniswapV3Pool(pool).slot0();
		require(observationCardinality > 0, "NI");

		(uint32 observationTimestamp, , , bool initialized) = IUniswapV3Pool(pool)
			.observations((observationIndex + 1) % observationCardinality);

		// The next index might not be initialized if the cardinality is in the process of increasing
		// In this case the oldest observation is always in index 0
		if (!initialized) {
			(observationTimestamp, , , ) = IUniswapV3Pool(pool).observations(0);
		}

		secondsAgo = uint32(block.timestamp) - observationTimestamp;
	}

	/// @notice Given a pool, it returns the tick value as of the start of the current block
	/// @param pool Address of Uniswap V3 pool
	/// @return The tick that the pool was in at the start of the current block
	function getBlockStartingTickAndLiquidity(address pool)
		internal
		view
		returns (int24, uint128)
	{
		(
			,
			int24 tick,
			uint16 observationIndex,
			uint16 observationCardinality,
			,
			,

		) = IUniswapV3Pool(pool).slot0();

		// 2 observations are needed to reliably calculate the block starting tick
		require(observationCardinality > 1, "NEO");

		// If the latest observation occurred in the past, then no tick-changing trades have happened in this block
		// therefore the tick in `slot0` is the same as at the beginning of the current block.
		// We don't need to check if this observation is initialized - it is guaranteed to be.
		(
			uint32 observationTimestamp,
			int56 tickCumulative,
			uint160 secondsPerLiquidityCumulativeX128,

		) = IUniswapV3Pool(pool).observations(observationIndex);
		if (observationTimestamp != uint32(block.timestamp)) {
			return (tick, IUniswapV3Pool(pool).liquidity());
		}

		uint256 prevIndex = (uint256(observationIndex) + observationCardinality - 1) %
			observationCardinality;
		(
			uint32 prevObservationTimestamp,
			int56 prevTickCumulative,
			uint160 prevSecondsPerLiquidityCumulativeX128,
			bool prevInitialized
		) = IUniswapV3Pool(pool).observations(prevIndex);

		require(prevInitialized, "ONI");

		uint32 delta = observationTimestamp - prevObservationTimestamp;
		tick = int24((tickCumulative - prevTickCumulative) / int32(delta));
		uint128 liquidity = uint128(
			(uint192(delta) * type(uint160).max) /
				(uint192(
					secondsPerLiquidityCumulativeX128 - prevSecondsPerLiquidityCumulativeX128
				) << 32)
		);
		return (tick, liquidity);
	}

	/// @notice Information for calculating a weighted arithmetic mean tick
	struct WeightedTickData {
		int24 tick;
		uint128 weight;
	}

	/// @notice Given an array of ticks and weights, calculates the weighted arithmetic mean tick
	/// @param weightedTickData An array of ticks and weights
	/// @return weightedArithmeticMeanTick The weighted arithmetic mean tick
	/// @dev Each entry of `weightedTickData` should represents ticks from pools with the same underlying pool tokens. If they do not,
	/// extreme care must be taken to ensure that ticks are comparable (including decimal differences).
	/// @dev Note that the weighted arithmetic mean tick corresponds to the weighted geometric mean price.
	function getWeightedArithmeticMeanTick(WeightedTickData[] memory weightedTickData)
		internal
		pure
		returns (int24 weightedArithmeticMeanTick)
	{
		// Accumulates the sum of products between each tick and its weight
		int256 numerator;

		// Accumulates the sum of the weights
		uint256 denominator;

		// Products fit in 152 bits, so it would take an array of length ~2**104 to overflow this logic
		for (uint256 i; i < weightedTickData.length; i++) {
			numerator +=
				weightedTickData[i].tick *
				int256(int128(weightedTickData[i].weight));
			denominator += weightedTickData[i].weight;
		}

		weightedArithmeticMeanTick = int24(numerator / int256(denominator));
		// Always round to negative infinity
		if (numerator < 0 && (numerator % int256(denominator) != 0))
			weightedArithmeticMeanTick--;
	}

	/// @notice Returns the "synthetic" tick which represents the price of the first entry in `tokens` in terms of the last
	/// @dev Useful for calculating relative prices along routes.
	/// @dev There must be one tick for each pairwise set of tokens.
	/// @param tokens The token contract addresses
	/// @param ticks The ticks, representing the price of each token pair in `tokens`
	/// @return syntheticTick The synthetic tick, representing the relative price of the outermost tokens in `tokens`
	function getChainedPrice(address[] memory tokens, int24[] memory ticks)
		internal
		pure
		returns (int256 syntheticTick)
	{
		require(tokens.length - 1 == ticks.length, "DL");
		for (uint256 i = 1; i <= ticks.length; i++) {
			// check the tokens for address sort order, then accumulate the
			// ticks into the running synthetic tick, ensuring that intermediate tokens "cancel out"
			tokens[i - 1] < tokens[i]
				? syntheticTick += ticks[i - 1]
				: syntheticTick -= ticks[i - 1];
		}
	}
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.6.0;

struct OracleAnswer {
	uint256 currentPrice;
	uint256 lastPrice;
	uint256 lastUpdate;
}

struct Oracle {
	address primaryWrapper;
	address secondaryWrapper;
	bool disabled;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface FlagsInterface {
  function getFlag(address) external view returns (bool);

  function getFlags(address[] calldata) external view returns (bool[] memory);

  function raiseFlag(address) external;

  function raiseFlags(address[] calldata) external;

  function lowerFlags(address[] calldata) external;

  function setRaisingAccessController(address) external;
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.7;

import { OracleAnswer } from "../model/OracleModels.sol";

interface IOracleWrapper {
	error TokenIsNotRegistered(address _token);
	error ResponseFromOracleIsInvalid(address _token, address _oracle);

	/**
	 * @notice getPrice get the current and last price with the last update
	 * @dev Depending of the wrapper and the oracle, last price and last update might be faked.
	 *      If faked: they will use the currentPrice and block.timestamp
	 * @dev If the contract fails to get the price, it will returns an empty response.
	 * @param _token the address of the token
	 * @return answer_ OracleAnswer structure.
	 */
	function getPrice(address _token)
		external
		view
		returns (OracleAnswer memory answer_);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
	/// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
	int24 internal constant MIN_TICK = -887272;
	/// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
	int24 internal constant MAX_TICK = -MIN_TICK;

	/// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
	uint160 internal constant MIN_SQRT_RATIO = 4295128739;
	/// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
	uint160 internal constant MAX_SQRT_RATIO =
		1461446703485210103287273052203988822378723970342;

	/// @notice Calculates sqrt(1.0001^tick) * 2^96
	/// @dev Throws if |tick| > max tick
	/// @param tick The input tick for the above formula
	/// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
	/// at the given tick
	function getSqrtRatioAtTick(int24 tick)
		internal
		pure
		returns (uint160 sqrtPriceX96)
	{
		uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
		require(absTick <= uint256(uint24(MAX_TICK)), "T");

		uint256 ratio = absTick & 0x1 != 0
			? 0xfffcb933bd6fad37aa2d162d1a594001
			: 0x100000000000000000000000000000000;
		if (absTick & 0x2 != 0)
			ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
		if (absTick & 0x4 != 0)
			ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
		if (absTick & 0x8 != 0)
			ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
		if (absTick & 0x10 != 0)
			ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
		if (absTick & 0x20 != 0)
			ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
		if (absTick & 0x40 != 0)
			ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
		if (absTick & 0x80 != 0)
			ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
		if (absTick & 0x100 != 0)
			ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
		if (absTick & 0x200 != 0)
			ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
		if (absTick & 0x400 != 0)
			ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
		if (absTick & 0x800 != 0)
			ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
		if (absTick & 0x1000 != 0)
			ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
		if (absTick & 0x2000 != 0)
			ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
		if (absTick & 0x4000 != 0)
			ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
		if (absTick & 0x8000 != 0)
			ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
		if (absTick & 0x10000 != 0)
			ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
		if (absTick & 0x20000 != 0)
			ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
		if (absTick & 0x40000 != 0)
			ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
		if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

		if (tick > 0) ratio = type(uint256).max / ratio;

		// this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
		// we then downcast because we know the result always fits within 160 bits due to our tick input constraint
		// we round up in the division so getTickAtSqrtRatio of the output price is always consistent
		sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
	}

	/// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
	/// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
	/// ever return.
	/// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
	/// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
	function getTickAtSqrtRatio(uint160 sqrtPriceX96)
		internal
		pure
		returns (int24 tick)
	{
		// second inequality must be < because the price can never reach the price at the max tick
		require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, "R");
		uint256 ratio = uint256(sqrtPriceX96) << 32;

		uint256 r = ratio;
		uint256 msb = 0;

		assembly {
			let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
			msb := or(msb, f)
			r := shr(f, r)
		}
		assembly {
			let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
			msb := or(msb, f)
			r := shr(f, r)
		}
		assembly {
			let f := shl(5, gt(r, 0xFFFFFFFF))
			msb := or(msb, f)
			r := shr(f, r)
		}
		assembly {
			let f := shl(4, gt(r, 0xFFFF))
			msb := or(msb, f)
			r := shr(f, r)
		}
		assembly {
			let f := shl(3, gt(r, 0xFF))
			msb := or(msb, f)
			r := shr(f, r)
		}
		assembly {
			let f := shl(2, gt(r, 0xF))
			msb := or(msb, f)
			r := shr(f, r)
		}
		assembly {
			let f := shl(1, gt(r, 0x3))
			msb := or(msb, f)
			r := shr(f, r)
		}
		assembly {
			let f := gt(r, 0x1)
			msb := or(msb, f)
		}

		if (msb >= 128) r = ratio >> (msb - 127);
		else r = ratio << (127 - msb);

		int256 log_2 = (int256(msb) - 128) << 64;

		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(63, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(62, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(61, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(60, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(59, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(58, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(57, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(56, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(55, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(54, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(53, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(52, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(51, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(50, f))
		}

		int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

		int24 tickLow = int24(
			(log_sqrt10001 - 3402992956809132418596140100660247210) >> 128
		);
		int24 tickHi = int24(
			(log_sqrt10001 + 291339464771989622907027621153398088495) >> 128
		);

		tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96
			? tickHi
			: tickLow;
	}
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

interface IUniswapV3Pool {
	function slot0()
		external
		view
		returns (
			uint160 sqrtPriceX96,
			int24 tick,
			uint16 observationIndex,
			uint16 observationCardinality,
			uint16 observationCardinalityNext,
			uint8 feeProtocol,
			bool unlocked
		);

	function observe(uint32[] calldata secondsAgos)
		external
		view
		returns (
			int56[] memory tickCumulatives,
			uint160[] memory secondsPerLiquidityCumulativeX128s
		);

	function observations(uint256 index)
		external
		view
		returns (
			uint32 blockTimestamp,
			int56 tickCumulative,
			uint160 secondsPerLiquidityCumulativeX128,
			bool initialized
		);

	function liquidity() external view returns (uint128);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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
pragma solidity ^0.8.7;

import { BaseWrapper } from "./BaseWrapper.sol";
import { IChainlinkWrapper } from "../interface/wrapper/IChainlinkWrapper.sol";

import { VestaMath } from "../../../lib/VestaMath.sol";
import { OracleAnswer } from "../model/OracleModels.sol";
import "../model/ChainlinksModels.sol";

import { AggregatorV2V3Interface } from "lib/chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";
import { FlagsInterface } from "lib/chainlink/contracts/src/v0.8/interfaces/FlagsInterface.sol";

contract ChainlinkWrapper is BaseWrapper, IChainlinkWrapper {
	AggregatorV2V3Interface internal sequencerUptimeFeed;

	mapping(address => Aggregators) private aggregators;

	function setUp(address _sequencerUptimeFeed)
		external
		onlyContract(_sequencerUptimeFeed)
		initializer
	{
		__BASE_VESTA_INIT();
		sequencerUptimeFeed = AggregatorV2V3Interface(_sequencerUptimeFeed);
	}

	function addOracle(
		address _token,
		address _priceAggregator,
		address _indexAggregator
	) external onlyOwner onlyContract(_priceAggregator) {
		if (_indexAggregator != address(0) && !isContract(_indexAggregator)) {
			revert InvalidContract();
		}

		aggregators[_token] = Aggregators(_priceAggregator, _indexAggregator);

		(ChainlinkWrappedReponse memory currentResponse, ) = _getResponses(
			_priceAggregator,
			false
		);

		(ChainlinkWrappedReponse memory currentResponseIndex, ) = _getResponses(
			_indexAggregator,
			true
		);

		if (_isBadOracleResponse(currentResponse)) {
			revert ResponseFromOracleIsInvalid(_token, _priceAggregator);
		}

		if (_isBadOracleResponse(currentResponseIndex)) {
			revert ResponseFromOracleIsInvalid(_token, _indexAggregator);
		}

		emit OracleAdded(_token, _priceAggregator, _indexAggregator);
	}

	function getPrice(address _token)
		public
		view
		override
		returns (OracleAnswer memory answer_)
	{
		Aggregators memory tokenAggregators = aggregators[_token];

		if (tokenAggregators.price == address(0)) {
			revert TokenIsNotRegistered(_token);
		}

		(
			ChainlinkWrappedReponse memory currentResponse,
			ChainlinkWrappedReponse memory previousResponse
		) = _getResponses(tokenAggregators.price, false);

		(
			ChainlinkWrappedReponse memory currentResponseIndex,
			ChainlinkWrappedReponse memory previousResponseIndex
		) = _getResponses(tokenAggregators.index, true);

		if (
			_isBadOracleResponse(currentResponse) ||
			_isBadOracleResponse(currentResponseIndex)
		) {
			return answer_;
		}

		answer_.currentPrice = _sanitizePrice(
			currentResponse.answer,
			currentResponseIndex.answer
		);

		answer_.lastPrice = _sanitizePrice(
			previousResponse.answer,
			previousResponseIndex.answer
		);

		answer_.lastUpdate = currentResponse.timestamp;

		return answer_;
	}

	function _getResponses(address _aggregator, bool _isIndex)
		internal
		view
		returns (
			ChainlinkWrappedReponse memory currentResponse_,
			ChainlinkWrappedReponse memory lastResponse_
		)
	{
		if (_aggregator == address(0) && _isIndex) {
			currentResponse_ = ChainlinkWrappedReponse(1, 18, 1 ether, block.timestamp);
			lastResponse_ = currentResponse_;
		} else {
			currentResponse_ = _getCurrentChainlinkResponse(
				AggregatorV2V3Interface(_aggregator)
			);
			lastResponse_ = _getPrevChainlinkResponse(
				AggregatorV2V3Interface(_aggregator),
				currentResponse_.roundId,
				currentResponse_.decimals
			);
		}

		return (currentResponse_, lastResponse_);
	}

	function _getCurrentChainlinkResponse(AggregatorV2V3Interface _aggregator)
		internal
		view
		returns (ChainlinkWrappedReponse memory oracleResponse_)
	{
		if (!_isSequencerUp()) {
			return oracleResponse_;
		}

		try _aggregator.decimals() returns (uint8 decimals) {
			if (decimals == 0) return oracleResponse_;

			oracleResponse_.decimals = decimals;
		} catch {
			return oracleResponse_;
		}

		try _aggregator.latestRoundData() returns (
			uint80 roundId,
			int256 answer,
			uint256, /* startedAt */
			uint256 timestamp,
			uint80 /* answeredInRound */
		) {
			oracleResponse_.roundId = roundId;
			oracleResponse_.answer = scalePriceByDigits(
				uint256(answer),
				oracleResponse_.decimals
			);
			oracleResponse_.timestamp = timestamp;
		} catch {}

		return oracleResponse_;
	}

	function _getPrevChainlinkResponse(
		AggregatorV2V3Interface _aggregator,
		uint80 _currentRoundId,
		uint8 _currentDecimals
	) internal view returns (ChainlinkWrappedReponse memory prevOracleResponse_) {
		if (_currentRoundId == 0) {
			return prevOracleResponse_;
		}

		try _aggregator.getRoundData(_currentRoundId - 1) returns (
			uint80 roundId,
			int256 answer,
			uint256, /* startedAt */
			uint256 timestamp,
			uint80 /* answeredInRound */
		) {
			if (answer == 0) return prevOracleResponse_;

			prevOracleResponse_.roundId = roundId;
			prevOracleResponse_.answer = scalePriceByDigits(
				uint256(answer),
				_currentDecimals
			);
			prevOracleResponse_.timestamp = timestamp;
			prevOracleResponse_.decimals = _currentDecimals;
		} catch {}

		return prevOracleResponse_;
	}

	function _sanitizePrice(uint256 price, uint256 index)
		internal
		pure
		returns (uint256)
	{
		return VestaMath.mulDiv(price, index, 1e18);
	}

	function _isBadOracleResponse(ChainlinkWrappedReponse memory _answer)
		internal
		view
		returns (bool)
	{
		return (_answer.answer == 0 ||
			_answer.roundId == 0 ||
			_answer.timestamp > block.timestamp ||
			_answer.timestamp == 0 ||
			!_isSequencerUp());
	}

	function _isSequencerUp() internal view returns (bool sequencerIsUp) {
		(, int256 answer, , uint256 updatedAt, ) = sequencerUptimeFeed.latestRoundData();

		return (answer == 0 && (block.timestamp - updatedAt) < 3600);
	}

	function removeOracle(address _token) external onlyOwner {
		delete aggregators[_token];
		emit OracleRemoved(_token);
	}

	function getAggregators(address _token)
		external
		view
		override
		returns (Aggregators memory)
	{
		return aggregators[_token];
	}
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.0;

import { Aggregators } from "../../model/ChainlinksModels.sol";

interface IChainlinkWrapper {
	event OracleAdded(
		address indexed token,
		address priceAggregator,
		address indexAggregator
	);

	event OracleRemoved(address indexed token);

	/**
	 * @notice getAggregators returns the price and index aggregator used for a token
	 * @param _token the token address
	 * @return Aggregators structure
	 */
	function getAggregators(address _token) external view returns (Aggregators memory);
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.0;

struct ChainlinkWrappedReponse {
	uint80 roundId;
	uint8 decimals;
	uint256 answer;
	uint256 timestamp;
}

struct Aggregators {
	address price;
	address index;
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

import { BaseWrapper } from "./BaseWrapper.sol";
import { ICustomOracleWrapper } from "../interface/wrapper/ICustomOracleWrapper.sol";

import { OracleAnswer } from "../model/OracleModels.sol";
import "../model/CustomOracleModels.sol";

import { AddressCalls } from "../lib/AddressCalls.sol";
import { VestaMath } from "../../../lib/VestaMath.sol";

contract CustomOracleWrapper is BaseWrapper, ICustomOracleWrapper {
	mapping(address => CustomOracle) private oracles;

	function setUp() external initializer {
		__BASE_VESTA_INIT();
	}

	function getPrice(address _token)
		external
		view
		override
		returns (OracleAnswer memory answer_)
	{
		CustomOracle memory oracle = oracles[_token];
		if (oracle.contractAddress == address(0)) {
			revert TokenIsNotRegistered(_token);
		}

		uint8 decimals = _getDecimals(
			oracle.contractAddress,
			oracle.callDecimals,
			oracle.decimals
		);

		answer_.lastUpdate = _getLastUpdate(
			oracle.contractAddress,
			oracle.callLastUpdate
		);

		answer_.currentPrice = scalePriceByDigits(
			_getPrice(oracle.contractAddress, oracle.callCurrentPrice),
			decimals
		);

		uint256 lastPrice = _getPrice(oracle.contractAddress, oracle.callLastPrice);

		answer_.lastPrice = (lastPrice == 0)
			? answer_.currentPrice
			: scalePriceByDigits(lastPrice, decimals);

		return answer_;
	}

	function _getDecimals(
		address _contractAddress,
		bytes memory _callData,
		uint8 _default
	) internal view returns (uint8) {
		(uint8 response, bool success) = AddressCalls.callReturnsUint8(
			_contractAddress,
			_callData
		);

		return success ? response : _default;
	}

	function _getPrice(address _contractAddress, bytes memory _callData)
		internal
		view
		returns (uint256)
	{
		(uint256 response, bool success) = AddressCalls.callReturnsUint256(
			_contractAddress,
			_callData
		);

		return success ? response : 0;
	}

	function _getLastUpdate(address _contractAddress, bytes memory _callData)
		internal
		view
		returns (uint256)
	{
		(uint256 response, bool success) = AddressCalls.callReturnsUint256(
			_contractAddress,
			_callData
		);

		return success ? response : block.timestamp;
	}

	function addOracle(
		address _token,
		address _externalOracle,
		uint8 _decimals,
		bytes memory _callCurrentPrice,
		bytes memory _callLastPrice,
		bytes memory _callLastUpdate,
		bytes memory _callDecimals
	) external onlyOwner onlyContract(_externalOracle) notZero(_decimals) {
		oracles[_token] = CustomOracle(
			_externalOracle,
			_decimals,
			_callCurrentPrice,
			_callLastPrice,
			_callLastUpdate,
			_callDecimals
		);

		if (_getPrice(_externalOracle, _callCurrentPrice) == 0) {
			revert ResponseFromOracleIsInvalid(_token, _externalOracle);
		}

		emit OracleAdded(_token, _externalOracle);
	}

	function removeOracle(address _token) external onlyOwner {
		delete oracles[_token];

		emit OracleRemoved(_token);
	}

	function getOracle(address _token)
		external
		view
		override
		returns (CustomOracle memory)
	{
		return oracles[_token];
	}
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.0;

import { CustomOracle } from "../../model/CustomOracleModels.sol";

interface ICustomOracleWrapper {
	event OracleAdded(address indexed _token, address _externalOracle);
	event OracleRemoved(address indexed _token);

	/**
	 * @notice getOracle returns the configured info of the custom oracle
	 * @param _token the address of the token
	 * @return CustomOracle structure
	 */
	function getOracle(address _token) external view returns (CustomOracle memory);
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.0;

struct CustomOracle {
	address contractAddress;
	uint8 decimals;
	bytes callCurrentPrice;
	bytes callLastPrice;
	bytes callLastUpdate;
	bytes callDecimals;
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

library AddressCalls {
	function callReturnsUint8(address _contract, bytes memory _callData)
		internal
		view
		returns (uint8, bool)
	{
		if (keccak256(_callData) == keccak256("")) return (0, false);

		(bool success, bytes memory response) = call(_contract, _callData);

		if (success) {
			return (abi.decode(response, (uint8)), true);
		}

		return (0, false);
	}

	function callReturnsUint256(address _contract, bytes memory _callData)
		internal
		view
		returns (uint256, bool)
	{
		if (keccak256(_callData) == keccak256("")) return (0, false);

		(bool success, bytes memory response) = call(_contract, _callData);

		if (success) {
			return (abi.decode(response, (uint256)), true);
		}

		return (0, false);
	}

	function callReturnsBytes32(address _contract, bytes memory _callData)
		internal
		view
		returns (bytes32, bool)
	{
		if (keccak256(_callData) == keccak256("")) return ("", false);

		(bool success, bytes memory response) = call(_contract, _callData);

		if (success) {
			return (abi.decode(response, (bytes32)), true);
		}

		return ("", false);
	}

	function call(address _contract, bytes memory _callData)
		internal
		view
		returns (bool success, bytes memory response)
	{
		if (keccak256(_callData) == keccak256("")) return (false, response);

		if (_contract == address(0)) {
			return (false, response);
		}

		return _contract.staticcall(_callData);
	}
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

import "../../BaseVesta.sol";
import { IPriceFeed } from "./interface/IPriceFeed.sol";

import { Oracle, OracleAnswer } from "./model/OracleModels.sol";
import { IOracleVerificationV1 as Verificator } from "./interface/IOracleVerificationV1.sol";
import { IOracleWrapper } from "./interface/IOracleWrapper.sol";

contract PriceFeed is BaseVesta, IPriceFeed {
	Verificator public verificator;

	mapping(address => uint256) private lastGoodPrice;
	mapping(address => Oracle) private oracles;

	function setUp(address _verificator)
		external
		initializer
		onlyContract(_verificator)
	{
		__BASE_VESTA_INIT();
		verificator = Verificator(_verificator);
	}

	function fetchPrice(address _token) external override returns (uint256) {
		Oracle memory oracle = oracles[_token];

		if (oracle.primaryWrapper == address(0)) revert OracleNotFound();
		if (oracle.disabled) revert OracleDisabled();

		uint256 lastPrice = lastGoodPrice[_token];
		uint256 goodPrice = _getValidPrice(
			_token,
			oracle.primaryWrapper,
			oracle.secondaryWrapper,
			lastPrice
		);

		if (lastPrice != goodPrice) {
			lastGoodPrice[_token] = goodPrice;
			emit TokenPriceUpdated(_token, goodPrice);
		}

		return goodPrice;
	}

	function _getValidPrice(
		address _token,
		address primary,
		address secondary,
		uint256 lastPrice
	) internal view returns (uint256) {
		OracleAnswer memory primaryResponse = IOracleWrapper(primary).getPrice(_token);

		OracleAnswer memory secondaryResponse = secondary == address(0)
			? OracleAnswer(0, 0, 0)
			: IOracleWrapper(secondary).getPrice(_token);

		return verificator.verify(lastPrice, [primaryResponse, secondaryResponse]);
	}

	function addOracle(
		address _token,
		address _primaryOracle,
		address _secondaryOracle
	) external onlyOwner onlyContract(_primaryOracle) {
		Oracle storage oracle = oracles[_token];
		oracle.primaryWrapper = _primaryOracle;
		oracle.secondaryWrapper = _secondaryOracle;
		uint256 price = _getValidPrice(_token, _primaryOracle, _secondaryOracle, 0);

		if (price == 0) revert OracleDown();

		lastGoodPrice[_token] = price;

		emit OracleAdded(_token, _primaryOracle, _secondaryOracle);
	}

	function removeOracle(address _token) external onlyOwner {
		delete oracles[_token];
		emit OracleRemoved(_token);
	}

	function setOracleDisabledState(address _token, bool _disabled)
		external
		onlyOwner
	{
		oracles[_token].disabled = _disabled;
		emit OracleDisabledStateChanged(_token, _disabled);
	}

	function changeVerificator(address _verificator)
		external
		onlyOwner
		onlyContract(_verificator)
	{
		verificator = Verificator(_verificator);
		emit OracleVerificationChanged(_verificator);
	}

	function getOracle(address _token) external view override returns (Oracle memory) {
		return oracles[_token];
	}

	function isOracleDisabled(address _token) external view override returns (bool) {
		return oracles[_token].disabled;
	}

	function getLastUsedPrice(address _token)
		external
		view
		override
		returns (uint256)
	{
		return lastGoodPrice[_token];
	}

	function getExternalPrice(address _token)
		external
		view
		override
		returns (uint256[2] memory answers_)
	{
		Oracle memory oracle = oracles[_token];

		if (oracle.primaryWrapper == address(0)) {
			revert UnsupportedToken();
		}

		answers_[0] = IOracleWrapper(oracle.primaryWrapper)
			.getPrice(_token)
			.currentPrice;

		if (oracle.secondaryWrapper != address(0)) {
			answers_[1] = IOracleWrapper(oracle.secondaryWrapper)
				.getPrice(_token)
				.currentPrice;
		}

		return answers_;
	}
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.0;

import { Oracle } from "../model/OracleModels.sol";

interface IPriceFeed {
	event OracleAdded(
		address indexed token,
		address primaryWrappedOracle,
		address secondaryWrappedOracle
	);
	event OracleRemoved(address indexed token);
	event OracleVerificationChanged(address indexed newVerificator);
	event OracleDisabledStateChanged(address indexed token, bool isDisabled);

	event TokenPriceUpdated(address indexed token, uint256 price);
	event AccessChanged(address indexed token, bool hasAccess);

	error OracleDisabled();
	error OracleDown();
	error OracleNotFound();
	error UnsupportedToken();

	/**
	 * @notice fetchPrice returns the safest price
	 * @param _token the address of the token
	 */
	function fetchPrice(address _token) external returns (uint256);

	/**
	 * @notice getOracle will return the configuration for the token
	 * @param _token the address of the token
	 * @return oracle_ Oracle strcuture
	 */
	function getOracle(address _token) external view returns (Oracle memory);

	/**
	 * @notice isOracleDisabled will return the disabled state of the oracle
	 * @param _token the address of the token
	 * @return disabled_ The disabled state
	 */
	function isOracleDisabled(address _token) external view returns (bool);

	/**
	 * @notice getLastUsedPrice returns the last price used by the system
	 * @dev This should never be used! This is informative usage only
	 * @param _token the address of the token
	 * @return lastPrice_ last price used by the protocol
	 */
	function getLastUsedPrice(address _token) external view returns (uint256);

	/**
	 * @notice getExternalPrice returns the current price without any checks
	 * @dev secondary oracle can be null, in this case, the value will be zero
	 * @param _token address of the token
	 * @return answers_ [primary oracle price, secondary oracle price]
	 */
	function getExternalPrice(address _token)
		external
		view
		returns (uint256[2] memory);
}

// SPDX-License-Identifier:SEE LICENSE IN LICENSE
pragma solidity >=0.8.0;

import { OracleAnswer } from "../model/OracleModels.sol";

interface IOracleVerificationV1 {
	/**
	 * @notice verify will check the answers and choose wisely between the primary, secondary or lastGoodPrice
	 * @param _lastGoodPrice the last price used by the protocol
	 * @param _oracleAnswers the answers from the primary and secondary oracle
	 * @return price the safest price
	 */
	function verify(uint256 _lastGoodPrice, OracleAnswer[2] calldata _oracleAnswers)
		external
		view
		returns (uint256);
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

import "../interface/IOracleVerificationV1.sol";
import "../lib/TimeoutChecker.sol";
import "../../../lib/VestaMath.sol";

contract OracleVerificationV1 is IOracleVerificationV1 {
	uint256 private constant MAX_PRICE_DEVIATION_FROM_PREVIOUS_ROUND = 5e17; // 50%
	uint256 private constant MAX_PRICE_DIFFERENCE_BETWEEN_ORACLES = 5e16; // 5%
	uint256 private constant TIMEOUT = 25 hours;

	function verify(uint256 _lastGoodPrice, OracleAnswer[2] calldata _oracleAnswers)
		external
		view
		override
		returns (uint256 value)
	{
		bool isPrimaryOracleBroken = _isRequestBroken(_oracleAnswers[0]);
		bool isSecondaryOracleBroken = _isRequestBroken(_oracleAnswers[1]);

		bool oraclesHaveSamePrice = _bothOraclesSimilarPrice(
			_oracleAnswers[0].currentPrice,
			_oracleAnswers[1].currentPrice
		);

		bool primaryPriceIsAboveMax = _priceChangeAboveMax(
			_oracleAnswers[0].currentPrice,
			_oracleAnswers[0].lastPrice
		);

		bool secondaryPriceIsAboveMax = _priceChangeAboveMax(
			_oracleAnswers[1].currentPrice,
			_oracleAnswers[1].lastPrice
		);

		//prettier-ignore
		if (!isPrimaryOracleBroken) {
			if (primaryPriceIsAboveMax) {
				if (isSecondaryOracleBroken || secondaryPriceIsAboveMax) {
					return _lastGoodPrice;
				}

				return _oracleAnswers[1].currentPrice;
			}
			else if(!oraclesHaveSamePrice && !secondaryPriceIsAboveMax) {
				return _lastGoodPrice;
			}
			
			return _oracleAnswers[0].currentPrice;
		}
		else if (!isSecondaryOracleBroken) {
			if (secondaryPriceIsAboveMax) {
				return _lastGoodPrice;
			}

			return _oracleAnswers[1].currentPrice;
		}

		return _lastGoodPrice;
	}

	function _isRequestBroken(OracleAnswer memory response)
		internal
		view
		returns (bool)
	{
		bool isTimeout = TimeoutChecker.isTimeout(response.lastUpdate, TIMEOUT);
		return isTimeout || response.currentPrice == 0 || response.lastPrice == 0;
	}

	function _priceChangeAboveMax(uint256 _currentResponse, uint256 _prevResponse)
		internal
		pure
		returns (bool)
	{
		if (_currentResponse == 0 && _prevResponse == 0) return false;

		uint256 minPrice = VestaMath.min(_currentResponse, _prevResponse);
		uint256 maxPrice = VestaMath.max(_currentResponse, _prevResponse);

		uint256 percentDeviation = VestaMath.mulDiv(
			(maxPrice - minPrice),
			1e18,
			maxPrice
		);

		return percentDeviation > MAX_PRICE_DEVIATION_FROM_PREVIOUS_ROUND;
	}

	function _bothOraclesSimilarPrice(
		uint256 _primaryOraclePrice,
		uint256 _secondaryOraclePrice
	) internal pure returns (bool) {
		if (_primaryOraclePrice == 0) return false;
		if (_secondaryOraclePrice == 0) return true;

		uint256 minPrice = VestaMath.min(_primaryOraclePrice, _secondaryOraclePrice);
		uint256 maxPrice = VestaMath.max(_primaryOraclePrice, _secondaryOraclePrice);

		uint256 percentPriceDifference = VestaMath.mulDiv(
			(maxPrice - minPrice),
			1e18,
			minPrice
		);

		return percentPriceDifference <= MAX_PRICE_DIFFERENCE_BETWEEN_ORACLES;
	}
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

library TimeoutChecker {
	function isTimeout(uint256 timestamp, uint256 timeout)
		internal
		view
		returns (bool)
	{
		if (block.timestamp < timestamp) return true;
		return block.timestamp - timestamp > timeout;
	}
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

import "../../../BaseVesta.sol";
import "./ILendingParameters.sol";

/**
@title LendingParameters
@notice Holds the parameters of the Lending Service
@dev All percentages are in BPS. (1e18 / 10_000) * X BPS = Y%
	 BPS = percentage wanted * 100
	 BPS in ether = percentage wanted / 100 ether
*/

contract LendingParameters is ILendingParameters, BaseVesta {
	bytes1 public constant CONFIG = 0x01;

	CompactedParameters private DEFAULT_PARAMTERS =
		CompactedParameters({
			mintCap: 0,
			stabilityPoolLiquidationRatio: 1.1 ether, // 110%
			stabilityPoolLiquidationBonus: 0.1 ether, // 10%
			borrowingFeeFloor: 0.005 ether, // 0.5%
			borrowingMaxFloor: 0.05 ether, // 5%
			redemptionFeeFloor: 0.005 ether, // 0.5%
			lockable: false,
			riskable: false
		});

	uint256 private gasCompensation = 30 ether;
	uint256 private minimumNetDebt = 300 ether;
	uint256 private liquidationCompensationCollateral = 0.01 ether; //1%

	mapping(address => CompactedParameters) lendingServiceParameters;

	function setUp() external initializer {
		__BASE_VESTA_INIT();
	}

	function setGasCompensation(uint256 _gasCompensation)
		external
		override
		hasPermissionOrOwner(CONFIG)
	{
		gasCompensation = _gasCompensation;
		emit GasCompensationChanged(gasCompensation);
	}

	function setMinimumNetDebt(uint256 _minDebt)
		external
		override
		hasPermissionOrOwner(CONFIG)
	{
		minimumNetDebt = _minDebt;
		emit MinimumNetDebtChanged(minimumNetDebt);
	}

	function setLendingServiceParameters(
		address _lendingService,
		CompactedParameters calldata _parameters
	) external override hasPermissionOrOwner(CONFIG) {
		lendingServiceParameters[_lendingService] = _parameters;
		emit ParameterChanged(_lendingService, _parameters);
	}

	function setLendingServiceParametersToDefault(address _lendingService)
		external
		override
		hasPermissionOrOwner(CONFIG)
	{
		lendingServiceParameters[_lendingService] = DEFAULT_PARAMTERS;
		emit ParameterChanged(_lendingService, DEFAULT_PARAMTERS);
	}

	function setDefaultParameters(CompactedParameters calldata _parameters)
		external
		onlyOwner
	{
		DEFAULT_PARAMTERS = _parameters;
		emit DefaultParametersChanged(_parameters);
	}

	function getGasCompensation() external view override returns (uint256) {
		return gasCompensation;
	}

	function getMinimumNetDebt() external view override returns (uint256) {
		return minimumNetDebt;
	}

	function getMintCap(address _lendingService)
		external
		view
		override
		returns (uint256)
	{
		return lendingServiceParameters[_lendingService].mintCap;
	}

	function getLiquidationParameters(address _lendingService)
		external
		view
		override
		returns (
			uint64 stabilityPoolLiquidationRatio_,
			uint64 stabilityPoolLiquidationBonus_,
			uint256 liquidationCompensationCollateral_
		)
	{
		CompactedParameters memory parameter = lendingServiceParameters[_lendingService];
		return (
			parameter.stabilityPoolLiquidationRatio,
			parameter.stabilityPoolLiquidationBonus,
			liquidationCompensationCollateral
		);
	}

	function getBorrowingFeeFloors(address _lendingService)
		external
		view
		override
		returns (uint64 floor_, uint64 maxFloor_)
	{
		CompactedParameters memory parameter = lendingServiceParameters[_lendingService];
		return (parameter.borrowingFeeFloor, parameter.borrowingMaxFloor);
	}

	function isLockable(address _lendingService)
		external
		view
		override
		returns (bool)
	{
		return lendingServiceParameters[_lendingService].lockable;
	}

	function isRiskable(address _lendingService)
		external
		view
		override
		returns (bool)
	{
		return lendingServiceParameters[_lendingService].riskable;
	}

	function getAssetParameters(address _lendingService)
		external
		view
		override
		returns (CompactedParameters memory)
	{
		return lendingServiceParameters[_lendingService];
	}

	function getDefaultParameters()
		external
		view
		override
		returns (CompactedParameters memory)
	{
		return DEFAULT_PARAMTERS;
	}
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.0;

import { CompactedParameters } from "./ParameterModel.sol";

interface ILendingParameters {
	event ParameterChanged(address indexed asset, CompactedParameters parameters);
	event GasCompensationChanged(uint256 gasCompensation);
	event MinimumNetDebtChanged(uint256 minimumDebt);
	event DefaultParametersChanged(CompactedParameters);

	/** 
	@notice setGasCompensation to change the whole protocol gas compensation
	@dev requires CONFIG or Owner permission to execute this function
	@param _gasCompensation new gas compensation value
	*/
	function setGasCompensation(uint256 _gasCompensation) external;

	/** 
	@notice setMinimumNetDebt to change the minimum debt to open a vault in the system
	@dev requires CONFIG or Owner permission to execute this function
	@param _minDebt new gas minimum net debt value
	*/
	function setMinimumNetDebt(uint256 _minDebt) external;

	/** 
	@notice setLendingServiceParameters to change the parameters of a specific asset 
	@dev requires CONFIG or Owner permission to execute this function
	@param _lendingService address of the Lending Service
	@param _parameters new parameters
	*/
	function setLendingServiceParameters(
		address _lendingService,
		CompactedParameters calldata _parameters
	) external;

	/** 
	@notice setLendingServiceParametersToDefault to put an asset to the default protocol values
	@dev requires CONFIG or Owner permission to execute this function
	@param _lendingService address of the Lending Service
	*/
	function setLendingServiceParametersToDefault(address _lendingService) external;

	/** 
	@notice getGasCompensation to get the current gas compensation value
	@return gasCompensation current value
	*/
	function getGasCompensation() external view returns (uint256);

	/** 
	@notice getMinimumNetDebt to get the current minimum net debt value
	@return minimumNetDebt current value
	*/
	function getMinimumNetDebt() external view returns (uint256);

	/** 
	@notice getMintCap to get the maxmimum mint cap of vst
	@dev 0 means unlimited / uncapped
	@param _lendingService address of the Lending Service
	@return mintCap return the max mintable vst from this asset
	*/
	function getMintCap(address _lendingService) external view returns (uint256);

	/** 
	@notice getLiquidationParameters to get liquidation info of an asset
	@param _lendingService address of the Lending Service
	@return stabilityPoolLiquidationRatio_ is the ratio that a vault will get liquidated
	@return stabilityPoolLiquidationBonus_ is the percentage that goes to Stability pool
	@return liquidationCompensationCollateral_ is the percentage that goes to the caller for gas compensation
	*/
	function getLiquidationParameters(address _lendingService)
		external
		view
		returns (
			uint64 stabilityPoolLiquidationRatio_,
			uint64 stabilityPoolLiquidationBonus_,
			uint256 liquidationCompensationCollateral_
		);

	/** 
	@notice getBorrowingFeeFloors to get the fee floors of an asset
	@param _lendingService address of the Lending Service
	@return floor_ is the minimum the user need to accept as fee
	@return maxFloor_ is the maximum fee that can be accepted
	*/
	function getBorrowingFeeFloors(address _lendingService)
		external
		view
		returns (uint64 floor_, uint64 maxFloor_);

	/** 
	@notice isLockable check if the asset can be locked
	@param _lendingService address of the Lending Service
	@return isLocakble
	*/
	function isLockable(address _lendingService) external view returns (bool);

	/** 
	@notice isRiskable check if the asset can use in the riskzone
	@param _lendingService address of the Lending Service
	@return isRiskable
	*/
	function isRiskable(address _lendingService) external view returns (bool);

	/** 
	@notice getAssetParameters to get the parameters of an asset
	@param _lendingService address of the Lending Service
	@return compactedParameters all the parameters of the asset
	*/
	function getAssetParameters(address _lendingService)
		external
		view
		returns (CompactedParameters memory);

	/** 
	@notice getDefaultParameters returns the default constant of the protocol
	@return defaultParameters return the private constant DEFAULT_PARAMETERS
	*/
	function getDefaultParameters() external view returns (CompactedParameters memory);
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.0;

struct CompactedParameters {
	uint192 mintCap;
	uint64 stabilityPoolLiquidationRatio;
	uint64 stabilityPoolLiquidationBonus;
	uint64 borrowingFeeFloor;
	uint64 borrowingMaxFloor;
	uint64 redemptionFeeFloor;
	bool lockable;
	bool riskable;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract Contract {}