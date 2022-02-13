// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract VoteStorage {

    address public owner;

    mapping(string => uint256) votes;
    mapping(uint256 => uint256) results;
    string[] voters;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Permission denied.");
        _;
    }

    function create_vote(string memory id, uint256 num) public onlyOwner {
        require(votes[id] == 0, "This vote is duplicated.");
        votes[id] = num;
        voters.push(id);
    }

    function calculate() public {
        for(uint256 i = 0; i < voters.length; i++) {
            results[votes[voters[i]]]++;
        }
    }

    function voters_count() public view returns(uint256) {
        return voters.length;
    }

    function get_result(uint256 id) public view returns(uint256) {
        return results[id];
    }
}