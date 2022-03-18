// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import { IERC721 } from '@openzeppelin/contracts/token/ERC721/IERC721.sol';

import './errors.sol';
import { IDopamintPass } from './interfaces/IDopamintPass.sol';
import { IProxyRegistry } from './interfaces/IProxyRegistry.sol';
import { ERC721 } from './erc721/ERC721.sol';
import { ERC721Checkpointable } from './erc721/ERC721Checkpointable.sol';

/// @title Dopamine ERC-721 membership pass
/// @notice DopamintPass holders are first-class members of the Dopamine DAO.
///  DopamintPasses are minted through drops of varying sizes, and each drop
///  features a separate set of NFT metadata. These parameters are configurable
///  by address `owner`, with the emissions controlled by address `minter`.
contract DopamintPass is ERC721Checkpointable, IDopamintPass {

    /// @notice The owner address controls drop creation, size, and scheduling.
    address public owner;

    /// @notice The minter address is responsible for controlling NFT emissions.
    address public minter;

    string public constant NAME = "Dopamint Pass";
    string public constant SYMBOL = "DOPE";

    uint256 public constant MAX_WHITELIST_SIZE = 99;

    uint256 public constant MIN_DROP_SIZE = 1;
    uint256 public constant MAX_DROP_SIZE = 9999;

    uint256 public constant MIN_DROP_DELAY = 4 weeks;
    uint256 public constant MAX_DROP_DELAY = 24 weeks;

    // An address who has permissions to mint RaritySociety tokens

    // OpenSea's Proxy Registry
    IProxyRegistry public proxyRegistry;

    string public baseURI = "https://dopamine.xyz/";

    uint256 public dropSize;
    uint256 public dropDelay; 
    uint256 public whitelistSize;

    uint256 public dropEndIndex;
    uint256 public dropEndTime;

    // Maps drops to their provenance markers.
    mapping(uint256 => bytes32) private _dropProvenanceHashes;
    // Maps drops to their IPFS URIs.
    mapping(uint256 => string) private _dropURIs;
    // Maps drops to their whitelists (merkle roots).
    mapping(uint256 => bytes32) private _dropWhitelists;

    /// @notice Ending index for each drop (non-inclusive).
    uint256[] private _dropEndIndices;
    uint256 private _id;

    /// @notice Modifier to restrict calls to owner only.
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert OwnerOnly();
        }
        _;
    }

    /// @notice Modifier to restrict calls to minter only.
    modifier onlyMinter() {
        if (msg.sender != minter) {
            revert MinterOnly();
        }
        _;
    }

    /// @notice Initializes the DopamintPass with the first drop created..
    /// @param minter_ The address which will control the NFT emissions.
    /// @param proxyRegistry_ The OpenSea proxy registry address.
    /// @param dropSize_ The number of DopamintPasses to issue for the next drop.
    /// @param dropDelay_ The minimum time in seconds to wait before a new drop.
    /// @dev Chain ID and domain separator are assigned here as immutables.
    constructor(
        address minter_,
        IProxyRegistry proxyRegistry_,
        uint256 dropSize_,
        uint256 dropDelay_,
        uint256 whitelistSize_,
        uint256 maxSupply_
    ) ERC721Checkpointable(NAME, SYMBOL, maxSupply_) {
		owner = msg.sender;
        minter = minter_;
        proxyRegistry = proxyRegistry_;

        setDropSize(dropSize_);
        setDropDelay(dropDelay_);
        setWhitelistSize(whitelistSize_);
    }

    /// @notice Mints a DopamintPass to the minter.
    function mint() public override onlyMinter returns (uint256) {
        if (_id >= dropEndIndex) {
            revert DropMaxCapacity();
        }
        return _mint(minter, _id++);
    }

    /// @notice Creates a new drop.
    /// @param whitelist A merkle root of the drop's whitelist.
    /// @param provenanceHash A provenance hash for the drop collection.
    function createDrop(bytes32 whitelist,  bytes32 provenanceHash)
        public 
        onlyOwner 
    {
        if (_id < dropEndIndex) {
            revert OngoingDrop();
        }
        if (block.timestamp < dropEndTime) {
            revert InsufficientTimePassed();
        }
        if (_id + dropSize > maxSupply) {
            revert DropMaxCapacity();
        }

        uint256 startIndex = _id;
        uint256 dropNumber = _dropEndIndices.length;

        _id += whitelistSize;
        dropEndIndex = startIndex + dropSize;
        dropEndTime = block.timestamp + dropDelay;

        _dropEndIndices.push(dropEndIndex);
        _dropProvenanceHashes[dropNumber] = provenanceHash;
        _dropWhitelists[dropNumber] = whitelist;

        emit DropCreated(
            dropNumber,
            startIndex,
            dropSize,
            whitelistSize,
            whitelist,
            provenanceHash
        );
    }

    /// @notice Set the minter of the contract
    function setMinter(address newMinter) external override onlyOwner {
        emit NewMinter(minter, newMinter);
        minter = newMinter;
    }
    
    /// @param newDropDelay The drops delay, in seconds.
    function setDropDelay(uint256 newDropDelay) public override onlyOwner {
        if (newDropDelay < MIN_DROP_DELAY || newDropDelay > MAX_DROP_DELAY) {
            revert InvalidDropDelay();
        }
        dropDelay = newDropDelay;
        emit DropDelaySet(dropDelay);
    }

    /// @notice Sets a new drop size `newDropSize`.
    /// @param newDropSize The number of NFTs to mint for the next drop.
    function setDropSize(uint256 newDropSize) public onlyOwner {
        if (newDropSize < MIN_DROP_SIZE || newDropSize > MAX_DROP_SIZE) {
            revert InvalidDropSize();
        }
        dropSize = newDropSize;
        emit DropSizeSet(dropSize);
    }

    /// @notice Sets a new whitelist size `newWhitelistSize`.
    /// @param newWhitelistSize The number of NFTs to whitelist for the next drop.
    function setWhitelistSize(uint256 newWhitelistSize) public onlyOwner {
        if (
            newWhitelistSize > MAX_WHITELIST_SIZE || 
            newWhitelistSize > dropSize
        ) 
        {
            revert InvalidWhitelistSize();
        }
        whitelistSize = newWhitelistSize;
        emit WhitelistSizeSet(whitelistSize);
    }

    /// @notice Return the drop number of the DopamintPass with id `tokenId`.
    /// @param tokenId Identifier of the DopamintPass being queried.
    function getDropId(uint256 tokenId) public view returns (uint256) {
        for (uint256 i = 0; i < _dropEndIndices.length; i++) {
            if (tokenId < _dropEndIndices[i]) {
                return i;
            }
        }
        revert NonExistentDrop();
    }
	
    /// @notice Sets the base URI.
    /// @param newBaseURI The base URI to set.
	function setBaseURI(string calldata newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
        emit BaseURISet(newBaseURI);
	}

    /// @notice Sets the IPFS URI `dropURI` for drop `dropId`.
    /// @param dropId The drop identifier to set.
	/// @param dropURI The drop URI to permanently set.
	function setDropURI(uint256 dropId, string calldata dropURI)
        public 
        onlyOwner 
    {
        uint256 numDrops = _dropEndIndices.length;
        if (dropId >= numDrops) {
            revert NonExistentDrop();
        }
        _dropURIs[dropId] = dropURI;
        emit DropURISet(dropId, dropURI);
	}


    /// @notice Checks if `operator` is an authorized operator for `owner`.
    /// @dev Ensures OS proxy is whitelisted for operating on behalf of owners.
    function isApprovedForAll(address owner, address operator) 
        public 
        view 
        override(IERC721, ERC721) 
        returns (bool) 
    {
        // Whitelist OpenSea proxy contract for easy trading.
        if (proxyRegistry.proxies(owner) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    /// @notice Claim `tokenId` for minting by presenting merkle proof `proof`.
    /// @param proof Merkle proof associated with the claim.
    /// @param tokenId Identifier of NFT being claimed.
    function claim(bytes32[] calldata proof, uint256 tokenId) external {
        bytes32 whitelist = _dropWhitelists[getDropId(tokenId)];
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, tokenId));

        if (!_verify(whitelist, proof, leaf)) {
            revert InvalidProof();
        }

        _mint(msg.sender, tokenId);
    }

    /// @notice Verifies `leaf` is part of merkle tree rooted at `merkleRoot`.
    function _verify(
        bytes32 merkleRoot,
        bytes32[] memory proof,
        bytes32 leaf
    ) private view returns (bool) 
    {
        bytes32 hash = leaf;

        unchecked {
            for (uint256 i = 0; i < proof.length; i++) {
                bytes32 proofElement = proof[i];
                if (hash <= proofElement) {
                    hash = keccak256(abi.encodePacked(hash, proofElement));
                } else {
                    hash = keccak256(abi.encodePacked(proofElement, hash));
                }
            }
            return hash == merkleRoot;
        }
    }


    /// @notice Retrieves the token metadata URI for NFT of id `tokenId`.
    /// @dev Before drop finalization, the token URI for an NFT is equivalent to
    ///  {baseURI}/{id}, and once a drop is finalized, it may be replaced by an
    ///  IPFS link whose contents equate to the initially set provenance hash.
    /// @param tokenId The identifier of the NFT being queried.
    function tokenURI(uint256 tokenId) 
        public 
        view 
        virtual 
        override 
        returns (string memory) 
    {
        if (ownerOf[tokenId] == address(0)) {
            revert NonExistentNFT();
        }

        string memory dropURI  = _dropURIs[getDropId(tokenId)];
		if (bytes(dropURI).length == 0) {
			dropURI = baseURI;
		}
		return string(abi.encodePacked(dropURI, _toString(tokenId)));
    }


	 function _toString(uint256 value) internal pure returns (string memory) {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

////////////////////////////////////////////////////////////////////////////////
///                               DOPAMINTPASS                               /// 
////////////////////////////////////////////////////////////////////////////////

/// @notice DopamintPass drop hit allocated capacity.
error DropMaxCapacity();

/// @notice Insufficient time passed since last drop was created.
error InsufficientTimePassed();

/// @notice Configured drop delay is invalid.
error InvalidDropDelay();

/// @notice Configured whitelist size is invalid.
error InvalidWhitelistSize();

/// @notice Configured drop size is invalid.
error InvalidDropSize();

/// @notice IPFS hash for the specified drop has already been set.
error IPFSHashAlreadySet();

/// @notice Action cannot be completed as a current drop is ongoing.
error OngoingDrop();

/// @notice No such drop exists.
error NonExistentDrop();

////////////////////////////////////////////////////////////////////////////////
///                          Dopamine Auction House                          ///
////////////////////////////////////////////////////////////////////////////////

/// @notice Auction has already been settled.
error SettledAuction();

/// @notice Bid placed was too low (see `reservePrice` and `MIN_BID_DIFF`).
error BidTooLow();

/// @notice The auction has expired.
error ExpiredAuction();

/// @notice Auction has yet to complete.
error IncompleteAuction();

/// @notice Auction duration set is invalid.
error InvalidDuration();

/// @notice Reserve price set is invalid.
error InvalidReservePrice();

/// @notice Time buffer set is invalid.
error InvalidTimeBuffer();

/// @notice Treasury split is invalid, must be in range [0, 100].
error InvalidTreasurySplit();

/// @notice The NFT specified is not up for auction.
error NotUpForAuction();

/// @notice Operation cannot be performed as auction is paused.
error PausedAuction();

/// @notice Auction has not yet started.
error UncommencedAuction();

/// @notice Operation cannot be performed as auction is unpaused.
error UnpausedAuction();

//////////////////////////////////////////////////////////////////////////////// 
///                                   MISC                                   ///
////////////////////////////////////////////////////////////////////////////////

/// @notice Number does not fit in 32 bytes.
error InvalidUint32();

/// @notice Block number being queried is invalid.
error InvalidBlock();

/// @notice Mismatch between input arrays.
error ArityMismatch();

/// @notice Reentrancy vulnerability.
error Reentrant();


////////////////////////////////////////////////////////////////////////////////
///                                 UPGRADES                                 ///
////////////////////////////////////////////////////////////////////////////////

/// @notice Contract already initialized.
error AlreadyInitialized();

/// @notice Upgrade requires either admin or vetoer privileges.
error UnauthorizedUpgrade();

////////////////////////////////////////////////////////////////////////////////
///                                 EIP-712                                  ///
////////////////////////////////////////////////////////////////////////////////

/// @notice Signature has expired and is no longer valid.
error ExpiredSignature();

/// @notice Signature invalid.
error InvalidSignature();

////////////////////////////////////////////////////////////////////////////////
///                                 ERC-721                                  ///
////////////////////////////////////////////////////////////////////////////////

/// @notice Token has already minted.
error DuplicateMint();

/// @notice Originating address does not own the NFT.
error InvalidOwner();

/// @notice Receiving contract does not implement the ERC721 wallet interface.
error InvalidReceiver();

/// @notice Receiving address cannot be the zero address.
error ZeroAddressReceiver();

/// @notice NFT does not exist.
error NonExistentNFT();

/// @notice NFT collection has hit maximum supply capacity.
error SupplyMaxCapacity();

/// @notice Sender is not NFT owner, approved address, or owner operator.
error UnauthorizedSender();

////////////////////////////////////////////////////////////////////////////////
///                              ADMINISTRATIVE                              ///
////////////////////////////////////////////////////////////////////////////////
 
/// @notice Function callable only by the admin.
error AdminOnly();

/// @notice Function callable only by the minter.
error MinterOnly();

/// @notice Function callable only by the owner.
error OwnerOnly();

/// @notice Function callable only by the pending owner.
error PendingAdminOnly();

////////////////////////////////////////////////////////////////////////////////
///                                GOVERNANCE                                ///
//////////////////////////////////////////////////////////////////////////////// 

/// @notice Proposal has already been settled.
error AlreadySettled();

/// @notice Proposal already voted for.
error AlreadyVoted();

/// @notice Duplicate transaction queued.
error DuplicateTransaction();

/// @notice Voting power insufficient.
error InsufficientVotingPower();

/// @notice Invalid number of actions proposed.
error InvalidActionCount();

/// @notice Invalid set timelock delay.
error InvalidDelay();

/// @notice Proposal threshold is invalid.
error InvalidProposalThreshold();

/// @notice Quorum threshold is invalid.
error InvalidQuorumThreshold();

/// @notice Vote type is not valid.
error InvalidVote();

/// @notice Voting delay set is invalid.
error InvalidVotingDelay();

/// @notice Voting period set is invalid.
error InvalidVotingPeriod();

/// @notice Only the proposer may invoke this action.
error ProposerOnly();

/// @notice Transaction executed prematurely.
error PrematureTx();

/// @notice Transaction execution was reverted.
error RevertedTx();

/// @notice Transaction is stale.
error StaleTx();

/// @notice Inactive proposals may not be voted for.
error InactiveProposal();

/// @notice Function callable only by the timelock itself.
error TimelockOnly();

/// @notice Proposal has failed to or has yet to be successful.
error UnpassedProposal();

/// @notice Proposal has failed to or has yet to be queued.
error UnqueuedProposal();

/// @notice Transaction is not yet queued.
error UnqueuedTx();

/// @notice A proposal is currently running and must be settled first.
error UnsettledProposal();

/// @notice Function callable only by the vetoer.
error VetoerOnly();

/// @notice Veto power has been revoked.
error VetoPowerRevoked();

////////////////////////////////////////////////////////////////////////////////
///                             Merkle Whitelist                             /// 
////////////////////////////////////////////////////////////////////////////////

/// @notice Whitelisted NFT already claimed.
error AlreadyClaimed();

/// @notice Proof for claim is invalid.
error InvalidProof();

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "./IDopamintPassEvents.sol";

import { IERC721 } from '@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface IDopamintPass is IERC721, IDopamintPassEvents {

    struct Drop {

        uint256 endIndex;

        bool initiated;

        uint256 endTime;
    }

    function setDropDelay(uint256 dropDelay) external;

    function mint() external returns (uint256);

    function setMinter(address minter) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IProxyRegistry {
    function proxies(address) external view returns (address);
}

// SPDX-License-Identifier: MIT

/// @title Minimal ERC721 Token Implementation

pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';

import '../errors.sol';

/// @title DθPΛM1NΞ ERC-721 base contract
/// @notice ERC-721 contract with metadata extension and maximum supply.
contract ERC721 is IERC721, IERC721Metadata {

    /// @notice Name of the NFT collection.
    string public name;

    /// @notice Abbreviated name of the NFT collection.
    string public symbol;

    /// @notice Total number of NFTs in circulation.
    uint256 public totalSupply;

    /// @notice Maximum allowed number of circulating NFTs.
	uint256 public immutable maxSupply;

    /// @notice Gets the number of NFTs owned by an address.
    /// @dev This implementation does not throw for 0-address queries.
    mapping(address => uint256) public balanceOf;

    /// @notice Gets the assigned owner of an address.
    mapping(uint256 => address) public ownerOf;

    /// @notice Gets the approved address for an NFT.
    mapping(uint256 => address) public getApproved;

    /// @notice Nonces for preventing replay attacks when signing.
    mapping(address => uint256) public nonces;

    /// @notice Checks for an owner if an address is an authorized operator.
    mapping(address => mapping(address => bool)) internal _operatorOf;

    /// @notice EIP-712 immutables for signing messages.
    uint256 internal immutable _CHAIN_ID;
    bytes32 internal immutable _DOMAIN_SEPARATOR;

    /// @notice EIP-165 identifiers for all supported interfaces.
    bytes4 private constant _ERC165_INTERFACE_ID = 0x01ffc9a7;
    bytes4 private constant _ERC721_INTERFACE_ID = 0x80ac58cd;
    bytes4 private constant _ERC721_METADATA_INTERFACE_ID = 0x5b5e139f;
    
    /// @notice Initialize the NFT collection contract.
    /// @param name_ Name of the NFT collection
    /// @param symbol_ Abbreviated name of the NFT collection.
    /// @param maxSupply_ Supply cap for the NFT collection
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_
    ) {
        name = name_;
        symbol = symbol_;
        maxSupply = maxSupply_;

        _CHAIN_ID = block.chainid;
        _DOMAIN_SEPARATOR = _buildDomainSeparator();
    }

    /// @notice Transfers NFT of id `id` from address `from` to address `to`,
    ///  without performing any safety checks.
    /// @param from The address of the current owner of the transferred NFT.
    /// @param to The address of the new owner of the transferred NFT.
    /// @param id The NFT being transferred.
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        _transferFrom(from, to, id);
    }

    /// @notice Transfers NFT of id `id` from address `from` to address `to`,
    ///  with safety checks ensuring `to` is capable of receiving the NFT.
    /// @param from The address of the current owner of the transferred NFT.
    /// @param to The address of the new owner of the transferred NFT.
    /// @param id The NFT being transferred.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        _transferFrom(from, to, id);

        if (
            to.code.length != 0 &&
                IERC721Receiver(to).onERC721Received(msg.sender, from, id, data) !=
                IERC721Receiver.onERC721Received.selector
        ) {
            revert InvalidReceiver();
        }
    }

    /// @notice Equivalent to preceding function with empty `data`.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        _transferFrom(from, to, id);

        if (
            to.code.length != 0 &&
                IERC721Receiver(to).onERC721Received(msg.sender, from, id, "") !=
                IERC721Receiver.onERC721Received.selector
        ) {
            revert InvalidReceiver();
        }
    }

    /// @notice Sets the approved address of NFT of id `id` to `approved`.
    /// @param approved The new approved address for the NFT
    /// @param id The id of the NFT to approve
    function approve(address approved, uint256 id) public virtual {
        address owner = ownerOf[id];

        if (msg.sender != owner && !_operatorOf[owner][msg.sender]) {
            revert UnauthorizedSender();
        }

        getApproved[id] = approved;
        emit Approval(owner, approved, id);
    }

    /// @notice Checks if `operator` is an authorized operator for `owner`.
    /// @param owner Address of the owner.
    /// @param operator Address for the owner's operator.
    /// @return true if `operator` is approved operator of `owner`, else false.
    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return _operatorOf[owner][operator];
    }

    /// @notice Sets the operator for `msg.sender` to `operator`.
    /// @param operator The operator address that will manage the sender's NFTs
    /// @param approved Whether the operator is allowed to operate sender's NFTs
    function setApprovalForAll(address operator, bool approved) public virtual {
        _operatorOf[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice Returns the token URI associated with the token of id `id`.
    function tokenURI(uint256) public view virtual returns (string memory) {
        return "";
    }

    /// @notice Checks if interface of identifier `interfaceId` is supported.
    /// @param interfaceId ERC-165 identifier
    /// @return `true` if `interfaceId` is supported, `false` otherwise.
    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == _ERC165_INTERFACE_ID ||
            interfaceId == _ERC721_INTERFACE_ID ||
            interfaceId == _ERC721_METADATA_INTERFACE_ID;
    }

    /// @notice Transfers NFT of id `id` from address `from` to address `to`.
    /// @dev Existence of an NFT is inferred by having a non-zero owner address.
    ///  To save gas, use Transfer events to track Approval clearances.
    /// @param from The address of the owner of the NFT.
    /// @param to The address of the new owner of the NFT.
    /// @param id The id of the NFT being transferred.
    function _transferFrom(address from, address to, uint256 id) internal virtual {
        if (from != ownerOf[id]) {
            revert InvalidOwner();
        }

        if (
            msg.sender != from &&
            msg.sender != getApproved[id] &&
            !_operatorOf[from][msg.sender]
        ) {
            revert UnauthorizedSender();
        }

        if (to == address(0)) {
            revert ZeroAddressReceiver();
        }

        _beforeTokenTransfer(from, to, id);

        delete getApproved[id];

        unchecked {
            balanceOf[from]--;
            balanceOf[to]++;
        }

        ownerOf[id] = to;
        emit Transfer(from, to, id);
    }

    /// @notice Mints NFT of id `id` to address `to`.
    /// @dev Assumes `maxSupply` < `type(uint256).max` to save on gas. 
    /// @param to Address receiving the minted NFT.
    /// @param id identifier of the NFT being minted.
    function _mint(address to, uint256 id) internal virtual returns (uint256) {
        if (to == address(0)) {
            revert ZeroAddressReceiver();
        }
        if (ownerOf[id] != address(0)) {
            revert DuplicateMint();
        }

        _beforeTokenTransfer(address(0), to, id);

        unchecked {
            totalSupply++;
            balanceOf[to]++;
        }
        if (totalSupply > maxSupply) {
            revert SupplyMaxCapacity();
        }
        ownerOf[id] = to;
        emit Transfer(address(0), to, id);
        return id;
    }

	/// @notice Burns NFT of id `id`.
    /// @param id Identifier of the NFT being burned
    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];

        if (owner == address(0)) {
            revert NonExistentNFT();
        }

        _beforeTokenTransfer(owner, address(0), id);

        unchecked {
            totalSupply--;
            balanceOf[owner]--;
        }

        delete ownerOf[id];
        emit Transfer(owner, address(0), id);
    }

    /// @notice Pre-transfer hook for adding additional functionality.
    /// @param from The address of the owner of the NFT.
    /// @param to The address of the new owner of the NFT.
    /// @param id The id of the NFT being transferred.
    function _beforeTokenTransfer(address from, address to, uint256 id) internal virtual {
    }

	/// @notice Generates an EIP-712 domain separator for an ERC-721.
    /// @return A 256-bit domain separator.
    function _buildDomainSeparator() internal view returns (bytes32) {
        return keccak256(
            abi.encode(
				keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
				keccak256(bytes(name)),
                keccak256("1"),
                block.chainid,
                address(this)
            )
        );
    }

	/// @notice Returns an EIP-712 encoding of structured data `structHash`.
    /// @param structHash The structured data to be encoded and signed.
    /// @return A bytestring suitable for signing in accordance to EIP-712.
    function _hashTypedData(bytes32 structHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparator(), structHash));
    }

    /// @notice Returns the domain separator tied to the contract.
    /// @dev Recreated if chain id changes, otherwise cached value is used.
    /// @return 256-bit domain separator tied to this contract.
    function _domainSeparator() internal view returns (bytes32) {
        if (block.chainid == _CHAIN_ID) {
            return _DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator();
        }
    }

}

