//SPDX-License-Identifier: MIT


pragma solidity ^ 0.8.8;

contract Facet {
    bytes32 internal constant NAMESPACE = keccak256("message.facet");

    struct Storage {
        string message;
    }

    function getStorage() internal pure returns (Storage storage s){
        bytes32 pos = NAMESPACE;
        assembly {
            s.slot := pos
        }
    }

    function setMessage(string calldata _msg) external {
        Storage storage s = getStorage();
        s.message = _msg;
    }

    function getMessage() external view returns (string memory) {
        return getStorage().message;
    }
}