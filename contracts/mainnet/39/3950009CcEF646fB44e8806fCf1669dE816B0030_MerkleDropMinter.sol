// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
 * @title IMetadataModule
 * @notice The interface for custom metadata modules.
 */
interface IMetadataModule {
    /**
     * @dev When implemented, SoundEdition's `tokenURI` redirects execution to this `tokenURI`.
     * @param tokenId The token ID to retrieve the token URI for.
     * @return The token URI string.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { IERC165 } from "openzeppelin/utils/introspection/IERC165.sol";
import { ISoundFeeRegistry } from "./ISoundFeeRegistry.sol";

/**
 * @title IMinterModule
 * @notice The interface for Sound protocol minter modules.
 */
interface IMinterModule is IERC165 {
    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct BaseData {
        // The start unix timestamp of the mint.
        uint32 startTime;
        // The end unix timestamp of the mint.
        uint32 endTime;
        // The affiliate fee in basis points.
        uint16 affiliateFeeBPS;
        // Whether the mint is paused.
        bool mintPaused;
    }

    // =============================================================
    //                            EVENTS
    // =============================================================

    /**
     * @dev Emitted when the mint instance for an `edition` is created.
     * @param edition The edition address.
     * @param mintId The mint ID, a global incrementing identifier used within the minter
     * @param startTime The start time of the mint.
     * @param endTime The end time of the mint.
     * @param affiliateFeeBPS The affiliate fee in basis points.
     */
    event MintConfigCreated(
        address indexed edition,
        address indexed creator,
        uint128 mintId,
        uint32 startTime,
        uint32 endTime,
        uint16 affiliateFeeBPS
    );

    /**
     * @dev Emitted when the `paused` status of `edition` is updated.
     * @param edition The edition address.
     * @param mintId  The mint ID, to distinguish between multiple mints for the same edition.
     * @param paused  The new paused status.
     */
    event MintPausedSet(address indexed edition, uint128 mintId, bool paused);

    /**
     * @dev Emitted when the `paused` status of `edition` is updated.
     * @param edition   The edition address.
     * @param mintId    The mint ID, to distinguish between multiple mints for the same edition.
     * @param startTime The start time of the mint.
     * @param endTime   The end time of the mint.
     */
    event TimeRangeSet(address indexed edition, uint128 indexed mintId, uint32 startTime, uint32 endTime);

    /**
     * @notice Emitted when the `affiliateFeeBPS` is updated.
     * @param edition The edition address.
     * @param mintId  The mint ID, to distinguish between multiple mints for the same edition.
     * @param bps     The affiliate fee basis points.
     */
    event AffiliateFeeSet(address indexed edition, uint128 indexed mintId, uint16 bps);

    /**
     * @notice Emitted when a mint happens.
     * @param edition            The edition address.
     * @param mintId             The mint ID, to distinguish between multiple mints for
     *                           the same edition.
     * @param buyer              The buyer address.
     * @param fromTokenId        The first token ID of the batch.
     * @param quantity           The size of the batch.
     * @param requiredEtherValue Total amount of Ether required for payment.
     * @param platformFee        The cut paid to the platform.
     * @param affiliateFee       The cut paid to the affiliate.
     * @param affiliate          The affiliate's address.
     * @param affiliated         Whether the affiliate is affiliated.
     */
    event Minted(
        address indexed edition,
        uint128 indexed mintId,
        address indexed buyer,
        uint32 fromTokenId,
        uint32 quantity,
        uint128 requiredEtherValue,
        uint128 platformFee,
        uint128 affiliateFee,
        address affiliate,
        bool affiliated
    );

    // =============================================================
    //                            ERRORS
    // =============================================================

    /**
     * @dev The Ether value paid is below the value required.
     * @param paid The amount sent to the contract.
     * @param required The amount required to mint.
     */
    error Underpaid(uint256 paid, uint256 required);

    /**
     * @dev The number minted has exceeded the max mintable amount.
     * @param available The number of tokens remaining available for mint.
     */
    error ExceedsAvailableSupply(uint32 available);

    /**
     * @dev The mint is not opened.
     * @param blockTimestamp The current block timestamp.
     * @param startTime The start time of the mint.
     * @param endTime The end time of the mint.
     */
    error MintNotOpen(uint256 blockTimestamp, uint32 startTime, uint32 endTime);

    /**
     * @dev The mint is paused.
     */
    error MintPaused();

    /**
     * @dev The `startTime` is not less than the `endTime`.
     */
    error InvalidTimeRange();

    /**
     * @dev Unauthorized caller
     */
    error Unauthorized();

    /**
     * @dev The affiliate fee numerator must not exceed `MAX_BPS`.
     */
    error InvalidAffiliateFeeBPS();

    /**
     * @dev Fee registry cannot be the zero address.
     */
    error FeeRegistryIsZeroAddress();

    // =============================================================
    //               PUBLIC / EXTERNAL WRITE FUNCTIONS
    // =============================================================

    /**
     * @dev Sets the paused status for (`edition`, `mintId`).
     *
     * Calling conditions:
     * - The caller must be the edition's owner or admin.
     */
    function setEditionMintPaused(
        address edition,
        uint128 mintId,
        bool paused
    ) external;

    /**
     * @dev Sets the time range for an edition mint.
     *
     * Calling conditions:
     * - The caller must be the edition's owner or admin.
     *
     * @param edition The edition address.
     * @param mintId The mint ID, a global incrementing identifier used within the minter
     * @param startTime The start time of the mint.
     * @param endTime The end time of the mint.
     */
    function setTimeRange(
        address edition,
        uint128 mintId,
        uint32 startTime,
        uint32 endTime
    ) external;

    /**
     * @dev Sets the affiliate fee for (`edition`, `mintId`).
     *
     * Calling conditions:
     * - The caller must be the edition's owner or admin.
     */
    function setAffiliateFee(
        address edition,
        uint128 mintId,
        uint16 affiliateFeeBPS
    ) external;

    /**
     * @dev Withdraws all the accrued fees for `affiliate`.
     */
    function withdrawForAffiliate(address affiliate) external;

    /**
     * @dev Withdraws all the accrued fees for the platform.
     */
    function withdrawForPlatform() external;

    // =============================================================
    //               PUBLIC / EXTERNAL VIEW FUNCTIONS
    // =============================================================

    /**
     * @dev The total fees accrued for `affiliate`.
     * @param affiliate The affiliate's address.
     * @return The latest value.
     */
    function affiliateFeesAccrued(address affiliate) external view returns (uint128);

    /**
     * @dev The total fees accrued for the platform.
     * @return The latest value.
     */
    function platformFeesAccrued() external view returns (uint128);

    /**
     * @dev Whether `affiliate` is affiliated for (`edition`, `mintId`).
     * @param edition   The edition's address.
     * @param mintId    The mint ID.
     * @param affiliate The affiliate's address.
     * @return The computed value.
     */
    function isAffiliated(
        address edition,
        uint128 mintId,
        address affiliate
    ) external view returns (bool);

    /**
     * @dev The total price for `quantity` tokens for (`edition`, `mintId`).
     * @param edition   The edition's address.
     * @param mintId    The mint ID.
     * @param mintId    The minter's address.
     * @param quantity  The number of tokens to mint.
     * @return The computed value.
     */
    function totalPrice(
        address edition,
        uint128 mintId,
        address minter,
        uint32 quantity
    ) external view returns (uint128);

    /**
     * @dev The next mint ID.
     *      A mint ID is assigned sequentially starting from (0, 1, 2, ...),
     *      and is shared amongst all editions connected to the minter contract.
     * @return The latest value.
     */
    function nextMintId() external view returns (uint128);

    /**
     * @dev The interface ID of the minter.
     * @return The constant value.
     */
    function moduleInterfaceId() external view returns (bytes4);

    /**
     * @dev The fee registry. Used for handling platform fees.
     * @return The immutable value.
     */
    function feeRegistry() external view returns (ISoundFeeRegistry);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { IERC721AUpgradeable } from "chiru-labs/ERC721A-Upgradeable/IERC721AUpgradeable.sol";
import { IERC2981Upgradeable } from "openzeppelin-upgradeable/interfaces/IERC2981Upgradeable.sol";
import { IERC165Upgradeable } from "openzeppelin-upgradeable/utils/introspection/IERC165Upgradeable.sol";

import { IMetadataModule } from "./IMetadataModule.sol";

/**
 * @dev The information pertaining to this edition.
 */
struct EditionInfo {
    // Base URI for the tokenId.
    string baseURI;
    // Contract URI for OpenSea storefront.
    string contractURI;
    // Name of the collection.
    string name;
    // Symbol of the collection.
    string symbol;
    // Address that receives primary and secondary royalties.
    address fundingRecipient;
    // The current max mintable amount;
    uint32 editionMaxMintable;
    // The lower limit of the maximum number of tokens that can be minted.
    uint32 editionMaxMintableUpper;
    // The upper limit of the maximum number of tokens that can be minted.
    uint32 editionMaxMintableLower;
    // The timestamp (in seconds since unix epoch) after which the
    // max amount of tokens mintable will drop from
    // `maxMintableUpper` to `maxMintableLower`.
    uint32 editionCutoffTime;
    // Address of metadata module, address(0x00) if not used.
    address metadataModule;
    // The current mint randomness value.
    uint256 mintRandomness;
    // The royalty BPS (basis points).
    uint16 royaltyBPS;
    // Whether the mint randomness is enabled.
    bool mintRandomnessEnabled;
    // Whether the mint has concluded.
    bool mintConcluded;
    // Whether the metadata has been frozen.
    bool isMetadataFrozen;
    // Next token ID to be minted.
    uint256 nextTokenId;
    // Total number of tokens burned.
    uint256 totalBurned;
    // Total number of tokens minted.
    uint256 totalMinted;
    // Total number of tokens currently in existence.
    uint256 totalSupply;
}

/**
 * @title ISoundEditionV1
 * @notice The interface for Sound edition contracts.
 */
interface ISoundEditionV1 is IERC721AUpgradeable, IERC2981Upgradeable {
    // =============================================================
    //                            EVENTS
    // =============================================================

    /**
     * @dev Emitted when the metadata module is set.
     * @param metadataModule the address of the metadata module.
     */
    event MetadataModuleSet(address metadataModule);

    /**
     * @dev Emitted when the `baseURI` is set.
     * @param baseURI the base URI of the edition.
     */
    event BaseURISet(string baseURI);

    /**
     * @dev Emitted when the `contractURI` is set.
     * @param contractURI The contract URI of the edition.
     */
    event ContractURISet(string contractURI);

    /**
     * @dev Emitted when the metadata is frozen (e.g.: `baseURI` can no longer be changed).
     * @param metadataModule The address of the metadata module.
     * @param baseURI        The base URI of the edition.
     * @param contractURI    The contract URI of the edition.
     */
    event MetadataFrozen(address metadataModule, string baseURI, string contractURI);

    /**
     * @dev Emitted when the `fundingRecipient` is set.
     * @param fundingRecipient The address of the funding recipient.
     */
    event FundingRecipientSet(address fundingRecipient);

    /**
     * @dev Emitted when the `royaltyBPS` is set.
     * @param bps The new royalty, measured in basis points.
     */
    event RoyaltySet(uint16 bps);

    /**
     * @dev Emitted when the edition's maximum mintable token quantity range is set.
     * @param editionMaxMintableLower_ The lower limit of the maximum number of tokens that can be minted.
     * @param editionMaxMintableUpper_ The upper limit of the maximum number of tokens that can be minted.
     */
    event EditionMaxMintableRangeSet(uint32 editionMaxMintableLower_, uint32 editionMaxMintableUpper_);

    /**
     * @dev Emitted when the edition's cutoff time set.
     * @param editionCutoffTime_ The timestamp.
     */
    event EditionCutoffTimeSet(uint32 editionCutoffTime_);

    /**
     * @dev Emitted when the `mintRandomnessEnabled` is set.
     * @param mintRandomnessEnabled_ The boolean value.
     */
    event MintRandomnessEnabledSet(bool mintRandomnessEnabled_);

    /**
     * @dev Emitted upon initialization.
     * @param edition_                 The address of the edition.
     * @param name_                    Name of the collection.
     * @param symbol_                  Symbol of the collection.
     * @param metadataModule_          Address of metadata module, address(0x00) if not used.
     * @param baseURI_                 Base URI.
     * @param contractURI_             Contract URI for OpenSea storefront.
     * @param fundingRecipient_        Address that receives primary and secondary royalties.
     * @param royaltyBPS_              Royalty amount in bps (basis points).
     * @param editionMaxMintableLower_ The lower bound of the max mintable quantity for the edition.
     * @param editionMaxMintableUpper_ The upper bound of the max mintable quantity for the edition.
     * @param editionCutoffTime_       The timestamp after which `editionMaxMintable` drops from
     *                                 `editionMaxMintableUpper` to
     *                                 `max(_totalMinted(), editionMaxMintableLower)`.
     * @param flags_                   The bitwise OR result of the initialization flags.
     *                                 See: {METADATA_IS_FROZEN_FLAG}
     *                                 See: {MINT_RANDOMNESS_ENABLED_FLAG}
     */
    event SoundEditionInitialized(
        address indexed edition_,
        string name_,
        string symbol_,
        address metadataModule_,
        string baseURI_,
        string contractURI_,
        address fundingRecipient_,
        uint16 royaltyBPS_,
        uint32 editionMaxMintableLower_,
        uint32 editionMaxMintableUpper_,
        uint32 editionCutoffTime_,
        uint8 flags_
    );

    /**
     * @dev Emitted upon ETH withdrawal.
     * @param recipient The recipient of the withdrawal.
     * @param amount    The amount withdrawn.
     * @param caller    The account that initiated the withdrawal.
     */
    event ETHWithdrawn(address recipient, uint256 amount, address caller);

    /**
     * @dev Emitted upon ERC20 withdrawal.
     * @param recipient The recipient of the withdrawal.
     * @param tokens    The addresses of the ERC20 tokens.
     * @param amounts   The amount of each token withdrawn.
     * @param caller    The account that initiated the withdrawal.
     */
    event ERC20Withdrawn(address recipient, address[] tokens, uint256[] amounts, address caller);

    /**
     * @dev Emitted upon a mint.
     * @param to          The address to mint to.
     * @param quantity    The number of minted.
     * @param fromTokenId The first token ID minted.
     */
    event Minted(address to, uint256 quantity, uint256 fromTokenId);

    /**
     * @dev Emitted upon an airdrop.
     * @param to          The recipients of the airdrop.
     * @param quantity    The number of tokens airdropped to each address in `to`.
     * @param fromTokenId The first token ID minted to the first address in `to`.
     */
    event Airdropped(address[] to, uint256 quantity, uint256 fromTokenId);

    // =============================================================
    //                            ERRORS
    // =============================================================

