// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract MessageFacet {
    // (1) Declare a constant to determine the slot to be used by this facet
    bytes32 internal constant NAMESPACE = keccak256("massage-facet.storage");

    // (2) Layout our storage with the variables we are going to use with this facet
    // In this case, we only want to store a message
    struct Storage {
        string message;
    }

    // (3) Retreival function to get the storage fron the defined slot
    function getStorage() internal pure returns (Storage storage s) {
        bytes32 ns = NAMESPACE;
        // (3.1) Set the slot position to reference the storage we want to manage with this facet
        assembly {
            s.slot := ns
        }
    }

    // (4) Setter function to store the message in our storage
    function setMessage(string calldata _message) external {
        // (4.1) Get storage
        Storage storage s = getStorage();
        // (4.2) Set the message value
        s.message = _message;
    }

    // (5) Getter funciton to read our message from storage
    function getMessage() external view returns (string memory) {
        return getStorage().message;
    }
}