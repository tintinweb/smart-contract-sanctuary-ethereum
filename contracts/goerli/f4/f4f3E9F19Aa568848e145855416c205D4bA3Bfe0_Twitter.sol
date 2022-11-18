// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Twitter {
    struct Tweet {
        uint256 id;
        address author;
        string content;
        uint256 createdAt;
    }
    struct Message {
        uint256 id;
        string content;
        address from;
        address to;
        uint256 createdAt;
    }
    mapping(uint256 => Tweet) private tweets;
    mapping(address => uint256[]) private tweetsOf;
    mapping(address => address[]) private following;
    mapping(uint256 => Message[]) private conversations;
    mapping(address => mapping(address => bool)) private operators;
    uint256 private nextTweetId;
    uint256 private nextMessageId;

    event TweetSent(
        uint256 id,
        address indexed author,
        string content,
        uint256 createdAt
    );

    event MessageSent(
        uint256 id,
        string content,
        address from,
        address to,
        uint256 createdAt
    );

    function tweet(string calldata _content) external {
        _tweet(msg.sender, _content);
    }

    function tweetFrom(address _from, string calldata _content)
        external
        canOperate(msg.sender)
    {
        _tweet(_from, _content);
    }

    function sendMessage(string calldata _content, address _to) external {
        _sendMessage(_content, msg.sender, _to);
    }

    function sendMessageFrom(
        string calldata _content,
        address _from,
        address _to
    ) external canOperate(msg.sender) {
        _sendMessage(_content, _from, _to);
    }

    function follow(address _followed) external {
        following[msg.sender].push(_followed);
    }

    function getLatestTweets(uint256 count)
        external
        view
        returns (Tweet[] memory)
    {
        require(
            count > 0 && count <= nextTweetId,
            "too few or too many tweets to return"
        );
        Tweet[] memory _tweets = new Tweet[](count);
        for (uint256 i = nextTweetId - count; i < nextTweetId; i++) {
            Tweet storage _tweet = tweets[i];
            _tweets[i] = Tweet(
                _tweet.id,
                _tweet.author,
                _tweet.content,
                _tweet.createdAt
            );
        }
        return _tweets;
    }

    function getTweetOf(address _user, uint256 count)
        external
        view
        returns (Tweet[] memory)
    {
        uint256[] storage tweetIds = tweetsOf[_user];
        require(
            count > 0 && count <= tweetIds.length,
            "too few or too many tweets to return"
        );
        Tweet[] memory _tweets = new Tweet[](count);
        for (uint256 i = tweetIds.length - count; i < nextTweetId; i++) {
            Tweet storage _tweet = tweets[i];
            _tweets[i] = Tweet(
                _tweet.id,
                _tweet.author,
                _tweet.content,
                _tweet.createdAt
            );
        }
    }

    function _tweet(address _from, string memory _content) internal {
        tweets[nextTweetId] = Tweet(
            nextTweetId,
            _from,
            _content,
            block.timestamp
        );
        tweetsOf[_from].push(nextTweetId);
        emit TweetSent(nextTweetId, _from, _content, block.timestamp);
        nextTweetId++;
    }

    function _sendMessage(
        string memory _content,
        address _from,
        address _to
    ) internal {
        uint256 conversationId = nextMessageId;
        conversations[conversationId].push(
            Message(nextMessageId, _content, _from, _to, block.timestamp)
        );
        emit MessageSent(nextMessageId, _content, _from, _to, block.timestamp);
        nextMessageId++;
    }

    modifier canOperate(address _from) {
        require(
            operators[_from][msg.sender] == true,
            "operators not authorized"
        );
        _;
    }
}