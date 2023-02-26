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

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./interfaces/INyxDAO.sol";

contract NyxDAO is INyxDAO
{
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

    modifier onlyExistingProposal(uint256 proposalTypeInt, uint256 proposalId)
    {
        require(voteConfMapping[proposalTypeInt][proposalId].creationTime != 0, "proposal doesn't exists");
        _;
    }

    // Attributes
    ///////////////////

    // bytes32 public constant STAKEHOLDER_ROLE = keccak256("STAKEHOLDER");
    uint256 public minVotersPct = 50;
    uint256 public minApprovalPct = 51;
    bool public redeemOpen;
    uint256 public currentRedeem;
    uint256 public maxRedeem;
    uint256 public redeemPricePerRedeemPower;
    uint256 public numOfRepresentatives;

    mapping(address => bool) public teamAddressesDict;
    mapping(uint256 => mapping(uint256 => VoteConf)) public voteConfMapping;
    // mapping(address => mapping(uint256 => Vote[])) public stakeholderVotes;
    mapping(address => mapping(uint256 => mapping(uint256 => Vote))) public stakeholderVotes;
    mapping(uint256 => mapping(uint256 => Vote[])) public proposalVotes;
    mapping(address => address[]) public delegateOperatorToVoters;
    mapping(address => address) public delegateVoterToOperator;
    mapping(address => mapping(uint256 => uint8)) public representativeRights;

    NyxNFT public nft_contract;
    NyxVaultSafeModule public nyx_vault_module_contract;
    INyxProposalHandler public proposalHandler;
    INyxProposalRegistry proposalRegistry;
    INyxProposalSettlerHandler proposalSettler;

    // Constructor
    /////////////////

    constructor()
    {
        teamAddressesDict[msg.sender] = true;
    }

    // External contract setters
    /////////////////////////////////////
    function setNftContract(address addr)
        public onlyOwner
    {
        nft_contract = NyxNFT(addr);
    }
    
    function setVaultModuleContract(address addr)
        public onlyOwner
    {
        nyx_vault_module_contract = NyxVaultSafeModule(addr);
    }

    function setProposalHandlerContract(address addr)
        public
        onlyOwner
    {
        proposalHandler = INyxProposalHandler(addr);
    }

    function setProposalRegistryContract(address addr)
        public
        onlyOwner
    {
        proposalRegistry = INyxProposalRegistry(addr);
    }

    function setProposalSettlerHandlerContract(address addr)
        public
        onlyOwner
    {
        proposalSettler = INyxProposalSettlerHandler(addr);
    }

    function setProposalContractAddress(uint256 proposalTypeInt, address addr)
        external
        onlyOwner withProposalRegistrySetted
    {
        proposalRegistry.setProposalContractAddress(proposalTypeInt, addr);
    }

    // Attributes Getters & Setters
    /////////////////////////////////////

    function syncAllVoteConf()
        public
        onlyOwner withProposalHandlerSetted
    {
        for (uint256 proposalTypeInt; proposalTypeInt <= getNumOfProposalTypes(); proposalTypeInt++)
        {
            syncVoteConf(proposalTypeInt);
        }
    }

    /**
    * @notice edit sync vote conf with existing proposal conf in the proposal handler. Used in case of redeployment
    * of the NyxDAO contract while INyxProposalHandler is not.
    *
    * @param proposalTypeInt porposal type number
    */
    function syncVoteConf(uint256 proposalTypeInt)
        public 
        onlyOwner withProposalHandlerSetted
    {
        for (uint256 idx = 0; idx < getNumOfProposals(proposalTypeInt); idx++)
        {
            VoteConf storage voteConf = voteConfMapping[proposalTypeInt][idx];
            if (voteConf.proposalTypeInt == 0)
            {
                INyxProposalHandler.ProposalConf memory proposalConf = proposalHandler.getProposalConf(proposalTypeInt, idx);
                voteConf.proposalTypeInt = proposalConf.proposalTypeInt;
                voteConf.proposalId = proposalConf.id;
                voteConf.author = proposalConf.proposer;
                voteConf.creationTime = proposalConf.creationTime;
                voteConf.creationBlock = proposalConf.creationBlock;
                // Setting to default 7 days because durationDays is lost in case of re-deployement
                voteConf.livePeriod = proposalConf.creationTime + 7 days;
            }   
        }
    }

    function closeRedeem()
        public 
        onlyOwner
    {
        redeemOpen = false;
    }

    function openRedeem(uint256 liquidity, uint256 pricePerReedemPower)
        public 
        onlyOwner withNftSetted
    {
        require(nft_contract.vault_address().balance >= liquidity, "Not enough balance in the vault to redeem that much");
        // nyx_vault_module_contract.lockLiquidity(liquidity * price);
        redeemOpen = true;
        currentRedeem = 0;
        maxRedeem = liquidity;
        redeemPricePerRedeemPower = pricePerReedemPower;
    }

    function setMinApprovalPct(uint256 _approvalPct)
        public
        withProposalHandlerSetted onlyProposalHandler
    {
        minApprovalPct = _approvalPct;
    }

    function setMinVotersPct(uint256 _votersPct)
        public
        withProposalHandlerSetted onlyProposalHandler
    {
        minVotersPct = _votersPct;
    }
    
    function isRepresentative(address addr)
        public view
        returns (bool)
    {
        mapping(uint256 => uint8) storage addrRights = representativeRights[addr];
        return isRepresentative(addrRights);
    }

    function isRepresentative(mapping(uint256 => uint8) storage addrRights)
        internal view
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

    function addTeamAddress(address addr)
        external onlyProposalHandler
    {
        teamAddressesDict[addr] = true;
    }

    function removeTeamAddress(address addr)
        external onlyProposalHandler
    {
        teamAddressesDict[addr] = false;
    }

    function isTeamAddress(address addr)
        public view
        returns (bool)
    {
        return teamAddressesDict[addr];
    }

    /**
    * @notice if a representative rights are true, set it to false and vice versa
    *
    * @param proposalTypeInt porposal type number
    */
    function toggleRepresentativeRight(address addr, uint256 proposalTypeInt)
        public
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
    * @notice Batch function for toggleRepresentativeRight
    *
    * @param proposalTypeInts porposal type number
    */
    function toggleRepresentativeRights(address addr, uint256[] calldata proposalTypeInts)
        public
        withProposalHandlerSetted onlyProposalHandler
    {
        for (uint256 idx = 0; idx < proposalTypeInts.length; idx++)
        {
            toggleRepresentativeRight(addr, proposalTypeInts[idx]);
        }
    }

    // Functions
    ////////////////////

    function createVoteConf(uint256 proposalTypeInt, uint256 proposalId, address author, uint256 durationDays)
        internal
        returns (VoteConf memory)
    {
        address[] memory voters;
        VoteConf memory voteConf = VoteConf(proposalTypeInt, proposalId, author, false, false, 0, 0, block.timestamp + (durationDays * 1 days),
            voters, block.timestamp, block.number);
        voteConfMapping[proposalTypeInt][proposalId] = voteConf;
        return voteConf;        
    }

    function updateVoteConf(uint256 proposalTypeInt, uint256 proposalId, address author, uint256 durationDays)
        external
        onlyOwner onlyExistingProposal(proposalTypeInt, proposalId)
        returns (VoteConf memory)
    {
        VoteConf memory currentVoteConf = voteConfMapping[proposalTypeInt][proposalId];
        require(currentVoteConf.proposalTypeInt == 0, "can't update a vote conf that is correctly setted up");
        address[] memory voters;
        VoteConf memory voteConf = VoteConf(proposalTypeInt, proposalId, author, false, false, 0, 0, block.timestamp + (durationDays * 1 days),
            voters, block.timestamp, block.number);
        voteConfMapping[proposalTypeInt][proposalId] = voteConf;
        return voteConf;        
    }

    function getNftTotalBalance(address addr)
        public view
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

    function getVotingPower(address addr, uint256 blockNumber)
        public view
        withNftSetted
        returns (uint256)
    {
        uint256 votingPower = 0;
        for (uint tid = 0; tid <= nft_contract.currentTokenId(); tid++)
        {
            uint256 tokenIdVotingPower = nft_contract.waveVotingPower(tid);
            // votingPower += nft_contract.balanceOf(addr, tid) * tokenIdVotingPower;
            votingPower += nft_contract.balanceOfAtBlock(addr, tid, blockNumber) * tokenIdVotingPower;
            
        }
        return votingPower;
    }

    function makeVotable(uint256 proposalTypeInt, uint256 proposalId)
        external
        onlyAllowedRepresentatives(proposalTypeInt) withProposalHandlerSetted
    {
        VoteConf storage voteConf = voteConfMapping[proposalTypeInt][proposalId];
        require(!voteConf.isProposedToVote);
        voteConf.isProposedToVote = true;

        emit ApprovedForVoteProposal(proposalHandler.getProposalConf(proposalTypeInt, proposalId).proposer, proposalTypeInt, proposalId);
    }

    function votable(address votingAddress, VoteConf memory voteConf, bool failOnRequirements)
        public view
        returns (bool)
    {
        require(!voteConf.votingPassed && (voteConf.livePeriod > block.timestamp), "Voting period has passed on this proposal");
        require(voteConf.isProposedToVote, "Proposal wasn't approved for vote yet");

        // No double voting, no vote update
        if (failOnRequirements)
        {
            require(stakeholderVotes[votingAddress][voteConf.proposalTypeInt][voteConf.proposalId].votedDatetime == 0, "Voter already voted on this proposal");
            return true;
        }
        else
        {
            if (stakeholderVotes[votingAddress][voteConf.proposalTypeInt][voteConf.proposalId].votedDatetime == 0)
            {
                return true;
            }
            else
            {
                return false;
            } 
        }
    }

    function voteOne(address voter, VoteConf storage voteConf, bool supportProposal, bool failOnRequirements)
        internal
        onlyStakeholder("Only stakeholders are allowed to vote")
        returns (VoteConf storage)
    {
        uint256 votingPower = getVotingPower(voter, voteConf.creationBlock);
        require(votingPower > 0, "Not enough voting power to vote");
        if (votingPower > 0 && votable(voter, voteConf, failOnRequirements))
        {
            Vote memory senderVote = Vote(block.timestamp, voter, supportProposal);
            stakeholderVotes[voter][voteConf.proposalTypeInt][voteConf.proposalId] = senderVote;
            // Vote[] storage senderVotes = stakeholderVotes[voter][voteConf.proposalTypeInt];
            // senderVotes[voteConf.proposalId] = senderVote;
            // if (senderVotes.length >= voteConf.proposalId)
            // {
            //     senderVotes[voteConf.proposalId] = senderVote;
            // }
            // else
            // {
            //     senderVotes.push(senderVote);
            // }
            
            proposalVotes[voteConf.proposalTypeInt][voteConf.proposalId].push(senderVote);

            if (supportProposal)
            {
                voteConf.votesFor = voteConf.votesFor + votingPower;
            }
            else
            {
                voteConf.votesAgainst = voteConf.votesAgainst + votingPower;
            }

            voteConf.voters.push(voter);
        }

        return voteConf;
    }

    function vote(uint256 proposalTypeInt, uint256 proposalId, bool supportProposal)
        external
        onlyStakeholder("Only stakeholders are allowed to vote") onlyExistingProposal(proposalTypeInt, proposalId)
    {
        VoteConf storage conf = voteConfMapping[proposalTypeInt][proposalId];
        
        // Voting on behalf of delegatees
        address[] memory voters = delegateOperatorToVoters[msg.sender];
        for (uint256 iVoter = 0; iVoter < voters.length; iVoter++)
        {
            address voter = voters[iVoter];
            if (voter != address(0))
            {
                conf = voteOne(voter, conf, supportProposal, false);
            }
        }

        // Voting for self
        voteOne(msg.sender, conf, supportProposal, true);
    }

    function setProposalTypeName(uint256 proposalTypeInt, string memory newProposalTypeName)
        external
        onlyOwner withProposalRegistrySetted
    {
        proposalRegistry.setProposalTypeName(proposalTypeInt, newProposalTypeName);
    }

    function getStakeholderVotes(uint256 proposalTypeInt, address addr)
        public
        view
        onlyStakeholder("User is not a stakeholder")
        returns (Vote[] memory)
    {
        Vote[] memory addrVotes = new Vote[](getNumOfProposals(proposalTypeInt));
        for (uint256 proposalId; proposalId < addrVotes.length; proposalId++)
        {
            Vote memory oneAddrVote = stakeholderVotes[addr][proposalTypeInt][proposalId];
            addrVotes[proposalId] = oneAddrVote;
        }
        return addrVotes;
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
        withNftSetted
        returns (bool)
    {
        uint256 totalBalance = getNftTotalBalance(addr);      
        return totalBalance > 0;
    }

    function getVoteConfs(uint256 proposalTypeInt)
        external view
        withProposalHandlerSetted
        returns (VoteConf[] memory)
    {
        uint256 numOfProposals = getNumOfProposals(proposalTypeInt);
        VoteConf[] memory voteConfs = new VoteConf[](numOfProposals);
        for (uint256 idx = 0; idx < numOfProposals; idx++)
        {
            voteConfs[idx] = voteConfMapping[proposalTypeInt][idx];
        }
        return voteConfs;
    }

    // Proposal Handler Wrappers
    ///////////////////////////////////

    function getProposalType(uint256 proposalTypeInt)
        external view
        withProposalRegistrySetted
        returns (INyxProposalRegistry.ProposalType memory)
    {
        return proposalRegistry.getProposalType(proposalTypeInt);
    }

    function getNumOfProposalTypes()
        public view
        withProposalRegistrySetted
        returns (uint256)
    {
        return proposalRegistry.numOfProposalTypes();
    }

    function getNumOfProposals(uint256 proposalTypeInt)
        public view
        withProposalHandlerSetted
        returns (uint256)
    {
        return proposalHandler.numOfProposals(proposalTypeInt);
    }

    function addProposalType(string memory proposalTypeName, address proposalHandlerAddr)
        external
        onlyOwner withProposalRegistrySetted
    {
        proposalRegistry.addProposalType(proposalTypeName, proposalHandlerAddr);
    }

    function setConverterAddress(address addr)
        external
        onlyOwner withProposalHandlerSetted
    {
        proposalHandler.setConverterAddress(addr);
    }

    function getProposalConf(uint256 proposalTypeInt, uint256 proposalId)
        external view
        onlyOwner withProposalHandlerSetted
    {
        proposalHandler.getProposalConf(proposalTypeInt, proposalId);
    }

    function setProposalConf(uint256 proposalTypeInt, uint256 proposalId, INyxProposalHandler.ProposalConf memory proposalConf)
        external
        onlyOwner withProposalHandlerSetted
    {
        proposalHandler.setProposalConf(proposalTypeInt, proposalId, proposalConf);
    }

    function createProposal(uint256 proposalTypeInt, bytes[] memory params, uint256 durationDays)
        external
        onlyStakeholder("Only stakeholders are allowed to create proposals") withProposalHandlerSetted
        returns (uint256)
    {
        uint256 proposalId = proposalHandler.createProposal(proposalTypeInt, params, msg.sender);
        createVoteConf(proposalTypeInt, proposalId, msg.sender, durationDays);

        emit NewProposal(msg.sender, proposalTypeInt, proposalId);

        return proposalId;
    }

    function deleteProposal(uint256 proposalTypeInt, uint256 proposalId)
        external
        onlyOwner withProposalHandlerSetted
    {
        proposalHandler.deleteProposal(proposalTypeInt, proposalId);

        emit DeleteProposal(proposalTypeInt, proposalId);
    }

    function getProposalConfs(uint256 proposalTypeInt)
        external view
        withProposalHandlerSetted
        returns (INyxProposalHandler.ProposalConf[] memory)
    {
        return proposalHandler.getProposalConfs(proposalTypeInt);
    }
    
    function getProposal(uint256 proposalTypeInt, uint256 proposalId)
        external view
        withProposalHandlerSetted
        returns (bytes[] memory)
    {
        return proposalHandler.getProposal(proposalTypeInt, proposalId);
    }
    
    function getProposals(uint256 proposalTypeInt)
        external view
        withProposalHandlerSetted
        returns (bytes[][] memory)
    {
        return proposalHandler.getProposals(proposalTypeInt);
    }

    function getProposalReadable(uint256 proposalTypeInt, uint256 proposalId)
        external view
        withProposalHandlerSetted
        returns (INyxProposalHandler.ProposalReadable memory)
    {
        return proposalHandler.getProposalReadable(proposalTypeInt, proposalId);
    }

    function getProposalReadables(uint256 proposalTypeInt)
        external view
        withProposalHandlerSetted
        returns (INyxProposalHandler.ProposalReadable[] memory)
    {
        return proposalHandler.getProposalReadables(proposalTypeInt);
    }

    function settleProposal(uint256 proposalTypeInt, uint256 proposalId)
        external
        onlyAllowedRepresentatives(proposalId) withProposalHandlerSetted withNftSetted
    {
        INyxProposalHandler.ProposalConf memory proposalConf = proposalHandler.getProposalConf(proposalTypeInt, proposalId);
        VoteConf memory voteConf = voteConfMapping[proposalTypeInt][proposalId];

        if (proposalConf.settled)
        {
            revert("Proposal have already been settled");
        }
        
        proposalConf.approved = voteConf.votesFor > (minApprovalPct * nft_contract.getCurrentSupply())/100 && 
            voteConf.voters.length >= (minVotersPct * nft_contract.getCurrentSupply())/100;
        proposalConf.settled = true;
        proposalConf.settledBy = msg.sender;

        proposalHandler.setProposalConf(proposalTypeInt, proposalId, proposalConf);
        // proposalSettler.settleProposal(proposalTypeInt, proposalId);

        emit SettledProposal(proposalConf.proposer, proposalTypeInt, proposalId, proposalConf.approved);
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
        require(isStakeholder(to));

        address senderDelegate = getDelegateOperator(msg.sender);
        bool notDelegated = senderDelegate == address(0);
        require(notDelegated);
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

    function getRedeemPrice(uint256 tokenId)
        public view
        withNftSetted
        returns (uint256)
    {
        uint256 tokenIdRedeemRatio = nft_contract.waveRedeemRatio(tokenId);
        uint256 redeemPrice = redeemPricePerRedeemPower * tokenIdRedeemRatio;
        return redeemPrice;
    }

    function redeem(uint56 nNfts, uint256 tokenId)
        public
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
        nyx_vault_module_contract.transfer(address(0), payable(msg.sender), redeemableAmount);
        // nyx_vault_module_contract.redeem(payable(msg.sender), uint96(redeemableAmount));
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

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "../nyx_proposals/NyxProposal.sol";
import "./INyxProposalHandler.sol";
import "./INyxProposalSettlerHandler.sol";

abstract contract NyxNFT
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

abstract contract NyxVaultSafeModule
{
    mapping(address => int8) public approvedCallers;
    function transfer(address token, address payable to, uint96 amount) public virtual;
    function redeem(address payable to, uint96 amount) public virtual;
    function lockLiquidity(uint96 amount) public virtual;
}

abstract contract INyxDAO is Ownable, ERC1155Holder, ReentrancyGuard
{
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

    // Events
    ///////////////////

    event NewProposal(address indexed proposer, uint256 proposalType, uint256 proposalId);
    event DeleteProposal(uint256 proposalType, uint256 proposalId);
    event ApprovedForVoteProposal(address indexed proposer, uint256 proposalTypeInt, uint256 proposalId);
    event SettledProposal(address indexed proposer, uint256 proposalType, uint256 proposalId, bool approved);

    // Errors
    ///////////////////

    error NotRepresentative();
    error NotProposalHandler();
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


abstract contract INyxProposalSettlerHandler is Ownable {
    mapping(uint256 => NyxProposalSettler) public proposalSettlerAddresses;
    
    function addProposalSettler(string memory proposalTypeName, address addr) public virtual;
    function setProposalSettlerAddress(uint256 proposalTypeInt, address addr) public virtual;
    function settleProposal(uint256 proposalTypeInt, bytes[] memory params, address author) public virtual returns (uint256);
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

import "../nyx_proposals/NyxProposal.sol";
import "../NyxProposalRegistry.sol";
import "./INyxProposalRegistry.sol";

abstract contract INyxProposalHandler
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

    // uint256 public numOfProposalTypes;
    mapping(uint256 => uint256) public numOfProposals;
    // mapping(uint256 => ProposalType) public proposalTypeMapping;
    // mapping(uint256 => NyxProposal) public proposalHandlerAddresses;
    mapping(uint256 => Proposal[]) public proposalMapping;
    Converter converterContract = Converter(0xB23e433BD8B53Ce077b91A831F80167272337e15);
    NyxProposalRegistry registry;

    function setProposalRegistry(address addr) public virtual;
    // function getProposalType(uint256 proposalTypeint) public view virtual returns(INyxProposalRegistry.ProposalType memory);
    // function addProposalType(string calldata proposalTypeName, address proposalHandlerAddr) external virtual;
    function setConverterAddress(address addr) external virtual;
    // function setProposalContractAddress(uint256 proposalTypeInt, address addr) external virtual;
    // function setProposalTypeName(uint256 proposalTypeInt, string calldata newProposalTypeName) external virtual;
    function getProposalConf(uint256 proposalTypeInt, uint256 proposalId) public view virtual returns(ProposalConf memory);
    function setProposalConf(uint256 proposalTypeInt, uint256 proposalId, ProposalConf calldata proposalConf) public virtual;
    function createProposal(uint256 proposalTypeInt, bytes[] calldata params, address author) public virtual returns(uint256);
    function getProposal(uint256 proposalTypeInt, uint256 proposalId) public view virtual returns (bytes[] memory);
    function getProposals(uint256 proposalTypeInt) public view virtual returns (bytes[][] memory);
    function getProposalReadable(uint256 proposalTypeInt, uint256 proposalId) public view virtual returns (ProposalReadable memory);
    function getProposalReadables(uint256 proposalTypeInt) public view virtual returns (ProposalReadable[] memory);
    function getProposalConfs(uint256 proposalTypeInt) public view virtual returns (ProposalConf[] memory);
    function deleteProposal(uint256 proposalTypeInt, uint256 proposalId) public virtual;
    // function settleProposal(uint256 proposalTypeInt, uint256 proposalId) public virtual;
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
import "../../utils/converter_contract.sol";

abstract contract NyxProposal is Converter {
    // Proposal Creators
    /////////////////////

    function createProposal(uint256 proposalId, bytes[] memory params) external virtual pure returns (bytes memory);
    
    // Proposal Getters
    /////////////////////
    function getProposal(bytes memory proposalBytes) external virtual pure returns (bytes[] memory);
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
import "../../utils/converter_contract.sol";
import "../nyx_proposals/NyxProposal.sol";
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

abstract contract INyxProposalRegistry
{
    struct ProposalType
    {
        uint256 id;
        string name;
        address contract_address;
    }

    uint256 public numOfProposalTypes;
    mapping(uint256 => ProposalType) public proposalTypeMapping;
    mapping(uint256 => NyxProposal) public proposalHandlerAddresses;

    function getProposalType(uint256 proposalTypeint) public view virtual returns(ProposalType memory);
    function addProposalType(string calldata proposalTypeName, address proposalHandlerAddr) external virtual;
    function setProposalContractAddress(uint256 proposalTypeInt, address addr) external virtual;
    function setProposalTypeName(uint256 proposalTypeInt, string calldata newProposalTypeName) external virtual;
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
import "./nyx_proposals/NyxProposal.sol";
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
        proposalTypeMapping[0] = ProposalType(0, "None", address(0));
        proposalHandlerAddresses[0] = NyxProposal(address(0));
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

    function addProposalType(string calldata proposalTypeName, address proposalHandlerAddr)
        public
        override
        onlyApproved
    {
        uint256 proposalTypeId = ++numOfProposalTypes;
        proposalTypeMapping[proposalTypeId] = ProposalType(proposalTypeId, proposalTypeName, proposalHandlerAddr);
        proposalHandlerAddresses[proposalTypeId] = NyxProposal(proposalHandlerAddr);
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

    function setProposalContractAddress(uint256 proposalTypeInt, address addr)
        public
        override
        onlyApproved onlyExistingProposalType(proposalTypeInt)
    {
        proposalHandlerAddresses[proposalTypeInt] = NyxProposal(addr);
        proposalTypeMapping[proposalTypeInt].contract_address = addr;
    }

    function setProposalTypeName(uint256 proposalTypeInt, string calldata newProposalTypeName)
        public
        override
        onlyApproved onlyExistingProposalType(proposalTypeInt)
    {
        ProposalType storage proposalType = proposalTypeMapping[proposalTypeInt];
        proposalType.name = newProposalTypeName;
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