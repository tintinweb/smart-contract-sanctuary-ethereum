/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

/** 
 *  SourceUnit: contracts\Bridge.sol
*/
            

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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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




/** 
 *  SourceUnit: contracts\Bridge.sol
*/
            

// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [////IMPORTANT]
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
     * ////IMPORTANT: because control is transferred to `recipient`, care must be
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




/** 
 *  SourceUnit: contracts\Bridge.sol
*/
            

// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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




/** 
 *  SourceUnit: contracts\Bridge.sol
*/
            

// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

////import "../Strings.sol";

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
     * ////IMPORTANT: `hash` _must_ be the result of a hash operation for the
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
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
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
     * ////IMPORTANT: `hash` _must_ be the result of a hash operation for the
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




/** 
 *  SourceUnit: contracts\Bridge.sol
*/
            

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




/** 
 *  SourceUnit: contracts\Bridge.sol
*/
            

pragma solidity 0.8.11;

//uint256 constant DECIMALS = 10**18;
uint256 constant DECIMALS = 18;
uint256 constant DECIMALS18 = 1e18;

uint256 constant MAX_UINT256 = type(uint256).max;
uint256 constant PERCENTAGE_100 = 100 * DECIMALS18;
uint256 constant PERCENTAGE_1 = DECIMALS18;
uint256 constant MAX_FEE_PERCENTAGE = 99 * DECIMALS18;

uint256 constant YEAR_IN_SECONDS = 31556952;

string constant ERROR_ACCESS_DENIED = "0x1";
string constant ERROR_NO_CONTRACT = "0x2";
string constant ERROR_NOT_AVAILABLE = "0x3";
string constant ERROR_KYC_MISSING = "0x4";
string constant ERROR_INVALID_ADDRESS = "0x5";
string constant ERROR_INCORRECT_CALL_METHOD = "0x6";
string constant ERROR_AMOUNT_IS_ZERO = "0x7";
string constant ERROR_HAVENT_ALLOCATION = "0x8";
string constant ERROR_AMOUNT_IS_MORE_TS = "0x9";
string constant ERROR_ERC20_CALL_ERROR = "0xa";
string constant ERROR_DIFF_ARR_LENGTH = "0xb";
string constant ERROR_METHOD_DISABLE = "0xc";
string constant ERROR_SEND_VALUE = "0xd";
string constant ERROR_NOT_ENOUGH_NFT_IDS = "0xe";
string constant ERROR_INCORRECT_FEE = "0xf";
string constant ERROR_WRONG_IMPLEMENT_ADDRESS = "0x10";
string constant ERROR_INVALID_SIGNER = "0x11";
string constant ERROR_NOT_FOUND = "0x12";
string constant ERROR_IS_EXISTS = "0x13";
string constant ERROR_IS_NOT_EXISTS = "0x14";
string constant ERROR_TIME_OUT = "0x15";
string constant ERROR_NFT_NOT_EXISTS = "0x16";
string constant ERROR_MINTING_COMPLETED = "0x17";
string constant ERROR_TOKEN_NOT_SUPPORTED = "0x18";
string constant ERROR_NOT_ENOUGH_NFT_FOR_SALE = "0x19";
string constant ERROR_NOT_ENOUGH_PREVIOUS_NFT = "0x1a";
string constant ERROR_FAIL = "0x1b";
string constant ERROR_MORE_THEN_MAX = "0x1c";
string constant ERROR_VESTING_NOT_START = "0x1d";
string constant ERROR_VESTING_IS_STARTED = "0x1e";
string constant ERROR_IS_SET = "0x1f";
string constant ERROR_ALREADY_CALL_METHOD = "0x20";
string constant ERROR_INCORRECT_DATE = "0x21";
string constant ERROR_IS_NOT_SALE = "0x22";
string constant ERROR_UNPREDICTABLE_MEMBER_ACTION = "0x23";
string constant ERROR_ALREADY_PAID = "0x24";
string constant ERROR_COOLDOWN_IS_NOT_OVER = "0x25";
string constant ERROR_INSUFFICIENT_AMOUNT = "0x26";
string constant ERROR_RESERVES_IS_ZERO = "0x27";
string constant ERROR_TREE_EXISTS = "0x28";
string constant ERROR_TREE_DOESNT_EXIST = "0x29";
string constant ERROR_NOT_DIFFERENT_MEMBERS = "0x2a";
string constant ERROR_NOT_ENOUGH_BALANCE = "0x2b";
string constant ERROR_ALREADY_DISTRIBUTED = "0x2c";
string constant ERROR_INDEX_OUT = "0x2d";
string constant ERROR_NOT_START = "0x2e";
string constant ERROR_ALREADY_CLAIMED = "0x2f";
string constant ERROR_LENGTH_IS_ZERO = "0x30";
string constant ERROR_WRONG_AMOUNT = "0x31";
string constant ERROR_SIGNERS_CANNOT_BE_EMPTY = "0x41";
string constant ERROR_LOCKED_PERIOD = "0x42";
string constant ERROR_INVALID_NONCE = "0x43";
string constant ERROR_CHAIN_NOT_SUPPORTED = "0x44";
string constant ERROR_INCORRECT_DATA = "0x45";
string constant ERROR_TWO_AMOUNTS_ENTERED = "0x46";

bytes32 constant KYC_CONTAINER_TYPEHASH = keccak256("Container(address sender,uint256 deadline)");

