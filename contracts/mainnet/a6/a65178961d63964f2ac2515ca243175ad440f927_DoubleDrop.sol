// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
pragma solidity ^0.8.16;

import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

import "./IDoubleDropNFT.sol";
import "./IDoubleDrop.sol";
import "./IProvenance.sol";
import "./SignedRedeemer.sol";

/// @title The Hashmasks Double Drop
/// @author fancyrats.io
/**
 * @notice Holders of Hashmasks NFTs can redeem Hashmasks Elementals, Derivatives, or burn their masks to get both!
 * Holders can only choose one redemption option per Hashmask NFT.
 * Once a selection is made, that NFT cannot be used to redeem again! Choose wisely!
 */
/**
 * @dev Hashmasks holders must set approval for this contract in order to "burn".
 * The original Hashmasks contract does not have burn functionality, so we move masks into the 0xdEaD wallet.
 * Elementals and Derivatives contracts must be deployed and addresses set prior to activating redemption.
 */
contract DoubleDrop is IDoubleDrop, Ownable, SignedRedeemer {
    event ElementalsRedeemed(uint256[] indexed tokenIds, address indexed redeemer);
    event DerivativesRedeemed(uint256[] indexed tokenIds, address indexed redeemer);
    event HashmasksBurned(uint256[] indexed tokenIds, address indexed redeemer);

    address private constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    bool public isActive;
    bool public contractsInitialized;

    uint256 public elementalsProvenance;

    mapping(uint256 => bool) public redeemedHashmasks;

    IERC721 public hashmasks;
    IDoubleDropNFT public derivatives;
    IDoubleDropNFT public elementals;

    constructor(address signer_) Ownable() SignedRedeemer(signer_) {}

    /// @notice Redeem Hashmasks Elementals NFTs
    /// @dev Resulting Elementals will have matching token IDs.
    /// @param signature Signed message from our website that validates token ownership
    /// @param tokenIds Ordered array of Hashmasks NFT ids used to claim the Elementals.
    function redeemElementals(bytes calldata signature, uint256[] calldata tokenIds)
        public
        isValidRedemption(signature, tokenIds)
    {
        emit ElementalsRedeemed(tokenIds, msg.sender);
        elementals.redeem(tokenIds, msg.sender);
    }

    /// @notice Redeem Hashmasks Derivatives NFTs
    /// @dev Resulting Derivatives will have matching token IDs.
    /// @param signature Signed message from our website that validates token ownership
    /// @param tokenIds Ordered array of Hashmasks NFT ids used to claim the Derivatives.
    function redeemDerivatives(bytes calldata signature, uint256[] calldata tokenIds)
        public
        isValidRedemption(signature, tokenIds)
    {
        emit DerivativesRedeemed(tokenIds, msg.sender);
        derivatives.redeem(tokenIds, msg.sender);
    }

    /**
     * @notice Burns Hashmasks and redeems one elemental and one derivative per Hashmask burned.
     * Requires this contract to be approved as an operator for the Hashmasks tokens provided.
     * CAUTION: ONLY APPROVE OR SETAPPROVALFORALL FROM THEHASHMASKS.COM
     * CAUTION: THIS ACTION IS PERMANENT. Holders will not be able to retrieve their burned Hashmask NFTs.
     */
    /**
     * @dev Resulting Derivatives and Elementals will have matching token IDs.
     *  Approval must be managed on the frontend.
     */
    /// @param signature Signed message from our website that validates token ownership
    /// @param tokenIds Ordered array of Hashmasks NFT ids to burn and use for double redemption
    function burnMasksForDoubleRedemption(bytes calldata signature, uint256[] calldata tokenIds)
        public
        isValidRedemption(signature, tokenIds)
    {
        emit HashmasksBurned(tokenIds, msg.sender);
        emit ElementalsRedeemed(tokenIds, msg.sender);
        emit DerivativesRedeemed(tokenIds, msg.sender);

        _burnMasks(tokenIds);
        elementals.redeem(tokenIds, msg.sender);
        derivatives.redeem(tokenIds, msg.sender);
    }

    /**
     * @notice Sets the Derivatives and Elementals contract addresses for redemption.
     * Caller must be contract owner.
     * CAUTION: ADDRESSES CAN ONLY BE SET ONCE.
     */
    /// @dev derivativesAddress and elementalsAddress must conform to IDoubleDropNFT
    /// @param hashmasksAddress The Hashmasks NFT contract address
    /// @param derivativesAddress The Hashmasks Derivatives NFT contract address
    /// @param elementalsAddress The Hashmasks Elementals NFT contract address
    function setTokenContracts(address hashmasksAddress, address derivativesAddress, address elementalsAddress)
        public
        onlyOwner
    {
        if (contractsInitialized) revert ContractsAlreadyInitialized();
        if (hashmasksAddress == address(0) || derivativesAddress == address(0) || elementalsAddress == address(0)) {
            revert ContractsCannotBeNull();
        }

        contractsInitialized = true;
        hashmasks = IERC721(hashmasksAddress);
        derivatives = IDoubleDropNFT(derivativesAddress);
        elementals = IDoubleDropNFT(elementalsAddress);
    }

    /**
     * @notice Asks the ProvenanceGenerator for a random number
     * Caller must be contract owner
     * Can only be set once
     */
    /// @dev Provenance implementation uses chainlink, so that will need setup first
    /// @param generatorAddress Contract conforming to IProvenance
    function setRandomProvenance(address generatorAddress) public onlyOwner {
        if (elementalsProvenance != 0) revert ElementalsProvenanceAlreadySet();
        if (generatorAddress == address(0)) revert ProvenanceContractCannotBeNull();

        IProvenance provenanceGenerator = IProvenance(generatorAddress);
        elementalsProvenance = provenanceGenerator.getRandomProvenance();

        if (elementalsProvenance == 0) revert ElementalsProvenanceNotSet();
    }

    /**
     * @notice Sets the known signer address used by the redemption backend to validate ownership
     * Caller must be contract owner.
     */
    /// @dev signer is responsible for signing redemption messages on the backend
    /// @param signer_ public address to expected to sign redemption signatures
    function setSigner(address signer_) public onlyOwner {
        _setSigner(signer_);
    }

    /**
     * @notice Turn on/off Double Drop redemption.
     * Starts out paused.
     * Caller must be contract owner.
     */
    /// @dev setTokenContracts must be called prior to activating.
    /// @param isActive_ updated redemption active status. false to pause. true to resume.
    function setIsActive(bool isActive_) public onlyOwner {
        if (address(hashmasks) == address(0) || address(derivatives) == address(0) || address(elementals) == address(0))
        {
            revert ContractsNotInitialized();
        }
        if (elementalsProvenance == 0) revert ElementalsProvenanceNotSet();
        isActive = isActive_;
    }

    function _burnMasks(uint256[] calldata tokenIds) private {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            hashmasks.safeTransferFrom(msg.sender, BURN_ADDRESS, tokenIds[i]);
        }
    }

    modifier isValidRedemption(bytes calldata signature, uint256[] calldata tokenIds) {
        if (!isActive) revert RedemptionNotActive();
        if (!validateSignature(signature, tokenIds, msg.sender)) revert InvalidSignature();
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (hashmasks.ownerOf(tokenIds[i]) != msg.sender) revert NotTokenOwner();
            if (redeemedHashmasks[tokenIds[i]]) revert TokenAlreadyRedeemed();
            redeemedHashmasks[tokenIds[i]] = true;
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IDoubleDrop {
    /**
      * Elementals provenance contract cannot be null
      */
    error ProvenanceContractCannotBeNull();

    /**
      * Elementals provenance not set
      */
    error ElementalsProvenanceNotSet();

    /**
      * Elementals provenance already set
      */
    error ElementalsProvenanceAlreadySet();

    /**
     * Redemption contracts already set
     */
    error ContractsAlreadyInitialized();

    /**
     * Redemption contracts cannot be NULL
     */
    error ContractsCannotBeNull();

    /**
     * Redemption contracts are not yet set
     */
    error ContractsNotInitialized();

    /**
     * Redemption is not active
     */
    error RedemptionNotActive();

    /**
     * Invalid signature provided
     */
    error InvalidSignature();

    /**
     * Hashmask token already used for redemption
     */
    error TokenAlreadyRedeemed();

    /**
     * Address is not the token owner
     */
    error NotTokenOwner();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IDoubleDropNFT {
    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * Metadata frozen. Cannot set new base URI.
     */
    error MetadataFrozen();

    /**
     * Cannot set redeemer contract multiple times
     */
    error RedeemerAlreadySet();

    /**
     * Redeemer contract not set
     */
    error RedeemerNotSet();

    /**
     * Only the redeemer contract can mint
     */
    error OnlyRedeemerCanMint();

    function redeem(uint256[] calldata _tokenIds, address _to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IProvenance {
    function getRandomProvenance() external returns (uint256);

    error ProvenanceAlreadyRequested();
    error ProvenanceAlreadyGenerated();
    error ProvenanceNotGenerated();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract SignedRedeemer {
    using ECDSA for bytes32;

    address public signer;

    constructor(address signer_) {
        signer = signer_;
    }

    /**
     * @notice Uses ECDSA to validate the provided signature was signed by the known address.
     */
    /**
     * @dev For a given unique ordered array of tokenIds,
     * a valid signature is a message keccack256(abi.encode(owner, tokenIds)) signed by the known address.
     */
    /// @param signature Signed message
    /// @param tokenIds ordered unique array of tokenIds encoded in the signed message
    /// @param to token owner encoded in the signed message
    function validateSignature(
        bytes memory signature,
        uint256[] calldata tokenIds, // must be in numeric order
        address to
    ) public view returns (bool) {
        bytes memory message = abi.encode(to, tokenIds);
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(keccak256(message));
        address recovered = messageHash.recover(signature);
        return signer == recovered;
    }

    function _setSigner(address signer_) internal {
        signer = signer_;
    }
}