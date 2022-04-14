/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

// File @openzeppelin/contracts/utils/cryptography/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}


// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)



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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


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


// File @openzeppelin/contracts-upgradeable/token/ERC20/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)




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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)



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


// File @openzeppelin/contracts-upgradeable/security/[email protected]


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)



/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)



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


// File @openzeppelin/contracts-upgradeable/security/[email protected]


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)




/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}


// File @openzeppelin/contracts-upgradeable/interfaces/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)



/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
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


// File @openzeppelin/contracts-upgradeable/proxy/beacon/[email protected]


// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)



/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)



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
library StorageSlotUpgradeable {
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
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}


// File @openzeppelin/contracts-upgradeable/proxy/ERC1967/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;





/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
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
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
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
            _functionDelegateCall(newImplementation, data);
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
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
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
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
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
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
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
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)





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
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}


// File @openzeppelin/contracts/token/ERC20/[email protected]





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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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


// File contracts/access/IKOAccessControlsLookup.sol



pragma solidity 0.8.4;

interface IKOAccessControlsLookup {
    function hasAdminRole(address _address) external view returns (bool);

    function isVerifiedArtist(uint256 _index, address _account, bytes32[] calldata _merkleProof) external view returns (bool);

    function isVerifiedArtistProxy(address _artist, address _proxy) external view returns (bool);

    function hasLegacyMinterRole(address _address) external view returns (bool);

    function hasContractRole(address _address) external view returns (bool);

    function hasContractOrAdminRole(address _address) external view returns (bool);
}


// File @openzeppelin/contracts/utils/introspection/[email protected]





/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File @openzeppelin/contracts/token/ERC721/[email protected]





/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}


// File contracts/core/IERC2309.sol



pragma solidity 0.8.4;

/**
  @title ERC-2309: ERC-721 Batch Mint Extension
  @dev https://github.com/ethereum/EIPs/issues/2309
 */
interface IERC2309 {
    /**
      @notice This event is emitted when ownership of a batch of tokens changes by any mechanism.
      This includes minting, transferring, and burning.

      @dev The address executing the transaction MUST own all the tokens within the range of
      fromTokenId and toTokenId, or MUST be an approved operator to act on the owners behalf.
      The fromTokenId and toTokenId MUST be a sequential range of tokens IDs.
      When minting/creating tokens, the `fromAddress` argument MUST be set to `0x0` (i.e. zero address).
      When burning/destroying tokens, the `toAddress` argument MUST be set to `0x0` (i.e. zero address).

      @param fromTokenId The token ID that begins the batch of tokens being transferred
      @param toTokenId The token ID that ends the batch of tokens being transferred
      @param fromAddress The address transferring ownership of the specified range of tokens
      @param toAddress The address receiving ownership of the specified range of tokens.
    */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed fromAddress, address indexed toAddress);
}


// File contracts/core/IERC2981.sol



pragma solidity 0.8.4;

/// @notice This is purely an extension for the KO platform
/// @notice Royalties on KO are defined at an edition level for all tokens from the same edition
interface IERC2981EditionExtension {

    /// @notice Does the edition have any royalties defined
    function hasRoyalties(uint256 _editionId) external view returns (bool);

    /// @notice Get the royalty receiver - all royalties should be sent to this account if not zero address
    function getRoyaltiesReceiver(uint256 _editionId) external view returns (address);
}

/**
 * ERC2981 standards interface for royalties
 */
interface IERC2981 is IERC165, IERC2981EditionExtension {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// implementing this standard
    ///
    /// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
    /// bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    /// _registerInterface(_INTERFACE_ID_ERC2981);

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _value - the sale price of the NFT asset specified by _tokenId
    /// @return _receiver - address of who should be sent the royalty payment
    /// @return _royaltyAmount - the royalty payment amount for _value sale price
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _value
    ) external view returns (
        address _receiver,
        uint256 _royaltyAmount
    );

}


// File contracts/core/IHasSecondarySaleFees.sol



pragma solidity 0.8.4;

/// @title Royalties formats required for use on the Rarible platform
/// @dev https://docs.rarible.com/asset/royalties-schema
interface IHasSecondarySaleFees is IERC165 {

    event SecondarySaleFees(uint256 tokenId, address[] recipients, uint[] bps);

    function getFeeRecipients(uint256 id) external returns (address payable[] memory);

    function getFeeBps(uint256 id) external returns (uint[] memory);
}


// File contracts/core/IKODAV3.sol



pragma solidity 0.8.4;





