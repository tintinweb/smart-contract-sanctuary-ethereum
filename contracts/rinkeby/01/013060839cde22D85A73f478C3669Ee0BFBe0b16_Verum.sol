// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract Verum {
    uint256 postId;
    event contentPosted(uint256 postId, string contentURI);
    event attestationPosted(address attestor, address profile, int8 attestation);
    event commentPosted(uint256 postId, string commentURI);
    function postContent(string calldata _contentURI) external {
        postId++;
        emit contentPosted(postId, _contentURI);
    }
    function attestToProfile(address _profile, int8 _attestation) external {
        emit attestationPosted(msg.sender, _profile, _attestation);
    }
    function postComment(uint256 _postId, string calldata _commentURI) external {
        emit commentPosted(_postId, _commentURI);
    }
}