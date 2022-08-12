pragma solidity ^0.8.0;

contract DStorage {

    uint public fileCount = 0;
    mapping(uint => File) public files;

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

    function uploadFile(
        string memory _fileHash,
        uint _fileSize,
        string memory _fileType,
        string memory _fileName,
        string memory _fileDescription
    ) public {

        require(bytes(_fileHash).length > 0, "DStorage: empty file hash");
        require(bytes(_fileType).length > 0, "DStorage: empty file type");
        require(bytes(_fileDescription).length > 0, "DStorage: empty file description");
        require(bytes(_fileName).length > 0, "DStorage: empty file name");
        require(msg.sender != address(0), "DStorage: sender is zero address");
        require(_fileSize > 0, "DStorage: file size is zero");

        // Increment file id
        fileCount ++;

        // Add File to the contract
        files[fileCount] = File(
            fileCount, _fileHash, _fileSize, _fileType, _fileName, _fileDescription, block.timestamp, msg.sender
        );

        // Trigger an event
        emit FileUploaded(
            fileCount, _fileHash, _fileSize, _fileType, _fileName, _fileDescription, block.timestamp, msg.sender
        );
    }

}