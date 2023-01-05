// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/*
                 ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
               ▒███████████████████████████████████████████████████████████
               ▒███████████████████████████████████████████████████████████
 ▒▓▓▓▓▓▓▓▓▓▓▓▓▓████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓██████████████████████████████▓▒▒▒▒▒▒▒▒▒▒▒▒▒
 █████████████████████████████▓              ████████████████████████████████████████████
 █████████████████████████████▓              ████████████████████████████████████████████
 █████████████████████████████▓               ▒▒▒▒▒▒▒▒▒▒▒▒▒██████████████████████████████
 █████████████████████████████▓                            ▒█████████████████████████████
 █████████████████████████████▓                             ▒████████████████████████████
 █████████████████████████████████████████████████████████▓
 ███████████████████████████████████████████████████████████
 ███████████████████████████████████████████████████████████▒
                              ███████████████████████████████████████████████████████████▒
                              ▓██████████████████████████████████████████████████████████▒
                               ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓███████████████████████████████▒
 █████████████████████████████                             ▒█████████████████████████████▒
 ██████████████████████████████                            ▒█████████████████████████████▒
 ██████████████████████████████▓▒▒▒▒▒▒▒▒▒▒▒▒▒              ▒█████████████████████████████▒
 ████████████████████████████████████████████▒             ▒█████████████████████████████▒
 ████████████████████████████████████████████▒             ▒█████████████████████████████▒
 ▒▒▒▒▒▒▒▒▒▒▒▒▒▒███████████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓███████████████▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒
               ▓█████████████████████████████████████████████████████████▒
               ▓██████████████████████████████████████████████████████████
*/

import { Clones } from "openzeppelin/proxy/Clones.sol";

import { ISoundCreatorV1 } from "./interfaces/ISoundCreatorV1.sol";
import { ISoundEditionV1_1 } from "./interfaces/ISoundEditionV1_1.sol";
import { IMetadataModule } from "./interfaces/IMetadataModule.sol";

import { OwnableRoles } from "solady/auth/OwnableRoles.sol";

/**
 * @title SoundCreatorV1
 * @notice A factory that deploys minimal proxies of `SoundEditionV1_1.sol`.
 * @dev The proxies are OpenZeppelin's Clones implementation of https://eips.ethereum.org/EIPS/eip-1167
 */
