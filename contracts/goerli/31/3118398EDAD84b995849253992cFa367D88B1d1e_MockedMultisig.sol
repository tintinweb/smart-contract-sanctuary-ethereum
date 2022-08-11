// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

/// @dev A mock multisig function that calls the given executed function
contract MockedMultisig {
    function execute(address destination, bytes memory data) public {
        (bool success, bytes memory result) = destination.call(data);

        if (!success) {
            if (result.length == 0) revert();
            assembly {
                revert(add(32, result), mload(result))
            }
        }
    }
}