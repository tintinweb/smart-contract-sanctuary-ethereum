/**
 *Submitted for verification at Etherscan.io on 2022-05-05
*/

pragma solidity 0.8.7;


// SPDX-License-Identifier: Unlicense
interface ITraits {
  function tokenURI(uint256 tokenId) external view returns (string memory);
  function tokenURINotRevealed(uint256 tokenId) external view returns (string memory);
  function tokenURITopTalents(uint8 topTalentNo, uint256 tokenId) external view returns (string memory);
}

interface IDrawSvg {
  function drawSvg(
    string memory svgBreedColor, string memory svgBreedHead, string memory svgOffhand, string memory svgArmor, string memory svgMainhand
  ) external view returns (string memory);
  function drawSvgNew(
    string memory svgBreedColor, string memory svgBreedHead, string memory svgOffhand, string memory svgArmor, string memory svgMainhand
  ) external view returns (string memory);
}

interface INameChange {
  function changeName(address owner, uint256 id, string memory newName) external;
}

interface IDogewood {
    // struct to store each token's traits
    struct Doge2 {
        uint8 head;
        uint8 breed;
        uint8 color;
        uint8 class;
        uint8 armor;
        uint8 offhand;
        uint8 mainhand;
        uint16 level;
        uint16 breedRerollCount;
        uint16 classRerollCount;
        uint8 artStyle; // 0: new, 1: old
    }

    function getTokenTraits(uint256 tokenId) external view returns (Doge2 memory);
    function getGenesisSupply() external view returns (uint256);
    function validateOwnerOfDoge(uint256 id, address who_) external view returns (bool);
    function unstakeForQuest(address[] memory owners, uint256[] memory ids) external;
    function updateQuestCooldown(uint256[] memory doges, uint88 timestamp) external;
    function pull(address owner, uint256[] calldata ids) external;
    function manuallyAdjustDoge(uint256 id, uint8 head, uint8 breed, uint8 color, uint8 class, uint8 armor, uint8 offhand, uint8 mainhand, uint16 level, uint16 breedRerollCount, uint16 classRerollCount, uint8 artStyle) external;
    function transfer(address to, uint256 tokenId) external;
    // function doges(uint256 id) external view returns(uint8 head, uint8 breed, uint8 color, uint8 class, uint8 armor, uint8 offhand, uint8 mainhand, uint16 level);
}

interface IDogewoodForCommonerSale {
    function validateDogeOwnerForClaim(uint256 id, address who_) external view returns (bool);
}

interface ICastleForCommonerSale {
    function dogeOwner(uint256 id) external view returns (address);
}

// interface DogeLike {
//     function pull(address owner, uint256[] calldata ids) external;
//     function manuallyAdjustDoge(uint256 id, uint8 head, uint8 breed, uint8 color, uint8 class, uint8 armor, uint8 offhand, uint8 mainhand, uint16 level) external;
//     function transfer(address to, uint256 tokenId) external;
//     function doges(uint256 id) external view returns(uint8 head, uint8 breed, uint8 color, uint8 class, uint8 armor, uint8 offhand, uint8 mainhand, uint16 level);
// }
interface PortalLike {
    function sendMessage(bytes calldata message_) external;
}

interface CastleLike {
    function pullCallback(address owner, uint256[] calldata ids) external;
}

interface ERC20Like {
    function balanceOf(address from) external view returns(uint256 balance);
    function burn(address from, uint256 amount) external;
    function mint(address from, uint256 amount) external;
    function transfer(address to, uint256 amount) external;
    function transferFrom(address from, address to, uint256 value) external;
}

interface ERC1155Like {
    function mint(address to, uint256 id, uint256 amount) external;
    function burn(address from, uint256 id, uint256 amount) external;
}

interface ERC721Like {
    function transferFrom(address from, address to, uint256 id) external;   
    function transfer(address to, uint256 id) external;
    function ownerOf(uint256 id) external returns (address owner);
    function mint(address to, uint256 tokenid) external;
}

