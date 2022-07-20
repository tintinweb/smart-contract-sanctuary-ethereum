/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract DistributedFileSharingDapp {
    string public contractName = "Distributed File Sharing";

    mapping(address => uint256) internal totalFilesOf;

    mapping(address => mapping(uint256 => File)) internal fileOf;

    struct File {
        uint256 fileId;
        string fileHash;
        uint256 fileSize;
        string fileType;
        string fileName;
        string fileDes;
        uint256 uploadTime;
        address uploader;
    }

    event FileUploadedEvent(string action, address uploader);

    function getTotalFileCount() public view returns (uint256) {
        return totalFilesOf[msg.sender];
    }

    function getFileOf(uint256 _fileId) public view returns (File memory) {
        return fileOf[msg.sender][_fileId];
    }

    //start =>  upload- delete-edit 
    function uploadFile(
        string memory _fileHash,
        uint256 _fileSize,
        string memory _fileType,
        string memory _fileName,
        string memory _fileDescription
    ) public {
        require(
            bytes(_fileHash).length > 0 &&
                bytes(_fileType).length > 0 &&
                bytes(_fileDescription).length > 0 &&
                bytes(_fileName).length > 0 &&
                msg.sender != address(0) &&
                _fileSize > 0
        );

        totalFilesOf[msg.sender]++;

        fileOf[msg.sender][totalFilesOf[msg.sender]] = File(
            totalFilesOf[msg.sender],
            _fileHash,
            _fileSize,
            _fileType,
            _fileName,
            _fileDescription,
            block.timestamp,
            msg.sender
        );

        emit FileUploadedEvent("File Uploaded", msg.sender);
    }

    function deleteFile(uint256 _id) public {
        fileOf[msg.sender][_id].fileName = "0deleted_";
    }
}