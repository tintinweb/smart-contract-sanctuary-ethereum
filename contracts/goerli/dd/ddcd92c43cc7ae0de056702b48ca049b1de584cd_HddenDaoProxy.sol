/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

// SPDX-License-Identifier: NONE

pragma solidity ^0.8.6;

contract HddenDaoEvents {
    /// @notice An event emitted when a new proposal is created
    event ProposalCreated(
        uint256 id,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startBlock,
        uint256 endBlock,
        string description
    );

    event ProposalCreatedWithRequirements(
        uint256 id,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startBlock,
        uint256 endBlock,
        uint256 proposalThreshold,
        uint256 quorumVotes,
        string description
    );

    /// @notice An event emitted when a vote has been cast on a proposal
    /// @param voter The address which casted a vote
    /// @param proposalId The proposal id which was voted on
    /// @param support Support value for the vote. 0=against, 1=for, 2=abstain
    /// @param votes Number of votes which were cast by the voter
    /// @param reason The reason given for the vote by the voter
    event VoteCast(address indexed voter, uint256 proposalId, uint8 support, uint256 votes, string reason);

    /// @notice An event emitted when a proposal has been canceled
    event ProposalCanceled(uint256 id);

    /// @notice An event emitted when a proposal has been queued in the HddenTreasury
    event ProposalQueued(uint256 id, uint256 eta);

    /// @notice An event emitted when a proposal has been executed in the HddenTreasury
    event ProposalExecuted(uint256 id);

    /// @notice An event emitted when a proposal has been vetoed by vetoAddress
    event ProposalVetoed(uint256 id);

    /// @notice An event emitted when the voting delay is set
    event VotingDelaySet(uint256 oldVotingDelay, uint256 newVotingDelay);

    /// @notice An event emitted when the voting period is set
    event VotingPeriodSet(uint256 oldVotingPeriod, uint256 newVotingPeriod);

    /// @notice Emitted when implementation is changed
    event NewImplementation(address oldImplementation, address newImplementation);

    /// @notice Emitted when proposal threshold basis points is set
    event ProposalThresholdBPSSet(uint256 oldProposalThresholdBPS, uint256 newProposalThresholdBPS);

    /// @notice Emitted when quorum votes basis points is set
    event QuorumVotesBPSSet(uint256 oldQuorumVotesBPS, uint256 newQuorumVotesBPS);

    /// @notice Emitted when pendingAdmin is changed
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /// @notice Emitted when pendingAdmin is accepted, which means admin is updated
    event NewAdmin(address oldAdmin, address newAdmin);

    /// @notice Emitted when vetoer is changed
    event NewVetoer(address oldVetoer, address newVetoer);
}

contract HddenStorage {
    /// @notice Administrator for this contract
    address public admin;

    /// @notice Pending administrator for this contract
    address public pendingAdmin;

    /// @notice Active brains of Governor
    address public implementation;
}
contract HddenDao is HddenStorage {
    /// @notice Vetoer who has the ability to veto any proposal
    address public vetoer;

    /// @notice The delay before voting on a proposal may take place, once proposed, in blocks
    uint256 public votingDelay;

    /// @notice The duration of voting on a proposal, in blocks
    uint256 public votingPeriod;

    /// @notice The basis point number of votes required in order for a voter to become a proposer. *DIFFERS from GovernerBravo
    uint256 public proposalThresholdBPS;

    /// @notice The basis point number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed. *DIFFERS from GovernerBravo
    uint256 public quorumVotesBPS;

    /// @notice The total number of proposals
    uint256 public proposalCount;

    IHddenTreasury public timelock;

    IHddenToken public hddentoken;

    mapping (uint256 => Proposal) public proposals;

    mapping(address => uint256) public latestProposalIds;

    struct Proposal {
        uint256 id;
        address proposer;
        uint256 proposalThreshold;
        uint256 quoromVotes;
        uint256 eta;
        address[] targets;
        uint256[] values;
        string[] signatures;
        bytes[] calldatas;
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        bool canceled;
        bool vetoed;
        bool executed;
        mapping(address => Receipt) receipts;
    }
    struct Receipt {
        bool hasVoted;
        uint8 support;
        uint96 votes;
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
interface IHddenTreasury {
    function delay() external view returns (uint256);

    function GRACE_PERIOD() external view returns (uint256);

    function acceptAdmin() external;

    function queuedTransactions(bytes32 hash) external view returns (bool);

    function queueTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) external returns (bytes32);

    function cancelTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) external;

    function executeTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) external payable returns (bytes memory);
}


interface IHddenToken {
    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint96);

    function totalSupply() external view returns (uint96);

}

contract HddenDaoProxy is HddenStorage, HddenDaoEvents {
    constructor(address timelock_, address hdden_, address vetoer_, address admin_, address implementation_, uint256 votingPeriod_, uint256 votingDelay_, uint256 proposalThresholdBPS_, uint256 quorumVotesBPS_) {
        admin = msg.sender;
        delegateTo(
            implementation_,
            abi.encodeWithSignature(
                '_initialize(address,address,address,uint256,uint256,uint256,uint256)',
                timelock_,
                hdden_,
                vetoer_,
                votingPeriod_,
                votingDelay_,
                proposalThresholdBPS_,
                quorumVotesBPS_
            )
        );

        _setImplementation(implementation_);

        admin = admin_;
    }

    function _setImplementation(address implementation_) public {
        require(msg.sender == admin, "admin only");
        require(implementation_ != address(0), "Invalid implementation address");

        address oldImplementation = implementation;
        implementation = implementation_;

        emit NewImplementation(oldImplementation, implementation);
    }

    function delegateTo(address callee, bytes memory data) internal {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
    }

    function _fallback() internal {
        (bool success, ) = implementation.delegatecall(msg.data);
        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())

            switch success
            case 0 {
                revert(free_mem_ptr, returndatasize())
            }
            default {
                return(free_mem_ptr, returndatasize())
            }
        }
    }
    fallback() external payable {
        _fallback();
    }
    receive() external payable {
        _fallback();
    }
}