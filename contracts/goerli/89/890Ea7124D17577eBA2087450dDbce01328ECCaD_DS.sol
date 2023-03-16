/**
 *Submitted for verification at Etherscan.io on 2023-03-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract DS is Context, Ownable {
    
    // File chunk structure, used inside the File structure.
    struct FileChunk{
        string chunkHash;
        string nodeId;
    }
    // File metadata structure.
    struct File{
        address owner;
 		string fileName;
        uint256 fileSize;
        string rootHash;
        uint256 fileChunkCount;
        FileChunk[] fileChunks;
    }
    
    // Mapping for file owner to all its files. 
    mapping(address => string[]) private _fileMapping;
    // Mapping the root hash of a file to its metadata.
    mapping(string => File) private _fileList;

    /**
     * Modifier to determine if the address is the file owner.
     */
    modifier isFileOwner(string memory _rootHash) {
        require(_fileList[_rootHash].owner == _msgSender(), "You don't have access to this file");
        _;
    }

    /*
     * Add new file and associate it with the owner via mapping (everyone can execute this function).
     */
    function addFile(string memory _fileName, uint256 _fileSize, string memory _rootHash, FileChunk[] memory _fileChunks) public returns(bool) {
        _fileList[_rootHash].owner = _msgSender();
        _fileList[_rootHash].fileName = _fileName;
        _fileList[_rootHash].fileSize = _fileSize;
        _fileList[_rootHash].rootHash = _rootHash;
        _fileList[_rootHash].fileChunkCount = _fileChunks.length;
        for (uint i=0; i<_fileChunks.length; i++){
            _fileList[_rootHash].fileChunks.push(_fileChunks[i]);
        }
        _fileMapping[_msgSender()].push(_rootHash);
        return true;
    }

    /*
     * Retrieve information of all files owned by this address and return. 
     */
    function listFiles() public view returns(File[] memory) {
        File memory file;
        File[] memory files = new File[](_fileMapping[_msgSender()].length);
        for (uint i=0; i<_fileMapping[_msgSender()].length; i++) {
            file = _fileList[_fileMapping[_msgSender()][i]];
            files[i] = file;
        }
        return files;
    }

    /*
     * Retrive single file information from owner's file list. (only file owner is allowed to execute this function).
     */
    function getFile(string memory _rootHash) public view isFileOwner(_rootHash) returns(File memory) {
        return _fileList[_rootHash];
    }

    function removeFile(string memory _rootHash) public isFileOwner(_rootHash) returns(bool) {
        for (uint i = 0; i < _fileMapping[_msgSender()].length; i++) {
            bytes32 storageHash = keccak256(abi.encodePacked(_fileMapping[_msgSender()][i]));
            bytes32 memoryHash = keccak256(abi.encodePacked(_rootHash));
            if (storageHash == memoryHash) {
                deleteFileMappingByIndex(i);
                break;
            }
        }
        delete _fileList[_rootHash];
        return true;
    }

    function checkFileMapping() public view returns (string[] memory) {
        return _fileMapping[_msgSender()];
    }

    function checkFileList(string memory _rootHash) public view returns (File memory) {
        return _fileList[_rootHash];
    }

    /*
     * Util function to delete a value at 'index' from an array.
     */
    function deleteFileMappingByIndex(uint index) private {
        require(index < _fileMapping[_msgSender()].length, "Index out of bounds");
        
        for (uint i = index; i < _fileMapping[_msgSender()].length-1; i++) {
            _fileMapping[_msgSender()][i] = _fileMapping[_msgSender()][i+1];
        }
        
        _fileMapping[_msgSender()].pop();
    }

    // a set of possible porotocol type.
    enum protocol{
        TCP,
        UDP,
        OTHER
    }

    // Node information structure.
    struct Node{
        string nodeId;
        string ipAddress;
        string netAddress;
        protocol protocol;
        uint256 port;
        address owner;
    }

    // Mapping for node owner to all its nodes.
    mapping(address => string[]) private _nodeMapping;
    // Mapping the node ID to its information.
    mapping(string => Node) private _nodeList;

    /**
     * Modifier to determine if the address is the node owner.
     */
    modifier isNodeOwner(string memory _nodeId) {
        require(_nodeList[_nodeId].owner == _msgSender(), "You don't have access to this file");
        _;
    }

    /*
     * Add new file and associate it with the owner via mapping (everyone can execute this function).
     */
    function addNode(string memory _nodeId, string memory _ipAddress, string memory _netAddress, protocol _protocol, uint256 _port) public returns(bool) {
        _nodeList[_nodeId].owner = _msgSender();
        _nodeList[_nodeId].nodeId = _nodeId;
        _nodeList[_nodeId].ipAddress = _ipAddress;
        _nodeList[_nodeId].netAddress = _netAddress;
        _nodeList[_nodeId].protocol = _protocol;
        _nodeList[_nodeId].port = _port;
        _nodeMapping[_msgSender()].push(_nodeId);
        return true;
    }

    /*
     * Retrieve information of all files owned by this address and return. 
     */
    function listNodes() public view returns(Node[] memory) {
        Node memory node;
        Node[] memory nodes = new Node[](_nodeMapping[_msgSender()].length);
        for (uint i=0; i<_nodeMapping[_msgSender()].length; i++) {
            node = _nodeList[_nodeMapping[_msgSender()][i]];
            nodes[i] = node;
        }
        return nodes;
    }

    /*
     * Retrive single file information from owner's file list. (only file owner is allowed to execute this function).
     */
    function getNode(string memory _nodeId) public view isNodeOwner(_nodeId) returns(Node memory) {
        return _nodeList[_nodeId];
    }

    function removeNode(string memory _nodeId) public isNodeOwner(_nodeId) returns(bool) {
        for (uint i = 0; i < _nodeMapping[_msgSender()].length; i++) {
            bytes32 storageHash = keccak256(abi.encodePacked(_nodeMapping[_msgSender()][i]));
            bytes32 memoryHash = keccak256(abi.encodePacked(_nodeId));
            if (storageHash == memoryHash) {
                deleteNodeMappingByIndex(i);
                break;
            }
        }
        delete _nodeList[_nodeId];
        return true;
    }

    function checkNodeMapping() public view returns (string[] memory) {
        return _nodeMapping[_msgSender()];
    }

    function checkNodeList(string memory _nodeId) public view returns (Node memory) {
        return _nodeList[_nodeId];
    }

    /*
     * Util function to delete a value at 'index' from an array.
     */
    function deleteNodeMappingByIndex(uint index) private {
        require(index < _nodeMapping[_msgSender()].length, "Index out of bounds");
        
        for (uint i = index; i < _nodeMapping[_msgSender()].length-1; i++) {
            _nodeMapping[_msgSender()][i] = _nodeMapping[_msgSender()][i+1];
        }
        
        _nodeMapping[_msgSender()].pop();
    }
}