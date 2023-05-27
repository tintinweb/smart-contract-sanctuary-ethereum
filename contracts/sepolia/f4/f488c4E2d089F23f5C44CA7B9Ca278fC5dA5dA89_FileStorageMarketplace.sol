// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title FileStorageMarketplace
/// @author Ibrahim Almutairi, Naif Alanazi
/// @dev All function calls are currently implemented without side effects
/// @custom:experimental This is a production ready contract.
/// @notice The FileStorageMarketplace contract is a decentralized marketplace where users can upload, share, unshare, buy and sell files to other users. The contract stores each uploaded file as a struct containing details such as the file name, description, owner's address, address of a user to whom a file is shared. The contract includes functions for uploading files, sharing files, setting files for sale, buying files, and getting files by ID. The contract also emits events for file uploads, deletions, sharing, setting for sale, and sales.

contract FileStorageMarketplace {
    // ===========================================
    //    State Variable
    // ===========================================

    address public contractOwner; // address of contract deployer/owner
    uint256 public fileCount; //  number of files uploaded to the marketplace.
    bool private reentrancyLock = false; // lock to track if the buy function is currently executing

    // ===========================================
    // Struct
    // ===========================================

    struct File {
        uint256 fileId; // unique identifier of the file.
        address owner; // address of the user who owns the file.
        string name; // name of the file.
        string description; // description of the file.
        address sharedWith; // address of user to whom a file is shared
        bool isForSale; // whether the file is for sale or not.
        uint256 price; // the price of the file in Wei.
        string hash; // the hash of the file.
    }

    // ===========================================
    // Mapping
    // ===========================================

    mapping(uint256 => File) public files; //  a mapping of file IDs to File structs

    // ===========================================
    // Events
    // ===========================================

    event FileUploaded(
        address indexed owner,
        uint256 indexed fileId,
        string name,
        string description,
        address sharedWith,
        bool isForSale,
        uint256 price,
        string hash
    );
    event FileDeleted(address indexed owner, uint256 indexed fileId);
    event FileShared(
        address indexed owner,
        uint256 indexed fileId,
        address indexed sharedWith
    );
    event FileUnshared(address indexed owner, uint256 indexed fileId);
    event FileForSale(
        address indexed owner,
        uint256 indexed fileId,
        uint256 price
    );
    event FileSold(
        address indexed buyer,
        address indexed seller,
        uint256 indexed fileId
    );

    // ===========================================
    // Modifier
    // ===========================================

    /**
     * @dev Throws if called by any account other than the file owner.
     */
    modifier onlyFileOwner(uint256 _fileId) {
        require(
            files[_fileId].owner == msg.sender,
            "Only the owner of the file can perform this action."
        );
        _;
    }

    /**
     * @dev Throws if fileId is invalid
     */
    modifier validFileId(uint256 _fileId) {
        require(_fileId > 0 && _fileId <= fileCount, "Invalid file ID.");
        _;
    }

    // ===========================================
    // Constructor
    // ===========================================

    constructor() {
        contractOwner = msg.sender;
    }

    // ===========================================
    // Functions
    // ===========================================

    /**
     * @dev Uploads a file to the marketplace.
     * @param _name The name of the file.
     * @param _description The description of the file.
     * @param _hash The hash of the file.
     * @return True if the file was uploaded successfully.
     */
    function uploadFile(
        string memory _name,
        string memory _description,
        string memory _hash
    ) public returns (bool) {
        require(bytes(_name).length > 0, "File name cannot be empty.");
        require(
            bytes(_description).length > 0,
            "File description cannot be empty."
        );
        require(bytes(_hash).length > 0, "File hash cannot be empty.");

        fileCount++;

        files[fileCount] = File({
            fileId: fileCount,
            owner: msg.sender,
            name: _name,
            description: _description,
            sharedWith: address(0),
            isForSale: false,
            price: 0,
            hash: _hash
        });

        emit FileUploaded(
            msg.sender,
            fileCount,
            _name,
            _description,
            address(0),
            false,
            0,
            _hash
        );

        return true;
    }

    /**
     * @dev Marks a file as shared with a specific user.
     * @param _fileId The ID of the file to be shared.
     * @param _sharedWith The address of the user with whom the file is being shared.
     * @return True if the file was marked as shared successfully.
     */
    function shareFile(
        uint256 _fileId,
        address _sharedWith
    ) public onlyFileOwner(_fileId) validFileId(_fileId) returns (bool) {
        require(_sharedWith != address(0), "Invalid shared address");
        require(
            files[_fileId].sharedWith == address(0),
            "File is already shared"
        );
        files[_fileId].sharedWith = _sharedWith;
        emit FileShared(msg.sender, _fileId, _sharedWith);
        return true;
    }

    /**
     * @dev Unshares a file that was previously shared with a specific user.
     * @param _fileId The ID of the file to be unshared.
     * @return True if the file was unshared successfully.
     */
    function unshareFile(
        uint256 _fileId
    ) public onlyFileOwner(_fileId) validFileId(_fileId) returns (bool) {
        require(
            files[_fileId].sharedWith != address(0),
            "File is not shared with anyone"
        );
        files[_fileId].sharedWith = address(0);
        emit FileUnshared(msg.sender, _fileId);
        return true;
    }

    /**
     * @dev Marks a file as for sale with the specified price.
     * @param _fileId The ID of the file to be marked as for sale.
     * @param _price The price of the file.
     * @return True if the file price was set successfully.
     */
    function setFileForSale(
        uint256 _fileId,
        uint256 _price
    ) public onlyFileOwner(_fileId) validFileId(_fileId) returns (bool) {
        require(!files[_fileId].isForSale, "File is already for sale");
        require(_price > 0 ether, "Price must be greater than 0 ether");
        files[_fileId].isForSale = true;
        files[_fileId].price = _price;
        emit FileForSale(msg.sender, _fileId, _price);
        return true;
    }

    /**
     * @dev Allows a user to purchase a file that is for sale.
     * @param _fileId The ID of the file to be purchased.
     * @return True if the file was purchased successfully.
     */
    function buyFile(
        uint256 _fileId
    ) public payable validFileId(_fileId) returns (bool) {
        // Prevent reentrancy attacks
        require(!reentrancyLock, "Reentrant call");
        reentrancyLock = true;

        require(files[_fileId].isForSale, "File is not for sale");
        require(msg.value == files[_fileId].price, "Incorrect payment amount");

        address payable seller = payable(files[_fileId].owner);
        files[_fileId].owner = msg.sender;
        files[_fileId].sharedWith = address(0);
        files[_fileId].isForSale = false;
        files[_fileId].price = 0;

        (bool success, ) = seller.call{value: msg.value}("");
        require(success, "Payment transfer failed");

        emit FileSold(msg.sender, seller, _fileId);

        // Unlock the function
        reentrancyLock = false;

        return true;
    }

    /**
     * @dev Deletes a file from the marketplace.
     * @param _fileId The ID of the file to delete.
     * @return True if the file was deleted successfully.
     * @notice The caller must be the owner of the file.
     * @notice Throws an error if the file ID is invalid or the caller is not the owner of the file.
     */
    function deleteFile(
        uint256 _fileId
    ) public onlyFileOwner(_fileId) validFileId(_fileId) returns (bool) {
        delete files[_fileId];
        emit FileDeleted(msg.sender, _fileId);
        return true;
    }

    fallback() external payable {}

    receive() external payable {}

    // ===========================================
    // Getter Functions
    // ===========================================

    /**
     * @dev Returns the address of contract owner.
     */
    function getContractOwnerAddress() public view returns (address) {
        return contractOwner;
    }

    /**
     * @dev Returns the total number of files uploaded to the marketplace.
     */
    function getTotalFileCount() public view returns (uint256) {
        return fileCount;
    }

    /**
     * @dev Gets all files uploaded by the caller(me) that are not for sale and not shared with anyone.
     * @return An array of File structs representing all files uploaded by the caller(me) that are not for sale and not shared with anyone.
     */

    function getAllMyUploadedFiles() public view returns (File[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i <= fileCount; i++) {
            if (
                files[i].owner == msg.sender &&
                !files[i].isForSale &&
                files[i].sharedWith == address(0)
            ) {
                count++;
            }
        }
        require(count > 0, "You haven't uploaded any files yet.");

        File[] memory fileArr = new File[](count);
        count = 0;
        for (uint256 i = 1; i <= fileCount; i++) {
            if (
                files[i].owner == msg.sender &&
                !files[i].isForSale &&
                files[i].sharedWith == address(0)
            ) {
                fileArr[count] = files[i];
                count++;
            }
        }
        return fileArr;
    }

    /**
     * @dev Gets all files that are currently for sale in the marketplace
     * @return Returns an array of file structs that are currently for sale in the marketplace.
     */
    function getFilesForSale() public view returns (File[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i <= fileCount; i++) {
            if (files[i].isForSale) {
                count++;
            }
        }
        File[] memory filesForSale = new File[](count);
        uint256 currentIndex = 0;
        for (uint256 i = 1; i <= fileCount; i++) {
            if (files[i].isForSale) {
                filesForSale[currentIndex] = files[i];
                currentIndex++;
            }
        }
        return filesForSale;
    }

    /**
     * @dev Returns an array of file structs that the caller(me) holds and are currently shared.
     */
    function getAllMySharedFiles() public view returns (File[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i <= fileCount; i++) {
            if (
                files[i].owner == msg.sender &&
                files[i].sharedWith != address(0)
            ) {
                count++;
            }
        }
        File[] memory mySharedFiles = new File[](count);
        uint256 currentIndex = 0;
        for (uint256 i = 1; i <= fileCount; i++) {
            if (
                files[i].owner == msg.sender &&
                files[i].sharedWith != address(0)
            ) {
                mySharedFiles[currentIndex] = files[i];
                currentIndex++;
            }
        }
        return mySharedFiles;
    }

    /**
     * @dev Returns an array of file structs that the caller(me) holds and are currently unshared.
     */
    function getAllMyUnSharedFiles() public view returns (File[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i <= fileCount; i++) {
            if (
                files[i].owner == msg.sender &&
                files[i].sharedWith == address(0)
            ) {
                count++;
            }
        }
        File[] memory myUnSharedFiles = new File[](count);
        uint256 currentIndex = 0;
        for (uint256 i = 1; i <= fileCount; i++) {
            if (
                files[i].owner == msg.sender &&
                files[i].sharedWith == address(0)
            ) {
                myUnSharedFiles[currentIndex] = files[i];
                currentIndex++;
            }
        }
        return myUnSharedFiles;
    }

    /**
     * @dev Returns an array of file structs that others users shared with the caller(me) .
     */
    function getAllMyReceivedFiles() public view returns (File[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i <= fileCount; i++) {
            if (files[i].sharedWith == msg.sender) {
                count++;
            }
        }
        File[] memory myReceivedFiles = new File[](count);
        uint256 currentIndex = 0;
        for (uint256 i = 1; i <= fileCount; i++) {
            if (files[i].sharedWith == msg.sender) {
                myReceivedFiles[currentIndex] = files[i];
                currentIndex++;
            }
        }
        return myReceivedFiles;
    }
}