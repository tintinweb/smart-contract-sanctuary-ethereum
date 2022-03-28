//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./utils/BaseStorage.sol";
import "./interfaces/ITweetStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract TweetStorage is BaseStorage, ITweetStorage {
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
    mapping(address => uint256[]) private _ownedTweets;

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
        bool deleted;
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

    function tweetsOf(address _author)
        external
        view
        returns (uint256[] memory)
    {
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
    ) external onlyController returns (uint256) {
        _tweetCount.increment();
        uint256 newTweetId = _tweetCount.current();
        _addTweetToAuthor(_userAddr, newTweetId);
        _addTweetToAllTweets(newTweetId);
        tweets[newTweetId] = Tweet(
            _userAddr,
            newTweetId,
            _text,
            block.timestamp,
            _photoUri,
            false
        );
        emit TweetCreated(_userAddr, newTweetId, block.timestamp);
        return newTweetId;
    }

    function deleteTweet(address _from, uint256 _tweetId)
        public
        onlyController
    {
        _removeTweetFromAuthor(_from, _tweetId);
        _removeTweetFromAllTweets(_tweetId);
        delete tweets[_tweetId];
        tweets[_tweetId].deleted = true;
        emit TweetDeleted(_from, _tweetId, block.timestamp);
    }

    function deleteAllTweetsOfUser(address _userAddr) external onlyController {
        uint256[] memory tweetIds = _ownedTweets[_userAddr];
        uint256 count = tweetIds.length;
        for (uint256 i = 0; i < count; i++) {
            deleteTweet(_userAddr, tweetIds[i]);
        }
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

interface ITweetStorage {
    function tweets(uint256 _tweetId)
        external
        view
        returns (
            address authorAddr,
            uint256 tweetId,
            string memory text,
            uint256 timestamp,
            string memory photo_uri,
            bool deleted
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

    function deleteAllTweetsOfUser(address _userAddr) external;
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