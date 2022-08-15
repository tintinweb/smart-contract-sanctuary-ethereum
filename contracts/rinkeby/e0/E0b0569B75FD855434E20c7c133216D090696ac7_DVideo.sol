pragma solidity ^0.8.0;

contract DVideo {

    uint public videoCount = 0;
    mapping(uint => Video) public videos;
    mapping(uint => mapping(address => bool)) public videoLikes;

    struct Video {
        uint id;
        string hash;
        string title;
        uint likes;
        address author;
    }

    event VideoUploaded(
        uint id,
        string hash,
        string title,
        address author
    );

    event VideoLikedStatusChanged(
        uint indexed videoId,
        address by,
        bool liked
    );

    function uploadVideo(string memory _videoHash, string memory _title) public {
        require(bytes(_videoHash).length > 0, "DVideo: empty video hash");
        require(bytes(_title).length > 0, "DVideo: empty video title");

        videoCount++;

        videos[videoCount] = Video(videoCount, _videoHash, _title, 0, msg.sender);

        emit VideoUploaded(videoCount, _videoHash, _title, msg.sender);
    }

    function addLike(uint _videoId) public {
        require(!videoLikes[_videoId][msg.sender], "DVideo: user has already liked the video");

        videoLikes[_videoId][msg.sender] = true;
        videos[_videoId].likes++;

        emit VideoLikedStatusChanged(_videoId, msg.sender, true);
    }

    function removeLike(uint _videoId) public {
        require(videoLikes[_videoId][msg.sender], "DVideo: user never liked the video");

        delete videoLikes[_videoId][msg.sender];
        videos[_videoId].likes--;

        emit VideoLikedStatusChanged(_videoId, msg.sender, false);
    }
}