// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract NFTContract {
    function getCurrentSupply() public virtual view returns(uint256);
    function getHolders() public virtual view returns(address[] memory);
    function isHolder(address addr) public virtual view returns(bool);
}

contract NyxDAO is ReentrancyGuard, AccessControl, Ownable {

    address public constant NULL_ADDRESS = 0x0000000000000000000000000000000000000000;
    enum ProposalType{Investment, Revenue, Governance, Allocation, Free}
    enum InvestmentType{Crypto, NFT}
    enum GovernanceAddressAction{ADD, REMOVE}

    // Proposal Structs
    /////////////////////////////////////////

    struct Vote
    {
        uint votedDatetime;
        address voter;
        ProposalType proposalType;
        uint256 proposalId;
        bool approved;
    }

    struct ProposalConf
    {
        uint256 id;
        ProposalType proposalType;
        uint256 livePeriod;
        uint256 votesFor;
        uint256 votesAgainst;
        bool votingPassed;
        bool settled;
        address proposer;
        address settledBy;
        bool isProposedToVote;
        bool approved;
    }

    struct Proposal
    {
        ProposalType proposalType;
        InvestmentProposal investmentPoposal;
        RevenueProposal revenuePoposal;
        AllocationProposal allocationPoposal;
        GovernanceProposal governancePoposal;
        FreeProposal freePoposal;
    }

    struct InvestmentProposal
    {
        uint256 id;
        InvestmentType assetType;
        string tokenName;
        address payable tokenAddress;
        uint256 percentage;
        ProposalConf conf;
    }

    struct RevenueProposal
    {
        uint256 id;
        uint256 yieldPercentage;
        uint256 reinvestedPercentage;
        uint256 mgmtFeesPercentage;
        uint256 perfFeesPercentage;
        ProposalConf conf;
    }

    struct GovernanceProposal
    {
        uint256 id;
        address ambassadorAddress;
        GovernanceAddressAction action;
        ProposalConf conf;
    }

    struct AllocationProposal
    {
        uint256 id;
        uint256 NFTPercentage;
        uint256 CryptoPercentage;
        uint256 VenturePercentage;
        uint256 TreasurePercentage;
        ProposalConf conf;
    }

    struct FreeProposal
    {
        uint256 id;
        string title;
        string description;
        ProposalConf conf;
    }

    // Attributes
    ///////////////////

    bytes32 public constant STAKEHOLDER_ROLE = keccak256("STAKEHOLDER");
    uint32 constant minimumVotingPeriod = 1 weeks;
    uint256 numOfInvestmentProposals;
    uint256 numOfRevenueProposals;
    uint256 numOfGovernanceProposals;
    uint256 numOfAllocationProposals;
    uint256 numOfFreeProposals;
    mapping(ProposalType => uint256) private numOfProposals;

    mapping(uint256 => InvestmentProposal) public investmentProposalMapping;
    mapping(uint256 => RevenueProposal) public revenueProposalMapping;
    mapping(uint256 => GovernanceProposal) public governanceProposalMapping;
    mapping(uint256 => AllocationProposal) public allocationProposalMapping;
    mapping(uint256 => FreeProposal) public freeProposalMapping;

    mapping(address => Vote[]) private stakeholderInvestmentVotes;
    mapping(address => Vote[]) private stakeholderRevenueVotes;
    mapping(address => Vote[]) private stakeholderGovernanceVotes;
    mapping(address => Vote[]) private stakeholderAllocationVotes;
    mapping(address => Vote[]) private stakeholderFreeVotes;
    // mapping(ProposalType => mapping(address => uint256[])) public stakeholderVotes;
    mapping(ProposalType => mapping(address => Vote[])) public stakeholderVotes;

    mapping(address => uint256) public stakeholders;
    address public nft_contract_address;
    mapping(address => address[]) delegateVoters;

    // Events
    ///////////////////

    event NewProposal(address indexed proposer, ProposalType proposalType, ProposalConf proposalConf);

    event ContributionReceived(address indexed fromAddress, uint256 amount);
    event PaymentTransfered(
        address indexed stakeholder,
        address indexed tokenAddress,
        uint256 amount
    );

    // Modifiers
    ///////////////////

    modifier onlyStakeholder(string memory message)
    {
        // require(hasRole(STAKEHOLDER_ROLE, msg.sender), message);
        require(isStakeholder(msg.sender), message);
        _;
    }

    // Constructor
    /////////////////

    constructor()
    {
        // proposalTypeMap[ProposalType.Investment] = InvestmentProposal;

        // Initializing numOfProposals mapping
        numOfProposals[ProposalType.Investment] = numOfInvestmentProposals;
        numOfProposals[ProposalType.Revenue] = numOfRevenueProposals;
        numOfProposals[ProposalType.Allocation] = numOfAllocationProposals;
        numOfProposals[ProposalType.Governance] = numOfGovernanceProposals;
        numOfProposals[ProposalType.Free] = numOfFreeProposals;
        
        // Initializing stakeholderVotes
        // mapping(address => uint256[]) storage investmentMapping = stakeholderVotes[ProposalType.Investment];
        // investmentMapping = stakeholderInvestmentVotes;
        // mapping(address => uint256[]) storage revenueMapping = stakeholderVotes[ProposalType.Revenue];
        // revenueMapping = stakeholderRevenueVotes;
        // mapping(address => uint256[]) storage allocationMapping = stakeholderVotes[ProposalType.Allocation];
        // allocationMapping = stakeholderAllocationVotes;
        // mapping(address => uint256[]) storage governanceMapping = stakeholderVotes[ProposalType.Governance];
        // governanceMapping = stakeholderGovernanceVotes;
        // mapping(address => uint256[]) storage freeMapping = stakeholderVotes[ProposalType.Free];
        // freeMapping = stakeholderFreeVotes;
        mapping(address => Vote[]) storage investmentMapping = stakeholderVotes[ProposalType.Investment];
        investmentMapping = stakeholderInvestmentVotes;
        mapping(address => Vote[]) storage revenueMapping = stakeholderVotes[ProposalType.Revenue];
        revenueMapping = stakeholderRevenueVotes;
        mapping(address => Vote[]) storage allocationMapping = stakeholderVotes[ProposalType.Allocation];
        allocationMapping = stakeholderAllocationVotes;
        mapping(address => Vote[]) storage governanceMapping = stakeholderVotes[ProposalType.Governance];
        governanceMapping = stakeholderGovernanceVotes;
        mapping(address => Vote[]) storage freeMapping = stakeholderVotes[ProposalType.Free];
        freeMapping = stakeholderFreeVotes;
    }

    // Functions
    ////////////////////

    function createProposalConf(uint256 proposalId, ProposalType proposalType)
        public view
        returns (ProposalConf memory)
    {
        uint256 livePeriod = block.timestamp + minimumVotingPeriod;
        uint256 votesFor = 0;
        uint256 votesAgainst = 0;
        bool votingPassed = false;
        bool settled = false;
        address proposer = msg.sender;
        address settledBy;
        bool isApprovedForVote;
        bool approved;
        ProposalConf memory proposalConf = ProposalConf(proposalId, proposalType, livePeriod, votesFor,
                                                        votesAgainst, votingPassed,
                                                        settled, proposer, settledBy, isApprovedForVote, approved);
        return proposalConf;
    }

    function createInvestmentProposal(InvestmentType assetType, string calldata tokenName,
                                      address tokenAddress, uint256 percentage)
        external
        onlyStakeholder("Only stakeholders are allowed to create proposals")
    {
        uint256 proposalId = numOfInvestmentProposals++;
        InvestmentProposal storage proposal = investmentProposalMapping[proposalId];

        proposal.id = proposalId;
        proposal.assetType = assetType;
        proposal.tokenName = tokenName;
        proposal.tokenAddress = payable(tokenAddress);
        proposal.percentage = percentage;

        ProposalConf memory proposalConf = createProposalConf(proposalId, ProposalType.Investment);

        proposal.conf = proposalConf;

        emit NewProposal(msg.sender, ProposalType.Investment, proposalConf);
    }

    function createRevenueProposal(uint256 yieldPercentage, uint256 reinvestedPercentage, uint256 mgmtFeesPercentage, uint256 perfFeesPercentage)
        external
        onlyStakeholder("Only stakeholders are allowed to create proposals")
    {
        uint256 proposalId = numOfRevenueProposals++;
        RevenueProposal storage proposal = revenueProposalMapping[proposalId];

        proposal.id = proposalId;
        proposal.yieldPercentage = yieldPercentage;
        proposal.reinvestedPercentage = reinvestedPercentage;
        proposal.mgmtFeesPercentage = mgmtFeesPercentage;
        proposal.perfFeesPercentage = perfFeesPercentage;

        ProposalConf memory proposalConf = createProposalConf(proposalId, ProposalType.Revenue);

        proposal.conf = proposalConf;

        emit NewProposal(msg.sender, ProposalType.Revenue, proposalConf);
    }

    function createAllocationProposal(uint256 NFTPercentage, uint256 cryptoPercentage, uint256 venturePercentage, uint256 treasurePercentage)
        external
        onlyStakeholder("Only stakeholders are allowed to create proposals")
    {
        uint256 proposalId = numOfAllocationProposals++;
        AllocationProposal storage proposal = allocationProposalMapping[proposalId];

        proposal.NFTPercentage = NFTPercentage;
        proposal.CryptoPercentage = cryptoPercentage;
        proposal.VenturePercentage = venturePercentage;
        proposal.TreasurePercentage = treasurePercentage;

        ProposalConf memory proposalConf = createProposalConf(proposalId, ProposalType.Allocation);

        proposal.conf = proposalConf;

        emit NewProposal(msg.sender, ProposalType.Allocation, proposalConf);
    }

    function createGovernanceProposal(address ambassadorAddress, GovernanceAddressAction action)
        external
        onlyStakeholder("Only stakeholders are allowed to create proposals")
    {
        uint256 proposalId = numOfGovernanceProposals++;
        GovernanceProposal storage proposal = governanceProposalMapping[proposalId];

        proposal.ambassadorAddress = ambassadorAddress;
        proposal.action = action;

        ProposalConf memory proposalConf = createProposalConf(proposalId, ProposalType.Governance);

        proposal.conf = proposalConf;

        emit NewProposal(msg.sender, ProposalType.Governance, proposalConf);
    }

    function createFreeProposal(string memory title, string memory description)
        external
        onlyStakeholder("Only stakeholders are allowed to create proposals")
    {
        uint256 proposalId = numOfFreeProposals++;
        FreeProposal storage proposal = freeProposalMapping[proposalId];

        proposal.title = title;
        proposal.description = description;

        ProposalConf memory proposalConf = createProposalConf(proposalId, ProposalType.Free);

        proposal.conf = proposalConf;

        emit NewProposal(msg.sender, ProposalType.Free, proposalConf);
    }

    function getProposalConf(ProposalType proposalType, uint256 proposalId)
        public view
        returns (ProposalConf memory)
    {
        ProposalConf memory conf;
        if (proposalType == ProposalType.Investment)
        {
            InvestmentProposal storage proposal = investmentProposalMapping[proposalId];
            conf = proposal.conf;
        }
        else if (proposalType == ProposalType.Revenue)
        {
            RevenueProposal storage proposal = revenueProposalMapping[proposalId];
            conf = proposal.conf;
        }
        else if (proposalType == ProposalType.Governance)
        {
            GovernanceProposal storage proposal = governanceProposalMapping[proposalId];
            conf = proposal.conf;
        }
        else if (proposalType == ProposalType.Allocation)
        {
            AllocationProposal storage proposal = allocationProposalMapping[proposalId];
            conf = proposal.conf;
        }
        else if (proposalType == ProposalType.Free)
        {
            FreeProposal storage proposal = freeProposalMapping[proposalId];
            conf = proposal.conf;
        }
        else
        {
            revert("Unkown proposal type");
        }
        return conf;
    }

    function setProposalConfOld(ProposalType proposalType, uint256 proposalId, bytes memory encodedProposal)
        public
    {
        if (proposalType == ProposalType.Investment)
        {
            InvestmentProposal memory newProposal = abi.decode(encodedProposal, (InvestmentProposal));
            InvestmentProposal storage oldProposal = investmentProposalMapping[proposalId];
            oldProposal.conf = newProposal.conf;
        }
        else if (proposalType == ProposalType.Revenue)
        {
            RevenueProposal memory newProposal = abi.decode(encodedProposal, (RevenueProposal));
            RevenueProposal storage oldProposal = revenueProposalMapping[proposalId];
            oldProposal.conf = newProposal.conf;
        }
        else if (proposalType == ProposalType.Governance)
        {
            GovernanceProposal memory newProposal = abi.decode(encodedProposal, (GovernanceProposal));
            GovernanceProposal storage oldProposal = governanceProposalMapping[proposalId];
            oldProposal.conf = newProposal.conf;
        }
        else if (proposalType == ProposalType.Allocation)
        {
            AllocationProposal memory newProposal = abi.decode(encodedProposal, (AllocationProposal));
            AllocationProposal storage oldProposal = allocationProposalMapping[proposalId];
            oldProposal.conf = newProposal.conf;
        }
        else if (proposalType == ProposalType.Free)
        {
            FreeProposal memory newProposal = abi.decode(encodedProposal, (FreeProposal));
            FreeProposal storage oldProposal = freeProposalMapping[proposalId];
            oldProposal.conf = newProposal.conf;
        }
        else
        {
            revert("Unkown proposal type");
        }
    }

    function setProposalConf(ProposalType proposalType, uint256 proposalId, ProposalConf memory proposalConf)
        public
    {
        if (proposalType == ProposalType.Investment)
        {
            InvestmentProposal storage oldProposal = investmentProposalMapping[proposalId];
            oldProposal.conf = proposalConf;
        }
        else if (proposalType == ProposalType.Revenue)
        {
            RevenueProposal storage oldProposal = revenueProposalMapping[proposalId];
            oldProposal.conf = proposalConf;
        }
        else if (proposalType == ProposalType.Governance)
        {
            GovernanceProposal storage oldProposal = governanceProposalMapping[proposalId];
            oldProposal.conf = proposalConf;
        }
        else if (proposalType == ProposalType.Allocation)
        {
            AllocationProposal storage oldProposal = allocationProposalMapping[proposalId];
            oldProposal.conf = proposalConf;
        }
        else if (proposalType == ProposalType.Free)
        {
            FreeProposal storage oldProposal = freeProposalMapping[proposalId];
            oldProposal.conf = proposalConf;
        }
        else
        {
            revert("Unkown proposal type");
        }
    }

    function makeVotable(ProposalType proposalType, uint256 proposalId)
        external onlyOwner
    {
        ProposalConf memory proposalConf = getProposalConf(proposalType, proposalId);
        require(!proposalConf.isProposedToVote, "Proposal is already proposed to votes");
        proposalConf.isProposedToVote = true;
        setProposalConf(proposalType, proposalId, proposalConf);
    }

    function voteOne(address voter, ProposalType proposalType, uint256 proposalId, ProposalConf memory proposalConf, bool supportProposal)
        internal
        onlyStakeholder("Only stakeholders are allowed to vote")
        returns (ProposalConf memory)
    {
        // uint256 votingPower = 1;
        uint256 votingPower = getStakeholderBalance(voter);
        votable(voter, proposalType, proposalConf);

        // stakeholderVotes[proposalType][voter].push(conf.id);
        Vote memory senderVote = Vote(block.timestamp, voter, proposalType, proposalId, supportProposal);
        stakeholderVotes[proposalType][voter].push(senderVote);

        if (supportProposal)
        {
            proposalConf.votesFor = proposalConf.votesFor + votingPower;
        }
        else
        {
            proposalConf.votesAgainst = proposalConf.votesAgainst + votingPower;
        }

        return proposalConf;
    }

    function vote(ProposalType proposalType, uint256 proposalId, bool supportProposal)
        external
        onlyStakeholder("Only stakeholders are allowed to vote")
    {
            
        ProposalConf memory conf = getProposalConf(proposalType, proposalId);
        address[] memory voters = delegateVoters[msg.sender];

        for (uint256 iVoter = 0; iVoter < voters.length; iVoter++)
        {
            address voter = voters[iVoter];
            conf = voteOne(voter, proposalType, proposalId, conf, supportProposal);
        }
        conf = voteOne(msg.sender, proposalType, proposalId, conf, supportProposal);
        
        setProposalConf(proposalType, proposalId, conf);
    }

    function votable(address votingAddress, ProposalType proposalType, ProposalConf memory proposalConf)
        private view
    {
        if (proposalConf.votingPassed || proposalConf.livePeriod <= block.timestamp)
        {
            proposalConf.votingPassed = true;
            revert("Voting period has passed on this proposal");
        }

        // uint256[] memory tempVotes = stakeholderVotes[proposalType][votingAddress];
        Vote[] memory tempVotes = stakeholderVotes[proposalType][votingAddress];

        // for (uint256 iVote = 0; iVote < tempVotes.length; iVote++)
        for (uint256 iVote = 0; iVote < tempVotes.length; iVote++)
        {
            if (proposalConf.id == tempVotes[iVote].proposalId)
            {
                revert("This stakeholder already voted on this proposal");                
            }
        }
    }

    function settleProposal(ProposalType proposalType, uint256 proposalId)
        external
        onlyStakeholder("Only stakeholders are allowed to settle proposals")
    {
        ProposalConf memory proposalConf = getProposalConf(proposalType, proposalId);

        if (proposalConf.settled)
        {
            revert("Proposal have already been settled");
        }
        
        proposalConf.approved = proposalConf.votesFor > proposalConf.votesAgainst;
        proposalConf.settled = true;
        proposalConf.settledBy = msg.sender;

        setProposalConf(proposalType, proposalId, proposalConf);
    }

    receive()
        external payable
    {
        emit ContributionReceived(msg.sender, msg.value);
    }

    function makeStakeholder()
        external onlyOwner
    {
        address[] memory holders = getHolders();

        for (uint256 i = 0; i < holders.length; i++)
        {
            address addr = holders[i];
            stakeholders[addr] = 1;
            _setupRole(STAKEHOLDER_ROLE, addr);
        }
    }

    function addStakeholder(address addr)
        public onlyOwner
    {
        stakeholders[addr] = 1;
    }

    function removeStakeholder(address addr)
        public onlyOwner
    {
        stakeholders[addr] = 0;
    }

    function setNftContract(address addr)
        public payable onlyOwner
    {
        nft_contract_address = addr;
    }

    function getHolders()
        public view
        returns (address[] memory)
    {
        NFTContract nft_contract = NFTContract(nft_contract_address);
        return nft_contract.getHolders();
    }

    function getInvestmentProposals()
        public
        view
        returns (InvestmentProposal[] memory props)
    {
        props = new InvestmentProposal[](numOfInvestmentProposals);

        for (uint256 index = 0; index < numOfInvestmentProposals; index++)
        {
            props[index] = investmentProposalMapping[index];
        }
    }

    function getRevenueProposals()
        public
        view
        returns (RevenueProposal[] memory props)
    {
        props = new RevenueProposal[](numOfRevenueProposals);

        for (uint256 index = 0; index < numOfRevenueProposals; index++)
        {
            props[index] = revenueProposalMapping[index];
        }
    }

    function getAllocationProposals()
        public
        view
        returns (AllocationProposal[] memory props)
    {
        props = new AllocationProposal[](numOfAllocationProposals);

        for (uint256 index = 0; index < numOfAllocationProposals; index++)
        {
            props[index] = allocationProposalMapping[index];
        }
    }

    function getGovernanceProposals()
        public
        view
        returns (GovernanceProposal[] memory props)
    {
        props = new GovernanceProposal[](numOfGovernanceProposals);

        for (uint256 index = 0; index < numOfGovernanceProposals; index++)
        {
            props[index] = governanceProposalMapping[index];
        }
    }

    function getFreeProposals()
        public
        view
        returns (FreeProposal[] memory props)
    {
        props = new FreeProposal[](numOfFreeProposals);

        for (uint256 index = 0; index < numOfFreeProposals; index++)
        {
            props[index] = freeProposalMapping[index];
        }
    }

    function getStakeholderVotes(ProposalType proposalType)
        public
        view
        onlyStakeholder("User is not a stakeholder")
        returns (Vote[] memory)
    {
        return stakeholderVotes[proposalType][msg.sender];
    }

    function getStakeholderBalance(address from)
        public
        view
        onlyStakeholder("User is not a stakeholder")
        returns (uint256)
    {
        return stakeholders[from];
    }

    function isStakeholder(address addr)
        public view
        returns (bool)
    {
        NFTContract nft_contract = NFTContract(nft_contract_address);
        return nft_contract.isHolder(addr);
    }

    function getDelegate(address addr)
        internal view
        returns (address addrOut)
    {
        address[] memory holders = getHolders();

        for (uint256 iHolder; iHolder < holders.length; iHolder++)
        {
            address holder = holders[iHolder];
            address[] memory holderDelegates = delegateVoters[holder];
            for (uint256 iHolderDelegate = 0; iHolderDelegate < holderDelegates.length; iHolderDelegate++)
            {
                address holderDelegate = holderDelegates[iHolderDelegate];
                // if (holderDelegate == msg.sender)
                if (holderDelegate == addr)
                {
                    return holder;
                }
            }
        }
        return NULL_ADDRESS;
        
    }

    function delegateVote(address to)
        external
        onlyStakeholder("User is not a stakeholder")
    {
        require(isStakeholder(to), "Can only delegate to stakeholder");

        address senderDelegate = getDelegate(msg.sender);
        bool alreadyDelegated = senderDelegate != NULL_ADDRESS;
        require(!alreadyDelegated, "sender have already delegated his vote");
        delegateVoters[to].push(msg.sender);
    }

    function undelegateVote()
        external
        onlyStakeholder("User is not a stakeholder")
    {
        address delegate = getDelegate(msg.sender);
        if (delegate != NULL_ADDRESS)
        {
            uint256 idxToDelete;
            for (uint256 iAddress = 0; iAddress < delegateVoters[delegate].length; iAddress++)
            {
                if (delegateVoters[delegate][iAddress] == msg.sender)
                {
                    idxToDelete = iAddress;
                }
            }
            delete delegateVoters[delegate][idxToDelete];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}