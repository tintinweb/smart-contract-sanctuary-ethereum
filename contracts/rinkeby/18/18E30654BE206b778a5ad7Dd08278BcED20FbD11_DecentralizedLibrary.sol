// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

/// @title A decentralized library
/// @author Team Ace [Blockgames] - Anyanwu Maureen(maura-dev), Johnmicheal(zendus), Philip(Phyf3), Chidera(derajohnson), Pearl(nextrated), JNIC, KingHolyHill(kinglighthill)
/// @notice You can use this to contract store files in a decentralized and distributed system 
/// @dev All function calls are currently implemented without side effects
/// @custom:experimental This contract is a PoC.
contract DecentralizedLibrary { 

    address public owner;

    /// @notice mapping of public files uploaded any user
    mapping (string => FileDetail) public collection; 
    /// @notice an array to keep track of uploads in public uploads
    string[] public keys;

    /// @notice mapping of public files uploaded by current user
    mapping (address => mapping(string => FileDetail)) public myCollection;
    /// @notice mapping to an array to keep track of uploads into user's public uploads
    mapping(address => string[]) private myKeys;

    /// @notice mapping of private files uploaded current user
    mapping (address => mapping(string => FileDetail)) public privateCollection;
    /// @notice mapping to an array to keep track of uploads into private collection mapping
    mapping(address => string[]) private pKey;


    /// @notice mapping of files shared to a current user
    mapping (address => mapping(string => FileDetail)) public sharedCollection;
    /// @notice mapping to an array to keep track of uploads into shared collection mapping
    mapping(address => string[]) private sKey;

    mapping (string => bool) public fileExists;
    mapping (address => mapping(string => bool)) public fileShared; 
   
    /// @notice Structs of all the file details.
    struct FileDetail { 
        string ipfsCID; 
        string fileName; 
        uint timeUploaded; 
        address fileOwner;
    } 


    event FileUploaded(string ipfsCID, string fileName, uint timeUploaded , address fileOwner); 


     
    constructor(){
        owner = msg.sender;
    }
    
    /// @notice Upload files to a public dashboard.
    /// @param  _ipfsCID The CID hash of the file uploaded to ipfs/any decentralised storage
    /// @param  _fileName The file name of the file
    /// @param _uploadType its either 0 for public and 1 for private
    /// @dev    The params are stored on the blockchain on function call, lookups can be done 
    function fileUpload(string memory _ipfsCID, string memory _fileName, uint _uploadType) 
    public { 
       //require(fileExists[_ipfsCID] == false, "File with this CID already exists.");
        require(fileExists[_fileName] == false, "File with this Name already exists, Rename.");

        //initialising our struct with data
        FileDetail memory fileDetails = FileDetail(_ipfsCID, _fileName, block.timestamp, msg.sender); 

        //check uploadType 0 is public, 1 is private
        if (_uploadType == 1) {
            privateCollection[msg.sender][_fileName] = fileDetails;
            pKey[msg.sender].push(_fileName);
        } else {
            collection[_ipfsCID] = fileDetails;
            keys.push(_ipfsCID); 

            myCollection[msg.sender][_fileName] = fileDetails;
            myKeys[msg.sender].push(_fileName);
        }
        
        // set fileExist to true
        fileExists[_fileName] = true;
        fileExists[_ipfsCID] = true;

        emit FileUploaded(_ipfsCID, _fileName, block.timestamp, msg.sender);

    }

   
     /// @notice Returns the total number of files uploaded.
    /// @dev    Returns only a fixed number that's the fixed length of the keys array from the iterable mapping.
    /// @return Length in unsigned integer
    function getSize() external view returns(uint) {
        return keys.length;
    }


    /// @notice Returns details about the last public file uploaded.
    /// @dev    Details returned are the one's stored in the blockchain on upload.
    /// @return ipfsCID of last public upload.
    /// @return File name of the last public upload.
    /// @return Date the public file got uploaded 
    /// @return Address of the public uploader.
    function getLatestPublicUpload() external view 
    returns ( string memory, string memory, uint, address) {
        uint len = keys.length;
        string memory key = keys[len - 1];
        return (
            collection[key].ipfsCID,
            collection[key].fileName,
            collection[key].timeUploaded,
            collection[key].fileOwner        
        );
    }
    


    /// @notice Returns details about all public files uploaded so far.
    /// @dev    Details returned are the one's stored in the blockchain on upload.
    /// @return ipfsCID of all public uploads.
    /// @return File name of all the public uploads.
    /// @return Upload date of all the public uploads.
    /// @return Address of the public uploader.
    function getAllPublicUploads() public view
    returns(string[] memory,string[] memory, uint[] memory, address[] memory) {
        uint len = keys.length;

        string [] memory ids = new string[](len);
        string [] memory names = new string[](len);
        uint [] memory time = new uint[](len);
        address [] memory owners = new address [](len);

        for (uint i = 0; i < keys.length; ++i) {
            string memory key = keys[i];

            ids[i] = collection[key].ipfsCID;
            names[i] = collection[key].fileName;
            time[i] = collection[key].timeUploaded;
            owners[i] = collection[key].fileOwner;
        }

        return(ids, names, time, owners);
    }


     /// @notice Returns details about all public files uploaded by current address so far.
    /// @dev    Details returned are the one's stored in the blockchain on upload.
    /// @return ipfsCID of all current user's public uploads.
    /// @return File name of all the current user's public uploads.
    /// @return Upload date of all the current user's public uploads.
    /// @return Address of the current user's public uploader.
     function getUserPublicUploads() public view 
     returns(string[] memory, string[] memory, uint[] memory, address[] memory) {
        uint len = myKeys[msg.sender].length;
        string [] memory ids = new string[](len);
        string [] memory names = new string[](len);
        uint [] memory time = new uint[](len);
        address [] memory owners = new address [](len);

        for (uint i = 0; i < len; ++i) {
            string memory key = myKeys[msg.sender][i];
            ids[i] = myCollection[msg.sender][key].ipfsCID;
            names[i] = myCollection[msg.sender][key].fileName;
            time[i] = myCollection[msg.sender][key].timeUploaded;
            owners[i] = myCollection[msg.sender][key].fileOwner;
        }
        return(ids, names, time, owners);
    }

   

    
    /*    function getUploadedFileWithCID(string memory _ipfsCID) public view 
    returns (string memory, string memory, string memory, uint, address) {
        require(fileExists[_ipfsCID] == true, "This file probably hasn't been uploaded yet, retry later or reupload");
        return ( 
            _ipfsCID,  
            collection[_ipfsCID].ipfsCID, 
            collection[_ipfsCID].fileName, 
            collection[_ipfsCID].timeUploaded, 
            collection[_ipfsCID].fileOwner,
        ); 
    }
    function getUploadedFilewithName(string memory _fileName) public view returns (string memory, string memory, string memory, string memory, uint, address, bool) {
        require(fileExists[_fileName] == true, "File does not exist");
        return ( 
            _fileName,  
            collection[_fileName].ipfsCID, 
            collection[_fileName].fileName, 
            collection[_fileName].fileType, 
            collection[_fileName].timeUploaded,
            collection[_fileName].fileOwner, 
            collection[_fileName].exist 
        ); 
    } */
    
    

    /// @notice Returns the total number of files uploaded.
    /// @dev    Returns only a fixed number that's the fixed length of the keys array from the iterable mapping.
    /// @return Length in unsigned integer
    function getSizeOfPrivateUploads() external view returns(uint) {
        return pKey[msg.sender].length;
    }


    /// @notice Returns details about the last private file uploaded.
    /// @dev    Details returned are the one's stored in the blockchain on upload.
    /// @return ipfsCID of last private upload.
    /// @return File name of the last private upload.
    /// @return Date the private file got uploaded 
    /// @return Address of the private uploader.
    function getLatestPrivateUpload() external view 
    returns ( string memory, string memory, uint, address) {
        uint len = pKey[msg.sender].length;
        string memory key = pKey[msg.sender][len - 1];
        return (
            privateCollection[msg.sender][key].ipfsCID,
            privateCollection[msg.sender][key].fileName,
            privateCollection[msg.sender][key].timeUploaded,
            privateCollection[msg.sender][key].fileOwner
        );
    }

    /// @notice Returns details about all private files uploaded so far.
    /// @dev    Details returned are the one's stored in the blockchain on upload.
    /// @return ipfsCID of all private uploads.
    /// @return File name of all the private uploads.
    /// @return Address of the private uploader.
    function getAllPrivateUploads() public view
    returns(string[] memory,string[] memory, uint[] memory, address[] memory) {

        uint len = pKey[msg.sender].length;
        string [] memory ids = new string[](len);
        string [] memory names = new string[](len);
        uint [] memory time = new uint[](len);
        address [] memory owners = new address [](len);

        for (uint i = 0; i < len; ++i) {
            string memory key = pKey[msg.sender][i];
            ids[i] = privateCollection[msg.sender][key].ipfsCID;
            names[i] = privateCollection[msg.sender][key].fileName;
            time[i] = privateCollection[msg.sender][key].timeUploaded;
            owners[i] = privateCollection[msg.sender][key].fileOwner;
        }
        return(ids, names, time, owners);
    }

    /// @notice Returns details about a specific file uploaded by a user.
    /// @dev returns string type of user FileDetail struct parameters
    /// @param _fileName Unique name of the file to be fetched
    /// @return _ipfsCID File CID.
    /// @return _filename File name.
    /// @return _timeUploaded Upload date of file
    /// @return _fileOwner Address of file uploader.
    function getOnePrivateFile(string memory _fileName) public view 
    returns (string memory _ipfsCID, string memory _filename, uint _timeUploaded, address _fileOwner) {
        require(fileExists[_fileName] == true, "File does not exist");
        _ipfsCID = privateCollection[msg.sender][_fileName].ipfsCID;
        _filename = privateCollection[msg.sender][_fileName].fileName;
        _timeUploaded = privateCollection[msg.sender][_fileName].timeUploaded;
        _fileOwner = privateCollection[msg.sender][_fileName].fileOwner;
    }

    /// @notice Shares a private file to another user.
    /// @dev Shares a fileDetail struct with another address.
    /// @param _to intended address to receive file.
    /// @param _fileName unique name of file to be shared.
    function sharePrivateFile(address _to, string memory _fileName) external {

        //checks if a file name exists
        require(fileExists[_fileName] == true, "File does not exist");
        
        // make's sure a file hasn't been shared to the same address before
        require(fileShared[_to][_fileName] == false, "File has already been shared to this address");

        (string memory _ipfsCID, string memory _filename,
        uint _timeUploaded, address _fileOwner)  = getOnePrivateFile(_fileName);
        require(_fileOwner == msg.sender, "File share not authorized. Not Owner");
        FileDetail memory fileDetails = FileDetail(_ipfsCID, _filename , _timeUploaded, _fileOwner);
        sharedCollection[_to][_fileName] = fileDetails;
        sKey[_to].push(_fileName);

        //mark a file name as already shared
        fileShared[_to][_fileName] = true;
    }


    /// @notice Returns only the files shared to the current address.
    /// @return _ipfsCID file CID.
    /// @return _filename file name.
    /// @return _timeUploaded upload date of file
    /// @return _fileOwner address of file uploader/sender.
    function getSharedFiles() public view 
    returns (string[] memory,string[] memory, uint[] memory, address[] memory) {
        uint len = sKey[msg.sender].length;
        string [] memory ids = new string[](len);
        string [] memory names = new string[](len);
        uint [] memory time = new uint[](len);
        address [] memory owners = new address [](len);

        for (uint i = 0; i < len; ++i) {
            string memory key = sKey[msg.sender][i];
            ids[i] = sharedCollection[msg.sender][key].ipfsCID;
            names[i] = sharedCollection[msg.sender][key].fileName;
            time[i] = sharedCollection[msg.sender][key].timeUploaded;
            owners[i] = sharedCollection[msg.sender][key].fileOwner;
        }
        return(ids, names, time, owners);
    }
}