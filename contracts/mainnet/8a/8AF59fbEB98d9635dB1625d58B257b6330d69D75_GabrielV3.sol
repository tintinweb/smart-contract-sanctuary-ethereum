/**
 *Submitted for verification at Etherscan.io on 2023-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
pragma abicoder v2;
// File: @openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.


/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
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
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
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

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
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

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

// File: @openzeppelin/contracts-upgradeable/interfaces/IERC1967Upgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC1967.sol)



/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.8.3._
 */
interface IERC1967Upgradeable {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
}

// File: @openzeppelin/contracts-upgradeable/proxy/beacon/IBeaconUpgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/interfaces/draft-IERC1822Upgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)



// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20PermitUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)



/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
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

// File: @openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)



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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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

// File: @openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)






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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20Upgradeable token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && AddressUpgradeable.isContract(address(token));
    }
}

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)


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
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
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
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// File: @openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (proxy/ERC1967/ERC1967Upgrade.sol)

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable, IERC1967Upgradeable {
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
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            AddressUpgradeable.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data, bool forceCall) internal {
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
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            AddressUpgradeable.functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/UUPSUpgradeable.sol)






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
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
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
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeTo(address newImplementation) public virtual onlyProxy {
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
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) public payable virtual onlyProxy {
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

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)





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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// File: contracts/GabrielV3.sol