uint256 constant ROLE_ADMIN = 1;
uint256 constant CAN_WITHDRAW_NATIVE = 10;

// Managemenet
uint256 constant MANAGEMENT_CAN_SET_KYC_WHITELISTED = 3;
uint256 constant MANAGEMENT_KYC_SIGNER = 4;
uint256 constant MANAGEMENT_WHITELISTED_KYC = 5;

// Payment Gateway
uint256 constant SHOPS_PAYMENT_PAY_SIGNER = 21;
uint256 constant SHOPS_POOL_CAN_WITHDRAW_FOR = 31;
uint256 constant SHOPS_MANAGER_BLACK_LIST_PERM = 41;
uint256 constant SHOPS_MAGANER_FREEZ_LIST_PERM = 42;
uint256 constant SHOPS_MANAGER_CAN_SET_SHOP_ACCESS = 43;
uint256 constant SHOPS_MANAGER_CAN_REGISTER_REMOVE_SHOP = 44;
uint256 constant SHOPS_MANAGER_CAN_SET_COMMISION = 45;

// Public Sale
uint256 constant CAN_MINT_TOKENS_TOKEN_PLAN = 100;
uint256 constant CAN_BURN_TOKENS_TOKEN_PLAN = 101;

uint256 constant CAN_UPDATE_REWARD_REFERRAL_TREE = 120;
uint256 constant CAN_CREATE_TREE_REFERRAL_TREE = 121;
uint256 constant CAN_UPDATE_CALCULATE_REWARDS_REFERRAL_TREE = 122;

uint256 constant CAN_STAKE_FOR_APR_STAKE = 123;

uint256 constant CAN_FORWARD_FORWARDER = 124;

uint256 constant CAN_DISTRIBUT_BONUS_KRU_DISTRIBUTOR = 140;
uint256 constant CAN_CHANGE_BONUS_KRU_BONUS_DISTRIBUTOR = 143;

uint256 constant CAN_CHANGE_PURCHASE_INFO = 141;
uint256 constant CAN_SET_PLANS_INFO = 142;

//KRUExchangeForwarder
uint256 constant EXCHANGE_FORWARDER_SIGNER = 151;
uint256 constant EXCHANGE_FORWARDER_CAN_SET_ADDRESSES = 152;

//KRUDiscountExcange
uint256 constant DISCOUNT_EXCHANGE_CAN_SET_VESTING_TYPE = 161;
uint256 constant DISCOUNT_EXCHANGE_CAN_SET_SIGNER = 162;
uint256 constant DISCOUNT_EXCHANGE_CAN_CLAIM_FOR = 163;
uint256 constant DISCOUNT_EXCHANGE_CAN_ISSUE_PURCHASE = 164;

//All contracts by all part

uint256 constant CONTRACT_MANAGEMENT = 0;

uint256 constant CONTRACT_KRU_SHOPS_PAYMENT_PROCCESOR = 2;
uint256 constant CONTRACT_KRU_SHOPS_POOL = 3;
uint256 constant CONTRACT_KRU_SHOPS_MANAGER = 4;

uint256 constant CONTRACT_APR_STAKE = 11;
uint256 constant CONTRACT_FUND_FORWARDER = 15;
uint256 constant CONTRACT_REFERRAL_TREE = 16;
uint256 constant CONTRACT_BONUS_DISTRIBUTOR = 20;

uint256 constant CONTRACT_UNISWAP_V2_PAIR = 23;
uint256 constant CONTRACT_UNISWAP_V2_ROUTER = 24;
uint256 constant CONTRACT_UNISWAP_V2_FACTORY = 25;

uint256 constant CONTRACT_WRAPPED_KRU = 26;

uint256 constant CONTRACT_KRU_SHOPS_TRESUARY = 100;




/** 
 *  SourceUnit: contracts\Bridge.sol
*/
            

pragma solidity 0.8.11;

/// @title IBridge
/// @author Applicature
/// @notice There is an interface for Bridge Smart Contract that provides transfering
/// coins/erc20 between different blockhains on base ethereum evm
/// @dev There are provided all events and function prototypes for Bridge SC
interface IBridge {
    /// @notice Types' enumeration of token
    /// @dev Types' enumeration of token
    enum TokenType {
        ERC20,
        ERC20_MINT_BURN,
        ERC20_MINT_BURN_V2
    }

    /// @notice Structured data type for creating  token info
    /// @dev Structured data type for creating  token info
    struct TokenCreateInfo {
        address token;
        bool needKYC;
        uint256 fee;
        TokenType tokenType;
    }

    /// @notice Structured data type for variables that store information about token
    /// @dev Structured data type for variables that store information about token
    struct TokenInfo {
        bool needKYC;
        uint256 fee;
        TokenType tokenType;
        uint256 liquidity;
        uint256 proposeFee;
        uint256 proposeTime;
    }

    /// @notice Generated when owner sets new address of withdrawer
    /// @param withdrawer Address of withdrawer
    event SetWithdrawer(address indexed withdrawer);

    /// @notice Emit when sender deposits some amount of tokens
    /// @dev Emit when sender transfers amount of tokens and withdraw fee
    /// @param sender Address of sender
    /// @param chainIdFrom Chain id from which tokens will be sent
    /// @param chainIdTo Chain id to which tokens will be sent
    /// @param token Address of token
    /// @param amount The amount of sent tokens
    /// @param recipient Address of recipient
    /// @param data Data to bytes to emit transaction
    event Deposit(
        address indexed sender,
        uint256 chainIdFrom,
        uint256 chainIdTo,
        address token,
        uint256 amount,
        address recipient,
        string data
    );

