// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
/** 
 * @title ImageRegister
 * @author MaheswaranKR
 * @notice This contract represents a registry of image ownership. 
 * Due to storage limitations, images are stored on IPFS.  
 * The IPFS hash along with metadata are stored onchain.
*/

contract ImageRegister is Ownable {

    /** 
    * @title Represents a single image which is owned by someone. 
    */
    struct Image {
        string ipfsHash;        // IPFS hash
        string title;           // Image title
        uint256 uploadedOn;     // Uploaded timestamp
    }

    // Maps owner to their images
    mapping (address => Image[]) public ownerToImages;

    string  hash = "https://ipfs.io/ipfs/";

    // Used by Circuit Breaker pattern to switch contract on / off
    bool private stopped = false;


    /**
    * @dev Indicates that a user has uploaded a new image
    * @param _owner The owner of the image
    */
    event LogImageUploaded(
        address indexed _owner, 
        string _ipfsHash,
        uint256 timestamp
    );

    /**
    * @dev Indicates that the owner has performed an emergency stop
    * @param _owner The owner of the image
    * @param _stop Indicates whether to stop or resume
    */
    event LogEmergencyStop(
        address indexed _owner, 
        bool _stop
    );

    /**
    * @dev Prevents execution in the case of an emergency
    */
    modifier stopInEmergency { 
        require(!stopped); 
        _;
    }

    /**  
    * @dev This function is called for all messages sent to
    * this contract (there is no other function).
    * Sending Ether to this contract will cause an exception,
    * because the fallback function does not have the `payable`
    * modifier.
    */
    receive() external payable{}

    /** 
        * @notice associate an image entry with the owner i.e. sender address
        * @dev Controlled by circuit breaker
        * @param _ipfsHash The IPFS hash
        * @param _title The image title
    */
    
    function uploadImage(
        string memory _ipfsHash, 
        string memory _title
    ) public stopInEmergency returns (bool _success) {
            
        require(bytes(_ipfsHash).length == 46);
        require(bytes(_title).length > 0 && bytes(_title).length <= 256);
        uint256 uploadedOn = block.timestamp;
        Image memory image = Image(
            _ipfsHash,
            _title,
            uploadedOn
        );

        ownerToImages[msg.sender].push(image);

        emit LogImageUploaded(
            msg.sender,
            _ipfsHash,
            uploadedOn
        );

        _success = true;
    }

    /** 
    * @notice Returns the number of images associated with the given address
    * @dev Controlled by circuit breaker
    * @param _owner The owner address
    * @return The number of images associated with a given address
    */
    function getImageCount(address _owner) 
        public view 
        stopInEmergency 
        returns (uint256) 
    {
        require(_owner != address(0x0));
        return ownerToImages[_owner].length;
    }


    /** 
    * @notice Returns the image at index in the ownership array
    * @dev Controlled by circuit breaker
    * @param _owner The owner address
    * @param _index The index of the image to return
    * @return _ipfsHash The IPFS hash
    * @return _title The image title
    * @return _uploadedOn The uploaded timestamp
    */ 
    function getImage(address _owner, uint8 _index) 
        public stopInEmergency view returns (
        string memory _ipfsHash, 
        string memory _title,
        uint256 _uploadedOn
    ) {

        require(_owner != address(0x0),"Invalid Address");
        require(_index >= 0 && _index <= 2**8 - 1);
        require(ownerToImages[_owner].length > 0);

        Image storage image = ownerToImages[_owner][_index];
        
        return (
            image.ipfsHash, 
            image.title,
            image.uploadedOn
        );
    }

    /**
    * @notice Pause the contract. 
    * It stops execution if certain conditions are met and can be useful 
    * when new errors are discovered. 
    * @param _stop Switch the circuit breaker on or off
    */
    function emergencyStop(bool _stop) public onlyOwner {
        stopped = _stop;
        emit LogEmergencyStop(_msgSender(),_stop);
    }

    function ImageViewer(string memory _IPFS) public view returns (string memory) {
        return string.concat(hash,_IPFS);
    }
}