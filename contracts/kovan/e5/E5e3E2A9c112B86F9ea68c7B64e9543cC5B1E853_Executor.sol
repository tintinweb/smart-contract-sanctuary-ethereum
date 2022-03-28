//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

import "./Logger.sol";

contract Executor {
    Logger logger;

    constructor(Logger _logger) {
        logger = _logger;
    }

    function execute() external {
        logger.log();
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

contract Logger {
    event Hello(string message);

    function log() external {
        emit Hello("Hello");
    }
}