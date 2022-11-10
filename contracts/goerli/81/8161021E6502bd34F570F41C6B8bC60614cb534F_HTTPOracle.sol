// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./HTTPRequest.sol";
import "./IHTTPConsumer.sol";
import "./IHTTPOracle.sol";

contract HTTPOracle is IHTTPOracle {
    function makeHTTPResponse(
        uint256 id,
        bytes memory signature,
        address consumer,
        bytes memory res
    ) public {
        IHTTPConsumer httpConsumer = IHTTPConsumer(consumer);
        bool success = httpConsumer.consumeHTTPResponse(id, signature, res);
        emit HTTPRequestFulfilled(id, consumer, success);
    }

    function makeHTTPRequest(uint256 id, address consumer) public {
        emit HTTPRequestCalled(id, consumer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

struct HTTPRequest {
    bytes8 method;
    bytes url;
    bytes body;
    bytes[] headers;
    bytes[] fields;
    bytes handlerFunction;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./HTTPRequest.sol";

interface IHTTPConsumer {
    function findHTTPRequest(uint256 id)
        external
        view
        returns (HTTPRequest memory, bool);

    function consumeHTTPResponse(uint256 id, bytes memory signature, bytes memory res)
        external
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IHTTPOracle {
    event HTTPRequestCalled(uint256 indexed id, address indexed consumer);
    event HTTPRequestFulfilled(
        uint256 indexed id,
        address indexed consumer,
        bool indexed success
    );

    function makeHTTPResponse(
        uint256 id,
        bytes memory signature,
        address consumer,
        bytes memory res
    ) external;

    function makeHTTPRequest(uint256 id, address consumer) external;
}