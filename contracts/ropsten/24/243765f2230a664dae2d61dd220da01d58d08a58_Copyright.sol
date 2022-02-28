// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CopyrightBase.sol";
import "../Utils/IdCounters.sol";

/// @dev Implementation of a traditional copyright contract using CopyrightBase
contract Copyright is CopyrightBase {
    using IdCounters for IdCounters.IdCounter;

    constructor() CopyrightBase("CRPL COPYRIGHT BACKED BY PIPO") payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ICopyright.sol";
import "../Structs/OwnershipStake.sol";
import "../Structs/ProposalVote.sol";
import "../Utils/IdCounters.sol";
import "../ICopyrightMeta.sol";
import "../Structs/Meta.sol";

abstract contract CopyrightBase is ICopyrightMeta {
    using IdCounters for IdCounters.IdCounter;

    bool internal _locked;
    string internal _name;

    string constant INVALID_ADDR = "INVALID_ADDR";
    string constant NOT_SHAREHOLDER = "NOT_SHAREHOLDER";
    string constant THREAD_LOCKED = "THREAD_LOCKED";
    string constant NOT_ALLOWED = "NOT_ALLOWED";
    string constant NOT_APPROVED = "NOT_APPROVED";
    string constant NOT_VALID_RIGHT = "NOT_VALID_RIGHT";
    string constant INVALID_SHARE = "INVALID_SHARE";
    string constant NO_SHAREHOLDERS = "NO_SHAREHOLDERS";
    string constant ALREADY_VOTED = "ALREADY_VOTED";
    string constant EXPIRED = "EXPIRED";

    // rightId -> ownership structures
    mapping (uint256 => OwnershipStructure) internal _shareholders;
    
    // rightId -> metadata
    mapping(uint256 => Meta) internal _metadata;

    // owner -> number of copyrights
    mapping (address => uint256) internal _numOfRights;

    // rightId -> new ownership
    mapping (uint256 => OwnershipStructure) internal _newHolders;

    // rightId -> shareholder -> bool (prop vote)
    mapping (uint256 => ProposalVote[]) internal _proposalVotes;

    // rightId -> number of votes
    mapping (uint256 => uint256) internal _numOfPropVotes;

    // rightId -> approved address
    mapping (uint256 => address) internal _approvedAddress;

    // owner address -> (operator address -> approved)
    mapping (address => mapping (address => bool)) internal ownerToOperators;

    IdCounters.IdCounter internal _copyCount;

    constructor(string memory name) {
        _name = name;
    }

    function OwnershipOf(uint256 rightId) public override validId(rightId) isExpired(rightId) view returns (OwnershipStake[] memory) {
        return _mapToOwnershipStakes(_shareholders[rightId]);
    }

    function PortfolioSize(address owner) external override validAddress(owner) view returns (uint256) {
        return _numOfRights[owner];
    }

    function CopyrightMeta(uint256 rightId) public override validId(rightId) isExpired(rightId) view returns (Meta memory) 
    {
        return _metadata[rightId];
    }

    function Register(OwnershipStake[] memory to, Meta memory meta) public validShareholders(to) {

        uint256 rightId = _copyCount.next();

        // registering copyright across all shareholders
        for (uint256 i = 0; i < to.length; i++) {

            require(to[i].share > 0, INVALID_SHARE);

            _recordRight(to[i].owner);
            _shareholders[rightId].stakes.push(to[i]);
        }
        
        _metadata[rightId] = meta;
        _shareholders[rightId].exists = true;
        
        _approvedAddress[_copyCount.getCurrent()] = msg.sender;

        emit Registered(rightId, to);
        emit Approved(rightId, msg.sender);
    }

    function ProposeRestructure(uint256 rightId, OwnershipStake[] memory restructured) external override validId(rightId) isExpired(rightId) validShareholders(restructured) isShareholderOrApproved(rightId, msg.sender) payable {
        
        for (uint256 i = 0; i < restructured.length; i++) {

            require(restructured[i].share > 0, INVALID_SHARE);

            _newHolders[rightId].stakes.push(restructured[i]);
            _newHolders[rightId].exists = true;
        }   

        emit ProposedRestructure(rightId, _getProposedRestructure(rightId));
    }

    function Proposal(uint256 rightId) external override validId(rightId) isExpired(rightId) view returns (RestructureProposal memory) {
        return _getProposedRestructure(rightId);
    }

    function CurrentVotes(uint256 rightId) external override validId(rightId) isExpired(rightId) view returns (ProposalVote[] memory) {
        return _proposalVotes[rightId];
    }

    function BindRestructure(uint256 rightId, bool accepted) external override validId(rightId) isExpired(rightId) isShareholderOrApproved(rightId, msg.sender) payable 
    {
        _checkHasVoted(rightId, msg.sender);
     
        // record vote
        _proposalVotes[rightId].push(ProposalVote(msg.sender, accepted));
        _numOfPropVotes[rightId] ++;

        for (uint256 i = 0; i < _proposalVotes[rightId].length; i ++) 
        {
            if (!_proposalVotes[rightId][i].accepted) 
            {
                _resetProposal(rightId);
                emit FailedProposal(rightId);

                return;
            }
        }

        // if the proposal has enough votes, **** 100% SHAREHOLDER CONSENSUS ****
        if (_numOfPropVotes[rightId] == _numberOfShareholder(rightId)) {
            
            // proposal has been accepted and is now binding

            OwnershipStake[] memory oldOwnership = OwnershipOf(rightId);
            
            // reset has to happen before new shareholders are registered to remove data concerning old shareholders
            _resetProposal(rightId);

            _shareholders[rightId] = _newHolders[rightId];

            delete(_newHolders[rightId]);

            emit Restructured(rightId, RestructureProposal({oldStructure: oldOwnership, newStructure: OwnershipOf(rightId)}));
        }

    }

    function ApproveOne(uint256 rightId, address approved) external override validId(rightId) validAddress(approved) isShareholderOrApproved(rightId, msg.sender) payable {
        // check approved is not owner of copyright

        _approvedAddress[rightId] = approved;

        emit Approved(rightId, approved);
    }

    function ApproveManager(address manager, bool hasApproval) external override validAddress(manager) {
        
        ownerToOperators[msg.sender][manager] = hasApproval;

        emit ApprovedManager(msg.sender, manager, hasApproval);
    }

    function GetApproved(uint256 rightId) external override validId(rightId) view returns (address) {
        return _approvedAddress[rightId];
    }

    function IsManager(address client, address manager) external override view returns (bool) {
        return ownerToOperators[client][manager];
    }

    //////////// INTERNAL METHODS ////////////

    function _numberOfShareholder(uint256 rightId) internal view returns (uint256) {
        return _shareholders[rightId].stakes.length;
    }

    function _recordRight(address shareholder) internal {
        _numOfRights[shareholder] += 1;
    }

    function _getProposedRestructure(uint256 rightId) internal view returns(RestructureProposal memory) {
        return RestructureProposal({oldStructure: _mapToOwnershipStakes(_shareholders[rightId]), newStructure: _mapToOwnershipStakes(_newHolders[rightId])});
    }
    
    function _mapToOwnershipStakes(OwnershipStructure memory structure) internal pure returns (OwnershipStake[] memory) 
    {
        OwnershipStake[] memory stakes = new OwnershipStake[](structure.stakes.length);
        for (uint256 i = 0; i < structure.stakes.length; i++) {
            stakes[i] = structure.stakes[i];
        }
        return stakes;
    }

    function _resetProposal(uint256 rightId) internal {        

        OwnershipStake[] memory holdersWhoVoted = _shareholders[rightId].stakes;

        for (uint256 i = 0; i < holdersWhoVoted.length; i++) {
            delete(_proposalVotes[rightId]);
        }

        _numOfPropVotes[rightId] = 0;

    }

    function _checkHasVoted(uint256 rightId, address addr) internal view
    {
        for (uint256 i = 0; i < _proposalVotes[rightId].length; i ++)
        {
            require(_proposalVotes[rightId][i].voter != addr, ALREADY_VOTED);
        }
    }

    //////////// MODIFIERS ////////////

    modifier isShareholderOrApproved(uint256 rightId, address addr) 
    {
        uint256 c = 0;
        for (uint256 i = 0; i < _shareholders[rightId].stakes.length; i++) 
        {
            if (_shareholders[rightId].stakes[i].owner == addr) c ++;
        }
        require(c == 1 || _approvedAddress[rightId] == addr, NOT_SHAREHOLDER);
        _;
    }

    modifier validAddress(address addr)
    {
        require(addr != address(0), INVALID_ADDR);
        _;
    }

    // TODO: could cause a problem
    modifier validId(uint256 rightId)
    {
        require(_shareholders[rightId].exists, NOT_VALID_RIGHT);
        _;
    }

    modifier validShareholders(OwnershipStake[] memory holders) 
    {
        require(holders.length > 0, NO_SHAREHOLDERS);

        for (uint256 i = 0; i < holders.length; i ++) 
        {
            require(holders[i].owner != address(0), INVALID_ADDR);
        }
        _;
    }

    modifier isExpired(uint256 rightId)
    {
        require(_metadata[rightId].expires > block.timestamp, EXPIRED);
        _;
    }

    // TODO: atomic locking
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Influenced by EIP-712, see: https://eips.ethereum.org/EIPS/eip-721

import "./IStructuredOwnership.sol";

/// @title Basic structure for interfacing with a copyright contract
interface ICopyright is IStructuredOwnership {

    /// @dev Emits when a copyright dispute has been registered
    event Disputed(uint256 indexed rightId, address indexed by, bytes reason);

    /// @dev Emits when a new address is approved to a copyright
    event Approved(uint256 indexed rightId, address indexed approved);

    /// @dev Emits when a new manager has been approved
    event ApprovedManager(address indexed owner, address indexed manager, bool hasApproval);

    /// @dev Emits after any modification
    event Modify(uint256 indexed rightId, bytes modification);

    // @notice gets all the rights held by address
    /// @param owner portfolios owner address
    // function Portfolio(address owner) external view returns (uint256[] memory);

    // @notice gets the number of rights held by an address
    /// @param owner portfolios owner address
    function PortfolioSize(address owner) external view returns (uint256);

    /// @notice Approve address for the copyright
    /// @dev Must authorize shareholder
    /// @param approved Address to be approved
    /// @param rightId The copyright id
    function ApproveOne(uint256 rightId, address approved) external payable;

    /// @notice Approve address to be manager of a users whole portfolio
    /// @dev Must authorize shareholder
    /// @param manager Address of the new manager
    /// @param hasApproval If the address has authority
    function ApproveManager(address manager, bool hasApproval) external;

    /// @notice Gets the approved address for a copyright
    /// @dev
    /// @param rightId The copyright id
    /// @return The approved address
    function GetApproved(uint256 rightId) external view returns (address);

    /// @notice Asks if address is a manager of a user/clients portfolio
    /// @dev
    /// @param client The address of the client in question
    /// @param manager The address of manager to be checked
    /// @return If the specific address (manager) has authority for client
    function IsManager(address client, address manager) external view returns (bool);

    //TODO: Dispute filing, cancelling and resolving
} 

//TODO: Implement EIP-165, see: https://eips.ethereum.org/EIPS/eip-165

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Structs/OwnershipStake.sol";
import "./Structs/RestructureProposal.sol";
import "./Structs/ProposalVote.sol";

/// @title Defintion of a multi party shareholder style ownership structure, with consensus voting
interface IStructuredOwnership {
    
    /// @dev Emits when a new copyright is registered
    event Registered(uint256 indexed rightId, OwnershipStake[] to);

    /// @dev Emits when a copyright has been restructured and bound
    event Restructured(uint256 indexed rightId, RestructureProposal proposal);

    /// @dev Emits when a restructure is proposed
    event ProposedRestructure(uint256 indexed rightId, RestructureProposal proposal);

    /// @dev Emits when a restructure vote fails
    event FailedProposal(uint256 indexed rightId);

    /// @notice The current ownership structure of a copyright
    /// @dev
    /// @param rightId The copyright id
    function OwnershipOf(uint256 rightId) external view returns (OwnershipStake[] memory);

    /// @notice Proposes a restructure of the ownership share of a copyright contract, this change must be bound by all share holders
    /// @dev 
    /// @param rightId The copyright id
    /// @param restructured The new owernship shares
    //  @param notes Any notes written concerning restructure for public record
    function ProposeRestructure(uint256 rightId, OwnershipStake[] memory restructured) external payable;

    /// @notice The current restructure proposal for a copyright
    /// @dev
    /// @param rightId The copyright id
    /// @return A restructure proposal
    function Proposal(uint256 rightId) external view returns (RestructureProposal memory);
    
    function CurrentVotes(uint256 rightId) external view returns (ProposalVote[] memory);

    /// @notice Binds a shareholders vote to a restructure
    /// @dev Must authorize shareholder
    /// @param rightId The copyright id
    /// @param accepted If the shareholder accepts the restructure
    function BindRestructure(uint256 rightId, bool accepted) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct OwnershipStake {
    address owner;
    uint8 share;
}

struct OwnershipStructure {
    bool exists;
    OwnershipStake[] stakes;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnershipStake.sol";

struct RestructureProposal {
    OwnershipStake[] oldStructure;
    OwnershipStake[] newStructure;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct ProposalVote {
    address voter;
    bool accepted;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library IdCounters {

    struct IdCounter {
        uint256 _count;
    }

    function getCurrent(IdCounter storage count) internal view returns (uint256) {
        return count._count;
    }

    function inc(IdCounter storage count) internal {
        count._count += 1;
    }

    function next(IdCounter storage count) internal returns (uint256) {
        inc(count);
        return count._count;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Structs/Meta.sol";
import "./Structs/Protections.sol";
import "./ICopyright.sol";

/// @title Copyright meta and legal data
interface ICopyrightMeta is ICopyright {
    /// @notice all metadata about copyright
    function CopyrightMeta(uint256 rightId) external view returns (Meta memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Protections.sol";

struct Meta {
    string title;
    uint256 expires;
    uint256 registered;
    string workHash;
    string workUri;
    string legalMeta;
    string workType;
    Protections protections;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Protections {
    bool authorship;

    bool commercialAdaptation;
    bool nonCommercialAdaptation;
    
    bool reviewOrCrit;

    bool commercialPerformance;
    bool nonCommercialPerformance;

    bool commercialReproduction;
    bool nonCommercialReproduction;
    
    bool commercialDistribution;
    bool nonCommercialDistribution;
}