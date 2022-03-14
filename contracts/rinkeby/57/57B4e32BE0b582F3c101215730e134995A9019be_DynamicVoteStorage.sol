// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "VoteStorage.sol";

contract DynamicVoteStorage {

    address public owner;
    VoteStorage[] public voteStorages;
    uint256 voteStorageIndex = 0;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Permission denied.");
        _;
    }

    function create_new_event() public onlyOwner {
        VoteStorage voteStorage =  new VoteStorage();
        voteStorages.push(voteStorage);
    }

    function create_vote(string memory id, uint256 num) public onlyOwner {
        VoteStorage voteStorage = VoteStorage(address(voteStorages[voteStorageIndex]));
        voteStorage.create_vote(id, num);
    }

    function get_result(uint256 num) public view returns(uint256){
        VoteStorage voteStorage = VoteStorage(address(voteStorages[voteStorageIndex]));
        return voteStorage.get_result(num);
    }

}

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