interface QuestLike {
    struct GroupConfig {
        uint16 lvlFrom;
        uint16 lvlTo;
        uint256 entryFee; // additional entry $TREAT
        uint256 initPrize; // init prize pool $TREAT
    }
    struct Action {
        uint256 id; // unique id to distinguish activities
        uint88 timestamp;
        uint256 doge;
        address owner;
        uint256 score;
        uint256 finalScore;
    }

    function doQuestByAdmin(uint256 doge, address owner, uint256 score, uint8 groupIndex, uint256 combatId) external;
}

interface IOracle {
    function request() external returns (uint64 key);
    function getRandom(uint64 id) external view returns(uint256 rand);
}

interface IVRF {
    function getRandom(uint256 seed) external returns (uint256);
    function getRandom(string memory seed) external returns (uint256);
    function getRand(uint256 nonce) external view returns (uint256);
    function getRange(uint min, uint max,uint nonce) external view returns(uint);
}

interface ICommoner {
    // struct to store each token's traits
    struct Commoner {
        uint8 head;
        uint8 breed;
        uint8 palette;
        uint8 bodyType;
        uint8 clothes;
        uint8 accessory;
        uint8 background;
        uint8 smithing;
        uint8 alchemy;
        uint8 cooking;
    }

    function getTokenTraits(uint256 tokenId) external view returns (Commoner memory);
    function getGenesisSupply() external view returns (uint256);
    function validateOwner(uint256 id, address who_) external view returns (bool);
    function pull(address owner, uint256[] calldata ids) external;
    function adjust(uint256 id, uint8 head, uint8 breed, uint8 palette, uint8 bodyType, uint8 clothes, uint8 accessory, uint8 background, uint8 smithing, uint8 alchemy, uint8 cooking) external;
    function transfer(address to, uint256 tokenId) external;
}

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

// OpenZeppelin Contracts v4.4.0 (utils/cryptography/ECDSA.sol)
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

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)
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

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)
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

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)
/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
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

// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)
/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
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

// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)
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

// Creator: Chiru Labs
/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
// error ApprovalCallerNotOwnerNorApproved();
// error ApprovalQueryForNonexistentToken();
// error ApproveToCaller();
// error ApprovalToCurrentOwner();
// error BalanceQueryForZeroAddress();
// error MintToZeroAddress();
// error MintZeroQuantity();
// error OwnerQueryForNonexistentToken();
// error TransferCallerNotOwnerNorApproved();
// error TransferFromIncorrectOwner();
// error TransferToNonERC721ReceiverImplementer();
// error TransferToZeroAddress();
// error URIQueryForNonexistentToken();
contract ERC721A is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;
    address        implementation_;
    address public admin; //Lame requirement from opensea

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    // The tokenId of the next token to be minted.
    uint256 internal _currentIndex;

    // The number of tokens burned.
    uint256 internal _burnCounter;

    // Token name
    string internal _name;

    // Token symbol
    string internal _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // function init(string memory name_, string memory symbol_) internal {
    //     _name = name_;
    //     _symbol = symbol_;
    //     _currentIndex = _startTokenId();
    // }

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 1;
    }

    /**
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() public view returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex - _startTokenId() times
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to _startTokenId()
        unchecked {
            return _currentIndex - _startTokenId();
        }
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
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert("BalanceQueryForZeroAddress()");
        return uint256(_addressData[owner].balance);
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return _addressData[owner].aux;
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        _addressData[owner].aux = aux;
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr && curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    // Invariant:
                    // There will always be an ownership that has an address and is not burned
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        curr--;
                        ownership = _ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert("OwnerQueryForNonexistentToken()");
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownershipOf(tokenId).addr;
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
        if (!_exists(tokenId)) revert("URIQueryForNonexistentToken()");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        if (to == owner) revert("ApprovalToCurrentOwner()");

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert("ApprovalCallerNotOwnerNorApproved()");
        }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert("ApprovalQueryForNonexistentToken()");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSender()) revert("ApproveToCaller()");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transfer(address to, uint256 tokenId) external {
        require(msg.sender == ownerOf(tokenId), "NOT_OWNER");
        if (to == address(0)) revert("TransferToZeroAddress()");

        _transfer(msg.sender, to, tokenId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        bool isApprovedOrOwner = (_msgSender() == from ||
            isApprovedForAll(from, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert("TransferCallerNotOwnerNorApproved()");
        if (to == address(0)) revert("TransferToZeroAddress()");

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
        safeTransferFrom(from, to, tokenId, '');
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
        bool isApprovedOrOwner = (_msgSender() == from ||
            isApprovedForAll(from, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert("TransferCallerNotOwnerNorApproved()");
        if (to == address(0)) revert("TransferToZeroAddress()");

        _transfer(from, to, tokenId);
        if (to.isContract() && !_checkContractOnERC721Received(from, to, tokenId, _data)) {
            revert("TransferToNonERC721ReceiverImplementer()");
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _startTokenId() <= tokenId && tokenId < _currentIndex && !_ownerships[tokenId].burned;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity, _data, true);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address to,
        uint256 quantity,
        bytes memory _data,
        bool safe
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert("MintToZeroAddress()");
        if (quantity == 0) revert("MintZeroQuantity()");

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (safe && to.isContract()) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert("TransferToNonERC721ReceiverImplementer()");
                    }
                } while (updatedIndex != end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert("Reentrancy protection");
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex != end);
            }
            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
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
    ) internal {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        if (prevOwnership.addr != from) revert("TransferFromIncorrectOwner()");

        // bool isApprovedOrOwner = (_msgSender() == from ||
        //     isApprovedForAll(from, _msgSender()) ||
        //     getApproved(tokenId) == _msgSender());

        // if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        // if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = to;
            currSlot.startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev This is equivalent to _burn(tokenId, false)
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
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
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        address from = prevOwnership.addr;

        if (approvalCheck) {
            bool isApprovedOrOwner = (_msgSender() == from ||
                isApprovedForAll(from, _msgSender()) ||
                getApproved(tokenId) == _msgSender());

            if (!isApprovedOrOwner) revert("TransferCallerNotOwnerNorApproved()");
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            AddressData storage addressData = _addressData[from];
            addressData.balance -= 1;
            addressData.numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = from;
            currSlot.startTimestamp = uint64(block.timestamp);
            currSlot.burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert("TransferToNonERC721ReceiverImplementer()");
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}

/**
 * Should be:
        treat.setMinter(commoners, true)
 */
