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

pragma solidity ^0.8.15;

/**
 * @title Contract ownership standard interface (event only)
 * @dev see https://eips.ethereum.org/EIPS/eip-173
 */
interface IERC173Events {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Context.sol";

import "./OwnableStorage.sol";
import "./IERC173Events.sol";

abstract contract OwnableInternal is IERC173Events, Context {
    using OwnableStorage for OwnableStorage.Layout;

    modifier onlyOwner() {
        require(_msgSender() == _owner(), "Ownable: sender must be owner");
        _;
    }

    function _owner() internal view virtual returns (address) {
        return OwnableStorage.layout().owner;
    }

    function _transferOwnership(address account) internal virtual {
        OwnableStorage.layout().setOwner(account);
        emit OwnershipTransferred(_msgSender(), account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("openzeppelin.contracts.storage.Ownable");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setOwner(Layout storage l, address owner) internal {
        l.owner = owner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./ITieredSalesInternal.sol";

interface ITieredSales is ITieredSalesInternal {
    function onTierAllowlist(
        uint256 tierId,
        address minter,
        uint256 maxAllowance,
        bytes32[] calldata proof
    ) external view returns (bool);

    function eligibleForTier(
        uint256 tierId,
        address minter,
        uint256 maxAllowance,
        bytes32[] calldata proof
    ) external view returns (uint256);

    function mintByTier(
        uint256 tierId,
        uint256 count,
        uint256 maxAllowance,
        bytes32[] calldata proof
    ) external payable;

    function remainingForTier(uint256 tierId) external view returns (uint256);

    function walletMintedByTier(uint256 tierId, address wallet) external view returns (uint256);

    function tierMints(uint256 tierId) external view returns (uint256);

    function totalReserved() external view returns (uint256);

    function reservedMints() external view returns (uint256);

    function tiers(uint256 tierId) external view returns (Tier memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./ITieredSalesInternal.sol";

interface ITieredSalesAdmin {
    function configureTiering(uint256, ITieredSalesInternal.Tier calldata) external;

    function configureTiering(uint256[] calldata, ITieredSalesInternal.Tier[] calldata) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface ITieredSalesInternal {
    struct Tier {
        uint256 start;
        uint256 end;
        address currency;
        uint256 price;
        uint256 maxPerWallet;
        bytes32 merkleRoot;
        uint256 reserved;
        uint256 maxAllocation;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ITieredSalesInternal.sol";
import "./TieredSalesStorage.sol";

import "../../access/ownable/OwnableInternal.sol";

/**
 * @title Sales mechanism for NFTs with multiple tiered pricing, allowlist and allocation plans
 */
abstract contract TieredSalesInternal is ITieredSalesInternal, Context, OwnableInternal {
    using TieredSalesStorage for TieredSalesStorage.Layout;

    function _configureTiering(uint256 tierId, Tier calldata tier) internal virtual {
        TieredSalesStorage.Layout storage l = TieredSalesStorage.layout();

        require(tier.maxAllocation >= l.tierMints[tierId], "LOWER_THAN_MINTED");

        if (l.tiers[tierId].reserved > 0) {
            require(tier.reserved >= l.tierMints[tierId], "LOW_RESERVE_AMOUNT");
        }

        if (l.tierMints[tierId] > 0) {
            require(tier.maxPerWallet >= l.tiers[tierId].maxPerWallet, "LOW_MAX_PER_WALLET");
        }

        l.totalReserved -= l.tiers[tierId].reserved;
        l.tiers[tierId] = tier;
        l.totalReserved += tier.reserved;
    }

    function _configureTiering(uint256[] calldata _tierIds, Tier[] calldata _tiers) internal virtual {
        for (uint256 i = 0; i < _tierIds.length; i++) {
            _configureTiering(_tierIds[i], _tiers[i]);
        }
    }

    function _onTierAllowlist(
        uint256 tierId,
        address minter,
        uint256 maxAllowance,
        bytes32[] calldata proof
    ) internal view virtual returns (bool) {
        return
            MerkleProof.verify(
                proof,
                TieredSalesStorage.layout().tiers[tierId].merkleRoot,
                _generateMerkleLeaf(minter, maxAllowance)
            );
    }

    function _eligibleForTier(
        uint256 tierId,
        address minter,
        uint256 maxAllowance,
        bytes32[] calldata proof
    ) internal view virtual returns (uint256 maxMintable) {
        TieredSalesStorage.Layout storage l = TieredSalesStorage.layout();

        require(l.tiers[tierId].maxPerWallet > 0, "NOT_EXISTS");
        require(block.timestamp >= l.tiers[tierId].start, "NOT_STARTED");
        require(block.timestamp <= l.tiers[tierId].end, "ALREADY_ENDED");

        maxMintable = l.tiers[tierId].maxPerWallet - l.walletMinted[tierId][minter];

        if (l.tiers[tierId].merkleRoot != bytes32(0)) {
            require(l.walletMinted[tierId][minter] < maxAllowance, "MAXED_ALLOWANCE");
            require(_onTierAllowlist(tierId, minter, maxAllowance, proof), "NOT_ALLOWLISTED");

            uint256 remainingAllowance = maxAllowance - l.walletMinted[tierId][minter];

            if (maxMintable > remainingAllowance) {
                maxMintable = remainingAllowance;
            }
        }
    }

    function _availableSupplyForTier(uint256 tierId) internal view virtual returns (uint256 remaining) {
        TieredSalesStorage.Layout storage l = TieredSalesStorage.layout();

        // Substract all the remaining reserved spots from the total remaining supply...
        remaining = _remainingSupply(tierId) - (l.totalReserved - l.reservedMints);

        // If this tier has reserved spots, add remaining spots back to result...
        if (l.tiers[tierId].reserved > 0) {
            remaining += (l.tiers[tierId].reserved - l.tierMints[tierId]);
        }
    }

    function _executeSale(
        uint256 tierId,
        uint256 count,
        uint256 maxAllowance,
        bytes32[] calldata proof
    ) internal virtual {
        address minter = _msgSender();

        uint256 maxMintable = _eligibleForTier(tierId, minter, maxAllowance, proof);

        TieredSalesStorage.Layout storage l = TieredSalesStorage.layout();

        require(count <= maxMintable, "EXCEEDS_MAX");
        require(count <= _availableSupplyForTier(tierId), "EXCEEDS_SUPPLY");
        require(count + l.tierMints[tierId] <= l.tiers[tierId].maxAllocation, "EXCEEDS_ALLOCATION");

        if (l.tiers[tierId].currency == address(0)) {
            require(l.tiers[tierId].price * count <= msg.value, "INSUFFICIENT_AMOUNT");
        } else {
            IERC20(l.tiers[tierId].currency).transferFrom(minter, address(this), l.tiers[tierId].price * count);
        }

        l.walletMinted[tierId][minter] += count;
        l.tierMints[tierId] += count;

        if (l.tiers[tierId].reserved > 0) {
            l.reservedMints += count;
        }
    }

    function _remainingSupply(
        uint256 /*tierId*/
    ) internal view virtual returns (uint256) {
        // By default assume supply is unlimited (that means reserving allocation for tiers is irrelevant)
        return type(uint256).max;
    }

    /* PRIVATE */

    function _generateMerkleLeaf(address account, uint256 maxAllowance) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, maxAllowance));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./ITieredSalesAdmin.sol";
import "./TieredSalesInternal.sol";

import "../../access/ownable/OwnableInternal.sol";

/**
 * @title Tiered Sales - Admin - Ownable
 * @notice Allow contract owner to manage sale tiers.
 *
 * @custom:type eip-2535-facet
 * @custom:category NFTs
 * @custom:peer-dependencies ITieredSales
 * @custom:provides-interfaces ITieredSalesAdmin
 */
contract TieredSalesOwnable is ITieredSalesAdmin, OwnableInternal, TieredSalesInternal {
    function configureTiering(uint256 tierId, ITieredSalesInternal.Tier calldata tier) external override onlyOwner {
        super._configureTiering(tierId, tier);
    }

    function configureTiering(uint256[] calldata tierIds, ITieredSalesInternal.Tier[] calldata tiers)
        external
        override
        onlyOwner
    {
        super._configureTiering(tierIds, tiers);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./ITieredSales.sol";

library TieredSalesStorage {
    struct Layout {
        uint256 totalReserved;
        uint256 reservedMints;
        mapping(uint256 => ITieredSales.Tier) tiers;
        mapping(uint256 => uint256) tierMints;
        mapping(uint256 => mapping(address => uint256)) walletMinted;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("v2.flair.contracts.storage.TieredSales");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}