/// @title Core KODA V3 functionality
interface IKODAV3 is
IERC165, // Contract introspection
IERC721, // Core NFTs
IERC2309, // Consecutive batch mint
IERC2981, // Royalties
IHasSecondarySaleFees // Rariable / Foundation royalties
{
    // edition utils

    function getCreatorOfEdition(uint256 _editionId) external view returns (address _originalCreator);

    function getCreatorOfToken(uint256 _tokenId) external view returns (address _originalCreator);

    function getSizeOfEdition(uint256 _editionId) external view returns (uint256 _size);

    function getEditionSizeOfToken(uint256 _tokenId) external view returns (uint256 _size);

    function editionExists(uint256 _editionId) external view returns (bool);

    // Has the edition been disabled / soft burnt
    function isEditionSalesDisabled(uint256 _editionId) external view returns (bool);

    // Has the edition been disabled / soft burnt OR sold out
    function isSalesDisabledOrSoldOut(uint256 _editionId) external view returns (bool);

    // Work out the max token ID for an edition ID
    function maxTokenIdOfEdition(uint256 _editionId) external view returns (uint256 _tokenId);

    // Helper method for getting the next primary sale token from an edition starting low to high token IDs
    function getNextAvailablePrimarySaleToken(uint256 _editionId) external returns (uint256 _tokenId);

    // Helper method for getting the next primary sale token from an edition starting high to low token IDs
    function getReverseAvailablePrimarySaleToken(uint256 _editionId) external view returns (uint256 _tokenId);

    // Utility method to get all data needed for the next primary sale, low token ID to high
    function facilitateNextPrimarySale(uint256 _editionId) external returns (address _receiver, address _creator, uint256 _tokenId);

    // Utility method to get all data needed for the next primary sale, high token ID to low
    function facilitateReversePrimarySale(uint256 _editionId) external returns (address _receiver, address _creator, uint256 _tokenId);

    // Expanded royalty method for the edition, not token
    function royaltyAndCreatorInfo(uint256 _editionId, uint256 _value) external returns (address _receiver, address _creator, uint256 _amount);

    // Allows the creator to correct mistakes until the first token from an edition is sold
    function updateURIIfNoSaleMade(uint256 _editionId, string calldata _newURI) external;

    // Has any primary transfer happened from an edition
    function hasMadePrimarySale(uint256 _editionId) external view returns (bool);

    // Has the edition sold out
    function isEditionSoldOut(uint256 _editionId) external view returns (bool);

    // Toggle on/off the edition from being able to make sales
    function toggleEditionSalesDisabled(uint256 _editionId) external;

    // token utils

    function exists(uint256 _tokenId) external view returns (bool);

    function getEditionIdOfToken(uint256 _tokenId) external pure returns (uint256 _editionId);

    function getEditionDetails(uint256 _tokenId) external view returns (address _originalCreator, address _owner, uint16 _size, uint256 _editionId, string memory _uri);

    function hadPrimarySaleOfToken(uint256 _tokenId) external view returns (bool);

}


// File contracts/marketplace/BaseUpgradableMarketplace.sol



pragma solidity 0.8.4;







