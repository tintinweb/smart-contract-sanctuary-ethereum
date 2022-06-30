// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

interface ICrvPriceOracle {
    function usdToCrv(uint256 amount) external view returns (uint256);

    function crvToUsd(uint256 amount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

import "ICrvPriceOracle.sol";

contract MockCrvPriceOracle is ICrvPriceOracle {
    function usdToCrv(uint256 amount) external override view returns (uint256) {
        return amount * 2;
    }

    function crvToUsd(uint256 amount) external override view returns (uint256) {
        return amount / 2;
    }
}