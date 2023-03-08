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

import "utils/Converter.sol";
import "./interfaces/INyxVotingHandler.sol";

contract NyxVotingHandler is INyxVotingHandler {
    string public constant name = "NyxVotingHandler";

    // Attributes Setters
    /////////////////////////////////////

    function setNftContract(address addr)
        external
        override
        onlyOwner
    {
        nft_contract = INyxNFT(addr);
    }

    function isApproved(address addr)
        external view
        returns (bool)
    {
        return approvedCallers[addr] == 1;
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

    // Voting Logic
    ////////////////////

    function createVoteConf(uint256 proposalTypeInt, uint256 proposalId, address author, uint256 durationDays)
        external
        override
        onlyApproved
        returns (VoteConf memory)
    {
        address[] memory voters;
        VoteConf memory voteConf = VoteConf(proposalTypeInt, proposalId, author, false, false, 0, 0, block.timestamp + (durationDays * 1 days),
            voters, block.timestamp, block.number);
        voteConfMapping[proposalTypeInt][proposalId] = voteConf;

        emit VoteConfCreated(proposalTypeInt, proposalId, author);

        return voteConf;        
    }

    function updateVoteConf(uint256 proposalTypeInt, uint256 proposalId, address author, uint256 durationDays)
        external
        override
        onlyApproved onlyExistingProposal(proposalTypeInt, proposalId)
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

    function makeVotable(uint256 proposalTypeInt, uint256 proposalId)
        external
        override
        onlyApproved
    {
        VoteConf storage voteConf = voteConfMapping[proposalTypeInt][proposalId];
        require(!voteConf.isProposedToVote);
        voteConf.isProposedToVote = true;

        emit ApprovedForVoteProposal(proposalTypeInt, proposalId);
    }

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

    function vote(address _voter, uint256 proposalTypeInt, uint256 proposalId, bool supportProposal)
        external
        override
        onlyApproved
    {
        VoteConf storage conf = voteConfMapping[proposalTypeInt][proposalId];
        
        // Voting on behalf of delegatees
        address[] memory voters = delegateOperatorToVoters[_voter];
        for (uint256 iVoter = 0; iVoter < voters.length; iVoter++)
        {
            address voter = voters[iVoter];
            if (voter != address(0))
            {
                conf = voteOne(voter, conf, supportProposal, false);
            }
        }

        // Voting for self
        voteOne(_voter, conf, supportProposal, true);
    }

    function getStakeholderVotes(uint256 proposalTypeInt, address addr)
        external view
        override
        onlyApproved
        returns (Vote[] memory)
    {
        uint256 numOfProposals = voteConfMapping[proposalTypeInt].length;
        Vote[] memory addrVotes = new Vote[](numOfProposals);
        for (uint256 proposalId; proposalId < addrVotes.length; proposalId++)
        {
            Vote memory oneAddrVote = stakeholderVotes[addr][proposalTypeInt][proposalId];
            addrVotes[proposalId] = oneAddrVote;
        }
        return addrVotes;
    }

    function getVotingPower(address addr, uint256 blockNumber)
        public view
        override
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

    function getProposalVotes(uint256 proposalTypeInt, uint256 proposalId)
        external view
        override
        onlyApproved
        returns (Vote[] memory)
    {
        Vote[] memory _proposalVotes = proposalVotes[proposalTypeInt][proposalId];
        return _proposalVotes;
    }

    function getProposalsVotes(uint256 proposalTypeInt)
        external view
        override
        onlyApproved
        returns (Vote[][] memory)
    {
        uint256 numOfProposals = voteConfMapping[proposalTypeInt].length;
        Vote[][] memory proposalsVotes = new Vote[][](numOfProposals);
        for (uint256 idx = 0; idx < proposalsVotes.length; idx++)
        {
            proposalsVotes[idx] = proposalVotes[proposalTypeInt][idx];
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
        return voteConfMapping[proposalTypeInt];
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
        onlyApproved
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
        onlyApproved
    {
        address delegate = getDelegateOperator(voter);
        require(delegate != address(0), "Voter vote is not delegated yet");

        uint256 idxToDelete;
        for (uint256 iAddress = 0; iAddress < delegateOperatorToVoters[delegate].length; iAddress++)
        {
            if (delegateOperatorToVoters[delegate][iAddress] == voter)
            {
                idxToDelete = iAddress;
            }
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
import "../nyx_proposals_settlers/NyxProposalSettler.sol";
import "nyx_nft/interfaces/INyxNft.sol";

abstract contract INyxVotingHandler is Ownable {
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
    mapping(uint256 => VoteConf[]) public voteConfMapping;
    mapping(address => mapping(uint256 => mapping(uint256 => Vote))) public stakeholderVotes;
    mapping(uint256 => mapping(uint256 => Vote[])) public proposalVotes;
    mapping(address => address[]) public delegateOperatorToVoters;
    mapping(address => address) public delegateVoterToOperator;
    mapping(address => int8) public approvedCallers;

    INyxNFT public nft_contract;

    // Modifiers
    ///////////////////
    modifier onlyApproved
    {
        require(approvedCallers[msg.sender] == 1 || msg.sender == owner(), "not approved");
        _;
    }

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