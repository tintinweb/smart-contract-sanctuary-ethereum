// SPDX-License-Identifier: GPL-3.0
import {ITreeSeeder} from "./interfaces/ITreeSeeder.sol";

pragma solidity ^0.8.6;

//        _-_
//     /~~   ~~\
//   /~         ~\
//  (             )
//   \  _-    -_  /
//    ^  \\ //  ^
//        | |
//        | |
//        | |
//       /   \
/// @title The Merge Tree Seeder
/// @author Anthony Graignic (@agraignic)
/// Inspired by Noun's seeder as it allow a cleaner code organization and simplify testing & QA.
contract TheMergeTreeSeeder is ITreeSeeder {
    uint8 internal constant INIT_SEGMENTS = 6;

    /// @notice Generate a pseudo-random Merge Tree using previous blockhash, contract address & tokenId
    function generateTree(
        uint256 tokenId,
        bool grow,
        uint256 contractInitBlockNumber
    ) external view override returns (Tree memory) {
        // Get some pseudo-randomness from block
        bytes32 predictableRandom = keccak256(
            abi.encodePacked(
                blockhash(block.number - 1),
                address(this),
                tokenId
            )
        );

        uint8 randomAngleSelector = uint8(predictableRandom[2]) & 0x07;
        uint16 randomAngle = 30;
        if (randomAngleSelector == 2) {
            randomAngle = 20;
        } else if (randomAngleSelector > 2 && randomAngleSelector < 5) {
            randomAngle = 45;
        } else if (randomAngleSelector > 4 && randomAngleSelector < 7) {
            randomAngle = 60;
        } else if (randomAngleSelector == 7) {
            randomAngle = 90;
        }

        return
            Tree({
                initLength: grow
                    ? (10 +
                        ((30 * (uint32(uint8(predictableRandom[0])))) / 255))
                    : 250,
                diameter: (5 +
                    ((35 * uint32(uint8(predictableRandom[1]))) / 255)),
                segments: grow ? 2 : INIT_SEGMENTS,
                branches: 2 + (uint8(predictableRandom[3]) % 0x03), // 50% chance of having 2
                animated: (predictableRandom[1] >> 7) == 0 &&
                    (predictableRandom[2] >> 7) == 0 &&
                    (predictableRandom[3] >> 7) == 0,
                angle: randomAngle,
                d: 1 +
                    ((10 * (uint8((predictableRandom[2] >> 5) & 0x0F))) / 16),
                delta: uint8(predictableRandom[2] >> 3) & 0x03,
                cuts: 0,
                mintedSince: uint128(block.number - contractInitBlockNumber)
            });
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

//        _-_
//     /~~   ~~\
//   /~         ~\
//  (             )
//   \  _-    -_  /
//    ^  \\ //  ^
//        | |
//        | |
//        | |
//       /   \
/// @title Interface for TheMergeTreeSeeder
interface ITreeSeeder {
    /// @notice Tree structure
    /// 114 bits + 128
    struct Tree {
        uint32 initLength;
        uint32 diameter;
        uint8 segments;
        uint8 branches;
        bool animated;
        uint16 angle;
        /// @dev D: fractal dimension (Hausdorff) of the tree skeleton (for length calculation)
        /// 2 < D < 3
        /// Stored as an index of the precomputed values (see TheMergeTreesRenderer.sol)
        uint8 d;
        /// @dev the Leonardo exponent (for diameter calculation)
        /// 1.93 < delta < 2.21 for infinite branching
        /// Stored as an index of the precomputed values (see TheMergeTreesRenderer.sol)
        uint8 delta;
        uint8 cuts;
        uint128 mintedSince;
    }

    function generateTree(
        uint256 tokenId,
        bool grow,
        uint256 contractInitBlockNumber
    ) external view returns (Tree memory);
}