    /**
     * @dev The edition's metadata is frozen (e.g.: `baseURI` can no longer be changed).
     */
    error MetadataIsFrozen();

    /**
     * @dev The given `royaltyBPS` is invalid.
     */
    error InvalidRoyaltyBPS();

    /**
     * @dev The given `randomnessLockedAfterMinted` value is invalid.
     */
    error InvalidRandomnessLock();

    /**
     * @dev The requested quantity exceeds the edition's remaining mintable token quantity.
     * @param available The number of tokens remaining available for mint.
     */
    error ExceedsEditionAvailableSupply(uint32 available);

    /**
     * @dev The given amount is invalid.
     */
    error InvalidAmount();

    /**
     * @dev The given `fundingRecipient` address is invalid.
     */
    error InvalidFundingRecipient();

    /**
     * @dev The `editionMaxMintableLower` must not be greater than `editionMaxMintableUpper`.
     */
    error InvalidEditionMaxMintableRange();

    /**
     * @dev The `editionMaxMintable` has already been reached.
     */
    error MaximumHasAlreadyBeenReached();

    /**
     * @dev The mint `quantity` cannot exceed `ADDRESS_BATCH_MINT_LIMIT` tokens.
     */
    error ExceedsAddressBatchMintLimit();

    /**
     * @dev The mint randomness has already been revealed.
     */
    error MintRandomnessAlreadyRevealed();

    /**
     * @dev No addresses to airdrop.
     */
    error NoAddressesToAirdrop();

    /**
     * @dev The mint has already concluded.
     */
    error MintHasConcluded();

    /**
     * @dev Cannot perform the operation after a token has been minted.
     */
    error MintsAlreadyExist();

    // =============================================================
    //               PUBLIC / EXTERNAL WRITE FUNCTIONS
    // =============================================================

    /**
     * @dev Initializes the contract.
     * @param name_                    Name of the collection.
     * @param symbol_                  Symbol of the collection.
     * @param metadataModule_          Address of metadata module, address(0x00) if not used.
     * @param baseURI_                 Base URI.
     * @param contractURI_             Contract URI for OpenSea storefront.
     * @param fundingRecipient_        Address that receives primary and secondary royalties.
     * @param royaltyBPS_              Royalty amount in bps (basis points).
     * @param editionMaxMintableLower_ The lower bound of the max mintable quantity for the edition.
     * @param editionMaxMintableUpper_ The upper bound of the max mintable quantity for the edition.
     * @param editionCutoffTime_       The timestamp after which `editionMaxMintable` drops from
     *                                 `editionMaxMintableUpper` to
     *                                 `max(_totalMinted(), editionMaxMintableLower)`.
     * @param flags_                   The bitwise OR result of the initialization flags.
     *                                 See: {METADATA_IS_FROZEN_FLAG}
     *                                 See: {MINT_RANDOMNESS_ENABLED_FLAG}
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        address metadataModule_,
        string memory baseURI_,
        string memory contractURI_,
        address fundingRecipient_,
        uint16 royaltyBPS_,
        uint32 editionMaxMintableLower_,
        uint32 editionMaxMintableUpper_,
        uint32 editionCutoffTime_,
        uint8 flags_
    ) external;

    /**
     * @dev Mints `quantity` tokens to addrress `to`
     *      Each token will be assigned a token ID that is consecutively increasing.
     *
     * Calling conditions:
     * - The caller must be the owner of the contract, or have either the
     *   `ADMIN_ROLE`, `MINTER_ROLE`, which can be granted via {grantRole}.
     *   Multiple minters, such as different minter contracts,
     *   can be authorized simultaneously.
     *
     * @param to       Address to mint to.
     * @param quantity Number of tokens to mint.
     * @return fromTokenId The first token ID minted.
     */
    function mint(address to, uint256 quantity) external payable returns (uint256 fromTokenId);

    /**
     * @dev Mints `quantity` tokens to each of the addresses in `to`.
     *
     * Calling conditions:
     * - The caller must be the owner of the contract, or have the
     *   `ADMIN_ROLE`, which can be granted via {grantRole}.
     *
     * @param to           Address to mint to.
     * @param quantity     Number of tokens to mint.
     * @return fromTokenId The first token ID minted.
     */
    function airdrop(address[] calldata to, uint256 quantity) external returns (uint256 fromTokenId);

    /**
     * @dev Withdraws collected ETH royalties to the fundingRecipient.
     */
    function withdrawETH() external;

    /**
     * @dev Withdraws collected ERC20 royalties to the fundingRecipient.
     * @param tokens array of ERC20 tokens to withdraw
     */
    function withdrawERC20(address[] calldata tokens) external;

    /**
     * @dev Sets metadata module.
     *
     * Calling conditions:
     * - The caller must be the owner of the contract, or have the `ADMIN_ROLE`.
     *
     * @param metadataModule Address of metadata module.
     */
    function setMetadataModule(address metadataModule) external;

    /**
     * @dev Sets global base URI.
     *
     * Calling conditions:
     * - The caller must be the owner of the contract, or have the `ADMIN_ROLE`.
     *
     * @param baseURI The base URI to be set.
     */
    function setBaseURI(string memory baseURI) external;

    /**
     * @dev Sets contract URI.
     *
     * Calling conditions:
     * - The caller must be the owner of the contract, or have the `ADMIN_ROLE`.
     *
     * @param contractURI The contract URI to be set.
     */
    function setContractURI(string memory contractURI) external;

    /**
     * @dev Freezes metadata by preventing any more changes to base URI.
     *
     * Calling conditions:
     * - The caller must be the owner of the contract, or have the `ADMIN_ROLE`.
     */
    function freezeMetadata() external;

    /**
     * @dev Sets funding recipient address.
     *
     * Calling conditions:
     * - The caller must be the owner of the contract, or have the `ADMIN_ROLE`.
     *
     * @param fundingRecipient Address to be set as the new funding recipient.
     */
    function setFundingRecipient(address fundingRecipient) external;

    /**
     * @dev Sets royalty amount in bps (basis points).
     *
     * Calling conditions:
     * - The caller must be the owner of the contract, or have the `ADMIN_ROLE`.
     *
     * @param bps The new royalty basis points to be set.
     */
    function setRoyalty(uint16 bps) external;

    /**
     * @dev Sets the edition max mintable range.
     *
     * Calling conditions:
     * - The caller must be the owner of the contract, or have the `ADMIN_ROLE`.
     *
     * @param editionMaxMintableLower_ The lower limit of the maximum number of tokens that can be minted.
     * @param editionMaxMintableUpper_ The upper limit of the maximum number of tokens that can be minted.
     */
    function setEditionMaxMintableRange(uint32 editionMaxMintableLower_, uint32 editionMaxMintableUpper_) external;

    /**
     * @dev Sets the timestamp after which, the `editionMaxMintable` drops
     *      from `editionMaxMintableUpper` to `editionMaxMintableLower.
     *
     * Calling conditions:
     * - The caller must be the owner of the contract, or have the `ADMIN_ROLE`.
     *
     * @param editionCutoffTime_ The timestamp.
     */
    function setEditionCutoffTime(uint32 editionCutoffTime_) external;

    /**
     * @dev Sets whether the `mintRandomness` is enabled.
     *
     * Calling conditions:
     * - The caller must be the owner of the contract, or have the `ADMIN_ROLE`.
     *
     * @param mintRandomnessEnabled_ The boolean value.
     */
    function setMintRandomnessEnabled(bool mintRandomnessEnabled_) external;

    // =============================================================
    //               PUBLIC / EXTERNAL VIEW FUNCTIONS
    // =============================================================

    /**
     * @dev Returns the edition info.
     * @return editionInfo The latest value.
     */
    function editionInfo() external view returns (EditionInfo memory editionInfo);

    /**
     * @dev Returns the minter role flag.
     * @return The constant value.
     */
    function MINTER_ROLE() external view returns (uint256);

    /**
     * @dev Returns the admin role flag.
     * @return The constant value.
     */
    function ADMIN_ROLE() external view returns (uint256);

    /**
     * @dev Returns the maximum limit for the mint or airdrop `quantity`.
     *      Prevents the first-time transfer costs for tokens near the end of large mint batches
     *      via ERC721A from becoming too expensive due to the need to scan many storage slots.
     *      See: https://chiru-labs.github.io/ERC721A/#/tips?id=batch-size
     * @return The constant value.
     */
    function ADDRESS_BATCH_MINT_LIMIT() external pure returns (uint256);

    /**
     * @dev Returns the bit flag to freeze the metadata on initialization.
     * @return The constant value.
     */
    function METADATA_IS_FROZEN_FLAG() external pure returns (uint8);

    /**
     * @dev Returns the bit flag to enable the mint randomness feature on initialization.
     * @return The constant value.
     */
    function MINT_RANDOMNESS_ENABLED_FLAG() external pure returns (uint8);

    /**
     * @dev Returns the base token URI for the collection.
     * @return The configured value.
     */
    function baseURI() external view returns (string memory);

    /**
     * @dev Returns the contract URI to be used by Opensea.
     *      See: https://docs.opensea.io/docs/contract-level-metadata
     * @return The configured value.
     */
    function contractURI() external view returns (string memory);

    /**
     * @dev Returns the address of the funding recipient.
     * @return The configured value.
     */
    function fundingRecipient() external view returns (address);

    /**
     * @dev Returns the maximum amount of tokens mintable for this edition.
     * @return The configured value.
     */
    function editionMaxMintable() external view returns (uint32);

    /**
     * @dev Returns the upper bound for the maximum tokens that can be minted for this edition.
     * @return The configured value.
     */
    function editionMaxMintableUpper() external view returns (uint32);

    /**
     * @dev Returns the lower bound for the maximum tokens that can be minted for this edition.
     * @return The configured value.
     */
    function editionMaxMintableLower() external view returns (uint32);

    /**
     * @dev Returns the timestamp after which `editionMaxMintable` drops from
     *      `editionMaxMintableUpper` to `editionMaxMintableLower`.
     * @return The configured value.
     */
    function editionCutoffTime() external view returns (uint32);

    /**
     * @dev Returns the address of the metadata module.
     * @return The configured value.
     */
    function metadataModule() external view returns (address);

    /**
     * @dev Returns the randomness based on latest block hash, which is stored upon each mint.
     *      unless {mintConcluded} is true.
     *      Used for game mechanics like the Sound Golden Egg.
     *      Returns 0 before revealed.
     *      WARNING: This value should NOT be used for any reward of significant monetary
     *      value, due to it being computed via a purely on-chain psuedorandom mechanism.
     * @return The latest value.
     */
    function mintRandomness() external view returns (uint256);

    /**
     * @dev Returns whether the `mintRandomness` has been enabled.
     * @return The configured value.
     */
    function mintRandomnessEnabled() external view returns (bool);

    /**
     * @dev Returns whether the mint has been concluded.
     * @return The latest value.
     */
    function mintConcluded() external view returns (bool);

    /**
     * @dev Returns the royalty basis points.
     * @return The configured value.
     */
    function royaltyBPS() external view returns (uint16);

    /**
     * @dev Returns whether the metadata module is frozen.
     * @return The configured value.
     */
    function isMetadataFrozen() external view returns (bool);

    /**
     * @dev Returns the next token ID to be minted.
     * @return The latest value.
     */
    function nextTokenId() external view returns (uint256);

    /**
     * @dev Returns the number of tokens minted by `owner`.
     * @param owner Address to query for number minted.
     * @return The latest value.
     */
    function numberMinted(address owner) external view returns (uint256);

    /**
     * @dev Returns the number of tokens burned by `owner`.
     * @param owner Address to query for number burned.
     * @return The latest value.
     */
    function numberBurned(address owner) external view returns (uint256);

    /**
     * @dev Returns the total amount of tokens minted.
     * @return The latest value.
     */
    function totalMinted() external view returns (uint256);

    /**
     * @dev Returns the total amount of tokens burned.
     * @return The latest value.
     */
    function totalBurned() external view returns (uint256);

    /**
     * @dev Informs other contracts which interfaces this contract supports.
     *      Required by https://eips.ethereum.org/EIPS/eip-165
     * @param interfaceId The interface id to check.
     * @return Whether the `interfaceId` is supported.
     */
    function supportsInterface(bytes4 interfaceId)
        external
        view
        override(IERC721AUpgradeable, IERC165Upgradeable)
        returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

/**
 * @title ISoundFeeRegistry
 * @author Sound.xyz
 */
interface ISoundFeeRegistry {
    // =============================================================
    //                            EVENTS
    // =============================================================

    /**
     * @dev Emitted when the `soundFeeAddress` is changed.
     */
    event SoundFeeAddressSet(address soundFeeAddress);

    /**
     * @dev Emitted when the `platformFeeBPS` is changed.
     */
    event PlatformFeeSet(uint16 platformFeeBPS);

    // =============================================================
    //                             ERRORS
    // =============================================================

    /**
     * @dev The new `soundFeeAddress` must not be address(0).
     */
    error InvalidSoundFeeAddress();

    /**
     * @dev The platform fee numerator must not exceed `_MAX_BPS`.
     */
    error InvalidPlatformFeeBPS();

    // =============================================================
    //               PUBLIC / EXTERNAL WRITE FUNCTIONS
    // =============================================================

    /**
     * @dev Sets the `soundFeeAddress`.
     *
     * Calling conditions:
     * - The caller must be the owner of the contract.
     *
     * @param soundFeeAddress_ The sound fee address.
     */
    function setSoundFeeAddress(address soundFeeAddress_) external;

    /**
     * @dev Sets the `platformFeePBS`.
     *
     * Calling conditions:
     * - The caller must be the owner of the contract.
     *
     * @param platformFeeBPS_ Platform fee amount in bps (basis points).
     */
    function setPlatformFeeBPS(uint16 platformFeeBPS_) external;

    // =============================================================
    //               PUBLIC / EXTERNAL VIEW FUNCTIONS
    // =============================================================

    /**
     * @dev The sound protocol's address that receives platform fees.
     * @return The configured value.
     */
    function soundFeeAddress() external view returns (address);

    /**
     * @dev The numerator of the platform fee.
     * @return The configured value.
     */
    function platformFeeBPS() external view returns (uint16);

