// SPDX-License-Identifier: MIT

// @title NyxDAO for Nyx DAO
// @author TheV

//  ________       ___    ___ ___    ___      ________  ________  ________     
// |\   ___  \    |\  \  /  /|\  \  /  /|    |\   ___ \|\   __  \|\   __  \    
// \ \  \\ \  \   \ \  \/  / | \  \/  / /    \ \  \_|\ \ \  \|\  \ \  \|\  \   
//  \ \  \\ \  \   \ \    / / \ \    / /      \ \  \ \\ \ \   __  \ \  \\\  \  
//   \ \  \\ \  \   \/  /  /   /     \/        \ \  \_\\ \ \  \ \  \ \  \\\  \ 
//    \ \__\\ \__\__/  / /    /  /\   \         \ \_______\ \__\ \__\ \_______\
//     \|__| \|__|\___/ /    /__/ /\ __\         \|_______|\|__|\|__|\|_______|
//               \|___|/     |__|/ \|__|                       

pragma solidity >=0.8.0;

import "./interfaces/INyxDAO.sol";

contract NyxDAO is INyxDAO
{
    string public constant name = "NyxDAO";

    // Constructor
    /////////////////

    constructor()
    {
        teamAddressesDict[msg.sender] = true;
    }

    // External contract setters
    /////////////////////////////////////

    /**
    * @notice Set the NFT contract address
    */
    function setNftContract(address addr)
        public
        override
        onlyOwner
    {
        nft_contract = INyxNFT(addr);
    }
    
    /**
    * @notice Set the NyxVault safe module contract
    */
    function setVaultModuleContract(address addr)
        public
        override
        onlyOwner
    {
        nyx_vault_module_contract = INyxVault(addr);
    }

    /**
    * @notice Set the Proposal Handler contract
    */
    function setProposalHandlerContract(address addr)
        public
        override
        onlyOwner
    {
        proposalHandler = INyxProposalHandler(addr);
    }

    /**
    * @notice Set the Proposal Registry contract
    */
    function setProposalRegistryContract(address addr)
        public
        override
        onlyOwner
    {
        proposalRegistry = INyxProposalRegistry(addr);
    }

    /**
    * @notice Set the Proposal Settler contract
    */
    function setProposalSettlerHandlerContract(address addr)
        public
        override
        onlyOwner
    {
        proposalSettler = INyxProposalSettlerHandler(addr);
    }

    /**
    * @notice Set the Voting Handler contract
    */
    function setVotingHandlerContract(address addr)
        public
        override
        onlyOwner
    {
        votingHandler = INyxVotingHandler(addr);
    }

    /**
    * @notice Set an existing Proposal Type name in the Proposal Registry
    */
    function setProposalTypeName(uint256 proposalTypeInt, string memory newProposalTypeName)
        external
        override
        onlyOwner withProposalRegistrySetted
    {
        proposalRegistry.setProposalTypeName(proposalTypeInt, newProposalTypeName);
    }

    /**
    * @notice Set an existing Proposal Type contract address in the Proposal Registry
    */
    function setProposalContractAddress(uint256 proposalTypeInt, address addr)
        external
        override
        onlyOwner withProposalRegistrySetted
    {
        proposalRegistry.setProposalContractAddress(proposalTypeInt, addr);
    }

    /**
    * @notice Set an existing Proposal Type Settler contract address in the Proposal Registry
    */
    function setProposalSettlerAddress(uint256 proposalTypeInt, address addr)
        external
        override
        onlyOwner withProposalRegistrySetted
    {
        proposalRegistry.setProposalContractAddress(proposalTypeInt, addr);
    }

    // Attributes Setters
    /////////////////////////////////////

    /**
    * @notice Set the voting minimum approval quorum percentage
    */
    function setMinApprovalPct(uint256 _approvalPct)
        public
        override
        withProposalHandlerSetted onlyProposalHandler
    {
        minApprovalPct = _approvalPct;
    }

    /**
    * @notice Set the voting minimum voters quorum percentage
    */
    function setMinVotersPct(uint256 _votersPct)
        public
        override
        withProposalHandlerSetted onlyProposalHandler
    {
        minVotersPct = _votersPct;
    }

    /**
    * @notice Add <addr> as admin
    */
    function addTeamAddress(address addr)
        external
        override
        onlyProposalHandler
    {
        teamAddressesDict[addr] = true;
    }

    /**
    * @notice Removes <addr> as admin
    */
    function removeTeamAddress(address addr)
        external
        override
        onlyProposalHandler
    {
        teamAddressesDict[addr] = false;
    }

    // Role Checkers
    /////////////////////////////////////
    
    /**
    * @notice Check <addr> is a representative of any Proposal Type
    */
    function isRepresentative(address addr)
        public view
        override
        returns (bool)
    {
        mapping(uint256 => uint8) storage addrRights = representativeRights[addr];
        return isRepresentative(addrRights);
    }

    /**
    * @notice Check <addr> is a representative of <proposalTypeInt>
    */
    function isRepresentative(address addr, uint256 proposalTypeInt)
        public view
        override
        returns (bool)
    {
        return representativeRights[addr][proposalTypeInt] == 1;
    }

    /**
    * @notice Helper functions to check if a Representative Rights mappings is True for any 
    * Proposal Type
    */
    function isRepresentative(mapping(uint256 => uint8) storage addrRights)
        internal view
        override
        returns (bool)
    {
        for (uint256 idx = 0; idx < getNumOfProposalTypes(); idx++)
        {
            if (addrRights[idx] == 1)
            {
                return true;
            }
        }
        return false;
    }

    /**
    * @notice Check <addr> is an admin
    */
    function isTeamAddress(address addr)
        public view
        override
        returns (bool)
    {
        return teamAddressesDict[addr];
    }

    /**
    * @notice Check <addr> is a holder
    */
    function isStakeholder(address addr)
        public view
        override
        withNftSetted
        returns (bool)
    {
        uint256 totalBalance = getNftTotalBalance(addr);      
        return totalBalance > 0;
    }

    // Representative Logic
    /////////////////////////////////////

    /**
    * @notice if <addr> is a representative for <proposalTypeInt>, remove its role
    * Otherwise, grants it representative role
    * @param addr proposal type number
    * @param proposalTypeInt proposal type number
    */
    function toggleRepresentativeRight(address addr, uint256 proposalTypeInt)
        public
        override
        withProposalHandlerSetted onlyProposalHandler
    {
        mapping(uint256 => uint8) storage addrRights = representativeRights[addr];
        bool wasRepresentative = isRepresentative(addrRights);
        if (addrRights[proposalTypeInt] == 1)
        {
            addrRights[proposalTypeInt] = 0;
            if (!isRepresentative(addrRights))
            {
                numOfRepresentatives--;
            }
        }
        else
        {
            addrRights[proposalTypeInt] = 1;
            if (!wasRepresentative)
            {
                numOfRepresentatives++;
            }
        }
    }

    /**
    * @notice For each Proposal Type in <proposalTypeInts>,
    * if <addr> is a representative, remove its role
    * Otherwise, grants it representative role
    * @param addr proposal type number
    * @param proposalTypeInts array of proposal type number
    */
    function toggleRepresentativeRights(address addr, uint256[] calldata proposalTypeInts)
        public
        override
        withProposalHandlerSetted onlyProposalHandler
    {
        for (uint256 idx = 0; idx < proposalTypeInts.length; idx++)
        {
            toggleRepresentativeRight(addr, proposalTypeInts[idx]);
        }
    }

    // Voting Handler wrapper
    ////////////////////

    /**
    * @notice Wrapper for Voting Handler createVoteConf function
    */
    function createVoteConf(uint256 proposalTypeInt, uint256 proposalId, address author, uint256 durationDays)
        internal
        override
        withVotingHandlerSetted
        returns (INyxVotingHandler.VoteConf memory)
    {
        return votingHandler.createVoteConf(proposalTypeInt, proposalId, author, durationDays);
    }

    /**
    * @notice Wrapper for Voting Handler updateVoteConf function
    */
    function updateVoteConf(uint256 proposalTypeInt, uint256 proposalId, address author, uint256 durationDays)
        external
        override
        onlyOwner withVotingHandlerSetted
        returns (INyxVotingHandler.VoteConf memory)
    {
        return votingHandler.updateVoteConf(proposalTypeInt, proposalId, author, durationDays);
    }

    /**
    * @notice Wrapper for Voting Handler makeVotable function
    */
    function makeVotable(uint256 proposalTypeInt, uint256 proposalId)
        external
        override
        onlyAllowedRepresentatives(proposalTypeInt) withVotingHandlerSetted
    {
        votingHandler.makeVotable(proposalTypeInt, proposalId);
    }

    /**
    * @notice Wrapper for Voting Handler votable function
    */
    function votable(address votingAddress, INyxVotingHandler.VoteConf memory voteConf, bool failOnRequirements)
        public view
        override
        withVotingHandlerSetted
        returns (bool)
    {
        return votingHandler.votable(votingAddress, voteConf, failOnRequirements);
    }

    /**
    * @notice Wrapper for Voting Handler vote function
    */
    function vote(uint256 proposalTypeInt, uint256 proposalId, bool supportProposal)
        external
        override
        onlyStakeholder("Only stakeholders are allowed to vote") withVotingHandlerSetted
    {
        return votingHandler.vote(msg.sender, proposalTypeInt, proposalId, supportProposal);
    }

    /**
    * @notice Wrapper for Voting Handler getStakeholderVotes function
    */
    function getStakeholderVotes(uint256 proposalTypeInt, address addr)
        public
        view
        override
        onlyStakeholder("User is not a stakeholder") withVotingHandlerSetted
        returns (INyxVotingHandler.Vote[] memory)
    {
        return votingHandler.getStakeholderVotes(proposalTypeInt, addr);
    }

    /**
    * @notice Wrapper for Voting Handler getProposalVotes function
    */
    function getProposalVotes(uint256 proposalTypeInt, uint256 proposalId)
        external view
        override
        onlyStakeholder("User is not a stakeholder") withVotingHandlerSetted
        returns (INyxVotingHandler.Vote[] memory)
    {
        return votingHandler.getProposalVotes(proposalTypeInt, proposalId);
    }

    /**
    * @notice Wrapper for Voting Handler getVoteConf function
    */
    function getVoteConf(uint256 proposalTypeInt, uint256 proposalId)
        public view
        override
        withVotingHandlerSetted
        returns (INyxVotingHandler.VoteConf memory)
    {
        return votingHandler.getVoteConf(proposalTypeInt, proposalId);
    }

    /**
    * @notice Wrapper for Voting Handler getVoteConfs function
    */
    function getVoteConfs(uint256 proposalTypeInt)
        external view
        override
        withVotingHandlerSetted
        returns (INyxVotingHandler.VoteConf[] memory)
    {
        return votingHandler.getVoteConfs(proposalTypeInt);
    }

    /**
    * @notice Wrapper for Voting Handler getVotingPower function
    */
    function getVotingPower(address addr, uint256 blockNumber)
        public view
        override
        withVotingHandlerSetted
        returns (uint256)
    {
        return votingHandler.getVotingPower(addr, blockNumber);
    }

    /**
    * @notice Wrapper for Voting Handler getDelegateOperator function
    */
    function getDelegateOperator(address voter)
        internal view
        override
        withVotingHandlerSetted
        returns (address addrOut)
    {
        return votingHandler.getDelegateOperator(voter);
    }

    /**
    * @notice Wrapper for Voting Handler delegateVote function
    * Also check that <to> is a holder before making the external call
    */
    function delegateVote(address to)
        external
        override
        onlyStakeholder("User is not a stakeholder") withVotingHandlerSetted
    {
        require(isStakeholder(to));
        votingHandler.delegateVote(msg.sender, to);
    }

    /**
    * @notice Wrapper for Voting Handler undelegateVote function
    */
    function undelegateVote()
        external
        override
        onlyStakeholder("User is not a stakeholder") withVotingHandlerSetted
    {
        votingHandler.undelegateVote(msg.sender);
    }

    /**
    * @notice Wrapper for Voting Handler votable function
    */
    // Nft wrapper functions
    //////////////////////////

    function getNftTotalBalance(address addr)
        public view
        override
        withNftSetted
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

    // Proposal Registry Wrappers
    ///////////////////////////////////
    
    function getProposalType(uint256 proposalTypeInt)
        external view
        override
        withProposalRegistrySetted
        returns (INyxProposalRegistry.ProposalType memory)
    {
        return proposalRegistry.getProposalType(proposalTypeInt);
    }

    function getNumOfProposalTypes()
        public view
        override
        withProposalRegistrySetted
        returns (uint256)
    {
        return proposalRegistry.numOfProposalTypes();
    }

    function addProposalType(string memory proposalTypeName, address proposalHandlerAddr, address proposalSettlerAddr)
        external
        override
        onlyOwner withProposalRegistrySetted
    {
        proposalRegistry.addProposalType(proposalTypeName, proposalHandlerAddr, proposalSettlerAddr);
    }

    // Proposal Handler Wrappers
    ///////////////////////////////////

    function getNumOfProposals(uint256 proposalTypeInt)
        public view
        override
        withProposalHandlerSetted
        returns (uint256)
    {
        return proposalHandler.numOfProposals(proposalTypeInt);
    }

    function setConverterAddress(address addr)
        external
        override
        onlyOwner withProposalHandlerSetted
    {
        proposalHandler.setConverterAddress(addr);
    }

    function getProposalConf(uint256 proposalTypeInt, uint256 proposalId)
        external view
        override
        onlyOwner withProposalHandlerSetted
    {
        proposalHandler.getProposalConf(proposalTypeInt, proposalId);
    }

    function setProposalConf(INyxProposalHandler.ProposalConf memory proposalConf)
        external
        override
        onlyOwner withProposalHandlerSetted
    {
        proposalHandler.setProposalConf(proposalConf);
    }

    function createProposal(uint256 proposalTypeInt, bytes[] memory params, uint256 durationDays)
        external
        override
        onlyStakeholder("Only stakeholders are allowed to create proposals") withProposalHandlerSetted
        returns (uint256)
    {
        uint256 proposalId = proposalHandler.createProposal(proposalTypeInt, params, msg.sender);
        createVoteConf(proposalTypeInt, proposalId, msg.sender, durationDays);

        return proposalId;
    }

    function deleteProposal(uint256 proposalTypeInt, uint256 proposalId)
        external
        override
        onlyOwner withProposalHandlerSetted
    {
        proposalHandler.deleteProposal(proposalTypeInt, proposalId);
    }

    function getProposalConfs(uint256 proposalTypeInt)
        external view
        override
        withProposalHandlerSetted
        returns (INyxProposalHandler.ProposalConf[] memory)
    {
        return proposalHandler.getProposalConfs(proposalTypeInt);
    }
    
    function getProposal(uint256 proposalTypeInt, uint256 proposalId)
        external view
        override
        withProposalHandlerSetted
        returns (bytes[] memory)
    {
        return proposalHandler.getProposal(proposalTypeInt, proposalId);
    }
    
    function getProposals(uint256 proposalTypeInt)
        external view
        override
        withProposalHandlerSetted
        returns (bytes[][] memory)
    {
        return proposalHandler.getProposals(proposalTypeInt);
    }

    function getProposalReadable(uint256 proposalTypeInt, uint256 proposalId)
        external view
        override
        withProposalHandlerSetted
        returns (INyxProposalHandler.ProposalReadable memory)
    {
        return proposalHandler.getProposalReadable(proposalTypeInt, proposalId);
    }

    function getProposalReadables(uint256 proposalTypeInt)
        external view
        override
        withProposalHandlerSetted
        returns (INyxProposalHandler.ProposalReadable[] memory)
    {
        return proposalHandler.getProposalReadables(proposalTypeInt);
    }

    // Proposal Settler Wrappers
    ///////////////////////////////////

    function settleProposal(uint256 proposalTypeInt, uint256 proposalId)
        external
        override
        onlyAllowedRepresentatives(proposalId) withProposalHandlerSetted withNftSetted
    {
        INyxProposalHandler.ProposalConf memory proposalConf = proposalHandler.getProposalConf(proposalTypeInt, proposalId);
        INyxVotingHandler.VoteConf memory voteConf = getVoteConf(proposalTypeInt, proposalId);

        require(block.timestamp > voteConf.livePeriod, "Proposal voting period is not ended yet");

        bytes[] memory proposalParams = proposalHandler.getProposal(proposalTypeInt, proposalId);

        if (proposalConf.settled)
        {
            revert("Proposal have already been settled");
        }
        
        proposalConf.approved = voteConf.votesFor > (minApprovalPct * nft_contract.getCurrentSupply())/100 && 
            voteConf.voters.length >= (minVotersPct * nft_contract.getCurrentSupply())/100;
        proposalConf.settled = true;
        proposalConf.settledBy = msg.sender;

        proposalHandler.setProposalConf(proposalConf);
        bool success = proposalSettler.settleProposal(proposalId, proposalParams);

        require(success, "Couldn't settle proposal");

        emit SettledProposal(proposalConf.proposer, proposalTypeInt, proposalId, proposalConf.approved);
    }

    // Redeem logic functions
    ///////////////////////////////////

    function closeRedeem()
        public 
        override
        onlyOwner
    {
        redeemOpen = false;
        nyx_vault_module_contract.resetLockedLiquidity();
    }

    function openRedeem(uint256 liquidity, uint256 pricePerReedemPower)
        public
        override
        onlyOwner withNftSetted
    {
        require(nft_contract.vault_address().balance >= liquidity, "Not enough balance in the vault to redeem that much");
        nyx_vault_module_contract.lockLiquidity(liquidity);
        redeemOpen = true;
        currentRedeem = 0;
        maxRedeem = liquidity;
        redeemPricePerRedeemPower = pricePerReedemPower;
    }

    function getRedeemPrice(uint256 tokenId)
        public view
        override
        withNftSetted
        returns (uint256)
    {
        uint256 tokenIdRedeemRatio = nft_contract.waveRedeemRatio(tokenId);
        uint256 redeemPrice = redeemPricePerRedeemPower * tokenIdRedeemRatio;
        return redeemPrice;
    }

    function redeem(uint56 nNfts, uint256 tokenId)
        public
        override
        withNftSetted withVaultModuleSetted nonReentrant
    {
        require(redeemOpen, "redeem is not open");
        require(tokenId <= nft_contract.currentTokenId(), "token ID does not exists");
        require(address(nft_contract).balance == 0, "NFT balance have to be withdrawn to the vault before redeem");
        require(nyx_vault_module_contract.approvedCallers(address(this)) == 1, "vault have to approve dao");
        require(nft_contract.isApprovedForAll(msg.sender, address(this)), "NyxDAO have to be approved by the caller");
        require(nft_contract.balanceOf(msg.sender, tokenId) >= nNfts, "Not enough balance to redeem that much");

        // Compute redeemable Amount
        uint96 redeemableAmount = uint96(getRedeemPrice(tokenId) * nNfts);

        // require(currentRedeem + nNfts <= maxRedeem, "too muche NFTs redeemed");
        require(currentRedeem + redeemableAmount <= maxRedeem, "Not enough remaining liquidity to redeem that much");

        // Updating currentRedeem value
        currentRedeem += redeemableAmount;

        // Send the nft from msg.sender to NyxDAO thanks to the approval
        nft_contract.safeTransferFrom(msg.sender, address(this), tokenId, nNfts, "");

        // Now that NyxDAO have received the NFT, it can burn it
        nft_contract.burnNFT(address(this), nNfts, tokenId);

        // Send the redeem amount to msg.sender
        // nyx_vault_module_contract.transfer(address(0), payable(msg.sender), redeemableAmount);
        // // nyx_vault_module_contract.redeem(payable(msg.sender), uint96(redeemableAmount));
        nyx_vault_module_contract.redeem(payable(msg.sender), redeemableAmount);
    }
}

