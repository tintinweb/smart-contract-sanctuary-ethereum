// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// ====================================================================
// |     __      __                       __   __             __      |
// |    /  \    / / ____   ______  ___   / /  / / ____  ____ / /_     |
// |   / /\ \  / // __  // _  _  // _ \ / /__/ // __  //   // __ \    |
// |  / /  \ \/ // /_/ // // // //  __// /  / // /_/ /  \  / / / /    |
// | /_/    \__/ \__,_//_//_//_/ \___//_/  /_/ \__,_//___//_/ /_/     |
// |                                                                  |
// ====================================================================
// ======================   OffchainResolver   ========================
// ====================================================================
// NameHash dapp: https://namehash.io/
// NameHash repo: https://github.com/namehash

import "@ensdomains/ens-contracts/contracts/resolvers/SupportsInterface.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./IResolverGateway.sol";
import "./IExtendedResolver.sol";
import "./IPublicResolver.sol";

/**
 * @title NameHash Offchain Resolver
 * @author @alextnetto - https://github.com/alextnetto
 * @author @maiconmoreira - https://github.com/Maicon-Moreira
 * @dev Implements an ENS resolver that directs all queries to a CCIP read gateway.
 * Callers must implement EIP 3668 and ENSIP 10.
 */

abstract contract RegistryWithFallback {
    function owner(bytes32 node) external view virtual returns (address);
}