/// @notice Core logic and state shared between upgradable marketplaces
abstract contract BaseUpgradableMarketplace is ReentrancyGuardUpgradeable, PausableUpgradeable, UUPSUpgradeable {

    event AdminUpdateModulo(uint256 _modulo);
    event AdminUpdatePlatformPrimaryCommission(uint256 newAmount);
    event AdminUpdateMinBidAmount(uint256 _minBidAmount);
    event AdminUpdateAccessControls(IKOAccessControlsLookup indexed _oldAddress, IKOAccessControlsLookup indexed _newAddress);
    event AdminUpdateBidLockupPeriod(uint256 _bidLockupPeriod);
    event AdminUpdatePlatformAccount(address indexed _oldAddress, address indexed _newAddress);
    event AdminRecoverERC20(address indexed _token, address indexed _recipient, uint256 _amount);
    event AdminRecoverETH(address payable indexed _recipient, uint256 _amount);

    event BidderRefunded(uint256 indexed _id, address _bidder, uint256 _bid, address _newBidder, uint256 _newOffer);
    event BidderRefundedFailed(uint256 indexed _id, address _bidder, uint256 _bid, address _newBidder, uint256 _newOffer);

    // KO Commission override definition for a given item
    struct KOCommissionOverride {
        bool active;
        uint256 koCommission;
    }

    // Only admin defined in the access controls contract
    modifier onlyAdmin() {
        require(accessControls.hasAdminRole(_msgSender()), "Caller not admin");
        _;
    }

    modifier onlyCreatorContractOrAdmin(uint256 _editionId) {
        require(
            koda.getCreatorOfEdition(_editionId) == _msgSender() || accessControls.hasContractOrAdminRole(_msgSender()),
            "Caller not creator or admin"
        );
        _;
    }

    /// @notice Address of the access control contract
    IKOAccessControlsLookup public accessControls;

    /// @notice KODA V3 token
    IKODAV3 public koda;

    /// @notice platform funds collector
    address public platformAccount;

    /// @notice precision 100.00000%
    uint256 public modulo;

    /// @notice Minimum bid / minimum list amount
    uint256 public minBidAmount;

    /// @notice Bid lockup period
    uint256 public bidLockupPeriod;

    /// @notice Primary commission percentage
    uint256 public platformPrimaryCommission;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(IKOAccessControlsLookup _accessControls, IKODAV3 _koda, address _platformAccount) public initializer {
        __ReentrancyGuard_init();
        __Pausable_init();

        require(address(_accessControls) != address(0), "Unable to set invalid accessControls address");
        require(address(_koda) != address(0), "Unable to set invalid koda address");
        require(_platformAccount != address(0), "Unable to set invalid _platformAccount address");

        accessControls = _accessControls;
        koda = _koda;
        platformAccount = _platformAccount;

        // initial values for adjustable vars
        modulo = 100_00000;
        platformPrimaryCommission = 15_00000;
        minBidAmount = 0.01 ether;
        bidLockupPeriod = 6 hours;
    }

    function _authorizeUpgrade(address newImplementation) internal view override {
        require(accessControls.hasAdminRole(msg.sender), "Only admin can upgrade");
    }

    function recoverERC20(address _token, address _recipient, uint256 _amount) public onlyAdmin {
        require(_recipient != address(0), "Unable to send funds to invalid _recipient address");
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(_token), _recipient, _amount);
        emit AdminRecoverERC20(_token, _recipient, _amount);
    }

    function recoverStuckETH(address payable _recipient, uint256 _amount) public onlyAdmin {
        require(_recipient != address(0), "Unable to send funds to invalid _recipient address");
        (bool success,) = _recipient.call{value : _amount}("");
        require(success, "Unable to send recipient ETH");
        emit AdminRecoverETH(_recipient, _amount);
    }

    function updatePlatformPrimaryCommission(uint256 _newAmount) external onlyAdmin {
        require(_newAmount <= 10**40, "Platform commission too high - danger of over overflow");
        platformPrimaryCommission = _newAmount;
        emit AdminUpdatePlatformPrimaryCommission(_newAmount);
    }

    function updateAccessControls(IKOAccessControlsLookup _accessControls) public onlyAdmin {
        require(_accessControls.hasAdminRole(_msgSender()), "Sender must have admin role in new contract");
        emit AdminUpdateAccessControls(accessControls, _accessControls);
        accessControls = _accessControls;
    }

    function updateModulo(uint256 _modulo) public onlyAdmin {
        require(_modulo > 0, "Modulo point cannot be zero");
        modulo = _modulo;
        emit AdminUpdateModulo(_modulo);
    }

    function updateMinBidAmount(uint256 _minBidAmount) public onlyAdmin {
        minBidAmount = _minBidAmount;
        emit AdminUpdateMinBidAmount(_minBidAmount);
    }

    function updateBidLockupPeriod(uint256 _bidLockupPeriod) public onlyAdmin {
        bidLockupPeriod = _bidLockupPeriod;
        emit AdminUpdateBidLockupPeriod(_bidLockupPeriod);
    }

    function updatePlatformAccount(address _newPlatformAccount) public onlyAdmin {
        require(_newPlatformAccount != address(0), "Unable to set invalid _newPlatformAccount address");
        emit AdminUpdatePlatformAccount(platformAccount, _newPlatformAccount);
        platformAccount = _newPlatformAccount;
    }

    function pause() public onlyAdmin {
        super._pause();
    }

    function unpause() public onlyAdmin {
        super._unpause();
    }

    function _getLockupTime() internal view returns (uint256 lockupUntil) {
        lockupUntil = block.timestamp + bidLockupPeriod;
    }

    function _handleSaleFunds(address _fundsReceiver, uint256 _platformCommission) internal {
        uint256 koCommission = msg.value * _platformCommission / modulo;
        if (koCommission > 0) {
            (bool koCommissionSuccess,) = platformAccount.call{value : koCommission}("");
            require(koCommissionSuccess, "commission payment failed");
        }
        (bool success,) = _fundsReceiver.call{value : msg.value - koCommission}("");
        require(success, "payment failed");
    }

    function _refundBidder(uint256 _id, address _receiver, uint256 _paymentAmount, address _newBidder, uint256 _newOffer) internal {
        (bool success,) = _receiver.call{value : _paymentAmount}("");
        if (!success) {
            emit BidderRefundedFailed(_id, _receiver, _paymentAmount, _newBidder, _newOffer);
        } else {
            emit BidderRefunded(_id, _receiver, _paymentAmount, _newBidder, _newOffer);
        }
    }

}


// File contracts/marketplace/IKODAV3Marketplace.sol


pragma solidity 0.8.4;

