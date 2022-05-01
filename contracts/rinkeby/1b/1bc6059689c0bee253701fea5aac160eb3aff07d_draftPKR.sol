/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

pragma solidity 0.8.13;

contract draftPKR {
    mapping(address => bytes) public pubKeys;

    function addPublicKey(bytes memory _pubKey) external {
        pubKeys[msg.sender] = _pubKey;
    }


}