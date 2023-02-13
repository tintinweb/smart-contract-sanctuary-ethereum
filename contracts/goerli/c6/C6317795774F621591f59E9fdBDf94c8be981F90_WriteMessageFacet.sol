// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

import "./MessageLib.sol";

contract WriteMessageFacet {

    function setMessage(MessageLib.Storage calldata _circuit) external {
        MessageLib.setMessage(_circuit);
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

library MessageLib{

    bytes32 internal constant NAMESPACE = keccak256("wtf.lib.message");
    struct Storage{
        uint id;
        string message;
    }

    function getStorage() internal pure returns (Storage storage s){
        bytes32 position = NAMESPACE;
        assembly {
            s.slot := position
        }
    }

    function setMessage(Storage calldata _msg) internal{
        Storage storage s = getStorage();
        s.id = _msg.id;
        s.message = _msg.message;
    }

    function getMessage() internal view returns (string memory){
        return getStorage().message;
    }

}