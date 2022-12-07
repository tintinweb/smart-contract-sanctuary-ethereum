// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

contract Facet {

    bytes32 internal constant NAMESPACE = keccak256(bytes("Facet.Facet"));

    struct Storage {
        string message;
    }

    function getStorage() internal pure returns(Storage storage s) {
        bytes32 position = NAMESPACE;
        // returns Storage struct at slot position
        assembly {
            s.slot := position
        }

    }

    function writeMessage(string calldata _message) external {
        require(bytes(_message).length > 0, "String Required!");
        Storage storage s = getStorage();
        s.message = _message;
    }

    function readMessage() external view returns(string memory) {
        Storage storage s = getStorage();
        return s.message;
    }

}