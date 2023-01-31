// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./MessageLib.sol";

/// @author Anto "Opixelum" Benedetti
contract ReadMessageFacet {
    function readMessage() external view returns (string memory) {
        return MessageLib._readMessage();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/// @author Anto "Opixelum" Benedetti
library MessageLib {
    bytes32 internal constant NAMESPACE = keccak256("traceability.lib.message");
    struct Storage {
        string message;
    }

    function _getStorage() internal pure returns (Storage storage s) {
        bytes32 position = NAMESPACE;
        assembly {
            s.slot := position
        }
    }

    function _writeMessage(string calldata _message) internal {
        Storage storage s = _getStorage();
        s.message = _message;
    }

    function _readMessage() internal view returns (string memory) {
        return _getStorage().message;
    }
}