// SPDX-License-Identifier: MIT

// @title INyxDAO for Nyx DAO
// @author TheV

//  ________       ___    ___ ___    ___      ________  ________  ________     
// |\   ___  \    |\  \  /  /|\  \  /  /|    |\   ___ \|\   __  \|\   __  \    
// \ \  \\ \  \   \ \  \/  / | \  \/  / /    \ \  \_|\ \ \  \|\  \ \  \|\  \   
//  \ \  \\ \  \   \ \    / / \ \    / /      \ \  \ \\ \ \   __  \ \  \\\  \  
//   \ \  \\ \  \   \/  /  /   /     \/        \ \  \_\\ \ \  \ \  \ \  \\\  \ 
//    \ \__\\ \__\__/  / /    /  /\   \         \ \_______\ \__\ \__\ \_______\
//     \|__| \|__|\___/ /    /__/ /\ __\         \|_______|\|__|\|__|\|_______|
//               \|___|/     |__|/ \|__|                       

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./INyxProposalHandler.sol";
import "./INyxVotingHandler.sol";
import "./INyxProposalSettlerHandler.sol";
import "nyx_nft/interfaces/INyxNft.sol";
import "nyx_vault/interfaces/INyxVault.sol";


abstract contract INyxDAO is Ownable, ERC1155Holder, ReentrancyGuard
{
    // Attributes
    ///////////////////
    uint256 public minVotersPct = 50;
    uint256 public minApprovalPct = 51;
    bool public redeemOpen;
    uint256 public currentRedeem;
    uint256 public maxRedeem;
    uint256 public redeemPricePerRedeemPower;
    uint256 public numOfRepresentatives;

    mapping(address => bool) public teamAddressesDict;
    mapping(address => mapping(uint256 => uint8)) public representativeRights;

    INyxNFT public nft_contract;
    INyxVault public nyx_vault_module_contract;
    INyxProposalHandler public proposalHandler;
    INyxProposalRegistry public proposalRegistry;
    INyxProposalSettlerHandler public proposalSettler;
    INyxVotingHandler public votingHandler;

    // Modifiers
    ///////////////////
    modifier onlyStakeholder(string memory message)
    {
        // require(hasRole(STAKEHOLDER_ROLE, msg.sender), message);
        require(isStakeholder(msg.sender));
        _;
    }

    modifier onlyAllowedRepresentatives(uint256 proposalTypeInt)
    {
        // require(hasRole(STAKEHOLDER_ROLE, msg.sender), message);
        require(msg.sender == owner() || isTeamAddress(msg.sender) || 
            representativeRights[msg.sender][proposalTypeInt] == 1, "not representative for this proposal type");
        _;
    }

    modifier onlyProposalHandler()
    {
        require(msg.sender == owner() || isTeamAddress(msg.sender) ||
            msg.sender == address(proposalHandler), "not called by proposal creator");
        _;
    }

    modifier withProposalRegistrySetted()
    {
        require(address(proposalRegistry) != address(0), "you have to set proposal registry contract first");
        _;
    }
    
    modifier withProposalHandlerSetted()
    {
        require(address(proposalHandler) != address(0), "you have to set proposal handler contract first");
        _;
    }

    modifier withVotingHandlerSetted()
    {
        require(address(votingHandler) != address(0), "you have to set voting handler contract first");
        _;
    }

    modifier withProposalSettlerHandlerSetted()
    {
        require(address(proposalHandler) != address(0), "you have to set proposal settler handler contract first");
        _;
    }

    modifier withNftSetted()
    {
        require(address(nft_contract) != address(0), "you have to set nft contract address first");
        _;
    }
    
    modifier withVaultModuleSetted()
    {
        require(address(nyx_vault_module_contract) != address(0), "you have to set the vault safe module contract first");
        _;
    }

    // modifier onlyExistingProposal(uint256 proposalTypeInt, uint256 proposalId)
    // {
    //     require(voteConfMapping[proposalTypeInt][proposalId].creationTime != 0, "proposal doesn't exists");
    //     _;
    // }

    // Functions
    /////////////////////
    function setNftContract(address addr) public virtual;
    function setVaultModuleContract(address addr) public virtual;
    function setProposalHandlerContract(address addr) public virtual;
    function setProposalRegistryContract(address addr) public virtual;
    function setProposalSettlerHandlerContract(address addr) public virtual;
    function setVotingHandlerContract(address addr) public virtual;
    function setProposalTypeName(uint256 proposalTypeInt, string memory newProposalTypeName) external virtual;
    function setProposalContractAddress(uint256 proposalTypeInt, address addr) external virtual;
    function setProposalSettlerAddress(uint256 proposalTypeInt, address addr) external virtual;
    function setMinApprovalPct(uint256 _approvalPct) public virtual;
    function setMinVotersPct(uint256 _votersPct) public virtual;
    function addTeamAddress(address addr) external virtual;
    function removeTeamAddress(address addr) external virtual;
    function isRepresentative(address addr) public view virtual returns (bool);
    function isRepresentative(address addr, uint256 proposalTypeInt) public view virtual returns (bool);
    function isRepresentative(mapping(uint256 => uint8) storage addrRights) internal view virtual returns (bool);
    function isTeamAddress(address addr) public view virtual returns (bool);
    function isStakeholder(address addr) public view virtual returns (bool);
    function toggleRepresentativeRight(address addr, uint256 proposalTypeInt) public virtual;
    function toggleRepresentativeRights(address addr, uint256[] calldata proposalTypeInts) public virtual;
    function createVoteConf(uint256 proposalTypeInt, uint256 proposalId, address author, uint256 durationDays) internal virtual returns (INyxVotingHandler.VoteConf memory);
    function updateVoteConf(uint256 proposalTypeInt, uint256 proposalId, address author, uint256 durationDays) external virtual returns (INyxVotingHandler.VoteConf memory);
    function makeVotable(uint256 proposalTypeInt, uint256 proposalId) external virtual;
    function votable(address votingAddress, INyxVotingHandler.VoteConf memory voteConf, bool failOnRequirements) public view virtual returns (bool);
    function vote(uint256 proposalTypeInt, uint256 proposalId, bool supportProposal) external virtual;
    function getStakeholderVotes(uint256 proposalTypeInt, address addr) public view virtual returns (INyxVotingHandler.Vote[] memory);
    function getProposalVotes(uint256 proposalTypeInt, uint256 proposalId) external view virtual returns (INyxVotingHandler.Vote[] memory);
    function getVoteConf(uint256 proposalTypeInt, uint256 proposalId) public view virtual returns (INyxVotingHandler.VoteConf memory);
    function getVoteConfs(uint256 proposalTypeInt) external view virtual returns (INyxVotingHandler.VoteConf[] memory);
    function getVotingPower(address addr, uint256 blockNumber) public view virtual returns (uint256);
    function getDelegateOperator(address voter) internal view virtual returns (address addrOut);
    function delegateVote(address to) external virtual;
    function undelegateVote() external virtual;
    function getNftTotalBalance(address addr) public view virtual returns (uint256);
    function getProposalType(uint256 proposalTypeInt) external view virtual returns (INyxProposalRegistry.ProposalType memory);
    function getNumOfProposalTypes() public view virtual returns (uint256);
    function addProposalType(string memory proposalTypeName, address proposalHandlerAddr, address proposalSettlerAddr) external virtual;
    function getNumOfProposals(uint256 proposalTypeInt) public view virtual returns (uint256);
    function setConverterAddress(address addr) external virtual;
    function getProposalConf(uint256 proposalTypeInt, uint256 proposalId) external view virtual;
    function setProposalConf(INyxProposalHandler.ProposalConf memory proposalConf) external virtual;
    function createProposal(uint256 proposalTypeInt, bytes[] memory params, uint256 durationDays) external virtual returns (uint256);
    function deleteProposal(uint256 proposalTypeInt, uint256 proposalId) external virtual;
    function getProposalConfs(uint256 proposalTypeInt) external view virtual returns (INyxProposalHandler.ProposalConf[] memory);
    function getProposal(uint256 proposalTypeInt, uint256 proposalId) external view virtual returns (bytes[] memory);
    function getProposals(uint256 proposalTypeInt) external view virtual returns (bytes[][] memory);
    function getProposalReadable(uint256 proposalTypeInt, uint256 proposalId) external view virtual returns (INyxProposalHandler.ProposalReadable memory);
    function getProposalReadables(uint256 proposalTypeInt) external view virtual returns (INyxProposalHandler.ProposalReadable[] memory);
    function settleProposal(uint256 proposalTypeInt, uint256 proposalId) external virtual;
    function closeRedeem() public virtual;
    function openRedeem(uint256 liquidity, uint256 pricePerReedemPower) public virtual;
    function getRedeemPrice(uint256 tokenId) public view virtual returns (uint256);
    function redeem(uint56 nNfts, uint256 tokenId) public virtual;

    // Events
    ///////////////////
    event SettledProposal(address indexed proposer, uint256 proposalType, uint256 proposalId, bool approved);
}