/// @title Archangel Reward Staking Pool V3 (GabrielV3)
/// @notice Stake tokens to Earn Rewards.
contract GabrielV3 is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    /* ========== STATE VARIABLES ========== */
    mapping(address => mapping(uint256 => bool)) public inPool;

    address public sharks;
    uint256 public sPercent;
    
    address public whales;
    uint256 public wPercent;
    
    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    /* ========== STRUCTS ========== */
    struct ConstructorArgs {
        uint256 sPercent;
        uint256 wPercent;
        address sharks;
        address whales;
    }
    
    struct ExtraArgs {
        IERC20Upgradeable stakeToken;
        uint256 openTime;
        uint256 waitPeriod;
        uint256 lockDuration;
        uint256 maxStake;
    }

    struct PoolInfo {
        bool canStake;
        bool canHarvest;
        IERC20Upgradeable stakeToken;
        uint256 compounded;
        uint256 lockDuration;
        uint256 lockTime;
        uint256 maxStake;
        uint256 NORT;
        uint256 openTime;
        uint256 staked;
        uint256 unlockTime;
        uint256 unstaked;        
        uint256 waitPeriod;
        address[] harvestList;
        address[] rewardTokens;
        address[] stakeList;
        uint256[] dynamicRewardsInPool;
        uint256[] staticRewardsInPool;
    }

    struct UserInfo {
        uint256 amount;
        bool harvested;
        uint256[] nonHarvestedRewards;
    }

    /* ========== EVENTS ========== */
    event Harvest(uint256 pid, address user, uint256 amount);
    event RateUpdated(uint256 sharks, uint256 whales);
    event Stake(uint256 pid, address user, uint256 amount);
    event Unstake(uint256 pid, address user, uint256 amount);

    /* ========== CONSTRUCTOR ========== */
    constructor() initializer {
        // solhint-disable-previous-line no-empty-blocks
    }

    function initialize(
        ConstructorArgs memory constructorArgs,
        ExtraArgs memory extraArgs,
        uint256 _NORT,
        address[] memory _rewardTokens,
        uint256[] memory _staticRewardsInPool
    ) public initializer {
        sPercent = constructorArgs.sPercent;
        wPercent = constructorArgs.wPercent;
        sharks = constructorArgs.sharks;
        whales = constructorArgs.whales;
        __Ownable_init();
        __UUPSUpgradeable_init();
        createPool(extraArgs, _NORT, _rewardTokens, _staticRewardsInPool);
    }

    /* ========== WRITE FUNCTIONS ========== */

    function _changeNORT(uint256 _pid, uint256 _NORT) internal {
        PoolInfo storage pool = poolInfo[_pid];
        address[] memory rewardTokens = new address[](_NORT);
        uint256[] memory staticRewardsInPool = new uint256[](_NORT);
        pool.NORT = _NORT;
        pool.rewardTokens = rewardTokens;
        pool.dynamicRewardsInPool = staticRewardsInPool;
        pool.staticRewardsInPool = staticRewardsInPool;
    }

    function changeNORT(uint256 _pid, uint256 _NORT) external onlyOwner {
        _changeNORT(_pid, _NORT);
    }

    function changeRewardTokens(uint256 _pid, address[] memory _rewardTokens) external onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 NORT = pool.NORT;
        require(_rewardTokens.length == NORT, "CRT: array length mismatch");
        for (uint256 i; i < NORT; i++) {
            pool.rewardTokens[i] = _rewardTokens[i];
        }
    }

    /**
     * @notice create a new pool
     * @param extraArgs ["stakeToken", openTime, waitPeriod, lockDuration]
     * @param _NORT specify the number of diffrent tokens the pool will give out as reward
     * @param _rewardTokens an array containing the addresses of the different reward tokens
     * @param _staticRewardsInPool an array of token balances for each unique reward token in the pool.
     */
    function createPool(ExtraArgs memory extraArgs, uint256 _NORT, address[] memory _rewardTokens, uint256[] memory _staticRewardsInPool) public onlyOwner {
        require(_rewardTokens.length == _NORT && _rewardTokens.length == _staticRewardsInPool.length, "CP: array length mismatch");
        address[] memory rewardTokens = new address[](_NORT);
        uint256[] memory staticRewardsInPool = new uint256[](_NORT);
        address[] memory emptyList;
        require(
            extraArgs.openTime > block.timestamp,
            "open time must be a future time"
        );
        uint256 _lockTime = extraArgs.openTime.add(extraArgs.waitPeriod);
        uint256 _unlockTime = _lockTime.add(extraArgs.lockDuration);
        
        poolInfo.push(
            PoolInfo({
                stakeToken: extraArgs.stakeToken,
                staked: 0,
                maxStake: extraArgs.maxStake,
                compounded: 0,
                unstaked: 0,
                openTime: extraArgs.openTime,
                waitPeriod: extraArgs.waitPeriod,
                lockTime: _lockTime,
                lockDuration: extraArgs.lockDuration,
                unlockTime: _unlockTime,
                canStake: false,
                canHarvest: false,
                NORT: _NORT,
                rewardTokens: rewardTokens,
                dynamicRewardsInPool: staticRewardsInPool,
                staticRewardsInPool: staticRewardsInPool,
                stakeList: emptyList,
                harvestList: emptyList
            })
        );
        uint256 _pid = poolInfo.length - 1;
        PoolInfo storage pool = poolInfo[_pid];
        for (uint256 i; i < _NORT; i++) {
            pool.rewardTokens[i] = _rewardTokens[i];
            pool.dynamicRewardsInPool[i] = _staticRewardsInPool[i];
            pool.staticRewardsInPool[i] = _staticRewardsInPool[i];
        }
    }

    /**
     * @notice Add your earnings to your stake
     * @dev compounding should be done after harvesting
     * @param _pid select the particular pool
    */
    function compoundArcha(uint256 _pid, address userAddress, bool leaveRewards) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][userAddress];
        uint256 NORT = pool.NORT;
        uint256 arrayLength = user.nonHarvestedRewards.length;
        uint256 pending;
        if (!leaveRewards) {
            uint256 reward = user.amount * pool.staticRewardsInPool[0];
            uint256 lpSupply = pool.staked;
            pending = reward.div(lpSupply);
        }
        if (arrayLength > 0 && arrayLength == NORT) {
            uint256 newPending = pending.add(user.nonHarvestedRewards[0]);
            uint256 futureStake = newPending.add(user.amount);
            if (futureStake <= pool.maxStake) {
                pending = pending.add(user.nonHarvestedRewards[0]);
                user.nonHarvestedRewards[0] = 0;
            } else if (futureStake > pool.maxStake) {
                user.nonHarvestedRewards[0] = user.nonHarvestedRewards[0].add(pending);
                uint256 toMax = pool.maxStake.sub(user.amount);
                pending = toMax;
                user.nonHarvestedRewards[0] = user.nonHarvestedRewards[0].sub(toMax);
            }    
        }
        if (arrayLength == 0) {
            uint256 reward = user.amount * pool.staticRewardsInPool[0];
            uint256 lpSupply = pool.staked;
            pending = reward.div(lpSupply);
            uint256 futureStake = pending.add(user.amount);
            if (futureStake > pool.maxStake) {
                uint256 toMax = pool.maxStake.sub(user.amount);
                uint256 excess = pending.sub(toMax);
                pending = toMax;
                user.nonHarvestedRewards = new uint256[](NORT);
                user.nonHarvestedRewards[0] = excess;
            }    
        }
        if (pending > 0) {
            pool.compounded = pool.compounded.add(pending);
            require(pending.add(user.amount) <= pool.maxStake, "you cannot stake more than the maximum");
            (bool inAnotherPool, uint256 pid) = checkIfAlreadyInAPool(userAddress);
            if (inAnotherPool) {
                require(pid == _pid, "staking in more than one pool is forbidden");
            }
            bool alreadyInAPool = inPool[userAddress][_pid];
            if (!alreadyInAPool) {
                inPool[userAddress][_pid] = true;
            }
            user.amount = user.amount.add(pending);
            emit Stake(_pid, userAddress, pending);
        }
    }

    /**
     * @notice Harvest your earnings
     * @param _pid select the particular pool
     * @param leaveRewards decide if you want to leave rewards in the pool till next round
    */
    function harvest(uint256 _pid, bool compound, bool leaveRewards) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        if (block.timestamp > pool.unlockTime && !(pool.canHarvest)) {
            pool.canHarvest = true;
        }
        require(pool.canHarvest, "pool is still locked");
        require(!(user.harvested), "Harvest: you have already claimed rewards for this round");
        pool.harvestList.push(msg.sender);
        update(_pid);
        uint256 NORT = pool.NORT;
        uint256 arrayLength = user.nonHarvestedRewards.length;
        user.harvested = true;
        if (compound && leaveRewards) {
            storeUnclaimedRewards(_pid, msg.sender);
            compoundArcha(_pid, msg.sender, leaveRewards);
        } else if (compound && !leaveRewards) {
            for (uint256 i; i < NORT; i++) {
                if (i == 0) { continue; }
                uint256 reward = user.amount * pool.staticRewardsInPool[i];
                uint256 lpSupply = pool.staked;
                uint256 pending = reward.div(lpSupply);
                pool.dynamicRewardsInPool[i] = pool.dynamicRewardsInPool[i].sub(pending);
                if (arrayLength > 0 && arrayLength == NORT) {
                    pending = pending.add(user.nonHarvestedRewards[i]);
                    user.nonHarvestedRewards[i] = 0; 
                }
                if (pending > 0) {
                    emit Harvest(_pid, msg.sender, pending);
                    IERC20Upgradeable(pool.rewardTokens[i]).safeTransfer(msg.sender, pending);
                }
            }
            compoundArcha(_pid, msg.sender, leaveRewards);
        } else if (!compound && leaveRewards) {
            storeUnclaimedRewards(_pid, msg.sender);
        } else if (!compound && !leaveRewards) {
            for (uint256 i; i < NORT; i++) {
                uint256 reward = user.amount * pool.staticRewardsInPool[i];
                uint256 lpSupply = pool.staked;
                uint256 pending = reward.div(lpSupply);
                pool.dynamicRewardsInPool[i] = pool.dynamicRewardsInPool[i].sub(pending);
                if (arrayLength > 0 && arrayLength == NORT) {
                    pending = pending.add(user.nonHarvestedRewards[i]);
                    user.nonHarvestedRewards[i] = 0; 
                }
                if (pending > 0) {
                    emit Harvest(_pid, msg.sender, pending);
                    IERC20Upgradeable(pool.rewardTokens[i]).safeTransfer(msg.sender, pending);
                }
            }
        }
    }

    /**
     * @notice prepare a pool for the next round of staking
     * @param _pid select the particular pool
     * @param extraArgs ["stakeToken", openTime, waitPeriod, lockDuration]
     * @param _NORT specify the number of diffrent tokens the pool will give out as reward
     * @param _rewardTokens an array containing the addresses of the different reward tokens
     * @param _staticRewardsInPool an array of token balances for each unique reward token in the pool.
     */
    function nextRound(uint256 _pid, ExtraArgs memory extraArgs, uint256 _NORT, address[] memory _rewardTokens, uint256[] memory _staticRewardsInPool) external onlyOwner {
        require(
            _rewardTokens.length == _NORT &&
            _rewardTokens.length == _staticRewardsInPool.length,
            "RP: array length mismatch"
        );
        PoolInfo storage pool = poolInfo[_pid];
        pool.stakeToken = extraArgs.stakeToken;
        pool.maxStake = extraArgs.maxStake;
        pool.staked = pool.staked.add(pool.compounded);
        pool.staked = pool.staked.sub(pool.unstaked);
        pool.compounded = 0;
        pool.unstaked = 0;
        _setTimeValues( _pid, extraArgs.openTime, extraArgs.waitPeriod, extraArgs.lockDuration);
        _changeNORT(_pid, _NORT);
        for (uint256 i; i < _NORT; i++) {
            pool.rewardTokens[i] = _rewardTokens[i];
            pool.dynamicRewardsInPool[i] = _staticRewardsInPool[i];
            pool.staticRewardsInPool[i] = _staticRewardsInPool[i];
        }
    }

    /// @notice allows for sending back locked tokens
    function recoverERC20(address token, address recipient, uint256 amount) external onlyOwner {
        IERC20Upgradeable(token).safeTransfer(recipient, amount);
    }

    /**
     * @notice sets user.harvested to false for all users
     * @dev the startIndex and endIndex are used to split the tnx into smaller batches
     * @param _pid select the particular pool
     * @param startIndex is the starting point for this batch.
     * @param endIndex is the ending point for this batch.
     */
    function reset(uint256 _pid, uint256 startIndex, uint256 endIndex) external onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 arrayLength = pool.harvestList.length;
        for (uint256 i = startIndex; i < endIndex; i++) {
            UserInfo storage user = userInfo[_pid][pool.harvestList[i]];
            user.harvested = false;
        }

        address lastArgAddr = pool.harvestList[endIndex - 1];
        address lastHarvester = pool.harvestList[arrayLength - 1];
        if (lastHarvester == lastArgAddr) {
            address[] memory emptyList;
            pool.harvestList = emptyList;
        }
    }

    function setPoolReward(uint256 _pid, address token, uint256 amount) external onlyOwner {
        uint256 onePercent = amount.div(100);
        uint256 tShare = wPercent.mul(onePercent);
        uint256 mShare = amount.sub(tShare);
        emit RateUpdated(_pid, amount);
        IERC20Upgradeable(token).safeTransfer(sharks, mShare);
        IERC20Upgradeable(token).safeTransfer(whales, tShare);
    }

    /**
     * @notice Set or modify the token balances of a particular pool
     * @param _pid select the particular pool
     * @param rewards array of token balances for each reward token in the pool
     */
    function setPoolRewards(uint256 _pid, uint256[] memory rewards) external onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 NORT = pool.NORT;
        require(rewards.length == NORT, "SPR: array length mismatch");
        for (uint256 i; i < NORT; i++) {
            pool.dynamicRewardsInPool[i] = rewards[i];
            pool.staticRewardsInPool[i] = rewards[i];
        }
    }

    function setRates(uint256 _sPercent, uint256 _wPercent) external onlyOwner {
        require(_sPercent.add(_wPercent) == 100, "must sum up to 100%");
        sPercent = _sPercent;
        wPercent = _wPercent;
        emit RateUpdated(_sPercent, _wPercent);
    }

    function setSharkPoolAddress(address _sharks) external {
        require(msg.sender == sharks, "sharks: caller is not the current sharks");
        require(_sharks != address(0), "cannot set sharks as zero address");
        sharks = _sharks;
    }

    function _setTimeValues(
        uint256 _pid,
        uint256 _openTime,
        uint256 _waitPeriod,
        uint256 _lockDuration
    ) internal {
        PoolInfo storage pool = poolInfo[_pid];
        require(
            _openTime > block.timestamp,
            "open time must be a future time"
        );
        pool.openTime = _openTime;
        pool.waitPeriod = _waitPeriod;
        pool.lockTime = _openTime.add(_waitPeriod);
        pool.lockDuration = _lockDuration;
        pool.unlockTime = pool.lockTime.add(_lockDuration);
    }

    function setTimeValues(
        uint256 _pid,
        uint256 _openTime,
        uint256 _waitPeriod,
        uint256 _lockDuration
    ) external onlyOwner {
        _setTimeValues(_pid, _openTime, _waitPeriod, _lockDuration);
    }

    /// @notice Update whales address.
    function setWhalePoolAddress(address _whales) external onlyOwner {
        require(_whales != address(0), "cannot set whales as zero address");
        whales = _whales;
    }

    /**
     * @notice stake ERC20 tokens to earn rewards
     * @param _pid select the particular pool
     * @param _amount amount of tokens to be deposited by user
     */
    function stake(uint256 _pid, uint256 _amount) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        if (block.timestamp > pool.lockTime && pool.canStake) {
            pool.canStake = false;
        }
        if (
            block.timestamp > pool.openTime &&
            block.timestamp < pool.lockTime &&
            block.timestamp < pool.unlockTime &&
            !(pool.canStake)
        ) {
            pool.canStake = true;
        }
        require(
            pool.canStake,
            "pool is not yet opened or is locked"
        );
        require(_amount > 0, "you cannot stake a value less than 1");
        require(_amount.add(user.amount) <= pool.maxStake, "you cannot stake more than the maximum");
        (bool inAnotherPool, uint256 pid) = checkIfAlreadyInAPool(msg.sender);
        if (inAnotherPool) {
            require(
                pid == _pid,
                "staking in more than one pool isn't allowed"
            );
        }
        bool alreadyInAPool = inPool[msg.sender][_pid];
        if (!alreadyInAPool) {
            inPool[msg.sender][_pid] = true;
        }
        update(_pid);
        pool.stakeList.push(msg.sender);
        user.amount = user.amount.add(_amount);
        pool.staked = pool.staked.add(_amount);
        emit Stake(_pid, msg.sender, _amount);
        pool.stakeToken.safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
    }

    function storeUnclaimedRewards(uint256 _pid, address userAddress) internal {
        PoolInfo memory pool = poolInfo[_pid];
        uint256 NORT = pool.NORT;
        UserInfo storage user = userInfo[_pid][userAddress];
        uint256 arrayLength = user.nonHarvestedRewards.length;
        if (arrayLength == 0) {
            user.nonHarvestedRewards = new uint256[](NORT);
            for (uint256 x = 0; x < NORT; x++) {
                uint256 reward = user.amount * pool.staticRewardsInPool[x];
                uint256 lpSupply = pool.staked;
                uint256 pending = reward.div(lpSupply);
                if (pending > 0) {
                    user.nonHarvestedRewards[x] = pending;
                }
            }
        }
        if (arrayLength == NORT) {
            for (uint256 x = 0; x < NORT; x++) {
                uint256 reward = user.amount * pool.staticRewardsInPool[x];
                uint256 lpSupply = pool.staked;
                uint256 pending = reward.div(lpSupply);
                if (pending > 0) {
                    user.nonHarvestedRewards[x] = user.nonHarvestedRewards[x].add(pending);
                }
            }
        }
    }

    /**
     * @notice Exit without caring about rewards
     * @param _pid select the particular pool
    */
    function unstake(uint256 _pid) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount > 0, "unstake: your staked balance is zero");
        bool alreadyInAPool = inPool[msg.sender][_pid];
        if (alreadyInAPool) {
            inPool[msg.sender][_pid] = false;
        }
        pool.unstaked = pool.unstaked.add(user.amount);
        uint256 staked = user.amount;
        user.amount = 0;
        emit Unstake(_pid, msg.sender, staked);
        pool.stakeToken.safeTransfer(msg.sender, staked);
    }

    function update(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.openTime) {
            return;
        }
        if (
            block.timestamp > pool.openTime &&
            block.timestamp < pool.lockTime &&
            block.timestamp < pool.unlockTime
        ) {
            pool.canStake = true;
            pool.canHarvest = false;
        }
        if (
            block.timestamp > pool.lockTime &&
            block.timestamp < pool.unlockTime
        ) {
            pool.canStake = false;
            pool.canHarvest = false;
        }
        if (
            block.timestamp > pool.unlockTime &&
            pool.unlockTime > 0
        ) {
            pool.canStake = false;
            pool.canHarvest = true;
        }
    }

    function _authorizeUpgrade(address newImplementation) internal onlyOwner override {
        // solhint-disable-previous-line no-empty-blocks
    }

    /* ========== READ ONLY FUNCTIONS ========== */

    // will return default values (false, 0) if !(alreadyInAPool)
    function checkIfAlreadyInAPool(address user) internal view returns (bool inAnotherPool, uint256 pid) {
        for (uint256 poolId; poolId < poolInfo.length; poolId++) {
            if (poolInfo.length > 0) {
                bool alreadyInAPool = inPool[user][poolId];
                if (alreadyInAPool) {
                    return (alreadyInAPool, poolId);
                }
            }
        }
    }

    function dynamicRewardInPool(uint256 _pid) external view returns (uint256[] memory dynamicRewardsInPool) {
        PoolInfo memory pool = poolInfo[_pid];
        dynamicRewardsInPool = pool.dynamicRewardsInPool;
    }

    function harvesters(uint256 _pid) external view returns (address[] memory) {
        PoolInfo memory pool = poolInfo[_pid];
        return pool.harvestList;
    }

    function harvests(uint256 _pid) external view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];
        return pool.harvestList.length;
    }

    function isInArray(address[] memory array, address item) internal pure returns (bool) {
        for (uint256 i; i < array.length; i++) {
            if (array[i] == item) {
                return true;
            }
        }
        return false;
    }

    function nonHarvestedRewards(uint256 _pid, address staker) external view returns (uint256[] memory) {
        UserInfo memory user = userInfo[_pid][staker];
        return user.nonHarvestedRewards;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function stakers(uint256 _pid) external view returns (address[] memory) {
        PoolInfo memory pool = poolInfo[_pid];
        return pool.stakeList;
    }

    function stakes(uint256 _pid) external view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];
        if (pool.stakeList.length > 0) {
            uint256 counter = 1;
            uint256 index = counter - 1;
            address[] memory newArray = new address[](counter);
            newArray[index] = pool.stakeList[index];
            for (uint256 i; i < pool.stakeList.length; i++) {
                if (!(isInArray(newArray, pool.stakeList[i]))) {
                    counter += 1;
                    index = counter - 1;
                    address[] memory oldArray = newArray;
                    newArray = new address[](counter);
                    for (uint256 x; x < oldArray.length; x++) {
                        newArray[x] = oldArray[x];
                    }
                    newArray[index] = pool.stakeList[i];
                }
            }
            return newArray.length;
        } else {
            return 0;
        }
    }

    function staticRewardInPool(uint256 _pid) external view returns (uint256[] memory staticRewardsInPool) {
        PoolInfo memory pool = poolInfo[_pid];
        staticRewardsInPool = pool.staticRewardsInPool;
    }

    function tokensInPool(uint256 _pid) external view returns (address[] memory rewardTokens) {
        PoolInfo memory pool = poolInfo[_pid];
        rewardTokens = pool.rewardTokens;
    }

    function unclaimedRewards(uint256 _pid, address _user)
        external
        view
        returns (uint256[] memory unclaimedReward)
    {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        uint256 NORT = pool.NORT;
        uint256 arrayLength = user.nonHarvestedRewards.length;
        if (block.timestamp > pool.lockTime && block.timestamp < pool.unlockTime && !(user.harvested) && pool.staked != 0) {
            uint256[] memory array = new uint256[](NORT);
            for (uint256 i; i < NORT; i++) {
                uint256 blocks = block.timestamp.sub(pool.lockTime);
                uint256 reward = blocks * user.amount * pool.staticRewardsInPool[i];
                uint256 lpSupply = pool.staked * pool.lockDuration;
                uint256 pending = reward.div(lpSupply);
                if (arrayLength == NORT) {
                    pending = pending.add(user.nonHarvestedRewards[i]);
                }
                array[i] = pending;
            }
            return array;
        } else if (block.timestamp > pool.unlockTime && !(user.harvested) && pool.staked != 0) {
            uint256[] memory array = new uint256[](NORT);
            for (uint256 i; i < NORT; i++) {                
                uint256 reward = user.amount * pool.staticRewardsInPool[i];
                uint256 lpSupply = pool.staked;
                uint256 pending = reward.div(lpSupply);
                if (arrayLength == NORT) {
                    pending = pending.add(user.nonHarvestedRewards[i]);
                }
                array[i] = pending;
            }
            return array;
        } else {
            uint256[] memory array = new uint256[](NORT);
            for (uint256 i; i < NORT; i++) {
                uint256 pending = 0;
                if (arrayLength == NORT) {
                    pending = user.nonHarvestedRewards[i];
                }                
                array[i] = pending;
            }
            return array;
        }        
    }
}