// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.8;

contract MessageFacet {
    bytes32 internal constant MessageFacetNameSpace1 = keccak256("message.facet_01");

    struct Storage {
        string message;
    }

    // use this function in other functions to read and write from this storage layout (internal: only callable from this Facet)
    function getStorage() internal pure returns (Storage storage s) {
        bytes32 position = MessageFacetNameSpace1;
        assembly {
            s.slot := position
        }
    }

    // externa because this is a uitility function thats has be able to be called from outside( (proxy)
    function setMessage(string calldata _msg) external {
        Storage storage s = getStorage(); // get target storage position
        s.message = _msg; // assign input of function parameter to variable at target storage
    }

    function getMessage() external view returns (string memory){
        return getStorage().message; // get current value of message variable from storage of message
    }


}