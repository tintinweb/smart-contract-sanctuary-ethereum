// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;


contract NewMessageFacet{
    bytes32 internal constant NAMESPACE = keccak256("MESSAGE.FACET");

    struct Storage{
        string message;
    }

    mapping(uint256=>Storage) idToStorage;

    event NewMessage(string  NewMessage);

    function getStorage() internal pure returns (Storage storage s){
        bytes32 position = NAMESPACE;
        assembly{
            s.slot := position
        }
    }

    function setStorage(uint256 _id,string calldata _message) external {
        Storage storage s = idToStorage[_id];
        s.message = _message;
        emit NewMessage(_message);
    }

    function getMessage(uint256 _id) external view returns(string memory){
        Storage storage s = idToStorage[_id];
        return s.message;
    }


}