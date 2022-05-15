// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.1;

contract EncryptedAnonimVoting {

    enum VotingStatus {TOO_EARLY, ACTIVE, FINISHED}
    VotingStatus voting_status;

    string public name;
    address creator;

    bytes[] public votes;
    string[] public signs;

    string[] public voters_public_keys;

    string public public_encryption_key;
    string public secret_decryption_key;

    event votedEvent();

    constructor (string memory _name, string memory _public_key, string[] memory _voters) {
        creator = msg.sender;

        name = _name;
        public_encryption_key = _public_key;
        voting_status = VotingStatus.TOO_EARLY;
        voters_public_keys = _voters;
    }

    function start_voting() public {
        require(creator == msg.sender);
        require(voting_status == VotingStatus.TOO_EARLY);
        voting_status = VotingStatus.ACTIVE;
    }

    function finish_voting() public {
        require(creator == msg.sender);
        require(voting_status == VotingStatus.ACTIVE);
        voting_status = VotingStatus.FINISHED;
    }

    function continue_voting() public {
        // TODO: DEBUG ONLY! REMOVE BEFORE PRODUCTION!
        require(creator == msg.sender);
        voting_status = VotingStatus.ACTIVE;
    }

    function publish_secret_key(string memory _secret_key) public {
        require(creator == msg.sender);
        require(voting_status == VotingStatus.FINISHED);
        secret_decryption_key = _secret_key;
    }

    function vote(bytes calldata _vote, string memory _sign) public {
        require(voting_status == VotingStatus.ACTIVE);

        votes.push(_vote);
        signs.push(_sign);

        // trigger voted event
        emit votedEvent();
    }

    function get_votes() public view returns (bytes[] memory) {
        require(voting_status == VotingStatus.FINISHED);
        return votes;
    }

    function get_signs() public view returns (string[] memory) {
        require(voting_status == VotingStatus.FINISHED);
        return signs;
    }

    function get_voters_public_keys() public view returns (string[] memory) {
        return voters_public_keys;
    }


}