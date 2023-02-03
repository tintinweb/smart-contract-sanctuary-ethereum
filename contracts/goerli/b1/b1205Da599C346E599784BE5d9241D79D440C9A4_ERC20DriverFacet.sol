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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { LibERC20Driver } from "../libraries/LibERC20Driver.sol";
import { LibValidatorController } from "../libraries/LibValidatorController.sol";
import { LibChainInfo } from "../libraries/LibChainInfo.sol";
import { IERC20Driver } from "../interfaces/IERC20Driver.sol";
import { IIssuedToken } from "../interfaces/IIssuedToken.sol";
import { UniversalAddressUtils } from "../../utils/UniversalAddressUtils.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ERC20DriverFacet is IERC20Driver {
    using SafeERC20 for IERC20;

    function getIssuedTokenAddressERC20(
        string calldata _originalChainName,
        string calldata _originalTokenAddress
    ) external view returns (address) {
        return LibERC20Driver.getIssuedTokenAddress(_originalChainName, _originalTokenAddress);
    }

    function getTokenIdERC20(
        string calldata _originalChainName,
        string calldata _originalTokenAddress
    ) external pure returns (bytes32) {
        return LibERC20Driver.getTokenId(_originalChainName, _originalTokenAddress);
    }

    function isIssuedTokenCreatedERC20(
        string calldata _originalChainName,
        string calldata _originalTokenAddress
    ) external view returns (bool) {
        return LibERC20Driver.isIssuedTokenCreated(_originalChainName, _originalTokenAddress);
    }

    function initialBlockNumberERC20() external view returns (uint256) {
        return LibERC20Driver.initialBlockNumber();
    }

    function isExternalNonceAlreadyRegisteredERC20(
        string calldata _initialChainName,
        uint256 _externalNonce
    ) external view returns (bool) {
        return LibERC20Driver.isExternalNonceAlreadyRegistered(_initialChainName, _externalNonce);
    }

    function tranferToOtherChainERC20(
        address _transferedToken,
        uint256 _amount,
        string calldata _targetChainName,
        UniversalAddressUtils.UniversalAddress calldata _recipient
    ) external {
        // Connect to storage
        LibERC20Driver.ERC20DriverStorage storage ds = LibERC20Driver.diamondStorage();
        LibChainInfo.ChainInfoStorage storage chainInfoStorage = LibChainInfo.diamondStorage();

        require(_amount > 0, "LibERC20Driver.tranferToOtherChain: amount <= 0");

        require(
            ds.registeredChains[_targetChainName],
            "LibERC20Driver.tranferToOtherChain: chain not registered"
        );

        require(
            UniversalAddressUtils.isValidUniversalAddress(_recipient),
            "LibERC20Driver.tranferToOtherChain: recipient address not valid"
        );

        bytes32 tokenId = ds.tokenIdByIssuedToken[_transferedToken];

        string memory initialChainName = chainInfoStorage.chainName;
        string memory originalChainName;
        string memory originalTokenAddress;

        if (tokenId != 0) {
            // There ISSUED token
            IIssuedToken issuedToken = IIssuedToken(_transferedToken);
            (originalChainName, originalTokenAddress) = issuedToken.getOriginalTokenInfo();

            bytes32 originalChainNameHash = keccak256(abi.encodePacked(originalChainName));
            bytes32 targetChainNameHash = keccak256(abi.encodePacked(_targetChainName));

            if (originalChainNameHash != targetChainNameHash && chainInfoStorage.isProxyChain) {
                // In proxy chain
                // LOCK ISSUED TOKENS
                issuedToken.permissionedTransferFrom(msg.sender, address(this), _amount);
            } else {
                // BURN ISSUED TOKENS
                issuedToken.burn(msg.sender, _amount);
            }
        } else {
            // There ORIGINAL token
            originalChainName = initialChainName;
            originalTokenAddress = Strings.toHexString(_transferedToken);

            ds.originalTokenAddressByString[originalTokenAddress] = _transferedToken;

            // LOCK ORIGIANL TOKENS
            // Need approve first
            IERC20(_transferedToken).safeTransferFrom(msg.sender, address(this), _amount);
        }

        // Send event to validator [required]
        uint256 nonce = ds.nonce++;
        emit ERC20DriverTransferToOtherChain(
            LibERC20Driver.getTranferId(nonce, initialChainName),
            nonce,
            initialChainName,
            originalChainName,
            originalTokenAddress,
            _targetChainName,
            _amount,
            UniversalAddressUtils.toString(msg.sender),
            UniversalAddressUtils.toString(_recipient)
        );
    }

    function tranferFromOtherChainERC20(
        uint256 _externalNonce,
        string calldata _originalChainName,
        string calldata _originalTokenAddress,
        string calldata _initialChainName,
        string calldata _targetChainName,
        uint256 _amount,
        string calldata _sender,
        UniversalAddressUtils.UniversalAddress calldata _recipient,
        LibERC20Driver.TokenCreateInfo calldata _tokenCreateInfo
    ) external {
        // Only Validator
        LibValidatorController.enforceIsValidator();

        // Connect to storage
        LibERC20Driver.ERC20DriverStorage storage ds = LibERC20Driver.diamondStorage();

        require(
            !ds.registeredExternalNoncesByChainName[_initialChainName][_externalNonce],
            "LibERC20Driver: nonce already registered"
        );
        ds.registeredExternalNoncesByChainName[_initialChainName][_externalNonce] = true;

        require(
            UniversalAddressUtils.isValidUniversalAddress(_recipient),
            "LibERC20Driver.tranferFromOtherChain: recipient address not valid"
        );

        LibChainInfo.ChainInfoStorage storage chainInfoStorage = LibChainInfo.diamondStorage();
        bytes32 currentChainNameHash = keccak256(abi.encodePacked(chainInfoStorage.chainName));
        bytes32 originalChainNameHash = keccak256(abi.encodePacked(_originalChainName));
        bytes32 targetChainNameHash = keccak256(abi.encodePacked(_targetChainName));
        bytes32 initialChainNameHash = keccak256(abi.encodePacked(_initialChainName));

        require(
            initialChainNameHash != currentChainNameHash,
            "LibERC20Driver.tranferFromOtherChain: Initial chain can not be equal current chain"
        );

        require(
            ds.registeredChains[_initialChainName],
            "LibERC20Driver.tranferFromOtherChain: Initial chain not registered"
        );

        if (currentChainNameHash == targetChainNameHash) {
            // This target chain

            require(
                UniversalAddressUtils.hasEvmAddress(_recipient),
                "LibERC20Driver: recipient not has evm address"
            );

            if (currentChainNameHash == originalChainNameHash) {
                // This Original chain
                // Withdraw original tokens
                IERC20(ds.originalTokenAddressByString[_originalTokenAddress]).safeTransfer(
                    _recipient.evmAddress,
                    _amount
                );
            } else {
                // This Secondary chain
                // Mint issued tokens

                address issuedTokenAddress = LibERC20Driver
                    .getIssuedTokenAddressOrPublishTokenIfNotExists(
                        _originalChainName,
                        _originalTokenAddress,
                        _tokenCreateInfo
                    );

                IIssuedToken(issuedTokenAddress).mint(_recipient.evmAddress, _amount);
            }

            emit ERC20DriverTransferFromOtherChain(
                LibERC20Driver.getTranferId(_externalNonce, _initialChainName),
                _externalNonce,
                _originalChainName,
                _originalTokenAddress,
                _initialChainName,
                _targetChainName,
                _amount,
                _sender,
                UniversalAddressUtils.toString(_recipient)
            );
        } else {
            // This Proxy chain
            // Mint and lock issued tokens
            // And send event to target bridge
            require(
                chainInfoStorage.isProxyChain,
                "LibERC20Driver: Only proxy bridge can be currentChainName != targetChainName"
            );

            address issuedTokenAddress = LibERC20Driver
                .getIssuedTokenAddressOrPublishTokenIfNotExists(
                    _originalChainName,
                    _originalTokenAddress,
                    _tokenCreateInfo
                );

            if (targetChainNameHash == originalChainNameHash) {
                // BURN PROXY ISSUED TOKENS
                IIssuedToken(issuedTokenAddress).burn(address(this), _amount);
            } else if (initialChainNameHash == originalChainNameHash) {
                // LOCK PROXY ISSUED TOKENS
                IIssuedToken(issuedTokenAddress).mint(address(this), _amount);
            }

            // Send event to validator [required]
            emit ERC20DriverTransferToOtherChain(
                LibERC20Driver.getTranferId(_externalNonce, _initialChainName),
                _externalNonce,
                _initialChainName,
                _originalChainName,
                _originalTokenAddress,
                _targetChainName,
                _amount,
                _sender,
                UniversalAddressUtils.toString(_recipient)
            );
        }
    }

    function setChainRegistrationERC20(string calldata _chainName, bool _value) external {
        // Only Validator
        LibValidatorController.enforceIsValidator();
        LibERC20Driver.setChainRegistration(_chainName, _value);
    }

    function nonceERC20() external view returns (uint256) {
        return LibERC20Driver.nonce();
    }

    function balancesERC20(
        string calldata _originalChainName,
        string calldata _originalTokenAddress,
        address _account
    ) external view returns (uint256) {
        return LibERC20Driver.balances(_originalChainName, _originalTokenAddress, _account);
    }

    function setIssuedTokenImplementation(address _issuedTokenImplementation) external {
        // Only Validator
        LibValidatorController.enforceIsValidator();

        LibERC20Driver.setIssuedTokenImplementation(_issuedTokenImplementation);
    }

    function getTranferIdERC20(uint256 _nonce, string calldata _initialChainName)
        external
        pure
        returns (bytes32)
    {
        return LibERC20Driver.getTranferId(_nonce, _initialChainName);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { UniversalAddressUtils } from "../../utils/UniversalAddressUtils.sol";
import { LibERC20Driver } from "../libraries/LibERC20Driver.sol";

interface IERC20Driver {
    event ERC20DriverPublishedToken(
        string originalChainName,
        string originalTokenAddress,
        bytes32 indexed tokenId,
        address createdToken
    );

    event ERC20DriverTransferToOtherChain(
        bytes32 indexed transferId,
        uint256 nonce,
        string initialChainName,
        string originalChainName,
        string originalTokenAddress,
        string targetChainName,
        uint256 tokenAmount,
        string sender,
        string recipient
    );

    event ERC20DriverTransferFromOtherChain(
        bytes32 indexed transferId,
        uint256 externalNonce,
        string originalChainName,
        string originalTokenAddress,
        string initialChainName,
        string targetChainName,
        uint256 amount,
        string sender,
        string recipient
    );

    function getIssuedTokenAddressERC20(
        string calldata _originalChainName,
        string calldata _originalTokenAddress
    ) external view returns (address);

    function getTokenIdERC20(
        string calldata _originalChainName,
        string calldata _originalTokenAddress
    ) external pure returns (bytes32);

    function isIssuedTokenCreatedERC20(
        string calldata _originalChainName,
        string calldata _originalTokenAddress
    ) external view returns (bool);

    function tranferToOtherChainERC20(
        address _transferedToken,
        uint256 _amount,
        string calldata _targetChainName,
        UniversalAddressUtils.UniversalAddress calldata _recipient
    ) external;

    function tranferFromOtherChainERC20(
        uint256 _externalNonce,
        string calldata _originalChainName,
        string calldata _originalTokenAddress,
        string calldata _initialChainName,
        string calldata _targetChainName,
        uint256 _amount,
        string calldata _sender,
        UniversalAddressUtils.UniversalAddress calldata _recipient,
        LibERC20Driver.TokenCreateInfo calldata _tokenCreateInfo
    ) external;

    function initialBlockNumberERC20() external view returns (uint256);

    function isExternalNonceAlreadyRegisteredERC20(
        string calldata _initialChainName,
        uint256 _externalNonce
    ) external view returns (bool);

    function setChainRegistrationERC20(string calldata _chainName, bool _value) external;

    function nonceERC20() external view returns (uint256);

    function balancesERC20(
        string calldata _originalChainName,
        string calldata _originalTokenAddress,
        address _account
    ) external view returns (uint256);

    function setIssuedTokenImplementation(address _issuedTokenImplementation) external;

    function getTranferIdERC20(uint256 _nonce, string calldata _initialChainName) external pure returns(bytes32);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IIssuedToken {
    function initialize(
        string memory _originalChainName,
        string memory _originalTokenAddress,
        string memory _originalTokenName,
        string memory _originalTokenSymbol,
        uint8 _originalTokenDecimals
    ) external;

    function getOriginalTokenInfo() external view returns (string memory, string memory);

    function mint(address _recipient, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;

    function permissionedTransferFrom(
        address from,
        address to,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

library LibChainInfo {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("LibChainInfo.storage");

    struct ChainInfoStorage {
        string chainName;
        bool isProxyChain;
    }

    function diamondStorage() internal pure returns (ChainInfoStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function chainName() internal view returns (string memory) {
        return diamondStorage().chainName;
    }

    function setChainName(string memory _chainName) internal {
        diamondStorage().chainName = _chainName;
    }

    function isProxyChain() internal view returns (bool) {
        return diamondStorage().isProxyChain;
    }

    function setIsProxyChain(bool _isProxyChain) internal {
        diamondStorage().isProxyChain = _isProxyChain;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IIssuedToken } from "../interfaces/IIssuedToken.sol";
import { LibChainInfo } from "./LibChainInfo.sol";

library LibERC20Driver {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("LibERC20Driver.storage");

    struct ERC20DriverStorage {
        uint256 initialBlockNumber;
        address issuedTokenImplementation;
        mapping(bytes32 => address) issuedTokenByTokenId;
        mapping(address => bytes32) tokenIdByIssuedToken;
        uint256 withdrawNonce;
        uint256 crossTheBridgeNonce;
        mapping(string => bool) registeredChains;
        mapping(string => address) originalTokenAddressByString;
        uint256 nonce;
        mapping(string => mapping(uint256 => bool)) registeredExternalNoncesByChainName;
    }

    function diamondStorage() internal pure returns (ERC20DriverStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event ERC20DriverPublishedToken(
        string originalChainName,
        string originalTokenAddress,
        bytes32 indexed tokenId,
        address createdToken
    );

    struct TokenCreateInfo {
        string tokenName;
        string tokenSymbol;
        uint8 tokenDecimals;
    }

    function balances(
        string calldata _originalChainName,
        string calldata _originalTokenAddress,
        address _account
    ) internal view returns (uint256) {
        ERC20DriverStorage storage ds = diamondStorage();
        LibChainInfo.ChainInfoStorage storage chainInfoStorage = LibChainInfo.diamondStorage();

        bytes32 currentChainNameHash = keccak256(abi.encodePacked(chainInfoStorage.chainName));
        bytes32 originalChainNameHash = keccak256(abi.encodePacked(_originalChainName));

        address tokenInCurrentChain = currentChainNameHash == originalChainNameHash
            ? ds.originalTokenAddressByString[_originalTokenAddress]
            : getIssuedTokenAddress(_originalChainName, _originalTokenAddress);

        if (tokenInCurrentChain != address(0)) {
            return IERC20(tokenInCurrentChain).balanceOf(_account);
        }
        return 0;
    }

    function initialBlockNumber() internal view returns (uint256) {
        return diamondStorage().initialBlockNumber;
    }

    function setChainRegistration(string calldata _chainName, bool _value) internal {
        diamondStorage().registeredChains[_chainName] = _value;
    }

    function setIssuedTokenImplementation(address _issuedTokenImplementation) internal {
        diamondStorage().issuedTokenImplementation = _issuedTokenImplementation;
    }

    function getTranferId(uint256 _nonce, string memory _initialChainName) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(_nonce, _initialChainName));
    }

    function publishNewToken(
        string calldata _originalChainName,
        string calldata _originalTokenAddress,
        TokenCreateInfo calldata _tokenCreateInfo
    ) internal returns (address) {
        // Connect to storage
        ERC20DriverStorage storage ds = diamondStorage();

        // Get token info
        bytes32 tokenId = getTokenId(_originalChainName, _originalTokenAddress);
        address issuedTokenAddress = ds.issuedTokenByTokenId[tokenId];

        // Check already published
        require(issuedTokenAddress == address(0), "Token already published");
        // Check create data
        require(!isEmptyTokenCreateInfo(_tokenCreateInfo), "Not has token create info!");

        // Deploy new token
        issuedTokenAddress = address(
            new ERC1967Proxy(
                ds.issuedTokenImplementation,
                abi.encodeWithSelector(
                    IIssuedToken.initialize.selector,
                    _originalChainName,
                    _originalTokenAddress,
                    _tokenCreateInfo.tokenName,
                    _tokenCreateInfo.tokenSymbol,
                    _tokenCreateInfo.tokenDecimals
                )
            )
        );

        // Save token info to storage
        ds.tokenIdByIssuedToken[issuedTokenAddress] = tokenId;
        ds.issuedTokenByTokenId[tokenId] = issuedTokenAddress;
        // Send event
        emit ERC20DriverPublishedToken(
            _originalChainName,
            _originalTokenAddress,
            tokenId,
            issuedTokenAddress
        );

        return issuedTokenAddress;
    }

    function getIssuedTokenAddress(
        string calldata _originalChainName,
        string calldata _originalTokenAddress
    ) internal view returns (address) {
        bytes32 tokenId = getTokenId(_originalChainName, _originalTokenAddress);
        return diamondStorage().issuedTokenByTokenId[tokenId];
    }

    function isExternalNonceAlreadyRegistered(
        string calldata _initialChainName,
        uint256 _externalNonce
    ) internal view returns (bool) {
        return
            diamondStorage().registeredExternalNoncesByChainName[_initialChainName][_externalNonce];
    }

    function isIssuedTokenCreated(
        string calldata _originalChainName,
        string calldata _originalTokenAddress
    ) internal view returns (bool) {
        return getIssuedTokenAddress(_originalChainName, _originalTokenAddress) != address(0);
    }

    function isEmptyTokenCreateInfo(TokenCreateInfo calldata _tokenCreateInfo)
        internal
        pure
        returns (bool)
    {
        bytes memory tokenInfoBytes = abi.encodePacked(
            _tokenCreateInfo.tokenName,
            _tokenCreateInfo.tokenSymbol,
            _tokenCreateInfo.tokenDecimals
        );
        return tokenInfoBytes.length <= 32 && bytes32(tokenInfoBytes) == "";
    }

    function getTokenId(string calldata _originalChainName, string calldata _originalTokenAddress)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_originalChainName, _originalTokenAddress));
    }

    function getIssuedTokenAddressOrPublishTokenIfNotExists(
        string calldata _originalChainName,
        string calldata _originalTokenAddress,
        TokenCreateInfo calldata _tokenCreateInfo
    ) internal returns (address) {
        bytes32 tokenId = getTokenId(_originalChainName, _originalTokenAddress);
        address issuedTokenAddress = diamondStorage().issuedTokenByTokenId[tokenId];

        // If token not exists, deploy new contract
        if (issuedTokenAddress == address(0)) {
            issuedTokenAddress = publishNewToken(
                _originalChainName,
                _originalTokenAddress,
                _tokenCreateInfo
            );
        }
        return issuedTokenAddress;
    }

    function nonce() internal view returns (uint256) {
        return diamondStorage().nonce;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

library LibValidatorController {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("validatorController.storage");

    struct ValidatorControllerStorage {
        address validator;
    }

    function diamondStorage() internal pure returns (ValidatorControllerStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event ValidatorTransferred(address indexed previousOwner, address indexed newOwner);

    function enforceIsValidator() internal view {
        require(
            msg.sender == diamondStorage().validator,
            "LibValidatorController: Must be validator"
        );
    }

    function setValidator(address _newValidator) internal {
        ValidatorControllerStorage storage ds = diamondStorage();
        address previousValidator = ds.validator;
        ds.validator = _newValidator;
        emit ValidatorTransferred(previousValidator, _newValidator);
    }

    function validator() internal view returns (address) {
        return diamondStorage().validator;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

library UniversalAddressUtils {
    struct UniversalAddress {
        address evmAddress;
        string noEvmAddress;
    }

    function isValidUniversalAddress(UniversalAddress calldata _universalAddress)
        internal
        pure
        returns (bool)
    {
        return
            (_universalAddress.evmAddress == address(0)) !=
            (bytes(_universalAddress.noEvmAddress).length == 0);
    }

    function toString(UniversalAddress calldata _universalAddress) internal pure returns(string memory) {
        if(hasEvmAddress(_universalAddress)) {
            return toString(_universalAddress.evmAddress);
        } else {
            return _universalAddress.noEvmAddress;
        }
    }

    function toString(address _account) internal pure returns(string memory) {
        return Strings.toHexString(_account);
    }
    
    function hasEvmAddress(UniversalAddress calldata _universalAddress) internal pure returns(bool ) {
        return _universalAddress.evmAddress != address(0);
    }
}