/**
 *Submitted for verification at Etherscan.io on 2022-09-10
*/

/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

// Sigil Test Predicates Contract
//
//         0..0       
//        (~~~~) 
//       ( s__s )   
//       ^^ ~~ ^^    
//
// A Fragments DAO Collection

//*********
//Libraries
//*********

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

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

library LibDeactivateToken {
    struct DeactivateToken {
        uint256 proposalId;
    }

    // Hash for the EIP712 Schema
    //    bytes32 constant internal EIP712_DEACTIVATE_TOKEN_HASH = keccak256(abi.encodePacked(
    //        "DeactivateToken(",
    //        "uint256 proposalId",
    //        ")"
    //    ));
    bytes32 internal constant EIP712_DEACTIVATE_TOKEN_SCHEMA_HASH =
        0xe6c775d77ef8ec84277aad8c3f9e3fa051e3ca07ea28a40e99a1fdf5b8cc0709;

    /// @dev Calculates Keccak-256 hash of the deactivation.
    /// @param _deactivate The deactivate structure.
    /// @param _eip712DomainHash The hash of the EIP712 domain.
    /// @return deactivateHash Keccak-256 EIP712 hash of the deactivation.
    function getDeactivateTokenHash(DeactivateToken memory _deactivate, bytes32 _eip712DomainHash)
        internal
        pure
        returns (bytes32 deactivateHash)
    {
        deactivateHash = LibEIP712.hashEIP712Message(_eip712DomainHash, hashDeactivateToken(_deactivate));
        return deactivateHash;
    }

    /// @dev Calculates EIP712 hash of the deactivation.
    /// @param _deactivate The deactivate structure.
    /// @return result EIP712 hash of the deactivate.
    function hashDeactivateToken(DeactivateToken memory _deactivate) internal pure returns (bytes32 result) {
        // Assembly for more efficiently computing:
        bytes32 schemaHash = EIP712_DEACTIVATE_TOKEN_SCHEMA_HASH;

        assembly {
            // Assert deactivate offset (this is an internal error that should never be triggered)
            if lt(_deactivate, 32) {
                invalid()
            }

            // Calculate memory addresses that will be swapped out before hashing
            let pos1 := sub(_deactivate, 32)

            // Backup
            let temp1 := mload(pos1)

            // Hash in place
            mstore(pos1, schemaHash)
            result := keccak256(pos1, 64)

            // Restore
            mstore(pos1, temp1)
        }
        return result;
    }
}

library LibEIP712 {
    // Hash of the EIP712 Domain Separator Schema
    // keccak256(abi.encodePacked(
    //     "EIP712Domain(",
    //     "string name,",
    //     "string version,",
    //     "uint256 chainId,",
    //     "address verifyingContract",
    //     ")"
    // ))
    bytes32 internal constant _EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH =
        0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    /// @dev Calculates a EIP712 domain separator.
    /// @param name The EIP712 domain name.
    /// @param version The EIP712 domain version.
    /// @param verifyingContract The EIP712 verifying contract.
    /// @return result EIP712 domain separator.
    function hashEIP712Domain(
        string memory name,
        string memory version,
        uint256 chainId,
        address verifyingContract
    ) internal pure returns (bytes32 result) {
        bytes32 schemaHash = _EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH;

        // Assembly for more efficient computing:
        // keccak256(abi.encodePacked(
        //     _EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH,
        //     keccak256(bytes(name)),
        //     keccak256(bytes(version)),
        //     chainId,
        //     uint256(verifyingContract)
        // ))

        assembly {
            // Calculate hashes of dynamic data
            let nameHash := keccak256(add(name, 32), mload(name))
            let versionHash := keccak256(add(version, 32), mload(version))

            // Load free memory pointer
            let memPtr := mload(64)

            // Store params in memory
            mstore(memPtr, schemaHash)
            mstore(add(memPtr, 32), nameHash)
            mstore(add(memPtr, 64), versionHash)
            mstore(add(memPtr, 96), chainId)
            mstore(add(memPtr, 128), verifyingContract)

            // Compute hash
            result := keccak256(memPtr, 160)
        }
        return result;
    }

    /// @dev Calculates EIP712 encoding for a hash struct with a given domain hash.
    /// @param eip712DomainHash Hash of the domain domain separator data, computed
    ///                         with getDomainHash().
    /// @param hashStruct The EIP712 hash struct.
    /// @return result EIP712 hash applied to the given EIP712 Domain.
    function hashEIP712Message(bytes32 eip712DomainHash, bytes32 hashStruct) internal pure returns (bytes32 result) {
        // Assembly for more efficient computing:
        // keccak256(abi.encodePacked(
        //     EIP191_HEADER,
        //     EIP712_DOMAIN_HASH,
        //     hashStruct
        // ));

        assembly {
            // Load free memory pointer
            let memPtr := mload(64)

            mstore(memPtr, 0x1901000000000000000000000000000000000000000000000000000000000000) // EIP191 header
            mstore(add(memPtr, 2), eip712DomainHash) // EIP712 domain hash
            mstore(add(memPtr, 34), hashStruct) // Hash of struct

            // Compute hash
            result := keccak256(memPtr, 66)
        }
        return result;
    }
}

library LibSignature {
    // Exclusive upper limit on ECDSA signatures 'R' values. The valid range is
    // given by fig (282) of the yellow paper.
    uint256 private constant ECDSA_SIGNATURE_R_LIMIT =
        uint256(0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141);

    // Exclusive upper limit on ECDSA signatures 'S' values. The valid range is
    // given by fig (283) of the yellow paper.
    uint256 private constant ECDSA_SIGNATURE_S_LIMIT = ECDSA_SIGNATURE_R_LIMIT / 2 + 1;

    /**
     * @dev Retrieve the signer of a signature. Throws if the signature can't be
     *      validated.
     * @param _hash The hash that was signed.
     * @param _signature The signature.
     * @return The recovered signer address.
     */
    function getSignerOfHash(bytes32 _hash, bytes memory _signature) internal pure returns (address) {
        require(_signature.length == 65, "LibSignature: Signature length must be 65 bytes.");

        // Get the v, r, and s values from the signature.
        uint8 v = uint8(_signature[0]);
        bytes32 r;
        bytes32 s;
        assembly {
            r := mload(add(_signature, 0x21))
            s := mload(add(_signature, 0x41))
        }

        // Enforce the signature malleability restrictions.
        validateSignatureMalleabilityLimits(v, r, s);

        // Recover the signature without pre-hashing.
        address recovered = ecrecover(_hash, v, r, s);

        // `recovered` can be null if the signature values are out of range.
        require(recovered != address(0), "LibSignature: Bad signature data.");
        return recovered;
    }

    /**
     * @notice Validates the malleability limits of an ECDSA signature.
     *
     *         Context:
     *
     *         EIP-2 still allows signature malleability for ecrecover(). Remove
     *         this possibility and make the signature unique. Appendix F in the
     *         Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf),
     *         defines the valid range for r in (282): 0 < r < secp256k1n, the
     *         valid range for s in (283): 0 < s < secp256k1n ÷ 2 + 1, and for v
     *         in (284): v ∈ {27, 28}. Most signatures from current libraries
     *         generate a unique signature with an s-value in the lower half order.
     *
     *         If your library generates malleable signatures, such as s-values
     *         in the upper range, calculate a new s-value with
     *         0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1
     *         and flip v from 27 to 28 or vice versa. If your library also
     *         generates signatures with 0/1 for v instead 27/28, add 27 to v to
     *         accept these malleable signatures as well.
     *
     * @param _v The v value of the signature.
     * @param _r The r value of the signature.
     * @param _s The s value of the signature.
     */
    function validateSignatureMalleabilityLimits(
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) private pure {
        // Ensure the r, s, and v are within malleability limits. Appendix F of
        // the Yellow Paper stipulates that all three values should be checked.
        require(uint256(_r) < ECDSA_SIGNATURE_R_LIMIT, "LibSignature: r parameter of signature is invalid.");
        require(uint256(_s) < ECDSA_SIGNATURE_S_LIMIT, "LibSignature: s parameter of signature is invalid.");
        require(_v == 27 || _v == 28, "LibSignature: v parameter of signature is invalid.");
    }
}

library LibClone {
    function createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }

    function isClone(address target, address query) internal view returns (bool result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
            mstore(add(clone, 0xa), targetBytes)
            mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

            let other := add(clone, 0x40)
            extcodecopy(query, other, 0, 0x2d)
            result := and(eq(mload(clone), mload(other)), eq(mload(add(clone, 0xd)), mload(add(other, 0xd))))
        }
    }
}

library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}

//**********
//Interfaces
//**********

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

interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IOwnable {
    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;

    function owner() external view returns (address);
}

interface IHashes is IERC721Enumerable {
    function deactivateTokens(
        address _owner,
        uint256 _proposalId,
        bytes memory _signature
    ) external returns (uint256);

    function deactivated(uint256 _tokenId) external view returns (bool);

