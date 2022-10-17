/**
 *Submitted for verification at Etherscan.io on 2022-10-17
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title IReferralNFT
 *
 * Interface for operating with ReferralNFTs.
 */
interface IReferralNFT {
    /* ============ Events =============== */

    /* ============ Functions ============ */

    function isOwnerOf(address, uint256) external view returns (bool);
    function getNumMinted() external view returns (uint256);
    function cidOf(uint256) external view returns (uint256);
    function referrerOf(uint256) external view returns (uint160) ;
    // mint
    function mint(address account, uint256 cid, address referrer) external returns (uint256);
    function mintBatch(address account, uint256 amount, uint256 cid, address referrer) external returns (uint256[] memory);
    function burn(address account, uint256 id) external;
    function burnBatch(address account, uint256[] calldata ids) external;
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// File: @openzeppelin/contracts/utils/cryptography/ECDSA.sol


// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;


/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// File: @openzeppelin/contracts/utils/cryptography/draft-EIP712.sol


// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;


/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// File: contracts/Lifo_referral/1_W3WPlatform_withnosig.sol



pragma solidity >=0.7.0 <0.9.0;

contract CampaignPlatform is EIP712, Ownable {
    using Address for address;
    using SafeMath for uint256;
    /* ============ Events ============ */
    event EventCreateCampaign(
        uint256 _cid,
        address _erc20,
        uint256 _erc20Fee,
        uint256 _platformFee,
        uint256 _referrerRewardFee
    );

    event EventCreateLink(
        uint256 _cid,
        IReferralNFT IReferralNFT,
        address _referrer,
        bytes32 _link
    ); //TODO

    //dummyId作为全局的id，所有项目统一使用的一套
    //_nftID即tokenId
    event EventClaim(
        uint256 _cid,
        uint256 _dummyId,
        uint256 _nftID,
        IReferralNFT _referralNFT,
        address _sender
    );

    event EventClaimBatch(
        uint256 _cid,
        uint256[] _dummyIdArr,
        uint256[] _nftIDArr,
        IReferralNFT _referralNFT,
        address _sender
    );

    event EventSettleReferrer(
        uint256 indexed cid,
        address referrer,
        uint256 referScore
    );

    /* ============ Modifiers ============ */
    // modifier onlyCampaignOrganizer(uint256 cid) {
    //     require(msg.sender == cidOf);
    //     _;
    // }
    modifier onlyManager() {
        require(msg.sender == manager, "not manager");
        _;
    }
    modifier existCampaign(uint256 cid) {
        require(
            campaignFeeConfigs[cid].rewardReferrerFee > 0,
            "the campaign id does't exist"
        ); //必须活动存在, 目前只设置了一个参数
        _;
    }
    modifier onlyCampaignSetter() {
        _validateOnlyCampaignSetter();
        _;
    }
    modifier onlyReferrer(uint256 cid) {
        require(
            referrerList4[cid][msg.sender] >= 1,
            "not the campaign referrer"
        );
        _;
    }
    modifier onlyNoPaused() {
        _validateOnlyNotPaused();
        _;
    }
    modifier onlyTreasuryManager() {
        _validateOnlyTreasuryManager();
        _;
    }
    /* ============ Enums ================ */

    /* ============ Structs ============ */
    // 根据config进行 fee
    //可以不要reward的信息，在offchain去具体协商，也可以上面的方式，在每次refer的时候都直接给予奖励。
    struct CampaignFeeConfig {
        address erc20; // Address of token asset if required
        uint256 erc20Fee; // Amount of token if required
        uint256 platformFee; // Amount of fee for using the service if applicable
        uint256 rewardReferrerFee; //TODO: 需要单独的settlement
        // uint256 rewardRefereeFee; //TODO: 必须直接增加奖励，不然还要维护一个单独的referree的列表，不太好
    }

    //如果使用referrerList4 可以替代
    // struct Campaign {
    //     // uint32 cid; 不需要，数组中位置就是cid编号
    //     uint160 organizer; // if organizer record is required, then we can use this Campaign struct, otherwise we can just use referrerList3 mapping datastructure below
    //     uint160[] referrers;
    // }

    /* ============ State Variables ============ */
    bool public paused;

    address public campaignSetter;
    address public manager;
    address public treasuryManager;
    address public w3wSigner;

    // CampaignFeeConfig[] campaignFeeConfigs;
    mapping(uint256 => CampaignFeeConfig) public campaignFeeConfigs;
    //1
    // address public Owner;
    // list存放官方添加的referrer, 或A主动申请成为了referrer
    // mapping(address => uint256) public ReferrerList1; //uint256 for refer num, need modify
    //2

    // mapping(address => mapping(uint256 => address)) public ReferRecord; // 不考虑把 refer 的记录全部都记录在链上，代价又大，有没有太大用处
    // mapping(address => uint32) cidOfAddr;
    //3
    // mapping(uint256 => address[]) public referrerList3; // cid -> referrers, but the query time is not acceptable, maybe we have to use mapping to store referrer info
    // 设置了public 提供查询接口，但是或许不必要
    mapping(uint256 => mapping(address => uint256)) public referrerList4; //great query time 表示cid=>(referrer->referScore)
    mapping(uint256 => bool) public hasMinted;

    /* ============ Constructor ============ */
    constructor(
        address _campaignSetter,
        address _manager,
        address _treasuryManager,
        address _w3wSigner
    ) EIP712("W3W", "1.0.0") {
        // require(w3wSigner != address(0), "w3wSigner address must not be null address");
        // require(campaignSetter != address(0), "Campaign setter address must not be null address");
        w3wSigner = _w3wSigner;
        campaignSetter = _campaignSetter;
        treasuryManager = _treasuryManager;
        manager = _manager;
    }

    /* ============ External Functions ============ */

    // Create Referral Campaign
    function createCampaign(
        uint256 _cid,
        address _erc20,
        uint256 _erc20Fee,
        uint256 _platformFee,
        uint256 _referrerRewardFee
    ) external onlyCampaignSetter {
        _setFees(_cid, _erc20, _erc20Fee, _platformFee, _referrerRewardFee);
        emit EventCreateCampaign(_cid, _erc20, _erc20Fee, _platformFee, _referrerRewardFee);
    }

    // link只生成log
    function createLink(
        uint256 cid,
        IReferralNFT ReferralNFT,
        address referrer
    ) external onlyManager returns (bytes32) {
        // Generate Link
        bytes32 link = _hashLink(cid, ReferralNFT, referrer); //可以链下生成，只要保证和链上用一样的方法，生成结果是相同的即可

        // Verify Signature
        // require(_verify(link, _signature), "Invalid signature");
        // Record referrer wallet address

        // Emit Event
        emit EventCreateLink(cid, ReferralNFT, referrer, link); //记录link的生成，link是一个bytes32的哈希值

        return link;
    }

    // function addReferrer(uint32 cid, address _referrer) onlyManager {
    //     ReferrerList1[_referrer] = 1;
    //     // ReferrerList2[address] = 1;
    //     cidOfAddr[_referrer] = cid;
    // }
    function addReferrer(uint32 cid, address _referrer) public onlyManager {
        referrerList4[cid][_referrer] = 1;
    }

    function setPause(bool _paused) external onlyManager {
        paused = _paused;
    }

    //same as the claim func below
    // function claimReferralToken(
    //     uint256 _cid,
    //     address _referrer,
    //     IReferralNFT referralNFT,
    //     address _mintTo,
    //     uint256 _amount,
    //     bytes calldata _signature
    // ) external payable override onlyNoPaused {
    //     // verify signature
    //     require(
    //         _verify(_hash(_cid, referralNFT, _dummyId, _mintTo), _signature),
    //         "Invalid signature"
    //     );

    //     // Actual Mint

    //     // Emit Event
    //     emit EventClaim(_cid, _dummyId, nftID, referralNFT, _mintTo);
    // }

    //claim 就是在spacestation合约里面去先验证一下签名，然后
    function claim(
        uint256 _cid, //campaign id
        IReferralNFT _referralNFT, //nft address
        uint256 _dummyId, //globalId
        // uint256 _powah,
        address _mintTo, //owner
        address _referrer
    )
        external
        payable
        // bytes calldata _signature //verify
        existCampaign(_cid)
        onlyNoPaused
    {
        require(!hasMinted[_dummyId], "Already minted");
        // require(
        //     _verify(
        //         _hash(_cid, _referralNFT, _dummyId, _mintTo, _referrer),
        //         _signature
        //     ),
        //     "Invalid signature"
        // );
        hasMinted[_dummyId] = true;
        _payFees(_cid, 1);
        uint256 nftID = _referralNFT.mint(_mintTo, _cid, _referrer); //callback??
        emit EventClaim(_cid, _dummyId, nftID, _referralNFT, _mintTo);
    }

    function claimBatch(
        uint256 _cid,
        IReferralNFT _referralNFT,
        uint256[] calldata _dummyIdArr,
        // uint256[] calldata _powahArr,
        address _mintTo,
        address _referrer
    )
        external
        payable
        // bytes calldata _signature
        onlyNoPaused
    {
        require(
            _dummyIdArr.length > 0,
            "Array(_dummyIdArr) should not be empty"
        );
        // require(
        //     _powahArr.length == _dummyIdArr.length,
        //     "Array(_powahArr) length mismatch"
        // );

        for (uint256 i = 0; i < _dummyIdArr.length; i++) {
            require(!hasMinted[_dummyIdArr[i]], "Already minted");
            hasMinted[_dummyIdArr[i]] = true;
        }

        // require(
        //     _verify(
        //         _hashBatch(_cid, _referralNFT, _dummyIdArr, _mintTo, _referrer),
        //         _signature
        //     ),
        //     "Invalid signature"
        // );
        _payFees(_cid, _dummyIdArr.length);

        uint256[] memory nftIdArr = _referralNFT.mintBatch(
            _mintTo,
            _dummyIdArr.length,
            _cid,
            _referrer
        );
        emit EventClaimBatch(
            _cid,
            _dummyIdArr,
            nftIdArr,
            _referralNFT,
            _mintTo
        );
    }

    // 结算方法, 给organizer, 可 offchain
    // function settleCampaign(uint256 cid) public onlyCampaignOrganizer(cid) {
    //     require(condition);
    // }

    // the referrer settlement for the specific campaignId
    function settleReferrer(uint256 cid) public onlyReferrer(cid) {
        uint256 delta = referrerList4[cid][msg.sender] - 1;
        emit EventSettleReferrer(cid, msg.sender, delta);
        //TODO: 可以增加referrer 的 奖励，使用erc20，从treasuryManager 转账
    }

    function updateW3WSigner(address newAddress) external onlyManager {
        require(
            newAddress != address(0),
            "W3W signer address must not be null address"
        );
        w3wSigner = newAddress;
    }

    function updateCampaignSetter(address newAddress) external onlyManager {
        require(
            newAddress != address(0),
            "Campaign setter address must not be null address"
        );
        campaignSetter = newAddress;
    }

    function updateManager(address newAddress) external onlyManager {
        require(
            newAddress != address(0),
            "Manager address must not be null address"
        );
        manager = newAddress;
    }

    function updateTreasureManager(address payable newAddress)
        external
        onlyTreasuryManager
    {
        require(
            newAddress != address(0),
            "Treasure manager must not be null address"
        );
        treasuryManager = newAddress;
    }

    // 通过这个函数设置可以把匿名的eth转账全部统一发到一个钱包地址 treasuryManager
    receive() external payable {
        // anonymous transfer: to treasuryManager
        (bool success, ) = treasuryManager.call{value: msg.value}(new bytes(0));
        require(success, "Transfer failed");
    }

    /* ============ Internal Functions ============ */

    function _validateOnlyCampaignSetter() internal view {
        require(msg.sender == campaignSetter, "Only campaignSetter can call");
    }

    // function refer1(uint32 cid, address referrer) public {
    //     //private
    //     require(referrer != address(0));
    //     require(ReferrerList4[referrer] > 0, "referrer doesn't not exist!");
    //     emit Refer(cid, referrer, msg.sender);
    // }

    // function refer2(uint32 cid, address referrer) public {
    //     //private
    //     require(referrer != address(0));
    //     require(ReferrerList[referrer] > 0, "referrer doesn't not exist!");
    //     require(
    //         cid == cidOfAddr[referrer],
    //         "either the campaign id you set or the referrer address is wrong, cid and referrer address do not match"
    //     );
    //     rewardReferrer(referrer); //TODO: not set yet
    //     uint256 memory index = ReferrerList1[referrer];
    //     ReferRecord[referrer][index] = msg.sender;

    //     emit Refer(cid, referrer, msg.sender);
    // }

    /// @notice reward referrer on chain
    //  TODO: need modification
    // function rewardReferrer(address referrer) internal {
    //     ReferrerList1[referrer] += 1;
    // }

    // function rewardOneReferrer(){

    // }

    // 一共5种哈希，对应到单个mint 、batchMint、CappedMint、BatchCappedMint、Forge，也就是输入是有些许区别的，造成哈希函数入参不同，全部都重写了一份。
    // verify 函数只有一个，就是

    function _hash(
        uint256 _cid,
        IReferralNFT _ReferralNFT,
        uint256 _dummyId,
        address _account,
        address _referrer
    ) public view returns (bytes32) {
        //暂改public
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "NFT(uint256 cid,address ReferralNFT,uint256 dummyId,address account,address referrer)"
                        ),
                        _cid,
                        _ReferralNFT,
                        _dummyId,
                        _account,
                        _referrer
                    )
                )
            );
    }

    //TODO: tbc
    function _hashBatch(
        uint256 _cid,
        IReferralNFT _ReferralNFT,
        uint256[] calldata _dummyIdArr,
        address _account,
        address _referrer
    ) private view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "NFT(uint256 cid,address ReferralNFT,uint256[] dummyIdArr,address account,address referrer)"
                        ),
                        _cid,
                        _ReferralNFT,
                        keccak256(abi.encodePacked(_dummyIdArr)),
                        _account,
                        _referrer
                    )
                )
            );
    }

    // 通过哈希函数直接生成每一个referrer的固定link名字

    function _hashLink(
        uint256 _cid,
        IReferralNFT _ReferralNFT,
        address _referrer
    ) private view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "createLink(uint256 cid,address ReferralNFT,address referrer)" //keccak256("createLink(uint256,address,address)")
                        ),
                        _cid,
                        _ReferralNFT,
                        _referrer
                    )
                )
            );
    }

    //ReferralRecord(cid, referralAddress, refereeAddress)
    //Welcome to OpenSea!

    // Click to sign in and accept the OpenSea Terms of Service: https://opensea.io/tos

    // This request will not trigger a blockchain transaction or cost any gas fees.

    // Your authentication status will reset after 24 hours.

    // Wallet address:
    // 0x2d11ae7a83cc5c31093e9f8918e6a905222f536c

    // Nonce:
    // d6cad8bb-e721-43f7-8eb7-3c43f3b2c3e7

    // 验证是官方signer提供的sig
    // function _verify(bytes32 hash, bytes calldata signature)
    //     private
    //     view
    //     returns (bool)
    // {
    //     return ECDSA.recover(hash, signature) == w3wSigner; //保证给出来的signature是galaxy官方signer签名的
    //     //就是用了ecrecover，但是封装了一下，增加了签名的一些判断
    //     // ecrecover()
    // }

    function _setFees(
        uint256 _cid,
        address _erc20, // maybe change to other kind
        uint256 _erc20Fee,
        uint256 _platformFee,
        uint256 _rewardReferrerFee
    ) private {
        require(
            (_erc20 == address(0) && _erc20Fee == 0) ||
                (_erc20 != address(0) && _erc20Fee != 0),
            "Invalid erc20 fee requirement arguments"
        );
        campaignFeeConfigs[_cid] = CampaignFeeConfig(
            _erc20,
            _erc20Fee,
            _platformFee,
            _rewardReferrerFee
        );
    }

    function _payFees(uint256 _cid, uint256 amount)
        private
        existCampaign(_cid)
    {
        require(amount > 0, "Must mint more than 0");
        CampaignFeeConfig memory feeConf = campaignFeeConfigs[_cid];
        // 1. pay platformFee if needed
        if (feeConf.platformFee > 0) {
            require(
                msg.value >= feeConf.platformFee.mul(amount), //safeMath
                "Insufficient Payment"
            );
            (bool success, ) = treasuryManager.call{value: msg.value}(
                new bytes(0)
            );
            require(success, "Transfer platformFee failed");
        }
        // 2. pay erc20_fee if needed
        if (feeConf.erc20Fee > 0) {
            // user wallet transfer <erc20> of <feeConf.erc20Fee> to <this contract>.
            require(
                IERC20(feeConf.erc20).transferFrom( //erc20 的transfer方法,对应上面eth的就是call{msg.value}
                    msg.sender,
                    treasuryManager,
                    feeConf.erc20Fee.mul(amount) //erc20 是自动执行？？
                ),
                "Transfer erc20Fee failed"
            );
        }
    }

    //return the eth if send too much
    // function refundIfOver(uint256 price) private {
    //     if (msg.value > price) {
    //         payable(msg.sender).transfer(msg.value - price); // 退款
    //     }
    // }

    function _validateOnlyNotPaused() internal view {
        require(!paused, "Contract paused");
    }

    function _validateOnlyTreasuryManager() internal view {
        require(
            msg.sender == treasuryManager,
            "Only treasury manager can call"
        );
    }
}