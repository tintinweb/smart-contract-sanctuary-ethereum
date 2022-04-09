// ███████  ██████  ██████   ██████  ███████
// ██      ██    ██ ██   ██ ██       ██
// █████   ██    ██ ██████  ██   ███ █████
// ██      ██    ██ ██   ██ ██    ██ ██
// ██       ██████  ██   ██  ██████  ███████
// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import { ForgeDeploymentBaseBase } from "src/ForgeDeploymentBaseBase.sol";

contract ForgeDeploymentBase is ForgeDeploymentBaseBase {
    function testBase() external pure returns (uint256) {
        return 2;
    }
}

// ███████  ██████  ██████   ██████  ███████
// ██      ██    ██ ██   ██ ██       ██
// █████   ██    ██ ██████  ██   ███ █████
// ██      ██    ██ ██   ██ ██    ██ ██
// ██       ██████  ██   ██  ██████  ███████
// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract ForgeDeploymentBaseBase {
    function testBaseBase() external pure returns (uint256) {
        return 2;
    }
}

// ███████  ██████  ██████   ██████  ███████
// ██      ██    ██ ██   ██ ██       ██
// █████   ██    ██ ██████  ██   ███ █████
// ██      ██    ██ ██   ██ ██    ██ ██
// ██       ██████  ██   ██  ██████  ███████
// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import { ForgeDeploymentBase } from "./ForgeDeploymentBase.sol";

contract ForgeDeploymentTest is ForgeDeploymentBase {
    function test() external pure returns (uint256) {
        return 3;
    }
}