contract SoundCreatorV1 is ISoundCreatorV1, OwnableRoles {
    // =============================================================
    //                            STORAGE
    // =============================================================

    /**
     * @dev The implementation contract delegated to by Sound edition proxies.
     */
    address public soundEditionImplementation;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor(address _soundEditionImplementation) implementationNotZero(_soundEditionImplementation) {
        soundEditionImplementation = _soundEditionImplementation;
        _initializeOwner(msg.sender);
    }

    // =============================================================
    //               PUBLIC / EXTERNAL WRITE FUNCTIONS
    // =============================================================

    /**
     * @inheritdoc ISoundCreatorV1
     */
    function createSoundAndMints(
        bytes32 salt,
        bytes calldata initData,
        address[] calldata contracts,
        bytes[] calldata data
    ) external returns (address soundEdition, bytes[] memory results) {
        // Create Sound Edition proxy.
        soundEdition = payable(Clones.cloneDeterministic(soundEditionImplementation, _saltedSalt(msg.sender, salt)));

        // Initialize proxy.
        assembly {
            // Grab the free memory pointer.
            let m := mload(0x40)
            // Copy the `initData` to the free memory.
            calldatacopy(m, initData.offset, initData.length)
            // Call the initializer, and revert if the call fails.
            if iszero(
                call(
                    gas(), // Gas remaining.
                    soundEdition, // Address of the edition.
                    0, // `msg.value` of the call: 0 ETH.
                    m, // Start of input.
                    initData.length, // Length of input.
                    0x00, // Start of output. Not used.
                    0x00 // Size of output. Not used.
                )
            ) {
                // Bubble up the revert if the call reverts.
                returndatacopy(0x00, 0x00, returndatasize())
                revert(0x00, returndatasize())
            }
        }

        results = _callContracts(contracts, data);

        OwnableRoles(soundEdition).transferOwnership(msg.sender);

        emit SoundEditionCreated(soundEdition, msg.sender, initData, contracts, data, results);
    }

    /**
     * @inheritdoc ISoundCreatorV1
     */
    function setEditionImplementation(address newImplementation)
        external
        onlyOwner
        implementationNotZero(newImplementation)
    {
        soundEditionImplementation = newImplementation;

        emit SoundEditionImplementationSet(soundEditionImplementation);
    }

    // =============================================================
    //               PUBLIC / EXTERNAL VIEW FUNCTIONS
    // =============================================================

    /**
     * @inheritdoc ISoundCreatorV1
     */
    function soundEditionAddress(address by, bytes32 salt) external view returns (address addr, bool exists) {
        addr = Clones.predictDeterministicAddress(soundEditionImplementation, _saltedSalt(by, salt), address(this));
        exists = addr.code.length > 0;
    }

    // =============================================================
    //                  INTERNAL / PRIVATE HELPERS
    // =============================================================

    /**
     * @dev Call the `contracts` in order with `data`.
     * @param contracts The addresses of the contracts.
     * @param data      The `abi.encodeWithSelector` calldata for each of the contracts.
     * @return results The results of calling the contracts.
     */
    function _callContracts(address[] calldata contracts, bytes[] calldata data)
        internal
        returns (bytes[] memory results)
    {
        if (contracts.length != data.length) revert ArrayLengthsMismatch();

        assembly {
            // Grab the free memory pointer.
            // We will use the free memory to construct the `results` array,
            // and also as a temporary space for the calldata.
            results := mload(0x40)
            // Set `results.length` to be equal to `data.length`.
            mstore(results, data.length)
            // Skip the first word, which is used to store the length
            let resultsOffsets := add(results, 0x20)
            // Compute the location of the last calldata offset in `data`.
            // `shl(5, n)` is a gas-saving shorthand for `mul(0x20, n)`.
            let dataOffsetsEnd := add(data.offset, shl(5, data.length))
            // This is the start of the unused free memory.
            // We use it to temporarily store the calldata to call the contracts.
            let m := add(resultsOffsets, shl(5, data.length))

            // Loop through `contacts` and `data` together.
            // prettier-ignore
            for { let i := data.offset } iszero(eq(i, dataOffsetsEnd)) { i := add(i, 0x20) } {
                // Location of `bytes[i]` in calldata.
                let o := add(data.offset, calldataload(i))
                // Copy `bytes[i]` from calldata to the free memory.
                calldatacopy(
                    m, // Start of the unused free memory.
                    add(o, 0x20), // Location of starting byte of `data[i]` in calldata.
                    calldataload(o) // The length of the `bytes[i]`.
                )
                // Grab `contracts[i]` from the calldata.
                // As `contracts` is the same length as `data`,
                // `sub(i, data.offset)` gives the relative offset to apply to
                // `contracts.offset` for `contracts[i]` to match `data[i]`.
                let c := calldataload(add(contracts.offset, sub(i, data.offset)))
                // Call the contract, and revert if the call fails.
                if iszero(
                    call(
                        gas(), // Gas remaining.
                        c, // `contracts[i]`.
                        0, // `msg.value` of the call: 0 ETH.
                        m, // Start of the copy of `bytes[i]` in memory.
                        calldataload(o), // The length of the `bytes[i]`.
                        0x00, // Start of output. Not used.
                        0x00 // Size of output. Not used.
                    )
                ) {
                    // Bubble up the revert if the call reverts.
                    returndatacopy(0x00, 0x00, returndatasize())
                    revert(0x00, returndatasize())
                }
                // Append the current `m` into `resultsOffsets`.
                mstore(resultsOffsets, m)
                resultsOffsets := add(resultsOffsets, 0x20)

                // Append the `returndatasize()` to `results`.
                mstore(m, returndatasize())
                // Append the return data to `results`.
                returndatacopy(add(m, 0x20), 0x00, returndatasize())
                // Advance `m` by `returndatasize() + 0x20`,
                // rounded up to the next multiple of 32.
                // `0x3f = 32 + 31`. The mask is `type(uint64).max & ~31`,
                // which is big enough for all purposes (see memory expansion costs).
                m := and(add(add(m, returndatasize()), 0x3f), 0xffffffffffffffe0)
            }
            // Allocate the memory for `results` by updating the free memory pointer.
            mstore(0x40, m)
        }
    }

    /**
     * @dev Returns the salted salt.
     *      To prevent griefing and accidental collisions from clients that don't
     *      generate their salt properly.
     * @param by   The caller of the {createSoundAndMints} function.
     * @param salt The salt, generated on the client side.
     * @return result The computed value.
     */
    function _saltedSalt(address by, bytes32 salt) internal pure returns (bytes32 result) {
        assembly {
            // Store the variables into the scratch space.
            mstore(0x00, by)
            mstore(0x20, salt)
            // Equivalent to `keccak256(abi.encode(by, salt))`.
            result := keccak256(0x00, 0x40)
        }
    }

    /**
     * @dev Reverts if the given implementation address is zero.
     * @param implementation The address of the implementation.
     */
    modifier implementationNotZero(address implementation) {
        if (implementation == address(0)) {
            revert ImplementationAddressCantBeZero();
        }
        _;
    }
}

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

