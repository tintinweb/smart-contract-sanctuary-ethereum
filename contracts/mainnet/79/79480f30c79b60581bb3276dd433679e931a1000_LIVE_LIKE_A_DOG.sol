/**
 *Submitted for verification at Etherscan.io on 2022-12-30
*/

// SPDX-License-Identifier: MIT
// File: LIVE_LIKE_A_DOG_flat.sol


// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/cryptography/MerkleProof.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// File: @openzeppelin/contracts/utils/math/Math.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;


/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
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
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

// File: contracts/ERC721A.sol


// Creator: Chiru Labs

pragma solidity ^0.8.4;









error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintedQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerIndexOutOfBounds();
error OwnerQueryForNonexistentToken();
error TokenIndexOutOfBounds();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error UnableDetermineTokenOwner();
error URIQueryForNonexistentToken();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 * Does not support burning tokens to address(0).
 *
 * Assumes that an owner cannot have more than the 2**128 - 1 (max value of uint128) of supply
 */
contract ERC721A is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using Address for address;
    using Strings for uint256;

    struct TokenOwnership {
        address addr;
        uint64 startTimestamp;
    }

    struct AddressData {
        uint128 balance;
        uint128 numberMinted;
    }

    uint256 internal _currentIndex;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        if (index >= totalSupply()) revert TokenIndexOutOfBounds();
        return index;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
     * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
    public
    view
    override
    returns (uint256)
  {
    require(index < balanceOf(owner), "ERC721A: owner index out of bounds");
    uint256 numMintedSoFar = totalSupply();
    uint256 tokenIdsIdx = 0;
    address currOwnershipAddr = address(0);
    for (uint256 i = 0; i < numMintedSoFar; i++) {
      TokenOwnership memory ownership = _ownerships[i];
      if (ownership.addr != address(0)) {
        currOwnershipAddr = ownership.addr;
      }
      if (currOwnershipAddr == owner) {
        if (tokenIdsIdx == index) {
          return i;
        }
        tokenIdsIdx++;
      }
    }
    revert("ERC721A: unable to get token of owner by index");
  }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    function _numberMinted(address owner) internal view returns (uint256) {
        if (owner == address(0)) revert MintedQueryForZeroAddress();
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        if (!_exists(tokenId)) revert OwnerQueryForNonexistentToken();

        unchecked {
            for (uint256 curr = tokenId; curr >= 0; curr--) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (ownership.addr != address(0)) {
                    return ownership;
                }
            }
        }

        revert UnableDetermineTokenOwner();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return ownershipOf(tokenId).addr;
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
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

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
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) revert ApprovalCallerNotOwnerNorApproved();

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public override {
        if (operator == _msgSender()) revert ApproveToCaller();

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
    ) public override {
        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, _data)) revert TransferToNonERC721ReceiverImplementer();
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < _currentIndex;
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
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 3.4e38 (2**128) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.56e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint128(quantity);
            _addressData[to].numberMinted += uint128(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;

            for (uint256 i; i < quantity; i++) {
                emit Transfer(address(0), to, updatedIndex);
                if (safe && !_checkOnERC721Received(address(0), to, updatedIndex, _data)) {
                    revert TransferToNonERC721ReceiverImplementer();
                }

                updatedIndex++;
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
    ) private {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
            getApproved(tokenId) == _msgSender() ||
            isApprovedForAll(prevOwnership.addr, _msgSender()));

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.addr);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            _ownerships[tokenId].addr = to;
            _ownerships[tokenId].startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            if (_ownerships[nextTokenId].addr == address(0)) {
                if (_exists(nextTokenId)) {
                    _ownerships[nextTokenId].addr = prevOwnership.addr;
                    _ownerships[nextTokenId].startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
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
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) revert TransferToNonERC721ReceiverImplementer();
                else {
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
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
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
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
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

// File: contracts/LIVE_LIKE_A_DOG.sol



pragma solidity >= 0.8.6 <=0.9.0;






contract LIVE_LIKE_A_DOG is Ownable, ReentrancyGuard, ERC721A {
using Strings for uint256;

  uint256 public maxMintAmount = 30;
  mapping(address => bool) public whitelist;
  uint256 Price = 0.00149 ether;
  uint256 public maxSupply = 22023;
  bool public paused = true;
  bool public revealed = false;
  uint256 public constant WHITELIST_PRICE = 0 ether;
  string private  baseTokenUri;
  string public   placeholderTokenUri;

    struct SaleConfig {
    uint256 Price;
    uint256 AmountForWhitelist;
  }

  SaleConfig public saleConfig;

  constructor() ERC721A("LIVE LIKE A DOG", "LLD") {
     
  whitelist[0x57648447820f4a8526F4Ca52E8a36A7a300860e5] = true; whitelist[0x1F84bfd68A9d5033Ddfd36354a47baCB77C6a878] = true; whitelist[0x25A577A021ca9F2376D6487d99AB759C3c60a696] = true; whitelist[0x2f37E25d543ec6C29E1E5AafdDD3Bb4Bb931f725] = true; whitelist[0x40e4CfBFCC0a518ff0dd77F4D326611BE341E123] = true; whitelist[0x42205cE26Bbd01E51050052d22Bb95b52EEf2527] = true; whitelist[0x5C1643e4caa7a6d2eCD37Aca614c5B189b16e803] = true; whitelist[0x9D8682930aaa7d80cf343390ADd8D4E3545226Ab] = true; whitelist[0xB70eF825C8098b6c0857bba9AD780df9e75bFb2A] = true; whitelist[0xb7a4cDE186fF1D89CB5754F932c3e5Ba538b65c5] = true; whitelist[0xd3CA7303626563CD27D1A57b0bB731bf4B63013F] = true; whitelist[0xE78F9a3BB3A364CB8Bc35f264D2B9CeabA2e1D52] = true; whitelist[0x893D3F68fD0f1Cdaa5DC45b98055d80392F785C9] = true; whitelist[0x2702Ff48e2B708A3BEe78C01c5E87D7595519EB1] = true; whitelist[0xA4F6080e72DB588591E85a559E5BCb37219B9CF4] = true; whitelist[0x01A275A5FAf0a019aFD01586De63634DDB55d900] = true; whitelist[0x0565cCFe332F638a287A2EdfFa937eb0307922B5] = true; whitelist[0x1244050335847B8b59Dbc8C05103d2bA1517B361] = true; whitelist[0x1acbB8fe61fB4ed8395F29A622a548555D88CF55] = true; whitelist[0x205698CE308ac7Dd4bf2CDA5926836dcB0316E19] = true; whitelist[0x2F1D71d05a2Fd7F8236C19009C82029779255A93] = true; whitelist[0x3810edDF658de0FFBEBA4d74a8ec007f04B2B6eb] = true; whitelist[0x3915A6716Ff28CfeA66F9B0f644BC4a18f916072] = true; whitelist[0x3d2FF7C764c7A10d47BaaA988347af3A9A0B1999] = true; whitelist[0x4085ADb71f055ee28f4409873bbefD85BE6e1E61] = true; whitelist[0x4124b3fe4e11d0419588abE8960aB09E3Fc5BaDA] = true; whitelist[0x41C0F1468F2731671A6Dbe5135383A28Ad47a5B7] = true; whitelist[0x42608B5217416F6F8CB2aCe1f414AF3716B76489] = true; whitelist[0x55151b934f51FE58a18862e11B069d3e1695f332] = true; whitelist[0x5F3BaDFD6E15322D9D86Af95A62e21D769FE1a3F] = true; whitelist[0x6391ab34960F779bdE2d57eF9B83B2f47d489A1E] = true; whitelist[0x6d7A28cc6D19D9707B0a2aC313F4E5Bbf05CD56a] = true; whitelist[0x74F86D244008b8bEa2C1d611EB670196530BF075] = true; whitelist[0x78Bc3ca23d278f698cd3bdd4037cEE7f18c55F4a] = true; whitelist[0x79f7E64F53CFfb93f9785a5B8F34a39654ae4590] = true; whitelist[0x84B24DC780cb6DE5bB4394d0e19EFBabEB2d4F4d] = true; whitelist[0x8C3a64AA67686D3B4699d817C13FF71B12534641] = true; whitelist[0x8d1544F93923126B7f6D84F5bCF11856FeE57Fb6] = true; whitelist[0x8f121A454ab86a3BbB90547F764cc95420FA3B97] = true; whitelist[0x9Fa89ff18068f00c9c0c82577aA8A729830Ca378] = true; whitelist[0xa8fF7872afbB6e06a912ca7a95F942CBcf69E276] = true; whitelist[0xb7F890197550BF6f87f4d1Ed92cC69A8BB32C04f] = true; whitelist[0xB9432fA0b73C8d36Ec799F48427693c3053419A5] = true; whitelist[0xC0a8e57Ba0Bc47C2453dd4Fe520e69a988786852] = true; whitelist[0xc636A5c78860Ca9Dd12457ca7af2f5d6dcb279f4] = true; whitelist[0xD845c99411c08C65db45Abc65741011ab0081b57] = true; whitelist[0xE16e9E9D309A67b3294De3B96070E21eB967017a] = true; whitelist[0xebB1220E79Bd6fe01489Ee4eb5C419485582FE8B] = true; whitelist[0xF06C2D7607a73ed521abBbdBe79C1B8Af48A6c65] = true; whitelist[0xF4D631fa4CB9322366bD5eBC25eA94dFCe1DDf09] = true; whitelist[0xf9b36a7C99A734949624f95FD3F927c4ECFEAB0D] = true; whitelist[0xFbfeC83D219fEfc04008E6b065a2BAF5F8Be7aDc] = true; whitelist[0xA86f5324129c34312187CdE5B42Fe283FC493fD8] = true; whitelist[0xccDc69E916e42a606444585aF8a3735d974Fb48A] = true; whitelist[0x04aa68FFC551b86EB2ed323FA897Cb946b2B8157] = true; whitelist[0x0AeB18Af829538D4F8feaB4d8d0a073491174969] = true; whitelist[0x42560517b33A7E68cda1640Aa47B6546BA585e30] = true; whitelist[0x4A8ce221AeEE731cd7F22EB59D7B69DE11E7a858] = true; whitelist[0x52dC5Fa1Be2428Ff782118c98291Aa812B60b4E2] = true; whitelist[0x5437500B3C72fBB66AF2C4bc6DF5f1C495D3a4bd] = true; whitelist[0x5F7754281a06F0B60cD330420Aa917e39f591C92] = true; whitelist[0x73a87E499c49BD14BeE8D12E3DAa73c97Cd9f9f2] = true; whitelist[0x7BC2eBe546aC66d37d0c933d64E060f0AD8ffaCf] = true; whitelist[0xc1b9aAEBB91399C7E7c002C3EE4b67148d4B2998] = true; whitelist[0xCAc5894367B71ED955df44c597d111647d418aF1] = true; whitelist[0x2E18F855a6b7749593Fa64479d49250Bf28018A7] = true; whitelist[0x536dCc00D8eBe2fD78E2A235dAE88322B18bbF83] = true; whitelist[0x99b0Ee8B91F0D1E7a32947df149Ad07fDaDFC8ca] = true; whitelist[0xcefBc24f9725516BDC329EDf5a300a5c03949b42] = true; whitelist[0xD7E51E919EFC08B3D8F02F86D9e4CFe3B5101958] = true; whitelist[0x2275B8be039e99F88835CE49B16285aD0e61d485] = true; whitelist[0x2C840c282dE8b08cbAfAfD488459F2fA50906888] = true; whitelist[0x2E6DE1dFebFfE1D5123e5AB342A6003f40ce71C1] = true; whitelist[0x5e75E7c69027175A16c16BA0c992b0935b3faf7E] = true; whitelist[0x61a002c7F723B8702Dc910D14e1d95a523a8FCCC] = true; whitelist[0x71bc7C03F5BEb715E40aCDB5Ab110e96E2214Cdc] = true; whitelist[0x793C7e1910F58c4c1a50448f4661D5C077214c1e] = true; whitelist[0x99C320B2C52443ec5D39CC24962a132B54260522] = true; whitelist[0x9ce16b0Ff00CEA66C954EFcD6Bc93c7bf2c06c3D] = true; whitelist[0xAae159043315daD76Ba431C970e6EE6acE1458AA] = true; whitelist[0xAE24fbe47ADB788150d9E3e7078040AbC22deD74] = true; whitelist[0xb0738A63A7E7De622661065a4B0695d046d29268] = true; whitelist[0xbEe1f7e369B3271088Ed58bF225DF13Cd96D32d5] = true; whitelist[0xDA1E0F4942Dde3bA7dAcED8fc97d978c5B930345] = true; whitelist[0xE15439FfE5e814e7502f8dA37435E77f5418d60F] = true; whitelist[0xE5463558a8241EC7bC70B202e7CB3D1465DbB124] = true; whitelist[0x0630E4A19505d253B0514fD01FDbE7e439F1A5Cb] = true; whitelist[0x0D0B3EF1487272F65681905063a35DB8CdC7d2D4] = true; whitelist[0x0DC87F37Acb9E6653991Fd365Cd92C142d07D43a] = true; whitelist[0x1d3Dd1da628E8F975523147182D47C14d537dB32] = true; whitelist[0x1DDCB237f234e1207F48624d242170F6cB8F8a7a] = true; whitelist[0x26ad010b488B67BA41b1A5C3dFEf10ba814D021A] = true; whitelist[0x31c4Eb8260e7005aAa63d8093699f236ED9bfF59] = true; whitelist[0x36e49F5Ab13fc41EB7598cDA84af9f6b92f6aD95] = true; whitelist[0x40C412E652cbcb8e381b7d69B2761820e138d89f] = true; whitelist[0x4D0852fCA6aB6f5D6cF13604611A3ee2B0b020c6] = true; whitelist[0x55D83306f7c02b4247A542a79E29A73AdA9Bb199] = true; whitelist[0x56dFFD232fc2C4f8bcd77887310cbA8076D3dD6b] = true; whitelist[0x570F1F3845a98B24EC7A82757F335838803A6cDb] = true; whitelist[0x57C9bCF0d1653B424c5F6cBB0436504Db56777fb] = true; whitelist[0x585c5598eeBf6f24982bFF282317F06A28170EB2] = true; whitelist[0x59cdc9C838B10C66B07B4D35A1aBA2f8FAb90b06] = true; whitelist[0x5bfEa1EB3FaA6eb85694BA28395f80EB8795Cf17] = true; whitelist[0x5cD0d3070E641c45766106bb1cD55fBf47095AF8] = true; whitelist[0x5D7896F73991C12Af4222748a9f3216024721618] = true; whitelist[0x5e2dbF20FC606896BBAa07E45C104Ca36Cf9Ca52] = true; whitelist[0x5f96511BA488C17879DA9425f39724D79c37d076] = true; whitelist[0x6C9486f50545AE405ea6b882bdee105A5FB78459] = true; whitelist[0x70f0E31C62bc9965c462790B6ACC6d0c655e99dE] = true; whitelist[0x739dD679224108509577652a62ab2A6150271E13] = true; whitelist[0x75a54C67330f4bb7d2Ab570Fdc410F4fc27C04de] = true; whitelist[0x75Cc9eC753070a4d1374e33aAc59619dA51F16b6] = true; whitelist[0x789F5EA765206BD040F5F86A03fcA4028E70931C] = true; whitelist[0x8a622Bc901de1fa2384d42FFA79606e446eD788F] = true; whitelist[0x8cBB211083B5B2A3210C6003703C060AC62Bebfd] = true; whitelist[0x8d83E6bDBbFabF862C9A503DA26a474aAA6C4907] = true; whitelist[0x8f123b70ab95aa2505bFe2A7B79A357FA24d53Df] = true; whitelist[0x90c01fC5F30AE6F64eB1a8565D0d5A6E98FD1feA] = true; whitelist[0x92eA6902C5023CC632e3Fd84dE7CcA6b98FE853d] = true; whitelist[0x96145139c8508Cf865efCa89e7c765eD5bf6235E] = true; whitelist[0x9902409aDd3263ebaccFeF71e3D95329623bFb30] = true; whitelist[0x9F3c44A7331Ca9DA2D3432Bcb0df91186a27E3D7] = true; whitelist[0xA8635B33E4d8d44d4468c2Fb23BE9Aff02457743] = true; whitelist[0xaAb918749E02d84EbeEcB45BC4bf7DC6770c1D6E] = true; whitelist[0xb360DDF74c9d0FB30E8D2CFFc2dA78CA85AB7b3a] = true; whitelist[0xb5619Ba9D7f67254e4C53c8bE903d951B551C9a5] = true; whitelist[0xb78F103De81747742B46bfd035764FD4734c80CD] = true; whitelist[0xB826F8dA4AcC747434Aa06cf6b18C0Fc9F84A69f] = true; whitelist[0xB84BE63f658365e94602d150b85FaB0cDC7Fc538] = true; whitelist[0xb891683fef799F0a619fb214408580f433748250] = true; whitelist[0xc479477db18101DD879Fc858932aeb2B373cb436] = true; whitelist[0xc6564E562706c83df79b6D479C2A0d412Fa18a23] = true; whitelist[0xc957775E49c99ca4a991048aD5dA79C5a5a8EB66] = true; whitelist[0xCaBfD430BaD193973fc88b84cFC22D5273Da94e5] = true; whitelist[0xcF2Eee8B0FC2e94e2C11344c5F30fdE16478339a] = true; whitelist[0xD1E1B4C6a090D92efBc683aa562142dABf0dc61d] = true; whitelist[0xD1E1B4C6a090D92efBc683aa562142dABf0dc61d] = true; whitelist[0xd813A0306FA07EC9bbF8ECAC119B130aBc9Bfb52] = true; whitelist[0xdC001A8f80FEd6F7e1b91B093e87d39ff0c39d02] = true; whitelist[0xDD47bE73FD91eCe2499c4500D0948f70E6B1c3b4] = true; whitelist[0xE10786ed6c8b7363aC502De7270CD8B9F8CD248a] = true; whitelist[0xe1E5440cc188BbA2e2Eeeb37d4fd698507dE2E41] = true; whitelist[0xE1fDd759488a5276C320AACAB12EA38Ca8c7fBdf] = true; whitelist[0xE524B912fB1f2471F3457ABe5B17Fb27ce84ab5D] = true; whitelist[0xe668569e8E4eC78a9054be071290f76FA420097d] = true; whitelist[0xe875831D33CF814Cb1EFEaB9898a680b393A6854] = true; whitelist[0xfD8BFcDb7306499f75e74187326dEd28df19f5E4] = true; whitelist[0xfDb78F8D4Db972BF2bEE69db56E1033D87654d32] = true; whitelist[0xfebDA30b5E3f47287992b9b64c3b0bae805a25e1] = true; whitelist[0xffAE3Cc0620469716356E8bad190bB53c5600d21] = true; whitelist[0xF0a63AF4C25D68F678E746d1136Abc3912757A6F] = true; whitelist[0xf706dEf6674c9fc5C543eF0834a17c0e97e45193] = true;
  whitelist[0x5C517656114e21596C373C38B782229B10CDB00b] = true; whitelist[0x7d035d8FfA4DdF40F042f32917C6059061241a6f] = true; whitelist[0x54F85eC7073ed8c12b3b38A78cb51479d4E0c0EA] = true; whitelist[0x82359081C428D0dc548202260B82ed4917669ecF] = true; whitelist[0x272e004b13438451224E38a36eF5A91B9B16e634] = true; whitelist[0x26783Ba680190553862B53727b523a00CF3BBa4E] = true; whitelist[0xc54Ac7EBE36aC18F710595AF1b711f45D0487C1e] = true; whitelist[0x90697a3b5D622E994DaE74F86a6F972fb46cB4FD] = true; whitelist[0x4d01C4F56E9e8fb98ED4E4fcAf820325c67bE6Ed] = true; whitelist[0xA4BaAa37eaA3f5Eff840f68aF934ceD5135E4782] = true; whitelist[0xF21b51505Adb20C14F07d62bf0F601992aEF10D5] = true; whitelist[0x2AE1227bF673956D0f2DB19A045E3096f6399c20] = true; whitelist[0x8CBD671A376aEF45B3eDe7Ea4a8C22a295a3C617] = true; whitelist[0xbCF35F9Ce2873658AADcB2100D75b00EE5330640] = true; whitelist[0x7057a4AD780A60Fd506bB4592858063f416599d2] = true; whitelist[0xF41EeA0Bf4edc6d381705d05166205824A30650d] = true; whitelist[0x93Bf4f77dE028F905A5dc44937D2e155646D8d49] = true; whitelist[0xcF2Eee8B0FC2e94e2C11344c5F30fdE16478339a] = true; whitelist[0x5435f1aF6067A1cf0151Bb505Bdc429E532b9B1b] = true; whitelist[0xcF23B1f68CA01cAb0D77faa5332Cd55A738e1ae9] = true; whitelist[0xDef954641494565FA21c9292Eb0FfabF763E7D18] = true; whitelist[0x4E0E3459E0DcDf451DA39f685B1953B7d345CE34] = true; whitelist[0xe9f7E6D12a17136440beD22Ab8933ff5F799b511] = true; whitelist[0x1E742b3B6EB80bEc0a1e84F3CB58913bc3C1ca3A] = true; whitelist[0x9A34B2AbE5c715126B2d3Bf9D334e00A1B06aEF8] = true; whitelist[0x548d12EE5AdBEeF06F0208AeE371EcD99ee5Af19] = true; whitelist[0x51ECC9824a76572a5f531cB60739f7A57c40276A] = true; whitelist[0x76B297179697d65D7216fd2edB9Ab7BB843B9eD7] = true; whitelist[0xF46938fb6329f8819Cd9b871a839cB0DF33d268a] = true; whitelist[0x2ACaFE2A5fc60126E2998B683BA71FCcb50A36Bd] = true; whitelist[0x362E05FB6b565AEE2dF6da5384343b6287510BC5] = true; whitelist[0x73941899af221CBAb18eD8BB03de642347948033] = true; whitelist[0xA302f5b72dA4F9097100E630B7Ef9aE68A896E74] = true; whitelist[0xA5F7cB7d419613777EEf87A2D04f85aecc88a7Ad] = true; whitelist[0xf706dEf6674c9fc5C543eF0834a17c0e97e45193] = true;  whitelist[0xe376705caAcc70a5a1b040D024C8A331fF8A66Ca] = true;  whitelist[0x9d90695B8E0CDE0d4Cdf2dD07643CD9C820ee1Cf] = true;  whitelist[0xd5dB1C7Abfe2A1Bc6bd82c21A2Cdd576E3d2462b] = true;  whitelist[0xd98d839275cf356Ec9E34A146C7EDaAa69f29022] = true;  whitelist[0xD6DF9dd48694F6F55EA4DB678cad073363863fBC] = true;  whitelist[0x42FF9Ed7d0a256c912515e5b4F0D7A5212A56b97] = true;  whitelist[0xA422492648e3e8b75ae756Dd7992Fa262E679358] = true;  whitelist[0x141f36d315F4145165c2d30261b21B6e61F52Cc8] = true;  whitelist[0x15867648EBFcEF76B07082f4a3be271996cE955E] = true;  whitelist[0xefa0A36E9648CF589f265Cb7C385059fCC213b2E] = true;  whitelist[0xe1Bb0406E38FE6e55c03f99030F5629ea9A675B8] = true;  whitelist[0xa469E51d286E627e5C2760D0689b060e9f3b2112] = true;  whitelist[0x1D9A294444830fc7Ee584ECA68BAbF5d5FFce18e] = true;  whitelist[0xd53b6ED0404aE84ed6fA8d4904B40Bd1e09BD2a4] = true;  whitelist[0x80E93D4Ae430Da4a4A66de6F25e8B2b7d36C8E61] = true;  whitelist[0x62715c036602B3C6252358E0dBACC4701252Aa4a] = true;  whitelist[0xE4c6D7f2bd9D193DA74Eb2e41aD1209219C1d81E] = true;  whitelist[0x4dcC55421c87fd4901fdF1Bd3319C7F6Eb4c76Ad] = true;  whitelist[0x78B237236A719E91aea1eE78a1Bd0513cF48965c] = true;  whitelist[0xEc6451c4A49d2A5495Db77810209715934426A2B] = true;  whitelist[0xD98FA744E31bb12d8F88aE4126Ed7B8fAC4E009E] = true;  whitelist[0x5B94a28677C05eB346b88dd964B3FB23b186346b] = true;  whitelist[0x649363A0FDfd8285D6b69710CcB42b083AB731e6] = true;  whitelist[0x057778c8FfaaAC2f2bE656cE1742F2747d807c4f] = true;  whitelist[0x028314259BA20F047bD65b752C7714202A1810e1] = true;  whitelist[0x2c4f2D587B87A68085E5660fBf6C5a4527f6FB29] = true;  whitelist[0x5d55D4155d6244922F7952a87B3FF90E465E2fac] = true;  whitelist[0x6836DA8B7D807506FB111343005e0fAb401EfED7] = true;  whitelist[0xF03cc725d979239DB5637bDc10C7b3980A4c446A] = true;  whitelist[0x0E219a7A21Fc7554E6f0eD694Da98A5753aD141d] = true;  whitelist[0x25EaE14113D4fA2ef209358019F6C2E78F0f2aBa] = true;  whitelist[0x6E619AC069D8696077266dAaEec5aB64eb009deD] = true; whitelist[0x9f687DE417937aC91C58E9c1d3038e738D7B0550] = true; whitelist[0xa32E9eC66e4661d62Dd4363A1579a7f04Bc1182B] = true; whitelist[0xDd46e88366876158D29883eF97e8EfCeB7f31957] = true; whitelist[0xA971FDf62C4346a36e6E8d4E8b9b04A30Df12Dc7] = true; whitelist[0x0d0eC51421dAe8aBc3ae198653279f9fB8D61c67] = true; whitelist[0x0AF6D8A2bF7a0708e3E3B2EC0dFbAAB9D5534d5e] = true; whitelist[0x1120e9059B2a12b57D942F8D586b8e6d78C4d28c] = true; whitelist[0x5a01feb1100f52Fc67A474A610FFE3DB549E7b7B] = true; whitelist[0x71b3EFF5e171c80A27B7Df479F43594737c83642] = true; whitelist[0x953a6f2527A9152598D820E2b857a33D1505e0E6] = true; whitelist[0x2b6f4845C20Eb4A3BF00255785711c96CE090CD3] = true; whitelist[0x2af043455Aa33bCeEd85134B9a35Cb6717b95a13] = true; whitelist[0x157434346fe2701A289D41834AF8A052143AFEB5] = true; whitelist[0x6Ed8082445E85795624db70859dF985ce86e4503] = true; whitelist[0x05be5bd318187b230F74C41C063Ac9aeE1212eF6] = true; whitelist[0xE95785E8a2185C3e9125A85879FC310976A49E3A] = true; whitelist[0x83283300b76f7Ee712D40d2751cF9061a227878E] = true; whitelist[0x2e9E9Bd26C64d70499b6F8C17ab0bb53c601978d] = true; whitelist[0x4565e398a3c9cA8FEbee295A0c94CB1E4b450D21] = true; whitelist[0x51187c2aa81E9a87320DE080948ede93A041C162] = true; whitelist[0xaD92c07db4Ca16D2Cd1fE4A36fA7a84B633ca942] = true; whitelist[0xCd11aBBC370dbCe80B81a250DF87b3226f2B1a49] = true; whitelist[0x9ad32A104c942B725EfBa82ef7f86F1208AFbCA9] = true;  whitelist[0x8d83E6bDBbFabF862C9A503DA26a474aAA6C4907] = true;  whitelist[0x99bFB0d876AB1DafD6D0a2B7c25E3e86fFAad4df] = true;  whitelist[0xF21fb2353377e60fA8A8DbFA22f1bc2EdAbA5E08] = true;  whitelist[0x3162d96F9AAb213143bD93d6d8c3d7589e5A4c1D] = true;  whitelist[0xc0fb9e6Dd8Dbf8542a930e13E23E17d2049Efa4a] = true;  whitelist[0x33BE249B512DCb6D2FC7586047ab0220397aF2d3] = true;  whitelist[0xDbdd866663855F4f3DE1a93669Bf9630176F72A7] = true;  whitelist[0x4b7d025c61632E414996843C6815E9aa962c0a02] = true;  whitelist[0x18dd0a35977F88E7aDaDE2682e3D9A585Ad3B87D] = true;  whitelist[0xB8f5fd1478F6d0b4c6C7473F749EAe9e0f60d309] = true;  whitelist[0x0A74E6dFEC50eB6A2E23Af4419C6Eb52e886F71E] = true;  whitelist[0xbDA2dfFbce4fB8933E0B3cEA42AeCa92dD54fb09] = true;  whitelist[0xC456eE074337aD909476D614fe0f0F0d1bF22C38] = true;  whitelist[0x18d074aFf48F0F101B1Cb13F7941B0bF7464A0B8] = true;  whitelist[0xf28217a9ea9b124B61F78783dEf3aF555996546b] = true;  whitelist[0x2DC8B722d06e58B10FCF835810EebF37e99f5A32] = true;  whitelist[0xE45Eac0f77576fcd6f01f7C119393e9e0214F743] = true;  whitelist[0xe5dc36Ac0f3c224D6a7e9840B02C4eD8c3587657] = true;  whitelist[0x3C74A8D0acc928B49F13D980075aeA9845AEA71c] = true;  whitelist[0x297ec58bCC731cD4a3b910e2Fd045b50Fb750147] = true;  whitelist[0x34367832d8Cf2561a03b4c5BfC387dEd2e6d936A] = true;  whitelist[0xe605a51bAE38e5F0D4c6C618D01a34a2BBBf9447] = true;  whitelist[0x7Bf18f8ACBbaA0b380859D7c16f071B8bFE5DB73] = true;  whitelist[0x642F1a5b0D3FA52528BCD2405fdE57e9afb3C254] = true;  whitelist[0x31036D78E00b1a9F523281B6dF94d6f316dDA8Aa] = true;  whitelist[0x67D3080137D899927E6cB552112Cf65b8633573a] = true;  whitelist[0xab3935F2142AF10C590506517a656bb9dcb2d948] = true; whitelist[0x93487B173Da8813316452374dB62E1Bb0CF66F15] = true; whitelist[0xB4314123401d8A5176297E3dAf2E46B56957B491] = true; whitelist[0xBC05b4B88E721BC8b144E90D6BF6E38226a22578] = true; whitelist[0x5c8Df1692E4fEc52D13220669B821Fdc26e3dC43] = true; whitelist[0xB74D9401F38F7001479cc16b567653F8ca6F5EE8] = true; whitelist[0x1dc161B0C412448FEa7F093f0F928DdcA57c3C43] = true; whitelist[0x0E003CBd2bD31C5067676B014ae0C65E97099b81] = true; whitelist[0x8C6DEA560ff0F481197735f863aA0771c416eE07] = true; whitelist[0xCE937A2D48e5BaF50230292C4192723C77Ddf989] = true; whitelist[0x65B02609A41133b254DAe5EE1722972E08084468] = true; whitelist[0x4E64C27E6F569d800d43915164f1b8b816bcd597] = true; whitelist[0xa38a453Ce05F5fFE47E993EbC38fDb2f8830f367] = true; whitelist[0xd299B9D5eDCE129FC14691e089300296d8cDF4a6] = true; whitelist[0x60D406BcdE29b0fc4397D9bc3d1FCc09a435A40f] = true; whitelist[0x73B41FAfc67fbee0Afd35EAEAba76e7468083f07] = true; whitelist[0xAA6571D1A85eBE35D739E010A1f1e3a1665Fc340] = true; whitelist[0x55D83306f7c02b4247A542a79E29A73AdA9Bb199] = true;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenUri;}

  modifier callerIsUser() {require(tx.origin == msg.sender, "The caller is another contract");
    _;}

   function addToWhitelist(address[] calldata toAddAddresses) external onlyOwner {
        for (uint i = 0; i < toAddAddresses.length; i++) {whitelist[toAddAddresses[i]] = true;} }

  function getMaxSupply() view public returns(uint256){return maxSupply;}

  function whitelistMint(uint256 quantity)  public payable callerIsUser
    {
    require(whitelist[msg.sender], "NOT_IN_WHITELIST");
    require(!paused, "contract paused");    
    require(totalSupply() + quantity <= maxSupply, "reached max supply"); 
    require(numberMinted(msg.sender) + quantity <= saleConfig.AmountForWhitelist, "can not mint this many");
      _safeMint(msg.sender, quantity);
      refundIfOver(WHITELIST_PRICE);  }
    
    function mint(uint256 quantity) public payable callerIsUser {
      require(!paused, "contract paused");    
      require(totalSupply() + quantity <= maxSupply, "reached max supply");   
      require(quantity <= maxMintAmount, "can not mint this many");
      uint256 totalCost = saleConfig.Price * quantity;
     _safeMint(msg.sender, quantity);
      refundIfOver(totalCost);  }

  function refundIfOver(uint256 price) private {
    require(msg.value >= price, "Need to send more ETH.");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price); } }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {tokenIds[i] = tokenOfOwnerByIndex(_owner, i);}
    return tokenIds; }

     function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        uint256 trueId = tokenId + 1;
        if(!revealed){return placeholderTokenUri;}
        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, trueId.toString(), ".json")) : ""; }

   function setTokenUri(string memory _baseTokenUri) external onlyOwner{
        baseTokenUri = _baseTokenUri;}

  function reveal() public onlyOwner {revealed = true;}

  function setPlaceholderTokenUri(string memory _notRevealedURI) public onlyOwner {placeholderTokenUri = _notRevealedURI;}

   function isPublicSaleOn() public view returns (bool) {return saleConfig.Price != 0; }
  
  uint256 public constant PRICE = 0.00149 ether;

  function InitInfoOfSale(uint256 price, uint256 amountForWhitelist) external onlyOwner {saleConfig = SaleConfig(price, amountForWhitelist);}

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {maxMintAmount = _newmaxMintAmount;}

  function setPrice(uint256 price) external onlyOwner {saleConfig.Price = price;}
    
function withdrawMoney() external onlyOwner {
    (bool success, ) = 0xF447B9ed137C405Ce908441701a8d6D5A4a1D287.call{value: address(this).balance}("");
    require(success, "Transfer failed."); }

  function pause(bool _state) public onlyOwner {paused = _state;}
  
  function numberMinted(address owner) public view returns (uint256) {return _numberMinted(owner);}

  function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {return ownershipOf(tokenId);}  
}