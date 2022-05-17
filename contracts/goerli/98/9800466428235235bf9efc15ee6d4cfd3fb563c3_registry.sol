/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

pragma solidity 0.8.13;

contract registry {
    mapping(address => bytes) public pubKeys;

    function addPublicKey(bytes32 _pubKeyPart1, bytes32 _pubKeyPart2) external {
        pubKeys[msg.sender] = abi.encode(_pubKeyPart1,_pubKeyPart2);
    }

}