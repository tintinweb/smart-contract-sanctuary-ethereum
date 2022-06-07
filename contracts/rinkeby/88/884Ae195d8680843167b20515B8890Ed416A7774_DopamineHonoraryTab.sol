// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

import { IDopamineHonoraryTab } from "./interfaces/IDopamineHonoraryTab.sol";
import { IOpenSeaProxyRegistry } from "./interfaces/IOpenSeaProxyRegistry.sol";
import { ERC721H } from "./erc721/ERC721H.sol";
import "./Errors.sol";

/// @title Dopamine honorary ERC-721 membership tab
/// @notice Dopamine honorary tabs are vanity tabs for friends of Dopamine.
contract DopamineHonoraryTab is ERC721H, IDopamineHonoraryTab {

    /// @notice The address administering minting and metadata settings.
    address public owner;

    /// @notice The OS registry address - allowlisted for gasless OS approvals.
    IOpenSeaProxyRegistry public proxyRegistry;

    /// @notice The URI each tab initially points to for metadata resolution.
    /// @dev Before drop completion, `tokenURI()` resolves to "{baseURI}/{id}".
    string public baseURI = "https://staging-api.dopamine.xyz/honoraries/metadata";

    /// @notice The permanent URI tabs will point to on collection finality.
    /// @dev After drop completion, `tokenURI()` directs to "{storageURI}/{id}".
    string public storageURI;

    /// @notice Restricts a function call to address `owner`.
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert OwnerOnly();
        }
        _;
    }

    /// @notice Instantiates a new Dopamine honorary membership tab contract.
    /// @param proxyRegistry_ The OpenSea proxy registry address.
    /// @param reserve_ Address to which EIP-2981 royalties direct to.
    /// @param royalties_ Royalties sent to `reserve_` on sales, in bips.
    constructor(
        IOpenSeaProxyRegistry proxyRegistry_,
        address reserve_,
        uint96 royalties_
    ) ERC721H("Dopamine Honorary Tabs", "HDOPE") {
        owner = msg.sender;
        proxyRegistry = proxyRegistry_;
        _setRoyalties(reserve_, royalties_);
    }

    /// @inheritdoc IDopamineHonoraryTab
    function mint(address to) external onlyOwner {
        return _mint(owner, to);
    }

    /// @inheritdoc IDopamineHonoraryTab
    function contractURI() external view returns (string memory)  {
        return string(abi.encodePacked(baseURI, "contract"));
    }

    /// @inheritdoc IDopamineHonoraryTab
    function setOwner(address newOwner) external onlyOwner {
        owner = newOwner;
        emit OwnerChanged(owner, newOwner);
    }

    /// @inheritdoc IDopamineHonoraryTab
    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit BaseURISet(newBaseURI);
    }

    /// @inheritdoc IDopamineHonoraryTab
    function setStorageURI(string calldata newStorageURI) external onlyOwner {
        storageURI = newStorageURI;
        emit StorageURISet(newStorageURI);
    }

    /// @inheritdoc IDopamineHonoraryTab
    function setRoyalties(
        address receiver,
        uint96 royalties
    ) external onlyOwner {
        _setRoyalties(receiver, royalties);
    }

    /// @inheritdoc ERC721H
    /// @dev Before all honoraries are minted, the token URI for tab of id `id`
    ///  defaults to {baseURI}/{id}. Once all honoraries are minted, this will
    ///  be replaced with a decentralized storage URI (Arweave / IPFS) given by
    ///  {storageURI}/{id}. If `id` does not exist, this function reverts.
    /// @param id The id of the NFT being queried.
    function tokenURI(uint256 id)
        public
        view
        virtual
        override(ERC721H)
        returns (string memory)
    {
        if (ownerOf[id] == address(0)) {
            revert TokenNonExistent();
        }

        string memory uri = storageURI;
        if (bytes(uri).length == 0) {
            uri = baseURI;
        }
        return string(abi.encodePacked(uri, _toString(id)));
    }

    /// @dev Ensures OS proxy is allowlisted for operating on behalf of owners.
    /// @inheritdoc ERC721H
    function isApprovedForAll(address owner, address operator)
    public
    view
        override
        returns (bool)
    {
        return
            proxyRegistry.proxies(owner) == operator ||
            _operatorApprovals[owner][operator];
    }

    /// @dev Converts a uint256 into a string.
    /// @param value A positive uint256 value.
    function _toString(uint256 value) internal pure returns (string memory) {
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

import "./IDopamineHonoraryTabEvents.sol";

/// @title Dopamine ERC-721 honorary membership tab interface
interface IDopamineHonoraryTab is IDopamineHonoraryTabEvents {

    /// @notice Mints an honorary Dopamine tab to address `to`.
    /// @dev This function is only callable by the owner address.
    function mint(address to) external;

    /// @notice Gets the owner address, which controls minting and metadata.
    function owner() external view returns (address);

    /// @notice Retrieves a URI describing the overall contract-level metadata.
    /// @return A string URI pointing to the tab contract metadata.
    function contractURI() external view returns (string memory);

    /// @notice Sets the owner address to `newOwner`.
    /// @param newOwner The address of the new owner.
    /// @dev This function is only callable by the owner address.
    function setOwner(address newOwner) external;

    /// @notice Sets the base URI to `newBaseURI`.
    /// @param newBaseURI The new base metadata URI to set for the collection.
    /// @dev This function is only callable by the owner address.
    function setBaseURI(string calldata newBaseURI) external;

    /// @notice Sets the permanent storage URI to `newStorageURI`.
    /// @param newStorageURI The new permanent URI to set for the collection.
    /// @dev This function is only callable by the owner address.
    function setStorageURI(string calldata newStorageURI) external;

    /// @notice Sets the EIP-2981 royalties for the NFT collection.
    /// @param receiver Address to which royalties will be received.
    /// @param royalties The amount of royalties to receive, in bips.
    /// @dev This function is only callable by the owner address.
    function setRoyalties(address receiver, uint96 royalties) external;

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title OpenSea proxy registry interface
interface IOpenSeaProxyRegistry {

    /// @notice Returns the proxy account associated with an OS user address.
    function proxies(address) external view returns (address);

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// Transfer & minting methods derive from ERC721.sol of solmate.

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC2981} from "../interfaces/IERC2981.sol";

import "../Errors.sol";

/// @title ERC-721 contract built for Dopamine honorary tabs.
/// @notice This is a minimal ERC-721 implementation that supports the metadata
///  extension, total supply tracking, and EIP-2981 royalties.
/// @dev This ERC-721 implementation is optimized for mints and transfers of
///  individual NFTs, as opposed to mints and transfers of NFT batches.
contract ERC721H is IERC721, IERC721Metadata, IERC2981 {

    /// @notice The name of this NFT collection.
    string public name;

    /// @notice The abbreviated name of this NFT collection.
    string public symbol;

    /// @notice The total number of NFTs in circulation.
    uint256 public totalSupply;

    /// @notice Gets the number of NFTs owned by an address.
    /// @dev This implementation does not throw for zero-address queries.
    mapping(address => uint256) public balanceOf;

    /// @notice Gets the assigned owner of an address.
    /// @dev This implementation does not throw for NFTs of the zero address.
    mapping(uint256 => address) public ownerOf;

    /// @notice Gets the approved address for an NFT.
    /// @dev This implementation does not throw for zero-address queries.
    mapping(uint256 => address) public getApproved;

    /// @dev Checks for an owner if an address is an authorized operator.
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    // EIP-2981 collection-wide royalties information.
    RoyaltiesInfo internal _royaltiesInfo;

    // EIP-165 identifiers for all supported interfaces.
    bytes4 private constant _ERC165_INTERFACE_ID = 0x01ffc9a7;
    bytes4 private constant _ERC721_INTERFACE_ID = 0x80ac58cd;
    bytes4 private constant _ERC721_METADATA_INTERFACE_ID = 0x5b5e139f;
    bytes4 private constant _ERC2981_METADATA_INTERFACE_ID = 0x2a55205a;

    /// @notice Instantiates a new ERC-721 contract.
    /// @param name_ The name of the NFT.
    /// @param symbol_ The abbreviated name of the NFT.
    constructor(
        string memory name_,
        string memory symbol_
    ) {
        name = name_;
        symbol = symbol_;
    }

    /// @notice Transfers NFT of id `id` from address `from` to address `to`,
    ///  with safety checks ensuring `to` is capable of receiving the NFT.
    /// @dev Safety checks are only performed if `to` is a smart contract.
    /// @param from The existing owner address of the NFT to be transferred.
    /// @param to The address of the new owner of the NFT to be transferred.
    /// @param id The id of the NFT being transferred.
    /// @param data Additional transfer data to pass to the receiving contract.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) external {
        transferFrom(from, to, id);

        if (
            to.code.length != 0 &&
                IERC721Receiver(to).onERC721Received(msg.sender, from, id, data)
                !=
                IERC721Receiver.onERC721Received.selector
        ) {
            revert SafeTransferUnsupported();
        }
    }

    /// @notice Transfers NFT of id `id` from address `from` to address `to`,
    ///  with safety checks ensuring `to` is capable of receiving the NFT.
    /// @dev Safety checks are only performed if `to` is a smart contract.
    /// @param from The existing owner address of the NFT to be transferred.
    /// @param to The address of the new owner of the NFT to be transferred.
    /// @param id The id of the NFT being transferred.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) external {
        transferFrom(from, to, id);

        if (
            to.code.length != 0 &&
                IERC721Receiver(to).onERC721Received(msg.sender, from, id, "")
                !=
                IERC721Receiver.onERC721Received.selector
        ) {
            revert SafeTransferUnsupported();
        }
    }

    /// @inheritdoc IERC2981
    function royaltyInfo(
        uint256,
        uint256 salePrice
    ) external view returns (address, uint256) {
        RoyaltiesInfo memory royaltiesInfo = _royaltiesInfo;
        uint256 royalties = (salePrice * royaltiesInfo.royalties) / 10000;
        return (royaltiesInfo.receiver, royalties);
    }

    /// @notice Transfers NFT of id `id` from address `from` to address `to`,
    ///  without performing any safety checks.
    /// @dev Existence of an NFT is inferred by having a non-zero owner address.
    ///  Transfers clear owner approvals, but `Approval` events are omitted.
    /// @param from The existing owner address of the NFT to be transferred.
    /// @param to The address of the new owner of the NFT to be transferred.
    /// @param id The id of the NFT being transferred.
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public {
        if (from != ownerOf[id]) {
            revert OwnerInvalid();
        }

        if (
            msg.sender != from &&
            msg.sender != getApproved[id] &&
            !_operatorApprovals[from][msg.sender]
        ) {
            revert SenderUnauthorized();
        }

        if (to == address(0)) {
            revert ReceiverInvalid();
        }

        delete getApproved[id];

        unchecked {
            balanceOf[from]--;
            balanceOf[to]++;
        }

        ownerOf[id] = to;
        emit Transfer(from, to, id);
    }

    /// @notice Sets approved address of NFT of id `id` to address `approved`.
    /// @param approved The new approved address for the NFT.
    /// @param id The id of the NFT to approve.
    function approve(address approved, uint256 id) public virtual {
        address owner = ownerOf[id];

        if (msg.sender != owner && !_operatorApprovals[owner][msg.sender]) {
            revert SenderUnauthorized();
        }

        getApproved[id] = approved;
        emit Approval(owner, approved, id);
    }

    /// @notice Checks if `operator` is an authorized operator for `owner`.
    /// @param owner The address of the owner.
    /// @param operator The address for the owner's operator.
    /// @return True if `operator` is approved operator of `owner`, else false.
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /// @notice Sets the operator for `msg.sender` to `operator`.
    /// @param operator The operator address that will manage the sender's NFTs.
    /// @param approved Whether operator is allowed to operate on sender's NFTs.
    function setApprovalForAll(address operator, bool approved) public {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice Returns the metadata URI associated with the NFT of id `id`.
    /// @return A string URI pointing to the metadata of the queried NFT.
    function tokenURI(uint256) public view virtual returns (string memory) {
        return "";
    }

    /// @notice Checks if interface of identifier `id` is supported.
    /// @param id The EIP-165 interface identifier.
    /// @return True if interface id `id` is supported, false otherwise.
    function supportsInterface(bytes4 id) public pure virtual returns (bool) {
        return
            id == _ERC165_INTERFACE_ID ||
            id == _ERC721_INTERFACE_ID ||
            id == _ERC721_METADATA_INTERFACE_ID ||
            id == _ERC2981_METADATA_INTERFACE_ID;
    }

    /// @notice Mints NFT of id `totalSupply + 1` to address `to`.
    /// @param creator Address to which NFT creation attribution is assigned.
    /// @param to Address receiving the minted NFT.
    function _mint(address creator, address to) internal {
        if (to == address(0)) {
            revert ReceiverInvalid();
        }

        unchecked {
            totalSupply++;
            balanceOf[to]++;
        }

        ownerOf[totalSupply] = to;
        emit Transfer(address(0), creator, totalSupply);
        emit Transfer(creator, to, totalSupply);
    }

    /// @notice Sets EIP-2981 royalty information for NFTs in the collection.
    /// @param receiver Address which will receive token royalties.
    /// @param royalties Amount of royalties to be sent, in bips.
    function _setRoyalties(address receiver, uint96 royalties) internal {
        if (royalties > 10000) {
            revert RoyaltiesTooHigh();
        }
        if (receiver == address(0)) {
            revert ReceiverInvalid();
        }
        _royaltiesInfo = RoyaltiesInfo(receiver, royalties);
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

// This file is a shared repository of all errors used in Dopamine's contracts.

////////////////////////////////////////////////////////////////////////////////
///                               DopamineTab                               ///
////////////////////////////////////////////////////////////////////////////////

/// @notice Configured drop delay is invalid.
error DropDelayInvalid();

/// @notice Drop hit allocated capacity.
error DropMaxCapacity();

/// @notice No such drop exists.
error DropNonExistent();

/// @notice Action cannot be completed as a current drop is ongoing.
error DropOngoing();

/// @notice Configured drop size is invalid.
error DropSizeInvalid();

/// @notice Insufficient time passed since the last drop was created.
error DropTooEarly();

/// @notice Configured allowlist size is too large.
error DropAllowlistOverCapacity();

////////////////////////////////////////////////////////////////////////////////
///                          Dopamine Auction House                          ///
////////////////////////////////////////////////////////////////////////////////

/// @notice Auction has already been settled.
error AuctionAlreadySettled();

/// @notice The NFT specified in the auction bid is invalid.
error AuctionBidInvalid();

/// @notice Bid placed was too low.
error AuctionBidTooLow();

/// @notice Auction duration set is invalid.
error AuctionDurationInvalid();

/// @notice The auction has expired.
error AuctionExpired();

/// @notice Operation cannot be performed as auction is not yet suspended.
error AuctionNotSuspended();

/// @notice Operation cannot be performed as auction is already suspended.
error AuctionAlreadySuspended();

/// @notice Auction has yet to complete.
error AuctionOngoing();

/// @notice Reserve price set is invalid.
error AuctionReservePriceInvalid();

/// @notice Time buffer set is invalid.
error AuctionTimeBufferInvalid();

/// @notice Treasury split is invalid as it must be in the range [0, 100].
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

/// @notice Number does not fit into 32 bytes.
error Uint32ConversionInvalid();

////////////////////////////////////////////////////////////////////////////////
///                                 Upgrades                                 ///
////////////////////////////////////////////////////////////////////////////////

/// @notice Contract already initialized.
error ContractAlreadyInitialized();

/// @notice Upgrade is unauthorized.
error UpgradeUnauthorized();

////////////////////////////////////////////////////////////////////////////////
///                                 EIP-712                                  ///
////////////////////////////////////////////////////////////////////////////////

/// @notice Signature has expired.
error SignatureExpired();

/// @notice Signature is invalid.
error SignatureInvalid();

////////////////////////////////////////////////////////////////////////////////
///                                 EIP-721                                  ///
////////////////////////////////////////////////////////////////////////////////

/// @notice Originating address does not own the NFT.
error OwnerInvalid();

/// @notice Receiving address cannot be the zero address.
error ReceiverInvalid();

/// @notice Receiving contract does not implement the EIP-721 wallet interface.
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

/// @notice Proposal has failed to or has yet to pass.
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

/// @notice Proposal vote has already been cast.
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

////////////////////////////////////////////////////////////////////////////////
///                           EIP-2981 Royalties                             ///
////////////////////////////////////////////////////////////////////////////////

/// @notice Royalties are set too high.
error RoyaltiesTooHigh();

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.13;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Dopamine ERC-721 honorary membership tab events interface
interface IDopamineHonoraryTabEvents {

    /// @notice Emits when the Dopamine tab base URI is set to `baseUri`.
    /// @param baseURI The base URI of the tab contract, as a string.
    event BaseURISet(string baseURI);

    /// @notice Emits when owner is changed from `oldOwner` to `newOwner`.
    /// @param oldOwner The address of the previous owner.
    /// @param newOwner The address of the new owner.
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emits when the Dopamine tab storage URI is set to `StorageUri`.
    /// @param storageURI The storage URI of the tab contract, as a string.
    event StorageURISet(string storageURI);

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Interface for the ERC-2981 royalties standard.
interface IERC2981 {

/// @notice RoyaltiesInfo stores token royalties information.
struct RoyaltiesInfo {

    /// @notice The address to which royalties will be directed.
    address receiver;

    /// @notice The royalties amount, in bips.
    uint96 royalties;

}

    /// @notice Returns the address to which royalties are received along with
    ///  the royalties amount to be paid to them for a given sale price.
    /// @param id The id of the NFT being queried for royalties information.
    /// @param salePrice The sale price of the NFT, in some unit of exchange.
    /// @return receiver The address of the royalties receiver.
    /// @return royaltyAmount The royalty payment to be made given `salePrice`.
    function royaltyInfo(
        uint256 id,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);

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