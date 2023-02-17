//SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;

import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./ERC20.sol";

contract SafuBetsDao is ReentrancyGuard, AccessControl {
    bytes32 public constant MEMBER = keccak256("MEMBER");
    uint256 public immutable votingPeriod = 7 days;
    uint256 public proposalCount;
    uint256 public memberCount;
    // owner of the contract
    address public admin;
    // sbetToken token
    ERC20 public sbetToken;

    struct Proposal {
        uint256 id;
        uint256 livePeriod;
        uint256 voteInFavor;
        uint256 voteAgainst;
        string title;
        string desc;
        bool isCompleted;
        address proposer;
    }

    mapping(uint256 => Proposal) private proposals;
    mapping(address => uint256) private members;
    mapping(address => uint256[]) private votes;

    modifier onlyMembers(string memory message) {
        require(hasRole(MEMBER, msg.sender), message);
        _;
    }

    constructor(ERC20 _sbetToken) {
        admin = msg.sender;
        sbetToken = _sbetToken;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Ownable: caller is not the owner");
        _;
    }

    event newProposal(address proposer, uint256 proposalId);

    function createProposal(string memory title, string memory desc)
        external
        onlyMembers("Only Members can create proposals")
    {
        uint256 proposalId = proposalCount;
        Proposal storage proposal = proposals[proposalId];
        proposal.id = proposalId;
        proposal.title = title;
        proposal.desc = desc;
        proposal.proposer = payable(msg.sender);
        proposal.livePeriod = block.timestamp + votingPeriod;
        proposal.isCompleted = false;
        proposalCount++;
        emit newProposal(msg.sender, proposalId);
    }

    function getAllProposals() public view returns (Proposal[] memory) {
        Proposal[] memory allProposals = new Proposal[](proposalCount);
        for (uint256 i = 0; i < proposalCount; i++) {
            allProposals[i] = proposals[i];
        }
        return allProposals;
    }

    function getProposal(uint256 proposalId)
        public
        view
        returns (Proposal memory)
    {
        return proposals[proposalId];
    }

    function getVotes() public view returns (uint256[] memory) {
        return votes[msg.sender];
    }

    function isMember() public view returns (bool) {
        return members[msg.sender] > 0;
    }

    function vote(uint256 proposalId, bool inFavour) external nonReentrant {
        require(
            sbetToken.balanceOf(msg.sender) > 100_000 * 1e18,
            "Only sbetToken holders with balance more than or equal to 100k tokens can vote!"
        );
        Proposal storage proposal = proposals[proposalId];
        if (proposal.isCompleted || proposal.livePeriod <= block.timestamp) {
            proposal.isCompleted = true;
            revert("Time period for this proposal is ended");
        }

        for (uint256 i = 0; i < votes[msg.sender].length; i++) {
            if (proposal.id == votes[msg.sender][i]) {
                revert("You can only vote once");
            }
        }

        uint256 numberOfVotes = sbetToken.balanceOf(msg.sender) / 1e18;

        if (inFavour) proposal.voteInFavor += numberOfVotes;
        else proposal.voteAgainst += numberOfVotes;
        votes[msg.sender].push(proposalId);
    }

    function addMembers(address _member) external onlyAdmin {
        memberCount++;
        _setupRole(MEMBER, _member);
    }

    // Withdraw function for the contract owner to withdraw accumulated ERC20 tokens
    function withdrawOtherTokens(ERC20 token) external onlyAdmin {
        uint256 withdrawableBal = token.balanceOf(address(this));
        // Ensure that the contract has enough token balance
        require(withdrawableBal >= 0, "Insufficient BUSD balance");
        // Transfer the tokens to the contract owner
        require(token.transfer(msg.sender, withdrawableBal), "Transfer failed");
    }
}