// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {Owned} from "solmate/auth/Owned.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {ECDSA} from "openzeppelin/utils/cryptography/ECDSA.sol";
import {EIP712} from "openzeppelin/utils/cryptography/draft-EIP712.sol";
import {ILMapsGameTokens} from "./interfaces/ILMapsGameTokens.sol";

/// @title Legend Maps Token Operator
/// @author Legend Maps
/// @notice An operator contract that can issue and spend tokens on behalf of players and the
///         game service. It uses EIP-712 signatures issued by the game service to make sure
///         players can only claim and spend what they're allowed.
contract LMapsTokenOperator is EIP712, Owned, ReentrancyGuard {
    /* ------------------------------------------------------------------------
       S T O R A G E
    ------------------------------------------------------------------------ */

    /// @dev Reference to the main token ownership contract so this contract can
    ///      call operator related functions on it
    ILMapsGameTokens public gameTokens;

    /// @dev EIP-712 signing domain
    string private constant SIGNING_DOMAIN = "LegendMapsGameTokens";

    /// @dev EIP-712 signature version. Should be incremented on new versions of this contract.
    string private constant SIGNATURE_VERSION = "1";

    /// @dev EIP-712 signed data type hash for managing tokens
    bytes32 public constant MANAGE_TOKENS_TYPEHASH =
        keccak256(
            "ManageTokensData(uint256 spendId,uint256 spendQty,uint256 issueId,uint256 issueQty,address player,uint256 nonce)"
        );

    /// @dev EIP-712 signed data struct for managing tokens
    struct ManageTokensData {
        uint256 spendId;
        uint256 spendQty;
        uint256 issueId;
        uint256 issueQty;
        address player;
        uint256 nonce;
        bytes signature;
    }

    /// @dev Approved signer public addresses used by the game service
    mapping(address => bool) private approvedSigners;

    /// @dev Nonce management for player accounts to avoid signature replay attacks
    mapping(address => uint256) public nonces;

    /* ------------------------------------------------------------------------
       E V E N T S
    ------------------------------------------------------------------------ */

    /// @dev Emitted when a new signer is added to this contract
    event SignerAdded(address indexed signer);

    /// @dev Emitted when an existing signer is removed from this contract
    event SignerRemoved(address indexed signer);

    /* ------------------------------------------------------------------------
       E R R O R S
    ------------------------------------------------------------------------ */

    /// @dev When an EIP-712 signature is invalid
    error InvalidSignature();

    /* ------------------------------------------------------------------------
       I N I T
    ------------------------------------------------------------------------ */

    /// @param owner The owner of the contract upon creation. Can be set later with `setOwner`.
    /// @param signer The public address of an initial EIP-712 signer
    /// @param gameTokens_ The address of the token ownership contract
    constructor(
        address owner,
        address signer,
        address gameTokens_
    ) Owned(owner) EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
        approvedSigners[signer] = true;
        gameTokens = ILMapsGameTokens(gameTokens_);
    }

    /* ------------------------------------------------------------------------
       A D M I N
    ------------------------------------------------------------------------ */

    /// @notice Allows the contract owner to add a new EIP-712 signer
    /// @param signer The public address of the EIP-712 signer to add
    function addApprovedSigner(address signer) external onlyOwner {
        approvedSigners[signer] = true;
        emit SignerAdded(signer);
    }

    /// @notice Allows the contract owner to remove an existing EIP-712 signer
    /// @param signer The public address of the EIP-712 signer to remove
    function removeApprovedSigner(address signer) external onlyOwner {
        delete approvedSigners[signer];
        emit SignerRemoved(signer);
    }

    /* ------------------------------------------------------------------------
       I S S U I N G,  S P E N D I N G,  C O N V E R T I N G
    ------------------------------------------------------------------------ */

    /// @notice Allows a player to receive gold
    /// @dev Reverts if the signature is invalid
    /// @param goldQty The quantity of gold to receive
    /// @param signature An EIP-712 signature
    function getGold(uint256 goldQty, bytes calldata signature) external nonReentrant {
        ManageTokensData memory data = ManageTokensData({
            spendId: 0,
            spendQty: 0,
            issueId: gameTokens.getGoldTokenId(),
            issueQty: goldQty,
            player: msg.sender,
            nonce: nonces[msg.sender],
            signature: signature
        });

        _manageTokens(data);
    }

    /// @notice Allows a player to spend gold
    /// @dev Reverts if the signature is invalid
    /// @param goldQty The quantity of gold to spend
    /// @param signature An EIP-712 signature
    function spendGold(uint256 goldQty, bytes calldata signature) external nonReentrant {
        ManageTokensData memory data = ManageTokensData({
            spendId: gameTokens.getGoldTokenId(),
            spendQty: goldQty,
            issueId: 0,
            issueQty: 0,
            player: msg.sender,
            nonce: nonces[msg.sender],
            signature: signature
        });

        _manageTokens(data);
    }

    /// @notice Allows a player to spend gold on another in game item
    /// @dev Reverts if the signature is invalid
    /// @param goldQty The quantity of gold to spend
    /// @param receiveId The id of the game item the player should receive
    /// @param receiveQty The quantity of the game item the player should receive
    /// @param signature An EIP-712 signature
    function spendGold(
        uint256 goldQty,
        uint256 receiveId,
        uint256 receiveQty,
        bytes calldata signature
    ) external nonReentrant {
        ManageTokensData memory data = ManageTokensData({
            spendId: gameTokens.getGoldTokenId(),
            spendQty: goldQty,
            issueId: receiveId,
            issueQty: receiveQty,
            player: msg.sender,
            nonce: nonces[msg.sender],
            signature: signature
        });

        _manageTokens(data);
    }

    /// @notice Allows a player to swap one in game item for another, including gold
    /// @dev Reverts if the signature is invalid
    /// @param fromId The id of the token to spend
    /// @param fromQty The quantity of token to spend
    /// @param receiveId The id of the game item the player should receive
    /// @param receiveQty The quantity of the game item the player should receive
    /// @param signature An EIP-712 signature
    function genericTokenSwap(
        uint256 fromId,
        uint256 fromQty,
        uint256 receiveId,
        uint256 receiveQty,
        bytes calldata signature
    ) external nonReentrant {
        ManageTokensData memory data = ManageTokensData({
            spendId: fromId,
            spendQty: fromQty,
            issueId: receiveId,
            issueQty: receiveQty,
            player: msg.sender,
            nonce: nonces[msg.sender],
            signature: signature
        });

        _manageTokens(data);
    }

    /// @dev Internal function to construct and verify an EIP-712 signature, and also call
    ///      spending and issuing in the token ownership contract
    /// @param data The struct of signature data to hash and verify
    function _manageTokens(ManageTokensData memory data) internal {
        // Hash the data for verification
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    MANAGE_TOKENS_TYPEHASH,
                    data.spendId,
                    data.spendQty,
                    data.issueId,
                    data.issueQty,
                    data.player,
                    nonces[data.player]++
                )
            )
        );

        // Verifiy signature is ok
        address addr = ECDSA.recover(digest, data.signature);
        if (!approvedSigners[addr] || addr == address(0)) revert InvalidSignature();

        // Spend tokens
        if (data.spendQty > 0) {
            gameTokens.spendTokens(data.spendId, data.spendQty, data.player);
        }

        // Issue tokens
        if (data.issueQty > 0) {
            gameTokens.issueTokens(data.issueId, data.issueQty, data.player);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
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
            /// @solidity memory-safe-assembly
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
            /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

interface ILMapsGameTokens {
    function issueTokens(
        uint256 id,
        uint256 amount,
        address player
    ) external;

    function issueTokensBatch(
        uint256[] memory ids,
        uint256[] memory amounts,
        address player
    ) external;

    function spendTokens(
        uint256 id,
        uint256 amount,
        address player
    ) external;

    function spendTokensBatch(
        uint256[] memory ids,
        uint256[] memory amounts,
        address player
    ) external;

    function getGoldTokenId() external pure returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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