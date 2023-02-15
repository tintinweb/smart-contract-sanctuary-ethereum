// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library MessageLib{
    bytes32 internal constant NAMESPACE = keccak256("message.lib");

    struct Storage {
        string message;
    }

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

    function addMessage(string calldata _msg) internal {
        Storage storage s = getStorage();
        s.message = string.concat(s.message, " ");
        s.message = string.concat(s.message, _msg);
    }

    function getMessage() internal view returns(string memory){
        return getStorage().message;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./MessageLib.sol";

contract ReadMessage {
    function getMessage() external view returns(string memory){
        return MessageLib.getMessage();
    }
}