    function activationFee() external view returns (uint256);

    function verify(
        uint256 _tokenId,
        address _minter,
        string memory _phrase
    ) external view returns (bool);

    function getHash(uint256 _tokenId) external view returns (bytes32);

    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint256);
}

interface IERC2981Royalties {
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _value - the sale price of the NFT asset specified by _tokenId
    /// @return _receiver - address of who should be sent the royalty payment
    /// @return _royaltyAmount - the royalty payment amount for value sale price
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        returns (address _receiver, uint256 _royaltyAmount);
}

interface ICollectionNFTMintFeePredicate {
    function getTokenMintFee(uint256 _tokenId, uint256 _hashesTokenId) external view returns (uint256);
}

interface ICollectionNFTEligibilityPredicate {
    function isTokenEligibleToMint(uint256 _tokenId, uint256 _hashesTokenId) external view returns (bool);
}

interface ICollectionNFTTokenURIPredicate {
    function getTokenURI(uint256 _tokenId, uint256 _hashesTokenId, bytes32 _hashesHash) external view returns (string memory);
}

interface ICollectionNFTCloneableV1 {
    function mint(uint256 _hashesTokenId) external payable;

    function burn(uint256 _tokenId) external;

    function completeSignatureBlock() external;

    function setBaseTokenURI(string memory _baseTokenURI) external;

    function setRoyaltyBps(uint16 _royaltyBps) external;

    function transferCreator(address _creatorAddress) external;

    function setSignatureBlockAddress(address _signatureBlockAddress) external;

    function withdraw() external;
}

interface ICollectionCloneable {
    function initialize(
        IHashes _hashesToken,
        address _factoryMaintainerAddress,
        address _createCollectionCaller,
        bytes memory _initializationData
    ) external;
}

interface ICollection {
    function verifyEcosystemSettings(bytes memory _settings) external pure returns (bool);
}

interface ICollectionFactory {
    function addImplementationAddress(
        bytes32 _hashedEcosystemName,
        address _implementationAddress,
        bool cloneable
    ) external;

    function createCollection(address _implementationAddress, bytes memory _initializationData) external;

    function setFactoryMaintainerAddress(address _factoryMaintainerAddress) external;

    function removeImplementationAddresses(
        bytes32[] memory _hashedEcosystemNames,
        address[] memory _implementationAddresses,
        uint256[] memory _indexes
    ) external;

    function removeCollection(
        address _implementationAddress,
        address _collectionAddress,
        uint256 _index
    ) external;

    function createEcosystemSettings(string memory _ecosystemName, bytes memory _settings) external;

    function updateEcosystemSettings(bytes32 _hashedEcosystemName, bytes memory _settings) external;

    function getEcosystemSettings(bytes32 _hashedEcosystemName, uint64 _blockNumber)
        external
        view
        returns (bytes memory);

    function getEcosystems() external view returns (bytes32[] memory);

    function getEcosystems(uint256 _start, uint256 _end) external view returns (bytes32[] memory);

    function getCollections(address _implementationAddress) external view returns (address[] memory);

    function getCollections(
        address _implementationAddress,
        uint256 _start,
        uint256 _end
    ) external view returns (address[] memory);

    function getImplementationAddresses(bytes32 _hashedEcosystemName) external view returns (address[] memory);

    function getImplementationAddresses(
        bytes32 _hashedEcosystemName,
        uint256 _start,
        uint256 _end
    ) external view returns (address[] memory);
}

interface ICollectionNFTCloneableV1Sigil {

    struct TokenIdEntry {
        bool exists;
        uint128 tokenId;
    }

    function mint(uint256 _hashesTokenId) external payable;

    function burn(uint256 _tokenId) external;

    function completeSignatureBlock() external;

    function setBaseTokenURI(string memory _baseTokenURI) external;

    function setRoyaltyBps(uint16 _royaltyBps) external;

    function transferCreator(address _creatorAddress) external;

    function setSignatureBlockAddress(address _signatureBlockAddress) external;

    function withdraw() external;

    function hashesIdToCollectionTokenIdMapping(uint256 hashesId) external view returns (TokenIdEntry memory);

    function nonce() external view returns (uint256);
}

interface IAirdropperV1 {

    function mintAndAirdropHashesERC721sToRecipients(
        ICollectionNFTCloneableV1 _collection,
        address[] memory _recipients
    ) external payable;

    function withdraw() external;
}

//******************************
//Abstract/Preliminary Contracts
//******************************