import { IMetadataModule } from "./IMetadataModule.sol";

/**
 * @title ISoundCreatorV1
 * @notice The interface for the Sound edition factory.
 */
interface ISoundCreatorV1 {
    // =============================================================
    //                            EVENTS
    // =============================================================

    /**
     * @dev Emitted when an edition is created.
     * @param soundEdition The address of the edition.
     * @param deployer     The address of the deployer.
     * @param initData     The calldata to initialize SoundEdition via `abi.encodeWithSelector`.
     * @param contracts    The list of contracts called.
     * @param data         The list of calldata created via `abi.encodeWithSelector`
     * @param results      The results of calling the contracts. Use `abi.decode` to decode them.
     */
    event SoundEditionCreated(
        address indexed soundEdition,
        address indexed deployer,
        bytes initData,
        address[] contracts,
        bytes[] data,
        bytes[] results
    );

    /**
     * @dev Emitted when the edition implementation address is set.
     * @param newImplementation The new implementation address to be set.
     */
    event SoundEditionImplementationSet(address newImplementation);

    // =============================================================
    //                            ERRORS
    // =============================================================

    /**
     * @dev Thrown if the implementation address is zero.
     */
    error ImplementationAddressCantBeZero();

    /**
     * @dev Thrown if the lengths of the input arrays are not equal.
     */
    error ArrayLengthsMismatch();

    // =============================================================
    //               PUBLIC / EXTERNAL WRITE FUNCTIONS
    // =============================================================

    /**
     * @dev Creates a Sound Edition proxy, initializes it,
     *      and creates mint configurations on a given set of minter addresses.
     * @param salt      The salt used for the CREATE2 to deploy the clone to a
     *                  deterministic address.
     * @param initData  The calldata to initialize SoundEdition via
     *                  `abi.encodeWithSelector`.
     * @param contracts A list of contracts to call.
     * @param data      A list of calldata created via `abi.encodeWithSelector`
     *                  This must contain the same number of entries as `contracts`.
     * @return soundEdition Returns the address of the created contract.
     * @return results      The results of calling the contracts.
     *                      Use `abi.decode` to decode them.
     */
    function createSoundAndMints(
        bytes32 salt,
        bytes calldata initData,
        address[] calldata contracts,
        bytes[] calldata data
    ) external returns (address soundEdition, bytes[] memory results);

    /**
     * @dev Changes the SoundEdition implementation contract address.
     *
     * Calling conditions:
     * - The caller must be the owner of the contract.
     *
     * @param newImplementation The new implementation address to be set.
     */
    function setEditionImplementation(address newImplementation) external;

    // =============================================================
    //               PUBLIC / EXTERNAL VIEW FUNCTIONS
    // =============================================================

    /**
     * @dev The address of the sound edition implementation.
     * @return The configured value.
     */
    function soundEditionImplementation() external returns (address);

    /**
     * @dev Returns the deterministic address for the sound edition clone.
     * @param by   The caller of the {createSoundAndMints} function.
     * @param salt The salt, generated on the client side.
     * @return addr The computed address.
     * @return exists Whether the contract exists.
     */
    function soundEditionAddress(address by, bytes32 salt) external view returns (address addr, bool exists);
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
 * @title ISoundEditionV1_1
 * @notice The interface for Sound edition contracts.
 */
interface ISoundEditionV1_1 is IERC721AUpgradeable, IERC2981Upgradeable {
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
     * @dev Emitted when the `operatorFilteringEnabled` is set.
     * @param operatorFilteringEnabled_ The boolean value.
     */
    event OperatorFilteringEnablededSet(bool operatorFilteringEnabled_);

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

    /**
     * @dev Sets whether OpenSea operator filtering is enabled.
     *
     * Calling conditions:
     * - The caller must be the owner of the contract, or have the `ADMIN_ROLE`.
     *
     * @param operatorFilteringEnabled_ The boolean value.
     */
    function setOperatorFilteringEnabled(bool operatorFilteringEnabled_) external;

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
     * @dev Returns the bit flag to enable OpenSea operator filtering.
     * @return The constant value.
     */
    function OPERATOR_FILTERING_ENABLED_FLAG() external pure returns (uint8);

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
     * @dev Returns whether the `operatorFilteringEnabled` has been enabled.
     * @return The configured value.
     */
    function operatorFilteringEnabled() external view returns (bool);

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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
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