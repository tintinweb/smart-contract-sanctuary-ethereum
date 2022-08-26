pragma solidity ^0.8.13;

contract keccackChecker {
    function KeccackChecker(address addy) public view returns (bytes32){
        return keccak256(abi.encodePacked(addy));
    }
}