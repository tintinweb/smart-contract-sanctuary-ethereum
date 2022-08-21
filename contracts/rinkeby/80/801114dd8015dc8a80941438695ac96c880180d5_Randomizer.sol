// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./interfaces/IRandomizer.sol";

contract Randomizer is IRandomizer {
    function getRandomHash(bytes32 seed)
        external
        view
        returns (bytes32 randomHash)
    {
        randomHash = _getRandomHash(seed);
    }

    function getRandomUint(
        bytes32 seed,
        uint256 from,
        uint256 to
    ) external view returns (uint256 randomUint) {
        require(to > from, "Invalid range");

        uint256 range = to - from + 1;
        randomUint = (uint256(_getRandomHash(seed)) % range) + from + 1;
    }

    function _getRandomHash(bytes32 seed)
        private
        view
        returns (bytes32 randomHash)
    {
        randomHash = keccak256(
            abi.encodePacked(
                seed,
                block.number,
                blockhash(block.number - 1),
                block.timestamp
            )
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IRandomizer {
    function getRandomHash(bytes32 seed)
        external
        view
        returns (bytes32 randomHash);

    function getRandomUint(
        bytes32 seed,
        uint256 from,
        uint256 to
    ) external view returns (uint256 randomUint);
}