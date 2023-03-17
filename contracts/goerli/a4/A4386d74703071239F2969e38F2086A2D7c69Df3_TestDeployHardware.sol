// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {ITestDeployHardware} from "../interfaces/ITestDeployHardware.sol";

contract TestDeployHardware is ITestDeployHardware {
    function Hello() pure external override returns (bool) {
        return true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface ITestDeployHardware {
    function Hello() pure external returns (bool);
}