// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.15;

import "./MessageLib.sol";

contract ReadMessageFacet {
    function getMessage() internal view returns (string memory) {
        return MessageLib.getMessage();
    }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.15;

library MessageLib{
    /// Storage

    bytes32 internal constant NAMESPACE = keccak256("wtf.lib.message");
    struct Storage{
        string message;
    }

    /// Fetch Storage
    function getStorage() internal pure returns (Storage storage s) {
        bytes32 position = NAMESPACE;
        assembly {
            s.slot := position
        }
    }

    function setMessage(string calldata _msg) internal {
        Storage storage s = getStorage();
        s.message = _msg;
    }

    function getMessage() internal view returns (string memory) {
        return getStorage().message;
    }
}