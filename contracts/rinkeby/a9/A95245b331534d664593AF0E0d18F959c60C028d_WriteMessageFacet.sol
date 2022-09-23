pragma solidity 0.8.17;

import "./MessageLib.sol";

contract WriteMessageFacet {
    function setMessage(string calldata _msg) external {
        MessageLib.setMessage(_msg);
    }
}

pragma solidity 0.8.17;


library MessageLib {
    bytes32 internal constant NAMESPACE = keccak256("lib.message");
    struct Storage {
        string message;
    } 

    // Fetch storage
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

    function getMessage() external view returns (string memory) {
        return getStorage().message;
    }
}