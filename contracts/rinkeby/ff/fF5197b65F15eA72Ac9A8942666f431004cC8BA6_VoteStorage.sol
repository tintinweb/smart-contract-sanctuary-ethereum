// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract VoteStorage {

    address public owner;

    mapping(string => uint256[]) votes;
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
        if (votes[id].length > 0) {
            for(uint256 i = 0; i < votes[id].length; i++) {
                require(votes[id][i] == num, "This vote is duplicated.");
            }
        } else {
            voters.push(id);
        }
        votes[id].push(num);
        results[num]++;
    }
    
    function voters_count() public view returns(uint256) {
        return voters.length;
    }

    function get_result(uint256 id) public view returns(uint256) {
        return results[id];
    }
}