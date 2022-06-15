// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/Clones.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Yoinked from Rarible: https://github.com/rariblecom/protocol-contracts/blob/master/royalties/contracts/LibPart.sol
struct Part {
    address payable account;
    uint96 value;
}

bytes4 constant ERC20_ASSET_CLASS = bytes4(keccak256("ERC20"));
bytes4 constant ERC721_ASSET_CLASS = bytes4(keccak256("ERC721"));
bytes4 constant ERC1155_ASSET_CLASS = bytes4(keccak256("ERC1155"));

/**
 * @param assetClass        ERC721: bytes(keccak256("ERC721"))
 *                          ERC1155: bytes4(keccak256("ERC1155"))
 * @param collection        Address where the token is deployed
 * @param tokenNonceOrId    tokenNonce if issued
 *                          tokenId if minted
 * @param startDate         Start date of the listing for sale
 * @param endDate           End date of the listing for sale
 * @param quantity          usually one except for initial listings.
 *                          Also leaves options open for semi-fungible tokens in the future
 * @param initialPrice      Price of the listing
 * @param paymentToken      Payment token accepted for the listing
 */
struct Listing {
    bytes4 assetClass;
    address collection;
    uint256 tokenNonceOrId;
    uint256 startDate;
    uint256 endDate;
    uint256 quantity;
    uint256 initialPrice;
    address paymentToken;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IMasterfileFactory} from "contracts/interfaces/IMasterfileFactory.sol";

