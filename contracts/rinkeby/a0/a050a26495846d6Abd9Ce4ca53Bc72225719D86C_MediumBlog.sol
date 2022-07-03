// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract MediumBlog {
    //--------------------------------------------------------------------
    // VARIABLES

    address public admin;
    uint256 public postingFee;

    uint256 public authorsCount;

    struct Author {
        uint256 id;
        string username;
        string authorDesciption;
        string profileImageUrl;
        bool isActive;
    }
    struct Post {
        uint256 id;
        address creator;
        string title;
        string postOverview;
        string coverImageURI;
        uint256 readTime;
        string contentURI;
        uint256 createdAt;
    }

    Post[] public posts;
    mapping(address => Author) authors;

    //--------------------------------------------------------------------
    // EVENTS

    event AuthorAdded(uint256 id, string username);

    event PostCreated(
        uint256 id,
        address creator,
        string title,
        string postOverview,
        string coverImageURI,
        uint256 readTime,
        string contentURI,
        uint256 createdAt
    );

    event PostUpdated(
        uint256 id,
        address creator,
        string title,
        string postOverview,
        string coverImageURI,
        string contentURI,
        uint256 createdAt
    );

    //--------------------------------------------------------------------
    // MODIFIERS

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin call");
        _;
    }

    //--------------------------------------------------------------------
    // CONSTRUCTOR

    constructor(uint256 _fee) {
        admin = msg.sender;
        postingFee = _fee;
    }

    //--------------------------------------------------------------------
    // FUNCTIONS

    function subscribe(
        string memory _username,
        string memory _authorDesc,
        string memory _profilePictureUrl
    ) public {
        require(!authors[msg.sender].isActive, "Already subscribed");

        uint256 authorId = authorsCount;
        authors[msg.sender] = Author(
            authorId,
            _username,
            _authorDesc,
            _profilePictureUrl,
            true
        );
        authorsCount++;

        emit AuthorAdded(authorId, _username);
    }

    function editProfile(
        string memory _newUsername,
        string memory _newAuthorDesc,
        string memory _newProfileImageUrl
    ) public {
        require(authors[msg.sender].isActive, "Not subscribed");
        Author memory author = authors[msg.sender];
        author.username = _newUsername;
        author.authorDesciption = _newAuthorDesc;
        author.profileImageUrl = _newProfileImageUrl;

        authors[msg.sender] = author;
    }

    function createPost(
        string memory _title,
        string memory _postOverview,
        string memory _coverImageURI,
        uint256 _readTime,
        string memory _contentURI
    ) public payable {
        require(authors[msg.sender].isActive, "Must subscribe first");
        require(msg.value == postingFee, "must pay exact posting fee");
        uint256 newPostId = posts.length;
        posts.push(
            Post(
                newPostId,
                msg.sender,
                _title,
                _postOverview,
                _coverImageURI,
                _readTime,
                _contentURI,
                block.timestamp
            )
        );

        emit PostCreated(
            newPostId,
            msg.sender,
            _title,
            _postOverview,
            _coverImageURI,
            _readTime,
            _contentURI,
            block.timestamp
        );
    }

    function updatePost(
        uint256 _postId,
        string memory _newTitle,
        string memory _newPostOverview,
        uint256 _newReadTime,
        string memory _newCoverImageURI,
        string memory _newContentURI
    ) public {
        Post memory _post = posts[_postId];
        require(msg.sender == _post.creator, "only post creator");
        _post.title = _newTitle;
        _post.postOverview = _newPostOverview;
        _post.readTime = _newReadTime;
        _post.coverImageURI = _newCoverImageURI;
        _post.contentURI = _newContentURI;
        _post.createdAt = block.timestamp;

        posts[_postId] = _post;

        emit PostUpdated(
            _postId,
            msg.sender,
            _newTitle,
            _newPostOverview,
            _newCoverImageURI,
            _newContentURI,
            block.timestamp
        );
    }

    function tipPostCreator(uint256 _postId) public payable {
        Post memory _post = posts[_postId];
        require(msg.sender != _post.creator);
        payable(_post.creator).transfer(msg.value);
    }

    function getAllPosts() public view returns (Post[] memory) {
        return posts;
    }

    function getAuthorDetails(address _author)
        external
        view
        returns (Author memory)
    {
        return authors[_author];
    }

    //--------------------------------------------------------------------
    // ADMIN FUNCTIONS

    function withdrawBalance() external onlyAdmin {
        payable(admin).transfer(address(this).balance);
    }

    function changePostingFee(uint256 _newFee) external onlyAdmin {
        postingFee = _newFee;
    }
}