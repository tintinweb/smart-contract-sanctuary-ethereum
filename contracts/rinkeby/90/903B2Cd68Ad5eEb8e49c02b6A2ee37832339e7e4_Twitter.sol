// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "./interfaces/ITweetCoin.sol";

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
        mapping(address => bool) followers;
        mapping(address => bool) following;
        mapping(uint256 => Tweet) tweets;
        uint256 numberOfFollowers;
        uint256 numberOfFollowing;
        uint256 numberOfTweets;
    }
    mapping(address => UserInfo) public users;

    ITweetCoin private immutable tweetCoin;
    address private immutable tweetCoinAddress;

    event UserCreated(address);
    event UserDeleted(address);
    event UsernameUpdated(address, string);
    event FollowUser(address, address);
    event UnfollowUser(address, address);
    event TweetCreated(address, string, uint256);
    event TweetDeleted(address, uint256);
    event TweetLiked(address, address, uint256, uint256);
    event TweetUnliked(address, address, uint256, uint256);

    constructor(address _tweetCoin) {
        tweetCoinAddress = _tweetCoin;
        tweetCoin = ITweetCoin(_tweetCoin);
    }

    function registerUser() public {
        require(users[msg.sender].registeredAddress != msg.sender, "Address already in use");
        users[msg.sender].registeredAddress = msg.sender;
        users[msg.sender].username = "";
        users[msg.sender].numberOfFollowers = 0;
        users[msg.sender].numberOfFollowing = 0;
        users[msg.sender].numberOfTweets = 0;
        emit UserCreated(msg.sender);
    }

    function setUsername(string memory _username) public {
        users[msg.sender].username = _username;
        emit UsernameUpdated(msg.sender, _username);
    }

    function deleteUser() public {
        require(
            users[msg.sender].registeredAddress != 0x0000000000000000000000000000000000000000,
            "User doesn't exist"
        );
        delete users[msg.sender];
        emit UserDeleted(msg.sender);
    }

    function sendTweetCoinToUser(address to, uint256 amount) public {
        tweetCoin.transfer(to, amount);
    }

    function buyTweetCoins(uint256 amount) public {
        tweetCoin.mint(msg.sender, amount);
    }

    function getUser(address user)
        public
        view
        returns (
            address,
            string memory,
            uint256,
            uint256
        )
    {
        return (
            users[user].registeredAddress,
            users[user].username,
            users[user].numberOfFollowers,
            users[user].numberOfFollowers
        );
    }

    function getTweet(address user, uint256 id)
        public
        view
        returns (
            address,
            string memory,
            string memory,
            uint256
        )
    {
        return (
            users[user].registeredAddress,
            users[user].username,
            users[user].tweets[id].tweet,
            users[user].tweets[id].likesCount
        );
    }

    function tweet(string memory _tweet) public {
        uint256 id = users[msg.sender].numberOfTweets++;
        users[msg.sender].tweets[id].tweet = _tweet;
        users[msg.sender].tweets[id].creator = msg.sender;
        emit TweetCreated(msg.sender, _tweet, id);
    }

    function followUser(address toFollow) public {
        require(msg.sender != toFollow, "You cannot follow yoursel");
        users[toFollow].followers[msg.sender] = true;
        users[msg.sender].following[toFollow] = true;
        users[msg.sender].numberOfFollowers++;
        users[msg.sender].numberOfFollowing++;
        emit FollowUser(msg.sender, toFollow);
    }

    function unfollowUser(address unfollowAddress) public {
        require(msg.sender != unfollowAddress, "You cannot unfollow yoursel");
        users[msg.sender].following[unfollowAddress] = false;
        users[unfollowAddress].followers[msg.sender] = false;
        users[msg.sender].numberOfFollowers--;
        users[msg.sender].numberOfFollowing--;
        emit UnfollowUser(msg.sender, unfollowAddress);
    }

    function likeTweet(address user, uint256 id) public {
        users[user].tweets[id].likes[msg.sender] = true;
        users[user].tweets[id].likesCount++;
        emit TweetLiked(msg.sender, user, id, users[user].tweets[id].likesCount);
    }

    function unlikeTweet(address user, uint256 id) public {
        users[user].tweets[id].likes[msg.sender] = false;
        users[user].tweets[id].likesCount--;
        emit TweetUnliked(msg.sender, user, id, users[user].tweets[id].likesCount);
    }
}

pragma solidity ^0.8.11;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITweetCoin is IERC20 {
    function mint(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}