    /// @notice Emit when recipient withdraws sent tokens amount for recipient
    /// @dev Emit when recipient transfers sent tokens amount from other chain to recipient
    /// @param sender Address of sender
    /// @param chainIdFrom Chain id from which tokens will be sent
    /// @param chainIdTo Chain id to which tokens will be sent
    /// @param token Address of token
    /// @param amount The amount of sent tokens
    /// @param txFee Amount of transfered fee to BE address
    /// @param nonce Nonce of sender transaction
    event Withdraw(
        address indexed sender,
        uint256 chainIdFrom,
        uint256 chainIdTo,
        address token,
        uint256 amount,
        uint256 txFee,
        uint256 nonce
    );

    /// @notice Emit when recipient adds some liquidity amount to token
    /// @dev Emit when recipient adds some liquidity amount to token
    /// @param sender Address of recipient
    /// @param token Address of token
    /// @param amount Liquidity amount
    event AddLiquidity(address indexed sender, address indexed token, uint256 amount);

    /// @notice Emit when recipient removes some liquidity amount from token
    /// @dev Emit when recipient removes some liquidity amount from token
    /// @param sender Address of recipient
    /// @param token Address of token
    /// @param amount Removed amount
    event RemoveLiquidity(address indexed sender, address indexed token, uint256 amount);

    /// @notice Emit when owner adds supported token
    /// @dev Emit when owner adds new token info to supported tokens set
    /// @param token Supported token address
    /// @param info Token info
    /// @param isUpdate Bool whether it is update info
    event AddSuportedToken(address indexed token, TokenInfo info, bool isUpdate);

    /// @notice Emit when owner initializes supported token to chain
    /// @dev Emit when owner initializes supported token to chain
    /// @param token Supported token address
    /// @param chainId Id of supported chain
    /// @param isSupported Bool whether support is
    event SetSupportedTokenToChain(address indexed token, uint256 chainId, bool isSupported);

    /// @notice Emit when owner set chain as ETH
    /// @dev Emit when owner set chain as ETH
    /// @param chainId Chain id
    /// @param isETHChain Bool whether chain is ETH
    event SetIsETHChain(uint256 chainId, bool isETHChain);

    /// @notice Emit when owner removes supported token
    /// @dev Emit when owner removes supported token
    /// @param token Address of removed token
    event RemoveSupportedToken(address indexed token);

    /// @notice Emit when recipient withdraw tokens
    /// @dev Emit when recipient withdraw tokens
    /// @param from The address of recipient
    /// @param token Address of token
    /// @param amount Amount of tokens
    event LogWithdrawToken(address indexed from, address indexed token, uint256 amount);

    /// @notice Add some liquidity amount to token
    /// @dev Add some liquidity amount to token
    /// @param tokenAddress_ Address of token
    /// @param amount_ Liquidity amount
    function addLiquidity(address tokenAddress_, uint256 amount_) external payable;

    /// @notice Remove some liquidity amount from token
    /// @dev Remove some liquidity amount from token
    /// @param tokenAddress_ Address of token
    /// @param amount_ Liquidity amount
    /// @param deadline_ Deadline timestamp
    /// @param maxAvailAmount_ Maximum available liquidity amount
    /// @param nonce_ Nonce of sender transaction
    /// @param v_ Signature parameter
    /// @param r_ Signature parameter
    /// @param s_ Signature parameter
    function withdrawLiquidity(
        address tokenAddress_,
        uint256 amount_,
        uint256 deadline_,
        uint256 maxAvailAmount_,
        uint256 nonce_,
        uint8[] calldata v_,
        bytes32[] calldata r_,
        bytes32[] calldata s_
    ) external;

