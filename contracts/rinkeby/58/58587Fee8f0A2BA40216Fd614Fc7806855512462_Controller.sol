//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./utils/BaseController.sol";
import "./ContractManager.sol";
import "./TweetStorage.sol";
import "./UserStorage.sol";
import "./CommentStorage.sol";

contract Controller is BaseController {
    TweetStorage _tweetStorage;
    UserStorage _userStorage;
    CommentStorage _commentStorage;

    function initialize() public onlyOwner {
        ContractManager _manager = ContractManager(managerAddr);
        address _userStorageAddr = _manager.getAddress("UserStorage");
        address _tweetStorageAddr = _manager.getAddress("TweetStorage");
        address _commentStorageAddr = _manager.getAddress("CommentStorage");
        _tweetStorage = TweetStorage(_tweetStorageAddr);
        _userStorage = UserStorage(_userStorageAddr);
        _commentStorage = CommentStorage(_commentStorageAddr);
    }

    function createUser(bytes32 _username, string memory _image_uri)
        public
        returns (uint256)
    {
        return _userStorage.createUser(msg.sender, _username, _image_uri);
    }

    function deleteMyProfileAndAll() public {
        _userStorage.deleteUser(msg.sender);
        _tweetStorage.deleteAllTweetsOfUser(msg.sender);
    }

    function createTweet(string memory _text, string memory _photoUri)
        public
        returns (uint256)
    {
        require(_userStorage._exists(msg.sender), "User does not exist");
        return _tweetStorage.createTweet(msg.sender, _text, _photoUri);
    }

    function deleteTweet(uint256 _tweetId) public {
        _tweetStorage.deleteTweet(msg.sender, _tweetId);
        _commentStorage.deleteAllCommentsOfTweet(msg.sender, _tweetId);
    }

    function createComment(
        uint256 _tweetId,
        string memory _text,
        string memory _photoUri
    ) public returns (uint256) {
        require(_tweetStorage._exists(_tweetId), "Tweet does not exist");
        return
            _commentStorage.createComment(
                msg.sender,
                _tweetId,
                _text,
                _photoUri
            );
    }

    function deleteComment(uint256 _commentId) public {
        _commentStorage.deleteComment(msg.sender, _commentId);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BaseController is Ownable {
    // The Contract Manager's address
    address managerAddr;

    function setManagerAddr(address _managerAddr) public onlyOwner {
        managerAddr = _managerAddr;
    }

    function getManagerAddr() public view onlyOwner returns (address) {
        return managerAddr;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ContractManager is Ownable {
    mapping(bytes32 => address) addresses;

    function setAddress(bytes32 _name, address _address) public onlyOwner {
        addresses[_name] = _address;
    }

    function getAddress(bytes32 _name) public view returns (address) {
        return addresses[_name];
    }

    function deleteAddress(bytes32 _name) public onlyOwner {
        addresses[_name] = address(0);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./utils/BaseStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract TweetStorage is BaseStorage {
    event TweetCreated(
        address indexed _author,
        uint256 _tweetId,
        uint256 _timestamp
    );
    event TweetDeleted(
        address indexed _author,
        uint256 _tweetId,
        uint256 _timestamp
    );

    using Counters for Counters.Counter;
    Counters.Counter private _tweetCount;
    // Mapping from author to list of owned tweetIds
    mapping(address => uint256[]) public _ownedTweets;

    // Mapping from tweetId to index of the author's tweets list
    mapping(uint256 => uint256) private _ownedTweetsIndex;

    // Array with all tweetIds
    uint256[] private _allTweets;

    //Mapping of tweetId to position in the allTweets array
    mapping(uint256 => uint256) private _allTweetsIndex;

    // Mapping of tweetId to tweet
    mapping(uint256 => Tweet) public tweets;

    struct Tweet {
        address authorAddr;
        uint256 tweetId;
        string text;
        uint256 timestamp;
        string photoUri;
    }

    function _exists(uint256 _tweetId)
        public
        view
        onlyController
        returns (bool)
    {
        // All kwys in solidity mapping exists, so we need to check the zero index
        uint256 tweetIndex = _allTweetsIndex[_tweetId];
        return tweetIndex != 0 || _allTweets[tweetIndex] == _tweetId;
    }

    function _addTweetToAuthor(address _to, uint256 _tweetId) private {
        _ownedTweets[_to].push(_tweetId);
        _ownedTweetsIndex[_tweetId] = tweetCountOf(_to) - 1;
    }

    function _addTweetToAllTweets(uint256 _tweetId) private {
        _allTweets.push(_tweetId);
        _allTweetsIndex[_tweetId] = _allTweets.length - 1;
    }

    function _removeTweetFromAuthor(address _from, uint256 _tweetId) private {
        require(
            authorOf(_tweetId) == _from,
            "UserStorage: user does not own this tweet"
        );
        require(
            _ownedTweets[_from].length > 0,
            "UserStorage: user has no tweets"
        );
        uint256 lastIndex = _ownedTweets[_from].length - 1;
        uint256 tweetIndex = _ownedTweetsIndex[_tweetId];

        uint256 lastTweetId = _ownedTweets[_from][lastIndex];
        _ownedTweets[_from][tweetIndex] = lastTweetId;
        _ownedTweetsIndex[lastTweetId] = tweetIndex;

        delete _ownedTweetsIndex[_tweetId];
        _ownedTweets[_from].pop();
    }

    function _removeTweetFromAllTweets(uint256 _tweetId) private {
        uint256 lastIndex = _allTweets.length - 1;
        uint256 tweetIndex = _allTweetsIndex[_tweetId];

        uint256 lastTweetId = _allTweets[lastIndex];
        _allTweets[tweetIndex] = lastTweetId;
        _allTweetsIndex[lastTweetId] = tweetIndex;

        delete _allTweetsIndex[_tweetId];
        _allTweets.pop();
    }

    function authorOf(uint256 _tweetId) public view returns (address) {
        return tweets[_tweetId].authorAddr;
    }

    function tweetsOf(address _author) public view returns (uint256[] memory) {
        return _ownedTweets[_author];
    }

    function tweetCountOf(address _authorAddr) public view returns (uint256) {
        require(_authorAddr != address(0), "User address cannot be zero");
        return _ownedTweets[_authorAddr].length;
    }

    function createTweet(
        address _userAddr,
        string memory _text,
        string memory _photoUri
    ) public onlyController returns (uint256) {
        _tweetCount.increment();
        uint256 newTweetId = _tweetCount.current();
        _addTweetToAuthor(_userAddr, newTweetId);
        _addTweetToAllTweets(newTweetId);
        tweets[newTweetId] = Tweet(
            _userAddr,
            newTweetId,
            _text,
            block.timestamp,
            _photoUri
        );
        emit TweetCreated(_userAddr, newTweetId, block.timestamp);
        return newTweetId;
    }

    function deleteTweet(address _from, uint256 _tweetId)
        public
        onlyController
    {
        require(_exists(_tweetId), "Tweet does not exist");
        require(
            authorOf(_tweetId) == _from || _from == owner(),
            "TweetStorage: User does not own this tweet"
        );
        _removeTweetFromAuthor(_from, _tweetId);
        _removeTweetFromAllTweets(_tweetId);
        delete tweets[_tweetId];
        emit TweetDeleted(_from, _tweetId, block.timestamp);
    }

    function deleteAllTweetsOfUser(address _deletedUserAddr)
        public
        onlyController
    {
        uint256[] memory tweetIds = _ownedTweets[_deletedUserAddr];
        uint256 count = tweetIds.length;
        for (uint256 i = 0; i < count; i++) {
            deleteTweet(_deletedUserAddr, tweetIds[i]);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./utils/BaseStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract UserStorage is BaseStorage {
    event UserCreated(
        address indexed _userAddr,
        uint256 _userId,
        uint256 _timestamp
    );
    event UserDeleted(
        address indexed _userAddr,
        uint256 _userId,
        uint256 _timestamp
    );

    // Use for assigning unique ids to users
    using Counters for Counters.Counter;
    Counters.Counter private _userCount;

    // Map of user address to user profile
    mapping(address => Profile) public profiles;

    // Map of user's id to the the index of the user in the array of users
    mapping(uint256 => uint256) private _userIndex;

    // Store all user's id for easy enumeration
    uint256[] private _allUserIds;

    struct Profile {
        uint256 userId;
        address userAddr;
        bytes32 username;
        string image_uri;
        bool exists;
    }

    function _exists(address _userAddr)
        public
        view
        onlyController
        returns (bool)
    {
        return profiles[_userAddr].exists;
    }

    function createUser(
        address _userAddr,
        bytes32 _username,
        string memory _image_uri
    ) public onlyController returns (uint256) {
        require(!_exists(_userAddr), "User already exists");
        _userCount.increment();
        uint256 newUserId = _userCount.current();
        profiles[_userAddr] = Profile(
            newUserId,
            _userAddr,
            _username,
            _image_uri,
            true
        );
        _allUserIds.push(newUserId);
        _userIndex[newUserId] = _allUserIds.length - 1;
        emit UserCreated(_userAddr, newUserId, block.timestamp);
        return newUserId;
    }

    function deleteUser(address _from) public onlyController {
        require(_exists(_from), "User does not exist");
        uint256 userId = profiles[_from].userId;
        uint256 lastIndex = _allUserIds.length - 1;
        uint256 userIndex = _userIndex[userId];
        _allUserIds[userIndex] = _allUserIds[lastIndex];
        _userIndex[_allUserIds[lastIndex]] = userIndex;
        _allUserIds.pop();
        profiles[_from].exists = false;

        emit UserDeleted(_from, userId, block.timestamp);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./utils/BaseStorage.sol";
import "./TweetStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract CommentStorage is BaseStorage {
    event CommentCreated(
        address indexed _author,
        uint256 indexed _tweetId,
        uint256 commentId,
        uint256 _timestamp
    );

    event CommentDeleted(
        address indexed _author,
        uint256 indexed _tweetId,
        uint256 commentId,
        uint256 _timestamp
    );
    using Counters for Counters.Counter;
    Counters.Counter private _commentCount;
    // Mapping from tweetId to list of owned CommentIds
    mapping(uint256 => uint256[]) private _commentsOfTweet;

    // Mapping from CommentId to index of the tweet's Comments list
    mapping(uint256 => uint256) private _commentsOfTweetIndex;

    // Mapping from address to list of owned CommentIds
    mapping(address => uint256[]) private _commentsOfAuthor;

    // Mapping from CommentId to index of the address's Comments list
    mapping(uint256 => uint256) private _commentsOfAuthorIndex;

    // Array with all Comments' ids
    uint256[] private _allComments;

    //Mapping of CommentId to position in the allComments array
    mapping(uint256 => uint256) private _allCommentsIndex;

    // Mapping of CommentId to Comment
    mapping(uint256 => Comment) public comments;

    struct Comment {
        address authorAddr;
        uint256 tweetId;
        uint256 commentId;
        string text;
        uint256 timestamp;
        string photoUri;
    }

    function _exists(uint256 _commentId)
        public
        view
        onlyController
        returns (bool)
    {
        // All kwys in solidity mapping exists, so we need to check the zero index
        uint256 commentIndex = _allCommentsIndex[_commentId];
        return commentIndex != 0 || _allComments[commentIndex] == _commentId;
    }

    function _addCommentToTweet(uint256 _tweetId, uint256 _commentId) private {
        _commentsOfTweet[_tweetId].push(_commentId);
        _commentsOfTweetIndex[_commentId] =
            _commentsOfTweet[_tweetId].length -
            1;
    }

    function _addCommentToAuthor(address _authorAddr, uint256 _commentId)
        private
    {
        _commentsOfAuthor[_authorAddr].push(_commentId);
        _commentsOfAuthorIndex[_commentId] =
            _commentsOfAuthor[_authorAddr].length -
            1;
    }

    function _addCommentToAllComments(uint256 _commentId) private {
        _allComments.push(_commentId);
        _allCommentsIndex[_commentId] = _allComments.length - 1;
    }

    function _removeCommentFromTweet(uint256 _tweetId, uint256 _commentId)
        private
    {
        require(
            _commentTo(_commentId) == _tweetId,
            "This Comment do not belong to this Tweet"
        );
        uint256 lastIndex = _commentsOfTweet[_tweetId].length - 1;
        uint256 commentIndex = _commentsOfTweetIndex[_commentId];

        uint256 lastCommentId = _commentsOfTweet[_tweetId][lastIndex];
        _commentsOfTweet[_tweetId][commentIndex] = lastCommentId;
        _commentsOfTweetIndex[lastCommentId] = commentIndex;

        delete _commentsOfTweetIndex[_commentId];
        _commentsOfTweet[_tweetId].pop();
    }

    function _removeCommentFromAuthor(address _authorAddr, uint256 _commentId)
        private
    {
        require(
            authorOf(_commentId) == _authorAddr,
            "This Comment do not belong to this author"
        );
        uint256 lastIndex = _commentsOfAuthor[_authorAddr].length - 1;
        uint256 commentIndex = _commentsOfAuthorIndex[_commentId];

        uint256 lastCommentId = _commentsOfAuthor[_authorAddr][lastIndex];
        _commentsOfAuthor[_authorAddr][commentIndex] = lastCommentId;
        _commentsOfAuthorIndex[lastCommentId] = commentIndex;

        delete _commentsOfAuthorIndex[_commentId];
        _commentsOfAuthor[_authorAddr].pop();
    }

    function _removeCommentFromAllComments(uint256 _CommentId) private {
        uint256 lastIndex = _allComments.length - 1;
        uint256 CommentIndex = _allCommentsIndex[_CommentId];

        uint256 lastCommentId = _allComments[lastIndex];
        _allComments[CommentIndex] = lastCommentId;
        _allCommentsIndex[lastCommentId] = CommentIndex;

        delete _allCommentsIndex[_CommentId];
        _allComments.pop();
    }

    function _commentTo(uint256 _commentId) private view returns (uint256) {
        return comments[_commentId].tweetId;
    }

    function authorOf(uint256 _commentId) public view returns (address) {
        return comments[_commentId].authorAddr;
    }

    function commentsOfTweet(uint256 _tweetId)
        external
        view
        returns (uint256[] memory)
    {
        return _commentsOfTweet[_tweetId];
    }

    function commentsOfAuthor(address _authorAddr)
        external
        view
        returns (uint256[] memory)
    {
        require(
            _authorAddr != address(0),
            "Author address cannot be the zero address"
        );
        return _commentsOfAuthor[_authorAddr];
    }

    function commentCountOfAuthor(address _authorAddr)
        external
        view
        returns (uint256)
    {
        require(_authorAddr != address(0), "User address cannot be zero");
        return _commentsOfAuthor[_authorAddr].length;
    }

    function createComment(
        address _authorAddr,
        uint256 _tweetId,
        string memory _text,
        string memory _photoUri
    ) public onlyController returns (uint256) {
        _commentCount.increment();
        uint256 newCommentId = _commentCount.current();
        _addCommentToTweet(_tweetId, newCommentId);
        _addCommentToAuthor(_authorAddr, newCommentId);
        _addCommentToAllComments(newCommentId);
        comments[newCommentId] = Comment(
            _authorAddr,
            newCommentId,
            _tweetId,
            _text,
            block.timestamp,
            _photoUri
        );
        return newCommentId;
    }

    function deleteComment(address _from, uint256 _commentId)
        public
        onlyController
        returns (bool)
    {
        require(_exists(_commentId), "Comment does not exist");
        require(
            authorOf(_commentId) == _from,
            "User does not own this comment"
        );

        _removeCommentFromAuthor(_from, _commentId);
        _removeCommentFromTweet(_commentTo(_commentId), _commentId);
        _removeCommentFromAllComments(_commentId);
        delete comments[_commentId];
        return true;
    }

    function deleteAllCommentsOfTweet(address _from, uint256 _tweetId)
        public
        onlyController
        returns (bool)
    {
        uint256 count = _commentsOfTweet[_tweetId].length;
        for (uint256 i = 0; i < count; i++) {
            uint256 commentId = _commentsOfTweet[_tweetId][i];
            deleteComment(_from, commentId);
        }
        return true;
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BaseStorage is Ownable {
    address public controllerAddr;

    modifier onlyController() {
        require(msg.sender == controllerAddr);
        _;
    }

    function setControllerAddr(address _controllerAddr) public onlyOwner {
        controllerAddr = _controllerAddr;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}