// SPDX-License-Identifier: BSD-3-Clause

/// @title Compound-style vote checkpointing for ERC-721

pragma solidity ^0.8.9;

import './ERC721.sol';

/// @title DθPΛM1NΞ ERC-721 voting contract.
/// @notice ERC-721 voting contract inspired by Nouns DAO and Compound.
abstract contract ERC721Checkpointable is ERC721 {

	/// @notice Marker for recording the voting power held for a given block.
    /// @dev Packs 4 checkpoints per storage slot, and assumes supply < 2^32.
	struct Checkpoint {
		uint32 fromBlock;
		uint32 votes;
	}

	/// @notice Maps addresses to their currently selected voting delegates.
    /// @dev A delegate of address(0) corresponds to self-delegation.
	mapping(address => address) internal _delegates;

	/// @notice A record of voting checkpoints for an address.
	mapping(address => Checkpoint[]) public checkpoints;

	/// @notice EIP-712 typehash used for voting delegation.
	bytes32 public constant DELEGATION_TYPEHASH =
		keccak256('Delegate(address delegator,address delegatee,uint256 nonce,uint256 expiry)');

    /// @notice `delegator` changes delegate from `fromDelegate` to `toDelegate`.
    event DelegateChanged(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );

    /// @notice `delegate` votes change from `oldBalance` to `newBalance`.
    event DelegateVotesChanged(
        address indexed delegate,
        uint256 oldBalance,
        uint256 newBalance
    );

    /// @notice Constructs a new ERC-721 voting contract.
	constructor(string memory name_, string memory symbol_, uint256 maxSupply_)
        ERC721(name_, symbol_, maxSupply_) {
    }

    /// @notice Returns the currently assigned delegate for `delegator`.
    /// @dev A value of address(0) indicates self-delegation.
    /// @param `delegator` The address of the delegator
    /// @return Address of the assigned delegate, if it exists, else address(0).
    function delegates(address delegator) public view returns (address) {
        address current = _delegates[delegator];
        return current == address(0) ? delegator : current;
    }

    /// @notice Delegate voting power of `msg.sender` to `delegatee`.
    /// @param delegatee Address to become delegator's delegatee.
    function delegate(address delegatee) public {
        _delegate(msg.sender, delegatee);
    }

    /// @notice Have `delegator` delegate to `delegatee` using EIP-712 signing.
    /// @param delegator The address which is performing delegation.
    /// @param delegatee The address being delegated to.
    /// @param expiry The timestamp at which this signature is set to expire.
    /// @param v Transaction signature recovery identifier.
    /// @param r Transaction signature output component #1.
    /// @param s Transaction signature output component #2.
    function delegateBySig(
        address delegator,
        address delegatee,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        if (block.timestamp > expiry) {
            revert ExpiredSignature();
        }
        address signatory;
        unchecked {
            signatory = ecrecover(
                _hashTypedData(keccak256(abi.encode(DELEGATION_TYPEHASH, delegator, delegatee, nonces[delegator]++, expiry))),
                v,
                r,
                s
            );
        }
        if (signatory == address(0) || signatory != delegator) {
            revert InvalidSignature();
        }
        _delegate(signatory, delegatee);
    }

    /// @notice Get the current number of votes allocated for address `voter`.
    /// @param voter The address being queried.
    /// @return The number of votes for address `voter`.
    function getCurrentVotes(address voter) external view returns (uint32) {
        uint256 numCheckpoints = checkpoints[voter].length;
        return numCheckpoints == 0 ?
            0 : checkpoints[voter][numCheckpoints - 1].votes;
    }

    /// @notice Get number of checkpoints registered by a voter `voter`.
    /// @param voter Address of the voter being queried.
    /// @return The number of checkpoints assigned to `voter`.
    function getNumCheckpoints(address voter) public view returns (uint256) {
        return checkpoints[voter].length;
    }

    /// @notice Get number of votes for `voter` at block number `blockNumber`.
    /// @param voter Address of the voter being queried.
    /// @param blockNumber Block number being queried.
    /// @return The uint32 voting weight of `voter` at `blockNumber`.
    function getPriorVotes(address voter, uint256 blockNumber) public view returns (uint32) {
        if (blockNumber >= block.number) {
            revert InvalidBlock();
        }

        uint256 numCheckpoints = checkpoints[voter].length;
        if (numCheckpoints == 0) {
            return 0;
        }

        // Check common case of `blockNumber` being ahead of latest checkpoint.
        if (checkpoints[voter][numCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[voter][numCheckpoints - 1].votes;
        }

        // Check case of `blockNumber` being behind first checkpoint (0 votes).
        if (checkpoints[voter][0].fromBlock > blockNumber) {
            return 0;
        }

        // Run binary search to find 1st checkpoint at or before `blockNumber`.
        uint256 lower = 0;
        uint256 upper = numCheckpoints - 1;
        while (upper > lower) {
            uint256 center = upper - (upper - lower) / 2;
            Checkpoint memory cp = checkpoints[voter][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[voter][lower].votes;
    }

    /// @notice Delegate voting power of `delegator` to `delegatee`.
    /// @param delegator Address of the delegator
    /// @param delegatee Address of the delegatee
	function _delegate(address delegator, address delegatee) internal {
		if (delegatee == address(0)) delegatee = delegator;

		address currentDelegate = delegates(delegator);
		uint256 amount = balanceOf[delegator];

		_delegates[delegator] = delegatee;
		emit DelegateChanged(delegator, currentDelegate, delegatee);

		_transferDelegates(currentDelegate, delegatee, amount);
	}

    /// @notice Transfer `amount` voting power from `srcRep` to `dstRep`.
    /// @param srcRep The delegate whose votes are being transferred away from.
    /// @param dstRep The delegate who is being transferred additional votes.
    /// @param amount The number of votes being transferred.
	function _transferDelegates(
		address srcRep,
		address dstRep,
		uint256 amount
	) internal {
		if (srcRep != dstRep && amount > 0) {
			if (srcRep != address(0)) {
				(uint256 oldVotes, uint256 newVotes) = _writeCheckpoint(checkpoints[srcRep], _sub, amount);
				emit DelegateVotesChanged(srcRep, oldVotes, newVotes);
			}

			if (dstRep != address(0)) {
				(uint256 oldVotes, uint256 newVotes) = _writeCheckpoint(checkpoints[dstRep], _add, amount);
				emit DelegateVotesChanged(dstRep, oldVotes, newVotes);
			}
		}
	}

    /// @notice Adds a new checkpoint to `ckpts` by performing `op` of amount
    ///  `delta` on the last known checkpoint of `ckpts` (if it exists).
    /// @param ckpts Storage pointer to the Checkpoint array being modified
    /// @param op Function operation - either add or subtract
    /// @param delta Amount in voting units to be added or subtracted from.
	function _writeCheckpoint(
		Checkpoint[] storage ckpts,
		function(uint256, uint256) view returns (uint256) op,
		uint256 delta
	) private returns (uint256 oldVotes, uint256 newVotes) {
		uint256 numCheckpoints = ckpts.length;
		oldVotes = numCheckpoints == 0 ? 0 : ckpts[numCheckpoints - 1].votes;
		newVotes = op(oldVotes, delta);

		if ( // If latest checkpoint belonged to current block, just reassign.
             numCheckpoints > 0 && 
            ckpts[numCheckpoints - 1].fromBlock == block.number
        ) {
			ckpts[numCheckpoints - 1].votes = _safe32(newVotes);
		} else { // Otherwise, a new Checkpoint must be created.
			ckpts.push(Checkpoint({
				fromBlock: _safe32(block.number),
				votes: _safe32(newVotes)
			}));
		}
	}

    /// @notice Override pre-transfer hook to account for voting power transfer.
    /// @param from The address from which the NFT is being transferred.
    /// @param to The receiving address of the NFT.
    /// @param id The identifier of the NFT being transferred.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 id
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, id);
        _transferDelegates(delegates(from), delegates(to), 1);
    }


    /// @notice Safely downcasts a uint256 into a uint32.
	function _safe32(uint256 n) internal pure returns (uint32) {
        if (n > type(uint32).max) {
            revert InvalidUint32();
        }
		return uint32(n);
	}

	function _add(uint256 a, uint256 b) private pure returns (uint256) {
		return a + b;
	}

	function _sub(uint256 a, uint256 b) private pure returns (uint256) {
		return a - b;
	}

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

interface IDopamintPassEvents {

	event BaseURISet(string baseURI);

    event DropCreated(uint256 indexed dropId, uint256 startIndex, uint256 dropSize, uint256 whitelistSize, bytes32 whitelist, bytes32 provenanceHash);

    event DropDelaySet(uint256 dropDelay);

    event DropSizeSet(uint256 dropSize);

	event DropURISet(uint256 indexed dropId, string URI);

    event WhitelistSizeSet(uint256 whitelistSize);

    event MinterLocked();

    event NewMinter(address oldMinter, address newMinter);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}