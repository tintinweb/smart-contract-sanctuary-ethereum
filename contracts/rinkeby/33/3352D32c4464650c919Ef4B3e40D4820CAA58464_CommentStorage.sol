//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./utils/BaseStorage.sol";
import "./interfaces/ICommentStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract CommentStorage is BaseStorage, ICommentStorage {
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
    ) external onlyController returns (uint256) {
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
        external
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IBaseStorage.sol";

contract BaseStorage is Ownable, IBaseStorage {
    address public controllerAddr;

    modifier onlyController() {
        require(msg.sender == controllerAddr);
        _;
    }

    function setControllerAddr(address _controllerAddr) public onlyOwner {
        controllerAddr = _controllerAddr;
    }
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

interface IBaseStorage {
    function controllerAddr() external view returns (address);

    function setControllerAddr(address _controllerAddr) external;
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