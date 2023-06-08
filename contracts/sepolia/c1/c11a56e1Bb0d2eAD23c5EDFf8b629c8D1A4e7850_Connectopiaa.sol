// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Post.sol";
import "./Subscription.sol";
import "./Like.sol";
import "./PostStruct.sol";

contract Connectopiaa {
    Post private postInstance;
    Subscription private subscriptionInstance;
    Like private likesInstance;

    constructor() {
        postInstance = new Post();
        subscriptionInstance = new Subscription();
        likesInstance = new Like();
    }

    function createPost(
        string memory _content,
        bool _isPaidContent,
        uint256 _price
    ) public returns (uint256) {
        return postInstance.createPost(_content, _isPaidContent, _price);
    }

    function payForPost(uint256 _postId) public payable {
        subscriptionInstance.payForPost{value: msg.value}(_postId);
    }

    function hasPaidForPost(
        uint256 _postId,
        address _user
    ) public view returns (bool) {
        return postInstance.hasPaidForPost(_postId, _user);
    }

    function likePost(uint256 _postId) public returns (bool) {
        likesInstance.likePost(_postId);
        return true;
    }

    function getPosts() public view returns (PostStruct[] memory) {
        return postInstance.getPosts();
    }

    function getUserPosts(address _user)
        public
        view
        returns (PostStruct[] memory)
    {
        return postInstance.getUserPosts(_user);
    }

    function getPayablePosts() public view returns (PostStruct[] memory) {
        return postInstance.getPayablePosts();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Post.sol";

contract Like is Post {
    function likePost(
        uint256 _postId
    ) public doesPostExist(_postId) returns (bool) {
        posts[_postId].likes = posts[_postId].likes + 1;
        emit PostLiked(_postId, msg.sender);
        return true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./PostStruct.sol";

contract Post {
    mapping(uint256 => PostStruct) internal posts;
    mapping(uint256 => mapping(address => bool)) internal paidPosts;
    uint256 nextPostId = 0;

    modifier hasValidContent(string memory _content) {
        require(
            bytes(_content).length != 0,
            "PostStruct Content should not be empty."
        );
        _;
    }

    modifier isContentPayable(uint256 _postId) {
        require(
            posts[_postId].isPaidContent,
            "This post does not require subscription."
        );
        _;
    }

    modifier hasPriceIfPayableContent(bool _isPaidContent, uint256 _price) {
        require(
            !_isPaidContent || _price > 0,
            "Price must be greater than zero for payable content."
        );
        _;
    }

    modifier doesPostExist(uint256 _postId) {
        require(posts[_postId].postId != 0, "Invalid PostStruct ID");
        _;
    }

    event PostCreated(
        uint256 postId,
        address indexed author,
        uint256 timestamp
    );
    event PostLiked(uint256 postId, address indexed liker);
    event PostPaid(uint256 postId, address indexed payer, uint256 amount);

    function createPost(
        string memory _content,
        bool _isPaidContent,
        uint256 _price
    )
        public
        hasValidContent(_content)
        hasPriceIfPayableContent(_isPaidContent, _price)
        returns (uint256)
    {
        posts[nextPostId] = PostStruct(
            nextPostId,
            msg.sender,
            _content,
            block.timestamp,
            0,
            false,
            _isPaidContent,
            _price,
            new address[](0)
        );

        nextPostId++;
        emit PostCreated(nextPostId, msg.sender, block.timestamp);

        return nextPostId - 1;
    }

    function hasPaidForPost(
        uint256 _postId,
        address _user
    ) public view returns (bool) {
        return paidPosts[_postId][_user];
    }

    function getPosts() public view returns (PostStruct[] memory) {
        PostStruct[] memory allPosts = new PostStruct[](nextPostId);

        for (uint i = 0; i < nextPostId; i++) {
            PostStruct storage post = posts[i];
            allPosts[i] = post;
        }

        return allPosts;
    }

    function getUserPosts(address _user) public view returns (PostStruct[] memory) {
        PostStruct[] memory userPosts = new PostStruct[](nextPostId);
        uint256 userPostCount = 0;

        for (uint i = 0; i < nextPostId; i++) {
            PostStruct storage post = posts[i];
            if (post.author == _user) {
                userPosts[userPostCount] = post;
                userPostCount++;
            }
        }

        return userPosts;
    }

    function getPayablePosts() public view returns (PostStruct[] memory) {
        PostStruct[] memory payablePosts = new PostStruct[](nextPostId);
        uint256 payablePostCount = 0;

        for (uint i = 0; i < nextPostId; i++) {
            PostStruct storage post = posts[i];
            if (post.isPaidContent) {
                payablePosts[payablePostCount] = post;
                payablePostCount++;
            }
        }

        return payablePosts;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

struct PostStruct {
    uint256 postId;
    address author;
    string content;
    uint256 timestamp;
    uint256 likes;
    bool isHidden;
    bool isPaidContent;
    uint256 price;
    address[] subscribers;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Post.sol";
import "./PostStruct.sol";

contract Subscription is Post {
    mapping(uint256 => uint256) public subscriberCount;

    modifier hasEnoughFound(uint256 _postId) {
        require(
            msg.value >= posts[_postId].price,
            "You don't have sufficiant found to subscribe."
        );
        _;
    }

    modifier isOwnerOfPost(uint256 _postId) {
        require(
            posts[_postId].author != msg.sender,
            "You can't pay for your own post."
        );
        _;
    }

    modifier hasAlreadyPaid(uint256 _postId) {
        require(
            !paidPosts[_postId][msg.sender],
            "You have already paid for this post."
        );
        _;
    }

    function payForPost(
        uint256 _postId
    )
        public
        payable
        doesPostExist(_postId)
        isContentPayable(_postId)
        hasEnoughFound(_postId)
        isOwnerOfPost(_postId)
        hasAlreadyPaid(_postId)
        returns (bool)
    {
        PostStruct memory post = posts[_postId];
        paidPosts[_postId][msg.sender] = true;
        uint256 currentLength = post.subscribers.length;

        address[] memory newSubscribers = new address[](currentLength + 1);

        for (uint256 i = 0; i < currentLength; i++) {
            newSubscribers[i] = post.subscribers[i];
        }

        newSubscribers[currentLength] = msg.sender;
        post.subscribers = newSubscribers;

        address payable postAuthor = payable(post.author);
        postAuthor.transfer(msg.value);
        subscriberCount[_postId] += 1;
        emit PostPaid(_postId, msg.sender, msg.value);
        return true;
    }
}