    /// @notice Deposit some amount of tokens
    /// @dev Transfer amount of tokens and withdraw fee
    /// @param chainIdTo_ Chain id to which tokens will be sent
    /// @param tokenAddress_ Address of token
    /// @param amount_ The amount of sent tokens
    /// @param data_ Data to bytes to emit transaction
    /// @param v_ Signature parameter
    /// @param r_ Signature parameter
    /// @param s_ Signature parameter
    function deposit(
        uint256 chainIdTo_,
        address tokenAddress_,
        uint256 amount_,
        address recipient_,
        string memory data_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external payable;

    /// @notice Set withdrawer address
    /// @dev Set withdrawer address
    /// @param withdrawer_ Withdrawer address
    function setWithdrawer(address withdrawer_) external;

    /// @notice Withdraw sent tokens amount for recipient
    /// @dev Transfer sent tokens amount from other chain to recipient
    /// @param reciver_ Address of recipient
    /// @param chainIdFrom_ Chain id from which tokens will be sent
    /// @param tokenAddress_ Address of token
    /// @param amount_ The amount of sent tokens
    /// @param nonce_ Nonce of sender transaction
    /// @param v_ Signature parameter
    /// @param r_ Signature parameter
    /// @param s_ Signature parameter
    function withdrawFor(
        address reciver_,
        uint256 chainIdFrom_,
        address tokenAddress_,
        uint256 amount_,
        uint256 nonce_,
        uint8[] calldata v_,
        bytes32[] calldata r_,
        bytes32[] calldata s_
    ) external;

    /// @notice Withdraw sent coins amount for recipient with cost recovery to sender
    /// @dev Transfer sent coins amount from other chain to recipient with cost recovery to sender
    /// @param reciver_ Address of recipient
    /// @param chainIdFrom_ Chain id from which coins will be sent
    /// @param amount_ The amount of sent coins
    /// @param nonce_ Nonce of sender transaction
    /// @param v_ Signature parameter
    /// @param r_ Signature parameter
    /// @param s_ Signature parameter
    function withdrawForWithCostRecovery(
        address reciver_,
        uint256 chainIdFrom_,
        uint256 amount_,
        uint256 nonce_,
        uint8[] calldata v_,
        bytes32[] calldata r_,
        bytes32[] calldata s_
    ) external;

    /// @notice Withdraw sent tokens amount for sender
    /// @dev Transfer sent tokens amount from other chain to sender
    /// @param chainIdFrom_ Chain id from which tokens will be sent
    /// @param tokenAddress_ Address of token
    /// @param amount_ The amount of sent tokens
    /// @param nonce_ Nonce of sender transaction
    /// @param v_ Signature parameter
    /// @param r_ Signature parameter
    /// @param s_ Signature parameter
    function withdraw(
        uint256 chainIdFrom_,
        address tokenAddress_,
        uint256 amount_,
        uint256 nonce_,
        uint8[] calldata v_,
        bytes32[] calldata r_,
        bytes32[] calldata s_
    ) external;

    /// @notice Get supported tokens
    /// @dev Get all items from supported tokens set
    /// @return list Address array of supported tokens
    function getSupportedTokens() external view returns (address[] memory list);
}




/** 
 *  SourceUnit: contracts\Bridge.sol
*/
            

pragma solidity 0.8.11;

/**
 * @dev Interface of FeeDistributor.
 */
interface IFeeDistributor {
    /**
     * @dev Distributes fee for the token
     */
    function distributeFee(address token_, uint256 amount_) external;
}




/** 
 *  SourceUnit: contracts\Bridge.sol
*/
            

pragma solidity 0.8.11;

////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Interface of the ERC20 standard
 * that allows token holders to mint and destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
interface IERC20Mintable is IERC20 {
    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     */
    function mint(address _to, uint256 _value) external;

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(address account, uint256 amount) external;

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) external;
}




/** 
 *  SourceUnit: contracts\Bridge.sol
*/
            

// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}




/** 
 *  SourceUnit: contracts\Bridge.sol
*/
            

// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

////import "../IERC20.sol";
////import "../../../utils/Address.sol";

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




/** 
 *  SourceUnit: contracts\Bridge.sol
*/
            

// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

////import "./ECDSA.sol";

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




/** 
 *  SourceUnit: contracts\Bridge.sol
*/
            

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

////import "../utils/Context.sol";

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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


/** 
 *  SourceUnit: contracts\Bridge.sol
*/


pragma solidity 0.8.11;
// SPDX-License-Identifier: MIT

////import "@openzeppelin/contracts/access/Ownable.sol";
////import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
////import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
////import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
////import "@openzeppelin/contracts/utils/Address.sol";
////import "./interfaces/IERC20Mintable.sol";
////import "./interfaces/IFeeDistributor.sol";
////import "./interfaces/IBridge.sol";
////import "./management/Constants.sol";

