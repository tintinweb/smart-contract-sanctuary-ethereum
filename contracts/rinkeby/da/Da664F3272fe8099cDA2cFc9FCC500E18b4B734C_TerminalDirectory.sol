// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ITerminal } from "./interfaces/ITerminal.sol";
import { IProjects } from "./interfaces/IProjects.sol";
import { ITerminalDirectory } from "./interfaces/ITerminalDirectory.sol";

/**
  @notice
  Allows project owners to deploy proxy contracts that can pay them when receiving funds directly.
*/
contract TerminalDirectory is ITerminalDirectory {
    // --- public immutable stored properties --- //

    // The Projects contract which mints ERC-721's that represent project ownership and transfers.
    IProjects public immutable override projects;

    // --- public stored properties --- //

    // The terminal of each project
    mapping(uint256 => ITerminal) public override terminalOf;

    // --- external transactions --- //

    /**
      @param _projects A Projects contract which mints ERC-721's that represent project ownership and transfers.
    */
    constructor(IProjects _projects) {
        projects = _projects;
    }

    /** 
      @notice
      Update the terminal

      @param _projectId The ID of the project to set a new terminal for.
      @param _terminal The new terminal to set.
    */
    function setTerminal(uint256 _projectId, ITerminal _terminal) external override {
        // Get a reference to the current terminal being used.
        ITerminal _currentTerminal = terminalOf[_projectId];

        // Either:
        // - case 1: the current terminal hasn't been set yet and the msg sender is either the projects contract or the terminal being set.
        // - case 2: the current terminal must not yet be set, or the current terminal is setting a new terminal.
        require(
            // case 1.
            (_currentTerminal == ITerminal(address(0)) &&
                (msg.sender == address(projects) || msg.sender == address(_terminal))) ||
                // case 2.
                msg.sender == address(_currentTerminal),
            "TerminalDirectory::setTerminal: UNAUTHORIZED"
        );

        // The project must exist.
        if (!projects.exists(_projectId)) revert UnknowTerminal();

        // Can't set the zero address.
        if (_terminal == ITerminal(address(0))) revert ZeroAddress();

        // If the terminal is already set, nothing to do.
        if (_currentTerminal == _terminal) return;

        // Set the new terminal.
        terminalOf[_projectId] = _terminal;

        emit SetTerminal(_projectId, _terminal, msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IBluechipsBooster {
    event CreateProof(
        address indexed from,
        address indexed bluechip,
        uint256 tokenId,
        bytes32 proof,
        uint256 proofExpiry,
        uint256 weight
    );

    event CreateCustomizedProof(
        uint256 indexed projectId,
        address indexed from,
        address indexed bluechip,
        uint256 tokenId,
        bytes32 proof,
        uint256 proofExpiry,
        uint256 weight
    );

    event ChallengeProof(
        address indexed from,
        address indexed bluechip,
        uint256 tokenId,
        bytes32 proof
    );

    event ChallengeCustomizedProof(
        uint256 indexed projectId,
        address indexed from,
        address indexed bluechip,
        uint256 tokenId,
        bytes32 proof
    );

    event RedeemProof(
        address indexed from,
        address indexed bluechip,
        uint256 tokenId,
        bytes32 proof
    );

    event RedeemCustomizedProof(
        uint256 indexed projectId,
        address indexed from,
        address indexed bluechip,
        uint256 tokenId,
        bytes32 proof
    );

    event RenewProof(
        address indexed from,
        address indexed bluechip,
        uint256 tokenId,
        bytes32 proof,
        uint256 proofExpiry
    );

    event RenewCustomizedProof(
        uint256 indexed projectId,
        address indexed from,
        address indexed bluechip,
        uint256 tokenId,
        bytes32 proof,
        uint256 proofExpiry
    );

    event Remove(
        address indexed from,
        address beneficiary,
        bytes32 proof,
        uint256 weight
    );

    event RemoveCustomize(
        address indexed from,
        address beneficiary,
        uint256 projectId,
        bytes32 proof,
        uint256 weight
    );

    event AddBluechip(address bluechip, uint256 multiper);

    error SizeNotMatch();
    error BadMultiper();
    error ZeroAddress();
    error RenewFirst();
    error NotNFTOwner();
    error InsufficientBalance();
    error BoosterRegisterd();
    error BoosterNotRegisterd();
    error ProofNotRegisterd();
    error ChallengeFailed();
    error RedeemAfterExpired();
    error ForbiddenUpdate();
    error OnlyGovernor();
    error TransferDisabled();

    function count() external view returns (uint256);

    function tokenIdOf(bytes32 _proof) external view returns (uint256);

    function proofBy(bytes32 _proof) external view returns (address);

    function multiplierOf(address _bluechip) external view returns (uint16);

    function boosterWeights(address _bluechip) external view returns (uint256);

    function proofExpiryOf(bytes32 _proof) external view returns (uint256);

    function stakedOf(bytes32 _proof) external view returns (uint256);

    function customBoosterWeights(uint256 _projectId, address _bluechip)
        external
        view
        returns (uint256);

    function customMultiplierOf(uint256 _projectId, address _bluechip)
        external
        view
        returns (uint16);

    function createCustomBooster(
        uint256 _projectId,
        address[] memory _bluechips,
        uint16[] memory _multipers
    ) external;

    function createProof(address _bluechip, uint256 _tokenId) external payable;

    function createProof(
        address _bluechip,
        uint256 _tokenId,
        uint256 _projectId
    ) external payable;

    function challengeProof(address _bluechip, uint256 _tokenId) external;

    function challengeProof(
        address _bluechip,
        uint256 _tokenId,
        uint256 _projectId
    ) external;

    function renewProof(address _bluechip, uint256 _tokenId) external;

    function renewProof(
        address _bluechip,
        uint256 _tokenId,
        uint256 _projectId
    ) external;

    function redeemProof(address _bluechip, uint256 _tokenId) external;

    function redeemProof(
        address _bluechip,
        uint256 _tokenId,
        uint256 _projectId
    ) external;

    function addBlueChip(address _bluechip, uint16 _multiper) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IProjects.sol";
interface IDAOGovernorBooster {
    enum ProposalState {
    Pending,
    Active,
    Queued,
    Failed,
    Expired,
    Executed
}

struct Proposal {
    string uri;
    uint256 id;
    bytes32 hash;
    uint256 start;
    uint256 end;
    uint256 minVoters;
    uint256 minVotes;
    ProposalState state;
}

struct Vote {
    uint256 totalVoters;
    uint256 totalVotes;
}

struct PassStake {
    uint256 tier;
    uint256 amount; // ERC721: 1
    uint8 duration; // duartion in day
}

struct StakeRecord {
    uint256 tier;
    uint256 amount; // ERC721: 1
    uint256 point;
    uint256 stakeAt;
    uint256 expiry;
}


    /************************* EVENTS *************************/
    event CreateGovernor(uint256 indexed projectId, address membershipPass, address admin);

    event ProposalCreated(uint256 indexed projectId, address indexed from, uint256 proposalId);

    event ExecuteProposal(
        uint256 indexed projectId,
        address indexed from,
        uint256 proposalId,
        uint8 proposalResult
    );

    event StakePass(uint256 indexed projectId, address indexed from, uint256 points);

    event UnStakePass(uint256 indexed projectId, address indexed from, uint256 points);

    /************************* ERRORS *************************/
    error InsufficientBalance();
    error UnknowProposal();
    error BadPeriod();
    error InvalidSignature();
    error TransactionNotMatch();
    error TransactionReverted();
    error NotProjectOwner();
    error BadAmount();
    error NotExpired();
    error InvalidRecord();

    function createGovernor(
        uint256 _projectId,
        address _membershipPass,
        address _admin
    ) external;

    function propose(
        uint256 _projectId,
        address _proposer,
        Proposal memory _properties,
        address _target,
        uint256 _value,
        string memory _signature,
        bytes memory _calldata
    ) external payable returns (uint256);

    function execute(
        uint256 _projectId,
        uint256 _proposalId,
        uint8 _proposeResult,
        bytes memory _signatureBySigner,
        address _target,
        uint256 _value,
        string memory _signature,
        bytes memory _data
    ) external returns (bytes memory);

    function stakePass(uint256 _projectId, PassStake[] memory _membershipPass)
        external
        returns (uint256);
    
    function unStakePass(uint256 _projectId, uint256[] memory _recordIds)
        external
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

enum FundingCycleState {
    WarmUp,
    Active,
    Expired
}

struct Metadata {
    // The unique handle name for the DAO
    bytes32 handle;
    // Contract level data, for intergrating the NFT to OpenSea
    string contractURI;
    // Metadata for membershippass nft
    string membershipPassURI;
    // The NFT token address of Customized Boosters
    address[] customBoosters;
    // The multipliers of customized NFT 
    uint16[] boosterMultipliers;
}

struct AuctionedPass {
    // tier id, indexed from 0
    uint256 id;
    uint256 weight;
    uint256 salePrice;
    // the amount of tickets open for sale in this round
    uint256 saleAmount;
    // the amount of tickets airdroped to community
    uint256 communityAmount;
    // who own the community vouchers can free mint the community ticket
    address communityVoucher;
    // the amount of tickets reserved to next round
    uint256 reservedAmount;
}

// 1st funding cycle:
// gold ticket (erc1155) :  11 salePrice 1 reserveampiunt

// silver ticket: 10 salePrice  2 reserveampiunt

struct FundingCycleProperties {
    uint256 id;
    uint256 projectId;
    uint256 previousId;
    uint256 start;
    uint256 target;
    uint256 lockRate;
    uint16 duration;
    bool isPaused;
    uint256 cycleLimit;
}

struct FundingCycleParameter {
    // rate to be locked in treasury 1000 -> 10% 9999 -> 99.99%
    uint16 lockRate;
    uint16 duration;
    uint256 cycleLimit;
    uint256 target;
}

interface IFundingCycles {
    event Configure(
        uint256 indexed fundingCycleId,
        uint256 indexed projectId,
        uint256 reconfigured,
        address caller
    );

    event FundingCycleExist(
        uint256 indexed fundingCycleId,
        uint256 indexed projectId,
        uint256 reconfigured,
        address caller
    );

    event Tap(
        uint256 indexed projectId,
        uint256 indexed fundingCycleId,
        uint256 tapAmount
    );

    event Unlock(
        uint256 indexed projectId,
        uint256 indexed fundingCycleId,
        uint256 unlockAmount,
        uint256 totalUnlockedAmount
    );

    event Init(
        uint256 indexed fundingCycleId,
        uint256 indexed projectId,
        uint256 previous,
        uint256 start,
        uint256 duration,
        uint256 target,
        uint256 lockRate,
        AuctionedPass[] auctionedPass
    );

    error InsufficientBalance();
    error BadCycleLimit();
    error BadDuration();
    error BadLockRate();

    function latestIdFundingProject(uint256 _projectId) external view returns (uint256);

    function fundingCycleIdAuctionedPass(uint256 _projectId, uint256 _tierId)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            address,
            uint256
        );

    function count() external view returns (uint256);

    function MAX_CYCLE_LIMIT() external view returns (uint8);

    function getFundingCycle(uint256 _fundingCycleId)
        external
        view
        returns (FundingCycleProperties memory);

    function configure(
        uint256 _projectId,
        uint16 _duration,
        uint256 _cycleLimit,
        uint256 _target,
        uint256 _lockRate,
        AuctionedPass[] memory _auctionedPass
    ) external returns (FundingCycleProperties memory);

    function currentOf(uint256 _projectId) external view returns (FundingCycleProperties memory);

    function setPauseFundingCycle(uint256 _projectId, bool _paused) external returns (bool);

    function updateLocked(uint256 _projectId, uint256 _fundingCycleId, uint256 _amount) external;

    function tap(uint256 _projectId, uint256 _fundingCycleId, uint256 _amount) external;

    function unlock(uint256 _projectId, uint256 _fundingCycleId, uint256 _amount) external;

    function getTappableAmount(uint256 _fundingCycleId) external view returns (uint256);

    function getFundingCycleState(uint256 _fundingCycleId) external view returns (FundingCycleState);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

interface IMembershipPass is IERC1155, IERC2981 {
    event MintPass(address indexed recepient, uint256 indexed tier, uint256 amount);

    event BatchMintPass(address indexed recepient, uint256[] tiers, uint256[] amounts);

    error TierNotSet();
    error TierUnknow();
    error BadCapacity();
    error BadFee();
    error InsufficientBalance();

    function feeCollector() external view returns (address);

    /**
     * @notice
     * Implement ERC2981, but actually the most marketplaces have their own royalty logic
     */
    function royaltyInfo(uint256 _tier, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount);

    function mintPassForMember(
        address _recepient,
        uint256 _token,
        uint256 _amount
    ) external;

    function batchMintPassForMember(
        address _recepient,
        uint256[] memory _tokens,
        uint256[] memory _amounts
    ) external;

    function updateFeeCollector(address _feeCollector) external;

    function setBaseURI(string memory _uri) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IMembershipPass} from "./IMembershipPass.sol";
import {IRoyaltyDistributor} from "./IRoyaltyDistributor.sol";

struct PayInfoWithWeight {
    uint256 tier;
    uint256 amount;
    uint256 weight;
}
struct WeightInfo {
    uint256 amount;
    uint256 sqrtWeight;
}

interface IMembershipPassBooth {
    /************************* EVENTS *************************/
    event Issue(
        uint256 indexed projectId,
        string uri,
        address membershipPass,
        uint256[] tierFee,
        uint256[] tierCapacity
    );

    event BatchMintTicket(
        address indexed from,
        uint256 indexed projectId,
        uint256[] tiers,
        uint256[] amounts
    );

    event AirdropBatchMintTicket(
        address indexed from,
        uint256 indexed projectId,
        uint256[] tiers,
        uint256[] amounts
    );

    /************************* VIEW FUNCTIONS *************************/
    function tierSizeOf(uint256 _projectId) external view returns (uint256);

    function membershipPassOf(uint256 _projectId) external view returns (IMembershipPass);

    function royaltyDistributorOf(uint256 _projectId) external view returns (IRoyaltyDistributor);

    function totalSqrtWeightBy(uint256 _fundingCycleId, uint256 _tierId) external returns (uint256);

    function depositedWeightBy(
        address _from,
        uint256 _fundingCycleId,
        uint256 _tierId
    ) external view returns (uint256, uint256);

    function claimedOf(address _from, uint256 _fundingCycleId) external returns (bool);

    function airdropClaimedOf(address _from, uint256 _fundingCycleId) external returns (bool);

    function airdropClaimedAmountOf(uint256 _fundingCycleId, uint256 _tierId)
        external
        returns (uint256);

    function issue(
        uint256 _projectId,
        string memory _uri,
        string memory _contractURI,
        uint256[] memory _tierFees,
        uint256[] memory _tierCapacities
    ) external returns (address);

    function stake(
        uint256 _projectId,
        uint256 _fundingCycleId,
        address _from,
        PayInfoWithWeight[] memory _payInfo
    ) external;

    function batchMintTicket(
        uint256 _projectId,
        uint256 _fundingCycleId,
        address _from,
        uint256[] memory _amounts
    ) external;

    function airdropBatchMintTicket(
        uint256 _projectId,
        uint256 _fundingCycleId,
        address _from,
        uint256[] memory _tierIds,
        uint256[] memory _amounts
    ) external;

    function setBaseURI(uint256 _projectId, string memory _uri) external;

    function getUserAllocation(
        address _user,
        uint256 _projectId,
        uint256 _fundingCycleId
    ) external view returns (uint256[] memory);

    function getEstimatingUserAllocation(
        uint256 _projectId,
        uint256 _fundingCycleId,
        uint256[] memory _weights
    ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./ITerminal.sol";

interface IProjects is IERC721 {
    error EmptyHandle();
    error TakenedHandle();
    error UnAuthorized();

    event Create(
        uint256 indexed projectId,
        address indexed owner,
        bytes32 handle,
        address caller
    );

    event SetHandle(uint256 indexed projectId, bytes32 indexed handle, address caller);

    event SetUri(uint256 indexed projectId, string uri, address caller);
    
    event SetBaseURI(string baseURI);

    function count() external view returns (uint256);

    function handleOf(uint256 _projectId) external returns (bytes32 handle);

    function projectFor(bytes32 _handle) external returns (uint256 projectId);

    function exists(uint256 _projectId) external view returns (bool);

    function create(
        address _owner,
        bytes32 _handle,
        ITerminal _terminal
    ) external returns (uint256 id);

    function setHandle(uint256 _projectId, bytes32 _handle) external;
    
    function setBaseURI(string memory _uri) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IRoyaltyDistributor {
	/**
	 * @notice
	 * Claim according to votes share
	 */
	function claimRoyalties() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IProjects.sol";
import "./IFundingCycles.sol";
import "./ITerminalDirectory.sol";
import "./IBluechipsBooster.sol";
import "./IDAOGovernorBooster.sol";
import "./IMembershipPassBooth.sol";

struct ImmutablePassTier {
    uint256 tierFee;
    uint256 multiplier;
    uint256 tierCapacity;
}

interface ITerminal {
    event Pay(
        uint256 indexed projectId,
        uint256 indexed fundingCycleId,
        address indexed beneficiary,
        uint256 amount,
        uint256[] tiers,
        uint256[] amounts,
        string note
    );

    event Airdrop(
        uint256 indexed projectId,
        uint256 indexed fundingCycleId,
        address indexed beneficiary,
        uint256[] tierIds,
        uint256[] amounts,
        string note
    );

    event Claim(
        uint256 indexed projectId,
        uint256 indexed fundingCycleId,
        address indexed beneficiary,
        uint256 refundAmount,
        uint256[] offeringAmounts
    );

    event Tap(
        uint256 indexed projectId,
        uint256 indexed fundingCycleId,
        address indexed beneficiary,
        uint256 govFeeAmount,
        uint256 netTransferAmount
    );

    event AddToBalance(uint256 indexed projectId, uint256 amount, address beneficiary);

    event UnlockTreasury(uint256 indexed projectId, uint256 unlockAmount);

    event SetTapFee(uint256 fee);

    event SetContributeFee(uint256 fee);

    event SetMinLockRate(uint256 minLockRate);

    error MultiplierNotMatch();
    error Voucher721(address _voucher);
    error NoCommunityTicketLeft();
    error AllReservedAmoungZero();
    error FundingCycleNotExist();
    error FundingCyclePaused();
    error FundingCycleActived();
    error InsufficientBalance();
    error AlreadyClaimed();
    error ZeroAddress();
    error BadOperationPeriod();
    error OnlyGovernor();
    error UnAuthorized();
    error LastWeightMustBe1();
    error BadPayment();
    error BadAmount();
    error BadLockRate();
    error BadTapFee();

    function superAdmin() external view returns (address);

    function tapFee() external view returns (uint256);

    function contributeFee() external view returns (uint256);

    function devTreasury() external view returns (address);

    function minLockRate() external view returns (uint256);

    function projects() external view returns (IProjects);

    function fundingCycles() external view returns (IFundingCycles);

    function membershipPassBooth() external view returns (IMembershipPassBooth);

    function daoGovernorBooster() external view returns (IDAOGovernorBooster);

    function bluechipsBooster() external view returns (IBluechipsBooster);

    function terminalDirectory() external view returns (ITerminalDirectory);

    function balanceOf(uint256 _projectId) external view returns (uint256);

    function addToBalance(uint256 _projectId) external payable;

    function setTapFee(uint256 _fee) external;

    function setContributeFee(uint256 _fee) external;

    function setMinLockRate(uint256 _minLockRate) external;

    function createDao(
        address _owner,
        Metadata memory _metadata,
        ImmutablePassTier[] calldata _tiers,
        FundingCycleParameter calldata _params,
        AuctionedPass[] calldata _auctionedPass
    ) external;

    function createNewFundingCycle(
        uint256 projectId,
        FundingCycleParameter calldata _params,
        AuctionedPass[] calldata _auctionedPass
    ) external;

    function contribute(
        uint256 _projectId,
        uint256[] memory _tiers,
        uint256[] memory _amounts,
        string memory _memo
    ) external payable;

    function communityContribute(
        uint256 _projectId,
        uint256 _fundingCycleId,
        string memory _memo
    ) external;

    function claimPassOrRefund(uint256 _projectId, uint256 _fundingCycleId) external;

    function tap(
        uint256 _projectId,
        uint256 _fundingCycleId,
        uint256 _amount
    ) external;

    function unLockTreasury(
        uint256 _projectId,
        uint256 _fundingCycleId,
        uint256 _unlockAmount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ITerminal.sol";
import "./IProjects.sol";

interface ITerminalDirectory {
    event SetTerminal(
        uint256 indexed projectId,
        ITerminal indexed terminal,
        address caller
    );

    error ZeroAddress();
    error UnAuthorized();
    error UnknowTerminal();

    function projects() external view returns (IProjects);

    function terminalOf(uint256 _projectId) external view returns (ITerminal);

    function setTerminal(uint256 _projectId, ITerminal _terminal) external;
}