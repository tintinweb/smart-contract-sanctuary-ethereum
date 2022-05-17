// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract VoterCVXProxy {
    address public owner;
    address public voteProcessor;

    mapping(bytes32 => bool) private votes;

    bytes4 internal constant MAGIC_VALUE = 0x1626ba7e;

    event VoteSet(bytes32 hash, bool valid);

    constructor(address _voteProcessor) {
        owner = msg.sender;
        voteProcessor = _voteProcessor;
    }

    function setOwner(address _owner) external {
        require(msg.sender == owner, "!owner");
        owner = _owner;
    }

    function setVoteProcessor(address _voteProcessor) external {
        require(msg.sender == owner, "!owner");
        voteProcessor = _voteProcessor;
    }

    function vote(bytes32 _hash, bool _valid) external {
        require(msg.sender == voteProcessor, "!voteProcessor");
        votes[_hash] = _valid;
        emit VoteSet(_hash, _valid);
    }

    function isValidSignature(bytes32 _hash, bytes memory)
        public
        view
        returns (bytes4)
    {
        if (votes[_hash]) {
            return MAGIC_VALUE;
        } else {
            return bytes4(0);
        }
    }
}