// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

error ContributionEnded();
error NotEnoughShare();
error NotEnoughFund();
error CannotVoteTwice();
error ProposalEnded();
error ProposalNotEnded();
error AlreadyExecuted();
error QuorumNotFulfilled();
error OnlyInvestor();
error OnlyAdmin();

contract DAO {
    struct Proposal {
        uint256 id;
        string name;
        uint256 amount;
        address payable recipient;
        uint256 votes;
        uint256 end;
        bool executed;
    }

    uint256 public nextProposalId;
    uint256 private voteTime;
    uint256 private quorum;
    uint256 private totalShares;
    uint256 private availableFunds;
    uint256 private contributionEnd;

    address private admin;

    mapping(uint256 => Proposal) private proposals;
    mapping(address => bool) private investors;
    mapping(address => uint256) private shares;
    mapping(address => mapping(uint256 => bool)) public votes;

    modifier onlyInvestors() {
        if (investors[msg.sender] != true) {
            revert OnlyInvestor();
        }
        _;
    }
    modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert OnlyAdmin();
        }
        _;
    }

    constructor(
        uint256 contributionTime,
        uint256 _voteTime,
        uint256 _quorum
    ) {
        contributionEnd = block.timestamp + contributionTime;
        voteTime = _voteTime;
        quorum = _quorum;
        admin = msg.sender;
    }

    receive() external payable {
        availableFunds += msg.value;
    }

    function contribute() external payable {
        if (block.timestamp > contributionEnd) {
            revert ContributionEnded();
        }
        investors[msg.sender] = true;
        shares[msg.sender] += msg.value;
        totalShares += msg.value;
        availableFunds += msg.value;
    }

    function redeemShare(uint256 amount) external {
        if (shares[msg.sender] < amount) {
            revert NotEnoughShare();
        }
        if (availableFunds < amount) {
            revert NotEnoughFund();
        }
        shares[msg.sender] -= amount;
        availableFunds -= amount;
        msg.sender.call{value: amount};
    }

    function transferShare(uint256 amount, address to) external {
        if (shares[msg.sender] < amount) {
            revert NotEnoughShare();
        }
        shares[msg.sender] -= amount;
        shares[to] += amount;
        investors[to] = true;
    }

    function createProposal(
        string memory name,
        uint256 amount,
        address payable recepient
    ) external {
        if (availableFunds < amount) {
            revert NotEnoughFund();
        }
        proposals[nextProposalId] = Proposal(
            nextProposalId,
            name,
            amount,
            recepient,
            0,
            (block.timestamp + voteTime),
            false
        );
        availableFunds -= amount;
        nextProposalId++;
    }

    function vote(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        if (votes[msg.sender][proposalId] != false) {
            revert CannotVoteTwice();
        }
        if (block.timestamp > proposal.end) {
            revert ProposalEnded();
        }
        votes[msg.sender][proposalId] = true;
        proposal.votes += shares[msg.sender];
    }

    function executeProposal(uint256 proposalId) external onlyAdmin {
        Proposal storage proposal = proposals[proposalId];
        if (block.timestamp < proposal.end) {
            revert ProposalNotEnded();
        }
        if (proposal.executed != false) {
            revert AlreadyExecuted();
        }
        if ((proposal.votes / totalShares) * 100 < quorum) {
            revert QuorumNotFulfilled();
        }
        proposal.executed = true;
        _transferEther(proposal.amount, proposal.recipient);
    }

    function withdrawEther(uint256 amount, address payable to)
        external
        onlyAdmin
    {
        _transferEther(amount, to);
    }

    function _transferEther(uint256 amount, address payable to) internal {
        if (amount > availableFunds) {
            revert NotEnoughFund();
        }
        availableFunds -= amount;
        to.transfer(amount);
    }

    function getSharesOfAddress(address shareHolder)
        public
        view
        returns (uint256)
    {
        return shares[shareHolder];
    }

    function getVoteTime() public view returns (uint256) {
        return voteTime;
    }

    function getQuorum() public view returns (uint256) {
        return quorum;
    }

    function getTotalShares() public view returns (uint256) {
        return totalShares;
    }

    function getShares(address _holder) public view returns (uint256) {
        return shares[_holder];
    }

    function getAvailableFunds() public view returns (uint256) {
        return availableFunds;
    }

    function getContributionEnd() public view returns (uint256) {
        return contributionEnd;
    }

    function getAdmin() public view returns (address) {
        return admin;
    }

    function getProposals(uint256 proposalId)
        public
        view
        returns (Proposal memory)
    {
        return proposals[proposalId];
    }

    function getInvestor(address investorAddress) public view returns (bool) {
        return investors[investorAddress];
    }
}