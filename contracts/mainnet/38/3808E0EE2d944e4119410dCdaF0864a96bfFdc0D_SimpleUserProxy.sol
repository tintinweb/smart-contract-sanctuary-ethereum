// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract SimpleUserProxy {
    error Unauthorized();

    address public owner;
    bool public initialized;

    function initialize(address _owner) external {
        if (initialized) revert Unauthorized();

        owner = _owner;
        initialized = true;
    }

    function doCall(address _target, bytes calldata _data) external payable {
        if (msg.sender != owner) revert Unauthorized();

        (bool success, bytes memory result) = _target.call{value: msg.value}(
            _data
        );
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }
}