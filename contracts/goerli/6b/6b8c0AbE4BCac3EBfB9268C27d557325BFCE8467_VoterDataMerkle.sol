// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract VoterDataMerkle {

    struct History {
        uint votingId;
        uint candidateId;
        uint timeStamp;
    }
    
    mapping(uint => bytes32) public votingToRoot;
    mapping(uint => bytes32[]) public votingToLeaves;
    mapping(address => History[]) public voterHistory;
    mapping(address => bytes32) public addressToLeave;
    

    function addLeaf(uint _votingId, bytes32 _leaf, bytes32 _newRoot, address _voter) external {
        bool result = checkLeaf(_votingId,_leaf);
        require(result, "The same leaf already added to the tree");
        votingToLeaves[_votingId].push(_leaf);
        addressToLeave[_voter] = _leaf;
        setRoot(_votingId, _newRoot);
    }
    function checkLeaf (uint _votingId, bytes32 _leaf) public view returns(bool){
        bool result;
        bytes32[] memory leaves = votingToLeaves[_votingId];
        uint length = leaves.length;
        if(length == 0) {
            result = true;
        }else {
           for(uint i; i < length; i++ ) {
            if(leaves[i] != _leaf) {
              result = true;
                }
            }
        }
        return result;
    }

    function setRoot(uint _votingId, bytes32 _root) public {
        votingToRoot[_votingId] = _root;
    }

   function getLeaves(address _voter) external view returns(bytes32) {
        bytes32 voter = addressToLeave[_voter];
        return voter;
   }
   
    function verify(uint _votingId, bytes32[] calldata proof, bytes32 leaf) external view returns(bool){
        bytes32 root = votingToRoot[_votingId];
        return MerkleProof.verify(proof, root, leaf);
    }
    
    function addVoterHistory(address _voter, uint _votingId, uint _candidateId, uint _timeStamp) external{
        voterHistory[_voter].push(History(_votingId, _candidateId, _timeStamp));
    }

    function getVoterHistory(address _voter) external view returns(History[] memory) {
        History[] memory history = voterHistory[_voter];
        return history;
    }

}