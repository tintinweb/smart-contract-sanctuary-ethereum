//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract DVideos {
    uint256 public videoCount = 0;

    mapping(uint256 => Video) public videos;
    struct Video {
        uint256 id;
        string videoURL;
        string title;
        string description;
        address author;
    }

    function getVideoCount() public view returns (uint256) {
        return videoCount;
    }

    function getVideo(uint256 _videoID) public view returns (Video memory) {
        return videos[_videoID];
    }

    function uploadVideo(
        string memory _videoURL,
        string memory _title,
        string memory _description
    ) public {
        require(bytes(_videoURL).length > 0);
        require(bytes(_title).length > 0);
        require(bytes(_description).length > 0);
        require(msg.sender != address(0));

        videoCount++;

        videos[videoCount] = Video(
            videoCount,
            _videoURL,
            _title,
            _description,
            msg.sender
        );
    }
}