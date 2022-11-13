// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//interface IUniswapV2Router {
//  function getAmountsOut(uint256 amountIn, address[] memory path)
//    external
//    view
//    returns (uint256[] memory amounts);
//
//  function swapExactTokensForTokens(
//    //amount of tokens we are sending in
//    uint256 amountIn,
//    //the minimum amount of tokens we want out of the trade
//    uint256 amountOutMin,
//    //list of token addresses we are going to trade in.  this is necessary to calculate amounts
//    address[] calldata path,
//    //this is the address we are going to send the output tokens to
//    address to,
//    //the last time that the trade is valid for
//    uint256 deadline
//  ) external returns (uint256[] memory amounts);
//}
//
//interface IUniswapV2Pair {
//    function token0() external view returns (address);
//    function token1() external view returns (address);
//    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
//}
//
//interface IUniswapV2Factory {
//  function getPair(address token0, address token1) external returns (address);
//}

abstract contract NyxNFT {
    uint256 public currentTokenId;
    address public vault_address;

    function getCurrentSupply() public virtual view returns(uint256);
    function isHolder(address addr, uint256 tokenId) public virtual view returns(bool);
    function balanceOf(address addr, uint256 tokenId) public virtual view returns(uint256);
}

contract NyxDAO is ReentrancyGuard, Ownable {
    // Uniswap variables
    /////////////////////////////////////////
    //address of the uniswap v2 router
    address private constant UNISWAP_V2_ROUTER =  0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    
    //address of WETH token.  This is needed because some times it is better to trade through WETH.  
    //you might get a better price using WETH.  
    //example trading from token A to WETH then WETH to token B might result in a better price
    address private constant WETH =  0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    enum ProposalType{Investment, Revenue, Governance, Allocation, Free}
    enum InvestmentType{Crypto, NFT, Venture}
    enum GovernanceAddressAction{ADD, REMOVE}

    // Proposal Structs
    /////////////////////////////////////////

    struct Vote
    {
        uint votedDatetime;
        address voter;
        bool approved;
    }

    struct VoteConf
    {
        bool isProposedToVote;
        bool votingPassed;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 livePeriod;
        address[] voters;
    }

    struct ProposalConf
    {
        uint256 id;
        ProposalType proposalType;
        bool settled;
        address proposer;
        address settledBy;
        VoteConf voteConf;
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
        uint256 tokenId;
        address payable tokenAddress;
        uint256 amountETH;
        uint256 price;
        uint256 maxDelta;
        string osLink;
        string projectLink;
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
        string socialNetworkLink;
        string ambassadorDescription;
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

    // bytes32 public constant STAKEHOLDER_ROLE = keccak256("STAKEHOLDER");
    uint32 constant minimumVotingPeriod = 1 weeks;
    uint256 public numOfInvestmentProposals;
    uint256 public numOfRevenueProposals;
    uint256 public numOfGovernanceProposals;
    uint256 public numOfAllocationProposals;
    uint256 public numOfFreeProposals;
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
    mapping(uint256 => mapping(address => Vote[])) public stakeholderVotes;
    mapping(uint256 => mapping(uint256 => Vote[])) public proposalVotes;

    address public nft_contract_address;
    address public vault_contract_address;
    address public founder_contract_address;
    NyxNFT public nft_contract;
    mapping(address => address[]) public delegateOperatorToVoters;
    mapping(address => address) public delegateVoterToOperator;

    // Events
    ///////////////////

    event NewProposal(address indexed proposer, ProposalType proposalType, ProposalConf proposalConf);
    event ApprovedForVoteProposal(address indexed proposer, uint256 proposalTypeInt, ProposalConf proposalConf);
    event ApprovedProposal(address indexed proposer, ProposalType proposalType, ProposalConf proposalConf);
    event SettledProposal(address indexed proposer, ProposalType proposalType, ProposalConf proposalConf);

    event ContributionReceived(address indexed fromAddress, uint256 amount);
    event PaymentTransfered(address indexed stakeholder, address indexed tokenAddress, uint256 amount);

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
        mapping(address => Vote[]) storage investmentMapping = stakeholderVotes[uint256(ProposalType.Investment)];
        investmentMapping = stakeholderInvestmentVotes;
        mapping(address => Vote[]) storage revenueMapping = stakeholderVotes[uint256(ProposalType.Revenue)];
        revenueMapping = stakeholderRevenueVotes;
        mapping(address => Vote[]) storage allocationMapping = stakeholderVotes[uint256(ProposalType.Allocation)];
        allocationMapping = stakeholderAllocationVotes;
        mapping(address => Vote[]) storage governanceMapping = stakeholderVotes[uint256(ProposalType.Governance)];
        governanceMapping = stakeholderGovernanceVotes;
        mapping(address => Vote[]) storage freeMapping = stakeholderVotes[uint256(ProposalType.Free)];
        freeMapping = stakeholderFreeVotes;
    }

    // Functions
    ////////////////////

    function getNftTotalBalance(address addr)
        public view
        returns (uint256)
    {
        uint256 currentTokenId = nft_contract.currentTokenId();
        uint256 totalBalance;
        for (uint256 tokenId = 0; tokenId <= currentTokenId; tokenId++)
        {
            totalBalance += nft_contract.balanceOf(addr, tokenId);
        }
        return totalBalance;
    }

    function getVotingPower(address addr)
        public view
        returns (uint256)
    {
        uint256 votingPower = 0;
        for (uint tid = 0; tid <= nft_contract.currentTokenId(); tid++)
        {
            votingPower += nft_contract.balanceOf(addr, tid);
        }
        return votingPower;
    }

    function createVoteConf()
        public view
        returns (VoteConf memory)
    {
        address[] memory voters;
        return VoteConf(false, false, 0, 0, block.timestamp + minimumVotingPeriod, voters);
    }

    function createProposalConf(uint256 proposalId, ProposalType proposalType)
        internal view
        returns (ProposalConf memory)
    {
        VoteConf memory voteConf = createVoteConf();
        ProposalConf memory proposalConf = ProposalConf(proposalId, proposalType, false, msg.sender, address(0), voteConf, false);
        return proposalConf;
    }

    function createInvestmentProposal(InvestmentType assetType, string calldata tokenName,
                                      address tokenAddress, uint256 tokenId, uint256 price, uint256 maxDelta,
                                      string memory osLink, string memory projectLink)
        external
        onlyStakeholder("Only stakeholders are allowed to create proposals")
    {
        uint256 proposalId = numOfInvestmentProposals++;
        InvestmentProposal storage proposal = investmentProposalMapping[proposalId];

        proposal.id = proposalId;
        proposal.assetType = assetType;
        proposal.tokenName = tokenName;
        proposal.tokenAddress = payable(tokenAddress);
        proposal.tokenId = tokenId;
        proposal.price = price;
        proposal.maxDelta = maxDelta;
        proposal.osLink = osLink;
        proposal.projectLink = projectLink;

        ProposalConf memory proposalConf = createProposalConf(proposalId, ProposalType.Investment);

        proposal.conf = proposalConf;

        emit NewProposal(msg.sender, ProposalType.Investment, proposalConf);
    }

    function createRevenueProposal(uint256 yieldPercentage, uint256 reinvestedPercentage, uint256 mgmtFeesPercentage, uint256 perfFeesPercentage)
        external
        onlyStakeholder("Only stakeholders are allowed to create proposals")
    {
        require(yieldPercentage + reinvestedPercentage + mgmtFeesPercentage + perfFeesPercentage == 100,
            "total allocated must be equal to 1");

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
        require(NFTPercentage + cryptoPercentage + venturePercentage + treasurePercentage == 100,
            "total allocated must be equal to 1");

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

    function createGovernanceProposal(address ambassadorAddress, GovernanceAddressAction action, string memory socialNetworkLink,
                                      string memory ambassadorDescription)
        external
        onlyStakeholder("Only stakeholders are allowed to create proposals")
    {
        uint256 proposalId = numOfGovernanceProposals++;
        GovernanceProposal storage proposal = governanceProposalMapping[proposalId];

        proposal.ambassadorAddress = ambassadorAddress;
        proposal.action = action;
        proposal.socialNetworkLink = socialNetworkLink;
        proposal.ambassadorDescription = ambassadorDescription;

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

    // function settleInvestmentProposal(InvestmentProposal memory proposal)
    //     external
    //     onlyStakeholder("Only stakeholders are allowed to create proposals")
    // {
    //     if (proposal.assetType == InvestmentType.Crypto)
    //     {
    //         swap(WETH, proposal.tokenAddress,
    //             proposal.amountETH,
    //             proposal.amountETH / (proposal.price + proposal.maxDelta),
    //             nft_contract.vault_address);
    //     }
    // }

    // function settleRevenueProposal(InvestmentProposal proposal)
    //     external
    //     onlyStakeholder("Only stakeholders are allowed to create proposals")
    // {
    // }

    // function settleAllocationProposal(InvestmentProposal proposal)
    //     external
    //     onlyStakeholder("Only stakeholders are allowed to create proposals")
    // {
    // }

    // function settleGovernanceProposal(InvestmentProposal proposal)
    //     external
    //     onlyStakeholder("Only stakeholders are allowed to create proposals")
    // {
    // }

    function getProposalConf(uint256 proposalTypeInt, uint256 proposalId)
        public view
        returns (ProposalConf memory)
    {
        ProposalType proposalType = ProposalType(proposalTypeInt);
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

        return conf;
    }

    function setProposalConf(uint256 proposalTypeInt, uint256 proposalId, ProposalConf memory proposalConf)
        public
    {
        ProposalType proposalType = ProposalType(proposalTypeInt);
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

    function makeVotable(uint256 proposalTypeInt, uint256 proposalId)
        external onlyOwner
    {
        ProposalConf memory proposalConf = getProposalConf(proposalTypeInt, proposalId);
        require(!proposalConf.voteConf.isProposedToVote, "Proposal is already proposed to votes");
        proposalConf.voteConf.isProposedToVote = true;
        setProposalConf(proposalTypeInt, proposalId, proposalConf);

        emit ApprovedForVoteProposal(proposalConf.proposer, proposalTypeInt, proposalConf);
    }

    function voteOne(address voter, uint256 proposalTypeInt, uint256 proposalId, ProposalConf memory proposalConf, bool supportProposal)
        internal
        onlyStakeholder("Only stakeholders are allowed to vote")
        returns (ProposalConf memory)
    {
        uint256 votingPower = getVotingPower(voter);
        votable(voter, proposalConf.voteConf);

        Vote memory senderVote = Vote(block.timestamp, voter, supportProposal);
        stakeholderVotes[proposalTypeInt][voter].push(senderVote);
        proposalVotes[proposalTypeInt][proposalId].push(senderVote);

        if (supportProposal)
        {
            proposalConf.voteConf.votesFor = proposalConf.voteConf.votesFor + votingPower;
        }
        else
        {
            proposalConf.voteConf.votesAgainst = proposalConf.voteConf.votesAgainst + votingPower;
        }

        return proposalConf;
    }

    function vote(uint256 proposalTypeInt, uint256 proposalId, bool supportProposal)
        external
        onlyStakeholder("Only stakeholders are allowed to vote")
    {
            
        ProposalConf memory conf = getProposalConf(proposalTypeInt, proposalId);
        address[] memory voters = delegateOperatorToVoters[msg.sender];

        for (uint256 iVoter = 0; iVoter < voters.length; iVoter++)
        {
            address voter = voters[iVoter];
            conf = voteOne(voter, proposalTypeInt, proposalId, conf, supportProposal);
        }
        conf = voteOne(msg.sender, proposalTypeInt, proposalId, conf, supportProposal);
        
        setProposalConf(proposalTypeInt, proposalId, conf);
    }

    function votable(address votingAddress, VoteConf memory voteConf)
        private view
    {
        if (voteConf.votingPassed || voteConf.livePeriod <= block.timestamp)
        {
            string memory message = "Voting period has passed on this proposal : ";
            message = string(abi.encodePacked(message, Strings.toString(voteConf.livePeriod)));
            message = string(abi.encodePacked(message, " <= "));
            message = string(abi.encodePacked(message, Strings.toString(block.timestamp)));
            revert(message);
        }

        if (!voteConf.isProposedToVote)
        {
            revert("Proposal wasn't approved for vote yet");
        }

        for (uint256 iVote = 0; iVote < voteConf.voters.length; iVote++)
        {
            if (voteConf.voters[iVote] == votingAddress)
            {
                revert("This stakeholder already voted on this proposal");                
            }
        }
    }

    function settleProposal(ProposalType proposalType, uint256 proposalId)
        external
        onlyStakeholder("Only stakeholders are allowed to settle proposals")
    {
        ProposalConf memory proposalConf = getProposalConf(uint256(proposalType), proposalId);

        if (proposalConf.settled)
        {
            revert("Proposal have already been settled");
        }
        
        proposalConf.approved = proposalConf.voteConf.votesFor > proposalConf.voteConf.votesAgainst;
        proposalConf.settled = true;
        proposalConf.settledBy = msg.sender;

        setProposalConf(uint256(proposalType), proposalId, proposalConf);

        emit SettledProposal(proposalConf.proposer, proposalType, proposalConf);
    }

    function setNftContract(address addr)
        public payable onlyOwner
    {
        nft_contract_address = addr;
        nft_contract = NyxNFT(nft_contract_address);
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

    function getStakeholderVotes(uint256 proposalTypeInt, address addr)
        public
        view
        onlyStakeholder("User is not a stakeholder")
        returns (Vote[] memory)
    {
        return stakeholderVotes[proposalTypeInt][addr];
    }

    function getProposalVotes(uint256 proposalTypeInt, uint256 proposalId)
        external view
        onlyStakeholder("User is not a stakeholder")
        returns (Vote[] memory)
    {
        Vote[] memory _proposalVotes = proposalVotes[proposalTypeInt][proposalId];
        return _proposalVotes;
    }

    function isStakeholder(address addr)
        public view
        returns (bool)
    {
        require(nft_contract_address != address(0), "Have to setup the NFT smart contract address");
        uint256 totalBalance = getNftTotalBalance(addr);      
        return totalBalance > 0;
    }

    function getDelegateOperator(address voter)
        internal view
        returns (address addrOut)
    {
        return delegateVoterToOperator[voter];        
    }

    function delegateVote(address to)
        external
        onlyStakeholder("User is not a stakeholder")
    {
        require(isStakeholder(to), "Can only delegate to stakeholder");

        address senderDelegate = getDelegateOperator(msg.sender);
        bool notDelegated = senderDelegate == address(0);
        require(notDelegated, "sender have already delegated his vote");
        delegateOperatorToVoters[to].push(msg.sender);
        delegateVoterToOperator[msg.sender] = to;
    }

    function undelegateVote()
        external
        onlyStakeholder("User is not a stakeholder")
    {
        address delegate = getDelegateOperator(msg.sender);
        if (delegate != address(0))
        {
            uint256 idxToDelete;
            for (uint256 iAddress = 0; iAddress < delegateOperatorToVoters[delegate].length; iAddress++)
            {
                if (delegateOperatorToVoters[delegate][iAddress] == msg.sender)
                {
                    idxToDelete = iAddress;
                }
            }
            delete delegateOperatorToVoters[delegate][idxToDelete];
            delete delegateVoterToOperator[msg.sender];
        }
    }

    // function revenueDistribution()
    //     external onlyOwner payable
    // {
    // }

    receive()
        external payable
    {
        emit ContributionReceived(msg.sender, msg.value);
    }

    //this swap function is used to trade from one token to another
    //the inputs are self explainatory
    //token in = the token address you want to trade out of
    //token out = the token address you want as the output of this trade
    //amount in = the amount of tokens you are sending in
    //amount out Min = the minimum amount of tokens you want out of the trade
    //to = the address you want the tokens to be sent to
    
//    function swap(address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _amountOutMin, address _to)
//        public
//    {
//        //first we need to transfer the amount in tokens from the msg.sender to this contract
//        //this contract will have the amount of in tokens
//        IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
//
//        //next we need to allow the uniswapv2 router to spend the token we just sent to this contract
//        //by calling IERC20 approve you allow the uniswap contract to spend the tokens in this contract
//        IERC20(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountIn);
//
//        //path is an array of addresses.
//        //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
//        //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
//        address[] memory path;
//        if (_tokenIn == WETH || _tokenOut == WETH)
//        {
//            path = new address[](2);
//            path[0] = _tokenIn;
//            path[1] = _tokenOut;
//        }
//        else
//        {
//            path = new address[](3);
//            path[0] = _tokenIn;
//            path[1] = WETH;
//            path[2] = _tokenOut;
//        }
//        //then we will call swapExactTokensForTokens
//        //for the deadline we will pass in block.timestamp
//        //the deadline is the latest time the trade is valid for
//        IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, _to, block.timestamp);
//    }
//
//    //this function will return the minimum amount from a swap
//    //input the 3 parameters below and it will return the minimum amount out
//    //this is needed for the swap function above
//    function getAmountOutMin(address _tokenIn, address _tokenOut, uint256 _amountIn) external view returns (uint256)
//    {
//        //path is an array of addresses.
//        //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
//        //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
//        address[] memory path;
//        if (_tokenIn == WETH || _tokenOut == WETH)
//        {
//            path = new address[](2);
//            path[0] = _tokenIn;
//            path[1] = _tokenOut;
//        }
//        else
//        {
//            path = new address[](3);
//            path[0] = _tokenIn;
//            path[1] = WETH;
//            path[2] = _tokenOut;
//        }
//
//        uint256[] memory amountOutMins = IUniswapV2Router(UNISWAP_V2_ROUTER).getAmountsOut(_amountIn, path);
//        return amountOutMins[path.length -1];
//    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
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