// SPDX-License-Identifier: MIT

// @title INyxVault for Nyx DAO
// @author TheV

//  ________       ___    ___ ___    ___      ________  ________  ________     
// |\   ___  \    |\  \  /  /|\  \  /  /|    |\   ___ \|\   __  \|\   __  \    
// \ \  \\ \  \   \ \  \/  / | \  \/  / /    \ \  \_|\ \ \  \|\  \ \  \|\  \   
//  \ \  \\ \  \   \ \    / / \ \    / /      \ \  \ \\ \ \   __  \ \  \\\  \  
//   \ \  \\ \  \   \/  /  /   /     \/        \ \  \_\\ \ \  \ \  \ \  \\\  \ 
//    \ \__\\ \__\__/  / /    /  /\   \         \ \_______\ \__\ \__\ \_______\
//     \|__| \|__|\___/ /    /__/ /\ __\         \|_______|\|__|\|__|\|_______|
//               \|___|/     |__|/ \|__|                       

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface GnosisSafe {
    enum Operation {
        Call,
        DelegateCall
    }

    /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(address to, uint256 value, bytes calldata data, GnosisSafe.Operation operation)
        external
        returns (bool success);

    function isModuleEnabled(address moduleAddress) external returns (bool);
}

abstract contract INyxVault is Ownable
{
    // Enums
    ///////////////////
    enum VaultType
    {
        Crypto,
        NFT,
        VC
    }

    // Attributes
    ///////////////////
    mapping(address => int8) public approvedCallers;
    
    uint256 lockedLiquidity;
    
    address public gnosisSafeAddress;
    address cryptoVault;
    address NFTVault;
    address VCVault;

    GnosisSafe public gnosisSafe;
    
    // Functions
    ///////////////////
    function setupGnosis(address addr) external virtual;
    function setCryptoVault(address addr) external virtual;
    function setNftVault(address addr) external virtual;
    function setVCVault(address addr) external virtual;
    function transfer(address token, address payable to, uint96 amount) public virtual;
    function makeAllocation(uint256[3] calldata allocation) external virtual;
    function redeem(address payable to, uint256 amount) external virtual;
    function lockLiquidity(uint256 amount) external virtual;
    function resetLockedLiquidity() external virtual;
}

