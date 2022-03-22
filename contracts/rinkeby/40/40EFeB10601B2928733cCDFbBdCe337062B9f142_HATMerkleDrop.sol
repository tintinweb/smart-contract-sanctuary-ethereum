// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;


import "openzeppelin-solidity/contracts/utils/cryptography/MerkleProof.sol";
import "./interfaces/HATTokenInterface.sol";

contract HATMerkleDrop {

    HATTokenInterface public immutable hat;
    bytes32 public immutable merkleRoot;
    mapping(address => bool) public hasClaimed;

    event Claim(address indexed to, uint256 amount);

    // solhint-disable-next-line func-visibility
    constructor(HATTokenInterface _hat, bytes32 _merkleRoot) {
        hat = _hat;
        merkleRoot = _merkleRoot;
    }


    /**
    * @dev Allows claiming tokens if address is part of merkle tree
    * If an address appears in the merkle tree more than once
    * it will only be able to redeem one of the leafs
    * @param to address of claimee
    * @param amount of tokens owed to claimee
    * @param proof merkle proof to prove address and amount are in tree
    */
    function claim(address to, uint256 amount, bytes32[] calldata proof) public {
        // Throw if address has already claimed tokens
        require(!hasClaimed[to], "Account already claimed");
        require(hat.delegates(to) != address(0), "Must delegate to claim");

        // Verify merkle proof, or revert if not in tree
        bytes32 leaf = keccak256(abi.encodePacked(to, amount));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid merkle proof");

        // Set address to claimed
        hasClaimed[to] = true;

        // Mint tokens to address
        hat.mint(to, amount);


        // Emit claim event
        emit Claim(to, amount);
    }

    /**
    * @dev Allows delegating and claiming tokens if address is part of merkle tree
    * If an address appears in the merkle tree more than once
    * it will only be able to redeem one of the leafs
    * @param to address of claimee
    * @param amount of tokens owed to claimee
    * @param proof merkle proof to prove address and amount are in tree
    * @param delegatee The address to delegate votes to
    * @param nonce The contract state required to match the signature
    * @param expiry The time at which to expire the signature
    * @param v The recovery byte of the signature
    * @param r Half of the ECDSA signature pair
    * @param s Half of the ECDSA signature pair
    */
    function delegateAndClaim(
        address to,
        uint256 amount,
        bytes32[] calldata proof,
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
        ) external {
        hat.delegateBySig(delegatee, nonce, expiry, v, r, s);
        // Makes sure the delegation was successful
        // Or at least that the delegatee is set correctly
        require(hat.delegates(to) == delegatee, "Delegation failed");
        claim(to, amount, proof);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
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
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
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
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;


interface HATTokenInterface {
    // mapping (address => address) public delegates;

    function delegates(address delegate) external returns (address);

    function mint(address _account, uint _amount) external;

    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) external;
}