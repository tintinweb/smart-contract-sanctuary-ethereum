// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

contract MessageFacet{
    bytes32 internal constant NAMESPACE = keccak256("MESSAGE.FACET");

    struct Storage{
        string message;
    }

    function getStorage() internal pure returns (Storage storage s){
        bytes32 position = NAMESPACE;
        assembly{
            s.slot := position
        }
    }

    function setStorage(string calldata _message) external {
        Storage storage s = getStorage();
        s.message = _message;
    }

    function getMessage() external view returns(string memory){
        return getStorage().message;
    }
}