// SPDX-License-Identifier: MIT

// @title INyxDAO for Nyx DAO
// @author TheV

//  ________       ___    ___ ___    ___      ________  ________  ________     
// |\   ___  \    |\  \  /  /|\  \  /  /|    |\   ___ \|\   __  \|\   __  \    
// \ \  \\ \  \   \ \  \/  / | \  \/  / /    \ \  \_|\ \ \  \|\  \ \  \|\  \   
//  \ \  \\ \  \   \ \    / / \ \    / /      \ \  \ \\ \ \   __  \ \  \\\  \  
//   \ \  \\ \  \   \/  /  /   /     \/        \ \  \_\\ \ \  \ \  \ \  \\\  \ 
//    \ \__\\ \__\__/  / /    /  /\   \         \ \_______\ \__\ \__\ \_______\
//     \|__| \|__|\___/ /    /__/ /\ __\         \|_______|\|__|\|__|\|_______|
//               \|___|/     |__|/ \|__|                       

pragma solidity >=0.8.0;

abstract contract INyxNFT
{
    address public vault_address;
    uint256 public BASE_VOTING_POWER;
    uint256 public BASE_REDEEM_RATIO;
    uint256 public currentTokenId;
    bool public isMinting;
    mapping(uint256 => uint256) public wavePrice;
    mapping(uint256 => uint256) public waveCurrentSupply;
    mapping(uint256 => uint256) public waveVotingPower;
    mapping(uint256 => uint256) public waveRedeemRatio;
    mapping(address => bool) public approved;

    function getCurrentSupply() public virtual view returns(uint256);
    function isHolder(address addr, uint256 tokenId) public virtual view returns(bool);
    function balanceOf(address addr, uint256 tokenId) public virtual view returns(uint256);
    function balanceOfAtBlock(address addr, uint256 tokenId, uint256 blockNumber) public virtual view returns(uint256);
    function burnNFT(address fromAddress, uint256 amount, uint256 tokenId) public virtual;
    function isApprovedForAll(address account, address operator) public virtual returns (bool);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) public virtual;
    function toggleMintingState() public virtual;
    function createNewTokenId(uint256 _wavePrice, uint256 _waveMintableSupply, uint256 votingPower, uint256 redeemRatio,
        uint256 teamMintPct, uint256 teamFeePct) public virtual;
}

