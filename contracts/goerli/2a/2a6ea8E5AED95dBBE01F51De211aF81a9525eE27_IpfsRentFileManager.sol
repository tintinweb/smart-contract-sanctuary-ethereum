// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error NotOwner(address attempt, string message);
error FileDoesNotExist(address attempt, string hashFile, string message);
error FileAlreadyExists(address attempt, string hashFile, string message);

contract IpfsRentFileManager {
    //Enums
    enum FileCategory {
        Empty,
        IdCard,
        LiquidationNote,
        SalaryReceipt
    }

    //Structs
    struct File {
        string url;
        string fileName;
        address fileOwner;
        uint256 size;
        FileCategory category;
        string houseId;
    }

    //State Variables
    mapping(string => File) private s_files;

    mapping(string => string) private s_ipfsURL;

    //Events
    event FileUploaded(
        address indexed fileOwner,
        string hashFile,
        uint256 size,
        FileCategory category
    );

    event FileDeleted(address indexed fileOwner, string hashFile);

    event FileAccessed(
        address indexed fileOwner,
        string hashFile,
        address indexed accessor,
        uint256 timestamp
    );

    /**
     * @dev Empty Constructor
     */
    constructor() {}

    /**
     * @dev Enables anyone to upload file metadata
     */
    function uploadFile(
        string memory _hashFile,
        uint256 _size,
        FileCategory _category,
        string memory _ipfsURL,
        string memory _fileName,
        string memory _houseId
    ) external {
        if (s_files[_hashFile].category != FileCategory.Empty) {
            revert FileAlreadyExists(msg.sender, _hashFile, 'A file with this hash already exists');
        }

        File memory fileInformation = File({
            fileName: _fileName,
            url: _ipfsURL,
            fileOwner: msg.sender,
            size: _size,
            category: _category,
            houseId: _houseId
        });

        s_files[_hashFile] = fileInformation;

        s_ipfsURL[_houseId] = _ipfsURL;

        emit FileUploaded(msg.sender, _hashFile, _size, _category);
    }

    /**
     * @dev Enables the owner of a file to delete his file metadata
     */
    function deleteFile(string memory _hashFile, string memory houseId) external {
        if (s_files[_hashFile].category == FileCategory.Empty) {
            revert FileDoesNotExist(msg.sender, _hashFile, 'A file with this hash does not exist');
        }

        if (msg.sender != s_files[_hashFile].fileOwner) {
            revert NotOwner(msg.sender, 'Address is not the owner of the file');
        }

        File memory fileInformation = File({
            fileName: '',
            url: '',
            fileOwner: address(0),
            size: 0,
            category: FileCategory.Empty,
            houseId: ''
        });

        s_files[_hashFile] = fileInformation;

        s_ipfsURL[houseId] = '';

        emit FileDeleted(msg.sender, _hashFile);
    }

    /**
     * @dev Saves in the file metadata who and when accessed a certain file
     */
    function existsFile(string memory _hashFile) internal {
        if (s_files[_hashFile].category == FileCategory.Empty) {
            revert FileDoesNotExist(msg.sender, _hashFile, 'A file with this hash does not exist');
        }

        emit FileAccessed(s_files[_hashFile].fileOwner, _hashFile, msg.sender, block.timestamp);
    }

    function getFileOwner(string memory _hashFile) public view returns (address) {
        if (s_files[_hashFile].category == FileCategory.Empty) {
            revert FileDoesNotExist(msg.sender, _hashFile, 'A file with this hash does not exist');
        }

        return s_files[_hashFile].fileOwner;
    }

    function getFileSize(string memory _hashFile) public view returns (uint256) {
        if (s_files[_hashFile].category == FileCategory.Empty) {
            revert FileDoesNotExist(msg.sender, _hashFile, 'A file with this hash does not exist');
        }
        return s_files[_hashFile].size;
    }

    function getFileCategory(string memory _hashFile) public view returns (uint256) {
        if (s_files[_hashFile].category == FileCategory.Empty) {
            revert FileDoesNotExist(msg.sender, _hashFile, 'A file with this hash does not exist');
        }
        return uint256(s_files[_hashFile].category);
    }

    function getFilesURL(
        string memory _hashFile,
        string memory _houseID
    ) public view returns (string memory) {
        if (s_files[_hashFile].category == FileCategory.Empty) {
            revert FileDoesNotExist(msg.sender, _hashFile, 'A file with this hash does not exist');
        }
        return s_ipfsURL[_houseID];
    }
}