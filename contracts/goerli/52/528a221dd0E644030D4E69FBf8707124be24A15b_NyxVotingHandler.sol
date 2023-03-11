// SPDX-License-Identifier: MIT

// @title NyxVotingHandler for Nyx DAO
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

import "./interfaces/INyxVotingHandler.sol";

contract NyxVotingHandler is INyxVotingHandler {
    string public constant name = "NyxVotingHandler";

    // Attributes Setters
    /////////////////////////////////////

    /**
    * @notice Set the NFT contract address
    */
    function setNftContract(address addr)
        external
        override
        onlyOwner
    {
        nft_contract = INyxNFT(addr);
    }

    // Voting Logic
    ////////////////////

    /**
    * @notice create the Vote Configuration object for a
    * given <proposalTypeInt>, <proposalId>, <author>, and <durationDays>
    */
    function createVoteConf(uint256 proposalTypeInt, uint256 proposalId, address author, uint256 durationDays)
        external
        override
        onlyApprovedOrOwner(msg.sender)
        returns (VoteConf memory)
    {
        numOfVoteConfs[proposalTypeInt]++;
        address[] memory voters;
        VoteConf memory voteConf = VoteConf(proposalTypeInt, proposalId, author, false, false, 0, 0, block.timestamp + (durationDays * 1 days),
            voters, block.timestamp, block.number);
        voteConfMapping[proposalTypeInt][proposalId] = voteConf;
        // voteConfMapping[proposalTypeInt].push(voteConf);

        emit VoteConfCreated(proposalTypeInt, proposalId, author);

        return voteConf;        
    }

    /**
    * @notice update the given <proposalTypeInt>, <proposalId>, existing Vote Configuration
    * object for a given <author>, and <durationDays>.
    * It also reset its parameters in terms of votes, and expiry
    */
    function updateVoteConf(uint256 proposalTypeInt, uint256 proposalId, address author, uint256 durationDays)
        external
        override
        onlyApprovedOrOwner(msg.sender) onlyExistingProposal(proposalTypeInt, proposalId)
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

    /**
    * @notice approve the given <proposalTypeInt>, <proposalId>, proposal 
    * for vote. Required condition before a proposal can be voted.
    */
    function makeVotable(uint256 proposalTypeInt, uint256 proposalId)
        external
        override
        onlyApprovedOrOwner(msg.sender)
    {
        VoteConf storage voteConf = voteConfMapping[proposalTypeInt][proposalId];
        require(!voteConf.isProposedToVote);
        voteConf.isProposedToVote = true;

        emit ApprovedForVoteProposal(proposalTypeInt, proposalId);
    }

    /**
    * @notice Check that a given <voteConf> object, is votable
    * for the given <votingAddress>
    * If <failOnRequirements> is set to True, then if the condtions are not met, the call will revert.
    * Otherwise, it simply returns false.
    */
    function votable(address votingAddress, VoteConf memory voteConf, bool failOnRequirements)
        public view
        override
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

    /*
    * @notice Helper function to effectively register the vote of <voter>, on
    * a given <voteConf> object, the <voter> decision to approve the proposal beeing 
    * indicated by <supportProposal>
    * if <failOnRequirements> is True, if the <voter> is not allowed to vote, 
    * the transaction will revert
    */
    function voteOne(address voter, VoteConf storage voteConf, bool supportProposal, bool failOnRequirements)
        internal
        override
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

        emit VotedProposal(voter, voteConf.proposalTypeInt, voteConf.proposalId);

        return voteConf;
    }

    /*
    * @notice Main function to call to register a vote, from <voter>, on the fiven
    * <proposalTypeInt>, <proposalId> Proposal.
    * The approval of the proposal beeing indicated by <supportProposal>
    */
    function vote(address _voter, uint256 proposalTypeInt, uint256 proposalId, bool supportProposal)
        external
        override
        onlyApprovedOrOwner(msg.sender)
    {
        VoteConf storage conf = voteConfMapping[proposalTypeInt][proposalId];
        
        // Voting on behalf of delegatees
        address[] memory voters = delegateOperatorToVoters[_voter];
        for (uint256 iVoter = 0; iVoter < voters.length; )
        {
            address voter = voters[iVoter];
            if (voter != address(0))
            {
                conf = voteOne(voter, conf, supportProposal, false);
            }
            unchecked { iVoter++ ; }
        }

        // Voting for self
        voteOne(_voter, conf, supportProposal, true);
    }

    /*
    * @notice Get all votes of <addr> on a given <proposalTypeInt>
    */
    function getStakeholderVotes(uint256 proposalTypeInt, address addr)
        external view
        override
        onlyApprovedOrOwner(msg.sender)
        returns (Vote[] memory)
    {
        Vote[] memory addrVotes = new Vote[](numOfVoteConfs[proposalTypeInt]);
        for (uint256 proposalId; proposalId < addrVotes.length; )
        {
            Vote memory oneAddrVote = stakeholderVotes[addr][proposalTypeInt][proposalId];
            addrVotes[proposalId] = oneAddrVote;
            unchecked { proposalId++; }
        }
        return addrVotes;
    }

    /*
    * @notice Get <addr> voting power at a given <blockNumber>
    */
    function getVotingPower(address addr, uint256 blockNumber)
        public view
        override
        withNftSetted
        returns (uint256)
    {
        uint256 votingPower = 0;
        for (uint tid = 0; tid <= nft_contract.currentTokenId(); )
        {
            uint256 tokenIdVotingPower = nft_contract.waveVotingPower(tid);
            // votingPower += nft_contract.balanceOf(addr, tid) * tokenIdVotingPower;
            votingPower += nft_contract.balanceOfAtBlock(addr, tid, blockNumber) * tokenIdVotingPower;
            unchecked { tid++; }
        }
        return votingPower;
    }

    function getProposalVotes(uint256 proposalTypeInt, uint256 proposalId)
        external view
        override
        onlyApprovedOrOwner(msg.sender)
        returns (Vote[] memory)
    {
        Vote[] memory _proposalVotes = proposalVotes[proposalTypeInt][proposalId];
        return _proposalVotes;
    }

    function getProposalsVotes(uint256 proposalTypeInt)
        external view
        override
        onlyApprovedOrOwner(msg.sender)
        returns (Vote[][] memory)
    {
        Vote[][] memory proposalsVotes = new Vote[][](numOfVoteConfs[proposalTypeInt]);
        for (uint256 idx = 0; idx < proposalsVotes.length; )
        {
            proposalsVotes[idx] = proposalVotes[proposalTypeInt][idx];
            unchecked { idx++; }
        }
        return proposalsVotes;
    }

    function getVoteConf(uint256 proposalTypeInt, uint256 proposalId)
        external view
        override
        returns (VoteConf memory)
    {
        return voteConfMapping[proposalTypeInt][proposalId];
    }
    
    function getVoteConfs(uint256 proposalTypeInt)
        external view
        override
        returns (VoteConf[] memory)
    {
        VoteConf[] memory voteConfs = new VoteConf[](numOfVoteConfs[proposalTypeInt]);
        for (uint256 idx = 0; idx < voteConfs.length; )
        {
            voteConfs[idx] = voteConfMapping[proposalTypeInt][idx];
            unchecked { idx++; }
        }
        return voteConfs;
    }

    // Delegate logic functions
    ///////////////////////////////////

    function getDelegateOperator(address voter)
        public view
        override
        returns (address addrOut)
    {
        return delegateVoterToOperator[voter];        
    }

    function delegateVote(address voter, address to)
        external
        override
        onlyApprovedOrOwner(msg.sender)
    {
        address senderDelegate = getDelegateOperator(voter);
        require(senderDelegate == address(0), "Voter vote is already delegated");

        delegateOperatorToVoters[to].push(voter);
        delegateVoterToOperator[voter] = to;

        emit DelegatedVote(voter, to);
    }

    function undelegateVote(address voter)
        external
        override
        onlyApprovedOrOwner(msg.sender)
    {
        address delegate = getDelegateOperator(voter);
        require(delegate != address(0), "Voter vote is not delegated yet");

        uint256 idxToDelete;
        for (uint256 iAddress = 0; iAddress < delegateOperatorToVoters[delegate].length; )
        {
            if (delegateOperatorToVoters[delegate][iAddress] == voter)
            {
                idxToDelete = iAddress;
            }
            unchecked { iAddress++; }
        }
        delete delegateOperatorToVoters[delegate][idxToDelete];
        delete delegateVoterToOperator[voter];

        emit UndelegatedVote(voter, delegate);
    }
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