// SPDX-License-Identifier: MIT

// @title INyxProposalSettlerHandler for Nyx DAO
// @author TheV

//  ________       ___    ___ ___    ___      ________  ________  ________     
// |\   ___  \    |\  \  /  /|\  \  /  /|    |\   ___ \|\   __  \|\   __  \    
// \ \  \\ \  \   \ \  \/  / | \  \/  / /    \ \  \_|\ \ \  \|\  \ \  \|\  \   
//  \ \  \\ \  \   \ \    / / \ \    / /      \ \  \ \\ \ \   __  \ \  \\\  \  
//   \ \  \\ \  \   \/  /  /   /     \/        \ \  \_\\ \ \  \ \  \ \  \\\  \ 
//    \ \__\\ \__\__/  / /    /  /\   \         \ \_______\ \__\ \__\ \_______\
//     \|__| \|__|\___/ /    /__/ /\ __\         \|_______|\|__|\|__|\|_______|
//               \|___|/     |__|/ \|__|       

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../nyx_proposals_settlers/NyxProposalSettler.sol";
import "../NyxProposalRegistry.sol";

abstract contract INyxProposalSettlerHandler is Ownable {
    mapping(uint256 => NyxProposalSettler) public proposalSettlerAddresses;
    NyxProposalRegistry registry;

    function setProposalRegistry(address addr) public virtual;
    // function addProposalSettler(string memory proposalTypeName, address addr) public virtual;
    // function setProposalSettlerAddress(uint256 proposalTypeInt, address addr) public virtual;
    function settleProposal(uint256 proposalTypeInt, bytes[] calldata params) public virtual returns (bool);
}

// SPDX-License-Identifier: MIT

// @title INyxVotingHandler for Nyx DAO
// @author TheV

//  ________       ___    ___ ___    ___      ________  ________  ________     
// |\   ___  \    |\  \  /  /|\  \  /  /|    |\   ___ \|\   __  \|\   __  \    
// \ \  \\ \  \   \ \  \/  / | \  \/  / /    \ \  \_|\ \ \  \|\  \ \  \|\  \   
//  \ \  \\ \  \   \ \    / / \ \    / /      \ \  \ \\ \ \   __  \ \  \\\  \  
//   \ \  \\ \  \   \/  /  /   /     \/        \ \  \_\\ \ \  \ \  \ \  \\\  \ 
//    \ \__\\ \__\__/  / /    /  /\   \         \ \_______\ \__\ \__\ \_______\
//     \|__| \|__|\___/ /    /__/ /\ __\         \|_______|\|__|\|__|\|_______|
//               \|___|/     |__|/ \|__|       

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "nyx_nft/interfaces/INyxNft.sol";
import "nyx_dao/NyxRoleManager.sol";

abstract contract INyxVotingHandler is Ownable, NyxRoleManager {
    // Structs
    ///////////////////
    struct Vote
    {
        uint votedDatetime;
        address voter;
        bool approved;
    }

    struct VoteConf
    {
        uint256 proposalTypeInt;
        uint256 proposalId;
        address author;
        bool isProposedToVote;
        bool votingPassed;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 livePeriod;
        address[] voters;
        uint256 creationTime;
        uint256 creationBlock;
    }

    // Attributes
    ///////////////////
    mapping(uint256 => uint256) public numOfVoteConfs;
    // mapping(uint256 => VoteConf[]) public voteConfMapping;
    mapping(uint256 => mapping(uint256 => VoteConf)) public voteConfMapping;
    mapping(address => mapping(uint256 => mapping(uint256 => Vote))) public stakeholderVotes;
    mapping(uint256 => mapping(uint256 => Vote[])) public proposalVotes;
    mapping(address => address[]) public delegateOperatorToVoters;
    mapping(address => address) public delegateVoterToOperator;

    INyxNFT public nft_contract;

    // Modifiers
    ///////////////////
    modifier onlyExistingProposal(uint256 proposalTypeInt, uint256 proposalId)
    {
        require(voteConfMapping[proposalTypeInt][proposalId].creationTime != 0, "proposal doesn't exists");
        _;
    }

    modifier withNftSetted()
    {
        require(address(nft_contract) != address(0), "you have to set nft contract address first");
        _;
    }

    // Functions
    ////////////////////
    function setNftContract(address addr) external virtual;
    function createVoteConf(uint256 proposalTypeInt, uint256 proposalId, address author, uint256 durationDays) external virtual returns (VoteConf memory);
    function updateVoteConf(uint256 proposalTypeInt, uint256 proposalId, address author, uint256 durationDays) external virtual returns (VoteConf memory);
    function makeVotable(uint256 proposalTypeInt, uint256 proposalId) external virtual;
    function votable(address votingAddress, VoteConf memory voteConf, bool failOnRequirements) public virtual view returns (bool);
    function voteOne(address voter, VoteConf storage voteConf, bool supportProposal, bool failOnRequirements) internal virtual returns (VoteConf storage);
    function vote(address voter, uint256 proposalTypeInt, uint256 proposalId, bool supportProposal) external virtual;
    function getStakeholderVotes(uint256 proposalTypeInt, address addr) external virtual view returns (Vote[] memory);
    function getVotingPower(address addr, uint256 blockNumber) public virtual view returns (uint256);
    function getProposalVotes(uint256 proposalTypeInt, uint256 proposalId) external virtual view returns (Vote[] memory);
    function getProposalsVotes(uint256 proposalTypeInt) external virtual view returns (Vote[][] memory);
    function getVoteConf(uint256 proposalTypeInt, uint256 proposalId) external virtual view returns (VoteConf memory);
    function getVoteConfs(uint256 proposalTypeInt) external virtual view returns (VoteConf[] memory);
    function getDelegateOperator(address voter) external virtual view returns (address addrOut);
    function delegateVote(address voter, address to) external virtual;
    function undelegateVote(address voter) external virtual;

    // Events
    ///////////////////

    event VoteConfCreated(uint256 indexed proposalTypeInt, uint256 proposalId, address author);
    event ApprovedForVoteProposal(uint256 indexed proposalTypeInt, uint256 proposalId);
    event VotedProposal(address indexed voter, uint256 proposalTypeInt, uint256 proposalId);
    event DelegatedVote(address indexed from, address to);
    event UndelegatedVote(address indexed from, address to);
}

