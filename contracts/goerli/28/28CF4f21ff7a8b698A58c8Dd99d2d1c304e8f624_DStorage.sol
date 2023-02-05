/**
 *Submitted for verification at Etherscan.io on 2023-02-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DStorage {

    // Name of the contract
    string public name = 'DStorage';
    // count of files stored
    uint public fileCount = 0;
    // mapping of file ids to file data
    mapping(uint => File) public files;
    // mapping of addresses to a mapping of file ids to access authorization
    mapping(address => mapping(uint => bool)) public access;


    // data structure for file information
    struct File {
        uint fileId;
        string fileHash;
        uint fileSize;
        string fileType;
        string fileName;
        string fileDescription;
        uint uploadTime;
        address uploader;
    }

    // Event triggered when a file is uploaded
    event FileUploaded(
        uint fileId,
        string fileHash,
        uint fileSize,
        string fileType,
        string fileName, 
        string fileDescription,
        uint uploadTime,
        address uploader
    );

    // Event triggered when a user is granted access to a file
    event AccessGranted(address user, uint fileId);
    event AccessRevoked(address user, uint fileId);
    /**

    Function to upload a file to the contract
    @param _fileHash the hash of the file being uploaded
    @param _fileSize the size of the file being uploaded
    @param _fileType the type of the file being uploaded
    @param _fileName the name of the file being uploaded
    @param _fileDescription the description of the file being uploaded
    */
    function uploadFile(string memory _fileHash, uint _fileSize, string memory _fileType, string memory _fileName, string memory _fileDescription) public {
        // Make sure the file exists with all its required metadata
        require(bytes(_fileHash).length > 0);
        require(_fileSize > 0);
        require(bytes(_fileType).length > 0);
        require(bytes(_fileName).length > 0);
        require(bytes(_fileDescription).length > 0);
        require(msg.sender!=address(0));

        // Increment file id
        fileCount ++;

        // Add File to the contract
        files[fileCount] = File(fileCount, _fileHash, _fileSize, _fileType, _fileName, _fileDescription, block.timestamp, msg.sender);
        
        // Trigger an event
        emit FileUploaded(fileCount, _fileHash, _fileSize, _fileType, _fileName, _fileDescription, block.timestamp, msg.sender);

    }

    function grantAccess(uint _fileId, address _user) public {
        // Make sure the file exists
        require(files[_fileId].fileId == _fileId);
        // Make sure the caller is the file owner
        require(msg.sender == files[_fileId].uploader);
        // Grant access to the file
        access[msg.sender][_fileId] = true;
        // Trigger an event
        emit AccessGranted(_user, _fileId);
    }

    function revokeAccess(uint _fileId, address _user) public {
        // Make sure the file exists
        require(files[_fileId].fileId == _fileId);
        // Make sure the caller is the file owner
        require(msg.sender == files[_fileId].uploader);
        // Revoke access to the file
        access[msg.sender][_fileId] = false;
        // Trigger an event
        emit AccessRevoked(_user, _fileId);
    }

    function isAuthorized(uint _fileId) public view returns (bool) {
        // Check if the user has access to the file
        return access[msg.sender][_fileId];
    }

}