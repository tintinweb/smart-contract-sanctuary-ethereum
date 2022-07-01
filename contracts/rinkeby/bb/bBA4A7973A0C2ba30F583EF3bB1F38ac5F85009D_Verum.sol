// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract Verum {
    uint256 postIndex;
    event contentPosted(string contentURI);
    event attestationPosted(address attester, address profile, int8 attestation);
    event commentPosted(uint256 postIndex, string commentURI);
    function postContent(string calldata contentURI) external {
        postIndex++;
        emit contentPosted(contentURI);
    }
    function attestToProfile(address profile, int8 attestation) external {
        emit attestationPosted(msg.sender, profile, attestation);
    }
    function postComment(uint256 postIndex, string calldata commentURI) external {
        emit commentPosted(postIndex, commentURI);
    }
}