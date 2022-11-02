// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Endian.sol";
import "./interfaces/IBtcMirror.sol";

//
//                                        #
//                                       # #
//                                      # # #
//                                     # # # #
//                                    # # # # #
//                                   # # # # # #
//                                  # # # # # # #
//                                 # # # # # # # #
//                                # # # # # # # # #
//                               # # # # # # # # # #
//                              # # # # # # # # # # #
//                                   # # # # # #
//                               +        #        +
//                                ++++         ++++
//                                  ++++++ ++++++
//                                    +++++++++
//                                      +++++
//                                        +
//
// BtcMirror lets you prove that a Bitcoin transaction executed, on Ethereum. It
// does this by running an on-chain light client.
//
// Anyone can submit block headers to BtcMirror. The contract verifies
// proof-of-work, keeping only the longest chain it has seen. As long as 50% of
// Bitcoin hash power is honest and at least one person is running the submitter
// script, the BtcMirror contract always reports the current canonical Bitcoin
// chain.
contract BtcMirror is IBtcMirror {
    /**
     * @notice Emitted whenever the contract accepts a new heaviest chain.
     */
    event NewTip(uint256 blockHeight, uint256 blockTime, bytes32 blockHash);

    /**
     * @notice Emitted only after a difficulty retarget, when the contract
     *         accepts a new heaviest chain with updated difficulty.
     */
    event NewTotalDifficultySinceRetarget(
        uint256 blockHeight,
        uint256 totalDifficulty,
        uint32 newDifficultyBits
    );

    /**
     * @notice Emitted when we reorg out a portion of the chain.
     */
    event Reorg(uint256 count, bytes32 oldTip, bytes32 newTip);

    uint256 private latestBlockHeight;

    uint256 private latestBlockTime;

    mapping(uint256 => bytes32) private blockHeightToHash;

    mapping(uint256 => uint256) private periodToTarget;

    /** @notice The longest reorg that this BtcMirror instance has observed. */
    uint256 public longestReorg;

    /** @notice Whether we're tracking testnet or mainnet Bitcoin. */
    bool public immutable isTestnet;

    /** @notice Tracks Bitcoin starting from a given block. The isTestnet
     *          argument is necessary because the Bitcoin testnet does not
     *          respect the difficulty rules, so we disable block difficulty
     *          checks in order to track it.
     */
    constructor(
        uint256 _blockHeight,
        bytes32 _blockHash,
        uint256 _blockTime,
        uint256 _expectedTarget,
        bool _isTestnet
    ) {
        blockHeightToHash[_blockHeight] = _blockHash;
        latestBlockHeight = _blockHeight;
        latestBlockTime = _blockTime;
        periodToTarget[_blockHeight / 2016] = _expectedTarget;
        isTestnet = _isTestnet;
    }

    /**
     * @notice Returns the Bitcoin block hash at a specific height.
     */
    function getBlockHash(uint256 number) public view returns (bytes32) {
        return blockHeightToHash[number];
    }

    /**
     * @notice Returns the height of the current chain tip.
     */
    function getLatestBlockHeight() public view returns (uint256) {
        return latestBlockHeight;
    }

    /**
     * @notice Returns the timestamp of the current chain tip.
     */
    function getLatestBlockTime() public view returns (uint256) {
        return latestBlockTime;
    }

    /**
     * Submits a new Bitcoin chain segment. Must be heavier (not necessarily
     * longer) than the chain rooted at getBlockHash(getLatestBlockHeight()).
     */
    function submit(uint256 blockHeight, bytes calldata blockHeaders) public {
        uint256 numHeaders = blockHeaders.length / 80;
        require(numHeaders * 80 == blockHeaders.length, "wrong header length");
        require(numHeaders > 0, "must submit at least one block");

        // sanity check: the new chain must not end in a past difficulty period
        // (BtcMirror does not support a 2-week reorg)
        uint256 oldPeriod = latestBlockHeight / 2016;
        uint256 newHeight = blockHeight + numHeaders - 1;
        uint256 newPeriod = newHeight / 2016;
        require(newPeriod >= oldPeriod, "old difficulty period");

        // if we crossed a retarget, do extra math to compare chain weight
        uint256 parentPeriod = (blockHeight - 1) / 2016;
        uint256 oldWork = 0;
        if (newPeriod > parentPeriod) {
            assert(newPeriod == parentPeriod + 1);
            // the submitted chain segment contains a difficulty retarget.
            if (newPeriod == oldPeriod) {
                // the old canonical chain is past the retarget
                // we cannot compare length, we must compare total work
                oldWork = getWorkInPeriod(oldPeriod, latestBlockHeight);
            } else {
                // the old canonical chain is before the retarget
                assert(oldPeriod == parentPeriod);
            }
        }

        // verify and store each block
        bytes32 oldTip = getBlockHash(latestBlockHeight);
        uint256 nReorg = 0;
        for (uint256 i = 0; i < numHeaders; i++) {
            uint256 blockNum = blockHeight + i;
            nReorg += submitBlock(blockNum, blockHeaders[80 * i:80 * (i + 1)]);
        }

        // check that we have a new heaviest chain
        if (newPeriod > parentPeriod) {
            // the submitted chain segment crosses into a new difficulty
            // period. this is happens once every ~2 weeks. check total work
            bytes calldata lastHeader = blockHeaders[80 * (numHeaders - 1):];
            uint32 newDifficultyBits = Endian.reverse32(
                uint32(bytes4(lastHeader[72:76]))
            );

            uint256 newWork = getWorkInPeriod(newPeriod, newHeight);
            require(newWork > oldWork, "insufficient total difficulty");

            // erase any block hashes above newHeight, now invalidated.
            // (in case we just accepted a shorter, heavier chain.)
            for (uint256 i = newHeight + 1; i <= latestBlockHeight; i++) {
                blockHeightToHash[i] = 0;
            }

            emit NewTotalDifficultySinceRetarget(
                newHeight,
                newWork,
                newDifficultyBits
            );
        } else {
            // here we know what newPeriod == oldPeriod == parentPeriod
            // with identical per-block difficulty. just keep the longest chain.
            assert(newPeriod == oldPeriod);
            assert(newPeriod == parentPeriod);
            require(newHeight > latestBlockHeight, "insufficient chain length");
        }

        // record the new tip height and timestamp
        latestBlockHeight = newHeight;
        uint256 ixT = blockHeaders.length - 12;
        uint32 time = uint32(bytes4(blockHeaders[ixT:ixT + 4]));
        latestBlockTime = Endian.reverse32(time);

        // finally, log the new tip
        bytes32 newTip = getBlockHash(newHeight);
        emit NewTip(newHeight, latestBlockTime, newTip);
        if (nReorg > 0) {
            emit Reorg(nReorg, oldTip, newTip);
        }
    }

    function getWorkInPeriod(uint256 period, uint256 height)
        private
        view
        returns (uint256)
    {
        uint256 target = periodToTarget[period];
        uint256 workPerBlock = (2**256 - 1) / target;

        uint256 numBlocks = height - (period * 2016) + 1;
        assert(numBlocks >= 1 && numBlocks <= 2016);

        return numBlocks * workPerBlock;
    }

    function submitBlock(uint256 blockHeight, bytes calldata blockHeader)
        private
        returns (uint256 numReorged)
    {
        // compute the block hash
        assert(blockHeader.length == 80);
        uint256 blockHashNum = Endian.reverse256(
            uint256(sha256(abi.encode(sha256(blockHeader))))
        );

        // optimistically save the block hash
        // we'll revert if the header turns out to be invalid
        bytes32 oldHash = blockHeightToHash[blockHeight];
        bytes32 newHash = bytes32(blockHashNum);
        if (oldHash != bytes32(0) && oldHash != newHash) {
            // if we're overwriting a non-zero block hash, that block is reorged
            numReorged = 1;
        }
        // this is the most expensive line. 20,000 gas to use a new storage slot
        blockHeightToHash[blockHeight] = newHash;

        // verify previous hash
        bytes32 prevHash = bytes32(
            Endian.reverse256(uint256(bytes32(blockHeader[4:36])))
        );
        require(prevHash == blockHeightToHash[blockHeight - 1], "bad parent");
        require(prevHash != bytes32(0), "parent block not yet submitted");

        // verify proof-of-work
        bytes32 bits = bytes32(blockHeader[72:76]);
        uint256 target = getTarget(bits);
        require(blockHashNum < target, "block hash above target");

        // ignore difficulty update rules on testnet.
        // Bitcoin testnet has some clown hacks regarding difficulty, see
        // https://blog.lopp.net/the-block-storms-of-bitcoins-testnet/
        if (isTestnet) {
            return numReorged;
        }

        // support once-every-2016-blocks retargeting
        uint256 period = blockHeight / 2016;
        if (blockHeight % 2016 == 0) {
            // Bitcoin enforces a minimum difficulty of 25% of the previous
            // difficulty. Doing the full calculation here does not necessarily
            // add any security. We keep the heaviest chain, not the longest.
            uint256 lastTarget = periodToTarget[period - 1];
            require(target >> 2 < lastTarget, "<25% difficulty retarget");
            periodToTarget[period] = target;
        } else {
            // verify difficulty
            require(target == periodToTarget[period], "wrong difficulty bits");
        }
    }

    function getTarget(bytes32 bits) public pure returns (uint256) {
        // Bitcoin represents difficulty using a custom floating-point big int
        // representation. the "difficulty bits" consist of an 8-bit exponent
        // and a 24-bit mantissa, which combine to generate a u256 target. the
        // block hash must be below the target.
        uint256 exp = uint8(bits[3]);
        uint256 mantissa = uint8(bits[2]);
        mantissa = (mantissa << 8) | uint8(bits[1]);
        mantissa = (mantissa << 8) | uint8(bits[0]);
        uint256 target = mantissa << (8 * (exp - 3));
        return target;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

// Bitwise math helpers for dealing with Bitcoin block headers.
// Bitcoin block fields are little-endian. Must flip to big-endian for EVM.
library Endian {
    function reverse256(uint256 input) internal pure returns (uint256 v) {
        v = input;

        // swap bytes
        uint256 pat1 = 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00;
        v = ((v & pat1) >> 8) | ((v & ~pat1) << 8);

        // swap 2-byte long pairs
        uint256 pat2 = 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000;
        v = ((v & pat2) >> 16) | ((v & ~pat2) << 16);

        // swap 4-byte long pairs
        uint256 pat4 = 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000;
        v = ((v & pat4) >> 32) | ((v & ~pat4) << 32);

        // swap 8-byte long pairs
        uint256 pat8 = 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000;
        v = ((v & pat8) >> 64) | ((v & ~pat8) << 64);

        // swap 16-byte long pairs
        v = (v >> 128) | (v << 128);
    }

    function reverse64(uint64 input) internal pure returns (uint64 v) {
        v = input;

        // swap bytes
        v = ((v & 0xFF00FF00FF00FF00) >> 8) | ((v & 0x00FF00FF00FF00FF) << 8);

        // swap 2-byte long pairs
        v = ((v & 0xFFFF0000FFFF0000) >> 16) | ((v & 0x0000FFFF0000FFFF) << 16);

        // swap 4-byte long pairs
        v = (v >> 32) | (v << 32);
    }

    function reverse32(uint32 input) internal pure returns (uint32 v) {
        v = input;

        // swap bytes
        v = ((v & 0xFF00FF00) >> 8) | ((v & 0x00FF00FF) << 8);

        // swap 2-byte long pairs
        v = (v >> 16) | (v << 16);
    }

    function reverse16(uint16 input) internal pure returns (uint16 v) {
        v = input;

        // swap bytes
        v = (v >> 8) | (v << 8);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/** @notice Tracks Bitcoin. Provides block hashes. */
interface IBtcMirror {
    /** @notice Returns the Bitcoin block hash at a specific height. */
    function getBlockHash(uint256 number) external view returns (bytes32);

    /** @notice Returns the height of the latest block (tip of the chain). */
    function getLatestBlockHeight() external view returns (uint256);

    /** @notice Returns the timestamp of the lastest block, as Unix seconds. */
    function getLatestBlockTime() external view returns (uint256);

    /** @notice Submits a new Bitcoin chain segment (80-byte headers) s*/
    function submit(uint256 blockHeight, bytes calldata blockHeaders) external;
}