    /**
     * @dev The platform fee for `requiredEtherValue`.
     * @param requiredEtherValue The required Ether value for payment.
     * @return fee The computed value.
     */
    function platformFee(uint128 requiredEtherValue) external view returns (uint128 fee);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { OwnableRoles } from "solady/auth/OwnableRoles.sol";
import { ISoundEditionV1 } from "@core/interfaces/ISoundEditionV1.sol";
import { IMinterModule } from "@core/interfaces/IMinterModule.sol";
import { ISoundFeeRegistry } from "@core/interfaces/ISoundFeeRegistry.sol";
import { IERC165 } from "openzeppelin/utils/introspection/IERC165.sol";
import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";
import { FixedPointMathLib } from "solady/utils/FixedPointMathLib.sol";

/**
 * @title Minter Base
 * @dev The `BaseMinter` class maintains a central storage record of edition mint instances.
 */
abstract contract BaseMinter is IMinterModule {
    // =============================================================
    //                           CONSTANTS
    // =============================================================

    /**
     * @dev This is the denominator, in basis points (BPS), for:
     * - platform fees
     * - affiliate fees
     */
    uint16 private constant _MAX_BPS = 10_000;

    // =============================================================
    //                            STORAGE
    // =============================================================

    /**
     * @dev The next mint ID. Shared amongst all editions connected.
     */
    uint128 private _nextMintId;

    /**
     * @dev How much platform fees have been accrued.
     */
    uint128 private _platformFeesAccrued;

    /**
     * @dev Maps an edition and the mint ID to a mint instance.
     */
    mapping(address => mapping(uint256 => BaseData)) internal _baseData;

    /**
     * @dev Maps an address to how much affiliate fees have they accrued.
     */
    mapping(address => uint128) private _affiliateFeesAccrued;

    /**
     * @dev The fee registry. Used for handling platform fees.
     */
    ISoundFeeRegistry public immutable feeRegistry;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor(ISoundFeeRegistry feeRegistry_) {
        if (address(feeRegistry_) == address(0)) revert FeeRegistryIsZeroAddress();
        feeRegistry = feeRegistry_;
    }

    // =============================================================
    //               PUBLIC / EXTERNAL WRITE FUNCTIONS
    // =============================================================

    /**
     * @inheritdoc IMinterModule
     */
    function setEditionMintPaused(
        address edition,
        uint128 mintId,
        bool paused
    ) public virtual onlyEditionOwnerOrAdmin(edition) {
        _baseData[edition][mintId].mintPaused = paused;
        emit MintPausedSet(edition, mintId, paused);
    }

    /**
     * @inheritdoc IMinterModule
     */
    function setTimeRange(
        address edition,
        uint128 mintId,
        uint32 startTime,
        uint32 endTime
    ) public virtual onlyEditionOwnerOrAdmin(edition) onlyValidTimeRange(startTime, endTime) {
        _baseData[edition][mintId].startTime = startTime;
        _baseData[edition][mintId].endTime = endTime;

        emit TimeRangeSet(edition, mintId, startTime, endTime);
    }

    /**
     * @inheritdoc IMinterModule
     */
    function setAffiliateFee(
        address edition,
        uint128 mintId,
        uint16 feeBPS
    ) public virtual override onlyEditionOwnerOrAdmin(edition) onlyValidAffiliateFeeBPS(feeBPS) {
        _baseData[edition][mintId].affiliateFeeBPS = feeBPS;
        emit AffiliateFeeSet(edition, mintId, feeBPS);
    }

    /**
     * @inheritdoc IMinterModule
     */
    function withdrawForAffiliate(address affiliate) public override {
        uint256 accrued = _affiliateFeesAccrued[affiliate];
        if (accrued != 0) {
            _affiliateFeesAccrued[affiliate] = 0;
            SafeTransferLib.safeTransferETH(affiliate, accrued);
        }
    }

    /**
     * @inheritdoc IMinterModule
     */
    function withdrawForPlatform() public override {
        uint256 accrued = _platformFeesAccrued;
        if (accrued != 0) {
            _platformFeesAccrued = 0;
            SafeTransferLib.safeTransferETH(feeRegistry.soundFeeAddress(), accrued);
        }
    }

    // =============================================================
    //               PUBLIC / EXTERNAL VIEW FUNCTIONS
    // =============================================================

    /**
     * @dev Getter for the max basis points.
     */
    function MAX_BPS() external pure returns (uint16) {
        return _MAX_BPS;
    }

    /**
     * @inheritdoc IMinterModule
     */
    function affiliateFeesAccrued(address affiliate) external view returns (uint128) {
        return _affiliateFeesAccrued[affiliate];
    }

    /**
     * @inheritdoc IMinterModule
     */
    function platformFeesAccrued() external view returns (uint128) {
        return _platformFeesAccrued;
    }

    /**
     * @inheritdoc IMinterModule
     */
    function isAffiliated(
        address, /* edition */
        uint128, /* mintId */
        address affiliate
    ) public view virtual override returns (bool) {
        return affiliate != address(0);
    }

    /**
     * @inheritdoc IMinterModule
     */
    function nextMintId() public view returns (uint128) {
        return _nextMintId;
    }

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IMinterModule).interfaceId || interfaceId == this.supportsInterface.selector;
    }

    /**
     * @inheritdoc IMinterModule
     */
    function totalPrice(
        address edition,
        uint128 mintId,
        address minter,
        uint32 quantity
    ) public view virtual override returns (uint128);

    // =============================================================
    //                  INTERNAL / PRIVATE HELPERS
    // =============================================================

    /**
     * @dev Restricts the function to be only callable by the owner or admin of `edition`.
     * @param edition The edition address.
     */
    modifier onlyEditionOwnerOrAdmin(address edition) virtual {
        if (
            msg.sender != OwnableRoles(edition).owner() &&
            !OwnableRoles(edition).hasAnyRole(msg.sender, ISoundEditionV1(edition).ADMIN_ROLE())
        ) revert Unauthorized();

        _;
    }

    /**
     * @dev Restricts the start time to be less than the end time.
     * @param startTime The start time of the mint.
     * @param endTime The end time of the mint.
     */
    modifier onlyValidTimeRange(uint32 startTime, uint32 endTime) virtual {
        if (startTime >= endTime) revert InvalidTimeRange();
        _;
    }

    /**
     * @dev Restricts the affiliate fee numerator to not exceed the `MAX_BPS`.
     */
    modifier onlyValidAffiliateFeeBPS(uint16 affiliateFeeBPS) virtual {
        if (affiliateFeeBPS > _MAX_BPS) revert InvalidAffiliateFeeBPS();
        _;
    }

    /**
     * @dev Creates an edition mint instance.
     * @param edition The edition address.
     * @param startTime The start time of the mint.
     * @param endTime The end time of the mint.
     * @param affiliateFeeBPS The affiliate fee in basis points.
     * @return mintId The ID for the mint instance.
     * Calling conditions:
     * - Must be owner or admin of the edition.
     */
    function _createEditionMint(
        address edition,
        uint32 startTime,
        uint32 endTime,
        uint16 affiliateFeeBPS
    )
        internal
        onlyEditionOwnerOrAdmin(edition)
        onlyValidTimeRange(startTime, endTime)
        onlyValidAffiliateFeeBPS(affiliateFeeBPS)
        returns (uint128 mintId)
    {
        mintId = _nextMintId;

        BaseData storage data = _baseData[edition][mintId];
        data.startTime = startTime;
        data.endTime = endTime;
        data.affiliateFeeBPS = affiliateFeeBPS;

        _nextMintId = mintId + 1;

        emit MintConfigCreated(edition, msg.sender, mintId, startTime, endTime, affiliateFeeBPS);
    }

    /**
     * @dev Mints `quantity` of `edition` to `to` with a required payment of `requiredEtherValue`.
     * Note: this function should be called at the end of a function due to it refunding any
     * excess ether paid, to adhere to the checks-effects-interactions pattern.
     * Otherwise, a reentrancy guard must be used.
     * @param edition The edition address.
     * @param mintId The ID for the mint instance.
     * @param quantity The quantity of tokens to mint.
     * @param affiliate The affiliate (referral) address.
     */
    function _mint(
        address edition,
        uint128 mintId,
        uint32 quantity,
        address affiliate
    ) internal {
        BaseData storage baseData = _baseData[edition][mintId];

        /* --------------------- GENERAL CHECKS --------------------- */
        {
            uint32 startTime = baseData.startTime;
            uint32 endTime = baseData.endTime;
            if (block.timestamp < startTime) revert MintNotOpen(block.timestamp, startTime, endTime);
            if (block.timestamp > endTime) revert MintNotOpen(block.timestamp, startTime, endTime);
            if (baseData.mintPaused) revert MintPaused();
        }

        /* ----------- AFFILIATE AND PLATFORM FEES LOGIC ------------ */

        uint128 requiredEtherValue = totalPrice(edition, mintId, msg.sender, quantity);

        // Reverts if the payment is not exact.
        if (msg.value < requiredEtherValue) revert Underpaid(msg.value, requiredEtherValue);

        (uint128 remainingPayment, uint128 platformFee) = _deductPlatformFee(requiredEtherValue);

        // Check if the mint is an affiliated mint.
        bool affiliated = isAffiliated(edition, mintId, affiliate);
        uint128 affiliateFee;
        unchecked {
            if (affiliated) {
                // Compute the affiliate fee.
                // Won't overflow, as `remainingPayment` is 128 bits, and `affiliateFeeBPS` is 16 bits.
                affiliateFee = uint128(
                    (uint256(remainingPayment) * uint256(baseData.affiliateFeeBPS)) / uint256(_MAX_BPS)
                );
                // Deduct the affiliate fee from the remaining payment.
                // Won't underflow as `affiliateFee <= remainingPayment`.
                remainingPayment -= affiliateFee;
                // Increment the affiliate fees accrued.
                // Overflow is incredibly unrealistic.
                _affiliateFeesAccrued[affiliate] += affiliateFee;
            }
        }

        /* ------------------------- MINT --------------------------- */

        // Emit the event.
        emit Minted(
            edition,
            mintId,
            msg.sender,
            // Need to put this call here to avoid stack-too-deep error (it returns fromTokenId)
            uint32(ISoundEditionV1(edition).mint{ value: remainingPayment }(msg.sender, quantity)),
            quantity,
            requiredEtherValue,
            platformFee,
            affiliateFee,
            affiliate,
            affiliated
        );

        /* ------------------------- REFUND ------------------------- */

        unchecked {
            // Note: We do this at the end to avoid creating a reentrancy vector.
            // Refund the user any ETH they spent over the current total price of the NFTs.
            if (msg.value > requiredEtherValue) {
                SafeTransferLib.safeTransferETH(msg.sender, msg.value - requiredEtherValue);
            }
        }
    }

    /**
     * @dev Deducts the platform fee from `requiredEtherValue`.
     * @param requiredEtherValue The amount of Ether required.
     * @return remainingPayment  The remaining payment Ether amount.
     * @return platformFee       The platform fee.
     */
    function _deductPlatformFee(uint128 requiredEtherValue)
        internal
        returns (uint128 remainingPayment, uint128 platformFee)
    {
        unchecked {
            // Compute the platform fee.
            platformFee = feeRegistry.platformFee(requiredEtherValue);
            // Increment the platform fees accrued.
            // Overflow is incredibly unrealistic.
            _platformFeesAccrued += platformFee;
            // Deduct the platform fee.
            // Won't underflow as `platformFee <= requiredEtherValue`;
            remainingPayment = requiredEtherValue - platformFee;
        }
    }

