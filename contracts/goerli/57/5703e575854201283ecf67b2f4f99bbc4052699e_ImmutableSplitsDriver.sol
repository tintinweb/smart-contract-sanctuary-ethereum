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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializing the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is IERC1822Proxiable, ERC1967Upgrade {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

/// @notice A drips receiver
struct DripsReceiver {
    /// @notice The user ID.
    uint256 userId;
    /// @notice The drips configuration.
    DripsConfig config;
}

/// @notice The sender drips history entry, used when squeezing drips.
struct DripsHistory {
    /// @notice Drips receivers list hash, see `_hashDrips`.
    /// If it's non-zero, `receivers` must be empty.
    bytes32 dripsHash;
    /// @notice The drips receivers. If it's non-empty, `dripsHash` must be `0`.
    /// If it's empty, this history entry will be skipped when squeezing drips
    /// and `dripsHash` will be used when verifying the drips history validity.
    /// Skipping a history entry allows cutting gas usage on analysis
    /// of parts of the drips history which are not worth squeezing.
    /// The hash of an empty receivers list is `0`, so when the sender updates
    /// their receivers list to be empty, the new `DripsHistory` entry will have
    /// both the `dripsHash` equal to `0` and the `receivers` empty making it always skipped.
    /// This is fine, because there can't be any funds to squeeze from that entry anyway.
    DripsReceiver[] receivers;
    /// @notice The time when drips have been configured
    uint32 updateTime;
    /// @notice The maximum end time of drips
    uint32 maxEnd;
}

/// @notice Describes a drips configuration.
/// It's constructed from `dripId`, `amtPerSec`, `start` and `duration` as
/// `dripId << 224 | amtPerSec << 64 | start << 32 | duration`.
/// `dripId` is an arbitrary number used to identify a drip.
/// It's a part of the configuration but the protocol doesn't use it.
/// `amtPerSec` is the amount per second being dripped. Must never be zero.
/// It must have additional `Drips._AMT_PER_SEC_EXTRA_DECIMALS` decimals and can have fractions.
/// To achieve that its value must be multiplied by `Drips._AMT_PER_SEC_MULTIPLIER`.
/// `start` is the timestamp when dripping should start.
/// If zero, use the timestamp when drips are configured.
/// `duration` is the duration of dripping.
/// If zero, drip until balance runs out.
type DripsConfig is uint256;

using DripsConfigImpl for DripsConfig global;

library DripsConfigImpl {
    /// @notice Create a new DripsConfig.
    /// @param dripId_ An arbitrary number used to identify a drip.
    /// It's a part of the configuration but the protocol doesn't use it.
    /// @param amtPerSec_ The amount per second being dripped. Must never be zero.
    /// It must have additional `Drips._AMT_PER_SEC_EXTRA_DECIMALS` decimals and can have fractions.
    /// To achieve that the passed value must be multiplied by `Drips._AMT_PER_SEC_MULTIPLIER`.
    /// @param start_ The timestamp when dripping should start.
    /// If zero, use the timestamp when drips are configured.
    /// @param duration_ The duration of dripping.
    /// If zero, drip until balance runs out.
    function create(uint32 dripId_, uint160 amtPerSec_, uint32 start_, uint32 duration_)
        internal
        pure
        returns (DripsConfig)
    {
        uint256 config = dripId_;
        config = (config << 160) | amtPerSec_;
        config = (config << 32) | start_;
        config = (config << 32) | duration_;
        return DripsConfig.wrap(config);
    }

    /// @notice Extracts dripId from a `DripsConfig`
    function dripId(DripsConfig config) internal pure returns (uint32) {
        return uint32(DripsConfig.unwrap(config) >> 224);
    }

    /// @notice Extracts amtPerSec from a `DripsConfig`
    function amtPerSec(DripsConfig config) internal pure returns (uint160) {
        return uint160(DripsConfig.unwrap(config) >> 64);
    }

    /// @notice Extracts start from a `DripsConfig`
    function start(DripsConfig config) internal pure returns (uint32) {
        return uint32(DripsConfig.unwrap(config) >> 32);
    }

    /// @notice Extracts duration from a `DripsConfig`
    function duration(DripsConfig config) internal pure returns (uint32) {
        return uint32(DripsConfig.unwrap(config));
    }

    /// @notice Compares two `DripsConfig`s.
    /// First compares their `amtPerSec`s, then their `start`s and then their `duration`s.
    function lt(DripsConfig config, DripsConfig otherConfig) internal pure returns (bool) {
        return DripsConfig.unwrap(config) < DripsConfig.unwrap(otherConfig);
    }
}

/// @notice Drips can keep track of at most `type(int128).max`
/// which is `2 ^ 127 - 1` units of each asset.
/// It's up to the caller to guarantee that this limit is never exceeded,
/// failing to do so may result in a total protocol collapse.
abstract contract Drips {
    /// @notice Maximum number of drips receivers of a single user.
    /// Limits cost of changes in drips configuration.
    uint256 internal constant _MAX_DRIPS_RECEIVERS = 100;
    /// @notice The additional decimals for all amtPerSec values.
    uint8 internal constant _AMT_PER_SEC_EXTRA_DECIMALS = 9;
    /// @notice The multiplier for all amtPerSec values. It's `10 ** _AMT_PER_SEC_EXTRA_DECIMALS`.
    uint256 internal constant _AMT_PER_SEC_MULTIPLIER = 1_000_000_000;
    /// @notice The total amount the contract can keep track of each asset.
    uint256 internal constant _MAX_TOTAL_DRIPS_BALANCE = uint128(type(int128).max);
    /// @notice On every timestamp `T`, which is a multiple of `cycleSecs`, the receivers
    /// gain access to drips received during `T - cycleSecs` to `T - 1`.
    /// Always higher than 1.
    uint32 internal immutable _cycleSecs;
    /// @notice The storage slot holding a single `DripsStorage` structure.
    bytes32 private immutable _dripsStorageSlot;

    /// @notice Emitted when the drips configuration of a user is updated.
    /// @param userId The user ID.
    /// @param assetId The used asset ID
    /// @param receiversHash The drips receivers list hash
    /// @param dripsHistoryHash The drips history hash which was valid right before the update.
    /// @param balance The new drips balance. These funds will be dripped to the receivers.
    /// @param maxEnd The maximum end time of drips, when funds run out.
    /// If funds run out after the timestamp `type(uint32).max`, it's set to `type(uint32).max`.
    /// If the balance is 0 or there are no receivers, it's set to the current timestamp.
    event DripsSet(
        uint256 indexed userId,
        uint256 indexed assetId,
        bytes32 indexed receiversHash,
        bytes32 dripsHistoryHash,
        uint128 balance,
        uint32 maxEnd
    );

    /// @notice Emitted when a user is seen in a drips receivers list.
    /// @param receiversHash The drips receivers list hash
    /// @param userId The user ID.
    /// @param config The drips configuration.
    event DripsReceiverSeen(
        bytes32 indexed receiversHash, uint256 indexed userId, DripsConfig config
    );

    /// @notice Emitted when drips are received.
    /// @param userId The user ID
    /// @param assetId The used asset ID
    /// @param amt The received amount.
    /// @param receivableCycles The number of cycles which still can be received.
    event ReceivedDrips(
        uint256 indexed userId, uint256 indexed assetId, uint128 amt, uint32 receivableCycles
    );

    /// @notice Emitted when drips are squeezed.
    /// @param userId The squeezing user ID.
    /// @param assetId The used asset ID.
    /// @param senderId The ID of the user sending drips which are squeezed.
    /// @param amt The squeezed amount.
    /// @param dripsHistoryHashes The history hashes of all squeezed drips history entries.
    /// Each history hash matches `dripsHistoryHash` emitted in its `DripsSet`
    /// when the squeezed drips configuration was set.
    /// Sorted in the oldest drips configuration to the newest.
    event SqueezedDrips(
        uint256 indexed userId,
        uint256 indexed assetId,
        uint256 indexed senderId,
        uint128 amt,
        bytes32[] dripsHistoryHashes
    );

    struct DripsStorage {
        /// @notice User drips states.
        /// The keys are the asset ID and the user ID.
        mapping(uint256 => mapping(uint256 => DripsState)) states;
    }

    struct DripsState {
        /// @notice The drips history hash, see `_hashDripsHistory`.
        bytes32 dripsHistoryHash;
        /// @notice The next squeezable timestamps. The key is the sender's user ID.
        /// Each `N`th element of the array is the next squeezable timestamp
        /// of the `N`th sender's drips configuration in effect in the current cycle.
        mapping(uint256 => uint32[2 ** 32]) nextSqueezed;
        /// @notice The drips receivers list hash, see `_hashDrips`.
        bytes32 dripsHash;
        /// @notice The next cycle to be received
        uint32 nextReceivableCycle;
        /// @notice The time when drips have been configured for the last time
        uint32 updateTime;
        /// @notice The maximum end time of drips
        uint32 maxEnd;
        /// @notice The balance when drips have been configured for the last time
        uint128 balance;
        /// @notice The number of drips configurations seen in the current cycle
        uint32 currCycleConfigs;
        /// @notice The changes of received amounts on specific cycle.
        /// The keys are cycles, each cycle `C` becomes receivable on timestamp `C * cycleSecs`.
        /// Values for cycles before `nextReceivableCycle` are guaranteed to be zeroed.
        /// This means that the value of `amtDeltas[nextReceivableCycle].thisCycle` is always
        /// relative to 0 or in other words it's an absolute value independent from other cycles.
        mapping(uint32 => AmtDelta) amtDeltas;
    }

    struct AmtDelta {
        /// @notice Amount delta applied on this cycle
        int128 thisCycle;
        /// @notice Amount delta applied on the next cycle
        int128 nextCycle;
    }

    /// @param cycleSecs The length of cycleSecs to be used in the contract instance.
    /// Low value makes funds more available by shortening the average time of funds being frozen
    /// between being taken from the users' drips balances and being receivable by their receivers.
    /// High value makes receiving cheaper by making it process less cycles for a given time range.
    /// Must be higher than 1.
    /// @param dripsStorageSlot The storage slot to holding a single `DripsStorage` structure.
    constructor(uint32 cycleSecs, bytes32 dripsStorageSlot) {
        require(cycleSecs > 1, "Cycle length too low");
        _cycleSecs = cycleSecs;
        _dripsStorageSlot = dripsStorageSlot;
    }

    /// @notice Receive drips from unreceived cycles of the user.
    /// Received drips cycles won't need to be analyzed ever again.
    /// @param userId The user ID
    /// @param assetId The used asset ID
    /// @param maxCycles The maximum number of received drips cycles.
    /// If too low, receiving will be cheap, but may not cover many cycles.
    /// If too high, receiving may become too expensive to fit in a single transaction.
    /// @return receivedAmt The received amount
    function _receiveDrips(uint256 userId, uint256 assetId, uint32 maxCycles)
        internal
        returns (uint128 receivedAmt)
    {
        uint32 receivableCycles;
        uint32 fromCycle;
        uint32 toCycle;
        int128 finalAmtPerCycle;
        (receivedAmt, receivableCycles, fromCycle, toCycle, finalAmtPerCycle) =
            _receiveDripsResult(userId, assetId, maxCycles);
        if (fromCycle != toCycle) {
            DripsState storage state = _dripsStorage().states[assetId][userId];
            state.nextReceivableCycle = toCycle;
            mapping(uint32 => AmtDelta) storage amtDeltas = state.amtDeltas;
            for (uint32 cycle = fromCycle; cycle < toCycle; cycle++) {
                delete amtDeltas[cycle];
            }
            // The next cycle delta must be relative to the last received cycle, which got zeroed.
            // In other words the next cycle delta must be an absolute value.
            if (finalAmtPerCycle != 0) {
                amtDeltas[toCycle].thisCycle += finalAmtPerCycle;
            }
        }
        emit ReceivedDrips(userId, assetId, receivedAmt, receivableCycles);
    }

    /// @notice Calculate effects of calling `_receiveDrips` with the given parameters.
    /// @param userId The user ID
    /// @param assetId The used asset ID
    /// @param maxCycles The maximum number of received drips cycles.
    /// If too low, receiving will be cheap, but may not cover many cycles.
    /// If too high, receiving may become too expensive to fit in a single transaction.
    /// @return receivedAmt The amount which would be received
    /// @return receivableCycles The number of cycles which would still be receivable after the call
    /// @return fromCycle The cycle from which funds would be received
    /// @return toCycle The cycle to which funds would be received
    /// @return amtPerCycle The amount per cycle when `toCycle` starts.
    function _receiveDripsResult(uint256 userId, uint256 assetId, uint32 maxCycles)
        internal
        view
        returns (
            uint128 receivedAmt,
            uint32 receivableCycles,
            uint32 fromCycle,
            uint32 toCycle,
            int128 amtPerCycle
        )
    {
        (fromCycle, toCycle) = _receivableDripsCyclesRange(userId, assetId);
        if (toCycle - fromCycle > maxCycles) {
            receivableCycles = toCycle - fromCycle - maxCycles;
            toCycle -= receivableCycles;
        }
        DripsState storage state = _dripsStorage().states[assetId][userId];
        for (uint32 cycle = fromCycle; cycle < toCycle; cycle++) {
            amtPerCycle += state.amtDeltas[cycle].thisCycle;
            receivedAmt += uint128(amtPerCycle);
            amtPerCycle += state.amtDeltas[cycle].nextCycle;
        }
    }

    /// @notice Counts cycles from which drips can be received.
    /// This function can be used to detect that there are
    /// too many cycles to analyze in a single transaction.
    /// @param userId The user ID
    /// @param assetId The used asset ID
    /// @return cycles The number of cycles which can be flushed
    function _receivableDripsCycles(uint256 userId, uint256 assetId)
        internal
        view
        returns (uint32 cycles)
    {
        (uint32 fromCycle, uint32 toCycle) = _receivableDripsCyclesRange(userId, assetId);
        return toCycle - fromCycle;
    }

    /// @notice Calculates the cycles range from which drips can be received.
    /// @param userId The user ID
    /// @param assetId The used asset ID
    /// @return fromCycle The cycle from which funds can be received
    /// @return toCycle The cycle to which funds can be received
    function _receivableDripsCyclesRange(uint256 userId, uint256 assetId)
        private
        view
        returns (uint32 fromCycle, uint32 toCycle)
    {
        fromCycle = _dripsStorage().states[assetId][userId].nextReceivableCycle;
        toCycle = _cycleOf(_currTimestamp());
        if (fromCycle == 0 || toCycle < fromCycle) {
            toCycle = fromCycle;
        }
    }

    /// @notice Receive drips from the currently running cycle from a single sender.
    /// It doesn't receive drips from the previous, finished cycles, to do that use `_receiveDrips`.
    /// Squeezed funds won't be received in the next calls to `_squeezeDrips` or `_receiveDrips`.
    /// Only funds dripped before `block.timestamp` can be squeezed.
    /// @param userId The ID of the user receiving drips to squeeze funds for.
    /// @param assetId The used asset ID.
    /// @param senderId The ID of the user sending drips to squeeze funds from.
    /// @param historyHash The sender's history hash which was valid right before
    /// they set up the sequence of configurations described by `dripsHistory`.
    /// @param dripsHistory The sequence of the sender's drips configurations.
    /// It can start at an arbitrary past configuration, but must describe all the configurations
    /// which have been used since then including the current one, in the chronological order.
    /// Only drips described by `dripsHistory` will be squeezed.
    /// If `dripsHistory` entries have no receivers, they won't be squeezed.
    /// @return amt The squeezed amount.
    function _squeezeDrips(
        uint256 userId,
        uint256 assetId,
        uint256 senderId,
        bytes32 historyHash,
        DripsHistory[] memory dripsHistory
    ) internal returns (uint128 amt) {
        uint256 squeezedNum;
        uint256[] memory squeezedRevIdxs;
        bytes32[] memory historyHashes;
        uint256 currCycleConfigs;
        (amt, squeezedNum, squeezedRevIdxs, historyHashes, currCycleConfigs) =
            _squeezeDripsResult(userId, assetId, senderId, historyHash, dripsHistory);
        bytes32[] memory squeezedHistoryHashes = new bytes32[](squeezedNum);
        DripsState storage state = _dripsStorage().states[assetId][userId];
        uint32[2 ** 32] storage nextSqueezed = state.nextSqueezed[senderId];
        for (uint256 i = 0; i < squeezedNum; i++) {
            // `squeezedRevIdxs` are sorted from the newest configuration to the oldest,
            // but we need to consume them from the oldest to the newest.
            uint256 revIdx = squeezedRevIdxs[squeezedNum - i - 1];
            squeezedHistoryHashes[i] = historyHashes[historyHashes.length - revIdx];
            nextSqueezed[currCycleConfigs - revIdx] = _currTimestamp();
        }
        uint32 cycleStart = _currCycleStart();
        _addDeltaRange(state, cycleStart, cycleStart + 1, -int256(amt * _AMT_PER_SEC_MULTIPLIER));
        emit SqueezedDrips(userId, assetId, senderId, amt, squeezedHistoryHashes);
    }

    /// @notice Calculate effects of calling `_squeezeDrips` with the given parameters.
    /// See its documentation for more details.
    /// @param userId The ID of the user receiving drips to squeeze funds for.
    /// @param assetId The used asset ID.
    /// @param senderId The ID of the user sending drips to squeeze funds from.
    /// @param historyHash The sender's history hash which was valid right before `dripsHistory`.
    /// @param dripsHistory The sequence of the sender's drips configurations.
    /// @return amt The squeezed amount.
    /// @return squeezedNum The number of squeezed history entries.
    /// @return squeezedRevIdxs The indexes of the squeezed history entries.
    /// The indexes are reversed, meaning that to get the actual index in an array,
    /// they must counted from the end of arrays, as in `arrayLength - squeezedRevIdxs[i]`.
    /// These indexes can be safely used to access `dripsHistory`, `historyHashes`
    /// and `nextSqueezed` regardless of their lengths.
    /// `squeezeRevIdxs` is sorted ascending, from pointing at the most recent entry to the oldest.
    /// @return historyHashes The history hashes valid for squeezing each of `dripsHistory` entries.
    /// In other words history hashes which had been valid right before each drips
    /// configuration was set, matching `dripsHistoryHash` emitted in its `DripsSet`.
    /// The first item is always equal to `historyHash`.
    /// @return currCycleConfigs The number of the sender's
    /// drips configurations which have been seen in the current cycle.
    /// This is also the number of used entries in each of the sender's `nextSqueezed` arrays.
    function _squeezeDripsResult(
        uint256 userId,
        uint256 assetId,
        uint256 senderId,
        bytes32 historyHash,
        DripsHistory[] memory dripsHistory
    )
        internal
        view
        returns (
            uint128 amt,
            uint256 squeezedNum,
            uint256[] memory squeezedRevIdxs,
            bytes32[] memory historyHashes,
            uint256 currCycleConfigs
        )
    {
        {
            DripsState storage sender = _dripsStorage().states[assetId][senderId];
            historyHashes = _verifyDripsHistory(historyHash, dripsHistory, sender.dripsHistoryHash);
            // If the last update was not in the current cycle,
            // there's only the single latest history entry to squeeze in the current cycle.
            currCycleConfigs = 1;
            if (sender.updateTime >= _currCycleStart()) currCycleConfigs = sender.currCycleConfigs;
        }
        squeezedRevIdxs = new uint256[](dripsHistory.length);
        uint32[2 ** 32] storage nextSqueezed =
            _dripsStorage().states[assetId][userId].nextSqueezed[senderId];
        uint32 squeezeEndCap = _currTimestamp();
        for (uint256 i = 1; i <= dripsHistory.length && i <= currCycleConfigs; i++) {
            DripsHistory memory drips = dripsHistory[dripsHistory.length - i];
            if (drips.receivers.length != 0) {
                uint32 squeezeStartCap = nextSqueezed[currCycleConfigs - i];
                if (squeezeStartCap < _currCycleStart()) squeezeStartCap = _currCycleStart();
                if (squeezeStartCap < squeezeEndCap) {
                    squeezedRevIdxs[squeezedNum++] = i;
                    amt += _squeezedAmt(userId, drips, squeezeStartCap, squeezeEndCap);
                }
            }
            squeezeEndCap = drips.updateTime;
        }
    }

    /// @notice Verify a drips history and revert if it's invalid.
    /// @param historyHash The user's history hash which was valid right before `dripsHistory`.
    /// @param dripsHistory The sequence of the user's drips configurations.
    /// @param finalHistoryHash The history hash at the end of `dripsHistory`.
    /// @return historyHashes The history hashes valid for squeezing each of `dripsHistory` entries.
    /// In other words history hashes which had been valid right before each drips
    /// configuration was set, matching `dripsHistoryHash`es emitted in `DripsSet`.
    /// The first item is always equal to `historyHash` and `finalHistoryHash` is never included.
    function _verifyDripsHistory(
        bytes32 historyHash,
        DripsHistory[] memory dripsHistory,
        bytes32 finalHistoryHash
    ) private pure returns (bytes32[] memory historyHashes) {
        historyHashes = new bytes32[](dripsHistory.length);
        for (uint256 i = 0; i < dripsHistory.length; i++) {
            DripsHistory memory drips = dripsHistory[i];
            bytes32 dripsHash = drips.dripsHash;
            if (drips.receivers.length != 0) {
                require(dripsHash == 0, "Drips history entry with hash and receivers");
                dripsHash = _hashDrips(drips.receivers);
            }
            historyHashes[i] = historyHash;
            historyHash = _hashDripsHistory(historyHash, dripsHash, drips.updateTime, drips.maxEnd);
        }
        require(historyHash == finalHistoryHash, "Invalid drips history");
    }

    /// @notice Calculate the amount squeezable by a user from a single drips history entry.
    /// @param userId The ID of the user to squeeze drips for.
    /// @param dripsHistory The squeezed history entry.
    /// @param squeezeStartCap The squeezed time range start.
    /// @param squeezeEndCap The squeezed time range end.
    /// @return squeezedAmt The squeezed amount.
    function _squeezedAmt(
        uint256 userId,
        DripsHistory memory dripsHistory,
        uint32 squeezeStartCap,
        uint32 squeezeEndCap
    ) private view returns (uint128 squeezedAmt) {
        DripsReceiver[] memory receivers = dripsHistory.receivers;
        // Binary search for the `idx` of the first occurrence of `userId`
        uint256 idx = 0;
        for (uint256 idxCap = receivers.length; idx < idxCap;) {
            uint256 idxMid = (idx + idxCap) / 2;
            if (receivers[idxMid].userId < userId) {
                idx = idxMid + 1;
            } else {
                idxCap = idxMid;
            }
        }
        uint32 updateTime = dripsHistory.updateTime;
        uint32 maxEnd = dripsHistory.maxEnd;
        uint256 amt = 0;
        for (; idx < receivers.length; idx++) {
            DripsReceiver memory receiver = receivers[idx];
            if (receiver.userId != userId) break;
            (uint32 start, uint32 end) =
                _dripsRange(receiver, updateTime, maxEnd, squeezeStartCap, squeezeEndCap);
            amt += _drippedAmt(receiver.config.amtPerSec(), start, end);
        }
        return uint128(amt);
    }

    /// @notice Current user drips state.
    /// @param userId The user ID
    /// @param assetId The used asset ID
    /// @return dripsHash The current drips receivers list hash, see `_hashDrips`
    /// @return dripsHistoryHash The current drips history hash, see `_hashDripsHistory`.
    /// @return updateTime The time when drips have been configured for the last time
    /// @return balance The balance when drips have been configured for the last time
    /// @return maxEnd The current maximum end time of drips
    function _dripsState(uint256 userId, uint256 assetId)
        internal
        view
        returns (
            bytes32 dripsHash,
            bytes32 dripsHistoryHash,
            uint32 updateTime,
            uint128 balance,
            uint32 maxEnd
        )
    {
        DripsState storage state = _dripsStorage().states[assetId][userId];
        return
            (state.dripsHash, state.dripsHistoryHash, state.updateTime, state.balance, state.maxEnd);
    }

    /// @notice User drips balance at a given timestamp
    /// @param userId The user ID
    /// @param assetId The used asset ID
    /// @param receivers The current drips receivers list
    /// @param timestamp The timestamps for which balance should be calculated.
    /// It can't be lower than the timestamp of the last call to `setDrips`.
    /// If it's bigger than `block.timestamp`, then it's a prediction assuming
    /// that `setDrips` won't be called before `timestamp`.
    /// @return balance The user balance on `timestamp`
    function _balanceAt(
        uint256 userId,
        uint256 assetId,
        DripsReceiver[] memory receivers,
        uint32 timestamp
    ) internal view returns (uint128 balance) {
        DripsState storage state = _dripsStorage().states[assetId][userId];
        require(timestamp >= state.updateTime, "Timestamp before last drips update");
        require(_hashDrips(receivers) == state.dripsHash, "Invalid current drips list");
        return _balanceAt(state.balance, state.updateTime, state.maxEnd, receivers, timestamp);
    }

    /// @notice Calculates the drips balance at a given timestamp.
    /// @param lastBalance The balance when drips have started
    /// @param lastUpdate The timestamp when drips have started.
    /// @param maxEnd The maximum end time of drips
    /// @param receivers The list of drips receivers.
    /// @param timestamp The timestamps for which balance should be calculated.
    /// It can't be lower than `lastUpdate`.
    /// If it's bigger than `block.timestamp`, then it's a prediction assuming
    /// that `setDrips` won't be called before `timestamp`.
    /// @return balance The user balance on `timestamp`
    function _balanceAt(
        uint128 lastBalance,
        uint32 lastUpdate,
        uint32 maxEnd,
        DripsReceiver[] memory receivers,
        uint32 timestamp
    ) private view returns (uint128 balance) {
        balance = lastBalance;
        for (uint256 i = 0; i < receivers.length; i++) {
            DripsReceiver memory receiver = receivers[i];
            (uint32 start, uint32 end) = _dripsRange({
                receiver: receiver,
                updateTime: lastUpdate,
                maxEnd: maxEnd,
                startCap: lastUpdate,
                endCap: timestamp
            });
            balance -= uint128(_drippedAmt(receiver.config.amtPerSec(), start, end));
        }
    }

    /// @notice Sets the user's drips configuration.
    /// @param userId The user ID
    /// @param assetId The used asset ID
    /// @param currReceivers The list of the drips receivers set in the last drips update
    /// of the user.
    /// If this is the first update, pass an empty array.
    /// @param balanceDelta The drips balance change being applied.
    /// Positive when adding funds to the drips balance, negative to removing them.
    /// @param newReceivers The list of the drips receivers of the user to be set.
    /// Must be sorted, deduplicated and without 0 amtPerSecs.
    /// @return realBalanceDelta The actually applied drips balance change.
    function _setDrips(
        uint256 userId,
        uint256 assetId,
        DripsReceiver[] memory currReceivers,
        int128 balanceDelta,
        DripsReceiver[] memory newReceivers,
        uint32 maxEndTip1,
        uint32 maxEndTip2
    ) internal returns (int128 realBalanceDelta) {
        DripsState storage state = _dripsStorage().states[assetId][userId];
        require(_hashDrips(currReceivers) == state.dripsHash, "Invalid current drips list");
        uint32 lastUpdate = state.updateTime;
        uint128 newBalance;
        uint32 newMaxEnd;
        {
            uint32 currMaxEnd = state.maxEnd;
            int128 currBalance = int128(
                _balanceAt(state.balance, lastUpdate, currMaxEnd, currReceivers, _currTimestamp())
            );
            realBalanceDelta = balanceDelta;
            // Cap `realBalanceDelta` at withdrawal of the entire `currBalance`
            if (realBalanceDelta < -currBalance) {
                realBalanceDelta = -currBalance;
            }
            newBalance = uint128(currBalance + realBalanceDelta);
            newMaxEnd = _calcMaxEnd(newBalance, newReceivers, maxEndTip1, maxEndTip2);
            _updateReceiverStates(
                _dripsStorage().states[assetId],
                currReceivers,
                lastUpdate,
                currMaxEnd,
                newReceivers,
                newMaxEnd
            );
        }
        state.updateTime = _currTimestamp();
        state.maxEnd = newMaxEnd;
        state.balance = newBalance;
        bytes32 dripsHistory = state.dripsHistoryHash;
        if (dripsHistory != 0 && _cycleOf(lastUpdate) != _cycleOf(_currTimestamp())) {
            state.currCycleConfigs = 2;
        } else {
            state.currCycleConfigs++;
        }
        bytes32 newDripsHash = _hashDrips(newReceivers);
        state.dripsHistoryHash =
            _hashDripsHistory(dripsHistory, newDripsHash, _currTimestamp(), newMaxEnd);
        emit DripsSet(userId, assetId, newDripsHash, dripsHistory, newBalance, newMaxEnd);
        if (newDripsHash != state.dripsHash) {
            state.dripsHash = newDripsHash;
            for (uint256 i = 0; i < newReceivers.length; i++) {
                DripsReceiver memory receiver = newReceivers[i];
                emit DripsReceiverSeen(newDripsHash, receiver.userId, receiver.config);
            }
        }
    }

    /// @notice Calculates the maximum end time of drips.
    /// @param balance The balance when drips have started
    /// @param receivers The list of drips receivers.
    /// Must be sorted, deduplicated and without 0 amtPerSecs.
    /// @return maxEnd The maximum end time of drips
    function _calcMaxEnd(
        uint128 balance,
        DripsReceiver[] memory receivers,
        uint32 maxEndTip1,
        uint32 maxEndTip2
    ) private view returns (uint32 maxEnd) {
        require(receivers.length <= _MAX_DRIPS_RECEIVERS, "Too many drips receivers");
        uint256[] memory configs = new uint256[](receivers.length);
        uint256 configsLen = 0;
        for (uint256 i = 0; i < receivers.length; i++) {
            DripsReceiver memory receiver = receivers[i];
            if (i > 0) {
                require(_isOrdered(receivers[i - 1], receiver), "Receivers not sorted");
            }
            configsLen = _addConfig(configs, configsLen, receiver);
        }
        return _calcMaxEnd(balance, configs, configsLen, maxEndTip1, maxEndTip2);
    }

    /// @notice Calculates the maximum end time of drips.
    /// @param balance The balance when drips have started
    /// @param configs The list of drips configurations
    /// @param configsLen The length of `configs`
    /// @return maxEnd The maximum end time of drips
    function _calcMaxEnd(
        uint128 balance,
        uint256[] memory configs,
        uint256 configsLen,
        uint32 maxEndTip1,
        uint32 maxEndTip2
    ) private view returns (uint32 maxEnd) {
        unchecked {
            uint256 enoughEnd = _currTimestamp();
            if (configsLen == 0 || balance == 0) {
                return uint32(enoughEnd);
            }

            uint256 notEnoughEnd = type(uint32).max;
            if (_isBalanceEnough(balance, configs, configsLen, notEnoughEnd)) {
                return uint32(notEnoughEnd);
            }

            if (maxEndTip1 > enoughEnd && maxEndTip1 < notEnoughEnd) {
                if (_isBalanceEnough(balance, configs, configsLen, maxEndTip1)) {
                    enoughEnd = maxEndTip1;
                } else {
                    notEnoughEnd = maxEndTip1;
                }
            }

            if (maxEndTip2 > enoughEnd && maxEndTip2 < notEnoughEnd) {
                if (_isBalanceEnough(balance, configs, configsLen, maxEndTip2)) {
                    enoughEnd = maxEndTip2;
                } else {
                    notEnoughEnd = maxEndTip2;
                }
            }

            while (true) {
                uint256 end = (enoughEnd + notEnoughEnd) / 2;
                if (end == enoughEnd) {
                    return uint32(end);
                }
                if (_isBalanceEnough(balance, configs, configsLen, end)) {
                    enoughEnd = end;
                } else {
                    notEnoughEnd = end;
                }
            }
        }
    }

    /// @notice Check if a given balance is enough to cover drips with the given `maxEnd`.
    /// @param balance The balance when drips have started
    /// @param configs The list of drips configurations
    /// @param configsLen The length of `configs`
    /// @param maxEnd The maximum end time of drips
    /// @return isEnough `true` if the balance is enough, `false` otherwise
    function _isBalanceEnough(
        uint256 balance,
        uint256[] memory configs,
        uint256 configsLen,
        uint256 maxEnd
    ) private view returns (bool isEnough) {
        unchecked {
            uint256 spent = 0;
            for (uint256 i = 0; i < configsLen; i++) {
                (uint256 amtPerSec, uint256 start, uint256 end) = _getConfig(configs, i);
                if (maxEnd <= start) {
                    continue;
                }
                if (end > maxEnd) {
                    end = maxEnd;
                }
                spent += _drippedAmt(amtPerSec, start, end);
                if (spent > balance) {
                    return false;
                }
            }
            return true;
        }
    }

    /// @notice Preprocess and add a drips receiver to the list of configurations.
    /// @param configs The list of drips configurations
    /// @param configsLen The length of `configs`
    /// @param receiver The added drips receivers.
    /// @return newConfigsLen The new length of `configs`
    function _addConfig(uint256[] memory configs, uint256 configsLen, DripsReceiver memory receiver)
        private
        view
        returns (uint256 newConfigsLen)
    {
        uint256 amtPerSec = receiver.config.amtPerSec();
        require(amtPerSec != 0, "Drips receiver amtPerSec is zero");
        (uint256 start, uint256 end) =
            _dripsRangeInFuture(receiver, _currTimestamp(), type(uint32).max);
        if (start == end) {
            return configsLen;
        }
        configs[configsLen] = (amtPerSec << 64) | (start << 32) | end;
        return configsLen + 1;
    }

    /// @notice Load a drips configuration from the list.
    /// @param configs The list of drips configurations
    /// @param idx The loaded configuration index. It must be smaller than the `configs` length.
    /// @return amtPerSec The amount per second being dripped.
    /// @return start The timestamp when dripping starts.
    /// @return end The maximum timestamp when dripping ends.
    function _getConfig(uint256[] memory configs, uint256 idx)
        private
        pure
        returns (uint256 amtPerSec, uint256 start, uint256 end)
    {
        uint256 val;
        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            val := mload(add(32, add(configs, shl(5, idx))))
        }
        return (val >> 64, uint32(val >> 32), uint32(val));
    }

    /// @notice Calculates the hash of the drips configuration.
    /// It's used to verify if drips configuration is the previously set one.
    /// @param receivers The list of the drips receivers.
    /// Must be sorted, deduplicated and without 0 amtPerSecs.
    /// If the drips have never been updated, pass an empty array.
    /// @return dripsHash The hash of the drips configuration
    function _hashDrips(DripsReceiver[] memory receivers)
        internal
        pure
        returns (bytes32 dripsHash)
    {
        if (receivers.length == 0) {
            return bytes32(0);
        }
        return keccak256(abi.encode(receivers));
    }

    /// @notice Calculates the hash of the drips history after the drips configuration is updated.
    /// @param oldDripsHistoryHash The history hash which was valid before the drips were updated.
    /// The `dripsHistoryHash` of a user before they set drips for the first time is `0`.
    /// @param dripsHash The hash of the drips receivers being set.
    /// @param updateTime The timestamp when the drips are updated.
    /// @param maxEnd The maximum end of the drips being set.
    /// @return dripsHistoryHash The hash of the updated drips history.
    function _hashDripsHistory(
        bytes32 oldDripsHistoryHash,
        bytes32 dripsHash,
        uint32 updateTime,
        uint32 maxEnd
    ) internal pure returns (bytes32 dripsHistoryHash) {
        return keccak256(abi.encode(oldDripsHistoryHash, dripsHash, updateTime, maxEnd));
    }

    /// @notice Applies the effects of the change of the drips on the receivers' drips states.
    /// @param states The drips states for the used asset.
    /// @param currReceivers The list of the drips receivers set in the last drips update
    /// of the user.
    /// If this is the first update, pass an empty array.
    /// @param lastUpdate the last time the sender updated the drips.
    /// If this is the first update, pass zero.
    /// @param currMaxEnd The maximum end time of drips according to the last drips update.
    /// @param newReceivers  The list of the drips receivers of the user to be set.
    /// Must be sorted, deduplicated and without 0 amtPerSecs.
    /// @param newMaxEnd The maximum end time of drips according to the new drips configuration.
    function _updateReceiverStates(
        mapping(uint256 => DripsState) storage states,
        DripsReceiver[] memory currReceivers,
        uint32 lastUpdate,
        uint32 currMaxEnd,
        DripsReceiver[] memory newReceivers,
        uint32 newMaxEnd
    ) private {
        uint256 currIdx = 0;
        uint256 newIdx = 0;
        while (true) {
            bool pickCurr = currIdx < currReceivers.length;
            DripsReceiver memory currRecv;
            if (pickCurr) {
                currRecv = currReceivers[currIdx];
            }

            bool pickNew = newIdx < newReceivers.length;
            DripsReceiver memory newRecv;
            if (pickNew) {
                newRecv = newReceivers[newIdx];
            }

            // Limit picking both curr and new to situations when they differ only by time
            if (
                pickCurr && pickNew
                    && (
                        currRecv.userId != newRecv.userId
                            || currRecv.config.amtPerSec() != newRecv.config.amtPerSec()
                    )
            ) {
                pickCurr = _isOrdered(currRecv, newRecv);
                pickNew = !pickCurr;
            }

            if (pickCurr && pickNew) {
                // Shift the existing drip to fulfil the new configuration
                DripsState storage state = states[currRecv.userId];
                (uint32 currStart, uint32 currEnd) =
                    _dripsRangeInFuture(currRecv, lastUpdate, currMaxEnd);
                (uint32 newStart, uint32 newEnd) =
                    _dripsRangeInFuture(newRecv, _currTimestamp(), newMaxEnd);
                {
                    int256 amtPerSec = int256(uint256(currRecv.config.amtPerSec()));
                    // Move the start and end times if updated
                    _addDeltaRange(state, currStart, newStart, -amtPerSec);
                    _addDeltaRange(state, currEnd, newEnd, amtPerSec);
                }
                // Ensure that the user receives the updated cycles
                uint32 currStartCycle = _cycleOf(currStart);
                uint32 newStartCycle = _cycleOf(newStart);
                // The `currStartCycle > newStartCycle` check is just an optimization.
                // If it's false, then `state.nextReceivableCycle > newStartCycle` must be
                // false too, there's no need to pay for the storage access to check it.
                if (currStartCycle > newStartCycle && state.nextReceivableCycle > newStartCycle) {
                    state.nextReceivableCycle = newStartCycle;
                }
            } else if (pickCurr) {
                // Remove an existing drip
                DripsState storage state = states[currRecv.userId];
                (uint32 start, uint32 end) = _dripsRangeInFuture(currRecv, lastUpdate, currMaxEnd);
                int256 amtPerSec = int256(uint256(currRecv.config.amtPerSec()));
                _addDeltaRange(state, start, end, -amtPerSec);
            } else if (pickNew) {
                // Create a new drip
                DripsState storage state = states[newRecv.userId];
                (uint32 start, uint32 end) =
                    _dripsRangeInFuture(newRecv, _currTimestamp(), newMaxEnd);
                int256 amtPerSec = int256(uint256(newRecv.config.amtPerSec()));
                _addDeltaRange(state, start, end, amtPerSec);
                // Ensure that the user receives the updated cycles
                uint32 startCycle = _cycleOf(start);
                if (state.nextReceivableCycle == 0 || state.nextReceivableCycle > startCycle) {
                    state.nextReceivableCycle = startCycle;
                }
            } else {
                break;
            }

            if (pickCurr) {
                currIdx++;
            }
            if (pickNew) {
                newIdx++;
            }
        }
    }

    /// @notice Calculates the time range in the future in which a receiver will be dripped to.
    /// @param receiver The drips receiver
    /// @param maxEnd The maximum end time of drips
    function _dripsRangeInFuture(DripsReceiver memory receiver, uint32 updateTime, uint32 maxEnd)
        private
        view
        returns (uint32 start, uint32 end)
    {
        return _dripsRange(receiver, updateTime, maxEnd, _currTimestamp(), type(uint32).max);
    }

    /// @notice Calculates the time range in which a receiver is to be dripped to.
    /// This range is capped to provide a view on drips through a specific time window.
    /// @param receiver The drips receiver
    /// @param updateTime The time when drips are configured
    /// @param maxEnd The maximum end time of drips
    /// @param startCap The timestamp the drips range start should be capped to
    /// @param endCap The timestamp the drips range end should be capped to
    function _dripsRange(
        DripsReceiver memory receiver,
        uint32 updateTime,
        uint32 maxEnd,
        uint32 startCap,
        uint32 endCap
    ) private pure returns (uint32 start, uint32 end_) {
        start = receiver.config.start();
        if (start == 0) {
            start = updateTime;
        }
        uint40 end = uint40(start) + receiver.config.duration();
        if (end == start || end > maxEnd) {
            end = maxEnd;
        }
        if (start < startCap) {
            start = startCap;
        }
        if (end > endCap) {
            end = endCap;
        }
        if (end < start) {
            end = start;
        }
        return (start, uint32(end));
    }

    /// @notice Adds funds received by a user in a given time range
    /// @param state The user state
    /// @param start The timestamp from which the delta takes effect
    /// @param end The timestamp until which the delta takes effect
    /// @param amtPerSec The dripping rate
    function _addDeltaRange(DripsState storage state, uint32 start, uint32 end, int256 amtPerSec)
        private
    {
        if (start == end) {
            return;
        }
        mapping(uint32 => AmtDelta) storage amtDeltas = state.amtDeltas;
        _addDelta(amtDeltas, start, amtPerSec);
        _addDelta(amtDeltas, end, -amtPerSec);
    }

    /// @notice Adds delta of funds received by a user at a given time
    /// @param amtDeltas The user amount deltas
    /// @param timestamp The timestamp when the deltas need to be added
    /// @param amtPerSec The dripping rate
    function _addDelta(
        mapping(uint32 => AmtDelta) storage amtDeltas,
        uint256 timestamp,
        int256 amtPerSec
    ) private {
        unchecked {
            // In order to set a delta on a specific timestamp it must be introduced in two cycles.
            // These formulas follow the logic from `_drippedAmt`, see it for more details.
            int256 amtPerSecMultiplier = int256(_AMT_PER_SEC_MULTIPLIER);
            int256 fullCycle = (int256(uint256(_cycleSecs)) * amtPerSec) / amtPerSecMultiplier;
            int256 nextCycle = (int256(timestamp % _cycleSecs) * amtPerSec) / amtPerSecMultiplier;
            AmtDelta storage amtDelta = amtDeltas[_cycleOf(uint32(timestamp))];
            // Any over- or under-flows are fine, they're guaranteed to be fixed by a matching
            // under- or over-flow from the other call to `_addDelta` made by `_addDeltaRange`.
            // This is because the total balance of `Drips` can never exceed `type(int128).max`,
            // so in the end no amtDelta can have delta higher than `type(int128).max`.
            amtDelta.thisCycle += int128(fullCycle - nextCycle);
            amtDelta.nextCycle += int128(nextCycle);
        }
    }

    /// @notice Checks if two receivers fulfil the sortedness requirement of the receivers list.
    /// @param prev The previous receiver
    /// @param prev The next receiver
    function _isOrdered(DripsReceiver memory prev, DripsReceiver memory next)
        private
        pure
        returns (bool)
    {
        if (prev.userId != next.userId) {
            return prev.userId < next.userId;
        }
        return prev.config.lt(next.config);
    }

    /// @notice Calculates the amount dripped over a time range.
    /// The amount dripped in the `N`th second of each cycle is:
    /// `(N + 1) * amtPerSec / AMT_PER_SEC_MULTIPLIER - N * amtPerSec / AMT_PER_SEC_MULTIPLIER`.
    /// For a range of `N`s from `0` to `M` the sum of the dripped amounts is calculated as:
    /// `M * amtPerSec / AMT_PER_SEC_MULTIPLIER` assuming that `M <= cycleSecs`.
    /// For an arbitrary time range across multiple cycles the amount is calculated as the sum of
    /// the amount dripped in the start cycle, each of the full cycles in between and the end cycle.
    /// This algorithm has the following properties:
    /// - During every second full units are dripped, there are no partially dripped units.
    /// - Undripped fractions are dripped when they add up into full units.
    /// - Undripped fractions don't add up across cycle end boundaries.
    /// - Some seconds drip more units and some less.
    /// - Every `N`th second of each cycle drips the same amount.
    /// - Every full cycle drips the same amount.
    /// - The amount dripped in a given second is independent from the dripping start and end.
    /// - Dripping over time ranges `A:B` and then `B:C` is equivalent to dripping over `A:C`.
    /// - Different drips existing in the system don't interfere with each other.
    /// @param amtPerSec The dripping rate
    /// @param start The dripping start time
    /// @param end The dripping end time
    /// @param amt The dripped amount
    function _drippedAmt(uint256 amtPerSec, uint256 start, uint256 end)
        private
        view
        returns (uint256 amt)
    {
        // This function is written in Yul because it can be called thousands of times
        // per transaction and it needs to be optimized as much as possible.
        // As of Solidity 0.8.13, rewriting it in unchecked Solidity triples its gas cost.
        uint256 cycleSecs = _cycleSecs;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let endedCycles := sub(div(end, cycleSecs), div(start, cycleSecs))
            let amtPerCycle := div(mul(cycleSecs, amtPerSec), _AMT_PER_SEC_MULTIPLIER)
            amt := mul(endedCycles, amtPerCycle)
            let amtEnd := div(mul(mod(end, cycleSecs), amtPerSec), _AMT_PER_SEC_MULTIPLIER)
            amt := add(amt, amtEnd)
            let amtStart := div(mul(mod(start, cycleSecs), amtPerSec), _AMT_PER_SEC_MULTIPLIER)
            amt := sub(amt, amtStart)
        }
    }

    /// @notice Calculates the cycle containing the given timestamp.
    /// @param timestamp The timestamp.
    /// @return cycle The cycle containing the timestamp.
    function _cycleOf(uint32 timestamp) private view returns (uint32 cycle) {
        unchecked {
            return timestamp / _cycleSecs + 1;
        }
    }

    /// @notice The current timestamp, casted to the contract's internal representation.
    /// @return timestamp The current timestamp
    function _currTimestamp() private view returns (uint32 timestamp) {
        return uint32(block.timestamp);
    }

    /// @notice The current cycle start timestamp, casted to the contract's internal representation.
    /// @return timestamp The current cycle start timestamp
    function _currCycleStart() private view returns (uint32 timestamp) {
        uint32 currTimestamp = _currTimestamp();
        return currTimestamp - (currTimestamp % _cycleSecs);
    }

    /// @notice Returns the Drips storage.
    /// @return dripsStorage The storage.
    function _dripsStorage() private view returns (DripsStorage storage dripsStorage) {
        bytes32 slot = _dripsStorageSlot;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            dripsStorage.slot := slot
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import {Drips, DripsConfig, DripsHistory, DripsConfigImpl, DripsReceiver} from "./Drips.sol";
import {IReserve} from "./Reserve.sol";
import {Managed} from "./Managed.sol";
import {Splits, SplitsReceiver} from "./Splits.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

/// @notice The user metadata.
/// The key and the value are not standardized by the protocol, it's up to the user
/// to establish and follow conventions to ensure compatibility with the consumers.
struct UserMetadata {
    /// @param key The metadata key
    bytes32 key;
    /// @param value The metadata value
    bytes value;
}

/// @notice Drips hub contract. Automatically drips and splits funds between users.
///
/// The user can transfer some funds to their drips balance in the contract
/// and configure a list of receivers, to whom they want to drip these funds.
/// As soon as the drips balance is enough to cover at least 1 second of dripping
/// to the configured receivers, the funds start dripping automatically.
/// Every second funds are deducted from the drips balance and moved to their receivers.
/// The process stops automatically when the drips balance is not enough to cover another second.
///
/// Every user has a receiver balance, in which they have funds received from other users.
/// The dripped funds are added to the receiver balances in global cycles.
/// Every `cycleSecs` seconds the drips hub adds dripped funds to the receivers' balances,
/// so recently dripped funds may not be receivable immediately.
/// `cycleSecs` is a constant configured when the drips hub is deployed.
/// The receiver balance is independent from the drips balance,
/// to drip received funds they need to be first collected and then added to the drips balance.
///
/// The user can share collected funds with other users by using splits.
/// When collecting, the user gives each of their splits receivers a fraction of the received funds.
/// Funds received from splits are available for collection immediately regardless of the cycle.
/// They aren't exempt from being split, so they too can be split when collected.
/// Users can build chains and networks of splits between each other.
/// Anybody can request collection of funds for any user,
/// which can be used to enforce the flow of funds in the network of splits.
///
/// The concept of something happening periodically, e.g. every second or every `cycleSecs` are
/// only high-level abstractions for the user, Ethereum isn't really capable of scheduling work.
/// The actual implementation emulates that behavior by calculating the results of the scheduled
/// events based on how many seconds have passed and only when the user needs their outcomes.
///
/// The contract can store at most `type(int128).max` which is `2 ^ 127 - 1` units of each token.
contract DripsHub is Managed, Drips, Splits {
    /// @notice The address of the ERC-20 reserve which the drips hub works with
    IReserve public immutable reserve;
    /// @notice Maximum number of drips receivers of a single user.
    /// Limits cost of changes in drips configuration.
    uint256 public constant MAX_DRIPS_RECEIVERS = _MAX_DRIPS_RECEIVERS;
    /// @notice The additional decimals for all amtPerSec values.
    uint8 public constant AMT_PER_SEC_EXTRA_DECIMALS = _AMT_PER_SEC_EXTRA_DECIMALS;
    /// @notice The multiplier for all amtPerSec values.
    uint256 public constant AMT_PER_SEC_MULTIPLIER = _AMT_PER_SEC_MULTIPLIER;
    /// @notice Maximum number of splits receivers of a single user. Limits the cost of splitting.
    uint256 public constant MAX_SPLITS_RECEIVERS = _MAX_SPLITS_RECEIVERS;
    /// @notice The total splits weight of a user
    uint32 public constant TOTAL_SPLITS_WEIGHT = _TOTAL_SPLITS_WEIGHT;
    /// @notice The offset of the controlling driver ID in the user ID.
    /// In other words the controlling driver ID is the higest 32 bits of the user ID.
    uint256 public constant DRIVER_ID_OFFSET = 224;
    /// @notice The total amount the contract can store of each token.
    uint256 public constant MAX_TOTAL_BALANCE = _MAX_TOTAL_DRIPS_BALANCE;
    /// @notice The ERC-1967 storage slot holding a single `DripsHubStorage` structure.
    bytes32 private immutable _storageSlot = erc1967Slot("eip1967.dripsHub.storage");

    /// @notice Emitted when a driver is registered
    /// @param driverId The driver ID
    /// @param driverAddr The driver address
    event DriverRegistered(uint32 indexed driverId, address indexed driverAddr);

    /// @notice Emitted when a driver address is updated
    /// @param driverId The driver ID
    /// @param oldDriverAddr The old driver address
    /// @param newDriverAddr The new driver address
    event DriverAddressUpdated(
        uint32 indexed driverId, address indexed oldDriverAddr, address indexed newDriverAddr
    );

    /// @notice Emitted by the user to broadcast metadata.
    /// The key and the value are not standardized by the protocol, it's up to the user
    /// to establish and follow conventions to ensure compatibility with the consumers.
    /// @param userId The ID of the user emitting metadata
    /// @param key The metadata key
    /// @param value The metadata value
    event UserMetadataEmitted(uint256 indexed userId, bytes32 indexed key, bytes value);

    struct DripsHubStorage {
        /// @notice The next driver ID that will be used when registering.
        uint32 nextDriverId;
        /// @notice Driver addresses. The key is the driver ID, the value is the driver address.
        mapping(uint32 => address) driverAddresses;
        /// @notice The total amount currently stored in DripsHub of each token.
        mapping(IERC20 => uint256) totalBalances;
    }

    /// @param cycleSecs_ The length of cycleSecs to be used in the contract instance.
    /// Low value makes funds more available by shortening the average time of funds being frozen
    /// between being taken from the users' drips balances and being receivable by their receivers.
    /// High value makes receiving cheaper by making it process less cycles for a given time range.
    /// Must be higher than 1.
    /// @param reserve_ The address of the ERC-20 reserve which the drips hub will work with
    constructor(uint32 cycleSecs_, IReserve reserve_)
        Drips(cycleSecs_, erc1967Slot("eip1967.drips.storage"))
        Splits(erc1967Slot("eip1967.splits.storage"))
    {
        reserve = reserve_;
    }

    /// @notice A modifier making functions callable only by the driver controlling the user ID.
    /// @param userId The user ID.
    modifier onlyDriver(uint256 userId) {
        uint32 driverId = uint32(userId >> DRIVER_ID_OFFSET);
        _assertCallerIsDriver(driverId);
        _;
    }

    function _assertCallerIsDriver(uint32 driverId) internal view {
        require(driverAddress(driverId) == msg.sender, "Callable only by the driver");
    }

    /// @notice Registers a driver.
    /// The driver is assigned a unique ID and a range of user IDs it can control.
    /// That range consists of all 2^224 user IDs with highest 32 bits equal to the driver ID.
    /// Multiple drivers can have the same address, that address can then control all of them.
    /// @param driverAddr The address of the driver.
    /// @return driverId The registered driver ID.
    function registerDriver(address driverAddr) public whenNotPaused returns (uint32 driverId) {
        DripsHubStorage storage dripsHubStorage = _dripsHubStorage();
        driverId = dripsHubStorage.nextDriverId++;
        dripsHubStorage.driverAddresses[driverId] = driverAddr;
        emit DriverRegistered(driverId, driverAddr);
    }

    /// @notice Returns the driver address.
    /// @param driverId The driver ID to look up.
    /// @return driverAddr The address of the driver.
    /// If the driver hasn't been registered yet, returns address 0.
    function driverAddress(uint32 driverId) public view returns (address driverAddr) {
        return _dripsHubStorage().driverAddresses[driverId];
    }

    /// @notice Updates the driver address. Must be called from the current driver address.
    /// @param driverId The driver ID.
    /// @param newDriverAddr The new address of the driver.
    function updateDriverAddress(uint32 driverId, address newDriverAddr) public whenNotPaused {
        _assertCallerIsDriver(driverId);
        _dripsHubStorage().driverAddresses[driverId] = newDriverAddr;
        emit DriverAddressUpdated(driverId, msg.sender, newDriverAddr);
    }

    /// @notice Returns the driver ID which will be assigned for the next registered driver.
    /// @return driverId The next driver ID.
    function nextDriverId() public view returns (uint32 driverId) {
        return _dripsHubStorage().nextDriverId;
    }

    /// @notice Returns the cycle length in seconds.
    /// On every timestamp `T`, which is a multiple of `cycleSecs`, the receivers
    /// gain access to drips received during `T - cycleSecs` to `T - 1`.
    /// Always higher than 1.
    /// @return cycleSecs_ The cycle length in seconds.
    function cycleSecs() public view returns (uint32 cycleSecs_) {
        return Drips._cycleSecs;
    }

    /// @notice Returns the total amount currently stored in DripsHub of the given token.
    /// @param erc20 The used ERC-20 token.
    /// It must preserve amounts, so if some amount of tokens is transferred to
    /// an address, then later the same amount must be transferrable from that address.
    /// Tokens which rebase the holders' balances, collect taxes on transfers,
    /// or impose any restrictions on holding or transferring tokens are not supported.
    /// If you use such tokens in the protocol, they can get stuck or lost.
    /// @return balance The balance of the token.
    function totalBalance(IERC20 erc20) public view returns (uint256 balance) {
        return _dripsHubStorage().totalBalances[erc20];
    }

    /// @notice Counts cycles from which drips can be collected.
    /// This function can be used to detect that there are
    /// too many cycles to analyze in a single transaction.
    /// @param userId The user ID
    /// @param erc20 The used ERC-20 token.
    /// It must preserve amounts, so if some amount of tokens is transferred to
    /// an address, then later the same amount must be transferrable from that address.
    /// Tokens which rebase the holders' balances, collect taxes on transfers,
    /// or impose any restrictions on holding or transferring tokens are not supported.
    /// If you use such tokens in the protocol, they can get stuck or lost.
    /// @return cycles The number of cycles which can be flushed
    function receivableDripsCycles(uint256 userId, IERC20 erc20)
        public
        view
        returns (uint32 cycles)
    {
        return Drips._receivableDripsCycles(userId, _assetId(erc20));
    }

    /// @notice Calculate effects of calling `receiveDrips` with the given parameters.
    /// @param userId The user ID
    /// @param erc20 The used ERC-20 token.
    /// It must preserve amounts, so if some amount of tokens is transferred to
    /// an address, then later the same amount must be transferrable from that address.
    /// Tokens which rebase the holders' balances, collect taxes on transfers,
    /// or impose any restrictions on holding or transferring tokens are not supported.
    /// If you use such tokens in the protocol, they can get stuck or lost.
    /// @param maxCycles The maximum number of received drips cycles.
    /// If too low, receiving will be cheap, but may not cover many cycles.
    /// If too high, receiving may become too expensive to fit in a single transaction.
    /// @return receivableAmt The amount which would be received
    function receiveDripsResult(uint256 userId, IERC20 erc20, uint32 maxCycles)
        public
        view
        returns (uint128 receivableAmt)
    {
        (receivableAmt,,,,) = Drips._receiveDripsResult(userId, _assetId(erc20), maxCycles);
    }

    /// @notice Receive drips for the user.
    /// Received drips cycles won't need to be analyzed ever again.
    /// Calling this function does not collect but makes the funds ready to be split and collected.
    /// @param userId The user ID
    /// @param erc20 The used ERC-20 token.
    /// It must preserve amounts, so if some amount of tokens is transferred to
    /// an address, then later the same amount must be transferrable from that address.
    /// Tokens which rebase the holders' balances, collect taxes on transfers,
    /// or impose any restrictions on holding or transferring tokens are not supported.
    /// If you use such tokens in the protocol, they can get stuck or lost.
    /// @param maxCycles The maximum number of received drips cycles.
    /// If too low, receiving will be cheap, but may not cover many cycles.
    /// If too high, receiving may become too expensive to fit in a single transaction.
    /// @return receivedAmt The received amount
    function receiveDrips(uint256 userId, IERC20 erc20, uint32 maxCycles)
        public
        whenNotPaused
        returns (uint128 receivedAmt)
    {
        uint256 assetId = _assetId(erc20);
        receivedAmt = Drips._receiveDrips(userId, assetId, maxCycles);
        if (receivedAmt > 0) {
            Splits._addSplittable(userId, assetId, receivedAmt);
        }
    }

    /// @notice Receive drips from the currently running cycle from a single sender.
    /// It doesn't receive drips from the previous, finished cycles, to do that use `receiveDrips`.
    /// Squeezed funds won't be received in the next calls to `squeezeDrips` or `receiveDrips`.
    /// Only funds dripped before `block.timestamp` can be squeezed.
    /// @param userId The ID of the user receiving drips to squeeze funds for.
    /// @param erc20 The used ERC-20 token.
    /// It must preserve amounts, so if some amount of tokens is transferred to
    /// an address, then later the same amount must be transferrable from that address.
    /// Tokens which rebase the holders' balances, collect taxes on transfers,
    /// or impose any restrictions on holding or transferring tokens are not supported.
    /// If you use such tokens in the protocol, they can get stuck or lost.
    /// @param senderId The ID of the user sending drips to squeeze funds from.
    /// @param historyHash The sender's history hash which was valid right before
    /// they set up the sequence of configurations described by `dripsHistory`.
    /// @param dripsHistory The sequence of the sender's drips configurations.
    /// It can start at an arbitrary past configuration, but must describe all the configurations
    /// which have been used since then including the current one, in the chronological order.
    /// Only drips described by `dripsHistory` will be squeezed.
    /// If `dripsHistory` entries have no receivers, they won't be squeezed.
    /// @return amt The squeezed amount.
    function squeezeDrips(
        uint256 userId,
        IERC20 erc20,
        uint256 senderId,
        bytes32 historyHash,
        DripsHistory[] memory dripsHistory
    ) public whenNotPaused returns (uint128 amt) {
        uint256 assetId = _assetId(erc20);
        amt = Drips._squeezeDrips(userId, assetId, senderId, historyHash, dripsHistory);
        if (amt > 0) {
            Splits._addSplittable(userId, assetId, amt);
        }
    }

    /// @notice Calculate effects of calling `squeezeDrips` with the given parameters.
    /// See its documentation for more details.
    /// @param userId The ID of the user receiving drips to squeeze funds for.
    /// @param erc20 The used ERC-20 token.
    /// It must preserve amounts, so if some amount of tokens is transferred to
    /// an address, then later the same amount must be transferrable from that address.
    /// Tokens which rebase the holders' balances, collect taxes on transfers,
    /// or impose any restrictions on holding or transferring tokens are not supported.
    /// If you use such tokens in the protocol, they can get stuck or lost.
    /// @param senderId The ID of the user sending drips to squeeze funds from.
    /// @param historyHash The sender's history hash which was valid right before `dripsHistory`.
    /// @param dripsHistory The sequence of the sender's drips configurations.
    /// @return amt The squeezed amount.
    function squeezeDripsResult(
        uint256 userId,
        IERC20 erc20,
        uint256 senderId,
        bytes32 historyHash,
        DripsHistory[] memory dripsHistory
    ) public view returns (uint128 amt) {
        (amt,,,,) =
            Drips._squeezeDripsResult(userId, _assetId(erc20), senderId, historyHash, dripsHistory);
    }

    /// @notice Returns user's received but not split yet funds.
    /// @param userId The user ID
    /// @param erc20 The used ERC-20 token.
    /// It must preserve amounts, so if some amount of tokens is transferred to
    /// an address, then later the same amount must be transferrable from that address.
    /// Tokens which rebase the holders' balances, collect taxes on transfers,
    /// or impose any restrictions on holding or transferring tokens are not supported.
    /// If you use such tokens in the protocol, they can get stuck or lost.
    /// @return amt The amount received but not split yet.
    function splittable(uint256 userId, IERC20 erc20) public view returns (uint128 amt) {
        return Splits._splittable(userId, _assetId(erc20));
    }

    /// @notice Calculate the result of splitting an amount using the current splits configuration.
    /// @param userId The user ID
    /// @param currReceivers The list of the user's current splits receivers.
    /// @param amount The amount being split.
    /// @return collectableAmt The amount made collectable for the user
    /// on top of what was collectable before.
    /// @return splitAmt The amount split to the user's splits receivers
    function splitResult(uint256 userId, SplitsReceiver[] memory currReceivers, uint128 amount)
        public
        view
        returns (uint128 collectableAmt, uint128 splitAmt)
    {
        return Splits._splitResult(userId, currReceivers, amount);
    }

    /// @notice Splits user's received but not split yet funds among receivers.
    /// @param userId The user ID
    /// @param erc20 The used ERC-20 token.
    /// It must preserve amounts, so if some amount of tokens is transferred to
    /// an address, then later the same amount must be transferrable from that address.
    /// Tokens which rebase the holders' balances, collect taxes on transfers,
    /// or impose any restrictions on holding or transferring tokens are not supported.
    /// If you use such tokens in the protocol, they can get stuck or lost.
    /// @param currReceivers The list of the user's current splits receivers.
    /// @return collectableAmt The amount made collectable for the user
    /// on top of what was collectable before.
    /// @return splitAmt The amount split to the user's splits receivers
    function split(uint256 userId, IERC20 erc20, SplitsReceiver[] memory currReceivers)
        public
        whenNotPaused
        returns (uint128 collectableAmt, uint128 splitAmt)
    {
        return Splits._split(userId, _assetId(erc20), currReceivers);
    }

    /// @notice Returns user's received funds already split and ready to be collected.
    /// @param userId The user ID
    /// @param erc20 The used ERC-20 token.
    /// It must preserve amounts, so if some amount of tokens is transferred to
    /// an address, then later the same amount must be transferrable from that address.
    /// Tokens which rebase the holders' balances, collect taxes on transfers,
    /// or impose any restrictions on holding or transferring tokens are not supported.
    /// If you use such tokens in the protocol, they can get stuck or lost.
    /// @return amt The collectable amount.
    function collectable(uint256 userId, IERC20 erc20) public view returns (uint128 amt) {
        return Splits._collectable(userId, _assetId(erc20));
    }

    /// @notice Collects user's received already split funds
    /// and transfers them out of the drips hub contract to msg.sender.
    /// @param userId The user ID
    /// @param erc20 The used ERC-20 token.
    /// It must preserve amounts, so if some amount of tokens is transferred to
    /// an address, then later the same amount must be transferrable from that address.
    /// Tokens which rebase the holders' balances, collect taxes on transfers,
    /// or impose any restrictions on holding or transferring tokens are not supported.
    /// If you use such tokens in the protocol, they can get stuck or lost.
    /// @return amt The collected amount
    function collect(uint256 userId, IERC20 erc20)
        public
        whenNotPaused
        onlyDriver(userId)
        returns (uint128 amt)
    {
        amt = Splits._collect(userId, _assetId(erc20));
        _decreaseTotalBalance(erc20, amt);
        reserve.withdraw(erc20, msg.sender, amt);
    }

    /// @notice Gives funds from the user to the receiver.
    /// The receiver can split and collect them immediately.
    /// Transfers the funds to be given from the user's wallet to the drips hub contract.
    /// @param userId The user ID
    /// @param receiver The receiver
    /// @param erc20 The used ERC-20 token.
    /// It must preserve amounts, so if some amount of tokens is transferred to
    /// an address, then later the same amount must be transferrable from that address.
    /// Tokens which rebase the holders' balances, collect taxes on transfers,
    /// or impose any restrictions on holding or transferring tokens are not supported.
    /// If you use such tokens in the protocol, they can get stuck or lost.
    /// @param amt The given amount
    function give(uint256 userId, uint256 receiver, IERC20 erc20, uint128 amt)
        public
        whenNotPaused
        onlyDriver(userId)
    {
        _increaseTotalBalance(erc20, amt);
        Splits._give(userId, receiver, _assetId(erc20), amt);
        reserve.deposit(erc20, msg.sender, amt);
    }

    /// @notice Current user drips state.
    /// @param userId The user ID
    /// @param erc20 The used ERC-20 token.
    /// It must preserve amounts, so if some amount of tokens is transferred to
    /// an address, then later the same amount must be transferrable from that address.
    /// Tokens which rebase the holders' balances, collect taxes on transfers,
    /// or impose any restrictions on holding or transferring tokens are not supported.
    /// If you use such tokens in the protocol, they can get stuck or lost.
    /// @return dripsHash The current drips receivers list hash, see `hashDrips`
    /// @return dripsHistoryHash The current drips history hash, see `hashDripsHistory`.
    /// @return updateTime The time when drips have been configured for the last time
    /// @return balance The balance when drips have been configured for the last time
    /// @return maxEnd The current maximum end time of drips
    function dripsState(uint256 userId, IERC20 erc20)
        public
        view
        returns (
            bytes32 dripsHash,
            bytes32 dripsHistoryHash,
            uint32 updateTime,
            uint128 balance,
            uint32 maxEnd
        )
    {
        return Drips._dripsState(userId, _assetId(erc20));
    }

    /// @notice User drips balance at a given timestamp
    /// @param userId The user ID
    /// @param erc20 The used ERC-20 token.
    /// It must preserve amounts, so if some amount of tokens is transferred to
    /// an address, then later the same amount must be transferrable from that address.
    /// Tokens which rebase the holders' balances, collect taxes on transfers,
    /// or impose any restrictions on holding or transferring tokens are not supported.
    /// If you use such tokens in the protocol, they can get stuck or lost.
    /// @param receivers The current drips receivers list
    /// @param timestamp The timestamps for which balance should be calculated.
    /// It can't be lower than the timestamp of the last call to `setDrips`.
    /// If it's bigger than `block.timestamp`, then it's a prediction assuming
    /// that `setDrips` won't be called before `timestamp`.
    /// @return balance The user balance on `timestamp`
    function balanceAt(
        uint256 userId,
        IERC20 erc20,
        DripsReceiver[] memory receivers,
        uint32 timestamp
    ) public view returns (uint128 balance) {
        return Drips._balanceAt(userId, _assetId(erc20), receivers, timestamp);
    }

    /// @notice Sets the user's drips configuration.
    /// Transfers funds between the user's wallet and the drips hub contract
    /// to fulfill the change of the drips balance.
    /// @param userId The user ID
    /// @param erc20 The used ERC-20 token.
    /// It must preserve amounts, so if some amount of tokens is transferred to
    /// an address, then later the same amount must be transferrable from that address.
    /// Tokens which rebase the holders' balances, collect taxes on transfers,
    /// or impose any restrictions on holding or transferring tokens are not supported.
    /// If you use such tokens in the protocol, they can get stuck or lost.
    /// @param currReceivers The list of the drips receivers set in the last drips update
    /// of the user.
    /// If this is the first update, pass an empty array.
    /// @param balanceDelta The drips balance change to be applied.
    /// Positive to add funds to the drips balance, negative to remove them.
    /// @param newReceivers The list of the drips receivers of the user to be set.
    /// Must be sorted by the receivers' addresses, deduplicated and without 0 amtPerSecs.
    /// @return realBalanceDelta The actually applied drips balance change.
    function setDrips(
        uint256 userId,
        IERC20 erc20,
        DripsReceiver[] memory currReceivers,
        int128 balanceDelta,
        DripsReceiver[] memory newReceivers,
        uint32 maxEndTip1,
        uint32 maxEndTip2
    ) public whenNotPaused onlyDriver(userId) returns (int128 realBalanceDelta) {
        if (balanceDelta > 0) {
            _increaseTotalBalance(erc20, uint128(balanceDelta));
        }
        realBalanceDelta = Drips._setDrips(
            userId,
            _assetId(erc20),
            currReceivers,
            balanceDelta,
            newReceivers,
            maxEndTip1,
            maxEndTip2
        );
        if (realBalanceDelta > 0) {
            reserve.deposit(erc20, msg.sender, uint128(realBalanceDelta));
        } else if (realBalanceDelta < 0) {
            _decreaseTotalBalance(erc20, uint128(-realBalanceDelta));
            reserve.withdraw(erc20, msg.sender, uint128(-realBalanceDelta));
        }
    }

    /// @notice Calculates the hash of the drips configuration.
    /// It's used to verify if drips configuration is the previously set one.
    /// @param receivers The list of the drips receivers.
    /// Must be sorted by the receivers' addresses, deduplicated and without 0 amtPerSecs.
    /// If the drips have never been updated, pass an empty array.
    /// @return dripsHash The hash of the drips configuration
    function hashDrips(DripsReceiver[] memory receivers) public pure returns (bytes32 dripsHash) {
        return Drips._hashDrips(receivers);
    }

    /// @notice Calculates the hash of the drips history after the drips configuration is updated.
    /// @param oldDripsHistoryHash The history hash which was valid before the drips were updated.
    /// The `dripsHistoryHash` of a user before they set drips for the first time is `0`.
    /// @param dripsHash The hash of the drips receivers being set.
    /// @param updateTime The timestamp when the drips are updated.
    /// @param maxEnd The maximum end of the drips being set.
    /// @return dripsHistoryHash The hash of the updated drips history.
    function hashDripsHistory(
        bytes32 oldDripsHistoryHash,
        bytes32 dripsHash,
        uint32 updateTime,
        uint32 maxEnd
    ) public pure returns (bytes32 dripsHistoryHash) {
        return Drips._hashDripsHistory(oldDripsHistoryHash, dripsHash, updateTime, maxEnd);
    }

    /// @notice Sets user splits configuration.
    /// @param userId The user ID
    /// @param receivers The list of the user's splits receivers to be set.
    /// Must be sorted by the splits receivers' addresses, deduplicated and without 0 weights.
    /// Each splits receiver will be getting `weight / TOTAL_SPLITS_WEIGHT`
    /// share of the funds collected by the user.
    function setSplits(uint256 userId, SplitsReceiver[] memory receivers)
        public
        whenNotPaused
        onlyDriver(userId)
    {
        Splits._setSplits(userId, receivers);
    }

    /// @notice Current user's splits hash, see `hashSplits`.
    /// @param userId The user ID
    /// @return currSplitsHash The current user's splits hash
    function splitsHash(uint256 userId) public view returns (bytes32 currSplitsHash) {
        return Splits._splitsHash(userId);
    }

    /// @notice Calculates the hash of the list of splits receivers.
    /// @param receivers The list of the splits receivers.
    /// Must be sorted by the splits receivers' addresses, deduplicated and without 0 weights.
    /// @return receiversHash The hash of the list of splits receivers.
    function hashSplits(SplitsReceiver[] memory receivers)
        public
        pure
        returns (bytes32 receiversHash)
    {
        return Splits._hashSplits(receivers);
    }

    /// @notice Emits user metadata.
    /// The keys and the values are not standardized by the protocol, it's up to the user
    /// to establish and follow conventions to ensure compatibility with the consumers.
    /// @param userId The user ID.
    /// @param userMetadata The list of user metadata.
    function emitUserMetadata(uint256 userId, UserMetadata[] calldata userMetadata)
        public
        whenNotPaused
        onlyDriver(userId)
    {
        for (uint256 i = 0; i < userMetadata.length; i++) {
            UserMetadata calldata metadata = userMetadata[i];
            emit UserMetadataEmitted(userId, metadata.key, metadata.value);
        }
    }

    /// @notice Returns the DripsHub storage.
    /// @return storageRef The storage.
    function _dripsHubStorage() internal view returns (DripsHubStorage storage storageRef) {
        bytes32 slot = _storageSlot;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            storageRef.slot := slot
        }
    }

    function _increaseTotalBalance(IERC20 erc20, uint128 amt) internal {
        mapping(IERC20 => uint256) storage totalBalances = _dripsHubStorage().totalBalances;
        require(totalBalances[erc20] + amt <= MAX_TOTAL_BALANCE, "Total balance too high");
        totalBalances[erc20] += amt;
    }

    function _decreaseTotalBalance(IERC20 erc20, uint128 amt) internal {
        _dripsHubStorage().totalBalances[erc20] -= amt;
    }

    /// @notice Generates an asset ID for the ERC-20 token
    /// @param erc20 The ERC-20 token
    /// @return assetId The asset ID
    function _assetId(IERC20 erc20) internal pure returns (uint256 assetId) {
        return uint160(address(erc20));
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import {DripsHub, SplitsReceiver, UserMetadata} from "./DripsHub.sol";
import {Upgradeable} from "./Upgradeable.sol";
import {StorageSlot} from "openzeppelin-contracts/utils/StorageSlot.sol";

/// @notice A DripsHub driver implementing immutable splits configurations.
/// Anybody can create a new user ID and configure its splits configuration,
/// but nobody can update its configuration afterwards, it's immutable.
contract ImmutableSplitsDriver is Upgradeable {
    /// @notice The DripsHub address used by this driver.
    DripsHub public immutable dripsHub;
    /// @notice The driver ID which this driver uses when calling DripsHub.
    uint32 public immutable driverId;
    /// @notice The required total splits weight of each splits configuration
    uint32 public immutable totalSplitsWeight;
    /// @notice The ERC-1967 storage slot holding a single `uint256` counter of created identities.
    bytes32 private immutable _counterSlot = erc1967Slot("eip1967.immutableSplitsDriver.storage");

    /// @notice Emitted when an immutable splits configuration is created.
    /// @param userId The user ID
    /// @param receiversHash The splits receivers list hash
    event CreatedSplits(uint256 indexed userId, bytes32 indexed receiversHash);

    /// @param _dripsHub The drips hub to use.
    /// @param _driverId The driver ID to use when calling DripsHub.
    constructor(DripsHub _dripsHub, uint32 _driverId) {
        dripsHub = _dripsHub;
        driverId = _driverId;
        totalSplitsWeight = _dripsHub.TOTAL_SPLITS_WEIGHT();
    }

    /// @notice The ID of the next user to be created.
    /// @return userId The user ID.
    function nextUserId() public view returns (uint256 userId) {
        return (uint256(driverId) << 224) + StorageSlot.getUint256Slot(_counterSlot).value;
    }

    /// @notice Creates a new user ID, configures its splits configuration and emits its metadata.
    /// The configuration is immutable and nobody can control the user ID after its creation.
    /// Calling this function is the only way and the only chance to emit metadata for that user.
    /// @param receivers The list of the user's splits receivers to be set.
    /// Must be sorted by the splits receivers' addresses, deduplicated and without 0 weights.
    /// Each splits receiver will be getting `weight / totalSplitsWeight`
    /// share of the funds collected by the user.
    /// The sum of the receivers' weights must be equal to `totalSplitsWeight`,
    /// or in other words the configuration must be splitting 100% of received funds.
    /// @param userMetadata The list of user metadata to emit for the created user.
    /// The keys and the values are not standardized by the protocol, it's up to the user
    /// to establish and follow conventions to ensure compatibility with the consumers.
    /// @return userId The new user ID with `receivers` configured.
    function createSplits(SplitsReceiver[] calldata receivers, UserMetadata[] calldata userMetadata)
        public
        returns (uint256 userId)
    {
        userId = nextUserId();
        StorageSlot.getUint256Slot(_counterSlot).value++;
        uint256 weightSum = 0;
        for (uint256 i = 0; i < receivers.length; i++) {
            weightSum += receivers[i].weight;
        }
        require(weightSum == totalSplitsWeight, "Invalid total receivers weight");
        dripsHub.setSplits(userId, receivers);
        if (userMetadata.length > 0) dripsHub.emitUserMetadata(userId, userMetadata);
        emit CreatedSplits(userId, dripsHub.splitsHash(userId));
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import {Upgradeable} from "./Upgradeable.sol";
import {StorageSlot} from "openzeppelin-contracts/utils/StorageSlot.sol";

/// @notice A mix-in for contract pauseability and upgradeability.
/// It can't be used directly, only via a proxy. It uses the upgrade-safe ERC-1967 storage scheme.
///
/// All instances of the contracts are paused and can't be unpaused.
/// When a proxy uses such contract via delegation, it's initially unpaused.
abstract contract Managed is Upgradeable {
    /// @notice The pointer to the storage slot with the boolean holding the paused state.
    bytes32 private immutable pausedSlot = erc1967Slot("eip1967.managed.paused");

    /// @notice Emitted when the pause is triggered.
    /// @param caller The caller who triggered the change.
    event Paused(address caller);

    /// @notice Emitted when the pause is lifted.
    /// @param caller The caller who triggered the change.
    event Unpaused(address caller);

    /// @notice Modifier to make a function callable only when the contract is not paused.
    modifier whenNotPaused() {
        require(!paused(), "Contract paused");
        _;
    }

    /// @notice Modifier to make a function callable only when the contract is paused.
    modifier whenPaused() {
        require(paused(), "Contract not paused");
        _;
    }

    /// @notice Initializes the contract in paused state and with no admin.
    /// The contract instance can be used only as a call delegation target for a proxy.
    constructor() {
        _pausedSlot().value = true;
    }

    /// @notice Returns true if the contract is paused, and false otherwise.
    function paused() public view returns (bool isPaused) {
        return _pausedSlot().value;
    }

    /// @notice Triggers stopped state.
    function pause() public onlyAdmin whenNotPaused {
        _pausedSlot().value = true;
        emit Paused(msg.sender);
    }

    /// @notice Returns to normal state.
    function unpause() public onlyAdmin whenPaused {
        _pausedSlot().value = false;
        emit Unpaused(msg.sender);
    }

    function _pausedSlot() private view returns (StorageSlot.BooleanSlot storage slot) {
        return StorageSlot.getBooleanSlot(pausedSlot);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";

/// @notice The reserve interface as seen by the users.
interface IReserve {
    /// @notice Deposits funds into the reserve.
    /// The reserve will `transferFrom` `amt` tokens from the `from` address.
    /// @param token The used token.
    /// @param from The address from which funds are deposited.
    /// @param amt The deposited amount.
    function deposit(IERC20 token, address from, uint256 amt) external;

    /// @notice Withdraws funds from the reserve.
    /// The reserve will transfer `amt` tokens to the `to` address.
    /// Only funds previously deposited can be withdrawn.
    /// @param token The used token.
    /// @param to The address to which funds are withdrawn.
    /// @param amt The withdrawn amount.
    function withdraw(IERC20 token, address to, uint256 amt) external;
}

/// @notice The reserve plugin interface required by the reserve.
interface IReservePlugin {
    /// @notice Called by the reserve when it starts using the plugin,
    /// immediately after transferring to the plugin all the deposited funds.
    /// This initial transfer won't trigger the regular call to `afterDeposition`.
    /// @param token The used token.
    /// @param amt The amount which has been transferred for deposition.
    function afterStart(IERC20 token, uint256 amt) external;

    /// @notice Called by the reserve immediately after
    /// transferring funds to the plugin for deposition.
    /// @param token The used token.
    /// @param amt The amount which has been transferred for deposition.
    function afterDeposition(IERC20 token, uint256 amt) external;

    /// @notice Called by the reserve right before transferring funds for withdrawal.
    /// The reserve will `transferFrom` the tokens from the plugin address.
    /// The reserve can always withdraw everything that has been ever deposited, but never more.
    /// @param token The used token.
    /// @param amt The amount which will be transferred.
    function beforeWithdrawal(IERC20 token, uint256 amt) external;

    /// @notice Called by the reserve when it stops using the plugin,
    /// right before transferring from the plugin all the deposited funds.
    /// The reserve will `transferFrom` the tokens from the plugin address.
    /// This final transfer won't trigger the regular call to `beforeWithdrawal`.
    /// @param token The used token.
    /// @param amt The amount which will be transferred.
    function beforeEnd(IERC20 token, uint256 amt) external;
}

/// @notice The ERC-20 tokens reserve contract.
/// The registered users can deposit and withdraw funds.
/// The reserve by default doesn't do anything with the tokens,
/// but for each ERC-20 address a plugin can be registered for tokens storage.
contract Reserve is IReserve, Ownable {
    using SafeERC20 for IERC20;
    /// @notice The dummy plugin address meaning that no plugin is being used.

    IReservePlugin public constant NO_PLUGIN = IReservePlugin(address(0));

    /// @notice A set of addresses considered users.
    /// The value is `true` if an address is a user, `false` otherwise.
    mapping(address => bool) public isUser;
    /// @notice How many tokens are deposited for each token address.
    mapping(IERC20 => uint256) public deposited;
    /// @notice The reserved plugins for each token address.
    mapping(IERC20 => IReservePlugin) public plugins;

    /// @notice Emitted when a plugin is set.
    /// @param owner The address which called the function.
    /// @param token The token for which plugin has been set.
    /// @param oldPlugin The old plugin address. `NO_PLUGIN` if no plugin was being used.
    /// @param newPlugin The new plugin address. `NO_PLUGIN` if no plugin will be used.
    /// @param amt The amount which has been withdrawn
    /// from the old plugin and deposited into the new one.
    event PluginSet(
        address owner,
        IERC20 indexed token,
        IReservePlugin indexed oldPlugin,
        IReservePlugin indexed newPlugin,
        uint256 amt
    );

    /// @notice Emitted when funds are deposited.
    /// @param user The address which called the function.
    /// @param token The used token.
    /// @param from The address from which tokens have been transferred.
    /// @param amt The amount which has been deposited.
    event Deposited(address user, IERC20 indexed token, address indexed from, uint256 amt);

    /// @notice Emitted when funds are withdrawn.
    /// @param user The address which called the function.
    /// @param token The used token.
    /// @param to The address to which tokens have been transferred.
    /// @param amt The amount which has been withdrawn.
    event Withdrawn(address user, IERC20 indexed token, address indexed to, uint256 amt);

    /// @notice Emitted when funds are force withdrawn.
    /// @param owner The address which called the function.
    /// @param token The used token.
    /// @param plugin The address of the plugin from which funds have been withdrawn or
    /// `NO_PLUGIN` if from the reserve itself.
    /// @param to The address to which tokens have been transferred.
    /// @param amt The amount which has been withdrawn.
    event ForceWithdrawn(
        address owner,
        IERC20 indexed token,
        IReservePlugin indexed plugin,
        address indexed to,
        uint256 amt
    );

    /// @notice Emitted when an address is registered as a user.
    /// @param owner The address which called the function.
    /// @param user The registered user address.
    event UserAdded(address owner, address indexed user);

    /// @notice Emitted when an address is unregistered as a user.
    /// @param owner The address which called the function.
    /// @param user The unregistered user address.
    event UserRemoved(address owner, address indexed user);

    /// @param owner_ The initial owner address.
    constructor(address owner_) {
        transferOwnership(owner_);
    }

    modifier onlyUser() {
        require(isUser[msg.sender], "Reserve: caller is not the user");
        _;
    }

    /// @notice Sets a plugin for a given token.
    /// All future deposits and withdrawals of that token will be made using that plugin.
    /// All currently deposited tokens of that type will be withdrawn from the plugin previously
    /// set for that token and deposited into the new one.
    /// If no plugin has been set, funds are deposited from the reserve itself.
    /// If no plugin is being set, funds are deposited into the reserve itself.
    /// Callable only by the current owner.
    /// @param token The used token.
    /// @param newPlugin The new plugin address. `NO_PLUGIN` if no plugin should be used.
    function setPlugin(IERC20 token, IReservePlugin newPlugin) public onlyOwner {
        IReservePlugin oldPlugin = plugins[token];
        plugins[token] = newPlugin;
        uint256 amt = deposited[token];
        if (oldPlugin != NO_PLUGIN) {
            oldPlugin.beforeEnd(token, amt);
        }
        _transfer(token, _pluginAddr(oldPlugin), _pluginAddr(newPlugin), amt);
        if (newPlugin != NO_PLUGIN) {
            newPlugin.afterStart(token, amt);
        }
        emit PluginSet(msg.sender, token, oldPlugin, newPlugin, amt);
    }

    /// @notice Deposits funds into the reserve.
    /// The reserve will `transferFrom` `amt` tokens from the `from` address.
    /// Callable only by a current user.
    /// @param token The used token.
    /// @param from The address from which funds are deposited.
    /// @param amt The deposited amount.
    function deposit(IERC20 token, address from, uint256 amt) public override onlyUser {
        IReservePlugin plugin = plugins[token];
        require(from != address(plugin) && from != address(this), "Reserve: deposition from self");
        deposited[token] += amt;
        _transfer(token, from, _pluginAddr(plugin), amt);
        if (plugin != NO_PLUGIN) {
            plugin.afterDeposition(token, amt);
        }
        emit Deposited(msg.sender, token, from, amt);
    }

    /// @notice Withdraws funds from the reserve.
    /// The reserve will transfer `amt` tokens to the `to` address.
    /// Only funds previously deposited can be withdrawn.
    /// Callable only by a current user.
    /// @param token The used token.
    /// @param to The address to which funds are withdrawn.
    /// @param amt The withdrawn amount.
    function withdraw(IERC20 token, address to, uint256 amt) public override onlyUser {
        uint256 balance = deposited[token];
        require(balance >= amt, "Reserve: withdrawal over balance");
        deposited[token] = balance - amt;
        IReservePlugin plugin = plugins[token];
        if (plugin != NO_PLUGIN) {
            plugin.beforeWithdrawal(token, amt);
        }
        _transfer(token, _pluginAddr(plugin), to, amt);
        emit Withdrawn(msg.sender, token, to, amt);
    }

    /// @notice Withdraws funds from the reserve or a plugin.
    /// The reserve will transfer `amt` tokens to the `to` address.
    /// The function doesn't update the deposited amount counter.
    /// If used recklessly, it may cause a mismatch between the counter and the actual balance
    /// making valid future calls to `withdraw` or `setPlugin` fail due to lack of funds.
    /// Callable only by the current owner.
    /// @param token The used token.
    /// @param plugin The plugin to withdraw from.
    /// It doesn't need to be registered as a plugin for `token`.
    /// Pass `NO_PLUGIN` to withdraw directly from the reserve balance.
    /// @param to The address to which funds are withdrawn.
    /// @param amt The withdrawn amount.
    function forceWithdraw(IERC20 token, IReservePlugin plugin, address to, uint256 amt)
        public
        onlyOwner
    {
        if (plugin != NO_PLUGIN) {
            plugin.beforeWithdrawal(token, amt);
        }
        _transfer(token, _pluginAddr(plugin), to, amt);
        emit ForceWithdrawn(msg.sender, token, plugin, to, amt);
    }

    /// @notice Sets the deposited amount counter for a token without transferring any funds.
    /// If used recklessly, it may cause a mismatch between the counter and the actual balance
    /// making valid future calls to `withdraw` or `setPlugin` fail due to lack of funds.
    /// It may also make the counter lower than what users expect it to be again making
    /// valid future calls to `withdraw` fail.
    /// Callable only by the current owner.
    /// @param token The used token.
    /// @param amt The new deposited amount counter value.
    function setDeposited(IERC20 token, uint256 amt) public onlyOwner {
        deposited[token] = amt;
    }

    /// @notice Adds a new user.
    /// @param user The new user address.
    function addUser(address user) public onlyOwner {
        isUser[user] = true;
        emit UserAdded(msg.sender, user);
    }

    /// @notice Removes an existing user.
    /// @param user The removed user address.
    function removeUser(address user) public onlyOwner {
        isUser[user] = false;
        emit UserRemoved(msg.sender, user);
    }

    function _pluginAddr(IReservePlugin plugin) internal view returns (address) {
        return plugin == NO_PLUGIN ? address(this) : address(plugin);
    }

    function _transfer(IERC20 token, address from, address to, uint256 amt) internal {
        if (from == address(this)) {
            token.safeTransfer(to, amt);
        } else {
            token.safeTransferFrom(from, to, amt);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

/// @notice A splits receiver
struct SplitsReceiver {
    /// @notice The user ID.
    uint256 userId;
    /// @notice The splits weight. Must never be zero.
    /// The user will be getting `weight / _TOTAL_SPLITS_WEIGHT`
    /// share of the funds collected by the splitting user.
    uint32 weight;
}

/// @notice Splits can keep track of at most `type(uint128).max`
/// which is `2 ^ 128 - 1` units of each asset.
/// It's up to the caller to guarantee that this limit is never exceeded,
/// failing to do so may result in a total protocol collapse.
abstract contract Splits {
    /// @notice Maximum number of splits receivers of a single user. Limits the cost of splitting.
    uint256 internal constant _MAX_SPLITS_RECEIVERS = 200;
    /// @notice The total splits weight of a user
    uint32 internal constant _TOTAL_SPLITS_WEIGHT = 1_000_000;
    /// @notice The total amount the contract can keep track of each asset.
    uint256 internal constant _MAX_TOTAL_SPLITS_BALANCE = type(uint128).max;
    /// @notice The storage slot holding a single `SplitsStorage` structure.
    bytes32 private immutable _splitsStorageSlot;

    /// @notice Emitted when a user collects funds
    /// @param userId The user ID
    /// @param assetId The used asset ID
    /// @param collected The collected amount
    event Collected(uint256 indexed userId, uint256 indexed assetId, uint128 collected);

    /// @notice Emitted when funds are split from a user to a receiver.
    /// This is caused by the user collecting received funds.
    /// @param userId The user ID
    /// @param receiver The splits receiver user ID
    /// @param assetId The used asset ID
    /// @param amt The amount split to the receiver
    event Split(
        uint256 indexed userId, uint256 indexed receiver, uint256 indexed assetId, uint128 amt
    );

    /// @notice Emitted when funds are made collectable after splitting.
    /// @param userId The user ID
    /// @param assetId The used asset ID
    /// @param amt The amount made collectable for the user on top of what was collectable before.
    event Collectable(uint256 indexed userId, uint256 indexed assetId, uint128 amt);

    /// @notice Emitted when funds are given from the user to the receiver.
    /// @param userId The user ID
    /// @param receiver The receiver user ID
    /// @param assetId The used asset ID
    /// @param amt The given amount
    event Given(
        uint256 indexed userId, uint256 indexed receiver, uint256 indexed assetId, uint128 amt
    );

    /// @notice Emitted when the user's splits are updated.
    /// @param userId The user ID
    /// @param receiversHash The splits receivers list hash
    event SplitsSet(uint256 indexed userId, bytes32 indexed receiversHash);

    /// @notice Emitted when a user is seen in a splits receivers list.
    /// @param receiversHash The splits receivers list hash
    /// @param userId The user ID.
    /// @param weight The splits weight. Must never be zero.
    /// The user will be getting `weight / _TOTAL_SPLITS_WEIGHT`
    /// share of the funds collected by the splitting user.
    event SplitsReceiverSeen(bytes32 indexed receiversHash, uint256 indexed userId, uint32 weight);

    struct SplitsStorage {
        /// @notice User splits states.
        /// The key is the user ID.
        mapping(uint256 => SplitsState) splitsStates;
    }

    struct SplitsState {
        /// @notice The user's splits configuration hash, see `hashSplits`.
        bytes32 splitsHash;
        /// @notice The user's splits balance. The key is the asset ID.
        mapping(uint256 => SplitsBalance) balances;
    }

    struct SplitsBalance {
        /// @notice The not yet split balance, must be split before collecting by the user.
        uint128 splittable;
        /// @notice The already split balance, ready to be collected by the user.
        uint128 collectable;
    }

    /// @param splitsStorageSlot The storage slot to holding a single `SplitsStorage` structure.
    constructor(bytes32 splitsStorageSlot) {
        _splitsStorageSlot = splitsStorageSlot;
    }

    function _addSplittable(uint256 userId, uint256 assetId, uint128 amt) internal {
        _splitsStorage().splitsStates[userId].balances[assetId].splittable += amt;
    }

    /// @notice Returns user's received but not split yet funds.
    /// @param userId The user ID
    /// @param assetId The used asset ID.
    /// @return amt The amount received but not split yet.
    function _splittable(uint256 userId, uint256 assetId) internal view returns (uint128 amt) {
        return _splitsStorage().splitsStates[userId].balances[assetId].splittable;
    }

    /// @notice Calculate the result of splitting an amount using the current splits configuration.
    /// @param userId The user ID
    /// @param currReceivers The list of the user's current splits receivers.
    /// @param amount The amount being split.
    /// @return collectableAmt The amount made collectable for the user
    /// on top of what was collectable before.
    /// @return splitAmt The amount split to the user's splits receivers
    function _splitResult(uint256 userId, SplitsReceiver[] memory currReceivers, uint128 amount)
        internal
        view
        returns (uint128 collectableAmt, uint128 splitAmt)
    {
        _assertCurrSplits(userId, currReceivers);
        if (amount == 0) {
            return (0, 0);
        }
        uint32 splitsWeight = 0;
        for (uint256 i = 0; i < currReceivers.length; i++) {
            splitsWeight += currReceivers[i].weight;
        }
        splitAmt = uint128((uint160(amount) * splitsWeight) / _TOTAL_SPLITS_WEIGHT);
        collectableAmt = amount - splitAmt;
    }

    /// @notice Splits user's received but not split yet funds among receivers.
    /// @param userId The user ID
    /// @param assetId The used asset ID
    /// @param currReceivers The list of the user's current splits receivers.
    /// @return collectableAmt The amount made collectable for the user
    /// on top of what was collectable before.
    /// @return splitAmt The amount split to the user's splits receivers
    function _split(uint256 userId, uint256 assetId, SplitsReceiver[] memory currReceivers)
        internal
        returns (uint128 collectableAmt, uint128 splitAmt)
    {
        _assertCurrSplits(userId, currReceivers);
        mapping(uint256 => SplitsState) storage splitsStates = _splitsStorage().splitsStates;
        SplitsBalance storage balance = splitsStates[userId].balances[assetId];

        collectableAmt = balance.splittable;
        if (collectableAmt == 0) {
            return (0, 0);
        }

        balance.splittable = 0;
        uint32 splitsWeight = 0;
        for (uint256 i = 0; i < currReceivers.length; i++) {
            splitsWeight += currReceivers[i].weight;
            uint128 currSplitAmt =
                uint128((uint160(collectableAmt) * splitsWeight) / _TOTAL_SPLITS_WEIGHT - splitAmt);
            splitAmt += currSplitAmt;
            uint256 receiver = currReceivers[i].userId;
            _addSplittable(receiver, assetId, currSplitAmt);
            emit Split(userId, receiver, assetId, currSplitAmt);
        }
        collectableAmt -= splitAmt;
        balance.collectable += collectableAmt;
        emit Collectable(userId, assetId, collectableAmt);
    }

    /// @notice Returns user's received funds already split and ready to be collected.
    /// @param userId The user ID
    /// @param assetId The used asset ID.
    /// @return amt The collectable amount.
    function _collectable(uint256 userId, uint256 assetId) internal view returns (uint128 amt) {
        return _splitsStorage().splitsStates[userId].balances[assetId].collectable;
    }

    /// @notice Collects user's received already split funds
    /// and transfers them out of the drips hub contract to msg.sender.
    /// @param userId The user ID
    /// @param assetId The used asset ID
    /// @return amt The collected amount
    function _collect(uint256 userId, uint256 assetId) internal returns (uint128 amt) {
        SplitsBalance storage balance = _splitsStorage().splitsStates[userId].balances[assetId];
        amt = balance.collectable;
        balance.collectable = 0;
        emit Collected(userId, assetId, amt);
    }

    /// @notice Gives funds from the user to the receiver.
    /// The receiver can split and collect them immediately.
    /// Transfers the funds to be given from the user's wallet to the drips hub contract.
    /// @param userId The user ID
    /// @param receiver The receiver
    /// @param assetId The used asset ID
    /// @param amt The given amount
    function _give(uint256 userId, uint256 receiver, uint256 assetId, uint128 amt) internal {
        _addSplittable(receiver, assetId, amt);
        emit Given(userId, receiver, assetId, amt);
    }

    /// @notice Sets user splits configuration.
    /// @param userId The user ID
    /// @param receivers The list of the user's splits receivers to be set.
    /// Must be sorted by the splits receivers' addresses, deduplicated and without 0 weights.
    /// Each splits receiver will be getting `weight / _TOTAL_SPLITS_WEIGHT`
    /// share of the funds collected by the user.
    function _setSplits(uint256 userId, SplitsReceiver[] memory receivers) internal {
        SplitsState storage state = _splitsStorage().splitsStates[userId];
        bytes32 newSplitsHash = _hashSplits(receivers);
        emit SplitsSet(userId, newSplitsHash);
        if (newSplitsHash != state.splitsHash) {
            _assertSplitsValid(receivers, newSplitsHash);
            state.splitsHash = newSplitsHash;
        }
    }

    /// @notice Validates a list of splits receivers and emits events for them
    /// @param receivers The list of splits receivers
    /// @param receiversHash The hash of the list of splits receivers.
    /// Must be sorted by the splits receivers' addresses, deduplicated and without 0 weights.
    function _assertSplitsValid(SplitsReceiver[] memory receivers, bytes32 receiversHash) private {
        require(receivers.length <= _MAX_SPLITS_RECEIVERS, "Too many splits receivers");
        uint64 totalWeight = 0;
        uint256 prevUserId;
        for (uint256 i = 0; i < receivers.length; i++) {
            SplitsReceiver memory receiver = receivers[i];
            uint32 weight = receiver.weight;
            require(weight != 0, "Splits receiver weight is zero");
            totalWeight += weight;
            uint256 userId = receiver.userId;
            if (i > 0) {
                require(prevUserId != userId, "Duplicate splits receivers");
                require(prevUserId < userId, "Splits receivers not sorted by user ID");
            }
            prevUserId = userId;
            emit SplitsReceiverSeen(receiversHash, userId, weight);
        }
        require(totalWeight <= _TOTAL_SPLITS_WEIGHT, "Splits weights sum too high");
    }

    /// @notice Asserts that the list of splits receivers is the user's currently used one.
    /// @param userId The user ID
    /// @param currReceivers The list of the user's current splits receivers.
    function _assertCurrSplits(uint256 userId, SplitsReceiver[] memory currReceivers)
        internal
        view
    {
        require(
            _hashSplits(currReceivers) == _splitsHash(userId), "Invalid current splits receivers"
        );
    }

    /// @notice Current user's splits hash, see `hashSplits`.
    /// @param userId The user ID
    /// @return currSplitsHash The current user's splits hash
    function _splitsHash(uint256 userId) internal view returns (bytes32 currSplitsHash) {
        return _splitsStorage().splitsStates[userId].splitsHash;
    }

    /// @notice Calculates the hash of the list of splits receivers.
    /// @param receivers The list of the splits receivers.
    /// Must be sorted by the splits receivers' addresses, deduplicated and without 0 weights.
    /// @return receiversHash The hash of the list of splits receivers.
    function _hashSplits(SplitsReceiver[] memory receivers)
        internal
        pure
        returns (bytes32 receiversHash)
    {
        if (receivers.length == 0) {
            return bytes32(0);
        }
        return keccak256(abi.encode(receivers));
    }

    /// @notice Returns the Splits storage.
    /// @return splitsStorage The storage.
    function _splitsStorage() private view returns (SplitsStorage storage splitsStorage) {
        bytes32 slot = _splitsStorageSlot;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            splitsStorage.slot := slot
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import {UUPSUpgradeable} from "openzeppelin-contracts/proxy/utils/UUPSUpgradeable.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";

/// @notice A mix-in for contract UUPS-upgradeability and admin management.
/// It can't be used directly, only via a proxy. It uses the upgrade-safe ERC-1967 storage scheme.
///
/// Upgradeable uses the ERC-1967 admin slot to store the admin address.
/// All instances of the contracts are owned by address `0x00`.
/// While this contract is capable of updating the admin,
/// the proxy is expected to set up the initial value of the ERC-1967 admin.
abstract contract Upgradeable is UUPSUpgradeable {
    /// @notice Throws if called by any caller other than the admin.
    modifier onlyAdmin() {
        require(admin() == msg.sender, "Caller is not the admin");
        _;
    }

    /// @notice Calculates the ERC-1967 slot pointer.
    /// @param name The name of the slot, should be globally unique
    /// @return slot The slot pointer
    function erc1967Slot(string memory name) internal pure returns (bytes32 slot) {
        return bytes32(uint256(keccak256(bytes(name))) - 1);
    }

    /// @notice Authorizes the contract upgrade. See `UUPSUpgradeable` docs for more details.
    function _authorizeUpgrade(address newImplementation) internal view override onlyAdmin {
        newImplementation;
    }

    /// @notice Returns the address of the current admin.
    function admin() public view returns (address) {
        return _getAdmin();
    }

    /// @notice Changes the admin of the contract.
    /// Can only be called by the current admin.
    function changeAdmin(address newAdmin) public onlyAdmin {
        _changeAdmin(newAdmin);
    }
}

/// @notice A generic proxy for Upgradeable contracts.
contract UpgradeableProxy is ERC1967Proxy {
    constructor(Upgradeable logic, address admin) ERC1967Proxy(address(logic), new bytes(0)) {
        _changeAdmin(admin);
    }
}