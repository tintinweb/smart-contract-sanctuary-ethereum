/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library MessageLib{
    
    bytes32 internal constant NAMESPACE = keccak256("DiamondProxy.lib.message");
    struct Storage{
        string message;
    }
    function getStorage() internal pure returns(Storage storage s){
        bytes32 position = NAMESPACE;
        assembly {
            s.slot := position
        }
    }
    function setMessage(string calldata _msg) internal  {
        Storage storage s= getStorage();
        s.message = _msg;
    }
    function getMessage() internal view returns(string memory){
        return getStorage().message;
    }
}
contract writeMessageFacet{
    function setMessage(string calldata _msg) external  {
        MessageLib.setMessage(_msg);
    }
}