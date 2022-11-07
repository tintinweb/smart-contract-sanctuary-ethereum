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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
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
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
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
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
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
     * @dev Calldata version of {processMultiProof}
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

contract ExclusivesYieldMap {
    uint256[] public YIELD_MAP = [
        127689209163621340800975369692887101994514425976037930576731308074077257728,
        6753153917220401196899736694153029318930711892062416711752429375504,
        8143398124117396899987774834844922863974330482361793009967084270027538472960,
        904846606982687445547887032273189160859675851540267250047031488062456627200,
        221341162137358637457934410757978275112249602007170343361381244113780800,
        1766847066449606368897757431762078670333126734602310857023130828808421377,
        14488145931195919154652211730312669894721622402245540684164609667634818973696,
        107839786674879660962284295149278626613731412961974160436439994662976,
        855714193558978439600180920575387457109609170093290301725354295296,
        107841432223488566448886464657249700657495345086125706239647338725376,
        42435387414890550099181881421510309192222220764397156893696321252516442624,
        904653735511092325205405702522746983442865158853724658543027888974473461824,
        53933083088045683062968712886885842090668581084422208199274109337608,
        8141852561846376966633364494578066340832735700825023457147381546746577682433,
        7237009034947508087999372842444878193351586692892858927190258174099139330050,
        1809251825692212629736148548004775327449081419426083295371710407222461726720,
        42404437501432180058531776494431691926741654233591182749010509113426445312,
        14163678425198499775079031680960538338078575496093723048039448098369437696,
        113299129636810209322791409486204458102728459423630940986290520940334813713,
        906861863088205211094597746465241253180168885996822765039538221723869777920,
        14588863116477154331764461313260546006573195324256945577023454839394036355592,
        30257310852239479033653781943308815454419542226881113133482467444473987136,
        26353791772251548151867970195806678612595411784355624021865267208,
        7237009890923735787562481262902339512443458934001442233980709118408403190336,
        251913741659111010848457020105384818928415929242265780952450868143226880,
        10063960881820201593675291886165623334308687336540197642300748756910973386768,
        7351850636542857659901632359859819723445084295634860096310858908355042508801,
        1809251833380016350089876474113563869124297516159721017250839217992007422978,
        951104854286571783208133907009074371232312303136073372744624177216,
        14356064602972600589748753907742128318739053374838267391099376786586206272,
        7238803483205057291789354599244276030967730650142414209554458908525837942786,
        224306771080334774167065072968001954953696202454525699444820666472235016,
        113078212146022285371799082393245919705963271557061666824257666410510091265,
        14700168064353879710598725997397176632414730459792095013297043515395312451648,
        15406906404987710370678569893662259257989112169811933387866230488841072934912,
        466530931455402736694290967607979784713001307600537720088663197527134175232,
        906395995104510267405146335308482677385440270153399930823313892608533610496,
        7585780026693951011482627432448869271820260484043928587553141161984,
        6740012377796368092512590431295524108232846806650884555150377091584,
        113078232365779811345067185773594749929150852809930468810917583206563717128,
        906451262997003458014082321514027972232888594543177317347691244013257491073,
        113519923912011595008512198883679820430683831855976137610662321283951230976,
        7238772431979525598438887302793835152656041262399837108196878931751516504066,
        118379184804620357792205379675498758854940509597182637391989759956098224128,
        1794454066620592157951083256470526566762981605162225958026251593932865608,
        14474011155508671486791512291545797300541743934179547279151429563876777132544,
        113079090029286086210336889245199195099549637127375276628487137132764234248,
        34563494177444330947274478893706677544627277771697322024963795847249920,
        904626142007301553581652972237627498579873114720395349012578344521825517568,
        14488591148913612073061307345770174297937538647232319597193655577988573462528,
        3457823787866344712686117832039218792975529736246459513907316273512448,
        1809282506111519445429699406957582417154249943304742438650319701142223192065,
        55268734837207824145625580455255387568304346831893000537489779153993729,
        904847099093865596522140236962995496036376488637811700395123008875496742976,
        127433844575320241592428800946479265618683713055309463557170681707162244169,
        9046256971691861529435617292951362444633158331217486644900811458644174438400,
        141375372167664336373990955765518093842425620077422766175527094373941510280,
        842528519930702968132587061673755889989271988690100710659506831872,
        113305969985885275312580760415007944698097287198703669553034562204634186752,
        1766847064778385117286005609999271580063413208369541046665640420935991872,
        13494782874591857290810104294732169541585520292341407105998479458304,
        7237005584282925287850080220409917625866194770839212719101591292290376176648,
        1991153821074889879648559879757476930928063262872123503706621672647917568,
        3561301430880806704632065855709544429574547346876693474557063173228470336,
        3561793239282898180129956422570005972210051656801055502201999514264437256,
        918981437407644722812439118464180761162935733758462115229503352478330257408,
        904680911453449683263202305584476759212635064755296398543971614037555355649,
        14476026464610977421774095971673611407465069238645853752591083284445765042177,
        7240539273252127955906133936318951131543738422584407175125987038040869306377,
        17668908760084434842213282868721737307911909751941415813573777397886779400,
        221718603039365295081533249583754996873794408800998779671592037546725440,
        14134938383219375486164444238479109723859805214341124516282178528323076104,
        7237033615676796050638573064237669191610500533620517567464614144233818816576,
        16129387965600301035811000112710144018440539041619528541699708798364057672,
        14359952734426553198912187632495361369158910179570702581256668441603211776,
        1259789995531782590154412715662325340653412082130742869699133419322689749504,
        9046257403052474941938603303641840649587120260274892449652214385456886153281,
        15901631270802851204552820941873458526156516555833692983023826853411422792,
        3451715674992821333700795175505918826028676663227588154392269698371584,
        1019471242722455121785783966193669719829701652335502260261384737706884472897,
        116611913122343696702287879134720683711343087729323246864159392157348659201,
        14474038769234299205080122666462799806694047821797400711566218246399882952832,
        842498383664910525231275040345923083389172625665506952342633743872,
        27607011920923242148788330674807481805009270601750753872695180134481921,
        27622150360433682032463218364699410653018529705344201403741426247798784,
        1017704394591389388828597773976732888748944250441704161613089220516405837833,
        14809541114165170860870095719723875792871240101783780657509466176,
        904629148039731883037256170128553661599509525106111692529594151263887425536,
        906392604891602550858704988087731411260025424846305311767502371557367353856,
        1766900984671724920440093735242524140592919450540546860778944999971356744,
        14474038761650194412083483414727729989458634441604697908963498258282961698816,
        127240757619941108308408961178450997360559305308259232856947489146367377408,
        7237009574354980202408023435265650670642126926145009597285851302741133000704,
        1019470817158775096598357196589097987842228210222704486240458982891511124032,
        7254674156032154336217058350043602349772460699659836735598086491076904878664,
        904625697298224563374329659623520538978022168948990626535023634548114104449,
        14474011154664550189184155117350792680795144919866412405937101540740586545665,
        10352621374592446859686861356000752357132795677755290852952342110666752,
        1766860546423736939957667382745409558746572509807994482938555604991738384,
        906392611736721971665073928643624589532943524841735976169328406107405942785,
        3450993295630485490545996418370363455588296746857931148839633171779593,
        1987702947875682371167700873324666625949945547007673112433848320178257920,
        1017707361029666607827641434929577056827015183098958030876992422803293864448,
        118386147105738135448168900540292710969639135357391453087087635893487435840,
        7265503326099145387412455242527196694404064649625661436141073700463210397696,
        14135207995850083549211386303615913891561671596781362991568365487225044993,
        248469717074484361122817141759026500163695769888095257742737053434511872,
        8256511280540672661225559411097223470381662237496123455253228054799622078464,
        14475778001729714992780821879469884102266619167805629333807862650756472537666,
        113078272805696999930766039027606061227608684993350363740153609103494611521,
        14359090016130341039250983986311775663286255439760245485124354682698891337,
        120152502151276925763349302054185068409437481943491329738316521882802716688,
        445654671558703322041850078082278151053253327410107833138026457161793600,
        113299068884579529034482442756143511200239602510821331384521101519943401537,
        7237005578280098551568211806181589330883481559192745478211019140041269051392,
        1017704018945736411658888247275988221725379335841022243163919229243357397120,
        906392545929677552302913899681359060986451221064839408926391696429670465600,
        66902235595922171653472526251057195641733120
    ];
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;


interface ILandMintUpdater {

    function updateLandMintingTime(uint256 _id) external;

}

interface ITierTwoMintUpdater {

    function updateTierTwoMintingTime(uint256 _id) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "solmate/tokens/ERC721.sol";
import "openzeppelin-contracts/contracts/utils/math/SafeMath.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "./PccTierTwoItem.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import "./MintUpdater.sol";

contract PccLand is ERC721, Ownable {

    using Strings for uint256;
    mapping(address => mapping(uint256 => bool)) public HasClaimed;

    uint256 public constant MAX_SUPPLY = 9856;
    uint256 public constant MAX_MINT = 20;
    uint256 public CurrentMaxSupply = 500;
    uint256 public MintPrice = 0.09 ether;
    string public BaseUri;
    uint256 public totalSupply;
    bytes32 public MerkleRoot;
    bool public PublicMintingOpen;
    uint256 public currentPhase;

    ILandMintUpdater public tokenContract;


    constructor()ERC721("Country Club Land", "PCCL") {
        
    }


    function claimLand(bytes32[] memory _proofs, uint256 _quantity) public payable canMint(_proofs, _quantity) {
        require(totalSupply + _quantity < CurrentMaxSupply, "too many minted");
        

        if(msg.value == 0 && !HasClaimed[msg.sender][currentPhase]){
            HasClaimed[msg.sender][currentPhase] = true;
        }

        for(uint256 i; i < _quantity; ){

            _mint(msg.sender, totalSupply);
            tokenContract.updateLandMintingTime(totalSupply);
            unchecked {
                ++i;
                ++totalSupply;
            }
        }

    }


    modifier canMint(bytes32[] memory _proofs, uint256 _qty) {
        if(PublicMintingOpen){
            require(msg.value == MintPrice * _qty, "incorrect ether");
            require(_qty <= MAX_MINT, "too many");
        }
        else{
            require(msg.value == 0, "free");
            
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _qty));
            require(
                MerkleProof.verify(_proofs, MerkleRoot, leaf),
                "not authorised"
            );
            require(!HasClaimed[msg.sender][currentPhase], "already claimed from this wallet");
        }
        _;
    }

    function setMintPrice(uint256 _priceInWei) public onlyOwner {
        MintPrice = _priceInWei;
    }


    function setMerkleRoot(bytes32 _root) public onlyOwner {
        MerkleRoot = _root;
    }

    function setBaseUri(string calldata _uri) public onlyOwner {
        BaseUri = _uri;
    }

    function setTokenContract(address _token) public onlyOwner{
        tokenContract = ILandMintUpdater(_token);
    }

    function setPublicMintingOpen(bool _mintingOpen) public onlyOwner {
        PublicMintingOpen =  _mintingOpen;
    }
    
    function incrementPhase() public onlyOwner {
        unchecked{
            ++currentPhase;
        }
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setTempMaxSupply(uint256 _supply) public onlyOwner {
        require(_supply > totalSupply, "cannot set supply to less than current supply");
        require(_supply <= MAX_SUPPLY, "cannot set supply to higher than max supply");
        CurrentMaxSupply = _supply;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        require(_ownerOf[id] != address(0), "not minted");
        return string(abi.encodePacked(BaseUri, id.toString()));
    }


}

// SPDX-License-Identifier: MIT




pragma solidity ^0.8.14;

import "solmate/tokens/ERC721.sol";
import "openzeppelin-contracts/contracts/utils/math/SafeMath.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./PccTierTwoItem.sol";
import "./MintUpdater.sol";




contract PccTierTwo is ERC721, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 constant NUMBER_OF_TICKETS = 6;
    uint256 constant MAX_NUMBER_PER_TYPE = 3000;
    uint256 constant MAX_MINT = 30;

    uint256[MAX_NUMBER_PER_TYPE][NUMBER_OF_TICKETS] private Ids;
    uint256[2000] private finalIds;
    uint256[NUMBER_OF_TICKETS] public CurrentSupplyByType;

    uint256 public totalSupply;
    uint256 public CurrentSupplyFinalSubcollection;
    address public TicketContract;
    address public FinalMintContract;
    string public BaseUri;

    ITierTwoMintUpdater public tokenContract;

    

    constructor() ERC721("PCC Tier Two", "PTT") {

 

    }

    function mintTeamTierTwo() external onlyOwner{
               uint256 remaining = MAX_NUMBER_PER_TYPE -
        CurrentSupplyByType[0];       

        for (uint256 index; index < 3; ) {

            --remaining;


            _safeMint(
                0x112E62d5906F9239D9fabAb7D0237A328F128e22,
                index
            );

            tokenContract.updateTierTwoMintingTime(index);

            Ids[0][index] = Ids[0][remaining] == 0
                ? remaining
                : Ids[0][remaining];

            unchecked {
                ++CurrentSupplyByType[0];
                ++totalSupply;
                ++index;
            }
        }
    }

    function mint(
        uint256 _ticketId,
        uint256 _quantity,
        address _to
    ) public {
        require(msg.sender == TicketContract, "not authorised");
        require(_quantity <= MAX_MINT, "cannot exceed max mint");
        require(CurrentSupplyByType[_ticketId] + _quantity <= MAX_NUMBER_PER_TYPE, "cannot exceed maximum");

        uint256 remaining = MAX_NUMBER_PER_TYPE -
        CurrentSupplyByType[_ticketId];       

        for (uint256 i; i < _quantity; ) {

            --remaining;

            uint256 index = getRandomNumber(remaining, uint256(block.number));

            uint256 id = ((Ids[_ticketId][index] == 0) ? index : Ids[_ticketId][index]) +
                    (MAX_NUMBER_PER_TYPE * _ticketId);

            _safeMint(
                _to,
                id
            );

            
            tokenContract.updateTierTwoMintingTime(id);

            Ids[_ticketId][index] = Ids[_ticketId][remaining] == 0
                ? remaining
                : Ids[_ticketId][remaining];

            unchecked {
                ++CurrentSupplyByType[_ticketId];
                ++totalSupply;
                ++i;
            }
        }
    }

    function finalSubcollectionMint(
        uint256 _quantity,
        address _to
    ) public {
        require(msg.sender == FinalMintContract, "not authorised");
        require(_quantity <= MAX_MINT, "cannot exceed max mint");
        require(CurrentSupplyFinalSubcollection + _quantity <= 2000, "cannot exceed maximum");

        uint256 remaining = 2000 -
        CurrentSupplyFinalSubcollection;       

        for (uint256 i; i < _quantity; ) {

            --remaining;

            uint256 index = getRandomNumber(remaining, uint256(block.number));

            _safeMint(
                _to,
                ((finalIds[index] == 0) ? index : finalIds[index]) + 18000
            );

            finalIds[index] = finalIds[remaining] == 0
                ? remaining
                : finalIds[remaining];

            unchecked {
                ++CurrentSupplyFinalSubcollection;
                ++totalSupply;
                ++i;
            }
        }
    }


    function getRandomNumber(uint256 maxValue, uint256 salt)
        private
        view
        returns (uint256)
    {
        if (maxValue == 0) return 0;

        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.difficulty +
                        ((
                            uint256(
                                keccak256(abi.encodePacked(tx.origin, msg.sig))
                            )
                        ) / (block.timestamp)) +
                        block.number +
                        salt
                )
            )
        );
        return seed.mod(maxValue);
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        require(_ownerOf[id] != address(0), "not minted");
        return string(abi.encodePacked(BaseUri, id.toString()));
    }

    function setFinalSubcollectionMintAddress(address _addr) external onlyOwner {
        FinalMintContract = _addr;
    }

    function setUri(string calldata _baseUri) external onlyOwner {
        BaseUri = _baseUri;
    }
    function setTicketContract(address _ticket) external onlyOwner{
                TicketContract = _ticket;
    }

    function setTokenContract(address _token) public onlyOwner{
        tokenContract = ITierTwoMintUpdater(_token);
    }

    function withdrawTokens(IERC20 token) public onlyOwner {
		require(address(token) != address(0));
		uint256 balance = token.balanceOf(address(this));
		token.transfer(msg.sender, balance);
	}


    modifier onlyTicketContract() {
        require(msg.sender == TicketContract, "not authorised address");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "solmate/tokens/ERC1155.sol";
import "src/PccToken.sol";
import "src/PccTierTwo.sol";
import "openzeppelin-contracts/contracts/utils/math/SafeMath.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./PccTierTwo.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";




contract PccTierTwoItem is ERC1155, Ownable {
    using Strings for uint256;
    PccToken public TokenContract;
    PccTierTwo public TierTwo;

    string public symbol = "PTTI";
    string public name = "PCC Tier Two Item";

    uint256[6] public ItemPrice;
    string public BaseUri;

    bool[6] public IsForSale;

    constructor(PccTierTwo _tierTwo) {

        TierTwo = _tierTwo;
    }

    function purchaseTierTwo(uint256 _ticketId, uint256 _quantity) public {
        require(
            balanceOf[msg.sender][_ticketId] >= _quantity,
            "not enough tickets"
        );
        require(IsForSale[_ticketId], "not for sale currently");

        _burn(msg.sender, _ticketId, _quantity);
        TierTwo.mint(_ticketId, _quantity, msg.sender);
    }

    function purchaseTicket(uint256 _ticketId, uint256 _quantity) public {
        uint256 price = ItemPrice[_ticketId];
        require(price > 0, "sale not open for this item");

        TokenContract.payForTierTwoItem(msg.sender, price * _quantity);
        _mint(msg.sender, _ticketId, _quantity, "");
    }

    function uri(uint256 id) public view override returns (string memory) {
        return string(abi.encodePacked(BaseUri, id.toString()));
    }

    function setPricePerTicket(uint256 _ticketId, uint256 _price)
        external
        onlyOwner
    {
        ItemPrice[_ticketId] = _price * 1 ether;
    }

    function setTokenContract(PccToken _token) external onlyOwner {
        TokenContract = _token;
    }

    function setUri(string calldata _baseUri) external onlyOwner {
        BaseUri = _baseUri;
    }

    function setIsForSale(bool _isForSale, uint256 _ticketId)
        external
        onlyOwner
    {
        IsForSale[_ticketId] = _isForSale;
    }

    	function withdrawTokens(IERC20 token) public onlyOwner {
		require(address(token) != address(0));
		uint256 balance = token.balanceOf(address(this));
		token.transfer(msg.sender, balance);
	}

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "solmate/tokens/ERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import "./ExclusivesYieldMap.sol";
import "./PccTierTwoItem.sol";
import "./PccLand.sol";
import "./MintUpdater.sol";
import "./PccTierTwo.sol";

struct TokenBucket {
    uint256 AvailableCurrently;
    uint256 DailyYield;
    uint256 MaxYield;
    uint256 CurrentYield;
    uint256 LastClaimTimestamp;
}


contract PccToken is ERC20, Ownable, ExclusivesYieldMap, ILandMintUpdater {
    uint256 public constant SECOND_RATE_FOR_ONE_PER_DAY = 11574074074074;
    uint256 public packedNumbers;

    PccTierTwoItem public TierTwoItem;
    IERC721 public TierTwo;

    bytes32 public MerkleRoot;

    event AddedClaimBucket(
        string indexed _name,
        uint256 _dailyYield,
        uint256 _maxYield
    );

    mapping(string => TokenBucket) public TokenClaimBuckets;
    mapping(address => bool) public ClaimedAirdrop;

    uint256[5] public EXCLUSIVES_DAILY_YIELD = [
        5 * SECOND_RATE_FOR_ONE_PER_DAY,
        10 * SECOND_RATE_FOR_ONE_PER_DAY,
        25 * SECOND_RATE_FOR_ONE_PER_DAY,
        50 * SECOND_RATE_FOR_ONE_PER_DAY,
        100 * SECOND_RATE_FOR_ONE_PER_DAY
    ];
    IERC721 immutable public EXCLUSIVES_CONTRACT;
    IERC721 immutable public landContract;

    uint256 public EXCLUSIVES_START_TIME;

    uint256 private constant MAX_VALUE_3_BIT_INT = 7;

    uint256 contractCount;

    mapping(uint256 => uint256) public test;

    mapping(IERC721 => uint256) public NftContracts;

    mapping(IERC721 => mapping(uint256 => uint256)) public LastClaimedTimes;

    mapping(IERC721 => uint256) public FirstClaimTime;

    constructor(PccLand _land, PccTierTwoItem _ticket, PccTierTwo _tierTwo, IERC721 _nft1, IERC721 _nft2, IERC721 _nft3) ERC20("YARN", "PCC Yarn", 18) {
        TierTwoItem = _ticket;

        EXCLUSIVES_CONTRACT = IERC721(0x9e8a92F833c0ae4842574cE9cC0ef4c7300Ddb12);

        landContract = IERC721(address(_land));
        TierTwo = IERC721(address(_tierTwo));

        EXCLUSIVES_START_TIME = block.timestamp;

        FirstClaimTime[
            _nft1
        ] = block.timestamp; //PCC
        FirstClaimTime[
            _nft2
        ] = block.timestamp; //kittens
        FirstClaimTime[
            _nft3
        ] = block.timestamp; //grandmas

        addNewContract(IERC721(address(_tierTwo)), 5);
        addNewContract(landContract, 5);

        addTokenBucket(
        "employee",
        7847312 ether, //start number
        12960 ether,    //daily yield
        78803313 ether); //max tokens

        addTokenBucket(
        "team",
        16176000 ether, //start number
        51840 ether,   //daily yield
        300000000 ether); //max tokens


            addNewContract(IERC721(address(_nft1)), 10);
            addNewContract(IERC721(address(_nft2)), 1);
            addNewContract(IERC721(address(_nft3)), 1);

    }

    function updateLandMintingTime(uint256 _id) external {
        require(address(landContract) == msg.sender, "not authorised");

        LastClaimedTimes[landContract][_id] = block.timestamp;
    }

    function updateTierTwoMintingTime(uint256 _id) external {
        require(address(TierTwo) == msg.sender, "not authorised");

        LastClaimedTimes[TierTwo][_id] = block.timestamp;
    }

    function payForTierTwoItem(address _sender, uint256 _amount) public {
        address tierTwoAddress = address(TierTwoItem);
        require(msg.sender == tierTwoAddress, "not authorised");
        require(balanceOf[_sender] >= _amount, "insufficient balance");

        balanceOf[_sender] -= _amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[tierTwoAddress] += _amount;
        }

        emit Transfer(_sender, tierTwoAddress, _amount);
    }

    function burn(address _from, uint256 _quantity) public onlyTicketContract {
        _burn(_from, _quantity);
    }

    function addTokenBucket(
        string memory _name,
        uint256 _startNumber,
        uint256 _dailyYield,
        uint256 _maxYield
    ) private {
        TokenBucket memory bucket = TokenBucket(
            _startNumber,
            _dailyYield,
            _maxYield,
            0,
            uint80(block.timestamp)
        );

        TokenClaimBuckets[_name] = bucket;
        emit AddedClaimBucket(_name, _dailyYield, _maxYield);
    }


    function addNewContract(IERC721 _contract, uint256 _yield)
        private

    {
        require(NftContracts[_contract] == 0, "duplicate contract");
        require(_yield < 11 && _yield > 0, "yield out of range");
        unchecked {
            ++contractCount;
        }

        NftContracts[_contract] = _yield * SECOND_RATE_FOR_ONE_PER_DAY;
    }

    function claimCommunitityAirdrop(
        bytes32[] calldata _merkleProof,
        uint256 _amount
    ) public {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _amount));
        require(
            MerkleProof.verify(_merkleProof, MerkleRoot, leaf),
            "not authorised"
        );
        require(!ClaimedAirdrop[msg.sender], "already claimed airdrop");

        ClaimedAirdrop[msg.sender] = true;
        _mint(msg.sender, _amount * 1 ether);
    }

    function setMerkleRoot(bytes32 _root) public onlyOwner {
        MerkleRoot = _root;
    }

    function claimTokens(IERC721[] calldata _contracts, uint256[] calldata _ids)
        public
    {
        uint256 contractsLength = _contracts.length;
        require(contractsLength == _ids.length, "invalid array lengths");
        uint256 amountToMint;

        for (uint256 i; i < contractsLength; ) {
            amountToMint += getYield(_contracts[i], _ids[i], msg.sender);
            LastClaimedTimes[_contracts[i]][_ids[i]] = block.timestamp;
            unchecked {
                ++i;
            }
        }

        _mint(msg.sender, amountToMint);
        require(totalSupply < 2000000000 ether, "reached max cap");
    }

    function currentTokenToClaim(
        address _owner,
        IERC721[] calldata _contracts,
        uint256[] calldata _ids
    ) external view returns (uint256) {
        uint256 contractsLength = _contracts.length;
        require(contractsLength == _ids.length, "invalid array lengths");
        uint256 amountToClaim;

        for (uint256 i; i < contractsLength; ) {
            unchecked {
                amountToClaim += getYield(_contracts[i], _ids[i], _owner);
                ++i;
            }
        }

        return amountToClaim;
    }

    function availableFromBucket(string calldata _name)
        public
        view
        returns (uint256)
    {
        TokenBucket memory bucket = TokenClaimBuckets[_name];

        require(bucket.LastClaimTimestamp > 0, "bucket does not exist");

        uint256 amountToMint = bucket.AvailableCurrently;

        amountToMint +=

                (block.timestamp - bucket.LastClaimTimestamp) *
                    (bucket.DailyYield / 86400)
            ;

        if (bucket.CurrentYield + (amountToMint) > bucket.MaxYield) {
            return bucket.MaxYield - bucket.CurrentYield;
        }

        return amountToMint;
    }

    function bucketMint(string calldata _name, uint256 _amount)
        public
        onlyOwner
    {
        TokenBucket memory bucket = TokenClaimBuckets[_name];

        require(bucket.LastClaimTimestamp > 0, "bucket does not exist");

        uint256 amountToMint = bucket.AvailableCurrently;

        uint256 timeSinceLastClaim = (block.timestamp - bucket.LastClaimTimestamp);

        amountToMint += (timeSinceLastClaim * (bucket.DailyYield / 86400));

        bucket.CurrentYield += _amount;
        require(
            bucket.CurrentYield <= bucket.MaxYield && amountToMint >= _amount,
            "cannot mint this many from this bucket"
        );

        _mint(msg.sender, _amount);


        bucket.AvailableCurrently = amountToMint - _amount;
        bucket.LastClaimTimestamp = uint80(block.timestamp);

        TokenClaimBuckets[_name] = bucket;
    }

    function getYield(
        IERC721 _contract,
        uint256 _id,
        address _operator
    ) private view returns (uint256) {
        address owner = _contract.ownerOf(_id);
        require(
            owner == _operator || _contract.isApprovedForAll(owner, _operator),
            "not eligible"
        );
        if (_contract == EXCLUSIVES_CONTRACT) {
            return getExclusivesYield(_id);
        } else {
            return getNftYield(_contract, _id);
        }
    }

    function getExclusivesYield(uint256 _id) public view returns (uint256) {
        uint256 lastClaim = (
            LastClaimedTimes[EXCLUSIVES_CONTRACT][_id] == 0
                ? EXCLUSIVES_START_TIME
                : LastClaimedTimes[EXCLUSIVES_CONTRACT][_id]
        );
        return
            (block.timestamp - lastClaim) *
            EXCLUSIVES_DAILY_YIELD[getExclusivesDailyYield(_id)];
    }

    function getNftYield(IERC721 _nft, uint256 _id)
        public
        view
        returns (uint256)
    {
        uint256 lastClaim = (
            LastClaimedTimes[_nft][_id] == 0
                ? FirstClaimTime[_nft] == 0
                    ? block.timestamp - (5 days - 1)
                    : FirstClaimTime[_nft]
                : LastClaimedTimes[_nft][_id]
        );
        return (block.timestamp - lastClaim) * NftContracts[_nft];
    }

    function getExclusivesDailyYield(uint256 _id)
        public
        view
        returns (uint256)
    {
        return unpackNumber(YIELD_MAP[_id / 85], _id % 85);
    }

    function unpackNumber(uint256 _packedNumbers, uint256 _position)
        private
        pure
        returns (uint256)
    {
        unchecked {
            uint256 number = (_packedNumbers >> (_position * 3)) &
                MAX_VALUE_3_BIT_INT;
            return number;
        }
    }

    modifier onlyTicketContract() {
        require(address(TierTwoItem) == msg.sender, "only ticket contract");
        _;
    }
}