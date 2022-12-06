// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "./proxy/ProxyRegistry.sol";

/// Thrown if any initial caller of this proxy registry is already set.
error InitialCallerIsAlreadySet ();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title GigaMart Proxy Registry
	@author Tim Clancy <@_Enoch>
	@author Rostislav Khlebnikov <@catpic5buck>
	
	A fully-implemented proxy registry contract.

	@custom:date December 4th, 2022.
*/
contract GigaMartProxyRegistry is ProxyRegistry {

	/// The public name of this registry.
	string public constant name = "GigaMart Proxy Registry";

	/// A flag for whether or not the initial authorized caller has been set.
	bool public initialCallersSet = false;

	/**
		Constructing a new instance of this registry is passed through to the 
		`ProxyRegistry` constructor.
	*/
	constructor () ProxyRegistry() { }

	/**
		Allow the owner of this registry to grant immediate authorization to a
		set of addresses for calling proxies in this registry. This is to avoid
		waiting for the `DELAY_PERIOD` otherwise specified for further caller
		additions.

		@param _initials The array of initial callers authorized to operate in this 
			registry.

		@custom:throws InitialCallerIsAlreadySet if an intial caller is already set 
			for this proxy registry.
	*/
	function grantInitialAuthentication (
		address[] calldata _initials
	) external onlyOwner {
		if (initialCallersSet) {
			revert InitialCallerIsAlreadySet();
		}
		initialCallersSet = true;

		// Authorize each initial caller.
		for (uint256 i; i < _initials.length; ) {
			authorizedCallers[_initials[i]] = true;
			unchecked {
				++i;
			}
		}
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./AuthenticatedProxy.sol";
import "../interfaces/IProxyRegistry.sol";
import "../proxy/OwnableDelegateProxy.sol";

/// Thrown if an address authentifying is already an authorized caller.
error AlreadyAuthorized ();

/// Thrown if an address is already pending authentication.
error AlreadyPendingAuthentication ();

/// Thrown if an address ending authentication has not yet started it.
error AddressHasntStartedAuth ();

/// Thrown if an address ending authentication has not delayed long enough.
error AddressHasntClearedTimelock ();

/// Thrown if a caller has already registered a proxy.
error ProxyAlreadyRegistered ();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title Ownable Delegate Proxy
	@author Protinam, Project Wyvern
	@author Tim Clancy <@_Enoch>
	@author Rostislav Khlebnikov <@catpic5buck>

	A proxy registry contract. This contract was originally developed 
	by Project Wyvern. It has been modified to support a more modern version of 
	Solidity with associated best practices. The documentation has also been 
	improved to provide more clarity.

	@custom:date December 4th, 2022.
*/
contract ProxyRegistry is IProxyRegistry, Ownable {

	/**
		Each `OwnableDelegateProxy` contract ultimately dictates its implementation
		details elsewhere, to `delegateProxyImplementation`.
	*/
	address public delegateProxyImplementation;

	/**
		This mapping relates an addresses to its own personal `OwnableDelegateProxy`
		which allow it to proxy functionality to the various callers contained in
		`authorizedCallers`.
	*/
	mapping ( address => address ) public proxies;

	/**
		This mapping relates addresses which are pending access to the registry to
		the timestamp where they began the `startGrantAuthentication` process.
	*/
	mapping ( address => uint256 ) public pendingCallers;

	/**
		This mapping relates an address to a boolean specifying whether or not it is
		allowed to call the `OwnableDelegateProxy` for any given address in the
		`proxies` mapping.
	*/
	mapping ( address => bool ) public authorizedCallers;

	/**
		A delay period which must elapse before adding an authenticated contract to
		the registry, thus allowing it to call the `OwnableDelegateProxy` for an
		address in the `proxies` mapping.

		This `ProxyRegistry` contract was designed with the intent to be owned by a
		DAO, so this delay mitigates a particular class of attack against an owning
		DAO. If at any point the value of assets accessible to the
		`OwnableDelegateProxy` contracts exceeded the cost of gaining control of the
		DAO, a malicious but rational attacker could spend (potentially 
		considerable) resources to then have access to all `OwnableDelegateProxy`
		contracts via a malicious contract upgrade. This delay period renders this
		attack ineffective by granting time for addresses to remove assets from
		compromised `OwnableDelegateProxy` contracts.

		Under its present usage, this delay period protects exchange users from a 
		malicious upgrade.
	*/
	uint256 public DELAY_PERIOD = 1 weeks;

	/**
		Construct this registry by specifying the initial implementation of all
		`OwnableDelegateProxy` contracts that are registered by users. This registry
		will use `AuthenticatedProxy` as its initial implementation.
	*/
	constructor () {
		delegateProxyImplementation = address(new AuthenticatedProxy());
	}

	/**
		Allow the `ProxyRegistry` owner to begin the process of enabling access to
		the registry for the unauthenticated address `_unauthenticated`. Once the
		grant authentication process has begun, it is subject to the `DELAY_PERIOD`
		before the authentication process may conclude. Once concluded, the new
		address `_unauthenticated` will have access to the registry.

		@param _unauthenticated The new address to grant access to the registry.

		@custom:throws AlreadyAuthorized if the address beginning authentication is 
			already an authorized caller.
		@custom:throws AlreadyPendingAuthentication if the address beginning 
			authentication is already pending.
	*/
	function startGrantAuthentication (
		address _unauthenticated
	) external onlyOwner {
		if (authorizedCallers[_unauthenticated]) {
			revert AlreadyAuthorized();
		}
		if (pendingCallers[_unauthenticated] != 0) {
			revert AlreadyPendingAuthentication();
		}
		pendingCallers[_unauthenticated] = block.timestamp;
	}

	/**
		Allow the `ProxyRegistry` owner to end the process of enabling access to the
		registry for the unauthenticated address `_unauthenticated`. If the required
		`DELAY_PERIOD` has passed, then the new address `_unauthenticated` will have
		access to the registry.

		@param _unauthenticated The new address to grant access to the registry.

		@custom:throws AlreadyAuthorized if the address beginning authentication is
			already an authorized caller.
		@custom:throws AddressHasntStartedAuth if the address attempting to end 
			authentication has not yet started it.
		@custom:throws AddressHasntClearedTimelock if the address attempting to end 
			authentication has not yet incurred a sufficient delay.
	*/
	function endGrantAuthentication(
		address _unauthenticated
	) external onlyOwner {
		if (authorizedCallers[_unauthenticated]) {
			revert AlreadyAuthorized();
		}
		if (pendingCallers[_unauthenticated] == 0) {
			revert AddressHasntStartedAuth();
		}
		unchecked {
			if (
				(pendingCallers[_unauthenticated] + DELAY_PERIOD) >= block.timestamp
			) {
				revert AddressHasntClearedTimelock();
			}
		}
		pendingCallers[_unauthenticated] = 0;
		authorizedCallers[_unauthenticated] = true;
	}

	/**
		Allow the owner of the `ProxyRegistry` to immediately revoke authorization
		to call proxies from the specified address.

		@param _caller The address to revoke authentication from.
	*/
	function revokeAuthentication (
		address _caller
	) external onlyOwner {
		authorizedCallers[_caller] = false;
	}

	/**
		Enables an address to register its own proxy contract with this registry.

		@return _ The address of the new `OwnableMutableDelegateProxy` contract 
			with its `delegateProxyImplementation` implementation.

		@custom:throws ProxyAlreadyRegistered if the caller has already registered 
			a proxy.
	*/
	function registerProxy () external returns (address) {
		if (address(proxies[_msgSender()]) != address(0)) {
			revert ProxyAlreadyRegistered();
		}

		/** 
			Construct the new `OwnableDelegateProxy` with this registry's initial
			implementation and call said implementation's "initialize" function.
		*/
		OwnableDelegateProxy proxy = new OwnableDelegateProxy(
			_msgSender(),
			delegateProxyImplementation,
			abi.encodeWithSignature("initialize(address)", address(this))
		);
		address proxyAddr = address(proxy);
		proxies[_msgSender()] = proxyAddr;
		return proxyAddr;
	}

	/**
		Returns the address of the caller's proxy and the current implementation 
		address.

		@param _caller The address of the caller.

		@return _ A tuple containing the address of the caller's proxy and the 
			address of the current implementation of the proxy.
	*/
	function userProxyConfig(
		address _caller
	) external view returns (address, address) {
		return (proxies[_caller], delegateProxyImplementation);
	}
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IProxyRegistry.sol";

/**
	Thrown if attempting to initialize a proxy which has already been initialized.
*/
error ProxyAlreadyInitialized ();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title Authenticated Proxy
	@author Protinam, Project Wyvern
	@author Tim Clancy <@_Enoch>
	@custom:contributor Rostislav Khlebnikov <@catpic5buck>

	An ownable call-delegating proxy which can receive tokens and only make calls 
	against contracts that have been approved by a `ProxyRegistry`. This contract 
	was originally developed by Project Wyvern. It has been modified to support a 
	more modern version of Solidity with associated best practices. The 
	documentation has also been improved to provide more clarity.

	@custom:date December 4th, 2022.
*/
contract AuthenticatedProxy is Ownable {

	/**
		An enum for selecting the method by which we would like to perform a call 
		in the `proxy` function.
	*/
	enum CallType {
		Call,
		DelegateCall
	}

	/// Whether or not this proxy is initialized. It may only initialize once.
	bool public initialized = false;

	/// The associated `ProxyRegistry` contract with authentication information.
	address public registry;

	/// Whether or not access has been revoked.
	bool public revoked;

	/**
		An event fired when the proxy contract's access is revoked or unrevoked.

		@param revoked The status of the revocation call; true if access is 
			revoked and false if access is unrevoked.
	*/
	event Revoked (
		bool revoked
	);

	/**
		Initialize this authenticated proxy for its owner against a specified
		`ProxyRegistry`. The registry controls the eligible targets.

		@param _registry The registry to create this proxy against.
	*/
	function initialize (
		address _registry
	) external {
		if (initialized) {
			revert ProxyAlreadyInitialized();
		}
		initialized = true;
		registry = _registry;
	}

	/**
		Allow the owner of this proxy to set the revocation flag. This permits them
		to revoke access from the associated `ProxyRegistry` if needed.

		@param _revoke The revocation flag to set for this proxy.
	*/
	function setRevoke (
		bool _revoke
	) external onlyOwner {
		revoked = _revoke;
		emit Revoked(_revoke);
	}

	/**
		Trigger this proxy to call a specific address with the provided data. The
		proxy may perform a direct or a delegate call. This proxy can only be called
		by the owner, or on behalf of the owner by a caller authorized by the
		registry. Unless the user has revoked access to the registry, that is.

		@param _target The target address to make the call to.
		@param _type The type of call to make: direct or delegated.
		@param _data The call data to send to `_target`.

		@return _ Whether or not the call succeeded.

		@custom:throws NonAuthorizedCaller if the proxy caller is not the owner or 
			an authorized caller from the proxy registry.
	*/
	function call (
		address _target,
		CallType _type,
		bytes calldata _data
	) public returns (bool) {
		if (
			_msgSender() != owner() &&
			(revoked || !IProxyRegistry(registry).authorizedCallers(_msgSender()))
		) {
			revert NonAuthorizedCaller();
		}

		// The call is authorized to be performed, now select a type and return.
		if (_type == CallType.Call) {
			(bool success, ) = _target.call(_data);
			return success;
		} else if (_type == CallType.DelegateCall) {
			(bool success, ) = _target.delegatecall(_data);
			return success;
		}
		return false;
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

/// Thrown if a caller is not authorized in the proxy registry.
error NonAuthorizedCaller ();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title Ownable Delegate Proxy
	@author Protinam, Project Wyvern
	@author Tim Clancy <@_Enoch>
	@author Rostislav Khlebnikov <@catpic5buck>

	A proxy registry contract. This contract was originally developed 
	by Project Wyvern. It has been modified to support a more modern version of 
	Solidity with associated best practices. The documentation has also been 
	improved to provide more clarity.

	@custom:date December 4th, 2022.
*/
interface IProxyRegistry {

	/// Return the address of tje current valid implementation of delegate proxy.
	function delegateProxyImplementation () external view returns (address);

	/**
		Returns the address of a proxy which was registered for the user address 
		before listing items.

		@param _owner The address of items lister.
	*/
	function proxies (
		address _owner
	) external view returns (address);

	/**
		Returns true if the `_caller` to the proxy registry is eligible and 
		registered.

		@param _caller The address of the caller.
	*/
	function authorizedCallers (
		address _caller
	) external view returns (bool);

	/**
		Returns the address of the `_caller`'s proxy and current implementation 
		address.

		@param _caller The address of the caller.
	*/
	function userProxyConfig (
		address _caller
	) external view returns (address, address);

	/**
		Enables an address to register its own proxy contract with this registry.

		@return _ The new contract with its implementation.
	*/
	function registerProxy () external returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./DelegateProxy.sol";

/// Thrown if the initial delgate call from this proxy is not successful.
error InitialTargetCallFailed ();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title Ownable Delegate Proxy
	@author Protinam, Project Wyvern
	@author Tim Clancy <@_Enoch>
	@author Rostislav Khlebnikov <@catpic5buck>

	A call-delegating proxy with an owner. This contract was originally developed 
	by Project Wyvern. It has been modified to support a more modern version of 
	Solidity with associated best practices. The documentation has also been 
	improved to provide more clarity.

	@custom:date December 4th, 2022.
*/
contract OwnableDelegateProxy is Ownable, DelegateProxy {

	/// Whether or not the proxy was initialized.
	bool public initialized;

	/**
		This is a storage escape slot to match `AuthenticatedProxy` storage.
		uint8(bool) + uint184 = 192 bits. This prevents target (160 bits) from
		being placed in this storage slot.
	*/
	uint184 private _escape;

	/// The address of the proxy's current target.
	address public target;

	/**
		Construct this delegate proxy with an owner, initial target, and an initial
		call sent to the target.

		@param _owner The address which should own this proxy.
		@param _target The initial target of this proxy.
		@param _data The initial call to delegate to `_target`.

		@custom:throws InitialTargetCallFailed if the proxy initialization call 
			fails.
	*/
	constructor (
		address _owner,
		address _target,
		bytes memory _data
	) {
	
		/*
			Do not perform a redundant ownership transfer if the deployer should remain as the owner of this contract.
		*/
		if (_owner != owner()) {
			transferOwnership(_owner);
		}
		target = _target;

		/**
			Immediately delegate a call to the initial implementation and require it 
			to succeed. This is often used to trigger some kind of initialization 
			function on the target.
		*/
		(bool success, ) = _target.delegatecall(_data);
		if (!success) {
			revert InitialTargetCallFailed();
		}
	}

	/**
		Return the current address where all calls to this proxy are delegated. If
		`proxyType()` returns `1`, ERC-897 dictates that this address MUST not
		change.

		@return _ The current address where calls to this proxy are delegated.
	*/
	function implementation () public view override returns (address) {
		return target;
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
pragma solidity ^0.8.15;

/// Thrown if the proxy's implementation is not set.
error ImplementationIsNotSet ();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title Delegate Proxy
	@author Facu Spagnuolo, OpenZeppelin
	@author Protinam, Project Wyvern
	@author Tim Clancy <@_Enoch>

	A basic call-delegating proxy contract which is compliant with the current 
	draft version of ERC-897. This contract was originally developed by Project 
	Wyvern. It has been modified to support a more modern version of Solidity 
	with associated best practices. The documentation has also been improved to 
	provide more clarity.

	@custom:date December 4th, 2022.
*/
abstract contract DelegateProxy {

	/**
		This payable fallback function exists to automatically delegate all calls to
		this proxy to the contract specified from `implementation()`. Anything
		returned from the delegated call will also be returned here.

		@custom:throws ImplementationIsNotSet if the contract implementation is not 
			set.
	*/
	fallback () external payable virtual {
		address target = implementation();

		// Ensure that the proxy implementation has been set correctly.
		if (target == address(0)) {
			revert ImplementationIsNotSet();
		}

		// Perform the actual call delegation.
		assembly {
			let ptr := mload(0x40)
			calldatacopy(ptr, 0, calldatasize())
			let result := delegatecall(gas(), target, ptr, calldatasize(), 0, 0)
			let size := returndatasize()
			returndatacopy(ptr, 0, size)
			switch result
			case 0 {
				revert(ptr, size)
			}
			default {
				return(ptr, size)
			}
		}
	}

	/**
		Return the current address where all calls to this proxy are delegated. If
		`proxyType()` returns `1`, ERC-897 dictates that this address MUST not
		change.

		@return _ The current address where calls to this proxy are delegated.
	*/
	function implementation () public view virtual returns (address);
}