// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "./interface/IBaseVesta.sol";

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
	address internal constant RESERVED_ETH_ADDRESS = address(0);
	uint256 internal constant MAX_UINT256 = type(uint256).max;

	address internal SELF;
	bool private reentrencyStatus;

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
		SELF = address(this);
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import { IVestaDexTrader } from "./interface/IVestaDexTrader.sol";
import "./model/TradingModel.sol";
import "./interface/dex/curve/ICurvePool.sol";

import "./interface/ITrader.sol";
import { IERC20, TokenTransferrer } from "./lib/token/TokenTransferrer.sol";
import "./BaseVesta.sol";

/**
	Selectors (bytes16(keccak256("TRADER_FILE_NAME")))
	UniswapV3Trader: 0x0fa74b3ade106cd68a66c0ef6dfe2154
	CurveTrader: 0x79402703bca5d67f15c4e7e9841e7231
	UniswapV2Trader: 0x7eb272ca6b6d9e128a5589927962ba6d
	GMXTrader: 0xdc7e0e193e9fe90a4a7fbe7a768857c8
 */
contract VestaDexTrader is IVestaDexTrader, TokenTransferrer, BaseVesta {
	mapping(address => bool) internal registeredTrader;
	mapping(bytes16 => address) internal tradersAddress;

	function setUp() external initializer {
		__BASE_VESTA_INIT();
	}

	function registerTrader(bytes16 _selector, address _trader) external onlyOwner {
		registeredTrader[_trader] = true;
		tradersAddress[_selector] = _trader;

		emit TraderRegistered(_trader, _selector);
	}

	function removeTrader(bytes16 _selector, address _trader) external onlyOwner {
		delete registeredTrader[_trader];
		delete tradersAddress[_selector];

		emit TraderRemoved(_trader);
	}

	function exchange(
		address _receiver,
		address _firstTokenIn,
		uint256 _firstAmountIn,
		ManualExchange[] calldata _requests
	)
		external
		override
		onlyValidAddress(_receiver)
		returns (uint256[] memory swapDatas_)
	{
		uint256 length = _requests.length;

		if (length == 0) revert EmptyRequest();

		swapDatas_ = new uint256[](length);

		_performTokenTransferFrom(_firstTokenIn, msg.sender, SELF, _firstAmountIn);

		ManualExchange memory currentManualExchange;
		uint256 nextIn = _firstAmountIn;
		address trader;

		for (uint256 i = 0; i < length; ++i) {
			currentManualExchange = _requests[i];
			trader = tradersAddress[currentManualExchange.traderSelector];

			if (trader == address(0)) {
				revert InvalidTraderSelector();
			}

			_tryPerformMaxApprove(currentManualExchange.tokenInOut[0], trader);

			nextIn = ITrader(trader).exchange(
				i == length - 1 ? _receiver : SELF,
				_getFulfilledSwapRequest(
					currentManualExchange.traderSelector,
					currentManualExchange.data,
					nextIn
				)
			);

			swapDatas_[i] = nextIn;
		}

		emit SwapExecuted(
			msg.sender,
			_receiver,
			[_firstTokenIn, _requests[length - 1].tokenInOut[1]],
			[_firstAmountIn, swapDatas_[length - 1]]
		);

		return swapDatas_;
	}

	function _getFulfilledSwapRequest(
		bytes16 _traderSelector,
		bytes memory _encodedData,
		uint256 _amountIn
	) internal pure returns (bytes memory) {
		//UniswapV3Trader
		if (_traderSelector == 0x0fa74b3ade106cd68a66c0ef6dfe2154) {
			//Setting UniswapV3SwapRequest::expectedAmountIn
			assembly {
				mstore(add(_encodedData, 0x80), _amountIn)
			}

			return _encodedData;
		}
		//Cruve
		else if (_traderSelector == 0x79402703bca5d67f15c4e7e9841e7231) {
			//Setting CurveSwapRequest::expectedAmountIn
			//Setting CurveSwapRequest::slippage (if slippage != 0)
			assembly {
				mstore(add(_encodedData, 0x80), _amountIn)
			}

			return _encodedData;
		} else {
			//Setting GenericSwapRequest::expectedAmountIn
			assembly {
				mstore(add(_encodedData, 0x60), _amountIn)
			}

			return _encodedData;
		}
	}

	function getAmountIn(uint256 _amountOut, ManualExchange[] calldata _requests)
		external
		override
		returns (uint256 amountIn_)
	{
		uint256 length = _requests.length;

		ManualExchange memory path;
		address trader;

		uint256 lastAmountOut = _amountOut;
		while (length > 0) {
			length--;

			path = _requests[length];
			trader = tradersAddress[path.traderSelector];

			lastAmountOut = ITrader(trader).getAmountIn(
				_getFulfilledGetAmountInOut(path.traderSelector, path.data, lastAmountOut)
			);
		}

		return lastAmountOut;
	}

	function getAmountOut(uint256 _amountIn, ManualExchange[] calldata _requests)
		external
		override
		returns (uint256 amountOut_)
	{
		uint256 length = _requests.length;

		ManualExchange memory path;
		address trader;

		uint256 lastAmountIn = _amountIn;
		for (uint256 i = 0; i < length; ++i) {
			path = _requests[i];
			trader = tradersAddress[path.traderSelector];

			lastAmountIn = ITrader(trader).getAmountOut(
				_getFulfilledGetAmountInOut(path.traderSelector, path.data, lastAmountIn)
			);
		}

		return lastAmountIn;
	}

	function _getFulfilledGetAmountInOut(
		bytes16 _traderSelector,
		bytes memory _encodedData,
		uint256 _amount
	) internal pure returns (bytes memory) {
		if (_traderSelector == 0x0fa74b3ade106cd68a66c0ef6dfe2154) {
			UniswapV3SwapRequest memory request = abi.decode(
				_encodedData,
				(UniswapV3SwapRequest)
			);

			return
				abi.encode(
					UniswapV3RequestExactInOutParams(
						request.path,
						request.tokenIn,
						_amount,
						request.usingHop
					)
				);
		} else if (_traderSelector == 0x79402703bca5d67f15c4e7e9841e7231) {
			CurveSwapRequest memory request = abi.decode(_encodedData, (CurveSwapRequest));

			return
				abi.encode(
					CurveRequestExactInOutParams(
						request.pool,
						request.coins,
						_amount,
						request.slippage
					)
				);
		} else {
			GenericSwapRequest memory request = abi.decode(
				_encodedData,
				(GenericSwapRequest)
			);

			return abi.encode(GenericRequestExactInOutParams(request.path, _amount));
		}
	}

	function isRegisteredTrader(address _trader)
		external
		view
		override
		returns (bool)
	{
		return registeredTrader[_trader];
	}

	function getTraderAddressWithSelector(bytes16 _selector)
		external
		view
		override
		returns (address)
	{
		return tradersAddress[_selector];
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { ManualExchange } from "../model/TradingModel.sol";

interface IVestaDexTrader {
	error InvalidTraderSelector();
	error TraderFailed(address trader, bytes returnedCallData);
	error FailedToReceiveExactAmountOut(uint256 minimumAmount, uint256 receivedAmount);
	error TraderFailedMaxAmountInExceeded(
		uint256 maximumAmountIn,
		uint256 requestedAmountIn
	);
	error RoutingNotFound();
	error EmptyRequest();

	event TraderRegistered(address indexed trader, bytes16 selector);
	event TraderRemoved(address indexed trader);
	event RouteUpdated(address indexed tokenIn, address indexed tokenOut);
	event SwapExecuted(
		address indexed executor,
		address indexed receiver,
		address[2] tokenInOut,
		uint256[2] amountInOut
	);

	/**
	 * exchange uses Vesta's traders but with your own routing.
	 * @param _receiver the wallet that will receives the output token
	 * @param _firstTokenIn the token that will be swapped
	 * @param _firstAmountIn the amount of Token In you will send
	 * @param _requests Your custom routing
	 * @return swapDatas_ elements are the amountOut from each swaps
	 *
	 * @dev this function only uses expectedAmountIn
	 */
	function exchange(
		address _receiver,
		address _firstTokenIn,
		uint256 _firstAmountIn,
		ManualExchange[] calldata _requests
	) external returns (uint256[] memory swapDatas_);

	function getAmountIn(uint256 _amountOut, ManualExchange[] calldata _requests)
		external
		returns (uint256 amountIn_);

	function getAmountOut(uint256 _amountIn, ManualExchange[] calldata _requests)
		external
		returns (uint256 amountOut_);

	/**
	 * isRegisteredTrader check if a contract is a Trader
	 * @param _trader address of the trader
	 * @return registered_ is true if the trader is registered
	 */
	function isRegisteredTrader(address _trader) external view returns (bool);

	/**
	 * getTraderAddressWithSelector get Trader address with selector
	 * @param _selector Trader's selector
	 * @return address_ Trader's address
	 */
	function getTraderAddressWithSelector(bytes16 _selector)
		external
		view
		returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @param traderSelector the Selector of the Dex you want to use. If not sure, you can find them in VestaDexTrader.sol
 * @param tokenInOut the token0 is the one that will be swapped, the token1 is the one that will be returned
 * @param data the encoded structure for the exchange function of a ITrader.
 * @dev {data}'s structure should have 0 for expectedAmountIn and expectedAmountOut
 */
struct ManualExchange {
	bytes16 traderSelector;
	address[2] tokenInOut;
	bytes data;
}

/**
 * @param path
 * 	SingleHop: abi.encode(address tokenOut,uint24 poolFee);
 * 	MultiHop-ExactAmountIn: abi.encode(tokenIn, uint24 fee, tokenOutIn, fee, tokenOut);
 * @param tokenIn the token that will be swapped
 * @param expectedAmountIn the expected amount In that will be swapped
 * @param expectedAmountOut the expected amount Out that will be returned
 * @param amountInMaximum the maximum tokenIn that can be used
 * @param usingHop does it use a hop (multi-path)
 *
 * @dev you can only use one of the expectedAmount, not both.
 * @dev amountInMaximum can be zero
 */
struct UniswapV3SwapRequest {
	bytes path;
	address tokenIn;
	uint256 expectedAmountIn;
	uint256 expectedAmountOut;
	uint256 amountInMaximum;
	bool usingHop;
}

/**
 * @param pool the curve's pool address
 * @param coins coins0 is the token that goes in, coins1 is the token that goes out
 * @param expectedAmountIn the expect amount in that will be used
 * @param expectedAmountOut the expect amount out that the user will receives
 * @param slippage allowed slippage in BPS percentage
 * @dev {_slippage} is only used for curve and it is an addition to the expected amountIn that the system calculates.
		If the system expects amountIn to be 100 to have the exact amountOut, the total of amountIn WILL BE 110.
		You'll need it on major price impacts trading.
 *
 * @dev you can only use one of the expectedAmount, not both.
 * @dev slippage should only used by other contracts. Otherwise, do the formula off-chain and set it to zero.
 */
struct CurveSwapRequest {
	address pool;
	uint8[2] coins;
	uint256 expectedAmountIn;
	uint256 expectedAmountOut;
	uint16 slippage;
}

/**
 * @param path uses the token address to create the path
 * @param expectedAmountIn the expect amount in that will be used
 * @param expectedAmountOut the expect amount out that the user will receives
 *
 * @dev Path length should be 2 or 3. Otherwise, you are using it wrong!
 * @dev you can only use one of the expectedAmount, not both.
 */
struct GenericSwapRequest {
	address[] path;
	uint256 expectedAmountIn;
	uint256 expectedAmountOut;
}

/**
 * @param pool the curve's pool address
 * @param coins coins0 is the token that goes in, coins1 is the token that goes out
 * @param amount the amount wanted
 * @param slippage allowed slippage in BPS percentage
 * @dev {_slippage} is only used for curve and it is an addition to the expected amountIn that the system calculates.
		If the system expects amountIn to be 100 to have the exact amountOut, the total of amountIn WILL BE 110.
		You'll need it on major price impacts trading.
 */
struct CurveRequestExactInOutParams {
	address pool;
	uint8[2] coins;
	uint256 amount;
	uint16 slippage;
}

/**
 * @param path uses the token address to create the path
 * @param amount the wanted amount
 */
struct GenericRequestExactInOutParams {
	address[] path;
	uint256 amount;
}

/**
 * @param path
 * 	SingleHop: abi.encode(address tokenOut,uint24 poolFee);
 * 	MultiHop-ExactAmountIn: abi.encode(tokenIn, uint24 fee, tokenOutIn, fee, tokenOut);
 * @param tokenIn the token that will be swapped
 * @param amount the amount wanted
 * @param usingHop does it use a hop (multi-path)
 */
struct UniswapV3RequestExactInOutParams {
	bytes path;
	address tokenIn;
	uint256 amount;
	bool usingHop;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ICurvePool {
	function coins(uint256 arg) external view returns (address);

	function get_dy_underlying(
		int128 i,
		int128 j,
		uint256 dx
	) external view returns (uint256);

	function calc_withdraw_one_coin(uint256 _burn, int128 i)
		external
		view
		returns (uint256);

	function exchange(
		int128 i,
		int128 j,
		uint256 _dx,
		uint256 _min_dy,
		address _receiver
	) external returns (uint256);

	function exchange_underlying(
		int128 i,
		int128 j,
		uint256 _dx,
		uint256 _min_dy,
		address _receiver
	) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ITrader {
	error InvalidRequestEncoding();
	error AmountInAndOutAreZeroOrSameValue();

	/**
	 * exchange Execute a swap request
	 * @param receiver the wallet that will receives the outcome token
	 * @param _request the encoded request
	 */
	function exchange(address receiver, bytes memory _request)
		external
		returns (uint256 swapResponse_);

	/**
	 * getAmountIn get what your need for almost-exact amount in.
	 * @dev depending of the trader, some aren't exact but higher depending of the slippage
	 * @param _request the encoded request of InOutParams
	 */
	function getAmountIn(bytes memory _request) external returns (uint256);

	/**
	 * getAmountOut get what your need for exact amount out.
	 * @param _request the encoded request of InOutParams
	 */
	function getAmountOut(bytes memory _request) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./TokenTransferrerConstants.sol";
import { TokenTransferrerErrors } from "./TokenTransferrerErrors.sol";
import "../../interface/token/IERC20.sol";

/**
 * @title TokenTransferrer
 * @custom:source https://github.com/ProjectOpenSea/seaport
 * @dev Modified version of Seaport.
 */
abstract contract TokenTransferrer is TokenTransferrerErrors {
	function _performTokenTransfer(
		address token,
		address to,
		uint256 amount
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
	}

	function _performTokenTransferFrom(
		address token,
		address from,
		address to,
		uint256 amount
	) internal {
		if (token == address(0)) return;

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

		uint8 decimals = IERC20(token).decimals();

		if (decimals < 18) {
			return value / (10**(18 - decimals));
		}

		return value;
	}

	function _tryPerformMaxApprove(address token, address to) internal {
		if (IERC20(token).allowance(address(this), to) == type(uint256).max) {
			return;
		}

		require(IERC20(token).approve(to, type(uint256).max), "Approve Failed");
	}

	function _performApprove(
		address token,
		address to,
		uint256 value
	) internal {
		require(IERC20(token).approve(to, value), "Approve Failed");
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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
pragma solidity ^0.8.17;

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
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IERC20 {
	function decimals() external view returns (uint8);

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import { BaseTrader } from "../../BaseTrader.sol";

import { ISwapRouter } from "../../../interface/dex/uniswap/ISwapRouter.sol";
import { TokenTransferrer } from "../../../lib/token/TokenTransferrer.sol";

import { UniswapV3SwapRequest, UniswapV3RequestExactInOutParams as RequestExactInOutParams } from "../../../model/TradingModel.sol";
import "../../../model/UniswapV3Model.sol";

import { IQuoter } from "lib/uniswap-v3-periphery/contracts/interfaces/IQuoter.sol";

contract UniswapV3Trader is TokenTransferrer, BaseTrader {
	error InvalidPathEncoding();

	ISwapRouter public router;
	IQuoter public quoter;

	function setUp(address _router, address _quoter)
		external
		initializer
		onlyContract(_router)
		onlyContract(_quoter)
	{
		__BASE_VESTA_INIT();
		router = ISwapRouter(_router);
		quoter = IQuoter(_quoter);
	}

	function exchange(address _receiver, bytes memory _request)
		external
		override
		onlyValidAddress(_receiver)
		returns (uint256 swapResponse_)
	{
		UniswapV3SwapRequest memory request = _safeDecodeSwapRequest(_request);
		bytes memory path = request.path;

		_validExpectingAmount(request.expectedAmountIn, request.expectedAmountOut);

		if (!request.usingHop) {
			(address tokenOut, uint24 poolFee) = _safeDecodeSingleHopPath(path);

			return
				(request.expectedAmountIn != 0)
					? _swapExactInputSingleHop(
						_receiver,
						request.tokenIn,
						tokenOut,
						poolFee,
						request.expectedAmountIn
					)
					: _swapExactOutputSingleHop(
						_receiver,
						request.tokenIn,
						tokenOut,
						poolFee,
						request.expectedAmountOut,
						request.amountInMaximum
					);
		} else {
			bytes memory correctedPath = _safeCorrectMultiHopPath(
				path,
				request.expectedAmountIn != 0
			);

			return
				(request.expectedAmountIn != 0)
					? _swapExactInputMultiHop(
						correctedPath,
						_receiver,
						request.tokenIn,
						request.expectedAmountIn
					)
					: _swapExactOutputMultiHop(
						correctedPath,
						_receiver,
						request.tokenIn,
						request.expectedAmountOut,
						request.amountInMaximum
					);
		}
	}

	function _swapExactInputSingleHop(
		address _receiver,
		address _tokenIn,
		address _tokenOut,
		uint24 _poolFee,
		uint256 _amountIn
	) internal returns (uint256 amountOut_) {
		_performTokenTransferFrom(_tokenIn, msg.sender, address(this), _amountIn);
		_tryPerformMaxApprove(_tokenIn, address(router));

		ExactInputSingleParams memory params = ExactInputSingleParams({
			tokenIn: _tokenIn,
			tokenOut: _tokenOut,
			fee: _poolFee,
			recipient: _receiver,
			deadline: block.timestamp,
			amountIn: _amountIn,
			amountOutMinimum: 0,
			sqrtPriceLimitX96: 0
		});

		amountOut_ = router.exactInputSingle(params);

		return amountOut_;
	}

	function _swapExactOutputSingleHop(
		address _receiver,
		address _tokenIn,
		address _tokenOut,
		uint24 _poolFee,
		uint256 _amountOut,
		uint256 _amountInMaximum
	) internal returns (uint256 amountIn_) {
		if (_amountInMaximum == 0) {
			_amountInMaximum = quoter.quoteExactOutputSingle(
				_tokenIn,
				_tokenOut,
				_poolFee,
				_amountOut,
				0
			);
		}

		_performTokenTransferFrom(_tokenIn, msg.sender, address(this), _amountInMaximum);
		_tryPerformMaxApprove(_tokenIn, address(router));

		ExactOutputSingleParams memory params = ExactOutputSingleParams({
			tokenIn: _tokenIn,
			tokenOut: _tokenOut,
			fee: _poolFee,
			recipient: _receiver,
			deadline: block.timestamp,
			amountOut: _amountOut,
			amountInMaximum: _amountInMaximum,
			sqrtPriceLimitX96: 0
		});

		amountIn_ = router.exactOutputSingle(params);

		if (amountIn_ < _amountInMaximum) {
			_performTokenTransfer(_tokenIn, msg.sender, _amountInMaximum - amountIn_);
		}

		return amountIn_;
	}

	function _swapExactInputMultiHop(
		bytes memory _path,
		address _receiver,
		address _tokenIn,
		uint256 _amountIn
	) internal returns (uint256 amountOut_) {
		_performTokenTransferFrom(_tokenIn, msg.sender, address(this), _amountIn);
		_tryPerformMaxApprove(_tokenIn, address(router));

		ExactInputParams memory params = ExactInputParams({
			path: _path,
			recipient: _receiver,
			deadline: block.timestamp,
			amountIn: _amountIn,
			amountOutMinimum: 0
		});

		return router.exactInput(params);
	}

	function _swapExactOutputMultiHop(
		bytes memory _path,
		address _receiver,
		address _tokenIn,
		uint256 _amountOut,
		uint256 _amountInMaximum
	) internal returns (uint256 amountIn_) {
		if (_amountInMaximum == 0) {
			_amountInMaximum = quoter.quoteExactOutput(_path, _amountOut);
		}

		_performTokenTransferFrom(_tokenIn, msg.sender, address(this), _amountInMaximum);
		_tryPerformMaxApprove(_tokenIn, address(router));

		ExactOutputParams memory params = ExactOutputParams({
			path: _path,
			recipient: _receiver,
			deadline: block.timestamp,
			amountOut: _amountOut,
			amountInMaximum: _amountInMaximum
		});

		amountIn_ = router.exactOutput(params);

		if (amountIn_ < _amountInMaximum) {
			_performTokenTransfer(_tokenIn, msg.sender, _amountInMaximum - amountIn_);
		}

		return amountIn_;
	}

	function getAmountIn(bytes memory _request) external override returns (uint256) {
		RequestExactInOutParams memory params = _safeDecodeRequestInOutParams(_request);
		uint256 amount = params.amount;

		if (params.usingHop) {
			bytes memory path = _safeCorrectMultiHopPath(params.path, false);
			return quoter.quoteExactOutput(path, amount);
		} else {
			(address tokenOut, uint24 fee) = _safeDecodeSingleHopPath(params.path);
			return quoter.quoteExactOutputSingle(params.tokenIn, tokenOut, fee, amount, 0);
		}
	}

	function getAmountOut(bytes memory _request) external override returns (uint256) {
		RequestExactInOutParams memory params = _safeDecodeRequestInOutParams(_request);
		uint256 amount = params.amount;

		if (params.usingHop) {
			bytes memory path = _safeCorrectMultiHopPath(params.path, true);
			return quoter.quoteExactInput(path, amount);
		} else {
			(address tokenOut, uint24 fee) = _safeDecodeSingleHopPath(params.path);
			return quoter.quoteExactInputSingle(params.tokenIn, tokenOut, fee, amount, 0);
		}
	}

	function _safeDecodeSwapRequest(bytes memory _request)
		internal
		view
		returns (UniswapV3SwapRequest memory)
	{
		try this.decodeSwapRequest(_request) returns (
			UniswapV3SwapRequest memory request_
		) {
			return request_;
		} catch {
			revert InvalidRequestEncoding();
		}
	}

	function decodeSwapRequest(bytes memory _request)
		external
		pure
		returns (UniswapV3SwapRequest memory)
	{
		return abi.decode(_request, (UniswapV3SwapRequest));
	}

	function _safeDecodeSingleHopPath(bytes memory _path)
		internal
		view
		returns (address tokenOut_, uint24 fee_)
	{
		try this.decodeSingleHopPath(_path) returns (address tokenOut, uint24 fee) {
			return (tokenOut, fee);
		} catch {
			revert InvalidPathEncoding();
		}
	}

	function decodeSingleHopPath(bytes memory _path)
		external
		pure
		returns (address tokenOut_, uint24 fee_)
	{
		return abi.decode(_path, (address, uint24));
	}

	function _safeCorrectMultiHopPath(bytes memory _path, bool _withAmountIn)
		internal
		view
		returns (bytes memory correctedPath_)
	{
		try this.correctMultiHopPath(_path, _withAmountIn) returns (
			bytes memory correctedPath
		) {
			return correctedPath;
		} catch {
			revert InvalidPathEncoding();
		}
	}

	function correctMultiHopPath(bytes memory _path, bool _withAmountIn)
		external
		pure
		returns (bytes memory correctedPath_)
	{
		(
			address tokenIn,
			uint24 feeA,
			address tokenOutIn,
			uint24 feeB,
			address tokenOut
		) = abi.decode(_path, (address, uint24, address, uint24, address));

		return
			(_withAmountIn)
				? abi.encodePacked(tokenIn, feeA, tokenOutIn, feeB, tokenOut)
				: abi.encodePacked(tokenOut, feeB, tokenOutIn, feeA, tokenIn);
	}

	function _safeDecodeRequestInOutParams(bytes memory _request)
		internal
		view
		returns (RequestExactInOutParams memory)
	{
		try this.decodeRequestInOutParams(_request) returns (
			RequestExactInOutParams memory params
		) {
			return params;
		} catch {
			revert InvalidRequestEncoding();
		}
	}

	function decodeRequestInOutParams(bytes memory _request)
		external
		pure
		returns (RequestExactInOutParams memory)
	{
		return abi.decode(_request, (RequestExactInOutParams));
	}

	function generateSwapRequest(
		address _tokenMiddle,
		address _tokenOut,
		uint24 _poolFeeA,
		uint24 _poolFeeB,
		address _tokenIn,
		uint256 _expectedAmountIn,
		uint256 _expectedAmountOut,
		uint256 _amountInMaximum,
		bool _usingHop
	) external pure returns (bytes memory) {
		bytes memory path = _usingHop
			? abi.encode(_tokenIn, _poolFeeA, _tokenMiddle, _poolFeeB, _tokenOut)
			: abi.encode(_tokenOut, _poolFeeA);

		return
			abi.encode(
				UniswapV3SwapRequest(
					path,
					_tokenIn,
					_expectedAmountIn,
					_expectedAmountOut,
					_amountInMaximum,
					_usingHop
				)
			);
	}

	function generateExpectInOutRequest(
		address _tokenMiddle,
		address _tokenOut,
		uint24 _poolFeeA,
		uint24 _poolFeeB,
		address _tokenIn,
		uint256 _amount,
		bool _usingHop
	) external pure returns (bytes memory) {
		bytes memory path = _usingHop
			? abi.encode(_tokenIn, _poolFeeA, _tokenMiddle, _poolFeeB, _tokenOut)
			: abi.encode(_tokenOut, _poolFeeA);

		return abi.encode(RequestExactInOutParams(path, _tokenIn, _amount, _usingHop));
	}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "../BaseVesta.sol";
import "../lib/token/TokenTransferrer.sol";
import "../interface/ITrader.sol";

abstract contract BaseTrader is ITrader, BaseVesta, TokenTransferrer {
	uint16 public constant EXACT_AMOUNT_IN_CORRECTION = 3; //0.003
	uint128 public constant CORRECTION_DENOMINATOR = 100_000;

	function _validExpectingAmount(uint256 _in, uint256 _out) internal pure {
		if (_in == _out || (_in == 0 && _out == 0)) {
			revert AmountInAndOutAreZeroOrSameValue();
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../../../model/UniswapV3Model.sol";

interface ISwapRouter {
	function exactInputSingle(ExactInputSingleParams calldata params)
		external
		payable
		returns (uint256 amountOut);

	function exactInput(ExactInputParams calldata params)
		external
		payable
		returns (uint256 amountOut);

	function exactOutputSingle(ExactOutputSingleParams calldata params)
		external
		returns (uint256 amountIn);

	function exactOutput(ExactOutputParams calldata params)
		external
		returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @custom:doc Uniswap V3's Doc
 */

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

struct ExactInputParams {
	bytes path;
	address recipient;
	uint256 deadline;
	uint256 amountIn;
	uint256 amountOutMinimum;
}

struct ExactOutputParams {
	bytes path;
	address recipient;
	uint256 deadline;
	uint256 amountOut;
	uint256 amountInMaximum;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Quoter Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoter {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    function quoteExactInput(bytes memory path, uint256 amountIn) external returns (uint256 amountOut);

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountIn The desired input amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    function quoteExactOutput(bytes memory path, uint256 amountOut) external returns (uint256 amountIn);

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountOut The desired output amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import { BaseTrader } from "../../BaseTrader.sol";

import { ITrader } from "../../../interface/ITrader.sol";
import { IRouter02 } from "../../../interface/dex/uniswap/IRouter02.sol";

import { GenericSwapRequest, GenericRequestExactInOutParams as RequestExactInOutParams } from "../../../model/TradingModel.sol";

import { TokenTransferrer } from "../../../lib/token/TokenTransferrer.sol";
import { PathHelper } from "../../../lib/PathHelper.sol";

contract UniswapV2Trader is BaseTrader {
	using PathHelper for address[];

	IRouter02 public router;

	function setUp(address _router) external onlyContract(_router) initializer {
		__BASE_VESTA_INIT();

		router = IRouter02(_router);
	}

	function exchange(address _receiver, bytes memory _request)
		external
		override
		returns (uint256 swapResponse_)
	{
		GenericSwapRequest memory request = _safeDecodeSwapRequest(_request);

		_validExpectingAmount(request.expectedAmountIn, request.expectedAmountOut);

		return
			(request.expectedAmountIn != 0)
				? _swapExactInput(_receiver, request.path, request.expectedAmountIn)
				: _swapExactOutput(_receiver, request.path, request.expectedAmountOut);
	}

	function _safeDecodeSwapRequest(bytes memory _request)
		internal
		view
		returns (GenericSwapRequest memory)
	{
		try this.decodeSwapRequest(_request) returns (
			GenericSwapRequest memory request_
		) {
			return request_;
		} catch {
			revert InvalidRequestEncoding();
		}
	}

	function decodeSwapRequest(bytes memory _request)
		external
		pure
		returns (GenericSwapRequest memory)
	{
		return abi.decode(_request, (GenericSwapRequest));
	}

	function _swapExactInput(
		address _receiver,
		address[] memory _path,
		uint256 _amountIn
	) internal returns (uint256 amountOut_) {
		address tokenIn = _path[0];

		_performTokenTransferFrom(tokenIn, msg.sender, address(this), _amountIn);
		_tryPerformMaxApprove(tokenIn, address(router));

		uint256[] memory values = router.swapExactTokensForTokens(
			_amountIn,
			0,
			_path,
			_receiver,
			block.timestamp
		);

		return values[values.length - 1];
	}

	function _swapExactOutput(
		address _receiver,
		address[] memory _path,
		uint256 _amountOut
	) internal returns (uint256 amountIn_) {
		address tokenIn = _path[0];
		uint256 amountInMax = router.getAmountsIn(_amountOut, _path)[0];

		_performTokenTransferFrom(tokenIn, msg.sender, address(this), amountInMax);
		_tryPerformMaxApprove(tokenIn, address(router));

		amountIn_ = router.swapTokensForExactTokens(
			_amountOut,
			amountInMax,
			_path,
			_receiver,
			block.timestamp
		)[0];

		if (amountIn_ < amountInMax) {
			_performTokenTransfer(tokenIn, msg.sender, amountInMax - amountIn_);
		}

		return amountIn_;
	}

	function getAmountIn(bytes memory _request)
		external
		view
		override
		returns (uint256)
	{
		RequestExactInOutParams memory params = _safeDecodeRequestExactInOutParams(
			_request
		);

		return router.getAmountsIn(params.amount, params.path)[0];
	}

	function getAmountOut(bytes memory _request)
		external
		view
		override
		returns (uint256)
	{
		RequestExactInOutParams memory params = _safeDecodeRequestExactInOutParams(
			_request
		);

		uint256[] memory values = router.getAmountsOut(params.amount, params.path);
		return values[values.length - 1];
	}

	function _safeDecodeRequestExactInOutParams(bytes memory _request)
		internal
		view
		returns (RequestExactInOutParams memory)
	{
		try this.decodeRequestExactInOutParams(_request) returns (
			RequestExactInOutParams memory params
		) {
			return params;
		} catch {
			revert InvalidRequestEncoding();
		}
	}

	function decodeRequestExactInOutParams(bytes memory _request)
		external
		pure
		returns (RequestExactInOutParams memory)
	{
		return abi.decode(_request, (RequestExactInOutParams));
	}

	function generateSwapRequest(
		address[] calldata _path,
		uint256 _expectedAmountIn,
		uint256 _expectedAmountOut
	) external pure returns (bytes memory) {
		return
			abi.encode(GenericSwapRequest(_path, _expectedAmountIn, _expectedAmountOut));
	}

	function generateExpectInOutRequest(address[] calldata _path, uint256 _amount)
		external
		pure
		returns (bytes memory)
	{
		return abi.encode(RequestExactInOutParams(_path, _amount));
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IRouter02 {
	function swapExactTokensForTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapTokensForExactTokens(
		uint256 amountOut,
		uint256 amountInMax,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function getAmountsOut(uint256 amountIn, address[] calldata path)
		external
		view
		returns (uint256[] memory amounts);

	function getAmountsIn(uint256 amountOut, address[] calldata path)
		external
		view
		returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

library PathHelper {
	function tokenIn(address[] memory _path) internal pure returns (address) {
		return _path[0];
	}

	function tokenOut(address[] memory _path) internal pure returns (address) {
		return _path[_path.length - 1];
	}

	function isSinglePath(address[] memory _path) internal pure returns (bool) {
		return _path.length == 2;
	}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import { BaseTrader } from "../BaseTrader.sol";

import { ITrader } from "../../interface/ITrader.sol";
import { IVault } from "../../interface/dex/gmx/IVault.sol";
import { IVaultUtils } from "../../interface/dex/gmx/IVaultUtils.sol";

import { GenericSwapRequest, GenericRequestExactInOutParams as RequestExactInOutParams } from "../../model/TradingModel.sol";

import { TokenTransferrer } from "../../lib/token/TokenTransferrer.sol";
import { PathHelper } from "../../lib/PathHelper.sol";

import { PathHelper } from "../../lib/PathHelper.sol";
import { FullMath } from "../../lib/FullMath.sol";

contract GMXTrader is BaseTrader {
	using PathHelper for address[];

	error InvalidRoutPathLenght();

	uint256 public constant BASIS_POINTS_DIVISOR = 10_000;
	uint256 public constant PRICE_PRECISION = 10**30;

	IVault public vault;
	IVaultUtils public vaultUtils;
	address public usdg;

	function setUp(
		address _vault,
		address _vaultUtils,
		address _usdg
	) external initializer onlyContract(_vault) onlyContracts(_vaultUtils, _usdg) {
		__BASE_VESTA_INIT();

		vault = IVault(_vault);
		vaultUtils = IVaultUtils(_vaultUtils);
		usdg = _usdg;
	}

	function exchange(address _receiver, bytes memory _request)
		external
		override
		returns (uint256)
	{
		GenericSwapRequest memory request = _safeDecodeSwapRequest(_request);
		_validExpectingAmount(request.expectedAmountIn, request.expectedAmountOut);

		address[] memory path = request.path;
		uint256 amountIn = request.expectedAmountIn;

		if (amountIn == 0) {
			amountIn = this.getAmountIn(
				abi.encode(RequestExactInOutParams(path, request.expectedAmountOut))
			);
		}

		return _swap(request.path, amountIn, _receiver);
	}

	function _safeDecodeSwapRequest(bytes memory _request)
		internal
		view
		returns (GenericSwapRequest memory)
	{
		try this.decodeSwapRequest(_request) returns (
			GenericSwapRequest memory request_
		) {
			return request_;
		} catch {
			revert InvalidRequestEncoding();
		}
	}

	function decodeSwapRequest(bytes memory _request)
		external
		pure
		returns (GenericSwapRequest memory)
	{
		return abi.decode(_request, (GenericSwapRequest));
	}

	function _swap(
		address[] memory _path,
		uint256 _amountIn,
		address _receiver
	) internal returns (uint256) {
		_performTokenTransferFrom(_path[0], msg.sender, address(vault), _amountIn);

		if (_path.length == 2) {
			return _vaultSwap(_path[0], _path[1], _receiver);
		} else if (_path.length == 3) {
			uint256 midOut = _vaultSwap(_path[0], _path[1], address(this));
			_performTokenTransfer(_path[1], address(vault), midOut);
			return _vaultSwap(_path[1], _path[2], _receiver);
		}

		revert InvalidRoutPathLenght();
	}

	function _vaultSwap(
		address _tokenIn,
		address _tokenOut,
		address _receiver
	) internal returns (uint256 amountOut_) {
		if (_tokenOut == usdg) {
			amountOut_ = IVault(vault).buyUSDG(_tokenIn, _receiver);
		} else if (_tokenIn == usdg) {
			amountOut_ = IVault(vault).sellUSDG(_tokenOut, _receiver);
		} else {
			amountOut_ = IVault(vault).swap(_tokenIn, _tokenOut, _receiver);
		}

		return amountOut_;
	}

	function getAmountIn(bytes memory _request)
		external
		view
		override
		returns (uint256 amountIn_)
	{
		RequestExactInOutParams memory request = _safeDecodeRequestExactInOutParams(
			_request
		);

		address[] memory path = request.path;

		if (path.isSinglePath()) {
			amountIn_ = _getAmountIn(path[1], path[0], request.amount);
		} else {
			amountIn_ = _getAmountIn(path[2], path[1], request.amount);
			amountIn_ = _getAmountIn(path[1], path[0], amountIn_);
		}

		amountIn_ += FullMath.mulDiv(
			amountIn_,
			EXACT_AMOUNT_IN_CORRECTION,
			CORRECTION_DENOMINATOR
		);

		return amountIn_;
	}

	function getAmountOut(bytes memory _request)
		external
		view
		override
		returns (uint256 _amountOut)
	{
		RequestExactInOutParams memory request = _safeDecodeRequestExactInOutParams(
			_request
		);

		address[] memory path = request.path;

		if (path.isSinglePath()) {
			_amountOut = _getAmountOut(path[0], path[1], request.amount);
		} else {
			_amountOut = _getAmountOut(path[0], path[1], request.amount);
			_amountOut = _getAmountOut(path[1], path[2], _amountOut);
		}

		return _amountOut;
	}

	function _safeDecodeRequestExactInOutParams(bytes memory _request)
		internal
		view
		returns (RequestExactInOutParams memory)
	{
		try this.decodeRequestExactInOutParams(_request) returns (
			RequestExactInOutParams memory params
		) {
			return params;
		} catch {
			revert InvalidRequestEncoding();
		}
	}

	function decodeRequestExactInOutParams(bytes memory _request)
		external
		pure
		returns (RequestExactInOutParams memory)
	{
		return abi.decode(_request, (RequestExactInOutParams));
	}

	function _getAmountIn(
		address _tokenIn,
		address _tokenOut,
		uint256 _amount
	) internal view returns (uint256 amountIn_) {
		uint256 priceIn = vault.getMinPrice(_tokenIn);
		uint256 priceOut = vault.getMaxPrice(_tokenOut);

		amountIn_ = vault.adjustForDecimals(
			FullMath.mulDiv(_amount, priceIn, priceOut),
			_tokenIn,
			_tokenOut
		);

		uint256 usdgAmount = vault.adjustForDecimals(
			FullMath.mulDiv(_amount, priceIn, PRICE_PRECISION),
			_tokenIn,
			usdg
		);

		uint256 feeBasisPoints = vaultUtils.getSwapFeeBasisPoints(
			_tokenOut,
			_tokenIn,
			usdgAmount
		);

		return
			FullMath.mulDiv(
				amountIn_,
				(BASIS_POINTS_DIVISOR + feeBasisPoints),
				BASIS_POINTS_DIVISOR
			);
	}

	function _getAmountOut(
		address _tokenIn,
		address _tokenOut,
		uint256 _amount
	) internal view returns (uint256 amountOut_) {
		uint256 priceIn = vault.getMinPrice(_tokenIn);
		uint256 priceOut = vault.getMaxPrice(_tokenOut);

		amountOut_ = vault.adjustForDecimals(
			FullMath.mulDiv(_amount, priceIn, priceOut),
			_tokenIn,
			_tokenOut
		);

		uint256 usdgAmount = vault.adjustForDecimals(
			FullMath.mulDiv(_amount, priceIn, PRICE_PRECISION),
			_tokenIn,
			usdg
		);

		uint256 feeBasisPoints = vaultUtils.getSwapFeeBasisPoints(
			_tokenIn,
			_tokenOut,
			usdgAmount
		);

		return
			FullMath.mulDiv(
				amountOut_,
				(BASIS_POINTS_DIVISOR - feeBasisPoints),
				BASIS_POINTS_DIVISOR
			);
	}

	function generateSwapRequest(
		address[] calldata _path,
		uint256 _expectedAmountIn,
		uint256 _expectedAmountOut
	) external pure returns (bytes memory) {
		return
			abi.encode(GenericSwapRequest(_path, _expectedAmountIn, _expectedAmountOut));
	}

	function generateExpectInOutRequest(address[] calldata _path, uint256 _amount)
		external
		pure
		returns (bytes memory)
	{
		return abi.encode(RequestExactInOutParams(_path, _amount));
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IVault {
	function buyUSDG(address _token, address _receiver) external returns (uint256);

	function sellUSDG(address _token, address _receiver) external returns (uint256);

	function swap(
		address _tokenIn,
		address _tokenOut,
		address _receiver
	) external returns (uint256);

	function getMaxPrice(address _token) external view returns (uint256);

	function getMinPrice(address _token) external view returns (uint256);

	function adjustForDecimals(
		uint256 _amount,
		address _tokenDiv,
		address _tokenMul
	) external view returns (uint256);

	function mintBurnFeeBasisPoints() external view returns (uint256);

	function taxBasisPoints() external view returns (uint256);

	function stableTokens(address) external view returns (bool);

	function stableSwapFeeBasisPoints() external view returns (uint256);

	function swapFeeBasisPoints() external view returns (uint256);

	function stableTaxBasisPoints() external view returns (uint256);

	function hasDynamicFees() external view returns (bool);

	function usdgAmounts(address _token) external view returns (uint256);

	function getTargetUsdgAmount(address _token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IVaultUtils {
	function getBuyUsdgFeeBasisPoints(address _token, uint256 _usdgAmount)
		external
		view
		returns (uint256);

	function getSellUsdgFeeBasisPoints(address _token, uint256 _usdgAmount)
		external
		view
		returns (uint256);

	function getFeeBasisPoints(
		address _token,
		uint256 _usdgDelta,
		uint256 _feeBasisPoints,
		uint256 _taxBasisPoints,
		bool _increment
	) external view returns (uint256);

	function getSwapFeeBasisPoints(
		address _tokenIn,
		address _tokenOut,
		uint256 _usdgAmount
	) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import { BaseTrader } from "../BaseTrader.sol";
import { ICurvePool } from "../../interface/dex/curve/ICurvePool.sol";

import { CurveSwapRequest, CurveRequestExactInOutParams as RequestExactInOutParams } from "../../model/TradingModel.sol";
import { PoolConfig } from "../../model/CurveModel.sol";

import { FullMath } from "../../lib/FullMath.sol";
import { IERC20 } from "../../interface/token/IERC20.sol";

contract CurveTrader is BaseTrader {
	error ExchangeReturnedRevert();
	error GetDyReturnedRevert();
	error PoolNotRegistered();
	error InvalidCoinsSize();

	event PoolRegistered(address indexed pool);
	event PoolUnRegistered(address indexed pool);

	uint256 public constant PRECISION = 1e27;
	uint128 public constant BPS_DEMOMINATOR = 10_000;
	uint8 public constant TARGET_DECIMALS = 18;

	mapping(address => PoolConfig) internal curvePools;

	modifier onlyRegistered(address _pool) {
		if (curvePools[_pool].tokens.length == 0) {
			revert PoolNotRegistered();
		}
		_;
	}

	function setUp() external initializer {
		__BASE_VESTA_INIT();
	}

	function registerPool(
		address _pool,
		uint8 _totalCoins,
		string calldata _get_dy_signature,
		string calldata _exchange_signature
	) external onlyOwner onlyContract(_pool) {
		if (_totalCoins < 2) revert InvalidCoinsSize();

		address[] memory tokens = new address[](_totalCoins);
		address token;

		for (uint256 i = 0; i < _totalCoins; ++i) {
			token = ICurvePool(_pool).coins(i);
			tokens[i] = token;

			_performApprove(token, _pool, MAX_UINT256);
		}

		curvePools[_pool] = PoolConfig({
			tokens: tokens,
			get_dy_signature: _get_dy_signature,
			exchange_signature: _exchange_signature
		});

		emit PoolRegistered(_pool);
	}

	function unregisterPool(address _pool) external onlyOwner onlyRegistered(_pool) {
		delete curvePools[_pool];
		emit PoolUnRegistered(_pool);
	}

	function exchange(address _receiver, bytes memory _request)
		external
		override
		returns (uint256 swapResponse_)
	{
		CurveSwapRequest memory request = _safeDecodeSwapRequest(_request);

		_validExpectingAmount(request.expectedAmountIn, request.expectedAmountOut);

		if (!isPoolRegistered(request.pool)) {
			revert PoolNotRegistered();
		}

		PoolConfig memory curve = curvePools[request.pool];
		address pool = request.pool;
		int128 i = int128(int8(request.coins[0]));
		int128 j = int128(int8(request.coins[1]));
		address tokenOut = curve.tokens[uint128(j)];

		if (request.expectedAmountIn == 0) {
			uint256 amountIn = _getExpectAmountIn(
				pool,
				curve.get_dy_signature,
				i,
				j,
				request.expectedAmountOut
			);

			request.expectedAmountIn =
				amountIn +
				FullMath.mulDiv(amountIn, request.slippage, BPS_DEMOMINATOR);
		} else {
			request.expectedAmountOut = _get_dy(
				pool,
				curve.get_dy_signature,
				i,
				j,
				request.expectedAmountIn
			);
		}

		_performTokenTransferFrom(
			curve.tokens[uint128(i)],
			msg.sender,
			address(this),
			request.expectedAmountIn
		);

		uint256 balanceBefore = IERC20(tokenOut).balanceOf(address(this));

		(bool success, ) = pool.call{ value: 0 }(
			abi.encodeWithSignature(
				curve.exchange_signature,
				i,
				j,
				request.expectedAmountIn,
				request.expectedAmountOut,
				false
			)
		);

		if (!success) revert ExchangeReturnedRevert();

		uint256 balanceAfter = IERC20(tokenOut).balanceOf(address(this));
		uint256 result = balanceAfter - balanceBefore;

		_performTokenTransfer(curve.tokens[uint128(j)], _receiver, result);

		return result;
	}

	function _safeDecodeSwapRequest(bytes memory _request)
		internal
		view
		returns (CurveSwapRequest memory)
	{
		try this.decodeSwapRequest(_request) returns (CurveSwapRequest memory params) {
			return params;
		} catch {
			revert InvalidRequestEncoding();
		}
	}

	function decodeSwapRequest(bytes memory _request)
		external
		pure
		returns (CurveSwapRequest memory)
	{
		return abi.decode(_request, (CurveSwapRequest));
	}

	function getAmountIn(bytes memory _request)
		external
		view
		override
		returns (uint256 amountIn_)
	{
		RequestExactInOutParams memory params = _safeDecodeRequestExactInOutParams(
			_request
		);

		PoolConfig memory curve = curvePools[params.pool];

		amountIn_ = _getExpectAmountIn(
			params.pool,
			curve.get_dy_signature,
			int128(int8(params.coins[0])),
			int128(int8(params.coins[1])),
			params.amount
		);

		amountIn_ += FullMath.mulDiv(amountIn_, params.slippage, BPS_DEMOMINATOR);

		return amountIn_;
	}

	function _getExpectAmountIn(
		address _pool,
		string memory _get_dy_signature,
		int128 _coinA,
		int128 _coinB,
		uint256 _expectOut
	) internal view returns (uint256 amountIn_) {
		uint256 estimationIn = _get_dy(
			_pool,
			_get_dy_signature,
			_coinB,
			_coinA,
			_expectOut
		);
		uint256 estimationOut = _get_dy(
			_pool,
			_get_dy_signature,
			_coinA,
			_coinB,
			estimationIn
		);

		uint256 rate = FullMath.mulDiv(estimationIn, PRECISION, estimationOut);
		amountIn_ = FullMath.mulDiv(rate, _expectOut, PRECISION);
		amountIn_ += FullMath.mulDiv(
			amountIn_,
			EXACT_AMOUNT_IN_CORRECTION,
			CORRECTION_DENOMINATOR
		);

		return amountIn_;
	}

	function getAmountOut(bytes memory _request)
		external
		view
		override
		returns (uint256)
	{
		RequestExactInOutParams memory params = _safeDecodeRequestExactInOutParams(
			_request
		);

		address pool = params.pool;

		return
			_get_dy(
				pool,
				curvePools[pool].get_dy_signature,
				int128(int8(params.coins[0])),
				int128(int8(params.coins[1])),
				params.amount
			);
	}

	function _get_dy(
		address _pool,
		string memory _signature,
		int128 i,
		int128 j,
		uint256 dx
	) internal view returns (uint256) {
		bool success;
		bytes memory data;

		(success, data) = _pool.staticcall(
			abi.encodeWithSignature(_signature, i, j, dx)
		);

		if (!success) {
			revert GetDyReturnedRevert();
		}

		return abi.decode(data, (uint256));
	}

	function _safeDecodeRequestExactInOutParams(bytes memory _request)
		internal
		view
		returns (RequestExactInOutParams memory)
	{
		try this.decodeDecodeRequestExactInOutParams(_request) returns (
			RequestExactInOutParams memory params
		) {
			return params;
		} catch {
			revert InvalidRequestEncoding();
		}
	}

	function decodeDecodeRequestExactInOutParams(bytes memory _request)
		external
		pure
		returns (RequestExactInOutParams memory)
	{
		return abi.decode(_request, (RequestExactInOutParams));
	}

	function getPoolConfigOf(address _pool) external view returns (PoolConfig memory) {
		return curvePools[_pool];
	}

	function isPoolRegistered(address _pool) public view returns (bool) {
		return curvePools[_pool].tokens.length != 0;
	}

	function generateSwapRequest(
		address _pool,
		uint8[2] calldata _coins,
		uint256 _expectedAmountIn,
		uint256 _expectedAmountOut,
		uint16 _slippage
	) external pure returns (bytes memory) {
		return
			abi.encode(
				CurveSwapRequest(
					_pool,
					_coins,
					_expectedAmountIn,
					_expectedAmountOut,
					_slippage
				)
			);
	}

	function generateExpectInOutRequest(
		address _pool,
		uint8[2] calldata _coins,
		uint256 _amount,
		uint16 _slippage
	) external pure returns (bytes memory) {
		return abi.encode(RequestExactInOutParams(_pool, _coins, _amount, _slippage));
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @param tokens should have the same array of coins from the curve pool
 * @param uint8 holds the decimals of each tokens
 * @param underlying is the curve pool uses underlying
 */
struct PoolConfig {
	address[] tokens;
	string get_dy_signature;
	string exchange_signature;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IERC20.sol";

interface IWETH is IERC20 {
	function deposit() external payable;

	function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IVault } from "../../interface/dex/gmx/IVault.sol";
import { IVaultUtils } from "../../interface/dex/gmx/IVaultUtils.sol";

/**
 * Deployed by Vesta because we needed this little helper
 * There's no ownership attach to it.
 *
 * We didn't modify the core logic whatsoever, we just removed the functions that we do not need
 *
 * Ref: https://github.com/gmx-io/gmx-contracts/blob/master/contracts/core/VaultUtils.sol
 * Commit Id: 1a901D0
 */
contract VaultUtils is IVaultUtils {
	IVault public vault;

	uint256 public constant BASIS_POINTS_DIVISOR = 10000;
	uint256 public constant FUNDING_RATE_PRECISION = 1000000;

	constructor(address _vault) {
		require(_vault != address(0), "Invalid Vault Address");
		vault = IVault(_vault);
	}

	function getBuyUsdgFeeBasisPoints(address _token, uint256 _usdgAmount)
		public
		view
		override
		returns (uint256)
	{
		return
			getFeeBasisPoints(
				_token,
				_usdgAmount,
				vault.mintBurnFeeBasisPoints(),
				vault.taxBasisPoints(),
				true
			);
	}

	function getSellUsdgFeeBasisPoints(address _token, uint256 _usdgAmount)
		public
		view
		override
		returns (uint256)
	{
		return
			getFeeBasisPoints(
				_token,
				_usdgAmount,
				vault.mintBurnFeeBasisPoints(),
				vault.taxBasisPoints(),
				false
			);
	}

	function getSwapFeeBasisPoints(
		address _tokenIn,
		address _tokenOut,
		uint256 _usdgAmount
	) public view override returns (uint256) {
		bool isStableSwap = vault.stableTokens(_tokenIn) &&
			vault.stableTokens(_tokenOut);

		uint256 baseBps = isStableSwap
			? vault.stableSwapFeeBasisPoints()
			: vault.swapFeeBasisPoints();
		uint256 taxBps = isStableSwap
			? vault.stableTaxBasisPoints()
			: vault.taxBasisPoints();
		uint256 feesBasisPoints0 = getFeeBasisPoints(
			_tokenIn,
			_usdgAmount,
			baseBps,
			taxBps,
			true
		);
		uint256 feesBasisPoints1 = getFeeBasisPoints(
			_tokenOut,
			_usdgAmount,
			baseBps,
			taxBps,
			false
		);
		// use the higher of the two fee basis points
		return feesBasisPoints0 > feesBasisPoints1 ? feesBasisPoints0 : feesBasisPoints1;
	}

	// cases to consider
	// 1. initialAmount is far from targetAmount, action increases balance slightly => high rebate
	// 2. initialAmount is far from targetAmount, action increases balance largely => high rebate
	// 3. initialAmount is close to targetAmount, action increases balance slightly => low rebate
	// 4. initialAmount is far from targetAmount, action reduces balance slightly => high tax
	// 5. initialAmount is far from targetAmount, action reduces balance largely => high tax
	// 6. initialAmount is close to targetAmount, action reduces balance largely => low tax
	// 7. initialAmount is above targetAmount, nextAmount is below targetAmount and vice versa
	// 8. a large swap should have similar fees as the same trade split into multiple smaller swaps
	function getFeeBasisPoints(
		address _token,
		uint256 _usdgDelta,
		uint256 _feeBasisPoints,
		uint256 _taxBasisPoints,
		bool _increment
	) public view override returns (uint256) {
		if (!vault.hasDynamicFees()) {
			return _feeBasisPoints;
		}

		uint256 initialAmount = vault.usdgAmounts(_token);
		uint256 nextAmount = initialAmount + _usdgDelta;
		if (!_increment) {
			nextAmount = _usdgDelta > initialAmount ? 0 : initialAmount - _usdgDelta;
		}

		uint256 targetAmount = vault.getTargetUsdgAmount(_token);
		if (targetAmount == 0) {
			return _feeBasisPoints;
		}

		uint256 initialDiff = initialAmount > targetAmount
			? initialAmount - targetAmount
			: targetAmount - initialAmount;
		uint256 nextDiff = nextAmount > targetAmount
			? nextAmount - targetAmount
			: targetAmount - nextAmount;

		// action improves relative asset balance
		if (nextDiff < initialDiff) {
			uint256 rebateBps = (_taxBasisPoints * initialDiff) / targetAmount;
			return rebateBps > _feeBasisPoints ? 0 : _feeBasisPoints - rebateBps;
		}

		uint256 averageDiff = (initialDiff + nextDiff) / 2;
		if (averageDiff > targetAmount) {
			averageDiff = targetAmount;
		}
		uint256 taxBps = (_taxBasisPoints * averageDiff) / targetAmount;
		return _feeBasisPoints + taxBps;
	}
}