// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./interfaces/IRandomizer.sol";

contract Randomizer {

    function random(uint256 seed) external view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        tx.origin,
                        blockhash(block.number - 1),
                        block.timestamp,
                        seed
                    )
                )
            );
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IRandomizer {
    function random(uint256) external returns (uint256);
}