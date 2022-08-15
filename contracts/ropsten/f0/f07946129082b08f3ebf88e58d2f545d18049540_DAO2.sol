/**
 *Submitted for verification at Etherscan.io on 2022-08-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

error alreadyMember();
error notEnoughFee(uint256);
error notMember();
error alreadyExist();
error notDelegated();
error alreadyVoted_or_Canceled();
error notOwner();
error run_renounceOwnership_instead();

contract Ownable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        checkOwner();
        _;
    }

    function checkOwner() internal view {
        if (owner != msg.sender) {
            revert notOwner();
        }
    }

    function renounceOwnership() public onlyOwner {
        owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner == address(0)) {
            revert run_renounceOwnership_instead();
        }
        owner = newOwner;
    }
}

contract DAO2 is Ownable {
    struct Propasal {
        address payable to;
        uint256 amount;
        uint256 voteCount;
        bool executed;
        bool canceled;
    }

    uint256 public ProposalCount;
    uint256 public MemberCount;

    mapping(uint256 => Propasal) Proposals;
    mapping(address => bool) private Members;
    mapping(uint256 => mapping(address => bool)) Votes;

    constructor() payable {
        ProposalCount = 0;
        MemberCount = 0;
    }

    event newProposal(
        address indexed to,
        uint256 indexed value,
        string indexed description
    );
    event newMember(address indexed member_address);
    event voteCast(address indexed voter, uint256 proposalId);
    event proposalExecuted(
        address indexed to,
        uint256 indexed value,
        uint256 indexed proposalId
    );
    event proposalPassThreshold(uint indexed proposalId);

    function propasalThreshold() private view returns (uint256) {
        return MemberCount / uint256(2);
    }

    function isMember(address _address) public view returns (bool) {
        return Members[_address];
    }

    function addMember(address memberAddress) public onlyOwner {
        if (Members[memberAddress]) {
            revert alreadyMember();
        } else {
            Members[memberAddress] = true;
            emit newMember(memberAddress);
            MemberCount += 1;
        }
    }

    function cancelProposal(uint256 proposalId) public onlyOwner {
        Propasal storage proposal = Proposals[proposalId];
        proposal.canceled = true;
    }

    function isActive(uint256 proposalId) private view returns (bool) {
        Propasal storage proposal = Proposals[proposalId];
        return (!proposal.executed) || proposal.canceled;
    }

    function proposalHash(
        address to,
        uint256 value,
        string memory description
    ) public pure returns (uint256) {
        return uint256(keccak256(abi.encode(to, value, description)));
    }

    function submitProposal(
        address to,
        uint256 value,
        string memory description
    ) public returns (uint256) {
        if (!Members[msg.sender]) revert notMember();

        uint256 proposalId = proposalHash(to, value, description);
        Propasal storage proposal = Proposals[proposalId];

        if (proposal.to != address(0)) revert alreadyExist();

        proposal.to = payable(to);
        proposal.amount = value;
        ProposalCount += 1;

        emit newProposal(to, value, description);
        return proposalId;
    }

    function isExecutable(uint256 proposalId) private view returns (bool) {
        Propasal storage proposal = Proposals[proposalId];
        if (proposal.voteCount > propasalThreshold()) {
            return true;
        } else {
            return false;
        }
    }

    function castVote(uint256 proposalId, string memory declaration) public {
        Propasal storage proposal = Proposals[proposalId];
        if (isActive(proposalId)) {
            if (!Votes[proposalId][msg.sender]) {
                if (
                    keccak256(abi.encodePacked((declaration))) ==
                    keccak256(abi.encodePacked(("Approve")))
                ) {
                    Votes[proposalId][msg.sender] = true;
                    proposal.voteCount += 1;
                    emit voteCast(msg.sender, proposalId);
                    if (proposal.voteCount > propasalThreshold()) {
                        emit proposalPassThreshold(proposalId);
                    }
                } else {
                    revert notDelegated();
                }
            } else {
                revert alreadyVoted_or_Canceled();
            }
        }
    }

    function numberOfVotes(uint256 proposalId) public view returns (uint256) {
        Propasal storage proposal = Proposals[proposalId];
        return proposal.voteCount;
    }

    function execute(uint256 proposalId) public onlyOwner {
        require(
            isExecutable(proposalId),
            "Required number of votes not reached."
        );
        Propasal storage proposal = Proposals[proposalId];
        proposal.executed = true;

        (bool success, ) = (proposal.to).call{
            value: proposal.amount * (1 ether)
        }("");
        require(success);

        emit proposalExecuted(proposal.to, proposal.amount, proposalId);
    }
}