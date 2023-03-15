// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MerkleProof} from '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';



//  enum STATE { NONE, START, PAUSE , END} // 0 1 2 3
// import "hardhat/console.sol";

library LibSalePhase {

    enum STATE { NONE, START, PAUSE , END} 
    struct PhaseSettings {
        uint phaseNum;

        string name;
        /// @dev phase supply. This can be released to public by ending the phase.
        uint maxSupply;
        /// @dev tracks the total amount minted in the phase
        uint amountMinted;
        /// @dev wallet maximum for the phase
        uint maxPerWallet;
        /// @dev merkle root for the phase (if applicable, otherwise bytes32(0))
        bytes32 merkleRoot;
        /// @dev whether the phase is active
        bool isActive;
      
        /// @dev price for the phase (or free if 0)
        uint256 price;

        STATE status; 

        
    }

    struct SaleState {
        uint phaseNum;
        uint activeState;
        mapping(uint256 => PhaseSettings) phases;
        mapping(uint => mapping(address => uint)) mintAddress;
  
    }

      // return a struct storage pointer for accessing the state variables
    function  phaseSettingsStorage() 
      internal 
      pure 
      returns (PhaseSettings storage ds) 
    {
      bytes32 position = keccak256("phaseSetting.diamond.storage");
      assembly { ds.slot := position }
    }


    function saleStateStorage() 
      internal 
      pure 
      returns ( SaleState storage ps) 
    {
      bytes32 position = keccak256("saleState.diamond.storage");
      assembly { ps.slot := position }
    }

   function setActiveState(uint activeState_)  internal{
         SaleState storage ss = saleStateStorage();
         ss.activeState =  activeState_;
         ss.phases[activeState_].isActive = true;
   } 


   function setPhaseStatus(uint phaseNum_ , uint status_)  internal{

         require(status_ <= uint(STATE.END), "Out of status state");

         SaleState storage ss = saleStateStorage();
         ss.activeState =  phaseNum_;
         ss.phases[phaseNum_].status = STATE(status_);
   } 


   function setAmountMintedPhase(uint phaseNum_ , uint  amountMinted_ ,address user_)  internal{
         SaleState storage ss = saleStateStorage();
         ss.phases[phaseNum_].amountMinted += amountMinted_;
         ss.mintAddress[phaseNum_][user_] +=  amountMinted_;
   }

   function getActivePhase()  public  view  returns( PhaseSettings memory ){
      SaleState storage ss = saleStateStorage();
     return  ss.phases[ss.activeState];
   } 

   function getAllPhase() public  view  returns ( PhaseSettings[] memory  ){

       SaleState storage ss = saleStateStorage();
       PhaseSettings[] memory salestate = new PhaseSettings[](ss.phaseNum);

      for(uint i = 0; i < ss.phaseNum; i++){
        salestate[i] =  ss.phases[i+1];
      }
      return   salestate;
   }

   function getPhase(uint numPhase_) public  view returns(PhaseSettings memory){
       SaleState storage ps = saleStateStorage();
       return ps.phases[numPhase_];

   }


  function addPhase(
    string  memory name_,
    uint    maxSupply_,
    uint    maxPerWallet_,
    bytes32 merkleRoot_,
    bool    isActive_,
    uint256 price_
  )  internal  {

    SaleState storage ps = saleStateStorage();
    ps.phaseNum =  ps.phaseNum+1;
    ps.phases[ps.phaseNum].phaseNum     = ps.phaseNum;
    ps.phases[ps.phaseNum].name         = name_;
    ps.phases[ps.phaseNum].maxSupply    = maxSupply_;
    ps.phases[ps.phaseNum].amountMinted = 0;
    ps.phases[ps.phaseNum].maxPerWallet = maxPerWallet_;
    ps.phases[ps.phaseNum].merkleRoot   = merkleRoot_;
    ps.phases[ps.phaseNum].isActive     = isActive_;
    ps.phases[ps.phaseNum].price        = price_;
    
  }

  function updatePhase(
    string  memory name_,
    uint    maxSupply_,
    uint    maxPerWallet_,
    bytes32 merkleRoot_,
    bool    isActive_,
    uint256 price_,
    uint    numPhase_
  )  internal  {
    
    SaleState storage ss = saleStateStorage();
    // ss.phases[numPhase_] = ds;
    ss.phases[numPhase_].name          = name_;
    ss.phases[numPhase_].maxSupply     = maxSupply_;
    ss.phases[numPhase_].maxPerWallet =  maxPerWallet_;
    ss.phases[numPhase_].merkleRoot    = merkleRoot_;
    ss.phases[numPhase_].isActive      = isActive_;
    ss.phases[numPhase_].price         = price_;
   // ss.phases[numPhase_].status       = STATE.NONE;

    
  }

  ///////////////
  // Whitelist
  ///////////////


  function setWhitelist(bytes32  _merkleRoot, uint _phaseNum) internal {

        SaleState storage ss = saleStateStorage();
        ss.phases[ _phaseNum].merkleRoot  = _merkleRoot;

  }

  function unWhitelist(address[] calldata _users, uint phaseName) internal {

  }

  function isWhitelist(address _address ,  bytes32[] calldata _merkleProof , uint _phaseNum) view public returns(bool) {
     
        SaleState storage ss = saleStateStorage();
        bytes32  merkleRoot =  ss.phases[_phaseNum].merkleRoot;

       if (merkleRoot == bytes32(0)) {
             return  true;
         }else{
           bytes32 node = keccak256(abi.encodePacked(_address));
          return MerkleProof.verify(_merkleProof, merkleRoot, node);
         }
  }

   function setMintAddress(
    address address_,
    uint    amountMint_
  )  internal  {
    SaleState storage ss = saleStateStorage();
    ss.mintAddress[ss.activeState][address_] += amountMint_;

  }

  function getMintAvailableAddress(
    address address_
  )  public  view returns(uint){ 
    SaleState storage ss = saleStateStorage();
    return  ss.phases[ss.activeState].maxPerWallet - ss.mintAddress[ss.activeState][address_];

  }

  function getPhaseTotalMint(
    uint numPhase_
  )public view returns(uint ) {
    SaleState storage ss = saleStateStorage();
    return  ss.phases[numPhase_].amountMinted;
  }

} // end lib