    /**
     * @dev Increments `totalMinted` with `quantity`, reverting if `totalMinted + quantity > maxMintable`.
     * @param totalMinted The current total number of minted tokens.
     * @param maxMintable The maximum number of mintable tokens.
     * @return `totalMinted` + `quantity`.
     */
    function _incrementTotalMinted(
        uint32 totalMinted,
        uint32 quantity,
        uint32 maxMintable
    ) internal pure returns (uint32) {
        unchecked {
            // Won't overflow as both are 32 bits.
            uint256 sum = uint256(totalMinted) + uint256(quantity);
            if (sum > maxMintable) {
                // Note that the `maxMintable` may vary and drop over time
                // and cause `totalMinted` to be greater than `maxMintable`.
                // The `zeroFloorSub` is equivalent to `max(0, x - y)`.
                uint32 available = uint32(FixedPointMathLib.zeroFloorSub(maxMintable, totalMinted));
                revert ExceedsAvailableSupply(available);
            }
            return uint32(sum);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import { MerkleProofLib } from "solady/utils/MerkleProofLib.sol";
import { IERC165 } from "openzeppelin/utils/introspection/IERC165.sol";
import { ISoundFeeRegistry } from "@core/interfaces/ISoundFeeRegistry.sol";
import { BaseMinter } from "@modules/BaseMinter.sol";
import { IMerkleDropMinter, EditionMintData, MintInfo } from "./interfaces/IMerkleDropMinter.sol";
import { IMinterModule } from "@core/interfaces/IMinterModule.sol";
import { ISoundEditionV1 } from "@core/interfaces/ISoundEditionV1.sol";

/**
 * @title MerkleDropMinter
 * @dev Module for minting Sound editions using a merkle tree of approved accounts.
 * @author Sound.xyz
 */
contract MerkleDropMinter is IMerkleDropMinter, BaseMinter {
    // =============================================================
    //                            STORAGE
    // =============================================================

    /**
     * @dev Edition mint data.
     *      Maps `edition` => `mintId` => value.
     */
    mapping(address => mapping(uint128 => EditionMintData)) internal _editionMintData;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor(ISoundFeeRegistry feeRegistry_) BaseMinter(feeRegistry_) {}

    // =============================================================
    //               PUBLIC / EXTERNAL WRITE FUNCTIONS
    // =============================================================

    /**
     * @inheritdoc IMerkleDropMinter
     */
    function createEditionMint(
        address edition,
        bytes32 merkleRootHash,
        uint96 price,
        uint32 startTime,
        uint32 endTime,
        uint16 affiliateFeeBPS,
        uint32 maxMintable,
        uint32 maxMintablePerAccount
    ) public returns (uint128 mintId) {
        if (merkleRootHash == bytes32(0)) revert MerkleRootHashIsEmpty();
        if (maxMintablePerAccount == 0) revert MaxMintablePerAccountIsZero();

        mintId = _createEditionMint(edition, startTime, endTime, affiliateFeeBPS);

        EditionMintData storage data = _editionMintData[edition][mintId];
        data.merkleRootHash = merkleRootHash;
        data.price = price;
        data.maxMintable = maxMintable;
        data.maxMintablePerAccount = maxMintablePerAccount;
        // prettier-ignore
        emit MerkleDropMintCreated(
            edition,
            mintId,
            merkleRootHash,
            price,
            startTime,
            endTime,
            affiliateFeeBPS,
            maxMintable,
            maxMintablePerAccount
        );
    }

    /**
     * @inheritdoc IMerkleDropMinter
     */
    function mint(
        address edition,
        uint128 mintId,
        uint32 requestedQuantity,
        bytes32[] calldata merkleProof,
        address affiliate
    ) public payable {
        EditionMintData storage data = _editionMintData[edition][mintId];

        // Increase `totalMinted` by `requestedQuantity`.
        // Require that the increased value does not exceed `maxMintable`.
        data.totalMinted = _incrementTotalMinted(data.totalMinted, requestedQuantity, data.maxMintable);

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        bool valid = MerkleProofLib.verify(merkleProof, data.merkleRootHash, leaf);
        if (!valid) revert InvalidMerkleProof();

        unchecked {
            // Check the additional `requestedQuantity` does not exceed the maximum mintable per account.
            uint256 numberMinted = ISoundEditionV1(edition).numberMinted(msg.sender);
            // Won't overflow. The total number of tokens minted in `edition` won't exceed `type(uint32).max`,
            // and `quantity` has 32 bits.
            if (numberMinted + requestedQuantity > data.maxMintablePerAccount) revert ExceedsMaxPerAccount();
        }

        _mint(edition, mintId, requestedQuantity, affiliate);

        emit DropClaimed(msg.sender, requestedQuantity);
    }

    /**
     * @inheritdoc IMerkleDropMinter
     */
    function setPrice(
        address edition,
        uint128 mintId,
        uint96 price
    ) public onlyEditionOwnerOrAdmin(edition) {
        _editionMintData[edition][mintId].price = price;
        emit PriceSet(edition, mintId, price);
    }

    /**
     * @inheritdoc IMerkleDropMinter
     */
    function setMaxMintablePerAccount(
        address edition,
        uint128 mintId,
        uint32 maxMintablePerAccount
    ) public onlyEditionOwnerOrAdmin(edition) {
        if (maxMintablePerAccount == 0) revert MaxMintablePerAccountIsZero();
        _editionMintData[edition][mintId].maxMintablePerAccount = maxMintablePerAccount;
        emit MaxMintablePerAccountSet(edition, mintId, maxMintablePerAccount);
    }

    /**
     * @inheritdoc IMerkleDropMinter
     */
    function setMaxMintable(
        address edition,
        uint128 mintId,
        uint32 maxMintable
    ) public onlyEditionOwnerOrAdmin(edition) {
        _editionMintData[edition][mintId].maxMintable = maxMintable;
        emit MaxMintableSet(edition, mintId, maxMintable);
    }

    /*
     * @inheritdoc IMerkleDropMinter
     */
    function setMerkleRootHash(
        address edition,
        uint128 mintId,
        bytes32 merkleRootHash
    ) public onlyEditionOwnerOrAdmin(edition) {
        if (merkleRootHash == bytes32(0)) revert MerkleRootHashIsEmpty();

        _editionMintData[edition][mintId].merkleRootHash = merkleRootHash;
        emit MerkleRootHashSet(edition, mintId, merkleRootHash);
    }

    // =============================================================
    //               PUBLIC / EXTERNAL VIEW FUNCTIONS
    // =============================================================

    /**
     * @inheritdoc IMinterModule
     */
    function totalPrice(
        address edition,
        uint128 mintId,
        address, /* minter */
        uint32 quantity
    ) public view virtual override(BaseMinter, IMinterModule) returns (uint128) {
        unchecked {
            // Will not overflow, as `price` is 96 bits, and `quantity` is 32 bits. 96 + 32 = 128.
            return uint128(uint256(_editionMintData[edition][mintId].price) * uint256(quantity));
        }
    }

    /**
     * @inheritdoc IMerkleDropMinter
     */
    function mintInfo(address edition, uint128 mintId) external view returns (MintInfo memory) {
        BaseData memory baseData = _baseData[edition][mintId];
        EditionMintData storage mintData = _editionMintData[edition][mintId];

        MintInfo memory combinedMintData = MintInfo(
            baseData.startTime,
            baseData.endTime,
            baseData.affiliateFeeBPS,
            baseData.mintPaused,
            mintData.price,
            mintData.maxMintable,
            mintData.maxMintablePerAccount,
            mintData.totalMinted,
            mintData.merkleRootHash
        );

        return combinedMintData;
    }

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view override(IERC165, BaseMinter) returns (bool) {
        return BaseMinter.supportsInterface(interfaceId) || interfaceId == type(IMerkleDropMinter).interfaceId;
    }

    /**
     * @inheritdoc IMinterModule
     */
    function moduleInterfaceId() public pure returns (bytes4) {
        return type(IMerkleDropMinter).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { IMinterModule } from "@core/interfaces/IMinterModule.sol";

/**
 * @dev Data unique to a merkle drop mint.
 */
struct EditionMintData {
    // Hash of the root node for the merkle tree drop
    bytes32 merkleRootHash;
    // The price at which each token will be sold, in ETH.
    uint96 price;
    // The maximum number of tokens that can can be minted for this sale.
    uint32 maxMintable;
    // The maximum number of tokens that a wallet can mint.
    uint32 maxMintablePerAccount;
    // The total number of tokens minted so far for this sale.
    uint32 totalMinted;
}

/**
 * @dev All the information about a merkle drop mint (combines EditionMintData with BaseData).
 */
struct MintInfo {
    uint32 startTime;
    uint32 endTime;
    uint16 affiliateFeeBPS;
    bool mintPaused;
    uint96 price;
    uint32 maxMintable;
    uint32 maxMintablePerAccount;
    uint32 totalMinted;
    bytes32 merkleRootHash;
}

/**
 * @title IMerkleDropMinter
 * @dev Interface for the `MerkleDropMinter` module.
 * @author Sound.xyz
 */
interface IMerkleDropMinter is IMinterModule {
    // =============================================================
    //                            EVENTS
    // =============================================================

    /**
     * @dev Emitted when a new merkle drop mint is created.
     * @param edition               The edition address.
     * @param mintId                The mint ID.
     * @param merkleRootHash        The root of the merkle tree of the approved addresses.
     * @param price                 The price at which each token will be sold, in ETH.
     * @param startTime             The time minting can begin.
     * @param endTime               The time minting will end.
     * @param affiliateFeeBPS       The affiliate fee in basis points.
     * @param maxMintable           The maximum number of tokens that can be minted.
     * @param maxMintablePerAccount The maximum number of tokens that an account can mint.
     */
    event MerkleDropMintCreated(
        address indexed edition,
        uint128 indexed mintId,
        bytes32 merkleRootHash,
        uint96 price,
        uint32 startTime,
        uint32 endTime,
        uint16 affiliateFeeBPS,
        uint32 maxMintable,
        uint32 maxMintablePerAccount
    );

    /**
     * @dev Emitted when tokens are claimed by an account.
     * @param recipient The address of the account that claimed the tokens.
     * @param quantity  The quantity of tokens claimed.
     */
    event DropClaimed(address recipient, uint32 quantity);

    /**
     * @dev Emitted when the `price` is changed for (`edition`, `mintId`).
     * @param edition Address of the song edition contract we are minting for.
     * @param mintId  The mint ID.
     * @param price   Sale price in ETH for minting a single token in `edition`.
     */
    event PriceSet(address indexed edition, uint128 indexed mintId, uint96 price);

    /**
     * @dev Emitted when the `maxMintable` is changed for (`edition`, `mintId`).
     * @param edition               Address of the song edition contract we are minting for.
     * @param mintId                The mint ID.
     * @param maxMintable The maximum number of tokens that can be minted on this schedule.
     */
    event MaxMintableSet(address indexed edition, uint128 indexed mintId, uint32 maxMintable);

    /**
     * @dev Emitted when the `maxMintablePerAccount` is changed for (`edition`, `mintId`).
     * @param edition               Address of the song edition contract we are minting for.
     * @param mintId                The mint ID.
     * @param maxMintablePerAccount The maximum number of tokens that can be minted per account.
     */
    event MaxMintablePerAccountSet(address indexed edition, uint128 indexed mintId, uint32 maxMintablePerAccount);

    /**
     * @dev Emitted when the `merkleRootHash` is changed for (`edition`, `mintId`).
     * @param edition        Address of the song edition contract we are minting for.
     * @param mintId         The mint ID.
     * @param merkleRootHash The merkle root hash of the entries.
     */
    event MerkleRootHashSet(address indexed edition, uint128 indexed mintId, bytes32 merkleRootHash);

    // =============================================================
    //                            ERRORS
    // =============================================================

    /**
     * @dev The merkle proof is invalid.
     */
    error InvalidMerkleProof();

    /**
     * @dev The number of tokens minted has exceeded the number allowed for each account.
     */
    error ExceedsMaxPerAccount();

    /**
     * @dev The merkle root hash is empty.
     */
    error MerkleRootHashIsEmpty();

    /**
     * @dev The max mintable per account cannot be zero.
     */
    error MaxMintablePerAccountIsZero();

    // =============================================================
    //               PUBLIC / EXTERNAL WRITE FUNCTIONS
    // =============================================================

    /**
     * @dev Initializes merkle drop mint instance.
     * @param edition                Address of the song edition contract we are minting for.
     * @param merkleRootHash         bytes32 hash of the Merkle tree representing eligible mints.
     * @param price                  Sale price in ETH for minting a single token in `edition`.
     * @param startTime              Start timestamp of sale (in seconds since unix epoch).
     * @param endTime                End timestamp of sale (in seconds since unix epoch).
     * @param affiliateFeeBPS        The affiliate fee in basis points.
     * @param maxMintable_           The maximum number of tokens that can can be minted for this sale.
     * @param maxMintablePerAccount_ The maximum number of tokens that a single account can mint.
     * @return mintId The ID of the new mint instance.
     */
    function createEditionMint(
        address edition,
        bytes32 merkleRootHash,
        uint96 price,
        uint32 startTime,
        uint32 endTime,
        uint16 affiliateFeeBPS,
        uint32 maxMintable_,
        uint32 maxMintablePerAccount_
    ) external returns (uint128 mintId);

    /**
     * @dev Mints a token for a particular mint instance.
     * @param mintId            The ID of the mint instance.
     * @param requestedQuantity The quantity of tokens to mint.
     */
    function mint(
        address edition,
        uint128 mintId,
        uint32 requestedQuantity,
        bytes32[] calldata merkleProof,
        address affiliate
    ) external payable;

    /*
     * @dev Sets the `price` for (`edition`, `mintId`).
     * @param edition Address of the song edition contract we are minting for.
     * @param mintId  The mint ID.
     * @param price   Sale price in ETH for minting a single token in `edition`.
     */
    function setPrice(
        address edition,
        uint128 mintId,
        uint96 price
    ) external;

    /*
     * @dev Sets the `maxMintablePerAccount` for (`edition`, `mintId`).
     * @param edition               Address of the song edition contract we are minting for.
     * @param mintId                The mint ID.
     * @param maxMintablePerAccount The maximum number of tokens that can be minted by an account.
     */
    function setMaxMintablePerAccount(
        address edition,
        uint128 mintId,
        uint32 maxMintablePerAccount
    ) external;

    /*
     * @dev Sets the `maxMintable` for (`edition`, `mintId`).
     * @param edition               Address of the song edition contract we are minting for.
     * @param mintId                The mint ID.
     * @param maxMintable The maximum number of tokens that can be minted on this schedule.
     */
    function setMaxMintable(
        address edition,
        uint128 mintId,
        uint32 maxMintable
    ) external;

    /*
     * @dev Sets the `merkleRootHash` for (`edition`, `mintId`).
     * @param edition        Address of the song edition contract we are minting for.
     * @param mintId         The mint ID.
     * @param merkleRootHash The merkle root hash of the entries.
     */
    function setMerkleRootHash(
        address edition,
        uint128 mintId,
        bytes32 merkleRootHash
    ) external;

    // =============================================================
    //               PUBLIC / EXTERNAL VIEW FUNCTIONS
    // =============================================================

    /**
     * @dev Returns IMerkleDropMinter.MintInfo instance containing the full minter parameter set.
     * @param edition The edition to get the mint instance for.
     * @param mintId The ID of the mint instance.
     * @return mintInfo Information about this mint.
     */
    function mintInfo(address edition, uint128 mintId) external view returns (MintInfo memory);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721AUpgradeable {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external payable;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

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

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
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
interface IERC165Upgradeable {
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

/// @notice Simple single owner and multiroles authorization mixin.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/auth/OwnableRoles.sol)
/// @dev While the ownable portion follows [EIP-173](https://eips.ethereum.org/EIPS/eip-173)
/// for compatibility, the nomenclature for the 2-step ownership handover and roles
/// may be unique to this codebase.
abstract contract OwnableRoles {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The caller is not authorized to call the function.
    error Unauthorized();

    /// @dev The `newOwner` cannot be the zero address.
    error NewOwnerIsZeroAddress();

    /// @dev The `pendingOwner` does not have a valid handover request.
    error NoHandoverRequest();

    /// @dev `bytes4(keccak256(bytes("Unauthorized()")))`.
    uint256 private constant _UNAUTHORIZED_ERROR_SELECTOR = 0x82b42900;

    /// @dev `bytes4(keccak256(bytes("NewOwnerIsZeroAddress()")))`.
    uint256 private constant _NEW_OWNER_IS_ZERO_ADDRESS_ERROR_SELECTOR = 0x7448fbae;

    /// @dev `bytes4(keccak256(bytes("NoHandoverRequest()")))`.
    uint256 private constant _NO_HANDOVER_REQUEST_ERROR_SELECTOR = 0x6f5e8818;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ownership is transferred from `oldOwner` to `newOwner`.
    /// This event is intentionally kept the same as OpenZeppelin's Ownable to be
    /// compatible with indexers and [EIP-173](https://eips.ethereum.org/EIPS/eip-173),
    /// despite it not being as lightweight as a single argument event.
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    /// @dev An ownership handover to `pendingOwner` has been requested.
    event OwnershipHandoverRequested(address indexed pendingOwner);

    /// @dev The ownership handover to `pendingOwner` has been canceled.
    event OwnershipHandoverCanceled(address indexed pendingOwner);

    /// @dev The `user`'s roles is updated to `roles`.
    /// Each bit of `roles` represents whether the role is set.
    event RolesUpdated(address indexed user, uint256 indexed roles);

    /// @dev `keccak256(bytes("OwnershipTransferred(address,address)"))`.
    uint256 private constant _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE =
        0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0;

    /// @dev `keccak256(bytes("OwnershipHandoverRequested(address)"))`.
    uint256 private constant _OWNERSHIP_HANDOVER_REQUESTED_EVENT_SIGNATURE =
        0xdbf36a107da19e49527a7176a1babf963b4b0ff8cde35ee35d6cd8f1f9ac7e1d;

    /// @dev `keccak256(bytes("OwnershipHandoverCanceled(address)"))`.
    uint256 private constant _OWNERSHIP_HANDOVER_CANCELED_EVENT_SIGNATURE =
        0xfa7b8eab7da67f412cc9575ed43464468f9bfbae89d1675917346ca6d8fe3c92;

    /// @dev `keccak256(bytes("RolesUpdated(address,uint256)"))`.
    uint256 private constant _ROLES_UPDATED_EVENT_SIGNATURE =
        0x715ad5ce61fc9595c7b415289d59cf203f23a94fa06f04af7e489a0a76e1fe26;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The owner slot is given by: `not(_OWNER_SLOT_NOT)`.
    /// It is intentionally choosen to be a high value
    /// to avoid collision with lower slots.
    /// The choice of manual storage layout is to enable compatibility
    /// with both regular and upgradeable contracts.
    ///
    /// The role slot of `user` is given by:
    /// ```
    ///     mstore(0x00, or(shl(96, user), _OWNER_SLOT_NOT))
    ///     let roleSlot := keccak256(0x00, 0x20)
    /// ```
    /// This automatically ignores the upper bits of the `user` in case
    /// they are not clean, as well as keep the `keccak256` under 32-bytes.
    uint256 private constant _OWNER_SLOT_NOT = 0x8b78c6d8;

    /// The ownership handover slot of `newOwner` is given by:
    /// ```
    ///     mstore(0x00, or(shl(96, user), _HANDOVER_SLOT_SEED))
    ///     let handoverSlot := keccak256(0x00, 0x20)
    /// ```
    /// It stores the expiry timestamp of the two-step ownership handover.
    uint256 private constant _HANDOVER_SLOT_SEED = 0x389a75e1;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     INTERNAL FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Initializes the owner directly without authorization guard.
    /// This function must be called upon initialization,
    /// regardless of whether the contract is upgradeable or not.
    /// This is to enable generalization to both regular and upgradeable contracts,
    /// and to save gas in case the initial owner is not the caller.
    /// For performance reasons, this function will not check if there
    /// is an existing owner.
    function _initializeOwner(address newOwner) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Clean the upper 96 bits.
            newOwner := shr(96, shl(96, newOwner))
            // Store the new value.
            sstore(not(_OWNER_SLOT_NOT), newOwner)
            // Emit the {OwnershipTransferred} event.
            log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, 0, newOwner)
        }
    }

    /// @dev Sets the owner directly without authorization guard.
    function _setOwner(address newOwner) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            let ownerSlot := not(_OWNER_SLOT_NOT)
            // Clean the upper 96 bits.
            newOwner := shr(96, shl(96, newOwner))
            // Emit the {OwnershipTransferred} event.
            log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, sload(ownerSlot), newOwner)
            // Store the new value.
            sstore(ownerSlot, newOwner)
        }
    }

    /// @dev Grants the roles directly without authorization guard.
    /// Each bit of `roles` represents the role to turn on.
    function _grantRoles(address user, uint256 roles) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the role slot.
            mstore(0x00, or(shl(96, user), _OWNER_SLOT_NOT))
            let roleSlot := keccak256(0x00, 0x20)
            // Load the current value and `or` it with `roles`.
            let newRoles := or(sload(roleSlot), roles)
            // Store the new value.
            sstore(roleSlot, newRoles)
            // Emit the {RolesUpdated} event.
            log3(0, 0, _ROLES_UPDATED_EVENT_SIGNATURE, shr(96, shl(96, user)), newRoles)
        }
    }

