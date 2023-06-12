// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Connectopiaa {
    struct PostStruct {
        uint256 postId;
        address author;
        string title;
        string content;
        string image;
        uint256 timestamp;
        uint256 likes;
        bool isHidden;
        bool isPaidContent;
        uint256 price;
        address[] subscribers;
    }

    mapping(uint256 => PostStruct) internal posts;
    mapping(uint256 => mapping(address => bool)) internal paidPosts;
    mapping(uint256 => uint256) public subscriberCount;

    uint256 nextPostId = 1;

    event PostLiked(uint256 postId, address indexed liker);
    event PostPaid(uint256 postId, address indexed payer, uint256 amount);

    modifier hasValidContent(string memory _content) {
        require(
            bytes(_content).length > 0,
            "PostStruct content should not be empty."
        );
        _;
    }

    modifier isContentPayable(uint256 _postId) {
        require(posts[_postId].isPaidContent, "PostStruct is not payable.");
        _;
    }

    modifier hasPriceIfPayableContent(bool _isPaidContent, uint256 _price) {
        require(
            !_isPaidContent || _price > 0,
            "PostStruct price should be greater than 0."
        );
        _;
    }

    modifier hasEnoughFound(uint256 _postId) {
        require(
            msg.value >= posts[_postId].price,
            "You don't have sufficiant found to subscribe."
        );
        _;
    }

    modifier doesPostExist(uint256 _postId) {
        require(posts[_postId].postId > 0, "Post not found");
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

    event PostCreated(
        uint256 postId,
        address indexed author,
        uint256 timestamp
    );

    function createPost(
        address _author,
        string memory _title,
        string memory _content,
        bool _isPaidContent,
        uint256 _price,
        string memory _image
    )
        public
        hasValidContent(_content)
        hasPriceIfPayableContent(_isPaidContent, _price)
        returns (uint256)
    {
        uint256 price = _isPaidContent ? _price : 0;
        posts[nextPostId] = PostStruct(
            nextPostId,
            _author,
            _title,
            _content,
            _image,
            block.timestamp,
            0,
            false,
            _isPaidContent,
            price,
            new address[](0)
        );

        emit PostCreated(nextPostId, _author, block.timestamp);

        return nextPostId++;
    }

    function hasPaidForPost(
        uint256 _postId,
        address _user
    ) public view doesPostExist(_postId) returns (bool) {
        return paidPosts[_postId][_user];
    }

    function getPosts() public view returns (PostStruct[] memory) {
        PostStruct[] memory realPosts = new PostStruct[](nextPostId - 1);
        uint256 realPostCount = 0;

        for (uint i = 1; i < nextPostId; i++) {
            PostStruct storage post = posts[i];
            if (bytes(post.content).length > 0) {
                realPosts[realPostCount] = post;
                realPostCount++;
            }
        }

        assembly {
            mstore(realPosts, realPostCount)
        }

        return realPosts;
    }

    function getUserPosts(
        address _user
    ) public view returns (PostStruct[] memory) {
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

    function likePost(uint256 _postId) public returns (bool) {
        posts[_postId].likes = posts[_postId].likes + 1;
        emit PostLiked(_postId, msg.sender);
        return true;
    }

    function payForPost(
        uint256 _postId
    )
        public
        payable
        doesPostExist(_postId)
        isContentPayable(_postId)
        isOwnerOfPost(_postId)
        hasAlreadyPaid(_postId)
        hasEnoughFound(_postId)
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