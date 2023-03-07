// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IAggregatorV3 } from "./internal-upgradeable/interfaces/IAggregatorV3.sol";

contract EACAggregatorProxy is IAggregatorV3 {
    function latestRoundData() public pure override returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) {
        return (0, 734994, 0, 0, 0);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IAggregatorV3 {
    function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}