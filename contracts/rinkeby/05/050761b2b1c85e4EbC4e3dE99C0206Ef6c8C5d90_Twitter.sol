// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Twitter {
    struct Tweet {
        string tweet;
        address creator;
        uint256 timestamp;
        mapping(address => bool) likes;
        uint256 likesCount;
    }
    struct UserInfo {
        address registeredAddress;
        string username;
        mapping(address => address) followers;
        mapping(address => address) following;
        mapping(uint256 => Tweet) tweets;
        uint256 numberOfFollowers;
        uint256 numberOfFollowing;
        uint256 numberOfTweets;
    }
    mapping(address => UserInfo) public users;

    event UserCreated(address);
    event UsernameUpdated(address, string);
    event TweetCreated(address, string, uint256);
    event TweetDeleted(address, uint256);
    event TweetLiked(address, address, uint256, uint256);
    event TweetUnliked(address, address, uint256, uint256);
    constructor() {}

    function registerUser() public {
        require(users[msg.sender].registeredAddress != msg.sender, "Address already in use");
        users[msg.sender].registeredAddress = msg.sender;
        users[msg.sender].username = "";
        users[msg.sender].numberOfFollowers = 0;
        users[msg.sender].numberOfFollowing = 0;
        users[msg.sender].numberOfTweets = 0;
    }

    function editUsername(string memory _username) public {
        users[msg.sender].username = _username;
    }

    function deleteUser() public {
        delete users[msg.sender];
    }

    function getUser(address user) public view returns(string memory){
        return users[user].username;
    }

    function getTweet(address user, uint256 id) public view returns(string memory, uint256){
        return (users[user].tweets[id].tweet, users[user].tweets[id].likesCount);
    }

    function getMyDetails() public view returns(address, string memory, uint256, uint256){
        return (users[msg.sender].registeredAddress, users[msg.sender].username, users[msg.sender].numberOfFollowers,users[msg.sender].numberOfFollowers);
    }

    function tweet(string memory _tweet) public {
        uint256 id = users[msg.sender].numberOfTweets++;
        users[msg.sender].tweets[id].tweet = _tweet;
        users[msg.sender].tweets[id].creator = msg.sender;
    }

    function followUser(address toFollow) public {
        require(msg.sender != toFollow, "You cannot follow yoursel");
        users[toFollow].followers[msg.sender] = msg.sender;
        users[msg.sender].following[toFollow] = toFollow;
        users[msg.sender].numberOfFollowers++;
        users[msg.sender].numberOfFollowing++;
    }

    function unfollowUser(address unfollowAddress) public {
        require(msg.sender != unfollowAddress, "You cannot follow yoursel");
        delete users[msg.sender].following[unfollowAddress];
        delete users[unfollowAddress].followers[msg.sender];
        users[msg.sender].numberOfFollowers--;
        users[msg.sender].numberOfFollowing--;
    }

    function likeTweet(address user, uint256 id) public {
        users[user].tweets[id].likes[msg.sender] = true;
        users[user].tweets[id].likesCount++;
    }

    function unlikeTweet(address user, uint256 id) public {
        delete users[user].tweets[id].likes[msg.sender];
        users[user].tweets[id].likesCount--;
    }
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