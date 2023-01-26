// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

/**
                                                      ...:--==***#@%%-
                                             ..:  -*@@@@@@@@@@@@@#*:  
                               -:::-=+*#%@@@@@@*[email protected]@@@@@@@@@@#+=:     
           .::---:.         +#@@@@@@@@@@@@@%*+-. [email protected]@@@@@+..           
    .-+*%@@@@@@@@@@@#-     [email protected]@@@@@@@@@%#*=:.    :@@@@@@@#%@@@@@%:     
 =#@@@@@@@@@@@@@@@@@@@%.   %@@@@@@-..           *@@@@@@@@@@@@%*.      
[email protected]@@@@@@@@#*+=--=#@@@@@%  [email protected]@@@@@%*#%@@@%*=-.. [email protected]@@@@@@%%*+=:         
 :*@@@@@@*       [email protected]@@@@@.*@@@@@@@@@@@@*+-      =%@@@@%                
  [email protected]@@@@@.       *@@@@@%:@@@@@@*==-:.          [email protected]@@@@:                
 [email protected]@@@@@=      [email protected]@@@@@%.*@@@@@=   ..::--=+*=+*[email protected]@@@=                 
 #@@@@@*    [email protected]@@@@@@* [email protected]@@@@#%%@@@@@@@@#+:.  =#@@=                  
 @@@@@%   :*@@@@@@@*:  .#@@@@@@@@@@@@@%#:       ---                   
:@@@@%. -%@@@@@@@+.     [email protected]@@@@%#*+=:.                                 
[email protected]@@%=*@@@@@@@*:        =*:                                           
:*#+%@@@@%*=.                                                         
 :+##*=:.

*/

import {Auth} from "./lib/Auth.sol";
import {IDefinitelyMemberships} from "./interfaces/IDefinitelyMemberships.sol";
import {IERC721} from "openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title
 * Definitely Revoke v1
 *
 * @author
 * DEF DAO
 *
 * @notice
 * A contract to revoke memberships based on a simple voting mechanism.
 */
