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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IEIP712Proposition} from "../../interfaces/IEIP712Proposition.sol";
import {LibEIP712Proposition} from "../../libraries/LibEIP712Proposition.sol";
import {IWallet} from "../../interfaces/IWallet.sol";

/// @author Amit Molek
/// @dev Please see `IEIP712Proposition` for docs
contract EIP712PropositionFacet is IEIP712Proposition {
    function verifyPropositionSigner(
        address signer,
        IWallet.Proposition memory proposition,
        bytes memory signature
    ) external view override returns (bool) {
        return
            LibEIP712Proposition._verifyPropositionSigner(
                signer,
                proposition,
                signature
            );
    }

    function recoverPropositionSigner(
        IWallet.Proposition memory proposition,
        bytes memory signature
    ) external view override returns (address) {
        return
            LibEIP712Proposition._recoverPropositionSigner(
                proposition,
                signature
            );
    }

    function hashProposition(IWallet.Proposition memory proposition)
        external
        pure
        override
        returns (bytes32)
    {
        return LibEIP712Proposition._hashProposition(proposition);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IWallet} from "./IWallet.sol";

/// @author Amit Molek
/// @dev EIP712 Proposition struct signature verification for Antic domain
interface IEIP712Proposition {
    /// @param signer the account you want to check that signed
    /// @param proposition the proposition to verify
    /// @param signature the supposed signature of `signer` on `proposition`
    /// @return true if `signer` signed `proposition` using `signature`
    function verifyPropositionSigner(
        address signer,
        IWallet.Proposition memory proposition,
        bytes memory signature
    ) external view returns (bool);

    /// @param proposition the proposition
    /// @param signature the account's signature on `proposition`
    /// @return the address that signed on `proposition`
    function recoverPropositionSigner(
        IWallet.Proposition memory proposition,
        bytes memory signature
    ) external view returns (address);

    function hashProposition(IWallet.Proposition memory proposition)
        external
        pure
        returns (bytes32);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title Multisig wallet interface
/// @author Amit Molek
interface IWallet {
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
    }

    struct Proposition {
        /// @dev Proposition's deadline
        uint256 endsAt;
        /// @dev Proposed transaction to execute
        Transaction tx;
        /// @dev can be useful if your `transaction` needs an accompanying hash.
        /// For example in EIP1271 `isValidSignature` function.
        /// Note: Pass zero hash (0x0) if you don't need this.
        bytes32 relevantHash;
    }

    /// @dev Emitted on proposition execution
    /// @param hash the transaction's hash
    /// @param value the value passed with `transaction`
    /// @param successful is the transaction were successfully executed
    event ExecutedTransaction(
        bytes32 indexed hash,
        uint256 value,
        bool successful
    );

    /// @notice Execute proposition
    /// @param proposition the proposition to enact
    /// @param signatures a set of members EIP712 signatures on `proposition`
    /// @dev Emits `ExecutedTransaction` and `ApprovedHash` (only if `relevantHash` is passed) events
    /// @return successful true if the `proposition`'s transaction executed successfully
    /// @return returnData the data returned from the transaction
    function enactProposition(
        Proposition memory proposition,
        bytes[] memory signatures
    ) external returns (bool successful, bytes memory returnData);

    /// @return true, if the proposition has been enacted
    function isPropositionEnacted(bytes32 propositionHash)
        external
        view
        returns (bool);

    /// @return the maximum amount of value allowed to be transferred out of the contract
    function maxAllowedTransfer() external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {StorageAnticDomain} from "../storage/StorageAnticDomain.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @author Amit Molek
/// @dev Please see `IEIP712` for docs
/// Also please make sure you are familiar with EIP712 before editing anything
library LibEIP712 {
    bytes32 internal constant _DOMAIN_NAME = keccak256("Antic");
    bytes32 internal constant _DOMAIN_VERSION = keccak256("1");
    bytes32 internal constant _SALT = keccak256("Magrathea");

    bytes32 internal constant _EIP712_DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"
        );

    /// @dev Initializes the EIP712's domain separator
    /// note Must be called at least once, because it saves the
    /// domain separator in storage
    function _initDomainSeparator() internal {
        StorageAnticDomain.DiamondStorage storage ds = StorageAnticDomain
            .diamondStorage();

        ds.domainSeparator = keccak256(
            abi.encode(
                _EIP712_DOMAIN_TYPEHASH,
                _DOMAIN_NAME,
                _DOMAIN_VERSION,
                _chainId(),
                _verifyingContract(),
                _salt()
            )
        );
    }

    function _toTypedDataHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return ECDSA.toTypedDataHash(_domainSeparator(), messageHash);
    }

    function _domainSeparator() internal view returns (bytes32) {
        StorageAnticDomain.DiamondStorage storage ds = StorageAnticDomain
            .diamondStorage();

        return ds.domainSeparator;
    }

    function _chainId() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function _verifyingContract() internal view returns (address) {
        return address(this);
    }

    function _salt() internal pure returns (bytes32) {
        return _SALT;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IWallet} from "../interfaces/IWallet.sol";
import {LibEIP712} from "./LibEIP712.sol";
import {LibSignature} from "./LibSignature.sol";
import {LibEIP712Transaction} from "./LibEIP712Transaction.sol";

/// @author Amit Molek
/// @dev Please see `IEIP712Proposition` for docs
/// Also please make sure you are familiar with EIP712 before editing anything
library LibEIP712Proposition {
    bytes32 internal constant _PROPOSITION_TYPEHASH =
        keccak256(
            "Proposition(uint256 endsAt,Transaction tx,bytes32 relevantHash)Transaction(address to,uint256 value,bytes data)"
        );

    function _verifyPropositionSigner(
        address signer,
        IWallet.Proposition memory proposition,
        bytes memory signature
    ) internal view returns (bool) {
        return
            LibSignature._verifySigner(
                signer,
                LibEIP712._toTypedDataHash(_hashProposition(proposition)),
                signature
            );
    }

    function _recoverPropositionSigner(
        IWallet.Proposition memory proposition,
        bytes memory signature
    ) internal view returns (address) {
        return
            LibSignature._recoverSigner(
                LibEIP712._toTypedDataHash(_hashProposition(proposition)),
                signature
            );
    }

    function _hashProposition(IWallet.Proposition memory proposition)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    _PROPOSITION_TYPEHASH,
                    proposition.endsAt,
                    LibEIP712Transaction._hashTransaction(proposition.tx),
                    proposition.relevantHash
                )
            );
    }

    function _toTypedDataHash(IWallet.Proposition memory proposition)
        internal
        view
        returns (bytes32)
    {
        return LibEIP712._toTypedDataHash(_hashProposition(proposition));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IWallet} from "../interfaces/IWallet.sol";