abstract contract ReentrancyGuard {
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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

abstract contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

abstract contract OwnableCloneable is Context {
    bool ownableInitialized;
    address private _owner;

    modifier ownershipInitialized() {
        require(ownableInitialized, "OwnableCloneable: hasn't been initialized yet.");
        _;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the initialize caller as the initial owner.
     */
    function initializeOwnership(address initialOwner) public virtual {
        require(!ownableInitialized, "OwnableCloneable: already initialized.");
        ownableInitialized = true;
        _setOwner(initialOwner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual ownershipInitialized returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "OwnableCloneable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual ownershipInitialized onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual ownershipInitialized onlyOwner {
        require(newOwner != address(0), "OwnableCloneable: new owner is the zero address");
        _setOwner(newOwner);
    }

    // This is set to internal so overriden versions of renounce/transfer ownership
    // can also be carried out by DAO address.
    function _setOwner(address newOwner) internal ownershipInitialized {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Hashes is IHashes, ERC721Enumerable, ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    /// @notice version for this Hashes contract
    string public constant version = "1"; // solhint-disable-line const-name-snakecase

    /// @notice activationFee The fee to activate (and the payment to deactivate)
    ///         a governance class hash that wasn't reserved. This is the initial
    ///         minting fee.
    uint256 public immutable override activationFee;

    /// @notice locked The lock status of the contract. Once locked, the contract
    ///         will never be unlocked. Locking prevents the transfer of ownership.
    bool public locked;

    /// @notice mintFee Minting fee.
    uint256 public mintFee;

    /// @notice reservedAmount Number of Hashes reserved.
    uint256 public reservedAmount;

    /// @notice governanceCap Number of Hashes qualifying for governance.
    uint256 public governanceCap;

    /// @notice nonce Monotonically-increasing number (token ID).
    uint256 public nonce;

    /// @notice baseTokenURI The base of the token URI.
    string public baseTokenURI;

    bytes internal constant TABLE = "0123456789abcdef";

    /// @notice A checkpoint for marking vote count from given block.
    struct Checkpoint {
        uint32 id;
        uint256 votes;
    }

    /// @notice deactivated A record of tokens that have been deactivated by token ID.
    mapping(uint256 => bool) public deactivated;

    /// @notice lastProposalIds A record of the last recorded proposal IDs by an address.
    mapping(address => uint256) public lastProposalIds;

    /// @notice checkpoints A record of votes checkpoints for each account, by index.
    mapping(address => mapping(uint256 => Checkpoint)) public checkpoints;

    /// @notice numCheckpoints The number of checkpoints for each account.
    mapping(address => uint256) public numCheckpoints;

    mapping(uint256 => bytes32) nonceToHash;

    mapping(uint256 => bool) redeemed;

    /// @notice Emitted when governance class tokens are activated.
    event Activated(address indexed owner, uint256 indexed tokenId);

    /// @notice Emitted when governance class tokens are deactivated.
    event Deactivated(address indexed owner, uint256 indexed tokenId, uint256 proposalId);

    /// @notice Emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice Emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /// @notice Emitted when a Hash was generated/minted
    event Generated(address artist, uint256 tokenId, string phrase);

    /// @notice Emitted when a reserved Hash was redemed
    event Redeemed(address artist, uint256 tokenId, string phrase);

    // @notice Emitted when the base token URI is updated
    event BaseTokenURISet(string baseTokenURI);

    // @notice Emitted when the mint fee is updated
    event MintFeeSet(uint256 indexed fee);

    /**
     * @notice Constructor for the Hashes token. Initializes the state.
     * @param _mintFee Minting fee
     * @param _reservedAmount Reserved number of Hashes
     * @param _governanceCap Number of hashes qualifying for governance
     * @param _baseTokenURI The initial base token URI.
     */
    constructor(uint256 _mintFee, uint256 _reservedAmount, uint256 _governanceCap, string memory _baseTokenURI) ERC721("Hashes", "HASH") Ownable() {
        reservedAmount = _reservedAmount;
        activationFee = _mintFee;
        mintFee = _mintFee;
        governanceCap = _governanceCap;
        for (uint i = 0; i < reservedAmount; i++) {
            // Compute and save the hash (temporary till redemption)
            nonceToHash[nonce] = keccak256(abi.encodePacked(nonce, _msgSender()));
            // Mint the token
            _safeMint(_msgSender(), nonce++);
        }
        baseTokenURI = _baseTokenURI;
    }

    /**
     * @notice Allows the owner to lock ownership. This prevents ownership from
     *         ever being transferred in the future.
     */
    function lock() external onlyOwner {
        require(!locked, "Hashes: can't lock twice.");
        locked = true;
    }

    /**
     * @dev An overridden version of `transferOwnership` that checks to see if
     *      ownership is locked.
     */
    function transferOwnership(address _newOwner) public override onlyOwner {
        require(!locked, "Hashes: can't transfer ownership when locked.");
        super.transferOwnership(_newOwner);
    }

    /**
     * @notice Allows governance to update the base token URI.
     * @param _baseTokenURI The new base token URI.
     */
    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
        emit BaseTokenURISet(_baseTokenURI);
    }

    /**
     * @notice Allows governance to update the fee to mint a hash.
     * @param _mintFee The fee to mint a hash.
     */
    function setMintFee(uint256 _mintFee) external onlyOwner {
        mintFee = _mintFee;
        emit MintFeeSet(_mintFee);
    }

    /**
     * @notice Allows a token ID owner to activate their governance class token.
     * @return activationCount The amount of tokens that were activated.
     */
    function activateTokens() external payable nonReentrant returns (uint256 activationCount) {
        // Activate as many tokens as possible.
        for (uint256 i = 0; i < balanceOf(msg.sender); i++) {
            uint256 tokenId = tokenOfOwnerByIndex(msg.sender, i);
            if (tokenId >= reservedAmount && tokenId < governanceCap && deactivated[tokenId]) {
                deactivated[tokenId] = false;
                activationCount++;

                // Emit an activation event.
                emit Activated(msg.sender, tokenId);
            }
        }

        // Increase the sender's governance power.
        _moveDelegates(address(0), msg.sender, activationCount);

        // Ensure that sufficient ether was provided to pay the activation fee.
        // If a sufficient amount was provided, send it to the owner. Refund the
        // sender with the remaining amount of ether.
        bool sent;
        uint256 requiredFee = activationFee.mul(activationCount);
        require(msg.value >= requiredFee, "Hashes: must pay adequate fee to activate hash.");
        (sent,) = owner().call{value: requiredFee}("");
        require(sent, "Hashes: couldn't pay owner the activation fee.");
        if (msg.value > requiredFee) {
            (sent,) = msg.sender.call{value: msg.value - requiredFee}("");
            require(sent, "Hashes: couldn't refund sender with the remaining ether.");
        }

        return activationCount;
    }

    /**
     * @notice Allows the owner to process a series of deactivations from governance
     *         class tokens owned by a single holder. The owner is responsible for
     *         handling payment once deactivations have been finalized.
     * @param _tokenOwner The owner of the hashes to deactivate.
     * @param _proposalId The proposal ID that this deactivation is related to.
     * @param _signature The signature to prove the owner wants to deactivate
     *        their holdings.
     * @return deactivationCount The amount of tokens that were deactivated.
     */
    function deactivateTokens(address _tokenOwner, uint256 _proposalId, bytes memory _signature) external override nonReentrant onlyOwner returns (uint256 deactivationCount) {
        // Ensure that the token owner has approved the deactivation.
        require(lastProposalIds[_tokenOwner] < _proposalId, "Hashes: can't re-use an old proposal ID.");
        lastProposalIds[_tokenOwner] = _proposalId;
        bytes32 eip712DomainHash = LibEIP712.hashEIP712Domain(name(), version, getChainId(), address(this));
        bytes32 deactivateHash =
            LibDeactivateToken.getDeactivateTokenHash(
                LibDeactivateToken.DeactivateToken({ proposalId: _proposalId }),
                eip712DomainHash
            );
        require(LibSignature.getSignerOfHash(deactivateHash, _signature) == _tokenOwner, "Hashes: The token owner must approve the deactivation.");

        // Deactivate as many tokens as possible.
        for (uint256 i = 0; i < balanceOf(_tokenOwner); i++) {
            uint256 tokenId = tokenOfOwnerByIndex(_tokenOwner, i);
            if (tokenId >= reservedAmount && tokenId < governanceCap && !deactivated[tokenId]) {
                deactivated[tokenId] = true;
                deactivationCount++;

                // Emit a deactivation event.
                emit Deactivated(_tokenOwner, tokenId, _proposalId);
            }
        }

        // Decrease the voter's governance power.
        _moveDelegates(_tokenOwner, address(0), deactivationCount);

        return deactivationCount;
    }

    /**
     * @notice Generate a new Hashes token provided a phrase. This
     *         function generates/saves a hash, mints the token, and
     *         transfers the minting fee to the HashesDAO when
     *         applicable.
     * @param _phrase Phrase used as part of hashing inputs.
     */
    function generate(string memory _phrase) external nonReentrant payable {
        // Ensure that the hash can be generated.
        require(bytes(_phrase).length > 0, "Hashes: Can't generate hash with the empty string.");

        // Ensure token minter is passing in a sufficient minting fee.
        require(msg.value >= mintFee, "Hashes: Must pass sufficient mint fee.");

        // Compute and save the hash
        nonceToHash[nonce] = keccak256(abi.encodePacked(nonce, _msgSender(), _phrase));

        // Mint the token
        _safeMint(_msgSender(), nonce++);

        uint256 mintFeePaid;
        if (mintFee > 0) {
            // If the minting fee is non-zero

            // Send the fee to HashesDAO.
            (bool sent,) = owner().call{value: mintFee}("");
            require(sent, "Hashes: failed to send ETH to HashesDAO");

            // Set the mintFeePaid to the current minting fee
            mintFeePaid = mintFee;
        }

        if (msg.value > mintFeePaid) {
            // If minter passed ETH value greater than the minting
            // fee paid/computed above

            // Refund the remaining ether balance to the sender. Since there are no
            // other payable functions, this remainder will always be the senders.
            (bool sent,) = _msgSender().call{value: msg.value - mintFeePaid}("");
            require(sent, "Hashes: failed to refund ETH.");
        }

        if (nonce == governanceCap) {
            // Set mint fee to 0 now that governance cap has been hit.
            // The minting fee can only be increased from here via
            // governance.
            mintFee = 0;
        }

        emit Generated(_msgSender(), nonce - 1, _phrase);
    }

    /**
     * @notice Redeem a reserved Hashes token. Any may redeem a
     *         reserved Hashes token so long as they hold the token
     *         and this particular token hasn't been redeemed yet.
     *         Redemption lets an owner of a reserved token to
     *         modify the phrase as they choose.
     * @param _tokenId Token ID.
     * @param _phrase Phrase used as part of hashing inputs.
     */
    function redeem(uint256 _tokenId, string memory _phrase) external nonReentrant {
        // Ensure redeemer is the token owner.
        require(_msgSender() == ownerOf(_tokenId), "Hashes: must be owner.");

        // Ensure that redeemed token is a reserved token.
        require(_tokenId < reservedAmount, "Hashes: must be a reserved token.");

        // Ensure the token hasn't been redeemed before.
        require(!redeemed[_tokenId], "Hashes: already redeemed.");

        // Mark the token as redeemed.
        redeemed[_tokenId] = true;

        // Update the hash.
        nonceToHash[_tokenId] = keccak256(abi.encodePacked(_tokenId, _msgSender(), _phrase));

        emit Redeemed(_msgSender(), _tokenId, _phrase);
    }

    /**
     * @notice Verify the validity of a Hash token given its inputs.
     * @param _tokenId Token ID for Hash token.
     * @param _minter Minter's (or redeemer's) Ethereum address.
     * @param _phrase Phrase used at time of generation/redemption.
     * @return Whether the Hash token's hash saved given this token ID
     *         matches the inputs provided.
     */
    function verify(uint256 _tokenId, address _minter, string memory _phrase) external override view returns (bool) {
        // Enforce the normal hashes regularity conditions before verifying.
        if (_tokenId >= nonce || _minter == address(0) || bytes(_phrase).length == 0) {
            return false;
        }

        // Verify the provided phrase.
        return nonceToHash[_tokenId] == keccak256(abi.encodePacked(_tokenId, _minter, _phrase));
    }

    /**
     * @notice Retrieve token URI given a token ID.
     * @param _tokenId Token ID.
     * @return Token URI string.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        // Ensure that the token ID is valid and that the hash isn't empty.
        require(_tokenId < nonce, "Hashes: Can't provide a token URI for a non-existent hash.");

        // Return the base token URI concatenated with the token ID.
        return string(abi.encodePacked(baseTokenURI, _toDecimalString(_tokenId)));
    }

    /**
     * @notice Retrieve hash given a token ID.
     * @param _tokenId Token ID.
     * @return Hash associated with this token ID.
     */
    function getHash(uint256 _tokenId) external override view returns (bytes32) {
        return nonceToHash[_tokenId];
    }

    /**
     * @notice Gets the current votes balance.
     * @param _account The address to get votes balance.
     * @return The number of current votes.
     */
    function getCurrentVotes(address _account) external view returns (uint256) {
        uint256 numCheckpointsAccount = numCheckpoints[_account];
        return numCheckpointsAccount > 0 ? checkpoints[_account][numCheckpointsAccount - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param _account The address of the account to check
     * @param _blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address _account, uint256 _blockNumber) external override view returns (uint256) {
        require(_blockNumber < block.number, "Hashes: block not yet determined.");

        uint256 numCheckpointsAccount = numCheckpoints[_account];
        if (numCheckpointsAccount == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[_account][numCheckpointsAccount - 1].id <= _blockNumber) {
            return checkpoints[_account][numCheckpointsAccount - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[_account][0].id > _blockNumber) {
            return 0;
        }

        // Perform binary search to find the most recent token holdings
        // leading to a measure of voting power
        uint256 lower = 0;
        uint256 upper = numCheckpointsAccount - 1;
        while (upper > lower) {
            // ceil, avoiding overflow
            uint256 center = upper - (upper - lower) / 2;
            Checkpoint memory cp = checkpoints[_account][center];
            if (cp.id == _blockNumber) {
                return cp.votes;
            } else if (cp.id < _blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[_account][lower].votes;
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (tokenId < governanceCap && !deactivated[tokenId]) {
            // If Hashes token is in the governance class, transfer voting rights
            // from `from` address to `to` address.
            _moveDelegates(from, to, 1);
        }
    }

    function _moveDelegates(
        address _initDel,
        address _finDel,
        uint256 _amount
    ) internal {
        if (_initDel != _finDel && _amount > 0) {
            // Initial delegated address is different than final
            // delegated address and nonzero number of votes moved
            if (_initDel != address(0)) {
                // If we are not minting a new token

                uint256 initDelNum = numCheckpoints[_initDel];

                // Retrieve and compute the old and new initial delegate
                // address' votes
                uint256 initDelOld = initDelNum > 0 ? checkpoints[_initDel][initDelNum - 1].votes : 0;
                uint256 initDelNew = initDelOld.sub(_amount);
                _writeCheckpoint(_initDel, initDelOld, initDelNew);
            }

            if (_finDel != address(0)) {
                // If we are not burning a token
                uint256 finDelNum = numCheckpoints[_finDel];

                // Retrieve and compute the old and new final delegate
                // address' votes
                uint256 finDelOld = finDelNum > 0 ? checkpoints[_finDel][finDelNum - 1].votes : 0;
                uint256 finDelNew = finDelOld.add(_amount);
                _writeCheckpoint(_finDel, finDelOld, finDelNew);
            }
        }
    }

    function _writeCheckpoint(
        address _delegatee,
        uint256 _oldVotes,
        uint256 _newVotes
    ) internal {
        uint32 blockNumber = safe32(block.number, "Hashes: exceeds 32 bits.");
        uint256 delNum = numCheckpoints[_delegatee];
        if (delNum > 0 && checkpoints[_delegatee][delNum - 1].id == blockNumber) {
            // If latest checkpoint is current block, edit in place
            checkpoints[_delegatee][delNum - 1].votes = _newVotes;
        } else {
            // Create a new id, vote pair
            checkpoints[_delegatee][delNum] = Checkpoint({ id: blockNumber, votes: _newVotes });
            numCheckpoints[_delegatee] = delNum.add(1);
        }

        emit DelegateVotesChanged(_delegatee, _oldVotes, _newVotes);
    }

    function getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

    function _toDecimalString(uint256 _value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (_value == 0) {
            return "0";
        }
        uint256 temp = _value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (_value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(_value % 10)));
            _value /= 10;
        }
        return string(buffer);
    }

    function _toHexString(uint256 _value) internal pure returns (string memory) {
        bytes memory buffer = new bytes(66);
        buffer[0] = bytes1("0");
        buffer[1] = bytes1("x");
        for (uint256 i = 0; i < 64; i++) {
            buffer[65 - i] = bytes1(TABLE[_value % 16]);
            _value /= 16;
        }
        return string(buffer);
    }

    function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }
}

contract CollectionNFTCloneableV1 is
    ICollection,
    ICollectionCloneable,
    ICollectionNFTCloneableV1,
    OwnableCloneable,
    ERC721Enumerable,
    IERC2981Royalties,
    ReentrancyGuard
{
    using SafeMath for uint16;
    using SafeMath for uint64;
    using SafeMath for uint128;
    using SafeMath for uint256;

    bool _initialized;

    /// @notice A structure for storing a token ID in a map.
    struct TokenIdEntry {
        bool exists;
        uint128 tokenId;
    }

    /// @notice A structure for decoding and storing data from the factory initializer
    struct InitializerSettings {
        string tokenName;
        string tokenSymbol;
        string baseTokenURI;
        uint256 cap;
        ICollectionNFTEligibilityPredicate mintEligibilityPredicateContract;
        ICollectionNFTMintFeePredicate mintFeePredicateContract;
        uint16 royaltyBps;
        address signatureBlockAddress;
    }

    /// @notice nonce Monotonically-increasing number (token ID).
    uint256 public nonce;

    /// @notice cap The supply cap for this token. Set to 0 for unlimited.
    uint256 public cap;

    /// @notice baseTokenURI The base token URI for this token.
    string public baseTokenURI;

    /// @notice tokenName The name of the ERC-721 token.
    string private tokenName;

    /// @notice tokenSymbol The symbol of the ERC-721 token.
    string private tokenSymbol;

    /// @notice creatorAddress The address of the collection creator.
    address public creatorAddress;

    /// @notice signatureBlockAddress An optional address which (when set) will cause all tokens to be
    ///         minted from this address and then immediately transfered to the mint message sender.
    address public signatureBlockAddress;

    // Interface for contract which contains a function isTokenEligibleToMint(tokenId, hashesTokenId)
    // used for determining mint eligibility for a Hashes token.
    ICollectionNFTEligibilityPredicate public mintEligibilityPredicateContract;

    // Interface for contract which contains a function getTokenMintFee(tokenId, hashesTokenId)
    // used for determining the mint fee for a Hashes token.
    ICollectionNFTMintFeePredicate public mintFeePredicateContract;

    /// @notice hashesIdToCollectionTokenIdMapping Mapping of Hashes ID to collection token ID.
    mapping(uint256 => TokenIdEntry) public hashesIdToCollectionTokenIdMapping;

    /// @notice royaltyBps The sales royalty amount (in hundredths of a percent).
    uint16 public royaltyBps;

    uint16 private _hashesDAOMintFeePercent;

    uint16 private _hashesDAORoyaltyFeePercent;

    uint16 private _maximumCollectionRoyaltyPercent;

    /// @notice isSignatureBlockCompleted Whether the signature block address has interacted with this
    ///         contract to verify their support of this contract and establish provenance.
    bool public isSignatureBlockCompleted;

    IHashes hashesToken;

    /// @notice CollectionInitialized Emitted when a Collection is initialized.
    event CollectionInitialized(
        string tokenName,
        string tokenSymbol,
        string baseTokenURI,
        uint256 cap,
        address mintEligibilityPredicateAddress,
        address mintFeePredicateAddress,
        uint16 royaltyBps,
        address signatureBlockAddress,
        uint64 indexed initializationBlock
    );

    /// @notice Minted Emitted when a Hashes Collection is minted.
    event Minted(address indexed minter, uint256 indexed tokenId, uint256 indexed hashesTokenId);

    /// @notice BaseTokenURISet Emitted when the base token URI is updated.
    event BaseTokenURISet(string baseTokenURI);

    /// @notice Withdraw Emitted when a withdraw event is triggered.
    event Withdraw(uint256 indexed creatorAmount, uint256 indexed hashesDAOAmount);

    /// @notice CreatorTransferred Emitted when the creator address is transferred.
    event CreatorTransferred(address indexed previousCreator, address indexed newCreator);

    /// @notice RoyaltyBpsSet Emitted when the royalty bps is set.
    event RoyaltyBpsSet(uint16 royaltyBps);

    /// @notice Burned Emitted when a token is burned.
    event Burned(address indexed burner, uint256 indexed tokenId);

    /// @notice SignatureBlockCompleted Emitted when the signature block is completed.
    event SignatureBlockCompleted(address indexed signatureBlockAddress);

    /// @notice SignatureBlockAddressSet Emitted when the signature block address is set.
    event SignatureBlockAddressSet(address indexed signatureBlockAddress);

    modifier initialized() {
        require(_initialized, "CollectionNFTCloneableV1: hasn't been initialized yet.");
        _;
    }

    modifier onlyOwnerOrHashesDAO() {
        require(
            _msgSender() == owner() || _msgSender() == IOwnable(address(hashesToken)).owner(),
            "CollectionNFTCloneableV1: must be contract owner or HashesDAO"
        );
        _;
    }

    modifier onlyCreator() {
        require(_msgSender() == creatorAddress, "CollectionNFTCloneableV1: must be contract creator");
        _;
    }

    /**
     * @notice Constructor for the cloneable Hashes Collection contract. The ERC-721 token
     *         name and symbol aren't used since they are provided in the initialize function.
     */
    constructor() ERC721("TOKEN_NAME_PLACEHOLDER", "TOKEN_SYMBOL_PLACEHOLDER") {}

    receive() external payable {}

    /**
     * @notice This function is used by the Factory to verify the format of ecosystem settings
     * @param _settings ABI encoded ecosystem settings data. This expected encoding for
     *        ecosystem name 'NFT_v1' is the following:
     *
     *        'uint16' hashesDAOMintFeePercent - The percentage of mint fees owable to HashesDAO.
     *        'uint16' hashesDAORoyaltyFeePercent - The percentage of royalties owable to HashesDAO. This will
     *                 be the percentage of the royalties percent set by the creator.
     *        'uint16' maximumCollectionRoyaltyPercent - The highest allowable royalty percentage
     *                 settable by creators for cloned instances of this contract.
     * @return The boolean result of the validation.
     */
    function verifyEcosystemSettings(bytes memory _settings) external pure override returns (bool) {
        (
            uint16 _settingsHashesDAOMintFeePercent,
            uint16 _settingsHashesDAORoyaltyFeePercent,
            uint16 _settingsMaximumCollectionRoyaltyPercent
        ) = abi.decode(_settings, (uint16, uint16, uint16));

        return
            _settingsHashesDAOMintFeePercent <= 10000 &&
            _settingsHashesDAORoyaltyFeePercent <= 10000 &&
            _settingsMaximumCollectionRoyaltyPercent <= 10000;
    }

    /**
     * @notice This function initializes a cloneable implementation contract.
     * @param _hashesToken The Hashes NFT contract address.
     * @param _factoryMaintainerAddress The address of the current factory maintainer
     *        which will be the Owner role of this collection.
     * @param _createCollectionCaller The address which has called createCollection on the factory.
     *        This will be the Creator role of this collection.
     * @param _initializationData ABI encoded initialization data. This expected encoding is a struct
     *        with the following properties:
     *
     *        'string' tokenName - The name of the resulting ERC-721 token.
     *        'string' tokenSymbol - The symbol of the resulting ERC-721 token.
     *        'string' baseTokenURI - The initial base token URI of the resulting ERC-721 token.
     *        'uint256' cap - The maximum token supply of the resulting ERC-721 token. Set 0 for no limit.
     *        'address' mintEligibilityPredicateContract - The address of a contract which contains a
     *                  function isTokenEligibleToMint(uint256 tokenId, uint256 hashesTokenId) used to
     *                  determine whether the chosen Hashes token ID is eligible for minting. Contracts
     *                  which define this logic should implement the interface ICollectionNFTEligibilityPredicate.
     *        'address' mintFeePredicateContract - The address of a contract which contains a function
     *                  getTokenMintFee(tokenId, hashesTokenId) used to determine the mint fee for the
     *                  chosen Hashes token ID. Contracts which define this logic should implement the
     *                  interface ICollectionNFTMintFeePredicate.
     *        'uint16' royaltyBps - The sales royalty that should be collected. A percentage of this
     *                 will be allocated for the HashesDAO to withdraw.
     *        'address' signatureBlockAddress - An optional address which can be used to establish
     *                  creator provenance. When set, the specified address (could be the artist for example)
     *                  can call completeSignatureBlock to establish provenance and sign off on the contract
     *                  values. To skip using this mechanism, set the value of this field to the 0x0 address.
     */
    function initialize(
        IHashes _hashesToken,
        address _factoryMaintainerAddress,
        address _createCollectionCaller,
        bytes memory _initializationData
    ) external override {
        require(!_initialized, "CollectionNFTCloneableV1: already inititialized.");

        initializeOwnership(_factoryMaintainerAddress);
        creatorAddress = _createCollectionCaller;

        // Use this struct workaround to get around Stack Too Deep issues
        InitializerSettings memory _initializerSettings;
        (_initializerSettings) = abi.decode(_initializationData, (InitializerSettings));
        tokenName = _initializerSettings.tokenName;
        tokenSymbol = _initializerSettings.tokenSymbol;
        baseTokenURI = _initializerSettings.baseTokenURI;
        cap = _initializerSettings.cap;
        mintEligibilityPredicateContract = _initializerSettings.mintEligibilityPredicateContract;
        mintFeePredicateContract = _initializerSettings.mintFeePredicateContract;
        royaltyBps = _initializerSettings.royaltyBps;
        signatureBlockAddress = _initializerSettings.signatureBlockAddress;

        uint64 _initializationBlock = safe64(block.number, "CollectionNFTCloneableV1: exceeds 64 bits.");
        bytes memory settingsBytes = ICollectionFactory(_msgSender()).getEcosystemSettings(
            keccak256(abi.encodePacked("NFT_v1")),
            _initializationBlock
        );

        (_hashesDAOMintFeePercent, _hashesDAORoyaltyFeePercent, _maximumCollectionRoyaltyPercent) = abi.decode(
            settingsBytes,
            (uint16, uint16, uint16)
        );

        require(
            royaltyBps <= _maximumCollectionRoyaltyPercent,
            "CollectionNFTCloneableV1: royalty percentage must be less than or equal to maximum allowed setting"
        );

        _initialized = true;

        hashesToken = _hashesToken;

        emit CollectionInitialized(
            tokenName,
            tokenSymbol,
            baseTokenURI,
            cap,
            address(mintEligibilityPredicateContract),
            address(mintFeePredicateContract),
            royaltyBps,
            signatureBlockAddress,
            _initializationBlock
        );
    }

    /**
     * @notice The function used to mint instances of this Hashes Collection ERC-721 token.
     *         Minting requires passing in a specific Hashes token id which is owned by the minter.
     *         Each Hashes token id may only be used to mint once towards a specific collection.
     *         The minting eligibility and fee structure are determined per Hashes token id
     *         by the Hashes Collection owner through predicate functions. The Hashes DAO will receive
     *         a minting fee percentage of each mint, unless a DAO hash was used to mint.
     * @param _hashesTokenId The Hashes token Id being used to mint.
     */
    function mint(uint256 _hashesTokenId) external payable override initialized nonReentrant {
        require(cap == 0 || nonce < cap, "CollectionNFTCloneableV1: supply cap has been reached");
        require(
            _msgSender() == hashesToken.ownerOf(_hashesTokenId),
            "CollectionNFTCloneableV1: must be owner of supplied hashes token ID to mint"
        );
        require(
            !hashesIdToCollectionTokenIdMapping[_hashesTokenId].exists,
            "CollectionNFTCloneableV1: supplied token ID has already been used to mint with this collection"
        );

        // get mint eligibility through static call
        bool isHashesTokenIdEligibleToMint = mintEligibilityPredicateContract.isTokenEligibleToMint(
            nonce,
            _hashesTokenId
        );
        require(isHashesTokenIdEligibleToMint, "CollectionNFTCloneableV1: supplied token ID is ineligible to mint");

        // get mint fee through static call
        uint256 currentMintFee = mintFeePredicateContract.getTokenMintFee(nonce, _hashesTokenId);
        require(msg.value >= currentMintFee, "CollectionNFTCloneableV1: must pass sufficient mint fee.");

        hashesIdToCollectionTokenIdMapping[_hashesTokenId] = TokenIdEntry({
            exists: true,
            tokenId: safe128(nonce, "CollectionNFTCloneableV1: exceeds 128 bits.")
        });

        uint256 feeForHashesDAO = (currentMintFee.mul(_hashesDAOMintFeePercent)) / 10000;
        uint256 authorFee = currentMintFee.sub(feeForHashesDAO);

        uint256 mintFeePaid;
        if (authorFee > 0) {
            // If the minting fee is non-zero
            mintFeePaid = mintFeePaid.add(authorFee);

            (bool sent, ) = creatorAddress.call{ value: authorFee }("");
            require(sent, "CollectionNFTCloneableV1: failed to send ETH to creator address");
        }

        // Only apply the minting tax for non-DAO hashes (tokenID >= 1000 or deactivated DAO tokens)
        if (feeForHashesDAO > 0 && (_hashesTokenId >= 1000 || hashesToken.deactivated(_hashesTokenId))) {
            // If the hashes DAO minting fee is non-zero

            // Send minting tax to HashesDAO
            (bool sent, ) = IOwnable(address(hashesToken)).owner().call{ value: feeForHashesDAO }("");
            require(sent, "CollectionNFTCloneableV1: failed to send ETH to HashesDAO");

            mintFeePaid = mintFeePaid.add(feeForHashesDAO);
        }

        if (msg.value > mintFeePaid) {
            // If minter passed ETH value greater than the minting
            // fee paid/computed above

            // Refund the remaining ether balance to the sender. Since there are no
            // other payable functions, this remainder will always be the senders.
            (bool sent, ) = _msgSender().call{ value: msg.value.sub(mintFeePaid) }("");
            require(sent, "CollectionNFTCloneableV1: failed to refund ETH.");
        }

        _safeMint(_msgSender(), nonce++);

        emit Minted(_msgSender(), nonce - 1, _hashesTokenId);
    }

    /**
     * @notice The function allows the token owner or approved address to burn the token.
     * @param _tokenId The token Id to be burned.
     */
    function burn(uint256 _tokenId) external override initialized {
        require(
            _isApprovedOrOwner(_msgSender(), _tokenId),
            "CollectionNFTCloneableV1: caller is not owner nor approved."
        );
        _burn(_tokenId);

        emit Burned(_msgSender(), _tokenId);
    }

    /**
     * @notice The signatureBlockAddress can call this function to establish provenance and effectively
     *         sign off on the contract. Can be useful in cases where the creator address is different
     *         from the artist address.
     */
    function completeSignatureBlock() external override initialized {
        require(!isSignatureBlockCompleted, "CollectionNFTCloneableV1: signature block has already been completed");
        require(
            signatureBlockAddress != address(0),
            "CollectionNFTCloneableV1: signature block address has not been set."
        );
        require(
            _msgSender() == signatureBlockAddress,
            "CollectionNFTCloneableV1: only signature block address can complete signature block"
        );
        isSignatureBlockCompleted = true;

        emit SignatureBlockCompleted(signatureBlockAddress);
    }

    /// @inheritdoc IERC2981Royalties
    function royaltyInfo(uint256, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        // Send royalties to this contract address. Note: this will only work for
        // marketplaces which implement the ERC2981 royalty standard. Off-chain
        // configuration may be required for certain marketplaces.
        return (address(this), (value.mul(royaltyBps)).div(10000));
    }

    /**
     * @notice The function used to renounce contract ownership. This can be performed
     *         by either the Owner or HashesDAO. This departs slightly from the traditional
     *         implementation where only the Owner has this permission. HashesDAO may
     *         need to perform this actions in the case of the factory maintainer changing,
     *         getting lost, or being taken over by a bad actor.
     */
    function renounceOwnership() public override ownershipInitialized onlyOwnerOrHashesDAO {
        _setOwner(address(0));
    }

    /**
     * @notice The function used to transfer contract ownership. This can be performed by
     *         either the owner or HashesDAO. This departs slightly from the traditional
     *         implementation where only the Owner has this permission. HashesDAO may
     *         need to perform this actions in the case of the factory maintainer changing,
     *         getting lost, or being taken over by a bad actor.
     * @param newOwner The new owner address.
     */
    function transferOwnership(address newOwner) public override ownershipInitialized onlyOwnerOrHashesDAO {
        require(newOwner != address(0), "CollectionNFTCloneableV1: new owner is the zero address");
        _setOwner(newOwner);
    }

    /**
     * @notice The function used to set the base token URI. Only collection creator may call.
     * @param _baseTokenURI The base token URI.
     */
    function setBaseTokenURI(string memory _baseTokenURI) external override initialized onlyCreator {
        baseTokenURI = _baseTokenURI;
        emit BaseTokenURISet(_baseTokenURI);
    }

    /**
     * @notice The function used to set the sales royalty bps. Only collection creator may call.
     * @param _royaltyBps The sales royalty percent in hundredths of a percent.
     */
    function setRoyaltyBps(uint16 _royaltyBps) external override initialized onlyCreator {
        require(
            _royaltyBps <= _maximumCollectionRoyaltyPercent,
            "CollectionNFTCloneableV1: royalty percentage must be less than or equal to maximum allowed setting"
        );
        royaltyBps = _royaltyBps;
        emit RoyaltyBpsSet(_royaltyBps);
    }

    /**
     * @notice The function used to transfer the creator address. Only collection creator may call.
     *         This is especially important since this concerns withdrawl permissions.
     * @param _creatorAddress The new creator address.
     */
    function transferCreator(address _creatorAddress) external override initialized onlyCreator {
        address oldCreator = creatorAddress;
        creatorAddress = _creatorAddress;
        emit CreatorTransferred(oldCreator, _creatorAddress);
    }

    function setSignatureBlockAddress(address _signatureBlockAddress) external override initialized onlyCreator {
        require(!isSignatureBlockCompleted, "CollectionNFTCloneableV1: signature block has already been completed");
        signatureBlockAddress = _signatureBlockAddress;
        emit SignatureBlockAddressSet(_signatureBlockAddress);
    }

    /**
     * @notice The function used to withdraw funds to the Collection creator and HashesDAO addresses.
     *         The balance of the contract is equal to the royalties and gifts owed to the creator and HashesDAO.
     */
    function withdraw() external override initialized {
        // The contract balance is equal to the royalties or gifts which need to be allocated
        // to both the creator and HashesDAO.
        uint256 _contractBalance = address(this).balance;

        // The amount owed to the DAO will be the total royalties times the royalty
        // fee percent value (in bps).
        uint256 _daoRoyaltiesOwed = (_contractBalance.mul(_hashesDAORoyaltyFeePercent)).div(10000);

        // The amount owed to the creator will then be the total balance of the contract minus the DAO
        // royalties owed.
        uint256 _creatorRoyaltiesOwed = _contractBalance.sub(_daoRoyaltiesOwed);

        if (_creatorRoyaltiesOwed > 0) {
            (bool sent, ) = creatorAddress.call{ value: _creatorRoyaltiesOwed }("");
            require(sent, "CollectionNFTCloneableV1: failed to send ETH to creator address");
        }

        if (_daoRoyaltiesOwed > 0) {
            (bool sent, ) = IOwnable(address(hashesToken)).owner().call{ value: _daoRoyaltiesOwed }("");
            require(sent, "CollectionNFTCloneableV1: failed to send ETH to HashesDAO");
        }

        emit Withdraw(_creatorRoyaltiesOwed, _daoRoyaltiesOwed);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
        return interfaceId == type(IERC2981Royalties).interfaceId || ERC721Enumerable.supportsInterface(interfaceId);
    }

    /**
     * @notice The function used to get the Hashes Collection token URI.
     * @param _tokenId The Hashes Collection token Id.
     */
    function tokenURI(uint256 _tokenId) public view override initialized returns (string memory) {
        // Ensure that the token ID is valid and that the hash isn't empty.
        require(_tokenId < nonce, "CollectionNFTCloneableV1: Can't provide a token URI for a non-existent collection.");

        // Return the base token URI concatenated with the token ID.
        return string(abi.encodePacked(baseTokenURI, _toDecimalString(_tokenId)));
    }

    /**
     * @notice The function used to get the name of the Hashes Collection token
     */
    function name() public view override initialized returns (string memory) {
        return tokenName;
    }

    /**
     * @notice The function used to get the symbol of the Hashes Collection token
     */
    function symbol() public view override initialized returns (string memory) {
        return tokenSymbol;
    }

    function _toDecimalString(uint256 _value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (_value == 0) {
            return "0";
        }
        uint256 temp = _value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (_value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(_value % 10)));
            _value /= 10;
        }
        return string(buffer);
    }

    function safe64(uint256 n, string memory errorMessage) internal pure returns (uint64) {
        require(n < 2**64, errorMessage);
        return uint64(n);
    }

    function safe128(uint256 n, string memory errorMessage) internal pure returns (uint128) {
        require(n < 2**128, errorMessage);
        return uint128(n);
    }
}

/**
 * @title CollectionFactory
 * @author DEX Labs
 * @notice This contract is the registry for Hashes Collections.
 */
contract CollectionFactory is ICollectionFactory, Ownable, ReentrancyGuard {
    /// @notice A checkpoint for ecosystem settings values. Settings are ABI encoded bytes
    ///         to provide the most flexibility towards various implementation contracts.
    struct SettingsCheckpoint {
        uint64 id;
        bytes settings;
    }

    /// @notice A structure for storing the contract addresses of collection instances.
    struct CollectionContracts {
        bool exists;
        bool cloneable;
        address[] contractAddresses;
    }

    IHashes hashesToken;

    /// @notice collections A mapping of implementation addresses to a struct which
    ///         contains an array of the cloned collections for that implementation.
    mapping(address => CollectionContracts) public collections;

    /// @notice ecosystems An array of the hashed ecosystem names which correspond to
    ///         a settings format which can be used by multiple implementation contracts.
    bytes32[] public ecosystems;

    /// @notice ecosystemSettings A mapping of hashed ecosystem names to an array of
    ///         settings checkpoints. Settings checkpoints contain ABI encoded data
    ///         which can be decoded in implementation addresses that consume them.
    mapping(bytes32 => SettingsCheckpoint[]) public ecosystemSettings;

    /// @notice implementationAddresses A mapping of hashed ecosystem names to an array
    ///         of the implementation addresses for that ecosystem.
    mapping(bytes32 => address[]) public implementationAddresses;

    /// @notice factoryMaintainerAddress An address which has some distinct maintenance abilities. These
    ///         include the ability to remove implementation addresses or collection instances, as well as
    ///         transfer this role to another address. Implementation addresses can choose to use this address
    ///         for certain roles since it is passed through to the initialize function upon creating
    ///         a cloned collection.
    address public factoryMaintainerAddress;

    /// @notice ImplementationAddressAdded Emitted when an implementation address is added.
    event ImplementationAddressAdded(address indexed implementationAddress, bool indexed cloneable);

    /// @notice CollectionCreated Emitted when a Collection is created.
    event CollectionCreated(
        address indexed implementationAddress,
        address indexed collectionAddress,
        address indexed creator
    );

    /// @notice FactoryMaintainerAddressSet Emitted when the factory maintainer address is set.
    event FactoryMaintainerAddressSet(address indexed factoryMaintainerAddress);

    /// @notice ImplementationAddressesRemoved Emitted when implementation addresses are removed.
    event ImplementationAddressesRemoved(address[] implementationAddresses);

    /// @notice CollectionAddressRemoved Emitted when a cloned collection contract address is removed.
    event CollectionAddressRemoved(address indexed implementationAddress, address indexed collectionAddress);

    /// @notice EcosystemSettingsCreated Emitted when ecosystem settings are created.
    event EcosystemSettingsCreated(string ecosystemName, bytes32 indexed hashedEcosystemName, bytes settings);

    /// @notice EcosystemSettingsUpdated Emitted when ecosystem settings are updated.
    event EcosystemSettingsUpdated(bytes32 indexed hashedEcosystemName, bytes settings);

    modifier onlyOwnerOrFactoryMaintainer() {
        require(
            _msgSender() == factoryMaintainerAddress || _msgSender() == owner(),
            "CollectionFactory: must be either factory maintainer or owner"
        );
        _;
    }

    /**
     * @notice Constructor for the Collection Factory.
     */
    constructor(IHashes _hashesToken) {
        // initially set the factoryMaintainerAddress to be the deployer, though this can transfered
        factoryMaintainerAddress = _msgSender();
        hashesToken = _hashesToken;

        // make HashesDAO the owner of this Factory contract
        transferOwnership(IOwnable(address(hashesToken)).owner());
    }

    /**
     * @notice This function adds an implementation address.
     * @param _hashedEcosystemName The ecosystem which this implementation address will reference.
     * @param _implementationAddress The address of the Collection contract.
     * @param _cloneable Whether this implementation address is cloneable.
     */
    function addImplementationAddress(
        bytes32 _hashedEcosystemName,
        address _implementationAddress,
        bool _cloneable
    ) external override {
        require(ecosystemSettings[_hashedEcosystemName].length > 0, "CollectionFactory: ecosystem doesn't exist");
        CollectionContracts storage collection = collections[_implementationAddress];
        require(!collection.exists, "CollectionFactory: implementation address already exists");
        require(_implementationAddress != address(0), "CollectionFactory: implementation address cannot be 0 address");

        uint64 blockNumber = safe64(block.number, "CollectionFactory: exceeds 64 bits.");
        require(
            ICollection(_implementationAddress).verifyEcosystemSettings(
                getCheckpointedSettings(ecosystemSettings[_hashedEcosystemName], blockNumber)
            ),
            "CollectionFactory: implementation address doesn't properly validate ecosystem settings"
        );

        collection.exists = true;
        collection.cloneable = _cloneable;

        implementationAddresses[_hashedEcosystemName].push(_implementationAddress);

        emit ImplementationAddressAdded(_implementationAddress, _cloneable);
    }

    /**
     * @notice This function clones a Hashes Collection implementation contract.
     * @param _implementationAddress The address of the cloneable implementation contract.
     * @param _initializationData The abi encoded initialization data which is consumable
     *        by the implementation contract in its initialize function.
     */
    function createCollection(address _implementationAddress, bytes memory _initializationData)
        external
        override
        nonReentrant
    {
        CollectionContracts storage collection = collections[_implementationAddress];
        require(collection.exists, "CollectionFactory: implementation address not found.");
        require(collection.cloneable, "CollectionFactory: implementation address is not cloneable.");

        ICollectionCloneable clonedCollection = ICollectionCloneable(LibClone.createClone(_implementationAddress));
        collection.contractAddresses.push(address(clonedCollection));

        clonedCollection.initialize(hashesToken, factoryMaintainerAddress, _msgSender(), _initializationData);

        emit CollectionCreated(_implementationAddress, address(clonedCollection), _msgSender());
    }

    /**
     * @notice This function sets the factory maintainer address.
     * @param _factoryMaintainerAddress The address of the factory maintainer.
     */
    function setFactoryMaintainerAddress(address _factoryMaintainerAddress)
        external
        override
        onlyOwnerOrFactoryMaintainer
    {
        factoryMaintainerAddress = _factoryMaintainerAddress;
        emit FactoryMaintainerAddressSet(_factoryMaintainerAddress);
    }

    /**
     * @notice This function removes implementation addresses from the factory.
     * @param _hashedEcosystemNames The ecosystems which these implementation addresses reference.
     * @param _implementationAddressesToRemove The implementation addresses to remove: either cloneable
     *        implementation addresses or a standalone contracts.
     * @param _indexes The array indexes to be removed. Must be monotonically increasing and match the items
     *        in the other two arrays. This array is provided to reduce the cost of removal.
     */
    function removeImplementationAddresses(
        bytes32[] memory _hashedEcosystemNames,
        address[] memory _implementationAddressesToRemove,
        uint256[] memory _indexes
    ) external override onlyOwnerOrFactoryMaintainer {
        require(
            _hashedEcosystemNames.length == _implementationAddressesToRemove.length &&
                _hashedEcosystemNames.length == _indexes.length,
            "CollectionFactory: arrays provided must be the same length"
        );

        // set this to max int to start so first less-than comparison is always true
        uint256 _previousIndex = 2**256 - 1;

        // iterate through items in reverse order
        for (uint256 i = 0; i < _indexes.length; i++) {
            require(
                _indexes[_indexes.length - 1 - i] < _previousIndex,
                "CollectionFactory: arrays must be ordered before processing."
            );
            _previousIndex = _indexes[_indexes.length - 1 - i];

            bytes32 _hashedEcosystemName = _hashedEcosystemNames[_indexes.length - 1 - i];
            address _implementationAddress = _implementationAddressesToRemove[_indexes.length - 1 - i];
            uint256 _currentIndex = _indexes[_indexes.length - 1 - i];

            require(ecosystemSettings[_hashedEcosystemName].length > 0, "CollectionFactory: ecosystem doesn't exist");
            require(collections[_implementationAddress].exists, "CollectionFactory: implementation address not found.");
            address[] storage _implementationAddresses = implementationAddresses[_hashedEcosystemName];
            require(_currentIndex < _implementationAddresses.length, "CollectionFactory: array index out of bounds.");
            require(
                _implementationAddresses[_currentIndex] == _implementationAddress,
                "CollectionFactory: element at array index not equal to implementation address."
            );

            // remove the implementation address from the mapping
            delete collections[_implementationAddress];

            // swap the last element of the array for the one we're removing
            _implementationAddresses[_currentIndex] = _implementationAddresses[_implementationAddresses.length - 1];
            _implementationAddresses.pop();
        }

        emit ImplementationAddressesRemoved(_implementationAddressesToRemove);
    }

    /**
     * @notice This function removes a cloned collection address from the factory.
     * @param _implementationAddress The implementation address of the cloneable contract.
     * @param _collectionAddress The cloned collection address to be removed.
     * @param _index The array index to be removed. This is provided to reduce the cost of removal.
     */
    function removeCollection(
        address _implementationAddress,
        address _collectionAddress,
        uint256 _index
    ) external override onlyOwnerOrFactoryMaintainer {
        CollectionContracts storage collection = collections[_implementationAddress];
        require(collection.exists, "CollectionFactory: implementation address not found.");
        require(_index < collection.contractAddresses.length, "CollectionFactory: array index out of bounds.");
        require(
            collection.contractAddresses[_index] == _collectionAddress,
            "CollectionFactory: element at array index not equal to collection address."
        );

        // swap the last element of the array for the one we're removing
        collection.contractAddresses[_index] = collection.contractAddresses[collection.contractAddresses.length - 1];
        collection.contractAddresses.pop();

        emit CollectionAddressRemoved(_implementationAddress, _collectionAddress);
    }

    /**
     * @notice This function creates a new ecosystem setting key in the mapping along with
     *         the initial ABI encoded settings value to be used for that key. The factory maintainer
     *         can create a new ecosystem setting to allow for efficient bootstrapping of a new
     *         ecosystem, but only HashesDAO can update an existing ecosystem.
     * @param _ecosystemName The name of the ecosystem.
     * @param _settings The ABI encoded settings data which can be decoded by implementation
     *        contracts which consume this ecosystem.
     */
    function createEcosystemSettings(string memory _ecosystemName, bytes memory _settings)
        external
        override
        onlyOwnerOrFactoryMaintainer
    {
        bytes32 hashedEcosystemName = keccak256(abi.encodePacked(_ecosystemName));
        require(
            ecosystemSettings[hashedEcosystemName].length == 0,
            "CollectionFactory: ecosystem settings for this name already exist"
        );

        uint64 blockNumber = safe64(block.number, "CollectionFactory: exceeds 64 bits.");
        ecosystemSettings[hashedEcosystemName].push(SettingsCheckpoint({ id: blockNumber, settings: _settings }));

        ecosystems.push(hashedEcosystemName);

        emit EcosystemSettingsCreated(_ecosystemName, hashedEcosystemName, _settings);
    }

    /**
     * @notice This function updates an ecosystem setting which means a new checkpoint is
     *         added to the array of settings checkpoints for that ecosystem. Only HashesDAO
     *         can call this function since these are likely to be more established ecosystems
     *         which have more impact.
     * @param _hashedEcosystemName The hashed name of the ecosystem.
     * @param _settings The ABI encoded settings data which can be decoded by implementation
     *        contracts which consume this ecosystem.
     */
    function updateEcosystemSettings(bytes32 _hashedEcosystemName, bytes memory _settings) external override onlyOwner {
        require(ecosystemSettings[_hashedEcosystemName].length > 0, "CollectionFactory: ecosystem settings not found");
        require(
            implementationAddresses[_hashedEcosystemName].length > 0,
            "CollectionFactory: no implementation addresses for this ecosystem"
        );

        ICollection firstImplementationAddress = ICollection(implementationAddresses[_hashedEcosystemName][0]);
        require(
            firstImplementationAddress.verifyEcosystemSettings(_settings),
            "CollectionFactory: invalid ecosystem settings according to first implementation contract"
        );

        uint64 blockNumber = safe64(block.number, "CollectionFactory: exceeds 64 bits.");
        ecosystemSettings[_hashedEcosystemName].push(SettingsCheckpoint({ id: blockNumber, settings: _settings }));

        emit EcosystemSettingsUpdated(_hashedEcosystemName, _settings);
    }

    /**
     * @notice This function gets the ecosystem settings from a particular ecosystem checkpoint.
     * @param _hashedEcosystemName The hashed name of the ecosystem.
     * @param _blockNumber The block number in which the new Collection was initialized. This is
     *        used to determine which settings were active at the time of Collection creation.
     */
    function getEcosystemSettings(bytes32 _hashedEcosystemName, uint64 _blockNumber)
        external
        view
        override
        returns (bytes memory)
    {
        require(ecosystemSettings[_hashedEcosystemName].length > 0, "CollectionFactory: ecosystem settings not found");

        return getCheckpointedSettings(ecosystemSettings[_hashedEcosystemName], _blockNumber);
    }

    /**
     * @notice This function returns an array of the Hashes Collections
     *         created through this registry for a particular implementation address.
     * @param _implementationAddress The implementation address.
     * @return An array of Collection addresses.
     */
    function getCollections(address _implementationAddress) external view override returns (address[] memory) {
        require(collections[_implementationAddress].exists, "CollectionFactory: implementation address not found.");
        return collections[_implementationAddress].contractAddresses;
    }

    /**
     * @notice This function returns an array of the Hashes Collections
     *         created through this registry for a particular implementation address.
     * @param _implementationAddress The implementation address.
     * @param _start The array start index (inclusive).
     * @param _end The array end index (exclusive).
     * @return An array of Collection addresses.
     */
    function getCollections(
        address _implementationAddress,
        uint256 _start,
        uint256 _end
    ) external view override returns (address[] memory) {
        CollectionContracts storage collection = collections[_implementationAddress];

        require(collection.exists, "CollectionFactory: implementation address not found.");
        require(
            _start < collection.contractAddresses.length &&
                _end <= collection.contractAddresses.length &&
                _end > _start,
            "CollectionFactory: Array indices out of bounds"
        );

        address[] memory collectionsForImplementation = new address[](_end - _start);
        for (uint256 i = _start; i < _end; i++) {
            collectionsForImplementation[i] = collection.contractAddresses[i];
        }
        return collectionsForImplementation;
    }

    /**
     * @notice This function gets the list of hashed ecosystem names.
     * @return An array of the hashed ecosystem names.
     */
    function getEcosystems() external view override returns (bytes32[] memory) {
        return ecosystems;
    }

    /**
     * @notice This function gets the list of hashed ecosystem names.
     * @param _start The array start index (inclusive).
     * @param _end The array end index (exclusive).
     * @return An array of the hashed ecosystem names.
     */
    function getEcosystems(uint256 _start, uint256 _end) external view override returns (bytes32[] memory) {
        require(
            _start < ecosystems.length && _end <= ecosystems.length && _end > _start,
            "CollectionFactory: Array indices out of bounds"
        );

        bytes32[] memory _ecosystems = new bytes32[](_end - _start);
        for (uint256 i = _start; i < _end; i++) {
            _ecosystems[i] = ecosystems[i];
        }
        return _ecosystems;
    }

    /**
     * @notice This function returns an array of the implementation addresses.
     * @param _hashedEcosystemName The ecosystem to fetch implementation addresses from.
     * @return Array of Hashes Collection implementation addresses.
     */
    function getImplementationAddresses(bytes32 _hashedEcosystemName)
        external
        view
        override
        returns (address[] memory)
    {
        require(ecosystemSettings[_hashedEcosystemName].length > 0, "CollectionFactory: ecosystem doesn't exist");
        return implementationAddresses[_hashedEcosystemName];
    }

    /**
     * @notice This function returns an array of the implementation addresses.
     * @param _hashedEcosystemName The ecosystem to fetch implementation addresses from.
     * @param _start The array start index (inclusive).
     * @param _end The array end index (exclusive).
     * @return Array of Hashes Collection implementation addresses.
     */
    function getImplementationAddresses(
        bytes32 _hashedEcosystemName,
        uint256 _start,
        uint256 _end
    ) external view override returns (address[] memory) {
        require(ecosystemSettings[_hashedEcosystemName].length > 0, "CollectionFactory: ecosystem doesn't exist");
        require(
            _start < implementationAddresses[_hashedEcosystemName].length &&
                _end <= implementationAddresses[_hashedEcosystemName].length &&
                _end > _start,
            "CollectionFactory: Array indices out of bounds"
        );

        address[] memory _implementationAddresses = new address[](_end - _start);
        for (uint256 i = _start; i < _end; i++) {
            _implementationAddresses[i] = implementationAddresses[_hashedEcosystemName][i];
        }
        return _implementationAddresses;
    }

    function getCheckpointedSettings(SettingsCheckpoint[] storage _settingsCheckpoints, uint64 _blockNumber)
        private
        view
        returns (bytes storage)
    {
        require(
            _blockNumber >= _settingsCheckpoints[0].id,
            "CollectionFactory: Block number before first settings block"
        );

        // If blocknumber greater than highest checkpoint, just return the latest checkpoint
        if (_blockNumber >= _settingsCheckpoints[_settingsCheckpoints.length - 1].id)
            return _settingsCheckpoints[_settingsCheckpoints.length - 1].settings;

        // Binary search for the matching checkpoint
        uint256 min = 0;
        uint256 max = _settingsCheckpoints.length - 1;
        while (max > min) {
            uint256 mid = (max + min + 1) / 2;

            if (_settingsCheckpoints[mid].id == _blockNumber) {
                return _settingsCheckpoints[mid].settings;
            }
            if (_settingsCheckpoints[mid].id < _blockNumber) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }
        return _settingsCheckpoints[min].settings;
    }

    function safe64(uint256 n, string memory errorMessage) internal pure returns (uint64) {
        require(n < 2**64, errorMessage);
        return uint64(n);
    }
}


contract AllHashesEligibilityPredicate is
    ICollectionNFTEligibilityPredicate,
    ICollectionNFTMintFeePredicate,
    ICollectionNFTTokenURIPredicate,
    ICollection
{
    /**
     * @notice This predicate function is used to determine the mint eligibility of a hashes token Id for
     *          a specified hashes collection and always returns a boolean value of true. This function is to
     *          be used when instantiating new hashes collections where all hash holders are eligible to mint.
     * @param _tokenId The token Id of the associated hashes collection contract.
     * @param _hashesTokenId The Hashes token Id being used to mint.
     *
     * @return the boolean value of true
     */
    function isTokenEligibleToMint(uint256 _tokenId, uint256 _hashesTokenId) external pure override returns (bool) {
        return true;
    }

    function getTokenMintFee(uint256 _tokenId, uint256 _hashesTokenId) external pure override returns (uint256) {
        return 0.01e18;
    }

    function getTokenURI(
        uint256 _tokenId,
        uint256 _hashesTokenId,
        bytes32 _hashehash
    ) external pure override returns (string memory) {
        return "";
    }

    /**
     * @notice This function is used by the Factory to verify the format of ecosystem settings
     * @param _settings ABI encoded ecosystem settings data. This should be empty for the 'Default' ecosystem.
     *
     * @return The boolean result of the validation.
     */
    function verifyEcosystemSettings(bytes memory _settings) external pure override returns (bool) {
        return _settings.length == 0;
    }
}