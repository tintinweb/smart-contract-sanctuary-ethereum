//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// solhint-disable reason-string
contract CollectorDao {
    string public constant NAME = "collector-dao";

    uint8 public constant PROPOSAL_MAX_OPERATIONS = 10;
    uint8 public constant QUORUM_THRESHOLD = 250; // 25%
    uint16 public constant QUORUM_DIVISOR = 1000;
    uint32 public constant VOTING_PERIOD = 80640; // About 2 weeks
    uint256 public constant MEMBERSHIP_PRICE = 1 ether;

    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );
    bytes32 public constant BALLOT_TYPEHASH =
        keccak256("Vote(uint256 proposalId,bool support)");

    mapping(uint256 => Proposal) public proposals;

    mapping(address => bool) public isMember;
    uint256 public membersCount;

    enum ProposalState {
        ACTIVE,
        PASSED,
        EXECUTED,
        FAILED,
        EXPIRED
    }

    struct Proposal {
        uint256 id;
        address proposer;
        uint32 endTime;
        uint128 forVotes;
        uint128 againstVotes;
        bool executed;
        mapping(address => bool) hasVoted;
    }

    modifier onlyMember(address _address) {
        require(isMember[_address] == true, "CollectorDao::Not a member");
        _;
    }

    function state(uint256 _proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[_proposalId];

        if (proposal.executed) return ProposalState.EXECUTED;

        if (_timeNow() <= proposal.endTime) return ProposalState.ACTIVE;

        if (
            _timeNow() > proposal.endTime &&
            ((proposal.forVotes + proposal.againstVotes) >=
                (membersCount * QUORUM_THRESHOLD) / QUORUM_DIVISOR) &&
            proposal.forVotes > proposal.againstVotes
        ) return ProposalState.PASSED;

        if (
            _timeNow() > proposal.endTime &&
            ((proposal.forVotes + proposal.againstVotes) >=
                (membersCount * QUORUM_THRESHOLD) / QUORUM_DIVISOR) &&
            proposal.forVotes < proposal.againstVotes
        ) return ProposalState.FAILED;

        return ProposalState.EXPIRED;
    }

    function buyMembership() external payable {
        require(
            msg.value >= MEMBERSHIP_PRICE,
            "CollectorDao::Insufficient ether value"
        );
        require(isMember[msg.sender] != true, "CollectorDao::Already a member");
        isMember[msg.sender] = true;
        membersCount++;
    }

    function propose(
        address[] memory _targets,
        uint256[] memory _values,
        bytes[] memory _calldatas,
        bytes32 _descriptionHash
    ) external onlyMember(msg.sender) returns (uint256) {
        require(
            _targets.length == _values.length &&
                _targets.length == _calldatas.length,
            "CollectorDao::mismatch lengths"
        );
        require(
            _targets.length <= PROPOSAL_MAX_OPERATIONS,
            "CollectorDao::too many action"
        );
        require(_targets.length != 0, "CollectorDao::empty action");

        uint256 proposalId = hashProposal(
            _targets,
            _values,
            _calldatas,
            _descriptionHash
        );
        require(
            (state(proposalId) != ProposalState.ACTIVE) &&
                (state(proposalId) != ProposalState.FAILED) &&
                (state(proposalId) != ProposalState.EXECUTED),
            "CollectorDao::proposal already exists"
        );

        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.proposer = msg.sender;
        newProposal.endTime = _timeNow() + VOTING_PERIOD;

        emit Proposed(proposalId, msg.sender);

        return newProposal.id;
    }

    function execute(
        address[] memory _targets,
        uint256[] memory _values,
        bytes[] memory _calldatas,
        bytes32 _descriptionHash
    ) external onlyMember(msg.sender) {
        uint256 proposalId = hashProposal(
            _targets,
            _values,
            _calldatas,
            _descriptionHash
        );
        require(
            (state(proposalId) == ProposalState.PASSED),
            "CollectorDao::Proposal not passed"
        );

        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;

        for (uint256 i = 0; i < _targets.length; i++) {
            (bool success, ) = _targets[i].call{value: _values[i]}(
                _calldatas[i]
            );
            require(success, "CollectorDao::Execution failed");
        }

        emit Executed(proposalId);
    }

    function castVoteBySig(
        uint256 _proposalId,
        bool _support,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(NAME)),
                _getChainId(),
                address(this)
            )
        );
        bytes32 structHash = keccak256(
            abi.encode(BALLOT_TYPEHASH, _proposalId, _support)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );

        address signatory = ecrecover(digest, _v, _r, _s);

        require(
            signatory != address(0),
            "GovernorBravo::castVoteBySig: invalid signature"
        );
        _castVote(signatory, _proposalId, _support);
    }

    function castVoteBySigMultiple(
        uint256[] memory proposalId,
        bool[] memory support,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external {
        for (uint256 i = 0; i < proposalId.length; i++) {
            castVoteBySig(proposalId[i], support[i], v[i], r[i], s[i]);
        }
    }

    function _castVote(
        address _voter,
        uint256 _proposalId,
        bool _support
    ) private onlyMember(_voter) {
        require(
            state(_proposalId) == ProposalState.ACTIVE,
            "CollectorDao::not active"
        );
        require(
            !proposals[_proposalId].hasVoted[_voter],
            "CollectorDao::already voted"
        );
        Proposal storage proposal = proposals[_proposalId];

        if (_support) proposal.forVotes++;
        else proposal.againstVotes++;

        proposal.hasVoted[_voter] = true;

        emit Voted(_proposalId, _voter, _support);
    }

    function hashProposal(
        address[] memory _targets,
        uint256[] memory _values,
        bytes[] memory _calldatas,
        bytes32 _descriptionHash
    ) public pure returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(_targets, _values, _calldatas, _descriptionHash)
                )
            );
    }

    function _getChainId() private view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

    function _timeNow() private view returns (uint32) {
        return uint32(block.timestamp);
    }

    event Voted(uint256 indexed _proposalId, address _voter, bool _support);
    event Proposed(uint256 indexed _proposalId, address _proposer);
    event Executed(uint256 indexed _proposalId);
}
// solhint-enable reason-string