pragma solidity ^0.8.0;

contract SimpleStorage {

    mapping(address => string) public ipfsHash;

    function setIpfsHash(string memory _ipfsHash) public {
        ipfsHash[msg.sender] = _ipfsHash;
    }

}