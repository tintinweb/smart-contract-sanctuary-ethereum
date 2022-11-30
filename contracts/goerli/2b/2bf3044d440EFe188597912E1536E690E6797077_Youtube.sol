// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Youtube {
    uint public videoCount = 0;
    string public name = "youtube";

    struct video {
        uint id;
        string ipfs_hash;
        string title;
        address creator;
    }

    mapping(uint256 => video) public content;

    event videoUpload (
        uint id,
        string ipfs_hash,
        string title,
        address creator
    );

    function uploadVideo (string memory _title, string memory _hash) public {
        require(bytes(_hash).length > 0);
        require(bytes(_title).length > 0);
        require(msg.sender != address(0));

        uint temp_count = videoCount + 1;

        content[temp_count] = video(temp_count, _hash, _title, msg.sender);
        emit videoUpload(temp_count, _hash, _title, msg.sender);
        videoCount = temp_count;

    }

    function returnCount() public view returns (uint) {
        return videoCount;
    }
}