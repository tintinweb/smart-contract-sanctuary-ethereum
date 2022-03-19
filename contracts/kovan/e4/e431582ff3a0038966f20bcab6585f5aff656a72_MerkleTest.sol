/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

/** 
 *  SourceUnit: /home/iwura/merkleTree/merkle-airdrop/contracts/merkleTree.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}




/** 
 *  SourceUnit: /home/iwura/merkleTree/merkle-airdrop/contracts/merkleTree.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

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

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}


/** 
 *  SourceUnit: /home/iwura/merkleTree/merkle-airdrop/contracts/merkleTree.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

////import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MerkleTest {
    // Our rootHash
    bytes32 public root = 0x10e0767982dfd71d50c3ba77901437b8d20283e3f9677b5dfe7896c1a439447e;
    IERC20 token = IERC20(0x139360Ca9620CF4A748B81844b84aDe0747360ed);

    mapping(address => bool) IwhitelistClaimed;
    mapping(address => uint256) _balances;

    function claimToken(
        bytes32[] calldata _merkleProof,
        uint256 _id,
        uint256 amount
    ) public {
        require(IwhitelistClaimed[msg.sender] == false, "already claimed");
        require(checkValidity(_merkleProof, _id, amount), "invalid proof");
        require(token.transfer(msg.sender, amount));
        IwhitelistClaimed[msg.sender] = true;
    }

    function checkValidity(
        bytes32[] calldata _merkleProof,
        uint256 _id,
        uint256 amount
    ) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _id, amount));
        require(MerkleProof.verify(_merkleProof, root, leaf), "Incorrect proof");
        return true; // Or you can mint tokens here
    }

    function balanceOf(address addr) public view returns (uint256) {
        return _balances[addr];
    }
}