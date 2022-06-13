pragma solidity 0.8.14;

import {Job} from "../Job.sol";

/**
 * @title Job
 * @dev Job contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
contract IncreaseOneJob is Job {
    uint256 public number;
    uint256 public lastUpdateBlock;

    constructor(address _master) Job(_master) {
        lastUpdateBlock = block.number;
    }

    function workable() external view override returns (bool, bytes memory) {
        return (block.number - lastUpdateBlock >= 10, "");
    }

    function work(bytes calldata) external override needsExecution {
        if (msg.sender != MASTER) revert Forbidden();
        number++;
        lastUpdateBlock = block.number;
    }
}

pragma solidity 0.8.14;

import {IJob} from "./interfaces/IJob.sol";

/**
 * @title Job
 * @dev Job contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
abstract contract Job is IJob {
    address public immutable MASTER;

    error Forbidden();
    error ZeroAddressMaster();

    constructor(address _master) {
        if (_master == address(0)) revert ZeroAddressMaster();
        MASTER = _master;
    }

    function work(bytes calldata _data) external virtual override;

    modifier needsExecution() {
        if (msg.sender != MASTER) revert Forbidden();
        _;
    }
}

pragma solidity >=0.8.0;

/**
 * @title IJob
 * @dev IJob contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
interface IJob {
    function workable() external view returns (bool, bytes memory);

    function work(bytes calldata _data) external;
}