interface IBuyNowMarketplace {
    event ListedForBuyNow(uint256 indexed _id, uint256 _price, address _currentOwner, uint256 _startDate);
    event BuyNowPriceChanged(uint256 indexed _id, uint256 _price);
    event BuyNowDeListed(uint256 indexed _id);
    event BuyNowPurchased(uint256 indexed _tokenId, address _buyer, address _currentOwner, uint256 _price);

    function listForBuyNow(address _creator, uint256 _id, uint128 _listingPrice, uint128 _startDate) external;

    function buyEditionToken(uint256 _id) external payable;
    function buyEditionTokenFor(uint256 _id, address _recipient) external payable;

    function setBuyNowPriceListing(uint256 _editionId, uint128 _listingPrice) external;
}

interface IEditionOffersMarketplace {
    event EditionAcceptingOffer(uint256 indexed _editionId, uint128 _startDate);
    event EditionBidPlaced(uint256 indexed _editionId, address _bidder, uint256 _amount);
    event EditionBidWithdrawn(uint256 indexed _editionId, address _bidder);
    event EditionBidAccepted(uint256 indexed _editionId, uint256 indexed _tokenId, address _bidder, uint256 _amount);
    event EditionBidRejected(uint256 indexed _editionId, address _bidder, uint256 _amount);
    event EditionConvertedFromOffersToBuyItNow(uint256 _editionId, uint128 _price, uint128 _startDate);

    function enableEditionOffers(uint256 _editionId, uint128 _startDate) external;

    function placeEditionBid(uint256 _editionId) external payable;
    function placeEditionBidFor(uint256 _editionId, address _bidder) external payable;

    function withdrawEditionBid(uint256 _editionId) external;

    function rejectEditionBid(uint256 _editionId) external;

    function acceptEditionBid(uint256 _editionId, uint256 _offerPrice) external;

    function convertOffersToBuyItNow(uint256 _editionId, uint128 _listingPrice, uint128 _startDate) external;
}

interface IEditionSteppedMarketplace {
    event EditionSteppedSaleListed(uint256 indexed _editionId, uint128 _basePrice, uint128 _stepPrice, uint128 _startDate);
    event EditionSteppedSaleBuy(uint256 indexed _editionId, uint256 indexed _tokenId, address _buyer, uint256 _price, uint16 _currentStep);
    event EditionSteppedAuctionUpdated(uint256 indexed _editionId, uint128 _basePrice, uint128 _stepPrice);

    function listSteppedEditionAuction(address _creator, uint256 _editionId, uint128 _basePrice, uint128 _stepPrice, uint128 _startDate) external;

    function buyNextStep(uint256 _editionId) external payable;
    function buyNextStepFor(uint256 _editionId, address _buyer) external payable;

    function convertSteppedAuctionToListing(uint256 _editionId, uint128 _listingPrice, uint128 _startDate) external;

    function convertSteppedAuctionToOffers(uint256 _editionId, uint128 _startDate) external;

    function updateSteppedAuction(uint256 _editionId, uint128 _basePrice, uint128 _stepPrice) external;
}

interface IReserveAuctionMarketplace {
    event ListedForReserveAuction(uint256 indexed _id, uint256 _reservePrice, uint128 _startDate);
    event BidPlacedOnReserveAuction(uint256 indexed _id, address _currentOwner, address _bidder, uint256 _amount, uint256 _originalBiddingEnd, uint256 _currentBiddingEnd);
    event ReserveAuctionResulted(uint256 indexed _id, uint256 _finalPrice, address _currentOwner, address _winner, address _resulter);
    event BidWithdrawnFromReserveAuction(uint256 _id, address _bidder, uint128 _bid);
    event ReservePriceUpdated(uint256 indexed _id, uint256 _reservePrice);
    event ReserveAuctionConvertedToBuyItNow(uint256 indexed _id, uint128 _listingPrice, uint128 _startDate);
    event EmergencyBidWithdrawFromReserveAuction(uint256 indexed _id, address _bidder, uint128 _bid);

    function placeBidOnReserveAuction(uint256 _id) external payable;
    function placeBidOnReserveAuctionFor(uint256 _id, address _bidder) external payable;

    function listForReserveAuction(address _creator, uint256 _id, uint128 _reservePrice, uint128 _startDate) external;

    function resultReserveAuction(uint256 _id) external;

    function withdrawBidFromReserveAuction(uint256 _id) external;

    function updateReservePriceForReserveAuction(uint256 _id, uint128 _reservePrice) external;

    function emergencyExitBidFromReserveAuction(uint256 _id) external;
}

interface IKODAV3PrimarySaleMarketplace is IEditionSteppedMarketplace, IEditionOffersMarketplace, IBuyNowMarketplace, IReserveAuctionMarketplace {
    function convertReserveAuctionToBuyItNow(uint256 _editionId, uint128 _listingPrice, uint128 _startDate) external;

