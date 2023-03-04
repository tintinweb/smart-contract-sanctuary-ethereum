// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract DVoting {
    // structs: Polls created
    struct Poll {
        uint256 pollId;
        string title;
        string[4] options; // contains 4 options
        address owner;
        uint256 createdAt;
        string banner;
        address[] voters;
        uint256 votersCount;
        uint256 votesOption0;
        uint256 votesOption1;
        uint256 votesOption2;
        uint256 votesOption3;
    }

    // events
    event PollCreated(
        uint256 indexed pollId,
        string title,
        string[4] options,
        string banner,
        address indexed owner,
        uint256 indexed createdAt
    );

    event VoteCreated(
        uint256 indexed pollId,
        address indexed voter,
        uint256 indexed votedAt
    );

    // modifier
    modifier pollExists(uint256 pollId) {
        address testingOwner = polls[pollId].owner;
        require(testingOwner != address(0), "Poll doesn't exist.");
        _;
    }

    // variables:
    uint256 nextPollId; // keep tracks of the next poll id which will be assigned to the next poll created;

    mapping(uint256 => Poll) public polls; // keep tracks of the polls created

    // functions
    function createPoll(
        string memory _title,
        string[4] memory _options,
        string memory _banner
    ) public payable {
        require(msg.value == 0.001 ether, "Please send sufficient ethers.");
        require(
            checkArrayItemEmptiness(getArray(_options)),
            "Each option should have atleast 2 characters."
        );
        require(
            checkEmptiness(_title, 10),
            "Title should be at least 10 characters."
        );
        // banner can only be checked by the frontend

        Poll storage poll = polls[nextPollId];

        poll.pollId = nextPollId;
        poll.title = _title;
        poll.banner = _banner;
        poll.options = _options;
        poll.createdAt = block.timestamp;
        poll.owner = msg.sender;

        nextPollId++;

        emit PollCreated(
            poll.pollId,
            poll.title,
            poll.options,
            poll.banner,
            poll.owner,
            poll.createdAt
        );
    }

    function getPolls() public view returns (Poll[] memory) {
        Poll[] memory returnablePolls = new Poll[](nextPollId);
        for (uint256 idx = 0; idx < nextPollId; idx++) {
            returnablePolls[idx] = polls[idx];
        }
        return returnablePolls;
    }

    function getPollDetails(uint256 pollId)
        public
        view
        pollExists(pollId)
        returns (Poll memory)
    {
        return polls[pollId];
    }

    function vote(uint256 pollId, uint8 optionIndex) public pollExists(pollId) {
        Poll storage poll = polls[pollId]; // reference

        require(msg.sender != poll.owner, "You can't vote your own poll.");

        require(!alreadyVoted(pollId, msg.sender), "You have already voted.");

        if (optionIndex == 0) {
            poll.votesOption0++;
        } else if (optionIndex == 1) {
            poll.votesOption1++;
        } else if (optionIndex == 2) {
            poll.votesOption2++;
        } else if (optionIndex == 3) {
            poll.votesOption3++;
        }

        poll.votersCount++;
        poll.voters.push(msg.sender);

        emit VoteCreated(poll.pollId, msg.sender, block.timestamp);
    }

    // utility functions
    function checkEmptiness(string memory item, uint256 minLimit)
        private
        pure
        returns (bool)
    {
        if (bytes(item).length > minLimit) {
            return true;
        } else {
            return false;
        }
    }

    function checkArrayItemEmptiness(string[] memory items)
        private
        pure
        returns (bool)
    {
        for (uint256 idx; idx < items.length; idx++) {
            if (checkEmptiness(items[idx], 1) == false) {
                return false;
            }
        }

        return true;
    }

    function getArray(string[4] memory fixedArray)
        public
        pure
        returns (string[] memory)
    {
        string[] memory dynamicArray = new string[](fixedArray.length);
        for (uint256 i = 0; i < fixedArray.length; i++) {
            dynamicArray[i] = fixedArray[i];
        }
        return dynamicArray;
    }

    function alreadyVoted(uint256 pollId, address voter)
        private
        view
        returns (bool)
    {
        address[] memory alreadyVoters = polls[pollId].voters;

        for (uint256 idx; idx < alreadyVoters.length; idx++) {
            if (alreadyVoters[idx] == voter) {
                return true;
            }
        }

        return false;
    }
}