// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.18;

contract MessageFacet2 {
    bytes32 internal constant NAMESPACE = keccak256("message.facet");

    struct Storage {
        string message;
    }

    function getStorage() internal pure returns (Storage storage s){
        bytes32 position = NAMESPACE;
        assembly {
            s.slot := position
        }
    }

    function setMessage(string calldata _message) external {
        Storage storage s = getStorage();
        s.message = _message;
    }

    function getMessageImproved() external view returns (string memory) {
        return getStorage().message;
    }
}