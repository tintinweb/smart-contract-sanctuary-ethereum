//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract HashRecorder{

    struct FileInfo{
        bytes32 fileId;
        bytes sha256Hash;
        uint timestamp;
        address  registrant;
    }

    mapping(bytes32 => FileInfo) private fileList;

    uint private fileCount;

    event FileHash(address indexed _from, bytes32 _fileId, bytes indexed _sha256Hash,uint _timestamp);

    //constructor() {}

    function getFileCount() public view returns(uint _fileCount){
        return fileCount;
    }

    function getFileInfoWithFileId(bytes32 fileId)public 
    view returns (bytes32 _fileId, bytes memory _sha256Hash, uint _timestamp, address registrant){
        FileInfo memory fileInfo = fileList[fileId];
        return(fileInfo.fileId, fileInfo.sha256Hash, fileInfo.timestamp, fileInfo.registrant);
    }

    function getFileInfoWithFileHash(string memory fileHash)public
    view returns (bytes32 _fileId, bytes memory _sha256Hash, uint _timestamp, address registrant){
        bytes32 fileId = getFileId(fileHash);
        FileInfo memory fileInfo = fileList[fileId];
        return(fileInfo.fileId, fileInfo.sha256Hash, fileInfo.timestamp, fileInfo.registrant);
    }

    function getFileId(string memory _sha256Hash)public pure returns(bytes32){
        return keccak256(bytes(_sha256Hash));
    }

    function fileExist(bytes32 fileId) public view returns(bool) {
        if(fileList[fileId].registrant == address(0x0)){
            return false;
        }else{
            return true;
        }
    }

    function recordFileHash(string memory sha256Hash, uint timestamp)public returns(bool){
        bytes32 fileId = getFileId(sha256Hash);

        require(fileExist(fileId) == false,"file already exist.");

        fileList[fileId].fileId = fileId;
        fileList[fileId].sha256Hash = bytes(sha256Hash);
        fileList[fileId].timestamp = timestamp;
        fileList[fileId].registrant = msg.sender;

        fileCount++;

        emit FileHash(msg.sender, fileId, bytes(sha256Hash), timestamp);

        return true;
    }
}