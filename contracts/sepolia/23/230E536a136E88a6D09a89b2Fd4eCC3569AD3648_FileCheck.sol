/**
 *Submitted for verification at Etherscan.io on 2023-07-13
*/

pragma solidity >=0.8.4;

contract FileCheck {

    event FileAdded(address sender, string fileHash);

    mapping(string => bool) private fileHashes;

    address private owner;

    constructor() {
        owner = msg.sender;
    }

    function isFileHashExist(string memory fileHash) public view returns (bool){
        return fileHashes[fileHash];
    }

    function addFileHash(string memory fileHash) public {
        require(msg.sender == owner, "Only Owner can add file");
        fileHashes[fileHash] = true;
        emit FileAdded(msg.sender, fileHash);
    }

}