// SPDX-License-Identifier: MIT

// @title INyxProposalHandler for Nyx DAO
// @author TheV

//  ________       ___    ___ ___    ___      ________  ________  ________     
// |\   ___  \    |\  \  /  /|\  \  /  /|    |\   ___ \|\   __  \|\   __  \    
// \ \  \\ \  \   \ \  \/  / | \  \/  / /    \ \  \_|\ \ \  \|\  \ \  \|\  \   
//  \ \  \\ \  \   \ \    / / \ \    / /      \ \  \ \\ \ \   __  \ \  \\\  \  
//   \ \  \\ \  \   \/  /  /   /     \/        \ \  \_\\ \ \  \ \  \ \  \\\  \ 
//    \ \__\\ \__\__/  / /    /  /\   \         \ \_______\ \__\ \__\ \_______\
//     \|__| \|__|\___/ /    /__/ /\ __\         \|_______|\|__|\|__|\|_______|
//               \|___|/     |__|/ \|__|                       

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "nyx_dao/nyx_proposals/NyxProposal.sol";
import "nyx_dao/NyxProposalRegistry.sol";
import "utils/Converter.sol";
import "nyx_dao/NyxRoleManager.sol";

abstract contract INyxProposalHandler is Ownable, NyxRoleManager
{
    // Enums
    ////////////////////
    // enum ProposalType{Investment, Revenue, Governance, Allocation, Free, WL, Representative, Quorum, SendToken, Mint, Redeem}

    // Structs
    ////////////////////
    struct Proposal
    {
        bytes params;
        ProposalConf conf;
    }

    struct ProposalReadable
    {
        bytes[] params;
        ProposalConf conf;
    }

    struct ProposalConf
    {
        uint256 id;
        uint256 proposalTypeInt;
        uint256 creationTime;
        uint256 creationBlock;
        bool settled;
        address proposer;
        address settledBy;
        bool approved;
    }

    // Attributes
    ////////////////////
    mapping(uint256 => uint256) public numOfProposals;
    // mapping(uint256 => Proposal[]) public proposalMapping;
    mapping(uint256 => mapping(uint256 => Proposal)) public proposalMapping;

    Converter converterContract = Converter(0xB23e433BD8B53Ce077b91A831F80167272337e15);
    NyxProposalRegistry registry;

    // Modifiers
    ////////////////////
    modifier withProposalRegistrySetted()
    {
        require(address(registry) != address(0), "ProposalRegistry have to be setted");
        _;
    }

    modifier onlyExistingProposalType(uint256 proposalTypeInt)
    {
        require(proposalTypeInt > 0, "proposalType id have to be > 0");
        require(proposalTypeInt <= registry.numOfProposalTypes(), "proposalType doesn't exists");
        _;
    }

    // Functions
    ////////////////////
    function setProposalRegistry(address addr) public virtual;
    function setConverterAddress(address addr) external virtual;
    function getProposalConf(uint256 proposalTypeInt, uint256 proposalId) external view virtual returns(ProposalConf memory);
    function setProposalConf(ProposalConf calldata proposalConf) external virtual;
    function createProposal(uint256 proposalTypeInt, bytes[] calldata params, address author) public virtual returns(uint256);
    function getProposal(uint256 proposalTypeInt, uint256 proposalId) public view virtual returns (bytes[] memory);
    function getProposals(uint256 proposalTypeInt) public view virtual returns (bytes[][] memory);
    function getProposalReadable(uint256 proposalTypeInt, uint256 proposalId) public view virtual returns (ProposalReadable memory);
    function getProposalReadables(uint256 proposalTypeInt) public view virtual returns (ProposalReadable[] memory);
    function getProposalConfs(uint256 proposalTypeInt) external view virtual returns (ProposalConf[] memory);
    function deleteProposal(uint256 proposalTypeInt, uint256 proposalId) public virtual;

    // Events
    ///////////////////
    event CreatedProposal(address indexed proposer, uint256 proposalType, uint256 proposalId);
    event DeletedProposal(uint256 proposalType, uint256 proposalId);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
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

// @title NyxRoleManager for Nyx DAO
// @author TheV

//  ________       ___    ___ ___    ___      ________  ________  ________     
// |\   ___  \    |\  \  /  /|\  \  /  /|    |\   ___ \|\   __  \|\   __  \    
// \ \  \\ \  \   \ \  \/  / | \  \/  / /    \ \  \_|\ \ \  \|\  \ \  \|\  \   
//  \ \  \\ \  \   \ \    / / \ \    / /      \ \  \ \\ \ \   __  \ \  \\\  \  
//   \ \  \\ \  \   \/  /  /   /     \/        \ \  \_\\ \ \  \ \  \ \  \\\  \ 
//    \ \__\\ \__\__/  / /    /  /\   \         \ \_______\ \__\ \__\ \_______\
//     \|__| \|__|\___/ /    /__/ /\ __\         \|_______|\|__|\|__|\|_______|
//               \|___|/     |__|/ \|__|       

pragma solidity ^0.8.0;

import "./interfaces/INyxRoleManager.sol";

contract NyxRoleManager is INyxRoleManager {
    // string public constant name = "NyxRoleManager";

    // Main Functions
    ///////////////////////
    function isApproved(address addr)
        public view
        override
        returns (bool)
    {
        return approvedCallers[addr] == 1;
    }

    function toggleApprovedCaller(address addr)
        external
        override
        onlyOwner
    {
        if (approvedCallers[addr] == 1)
        {
            approvedCallers[addr] = 0;
        }
        else

        {
            approvedCallers[addr] = 1;
        }
    }
}

// SPDX-License-Identifier: MIT

// @title NyxProposalRegistry for Nyx DAO
// @author TheV

//  ________       ___    ___ ___    ___      ________  ________  ________     
// |\   ___  \    |\  \  /  /|\  \  /  /|    |\   ___ \|\   __  \|\   __  \    
// \ \  \\ \  \   \ \  \/  / | \  \/  / /    \ \  \_|\ \ \  \|\  \ \  \|\  \   
//  \ \  \\ \  \   \ \    / / \ \    / /      \ \  \ \\ \ \   __  \ \  \\\  \  
//   \ \  \\ \  \   \/  /  /   /     \/        \ \  \_\\ \ \  \ \  \ \  \\\  \ 
//    \ \__\\ \__\__/  / /    /  /\   \         \ \_______\ \__\ \__\ \_______\
//     \|__| \|__|\___/ /    /__/ /\ __\         \|_______|\|__|\|__|\|_______|
//               \|___|/     |__|/ \|__|       

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/INyxProposalRegistry.sol";

contract NyxProposalRegistry is INyxProposalRegistry, Ownable {
    string public constant name = "NyxProposalRegistry";

    // Enums
    ////////////////////
    // enum ProposalType{Investment, Revenue, Governance, Allocation, Free, WL, Representative, Quorum, SendToken, Mint, Redeem}

    // Structs
    ////////////////////
    mapping(address => int8) public approvedCallers;

    // Constructor
    ////////////////////
    constructor()
    {
        proposalTypeMapping[0] = ProposalType(0, "None", address(0), address(0));
        proposalHandlerAddresses[0] = NyxProposal(address(0));
        proposalSettlerAddresses[0] = NyxProposalSettler(address(0));
    }

    // Modifers
    ////////////////////
    modifier onlyApproved
    {
        require(approvedCallers[msg.sender] == 1 || msg.sender == owner(), "not approved");
        _;
    }

    modifier onlyExistingProposalType(uint256 proposalTypeInt)
    {
        require(proposalTypeInt > 0, "proposalType id have to be > 0");
        require(proposalTypeInt <= numOfProposalTypes, "proposalType doesn't exists");
        _;
    }

    // Attributes Getters & Setters
    /////////////////////

    function getProposalType(uint256 proposalTypeInt)
        public view
        override
        returns (ProposalType memory)
    {
        return proposalTypeMapping[proposalTypeInt];
    }

    function isApproved(address addr)
        public view
        returns (bool)
    {
        return approvedCallers[addr] == 1;
    }

    function addProposalType(string calldata proposalTypeName, address proposalHandlerAddr, address proposalSettlerAddr)
        public
        override
        onlyApproved
    {
        uint256 proposalTypeId = ++numOfProposalTypes;
        proposalTypeMapping[proposalTypeId] = ProposalType(proposalTypeId, proposalTypeName, proposalHandlerAddr, proposalSettlerAddr);
        proposalHandlerAddresses[proposalTypeId] = NyxProposal(proposalHandlerAddr);
        proposalSettlerAddresses[proposalTypeId] = NyxProposalSettler(proposalSettlerAddr);
    }

    function toggleApprovedCaller(address addr)
        external
        onlyOwner
    {
        if (approvedCallers[addr] == 1)
        {
            approvedCallers[addr] = 0;
        }
        else
        
        {
            approvedCallers[addr] = 1;
        }
    }

    function setProposalTypeName(uint256 proposalTypeInt, string calldata newProposalTypeName)
        public
        override
        onlyApproved onlyExistingProposalType(proposalTypeInt)
    {
        ProposalType storage proposalType = proposalTypeMapping[proposalTypeInt];
        proposalType.name = newProposalTypeName;
    }

    function setProposalContractAddress(uint256 proposalTypeInt, address addr)
        public
        override
        onlyApproved onlyExistingProposalType(proposalTypeInt)
    {
        proposalHandlerAddresses[proposalTypeInt] = NyxProposal(addr);
        proposalTypeMapping[proposalTypeInt].contract_address = addr;
    }

    function setProposalSettlerAddress(uint256 proposalTypeInt, address addr)
        public
        override
        onlyApproved onlyExistingProposalType(proposalTypeInt)
    {
        proposalSettlerAddresses[proposalTypeInt] = NyxProposalSettler(addr);
        proposalTypeMapping[proposalTypeInt].settler_address = addr;
    }
}

// SPDX-License-Identifier: MIT

// @title NyxProposal for Nyx DAO
// @author TheV

//  ________       ___    ___ ___    ___      ________  ________  ________     
// |\   ___  \    |\  \  /  /|\  \  /  /|    |\   ___ \|\   __  \|\   __  \    
// \ \  \\ \  \   \ \  \/  / | \  \/  / /    \ \  \_|\ \ \  \|\  \ \  \|\  \   
//  \ \  \\ \  \   \ \    / / \ \    / /      \ \  \ \\ \ \   __  \ \  \\\  \  
//   \ \  \\ \  \   \/  /  /   /     \/        \ \  \_\\ \ \  \ \  \ \  \\\  \ 
//    \ \__\\ \__\__/  / /    /  /\   \         \ \_______\ \__\ \__\ \_______\
//     \|__| \|__|\___/ /    /__/ /\ __\         \|_______|\|__|\|__|\|_______|
//               \|___|/     |__|/ \|__|       

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "utils/Converter.sol";
import "nyx_dao/nyx_proposals/NyxProposal.sol";
// import "../interfaces/INyxDao.sol";

abstract contract NyxProposalSettler is Ownable, Converter {
    // INyxDAO dao;
    // NyxNFT nft;

    // modifier withDAOSetted()
    // {
    //     require(address(dao) != address(0), "you have to set dao contract first");
    //     _;
    // }

    // modifier withNFTSetted()
    // {
    //     require(address(nft) != address(0), "you have to set dao contract first");
    //     _;
    // }

    // modifier withApprovedByNFT(address addr)
    // {
    //     require(nft.approved(addr), "you have to set dao contract first");
    //     _;
    // }

    function settleProposal(bytes[] calldata params) public virtual returns(bool);
}

// SPDX-License-Identifier: MIT

// @title INyxDAO for Nyx DAO
// @author TheV

//  ________       ___    ___ ___    ___      ________  ________  ________     
// |\   ___  \    |\  \  /  /|\  \  /  /|    |\   ___ \|\   __  \|\   __  \    
// \ \  \\ \  \   \ \  \/  / | \  \/  / /    \ \  \_|\ \ \  \|\  \ \  \|\  \   
//  \ \  \\ \  \   \ \    / / \ \    / /      \ \  \ \\ \ \   __  \ \  \\\  \  
//   \ \  \\ \  \   \/  /  /   /     \/        \ \  \_\\ \ \  \ \  \ \  \\\  \ 
//    \ \__\\ \__\__/  / /    /  /\   \         \ \_______\ \__\ \__\ \_______\
//     \|__| \|__|\___/ /    /__/ /\ __\         \|_______|\|__|\|__|\|_______|
//               \|___|/     |__|/ \|__|       

pragma solidity ^0.8.0;

import "./IConverter.sol";

contract Converter is IConverter {
    function stringToBytes(string memory str)
        public pure
        returns (bytes memory)
    {
        return bytes(str);
    }

    function bytesToString(bytes memory strBytes)
        public pure
        returns (string memory)
    {
        return string(strBytes);
    }

    function stringArrayToBytesArray(string[] memory strArray)
        public pure
        returns (bytes[] memory)
    {
        bytes[] memory bytesArray = new bytes[](strArray.length);
        for (uint256 idx = 0; idx < strArray.length; idx++)
        {
            bytes memory bytesElem = bytes(strArray[idx]);
            bytesArray[idx] = bytesElem;
        }
        return bytesArray;
    }

    function bytesArrayToStringAray(bytes[] memory bytesArray)
        public pure
        returns (string[] memory)
    {
        string[] memory strArray = new string[](bytesArray.length);
        for (uint256 idx = 0; idx < bytesArray.length; idx++)
        {
            string memory strElem = string(bytesArray[idx]);
            strArray[idx] = strElem;
        }
        return strArray;
    }

    function intToBytes(int256 i)
        public pure
        returns (bytes memory)
    {
        return abi.encodePacked(i);
    }

    function bytesToUint(bytes memory iBytes)
        public pure
        returns (uint256)
    {
        uint256 i;
        for (uint idx = 0; idx < iBytes.length; idx++)
        {
            i = i + uint(uint8(iBytes[idx])) * (2**(8 * (iBytes.length - (idx + 1))));
        }
        return i;
    }

    // function addressToBytes(address addr)
    //     public pure
    //     returns (bytes memory)
    // {
    //     return bytes(bytes8(uint64(uint160(addr))));
    // }

    function bytesToAddress(bytes memory addrBytes)
        public pure
        returns (address)
    {
        address addr;
        assembly
        {
            addr := mload(add(addrBytes,20))
        }
        return addr;
    }

    function bytesToBool(bytes memory boolBytes)
        public pure
        returns (bool)
    {
        return abi.decode(boolBytes, (bool));
    }

    function boolToBytes(bool b)
        public pure
        returns (bytes memory)
    {
        return abi.encode(b);
    }
}

// SPDX-License-Identifier: MIT

// @title NyxProposal for Nyx DAO
// @author TheV

//  ________       ___    ___ ___    ___      ________  ________  ________     
// |\   ___  \    |\  \  /  /|\  \  /  /|    |\   ___ \|\   __  \|\   __  \    
// \ \  \\ \  \   \ \  \/  / | \  \/  / /    \ \  \_|\ \ \  \|\  \ \  \|\  \   
//  \ \  \\ \  \   \ \    / / \ \    / /      \ \  \ \\ \ \   __  \ \  \\\  \  
//   \ \  \\ \  \   \/  /  /   /     \/        \ \  \_\\ \ \  \ \  \ \  \\\  \ 
//    \ \__\\ \__\__/  / /    /  /\   \         \ \_______\ \__\ \__\ \_______\
//     \|__| \|__|\___/ /    /__/ /\ __\         \|_______|\|__|\|__|\|_______|
//               \|___|/     |__|/ \|__|       

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "utils/Converter.sol";

abstract contract NyxProposal is Converter {
    // Proposal Creators
    /////////////////////

    function createProposal(uint256 proposalId, bytes[] memory params) external virtual pure returns (bytes memory);
    
    // Proposal Getters
    /////////////////////
    function getProposal(bytes memory proposalBytes) external virtual pure returns (bytes[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
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

// @title IConverter for Nyx DAO
// @author TheV

//  ________       ___    ___ ___    ___      ________  ________  ________     
// |\   ___  \    |\  \  /  /|\  \  /  /|    |\   ___ \|\   __  \|\   __  \    
// \ \  \\ \  \   \ \  \/  / | \  \/  / /    \ \  \_|\ \ \  \|\  \ \  \|\  \   
//  \ \  \\ \  \   \ \    / / \ \    / /      \ \  \ \\ \ \   __  \ \  \\\  \  
//   \ \  \\ \  \   \/  /  /   /     \/        \ \  \_\\ \ \  \ \  \ \  \\\  \ 
//    \ \__\\ \__\__/  / /    /  /\   \         \ \_______\ \__\ \__\ \_______\
//     \|__| \|__|\___/ /    /__/ /\ __\         \|_______|\|__|\|__|\|_______|
//               \|___|/     |__|/ \|__|                       

pragma solidity ^0.8.0;

interface IConverter
{
    function stringToBytes(string memory str) external pure returns (bytes memory);
    function bytesToString(bytes memory strBytes) external pure returns (string memory);
    function stringArrayToBytesArray(string[] memory strArray) external pure returns (bytes[] memory);
    function bytesArrayToStringAray(bytes[] memory bytesArray) external pure returns (string[] memory);
    function intToBytes(int256 i) external pure returns (bytes memory);
    function bytesToUint(bytes memory iBytes) external pure returns (uint256);
    function bytesToAddress(bytes memory addrBytes) external pure returns (address);
    function bytesToBool(bytes memory boolBytes) external pure returns (bool);
    function boolToBytes(bool b) external pure returns (bytes memory);
}

// SPDX-License-Identifier: MIT

// @title INyxRoleManager for Nyx DAO
// @author TheV

//  ________       ___    ___ ___    ___      ________  ________  ________     
// |\   ___  \    |\  \  /  /|\  \  /  /|    |\   ___ \|\   __  \|\   __  \    
// \ \  \\ \  \   \ \  \/  / | \  \/  / /    \ \  \_|\ \ \  \|\  \ \  \|\  \   
//  \ \  \\ \  \   \ \    / / \ \    / /      \ \  \ \\ \ \   __  \ \  \\\  \  
//   \ \  \\ \  \   \/  /  /   /     \/        \ \  \_\\ \ \  \ \  \ \  \\\  \ 
//    \ \__\\ \__\__/  / /    /  /\   \         \ \_______\ \__\ \__\ \_______\
//     \|__| \|__|\___/ /    /__/ /\ __\         \|_______|\|__|\|__|\|_______|
//               \|___|/     |__|/ \|__|                       

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract INyxRoleManager is Ownable
{
    // Attributes
    ////////////////////
    mapping(address => int8) public approvedCallers;

    // Modifiers
    ////////////////////
    modifier onlyApprovedOrOwner(address addr)
    {
        require(approvedCallers[addr] == 1 || addr == owner(), "Caller is not approved nor owner");
        _;
    }
    
    modifier onlyApproved(address addr)
    {
        require(approvedCallers[addr] == 1, "Caller is not approved");
        _;
    }

    // Functions
    ////////////////////
    function isApproved(address addr) public view virtual returns (bool);
    function toggleApprovedCaller(address addr) external virtual;
}

// SPDX-License-Identifier: MIT

// @title INyxProposalRegistry for Nyx DAO
// @author TheV

//  ________       ___    ___ ___    ___      ________  ________  ________     
// |\   ___  \    |\  \  /  /|\  \  /  /|    |\   ___ \|\   __  \|\   __  \    
// \ \  \\ \  \   \ \  \/  / | \  \/  / /    \ \  \_|\ \ \  \|\  \ \  \|\  \   
//  \ \  \\ \  \   \ \    / / \ \    / /      \ \  \ \\ \ \   __  \ \  \\\  \  
//   \ \  \\ \  \   \/  /  /   /     \/        \ \  \_\\ \ \  \ \  \ \  \\\  \ 
//    \ \__\\ \__\__/  / /    /  /\   \         \ \_______\ \__\ \__\ \_______\
//     \|__| \|__|\___/ /    /__/ /\ __\         \|_______|\|__|\|__|\|_______|
//               \|___|/     |__|/ \|__|                       

pragma solidity >=0.8.0;

import "../nyx_proposals/NyxProposal.sol";
import "../nyx_proposals_settlers/NyxProposalSettler.sol";

abstract contract INyxProposalRegistry
{
    struct ProposalType
    {
        uint256 id;
        string name;
        address contract_address;
        address settler_address;
    }

    uint256 public numOfProposalTypes;
    mapping(uint256 => ProposalType) public proposalTypeMapping;
    mapping(uint256 => NyxProposal) public proposalHandlerAddresses;
    mapping(uint256 => NyxProposalSettler) public proposalSettlerAddresses;

    function getProposalType(uint256 proposalTypeint) public view virtual returns(ProposalType memory);
    function addProposalType(string calldata proposalTypeName, address proposalHandlerAddr, address proposalSettlerAddr) external virtual;
    function setProposalTypeName(uint256 proposalTypeInt, string calldata newProposalTypeName) external virtual;
    function setProposalContractAddress(uint256 proposalTypeInt, address addr) external virtual;
    function setProposalSettlerAddress(uint256 proposalTypeInt, address addr) external virtual;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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