contract DefinitelyRevoke is Auth {
    /* ------------------------------------------------------------------------
       S T O R A G E
    ------------------------------------------------------------------------ */

    /// @notice The main membership contract
    address public memberships;

    /* PROPOSALS ----------------------------------------------------------- */

    /// @dev Allows a member to propose another membership be revoked
    struct Proposal {
        address initiator;
        uint8 approvalCount;
        bool addToDenyList;
        address[] voters;
    }

    /// @notice Keeps track of revoke membership proposals by token id
    mapping(uint256 => Proposal) public proposals;

    /* VOTING -------------------------------------------------------------- */

    /// @dev Voting configuration for reaching quorum on proposals
    struct VotingConfig {
        uint64 minQuorum;
        uint64 maxVotes;
    }

    /// @notice The voting configuration for this contract
    VotingConfig public votingConfig;

    /* ------------------------------------------------------------------------
       E V E N T S
    ------------------------------------------------------------------------ */

    event ProposalCreated(uint256 indexed id, address indexed initiator, bool addToDenyList);
    event ProposalCancelled(uint256 indexed id, address indexed initiator);
    event ProposalApproved(uint256 indexed id, address indexed initiator);
    event ProposalDenied(uint256 indexed id, address indexed initiator);

    /* ------------------------------------------------------------------------
       E R R O R S    
    ------------------------------------------------------------------------ */

    error NotDefMember();
    error AlreadyDefMember();

    error ProposalNotFound();
    error ProposalInProgress();
    error ProposalEnded();
    error CannotCreateProposalForSelf();

    error AlreadyVoted();
    error NotProposalInitiator();

    /* ------------------------------------------------------------------------
       M O D I F I E R S    
    ------------------------------------------------------------------------ */

    /// @dev Reverts if `msg.sender` is not a member
    modifier onlyDefMember() {
        if ((IERC721(memberships).balanceOf(msg.sender) < 1)) revert NotDefMember();
        _;
    }

    /// @dev Reverts if `to` is already a member
    modifier whenNotDefMember(address to) {
        if (IERC721(memberships).balanceOf(to) > 0) revert AlreadyDefMember();
        _;
    }

    /* ------------------------------------------------------------------------
       I N I T
    ------------------------------------------------------------------------ */

    /**
     * @param owner_ Contract owner address
     * @param memberships_ The main membership contract
     * @param minQuorum_ The min number of votes to approve a proposal
     * @param maxVotes_ The max number of votes a proposal can have
     */
    constructor(
        address owner_,
        address memberships_,
        uint64 minQuorum_,
        uint64 maxVotes_
    ) Auth(owner_) {
        memberships = memberships_;
        votingConfig = VotingConfig(minQuorum_, maxVotes_);
    }

    /* ------------------------------------------------------------------------
       R E V O K I N G   M E M B E R S H I P S
    ------------------------------------------------------------------------ */

    /**
     * @notice
     * Allows a member to propose revoking the membership of another member
     *
     * @dev
     * Reverts if:
     *   - `msg.sender` currently owns the token they are attempting to revoke
     *   - there is a proposal in progress for `id`
     *
     * @param id The ID of the membership to revoke
     * @param addToDenyList If the owner of the revoked token should be denied future membership
     */
    function newProposal(uint256 id, bool addToDenyList) external onlyDefMember {
        address currentOwner = IERC721(memberships).ownerOf(id);
        Proposal storage proposal = proposals[id];

        // Prevent the current owner from creating a proposal
        if (msg.sender == currentOwner) revert CannotCreateProposalForSelf();

        // Can't update an existing proposal, it must be cancelled first since it may
        // have votes in progress
        if (proposal.initiator != address(0)) revert ProposalInProgress();

        // Init the new proposal
        proposal.initiator = msg.sender;
        proposal.addToDenyList = addToDenyList;
        emit ProposalCreated(id, proposal.initiator, addToDenyList);
    }

    /**
     * @notice
     * Allows the member who created the proposal to cancel it
     *
     * @dev
     * Reverts if:
     *   - `msg.sender` did not initiate the proposal
     *
     * @param id The ID of the proposal to cancel (the membership token id)
     */
    function cancelProposal(uint256 id) external onlyDefMember {
        Proposal storage proposal = proposals[id];
        if (proposal.initiator != msg.sender) revert NotProposalInitiator();
        delete proposals[id];
        emit ProposalCancelled(id, proposal.initiator);
    }

    /**
     * @notice
     * Allows a member to vote on a revoke membership proposal
     *
     * @dev
     * If the proposal reaches quorum, the last voter will burn the membership and
     * optionally add the owner to the deny list if it was defined in the proposal
     *
     * Reverts if:
     *   - the proposal doesn't exist
     *   - the proposal has ended
     *   - `msg.sender` has already voted
     *
     * @param id The ID of the proposal to cancel (the membership token id)
     */
    function vote(uint256 id, bool inFavor) external onlyDefMember {
        VotingConfig memory config = votingConfig;
        Proposal storage proposal = proposals[id];

        if (proposal.initiator == address(0)) revert ProposalNotFound();
        if (proposal.approvalCount == config.minQuorum || proposal.voters.length == config.maxVotes)
            revert ProposalEnded();

        // Check if this account has voted on this proposal already
        for (uint256 a = 0; a < proposal.voters.length; a++) {
            if (proposal.voters[a] == msg.sender) revert AlreadyVoted();
        }

        proposal.voters.push(msg.sender);

        // Remove an approval if the member says no
        if (!inFavor && proposal.approvalCount > 0) --proposal.approvalCount;

        // Add an approval if the member says yes
        if (inFavor) ++proposal.approvalCount;

        // Last vote has been reached but min approvals hasn't, then deny the proposal
        if (
            proposal.voters.length == config.maxVotes && proposal.approvalCount < config.minQuorum
        ) {
            emit ProposalDenied(id, proposal.initiator);
        }

        // If the proposal reaches quorum, revoke from the memberships contract
        if (proposal.approvalCount == config.minQuorum) {
            emit ProposalApproved(id, proposal.initiator);
            IDefinitelyMemberships(memberships).revokeMembership(id, proposal.addToDenyList);
        }
    }

    /* ------------------------------------------------------------------------
       A D M I N
    ------------------------------------------------------------------------ */

    /**
     * @notice
     * Admin function to update the voting configuration
     *
     * @param minQuorum_ The min number of votes to approve a proposal
     * @param maxVotes_ The max number of votes a proposal can have
     */
    function setVotingConfig(uint64 minQuorum_, uint64 maxVotes_) external onlyOwnerOrAdmin {
        votingConfig = VotingConfig(minQuorum_, maxVotes_);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IDefinitelyMemberships {
    function issueMembership(address to) external;

    function revokeMembership(uint256 id, bool addToDenyList) external;

    function addAddressToDenyList(address account) external;

    function removeAddressFromDenyList(address account) external;

    function transferMembership(uint256 id, address to) external;

    function overrideMetadataForToken(uint256 id, address metadata) external;

    function resetMetadataForToken(uint256 id) external;

    function isDefMember(address account) external view returns (bool);

    function isOnDenyList(address account) external view returns (bool);

    function memberSinceBlock(uint256 id) external view returns (uint256);

    function defaultMetadataAddress() external view returns (address);

    function metadataAddressForToken(uint256 id) external view returns (address);

    function allowedMembershipIssuingContract(address addr) external view returns (bool);

    function allowedMembershipRevokingContract(address addr) external view returns (bool);

    function allowedMembershipTransferContract(address addr) external view returns (bool);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

/**
 * @author DEF DAO
 * @title  Simple owner and admin authentication
 * @notice Allows the management of a contract by using simple ownership and admin modifiers.
 */
abstract contract Auth {
    /* ------------------------------------------------------------------------
       S T O R A G E
    ------------------------------------------------------------------------ */

    /// @notice Current owner of the contract
    address public owner;

    /// @notice Current admins of the contract
    mapping(address => bool) public admins;

    /* ------------------------------------------------------------------------
       E V E N T S
    ------------------------------------------------------------------------ */

    /**
     * @notice When the contract owner is updated
     * @param user The account that updated the new owner
     * @param newOwner The new owner of the contract
     */
    event OwnerUpdated(address indexed user, address indexed newOwner);

    /**
     * @notice When an admin is added to the contract
     * @param user The account that added the new admin
     * @param newAdmin The admin that was added
     */
    event AdminAdded(address indexed user, address indexed newAdmin);

    /**
     * @notice When an admin is removed from the contract
     * @param user The account that removed an admin
     * @param prevAdmin The admin that got removed
     */
    event AdminRemoved(address indexed user, address indexed prevAdmin);

    /* ------------------------------------------------------------------------
       M O D I F I E R S
    ------------------------------------------------------------------------ */

    /**
     * @dev Only the owner can call
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "UNAUTHORIZED");
        _;
    }

    /**
     * @dev Only an admin can call
     */
    modifier onlyAdmin() {
        require(admins[msg.sender], "UNAUTHORIZED");
        _;
    }

    /**
     * @dev Only the owner or an admin can call
     */
    modifier onlyOwnerOrAdmin() {
        require((msg.sender == owner || admins[msg.sender]), "UNAUTHORIZED");
        _;
    }

    /* ------------------------------------------------------------------------
       I N I T
    ------------------------------------------------------------------------ */

    /**
     * @dev Sets the initial owner and a first admin upon creation.
     * @param owner_ The initial owner of the contract
     */
    constructor(address owner_) {
        owner = owner_;
        emit OwnerUpdated(address(0), owner_);
    }

    /* ------------------------------------------------------------------------
       A D M I N
    ------------------------------------------------------------------------ */

    /**
     * @notice Transfers ownership of the contract to `newOwner`
     * @dev Can only be called by the current owner or an admin
     * @param newOwner The new owner of the contract
     */
    function setOwner(address newOwner) public virtual onlyOwnerOrAdmin {
        owner = newOwner;
        emit OwnerUpdated(msg.sender, newOwner);
    }

    /**
     * @notice Adds `newAdmin` as an admin of the contract
     * @dev Can only be called by the current owner or an admin
     * @param newAdmin A new admin of the contract
     */
    function addAdmin(address newAdmin) public virtual onlyOwnerOrAdmin {
        admins[newAdmin] = true;
        emit AdminAdded(msg.sender, newAdmin);
    }

    /**
     * @notice Removes `prevAdmin` as an admin of the contract
     * @dev Can only be called by the current owner or an admin
     * @param prevAdmin The admin to remove
     */
    function removeAdmin(address prevAdmin) public virtual onlyOwnerOrAdmin {
        admins[prevAdmin] = false;
        emit AdminRemoved(msg.sender, prevAdmin);
    }
}