/// @title Bridge
/// @author Applicature
/// @dev This Smart Contract use for transfer coins/erc20 between different blockhains on base ethereum evm
contract Bridge is IBridge, EIP712, Ownable {
    using SafeERC20 for IERC20Mintable;
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address payable;

    /// @notice Store constant of fee propose time lockup
    /// @dev Store value of 1 hour
    /// @return Number of percentage 100
    uint256 public constant FEE_PROPOSE_TIME_LOCKUP = 1 hours;
    uint256 public constant MAX_INITIAL_PERCENTAGE = 1e20;
    address public constant NATIVE = address(0);

    /// @notice Store hash to withdraw
    /// @dev Store computed 256 bit keccak hash
    /// @return Computed 256 bit keccak hash
    bytes32 public constant CONTAINER_TYPEHASH =
        keccak256("Container(address sender,uint256 chainIdFrom,address token,uint256 amount,uint256 nonce)");

    /// @notice Store hash to deposit transaction
    /// @dev Store computed 256 bit keccak hash
    /// @return Computed 256 bit keccak hash
    bytes32 public constant CONTAINER_KYC_TYPEHASH = keccak256("KycContainer(address sender)");

    /// @notice Store hash to withdraw liquidity
    /// @dev Store computed 256 bit keccak hash
    /// @return Computed 256 bit keccak hash
    bytes32 public constant CONTAINER_LIQUIDITY_TYPEHASH =
        keccak256(
            "LiquidityContainer(address sender,address token,uint256 deadline,uint256 maxAvailAmount,uint256 nonce)"
        );

    /// @notice Store bools whether chains are ETH
    /// @dev Store bools whether chains are ETH
    /// @return Bool if chain id is ETH
    mapping(uint256 => bool) public isETHChain;

    /// @notice Store token info
    /// @dev Store token info with token address key
    /// return Token info
    mapping(address => TokenInfo) public tokensInfo;

    /// @notice Store bools whether chains with tokens are supported
    /// @dev Store bools whether chains with tokens are supported
    /// @return Bool if token on chain is supported
    mapping(uint256 => mapping(address => bool)) public supportedChainsId;

    /// @notice Store user liquidity by token
    /// @dev Store user liquidity by token
    /// @return User liquidity amount
    mapping(address => mapping(address => uint256)) public userLiquidity;

    /// @notice Store fee recipient address
    /// @dev Store fee recipient address that will get fee
    /// @return Address of fee recipient
    address payable public feeRecipient;

    /// @notice Store fee distributor address
    /// @dev Store fee distributor address that will distribute fee
    /// @return Address of fee distributor
    address public feeDistributor;

    /// @notice Store address of KYC signer
    /// @dev Store address of KYC signer
    /// @return KYC signer address
    address public kycSigner;

    /// @notice Store withdrawer
    /// @dev Store address of withdrawer
    /// @return Address of withdrawer
    address public withdrawer;

    /// @notice Store set of registered supported tokens
    /// @dev Store set of registered supported tokens
    EnumerableSet.AddressSet internal _supportedTokens;

    /// @notice Store set of registered signers
    /// @dev Store set of registered signers
    EnumerableSet.AddressSet internal _signers;

    /// @notice Store nonces of recipients
    /// @dev Store recipients' nonces to sign deposit transactions
    mapping(address => mapping(uint256 => bool)) internal _nonces;

    /// @notice Check if sender is withdrawer
    /// @dev Check if msg.sender of transaction is a withdrawer
    modifier canWithdrawForWithCostRecovery() {
        require(_msgSender() == withdrawer, ERROR_ACCESS_DENIED);
        _;
    }

    /// @notice Initialization
    /// @dev Initialize contract, register signers, add supported tokens
    /// @param signers_ Address array of signers
    /// @param tokenInfos_ Array of tokens info
    constructor(
        address withdrawer_,
        address[] memory signers_,
        TokenCreateInfo[] memory tokenInfos_
    ) EIP712("Bridge", "v1") {
        _setWithdrawer(withdrawer_);
        _addSigners(signers_);
        for (uint256 i; i < tokenInfos_.length; i++) {
            _addSuportedToken(tokenInfos_[i]);
        }
    }

    /// @notice Initialize supported token to chain
    /// @dev Initialize supported token to chain
    /// @param chainId_ Id of supported chain
    /// @param tokenAddress_ Supported token address
    /// @param value_ Bool whether support is
    function setSupportedChainToToken(
        uint256 chainId_,
        address tokenAddress_,
        bool value_
    ) external onlyOwner {
        supportedChainsId[chainId_][tokenAddress_] = value_;
        emit SetSupportedTokenToChain(tokenAddress_, chainId_, value_);
    }

    /// @notice Initialize whether chain is ETH
    /// @dev Initialize whether chain is ETH
    /// @param chainId_ Chain id
    /// @param value_ Bool whether ETH is
    function setIsETHChain(uint256 chainId_, bool value_) external onlyOwner {
        isETHChain[chainId_] = value_;
        emit SetIsETHChain(chainId_, value_);
    }

    /// @notice Add signers
    /// @dev Add signers to signers set
    /// @param signers_ Address array of signers
    function addSigners(address[] calldata signers_) external onlyOwner {
        _addSigners(signers_);
    }

    /// @notice Remove signers
    /// @dev Remove signers from signers set
    /// @param signers_ Address array of signers
    function removeSigners(address[] calldata signers_) external onlyOwner {
        for (uint256 i; i < signers_.length; i++) {
            require(_signers.remove(signers_[i]), ERROR_IS_NOT_EXISTS);
        }
        require(_signers.length() > 0, ERROR_SIGNERS_CANNOT_BE_EMPTY);
    }

    /// @notice Set fee recipient
    /// @dev Set address of fee recipient
    /// @param recipient_ Address of fee recipient
    function setFeeRecipient(address payable recipient_) external onlyOwner {
        require(recipient_ != address(0), ERROR_INVALID_ADDRESS);
        feeRecipient = recipient_;
    }

    /// @notice Set fee distributor
    /// @dev Set address of fee distributor
    /// @param distributor_ Address of fee distributor
    function setFeeDistributor(address distributor_) external onlyOwner {
        feeDistributor = distributor_;
    }

    /// @notice Set KYC signer
    /// @dev Set address of KYC signer
    /// @param kycSigner_ Address of KYC signer
    function setKycSigner(address kycSigner_) external onlyOwner {
        kycSigner = kycSigner_;
    }

    /// @notice Add supported token
    /// @dev Add new token info to supported tokens set
    /// @param info_ Token info
    function addSupportedToken(TokenCreateInfo calldata info_) external onlyOwner {
        _addSuportedToken(info_);
    }

    /// @notice Propose new fee percentage
    /// @dev Propose new fee percentage and time lockup it
    /// @param tokenAddress_ Address of token
    /// @param newFee_ Fee to token
    function proposeNewFee(address tokenAddress_, uint256 newFee_) external onlyOwner {
        TokenInfo storage info = tokensInfo[tokenAddress_];
        require(newFee_ < MAX_INITIAL_PERCENTAGE, ERROR_INCORRECT_FEE);
        info.proposeFee = newFee_;
        info.proposeTime = block.timestamp + FEE_PROPOSE_TIME_LOCKUP;
    }

    /// @notice Unlock new fee
    /// @dev Set new fee to token
    /// @param tokenAddress_ Address of token
    function applyPropose(address tokenAddress_) external onlyOwner {
        TokenInfo storage info = tokensInfo[tokenAddress_];
        require(block.timestamp > info.proposeTime, ERROR_LOCKED_PERIOD);
        info.fee = info.proposeFee;
    }

    /// @notice Remove supported token
    /// @dev Remove token info from supported tokens set
    /// @param tokenAddress_ Address of token that will be removed
    function removeSupportedToken(address tokenAddress_) external onlyOwner {
        require(_supportedTokens.remove(tokenAddress_), ERROR_IS_NOT_EXISTS);
        emit RemoveSupportedToken(tokenAddress_);
    }

    /// @notice Add some liquidity amount to token
    /// @dev Add some liquidity amount to token
    /// @param tokenAddress_ Address of token
    /// @param amount_ Liquidity amount
    function addLiquidity(address tokenAddress_, uint256 amount_) external payable override {
        uint256 amount = _depositRequire(tokenAddress_, amount_);
        if (!_isNative(tokenAddress_)) {
            IERC20Mintable(tokenAddress_).safeTransferFrom(_msgSender(), address(this), amount);
        }
        tokensInfo[tokenAddress_].liquidity += amount;
        userLiquidity[tokenAddress_][_msgSender()] += amount;
        emit AddLiquidity(_msgSender(), tokenAddress_, amount);
    }

    /// @notice Remove some liquidity amount from token
    /// @dev Remove some liquidity amount from token
    /// @param tokenAddress_ Address of token
    /// @param amount_ Liquidity amount
    /// @param deadline_ Deadline timestamp
    /// @param maxAvailAmount_ Maximum available liquidity amount
    /// @param nonce_ Nonce of sender transaction
    /// @param v_ Signature parameter
    /// @param r_ Signature parameter
    /// @param s_ Signature parameter
    function withdrawLiquidity(
        address tokenAddress_,
        uint256 amount_,
        uint256 deadline_,
        uint256 maxAvailAmount_,
        uint256 nonce_,
        uint8[] calldata v_,
        bytes32[] calldata r_,
        bytes32[] calldata s_
    ) external override {
        require(!_nonces[_msgSender()][nonce_], ERROR_INVALID_NONCE);
        require(block.timestamp < deadline_, ERROR_TIME_OUT);
        _isValidSigners(
            keccak256(
                abi.encode(
                    CONTAINER_LIQUIDITY_TYPEHASH,
                    _msgSender(),
                    tokenAddress_,
                    deadline_,
                    maxAvailAmount_,
                    nonce_
                )
            ),
            v_,
            r_,
            s_
        );
        _nonces[_msgSender()][nonce_] = true;
        {
            uint256 liquidityBalance = userLiquidity[tokenAddress_][_msgSender()];
            uint256 contractBalance = _isNative(tokenAddress_)
                ? address(this).balance
                : IERC20Mintable(tokenAddress_).balanceOf(address(this));
            uint256 availableAmount = liquidityBalance > contractBalance ? contractBalance : liquidityBalance;
            require(amount_ <= availableAmount && amount_ <= maxAvailAmount_ && amount_ != 0, ERROR_WRONG_AMOUNT);
        }
        tokensInfo[tokenAddress_].liquidity -= amount_;
        userLiquidity[tokenAddress_][_msgSender()] -= amount_;
        if (_isNative(tokenAddress_)) {
            payable(_msgSender()).sendValue(amount_);
        } else {
            IERC20Mintable(tokenAddress_).safeTransfer(_msgSender(), amount_);
        }
        emit RemoveLiquidity(_msgSender(), tokenAddress_, amount_);
    }

    /// @notice Deposit some amount of tokens
    /// @dev Transfer amount of tokens and withdraw fee
    /// @param chainIdTo_ Chain id to which tokens will be sent
    /// @param tokenAddress_ Address of token
    /// @param amount_ The amount of sent tokens
    /// @param data_ Data to bytes to emit transaction
    /// @param v_ Signature parameter
    /// @param r_ Signature parameter
    /// @param s_ Signature parameter
    function deposit(
        uint256 chainIdTo_,
        address tokenAddress_,
        uint256 amount_,
        address recipient_,
        string memory data_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external payable override {
        require(supportedChainsId[chainIdTo_][tokenAddress_], ERROR_CHAIN_NOT_SUPPORTED);
        if (isETHChain[chainIdTo_]) {
            require(recipient_ != address(0), ERROR_INVALID_ADDRESS);
        } else {
            require(bytes(data_).length != 0, ERROR_INCORRECT_DATA);
        }
        _isValidKYC(tokenAddress_, v_, r_, s_);
        uint256 amount = _depositRequire(tokenAddress_, amount_);
        uint256 feePercentage = tokensInfo[tokenAddress_].fee;
        if (feePercentage > 0) {
            uint256 fee = (amount * feePercentage) / MAX_INITIAL_PERCENTAGE;
            amount -= fee;
            _feeDistribute(tokenAddress_, fee);
        }
        _transferFrom(tokenAddress_, amount);
        emit Deposit(_msgSender(), block.chainid, chainIdTo_, tokenAddress_, amount, recipient_, data_);
    }

    /// @notice Set withdrawer address
    /// @dev Set withdrawer address
    /// @param withdrawer_ Withdrawer address
    function setWithdrawer(address withdrawer_) external override onlyOwner {
        _setWithdrawer(withdrawer_);
    }

    /// @notice Withdraw sent tokens amount for recipient
    /// @dev Transfer sent tokens amount from other chain to recipient
    /// @param reciver_ Address of recipient
    /// @param chainIdFrom_ Chain id from which tokens will be sent
    /// @param tokenAddress_ Address of token
    /// @param amount_ The amount of sent tokens
    /// @param nonce_ Nonce of sender transaction
    /// @param v_ Signature parameter
    /// @param r_ Signature parameter
    /// @param s_ Signature parameter
    function withdrawFor(
        address reciver_,
        uint256 chainIdFrom_,
        address tokenAddress_,
        uint256 amount_,
        uint256 nonce_,
        uint8[] calldata v_,
        bytes32[] calldata r_,
        bytes32[] calldata s_
    ) external override {
        _withdraw(reciver_, chainIdFrom_, tokenAddress_, amount_, false, nonce_, v_, r_, s_);
    }

    /// @notice Withdraw sent tokens amount for sender
    /// @dev Transfer sent tokens amount from other chain to sender
    /// @param chainIdFrom_ Chain id from which tokens will be sent
    /// @param tokenAddress_ Address of token
    /// @param amount_ The amount of sent tokens
    /// @param nonce_ Nonce of sender transaction
    /// @param v_ Signature parameter
    /// @param r_ Signature parameter
    /// @param s_ Signature parameter
    function withdraw(
        uint256 chainIdFrom_,
        address tokenAddress_,
        uint256 amount_,
        uint256 nonce_,
        uint8[] calldata v_,
        bytes32[] calldata r_,
        bytes32[] calldata s_
    ) external override {
        _withdraw(_msgSender(), chainIdFrom_, tokenAddress_, amount_, false, nonce_, v_, r_, s_);
    }

    /// @notice Withdraw sent coins amount for recipient with cost recovery to sender
    /// @dev Transfer sent coins amount from other chain to recipient with cost recovery to sender
    /// @param reciver_ Address of recipient
    /// @param chainIdFrom_ Chain id from which coins will be sent
    /// @param amount_ The amount of sent coins
    /// @param nonce_ Nonce of sender transaction
    /// @param v_ Signature parameter
    /// @param r_ Signature parameter
    /// @param s_ Signature parameter
    function withdrawForWithCostRecovery(
        address reciver_,
        uint256 chainIdFrom_,
        uint256 amount_,
        uint256 nonce_,
        uint8[] calldata v_,
        bytes32[] calldata r_,
        bytes32[] calldata s_
    ) external override canWithdrawForWithCostRecovery {
        _withdraw(reciver_, chainIdFrom_, NATIVE, amount_, true, nonce_, v_, r_, s_);
    }

    /// @notice Get supported tokens
    /// @dev Get all items from supported tokens set
    /// @return list Address array of supported tokens
    function getSupportedTokens() external view override returns (address[] memory list) {
        uint256 lastIndex = _supportedTokens.length();

        list = new address[](lastIndex);

        for (uint256 i; i < lastIndex; i++) {
            list[i] = _supportedTokens.at(i);
        }
    }

    /// @notice Get signers
    /// @dev Get all items from signers set
    /// @return list Address array of signers
    function getSignersAddress() external view onlyOwner returns (address[] memory list) {
        uint256 lastIndex = _signers.length();
        list = new address[](lastIndex);
        for (uint256 i; i < lastIndex; i++) {
            list[i] = _signers.at(i);
        }
    }

    /// @notice Define if token is supported
    /// @dev Define if token is in set
    /// @param tokenAddress_ Address of token that will be checked
    /// @return Bool whether token is supported
    function isTokenSupported(address tokenAddress_) public view returns (bool) {
        return _supportedTokens.contains(tokenAddress_);
    }

    /// @notice Set withdrawer address
    /// @dev Set withdrawer address
    /// @param withdrawer_ Withdrawer address
    function _setWithdrawer(address withdrawer_) internal {
        require(withdrawer_ != address(0), ERROR_INVALID_ADDRESS);
        withdrawer = withdrawer_;
        emit SetWithdrawer(withdrawer_);
    }

    /// @notice Withdraw sent tokens amount for recipient
    /// @dev Transfer sent tokens amount from other chain to recipient
    /// @param recipient_ Address of recipient
    /// @param chainIdFrom_ Chain id from which tokens will be sent
    /// @param tokenAddress_ Address of token
    /// @param amount_ The amount of sent tokens
    /// @param nonce_ Nonce of sender transaction
    function _withdraw(
        address recipient_,
        uint256 chainIdFrom_,
        address tokenAddress_,
        uint256 amount_,
        bool isRecovery_,
        uint256 nonce_,
        uint8[] calldata v_,
        bytes32[] calldata r_,
        bytes32[] calldata s_
    ) internal {
        uint256 gasBefore = gasleft();
        require(isTokenSupported(tokenAddress_), ERROR_TOKEN_NOT_SUPPORTED);
        require(!_nonces[recipient_][nonce_], ERROR_INVALID_NONCE);
        _isValidSigners(
            keccak256(abi.encode(CONTAINER_TYPEHASH, recipient_, chainIdFrom_, tokenAddress_, amount_, nonce_)),
            v_,
            r_,
            s_
        );

        _nonces[recipient_][nonce_] = true;

        uint256 txFee;
        if (_isNative(tokenAddress_)) {
            txFee = isRecovery_ ? tx.gasprice * (gasBefore - gasleft() + 53350) : 0;
            require(amount_ > txFee, ERROR_INSUFFICIENT_AMOUNT);
            amount_ -= txFee;
            payable(recipient_).sendValue(amount_);
            if (txFee > 0) payable(_msgSender()).sendValue(txFee);
        } else if (tokensInfo[tokenAddress_].tokenType == TokenType.ERC20) {
            IERC20Mintable(tokenAddress_).safeTransfer(recipient_, amount_);
        } else {
            IERC20Mintable(tokenAddress_).mint(recipient_, amount_);
        }
        emit Withdraw(recipient_, chainIdFrom_, block.chainid, tokenAddress_, amount_, txFee, nonce_);
    }

    /// @notice Distribute fee to fee recipient
    /// @dev Transfer fee to fee recipient
    /// @param tokenAddress_ Address of token
    function _feeDistribute(address tokenAddress_, uint256 fee_) internal {
        if (_isNative(tokenAddress_)) {
            feeRecipient.sendValue(fee_);
        } else {
            IERC20Mintable(tokenAddress_).safeTransferFrom(_msgSender(), feeRecipient, fee_);
        }
        if (feeDistributor != address(0)) {
            IFeeDistributor(feeDistributor).distributeFee(tokenAddress_, fee_);
        }
    }

    /// @notice Send tokens to contract
    /// @dev Transfer some token amount to this contract address
    /// @param tokenAddress_ Address of token
    /// @param amount_ Amount that should be sent
    function _transferFrom(address tokenAddress_, uint256 amount_) internal {
        TokenType tokenType = tokensInfo[tokenAddress_].tokenType;
        if (_isNative(tokenAddress_)) {
            return;
        } else if (tokenType == TokenType.ERC20) {
            IERC20Mintable(tokenAddress_).safeTransferFrom(_msgSender(), address(this), amount_);
        } else if (tokenType == TokenType.ERC20_MINT_BURN_V2) {
            IERC20Mintable(tokenAddress_).burnFrom(_msgSender(), amount_);
        } else {
            IERC20Mintable(tokenAddress_).burn(_msgSender(), amount_);
        }
    }

    /// @notice Add signers
    /// @dev Add signers to signers set
    /// @param signers_ Address array of signers
    function _addSigners(address[] memory signers_) internal {
        require(signers_.length > 0, ERROR_SIGNERS_CANNOT_BE_EMPTY);
        for (uint256 i; i < signers_.length; i++) {
            require(signers_[i] != address(0), ERROR_INVALID_ADDRESS);
            _signers.add(signers_[i]);
        }
    }

    /// @notice Add supported token
    /// @dev Add new token info to supported tokens set
    /// @param info_ Token info
    function _addSuportedToken(TokenCreateInfo memory info_) internal {
        TokenInfo storage info = tokensInfo[info_.token];
        bool isNew = _supportedTokens.add(info_.token);
        if (isNew) {
            require(info_.fee < MAX_INITIAL_PERCENTAGE, ERROR_INCORRECT_FEE);
            info.fee = info_.fee;
        }
        info.needKYC = info_.needKYC;
        info.tokenType = info_.tokenType;
        emit AddSuportedToken(info_.token, info, !isNew);
    }

    /// @notice Check if deposit amount is correct
    /// @dev Check if deposit amount is correct
    /// @param tokenAddress_ Address of token
    /// @param amount_ Amount of tokens
    /// @return Token or ETH amount
    function _depositRequire(address tokenAddress_, uint256 amount_) internal view returns (uint256) {
        require(isTokenSupported(tokenAddress_), ERROR_TOKEN_NOT_SUPPORTED);
        require(!(msg.value > 0 && amount_ > 0), ERROR_TWO_AMOUNTS_ENTERED);
        uint256 amount = _isNative(tokenAddress_) ? msg.value : amount_;
        require(amount > 0, ERROR_AMOUNT_IS_ZERO);
        return amount;
    }

    /// @notice Check if KYC is validate
    /// @dev Check if recipient is KYC
    /// @param tokenAddress_ Address of token
    /// @param v_ Signature parameter
    /// @param r_ Signature parameter
    /// @param s_ Signature parameter
    function _isValidKYC(
        address tokenAddress_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) internal view {
        if (tokensInfo[tokenAddress_].needKYC) {
            bytes32 structHash = keccak256(abi.encode(CONTAINER_KYC_TYPEHASH, _msgSender()));
            bytes32 hash = _hashTypedDataV4(structHash);
            address messageSigner = ECDSA.recover(hash, v_, r_, s_);
            require(messageSigner == kycSigner, ERROR_KYC_MISSING);
        }
    }

    /// @notice Check if signers is validate
    /// @dev Check if signers is validate
    /// @param hash_ Bytes hash of structure
    /// @param v_ Signature parameter
    /// @param r_ Signature parameter
    /// @param s_ Signature parameter
    function _isValidSigners(
        bytes32 hash_,
        uint8[] calldata v_,
        bytes32[] calldata r_,
        bytes32[] calldata s_
    ) internal view {
        bytes32 digest = _hashTypedDataV4(hash_);
        require(
            v_.length == r_.length && r_.length == s_.length && s_.length == _signers.length(),
            ERROR_DIFF_ARR_LENGTH
        );
        for (uint256 i; i < v_.length; i++) {
            address messageSigner = ECDSA.recover(digest, v_[i], r_[i], s_[i]);
            require(messageSigner == _signers.at(i), ERROR_INVALID_SIGNER);
        }
    }

    /// @notice Check if token is native
    /// @dev Check if token address is zero address
    /// @param tokenAddress_ Address of token
    /// @return Bool whether token is native
    function _isNative(address tokenAddress_) internal pure returns (bool) {
        return tokenAddress_ == NATIVE;
    }
}