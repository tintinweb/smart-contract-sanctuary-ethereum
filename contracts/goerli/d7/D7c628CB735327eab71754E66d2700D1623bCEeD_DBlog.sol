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
pragma solidity = 0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DBlog is Ownable {

	struct Post {
		address account;
		string cid;
		mapping(address => bool) likes;
		mapping(address => bool) flags;
		uint totalFlags;
		bool hidden;
	}

	event PostCreated(uint postId, string cid);
	event PostUpdated(uint postId, string cid);
	event PostDeleted(uint postId);
	event PostLiked(uint postId);
	event PostFlagged(uint postId);

	mapping(uint => Post) public posts;

	Counters.Counter public postMaxId;
	using Counters for Counters.Counter;

	function createPost(string calldata _cid) external onlyOwner /** for testing */ {
		// Post storage post = Post({
		// 	account: msg.sender,
		// 	cid: _cid,
		// 	flags: 0,
		// 	flagged: false
		// });
		
		// uint postId = postMaxId.current();
		// posts[postId] = post;
		// postMaxId.increment();

		uint postId = postMaxId.current();
		Post storage post = posts[postId];

		post.account = msg.sender;
		post.cid = _cid;
		post.hidden = false;

		postMaxId.increment();

		emit PostCreated(postId, _cid);
	}

	function updatePost(uint _id, string calldata _cid)
		postExists(_id)
		postPublisher(_id)
		postNotHidden(_id)
		external
	{
		Post storage post = posts[_id];
		post.cid = _cid;

		emit PostUpdated(_id, _cid);
	}

	function deletePost(uint _id) 
		postExists(_id)
		postPublisher(_id)
		external
	{
		delete posts[_id];
		emit PostDeleted(_id);
	}

	modifier postExists(uint id){
		require(id < postMaxId.current(), "Post does not exist");
		_;
	}

	modifier notPostPublisher(uint id){
		require(msg.sender != posts[id].account, "you are post owner");
		_;
	}

	modifier postPublisher(uint id){
		require(msg.sender == posts[id].account, "you are not post owner");
		_;
	}

	modifier postNotHidden(uint id){
		require(!posts[id].hidden, "post is hidden");
		_;
	}

	modifier postHidden(uint id){
		require(posts[id].hidden, "post is not hidden");
		_;
	}

	function likePost(uint postId)
		external
		postExists(postId)
		notPostPublisher(postId)
		postNotHidden(postId)
		returns (bool liked)
	{
		Post storage post = posts[postId];
		post.likes[msg.sender] = true;

		emit PostLiked(postId);

		return true;
	}

	modifier postNotFlagged(uint postId) {
		require(!posts[postId].flags[msg.sender], "account has flagged post");
		_;
	}

	function flagPost(uint postId)
		external
		postExists(postId)
		notPostPublisher(postId)
		postNotFlagged(postId)
		returns (bool flagged) 
	{
		Post storage post = posts[postId];

		post.flags[msg.sender] = true;
		post.totalFlags++;

		if(post.totalFlags >= maxFlags){
			post.hidden = true;
		}

		emit PostFlagged(postId);

		return (true);
	}

	uint public maxFlags = 3;
	function setMaxFlags(uint _flags) external onlyOwner {
		maxFlags = _flags;
	}

}