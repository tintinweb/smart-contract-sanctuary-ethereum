/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

pragma solidity ^0.8.1;
interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}
contract Ownable {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    constructor() {
        _transferOwnership(_msgSender());
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
interface IALGP {
    function getPastVotes(address account, uint256 blockNumber)
        external
        view
        returns (uint256);
    function checkStaker(address account) external returns (bool);
}
contract Ballot is Ownable {
    struct Proposal {
        bool isCancel;
        bool isExecute;
        uint256 id;
        uint256 amount;
        uint256 currentBlock;
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        address owner;
        address target;
    }
    struct Receipt {
        bool isVote;
        uint8 support;
        uint256 votes;
    }
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Queued,
        Executed
    }
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => Receipt)) public receipts;
    uint256 public proposalTotal;
    uint256 public proposalExecuted;
    mapping(address => uint256) public latestProposalIds;
    uint256 public votingDelay;
    uint256 public votingPeriod;
    address public manager;
    IALGP private _aLGP;
    event ProposalCreated(
        uint256 id,
        address owner,
        address target,
        uint256 startBlock,
        uint256 endBlock,
        string description
    );
    event ProposalCanceled(uint256 proposalId);
    event ProposalExecuted(uint256 proposalId);
    event VoteCast(
        address indexed voter,
        uint256 proposalId,
        uint8 support,
        uint256 votes,
        string reason
    );
    receive() external payable {}
    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    constructor() {
        manager = 0x1Df6Bcef949B52192D04923d59e630f7F5ca5E88;
        _aLGP = IALGP(0x496EaBf0571eFecbD4e8BBcf47EdA7144972f25e);
        votingDelay = 432000;
        votingPeriod = 288000;
    }
    function setManager(address account) public {
        if (manager == _msgSender()) {
            manager = account;
        }
    }
    function setConfig(
        uint256 delay,
        uint256 period,
        address aLGP
    ) public onlyOwner {
        votingDelay = delay;
        votingPeriod = period;
        _aLGP = IALGP(aLGP);
    }
    function getExecuteNext() public view returns (Proposal memory proposal) {
        for (uint256 i = proposalExecuted; i < proposalTotal; i++) {
            if (state(i) == ProposalState.Queued) {
                proposal = proposals[i];
                break;
            }
        }
    }
    function state(uint256 proposalId) public view returns (ProposalState) {
        require(proposalTotal >= proposalId, "invalid proposal id");
        Proposal memory proposal = proposals[proposalId];
        if (proposal.isCancel) {
            return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (
            proposal.forVotes <
            ((proposal.againstVotes + proposal.forVotes) * 6) / 10
        ) {
            return ProposalState.Defeated;
        } else if (proposal.isExecute) {
            return ProposalState.Executed;
        } else {
            return ProposalState.Queued;
        }
    }
    function propose(
        address target,
        uint256 amount,
        string memory description
    ) public returns (uint256) {
        require(_aLGP.checkStaker(msg.sender), "propose: only top staker");
        require(target != address(0), "propose: must provide actions");
        require(amount >= 1e18 && amount <= 15e18, "propose: amount error");
        uint256 latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId != 0) {
            ProposalState lastState = state(latestProposalId);
            require(
                lastState != ProposalState.Active,
                "propose: one live proposal per proposer, found an already active proposal"
            );
            require(
                lastState != ProposalState.Pending,
                "propose: one live proposal per proposer, found an already pending proposal"
            );
        }
        uint256 startBlock = block.number + votingDelay;
        uint256 endBlock = startBlock + votingPeriod;
        proposalTotal++;
        Proposal storage newProposal = proposals[proposalTotal];
        newProposal.id = proposalTotal;
        newProposal.amount = amount;
        newProposal.owner = msg.sender;
        newProposal.target = target;
        newProposal.currentBlock = block.number;
        newProposal.startBlock = startBlock;
        newProposal.endBlock = endBlock;
        newProposal.forVotes = 0;
        newProposal.againstVotes = 0;
        newProposal.abstainVotes = 0;
        newProposal.isCancel = false;
        newProposal.isExecute = false;
        latestProposalIds[newProposal.owner] = newProposal.id;
        emit ProposalCreated(
            newProposal.id,
            msg.sender,
            target,
            startBlock,
            endBlock,
            description
        );
        return newProposal.id;
    }
    function cancel(uint256 proposalId) public {
        require(
            state(proposalId) != ProposalState.Executed,
            "cancel: cannot cancel executed proposal"
        );
        Proposal storage proposal = proposals[proposalId];
        require(
            msg.sender == proposal.owner,
            "cancel: Other user cannot cancel proposal"
        );
        proposal.isCancel = true;
        emit ProposalCanceled(proposalId);
    }
    function execute() public {
        for (uint256 i = proposalExecuted + 1; i <= proposalTotal; i++) {
            if (state(i) == ProposalState.Queued) {
                Proposal storage proposal = proposals[i];
                require(
                    address(this).balance >= proposal.amount,
                    "Insufficient ETH"
                );
                proposal.isExecute = true;
                payable(proposal.target).transfer(proposal.amount);
                proposalExecuted = i;
                emit ProposalExecuted(i);
                break;
            }
        }
    }
    function castVote(uint256 proposalId, uint8 support) public {
        emit VoteCast(
            msg.sender,
            proposalId,
            support,
            _castVote(msg.sender, proposalId, support),
            ""
        );
    }
    function castVoteWithReason(
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) external {
        emit VoteCast(
            msg.sender,
            proposalId,
            support,
            _castVote(msg.sender, proposalId, support),
            reason
        );
    }
    function _castVote(
        address voter,
        uint256 proposalId,
        uint8 support
    ) internal returns (uint256) {
        require(
            !_aLGP.checkStaker(msg.sender),
            "castVote: Top staker cannot vote"
        );
        require(
            state(proposalId) == ProposalState.Active,
            "castVote: voting is closed"
        );
        require(support <= 2, "castVote: invalid vote type");
        Receipt storage receipt = receipts[proposalId][voter];
        require(receipt.isVote == false, "castVote: voter already voted");
        Proposal storage proposal = proposals[proposalId];
        uint256 votes = (_aLGP.getPastVotes(voter, proposal.startBlock) /
            1e18) * 1e18;
        if (support == 0) {
            proposal.againstVotes += votes;
        } else if (support == 1) {
            proposal.forVotes += votes;
        } else if (support == 2) {
            proposal.abstainVotes += votes;
        }
        receipt.isVote = true;
        receipt.support = support;
        receipt.votes = votes;
        return votes;
    }
}