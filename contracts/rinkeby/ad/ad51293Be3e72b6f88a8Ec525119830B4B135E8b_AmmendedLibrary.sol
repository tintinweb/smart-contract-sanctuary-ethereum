/**
 *Submitted for verification at Etherscan.io on 2022-07-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract AmmendedLibrary {
    /// @notice Public Variable to track all the files(objects) that has been uploaded to library
    /// @dev Variable is an array of files
    _File[] public _allUploadedFiles;
    /// @notice Public Variable to track the addresses that has uploaded files to Library
    /// @dev Variable is an array of addresses
    address[] public _uploaders;
    /// @notice object file structure to hold al parameters of a file upload
    /// @dev object is useful to display parameters of each file structure
    struct _File {
        string fileName;
        string fileTitle;
        address uploader;
        string ipfsHash;
        string ipfsURL;
        string fileStatus;
        string fileType;
    } //basic template of a library file
    /// @notice Public Variable to track the files(object) uploaded by an address
    /// @dev Variable is an array of files. Each upload generates a file and that file is stored in an array and passed into this variable
    mapping(address => _File[]) public _userUploadedFiles;


    ///events
    event Upload(string message);

    /// @notice Upload a file as a first-time user of the Library
    /// @dev Update the mapping based on the address calling the function with the array of uploaded hashes
    function _upload(
        string memory fileName,
        string memory fileTitle,
        string memory ipfsHash,
        string memory ipfsURL,
        string memory status,
        string memory fileType
    ) public {
        _userUploadedFiles[msg.sender].push(_File(fileName, fileTitle, msg.sender, ipfsHash, ipfsURL, status, fileType));
        _allUploadedFiles.push(_File(fileName, fileTitle, msg.sender, ipfsHash, ipfsURL, status, fileType));

        bool isUploader = _isAnUploader(msg.sender);
        if (isUploader == false) {
            _uploaders.push(msg.sender);
        }

        emit Upload("You have just uploaded your file");
    }

    /// @notice Get a list of all uploaded files from the Library
    /// @dev view function to return an array of files representing the objects of all uploaded files in the Library
    /// @return An array of files, representing the uploaded files of metadata files to IPFS
    function _getListOfAllUploadedFiles() public view returns (_File[] memory) {
        return _allUploadedFiles;
    }

    /// @notice Get a list of uploaded hashes from the Library for a particular address
    /// @dev view function to return an array of strings representing the hashes of uploaded files for a particular address
    /// @param _address The address to check for it's uploaded files
    /// @return An array of strings, representing the uploaded hashes of metadata files to IPFS
    function _getListOfUserUploadedFiles(address _address)
        public
        view
        returns (_File[] memory)
    {
        return _userUploadedFiles[_address];
    }

    /// @notice Check if an address is an existing user of the Library
    /// @dev confirm if address is in the User Array
    /// @param _address The address to check if it's an existing user
    /// @return boolean, whether an address is existing in the Users Array
    function _isAnUploader(address _address) public view returns (bool) {
        for (uint8 s = 0; s < _uploaders.length; s += 1) {
            if (_address == _uploaders[s]) return (true);
        }
        return (false);
    }
}