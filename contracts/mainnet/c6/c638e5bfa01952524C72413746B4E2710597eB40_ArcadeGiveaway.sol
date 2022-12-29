// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IArcadeGiveaway.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

contract ArcadeGiveaway is IArcadeGiveaway, OwnableUpgradeable {
    using ECDSAUpgradeable for bytes32;

    event AddClaiming(uint256 indexed giveawayId, uint256 claimingId);
    event SetClaimingActive(uint256 indexed giveawayId, uint256 indexed claimingId, bool active);
    event Claimed(
        uint256 indexed withTokenId,
        uint256 indexed giveawayId,
        uint256 indexed claimingId
    );
    event ModeratorUpdated(address indexed moderator, bool approved);
    event SetMintingSinger(address mintingSigner);
    event CreateGiveaway(
        uint256 indexed giveawayCount,
        address indexed rewardToken,
        uint256 startTokenId,
        uint256 endTokenId,
        bool needsProof
    );

    address public mintingSigner;

    mapping(address => bool) public moderators;

    uint256 public giveawayCount;
    mapping(uint256 => Giveaway) public giveaways;

    mapping(uint256 => mapping(uint256 => mapping(uint256 => bool))) public claimed; //giveawayId => tokenId => claimingId

    modifier onlyMods() {
        require(msg.sender == owner() || moderators[msg.sender], "Giveaway: NOT_GOVERNANCE");
        _;
    }

    function initialize() public initializer {
        __Ownable_init();
    }

    /**
     * @notice Manage moderators of this contract
     * @param moderator Address to be managed
     * @param approved Whether or not this address should be a moderator
     */
    function setModerator(address moderator, bool approved) external onlyOwner {
        require(moderator != address(0), "Giveaway: INVALID_MODERATOR");
        moderators[moderator] = approved;
        emit ModeratorUpdated(moderator, approved);
    }

    /**
     * @notice Set a signer address for proofs
     * @param newMintingSigner new signer address
     */
    function setMintingSigner(address newMintingSigner) external onlyOwner {
        mintingSigner = newMintingSigner;
        emit SetMintingSinger(newMintingSigner);
    }

    /**
     * @notice Creates new giveaway in the contract
     * @param rewardToken ERC721 token which user should own to be able to claim reward
     * @param startTokenId minimum token id which counts for rewards
     * @param endTokenId maximum token id which counts for rewards
     * @param needsProof flag if it is crosschain giveaway and proof is needed
     * @param claimings data about each reward inside this giveaway
     */
    function createGiveaway(
        address rewardToken,
        uint256 startTokenId,
        uint256 endTokenId,
        bool needsProof,
        Claiming[] calldata claimings
    ) external onlyMods {
        giveawayCount++;

        giveaways[giveawayCount].rewardToken = rewardToken;
        giveaways[giveawayCount].startTokenId = startTokenId;
        giveaways[giveawayCount].endTokenId = endTokenId;
        giveaways[giveawayCount].needsProof = needsProof;
        addClaimingsToGiveaway(giveawayCount, claimings);

        emit CreateGiveaway(giveawayCount, rewardToken, startTokenId, endTokenId, needsProof);
    }

    function _getGiveaway(uint256 giveawayId) internal view returns (Giveaway storage) {
        require(giveawayId > 0 && giveawayId <= giveawayCount, "Giveaway: WRONG_GIVEAWAY_ID");
        return giveaways[giveawayId];
    }

    /**
     * @notice Adds new claimings (rewards) inside existing giveaway
     * @param giveawayId id of giveaway where claimings are added
     * @param claimings data about rewards
     */
    function addClaimingsToGiveaway(uint256 giveawayId, Claiming[] calldata claimings)
        public
        onlyMods
    {
        Giveaway storage giveaway = _getGiveaway(giveawayId);

        for (uint256 i = 0; i < claimings.length; i++) {
            giveaway.claimings.push(claimings[i]);
            emit AddClaiming(giveawayId, giveaway.claimings.length - 1);
        }
    }

    /**
     * @notice Disables or enables claiming inside of giveaway
     * @param giveawayId id of giveaway
     * @param claimingIds indexes of claimings inside of given giveaway
     * @param actives array of booleans, for coresponding claimingId shows if it should be enabled or disabled
     */
    function setClaimingsActive(
        uint256 giveawayId,
        uint256[] calldata claimingIds,
        bool[] calldata actives
    ) external onlyMods {
        require(claimingIds.length == actives.length, "Giveaway: NOT_SAME_LENGTH");
        Giveaway storage giveaway = _getGiveaway(giveawayId);

        for (uint256 i = 0; i < claimingIds.length; i++) {
            giveaway.claimings[claimingIds[i]].active = actives[i];
            emit SetClaimingActive(giveawayId, claimingIds[i], actives[i]);
        }
    }

    function _claim(
        uint256 giveawayId,
        uint256[] calldata withTokenIds,
        uint256[] calldata claimingIds
    ) internal {
        Giveaway storage giveaway = _getGiveaway(giveawayId);
        mapping(uint256 => mapping(uint256 => bool)) storage tokenClaims = claimed[giveawayId];

        for (uint256 i = 0; i < claimingIds.length; i++) {
            uint256 claimingId = claimingIds[i];

            require(claimingId < giveaway.claimings.length, "Giveaway: WRONG_CLAIMING_ID");

            Claiming storage claiming = giveaway.claimings[claimingId];
            require(claiming.active, "Giveaway: CLAIMING_NOT_ACTIVE");

            for (uint256 j = 0; j < withTokenIds.length; j++) {
                uint256 withTokenId = withTokenIds[j];

                require(
                    withTokenId >= giveaway.startTokenId && withTokenId <= giveaway.endTokenId,
                    "Giveaway: WRONG_TOKEN_ID"
                );

                require(!tokenClaims[withTokenId][claimingId], "Giveaway: ALREADY_CLAIMED");
                tokenClaims[withTokenId][claimingId] = true;

                emit Claimed(withTokenId, giveawayId, claimingId);
            }

            uint256 totalAmount = claiming.amount * withTokenIds.length;
            claiming.giveawayHanlder.handleGiveaway(msg.sender, claiming.tokenId, totalAmount);
        }
    }

    /**
     * @notice Claims rewards from giveaway. User must own token on this chain when calling this method.
     * @param giveawayId id of giveaway for which reward is claimed
     * @param withTokenIds token ids used to claim rewards
     * @param claimingIds indexes of claimings inside of giveaway for which user wants to claim rewards
     */
    function claim(
        uint256 giveawayId,
        uint256[] calldata withTokenIds,
        uint256[] calldata claimingIds
    ) external override {
        Giveaway storage giveaway = _getGiveaway(giveawayId);

        require(giveaway.needsProof == false, "Giveaway: NEEDS_PROOF");

        for (uint256 i = 0; i < withTokenIds.length; i++) {
            require(
                IERC721(giveaway.rewardToken).ownerOf(withTokenIds[i]) == msg.sender,
                "Giveaway: NOT_OWNER"
            );
        }

        _claim(giveawayId, withTokenIds, claimingIds);
    }

    function _verifySignature(bytes memory message, bytes memory signature)
        private
        view
        returns (bool)
    {
        address signer = keccak256(message).toEthSignedMessageHash().recover(signature);
        return (signer == mintingSigner);
    }

    /**
     * @notice Claims rewards from giveaway with given signature from backend. It means that base token is on other chain.
     * @param giveawayId id of giveaway for which reward is claimed
     * @param withTokenIds token ids used to claim rewards
     * @param claimingIds indexes of claimings inside of giveaway for which user wants to claim rewards
     * @param signatureProof signature obtained from backend
     * @param signatureTtl timestamp until signature is valid
     */
    function claimWithProof(
        uint256 giveawayId,
        uint256[] calldata withTokenIds,
        uint256[] calldata claimingIds,
        bytes calldata signatureProof,
        uint256 signatureTtl
    ) external override {
        require(block.timestamp <= signatureTtl, "Giveaway: TTL_PASSED");

        require(
            _verifySignature(
                abi.encode(msg.sender, giveawayId, withTokenIds, claimingIds, signatureTtl),
                signatureProof
            ),
            "Giveaway: INVALID_SIGNATURE"
        );

        Giveaway storage giveaway = _getGiveaway(giveawayId);

        require(giveaway.needsProof == true, "Giveaway: PROOF_NOT_NEEDED");

        _claim(giveawayId, withTokenIds, claimingIds);
    }

    /**
     * @notice Get all existing giveaways inside of this contract
     * @return retGiveaways list of all giveaways which exists
     */
    function getGiveaways() external view override returns (Giveaway[] memory) {
        Giveaway[] memory retGiveaways = new Giveaway[](giveawayCount);

        for (uint256 i = 1; i <= giveawayCount; i++) {
            retGiveaways[i - 1] = giveaways[i];
        }

        return retGiveaways;
    }

    /**
     * @notice Get all available claimings (rewards) for given giveaway id
     * @param giveawayId id of giveaway
     * @return claimings list of claimings inside of given giveaway
     */
    function getClaimings(uint256 giveawayId) external view override returns (Claiming[] memory) {
        Giveaway storage giveaway = _getGiveaway(giveawayId);
        return giveaway.claimings;
    }

    /**
     * @notice Gets list of claimed rewards inside giveaway for given token id
     * @param giveawayId id of giveaway
     * @param withTokenId id of token for which to check
     * @return bool[] returns list of booleans, for each claiming inside of giveaway it is true if given token already claimed
     */
    function getAlreadyClaimedForTokenId(uint256 giveawayId, uint256 withTokenId)
        external
        view
        override
        returns (bool[] memory)
    {
        Giveaway storage giveaway = _getGiveaway(giveawayId);
        bool[] memory alreadyClaimed = new bool[](giveaway.claimings.length);

        mapping(uint256 => bool) storage tokenClaims = claimed[giveawayId][withTokenId];

        for (uint256 i = 0; i < giveaway.claimings.length; i++) {
            alreadyClaimed[i] = tokenClaims[i];
        }

        return alreadyClaimed;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IArcadeGiveawayTokenHandler.sol";

interface IArcadeGiveaway {

    /**
    * @notice Data about giveaways
    * @param rewardToken address of erc721 token which user should own to be able to get reward
    * @param startTokenId minimum token id which counts for rewards
    * @param endTokenId maximum token id which counts for rewards
    * @param needsProof flag if it is crosschain giveaway and proof is needed
    * @param claimings data about each reward inside this giveaway
    */
    struct Giveaway {
        address rewardToken;
        uint256 startTokenId;
        uint256 endTokenId;
        bool needsProof;
        Claiming[] claimings;
    }

    /**
    * @notice Data about claimings (rewards) inside of giveaway
    * @param giveawayHanlder address of IArcadeGiveawayTokenHandler contract which handles sending tokens to the users
    * @param tokenId id of the token which is rewarded (not important for erc20)
    * @param amount number of rewarded tokens of the same type
    * @param active flag if claiming is currently active
    */
    struct Claiming {
        IArcadeGiveawayTokenHandler giveawayHanlder;
        uint256 tokenId;
        uint256 amount;
        bool active;
    }
  
    /**
    * @notice Get all existing giveaways inside of this contract
    * @return retGiveaways list of all giveaways which exists
    */
    function getGiveaways() external view returns(Giveaway[] memory);

    /**
    * @notice Get all available claimings (rewards) for given giveaway id
    * @param giveawayId id of giveaway
    * @return claimings list of claimings inside of given giveaway
    */
    function getClaimings(uint256 giveawayId) external view returns(Claiming[] memory);

    /**
    * @notice Gets list of claimed rewards inside giveaway for given token id
    * @param giveawayId id of giveaway
    * @param withTokenId id of token for which to check
    * @return bool[] returns list of booleans, for each claiming inside of giveaway it is true if given token already claimed
    */
    function getAlreadyClaimedForTokenId(uint256 giveawayId, uint256 withTokenId) external view returns(bool[] memory);

    /**
    * @notice Claims rewards from giveaway. User must own token on this chain when calling this method.
    * @param giveawayId id of giveaway for which reward is claimed
    * @param withTokenIds token ids used to claim rewards
    * @param claimingIds indexes of claimings inside of giveaway for which user wants to claim rewards
    */
    function claim(
        uint256 giveawayId, 
        uint256[] calldata withTokenIds,
        uint256[] calldata claimingIds
    ) external; 

    /**
    * @notice Claims rewards from giveaway with given signature from backend. It means that base token is on other chain.
    * @param giveawayId id of giveaway for which reward is claimed
    * @param withTokenIds token ids used to claim rewards
    * @param claimingIds indexes of claimings inside of giveaway for which user wants to claim rewards
    * @param signatureProof signature obtained from backend
    * @param signatureTtl timestamp until signature is valid
    */
    function claimWithProof(
        uint256 giveawayId, 
        uint256[] calldata withTokenIds,
        uint256[] calldata claimingIds, 
        bytes calldata signatureProof,
        uint256 signatureTtl
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IArcadeGiveawayTokenHandler {
    /**
    * @notice function called from ArcadeGiveaway which is used to send tokens to users
    * @param to address of user where to send token
    * @param tokenId id of the token (not important for erc20)
    * @param amountTimes number of tokens to send
    */
    function handleGiveaway(address to, uint256 tokenId, uint256 amountTimes) external;
}