// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
import "Ownable.sol";
contract StampingContract is Ownable{
    string ipfsHash;

    constructor(string memory _ipfsHash) {
        ipfsHash = _ipfsHash;
    }

    function setHash(string memory x) public onlyOwner{
        //require(creator==msg.sender,"Only Owner of this contract should be able to execute this function");
        ipfsHash = x;
    }
    
    function getHash() public view returns (string memory) {
        return ipfsHash;
    }
}