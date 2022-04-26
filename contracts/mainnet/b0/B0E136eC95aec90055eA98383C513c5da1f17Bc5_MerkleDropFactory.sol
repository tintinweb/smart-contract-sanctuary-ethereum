/**
 *Submitted for verification at Etherscan.io on 2022-04-26
*/

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// This library is used to check merkle proofs very efficiently. Each additional proof element adds ~1000 gas
library MerkleLib {

    // This is the main function that will be called by contracts. It assumes the leaf is already hashed, as in,
    // it is not raw data but the hash of that. This is because the leaf data could be any combination of hashable
    // datatypes, so we let contracts hash the data themselves to keep this function simple
    function verifyProof(bytes32 root, bytes32 leaf, bytes32[] memory proof) public pure returns (bool) {
        bytes32 currentHash = leaf;

        // the proof is all siblings of the ancestors of the leaf (including the sibling of the leaf itself)
        // each iteration of this loop steps one layer higher in the merkle tree
        for (uint i = 0; i < proof.length; i += 1) {
            currentHash = parentHash(currentHash, proof[i]);
        }

        // does the result match the expected root? if so this leaf was committed to when the root was posted
        // else we must assume the data was not included
        return currentHash == root;
    }

    function parentHash(bytes32 a, bytes32 b) public pure returns (bytes32) {
        // the convention is that the inputs are sorted, this removes ambiguity about tree structure
        if (a < b) {
            return keccak256(abi.encode(a, b));
        } else {
            return keccak256(abi.encode(b, a));
        }
    }

}

// This contract is for anyone to create a merkledrop, that is, an airdrop using merkleproofs to compute eligibility
contract MerkleDropFactory {
    using MerkleLib for bytes32;

    // the number of airdrops in this contract
    uint public numTrees = 0;

    // this represents a single airdrop
    struct MerkleTree {
        bytes32 merkleRoot;  // merkleroot of tree whose leaves are (address,uint) pairs representing amount owed to user
        bytes32 ipfsHash; // ipfs hash of entire dataset, as backup in case our servers turn off...
        address tokenAddress; // address of token that is being airdropped
        uint tokenBalance; // amount of tokens allocated for this tree
        uint spentTokens; // amount of tokens dispensed from this tree
    }

    // withdrawn[recipient][treeIndex] = hasUserWithdrawnAirdrop
    mapping (address => mapping (uint => bool)) public withdrawn;

    // array-like map for all ze merkle trees (airdrops)
    mapping (uint => MerkleTree) public merkleTrees;

    // every time there's a withdraw
    event Withdraw(uint indexed merkleIndex, address indexed recipient, uint value);
    // every time a tree is added
    event MerkleTreeAdded(uint indexed index, address indexed tokenAddress, bytes32 newRoot, bytes32 ipfsHash);

    // anyone can add a new airdrop
    function addMerkleTree(bytes32 newRoot, bytes32 ipfsHash, address depositToken, uint tokenBalance) public {
        // prefix operator ++ increments then evaluates
        merkleTrees[++numTrees] = MerkleTree(
            newRoot,
            ipfsHash,
            depositToken,
            0,  // ain't no tokens in here yet
            0   // ain't nobody claimed no tokens yet either
        );
        // you don't get to add a tree without funding it
        depositTokens(numTrees, tokenBalance);
        emit MerkleTreeAdded(numTrees, depositToken, newRoot, ipfsHash);
    }

    // anyone can fund any tree
    function depositTokens(uint treeIndex, uint value) public {
        // storage since we are editing
        MerkleTree storage merkleTree = merkleTrees[treeIndex];

        // bookkeeping to make sure trees don't share tokens
        merkleTree.tokenBalance += value;

        // transfer tokens, if this is a malicious token, then this whole tree is malicious
        // but it does not effect the other trees
        require(IERC20(merkleTree.tokenAddress).transferFrom(msg.sender, address(this), value), "ERC20 transfer failed");
    }

    // anyone can withdraw anyone else's tokens, altho they always go to the right destination
    // msg.sender is not used in this function
    function withdraw(uint merkleIndex, address walletAddress, uint value, bytes32[] memory proof) public {
        // no withdrawing from uninitialized merkle trees
        require(merkleIndex <= numTrees, "Provided merkle index doesn't exist");
        // no withdrawing same airdrop twice
        require(!withdrawn[walletAddress][merkleIndex], "You have already withdrawn your entitled token.");
        // compute merkle leaf, this is first element of proof
        bytes32 leaf = keccak256(abi.encode(walletAddress, value));
        // storage because we edit
        MerkleTree storage tree = merkleTrees[merkleIndex];
        // this calls to MerkleLib, will return false if recursive hashes do not end in merkle root
        require(tree.merkleRoot.verifyProof(leaf, proof), "The proof could not be verified.");
        // close re-entrance gate, prevent double claims
        withdrawn[walletAddress][merkleIndex] = true;
        // update struct
        tree.tokenBalance -= value;
        tree.spentTokens += value;
        // transfer the tokens
        // NOTE: if the token contract is malicious this call could re-enter this function
        // which will fail because withdrawn will be set to true
        require(IERC20(tree.tokenAddress).transfer(walletAddress, value), "ERC20 transfer failed");
        emit Withdraw(merkleIndex, walletAddress, value);
    }

}