// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract Verum {

    enum Attestation {
        honest,
        dishonest
    }

    event contentPosted(string contentURI);
    event attestationPosted(address attester, address profile, Attestation attestation);

    function postContent(string calldata contentURI) external {
        emit contentPosted(contentURI);
    }

    function attestToProfile(address profile, Attestation attestation) external {
        emit attestationPosted(msg.sender, profile, attestation);
    }

}