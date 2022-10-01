// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

contract DAO {
    error CannotVoteOwnPolling();
    error CannotVoteMoreThanOnce();
    error NotMember();
    error CannotCancelVoteBeforeVote();

    event PollingAdded(address indexed pollingOwner, uint256 indexed pollingId);
    event Voted(
        address indexed voter,
        address indexed pollingOwner,
        uint256 currentVotesAmount,
        uint256 currentTotalVoteAmount,
        uint256 reputation
    );
    event VoteCanceled(
        address indexed voter,
        address indexed pollingOwner,
        uint256 currentVotesAmount,
        uint256 currentTotalVoteAmount,
        uint256 reputation
    );

    struct Polling {
        string subject;
        uint256 id;
        address owner;
        uint256 votesTotalValue;
        uint256 votesAmount;
    }

    mapping(address => bool) public members;
    mapping(uint256 => Polling) pollingRegistry;
    mapping(address => uint256) reputations;
    mapping(address => mapping(uint256 => bool)) voteRegistry;

    function Vote(uint256 pollingId) public {
        Polling memory polling = pollingRegistry[pollingId];
        if (!members[msg.sender]) {
            revert NotMember();
        }
        if (polling.owner == msg.sender) {
            revert CannotVoteOwnPolling();
        }
        if (voteRegistry[msg.sender][pollingId]) {
            revert CannotVoteMoreThanOnce();
        }

        polling.votesTotalValue += reputations[msg.sender];
        polling.votesAmount += 1;
        voteRegistry[msg.sender][pollingId] = true;
        emit Voted(
            msg.sender,
            polling.owner,
            polling.votesAmount,
            polling.votesTotalValue,
            reputations[msg.sender]
        );
    }

    function CancelVote(uint256 pollingId) public {
        Polling memory polling = pollingRegistry[pollingId];
        if (!members[msg.sender]) {
            revert NotMember();
        }
        if (polling.owner == msg.sender) {
            revert CannotVoteOwnPolling();
        }
        if (!voteRegistry[msg.sender][pollingId]) {
            revert CannotCancelVoteBeforeVote();
        }

        polling.votesTotalValue -= reputations[msg.sender];
        polling.votesAmount -= 1;
        voteRegistry[msg.sender][pollingId] = true;
    }

    function CreatePolling(
        string memory subject,
        uint256 id,
        address owner
    ) public {
        if (!members[msg.sender]) {
            revert NotMember();
        }

        Polling memory polling = Polling({
            subject: subject,
            id: id,
            owner: msg.sender,
            votesTotalValue: 0,
            votesAmount: 0
        });
        pollingRegistry[id] = polling;

        emit PollingAdded(msg.sender, id);
    }
    // cuzdan kontrolu
    // proposal
    // oylanma
    // oylanma suresi
    // proposal devreye girme suresi
    // isteyen proposal yayinlayabilir -> belli bir kurali olacak
}