//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

import "./Logger.sol";

contract Executor {
    Logger logger;

    constructor(Logger _logger) {
        logger = _logger;
    }

    function execute(string memory _message) external {
        logger.log(_message);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

contract Logger {
    event Hello(string message);

    function log(string memory _message) external {
        emit Hello(_message);
    }
}