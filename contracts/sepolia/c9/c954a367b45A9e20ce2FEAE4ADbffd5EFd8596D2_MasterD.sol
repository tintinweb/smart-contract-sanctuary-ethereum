// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./MasterDStorage.sol";
import "./Utils/DAOLib.sol";

contract MasterD {
    MasterDStorage MasterDStorageContract;

    address public mainContract;

    event ProposalCreated(uint256 id, address proposer);
    event VoteCast(address indexed voter, uint256 proposalId, uint8 support);
    event ProposalQueued(uint256 id, uint256 eta);

    function initializeStorage(address _MasterDStorage) public {
        MasterDStorageContract = MasterDStorage(_MasterDStorage);
    }

    function initializeMainContract(address _mainContract) public {
        mainContract = _mainContract;
    }

    // // /////////////////////////////////////////////////////////////// CREATE PROPOSAL TO MAKE CHANGE IN CONTRACT

    function proposeToMakeChangeInContract(
        // contracts
        address[] calldata targets,
        // msg.value
        uint256[] calldata values,
        // function signature
        bytes[] calldata signatures,
        //
        bytes[] calldata calldatas
    ) public returns (uint256) {
        // require that we will do any action with this proposal;
        require(targets.length != 0, "must provide actions");

        // we get last proposal id that provided by msg.sender;
        uint256 _latestProposalId = MasterDStorageContract.getLatestProposalIds(
            msg.sender
        );

        // if msg.sender has proposal; this proposal state should NOT be active;
        if (_latestProposalId != 0) {
            // get last proposal state from msg.sender
            DAOLib.ProposalState proposersLatestProposalState = MasterDStorageContract
                    .state(_latestProposalId);
            require(
                // last proposal of msg.sender should not be active;
                proposersLatestProposalState != DAOLib.ProposalState.Active,
                "found an already active proposal"
            );
            require(
                // last proposal of msg.sender should not be pending;
                proposersLatestProposalState != DAOLib.ProposalState.Pending,
                "found an already pending proposal"
            );
        }

        // save token total supply in memory struct;
        uint256 _tokenSupply = MasterDStorageContract.getTokenSupply();

        // proposal start time should be current block number + voting delay !
        // for exmple current block number is 1; voting delay is 10; start block for this proposal is 11;
        uint256 _startBlock = block.number +
            MasterDStorageContract.getVotingDelay();
        // voting end block will be proposla start block + voting period !
        uint256 _endBlock = _startBlock +
            MasterDStorageContract.getVotingPeriod();

        // we increase number of proposals
        MasterDStorageContract.increaseProposalID();

        // we create proposal in storage mapping; changes will directly save in storage;
        DAOLib.Proposal memory newProposal;

        // set proposal id;
        newProposal.id = MasterDStorageContract.proposalCount();
        // set proposer;
        newProposal.proposer = msg.sender;

        // how much votes in support we need to set proposal as succeeded;
        newProposal.quorumVotes = bps2Uint(
            MasterDStorageContract.getQuorumVotesBPS(),
            _tokenSupply
        );
        // this is timestamp that proposal will get executed by MasterDAO contract; we will set this when proposal get succeeded;
        newProposal.eta = 0;
        // this is list of targets that proposal will make change on them or will interact with them;
        newProposal.targets = targets;
        // this is list of values ; for example msg.value;s that in calls to targets we will user them;
        newProposal.values = values;
        // signature is signature of the function; for example propose function has sign of 2eeed88f;
        newProposal.signatures = signatures;
        // list of calldata that we will user in calls to target;s;
        newProposal.calldatas = calldatas;
        // proposal start block; this is current block + delay time to start vote;
        newProposal.startBlock = _startBlock;
        // time the vote for proposal will get close ! start block + voting period;
        newProposal.endBlock = _endBlock;
        // ************************************** this variable has default value ! we will test them
        // support at start;
        newProposal.forVotes = 0;
        // no votes at start;
        newProposal.againstVotes = 0;
        // - votes at start;
        newProposal.abstainVotes = 0;
        // proposal state for when it get canceled
        newProposal.canceled = false;
        // proposal state when it get executed
        newProposal.executed = false;
        // proposal start when it get vetoed;
        newProposal.vetoed = false;
        // ************************************** this variable has default value !

        MasterDStorageContract.setProposal(newProposal, newProposal.id);

        MasterDStorageContract.setLatestProposalIds(
            newProposal.proposer,
            newProposal.id
        );

        emit ProposalCreated(newProposal.id, msg.sender);

        return newProposal.id;
    }

    // // /////////////////////////////////////////////////////////////// VOTE

    function castVote(uint256 proposalId, uint8 support) external {
        castVoteInternal(msg.sender, proposalId, support);
    }

    function castVoteInternal(
        address voter,
        uint256 proposalId,
        uint8 support
    ) internal returns (uint256) {
        require(
            MasterDStorageContract.state(proposalId) ==
                DAOLib.ProposalState.Active,
            "voting is not started"
        );
        require(support <= 2, "castVoteInternal: invalid vote type");
        DAOLib.Proposal memory _newProposal = MasterDStorageContract
            .getProposal(proposalId);

        DAOLib.Receipt memory _newreceipt = MasterDStorageContract.getReceipt(
            proposalId,
            voter
        );
        require(
            _newreceipt.hasVoted == false,
            "castVoteInternal: voter already voted"
        );

        // ***********************************
        uint256 votes = MasterDStorageContract.getPastVotes(
            voter,
            _newProposal.startBlock - 1
        );
        // ***********************************

        if (votes > 0) {
            if (support == 0) {
                _newProposal.againstVotes = _newProposal.againstVotes + 1;
            } else if (support == 1) {
                _newProposal.forVotes = _newProposal.forVotes + 1;
            } else if (support == 2) {
                _newProposal.abstainVotes = _newProposal.abstainVotes + 1;
            }

            MasterDStorageContract.setProposal(_newProposal, proposalId);

            MasterDStorageContract.setReceipt(
                proposalId,
                voter,
                true,
                support,
                votes
            );

            emit VoteCast(voter, proposalId, support);
        }

        // return nummber of votes !
        return votes;
    }

    // // /////////////////////////////////////////////////////////////// TIMELOCK

    function queue(uint256 proposalId) external {
        require(
            MasterDStorageContract.state(proposalId) ==
                DAOLib.ProposalState.Succeeded,
            "queue: proposal can only be queued if it is succeeded"
        );

        DAOLib.Proposal memory proposal = MasterDStorageContract.getProposal(
            proposalId
        );

        uint256 eta = block.number + MasterDStorageContract.getDelay();

        for (uint256 i; i < proposal.targets.length; i++) {
            if (
                !MasterDStorageContract.getQueuedTransaction(
                    keccak256(abi.encode(proposal.targets[0], eta))
                )
            ) {
                queueTransaction(proposal.targets[i], eta);
            }
        }
        proposal.eta = eta;
        MasterDStorageContract.setProposal(proposal, proposalId);

        emit ProposalQueued(proposalId, eta);
    }

    function queueTransaction(
        address target,
        uint256 eta
    ) public returns (bytes32) {
        require(
            eta >= block.number + MasterDStorageContract.getDelay(),
            "Estimated execution block must satisfy delay."
        );

        bytes32 txHash = keccak256(abi.encode(target, eta));
        MasterDStorageContract.setQueuedTransaction(txHash, true);

        return txHash;
    }

    // // /////////////////////////////////////////////////////////////// EXCUTE

    function executeTransaction(uint256 _proposalID) external returns (bool) {
        DAOLib.Proposal memory _newProposal = MasterDStorageContract
            .getProposal(_proposalID);

        require(
            MasterDStorageContract.state(_proposalID) ==
                DAOLib.ProposalState.Queued,
            "1"
        );

        require(
            block.number <=
                _newProposal.eta + MasterDStorageContract.GRACE_PERIOD(),
            "2"
        );

        require(block.number >= _newProposal.eta, "eta is not reached");

        for (uint256 i; i < _newProposal.targets.length; i++) {
            require(
                execute(
                    _newProposal.targets[i],
                    _newProposal.signatures[i],
                    _newProposal.eta
                ),
                "4"
            );
        }

        return true;
    }

    function execute(
        address _target,
        bytes memory _signatures,
        uint256 _eta
    ) internal returns (bool) {
        bytes32 txHash = keccak256(abi.encode(_target, _eta));

        require(
            MasterDStorageContract.getQueuedTransaction(txHash) == true,
            "111"
        );

        (bool Ok, ) = mainContract.call{value: 0}(_signatures);
        require(Ok, "final");
        return true;
    }

    // // /////////////////////////////////////////////////////////////// GETTER
    function bps2Uint(
        uint256 bps,
        uint256 number
    ) internal pure returns (uint256) {
        return (number * bps) / 10000;
    }

    receive() external payable {}

    fallback() external payable {}
}

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