    /// @dev Removes the roles directly without authorization guard.
    /// Each bit of `roles` represents the role to turn off.
    function _removeRoles(address user, uint256 roles) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the role slot.
            mstore(0x00, or(shl(96, user), _OWNER_SLOT_NOT))
            let roleSlot := keccak256(0x00, 0x20)
            // Load the current value.
            let currentRoles := sload(roleSlot)
            // Use `and` to compute the intersection of `currentRoles` and `roles`,
            // `xor` it with `currentRoles` to flip the bits in the intersection.
            let newRoles := xor(currentRoles, and(currentRoles, roles))
            // Then, store the new value.
            sstore(roleSlot, newRoles)
            // Emit the {RolesUpdated} event.
            log3(0, 0, _ROLES_UPDATED_EVENT_SIGNATURE, shr(96, shl(96, user)), newRoles)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  PUBLIC UPDATE FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Allows the owner to transfer the ownership to `newOwner`.
    function transferOwnership(address newOwner) public payable virtual onlyOwner {
        /// @solidity memory-safe-assembly
        assembly {
            // Clean the upper 96 bits.
            newOwner := shr(96, shl(96, newOwner))
            // Reverts if the `newOwner` is the zero address.
            if iszero(newOwner) {
                mstore(0x00, _NEW_OWNER_IS_ZERO_ADDRESS_ERROR_SELECTOR)
                revert(0x1c, 0x04)
            }
            // Emit the {OwnershipTransferred} event.
            log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, caller(), newOwner)
            // Store the new value.
            sstore(not(_OWNER_SLOT_NOT), newOwner)
        }
    }

    /// @dev Allows the owner to renounce their ownership.
    function renounceOwnership() public payable virtual onlyOwner {
        /// @solidity memory-safe-assembly
        assembly {
            // Emit the {OwnershipTransferred} event.
            log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, caller(), 0)
            // Store the new value.
            sstore(not(_OWNER_SLOT_NOT), 0)
        }
    }

    /// @dev Request a two-step ownership handover to the caller.
    /// The request will be automatically expire in 48 hours (172800 seconds) by default.
    function requestOwnershipHandover() public payable virtual {
        unchecked {
            uint256 expires = block.timestamp + ownershipHandoverValidFor();
            /// @solidity memory-safe-assembly
            assembly {
                // Compute and set the handover slot to 1.
                mstore(0x00, or(shl(96, caller()), _HANDOVER_SLOT_SEED))
                sstore(keccak256(0x00, 0x20), expires)
                // Emit the {OwnershipHandoverRequested} event.
                log2(0, 0, _OWNERSHIP_HANDOVER_REQUESTED_EVENT_SIGNATURE, caller())
            }
        }
    }

