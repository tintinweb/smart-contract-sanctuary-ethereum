//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./utils/BaseController.sol";
import "./interfaces/IContractManager.sol";
import "./interfaces/IController.sol";
import "./interfaces/ITweetStorage.sol";
import "./interfaces/IUserStorage.sol";
import "./interfaces/ICommentStorage.sol";

contract Controller is BaseController, IController {
    ITweetStorage public _tweetStorage;
    IUserStorage public _userStorage;
    ICommentStorage public _commentStorage;

    function setStorageAddrs() external onlyOwner {
        IContractManager _contractManager = IContractManager(managerAddr);
        address _userStorageAddr = _contractManager.storageAddrs(
            bytes32(bytes("UserStorage"))
        );
        address _tweetStorageAddr = _contractManager.storageAddrs(
            bytes32(bytes("TweetStorage"))
        );
        address _commentStorageAddr = _contractManager.storageAddrs(
            bytes32(bytes("CommentStorage"))
        );
        _tweetStorage = ITweetStorage(_tweetStorageAddr);
        _userStorage = IUserStorage(_userStorageAddr);
        _commentStorage = ICommentStorage(_commentStorageAddr);
    }

    function createUser(bytes32 _username, string memory _image_uri)
        public
        returns (uint256)
    {
        return _userStorage.createUser(msg.sender, _username, _image_uri);
    }

    function deleteMyProfileAndAll() external {
        _userStorage.deleteUser(msg.sender);
        _tweetStorage.deleteAllTweetsOfUser(msg.sender);
    }

    function createTweet(string memory _text, string memory _photoUri)
        external
        returns (uint256)
    {
        require(_userStorage._exists(msg.sender), "User does not exist");
        return _tweetStorage.createTweet(msg.sender, _text, _photoUri);
    }

    function deleteTweet(uint256 _tweetId) external {
        _tweetStorage.deleteTweet(msg.sender, _tweetId);
        _commentStorage.deleteAllCommentsOfTweet(msg.sender, _tweetId);
    }

    function createComment(
        uint256 _tweetId,
        string memory _text,
        string memory _photoUri
    ) external returns (uint256) {
        require(_tweetStorage._exists(_tweetId), "Tweet does not exist");
        return
            _commentStorage.createComment(
                msg.sender,
                _tweetId,
                _text,
                _photoUri
            );
    }

    function deleteComment(uint256 _commentId) external {
        _commentStorage.deleteComment(msg.sender, _commentId);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IBaseController.sol";

contract BaseController is Ownable, IBaseController {
    // The Contract Manager's address
    address public managerAddr;

    function setManagerAddr(address _managerAddr) public onlyOwner {
        managerAddr = _managerAddr;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IContractManager {
    function storageAddrs(bytes32 _name) external view returns (address);

    function setAddress(bytes32 _name, address _address) external;

    function deleteAddress(bytes32 _name) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IController {
    function setStorageAddrs() external;

    function createUser(bytes32 _username, string memory _image_uri)
        external
        returns (uint256);

    function deleteMyProfileAndAll() external;

    function createTweet(string memory _text, string memory _photoUri)
        external
        returns (uint256);

    function deleteTweet(uint256 _tweetId) external;

    function createComment(
        uint256 _tweetId,
        string memory _text,
        string memory _photoUri
    ) external returns (uint256);

    function deleteComment(uint256 _commentId) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ITweetStorage {
    function tweets(uint256 _tweetId)
        external
        view
        returns (
            address authorAddr,
            uint256 tweetId,
            string memory text,
            uint256 timestamp,
            string memory photo_uri
        );

    function _exists(uint256 _tweetId) external view returns (bool);

    function authorOf(uint256 _tweetId) external view returns (address);

    function tweetCountOf(address _authorAddr) external view returns (uint256);

    function tweetsOf(address _author) external view returns (uint256[] memory);

    function createTweet(
        address _userAddr,
        string memory _text,
        string memory _photoUri
    ) external returns (uint256);

    function deleteTweet(address _from, uint256 _tweetId) external;

    function deleteAllTweetsOfUser(address _deletedUserAddr) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IUserStorage {
    function profiles(address _userAddr)
        external
        view
        returns (
            uint256 userId,
            address userAddr,
            bytes32 username,
            string memory image_uri,
            bool exists
        );

    function _exists(address) external view returns (bool);

    function createUser(
        address _userAddr,
        bytes32 _username,
        string memory _image_uri
    ) external returns (uint256);

    function deleteUser(address) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ICommentStorage {
    function comments(uint256 _commentId)
        external
        view
        returns (
            address authorAddr,
            uint256 tweetId,
            uint256 commentId,
            string memory text,
            uint256 timestamp,
            string memory photoUri
        );

    function _exists(uint256 _commentId) external view returns (bool);

    function authorOf(uint256 _commentId) external view returns (address);

    function commentsOfTweet(uint256 _tweetId)
        external
        view
        returns (uint256[] memory);

    function commentsOfAuthor(address _authorAddr)
        external
        view
        returns (uint256[] memory);

    function commentCountOfAuthor(address _authorAddr)
        external
        view
        returns (uint256);

    function createComment(
        address _authorAddr,
        uint256 _tweetId,
        string memory _text,
        string memory _photoUri
    ) external returns (uint256);

    function deleteComment(address _from, uint256 _commentId)
        external
        returns (bool);

    function deleteAllCommentsOfTweet(address _from, uint256 _tweetId)
        external
        returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBaseController {
    function managerAddr() external view returns (address);

    function setManagerAddr(address _managerAddr) external;
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