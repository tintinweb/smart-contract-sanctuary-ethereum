// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.14;

import "./BridgeBase.sol";

contract BridgeTest is BridgeBase {
    string public value;

    constructor(address coordinator) BridgeBase(coordinator) {}

    function updateValue(string memory request) external payable {
        requestBridge(request);
    }

    function respondBridge(string memory response) internal override {
        value = response;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.14;

import "./BridgeInterface.sol";

abstract contract BridgeBase {
    address private immutable coordinator;

    BridgeInterface internal immutable Bridge;

    constructor(address _coordinator) {
        coordinator = _coordinator;
        Bridge = BridgeInterface(_coordinator);
    }

    function respondBridge(string memory response) internal virtual;

    function requestBridge(string memory request) internal {
        Bridge.requestBridge{value: msg.value}(request);
    }

    function rawRespondBridge(string memory response) external {
        require(msg.sender == coordinator, "only coordinator can respond");

        respondBridge(response);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.14;

interface BridgeInterface {
    function requestBridge(string memory request) external payable;

    function rawRespondBridge(string memory response) external;
}