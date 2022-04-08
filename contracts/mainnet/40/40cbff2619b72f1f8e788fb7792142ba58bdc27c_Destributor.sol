/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

interface Erc20 {
	function transfer(address, uint256) external returns (bool);
	function balanceOf(address) external returns (uint256);
	function transferFrom(address, address, uint256) external returns (bool);
}

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
  /// @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree defined by `root`.
  /// For this, a `proof` must be provided, containing sibling hashes on the branch from the leaf to the root of the 
  /// tree. Each pair of leaves and each pair of pre-images are assumed to be sorted.
  /// @param p Array of merkle proofs
  /// @param r Merkle root
  /// @param l Candidate 'leaf' of the merkle tree
  function verify(bytes32[] memory p, bytes32 r, bytes32 l) internal pure returns (bool) {
    uint256 len = p.length;
    bytes32 hash = l;

    for (uint256 i = 0; i < len; i++) {
      bytes32 element = p[i];

      if (hash <= element) {
        // Hash(current computed hash + current element of the proof)
        hash = keccak256(abi.encodePacked(hash, element));
      } else {
        // Hash(current element of the proof + current computed hash)
        hash = keccak256(abi.encodePacked(element, hash));
      }
    }

    // Check if the computed hash (root) is equal to the provided root
    return hash == r;
  }
}

contract Destributor {
  mapping (uint256 => bytes32) public merkleRoot;
  mapping (uint256 => mapping (uint256 => uint256)) private claims;
  mapping (uint256 => bool) private cancelled;

  uint256 public distribution;

  address public immutable token;
  address public admin;
  bool public paused;

  event Distribute(bytes32 merkleRoot, uint256 distribution);
  event Claim(uint256 index, address owner, uint256 amount);

  /// @param t Address of an ERC20 token
  /// @param r Initial merkle root
  constructor(address t, bytes32 r) {
    admin = msg.sender;
    token = t;
    merkleRoot[0] = r;
  }

  /// @notice Generate a new distribution, cancelling the would be current one
  /// @param f The address of the wallet containing tokens to distribute
  /// @param t The address that will receive any currently remaining distributions (will normally be the same as from)
  /// @param a The amount of tokens in the new distribution
  /// @param r The merkle root associated with the new distribution
  function distribute(address f, address t, uint256 a, bytes32 r) external authorized(admin) returns (bool) {
    // remove curent token balance
    Erc20 erc = Erc20(token);
    uint256 balance = erc.balanceOf(address(this));
    erc.transfer(t, balance);
        
    // transfer enough tokens for new distribution
    erc.transferFrom(f, address(this), a);

    // we are working with the distribution, eventually bumping it...
    uint256 current = distribution;
        
    // cancel the (to-be) previous distribution
    cancelled[current] = true;

    current++;
    // add the new distribution's merkleRoot
    merkleRoot[current] = r;

    distribution = current;

    // unpause redemptions
    pause(false);

    emit Distribute(r, current);        

    return true;
  }

  /// @param i An index which to construct a possible claim from
  /// @param d The distribution to check for a claim
  function claimed(uint256 i, uint256 d) public view returns (bool) {
    require(i > 0, 'passed index must be > 0');

    uint256 wordIndex = i / 256;
    uint256 bitIndex = i % 256;
    uint256 word = claims[d][wordIndex];
    uint256 mask = (1 << bitIndex);

    return word & mask == mask;
  }

  /// @param i An index which to construct a claim from
  /// @param o Owner address of the token being transferred
  /// @param a Amount being transferred
  /// @param p array of merkle proofs
  function claim(uint256 i, address o, uint256 a, bytes32[] calldata p) external returns (bool) {
    require(!paused, 'claiming is paused');
    require(!claimed(i, distribution), 'distribution claimed');
    require(!cancelled[distribution], 'distribution cancelled');

    // Verify the merkle proof...
    bytes32 node = keccak256(abi.encodePacked(i, o, a));
    require(MerkleProof.verify(p, merkleRoot[distribution], node), 'invalid proof');

    // Mark it claimed...
    uint256 wordIndex = i / 256;
    uint256 bitIndex = i % 256;
    claims[distribution][wordIndex] = claims[distribution][wordIndex] | (1 << bitIndex);
    
    // send the token...
    require(Erc20(token).transfer(o, a), 'transfer failed.');

    emit Claim(i, o, a);

    return true;
  }

  /// @param a Address of a new admin
  function transferAdmin(address a) external authorized(admin) returns (bool) {
    admin = a;

    return true;
  }

  /// @notice Allows admin to pause or unpause claims
  /// @param b Boolean value to set paused to
  function pause(bool b) public authorized(admin) returns (bool) {
    paused = b;
    return true;
  }

  modifier authorized(address a) {
    require(msg.sender == a, 'sender must be authorized');
    _;
  }
}