    /// @dev Cancels the two-step ownership handover to the caller, if any.
    function cancelOwnershipHandover() public payable virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute and set the handover slot to 0.
            mstore(0x00, or(shl(96, caller()), _HANDOVER_SLOT_SEED))
            sstore(keccak256(0x00, 0x20), 0)
            // Emit the {OwnershipHandoverCanceled} event.
            log2(0, 0, _OWNERSHIP_HANDOVER_CANCELED_EVENT_SIGNATURE, caller())
        }
    }

    /// @dev Allows the owner to complete the two-step ownership handover to `pendingOwner`.
    /// Reverts if there is no existing ownership handover requested by `pendingOwner`.
    function completeOwnershipHandover(address pendingOwner) public payable virtual onlyOwner {
        /// @solidity memory-safe-assembly
        assembly {
            // Clean the upper 96 bits.
            pendingOwner := shr(96, shl(96, pendingOwner))
            // Compute and set the handover slot to 0.
            mstore(0x00, or(shl(96, pendingOwner), _HANDOVER_SLOT_SEED))
            let handoverSlot := keccak256(0x00, 0x20)
            // If the handover does not exist, or has expired.
            if gt(timestamp(), sload(handoverSlot)) {
                mstore(0x00, _NO_HANDOVER_REQUEST_ERROR_SELECTOR)
                revert(0x1c, 0x04)
            }
            // Set the handover slot to 0.
            sstore(handoverSlot, 0)
            // Emit the {OwnershipTransferred} event.
            log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, caller(), pendingOwner)
            // Store the new value.
            sstore(not(_OWNER_SLOT_NOT), pendingOwner)
        }
    }

    /// @dev Allows the owner to grant `user` `roles`.
    /// If the `user` already has a role, then it will be an no-op for the role.
    function grantRoles(address user, uint256 roles) public payable virtual onlyOwner {
        _grantRoles(user, roles);
    }

    /// @dev Allows the owner to remove `user` `roles`.
    /// If the `user` does not have a role, then it will be an no-op for the role.
    function revokeRoles(address user, uint256 roles) public payable virtual onlyOwner {
        _removeRoles(user, roles);
    }

    /// @dev Allow the caller to remove their own roles.
    /// If the caller does not have a role, then it will be an no-op for the role.
    function renounceRoles(uint256 roles) public payable virtual {
        _removeRoles(msg.sender, roles);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   PUBLIC READ FUNCTIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the owner of the contract.
    function owner() public view virtual returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := sload(not(_OWNER_SLOT_NOT))
        }
    }

    /// @dev Returns the expiry timestamp for the two-step ownership handover to `pendingOwner`.
    function ownershipHandoverExpiresAt(address pendingOwner)
        public
        view
        virtual
        returns (uint256 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the handover slot.
            mstore(0x00, or(shl(96, pendingOwner), _HANDOVER_SLOT_SEED))
            // Load the handover slot.
            result := sload(keccak256(0x00, 0x20))
        }
    }

    /// @dev Returns how long a two-step ownership handover is valid for in seconds.
    function ownershipHandoverValidFor() public view virtual returns (uint64) {
        return 48 * 3600;
    }

    /// @dev Returns whether `user` has any of `roles`.
    function hasAnyRole(address user, uint256 roles) public view virtual returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the role slot.
            mstore(0x00, or(shl(96, user), _OWNER_SLOT_NOT))
            // Load the stored value, and set the result to whether the
            // `and` intersection of the value and `roles` is not zero.
            result := iszero(iszero(and(sload(keccak256(0x00, 0x20)), roles)))
        }
    }

    /// @dev Returns whether `user` has all of `roles`.
    function hasAllRoles(address user, uint256 roles) public view virtual returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the role slot.
            mstore(0x00, or(shl(96, user), _OWNER_SLOT_NOT))
            // Whether the stored value is contains all the set bits in `roles`.
            result := eq(and(sload(keccak256(0x00, 0x20)), roles), roles)
        }
    }

    /// @dev Returns the roles of `user`.
    function rolesOf(address user) public view virtual returns (uint256 roles) {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the role slot.
            mstore(0x00, or(shl(96, user), _OWNER_SLOT_NOT))
            // Load the stored value.
            roles := sload(keccak256(0x00, 0x20))
        }
    }

    /// @dev Convenience function to return a `roles` bitmap from an array of `ordinals`.
    /// This is meant for frontends like Etherscan, and is therefore not fully optimized.
    /// Not recommended to be called on-chain.
    function rolesFromOrdinals(uint8[] memory ordinals) public pure returns (uint256 roles) {
        /// @solidity memory-safe-assembly
        assembly {
            // Skip the length slot.
            let o := add(ordinals, 0x20)
            // `shl` 5 is equivalent to multiplying by 0x20.
            let end := add(o, shl(5, mload(ordinals)))

            for {} iszero(eq(o, end)) { o := add(o, 0x20) } {
                roles := or(roles, shl(and(mload(o), 0xff), 1))
            }
        }
    }

    /// @dev Convenience function to return an array of `ordinals` from the `roles` bitmap.
    /// This is meant for frontends like Etherscan, and is therefore not fully optimized.
    /// Not recommended to be called on-chain.
    function ordinalsFromRoles(uint256 roles) public pure returns (uint8[] memory ordinals) {
        /// @solidity memory-safe-assembly
        assembly {
            // Grab the pointer to the free memory.
            let ptr := add(mload(0x40), 0x20)
            // The absence of lookup tables, De Bruijn, etc., here is intentional for
            // smaller bytecode, as this function is not meant to be called on-chain.
            for { let i := 0 } 1 { i := add(i, 1) } {
                mstore(ptr, i)
                // `shr` 5 is equivalent to multiplying by 0x20.
                // Push back into the ordinals array if the bit is set.
                ptr := add(ptr, shl(5, and(roles, 1)))
                roles := shr(1, roles)
                if iszero(roles) { break }
            }
            // Set `ordinals` to the start of the free memory.
            ordinals := mload(0x40)
            // Allocate the memory.
            mstore(0x40, ptr)
            // Store the length of `ordinals`.
            mstore(ordinals, shr(5, sub(ptr, add(ordinals, 0x20))))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         MODIFIERS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Marks a function as only callable by the owner.
    modifier onlyOwner() virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // If the caller is not the stored owner, revert.
            if iszero(eq(caller(), sload(not(_OWNER_SLOT_NOT)))) {
                mstore(0x00, _UNAUTHORIZED_ERROR_SELECTOR)
                revert(0x1c, 0x04)
            }
        }
        _;
    }

    /// @dev Marks a function as only callable by an account with `roles`.
    modifier onlyRoles(uint256 roles) virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the role slot.
            mstore(0x00, or(shl(96, caller()), _OWNER_SLOT_NOT))
            // Load the stored value, and if the `and` intersection
            // of the value and `roles` is zero, revert.
            if iszero(and(sload(keccak256(0x00, 0x20)), roles)) {
                mstore(0x00, _UNAUTHORIZED_ERROR_SELECTOR)
                revert(0x1c, 0x04)
            }
        }
        _;
    }

    /// @dev Marks a function as only callable by the owner or by an account
    /// with `roles`. Checks for ownership first, then lazily checks for roles.
    modifier onlyOwnerOrRoles(uint256 roles) virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // If the caller is not the stored owner.
            if iszero(eq(caller(), sload(not(_OWNER_SLOT_NOT)))) {
                // Compute the role slot.
                mstore(0x00, or(shl(96, caller()), _OWNER_SLOT_NOT))
                // Load the stored value, and if the `and` intersection
                // of the value and `roles` is zero, revert.
                if iszero(and(sload(keccak256(0x00, 0x20)), roles)) {
                    mstore(0x00, _UNAUTHORIZED_ERROR_SELECTOR)
                    revert(0x1c, 0x04)
                }
            }
        }
        _;
    }

    /// @dev Marks a function as only callable by an account with `roles`
    /// or the owner. Checks for roles first, then lazily checks for ownership.
    modifier onlyRolesOrOwner(uint256 roles) virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the role slot.
            mstore(0x00, or(shl(96, caller()), _OWNER_SLOT_NOT))
            // Load the stored value, and if the `and` intersection
            // of the value and `roles` is zero, revert.
            if iszero(and(sload(keccak256(0x00, 0x20)), roles)) {
                // If the caller is not the stored owner.
                if iszero(eq(caller(), sload(not(_OWNER_SLOT_NOT)))) {
                    mstore(0x00, _UNAUTHORIZED_ERROR_SELECTOR)
                    revert(0x1c, 0x04)
                }
            }
        }
        _;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ROLE CONSTANTS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // IYKYK

    uint256 internal constant _ROLE_0 = 1 << 0;
    uint256 internal constant _ROLE_1 = 1 << 1;
    uint256 internal constant _ROLE_2 = 1 << 2;
    uint256 internal constant _ROLE_3 = 1 << 3;
    uint256 internal constant _ROLE_4 = 1 << 4;
    uint256 internal constant _ROLE_5 = 1 << 5;
    uint256 internal constant _ROLE_6 = 1 << 6;
    uint256 internal constant _ROLE_7 = 1 << 7;
    uint256 internal constant _ROLE_8 = 1 << 8;
    uint256 internal constant _ROLE_9 = 1 << 9;
    uint256 internal constant _ROLE_10 = 1 << 10;
    uint256 internal constant _ROLE_11 = 1 << 11;
    uint256 internal constant _ROLE_12 = 1 << 12;
    uint256 internal constant _ROLE_13 = 1 << 13;
    uint256 internal constant _ROLE_14 = 1 << 14;
    uint256 internal constant _ROLE_15 = 1 << 15;
    uint256 internal constant _ROLE_16 = 1 << 16;
    uint256 internal constant _ROLE_17 = 1 << 17;
    uint256 internal constant _ROLE_18 = 1 << 18;
    uint256 internal constant _ROLE_19 = 1 << 19;
    uint256 internal constant _ROLE_20 = 1 << 20;
    uint256 internal constant _ROLE_21 = 1 << 21;
    uint256 internal constant _ROLE_22 = 1 << 22;
    uint256 internal constant _ROLE_23 = 1 << 23;
    uint256 internal constant _ROLE_24 = 1 << 24;
    uint256 internal constant _ROLE_25 = 1 << 25;
    uint256 internal constant _ROLE_26 = 1 << 26;
    uint256 internal constant _ROLE_27 = 1 << 27;
    uint256 internal constant _ROLE_28 = 1 << 28;
    uint256 internal constant _ROLE_29 = 1 << 29;
    uint256 internal constant _ROLE_30 = 1 << 30;
    uint256 internal constant _ROLE_31 = 1 << 31;
    uint256 internal constant _ROLE_32 = 1 << 32;
    uint256 internal constant _ROLE_33 = 1 << 33;
    uint256 internal constant _ROLE_34 = 1 << 34;
    uint256 internal constant _ROLE_35 = 1 << 35;
    uint256 internal constant _ROLE_36 = 1 << 36;
    uint256 internal constant _ROLE_37 = 1 << 37;
    uint256 internal constant _ROLE_38 = 1 << 38;
    uint256 internal constant _ROLE_39 = 1 << 39;
    uint256 internal constant _ROLE_40 = 1 << 40;
    uint256 internal constant _ROLE_41 = 1 << 41;
    uint256 internal constant _ROLE_42 = 1 << 42;
    uint256 internal constant _ROLE_43 = 1 << 43;
    uint256 internal constant _ROLE_44 = 1 << 44;
    uint256 internal constant _ROLE_45 = 1 << 45;
    uint256 internal constant _ROLE_46 = 1 << 46;
    uint256 internal constant _ROLE_47 = 1 << 47;
    uint256 internal constant _ROLE_48 = 1 << 48;
    uint256 internal constant _ROLE_49 = 1 << 49;
    uint256 internal constant _ROLE_50 = 1 << 50;
    uint256 internal constant _ROLE_51 = 1 << 51;
    uint256 internal constant _ROLE_52 = 1 << 52;
    uint256 internal constant _ROLE_53 = 1 << 53;
    uint256 internal constant _ROLE_54 = 1 << 54;
    uint256 internal constant _ROLE_55 = 1 << 55;
    uint256 internal constant _ROLE_56 = 1 << 56;
    uint256 internal constant _ROLE_57 = 1 << 57;
    uint256 internal constant _ROLE_58 = 1 << 58;
    uint256 internal constant _ROLE_59 = 1 << 59;
    uint256 internal constant _ROLE_60 = 1 << 60;
    uint256 internal constant _ROLE_61 = 1 << 61;
    uint256 internal constant _ROLE_62 = 1 << 62;
    uint256 internal constant _ROLE_63 = 1 << 63;
    uint256 internal constant _ROLE_64 = 1 << 64;
    uint256 internal constant _ROLE_65 = 1 << 65;
    uint256 internal constant _ROLE_66 = 1 << 66;
    uint256 internal constant _ROLE_67 = 1 << 67;
    uint256 internal constant _ROLE_68 = 1 << 68;
    uint256 internal constant _ROLE_69 = 1 << 69;
    uint256 internal constant _ROLE_70 = 1 << 70;
    uint256 internal constant _ROLE_71 = 1 << 71;
    uint256 internal constant _ROLE_72 = 1 << 72;
    uint256 internal constant _ROLE_73 = 1 << 73;
    uint256 internal constant _ROLE_74 = 1 << 74;
    uint256 internal constant _ROLE_75 = 1 << 75;
    uint256 internal constant _ROLE_76 = 1 << 76;
    uint256 internal constant _ROLE_77 = 1 << 77;
    uint256 internal constant _ROLE_78 = 1 << 78;
    uint256 internal constant _ROLE_79 = 1 << 79;
    uint256 internal constant _ROLE_80 = 1 << 80;
    uint256 internal constant _ROLE_81 = 1 << 81;
    uint256 internal constant _ROLE_82 = 1 << 82;
    uint256 internal constant _ROLE_83 = 1 << 83;
    uint256 internal constant _ROLE_84 = 1 << 84;
    uint256 internal constant _ROLE_85 = 1 << 85;
    uint256 internal constant _ROLE_86 = 1 << 86;
    uint256 internal constant _ROLE_87 = 1 << 87;
    uint256 internal constant _ROLE_88 = 1 << 88;
    uint256 internal constant _ROLE_89 = 1 << 89;
    uint256 internal constant _ROLE_90 = 1 << 90;
    uint256 internal constant _ROLE_91 = 1 << 91;
    uint256 internal constant _ROLE_92 = 1 << 92;
    uint256 internal constant _ROLE_93 = 1 << 93;
    uint256 internal constant _ROLE_94 = 1 << 94;
    uint256 internal constant _ROLE_95 = 1 << 95;
    uint256 internal constant _ROLE_96 = 1 << 96;
    uint256 internal constant _ROLE_97 = 1 << 97;
    uint256 internal constant _ROLE_98 = 1 << 98;
    uint256 internal constant _ROLE_99 = 1 << 99;
    uint256 internal constant _ROLE_100 = 1 << 100;
    uint256 internal constant _ROLE_101 = 1 << 101;
    uint256 internal constant _ROLE_102 = 1 << 102;
    uint256 internal constant _ROLE_103 = 1 << 103;
    uint256 internal constant _ROLE_104 = 1 << 104;
    uint256 internal constant _ROLE_105 = 1 << 105;
    uint256 internal constant _ROLE_106 = 1 << 106;
    uint256 internal constant _ROLE_107 = 1 << 107;
    uint256 internal constant _ROLE_108 = 1 << 108;
    uint256 internal constant _ROLE_109 = 1 << 109;
    uint256 internal constant _ROLE_110 = 1 << 110;
    uint256 internal constant _ROLE_111 = 1 << 111;
    uint256 internal constant _ROLE_112 = 1 << 112;
    uint256 internal constant _ROLE_113 = 1 << 113;
    uint256 internal constant _ROLE_114 = 1 << 114;
    uint256 internal constant _ROLE_115 = 1 << 115;
    uint256 internal constant _ROLE_116 = 1 << 116;
    uint256 internal constant _ROLE_117 = 1 << 117;
    uint256 internal constant _ROLE_118 = 1 << 118;
    uint256 internal constant _ROLE_119 = 1 << 119;
    uint256 internal constant _ROLE_120 = 1 << 120;
    uint256 internal constant _ROLE_121 = 1 << 121;
    uint256 internal constant _ROLE_122 = 1 << 122;
    uint256 internal constant _ROLE_123 = 1 << 123;
    uint256 internal constant _ROLE_124 = 1 << 124;
    uint256 internal constant _ROLE_125 = 1 << 125;
    uint256 internal constant _ROLE_126 = 1 << 126;
    uint256 internal constant _ROLE_127 = 1 << 127;
    uint256 internal constant _ROLE_128 = 1 << 128;
    uint256 internal constant _ROLE_129 = 1 << 129;
    uint256 internal constant _ROLE_130 = 1 << 130;
    uint256 internal constant _ROLE_131 = 1 << 131;
    uint256 internal constant _ROLE_132 = 1 << 132;
    uint256 internal constant _ROLE_133 = 1 << 133;
    uint256 internal constant _ROLE_134 = 1 << 134;
    uint256 internal constant _ROLE_135 = 1 << 135;
    uint256 internal constant _ROLE_136 = 1 << 136;
    uint256 internal constant _ROLE_137 = 1 << 137;
    uint256 internal constant _ROLE_138 = 1 << 138;
    uint256 internal constant _ROLE_139 = 1 << 139;
    uint256 internal constant _ROLE_140 = 1 << 140;
    uint256 internal constant _ROLE_141 = 1 << 141;
    uint256 internal constant _ROLE_142 = 1 << 142;
    uint256 internal constant _ROLE_143 = 1 << 143;
    uint256 internal constant _ROLE_144 = 1 << 144;
    uint256 internal constant _ROLE_145 = 1 << 145;
    uint256 internal constant _ROLE_146 = 1 << 146;
    uint256 internal constant _ROLE_147 = 1 << 147;
    uint256 internal constant _ROLE_148 = 1 << 148;
    uint256 internal constant _ROLE_149 = 1 << 149;
    uint256 internal constant _ROLE_150 = 1 << 150;
    uint256 internal constant _ROLE_151 = 1 << 151;
    uint256 internal constant _ROLE_152 = 1 << 152;
    uint256 internal constant _ROLE_153 = 1 << 153;
    uint256 internal constant _ROLE_154 = 1 << 154;
    uint256 internal constant _ROLE_155 = 1 << 155;
    uint256 internal constant _ROLE_156 = 1 << 156;
    uint256 internal constant _ROLE_157 = 1 << 157;
    uint256 internal constant _ROLE_158 = 1 << 158;
    uint256 internal constant _ROLE_159 = 1 << 159;
    uint256 internal constant _ROLE_160 = 1 << 160;
    uint256 internal constant _ROLE_161 = 1 << 161;
    uint256 internal constant _ROLE_162 = 1 << 162;
    uint256 internal constant _ROLE_163 = 1 << 163;
    uint256 internal constant _ROLE_164 = 1 << 164;
    uint256 internal constant _ROLE_165 = 1 << 165;
    uint256 internal constant _ROLE_166 = 1 << 166;
    uint256 internal constant _ROLE_167 = 1 << 167;
    uint256 internal constant _ROLE_168 = 1 << 168;
    uint256 internal constant _ROLE_169 = 1 << 169;
    uint256 internal constant _ROLE_170 = 1 << 170;
    uint256 internal constant _ROLE_171 = 1 << 171;
    uint256 internal constant _ROLE_172 = 1 << 172;
    uint256 internal constant _ROLE_173 = 1 << 173;
    uint256 internal constant _ROLE_174 = 1 << 174;
    uint256 internal constant _ROLE_175 = 1 << 175;
    uint256 internal constant _ROLE_176 = 1 << 176;
    uint256 internal constant _ROLE_177 = 1 << 177;
    uint256 internal constant _ROLE_178 = 1 << 178;
    uint256 internal constant _ROLE_179 = 1 << 179;
    uint256 internal constant _ROLE_180 = 1 << 180;
    uint256 internal constant _ROLE_181 = 1 << 181;
    uint256 internal constant _ROLE_182 = 1 << 182;
    uint256 internal constant _ROLE_183 = 1 << 183;
    uint256 internal constant _ROLE_184 = 1 << 184;
    uint256 internal constant _ROLE_185 = 1 << 185;
    uint256 internal constant _ROLE_186 = 1 << 186;
    uint256 internal constant _ROLE_187 = 1 << 187;
    uint256 internal constant _ROLE_188 = 1 << 188;
    uint256 internal constant _ROLE_189 = 1 << 189;
    uint256 internal constant _ROLE_190 = 1 << 190;
    uint256 internal constant _ROLE_191 = 1 << 191;
    uint256 internal constant _ROLE_192 = 1 << 192;
    uint256 internal constant _ROLE_193 = 1 << 193;
    uint256 internal constant _ROLE_194 = 1 << 194;
    uint256 internal constant _ROLE_195 = 1 << 195;
    uint256 internal constant _ROLE_196 = 1 << 196;
    uint256 internal constant _ROLE_197 = 1 << 197;
    uint256 internal constant _ROLE_198 = 1 << 198;
    uint256 internal constant _ROLE_199 = 1 << 199;
    uint256 internal constant _ROLE_200 = 1 << 200;
    uint256 internal constant _ROLE_201 = 1 << 201;
    uint256 internal constant _ROLE_202 = 1 << 202;
    uint256 internal constant _ROLE_203 = 1 << 203;
    uint256 internal constant _ROLE_204 = 1 << 204;
    uint256 internal constant _ROLE_205 = 1 << 205;
    uint256 internal constant _ROLE_206 = 1 << 206;
    uint256 internal constant _ROLE_207 = 1 << 207;
    uint256 internal constant _ROLE_208 = 1 << 208;
    uint256 internal constant _ROLE_209 = 1 << 209;
    uint256 internal constant _ROLE_210 = 1 << 210;
    uint256 internal constant _ROLE_211 = 1 << 211;
    uint256 internal constant _ROLE_212 = 1 << 212;
    uint256 internal constant _ROLE_213 = 1 << 213;
    uint256 internal constant _ROLE_214 = 1 << 214;
    uint256 internal constant _ROLE_215 = 1 << 215;
    uint256 internal constant _ROLE_216 = 1 << 216;
    uint256 internal constant _ROLE_217 = 1 << 217;
    uint256 internal constant _ROLE_218 = 1 << 218;
    uint256 internal constant _ROLE_219 = 1 << 219;
    uint256 internal constant _ROLE_220 = 1 << 220;
    uint256 internal constant _ROLE_221 = 1 << 221;
    uint256 internal constant _ROLE_222 = 1 << 222;
    uint256 internal constant _ROLE_223 = 1 << 223;
    uint256 internal constant _ROLE_224 = 1 << 224;
    uint256 internal constant _ROLE_225 = 1 << 225;
    uint256 internal constant _ROLE_226 = 1 << 226;
    uint256 internal constant _ROLE_227 = 1 << 227;
    uint256 internal constant _ROLE_228 = 1 << 228;
    uint256 internal constant _ROLE_229 = 1 << 229;
    uint256 internal constant _ROLE_230 = 1 << 230;
    uint256 internal constant _ROLE_231 = 1 << 231;
    uint256 internal constant _ROLE_232 = 1 << 232;
    uint256 internal constant _ROLE_233 = 1 << 233;
    uint256 internal constant _ROLE_234 = 1 << 234;
    uint256 internal constant _ROLE_235 = 1 << 235;
    uint256 internal constant _ROLE_236 = 1 << 236;
    uint256 internal constant _ROLE_237 = 1 << 237;
    uint256 internal constant _ROLE_238 = 1 << 238;
    uint256 internal constant _ROLE_239 = 1 << 239;
    uint256 internal constant _ROLE_240 = 1 << 240;
    uint256 internal constant _ROLE_241 = 1 << 241;
    uint256 internal constant _ROLE_242 = 1 << 242;
    uint256 internal constant _ROLE_243 = 1 << 243;
    uint256 internal constant _ROLE_244 = 1 << 244;
    uint256 internal constant _ROLE_245 = 1 << 245;
    uint256 internal constant _ROLE_246 = 1 << 246;
    uint256 internal constant _ROLE_247 = 1 << 247;
    uint256 internal constant _ROLE_248 = 1 << 248;
    uint256 internal constant _ROLE_249 = 1 << 249;
    uint256 internal constant _ROLE_250 = 1 << 250;
    uint256 internal constant _ROLE_251 = 1 << 251;
    uint256 internal constant _ROLE_252 = 1 << 252;
    uint256 internal constant _ROLE_253 = 1 << 253;
    uint256 internal constant _ROLE_254 = 1 << 254;
    uint256 internal constant _ROLE_255 = 1 << 255;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
library FixedPointMathLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The operation failed, as the output exceeds the maximum value of uint256.
    error ExpOverflow();

    /// @dev The operation failed, as the output exceeds the maximum value of uint256.
    error FactorialOverflow();

    /// @dev The operation failed, due to an multiplication overflow.
    error MulWadFailed();

    /// @dev The operation failed, either due to a
    /// multiplication overflow, or a division by a zero.
    error DivWadFailed();

    /// @dev The multiply-divide operation failed, either due to a
    /// multiplication overflow, or a division by a zero.
    error MulDivFailed();

    /// @dev The division failed, as the denominator is zero.
    error DivFailed();

    /// @dev The full precision multiply-divide operation failed, either due
    /// to the result being larger than 256 bits, or a division by a zero.
    error FullMulDivFailed();

    /// @dev The output is undefined, as the input is less-than-or-equal to zero.
    error LnWadUndefined();

    /// @dev The output is undefined, as the input is zero.
    error Log2Undefined();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The scalar of ETH and most ERC20s.
    uint256 internal constant WAD = 1e18;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              SIMPLIFIED FIXED POINT OPERATIONS             */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Equivalent to `(x * y) / WAD` rounded down.
    function mulWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            if mul(y, gt(x, div(not(0), y))) {
                // Store the function selector of `MulWadFailed()`.
                mstore(0x00, 0xbac65e5b)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := div(mul(x, y), WAD)
        }
    }

    /// @dev Equivalent to `(x * y) / WAD` rounded up.
    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            if mul(y, gt(x, div(not(0), y))) {
                // Store the function selector of `MulWadFailed()`.
                mstore(0x00, 0xbac65e5b)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(mul(x, y), WAD))), div(mul(x, y), WAD))
        }
    }

    /// @dev Equivalent to `(x * WAD) / y` rounded down.
    function divWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y != 0 && (WAD == 0 || x <= type(uint256).max / WAD))`.
            if iszero(mul(y, iszero(mul(WAD, gt(x, div(not(0), WAD)))))) {
                // Store the function selector of `DivWadFailed()`.
                mstore(0x00, 0x7c5f487d)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := div(mul(x, WAD), y)
        }
    }

    /// @dev Equivalent to `(x * WAD) / y` rounded up.
    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y != 0 && (WAD == 0 || x <= type(uint256).max / WAD))`.
            if iszero(mul(y, iszero(mul(WAD, gt(x, div(not(0), WAD)))))) {
                // Store the function selector of `DivWadFailed()`.
                mstore(0x00, 0x7c5f487d)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(mul(x, WAD), y))), div(mul(x, WAD), y))
        }
    }

    /// @dev Equivalent to `x` to the power of `y`.
    /// because `x ** y = (e ** ln(x)) ** y = e ** (ln(x) * y)`.
    function powWad(int256 x, int256 y) internal pure returns (int256) {
        // Using `ln(x)` means `x` must be greater than 0.
        return expWad((lnWad(x) * y) / int256(WAD));
    }

    /// @dev Returns `exp(x)`, denominated in `WAD`.
    function expWad(int256 x) internal pure returns (int256 r) {
        unchecked {
            // When the result is < 0.5 we return zero. This happens when
            // x <= floor(log(0.5e18) * 1e18) ~ -42e18
            if (x <= -42139678854452767551) return 0;

            // When the result is > (2**255 - 1) / 1e18 we can not represent it as an
            // int. This happens when x >= floor(log((2**255 - 1) / 1e18) * 1e18) ~ 135.
            if (x >= 135305999368893231589) revert ExpOverflow();

            // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
            // for more intermediate precision and a binary basis. This base conversion
            // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
            x = (x << 78) / 5 ** 18;

            // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers
            // of two such that exp(x) = exp(x') * 2**k, where k is an integer.
            // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
            int256 k = ((x << 96) / 54916777467707473351141471128 + 2 ** 95) >> 96;
            x = x - k * 54916777467707473351141471128;

            // k is in the range [-61, 195].

            // Evaluate using a (6, 7)-term rational approximation.
            // p is made monic, we'll multiply by a scale factor later.
            int256 y = x + 1346386616545796478920950773328;
            y = ((y * x) >> 96) + 57155421227552351082224309758442;
            int256 p = y + x - 94201549194550492254356042504812;
            p = ((p * y) >> 96) + 28719021644029726153956944680412240;
            p = p * x + (4385272521454847904659076985693276 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            int256 q = x - 2855989394907223263936484059900;
            q = ((q * x) >> 96) + 50020603652535783019961831881945;
            q = ((q * x) >> 96) - 533845033583426703283633433725380;
            q = ((q * x) >> 96) + 3604857256930695427073651918091429;
            q = ((q * x) >> 96) - 14423608567350463180887372962807573;
            q = ((q * x) >> 96) + 26449188498355588339934803723976023;

            /// @solidity memory-safe-assembly
            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial won't have zeros in the domain as all its roots are complex.
                // No scaling is necessary because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r should be in the range (0.09, 0.25) * 2**96.

            // We now need to multiply r by:
            // * the scale factor s = ~6.031367120.
            // * the 2**k factor from the range reduction.
            // * the 1e18 / 2**96 factor for base conversion.
            // We do this all at once, with an intermediate result in 2**213
            // basis, so the final right shift is always by a positive amount.
            r = int256(
                (uint256(r) * 3822833074963236453042738258902158003155416615667) >> uint256(195 - k)
            );
        }
    }

    /// @dev Returns `ln(x)`, denominated in `WAD`.
    function lnWad(int256 x) internal pure returns (int256 r) {
        unchecked {
            if (x <= 0) revert LnWadUndefined();

            // We want to convert x from 10**18 fixed point to 2**96 fixed point.
            // We do this by multiplying by 2**96 / 10**18. But since
            // ln(x * C) = ln(x) + ln(C), we can simply do nothing here
            // and add ln(2**96 / 10**18) at the end.

            // Compute k = log2(x) - 96.
            int256 k;
            /// @solidity memory-safe-assembly
            assembly {
                let v := x
                k := shl(7, lt(0xffffffffffffffffffffffffffffffff, v))
                k := or(k, shl(6, lt(0xffffffffffffffff, shr(k, v))))
                k := or(k, shl(5, lt(0xffffffff, shr(k, v))))

                // For the remaining 32 bits, use a De Bruijn lookup.
                // See: https://graphics.stanford.edu/~seander/bithacks.html
                v := shr(k, v)
                v := or(v, shr(1, v))
                v := or(v, shr(2, v))
                v := or(v, shr(4, v))
                v := or(v, shr(8, v))
                v := or(v, shr(16, v))

                // forgefmt: disable-next-item
                k := sub(or(k, byte(shr(251, mul(v, shl(224, 0x07c4acdd))),
                    0x0009010a0d15021d0b0e10121619031e080c141c0f111807131b17061a05041f)), 96)
            }

            // Reduce range of x to (1, 2) * 2**96
            // ln(2^k * x) = k * ln(2) + ln(x)
            x <<= uint256(159 - k);
            x = int256(uint256(x) >> 159);

            // Evaluate using a (8, 8)-term rational approximation.
            // p is made monic, we will multiply by a scale factor later.
            int256 p = x + 3273285459638523848632254066296;
            p = ((p * x) >> 96) + 24828157081833163892658089445524;
            p = ((p * x) >> 96) + 43456485725739037958740375743393;
            p = ((p * x) >> 96) - 11111509109440967052023855526967;
            p = ((p * x) >> 96) - 45023709667254063763336534515857;
            p = ((p * x) >> 96) - 14706773417378608786704636184526;
            p = p * x - (795164235651350426258249787498 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            // q is monic by convention.
            int256 q = x + 5573035233440673466300451813936;
            q = ((q * x) >> 96) + 71694874799317883764090561454958;
            q = ((q * x) >> 96) + 283447036172924575727196451306956;
            q = ((q * x) >> 96) + 401686690394027663651624208769553;
            q = ((q * x) >> 96) + 204048457590392012362485061816622;
            q = ((q * x) >> 96) + 31853899698501571402653359427138;
            q = ((q * x) >> 96) + 909429971244387300277376558375;
            /// @solidity memory-safe-assembly
            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial is known not to have zeros in the domain.
                // No scaling required because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r is in the range (0, 0.125) * 2**96

            // Finalization, we need to:
            // * multiply by the scale factor s = 5.549…
            // * add ln(2**96 / 10**18)
            // * add k * ln(2)
            // * multiply by 10**18 / 2**96 = 5**18 >> 78

            // mul s * 5e18 * 2**96, base is now 5**18 * 2**192
            r *= 1677202110996718588342820967067443963516166;
            // add ln(2) * k * 5e18 * 2**192
            r += 16597577552685614221487285958193947469193820559219878177908093499208371 * k;
            // add ln(2**96 / 10**18) * 5e18 * 2**192
            r += 600920179829731861736702779321621459595472258049074101567377883020018308;
            // base conversion: mul 2**18 / 2**192
            r >>= 174;
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  GENERAL NUMBER UTILITIES                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Calculates floor(a × b ÷ denominator) with full precision.
    /// Throws if result overflows a uint256 or when the denominator is zero.
    /// Credit to Remco Bloemen under MIT license: https://xn--2-umb.com/21/muldiv
    function fullMulDiv(uint256 a, uint256 b, uint256 denominator)
        internal
        pure
        returns (uint256 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // forgefmt: disable-next-item
            for {} 1 {} {
                // 512-bit multiply [prod1 prod0] = a * b
                // Compute the product mod 2**256 and mod 2**256 - 1
                // then use the Chinese Remainder Theorem to reconstruct
                // the 512 bit result. The result is stored in two 256
                // variables such that product = prod1 * 2**256 + prod0

                // Least significant 256 bits of the product
                let prod0 := mul(a, b)
                let mm := mulmod(a, b, not(0))
                // Most significant 256 bits of the product
                let prod1 := sub(sub(mm, prod0), lt(mm, prod0))

                // Handle non-overflow cases, 256 by 256 division.
                if iszero(prod1) {
                    if iszero(denominator) {
                        // Store the function selector of `FullMulDivFailed()`.
                        mstore(0x00, 0xae47f702)
                        // Revert with (offset, size).
                        revert(0x1c, 0x04)
                    }
                    result := div(prod0, denominator)
                    break       
                }

                // Make sure the result is less than 2**256.
                // Also prevents `denominator == 0`.
                if iszero(gt(denominator, prod1)) {
                    // Store the function selector of `FullMulDivFailed()`.
                    mstore(0x00, 0xae47f702)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }

                ///////////////////////////////////////////////
                // 512 by 256 division.
                ///////////////////////////////////////////////

                // Make division exact by subtracting the remainder from [prod1 prod0].
                // Compute remainder using mulmod.
                let remainder := mulmod(a, b, denominator)
                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
                // Factor powers of two out of denominator.
                // Compute largest power of two divisor of denominator.
                // Always >= 1.
                let twos := and(denominator, sub(0, denominator))
                // Divide denominator by power of two
                denominator := div(denominator, twos)
                // Divide [prod1 prod0] by the factors of two
                prod0 := div(prod0, twos)
                // Shift in bits from prod1 into prod0. For this we need
                // to flip `twos` such that it is 2**256 / twos.
                // If `twos` is zero, then it becomes one.
                prod0 := or(prod0, mul(prod1, add(div(sub(0, twos), twos), 1)))
                // Invert denominator mod 2**256
                // Now that denominator is an odd number, it has an inverse
                // modulo 2**256 such that denominator * inv = 1 mod 2**256.
                // Compute the inverse by starting with a seed that is correct
                // correct for four bits. That is, denominator * inv = 1 mod 2**4
                let inv := xor(mul(3, denominator), 2)
                // Now use Newton-Raphson iteration to improve the precision.
                // Thanks to Hensel's lifting lemma, this also works in modular
                // arithmetic, doubling the correct bits in each step.
                inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**8
                inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**16
                inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**32
                inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**64
                inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**128
                result := mul(prod0, mul(inv, sub(2, mul(denominator, inv)))) // inverse mod 2**256
                break
            }
        }
    }

    /// @dev Calculates floor(a × b ÷ denominator) with full precision, rounded up.
    /// Throws if result overflows a uint256 or when the denominator is zero.
    /// Credit to Uniswap-v3-core under MIT license:
    /// https://github.com/Uniswap/v3-core/blob/contracts/libraries/FullMath.sol
    function fullMulDivUp(uint256 a, uint256 b, uint256 denominator)
        internal
        pure
        returns (uint256 result)
    {
        result = fullMulDiv(a, b, denominator);
        /// @solidity memory-safe-assembly
        assembly {
            if mulmod(a, b, denominator) {
                if iszero(add(result, 1)) {
                    // Store the function selector of `FullMulDivFailed()`.
                    mstore(0x00, 0xae47f702)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }
                result := add(result, 1)
            }
        }
    }

    /// @dev Returns `floor(x * y / denominator)`.
    /// Reverts if `x * y` overflows, or `denominator` is zero.
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(not(0), y)))))) {
                // Store the function selector of `MulDivFailed()`.
                mstore(0x00, 0xad251c27)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := div(mul(x, y), denominator)
        }
    }

    /// @dev Returns `ceil(x * y / denominator)`.
    /// Reverts if `x * y` overflows, or `denominator` is zero.
    function mulDivUp(uint256 x, uint256 y, uint256 denominator)
        internal
        pure
        returns (uint256 z)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(not(0), y)))))) {
                // Store the function selector of `MulDivFailed()`.
                mstore(0x00, 0xad251c27)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(mul(x, y), denominator))), div(mul(x, y), denominator))
        }
    }

    /// @dev Returns `ceil(x / denominator)`.
    /// Reverts if `denominator` is zero.
    function divUp(uint256 x, uint256 denominator) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(denominator) {
                // Store the function selector of `DivFailed()`.
                mstore(0x00, 0x65244e4e)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(x, denominator))), div(x, denominator))
        }
    }

    /// @dev Returns `max(0, x - y)`.
    function zeroFloorSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mul(gt(x, y), sub(x, y))
        }
    }

    /// @dev Returns the square root of `x`.
    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // `floor(sqrt(2**15)) = 181`. `sqrt(2**15) - 181 = 2.84`.
            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // Let `y = x / 2**r`.
            // We check `y >= 2**(k + 8)` but shift right by `k` bits
            // each branch to ensure that if `x >= 256`, then `y >= 256`.
            let r := shl(7, lt(0xffffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffffff, shr(r, x))))
            z := shl(shr(1, r), z)

            // Goal was to get `z*z*y` within a small factor of `x`. More iterations could
            // get y in a tighter range. Currently, we will have y in `[256, 256*(2**16))`.
            // We ensured `y >= 256` so that the relative difference between `y` and `y+1` is small.
            // That's not possible if `x < 256` but we can just verify those cases exhaustively.

            // Now, `z*z*y <= x < z*z*(y+1)`, and `y <= 2**(16+8)`, and either `y >= 256`, or `x < 256`.
            // Correctness can be checked exhaustively for `x < 256`, so we assume `y >= 256`.
            // Then `z*sqrt(y)` is within `sqrt(257)/sqrt(256)` of `sqrt(x)`, or about 20bps.

            // For `s` in the range `[1/256, 256]`, the estimate `f(s) = (181/1024) * (s+1)`
            // is in the range `(1/2.84 * sqrt(s), 2.84 * sqrt(s))`,
            // with largest error when `s = 1` and when `s = 256` or `1/256`.

            // Since `y` is in `[256, 256*(2**16))`, let `a = y/65536`, so that `a` is in `[1/256, 256)`.
            // Then we can estimate `sqrt(y)` using
            // `sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2**18`.

            // There is no overflow risk here since `y < 2**136` after the first branch above.
            z := shr(18, mul(z, add(shr(r, x), 65536))) // A `mul()` is saved from starting `z` at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If `x+1` is a perfect square, the Babylonian method cycles between
            // `floor(sqrt(x))` and `ceil(sqrt(x))`. This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    /// @dev Returns the factorial of `x`.
    function factorial(uint256 x) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            for {} 1 {} {
                if iszero(lt(10, x)) {
                    // forgefmt: disable-next-item
                    result := and(
                        shr(mul(22, x), 0x375f0016260009d80004ec0002d00001e0000180000180000200000400001),
                        0x3fffff
                    )
                    break
                }
                if iszero(lt(57, x)) {
                    let end := 31
                    result := 8222838654177922817725562880000000
                    if iszero(lt(end, x)) {
                        end := 10
                        result := 3628800
                    }
                    for { let w := not(0) } 1 {} {
                        result := mul(result, x)
                        x := add(x, w)
                        if eq(x, end) { break }
                    }
                    break
                }
                // Store the function selector of `FactorialOverflow()`.
                mstore(0x00, 0xaba0f2a2)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Returns the log2 of `x`.
    /// Equivalent to computing the index of the most significant bit (MSB) of `x`.
    function log2(uint256 x) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(x) {
                // Store the function selector of `Log2Undefined()`.
                mstore(0x00, 0x5be3aa5c)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))

            // For the remaining 32 bits, use a De Bruijn lookup.
            // See: https://graphics.stanford.edu/~seander/bithacks.html
            x := shr(r, x)
            x := or(x, shr(1, x))
            x := or(x, shr(2, x))
            x := or(x, shr(4, x))
            x := or(x, shr(8, x))
            x := or(x, shr(16, x))

            // forgefmt: disable-next-item
            r := or(r, byte(shr(251, mul(x, shl(224, 0x07c4acdd))),
                0x0009010a0d15021d0b0e10121619031e080c141c0f111807131b17061a05041f))
        }
    }

    /// @dev Returns the log2 of `x`, rounded up.
    function log2Up(uint256 x) internal pure returns (uint256 r) {
        unchecked {
            uint256 isNotPo2;
            assembly {
                isNotPo2 := iszero(iszero(and(x, sub(x, 1))))
            }
            return log2(x) + isNotPo2;
        }
    }

    /// @dev Returns the averege of `x` and `y`.
    function avg(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := add(and(x, y), shr(1, xor(x, y)))
        }
    }

    /// @dev Returns the absolute value of `x`.
    function abs(int256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let mask := mul(shr(255, x), not(0))
            z := xor(mask, add(mask, x))
        }
    }

    /// @dev Returns the absolute distance between `x` and `y`.
    function dist(int256 x, int256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let a := sub(y, x)
            z := xor(a, mul(xor(a, sub(x, y)), sgt(x, y)))
        }
    }

    /// @dev Returns the minimum of `x` and `y`.
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), lt(y, x)))
        }
    }

    /// @dev Returns the maximum of `x` and `y`.
    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), gt(y, x)))
        }
    }

    /// @dev Returns gcd of `x` and `y`.
    function gcd(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // forgefmt: disable-next-item
            for { z := x } y {} {
                let t := y
                y := mod(z, y)
                z := t
            }
        }
    }

    /// @dev Returns `x`, bounded to `minValue` and `maxValue`.
    function clamp(uint256 x, uint256 minValue, uint256 maxValue)
        internal
        pure
        returns (uint256 z)
    {
        return min(max(x, minValue), maxValue);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Gas optimized verification of proof of inclusion for a leaf in a Merkle tree.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/MerkleProofLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/MerkleProofLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/MerkleProof.sol)