    function convertReserveAuctionToOffers(uint256 _editionId, uint128 _startDate) external;
}

interface ITokenBuyNowMarketplace {
    event TokenDeListed(uint256 indexed _tokenId);

    function delistToken(uint256 _tokenId) external;
}

interface ITokenOffersMarketplace {
    event TokenBidPlaced(uint256 indexed _tokenId, address _currentOwner, address _bidder, uint256 _amount);
    event TokenBidAccepted(uint256 indexed _tokenId, address _currentOwner, address _bidder, uint256 _amount);
    event TokenBidRejected(uint256 indexed _tokenId, address _currentOwner, address _bidder, uint256 _amount);
    event TokenBidWithdrawn(uint256 indexed _tokenId, address _bidder);

    function acceptTokenBid(uint256 _tokenId, uint256 _offerPrice) external;

    function rejectTokenBid(uint256 _tokenId) external;

    function withdrawTokenBid(uint256 _tokenId) external;

    function placeTokenBid(uint256 _tokenId) external payable;
    function placeTokenBidFor(uint256 _tokenId, address _bidder) external payable;
}

interface IBuyNowSecondaryMarketplace {
    function listTokenForBuyNow(uint256 _tokenId, uint128 _listingPrice, uint128 _startDate) external;
}

interface IEditionOffersSecondaryMarketplace {
    event EditionBidPlaced(uint256 indexed _editionId, address indexed _bidder, uint256 _bid);
    event EditionBidWithdrawn(uint256 indexed _editionId, address _bidder);
    event EditionBidAccepted(uint256 indexed _tokenId, address _currentOwner, address _bidder, uint256 _amount);

    function placeEditionBid(uint256 _editionId) external payable;
    function placeEditionBidFor(uint256 _editionId, address _bidder) external payable;

    function withdrawEditionBid(uint256 _editionId) external;

    function acceptEditionBid(uint256 _tokenId, uint256 _offerPrice) external;
}

interface IKODAV3SecondarySaleMarketplace is ITokenBuyNowMarketplace, ITokenOffersMarketplace, IEditionOffersSecondaryMarketplace, IBuyNowSecondaryMarketplace {
    function convertReserveAuctionToBuyItNow(uint256 _tokenId, uint128 _listingPrice, uint128 _startDate) external;

    function convertReserveAuctionToOffers(uint256 _tokenId) external;
}

interface IKODAV3GatedMarketplace {

    function createSale(uint256 _editionId) external;

    function createPhase(
        uint256 _editionId,
        uint128 _startTime,
        uint128 _endTime,
        uint128 _priceInWei,
        uint16 _mintCap,
        uint16 _walletMintLimit,
        bytes32 _merkleRoot,
        string calldata _merkleIPFSHash
    ) external;

    function createSaleWithPhases(
        uint256 _editionId,
        uint128[] memory _startTimes,
        uint128[] memory _endTimes,
        uint128[] memory _pricesInWei,
        uint16[] memory _mintCaps,
        uint16[] memory _walletMintLimits,
        bytes32[] memory _merkleRoots,
        string[] memory _merkleIPFSHashes
    ) external;

    function createPhases(
        uint256 _editionId,
        uint128[] memory _startTimes,
        uint128[] memory _endTimes,
        uint128[] memory _pricesInWei,
        uint16[] memory _mintCaps,
        uint16[] memory _walletMintLimits,
        bytes32[] memory _merkleRoots,
        string[] memory _merkleIPFSHashes
    ) external;

    function removePhase(uint256 _editionId, uint256 _phaseId) external;
}


// File contracts/marketplace/KODAV3UpgradableGatedMarketplace.sol


pragma solidity 0.8.4;




