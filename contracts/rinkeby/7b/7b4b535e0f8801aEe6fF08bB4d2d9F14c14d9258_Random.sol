// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @dev Collection of functions related to the random
 */
library Random {
    struct Distribution {
        uint256 total;
        uint256[] weights;
    }

    /**
     * @dev Returns the random value.
     */
    function random(bytes memory seed) public pure returns (uint256) {
        return uint256(keccak256(seed));
    }

    /**
     * @dev Returns the limited random value.
     */
    function random(bytes memory seed, uint256 limit)
        public
        pure
        returns (uint256)
    {
        return uint256(keccak256(seed)) % limit;
    }

    /**
     * @dev Returns the weightened distributed value.
     *
     * [IMPORTANT]
     * ====
     * The weights better be sorted in descending order.
     * This function uses Hopscotch Selection method (https://blog.bruce-hill.com/a-faster-weighted-random-choice).
     * The runtime is O(1)
     * ====
     */
    function weightedDistribution(
        bytes memory seed,
        uint256 total,
        uint256[] memory weights
    ) public pure returns (uint256) {
        uint256 target = random(seed, total - 1);
        uint256 _index = 0;
        while (weights[_index] < target) {
            target -= weights[_index];
            _index++;
        }
        return _index;
    }
}