contract FactoryVersion is IMasterfileFactory {
    address internal factoryRegistry;
    uint256 internal factoryVersion;

    modifier onlyRegistry {
        require(msg.sender == factoryRegistry, "Factory: Invalid registry");
        _;
    }

    constructor(address _registry) {
        factoryRegistry = _registry;
    }

    function getVersion() external view override returns (uint256 version_) {
        return factoryVersion;
    }

    function setVersion(uint256 _version) external onlyRegistry override returns (bool success) {
        require(factoryVersion == 0, "Factory: Version already set");
        factoryVersion = _version;
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MintingModuleProxy} from "contracts/proxies/MintingModuleProxy.sol";
import {SafeRegistry} from "contracts/registry/SafeRegistry.sol";
import {FactoryVersion} from "contracts/factories/FactoryVersion.sol";
import {IModuleFactory} from "contracts/interfaces/IModuleFactory.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title MintingModuleFactory
 */
contract MintingModuleFactory is FactoryVersion, IModuleFactory {

    SafeRegistry private _registry;
    address public implementation;

    address public registry;
    address public roleModule;
    address public collectionFactory;

    modifier onlyChannel() {
        require(
            _registry.isDeployment(keccak256("CHANNEL"), msg.sender),
            "Factory Error: Not a channel"
        );
        _;
    }

    constructor(
        address registry_,
        address _implementation,
        address _collectionFactory
    ) FactoryVersion(registry_) {
        _registry = SafeRegistry(registry_);
        implementation = _implementation;
        collectionFactory = _collectionFactory;
    }

    /**
     * @notice Deploy and initialize MintingModule. See `MintingModule.sol`
     * @dev deploy module using clones
     * @param moduleSalt 	Unique hex string
	   * @param _roleModule 	Role module of the channel
     * @return module   	Newly deployed minting module address
     */
    function deployMintingModule(
        bytes32 moduleSalt,
        address _roleModule
    ) public onlyChannel returns (address module) {

        registry = address(_registry);
        roleModule = _roleModule;

        require(
            !Address.isContract(getMintingModuleAddress(moduleSalt)),
            "MintingModuleFactory: Duplicate salt"
        );

        module = address(
            new MintingModuleProxy{salt: moduleSalt}()
        );

        delete registry;
        delete roleModule;

        emit ModuleDeployed(module, msg.sender, bytes4(keccak256("MINTING")));
    }

    function getMintingModuleAddress(bytes32 salt) public view returns (address mintingModuleAddress) {
        bytes memory bytecode = type(MintingModuleProxy).creationCode;

        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode))
        );

        return address(uint160(uint(hash)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FactoryVersion} from "contracts/factories/FactoryVersion.sol";
import {SafeRegistry} from "contracts/registry/SafeRegistry.sol";
import {SafeCollaborationProxy} from "contracts/proxies/SafeCollaborationProxy.sol";
import {Part} from "contracts/Schema.sol";

import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title SafeCollabFactory
 */
contract SafeCollabFactory is FactoryVersion {
    using Address for address;

    SafeRegistry private registry;
    address public implementation;

    modifier onlyChannel() {
        require(
            registry.isDeployment(keccak256("CHANNEL"), msg.sender),
            "Factory Error: Not a channel"
        );
        _;
    }

    /**
     * @notice Emitted when a new collection is created
     * @param channel Address of the channel owner
     * @param collaboration Address of the deployed creation
     * @param metadata Additional appendix information describing this collaboration
     */
    event CollabCreated(
        address indexed channel,
        address indexed collaboration,
        string metadata
    );

    constructor(address _registry, address _implementation) FactoryVersion(_registry) {
        registry = SafeRegistry(_registry);
        require(_implementation != address(0), "SafeCollabFactory: Invalid Implementation");
        implementation = _implementation;
    }

    /**
     * @notice Creates a new collaboration contract that allows collaborators to share sales and royalty payments.
     * @dev If a collaboration with the same shares configuration has already been created then it just returns the address of that contract
     * @param shares    {account: Address, value: uint96}[]. List of shareholders and their
     *      proportional value. Values are in bps and must add to 10000
     * @param metadata  Additional appendix information describing this collaboration
     */
    function createCollab(Part[] memory shares, string memory metadata)
        public
        onlyChannel
        returns (address collabAddress)
    {
        collabAddress = getCollabAddress((shares));
        if(!Address.isContract(collabAddress)) {
            SafeCollaborationProxy proxy = new SafeCollaborationProxy{salt: keccak256(abi.encode(shares))}();
            
            proxy.initialize(shares, metadata, implementation);
            
            registry.addDeployment(keccak256("COLLABORATION"), collabAddress);
            
            emit CollabCreated(msg.sender, collabAddress, metadata);
        }
    }

    /**
     * @notice Predicts new collaboration address
     * @param shares    {account: Address, value: uint96}[]. List of shareholders and their
     *      proportional value. Values are in bps and must add to 10000
     * @return collabAddress    Collaboration address
     */
    function getCollabAddress(Part[] memory shares) public view returns (address collabAddress) {
        bytes memory bytecode = type(SafeCollaborationProxy).creationCode;

        bytes32 salt = keccak256(abi.encode(shares));

        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode))
        );

        return address(uint160(uint(hash)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Part} from "contracts/Schema.sol";
import {ISafeCollaboration} from "contracts/interfaces/ISafeCollaboration.sol";
import {SafeCollaborationStorage} from "contracts/storage/SafeCollaborationStorage.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title SafeCollaboration
 */
contract SafeCollaboration is SafeCollaborationStorage, ERC165, ISafeCollaboration {
    using Address for address;
    using Address for address payable;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
     * @dev Requires that the msg.sender is one of the accounts in this split.
     */
    modifier onlyaccount() {
        for (uint256 i = 0; i < _shares.length; i++) {
            if (_shares[i].account == msg.sender) {
                _;
                return;
            }
        }
        revert("Split: Can only be called by one of the accounts");
    }

    /**
     * @notice Returns a tuple with the terms of this split.
     * @return shares   Shares of this collaboration. See `Schema.sol` for Part struct.
     */
    function getShares() public view override returns (Part[] memory shares) {
        return _shares;
    }

    /**
     * @notice Returns how many accounts are part of this split.
     * @return shareLength  Number of shares for this collaboration
     */
    function getShareLength()
        public
        view
        override
        returns (uint256 shareLength)
    {
        return _shares.length;
    }

    /**
     * @notice Returns a account in this split.
     * @param index Account index
     * @return Shares account
     */
    function getShareAccountByIndex(uint256 index)
        public
        view
        override
        returns (address payable)
    {
        return _shares[index].account;
    }

    /**
     * @notice Returns a account's percent share in basis points.
     * @param index         Account index
     * @return percentShare  Percent by basis points
     */
    function getPercentInBasisPointsByIndex(uint256 index)
        public
        view
        override
        returns (uint256 percentShare)
    {
        return _shares[index].value;
    }

    /**
     * @notice Returns metadata uri describing this collaboration agreement.
     * @return metadata  Uri link to additional metadata describing this collaboration
     */
    function getMetadata()
        public
        view
        override
        returns (string memory metadata)
    {
        return _metadata;
    }

    /**
     * @notice Forwards any ETH received to the accounts in this split.
     * @dev Each account increases the gas required to split
     * and contract accounts may significantly increase the gas required.
     */
    receive() external payable {
        _splitETH(msg.value);
    }

    /**
     * @notice Allows any ETH stored by the contract to be split among accounts.
     */
    function splitETH() public override {
        _splitETH(address(this).balance);
    }

    /**
     * @notice Splits ETH stored by the contract to be split among accounts
     */
    function _splitETH(uint256 value) internal {
        if (value > 0) {
            uint256 totalSent;
            uint256 amountToSend;
            for (uint256 i = _shares.length - 1; i > 0; i--) {
                Part memory share = _shares[i];
                amountToSend = (value * share.value) / BASIS_POINTS;
                totalSent += amountToSend;
                // share.account.sendValue(amountToSend);
                (bool success, ) = share.account.call{value: amountToSend}("");
                if(!success) {
                  continue;
                }
                emit ETHTransferred(share.account, amountToSend, i);
            }
            // Favor the 1st account if there are any rounding issues
            amountToSend = value - totalSent;
            (bool success, ) = _shares[0].account.call{value: amountToSend}("");
            if(success) {
                emit ETHTransferred(_shares[0].account, amountToSend, 0);
            }
        }
    }

    /**
     * @notice Anyone can call this function to split all available tokens at the provided address between the accounts.
     * @param erc20Contract Contract address of ERC20 to split
     */
    function splitERC20Tokens(IERC20 erc20Contract) public override {
        require(_splitERC20Tokens(erc20Contract), "Split: ERC20 split failed");
    }

    /**
     * @dev Anyone can call this function to split all available tokens at the provided address between the accounts.
     * Returns false on fail instead of reverting.
     */
    function _splitERC20Tokens(IERC20 erc20Contract) internal returns (bool) {
        try erc20Contract.balanceOf(address(this)) returns (uint256 balance) {
            if (balance == 0) {
                return false;
            }
            uint256 amountToSend;
            uint256 totalSent;
            for (uint256 i = _shares.length - 1; i > 0; i--) {
                Part memory share = _shares[i];
                bool success;
                (success, amountToSend) = balance.tryMul(share.value);
                if (!success) {
                    return false;
                }
                amountToSend /= BASIS_POINTS;
                totalSent += amountToSend;
                erc20Contract.safeTransfer(share.account, amountToSend);
                emit ERC20Transferred(
                    address(erc20Contract),
                    share.account,
                    amountToSend,
                    i
                );
            }
            // Favor the 1st account if there are any rounding issues
            amountToSend = balance - totalSent;
            erc20Contract.safeTransfer(_shares[0].account, amountToSend);
            emit ERC20Transferred(
                address(erc20Contract),
                _shares[0].account,
                amountToSend,
                0
            );
            return true;
        } catch {
            return false;
        }
    }

    /**
     * @notice Allows account to update address that is paid
     * @param index         Shares account index to update
     * @param newAccount    Address to replace the account with
     */
    function updateAccount(uint256 index, address payable newAccount)
        public
        override
    {
        require(_shares[index].account == msg.sender, "Invalid account index");

        _shares[index].account = newAccount;
		
		emit PercentSplitUpdate(newAccount, index);
    }

    /**
     * @notice Allows the split accounts to make an arbitrary contract call.
     * @dev This is provided to allow recovering from unexpected scenarios,
     * such as receiving an NFT at this address.
     * It will first attempt a fair split of ERC20 tokens before proceeding.
     * @param target    Target address of the proxy function call
     * @param callData  Encoded function call data
     */
    function proxyCall(address payable target, bytes memory callData)
        public
        override
        onlyaccount
    {
        _splitERC20Tokens(IERC20(target));
        target.functionCall(callData);
    }

    /**
     * @notice Returns if the interface if supported
     * @dev See {IERC165-supportsInterface}.
     * @param interfaceId Interface id to check for support
     * @return _supportsInterface True if supported, otherwise false
     */
    function supportsInterface(bytes4 interfaceId)
      public
      view
      virtual
      override
      returns (bool _supportsInterface)
    {
      return
        interfaceId == type(ISafeCollaboration).interfaceId ||
        super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMasterfileFactory {

    function getVersion() external view returns (uint256 version_);

    function setVersion(uint256 _version) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IModuleFactory {
    event ModuleDeployed(
        address indexed module,
        address indexed deployer,
        bytes4 indexed moduleType
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Part} from "contracts/Schema.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface ISafeCollaboration {

    event PercentSplitShare(
        address indexed account,
        uint256 percentInBasisPoints,
        uint256 indexed accountIndex
    );
	event PercentSplitUpdate(
		address indexed newAccount,
		uint256 indexed accountIndex
	);
    event ETHTransferred(
        address indexed account,
        uint256 amount,
        uint256 indexed accountIndex
    );
    event ERC20Transferred(
        address indexed erc20Contract,
        address indexed account,
        uint256 amount,
        uint256 indexed accountIndex
    );

    /**
    //  * @notice Initialize a collaboration
    //  * @param shares Shares participation for the collaboration. See `Schema.sol`
    //  * @param metadata Metadata url string
    //  */
    // function initialize(Part[] memory shares, string memory metadata) external;

    /**
     * @notice Returns a tuple with the terms of this split.
     */
    function getShares() external view returns (Part[] memory shares);

    /**
     * @notice Returns how many accounts are part of this split.
     */
    function getShareLength() external view returns (uint256 shareLength) ;

    /**
     * @notice Returns a account in this split.
     */
    function getShareAccountByIndex(uint256 index)
        external
        view
        returns (address payable);

    /**
     * @notice Returns a account's percent share in basis points.
     */
    function getPercentInBasisPointsByIndex(uint256 index)
        external
        view
        returns (uint256 percentShare);

    /**
     * @notice Returns metadata uri describing this collaboration agreement.
     */
    function getMetadata() external view returns (string memory metadata);


    /**
     * @notice Allows any ETH stored by the contract to be split among accounts.
     */
    function splitETH() external; 


    /**
     * @notice Anyone can call this function to split all available tokens at the provided address between the accounts.
     */
    function splitERC20Tokens(IERC20 erc20Contract) external;

    /**
     * @notice Allows account to update address that is paid
     */
    function updateAccount(uint256 index, address payable newAccount) external;

    /**
     * @notice Allows the split accounts to make an arbitrary contract call.
     * @dev This is provided to allow recovering from unexpected scenarios,
     * such as receiving an NFT at this address.
     * It will first attempt a fair split of ERC20 tokens before proceeding.
     */
    function proxyCall(address payable target, bytes memory callData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {RoleModuleStorage} from "contracts/storage/RoleModuleStorage.sol";

contract RoleModule is RoleModuleStorage, IAccessControl {

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, msg.sender);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool _supportsInterface) {
        return interfaceId == type(IAccessControl).interfaceId;
    }

    /**
     * @notice Returns `true` if `account` has been granted `role`.
     * @param role      Account role
     * @param account   Account address
     */
    function hasRole(bytes32 role, address account) public view override returns (bool _hasRole) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @notice Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     * @dev To change a role's admin, use {_setRoleAdmin}.
     * @param role      Account role
     * @return admin    Admin account for the role
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32 admin) {
        return _roles[role].adminRole;
    }

    /**
     * @notice Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @notice Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * @param role      Account role to revoke
     * @param account   Account address
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @notice Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     * 
     * @param role      Account role to revoke
     * @param account   Account address
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == msg.sender, "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MintingModuleStorage} from "contracts/storage/MintingModuleStorage.sol";
import {RoleModule} from "contracts/modules/RoleModule.sol";
import {SafeRegistry} from "contracts/registry/SafeRegistry.sol";

interface IMintingModuleFactory {
    function registry() external returns(address);

    function roleModule() external returns(address);

    function collectionFactory() external returns(address);

    function implementation() external returns(address);
}

/**
 * @title MintingModuleProxy - Proxy for the Minting Module
 */
contract MintingModuleProxy is MintingModuleStorage {

    constructor() {

        registry = SafeRegistry(IMintingModuleFactory(msg.sender).registry());
        collectionFactory = IMintingModuleFactory(msg.sender).collectionFactory();
        roleModule = RoleModule(IMintingModuleFactory(msg.sender).roleModule());

        _implementation = IMintingModuleFactory(msg.sender).implementation();
    }

    fallback() external payable {
		address _impl = implementation();
		assembly {
			let ptr := mload(0x40)
			calldatacopy(ptr, 0, calldatasize())
			let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
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
     * @notice  Returns the implementation of this proxy
     * @return  implementation_     Implementation address
     */
    function implementation() public view returns(address implementation_) {
        return _implementation;
    }

    receive() external payable {
        revert();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeCollaborationStorage} from "contracts/storage/SafeCollaborationStorage.sol";
import {SafeCollaboration} from "contracts/implementations/SafeCollaboration.sol";
import {Part} from "contracts/Schema.sol";

/**
 * @title SafeCollaborationProxy
 */
contract SafeCollaborationProxy is SafeCollaborationStorage {

	event PercentSplitShare(
		address indexed account,
		uint256 percentInBasisPoints,
		uint256 indexed accountIndex
	);

	function initialize(Part[] memory shares, string memory metadata, address collabImplementation)
		external
	{
      require(!_initialized, "SafeCollaboration: Already initialized");
      require(shares.length >= 2, "Collab: Too few accounts");
      require(shares.length <= 5, "Collab: Too many accounts");
      uint256 total;
      for (uint256 i = 0; i < shares.length; i++) {
        total += shares[i].value;
        _shares.push(shares[i]);
        emit PercentSplitShare(shares[i].account, shares[i].value, i);
      }
      require(total == BASIS_POINTS, "Collab: Total amount must equal 100%");

      _initialized = true;

      _metadata = metadata;
      _implementation = collabImplementation;
	}

	fallback() external payable {
		address _impl = implementation();
		assembly {
			let ptr := mload(0x40)
			calldatacopy(ptr, 0, calldatasize())
			let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
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
     * @notice Returns implementation for this Proxy
     * @return implementation_      Implementation address
     */
	function implementation() public view returns(address implementation_) {
		return _implementation;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {RegistryStorage} from "contracts/storage/RegistryStorage.sol";
import {IMasterfileFactory} from "contracts/interfaces/IMasterfileFactory.sol";
import {MintingModuleFactory} from "contracts/factories/MintingModuleFactory.sol";

/**
 * @title SafeRegistry
 */
contract SafeRegistry is RegistryStorage {

    event FactoryAdded(bytes32 indexed name, uint256 version, address factory);
    event DeployerWhitelisted(address deployer);
    event RegistryUpdated(address implementation);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyFactory(bytes32 factoryType) {
        require(
            isFactory[factoryType][msg.sender],
            "Registry: Invalid Factory"
        );
        _;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Registry: caller is not the owner");
        _;
    }

    function owner() public view returns (address owner_) {
        return _owner;
    }

    /**
     * @notice Add array of factories in the Registry
     * @dev checks if factory already exists to prevent unintentional overwrite
     * @param names             Array of factory names
     * @param newFactories      Array of new factory address
     */
    function addFactory(bytes32[] memory names, address[] memory newFactories) public onlyOwner {
        require(names.length == newFactories.length, "Registry: Factory length mismatch");
        for(uint256 i; i < names.length; i++) {
            uint256 version = factories[names[i]].length + 1;
            
            factories[names[i]].push(newFactories[i]);
            isFactory[names[i]][newFactories[i]] = true;

            require(IMasterfileFactory(newFactories[i]).setVersion(version), "Registry: Set factory version failed");

            emit FactoryAdded(names[i], version, newFactories[i]);
        }
    }

    function getFactory(bytes32 name, uint256 version) public view returns(address factory) {
        address[] memory _factories = factories[name];
        if(_factories.length == 0) {
            return address(0);
        }
        return _factories[version - 1];
    }

    function getFactory(bytes32 name) public view returns(address factory) {
        address[] memory _factories = factories[name];
        if(_factories.length == 0) {
            return address(0);
        }
        return _factories[_factories.length - 1];
    }

    function latestFactoryVersion(bytes32 name) public view returns(uint256) {
        return factories[name].length;
    }

    /**
     * @notice Register contract deployment
     * @dev Contract type and factory identifier will be the same. i.e. keccak256(CHANNEL)
     * @param contractType  Type of deployment, e.g. keccak256(CHANNEL)
     * @param deployment    Contract address to register
     */
    function addDeployment(bytes32 contractType, address deployment) public onlyFactory(contractType) {
        isDeployment[contractType][deployment] = true;
    }

    /**
     * @notice Whitelists an address as a deployer
     * @param deployer Address to whitelist
     */
    function whitelistDeployer(address deployer) public onlyOwner {
        whitelisted[deployer] = true;

        emit DeployerWhitelisted(deployer);
    }

    function updateRegistryImplementation(address _registry) public onlyOwner {
        _safeRegistry = _registry;
        emit RegistryUpdated(_registry);
    }

    // Ownable functions
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Registry: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function renounceOwnership() public onlyOwner {
        _transferOwnership(address(0));
    }

    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {RoleModule} from "contracts/modules/RoleModule.sol";
import {SafeRegistry} from "contracts/registry/SafeRegistry.sol";

/**
 * @title MintingModuleStorage
 */
contract MintingModuleStorage {
    address internal _implementation;
    address public collectionFactory;
    SafeRegistry internal registry;
    RoleModule internal roleModule;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice RegistryStorage
 */
contract RegistryStorage {
    address internal _safeRegistry;
    address internal _owner;
    address public masterfile;
    mapping(address  => bool) public whitelisted;
    mapping(bytes32 => mapping(address => bool)) public isDeployment;
    mapping(bytes32 => address[]) internal factories;
    mapping(bytes32 => mapping(address => bool)) public isFactory;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeRegistry} from "contracts/registry/SafeRegistry.sol";

struct RoleData {
    mapping(address => bool) members;
    bytes32 adminRole;
}

/**
 * @title RoleModuleStorage
 */
contract RoleModuleStorage {
    address internal _implementation;
    bool internal _initialized;
    SafeRegistry internal registry;
    mapping(bytes32 => RoleData) internal _roles;
    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Part} from "contracts/Schema.sol";

/**
 * @title SafeCollaborationStorage
 */
contract SafeCollaborationStorage {
    address internal _implementation;
    bool internal _initialized;
    Part[] internal _shares;
    string internal _metadata;
    uint256 internal BASIS_POINTS = 10000;
}