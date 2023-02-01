/**
 *Submitted for verification at Etherscan.io on 2023-02-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract FileStorage {
    struct File {
        uint256 blockNumber;
        uint256 fileDate;
        uint256 fileLength;
        address owner;
        string fileName;
    }

    event Upload(uint256 indexed fileIndex, string indexed fileName, address indexed owner, bytes fileContent);
    File[] public files;

    function getAllFiles() public view returns(File[] memory) {
        return files;
    }

    function storeFile(string calldata fileName, bytes calldata fileContent)
        external
    {
        uint256 length = files.length;
        File memory file;
        file.blockNumber = block.number;
        file.fileDate = block.timestamp;
        file.fileName = fileName;
        file.owner = msg.sender;
        file.fileLength = fileContent.length;
        files.push(file);
        emit Upload(length, fileName, msg.sender, fileContent);
    }
}