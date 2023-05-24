// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./Utils/DAOLib.sol";

interface TokenInterface {
    function getPastVotes(
        address account,
        uint256 blockNumber
    ) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

interface contractInterface {
    function owner() external view returns (address);
}

contract MasterDStorage {
    uint256 public constant GRACE_PERIOD = 200;

    uint256 public delay;
    uint256 public proposalCount;
    uint256 public votingDelay;
    uint256 public votingPeriod;
    uint256 public quorumVotesBPS;

    //;
    address public erc20VoteToken;

    // mapping from proposal id to proposal struct
    mapping(uint256 => DAOLib.Proposal) public proposals;
    // mapping from user address to proposal
    mapping(address => uint256) public latestProposalIds;
    // mapping from proposal id to user vote state
    mapping(uint256 => mapping(address => DAOLib.Receipt)) receipts;
    // mapping to find what transactions are ready to execute
    mapping(bytes32 => bool) public queuedTransactions;

    // // /////////////////////////////////////////////////////////////// SETTER FUNCTION;
    function seterc20VoteToken(address _erc20VoteToken) public returns (bool) {
        erc20VoteToken = _erc20VoteToken;
        return true;
    }

    function setQueuedTransaction(
        bytes32 _TXHash,
        bool _state
    ) external returns (bool) {
        queuedTransactions[_TXHash] = _state;
        return true;
    }

    function increaseProposalID() public {
        proposalCount++;
    }

    function setDelay(uint256 _delay) public returns (bool) {
        delay = _delay;
        return true;
    }

    function setVotingDelay(uint256 _votingDelay) public returns (bool) {
        votingDelay = _votingDelay;
        return true;
    }

    function setVotingPeriod(uint256 _votingPeriod) public returns (bool) {
        votingPeriod = _votingPeriod;
        return true;
    }

    function setQuorumVotesBPS(uint256 _quorumVotesBPS) public returns (bool) {
        quorumVotesBPS = _quorumVotesBPS;
        return true;
    }

    function setProposal(
        DAOLib.Proposal calldata _newProposal,
        uint256 _proposalID
    ) external returns (bool) {
        proposals[_proposalID] = _newProposal;
        return true;
    }

    function setLatestProposalIds(
        address _userAddress,
        uint256 _proposalID
    ) external returns (bool) {
        latestProposalIds[_userAddress] = _proposalID;
        return true;
    }

    function setReceipt(
        uint256 _proposalID,
        address _voter,
        bool _hasVoted,
        uint8 _support,
        uint256 _votes
    ) external returns (bool) {
        DAOLib.Receipt memory _newReceipt;

        _newReceipt.hasVoted = _hasVoted;
        _newReceipt.support = _support;
        _newReceipt.votes = _votes;

        receipts[_proposalID][_voter] = _newReceipt;

        return true;
    }

    // // /////////////////////////////////////////////////////////////// GETTER FUNCTION;

    function getQueuedTransaction(
        bytes32 _TXHash
    ) external view returns (bool) {
        return queuedTransactions[_TXHash];
    }

    function getReceipt(
        uint256 _proposalID,
        address _voter
    ) external view returns (DAOLib.Receipt memory) {
        DAOLib.Receipt memory _newReceipt;
        _newReceipt = receipts[_proposalID][_voter];
        return _newReceipt;
    }

    function getProposal(
        uint256 _proposalID
    ) public view returns (DAOLib.Proposal memory) {
        DAOLib.Proposal memory proposal;
        proposal = proposals[_proposalID];
        return proposal;
    }

    function getQuorumVotesBPS() public view returns (uint256) {
        return quorumVotesBPS;
    }

    function state(
        uint256 proposalId
    ) public view returns (DAOLib.ProposalState) {
        // we check that proposal id is valid with proposal total number;
        require(proposalCount >= proposalId, "state: invalid proposal id");

        // get instance of proposal;
        DAOLib.Proposal storage proposal = proposals[proposalId];
        // if proposal is vetoed;
        if (proposal.vetoed) {
            return DAOLib.ProposalState.Vetoed;
            //
            // if proposal is canceled;
        } else if (proposal.canceled) {
            return DAOLib.ProposalState.Canceled;
            //
            // we check block number and if current block number is lower than proposal start ; so proposal is not started yet; and pending;
        } else if (block.number <= proposal.startBlock) {
            return DAOLib.ProposalState.Pending;
            //
            // we check block number and if current block number islower that proposal end block; so proposal is running and active;;
        } else if (block.number <= proposal.endBlock) {
            return DAOLib.ProposalState.Active;
            //
            // we check proposal for vote to againstVotes and proposal for votes to maximum votes that we need to pass proposal as succeeded(quorumVotes);
            // if yes votes is lower than no votes and we didn't reached quorumVotes; proposal is Defeated :(
        } else if (
            proposal.forVotes <= proposal.againstVotes ||
            proposal.forVotes < proposal.quorumVotes
        ) {
            return DAOLib.ProposalState.Defeated;
            //
            // if proposal execution time is 0; proposal is succeeded; but we need for votes > againstVotes and for votes > quorumVotes;
        } else if (proposal.eta == 0) {
            return DAOLib.ProposalState.Succeeded;
            //
            // when proposal is executed;
        } else if (proposal.executed) {
            return DAOLib.ProposalState.Executed;
            //
            // when proposal is Expired;
        } else if (block.number >= proposal.eta + GRACE_PERIOD) {
            return DAOLib.ProposalState.Expired;
            //
            // when proposal is Queued;
        } else {
            return DAOLib.ProposalState.Queued;
        }
    }

    function getProposalCount() public view returns (uint256) {
        return proposalCount;
    }

    function getVotingDelay() public view returns (uint256) {
        return votingDelay;
    }

    function getVotingPeriod() public view returns (uint256) {
        return votingPeriod;
    }

    function getPastVotes(
        address account,
        uint256 blockNumber
    ) external view returns (uint256) {
        return
            TokenInterface(erc20VoteToken).getPastVotes(account, blockNumber);
    }

    function getTokenSupply() external view returns (uint256) {
        return TokenInterface(erc20VoteToken).totalSupply();
    }

    function getContractOwner(
        address _contractAddress
    ) external view returns (address) {
        return contractInterface(_contractAddress).owner();
    }

    function getLatestProposalIds(
        address _userAddress
    ) external view returns (uint256) {
        return latestProposalIds[_userAddress];
    }

    function getDelay() external view returns (uint256) {
        return delay;
    }

    function getMatchStateProposals(
        uint256 _matchState
    ) public view returns (DAOLib.Proposal[] memory) {
        uint256 allProposals = proposalCount;
        uint256 allMatchProposals;

        for (uint i; i <= allProposals; ++i) {
            if (uint256(state(i)) == _matchState) {
                allMatchProposals = allMatchProposals + 1;
            }
        }

        DAOLib.Proposal[] memory matchProposalsArray = new DAOLib.Proposal[](
            allMatchProposals
        );
        uint256 currentIndex = 0;

        for (uint i; i <= allProposals; ++i) {
            if (uint256(state(i)) == _matchState) {
                matchProposalsArray[currentIndex] = proposals[i];
                currentIndex = currentIndex + 1;
            }
        }

        return matchProposalsArray;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library DAOLib {
    struct Proposal {
        uint256 id;
        address proposer;
        uint256 quorumVotes;
        uint256 eta;
        address[] targets;
        uint256[] values;
        bytes[] signatures;
        bytes[] calldatas;
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        bool canceled;
        bool vetoed;
        bool executed;
    }

    ///  Ballot receipt record for a voter
    struct Receipt {
        ///  Whether or not a vote has been cast
        bool hasVoted;
        ///  Whether or not the voter supports the proposal or abstains
        uint8 support;
        ///  The number of votes the voter had, which were cast
        uint256 votes;
    }

    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed,
        Vetoed
    }
}