contract KODAV3UpgradableGatedMarketplace is IKODAV3GatedMarketplace, BaseUpgradableMarketplace {

    /// @notice emitted when admin updates funds receiver
    event AdminUpdateFundReceiver(uint256 indexed _saleId, address _newFundsReceiver);

    /// @notice emitted when admin updates max edition ID
    event AdminUpdateMaxEditionId(uint256 indexed _saleId, uint256 _newMaxEditionId);

    /// @notice emitted when admin updates creator
    event AdminUpdateCreator(uint256 indexed _saleId, address _newCreator);

    /// @notice emitted when gated sale commission is updated for a given sale
    event AdminSetKoCommissionOverrideForSale(uint256 indexed _saleId, uint256 _platformPrimarySaleCommission);

    /// @notice emitted when a sale is paused
    event SalePaused(uint256 indexed _saleId);

    /// @notice emitted when a sale is resumed
    event SaleResumed(uint256 indexed _saleId);

    /// @notice emitted when a sale and its phases are created
    event SaleWithPhaseCreated(uint256 indexed _saleId);

    /// @notice emitted when a sale without any phases created
    event SaleCreated(uint256 indexed _saleId);

    /// @notice emitted when a new phase is added to a sale
    event PhaseCreated(uint256 indexed _saleId, uint256 indexed _phaseId);

    /// @notice emitted when a phase is removed from a sale
    event PhaseRemoved(uint256 indexed _saleId, uint256 indexed _phaseId);

    /// @notice emitted when someone mints from a sale
    event MintFromSale(uint256 indexed _saleId, uint256 indexed _phaseId, uint256 indexed _tokenId, address _recipient);

    /// @notice Phase represents a time structured part of a sale, i.e. VIP, pre sale or open sale
    struct Phase {
        uint128 startTime;      // The start time of the sale as a whole
        uint128 endTime;        // The end time of the sale phase, also the beginning of the next phase if applicable
        uint128 priceInWei;     // Price in wei for one mint
        uint16 mintCounter;     // The current amount of items minted
        uint16 mintCap;         // The maximum amount of mints for the phase
        uint16 walletMintLimit; // The mint limit per wallet for the phase
        bytes32 merkleRoot;     // The merkle tree root for the phase
        string merkleIPFSHash;  // The IPFS hash referencing the merkle tree
    }

    /// @notice Sale represents a gated sale, with mapping links to different sale phases
    struct Sale {
        uint256 id;             // The ID of the sale
        uint256 editionId;      // The ID of the edition the sale will mint
        address creator;        // Set on creation to save gas - the original edition creator
        address fundsReceiver;  // Where are the funds set
        uint256 maxEditionId;   // Stores the max edition ID for the edition - used when assigning tokens
        uint16 mintCounter;     // Keeps a pointer to the overall mint count for the full sale
        uint8 paused;           // Whether the sale is currently paused > 0 is paused
    }

    /// @notice sale Id -> KO commission override
    mapping(uint256 => KOCommissionOverride) public koCommissionOverrideForSale;

    /// @dev incremental counter for the ID of a sale
    uint256 public saleIdCounter;

    /// @dev totalMints is a mapping of hash(sale id, phase id, address) => total minted by that address
    mapping(bytes32 => uint256) public totalMints;

    /// @dev edition to sale is a mapping of edition id => sale id
    mapping(uint256 => uint256) public editionToSale;

    /// @dev sales is a mapping of sale id => Sale
    mapping(uint256 => Sale) public sales;

    /// @dev phases is a mapping of sale id => array of associated phases
    mapping(uint256 => Phase[]) public phases;

    /// @notice Allow an artist or admin to create a sale with 1 or more phases
    function createSaleWithPhases(
        uint256 _editionId,
        uint128[] memory _startTimes,
        uint128[] memory _endTimes,
        uint128[] memory _pricesInWei,
        uint16[] memory _mintCaps,
        uint16[] memory _walletMintLimits,
        bytes32[] memory _merkleRoots,
        string[] memory _merkleIPFSHashes
    ) external override whenNotPaused {
        address creator = koda.getCreatorOfEdition(_editionId);
        require(
            creator == _msgSender() || accessControls.hasContractOrAdminRole(_msgSender()),
            "Caller not creator or admin"
        );

        // Check no existing sale in place
        require(editionToSale[_editionId] == 0, "Sale exists for this edition");

        uint256 saleId = _createSale(_editionId, creator);

        _addMultiplePhasesToSale(
            saleId,
            _startTimes,
            _endTimes,
            _pricesInWei,
            _mintCaps,
            _walletMintLimits,
            _merkleRoots,
            _merkleIPFSHashes
        );

        emit SaleWithPhaseCreated(saleId);
    }

    /// @notice Allow an artist or admin to create a sale with 0 phases
    function createSale(uint256 _editionId) external override whenNotPaused {
        address creator = koda.getCreatorOfEdition(_editionId);
        require(
            creator == _msgSender() || accessControls.hasContractOrAdminRole(_msgSender()),
            "Caller not creator or admin"
        );

        // Check no existing sale in place
        require(editionToSale[_editionId] == 0, "Sale exists for this edition");

        uint256 saleId = _createSale(_editionId, creator);

        emit SaleCreated(saleId);
    }

    function _createSale(uint256 _editionId, address _creator) internal returns (uint256) {
        uint256 saleId = ++saleIdCounter;

        // Assign the sale to the sales and editionToSale mappings
        sales[saleId] = Sale({
        id : saleId,
        creator : _creator,
        fundsReceiver : koda.getRoyaltiesReceiver(_editionId),
        editionId : _editionId,
        maxEditionId : koda.maxTokenIdOfEdition(_editionId) - 1,
        paused : 0,
        mintCounter : 0
        });

        editionToSale[_editionId] = saleId;

        return saleId;
    }

    /// @notice Mint an NFT from the gated list
    function mint(
        uint256 _saleId,
        uint256 _phaseId,
        uint16 _mintCount,
        uint256 _index,
        bytes32[] calldata _merkleProof
    ) payable external nonReentrant whenNotPaused {
        Sale storage sale = sales[_saleId];
        require(sale.paused == 0, 'Sale is paused');

        Phase storage phase = phases[_saleId][_phaseId];

        require(block.timestamp >= phase.startTime && block.timestamp < phase.endTime, 'Sale phase not in progress');
        require(phase.mintCounter + _mintCount <= phase.mintCap, 'Phase mint cap reached');

        bytes32 totalMintsKey = keccak256(abi.encode(_saleId, _phaseId, _msgSender()));

        require(totalMints[totalMintsKey] + _mintCount <= phase.walletMintLimit, 'Cannot exceed total mints for sale phase');
        require(msg.value >= phase.priceInWei * _mintCount, 'Not enough wei sent to complete mint');
        require(onPhaseMintList(_saleId, _phaseId, _index, _msgSender(), _merkleProof), 'Address not able to mint from sale');

        handleMint(_saleId, _phaseId, sale.editionId, _mintCount, _msgSender());

        // Up the mint count for the user and the phase mint counter
        totalMints[totalMintsKey] += _mintCount;
        phase.mintCounter += _mintCount;
        sale.mintCounter += _mintCount;
    }

    function createPhase(
        uint256 _editionId,
        uint128 _startTime,
        uint128 _endTime,
        uint128 _priceInWei,
        uint16 _mintCap,
        uint16 _walletMintLimit,
        bytes32 _merkleRoot,
        string calldata _merkleIPFSHash
    )
    external override whenNotPaused onlyCreatorContractOrAdmin(_editionId) {
        uint256 saleId = editionToSale[_editionId];
        require(saleId > 0, 'No sale associated with edition id');

        _addPhaseToSale(
            saleId,
            _startTime,
            _endTime,
            _priceInWei,
            _mintCap,
            _walletMintLimit,
            _merkleRoot,
            _merkleIPFSHash
        );
    }

    function createPhases(
        uint256 _editionId,
        uint128[] memory _startTimes,
        uint128[] memory _endTimes,
        uint128[] memory _pricesInWei,
        uint16[] memory _mintCaps,
        uint16[] memory _walletMintLimits,
        bytes32[] memory _merkleRoots,
        string[] memory _merkleIPFSHashes
    )
    external override onlyCreatorContractOrAdmin(_editionId) whenNotPaused {

        // Ensure sale is valid
        uint256 saleId = editionToSale[_editionId];
        require(saleId > 0, 'No sale associated with edition id');

        _addMultiplePhasesToSale(
            saleId,
            _startTimes,
            _endTimes,
            _pricesInWei,
            _mintCaps,
            _walletMintLimits,
            _merkleRoots,
            _merkleIPFSHashes
        );
    }

    function removePhase(uint256 _editionId, uint256 _phaseId)
    external override onlyCreatorContractOrAdmin(_editionId) {
        require(koda.editionExists(_editionId), 'Edition does not exist');

        uint256 saleId = editionToSale[_editionId];
        require(saleId > 0, 'No sale associated with edition id');

        delete phases[saleId][_phaseId];

        emit PhaseRemoved(saleId, _phaseId);
    }

    /// @dev checks whether a given user is on the list to mint from a phase
    function onPhaseMintList(uint256 _saleId, uint256 _phaseId, uint256 _index, address _account, bytes32[] calldata _merkleProof)
    public view returns (bool) {
        Phase storage phase = phases[_saleId][_phaseId];
        // assume balance of 1 for enabled with access to the sale
        bytes32 node = keccak256(abi.encodePacked(_index, _account, uint256(1)));
        return MerkleProof.verify(_merkleProof, phase.merkleRoot, node);
    }

    function toggleSalePause(uint256 _saleId, uint256 _editionId) external onlyCreatorContractOrAdmin(_editionId) {
        if (sales[_saleId].paused != 0) {
            sales[_saleId].paused = 0;
            emit SaleResumed(_saleId);
        } else {
            sales[_saleId].paused = 1;
            emit SalePaused(_saleId);
        }
    }

    function remainingPhaseMintAllowance(uint256 _saleId, uint256 _phaseId, uint256 _index, address _account, bytes32[] calldata _merkleProof)
    external view returns (uint256) {
        require(onPhaseMintList(_saleId, _phaseId, _index, _account, _merkleProof), 'Address not able to mint from sale');

        return phases[_saleId][_phaseId].walletMintLimit - totalMints[keccak256(abi.encode(_saleId, _phaseId, _account))];
    }

    function handleMint(
        uint256 _saleId,
        uint256 _phaseId,
        uint256 _editionId,
        uint16 _mintCount,
        address _recipient
    ) internal {
        require(_mintCount > 0, "Nothing being minted");

        address creator = sales[_saleId].creator;
        uint256 startId = sales[_saleId].maxEditionId - sales[_saleId].mintCounter;

        for (uint256 i; i < _mintCount; ++i) {
            uint256 tokenId = getNextAvailablePrimarySaleToken(startId, _editionId, creator);

            // send token to buyer (assumes approval has been made, if not then this will fail)
            koda.safeTransferFrom(creator, _recipient, tokenId);

            emit MintFromSale(_saleId, _phaseId, tokenId, _recipient);

            // reduce start ID to allow to optimised token ID determination
            unchecked {startId = tokenId--;}
        }
        _handleSaleFunds(sales[_saleId].fundsReceiver, getPlatformSaleCommissionForSale(_saleId));
    }

    function getPlatformSaleCommissionForSale(uint256 _saleId) internal view returns (uint256) {
        if (koCommissionOverrideForSale[_saleId].active) {
            return koCommissionOverrideForSale[_saleId].koCommission;
        }
        return platformPrimaryCommission;
    }

    function getNextAvailablePrimarySaleToken(uint256 _startId, uint256 _editionId, address creator) internal view returns (uint256 _tokenId) {
        for (uint256 tokenId = _startId; tokenId >= _editionId; --tokenId) {
            if (koda.ownerOf(tokenId) == creator) {
                return tokenId;
            }
        }
        revert("Primary market exhausted");
    }

    function _addMultiplePhasesToSale(
        uint256 _saleId,
        uint128[] memory _startTimes,
        uint128[] memory _endTimes,
        uint128[] memory _pricesInWei,
        uint16[] memory _mintCaps,
        uint16[] memory _walletMintLimits,
        bytes32[] memory _merkleRoots,
        string[] memory _merkleIPFSHashes
    ) internal {
        uint256 numOfPhases = _startTimes.length;
        for (uint256 i; i < numOfPhases; ++i) {
            _addPhaseToSale(
                _saleId,
                _startTimes[i],
                _endTimes[i],
                _pricesInWei[i],
                _mintCaps[i],
                _walletMintLimits[i],
                _merkleRoots[i],
                _merkleIPFSHashes[i]
            );
        }
    }

    function _addPhaseToSale(
        uint256 _saleId,
        uint128 _startTime,
        uint128 _endTime,
        uint128 _priceInWei,
        uint16 _mintCap,
        uint16 _walletMintLimit,
        bytes32 _merkleRoot,
        string memory _merkleIPFSHash
    ) internal {
        require(_endTime > _startTime, 'Phase end time must be after start time');
        require(_walletMintLimit > 0, 'Zero mint limit');
        require(_mintCap > 0, "Zero mint cap");
        require(_merkleRoot != bytes32(0), "Zero merkle root");
        require(bytes(_merkleIPFSHash).length == 46, "Invalid IPFS hash");

        // Add the phase to the phases mapping
        phases[_saleId].push(Phase({
            startTime : _startTime,
            endTime : _endTime,
            priceInWei : _priceInWei,
            mintCounter : 0,
            mintCap : _mintCap,
            walletMintLimit : _walletMintLimit,
            merkleRoot : _merkleRoot,
            merkleIPFSHash : _merkleIPFSHash
        }));

        emit PhaseCreated(_saleId, phases[_saleId].length - 1);
    }

    function updateFundsReceiver(uint256 _saleId, address _newFundsReceiver) public onlyAdmin {
        require(_newFundsReceiver != address(0), "Unable to send funds to invalid address");
        sales[_saleId].fundsReceiver = _newFundsReceiver;
        emit AdminUpdateFundReceiver(_saleId, _newFundsReceiver);
    }

    function updateMaxEditionId(uint256 _saleId, uint256 _newMaxEditionId) public onlyAdmin {
        require(_newMaxEditionId >= 1, "Unable to set max edition");
        sales[_saleId].maxEditionId = _newMaxEditionId;
        emit AdminUpdateMaxEditionId(_saleId, _newMaxEditionId);
    }

    function updateCreator(uint256 _saleId, address _newCreator) public onlyAdmin {
        require(_newCreator != address(0), "Unable to make invalid address creator");
        sales[_saleId].creator = _newCreator;
        emit AdminUpdateCreator(_saleId, _newCreator);
    }

    function setKoCommissionOverrideForSale(uint256 _saleId, bool _active, uint256 _koCommission) public onlyAdmin {
        require(_koCommission <= (10**40), "KO Commission too high - danger of over overflow");
        KOCommissionOverride storage koCommissionOverride = koCommissionOverrideForSale[_saleId];
        koCommissionOverride.active = _active;
        koCommissionOverride.koCommission = _koCommission;
        emit AdminSetKoCommissionOverrideForSale(_saleId, _koCommission);
    }
}