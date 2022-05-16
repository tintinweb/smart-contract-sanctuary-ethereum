/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
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
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

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

struct Drop {
    IERC20 token;
    address sender;
    uint256 expired;
    uint256 amount; // total amount of distributed tokens
}

contract MerkleSenderNew {

    mapping(bytes32 => Drop) drops;
    mapping(bytes32 => mapping (bytes32 => bool)) sent;

    function hashChunk(address[] calldata addresses, uint256[] calldata amounts, uint256 nonce) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(addresses, amounts, nonce));
    }

    function add(address token, bytes32 root, uint256 amount, uint256 expired) external {
        require(drops[root].amount == 0, 'Unique drops only');

        IERC20 _contract = IERC20(token);

        _contract.transferFrom(msg.sender, address(this), amount);

        drops[root] = Drop(
            _contract,
            msg.sender,
            expired,
            amount
        );
    }

    function send(bytes32 root, bytes32[] calldata proof, address[] calldata to, uint256[] calldata amounts, uint256 nonce) external {
        Drop memory drop = drops[root];
        require(drop.amount > 0, "Active drop only");
        bytes32 leaf = hashChunk(to, amounts, nonce);
        // sent chunk only once:
        require(sent[root][leaf] == false, "Sent chunk only once");
        sent[root][leaf] = true;
        // verify proof:
        require(MerkleProof.verify(proof, root, leaf), "Validate leaf");
        // send tokens:
        uint256 leaf_amount = 0;
        for (uint256 i = 0; i < to.length; i++) {
            drop.token.transfer(to[i], amounts[i]);
            leaf_amount = leaf_amount + amounts[i];
        }

    }

    function _cleanup(bytes32 root, bytes32[] calldata leafs) internal {
        require(drops[root].amount == 0, "Finished drop only");
        for (uint256 i = 0; i < leafs.length; i++) {
            delete sent[root][leafs[i]];
        }
    }

    function cleanup(bytes32 root, bytes32[] calldata leafs) external {
        _cleanup(root, leafs);
    }

    function clame(bytes32 root) external {
        Drop memory drop = drops[root];
        require(block.timestamp > drop.expired, "Expired only");
        // transfer tokens back to user:
        drop.token.transfer(drop.sender, drop.amount);
        // transfer prize back to user:
        delete drops[root];
    }
}