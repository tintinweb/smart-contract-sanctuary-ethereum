// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

error FileStorage__FileAlreadyExist();
error FileStorage__NotAnOwner();

contract FileStorage {
    mapping(string => address) fileToOwner;

    event FileAdded(string fileId, address fileOwner);

    modifier onlyOwner(string memory fileId) {
        if (fileToOwner[fileId] != msg.sender) {
            revert FileStorage__NotAnOwner();
        } else {
            _;
        }
    }

    function addFile(string memory fileId) public {
        if (fileToOwner[fileId] == address(0)) {
            revert FileStorage__FileAlreadyExist();
        }
        fileToOwner[fileId] = msg.sender;
        emit FileAdded(fileId, msg.sender);
    }

    function getFile(
        string memory fileId
    ) public view onlyOwner(fileId) returns (bool) {
        return true;
    }

    function deleteFile(string memory fileId) public onlyOwner(fileId) {
        delete fileToOwner[fileId];
    }
}