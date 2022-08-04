/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.12;

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

library MerkleLib {

    function verifyProof(bytes32 root, bytes32 leaf, bytes32[] calldata proof) public pure returns (bool) {
        bytes32 currentHash = leaf;

        uint proofLength = proof.length;
        for (uint i; i < proofLength;) {
            currentHash = parentHash(currentHash, proof[i]);
            unchecked { ++i; }
        }

        return currentHash == root;
    }

    function parentHash(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return keccak256(a < b ? abi.encode(a, b) : abi.encode(b, a));
    }

}

/// @title A factory pattern for merkle-vesting, that is, a time release schedule for tokens, using merkle proofs to scale
/// @author metapriest, adrian.wachel, marek.babiarz, radoslaw.gorecki
/// @notice This contract is permissionless and public facing. Any fees must be included in the data of the merkle tree.
/// @dev The contract cannot introspect into the contents of the merkle tree, except when provided a merkle proof
contract MerkleVesting {
    using MerkleLib for bytes32;

    // the number of vesting schedules in this contract
    uint public numTrees;
    
    // this represents a single vesting schedule for a specific address
    struct Tranche {
        address recipient;
        uint totalCoins;  // total number of coins released to an address after vesting is completed
        uint currentCoins; // how many coins are left unclaimed by this address, vested or unvested
        uint startTime; // when the vesting schedule is set to start, possibly in the past
        uint endTime;  // when the vesting schedule will have released all coins
        uint coinsPerSecond; // an intermediate value cached to reduce gas costs, how many coins released every second
        uint lastWithdrawalTime; // the last time a withdrawal occurred, used to compute unvested coins
        uint lockPeriodEndTime; // the first time at which coins may be withdrawn
    }

    // this represents a set of vesting schedules all in the same token
    struct MerkleTree {
        bytes32 rootHash;  // merkleroot of tree whose leaves are (address,uint,uint,uint,uint) representing vesting schedules
        bytes32 ipfsHash; // ipfs hash of entire dataset, used to reconstruct merkle proofs if our servers go down
        address tokenAddress; // token that the vesting schedules will be denominated in
        uint tokenBalance; // current amount of tokens deposited to this tree, used to make sure trees don't share tokens
        uint numTranchesInitialized;
        mapping (uint => Tranche) tranches;
        mapping (bytes32 => bool) initialized;
    }

    // array-like sequential map for all the vesting schedules
    mapping (uint => MerkleTree) public merkleTrees;


    // every time there's a withdrawal
    event WithdrawalOccurred(uint indexed treeIndex, address indexed destination, uint numTokens, uint tokensLeft);

    // every time a tree is added
    event MerkleRootAdded(uint indexed treeIndex, address indexed tokenAddress, bytes32 newRoot, bytes32 ipfsHash);

    // every time a tree is topped up
    event TokensDeposited(uint indexed treeIndex, address indexed tokenAddress, uint amount);

    event TrancheInitialized(uint indexed treeIndex, uint indexed trancheIndex, address indexed recipient, bytes32 leaf);

    error BadTreeIndex(uint treeIndex);
    error AlreadyInitialized(uint treeIndex, bytes32 leaf);
    error BadProof(uint treeIndex, bytes32 leaf, bytes32[] proof);
    error UninitializedAccount(uint treeIndex, uint trancheIndex);
    error AccountStillLocked(uint treeIndex, uint trancheIndex);
    error AccountEmpty(uint treeIndex, uint trancheIndex);

    /// @notice Add a new merkle tree to the contract, creating a new merkle-vesting-schedule
    /// @dev Anyone may call this function, therefore we must make sure trees cannot affect each other
    /// @dev Root hash should be built from (destination, totalCoins, startTime, endTime, lockPeriodEndTime)
    /// @param newRoot root hash of merkle tree representing vesting schedules
    /// @param ipfsHash the ipfs hash of the entire dataset, used for redundance so that creator can ensure merkleproof are always computable
    /// @param tokenAddress the address of the token contract that is being distributed
    /// @param tokenBalance the amount of tokens user wishes to use to fund the airdrop, note trees can be under/overfunded
    function addMerkleRoot(bytes32 newRoot, bytes32 ipfsHash, address tokenAddress, uint tokenBalance) public {
        // prefix operator ++ increments then evaluates
        MerkleTree storage tree = merkleTrees[++numTrees];
        tree.rootHash = newRoot;
        tree.ipfsHash = ipfsHash;
        tree.tokenAddress = tokenAddress;

        // fund the tree now
        depositTokens(numTrees, tokenBalance);
        emit MerkleRootAdded(numTrees, tokenAddress, newRoot, ipfsHash);
    }

    /// @notice Add funds to an existing merkle-vesting-schedule
    /// @dev Anyone may call this function, the only risk here is that the token contract is malicious, rendering the tree malicious
    /// @dev If the tree is over-funded, excess funds are lost. No clear way to get around this without zk-proofs
    /// @param treeIndex index into array-like map of merkleTrees
    /// @param value the amount of tokens user wishes to use to fund the airdrop, note trees can be underfunded
    function depositTokens(uint treeIndex, uint value) public {
        if (treeIndex == 0 || treeIndex > numTrees) {
            revert BadTreeIndex(treeIndex);
        }

        // storage since we are editing
        MerkleTree storage merkleTree = merkleTrees[treeIndex];

        IERC20 token = IERC20(merkleTree.tokenAddress);
        uint balanceBefore = token.balanceOf(address(this));

        // transfer tokens, if this is a malicious token, then this whole tree is malicious
        // but it does not effect the other trees
        // NOTE: we don't check for success here because some tokens don't return a bool
        // Instead we check the balance before and after, which takes care of the fee-on-transfer tokens as well
        token.transferFrom(msg.sender, address(this), value);

        uint balanceAfter = token.balanceOf(address(this));
        // diff may be different from value here, it may even be zero if the transfer failed silently
        uint diff = balanceAfter - balanceBefore;

        // bookkeeping to make sure trees don't share tokens
        merkleTree.tokenBalance += diff;
        emit TokensDeposited(treeIndex, merkleTree.tokenAddress, diff);
    }

    /// @notice Called once per recipient of a vesting schedule to initialize the vesting schedule
    /// @dev Anyone may call this function, the only risk here is that the token contract is malicious, rendering the tree malicious
    /// @dev If the tree is over-funded, excess funds are lost. No clear way to get around this without zk-proofs of global tree stats
    /// @dev The contract has no knowledge of the vesting schedules until this function is called
    /// @param treeIndex index into array-like map of merkleTrees
    /// @param destination address that will receive tokens
    /// @param totalCoins amount of tokens to be released after vesting completes
    /// @param startTime time that vesting schedule starts, can be past or future
    /// @param endTime time vesting schedule completes, can be past or future
    /// @param lockPeriodEndTime time that coins become unlocked, can be after endTime
    /// @param proof array of hashes linking leaf hash of (destination, totalCoins, startTime, endTime, lockPeriodEndTime) to root
    function initialize(
        uint treeIndex,
        address destination,
        uint totalCoins,
        uint startTime,
        uint endTime,
        uint lockPeriodEndTime,
        bytes32[] memory proof) external returns (uint) {
        if (treeIndex == 0 || treeIndex > numTrees) {
            revert BadTreeIndex(treeIndex);
        }

        // leaf hash is digest of vesting schedule parameters and destination
        // NOTE: use abi.encode, not abi.encodePacked to avoid possible (but unlikely) collision
        bytes32 leaf = keccak256(abi.encode(destination, totalCoins, startTime, endTime, lockPeriodEndTime));

        // storage because it's cheaper, "memory" copies from storage to memory
        MerkleTree storage tree = merkleTrees[treeIndex];

        // must not initialize multiple times
        if (tree.initialized[leaf]) {
            revert AlreadyInitialized(treeIndex, leaf);
        }

        // call to MerkleLib to check if the submitted data is correct
        if (tree.rootHash.verifyProof(leaf, proof) == false) {
            revert BadProof(treeIndex, leaf, proof);
        }

        // set initialized, preventing double initialization
        tree.initialized[leaf] = true;

        // precompute how many coins are released per second
        // NOTE: should check that endTime != startTime on backend since that would revert here
        uint coinsPerSecond = totalCoins / (endTime - startTime);

        // create the tranche struct and assign it
        tree.tranches[++tree.numTranchesInitialized] = Tranche(
            destination,
            totalCoins,  // total coins to be released
            totalCoins,  // currentCoins starts as totalCoins
            startTime,
            endTime,
            coinsPerSecond,
            startTime,    // lastWithdrawal starts as startTime
            lockPeriodEndTime
        );

        emit TrancheInitialized(treeIndex, tree.numTranchesInitialized, destination, leaf);

        // if we've passed the lock time go ahead and perform a withdrawal now
        if (lockPeriodEndTime < block.timestamp) {
            withdraw(treeIndex, tree.numTranchesInitialized);
        }
        return tree.numTranchesInitialized;
    }

    /// @notice Claim funds as a recipient in the merkle-drop
    /// @dev Anyone may call this function for anyone else, funds go to destination regardless, it's just a question of
    /// @dev who provides the proof and pays the gas, msg.sender is not used in this function
    /// @param treeIndex index into array-like map of merkleTrees, which tree should we apply the proof to?
    /// @param trancheIndex recipient of tokens
    function withdraw(uint treeIndex, uint trancheIndex) public {

        MerkleTree storage tree = merkleTrees[treeIndex];
        Tranche storage tranche = tree.tranches[trancheIndex];

        // checking this way so we don't have to recompute leaf hash
        if (tranche.totalCoins == 0) {
            revert UninitializedAccount(treeIndex, trancheIndex);
        }

        // no withdrawals before lock time ends
        if (block.timestamp < tranche.lockPeriodEndTime) {
            revert AccountStillLocked(treeIndex, trancheIndex);
        }

        // revert if there's nothing left
        if (tranche.currentCoins == 0) {
            revert AccountEmpty(treeIndex, trancheIndex);
        }

        // declaration for branched assignment
        uint currentWithdrawal;

        // if after vesting period ends, give them the remaining coins
        if (block.timestamp >= tranche.endTime) {
            currentWithdrawal = tranche.currentCoins;
        } else {
            // compute allowed withdrawal
            currentWithdrawal = (block.timestamp - tranche.lastWithdrawalTime) * tranche.coinsPerSecond;
        }

        // this makes sure coins don't get double withdrawn, closes re-entrance gate
        tranche.lastWithdrawalTime = block.timestamp;

        IERC20 token = IERC20(tree.tokenAddress);
        uint balanceBefore = token.balanceOf(address(this));

        // Transfer the tokens, if the token contract is malicious, this will make the whole tree malicious
        // but this does not allow re-entrance due to struct updates and it does not effect other trees.
        // It is also consistent with the ethereum general security model:
        // other contracts do what they want, it's our job to protect our contract
        token.transfer(tranche.recipient, currentWithdrawal);

        // compute the diff in case there is a fee-on-transfer or transfer failed silently
        uint balanceAfter = token.balanceOf(address(this));
        uint diff = balanceBefore - balanceAfter;

        // decrease allocation of coins
        tranche.currentCoins -= diff;

        // update the tree balance so trees can't take each other's tokens
        tree.tokenBalance -= diff;

        emit WithdrawalOccurred(treeIndex, tranche.recipient, diff, tranche.currentCoins);
    }

    function getTranche(uint treeIndex, uint trancheIndex) view external returns (address, uint, uint, uint, uint, uint, uint) {
        Tranche storage tranche = merkleTrees[treeIndex].tranches[trancheIndex];
        return (tranche.recipient, tranche.totalCoins, tranche.currentCoins, tranche.startTime, tranche.endTime, tranche.coinsPerSecond, tranche.lastWithdrawalTime);
    }

    function getInitialized(uint treeIndex, bytes32 leaf) external view returns (bool) {
        return merkleTrees[treeIndex].initialized[leaf];
    }

}