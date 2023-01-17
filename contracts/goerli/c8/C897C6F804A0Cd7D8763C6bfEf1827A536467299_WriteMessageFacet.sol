// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

import "./MessageLib.sol";

contract WriteMessageFacet {

    function WriteMessage(string calldata _msg) external {
        MessageLib.setMessage(_msg);
    }

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

library MessageLib {

    // storage
    bytes32 internal constant NAMESPACE = keccak256("wtf.lib.message");
    struct Storage {
        string message;
    }

    // fetch storage
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