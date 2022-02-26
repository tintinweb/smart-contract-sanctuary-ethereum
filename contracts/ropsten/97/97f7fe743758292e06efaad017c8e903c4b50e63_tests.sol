/**
 *Submitted for verification at Etherscan.io on 2022-02-26
*/

pragma solidity ^0.8.4;

contract tests {
    function test() public pure returns(bytes32){ bytes memory a = new bytes(32); return keccak256(a); } 

    function hashAbiEncodedMessage(string memory abiMessage) public pure returns( bytes32){
        return keccak256(abi.encode(abiMessage));
    }
    function hashAbiEncodedMessagePACKED(string memory abiMessage) public pure returns( bytes32){
        return keccak256(abi.encodePacked(abiMessage));
    }
}