import {LibEIP712} from "./LibEIP712.sol";
import {LibSignature} from "./LibSignature.sol";

/// @author Amit Molek
/// @dev Please see `IEIP712Transaction` for docs
/// Also please make sure you are familiar with EIP712 before editing anything
library LibEIP712Transaction {
    bytes32 internal constant _TRANSACTION_TYPEHASH =
        keccak256("Transaction(address to,uint256 value,bytes data)");

    function _verifyTransactionSigner(
        address signer,
        IWallet.Transaction memory transaction,
        bytes memory signature
    ) internal view returns (bool) {
        return
            LibSignature._verifySigner(
                signer,
                LibEIP712._toTypedDataHash(_hashTransaction(transaction)),
                signature
            );
    }

    function _recoverTransactionSigner(
        IWallet.Transaction memory transaction,
        bytes memory signature
    ) internal view returns (address) {
        return
            LibSignature._recoverSigner(
                LibEIP712._toTypedDataHash(_hashTransaction(transaction)),
                signature
            );
    }

    function _hashTransaction(IWallet.Transaction memory transaction)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    _TRANSACTION_TYPEHASH,
                    transaction.to,
                    transaction.value,
                    keccak256(transaction.data)
                )
            );
    }

    function _toTypedDataHash(IWallet.Transaction memory transaction)
        internal
        view
        returns (bytes32)
    {
        return LibEIP712._toTypedDataHash(_hashTransaction(transaction));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @author Amit Molek
/// @dev Please see `ISignature` for docs
library LibSignature {
    function _verifySigner(
        address signer,
        bytes32 hashToVerify,
        bytes memory signature
    ) internal pure returns (bool) {
        return (signer == _recoverSigner(hashToVerify, signature));
    }

    function _recoverSigner(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        return ECDSA.recover(hash, signature);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek
/// @dev Diamond compatible storage for EIP712's domain separator
library StorageAnticDomain {
    struct DiamondStorage {
        bytes32 domainSeparator;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("antic.storage.AnticDomain");

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 storagePosition = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := storagePosition
        }
    }
}