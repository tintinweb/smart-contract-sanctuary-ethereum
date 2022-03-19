// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

////////////////////////////////////////////////////////////////////////////////
///				 ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./errors.sol";
import { IDopamintPass } from "./interfaces/IDopamintPass.sol";
import { IProxyRegistry } from "./interfaces/IProxyRegistry.sol";
import { ERC721 } from "./erc721/ERC721.sol";
import { ERC721Checkpointable } from "./erc721/ERC721Checkpointable.sol";

/// @title Dopamine DAO ERC-721 membership pass
/// @notice DopamintPass holders are first-class members of the Dopamine DAO.
///  The passes are minted through drops of varying sizes and durations, and
///  each drop features a separate set of NFT metadata. These parameters are 
///  configurable by address `owner`, with the emissions controlled by address 
///  `minter`. A drop is "completed" once all non-whitelisted passes are minted.
contract DopamintPass is ERC721Checkpointable, IDopamintPass {

    /// @notice The name of the Dopamine membership pass.
    string public constant NAME = "DopamintPass";

    /// @notice The abbreviated name of the Dopamine membership pass.
    string public constant SYMBOL = "DOPE";

    /// @notice The maximum number of passes that may be whitelisted per drop.
    uint256 public constant MAX_WL_SIZE = 99;

    /// @notice The minimum number of passes that can be minted for a drop.
    uint256 public constant MIN_DROP_SIZE = 1;

    /// @notice The maximum number of passes that can be minted for a drop.
    uint256 public constant MAX_DROP_SIZE = 9999;

    /// @notice The minimum delay to wait between creations of drops.
    uint256 public constant MIN_DROP_DELAY = 4 weeks;

    /// @notice The maximum delay to wait between creations of drops.
    uint256 public constant MAX_DROP_DELAY = 24 weeks;

    /// @notice The address administering drop creation, sizing, and scheduling.
    address public owner;

    /// @notice The address responsible for controlling pass emissions.
    address public minter;

    /// @notice The OS registry addresss - whitelisted for gasless OS approvals.
    IProxyRegistry public proxyRegistry;

    /// @notice The URI each pass initially points to for metadata resolution.
    /// @dev Before drop completion, `tokenURI()` resolves to "{baseURI}/{id}".
    string public baseURI = "https://dopamine.xyz/";

    /// @notice The number of passes for each drop (includes those whitelisted).
    uint256 public dropSize;

    /// @notice The minimum time to wait in seconds between drop creations.
    uint256 public dropDelay; 

    /// @notice The number of passes to allocate for whitelisting for each drop.
    uint256 public whitelistSize;

    /// @notice The current drop's ending token id (exclusive boundary).
    uint256 public dropEndIndex;

    /// @notice The time at which a new drop can start (if last drop completed).
    uint256 public dropEndTime;

    /// @dev Maps a drop id to the associated drop's provenance hash.
    mapping(uint256 => bytes32) private _dropProvenanceHashes;

    /// @dev Maps a drop id to the finalized IPFS / Arweave pass metadata URI.
    ///  On drop completion, `tokenURI()` resolves to "{_dropURIs[dropId]/{id}".
    mapping(uint256 => string) private _dropURIs;

    /// @dev Maps a drop id to the whitelist (a merkle tree root) for that drop.
    ///  A drop whitelist is only addable once, by the owner, on drop creation.
    mapping(uint256 => bytes32) private _dropWhitelists;

    /// @dev Maps a drop id to its ending token id (exclusive boundary).
    uint256[] private _dropEndIndices;

    /// @dev An internal tracker for the id of the next pass to mint.
    uint256 private _id;

    /// @notice Restricts a function call to address `minter`.
    modifier onlyMinter() {
        if (msg.sender != minter) {
            revert MinterOnly();
        }
        _;
    }

    /// @notice Restricts a function call to address `owner`.
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert OwnerOnly();
        }
        _;
    }

    /// @notice Initializes the membership pass with specified drop settings.
    /// @param minter_ The address which will control pass emissions.
    /// @param proxyRegistry_ The OS proxy registry address.
    /// @param dropSize_ The number of passes to issue for each drop.
    /// @param dropDelay_ The minimum delay to wait between creations of drops.
    /// @dev `owner` is intended to eventually switch to the Dopamine DAO proxy.
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

    /// @inheritdoc IDopamintPass
    /// @dev See `_verify` to understand how whitelist verification works. Leaf
    ///  nodes are formed using the encoded tuple (`msg.sender`, `id`) as input.
    function claim(bytes32[] calldata proof, uint256 id) external {
        bytes32 whitelist = _dropWhitelists[getDropId(id)];
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, id));

        if (!_verify(whitelist, proof, leaf)) {
            revert ProofInvalid();
        }

        _mint(msg.sender, id);
    }

    /// @inheritdoc IDopamintPass
    function mint() public onlyMinter returns (uint256) {
        if (_id >= dropEndIndex) {
            revert DropMaxCapacity();
        }
        return _mint(minter, _id++);
    }

    /// @inheritdoc IDopamintPass
    /// @dev See `_verify` to understand how whitelist generation works.
    function createDrop(bytes32 whitelist,  bytes32 provenanceHash)
        external 
        onlyOwner 
    {
        if (_id < dropEndIndex) {
            revert DropOngoing();
        }
        if (block.timestamp < dropEndTime) {
            revert DropTooEarly();
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

    /// @inheritdoc IDopamintPass
    function setMinter(address newMinter) external onlyOwner {
        emit NewMinter(minter, newMinter);
        minter = newMinter;
    }

    /// @inheritdoc IDopamintPass
    function setWhitelistSize(uint256 newWhitelistSize) public onlyOwner {
        if (newWhitelistSize > MAX_WL_SIZE || newWhitelistSize > dropSize) {
            revert DropWhitelistOverCapacity();
        }
        whitelistSize = newWhitelistSize;
        emit WhitelistSizeSet(whitelistSize);
    }

    /// @notice Sets the drop size `dropSize` to `newDropSize`.
    function setDropSize(uint256 newDropSize) public onlyOwner {
        if (newDropSize < MIN_DROP_SIZE || newDropSize > MAX_DROP_SIZE) {
            revert DropSizeInvalid();
        }
        dropSize = newDropSize;
        emit DropSizeSet(dropSize);
    }

    /// @notice Sets the drop delay `dropDelay` to `newDropDelay`.
    function setDropDelay(uint256 newDropDelay) public override onlyOwner {
        if (newDropDelay < MIN_DROP_DELAY || newDropDelay > MAX_DROP_DELAY) {
            revert DropDelayInvalid();
        }
        dropDelay = newDropDelay;
        emit DropDelaySet(dropDelay);
    }

    /// @notice Sets the final metadata URI for drop `dropId` to `dropURI`.
    /// @param dropId The id of the drop whose final metadata URI is being set.
	/// @param dropURI The finalized IPFS / Arweave metadata URI.
	function setDropURI(uint256 dropId, string calldata dropURI)
        public 
        onlyOwner 
    {
        uint256 numDrops = _dropEndIndices.length;
        if (dropId >= numDrops) {
            revert DropNonExistent();
        }
        _dropURIs[dropId] = dropURI;
        emit DropURISet(dropId, dropURI);
	}

    /// @notice Sets the base URI, `baseUri`, to `newBaseURI`.
	function setBaseURI(string calldata newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
        emit BaseURISet(newBaseURI);
	}

    /// @notice Retrieves the drop id of the pass with id `id`.
    /// @dev This function only reverts for non-existent drops. The drop id will
    ///  still be returned for an unminted pass belonging to a created drop.
    /// @return The drop id of the queried pass.
    function getDropId(uint256 id) public view returns (uint256) {
        for (uint256 i = 0; i < _dropEndIndices.length; i++) {
            if (id  < _dropEndIndices[i]) {
                return i;
            }
        }
        revert DropNonExistent();
    }
	
    /// @notice Retrieves a URI describing the overall contract-level metadata.
    /// @return A string URI pointing to the pass contract metadata.
    function contractURI() public returns (string memory)  {
        return string(abi.encodePacked(baseURI, "metadata"));
    }

    /// @notice Retrieves the token URI for the pass with id `id`.
    /// @dev Before drop completion, the token URI for pass of id `id` defaults
    ///  to {baseURI}/{id}, and on drop completion it should be replaced by an
    ///  IPFS / Arweave URI whose contents match the drop's provenance hash.
    /// @param id The id of the pass being queried.
    /// @return A string URI pointing to metadata of the queried pass.
    function tokenURI(uint256 id) 
        public 
        view 
        virtual 
        override 
        returns (string memory) 
    {
        if (ownerOf[id] == address(0)) {
            revert TokenNonExistent();
        }

        string memory dropURI  = _dropURIs[getDropId(id)];
		if (bytes(dropURI).length == 0) {
			dropURI = baseURI;
		}
		return string(abi.encodePacked(dropURI, _toString(id)));
    }


    /// @dev Ensures OS proxy is whitelisted for operating on behalf of owners.
    /// @inheritdoc ERC721
    function isApprovedForAll(address owner, address operator) 
        public 
        view 
        override(IERC721, ERC721) 
        returns (bool) 
    {
        if (proxyRegistry.proxies(owner) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    /// @dev Checks whether `leaf` is part of merkle tree rooted at `merkleRoot`
    ///  using proof `proof`. Merkle tree generation and proof construction is
    ///  done using the following JS library: github.com/miguelmota/merkletreejs
    /// @param merkleRoot The hexlified merkle root as a bytes32 data type.
    /// @param proof The abi-encoded proof formatted as a bytes32 array.
    /// @param leaf The leaf node being checked for (uses keccak-256 hashing).
    /// @return True if `leaf` is in `merkleRoot`-rooted tree, false otherwise.
    function _verify(
        bytes32 merkleRoot,
        bytes32[] memory proof,
        bytes32 leaf
    ) private view returns (bool) 
    {
        bytes32 hash = leaf;
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

    /// @dev Converts a uint256 into a string.
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

/// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

////////////////////////////////////////////////////////////////////////////////
///				 ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

// This file is a shared repository of all errors used in Dopamine's contracts.

////////////////////////////////////////////////////////////////////////////////
///                               DopamintPass                               /// 
////////////////////////////////////////////////////////////////////////////////

/// @notice Configured drop delay is invalid.
error DropDelayInvalid();

/// @notice DopamintPass drop hit allocated capacity.
error DropMaxCapacity();

/// @notice No such drop exists.
error DropNonExistent();

/// @notice Action cannot be completed as a current drop is ongoing.
error DropOngoing();

/// @notice Configured drop size is invalid.
error DropSizeInvalid();

/// @notice Insufficient time passed since last drop was created.
error DropTooEarly();

/// @notice Configured whitelist size is too large.
error DropWhitelistOverCapacity();

////////////////////////////////////////////////////////////////////////////////
///                          Dopamine Auction House                          ///
////////////////////////////////////////////////////////////////////////////////

/// @notice Auction has already been settled.
error AuctionAlreadySettled();

/// @notice The NFT specified in the auction bid is invalid.
error AuctionBidTokenInvalid();

/// @notice Bid placed was too low (see `reservePrice` and `MIN_BID_DIFF`).
error AuctionBidTooLow();

/// @notice Auction duration set is invalid.
error AuctionDurationInvalid();

/// @notice The auction has expired.
error AuctionExpired();

/// @notice Operation cannot be performed as auction is paused.
error AuctionMustBePaused();

/// @notice Operation cannot be performed as auction is unpaused.
error AuctionMustBeUnpaused();

/// @notice Auction has not yet started.
error AuctionNotYetStarted();

/// @notice Auction has yet to complete.
error AuctionOngoing();

/// @notice Reserve price set is invalid.
error AuctionReservePriceInvalid();

/// @notice Time buffer set is invalid.
error AuctionTimeBufferInvalid();

/// @notice Treasury split is invalid, must be in range [0, 100].
error AuctionTreasurySplitInvalid();

//////////////////////////////////////////////////////////////////////////////// 
///                              Miscellaneous                               ///
////////////////////////////////////////////////////////////////////////////////

/// @notice Mismatch between input arrays.
error ArityMismatch();

/// @notice Block number being queried is invalid.
error BlockInvalid();

/// @notice Reentrancy vulnerability.
error FunctionReentrant();

/// @notice Number does not fit in 32 bytes.
error Uint32ConversionInvalid();

////////////////////////////////////////////////////////////////////////////////
///                                 Upgrades                                 ///
////////////////////////////////////////////////////////////////////////////////

/// @notice Contract already initialized.
error ContractAlreadyInitialized();

/// @notice Upgrade requires either admin or vetoer privileges.
error UpgradeUnauthorized();

////////////////////////////////////////////////////////////////////////////////
///                                 EIP-712                                  ///
////////////////////////////////////////////////////////////////////////////////

/// @notice Signature has expired and is no longer valid.
error SignatureExpired();

/// @notice Signature invalid.
error SignatureInvalid();

////////////////////////////////////////////////////////////////////////////////
///                                 EIP-721                                  ///
////////////////////////////////////////////////////////////////////////////////

/// @notice Originating address does not own the NFT.
error OwnerInvalid();

/// @notice Receiving address cannot be the zero address.
error ReceiverInvalid();

/// @notice Receiving contract does not implement the ERC721 wallet interface.
error SafeTransferUnsupported();

/// @notice Sender is not NFT owner, approved address, or owner operator.
error SenderUnauthorized();

/// @notice NFT collection has hit maximum supply capacity.
error SupplyMaxCapacity();

/// @notice Token has already minted.
error TokenAlreadyMinted();

/// @notice NFT does not exist.
error TokenNonExistent();

////////////////////////////////////////////////////////////////////////////////
///                              Administrative                              ///
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
///                                Governance                                ///
//////////////////////////////////////////////////////////////////////////////// 

/// @notice Invalid number of actions proposed.
error ProposalActionCountInvalid();

/// @notice Proposal has already been settled.
error ProposalAlreadySettled();

/// @notice Inactive proposals may not be voted for.
error ProposalInactive();

/// @notice Proposal has failed to or has yet to be queued.
error ProposalNotYetQueued();

/// @notice Quorum threshold is invalid.
error ProposalQuorumThresholdInvalid();

/// @notice Proposal threshold is invalid.
error ProposalThresholdInvalid();

/// @notice Proposal has failed to or has yet to be successful.
error ProposalUnpassed();

/// @notice A proposal is currently running and must be settled first.
error ProposalUnsettled();

/// @notice Voting delay set is invalid.
error ProposalVotingDelayInvalid();

/// @notice Voting period set is invalid.
error ProposalVotingPeriodInvalid();

/// @notice Only the proposer may invoke this action.
error ProposerOnly();

/// @notice Function callable only by the vetoer.
error VetoerOnly();

/// @notice Veto power has been revoked.
error VetoPowerRevoked();

/// @notice Proposal already voted for.
error VoteAlreadyCast();

/// @notice Vote type is not valid.
error VoteInvalid();

/// @notice Voting power insufficient.
error VotingPowerInsufficient();

////////////////////////////////////////////////////////////////////////////////
///                                 Timelock                                 /// 
////////////////////////////////////////////////////////////////////////////////

/// @notice Invalid set timelock delay.
error TimelockDelayInvalid();

/// @notice Function callable only by the timelock itself.
error TimelockOnly();

/// @notice Duplicate transaction queued.
error TransactionAlreadyQueued();

/// @notice Transaction is not yet queued.
error TransactionNotYetQueued();

/// @notice Transaction executed prematurely.
error TransactionPremature();

/// @notice Transaction execution was reverted.
error TransactionReverted();

/// @notice Transaction is stale.
error TransactionStale();

////////////////////////////////////////////////////////////////////////////////
///                             Merkle Whitelist                             /// 
////////////////////////////////////////////////////////////////////////////////

/// @notice Proof for claim is invalid.
error ProofInvalid();

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

////////////////////////////////////////////////////////////////////////////////
///				 ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

import { IERC721 } from '@openzeppelin/contracts/token/ERC721/IERC721.sol';

import "./IDopamintPassEvents.sol";

/// @title Interface for the Dopamine DAO ERC-721 membership pass
interface IDopamintPass is IERC721, IDopamintPassEvents {

    /// @notice Mints pass of id `id` to `msg.sender` if proof `proof` is valid.
    /// @param proof The Merkle proof of the claim as a bytes32 array.
    /// @param id The id of the pass being claimed.
    function claim(bytes32[] calldata proof, uint256 id) external;

    /// @notice Mints a pass to address `minter`.
    /// @return Id of the minted pass, which is always equal to `_id`.
    function mint() external returns (uint256);

    /// @notice Creates a new pass drop.
    /// @param whitelist A merkle root whose tree is comprised of whitelisted 
    ///  addresses and their assigned pass ids. This assignment is permanent.
    /// @param provenanceHash An immutable provenance hash equal to the SHA-256
    ///  hash of the concatenation of all SHA-256 image hashes of the drop.
    function createDrop(bytes32 whitelist, bytes32 provenanceHash) external;

    /// @notice Sets the minter address `minter` to `newMinter`.
    function setMinter(address newMinter) external;

    /// @notice Sets the whitelist size `whitelistSize` to `newWhitelistSize`.
    function setWhitelistSize(uint256 newWhitelistSize) external;

    function setDropDelay(uint256 newDropDelay) external;


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
            revert SafeTransferUnsupported();
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
            revert SafeTransferUnsupported();
        }
    }

    /// @notice Sets the approved address of NFT of id `id` to `approved`.
    /// @param approved The new approved address for the NFT
    /// @param id The id of the NFT to approve
    function approve(address approved, uint256 id) public virtual {
        address owner = ownerOf[id];

        if (msg.sender != owner && !_operatorOf[owner][msg.sender]) {
            revert SenderUnauthorized();
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
            revert OwnerInvalid();
        }

        if (
            msg.sender != from &&
            msg.sender != getApproved[id] &&
            !_operatorOf[from][msg.sender]
        ) {
            revert SenderUnauthorized();
        }

        if (to == address(0)) {
            revert ReceiverInvalid();
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
            revert ReceiverInvalid();
        }
        if (ownerOf[id] != address(0)) {
            revert TokenAlreadyMinted();
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
            revert TokenNonExistent();
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
            revert SignatureExpired();
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
            revert SignatureInvalid();
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
            revert BlockInvalid();
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
            revert Uint32ConversionInvalid();
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