// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "VoteStorage.sol";


contract DynamicVoteStorage {

    address public owner;
    mapping(uint256 => address) private voteStorages;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Permission denied.");
        _;
    }

    function create_election(uint id, uint start_date, uint end_date, uint256[] memory candidates) public onlyOwner {
        VoteStorage voteStorage =  new VoteStorage(start_date, end_date, candidates);
        voteStorages[id] = address(voteStorage);
    }

    function create_vote(uint256 user_id, uint256 candidate_id, uint id) public onlyOwner {
        address election_address = voteStorages[id];
        VoteStorage voteStorage = VoteStorage(election_address);
        voteStorage.create_vote(user_id, candidate_id);
    }

    function get_result(uint256 candidate_id, uint id) public view returns(uint256) {
        address election_address = voteStorages[id];
        VoteStorage voteStorage = VoteStorage(election_address);
        return voteStorage.get_result(candidate_id);
    }

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract VoteStorage {

    address private owner;
    uint private start_date;
    uint private end_date;
    mapping(uint256 => uint256) private votes;
    mapping(uint256 => uint256) private results;
    uint256[] private voters;
    uint256[] private candidates;

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

    function create_vote(uint256 user_id, uint256 candidate_id) public onlyOwner {
        require(votes[user_id] == 0, "User already voted.");

        // Save voter id
        voters.push(user_id);
        // Save vote
        votes[user_id] = candidate_id;
        // Increment candidate vote count
        results[candidate_id]++;
    }

    function voters_count() public view returns(uint256) {
        return voters.length;
    }

    function get_result(uint256 user_id) public view returns(uint256) {
        return results[user_id];
    }

}