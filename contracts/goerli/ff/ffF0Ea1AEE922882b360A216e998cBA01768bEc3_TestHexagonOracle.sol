// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IHexagonOracle {
    function getTotalETHStakingProceeds(uint256 epoch) external view returns (uint256);
}

pragma solidity ^0.8.9;

/* SPDX-License-Identifier: UNLICENSED */

/**
 * @title Test implementation of Beacon chain oracle
 */
contract TestBeaconChainOracle {
    /// @notice Foundation validator's indexes
    string public validatorIndexes;

    constructor() {
        validatorIndexes = "1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20";
    }

    function balanceByEpoch(uint256 _epoch) external pure returns (uint256) {
        return 200 ether;
    }
}

pragma solidity ^0.8.9;

/* SPDX-License-Identifier: UNLICENSED */

/**
 * @title Test implementation of execution layer oracle.
 */
contract TestExecutionLayerOracle {
    /// @notice validator's address collecting fees
    address public validatorAddress;

    constructor() {
        validatorAddress = address(0xe7cf7C3BA875Dd3884Ed6a9082d342cb4FBb1f1b);
    }

    function balanceByEpoch(uint256 _epoch) external pure returns (uint256) {
        return 200 ether;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../interfaces/IHexagonOracle.sol";
import "./TestBeaconChainOracle.sol";
import "./TestExecutionLayerOracle.sol";

/**
 * @title Test implementation of hexagon oracle.
 */
contract TestHexagonOracle is IHexagonOracle {

    function getTotalETHStakingProceeds(uint256 epoch) public view returns (uint256) {
        return 400 ether;
    }
}