contract Commoners is ERC721A {

    using ECDSA for bytes32;

    // address implementation_;
    // address public admin;
    bool public initialized;
    mapping(address => bool) public auth;

    // sale variables
    uint256 public constant MAX_SUPPLY = 10_000;
    uint256 public constant DOGE_SUPPLY = 5_001;
    uint256 public totalClaimed; // total claimed amount of genesis doge holders
    // mapping of tokenNo => tokenPartner
    //   tokenNo values => [0: ETH, 1: $ZUG, 2: $CHEETH, 3: $MES, 4: $HONEYD, 5: $SHELL]
    mapping(uint8 => TokenPartner) tokenPartner;
    uint256 public initialSaleMinted; // minted amount of initial public sale

    IDogewood public dogewood;
    ERC20Like public treat;
    uint8 public saleStatus; // 0 : not in sale, 1: claim & WL & public, 2: public sale
    mapping(uint256 => bool) public dogeClaimed; // tokenId => isClaimed
    mapping(address => uint8) public whitelistMinted; // address => minted_amount

    mapping(uint256 => ICommoner.Commoner) internal commoners; // traits: tokenId => blockNumber
    mapping(uint256 => uint256) public coolBlocks; // cool blocks to lock metadata: tokenId => blockNumber
    ITraits public traits;
    IVRF public vrf; // random generator
    address public castle;

    // list of probabilities for each trait type
    // 0 - 7 are associated with head, breed, palette, bodyType, clothes, accessory, background, smithing, alchemy, cooking
    uint8[][10] public rarities;
    // list of aliases for Walker's Alias algorithm
    // 0 - 7 are associated with head, breed, palette, bodyType, clothes, accessory, background, smithing, alchemy, cooking
    uint8[][10] public aliases;
    // mapping from hashed(tokenTrait) to the tokenId it's associated with
    // used to ensure there are no duplicates
    mapping(uint256 => uint256) public existingCombinations;
    bool public revealed;
    mapping(uint256 => uint8) public topTalents; // commonerId => topTalentNo (1~4)

    /*///////////////////////////////////////////////////////////////
            --- End of data
    //////////////////////////////////////////////////////////////*/

    /*///////////////////////////////////////////////////////////////
                DATA STRUCTURE
    //////////////////////////////////////////////////////////////*/

    struct TokenPartner {
        bool mintActive;
        uint8 maxMintPerTx;
        uint16 totalMinted;
        uint16 mintQuantity;
        uint256 mintPrice;
        ERC20Like token;
    }

    /*///////////////////////////////////////////////////////////////
                EVENTS
    //////////////////////////////////////////////////////////////*/

    event AirdropTopTalent(uint8 talentId, uint256 commonerId);

    /*///////////////////////////////////////////////////////////////
                    MODIFIERS 
    //////////////////////////////////////////////////////////////*/

    modifier noCheaters() {
        uint256 size = 0;
        address acc = msg.sender;
        assembly {
            size := extcodesize(acc)
        }

        require(
            auth[msg.sender] || (msg.sender == tx.origin && size == 0),
            "you're trying to cheat!"
        );
        _;
    }


    /*///////////////////////////////////////////////////////////////
                    Admin methods
    //////////////////////////////////////////////////////////////*/

    function initialize(address dogewood_, address treat_, address vrf_) public {
        require(msg.sender == admin, "not admin");
        require(initialized == false, "already initialized");
        initialized = true;

        // init erc721a
        _name = "Commoners";
        _symbol = "COMMONERS";
        _currentIndex = _startTokenId();

        auth[msg.sender] = true;
        dogewood = IDogewood(dogewood_);
        treat = ERC20Like(treat_);
        vrf = IVRF(vrf_);
        revealed = false;

        // I know this looks weird but it saves users gas by making lookup O(1)
        // A.J. Walker's Alias Algorithm
        // head
        rarities[0] = [173, 155, 255, 206, 206, 206, 114, 114, 114];
        aliases[0] = [2, 2, 8, 0, 0, 0, 0, 1, 1];
        // breed
        rarities[1] = [255, 255, 255, 255, 255, 255, 255, 255];
        aliases[1] = [7, 7, 7, 7, 7, 7, 7, 7];
        // palette
        rarities[2] = [255, 188, 255, 229, 153, 76];
        aliases[2] = [2, 2, 5, 0, 0, 1];
        // bodyType
        rarities[3] = [255, 255];
        aliases[3] = [1, 1];
        // clothes
        rarities[4] = [209, 96, 66, 153, 219, 107, 112, 198, 198, 66, 132, 132, 254];
        aliases[4] = [4, 5, 0, 6, 6, 6, 12, 1, 1, 1, 3, 3, 12];
        // accessory
        rarities[5] = [209, 96, 66, 153, 219, 107, 112, 198, 198, 66, 132, 132, 254];
        aliases[5] = [4, 5, 0, 6, 6, 6, 12, 1, 1, 1, 3, 3, 12];
        // background
        rarities[6] = [142, 254, 244, 183, 122, 61];
        aliases[6] = [1, 5, 0, 0, 0, 0];
        // smithing
        rarities[7] = [204, 255, 153, 51]; // [0.5, 0.3, 0.15, 0.05]
        aliases[7] = [1, 3, 0, 0];
        // alchemy
        rarities[8] = [204, 255, 153, 51]; // [0.5, 0.3, 0.15, 0.05]
        aliases[8] = [1, 3, 0, 0];
        // cooking
        rarities[9] = [204, 255, 153, 51]; // [0.5, 0.3, 0.15, 0.05]
        aliases[9] = [1, 3, 0, 0];
    }

    function setRevealed() external {
        require(msg.sender == admin, "not admin");
        require(!revealed, "already revealed");
        revealed = true;
        _airdropTopTalents();
    }

    function setSaleStatus(uint8 status_) public {
        require(msg.sender == admin, "not admin");
        saleStatus = status_;
    }

    function withdraw() external payable {
        require(msg.sender == admin, "not admin");
        payable(0x8c8bbDB5C8D9c35FfB4493490172D2787648cAD8).transfer(address(this).balance);
    }

    function burnPartnerToken(uint8 tokenNo_) external {
        require(msg.sender == admin, "not admin");
        tokenPartner[tokenNo_].token.transfer(0x000000000000000000000000000000000000dEaD, tokenPartner[tokenNo_].token.balanceOf(address(this)));
    }

    function setTreat(address t_) external {
        require(msg.sender == admin);
        treat = ERC20Like(t_);
    }

    function setPartnerToken(uint8 tokenNo_, bool mintActive_, uint8 maxMintPerTx_, uint16 mintQuantity_,uint256 mintPrice_,  address token_) external {
        require(msg.sender == admin);
        tokenPartner[tokenNo_] = TokenPartner(mintActive_, maxMintPerTx_, 0, mintQuantity_, mintPrice_, ERC20Like(token_));
    }

    function setCastle(address c_) external {
        require(msg.sender == admin);
        castle = c_;
    }

    function setTraits(address t_) external {
        require(msg.sender == admin);
        traits = ITraits(t_);
    }

    function setAuth(address add, bool isAuth) external {
        require(msg.sender == admin);
        auth[add] = isAuth;
    }

    function transferOwnership(address newOwner) external {
        require(msg.sender == admin);
        admin = newOwner;
    }

    function mintReserve(uint16 quantity_, address to_) external {
        require(msg.sender == admin);
        // require(quantity_ <= 10, "exceed max quantity");
        require(totalSupply()+quantity_ <= MAX_SUPPLY-DOGE_SUPPLY, "sold out");
        _mintCommoners(to_, quantity_);
    }

    /*///////////////////////////////////////////////////////////////
                    Public methods
    //////////////////////////////////////////////////////////////*/

    function claimMint(uint16[] memory doges_) external noCheaters {
        require(saleStatus == 1, "claim is not active");
        require(doges_.length > 0, "empty doges");
        for (uint16 i = 0; i < doges_.length; i++) {
            require(dogeClaimed[doges_[i]] == false, "already claimed");
            require(IDogewoodForCommonerSale(address(dogewood)).validateDogeOwnerForClaim(doges_[i], msg.sender), "invalid owner");
        }

        treat.burn(msg.sender, doges_.length * 40 ether);
        for (uint16 i = 0; i < doges_.length; i++) {
            require(dogeClaimed[doges_[i]] == false, "already claimed");
            dogeClaimed[doges_[i]] = true;
        }
        totalClaimed += doges_.length;
        _mintCommoners(msg.sender, uint16(doges_.length));
    }

    // WL with mint with ETH
    //     Max mint per WL = 3
    //     Cost 0.035 ETH
    //     After 48hrs the unclaimed supply will go towards the public sale
    function whitelistMint(uint8 quantity_, bytes memory signature) external payable noCheaters {
        require(saleStatus == 1, "wl is not active");
        require(quantity_ > 0, "empty quantity");
        require(isValidSignature(msg.sender, signature), "invalid signature");
        require(whitelistMinted[msg.sender] + quantity_ <= 3, "exceeds wl quantity");
        require(totalSupply()+quantity_ <= MAX_SUPPLY-DOGE_SUPPLY+totalClaimed, "sold out");

        require(msg.value >= uint(quantity_) * 0.035 ether, "insufficient eth");
        whitelistMinted[msg.sender] = whitelistMinted[msg.sender] + quantity_;
        _mintCommoners(msg.sender, quantity_);
    }

    function isValidSignature(address user, bytes memory signature) internal view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked("whitelist", user));
        address signer_ = hash.toEthSignedMessageHash().recover(signature);
        return auth[signer_];
    }

    // Initial Public Sale
    //     Max mint per Tx = 6
    //     Cost 0.035 ETH or Partner Token
    function publicMintInitial(uint8 quantity_, uint8 tokenNo_) external payable noCheaters {
        require(saleStatus == 1, "status is not public sale");
        require(quantity_ <= 6, "exceed max quantity");
        require(initialSaleMinted+quantity_ <= 1000, "exceed initial sale amount");
        require(totalSupply()+quantity_ <= MAX_SUPPLY-DOGE_SUPPLY+totalClaimed, "sold out");

        if(tokenNo_ == 0) {
            require(msg.value >= uint(quantity_) * 0.035 ether, "insufficient eth");
        } else {
            require(tokenPartner[tokenNo_].mintActive == true, "invalid token");
            require(tokenPartner[tokenNo_].totalMinted + quantity_ <= tokenPartner[tokenNo_].mintQuantity, "minted out with this token");
            tokenPartner[tokenNo_].token.transferFrom(msg.sender, address(this), uint(quantity_) * tokenPartner[tokenNo_].mintPrice);
        }
        initialSaleMinted += quantity_;
        _mintCommoners(msg.sender, quantity_);
    }

    // Final Public Sale
    //     Max mint per Tx = 6
    //     Cost 0.035 ETH or Partner Token
    function publicMintFinal(uint8 quantity_, uint8 tokenNo_) external payable noCheaters {
        require(saleStatus == 2, "status is not public sale");
        require(quantity_ <= 6, "exceed max quantity");
        require(totalSupply()+quantity_ <= MAX_SUPPLY, "sold out");

        if(tokenNo_ == 0) {
            require(msg.value >= uint(quantity_) * 0.035 ether, "insufficient eth");
        } else {
            require(tokenPartner[tokenNo_].mintActive == true, "invalid token");
            require(tokenPartner[tokenNo_].totalMinted + quantity_ <= tokenPartner[tokenNo_].mintQuantity, "minted out with this token");
            tokenPartner[tokenNo_].token.transferFrom(msg.sender, address(this), uint(quantity_) * tokenPartner[tokenNo_].mintPrice);
        }
        _mintCommoners(msg.sender, quantity_);
    }

    /*///////////////////////////////////////////////////////////////
                    Internal methods
    //////////////////////////////////////////////////////////////*/

    function _airdropTopTalents() internal {
        uint256 airdropMax_ = _currentIndex > MAX_SUPPLY ? MAX_SUPPLY : (_currentIndex-1);
        for (uint8 i = 1; i <= 4; i++) {
            uint256 topCommoner_;
            do {
                topCommoner_ = (vrf.getRandom(i) % airdropMax_) + 1;
            } while (topTalents[topCommoner_] > 0);
            topTalents[topCommoner_] = i;

            // Set traits of top talents - commoners[topCommoner_]
            if(i == 1) {
                // Rudy Hammerpaw, Master Blacksmith
                //     uint8 head; Determined
                //     uint8 breed; Pitbull
                //     uint8 palette; 1
                //     uint8 bodyType; A
                //     uint8 clothes; Rudy's Smithing Apron
                //     uint8 accessory; Rudy's Eye Patch
                //     uint8 background; The Forge
                commoners[topCommoner_].head = 0;
                commoners[topCommoner_].breed = 6;
                commoners[topCommoner_].palette = 0;
                commoners[topCommoner_].bodyType = 0;
                commoners[topCommoner_].clothes = 13;
                commoners[topCommoner_].accessory = 13;
                commoners[topCommoner_].background = 6;
                commoners[topCommoner_].smithing = 5;
                commoners[topCommoner_].alchemy = 1;
                commoners[topCommoner_].cooking = 1;
            } else if(i == 2) {
                // Catharine Von Schbeagle, Savant of Science
                //     uint8 head; Excited
                //     uint8 breed; Beagle
                //     uint8 palette; 1
                //     uint8 bodyType; A
                //     uint8 clothes; Goggles of Science
                //     uint8 accessory; Von Schbeagle's Lab Coat
                //     uint8 background; Artificer's Lab
                commoners[topCommoner_].head = 9;
                commoners[topCommoner_].breed = 8;
                commoners[topCommoner_].palette = 0;
                commoners[topCommoner_].bodyType = 0;
                commoners[topCommoner_].clothes = 14;
                commoners[topCommoner_].accessory = 14;
                commoners[topCommoner_].background = 7;
                commoners[topCommoner_].smithing = 1;
                commoners[topCommoner_].alchemy = 5;
                commoners[topCommoner_].cooking = 1;
            } else if(i == 3) {
                // Charlie Chonkins, Royal Cook
                //     uint8 head; Content
                //     uint8 breed; Corgi
                //     uint8 palette; 1
                //     uint8 bodyType; A
                //     uint8 clothes; Royal Chef's Apron
                //     uint8 accessory; Royal Chef's Hat
                //     uint8 background; The Mess Hall
                commoners[topCommoner_].head = 10;
                commoners[topCommoner_].breed = 2;
                commoners[topCommoner_].palette = 0;
                commoners[topCommoner_].bodyType = 0;
                commoners[topCommoner_].clothes = 15;
                commoners[topCommoner_].accessory = 15;
                commoners[topCommoner_].background = 8;
                commoners[topCommoner_].smithing = 1;
                commoners[topCommoner_].alchemy = 1;
                commoners[topCommoner_].cooking = 5;
            } else if(i == 4) {
                // Prince Pom, Prince of Dogewood Kingdom
                //     uint8 head; Proud
                //     uint8 breed; Pomeranian
                //     uint8 palette; 1
                //     uint8 bodyType; A
                //     uint8 clothes; Coat of the Strategist
                //     uint8 accessory; Dogewood Royal Scepter
                //     uint8 background; The War Room
                commoners[topCommoner_].head = 11;
                commoners[topCommoner_].breed = 9;
                commoners[topCommoner_].palette = 0;
                commoners[topCommoner_].bodyType = 0;
                commoners[topCommoner_].clothes = 16;
                commoners[topCommoner_].accessory = 16;
                commoners[topCommoner_].background = 9;
                commoners[topCommoner_].smithing = 4;
                commoners[topCommoner_].alchemy = 4;
                commoners[topCommoner_].cooking = 4;
            }
            emit AirdropTopTalent(i, topCommoner_);
        }
    }

    function _mintCommoners(address to_, uint16 quantity_) internal {
        uint256 startTokenId = _currentIndex;
        for (uint256 id_ = startTokenId; id_ < startTokenId + quantity_; id_++) {
            uint256 seed = vrf.getRandom(id_);
            generate(id_, seed);
            coolBlocks[id_] = block.number;
        }
        // _safeMint(to_, quantity_);
        // _mint(to_, quantity_, '', false);
        // safe operation with max batch 10
        uint numBatch = quantity_ / 10;
        for (uint256 i = 0; i < numBatch; i++) {
            _mint(to_, 10, '', false);
        }
        uint left_ = quantity_ - (numBatch*10);
        if(left_ > 0) _mint(to_, left_, '', false);
    }

    /**
    * generates traits for a specific token, checking to make sure it's unique
    * @param tokenId the id of the token to generate traits for
    * @param seed a pseudorandom 256 bit number to derive traits from
    * @return t - a struct of traits for the given token ID
    */
    function generate(uint256 tokenId, uint256 seed) internal returns (ICommoner.Commoner memory t) {
        t = selectTraits(seed);
        commoners[tokenId] = t;
        return t;

        // keep the following code for future use, current version using different seed, so no need for now
        // if (existingCombinations[structToHash(t)] == 0) {
        //     doges[tokenId] = t;
        //     existingCombinations[structToHash(t)] = tokenId;
        //     return t;
        // }
        // return generate(tokenId, random(seed));
    }

    /**
    * uses A.J. Walker's Alias algorithm for O(1) rarity table lookup
    * ensuring O(1) instead of O(n) reduces mint cost by more than 50%
    * probability & alias tables are generated off-chain beforehand
    * @param seed portion of the 256 bit seed to remove trait correlation
    * @param traitType the trait type to select a trait for 
    * @return the ID of the randomly selected trait
    */
    function selectTrait(uint16 seed, uint8 traitType) internal view returns (uint8) {
        uint8 trait = uint8(seed) % uint8(rarities[traitType].length);
        if (seed >> 8 < rarities[traitType][trait]) return trait;
        return aliases[traitType][trait];
    }

    /**
    * selects the species and all of its traits based on the seed value
    * @param seed a pseudorandom 256 bit number to derive traits from
    * @return t -  a struct of randomly selected traits
    */
    function selectTraits(uint256 seed) internal view returns (ICommoner.Commoner memory t) {    
        t.head = selectTrait(uint16(seed & 0xFFFF), 0);
        seed >>= 16;
        t.breed = selectTrait(uint16(seed & 0xFFFF), 1);
        seed >>= 16;
        t.palette = selectTrait(uint16(seed & 0xFFFF), 2);
        seed >>= 16;
        t.bodyType = selectTrait(uint16(seed & 0xFFFF), 3);
        seed >>= 16;
        t.clothes = selectTrait(uint16(seed & 0xFFFF), 4);
        seed >>= 16;
        t.accessory = selectTrait(uint16(seed & 0xFFFF), 5);
        seed >>= 16;
        t.background = selectTrait(uint16(seed & 0xFFFF), 6);
        seed >>= 16;
        t.smithing = selectTrait(uint16(seed & 0xFFFF), 7);
        seed >>= 16;
        t.alchemy = selectTrait(uint16(seed & 0xFFFF), 8);
        seed >>= 16;
        t.cooking = selectTrait(uint16(seed & 0xFFFF), 9);
        seed >>= 16;
    }

    /**
    * converts a struct to a 256 bit hash to check for uniqueness
    * @param s the struct to pack into a hash
    * @return the 256 bit hash of the struct
    */
    function structToHash(ICommoner.Commoner memory s) internal pure returns (uint256) {
        return uint256(bytes32(
            abi.encodePacked(
                s.head,
                s.breed,
                s.palette,
                s.bodyType,
                s.clothes,
                s.accessory,
                s.background,
                s.smithing,
                s.alchemy,
                s.cooking
            )
        ));
    }


    /*///////////////////////////////////////////////////////////////
                    VIEWERS
    //////////////////////////////////////////////////////////////*/

    // function getGenesisSupply() external pure returns (uint256) {
    //     return GENESIS_SUPPLY;
    // }

    function validateOwner(uint256 id, address who_) external view returns (bool) { 
        return (ownerOf(id) == who_);
    }

    function getTokenTraits(uint256 tokenId) external view returns (ICommoner.Commoner memory) {
        require(revealed, "not revealed yet");
        require(coolBlocks[tokenId] != block.number, "ERC721Metadata: URI query for cooldown token");
        return ICommoner.Commoner({
            head: commoners[tokenId].head,
            breed: commoners[tokenId].breed,
            palette: commoners[tokenId].palette,
            bodyType: commoners[tokenId].bodyType,
            clothes: commoners[tokenId].clothes,
            accessory: commoners[tokenId].accessory,
            background: commoners[tokenId].background,
            smithing: commoners[tokenId].smithing,
            alchemy: commoners[tokenId].alchemy,
            cooking: commoners[tokenId].cooking
        });
    }

    /** RENDER */

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if(!revealed) return traits.tokenURINotRevealed(tokenId);
        // commoners[tokenId] empty check
        require(coolBlocks[tokenId] != block.number, "ERC721Metadata: URI query for nonexistent token");
        if(topTalents[tokenId] > 0) return traits.tokenURITopTalents(topTalents[tokenId], tokenId);
        return traits.tokenURI(tokenId);
    }

    /*///////////////////////////////////////////////////////////////
                    Travel FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function pull(address owner_, uint256[] calldata ids) external {
        require(revealed, "not revealed yet");
        require (msg.sender == castle, "not castle");
        for (uint256 index = 0; index < ids.length; index++) {
            _transfer(owner_, msg.sender, ids[index]);
        }
        CastleLike(msg.sender).pullCallback(owner_, ids);
    }

    function adjust(uint256 id, uint8 head, uint8 breed, uint8 palette, uint8 bodyType, uint8 clothes, uint8 accessory, uint8 background, uint8 smithing, uint8 alchemy, uint8 cooking) external {
        require(msg.sender == admin || auth[msg.sender], "not authorized");
        commoners[id].head = head;
        commoners[id].breed = breed;
        commoners[id].palette = palette;
        commoners[id].bodyType = bodyType;
        commoners[id].clothes = clothes;
        commoners[id].accessory = accessory;
        commoners[id].background = background;
        commoners[id].smithing = smithing;
        commoners[id].alchemy = alchemy;
        commoners[id].cooking = cooking;
    }

    // ERC721 receiver
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) public pure returns (bytes4) {
        return 0x150b7a02;
    }
}