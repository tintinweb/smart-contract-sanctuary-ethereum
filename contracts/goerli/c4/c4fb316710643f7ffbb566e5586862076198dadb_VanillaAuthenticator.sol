// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

abstract contract Authenticator {
    function _call(address target, bytes4 functionSelector, bytes memory data) internal {
        (bool success, ) = target.call(abi.encodePacked(functionSelector, data));
        if (!success) {
            // If the call failed, we revert with the propogated error message.
            assembly {
                let returnDataSize := returndatasize()
                returndatacopy(0, 0, returnDataSize)
                revert(0, returnDataSize)
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./Authenticator.sol";

contract VanillaAuthenticator is Authenticator {
    function authenticate(address target, bytes4 functionSelector, bytes memory data) external {
        // No authentication is performed.
        _call(target, functionSelector, data);
    }
}