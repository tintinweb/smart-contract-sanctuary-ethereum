// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.14;

contract MessageFacet {
    bytes32 internal constant NAMESPACE = keccak256("com.wtf.message");

    struct Storage {
        string message;
    }

    function setMessage(string calldata _msg) external {
        Storage storage s = getStorage();
        s.message = _msg;
    }

    function getMessage() external view returns (string memory) {
        Storage storage s = getStorage();
        return s.message;
    }

    function getStorage() internal pure returns (Storage storage s) {
        bytes32 position = NAMESPACE;
        assembly {
            s.slot := position
        }
    }
}