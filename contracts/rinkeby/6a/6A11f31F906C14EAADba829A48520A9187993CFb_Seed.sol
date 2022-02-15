// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "ISeed.sol";

contract Seed is ISeed {
    uint256 public seed1 = 123;

    function seed() external view override returns (uint256) {
        return seed1;
    }

    function update(uint256 _seed) external override returns (uint256) {
        seed1 = _seed;
        return seed1;
    }

    function generateAmount() external pure override returns (uint256) {
        return 4;
    }
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

interface ISeed {
    function seed() external view returns (uint256);

    function update(uint256 _seed) external returns (uint256);

    function generateAmount() external view returns (uint256);
}