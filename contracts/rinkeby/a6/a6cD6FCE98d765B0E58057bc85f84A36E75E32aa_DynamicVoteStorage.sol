// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "VoteStorage.sol";


contract DynamicVoteStorage {

    address public owner;
    mapping(uint256 => address) public voteStorages;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Permission denied.");
        _;
    }

    function create_election(uint256 election_id, uint start_date, uint end_date, uint256[] memory candidates) public onlyOwner {
        VoteStorage voteStorage =  new VoteStorage(start_date, end_date, candidates);
        voteStorages[election_id] = address(voteStorage);
    }

    function create_vote(uint256 election_id, uint256 user_id, uint256 candidate_id) public onlyOwner {
        address election_address = voteStorages[election_id];
        VoteStorage voteStorage = VoteStorage(election_address);
        voteStorage.create_vote(user_id, candidate_id);
    }

    function get_vote(uint256 election_id, uint256 candidate_id) public view returns(uint256) {
        address election_address = voteStorages[election_id];
        VoteStorage voteStorage = VoteStorage(election_address);
        return voteStorage.get_vote(candidate_id);
    }

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract VoteStorage {

    address private owner;
    uint private start_date;
    uint private end_date;
    mapping(uint256 => uint256) public votes;
    mapping(uint256 => uint256) public results;
    uint256[] public voters;
    uint256[] public candidates;

    constructor(uint _start_date, uint _end_date, uint256[] memory _candidates) {
        owner = msg.sender;
        start_date = _start_date;
        end_date = _end_date;
        candidates = _candidates;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Permission denied.");
        _;
    }

    function create_vote(uint256 voter_id, uint256 candidate_id) public onlyOwner {
        require(votes[voter_id] == 0, "User already voted.");

        // Save voter id
        voters.push(voter_id);
        // Save vote
        votes[voter_id] = candidate_id;
        // Increment candidate vote count
        results[candidate_id]++;
    }

    function voters_count() public view returns(uint256) {
        return voters.length;
    }

    function get_vote(uint256 candidate_id) public view returns(uint256) {
        return results[candidate_id];
    }

}