contract OffchainResolver is IExtendedResolver, SupportsInterface {
    struct Record {
        string key;
        string value;
        bytes identifier;
        bytes functionResultEncoded;
    }

    RegistryWithFallback public registry;

    bytes32 constant EIP712DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    bytes32 eip712DomainHash;

    string[] urls;

    string constant MESSAGE_TYPE =
        "Message(string message,Record[] records)Record(string key,string value,bytes identifier,bytes functionResultEncoded)";

    string constant RECORD_TYPE =
        "Record(string key,string value,bytes identifier,bytes functionResultEncoded)";

    string constant messageText =
        "Please sign the domains records to be saved on the gateway";

    /**
     * @notice NameHash Off-chain Resolver Constructor
     * @param contractName string - The name of the contract
     * @param version string - The version of the contract
     * @param chainId uint256 - The chainId of the network
     * @param verifyingContract address - The address of the contract
     * @param _urls string[] - Gateway URLs for resolving ENS records
     * @param _registryAddress address - The address of the ENS registry
     */
    constructor(
        string memory contractName,
        string memory version,
        uint256 chainId,
        address verifyingContract,
        string[] memory _urls,
        address _registryAddress
    ) {
        urls = _urls;
        registry = RegistryWithFallback(_registryAddress);

        eip712DomainHash = keccak256(
            abi.encode(
                EIP712DOMAIN_TYPEHASH,
                keccak256(bytes(contractName)),
                keccak256(bytes(version)),
                chainId,
                verifyingContract
            )
        );
    }

    /**
     * @notice Resolves a name, as specified by ENSIP 10.
     * @param name The DNS-encoded name to resolve.
     * @param query The ABI encoded data for the underlying resolution function (Eg, addr(bytes32), text(bytes32,string), etc).
     * @return The return data, ABI encoded identically to the underlying function.
     */
    function resolve(
        bytes calldata name,
        bytes calldata query
    ) external view override returns (bytes memory) {
        bytes memory callbackData = abi.encode(name, query);
        bytes memory gatewayRequest = abi.encodeWithSelector(
            IResolverGateway.resolve.selector,
            name
        );

        revert OffchainLookup(
            address(this),
            urls,
            gatewayRequest,
            OffchainResolver.resolveWithProof.selector,
            callbackData
        );
    }

    /**
     * @notice Callback used by CCIP read compatible clients to verify and parse the response.
     * @param gatewayResponse bytes - The response from the gateway.
     * @param callbackData bytes - The data passed from the resolve function.
     * @return The resolved record.
     */
    function resolveWithProof(
        bytes calldata gatewayResponse,
        bytes calldata callbackData
    ) external view returns (bytes memory) {
        (, bytes memory query) = abi.decode(callbackData, (bytes, bytes));

        (bytes memory signature, bytes[] memory records) = abi.decode(
            gatewayResponse,
            (bytes, bytes[])
        );

        Record[] memory recordsArray = parseRecords(records);

        bytes32 finalHash = hashRecords(recordsArray);
        address signer = ECDSA.recover(finalHash, signature);
        bytes32 namehash = sliceBytesToBytes32(query, 4);
        address nameOwner = registry.owner(namehash);

        if (signer != nameOwner) {
            revert("Signer is not the owner of name");
        }

        for (uint256 i = 0; i < recordsArray.length; i++) {
            if (
                bytes4(recordsArray[i].identifier) == bytes4(keccak256(query))
            ) {
                return recordsArray[i].functionResultEncoded;
            }
        }

        return new bytes(0);
    }

    /**
     * @notice Get from index next 32 bytes from a bytes memory array
     * @param _bytes bytes memory array to slice
     * @param _start uint256 index to start slice and get next 32 bytes
     */
    function sliceBytesToBytes32(
        bytes memory _bytes,
        uint256 _start
    ) internal pure returns (bytes32 result) {
        require(
            _bytes.length >= (_start + 32),
            "sliceBytesToBytes32_outOfBounds"
        );
        assembly {
            result := mload(add(_bytes, add(0x20, _start)))
        }
    }

    /**
     * @notice Parses records bytes array into Record struct array
     * @param records bytes[] - Records to parse
     * @return Record[] - Parsed records
     */
    function parseRecords(
        bytes[] memory records
    ) public pure returns (Record[] memory) {
        Record[] memory recordsArray = new Record[](records.length);
        for (uint256 i = 0; i < records.length; i++) {
            (
                string memory key,
                string memory value,
                bytes memory identifier,
                bytes memory functionResultEncoded
            ) = abi.decode(records[i], (string, string, bytes, bytes));
            recordsArray[i] = Record(
                key,
                value,
                identifier,
                functionResultEncoded
            );
        }
        return recordsArray;
    }

    /**
     * @notice Hashes records array to make EI712 signature
     * @param recordsArray Record[] - Records to hash
     * @return bytes32 - Hashed records
     */
    function hashRecords(
        Record[] memory recordsArray
    ) public view returns (bytes32) {
        bytes32 messageHash = keccak256(abi.encodePacked(messageText));

        bytes memory recordsEncoded;
        for (uint256 i = 0; i < recordsArray.length; i++) {
            bytes32 recordHash = keccak256(
                abi.encode(
                    keccak256(abi.encodePacked(RECORD_TYPE)),
                    keccak256(abi.encodePacked(recordsArray[i].key)),
                    keccak256(abi.encodePacked(recordsArray[i].value)),
                    keccak256(abi.encodePacked(recordsArray[i].identifier)),
                    keccak256(
                        abi.encodePacked(recordsArray[i].functionResultEncoded)
                    )
                )
            );
            recordsEncoded = bytes.concat(recordsEncoded, recordHash);
        }

        bytes32 recordsHash = keccak256(recordsEncoded);

        bytes32 valuesHash = keccak256(
            abi.encode(
                keccak256(abi.encodePacked(MESSAGE_TYPE)),
                messageHash,
                recordsHash
            )
        );

        bytes32 finalHash = keccak256(
            abi.encodePacked("\x19\x01", eip712DomainHash, valuesHash)
        );

        return finalHash;
    }

    /**
     * @notice Checks if the resolver supports the interface
     * @param interfaceID bytes4 - Interface ID to check
     * @return bool - True if the interface is supported
     */
    function supportsInterface(
        bytes4 interfaceID
    ) public pure override returns (bool) {
        return
            interfaceID == type(IExtendedResolver).interfaceId ||
            super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ISupportsInterface.sol";

abstract contract SupportsInterface is ISupportsInterface {
    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == type(ISupportsInterface).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

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
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IResolverGateway {
    function resolve(bytes calldata name)
        external
        view
        returns (bytes memory signature, bytes[] memory records);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IExtendedResolver {
    error OffchainLookup(
        address sender,
        string[] urls,
        bytes callData,
        bytes4 callbackFunction,
        bytes extraData
    );

    function resolve(bytes memory name, bytes memory data)
        external
        view
        returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPublicResolver {
    function addr(bytes32 node) external view returns (address payable);

    function addr(bytes32 node, uint256 coinType)
        external
        view
        returns (bytes memory);

    function text(bytes32 node, string calldata key)
        external
        view
        returns (string memory);

    function contenthash(bytes32 node) external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISupportsInterface {
    function supportsInterface(bytes4 interfaceID) external pure returns(bool);
}

// SPDX-License-Identifier: MIT
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