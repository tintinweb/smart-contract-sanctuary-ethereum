// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// snapshot SeeDao voting contract
// https://etherscan.io/address/0x23fda8a873e9e46dbe51c78754dddccfbc41cfe1#code

// ticket script
// https://github.com/snapshot-labs/snapshot-strategies/blob/master/src/strategies/ticket/README.md
// https://snapshot.org/#/avsee.eth
// https://snapshot.org/#/strategy/ticket

// https://docs.soliditylang.org/en/v0.8.20/solidity-by-example.html


contract VotingContract {
    struct Option {
        string description;
        uint256 voteCount;
    }

    struct Vote {
        string title;
        mapping(uint256 => Option) options;
        uint256 optionCount;
        mapping(address => bool) voters;
        uint256 endTime;
    }

    mapping(uint256 => Vote) public votes;
    uint256 public voteCount;

    event VoteCreated(uint256 voteId, string title);
    event VoteCast(uint256 voteId, uint256 optionId);

    function createVoteWithOption(string memory _title, uint256 _endTime, string[] memory _optionDescriptions) external {
        uint256 newVoteId = voteCount++;
        votes[newVoteId].title = _title;
        votes[newVoteId].endTime = _endTime;
        for (uint256 i = 0; i < _optionDescriptions.length; i++) {
            _createOption(newVoteId, _optionDescriptions[i]);
        }
        emit VoteCreated(newVoteId, _title);
    }

    function _createOption(uint256 _voteId, string memory _description) private {
        require(_voteId < voteCount, "Invalid vote ID.");
        require(block.timestamp < votes[_voteId].endTime, "Vote has ended.");

        Vote storage vote = votes[_voteId];
        uint256 newOptionId = vote.optionCount++;
        vote.options[newOptionId] = Option(_description, 0);
    }

    function voteVote(uint256 _voteId, uint256 _optionId) external {
        require(_voteId < voteCount, "Invalid vote ID.");
        require(block.timestamp < votes[_voteId].endTime, "Vote has ended.");

        Vote storage vote = votes[_voteId];
        require(_optionId < vote.optionCount, "Invalid option ID.");
        require(!vote.voters[msg.sender], "You have already voted.");

        Option storage option = vote.options[_optionId];
        option.voteCount++;
        vote.voters[msg.sender] = true;

        emit VoteCast(_voteId, _optionId);
    }

    function getVoteCount() external view returns (uint256) {
        return voteCount;
    }

    function getVote(uint256 _voteId) external view returns (string memory) {
        require(_voteId < voteCount, "Invalid vote ID.");

        Vote storage vote = votes[_voteId];
        return vote.title;
    }

    function getOptionCount(uint256 _voteId) external view returns (uint256) {
        require(_voteId < voteCount, "Invalid vote ID.");

        Vote storage vote = votes[_voteId];
        return vote.optionCount;
    }

    function getOption(uint256 _voteId, uint256 _optionId) external view returns (string memory, uint256) {
        require(_voteId < voteCount, "Invalid vote ID.");

        Vote storage vote = votes[_voteId];
        require(_optionId < vote.optionCount, "Invalid option ID.");

        Option memory option = vote.options[_optionId];
        return (option.description, option.voteCount);
    }

    function hasVoted(uint256 _voteId) external view returns (bool) {
        require(_voteId < voteCount, "Invalid vote ID.");

        Vote storage vote = votes[_voteId];
        return vote.voters[msg.sender];
    }
}