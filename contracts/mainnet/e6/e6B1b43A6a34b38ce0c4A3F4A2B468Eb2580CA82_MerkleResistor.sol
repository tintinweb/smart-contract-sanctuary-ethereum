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

// This contract is for user-chosen vesting schedules, within parameters selected by the tree creator
contract MerkleResistor {
    using MerkleLib for bytes32;

    // tree (vesting schedule) counter
    uint public numTrees = 0;

    // this represents a user chosen vesting schedule, post initiation
    struct Tranche {
        uint totalCoins; // total coins released after vesting complete
        uint currentCoins; // unclaimed coins remaining in the contract, waiting to be vested
        uint startTime; // start time of the vesting schedule
        uint endTime;   // end time of the vesting schedule
        uint coinsPerSecond;  // how many coins are emitted per second, this value is cached to avoid recomputing it
        uint lastWithdrawalTime; // keep track of last time user claimed coins to compute coins owed for this withdrawal
    }

    // this represents an arbitrarily large set of token recipients with partially-initialized vesting schedules
    struct MerkleTree {
        bytes32 merkleRoot; // merkle root of tree whose leaves are ranges of vesting schedules for each recipient
        bytes32 ipfsHash; // ipfs hash of the entire data set represented by the merkle root, in case our servers go down
        uint minEndTime; // minimum length (offset, not absolute) of vesting schedule in seconds
        uint maxEndTime; // maximum length (offset, not absolute) of vesting schedule in seconds
        uint pctUpFront; // percent of vested coins that will be available and withdrawn upon initialization
        address tokenAddress; // address of token to be distributed
        uint tokenBalance; // amount of tokens allocated to this tree (this prevents trees from sharing tokens)
    }

    // initialized[recipient][treeIndex] = hasUserChosenVestingSchedule
    // could have reused tranches (see below) for this but loading a bool is cheaper than loading an entire struct
    // NOTE: if a user appears in the same tree multiple times, the first leaf initialized will prevent the others from initializing
    mapping (address => mapping (uint => bool)) public initialized;

    // basically an array of vesting schedules, but without annoying solidity array syntax
    mapping (uint => MerkleTree) public merkleTrees;

    // tranches[recipient][treeIndex] = chosenVestingSchedule
    mapping (address => mapping (uint => Tranche)) public tranches;

    // precision factory used to handle floating point arithmetic
    uint constant public PRECISION = 1000000;

    // every time a withdrawal occurs
    event WithdrawalOccurred(address indexed destination, uint numTokens, uint tokensLeft, uint indexed merkleIndex);
    // every time a tree is added
    event MerkleTreeAdded(uint indexed index, address indexed tokenAddress, bytes32 newRoot, bytes32 ipfsHash);
    // every time a tree is topped up
    event TokensDeposited(uint indexed index, address indexed tokenAddress, uint amount);

    // anyone can add a tree
    function addMerkleTree(bytes32 newRoot, bytes32 ipfsHash, uint minEndTime, uint maxEndTime, uint pctUpFront, address depositToken, uint tokenBalance) public {
        // check basic coherence of request
        require(pctUpFront < 100, 'pctUpFront >= 100');
        require(minEndTime < maxEndTime, 'minEndTime must be less than maxEndTime');

        // prefix operator ++ increments then evaluates
        merkleTrees[++numTrees] = MerkleTree(
            newRoot,
            ipfsHash,
            minEndTime,
            maxEndTime,
            pctUpFront,
            depositToken,
            0    // tokenBalance is 0 at first because no tokens have been deposited
        );

        // pull tokens from user to fund the tree
        // if tree is insufficiently funded, then some users may not be able to be paid out, this is the responsibility
        // of the tree creator, if trees are not funded, then the UI will not display the tree
        depositTokens(numTrees, tokenBalance);
        emit MerkleTreeAdded(numTrees, depositToken, newRoot, ipfsHash);
    }

    // anyone can fund any tree
    function depositTokens(uint treeIndex, uint value) public {
        // storage because we edit
        MerkleTree storage merkleTree = merkleTrees[treeIndex];

        // bookkeeping to make sure trees do not share tokens
        merkleTree.tokenBalance += value;

        // do the transfer from the caller
        // NOTE: it is possible for user to overfund the tree and there is no mechanism to reclaim excess tokens
        // this is because there is no way for the contract to know when a tree has had all leaves claimed
        // there is also no way for the contract to know the minimum or maximum liabilities represented by the leaves
        // in short, there is no on-chain inspection of the leaves except at initialization time
        // NOTE: a malicious token contract could cause merkleTree.tokenBalance to be out of sync with the token contract
        // this is an unavoidable possibility, and it could render the tree unusable, while leaving other trees unharmed
        require(IERC20(merkleTree.tokenAddress).transferFrom(msg.sender, address(this), value), "ERC20 transfer failed");
        emit TokensDeposited(treeIndex, merkleTree.tokenAddress, value);
    }

    // user calls this to choose and start their vesting schedule
    // merkle proof confirms they are passing data previously committed to by tree creator
    // vestingTime is chosen by the user, min/max TotalPayments is committed to by the merkleRoot
    function initialize(uint merkleIndex, address destination, uint vestingTime, uint minTotalPayments, uint maxTotalPayments, bytes32[] memory proof) external {
        // user selects own vesting schedule, not others
        require(msg.sender == destination, 'Can only initialize your own tranche');
        // can only initialize once
        require(!initialized[destination][merkleIndex], "Already initialized");
        // compute merkle leaf, this is first element of proof
        bytes32 leaf = keccak256(abi.encode(destination, minTotalPayments, maxTotalPayments));
        // memory because we do not edit
        MerkleTree memory tree = merkleTrees[merkleIndex];
        // this calls into MerkleLib, super cheap ~1000 gas per proof element
        require(tree.merkleRoot.verifyProof(leaf, proof), "The proof could not be verified.");
        // mark tree as initialized, preventing re-entrance or multiple initializations
        initialized[destination][merkleIndex] = true;

        (bool valid, uint totalCoins, uint coinsPerSecond, uint startTime) = verifyVestingSchedule(merkleIndex, vestingTime, minTotalPayments, maxTotalPayments);
        require(valid, 'Invalid vesting schedule');

        // fill out the struct for the address' vesting schedule
        // don't have to mark as storage here, it's implied (why isn't it always implied when written to? solc-devs?)
        tranches[destination][merkleIndex] = Tranche(
            totalCoins,    // this is just a cached number for UI, not used
            totalCoins,    // starts out full
            startTime,     // start time will usually be in the past, if pctUpFront > 0
            block.timestamp + vestingTime,  // vesting starts from initialization time
            coinsPerSecond,  // cached value to avoid recomputation
            startTime      // this is lastWithdrawalTime, set to startTime to indicate no withdrawals have occurred yet
        );
        withdraw(merkleIndex, destination);
    }

    // user calls this to claim available (unclaimed, unlocked) tokens
    // NOTE: anyone can withdraw tokens for anyone else, but they always go to intended destination
    // msg.sender is not used in this function ;)
    function withdraw(uint merkleIndex, address destination) public {
        // initialize first, no operations on empty structs, I don't care if the values are "probably zero"
        require(initialized[destination][merkleIndex], "You must initialize your account first.");
        // storage, since we are editing
        Tranche storage tranche = tranches[destination][merkleIndex];
        // if it's empty, don't bother
        require(tranche.currentCoins >  0, 'No coins left to withdraw');
        uint currentWithdrawal = 0;

        // if after vesting period ends, give them the remaining coins, also avoids dust from rounding errors
        if (block.timestamp >= tranche.endTime) {
            currentWithdrawal = tranche.currentCoins;
        } else {
            // compute allowed withdrawal
            // secondsElapsedSinceLastWithdrawal * coinsPerSecond == coinsAccumulatedSinceLastWithdrawal
            currentWithdrawal = (block.timestamp - tranche.lastWithdrawalTime) * tranche.coinsPerSecond;
        }
        // muto? servo
        MerkleTree storage tree = merkleTrees[merkleIndex];

        // update struct, modern solidity will catch underflow and prevent currentWithdrawal from exceeding currentCoins
        // but it's computed internally anyway, not user generated
        tranche.currentCoins -= currentWithdrawal;
        // move the time counter up so users can't double-withdraw allocated coins
        // this also works as a re-entrance gate, so currentWithdrawal would be 0 upon re-entrance
        tranche.lastWithdrawalTime = block.timestamp;
        // handle the bookkeeping so trees don't share tokens, do it before transferring to create one more re-entrance gate
        tree.tokenBalance -= currentWithdrawal;

        // transfer the tokens, brah
        // NOTE: if this is a malicious token, what could happen?
        // 1/ token doesn't transfer given amount to recipient, this is bad for user, but does not effect other trees
        // 2/ token fails for some reason, again bad for user, but this does not effect other trees
        // 3/ token re-enters this function (or other, but this is the only one that transfers tokens out)
        // in which case, lastWithdrawalTime == block.timestamp, so currentWithdrawal == 0
        // besides msg.sender is not used in this function, so who calls it is irrelevant...
        require(IERC20(tree.tokenAddress).transfer(destination, currentWithdrawal), 'Token transfer failed');
        emit WithdrawalOccurred(destination, currentWithdrawal, tranche.currentCoins, merkleIndex);
    }

    // used to determine whether the vesting schedule is legit
    function verifyVestingSchedule(uint merkleIndex, uint vestingTime, uint minTotalPayments, uint maxTotalPayments) public view returns (bool, uint, uint, uint) {
        // vesting schedules for non-existing trees are invalid, I don't care how much you like uninitialized structs
        if (merkleIndex > numTrees) {
            return (false, 0, 0, 0);
        }

        // memory not storage, since we do not edit the tree, and it's a view function anyways
        MerkleTree memory tree = merkleTrees[merkleIndex];

        // vesting time must sit within the closed interval of [minEndTime, maxEndTime]
        if (vestingTime > tree.maxEndTime || vestingTime < tree.minEndTime) {
            return (false, 0, 0, 0);
        }

        uint totalCoins;
        if (vestingTime == tree.maxEndTime) {
            // this is to prevent dust accumulation from rounding errors
            // maxEndTime results in max payments, no further computation necessary
            totalCoins = maxTotalPayments;
        } else {
            // remember grade school algebra? slope = Δy / Δx
            // this is the slope of eligible vesting schedules. In general, 0 < m < 1,
            // (longer vesting schedules should result in less coins per second, hence "resistor")
            // so we multiply by a precision factor to reduce rounding errors
            // y axis = total coins released after vesting completed
            // x axis = length of vesting schedule
            // this is the line of valid end-points for the chosen vesting schedule line, see below
            // NOTE: this reverts if minTotalPayments > maxTotalPayments, which is a good thing
            uint paymentSlope = (maxTotalPayments - minTotalPayments) * PRECISION / (tree.maxEndTime - tree.minEndTime);

            // y = mx + b = paymentSlope * (x - x0) + y0
            // divide by precision factor here since we have completed the rounding error sensitive operations
            totalCoins = (paymentSlope * (vestingTime - tree.minEndTime) / PRECISION) + minTotalPayments;
        }

        // this is a different slope, the slope of their chosen vesting schedule
        // y axis = cumulative coins emitted
        // x axis = time elapsed
        // NOTE: vestingTime starts from block.timestamp, so doesn't include coins already available from pctUpFront
        // totalCoins / vestingTime is wrong, we have to multiple by the proportion of the coins that are indexed
        // by vestingTime, which is (100 - pctUpFront) / 100
        uint coinsPerSecond = (totalCoins * (uint(100) - tree.pctUpFront)) / (vestingTime * 100);

        // vestingTime is relative to initialization point
        // endTime = block.timestamp + vestingTime
        // vestingLength = totalCoins / coinsPerSecond
        uint startTime = block.timestamp + vestingTime - (totalCoins / coinsPerSecond);

        return (true, totalCoins, coinsPerSecond, startTime);
    }

}