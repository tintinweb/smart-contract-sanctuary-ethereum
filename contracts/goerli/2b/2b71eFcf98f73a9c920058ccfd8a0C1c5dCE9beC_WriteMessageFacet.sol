// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

import "./MessageLib.sol";

contract WriteMessageFacet {

    function setMessage(uint[] calldata _id, string[] calldata _message) external {
        MessageLib.setMessage(_id, _message);
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

    function getStorage() internal pure returns (Storage[] storage s){
        bytes32 position = NAMESPACE;
        assembly {
            s.slot := position
        }
    }

    function setMessage(uint[] calldata _id, string[] calldata _message) internal{
        Storage[] storage s = getStorage();
        for(uint i; _id.length > i; i++){
            s.push(Storage({id:_id[i], message:_message[i]}));
        }
    }

    function getMessage() internal view returns (uint[] memory, string[] memory){
        uint length = getStorage().length;
        uint[] memory retrievedIDs = new uint[](length+1);
        string[] memory  retrievedMessages = new string[](length+1);
        for (uint i; length > i; i++){
            retrievedIDs[i] = getStorage()[i].id;
            retrievedMessages[i] = getStorage()[i].message;
        }
        return (retrievedIDs, retrievedMessages);
    }

}