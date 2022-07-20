/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: ShareFile.sol


pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;


contract ShareFile is Ownable {
    struct File {
        address owner;
        address[] sharedUsers;
    }

    // modifier onlyFileOwner(string calldata fileId) {
    //     require(msg.sender == files[fileId].owner);
    //     _;
    // }

    address[] users;
    string[] fileIds;
    mapping(string => bool) isFileExist;
    mapping(string => File) files;

    function uploadFile(address owner, string memory fileId) public onlyOwner {
        if (!isFileExist[fileId]) {
            fileIds.push(fileId);
            files[fileId] = File(owner, new address[](0));
            isFileExist[fileId] = true;
        }
    }

    function shareFile(string calldata fileId, address otherUser)  public onlyOwner {
        if (!checkPer(fileId, otherUser)) {
            files[fileId].sharedUsers.push(otherUser);
        }
    }

    function checkPer(string calldata fileId, address user)
        public
        view
        returns (bool)
    {
        if (files[fileId].owner == user) return true;

        for (uint256 i = 0; i < files[fileId].sharedUsers.length; i++) {
            if (files[fileId].sharedUsers[i] == user) {
                return true;
            }
        }
        return false;
    }

    function getSharedUsers(string calldata fileId)
        public
        view
        returns (address[] memory)
    {
        return files[fileId].sharedUsers;
    }

    function getIndex(address[] memory arr, address user)
        public
        pure
        returns (uint256)
    {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == user) {
                return i + 1;
            }
        }
        return 0;
    }

    function removePer(string calldata fileId, address otherUser) public onlyOwner
        // public onlyFileOwner(fileId)
        returns (bool success)
    {
        if (otherUser == files[fileId].owner) return false;

        uint256 index = 0;
        while (index <= files[fileId].sharedUsers.length) {
            if (otherUser == files[fileId].sharedUsers[index]) {
                break;
            }
            index++;
        }
        for (uint256 i = index; i < files[fileId].sharedUsers.length - 1; i++) {
            files[fileId].sharedUsers[i] = files[fileId].sharedUsers[i + 1];
        }
        files[fileId].sharedUsers.pop();

        return true;
    }

    function getAllFiles() public view returns (string[] memory) {
        return fileIds;
    }

    function getAllFilesOfOwner(address user)
        public
        view
        returns (string[] memory)
    {
        string[] memory filesOfUser = new string[](fileIds.length);
        uint256 j;
        for (uint256 i = 0; i < fileIds.length; i++) {
            if (files[fileIds[i]].owner == user) {
                filesOfUser[j] = fileIds[i];
                j++;
            }
        }
        return filesOfUser;
    }

    function getOwnerOfFile(string memory fileId)
        public
        view
        returns (address)
    {
        return files[fileId].owner;
    }

    function getFilesSharedMe(address user)
        public
        view
        returns (string[] memory)
    {
        string[] memory filesOfUser = new string[](fileIds.length);
        uint256 j;
        for (uint256 i = 0; i < fileIds.length; i++) {
            if (getIndex(files[fileIds[i]].sharedUsers, user) != 0) {
                filesOfUser[j] = fileIds[i];
                j++;
            }
        }
        return filesOfUser;
    }
    function removeFile(string calldata fileId) public onlyOwner
        // public onlyFileOwner(fileId)
        returns (bool success)
    {
        if (!isFileExist[fileId]) return false;
        uint256 index = 0;
        while (index <= files[fileId].sharedUsers.length) {
            if (
                keccak256(abi.encodePacked(fileId)) ==
                keccak256(abi.encodePacked(fileIds[index]))
            ) {
                break;
            }
            index++;
        }

        for (uint256 i = index; i < fileIds.length - 1; i++) {
            fileIds[i] = fileIds[i + 1];
        }
        fileIds.pop();
        isFileExist[fileId] = false;

        return true;
    }
}

//contract addr: 0x588bEF2f0778733b5086D7E1bf4Bb1441e0aC1f1