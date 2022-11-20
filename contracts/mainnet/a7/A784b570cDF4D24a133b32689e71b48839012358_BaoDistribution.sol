// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

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


/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLibrary {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}


interface IVotingEscrow {
    function create_lock_for(address _to, uint256 _value, uint256 _unlock_time) external;
}


contract BaoDistribution is ReentrancyGuard {

    // -------------------------------
    // VARIABLES
    // -------------------------------

    //BaoToken public baoToken;
    IERC20 public baoToken;
    IVotingEscrow public votingEscrow;
    mapping(address => DistInfo) public distributions;
    mapping(address => bool) public lockStatus;
    address public treasury;

    // -------------------------------
    // CONSTANTS
    // -------------------------------

    bytes32 public immutable merkleRoot;

    // -------------------------------
    // STRUCTS
    // -------------------------------

    struct DistInfo {
        uint64 dateStarted;
        uint64 dateEnded;
        uint64 lastClaim;
        uint256 amountOwedTotal;
    }

    // -------------------------------
    // EVENTS
    // -------------------------------

    event DistributionStarted(address _account);
    event TokensClaimed(address _account, uint256 _amount);
    event DistributionEnded(address _account, uint256 _amount);
    event DistributionLocked(address _account, uint256 _amount);

    // -------------------------------
    // CUSTOM ERRORS
    // -------------------------------

    error DistributionAlreadyStarted();
    error DistributionEndedEarly();
    error InvalidProof(address _account, uint256 _amount, bytes32[] _proof);
    error ZeroClaimable();
    error InvalidTimestamp();
    error outsideLockRange();
    error alreadyLocked();

    /**
     * Create a new BaoDistribution contract.
     *
     * @param _baoToken Token to distribute.
     * @param _votingEscrow vote escrow BAO contract
     * @param _merkleRoot Merkle root to verify accounts' inclusion and amount owed when starting their distribution.
     */
    constructor(address _baoToken, address _votingEscrow ,bytes32 _merkleRoot, address _treasury) {
        baoToken = IERC20(_baoToken);
        votingEscrow = IVotingEscrow(_votingEscrow);
        merkleRoot = _merkleRoot;
        treasury = _treasury;
    }

    // -------------------------------
    // PUBLIC FUNCTIONS
    // -------------------------------

    /**
     * Starts the distribution of BAO for msg.sender.
     *
     * @param _proof Merkle proof to verify msg.sender's inclusion and claimed amount.
     * @param _amount Amount of tokens msg.sender is owed. Used to generate the merkle tree leaf.
     */
    function startDistribution(bytes32[] memory _proof, uint256 _amount) external {
        if (distributions[msg.sender].dateStarted != 0) {
            revert DistributionAlreadyStarted();
        } else if (!verifyProof(_proof, keccak256(abi.encodePacked(msg.sender, _amount)))) {
            revert InvalidProof(msg.sender, _amount, _proof);
        }

        uint64 _now = uint64(block.timestamp);
        distributions[msg.sender] = DistInfo(
            _now,
            0,
            _now,
            _amount / 1000
        );
        emit DistributionStarted(msg.sender);
    }

    /**
     * Claim all tokens that have been accrued since msg.sender's last claim.
     */
    function claim() external nonReentrant {
        uint256 _claimable = claimable(msg.sender, 0);
        if (_claimable == 0) {
            revert ZeroClaimable();
        }

        // Update account's DistInfo
        distributions[msg.sender].lastClaim = uint64(block.timestamp);

        // Send account the tokens that they've accrued since their last claim.
        baoToken.transfer(msg.sender, _claimable);

        // Emit tokens claimed event for logging
        emit TokensClaimed(msg.sender, _claimable);
    }

    /**
     * Claim all tokens that have been accrued since msg.sender's last claim AND
     * the rest of the total locked amount owed immediately at a pre-defined slashed rate.
     *
     * Slash Rate:
     * days_since_start <= 365: (100 - .01369863013 * days_since_start)%
     * days_since_start > 365: 95%
     */
    function endDistribution() external nonReentrant {
        uint256 _claimable = claimable(msg.sender, 0);
        if (_claimable == 0) {
            revert ZeroClaimable();
        }

        DistInfo storage distInfo = distributions[msg.sender];
        uint64 timestamp = uint64(block.timestamp);

        uint256 daysSinceStart = FixedPointMathLibrary.mulDivDown(uint256(timestamp - distInfo.dateStarted), 1e18, 86400);

        // Calculate total tokens left in distribution after the above claim
        uint256 tokensLeft = distInfo.amountOwedTotal - distCurve(distInfo.amountOwedTotal, daysSinceStart);

        // Calculate slashed amount
        uint256 slash = FixedPointMathLibrary.mulDivDown(
            daysSinceStart > 365e18 ? 95e16 : 1e18 - FixedPointMathLibrary.mulDivDown(daysSinceStart, 1369863013, 1e13),
            tokensLeft,
            1e18
        );
        uint256 owed = tokensLeft - slash;

        // Account gets slashed for (slash / tokensLeft)% of their remaining distribution
        baoToken.transfer(msg.sender, owed + _claimable);
        // Protocol treasury receives slashed tokens
        baoToken.transfer(treasury, slash);

        // Update DistInfo storage for account to reflect the end of the account's distribution
        distInfo.lastClaim = timestamp;
        distInfo.dateEnded = timestamp;

        // Emit tokens claimed event for logging
        emit TokensClaimed(msg.sender, _claimable);
        // Emit distribution ended event for logging
        emit DistributionEnded(msg.sender, owed);
    }

    /**
     * Lock all tokens that have NOT been claimed since msg.sender's last claim
     *
     * The Lock into veBAO will be set at _time with this function in-line with length of distribution curve (minimum of 3 years)
     */
    function lockDistribution(uint256 _time) external nonReentrant {
        if (lockStatus[msg.sender] == true) {
            revert alreadyLocked();
        }
        uint256 _claimable = claimable(msg.sender, 0);
        if (_claimable == 0) {
            revert ZeroClaimable();
        }
        if (_time < block.timestamp + 94608000) {
            revert outsideLockRange();
        }

        DistInfo storage distInfo = distributions[msg.sender];
        uint64 timestamp = uint64(block.timestamp);

        uint256 daysSinceStart = FixedPointMathLibrary.mulDivDown(uint256(timestamp - distInfo.dateStarted), 1e18, 86400);

        // Calculate total tokens left in distribution after the above claim
        uint256 tokensLeft = distInfo.amountOwedTotal - distCurve(distInfo.amountOwedTotal, daysSinceStart);

        baoToken.approve(address(votingEscrow), tokensLeft);

        //lock tokensLeft for msg.sender for _time years (minimum of 3 years)
        votingEscrow.create_lock_for(msg.sender, tokensLeft, _time);

        lockStatus[msg.sender] = true;
        distInfo.dateEnded = timestamp;

        emit DistributionLocked(msg.sender, tokensLeft);
    }

    /**
     * Get how many tokens an account is able to claim at a given timestamp. 0 = now.
     * This function takes into account the date of the account's last claim, and returns the amount
     * of tokens they've accrued since.
     *
     * @param _account Account address to query.
     * @param _timestamp Timestamp to query.
     * @return c _account's claimable tokens, scaled by 1e18.
     */
    function claimable(address _account, uint64 _timestamp) public view returns (uint256 c) {
        DistInfo memory distInfo = distributions[_account];
        uint64 dateStarted = distInfo.dateStarted;
        if (dateStarted == 0) {
            revert ZeroClaimable();
        } else if (distInfo.dateEnded != 0) {
            revert DistributionEndedEarly();
        }

        uint64 timestamp = _timestamp == 0 ? uint64(block.timestamp) : _timestamp;
        if (timestamp < dateStarted) {
            revert InvalidTimestamp();
        }

        uint256 daysSinceStart = FixedPointMathLibrary.mulDivDown(uint256(timestamp - dateStarted), 1e18, 86400);
        uint256 daysSinceClaim = FixedPointMathLibrary.mulDivDown(uint256(timestamp - distInfo.lastClaim), 1e18, 86400);

        // Allow the account to claim all tokens accrued since the last time they've claimed.
        uint256 _total = distInfo.amountOwedTotal;
        c = distCurve(_total, daysSinceStart) - distCurve(_total, daysSinceStart - daysSinceClaim);
    }

    /**
     * Get the amount of tokens that would have been accrued along the distribution curve, assuming _daysSinceStart
     * days have passed and the account has never claimed.
     *
     * f(x) = 0 <= x <= 1095 : (2x/219)^2
     *
     * @param _amountOwedTotal Total amount of tokens owed, scaled by 1e18.
     * @param _daysSinceStart Time since the start of the distribution, scaled by 1e18.
     * @return _amount Amount of tokens accrued on the distribution curve, assuming the time passed is _daysSinceStart.
     */
    function distCurve(uint256 _amountOwedTotal, uint256 _daysSinceStart) public pure returns (uint256 _amount) {
        if (_daysSinceStart >= 1095e18) return _amountOwedTotal;

        assembly {
            // Solmate's mulDivDown function
            function mulDivDown(x, y, denominator) -> z {
                // Store x * y in z for now.
                z := mul(x, y)

                // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
                if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                    revert(0, 0)
                }

                // Divide z by the denominator.
                z := div(z, denominator)
            }

            // This is disgusting, but its more gas efficient than storing the results in `_amount` each time.
            _amount := mulDivDown( // Multiply `amountOwedTotal` by distribution curve result
                div( // Correct precision after exponent op (scale down by 1e20 instead of 1e18 to convert % to a proportion)
                    exp( // Raise result to the power of two
                        mulDivDown( // (2/219) * `_daysSinceStart`
                            mulDivDown(0x1BC16D674EC80000, 0xDE0B6B3A7640000, 0xBDF3C4BB0328C0000),
                            _daysSinceStart,
                            0xDE0B6B3A7640000
                        ),
                        2
                    ),
                    0xDE0B6B3A7640000
                ),
                _amountOwedTotal,
                0x56BC75E2D63100000
            )
        }
    }

    // -------------------------------
    // PRIVATE FUNCTIONS
    // -------------------------------

    /**
     * Verifies a merkle proof against the stored root.
     *
     * @param _proof Merkle proof.
     * @param _leaf Leaf to verify.
     * @return bool True if proof is valid, false if proof is invalid.
     */
    function verifyProof(bytes32[] memory _proof, bytes32 _leaf) private view returns (bool) {
        return MerkleProof.verify(_proof, merkleRoot, _leaf);
    }
}