library MerkleProofLib {
    /// @dev Returns whether `leaf` exists in the Merkle tree with `root`, given `proof`.
    function verify(bytes32[] calldata proof, bytes32 root, bytes32 leaf)
        internal
        pure
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            if proof.length {
                // Left shift by 5 is equivalent to multiplying by 0x20.
                let end := add(proof.offset, shl(5, proof.length))
                // Initialize `offset` to the offset of `proof` in the calldata.
                let offset := proof.offset
                // Iterate over proof elements to compute root hash.
                for {} 1 {} {
                    // Slot of `leaf` in scratch space.
                    // If the condition is true: 0x20, otherwise: 0x00.
                    let scratch := shl(5, gt(leaf, calldataload(offset)))
                    // Store elements to hash contiguously in scratch space.
                    // Scratch space is 64 bytes (0x00 - 0x3f) and both elements are 32 bytes.
                    mstore(scratch, leaf)
                    mstore(xor(scratch, 0x20), calldataload(offset))
                    // Reuse `leaf` to store the hash to reduce stack operations.
                    leaf := keccak256(0x00, 0x40)
                    offset := add(offset, 0x20)
                    if iszero(lt(offset, end)) { break }
                }
            }
            isValid := eq(leaf, root)
        }
    }

    /// @dev Returns whether all `leafs` exist in the Merkle tree with `root`,
    /// given `proof` and `flags`.
    function verifyMultiProof(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32[] calldata leafs,
        bool[] calldata flags
    ) internal pure returns (bool isValid) {
        // Rebuilds the root by consuming and producing values on a queue.
        // The queue starts with the `leafs` array, and goes into a `hashes` array.
        // After the process, the last element on the queue is verified
        // to be equal to the `root`.
        //
        // The `flags` array denotes whether the sibling
        // should be popped from the queue (`flag == true`), or
        // should be popped from the `proof` (`flag == false`).
        /// @solidity memory-safe-assembly
        assembly {
            // If the number of flags is correct.
            for {} eq(add(leafs.length, proof.length), add(flags.length, 1)) {} {
                // For the case where `proof.length + leafs.length == 1`.
                if iszero(flags.length) {
                    // `isValid = (proof.length == 1 ? proof[0] : leafs[0]) == root`.
                    // forgefmt: disable-next-item
                    isValid := eq(
                        calldataload(
                            xor(leafs.offset, mul(xor(proof.offset, leafs.offset), proof.length))
                        ),
                        root
                    )
                    break
                }

                // We can use the free memory space for the queue.
                // We don't need to allocate, since the queue is temporary.
                let hashesFront := mload(0x40)
                // Copy the leafs into the hashes.
                // Sometimes, a little memory expansion costs less than branching.
                // Should cost less, even with a high free memory offset of 0x7d00.
                // Left shift by 5 is equivalent to multiplying by 0x20.
                calldatacopy(hashesFront, leafs.offset, shl(5, leafs.length))
                // Compute the back of the hashes.
                let hashesBack := add(hashesFront, shl(5, leafs.length))
                // This is the end of the memory for the queue.
                // We recycle `flags.length` to save on stack variables
                // (this trick may not always save gas).
                flags.length := add(hashesBack, shl(5, flags.length))

                // We don't need to make a copy of `proof.offset` or `flags.offset`,
                // as they are pass-by-value (this trick may not always save gas).

                for {} 1 {} {
                    // Pop from `hashes`.
                    let a := mload(hashesFront)
                    // Pop from `hashes`.
                    let b := mload(add(hashesFront, 0x20))
                    hashesFront := add(hashesFront, 0x40)

                    // If the flag is false, load the next proof,
                    // else, pops from the queue.
                    if iszero(calldataload(flags.offset)) {
                        // Loads the next proof.
                        b := calldataload(proof.offset)
                        proof.offset := add(proof.offset, 0x20)
                        // Unpop from `hashes`.
                        hashesFront := sub(hashesFront, 0x20)
                    }

                    // Advance to the next flag offset.
                    flags.offset := add(flags.offset, 0x20)

                    // Slot of `a` in scratch space.
                    // If the condition is true: 0x20, otherwise: 0x00.
                    let scratch := shl(5, gt(a, b))
                    // Hash the scratch space and push the result onto the queue.
                    mstore(scratch, a)
                    mstore(xor(scratch, 0x20), b)
                    mstore(hashesBack, keccak256(0x00, 0x40))
                    hashesBack := add(hashesBack, 0x20)
                    if iszero(lt(hashesBack, flags.length)) { break }
                }
                // Checks if the last value in the queue is same as the root.
                isValid := eq(mload(sub(hashesBack, 0x20)), root)
                break
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Caution! This library won't check that a token has code, responsibility is delegated to the caller.
library SafeTransferLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ETH transfer has failed.
    error ETHTransferFailed();

    /// @dev The ERC20 `transferFrom` has failed.
    error TransferFromFailed();

    /// @dev The ERC20 `transfer` has failed.
    error TransferFailed();

    /// @dev The ERC20 `approve` has failed.
    error ApproveFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Suggested gas stipend for contract receiving ETH
    /// that disallows any storage writes.
    uint256 internal constant _GAS_STIPEND_NO_STORAGE_WRITES = 2300;

    /// @dev Suggested gas stipend for contract receiving ETH to perform a few
    /// storage reads and writes, but low enough to prevent griefing.
    /// Multiply by a small constant (e.g. 2), if needed.
    uint256 internal constant _GAS_STIPEND_NO_GRIEF = 100000;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ETH OPERATIONS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sends `amount` (in wei) ETH to `to`.
    /// Reverts upon failure.
    function safeTransferETH(address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gas(), to, amount, 0, 0, 0, 0)) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    /// The `gasStipend` can be set to a low enough value to prevent
    /// storage writes or gas griefing.
    ///
    /// If sending via the normal procedure fails, force sends the ETH by
    /// creating a temporary contract which uses `SELFDESTRUCT` to force send the ETH.
    ///
    /// Reverts if the current contract has insufficient balance.
    function forceSafeTransferETH(address to, uint256 amount, uint256 gasStipend) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // If insufficient balance, revert.
            if lt(selfbalance(), amount) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gasStipend, to, amount, 0, 0, 0, 0)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                // We can directly use `SELFDESTRUCT` in the contract creation.
                // We don't check and revert upon failure here, just in case
                // `SELFDESTRUCT`'s behavior is changed some day in the future.
                // (If that ever happens, we will riot, and port the code to use WETH).
                pop(create(amount, 0x0b, 0x16))
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a gas stipend
    /// equal to `_GAS_STIPEND_NO_GRIEF`. This gas stipend is a reasonable default
    /// for 99% of cases and can be overriden with the three-argument version of this
    /// function if necessary.
    ///
    /// If sending via the normal procedure fails, force sends the ETH by
    /// creating a temporary contract which uses `SELFDESTRUCT` to force send the ETH.
    ///
    /// Reverts if the current contract has insufficient balance.
    function forceSafeTransferETH(address to, uint256 amount) internal {
        // Manually inlined because the compiler doesn't inline functions with branches.
        /// @solidity memory-safe-assembly
        assembly {
            // If insufficient balance, revert.
            if lt(selfbalance(), amount) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(_GAS_STIPEND_NO_GRIEF, to, amount, 0, 0, 0, 0)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                // We can directly use `SELFDESTRUCT` in the contract creation.
                // We don't check and revert upon failure here, just in case
                // `SELFDESTRUCT`'s behavior is changed some day in the future.
                // (If that ever happens, we will riot, and port the code to use WETH).
                pop(create(amount, 0x0b, 0x16))
            }
        }
    }

    /// @dev Sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    /// The `gasStipend` can be set to a low enough value to prevent
    /// storage writes or gas griefing.
    ///
    /// Simply use `gasleft()` for `gasStipend` if you don't need a gas stipend.
    ///
    /// Note: Does NOT revert upon failure.
    /// Returns whether the transfer of ETH is successful instead.
    function trySafeTransferETH(address to, uint256 amount, uint256 gasStipend)
        internal
        returns (bool success)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            success := call(gasStipend, to, amount, 0, 0, 0, 0)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      ERC20 OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sends `amount` of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have at least `amount` approved for
    /// the current contract to manage.
    function safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0x00, 0x23b872dd)
            mstore(0x20, from) // Append the "from" argument.
            mstore(0x40, to) // Append the "to" argument.
            mstore(0x60, amount) // Append the "amount" argument.

            if iszero(
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    // We use 0x64 because that's the total length of our calldata (0x04 + 0x20 * 3)
                    // Counterintuitively, this call() must be positioned after the or() in the
                    // surrounding and() because and() evaluates its arguments from right to left.
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransfer(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0x00, 0xa9059cbb)
            mstore(0x20, to) // Append the "to" argument.
            mstore(0x40, amount) // Append the "amount" argument.

            if iszero(
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    // We use 0x44 because that's the total length of our calldata (0x04 + 0x20 * 2)
                    // Counterintuitively, this call() must be positioned after the or() in the
                    // surrounding and() because and() evaluates its arguments from right to left.
                    call(gas(), token, 0, 0x1c, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x40, memPointer) // Restore the memPointer.
        }
    }

    /// @dev Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract.
    /// Reverts upon failure.
    function safeApprove(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0x00, 0x095ea7b3)
            mstore(0x20, to) // Append the "to" argument.
            mstore(0x40, amount) // Append the "amount" argument.

            if iszero(
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    // We use 0x44 because that's the total length of our calldata (0x04 + 0x20 * 2)
                    // Counterintuitively, this call() must be positioned after the or() in the
                    // surrounding and() because and() evaluates its arguments from right to left.
                    call(gas(), token, 0, 0x1c, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `ApproveFailed()`.
                mstore(0x00, 0x3e3f8f73)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x40, memPointer) // Restore the memPointer.
        }
    }
}