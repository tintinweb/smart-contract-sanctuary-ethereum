// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.19;

// Created By: Art Blocks Inc.

import "../../interfaces/v0.8.x/IRandomizer_V3CoreBase.sol";
import "../../interfaces/v0.8.x/IAdminACLV0.sol";
import "../../interfaces/v0.8.x/IEngineRegistryV0.sol";
import "../../interfaces/v0.8.x/IGenArt721CoreContractV3_Engine_Flex.sol";
import "../../interfaces/v0.8.x/IGenArt721CoreContractExposesHashSeed.sol";
import "../../interfaces/v0.8.x/IDependencyRegistryCompatibleV0.sol";
import "../../interfaces/v0.8.x/IManifold.sol";

import "@openzeppelin-4.7/contracts/access/Ownable.sol";
import "../../libs/v0.8.x/ERC721_PackedHashSeed.sol";
import "../../libs/v0.8.x/BytecodeStorageV1.sol";
import "../../libs/v0.8.x/Bytes32Strings.sol";

/**
 * @title Art Blocks Engine Flex ERC-721 core contract, V3.
 * @author Art Blocks Inc.
 * @notice Privileged Roles and Ownership:
 * This contract is designed to be managed, with progressively limited powers
 * as a project progresses from active to locked.
 * Privileged roles and abilities are controlled by the admin ACL contract and
 * artists. Both of these roles hold extensive power and can arbitrarily
 * control and modify portions of projects, dependent upon project state. After
 * a project is locked, important project metadata fields are locked including
 * the project name, artist name, and script and display details. Edition size
 * can never be increased.
 * Care must be taken to ensure that the admin ACL contract and artist
 * addresses are secure behind a multi-sig or other access control mechanism.
 * ----------------------------------------------------------------------------
 * The following functions are restricted to the Admin ACL contract:
 * - updateArtblocksDependencyRegistryAddress
 * - updateProviderSalesAddresses
 * - updateProviderPrimarySalesPercentages (up to 100%)
 * - updateProviderSecondarySalesBPS (up to 100%)
 * - updateMinterContract
 * - updateRandomizerAddress
 * - toggleProjectIsActive
 * - addProject
 * - forbidNewProjects (forever forbidding new projects)
 * - updateDefaultBaseURI (used to initialize new project base URIs)
 * - updateIPFSGateway
 * - updateArweaveGateway
 * ----------------------------------------------------------------------------
 * The following functions are restricted to either the the Artist address or
 * the Admin ACL contract, only when the project is not locked:
 * - updateProjectName
 * - updateProjectArtistName
 * - updateProjectLicense
 * - Change project script via addProjectScript, updateProjectScript,
 *   and removeProjectLastScript
 * - updateProjectScriptType
 * - updateProjectAspectRatio
 * ----------------------------------------------------------------------------
 * The following functions are restricted to only the Artist address:
 * - proposeArtistPaymentAddressesAndSplits (Note that this has to be accepted
 *   by adminAcceptArtistAddressesAndSplits to take effect, which is restricted
 *   to the Admin ACL contract, or the artist if the core contract owner has
 *   renounced ownership. Also note that a proposal will be automatically
 *   accepted if the artist only proposes changed payee percentages without
 *   modifying any payee addresses, or is only removing payee addresses, or
 *   if the global config `autoApproveArtistSplitProposals` is set to `true`.)
 * - toggleProjectIsPaused (note the artist can still mint while paused)
 * - updateProjectSecondaryMarketRoyaltyPercentage (up to
     ARTIST_MAX_SECONDARY_ROYALTY_PERCENTAGE percent)
 * - updateProjectWebsite
 * - updateProjectMaxInvocations (to a number greater than or equal to the
 *   current number of invocations, and less than current project maximum
 *   invocations)
 * - updateProjectBaseURI (controlling the base URI for tokens in the project)
 * ----------------------------------------------------------------------------
 * The following function is restricted to either the Admin ACL contract, or
 * the Artist address if the core contract owner has renounced ownership:
 * - adminAcceptArtistAddressesAndSplits
 * - updateProjectArtistAddress (owner ultimately controlling the project and
 *   its and-on revenue, unless owner has renounced ownership)
 * ----------------------------------------------------------------------------
 * The following function is restricted to the artist when a project is
 * unlocked, and only callable by Admin ACL contract when a project is locked:
 * - updateProjectDescription
 * ----------------------------------------------------------------------------
 * The following functions for managing external asset dependencies are restricted
 * to projects with external asset dependencies that are unlocked:
 * - lockProjectExternalAssetDependencies 
 * - updateProjectExternalAssetDependency
 * - removeProjectExternalAssetDependency
 * - addProjectExternalAssetDependency
 * ----------------------------------------------------------------------------
 * The following function is restricted to owner calling directly:
 * - transferOwnership
 * - renounceOwnership
 * ----------------------------------------------------------------------------
 * The following configuration variables are set at time of contract deployment,
 * and not modifiable thereafter (immutable after the point of deployment):
 * - (bool) autoApproveArtistSplitProposals
 * ----------------------------------------------------------------------------
 * Additional admin and artist privileged roles may be described on minters,
 * registries, and other contracts that may interact with this core contract.
 */
contract GenArt721CoreV3_Engine_Flex is
    ERC721_PackedHashSeed,
    Ownable,
    IDependencyRegistryCompatibleV0,
    IManifold,
    IGenArt721CoreContractV3_Engine_Flex,
    IGenArt721CoreContractExposesHashSeed
{
    using BytecodeStorageWriter for string;
    using Bytes32Strings for bytes32;
    uint256 constant ONE_HUNDRED = 100;
    uint256 constant ONE_MILLION = 1_000_000;
    uint24 constant ONE_MILLION_UINT24 = 1_000_000;
    uint256 constant FOUR_WEEKS_IN_SECONDS = 2_419_200;
    uint8 constant AT_CHARACTER_CODE = uint8(bytes1("@")); // 0x40

    // numeric constants
    uint256 constant MAX_PROVIDER_SECONDARY_SALES_BPS = 10000; // 10_000 BPS = 100%
    uint256 constant ARTIST_MAX_SECONDARY_ROYALTY_PERCENTAGE = 95; // 95%

    // This contract emits generic events that contain fields that indicate
    // which parameter has been updated. This is sufficient for application
    // state management, while also simplifying the contract and indexing code.
    // This was done as an alternative to having custom events that emit what
    // field-values have changed for each event, given that changed values can
    // be introspected by indexers due to the design of this smart contract
    // exposing these state changes via publicly viewable fields.
    //
    // The following fields are used to indicate which contract-level parameter
    // has been updated in the `PlatformUpdated` event:
    bytes32 constant FIELD_NEXT_PROJECT_ID = "nextProjectId";
    bytes32 constant FIELD_NEW_PROJECTS_FORBIDDEN = "newProjectsForbidden";
    bytes32 constant FIELD_DEFAULT_BASE_URI = "defaultBaseURI";
    bytes32 constant FIELD_RANDOMIZER_ADDRESS = "randomizerAddress";
    bytes32 constant FIELD_ARTBLOCKS_DEPENDENCY_REGISTRY_ADDRESS =
        "dependencyRegistryAddress";
    bytes32 constant FIELD_PROVIDER_SALES_ADDRESSES = "providerSalesAddresses";
    bytes32 constant FIELD_PROVIDER_PRIMARY_SALES_PERCENTAGES =
        "providerPrimaryPercentages";
    bytes32 constant FIELD_PROVIDER_SECONDARY_SALES_BPS =
        "providerSecondaryBPS";
    // The following fields are used to indicate which project-level parameter
    // has been updated in the `ProjectUpdated` event:
    bytes32 constant FIELD_PROJECT_COMPLETED = "completed";
    bytes32 constant FIELD_PROJECT_ACTIVE = "active";
    bytes32 constant FIELD_PROJECT_ARTIST_ADDRESS = "artistAddress";
    bytes32 constant FIELD_PROJECT_PAUSED = "paused";
    bytes32 constant FIELD_PROJECT_CREATED = "created";
    bytes32 constant FIELD_PROJECT_NAME = "name";
    bytes32 constant FIELD_PROJECT_ARTIST_NAME = "artistName";
    bytes32 constant FIELD_PROJECT_SECONDARY_MARKET_ROYALTY_PERCENTAGE =
        "royaltyPercentage";
    bytes32 constant FIELD_PROJECT_DESCRIPTION = "description";
    bytes32 constant FIELD_PROJECT_WEBSITE = "website";
    bytes32 constant FIELD_PROJECT_LICENSE = "license";
    bytes32 constant FIELD_PROJECT_MAX_INVOCATIONS = "maxInvocations";
    bytes32 constant FIELD_PROJECT_SCRIPT = "script";
    bytes32 constant FIELD_PROJECT_SCRIPT_TYPE = "scriptType";
    bytes32 constant FIELD_PROJECT_ASPECT_RATIO = "aspectRatio";
    bytes32 constant FIELD_PROJECT_BASE_URI = "baseURI";

    /// Dependency registry managed by Art Blocks
    address public artblocksDependencyRegistryAddress;

    /// current randomizer contract
    IRandomizer_V3CoreBase public randomizerContract;

    /// append-only array of all randomizer contract addresses ever used by
    /// this contract
    address[] private _historicalRandomizerAddresses;

    /// admin ACL contract
    IAdminACLV0 public adminACLContract;

    struct Project {
        uint24 invocations;
        uint24 maxInvocations;
        uint24 scriptCount;
        // max uint64 ~= 1.8e19 sec ~= 570 billion years
        uint64 completedTimestamp;
        bool active;
        bool paused;
        string name;
        string artist;
        address descriptionAddress;
        string website;
        string license;
        string projectBaseURI;
        bytes32 scriptTypeAndVersion;
        string aspectRatio;
        // mapping from script index to address storing script in bytecode
        mapping(uint256 => address) scriptBytecodeAddresses;
        bool externalAssetDependenciesLocked;
        uint24 externalAssetDependencyCount;
        mapping(uint256 => ExternalAssetDependency) externalAssetDependencies;
    }

    mapping(uint256 => Project) projects;

    string public preferredIPFSGateway;
    string public preferredArweaveGateway;

    /// packed struct containing project financial information
    struct ProjectFinance {
        address payable additionalPayeePrimarySales;
        // packed uint: max of 95, max uint8 = 255
        uint8 secondaryMarketRoyaltyPercentage;
        address payable additionalPayeeSecondarySales;
        // packed uint: max of 100, max uint8 = 255
        uint8 additionalPayeeSecondarySalesPercentage;
        address payable artistAddress;
        // packed uint: max of 100, max uint8 = 255
        uint8 additionalPayeePrimarySalesPercentage;
    }
    // Project financials mapping
    mapping(uint256 => ProjectFinance) projectIdToFinancials;

    /// hash of artist's proposed payment updates to be approved by admin
    mapping(uint256 => bytes32) public proposedArtistAddressesAndSplitsHash;

    /// The render provider payment address for all primary sales revenues
    /// (packed)
    address payable public renderProviderPrimarySalesAddress;
    /// Percentage of primary sales revenue allocated to the render provider
    /// (packed)
    // packed uint: max of 100, max uint8 = 255
    uint8 private _renderProviderPrimarySalesPercentage = 10;
    /// The platform provider payment address for all primary sales revenues
    /// (packed)
    address payable public platformProviderPrimarySalesAddress;
    /// Percentage of primary sales revenue allocated to the platform provider
    /// (packed)
    // packed uint: max of 100, max uint8 = 255
    uint8 private _platformProviderPrimarySalesPercentage = 10;

    /// The render provider payment address for all secondary sales royalty
    /// revenues
    address payable public renderProviderSecondarySalesAddress;
    /// Basis Points of secondary sales royalties allocated to the
    /// render provider
    uint256 public renderProviderSecondarySalesBPS = 250;
    /// The platform provider payment address for all secondary sales royalty
    /// revenues
    address payable public platformProviderSecondarySalesAddress;
    /// Basis Points of secondary sales royalties allocated to the
    /// platform provider
    uint256 public platformProviderSecondarySalesBPS = 250;

    /// single minter allowed for this core contract
    address public minterContract;

    /// starting (initial) project ID on this contract
    uint256 public immutable startingProjectId;

    /// next project ID to be created
    uint248 private _nextProjectId;

    /// bool indicating if adding new projects is forbidden;
    /// default behavior is to allow new projects
    bool public newProjectsForbidden;

    /// configuration variable (determined at time of deployment)
    /// that determines whether or not admin approval^ should be required
    /// to accept artist address change proposals, or if these proposals
    /// should always auto-approve, as determined by the business process
    /// requirements of the Engine partner using this contract.
    ///
    /// ^does not apply in the case where contract-ownership itself is revoked
    bool public immutable autoApproveArtistSplitProposals;

    /// version & type of this core contract
    bytes32 constant CORE_VERSION = "v3.1.3";

    function coreVersion() external pure returns (string memory) {
        return CORE_VERSION.toString();
    }

    bytes32 constant CORE_TYPE = "GenArt721CoreV3_Engine_Flex";

    function coreType() external pure returns (string memory) {
        return CORE_TYPE.toString();
    }

    /// default base URI to initialize all new project projectBaseURI values to
    string public defaultBaseURI;

    function _onlyUnlockedProjectExternalAssetDependencies(
        uint256 _projectId
    ) internal view {
        require(
            !projects[_projectId].externalAssetDependenciesLocked,
            "External dependencies locked"
        );
    }

    function _onlyNonZeroAddress(address _address) internal pure {
        require(_address != address(0), "Must input non-zero address");
    }

    function _onlyNonEmptyString(string memory _string) internal pure {
        require(bytes(_string).length != 0, "Must input non-empty string");
    }

    function _onlyValidTokenId(uint256 _tokenId) internal view {
        require(_exists(_tokenId), "Token ID does not exist");
    }

    function _onlyValidProjectId(uint256 _projectId) internal view {
        require(
            (_projectId >= startingProjectId) && (_projectId < _nextProjectId),
            "Project ID does not exist"
        );
    }

    function _onlyUnlocked(uint256 _projectId) internal view {
        // Note: calling `_projectUnlocked` enforces that the `_projectId`
        //       passed in is valid.`
        require(_projectUnlocked(_projectId), "Only if unlocked");
    }

    function _onlyAdminACL(bytes4 _selector) internal {
        require(
            adminACLAllowed(msg.sender, address(this), _selector),
            "Only Admin ACL allowed"
        );
    }

    function _onlyArtist(uint256 _projectId) internal view {
        require(
            msg.sender == projectIdToFinancials[_projectId].artistAddress,
            "Only artist"
        );
    }

    function _onlyArtistOrAdminACL(
        uint256 _projectId,
        bytes4 _selector
    ) internal {
        require(
            msg.sender == projectIdToFinancials[_projectId].artistAddress ||
                adminACLAllowed(msg.sender, address(this), _selector),
            "Only artist or Admin ACL allowed"
        );
    }

    /**
     * This modifier allows the artist of a project to call a function if the
     * owner of the contract has renounced ownership. This is to allow the
     * contract to continue to function if the owner decides to renounce
     * ownership.
     */
    function _onlyAdminACLOrRenouncedArtist(
        uint256 _projectId,
        bytes4 _selector
    ) internal {
        require(
            adminACLAllowed(msg.sender, address(this), _selector) ||
                (owner() == address(0) &&
                    msg.sender ==
                    projectIdToFinancials[_projectId].artistAddress),
            "Only Admin ACL allowed, or artist if owner has renounced"
        );
    }

    /**
     * @notice Initializes contract.
     * @param _tokenName Name of token.
     * @param _tokenSymbol Token symbol.
     * @param _randomizerContract Randomizer contract.
     * @param _adminACLContract Address of admin access control contract, to be
     * set as contract owner.
     * @param _startingProjectId The initial next project ID.
     * @param _autoApproveArtistSplitProposals Whether or not to always
     * auto-approve proposed artist split updates.
     * @dev _startingProjectId should be set to a value much, much less than
     * max(uint248), but an explicit input type of `uint248` is used as it is
     * safer to cast up to `uint256` than it is to cast down for the purposes
     * of setting `_nextProjectId`.
     */
    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        address _renderProviderAddress,
        address _platformProviderAddress,
        address _randomizerContract,
        address _adminACLContract,
        uint248 _startingProjectId,
        bool _autoApproveArtistSplitProposals,
        address _engineRegistryContract
    ) ERC721_PackedHashSeed(_tokenName, _tokenSymbol) {
        _onlyNonZeroAddress(_renderProviderAddress);
        _onlyNonZeroAddress(_platformProviderAddress);
        _onlyNonZeroAddress(_randomizerContract);
        _onlyNonZeroAddress(_adminACLContract);
        // setup immutable `autoApproveArtistSplitProposals` config
        autoApproveArtistSplitProposals = _autoApproveArtistSplitProposals;
        // record contracts starting project ID
        // casting-up is safe
        startingProjectId = uint256(_startingProjectId);
        _updateProviderSalesAddresses(
            _renderProviderAddress,
            _renderProviderAddress,
            _platformProviderAddress,
            _platformProviderAddress
        );
        _updateRandomizerAddress(_randomizerContract);
        // set AdminACL management contract as owner
        _transferOwnership(_adminACLContract);
        // initialize default base URI
        _updateDefaultBaseURI(
            string.concat(
                "https://token.artblocks.io/",
                toHexString(address(this)),
                "/"
            )
        );
        // initialize next project ID
        _nextProjectId = _startingProjectId;
        emit PlatformUpdated(FIELD_NEXT_PROJECT_ID);
        // register contract as an Engine contract
        IEngineRegistryV0(_engineRegistryContract).registerContract(
            address(this),
            CORE_VERSION,
            CORE_TYPE
        );
    }

    /**
     * @notice Updates preferredIPFSGateway to `_gateway`.
     */
    function updateIPFSGateway(string calldata _gateway) public {
        _onlyAdminACL(this.updateIPFSGateway.selector);
        preferredIPFSGateway = _gateway;
        emit GatewayUpdated(ExternalAssetDependencyType.IPFS, _gateway);
    }

    /**
     * @notice Updates preferredArweaveGateway to `_gateway`.
     */
    function updateArweaveGateway(string calldata _gateway) public {
        _onlyAdminACL(this.updateArweaveGateway.selector);
        preferredArweaveGateway = _gateway;
        emit GatewayUpdated(ExternalAssetDependencyType.ARWEAVE, _gateway);
    }

    /**
     * @notice Locks external asset dependencies for project `_projectId`.
     */
    function lockProjectExternalAssetDependencies(uint256 _projectId) external {
        _onlyUnlockedProjectExternalAssetDependencies(_projectId);
        _onlyArtistOrAdminACL(
            _projectId,
            this.lockProjectExternalAssetDependencies.selector
        );
        projects[_projectId].externalAssetDependenciesLocked = true;
        emit ProjectExternalAssetDependenciesLocked(_projectId);
    }

    /**
     * @notice Updates external asset dependency for project `_projectId`.
     * @param _projectId Project to be updated.
     * @param _index Asset index.
     * @param _cidOrData Asset cid (Content identifier) or data string to be translated into bytecode.
     * @param _dependencyType Asset dependency type.
     *  0 - IPFS
     *  1 - ARWEAVE
     *  2 - ONCHAIN
     */
    function updateProjectExternalAssetDependency(
        uint256 _projectId,
        uint256 _index,
        string memory _cidOrData,
        ExternalAssetDependencyType _dependencyType
    ) external {
        _onlyUnlockedProjectExternalAssetDependencies(_projectId);
        _onlyArtistOrAdminACL(
            _projectId,
            this.updateProjectExternalAssetDependency.selector
        );
        uint24 assetCount = projects[_projectId].externalAssetDependencyCount;
        require(_index < assetCount, "Asset index out of range");
        ExternalAssetDependency storage _oldDependency = projects[_projectId]
            .externalAssetDependencies[_index];
        ExternalAssetDependencyType _oldDependencyType = _oldDependency
            .dependencyType;
        projects[_projectId]
            .externalAssetDependencies[_index]
            .dependencyType = _dependencyType;
        // if the incoming dependency type is onchain, we need to write the data to bytecode
        if (_dependencyType == ExternalAssetDependencyType.ONCHAIN) {
            if (_oldDependencyType != ExternalAssetDependencyType.ONCHAIN) {
                // we only need to set the cid to an empty string if we are replacing an offchain asset
                // an onchain asset will already have an empty cid
                projects[_projectId].externalAssetDependencies[_index].cid = "";
            }

            projects[_projectId]
                .externalAssetDependencies[_index]
                .bytecodeAddress = _cidOrData.writeToBytecode();
            // we don't want to emit data, so we emit the cid as an empty string
            _cidOrData = "";
        } else {
            projects[_projectId]
                .externalAssetDependencies[_index]
                .cid = _cidOrData;
        }
        emit ExternalAssetDependencyUpdated(
            _projectId,
            _index,
            _cidOrData,
            _dependencyType,
            assetCount
        );
    }

    /**
     * @notice Removes external asset dependency for project `_projectId` at index `_index`.
     * Removal is done by swapping the element to be removed with the last element in the array, then deleting this last element.
     * Assets with indices higher than `_index` can have their indices adjusted as a result of this operation.
     * @param _projectId Project to be updated.
     * @param _index Asset index
     */
    function removeProjectExternalAssetDependency(
        uint256 _projectId,
        uint256 _index
    ) external {
        _onlyUnlockedProjectExternalAssetDependencies(_projectId);
        _onlyArtistOrAdminACL(
            _projectId,
            this.removeProjectExternalAssetDependency.selector
        );
        uint24 assetCount = projects[_projectId].externalAssetDependencyCount;
        require(_index < assetCount, "Asset index out of range");

        uint24 lastElementIndex = assetCount - 1;

        // copy last element to index of element to be removed
        projects[_projectId].externalAssetDependencies[_index] = projects[
            _projectId
        ].externalAssetDependencies[lastElementIndex];

        delete projects[_projectId].externalAssetDependencies[lastElementIndex];

        projects[_projectId].externalAssetDependencyCount = lastElementIndex;

        emit ExternalAssetDependencyRemoved(_projectId, _index);
    }

    /**
     * @notice Adds external asset dependency for project `_projectId`.
     * @param _projectId Project to be updated.
     * @param _cidOrData Asset cid (Content identifier) or data string to be translated into bytecode.
     * @param _dependencyType Asset dependency type.
     *  0 - IPFS
     *  1 - ARWEAVE
     *  2 - ONCHAIN
     */
    function addProjectExternalAssetDependency(
        uint256 _projectId,
        string memory _cidOrData,
        ExternalAssetDependencyType _dependencyType
    ) external {
        _onlyUnlockedProjectExternalAssetDependencies(_projectId);
        _onlyArtistOrAdminACL(
            _projectId,
            this.addProjectExternalAssetDependency.selector
        );
        uint24 assetCount = projects[_projectId].externalAssetDependencyCount;
        address _bytecodeAddress = address(0);
        // if the incoming dependency type is onchain, we need to write the data to bytecode
        if (_dependencyType == ExternalAssetDependencyType.ONCHAIN) {
            _bytecodeAddress = _cidOrData.writeToBytecode();
            // we don't want to emit data, so we emit the cid as an empty string
            _cidOrData = "";
        }
        ExternalAssetDependency memory asset = ExternalAssetDependency({
            cid: _cidOrData,
            dependencyType: _dependencyType,
            bytecodeAddress: _bytecodeAddress
        });
        projects[_projectId].externalAssetDependencies[assetCount] = asset;
        projects[_projectId].externalAssetDependencyCount = assetCount + 1;

        emit ExternalAssetDependencyUpdated(
            _projectId,
            assetCount,
            _cidOrData,
            _dependencyType,
            assetCount + 1
        );
    }

    /**
     * @notice Mints a token from project `_projectId` and sets the
     * token's owner to `_to`. Hash may or may not be assigned to the token
     * during the mint transaction, depending on the randomizer contract.
     * @param _to Address to be the minted token's owner.
     * @param _projectId Project ID to mint a token on.
     * @param _by Purchaser of minted token.
     * @return _tokenId The ID of the minted token.
     * @dev sender must be the allowed minterContract
     * @dev name of function is optimized for gas usage
     */
    function mint_Ecf(
        address _to,
        uint256 _projectId,
        address _by
    ) external returns (uint256 _tokenId) {
        // CHECKS
        require(msg.sender == minterContract, "Must mint from minter contract");
        Project storage project = projects[_projectId];
        // load invocations into memory
        uint24 invocationsBefore = project.invocations;
        uint24 invocationsAfter;
        unchecked {
            // invocationsBefore guaranteed <= maxInvocations <= 1_000_000,
            // 1_000_000 << max uint24, so no possible overflow
            invocationsAfter = invocationsBefore + 1;
        }
        uint24 maxInvocations = project.maxInvocations;

        require(
            invocationsBefore < maxInvocations,
            "Must not exceed max invocations"
        );
        require(
            project.active ||
                _by == projectIdToFinancials[_projectId].artistAddress,
            "Project must exist and be active"
        );
        require(
            !project.paused ||
                _by == projectIdToFinancials[_projectId].artistAddress,
            "Purchases are paused."
        );

        // EFFECTS
        // increment project's invocations
        project.invocations = invocationsAfter;
        uint256 thisTokenId;
        unchecked {
            // invocationsBefore is uint24 << max uint256. In production use,
            // _projectId * ONE_MILLION must be << max uint256, otherwise
            // tokenIdToProjectId function become invalid.
            // Therefore, no risk of overflow
            thisTokenId = (_projectId * ONE_MILLION) + invocationsBefore;
        }

        // mark project as completed if hit max invocations
        if (invocationsAfter == maxInvocations) {
            _completeProject(_projectId);
        }

        // INTERACTIONS
        _mint(_to, thisTokenId);

        // token hash is updated by the randomizer contract on V3
        randomizerContract.assignTokenHash(thisTokenId);

        // Do not need to also log `projectId` in event, as the `projectId` for
        // a given token can be derived from the `tokenId` with:
        //   projectId = tokenId / 1_000_000
        emit Mint(_to, thisTokenId);

        return thisTokenId;
    }

    /**
     * @notice Sets the hash seed for a given token ID `_tokenId`.
     * May only be called by the current randomizer contract.
     * May only be called for tokens that have not already been assigned a
     * non-zero hash.
     * @param _tokenId Token ID to set the hash for.
     * @param _hashSeed Hash seed to set for the token ID. Only last 12 bytes
     * will be used.
     * @dev gas-optimized function name because called during mint sequence
     * @dev if a separate event is required when the token hash is set, e.g.
     * for indexing purposes, it must be emitted by the randomizer. This is to
     * minimize gas when minting.
     */
    function setTokenHash_8PT(uint256 _tokenId, bytes32 _hashSeed) external {
        _onlyValidTokenId(_tokenId);

        OwnerAndHashSeed storage ownerAndHashSeed = _ownersAndHashSeeds[
            _tokenId
        ];
        require(
            msg.sender == address(randomizerContract),
            "Only randomizer may set"
        );
        require(
            ownerAndHashSeed.hashSeed == bytes12(0),
            "Token hash already set"
        );
        require(_hashSeed != bytes12(0), "No zero hash seed");
        ownerAndHashSeed.hashSeed = bytes12(_hashSeed);
    }

    /**
     * @notice Allows owner (AdminACL) to revoke ownership of the contract.
     * Note that the contract is intended to continue to function after the
     * owner renounces ownership, but no new projects will be able to be added.
     * Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the
     * owner/AdminACL contract. The same is true for any dependent contracts
     * that also integrate with the owner/AdminACL contract (e.g. potentially
     * minter suite contracts, registry contracts, etc.).
     * After renouncing ownership, artists will be in control of updates to
     * their payment addresses and splits (see modifier
     * onlyAdminACLOrRenouncedArtist`).
     * While there is no currently intended reason to call this method based on
     * typical Engine partner business practices, this method exists to allow
     * artists to continue to maintain the limited set of contract
     * functionality that exists post-project-lock in an environment in which
     * there is no longer an admin maintaining this smart contract.
     * @dev This function is intended to be called directly by the AdminACL,
     * not by an address allowed by the AdminACL contract.
     */
    function renounceOwnership() public override onlyOwner {
        // broadcast that new projects are no longer allowed (if not already)
        _forbidNewProjects();
        // renounce ownership viw Ownable
        Ownable.renounceOwnership();
    }

    /**
     * @notice Updates reference to Art Blocks Dependency Registry contract.
     * @param _artblocksDependencyRegistryAddress Address of new Dependency
     * Registry.
     */
    function updateArtblocksDependencyRegistryAddress(
        address _artblocksDependencyRegistryAddress
    ) external {
        _onlyAdminACL(this.updateArtblocksDependencyRegistryAddress.selector);
        _onlyNonZeroAddress(_artblocksDependencyRegistryAddress);
        artblocksDependencyRegistryAddress = _artblocksDependencyRegistryAddress;
        emit PlatformUpdated(FIELD_ARTBLOCKS_DEPENDENCY_REGISTRY_ADDRESS);
    }

    /**
     * @notice Updates sales addresses for the platform and render providers to
     * the input parameters.
     * @param _renderProviderPrimarySalesAddress Address of new primary sales
     * payment address.
     * @param _renderProviderSecondarySalesAddress Address of new secondary sales
     * payment address.
     * @param _platformProviderPrimarySalesAddress Address of new primary sales
     * payment address.
     * @param _platformProviderSecondarySalesAddress Address of new secondary sales
     * payment address.
     */
    function updateProviderSalesAddresses(
        address payable _renderProviderPrimarySalesAddress,
        address payable _renderProviderSecondarySalesAddress,
        address payable _platformProviderPrimarySalesAddress,
        address payable _platformProviderSecondarySalesAddress
    ) external {
        _onlyAdminACL(this.updateProviderSalesAddresses.selector);
        _onlyNonZeroAddress(_renderProviderPrimarySalesAddress);
        _onlyNonZeroAddress(_renderProviderSecondarySalesAddress);
        _onlyNonZeroAddress(_platformProviderPrimarySalesAddress);
        _onlyNonZeroAddress(_platformProviderSecondarySalesAddress);
        _updateProviderSalesAddresses(
            _renderProviderPrimarySalesAddress,
            _renderProviderSecondarySalesAddress,
            _platformProviderPrimarySalesAddress,
            _platformProviderSecondarySalesAddress
        );
    }

    /**
     * @notice Updates the render and platform provider primary sales revenue percentage to
     * the provided inputs.
     * @param renderProviderPrimarySalesPercentage_ New primary sales revenue % for the render provider
     * @param platformProviderPrimarySalesPercentage_ New primary sales revenue % for the platform provider
     * percentage.
     */
    function updateProviderPrimarySalesPercentages(
        uint256 renderProviderPrimarySalesPercentage_,
        uint256 platformProviderPrimarySalesPercentage_
    ) external {
        _onlyAdminACL(this.updateProviderPrimarySalesPercentages.selector);

        // Validate that the sum of the proposed %s, does not exceed 100%.
        require(
            (renderProviderPrimarySalesPercentage_ +
                platformProviderPrimarySalesPercentage_) <= ONE_HUNDRED,
            "Max sum of ONE_HUNDRED %"
        );
        // Casting to `uint8` here is safe due check above, which does not allow
        // overflow as of solidity version ^0.8.0.
        _renderProviderPrimarySalesPercentage = uint8(
            renderProviderPrimarySalesPercentage_
        );
        _platformProviderPrimarySalesPercentage = uint8(
            platformProviderPrimarySalesPercentage_
        );
        emit PlatformUpdated(FIELD_PROVIDER_PRIMARY_SALES_PERCENTAGES);
    }

    /**
     * @notice Updates render and platform provider secondary sales royalty Basis Points to
     * the provided inputs.
     * @param _renderProviderSecondarySalesBPS New secondary sales royalty Basis
     * points.
     * @param _platformProviderSecondarySalesBPS New secondary sales royalty Basis
     * points.
     * @dev Due to secondary royalties being ultimately enforced via social
     * consensus, no hard upper limit is imposed on the BPS value, other than
     * <= 100% royalty, which would not make mathematical sense. Realistically,
     * changing this value is expected to either never occur, or be a rare
     * occurrence.
     */
    function updateProviderSecondarySalesBPS(
        uint256 _renderProviderSecondarySalesBPS,
        uint256 _platformProviderSecondarySalesBPS
    ) external {
        _onlyAdminACL(this.updateProviderSecondarySalesBPS.selector);
        // Validate that the sum of the proposed provider BPS, does not exceed 10_000 BPS.
        require(
            (_renderProviderSecondarySalesBPS +
                _platformProviderSecondarySalesBPS) <=
                MAX_PROVIDER_SECONDARY_SALES_BPS,
            "Over max sum of BPS"
        );
        renderProviderSecondarySalesBPS = _renderProviderSecondarySalesBPS;
        platformProviderSecondarySalesBPS = _platformProviderSecondarySalesBPS;
        emit PlatformUpdated(FIELD_PROVIDER_SECONDARY_SALES_BPS);
    }

    /**
     * @notice Updates minter to `_address`.
     * @param _address Address of new minter.
     */
    function updateMinterContract(address _address) external {
        _onlyAdminACL(this.updateMinterContract.selector);
        _onlyNonZeroAddress(_address);
        minterContract = _address;
        emit MinterUpdated(_address);
    }

    /**
     * @notice Updates randomizer to `_randomizerAddress`.
     * @param _randomizerAddress Address of new randomizer.
     */
    function updateRandomizerAddress(address _randomizerAddress) external {
        _onlyAdminACL(this.updateRandomizerAddress.selector);
        _onlyNonZeroAddress(_randomizerAddress);
        _updateRandomizerAddress(_randomizerAddress);
    }

    /**
     * @notice Toggles project `_projectId` as active/inactive.
     * @param _projectId Project ID to be toggled.
     */
    function toggleProjectIsActive(uint256 _projectId) external {
        _onlyAdminACL(this.toggleProjectIsActive.selector);
        _onlyValidProjectId(_projectId);
        projects[_projectId].active = !projects[_projectId].active;
        emit ProjectUpdated(_projectId, FIELD_PROJECT_ACTIVE);
    }

    /**
     * @notice Artist proposes updated set of artist address, additional payee
     * addresses, and percentage splits for project `_projectId`. Addresses and
     * percentages do not have to all be changed, but they must all be defined
     * as a complete set.
     * Note that if the artist is only proposing a change to the payee percentage
     * splits, without modifying the payee addresses, the proposal will be
     * automatically approved and the new splits will become active immediately.
     * Automatic approval will also be granted if the artist is only removing
     * additional payee addresses, without adding any new ones.
     * Also note that if `autoApproveArtistSplitProposals` is true, proposals
     * will always be auto-approved, regardless of what is being changed.
     * Also note that if the artist is proposing sending funds to the zero
     * address, this function will revert and the proposal will not be created.
     * @param _projectId Project ID.
     * @param _artistAddress Artist address that controls the project, and may
     * receive payments.
     * @param _additionalPayeePrimarySales Address that may receive a
     * percentage split of the artist's primary sales revenue.
     * @param _additionalPayeePrimarySalesPercentage Percent of artist's
     * portion of primary sale revenue that will be split to address
     * `_additionalPayeePrimarySales`.
     * @param _additionalPayeeSecondarySales Address that may receive a percentage
     * split of the secondary sales royalties.
     * @param _additionalPayeeSecondarySalesPercentage Percent of artist's portion
     * of secondary sale royalties that will be split to address
     * `_additionalPayeeSecondarySales`.
     * @dev `_artistAddress` must be a valid address (non-zero-address), but it
     * is intentionally allowable for `_additionalPayee{Primary,Secondaary}Sales`
     * and their associated percentages to be zero'd out by the controlling artist.
     */
    function proposeArtistPaymentAddressesAndSplits(
        uint256 _projectId,
        address payable _artistAddress,
        address payable _additionalPayeePrimarySales,
        uint256 _additionalPayeePrimarySalesPercentage,
        address payable _additionalPayeeSecondarySales,
        uint256 _additionalPayeeSecondarySalesPercentage
    ) external {
        _onlyValidProjectId(_projectId);
        _onlyArtist(_projectId);
        _onlyNonZeroAddress(_artistAddress);
        ProjectFinance storage projectFinance = projectIdToFinancials[
            _projectId
        ];
        // checks
        require(
            _additionalPayeePrimarySalesPercentage <= ONE_HUNDRED &&
                _additionalPayeeSecondarySalesPercentage <= ONE_HUNDRED,
            "Max of 100%"
        );
        require(
            _additionalPayeePrimarySalesPercentage == 0 ||
                _additionalPayeePrimarySales != address(0),
            "Primary payee is zero address"
        );
        require(
            _additionalPayeeSecondarySalesPercentage == 0 ||
                _additionalPayeeSecondarySales != address(0),
            "Secondary payee is zero address"
        );
        // effects
        // emit event for off-chain indexing
        // note: always emit a proposal event, even in the pathway of
        // automatic approval, to simplify indexing expectations
        emit ProposedArtistAddressesAndSplits(
            _projectId,
            _artistAddress,
            _additionalPayeePrimarySales,
            _additionalPayeePrimarySalesPercentage,
            _additionalPayeeSecondarySales,
            _additionalPayeeSecondarySalesPercentage
        );
        // automatically accept if no proposed addresses modifications, or if
        // the proposal only removes payee addresses, or if contract is set to
        // always auto-approve.
        // store proposal hash on-chain, only if not automatic accept
        bool automaticAccept = autoApproveArtistSplitProposals;
        if (!automaticAccept) {
            // block scope to avoid stack too deep error
            bool artistUnchanged = _artistAddress ==
                projectFinance.artistAddress;
            bool additionalPrimaryUnchangedOrRemoved = (_additionalPayeePrimarySales ==
                    projectFinance.additionalPayeePrimarySales) ||
                    (_additionalPayeePrimarySales == address(0));
            bool additionalSecondaryUnchangedOrRemoved = (_additionalPayeeSecondarySales ==
                    projectFinance.additionalPayeeSecondarySales) ||
                    (_additionalPayeeSecondarySales == address(0));
            automaticAccept =
                artistUnchanged &&
                additionalPrimaryUnchangedOrRemoved &&
                additionalSecondaryUnchangedOrRemoved;
        }
        if (automaticAccept) {
            // clear any previously proposed values
            proposedArtistAddressesAndSplitsHash[_projectId] = bytes32(0);
            // update storage
            // artist address can change during automatic accept if
            // autoApproveArtistSplitProposals is true
            projectFinance.artistAddress = _artistAddress;
            projectFinance
                .additionalPayeePrimarySales = _additionalPayeePrimarySales;
            // safe to cast as uint8 as max is 100%, max uint8 is 255
            projectFinance.additionalPayeePrimarySalesPercentage = uint8(
                _additionalPayeePrimarySalesPercentage
            );
            projectFinance
                .additionalPayeeSecondarySales = _additionalPayeeSecondarySales;
            // safe to cast as uint8 as max is 100%, max uint8 is 255
            projectFinance.additionalPayeeSecondarySalesPercentage = uint8(
                _additionalPayeeSecondarySalesPercentage
            );
            // emit event for off-chain indexing
            emit AcceptedArtistAddressesAndSplits(_projectId);
        } else {
            proposedArtistAddressesAndSplitsHash[_projectId] = keccak256(
                abi.encode(
                    _artistAddress,
                    _additionalPayeePrimarySales,
                    _additionalPayeePrimarySalesPercentage,
                    _additionalPayeeSecondarySales,
                    _additionalPayeeSecondarySalesPercentage
                )
            );
        }
    }

    /**
     * @notice Admin accepts a proposed set of updated artist address,
     * additional payee addresses, and percentage splits for project
     * `_projectId`. Addresses and percentages do not have to all be changed,
     * but they must all be defined as a complete set.
     * @param _projectId Project ID.
     * @param _artistAddress Artist address that controls the project, and may
     * receive payments.
     * @param _additionalPayeePrimarySales Address that may receive a
     * percentage split of the artist's primary sales revenue.
     * @param _additionalPayeePrimarySalesPercentage Percent of artist's
     * portion of primary sale revenue that will be split to address
     * `_additionalPayeePrimarySales`.
     * @param _additionalPayeeSecondarySales Address that may receive a percentage
     * split of the secondary sales royalties.
     * @param _additionalPayeeSecondarySalesPercentage Percent of artist's portion
     * of secondary sale royalties that will be split to address
     * `_additionalPayeeSecondarySales`.
     * @dev this must be called by the Admin ACL contract, and must only accept
     * the most recent proposed values for a given project (validated on-chain
     * by comparing the hash of the proposed and accepted values).
     * @dev `_artistAddress` must be a valid address (non-zero-address), but it
     * is intentionally allowable for `_additionalPayee{Primary,Secondaary}Sales`
     * and their associated percentages to be zero'd out by the controlling artist.
     */
    function adminAcceptArtistAddressesAndSplits(
        uint256 _projectId,
        address payable _artistAddress,
        address payable _additionalPayeePrimarySales,
        uint256 _additionalPayeePrimarySalesPercentage,
        address payable _additionalPayeeSecondarySales,
        uint256 _additionalPayeeSecondarySalesPercentage
    ) external {
        _onlyValidProjectId(_projectId);
        _onlyAdminACLOrRenouncedArtist(
            _projectId,
            this.adminAcceptArtistAddressesAndSplits.selector
        );
        _onlyNonZeroAddress(_artistAddress);
        // checks
        require(
            proposedArtistAddressesAndSplitsHash[_projectId] ==
                keccak256(
                    abi.encode(
                        _artistAddress,
                        _additionalPayeePrimarySales,
                        _additionalPayeePrimarySalesPercentage,
                        _additionalPayeeSecondarySales,
                        _additionalPayeeSecondarySalesPercentage
                    )
                ),
            "Must match artist proposal"
        );
        // effects
        ProjectFinance storage projectFinance = projectIdToFinancials[
            _projectId
        ];
        projectFinance.artistAddress = _artistAddress;
        projectFinance
            .additionalPayeePrimarySales = _additionalPayeePrimarySales;
        projectFinance.additionalPayeePrimarySalesPercentage = uint8(
            _additionalPayeePrimarySalesPercentage
        );
        projectFinance
            .additionalPayeeSecondarySales = _additionalPayeeSecondarySales;
        projectFinance.additionalPayeeSecondarySalesPercentage = uint8(
            _additionalPayeeSecondarySalesPercentage
        );
        // clear proposed values
        proposedArtistAddressesAndSplitsHash[_projectId] = bytes32(0);
        // emit event for off-chain indexing
        emit AcceptedArtistAddressesAndSplits(_projectId);
    }

    /**
     * @notice Updates artist of project `_projectId` to `_artistAddress`.
     * This is to only be used in the event that the artist address is
     * compromised or sanctioned.
     * @param _projectId Project ID.
     * @param _artistAddress New artist address.
     */
    function updateProjectArtistAddress(
        uint256 _projectId,
        address payable _artistAddress
    ) external {
        _onlyValidProjectId(_projectId);
        _onlyAdminACLOrRenouncedArtist(
            _projectId,
            this.updateProjectArtistAddress.selector
        );
        _onlyNonZeroAddress(_artistAddress);
        projectIdToFinancials[_projectId].artistAddress = _artistAddress;
        emit ProjectUpdated(_projectId, FIELD_PROJECT_ARTIST_ADDRESS);
    }

    /**
     * @notice Toggles paused state of project `_projectId`.
     * @param _projectId Project ID to be toggled.
     */
    function toggleProjectIsPaused(uint256 _projectId) external {
        _onlyArtist(_projectId);
        projects[_projectId].paused = !projects[_projectId].paused;
        emit ProjectUpdated(_projectId, FIELD_PROJECT_PAUSED);
    }

    /**
     * @notice Adds new project `_projectName` by `_artistAddress`.
     * @param _projectName Project name.
     * @param _artistAddress Artist's address.
     * @dev token price now stored on minter
     */
    function addProject(
        string memory _projectName,
        address payable _artistAddress
    ) external {
        _onlyAdminACL(this.addProject.selector);
        _onlyNonEmptyString(_projectName);
        _onlyNonZeroAddress(_artistAddress);
        require(!newProjectsForbidden, "New projects forbidden");
        uint256 projectId = _nextProjectId;
        projectIdToFinancials[projectId].artistAddress = _artistAddress;
        projects[projectId].name = _projectName;
        projects[projectId].paused = true;
        projects[projectId].maxInvocations = ONE_MILLION_UINT24;
        projects[projectId].projectBaseURI = defaultBaseURI;

        _nextProjectId = uint248(projectId) + 1;
        emit ProjectUpdated(projectId, FIELD_PROJECT_CREATED);
    }

    /**
     * @notice Forever forbids new projects from being added to this contract.
     */
    function forbidNewProjects() external {
        _onlyAdminACL(this.forbidNewProjects.selector);
        require(!newProjectsForbidden, "Already forbidden");
        _forbidNewProjects();
    }

    /**
     * @notice Updates name of project `_projectId` to be `_projectName`.
     * @param _projectId Project ID.
     * @param _projectName New project name.
     */
    function updateProjectName(
        uint256 _projectId,
        string memory _projectName
    ) external {
        _onlyUnlocked(_projectId);
        _onlyArtistOrAdminACL(_projectId, this.updateProjectName.selector);
        _onlyNonEmptyString(_projectName);
        projects[_projectId].name = _projectName;
        emit ProjectUpdated(_projectId, FIELD_PROJECT_NAME);
    }

    /**
     * @notice Updates artist name for project `_projectId` to be
     * `_projectArtistName`.
     * @param _projectId Project ID.
     * @param _projectArtistName New artist name.
     */
    function updateProjectArtistName(
        uint256 _projectId,
        string memory _projectArtistName
    ) external {
        _onlyUnlocked(_projectId);
        _onlyArtistOrAdminACL(
            _projectId,
            this.updateProjectArtistName.selector
        );
        _onlyNonEmptyString(_projectArtistName);
        projects[_projectId].artist = _projectArtistName;
        emit ProjectUpdated(_projectId, FIELD_PROJECT_ARTIST_NAME);
    }

    /**
     * @notice Updates artist secondary market royalties for project
     * `_projectId` to be `_secondMarketRoyalty` percent.
     * This DOES NOT include the secondary market royalty percentages collected
     * by the issuing platform; it is only the total percentage of royalties
     * that will be split to artist and additionalSecondaryPayee.
     * @param _projectId Project ID.
     * @param _secondMarketRoyalty Percent of secondary sales revenue that will
     * be split to artist and additionalSecondaryPayee. This must be less than
     * or equal to ARTIST_MAX_SECONDARY_ROYALTY_PERCENTAGE percent.
     */
    function updateProjectSecondaryMarketRoyaltyPercentage(
        uint256 _projectId,
        uint256 _secondMarketRoyalty
    ) external {
        _onlyArtist(_projectId);
        require(
            _secondMarketRoyalty <= ARTIST_MAX_SECONDARY_ROYALTY_PERCENTAGE,
            "Over max percent"
        );
        projectIdToFinancials[_projectId]
            .secondaryMarketRoyaltyPercentage = uint8(_secondMarketRoyalty);
        emit ProjectUpdated(
            _projectId,
            FIELD_PROJECT_SECONDARY_MARKET_ROYALTY_PERCENTAGE
        );
    }

    /**
     * @notice Updates description of project `_projectId`.
     * Only artist may call when unlocked, only admin may call when locked.
     * Note: The BytecodeStorage library is used to store the description to
     * reduce initial upload cost, however, even minor edits will require an
     * expensive, entirely new bytecode storage contract to be deployed instead
     * of relatively cheap updates to already-warm storage slots. This results
     * in an increased gas cost for minor edits to the description after the
     * initial upload, but an overall decrease in gas cost for projects with
     * less than ~3-5 edits (depending on the length of the description).
     * @param _projectId Project ID.
     * @param _projectDescription New project description.
     */
    function updateProjectDescription(
        uint256 _projectId,
        string memory _projectDescription
    ) external {
        // checks
        require(
            _projectUnlocked(_projectId)
                ? msg.sender == projectIdToFinancials[_projectId].artistAddress
                : adminACLAllowed(
                    msg.sender,
                    address(this),
                    this.updateProjectDescription.selector
                ),
            "Only artist when unlocked, owner when locked"
        );
        // effects
        // store description in contract bytecode, replacing reference address from
        // the old storage description with the newly created one
        projects[_projectId].descriptionAddress = _projectDescription
            .writeToBytecode();
        emit ProjectUpdated(_projectId, FIELD_PROJECT_DESCRIPTION);
    }

    /**
     * @notice Updates website of project `_projectId` to be `_projectWebsite`.
     * @param _projectId Project ID.
     * @param _projectWebsite New project website.
     * @dev It is intentionally allowed for this to be set to the empty string.
     */
    function updateProjectWebsite(
        uint256 _projectId,
        string memory _projectWebsite
    ) external {
        _onlyArtist(_projectId);
        projects[_projectId].website = _projectWebsite;
        emit ProjectUpdated(_projectId, FIELD_PROJECT_WEBSITE);
    }

    /**
     * @notice Updates license for project `_projectId`.
     * @param _projectId Project ID.
     * @param _projectLicense New project license.
     */
    function updateProjectLicense(
        uint256 _projectId,
        string memory _projectLicense
    ) external {
        _onlyUnlocked(_projectId);
        _onlyArtistOrAdminACL(_projectId, this.updateProjectLicense.selector);
        _onlyNonEmptyString(_projectLicense);
        projects[_projectId].license = _projectLicense;
        emit ProjectUpdated(_projectId, FIELD_PROJECT_LICENSE);
    }

    /**
     * @notice Updates maximum invocations for project `_projectId` to
     * `_maxInvocations`. Maximum invocations may only be decreased by the
     * artist, and must be greater than or equal to current invocations.
     * New projects are created with maximum invocations of 1 million by
     * default.
     * @param _projectId Project ID.
     * @param _maxInvocations New maximum invocations.
     */
    function updateProjectMaxInvocations(
        uint256 _projectId,
        uint24 _maxInvocations
    ) external {
        _onlyArtist(_projectId);
        // CHECKS
        Project storage project = projects[_projectId];
        uint256 _invocations = project.invocations;
        require(
            (_maxInvocations < project.maxInvocations),
            "Only maxInvocations decrease"
        );
        require(_maxInvocations >= _invocations, "Only gte invocations");
        // EFFECTS
        project.maxInvocations = _maxInvocations;
        emit ProjectUpdated(_projectId, FIELD_PROJECT_MAX_INVOCATIONS);

        // register completed timestamp if action completed the project
        if (_maxInvocations == _invocations) {
            _completeProject(_projectId);
        }
    }

    /**
     * @notice Adds a script to project `_projectId`.
     * @param _projectId Project to be updated.
     * @param _script Script to be added. Required to be a non-empty string,
     * but no further validation is performed.
     */
    function addProjectScript(
        uint256 _projectId,
        string memory _script
    ) external {
        _onlyUnlocked(_projectId);
        _onlyArtistOrAdminACL(_projectId, this.addProjectScript.selector);
        _onlyNonEmptyString(_script);
        Project storage project = projects[_projectId];
        // store script in contract bytecode
        project.scriptBytecodeAddresses[project.scriptCount] = _script
            .writeToBytecode();
        project.scriptCount = project.scriptCount + 1;
        emit ProjectUpdated(_projectId, FIELD_PROJECT_SCRIPT);
    }

    /**
     * @notice Updates script for project `_projectId` at script ID `_scriptId`.
     * @param _projectId Project to be updated.
     * @param _scriptId Script ID to be updated.
     * @param _script The updated script value. Required to be a non-empty
     *                string, but no further validation is performed.
     */
    function updateProjectScript(
        uint256 _projectId,
        uint256 _scriptId,
        string memory _script
    ) external {
        _onlyUnlocked(_projectId);
        _onlyArtistOrAdminACL(_projectId, this.updateProjectScript.selector);
        _onlyNonEmptyString(_script);
        Project storage project = projects[_projectId];
        require(_scriptId < project.scriptCount, "scriptId out of range");
        // store script in contract bytecode, replacing reference address from
        // the old storage contract with the newly created one
        project.scriptBytecodeAddresses[_scriptId] = _script.writeToBytecode();
        emit ProjectUpdated(_projectId, FIELD_PROJECT_SCRIPT);
    }

    /**
     * @notice Removes last script from project `_projectId`.
     * @param _projectId Project to be updated.
     */
    function removeProjectLastScript(uint256 _projectId) external {
        _onlyUnlocked(_projectId);
        _onlyArtistOrAdminACL(
            _projectId,
            this.removeProjectLastScript.selector
        );
        Project storage project = projects[_projectId];
        require(project.scriptCount > 0, "No scripts to remove");
        // delete reference to old storage contract address
        delete project.scriptBytecodeAddresses[project.scriptCount - 1];
        unchecked {
            project.scriptCount = project.scriptCount - 1;
        }
        emit ProjectUpdated(_projectId, FIELD_PROJECT_SCRIPT);
    }

    /**
     * @notice Updates script type for project `_projectId`.
     * @param _projectId Project to be updated.
     * @param _scriptTypeAndVersion Script type and version e.g. "[email protected]",
     * as bytes32 encoded string.
     */
    function updateProjectScriptType(
        uint256 _projectId,
        bytes32 _scriptTypeAndVersion
    ) external {
        _onlyUnlocked(_projectId);
        _onlyArtistOrAdminACL(
            _projectId,
            this.updateProjectScriptType.selector
        );
        Project storage project = projects[_projectId];
        // require exactly one @ symbol in _scriptTypeAndVersion
        require(
            _scriptTypeAndVersion.containsExactCharacterQty(
                AT_CHARACTER_CODE,
                uint8(1)
            ),
            "must contain exactly one @"
        );
        project.scriptTypeAndVersion = _scriptTypeAndVersion;
        emit ProjectUpdated(_projectId, FIELD_PROJECT_SCRIPT_TYPE);
    }

    /**
     * @notice Updates project's aspect ratio.
     * @param _projectId Project to be updated.
     * @param _aspectRatio Aspect ratio to be set. Intended to be string in the
     * format of a decimal, e.g. "1" for square, "1.77777778" for 16:9, etc.,
     * allowing for a maximum of 10 digits and one (optional) decimal separator.
     */
    function updateProjectAspectRatio(
        uint256 _projectId,
        string memory _aspectRatio
    ) external {
        _onlyUnlocked(_projectId);
        _onlyArtistOrAdminACL(
            _projectId,
            this.updateProjectAspectRatio.selector
        );
        _onlyNonEmptyString(_aspectRatio);
        // Perform more detailed input validation for aspect ratio.
        bytes memory aspectRatioBytes = bytes(_aspectRatio);
        uint256 bytesLength = aspectRatioBytes.length;
        require(bytesLength <= 11, "Aspect ratio format too long");
        bool hasSeenDecimalSeparator = false;
        bool hasSeenNumber = false;
        for (uint256 i; i < bytesLength; i++) {
            bytes1 character = aspectRatioBytes[i];
            // Allow as many #s as desired.
            if (character >= 0x30 && character <= 0x39) {
                // 9-0
                // We need to ensure there is at least 1 `9-0` occurrence.
                hasSeenNumber = true;
                continue;
            }
            if (character == 0x2E) {
                // .
                // Allow no more than 1 `.` occurrence.
                if (!hasSeenDecimalSeparator) {
                    hasSeenDecimalSeparator = true;
                    continue;
                }
            }
            revert("Improperly formatted aspect ratio");
        }
        require(hasSeenNumber, "Aspect ratio has no numbers");

        projects[_projectId].aspectRatio = _aspectRatio;
        emit ProjectUpdated(_projectId, FIELD_PROJECT_ASPECT_RATIO);
    }

    /**
     * @notice Updates base URI for project `_projectId` to `_newBaseURI`.
     * This is the controlling base URI for all tokens in the project. The
     * contract-level defaultBaseURI is only used when initializing new
     * projects.
     * @param _projectId Project to be updated.
     * @param _newBaseURI New base URI.
     */
    function updateProjectBaseURI(
        uint256 _projectId,
        string memory _newBaseURI
    ) external {
        _onlyArtist(_projectId);
        _onlyNonEmptyString(_newBaseURI);
        projects[_projectId].projectBaseURI = _newBaseURI;
        emit ProjectUpdated(_projectId, FIELD_PROJECT_BASE_URI);
    }

    /**
     * @notice Updates default base URI to `_defaultBaseURI`. The
     * contract-level defaultBaseURI is only used when initializing new
     * projects. Token URIs are determined by their project's `projectBaseURI`.
     * @param _defaultBaseURI New default base URI.
     */
    function updateDefaultBaseURI(string memory _defaultBaseURI) external {
        _onlyAdminACL(this.updateDefaultBaseURI.selector);
        _onlyNonEmptyString(_defaultBaseURI);
        _updateDefaultBaseURI(_defaultBaseURI);
    }

    /**
     * @notice Next project ID to be created on this contract.
     * @return uint256 Next project ID.
     */
    function nextProjectId() external view returns (uint256) {
        return _nextProjectId;
    }

    /**
     * @notice Returns token hash for token ID `_tokenId`. Returns null if hash
     * has not been set.
     * @param _tokenId Token ID to be queried.
     * @return bytes32 Token hash.
     * @dev token hash is the keccak256 hash of the stored hash seed
     */
    function tokenIdToHash(uint256 _tokenId) external view returns (bytes32) {
        bytes12 _hashSeed = _ownersAndHashSeeds[_tokenId].hashSeed;
        if (_hashSeed == 0) {
            return 0;
        }
        return keccak256(abi.encode(_hashSeed));
    }

    /**
     * @notice Returns token hash **seed** for token ID `_tokenId`. Returns
     * null if hash seed has not been set. The hash seed id the bytes12 value
     * which is hashed to produce the token hash.
     * @param _tokenId Token ID to be queried.
     * @return bytes12 Token hash seed.
     * @dev token hash seed is keccak256 hashed to give the token hash
     */
    function tokenIdToHashSeed(
        uint256 _tokenId
    ) external view returns (bytes12) {
        return _ownersAndHashSeeds[_tokenId].hashSeed;
    }

    /**
     * @notice View function returning the render provider portion of
     * primary sales, in percent.
     * @return uint256 The render provider portion of primary sales,
     * in percent.
     */
    function renderProviderPrimarySalesPercentage()
        external
        view
        returns (uint256)
    {
        return _renderProviderPrimarySalesPercentage;
    }

    /**
     * @notice View function returning the platform provider portion of
     * primary sales, in percent.
     * @return uint256 The platform provider portion of primary sales,
     * in percent.
     */
    function platformProviderPrimarySalesPercentage()
        external
        view
        returns (uint256)
    {
        return _platformProviderPrimarySalesPercentage;
    }

    /**
     * @notice View function returning Artist's address for project
     * `_projectId`.
     * @param _projectId Project ID to be queried.
     * @return address Artist's address.
     */
    function projectIdToArtistAddress(
        uint256 _projectId
    ) external view returns (address payable) {
        return projectIdToFinancials[_projectId].artistAddress;
    }

    /**
     * @notice View function returning Artist's secondary market royalty
     * percentage for project `_projectId`.
     * This does not include render/platform providers portions of secondary
     * market royalties.
     * @param _projectId Project ID to be queried.
     * @return uint256 Artist's secondary market royalty percentage.
     */
    function projectIdToSecondaryMarketRoyaltyPercentage(
        uint256 _projectId
    ) external view returns (uint256) {
        return
            projectIdToFinancials[_projectId].secondaryMarketRoyaltyPercentage;
    }

    /**
     * @notice View function returning Artist's additional payee address for
     * primary sales, for project `_projectId`.
     * @param _projectId Project ID to be queried.
     * @return address Artist's additional payee address for primary sales.
     */
    function projectIdToAdditionalPayeePrimarySales(
        uint256 _projectId
    ) external view returns (address payable) {
        return projectIdToFinancials[_projectId].additionalPayeePrimarySales;
    }

    /**
     * @notice View function returning Artist's additional payee primary sales
     * percentage, for project `_projectId`.
     * @param _projectId Project ID to be queried.
     * @return uint256 Artist's additional payee primary sales percentage.
     */
    function projectIdToAdditionalPayeePrimarySalesPercentage(
        uint256 _projectId
    ) external view returns (uint256) {
        return
            projectIdToFinancials[_projectId]
                .additionalPayeePrimarySalesPercentage;
    }

    /**
     * @notice View function returning Artist's additional payee address for
     * secondary sales, for project `_projectId`.
     * @param _projectId Project ID to be queried.
     * @return address payable Artist's additional payee address for secondary
     * sales.
     */
    function projectIdToAdditionalPayeeSecondarySales(
        uint256 _projectId
    ) external view returns (address payable) {
        return projectIdToFinancials[_projectId].additionalPayeeSecondarySales;
    }

    /**
     * @notice View function returning Artist's additional payee secondary
     * sales percentage, for project `_projectId`.
     * @param _projectId Project ID to be queried.
     * @return uint256 Artist's additional payee secondary sales percentage.
     */
    function projectIdToAdditionalPayeeSecondarySalesPercentage(
        uint256 _projectId
    ) external view returns (uint256) {
        return
            projectIdToFinancials[_projectId]
                .additionalPayeeSecondarySalesPercentage;
    }

    /**
     * @notice Returns project details for project `_projectId`.
     * @param _projectId Project to be queried.
     * @return projectName Name of project
     * @return artist Artist of project
     * @return description Project description
     * @return website Project website
     * @return license Project license
     * @dev this function was named projectDetails prior to V3 core contract.
     */
    function projectDetails(
        uint256 _projectId
    )
        external
        view
        returns (
            string memory projectName,
            string memory artist,
            string memory description,
            string memory website,
            string memory license
        )
    {
        Project storage project = projects[_projectId];
        projectName = project.name;
        artist = project.artist;
        address projectDescriptionBytecodeAddress = project.descriptionAddress;
        if (projectDescriptionBytecodeAddress == address(0)) {
            description = "";
        } else {
            description = _readFromBytecode(projectDescriptionBytecodeAddress);
        }
        website = project.website;
        license = project.license;
    }

    /**
     * @notice Returns project state data for project `_projectId`.
     * @param _projectId Project to be queried
     * @return invocations Current number of invocations
     * @return maxInvocations Maximum allowed invocations
     * @return active Boolean representing if project is currently active
     * @return paused Boolean representing if project is paused
     * @return completedTimestamp zero if project not complete, otherwise
     * timestamp of project completion.
     * @return locked Boolean representing if project is locked
     * @dev price and currency info are located on minter contracts
     */
    function projectStateData(
        uint256 _projectId
    )
        external
        view
        returns (
            uint256 invocations,
            uint256 maxInvocations,
            bool active,
            bool paused,
            uint256 completedTimestamp,
            bool locked
        )
    {
        Project storage project = projects[_projectId];
        invocations = project.invocations;
        maxInvocations = project.maxInvocations;
        active = project.active;
        paused = project.paused;
        completedTimestamp = project.completedTimestamp;
        locked = !_projectUnlocked(_projectId);
    }

    /**
     * @notice Returns artist payment information for project `_projectId`.
     * @param _projectId Project to be queried
     * @return artistAddress Project Artist's address
     * @return additionalPayeePrimarySales Additional payee address for primary
     * sales
     * @return additionalPayeePrimarySalesPercentage Percentage of artist revenue
     * to be sent to the additional payee address for primary sales
     * @return additionalPayeeSecondarySales Additional payee address for secondary
     * sales royalties
     * @return additionalPayeeSecondarySalesPercentage Percentage of artist revenue
     * to be sent to the additional payee address for secondary sales royalties
     * @return secondaryMarketRoyaltyPercentage Royalty percentage to be sent to
     * combination of artist and additional payee. This does not include the
     * platform's percentage of secondary sales royalties, which is defined as
     * the sum of `renderProviderSecondarySalesBPS`
     * and `platformProviderSecondarySalesBPS`.
     */
    function projectArtistPaymentInfo(
        uint256 _projectId
    )
        external
        view
        returns (
            address artistAddress,
            address additionalPayeePrimarySales,
            uint256 additionalPayeePrimarySalesPercentage,
            address additionalPayeeSecondarySales,
            uint256 additionalPayeeSecondarySalesPercentage,
            uint256 secondaryMarketRoyaltyPercentage
        )
    {
        ProjectFinance storage projectFinance = projectIdToFinancials[
            _projectId
        ];
        artistAddress = projectFinance.artistAddress;
        additionalPayeePrimarySales = projectFinance
            .additionalPayeePrimarySales;
        additionalPayeePrimarySalesPercentage = projectFinance
            .additionalPayeePrimarySalesPercentage;
        additionalPayeeSecondarySales = projectFinance
            .additionalPayeeSecondarySales;
        additionalPayeeSecondarySalesPercentage = projectFinance
            .additionalPayeeSecondarySalesPercentage;
        secondaryMarketRoyaltyPercentage = projectFinance
            .secondaryMarketRoyaltyPercentage;
    }

    /**
     * @notice Returns script information for project `_projectId`.
     * @param _projectId Project to be queried.
     * @return scriptTypeAndVersion Project's script type and version
     * (e.g. "p5js(atSymbol)1.0.0")
     * @return aspectRatio Aspect ratio of project (e.g. "1" for square,
     * "1.77777778" for 16:9, etc.)
     * @return scriptCount Count of scripts for project
     */
    function projectScriptDetails(
        uint256 _projectId
    )
        external
        view
        override(IGenArt721CoreContractV3_Base, IDependencyRegistryCompatibleV0)
        returns (
            string memory scriptTypeAndVersion,
            string memory aspectRatio,
            uint256 scriptCount
        )
    {
        Project storage project = projects[_projectId];
        scriptTypeAndVersion = project.scriptTypeAndVersion.toString();
        aspectRatio = project.aspectRatio;
        scriptCount = project.scriptCount;
    }

    /**
     * @notice Returns address with bytecode containing project script for
     * project `_projectId` at script index `_index`.
     */
    function projectScriptBytecodeAddressByIndex(
        uint256 _projectId,
        uint256 _index
    ) external view returns (address) {
        return projects[_projectId].scriptBytecodeAddresses[_index];
    }

    /**
     * @notice Returns script for project `_projectId` at script index `_index`.
     * @param _projectId Project to be queried.
     * @param _index Index of script to be queried.
     */
    function projectScriptByIndex(
        uint256 _projectId,
        uint256 _index
    ) external view returns (string memory) {
        Project storage project = projects[_projectId];
        // If trying to access an out-of-index script, return the empty string.
        if (_index >= project.scriptCount) {
            return "";
        }
        return _readFromBytecode(project.scriptBytecodeAddresses[_index]);
    }

    /**
     * @notice Returns base URI for project `_projectId`.
     * @param _projectId Project to be queried.
     * @return projectBaseURI Base URI for project
     */
    function projectURIInfo(
        uint256 _projectId
    ) external view returns (string memory projectBaseURI) {
        projectBaseURI = projects[_projectId].projectBaseURI;
    }

    /**
     * @notice Backwards-compatible (pre-V3) function returning if `_minter` is
     * minterContract.
     * @param _minter Address to be queried.
     * @return bool Boolean representing if `_minter` is minterContract.
     */
    function isMintWhitelisted(address _minter) external view returns (bool) {
        return (minterContract == _minter);
    }

    /**
     * @notice Gets qty of randomizers in history of all randomizers used by
     * this core contract. If a randomizer is switched away from then back to,
     * it will show up in the history twice.
     * @return randomizerHistoryCount Count of randomizers in history
     */
    function numHistoricalRandomizers() external view returns (uint256) {
        return _historicalRandomizerAddresses.length;
    }

    /**
     * @notice Gets address of randomizer at index `_index` in history of all
     * randomizers used by this core contract. Index is zero-based.
     * @param _index Historical index of randomizer to be queried.
     * @return randomizerAddress Address of randomizer at index `_index`.
     * @dev If a randomizer is switched away from and then switched back to, it
     * will show up in the history twice.
     */
    function getHistoricalRandomizerAt(
        uint256 _index
    ) external view returns (address) {
        require(
            _index < _historicalRandomizerAddresses.length,
            "Index out of bounds"
        );
        return _historicalRandomizerAddresses[_index];
    }

    /**
     * @notice Gets royalty Basis Points (BPS) for token ID `_tokenId`.
     * This conforms to the IManifold interface designated in the Royalty
     * Registry's RoyaltyEngineV1.sol contract.
     * ref: https://github.com/manifoldxyz/royalty-registry-solidity
     * @param _tokenId Token ID to be queried.
     * @return recipients Array of royalty payment recipients
     * @return bps Array of Basis Points (BPS) allocated to each recipient,
     * aligned by index.
     * @dev reverts if invalid _tokenId
     * @dev only returns recipients that have a non-zero BPS allocation
     */
    function getRoyalties(
        uint256 _tokenId
    )
        external
        view
        returns (address payable[] memory recipients, uint256[] memory bps)
    {
        _onlyValidTokenId(_tokenId);
        // initialize arrays with maximum potential length
        recipients = new address payable[](4);
        bps = new uint256[](4);

        uint256 projectId = tokenIdToProjectId(_tokenId);
        ProjectFinance storage projectFinance = projectIdToFinancials[
            projectId
        ];
        // load values into memory
        uint256 royaltyPercentageForArtistAndAdditional = projectFinance
            .secondaryMarketRoyaltyPercentage;
        uint256 additionalPayeePercentage = projectFinance
            .additionalPayeeSecondarySalesPercentage;
        // calculate BPS = percentage * 100
        uint256 artistBPS = (ONE_HUNDRED - additionalPayeePercentage) *
            royaltyPercentageForArtistAndAdditional;

        uint256 additionalBPS = additionalPayeePercentage *
            royaltyPercentageForArtistAndAdditional;
        uint256 renderProviderBPS = renderProviderSecondarySalesBPS;
        uint256 platformProviderBPS = platformProviderSecondarySalesBPS;
        // populate arrays
        uint256 payeeCount;
        if (artistBPS > 0) {
            recipients[payeeCount] = projectFinance.artistAddress;
            bps[payeeCount++] = artistBPS;
        }
        if (additionalBPS > 0) {
            recipients[payeeCount] = projectFinance
                .additionalPayeeSecondarySales;
            bps[payeeCount++] = additionalBPS;
        }
        if (renderProviderBPS > 0) {
            recipients[payeeCount] = renderProviderSecondarySalesAddress;
            bps[payeeCount++] = renderProviderBPS;
        }
        if (platformProviderBPS > 0) {
            recipients[payeeCount] = platformProviderSecondarySalesAddress;
            bps[payeeCount++] = platformProviderBPS;
        }
        // trim arrays if necessary
        if (4 > payeeCount) {
            assembly {
                let decrease := sub(4, payeeCount)
                mstore(recipients, sub(mload(recipients), decrease))
                mstore(bps, sub(mload(bps), decrease))
            }
        }
        return (recipients, bps);
    }

    /**
     * @notice View function that returns appropriate revenue splits between
     * different render provider, platform provider, Artist, and Artist's
     * additional primary sales payee given a sale price of `_price` on
     * project `_projectId`.
     * This always returns four revenue amounts and four addresses, but if a
     * revenue is zero for either Artist or additional payee, the corresponding
     * address returned will also be null (for gas optimization).
     * Does not account for refund if user overpays for a token (minter should
     * handle a refund of the difference, if appropriate).
     * Some minters may have alternative methods of splitting payments, in
     * which case they should implement their own payment splitting logic.
     * @param _projectId Project ID to be queried.
     * @param _price Sale price of token.
     * @return renderProviderRevenue_ amount of revenue to be sent to the
     * render provider
     * @return renderProviderAddress_ address to send render provider revenue to
     * @return platformProviderRevenue_ amount of revenue to be sent to the
     * platform provider
     * @return platformProviderAddress_ address to send platform provider revenue to
     * @return artistRevenue_ amount of revenue to be sent to Artist
     * @return artistAddress_ address to send Artist revenue to. Will be null
     * if no revenue is due to artist (gas optimization).
     * @return additionalPayeePrimaryRevenue_ amount of revenue to be sent to
     * additional payee for primary sales
     * @return additionalPayeePrimaryAddress_ address to send Artist's
     * additional payee for primary sales revenue to. Will be null if no
     * revenue is due to additional payee for primary sales (gas optimization).
     * @dev this always returns four addresses and four revenues, but if the
     * revenue is zero, the corresponding address will be address(0). It is up
     * to the contract performing the revenue split to handle this
     * appropriately.
     */
    function getPrimaryRevenueSplits(
        uint256 _projectId,
        uint256 _price
    )
        external
        view
        returns (
            uint256 renderProviderRevenue_,
            address payable renderProviderAddress_,
            uint256 platformProviderRevenue_,
            address payable platformProviderAddress_,
            uint256 artistRevenue_,
            address payable artistAddress_,
            uint256 additionalPayeePrimaryRevenue_,
            address payable additionalPayeePrimaryAddress_
        )
    {
        ProjectFinance storage projectFinance = projectIdToFinancials[
            _projectId
        ];
        // calculate revenues – this is a three-way split between the
        // render provider, the platform provider, and the artist, and
        // is safe to perform this given that in the case of loss of
        // precision Solidity will round down.
        uint256 projectFunds = _price;
        renderProviderRevenue_ =
            (_price * uint256(_renderProviderPrimarySalesPercentage)) /
            ONE_HUNDRED;
        // renderProviderRevenue_ percentage is always <=100, so guaranteed to never underflow
        projectFunds -= renderProviderRevenue_;
        platformProviderRevenue_ =
            (_price * uint256(_platformProviderPrimarySalesPercentage)) /
            ONE_HUNDRED;
        // platformProviderRevenue_ percentage is always <=100, so guaranteed to never underflow
        projectFunds -= platformProviderRevenue_;
        additionalPayeePrimaryRevenue_ =
            (projectFunds *
                projectFinance.additionalPayeePrimarySalesPercentage) /
            ONE_HUNDRED;
        // projectIdToAdditionalPayeePrimarySalesPercentage is always
        // <=100, so guaranteed to never underflow
        artistRevenue_ = projectFunds - additionalPayeePrimaryRevenue_;
        // set addresses from storage
        renderProviderAddress_ = renderProviderPrimarySalesAddress;
        platformProviderAddress_ = platformProviderPrimarySalesAddress;
        if (artistRevenue_ > 0) {
            artistAddress_ = projectFinance.artistAddress;
        }
        if (additionalPayeePrimaryRevenue_ > 0) {
            additionalPayeePrimaryAddress_ = projectFinance
                .additionalPayeePrimarySales;
        }
    }

    /**
     * @notice Returns external asset dependency for project `_projectId` at index `_index`.
     * If the dependencyType is ONCHAIN, the `data` field will contain the extrated bytecode data and `cid`
     * will be an empty string. Conversly, for any other dependencyType, the `data` field will be an empty string
     * and the `bytecodeAddress` will point to the zero address.
     */
    function projectExternalAssetDependencyByIndex(
        uint256 _projectId,
        uint256 _index
    ) external view returns (ExternalAssetDependencyWithData memory) {
        ExternalAssetDependency storage _dependency = projects[_projectId]
            .externalAssetDependencies[_index];
        address _bytecodeAddress = _dependency.bytecodeAddress;

        return
            ExternalAssetDependencyWithData({
                dependencyType: _dependency.dependencyType,
                cid: _dependency.cid,
                bytecodeAddress: _bytecodeAddress,
                data: (_dependency.dependencyType ==
                    ExternalAssetDependencyType.ONCHAIN)
                    ? _readFromBytecode(_bytecodeAddress)
                    : ""
            });
    }

    /**
     * @notice Returns external asset dependency count for project `_projectId` at index `_index`.
     */
    function projectExternalAssetDependencyCount(
        uint256 _projectId
    ) external view returns (uint256) {
        return uint256(projects[_projectId].externalAssetDependencyCount);
    }

    /**
     * @notice Backwards-compatible (pre-V3) getter returning contract admin
     * @return address Address of contract admin (same as owner)
     */
    function admin() external view returns (address) {
        return owner();
    }

    /**
     * @notice Gets the project ID for a given `_tokenId`.
     * @param _tokenId Token ID to be queried.
     * @return _projectId Project ID for given `_tokenId`.
     */
    function tokenIdToProjectId(
        uint256 _tokenId
    ) public pure returns (uint256 _projectId) {
        return _tokenId / ONE_MILLION;
    }

    /**
     * @notice Convenience function that returns whether `_sender` is allowed
     * to call function with selector `_selector` on contract `_contract`, as
     * determined by this contract's current Admin ACL contract. Expected use
     * cases include minter contracts checking if caller is allowed to call
     * admin-gated functions on minter contracts.
     * @param _sender Address of the sender calling function with selector
     * `_selector` on contract `_contract`.
     * @param _contract Address of the contract being called by `_sender`.
     * @param _selector Function selector of the function being called by
     * `_sender`.
     * @return bool Whether `_sender` is allowed to call function with selector
     * `_selector` on contract `_contract`.
     * @dev assumes the Admin ACL contract is the owner of this contract, which
     * is expected to always be true.
     * @dev adminACLContract is expected to either be null address (if owner
     * has renounced ownership), or conform to IAdminACLV0 interface. Check for
     * null address first to avoid revert when admin has renounced ownership.
     */
    function adminACLAllowed(
        address _sender,
        address _contract,
        bytes4 _selector
    ) public returns (bool) {
        return
            owner() != address(0) &&
            adminACLContract.allowed(_sender, _contract, _selector);
    }

    /**
     * @notice Returns contract owner. Set to deployer's address by default on
     * contract deployment.
     * @return address Address of contract owner.
     * @dev ref: https://docs.openzeppelin.com/contracts/4.x/api/access#Ownable
     * @dev owner role was called `admin` prior to V3 core contract
     */
    function owner()
        public
        view
        override(Ownable, IGenArt721CoreContractV3_Base)
        returns (address)
    {
        return Ownable.owner();
    }

    /**
     * @notice Gets token URI for token ID `_tokenId`.
     * @param _tokenId Token ID to be queried.
     * @return string URI of token ID `_tokenId`.
     * @dev token URIs are the concatenation of the project base URI and the
     * token ID.
     */
    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        _onlyValidTokenId(_tokenId);
        string memory _projectBaseURI = projects[tokenIdToProjectId(_tokenId)]
            .projectBaseURI;
        return string.concat(_projectBaseURI, toString(_tokenId));
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IManifold).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @notice Forbids new projects from being created
     * @dev only performs operation and emits event if contract is not already
     * forbidding new projects.
     */
    function _forbidNewProjects() internal {
        if (!newProjectsForbidden) {
            newProjectsForbidden = true;
            emit PlatformUpdated(FIELD_NEW_PROJECTS_FORBIDDEN);
        }
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     * @param newOwner New owner.
     * @dev owner role was called `admin` prior to V3 core contract.
     * @dev Overrides and wraps OpenZeppelin's _transferOwnership function to
     * also update adminACLContract for improved introspection.
     */
    function _transferOwnership(address newOwner) internal override {
        Ownable._transferOwnership(newOwner);
        adminACLContract = IAdminACLV0(newOwner);
    }

    /**
     * @notice Updates sales addresses for the platform and render providers to
     * the input parameters.
     * @param _renderProviderPrimarySalesAddress Address of new primary sales
     * payment address.
     * @param _renderProviderSecondarySalesAddress Address of new secondary sales
     * payment address.
     * @param _platformProviderPrimarySalesAddress Address of new primary sales
     * payment address.
     * @param _platformProviderSecondarySalesAddress Address of new secondary sales
     * payment address.
     * @dev Note that this method does not check that the input address is
     * not `address(0)`, as it is expected that callers of this method should
     * perform input validation where applicable.
     */
    function _updateProviderSalesAddresses(
        address _renderProviderPrimarySalesAddress,
        address _renderProviderSecondarySalesAddress,
        address _platformProviderPrimarySalesAddress,
        address _platformProviderSecondarySalesAddress
    ) internal {
        platformProviderPrimarySalesAddress = payable(
            _platformProviderPrimarySalesAddress
        );
        platformProviderSecondarySalesAddress = payable(
            _platformProviderSecondarySalesAddress
        );
        renderProviderPrimarySalesAddress = payable(
            _renderProviderPrimarySalesAddress
        );
        renderProviderSecondarySalesAddress = payable(
            _renderProviderSecondarySalesAddress
        );
        emit PlatformUpdated(FIELD_PROVIDER_SALES_ADDRESSES);
    }

    /**
     * @notice Updates randomizer address to `_randomizerAddress`.
     * @param _randomizerAddress New randomizer address.
     * @dev Note that this method does not check that the input address is
     * not `address(0)`, as it is expected that callers of this method should
     * perform input validation where applicable.
     */
    function _updateRandomizerAddress(address _randomizerAddress) internal {
        randomizerContract = IRandomizer_V3CoreBase(_randomizerAddress);
        // populate historical randomizer array
        _historicalRandomizerAddresses.push(_randomizerAddress);
        emit PlatformUpdated(FIELD_RANDOMIZER_ADDRESS);
    }

    /**
     * @notice Updates default base URI to `_defaultBaseURI`.
     * When new projects are added, their `projectBaseURI` is automatically
     * initialized to `_defaultBaseURI`.
     * @param _defaultBaseURI New default base URI.
     * @dev Note that this method does not check that the input string is not
     * the empty string, as it is expected that callers of this method should
     * perform input validation where applicable.
     */
    function _updateDefaultBaseURI(string memory _defaultBaseURI) internal {
        defaultBaseURI = _defaultBaseURI;
        emit PlatformUpdated(FIELD_DEFAULT_BASE_URI);
    }

    /**
     * @notice Internal function to complete a project.
     * @param _projectId Project ID to be completed.
     */
    function _completeProject(uint256 _projectId) internal {
        projects[_projectId].completedTimestamp = uint64(block.timestamp);
        emit ProjectUpdated(_projectId, FIELD_PROJECT_COMPLETED);
    }

    /**
     * @notice Internal function that returns whether a project is unlocked.
     * Projects automatically lock four weeks after they are completed.
     * Projects are considered completed when they have been invoked the
     * maximum number of times.
     * @param _projectId Project ID to be queried.
     * @return bool true if project is unlocked, false otherwise.
     * @dev This also enforces that the `_projectId` passed in is valid.
     */
    function _projectUnlocked(uint256 _projectId) internal view returns (bool) {
        _onlyValidProjectId(_projectId);
        uint256 projectCompletedTimestamp = projects[_projectId]
            .completedTimestamp;
        bool projectOpen = projectCompletedTimestamp == 0;
        return
            projectOpen ||
            (block.timestamp - projectCompletedTimestamp <
                FOUR_WEEKS_IN_SECONDS);
    }

    /**
     * Helper for calling `BytecodeStorageReader` external library reader method,
     * added for bytecode size reduction purposes.
     */
    function _readFromBytecode(
        address _address
    ) internal view returns (string memory) {
        return BytecodeStorageReader.readFromBytecode(_address);
    }

    // strings library from OpenZeppelin, modified for no constants

    bytes16 private _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(
        uint256 value,
        uint256 length
    ) internal view returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal view returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

interface IAdminACLV0 {
    /**
     * @notice Token ID `_tokenId` minted to `_to`.
     * @param previousSuperAdmin The previous superAdmin address.
     * @param newSuperAdmin The new superAdmin address.
     * @param genArt721CoreAddressesToUpdate Array of genArt721Core
     * addresses to update to the new superAdmin, for indexing purposes only.
     */
    event SuperAdminTransferred(
        address indexed previousSuperAdmin,
        address indexed newSuperAdmin,
        address[] genArt721CoreAddressesToUpdate
    );

    /// Type of the Admin ACL contract, e.g. "AdminACLV0"
    function AdminACLType() external view returns (string memory);

    /// super admin address
    function superAdmin() external view returns (address);

    /**
     * @notice Calls transferOwnership on other contract from this contract.
     * This is useful for updating to a new AdminACL contract.
     * @dev this function should be gated to only superAdmin-like addresses.
     */
    function transferOwnershipOn(
        address _contract,
        address _newAdminACL
    ) external;

    /**
     * @notice Calls renounceOwnership on other contract from this contract.
     * @dev this function should be gated to only superAdmin-like addresses.
     */
    function renounceOwnershipOn(address _contract) external;

    /**
     * @notice Checks if sender `_sender` is allowed to call function with selector
     * `_selector` on contract `_contract`.
     */
    function allowed(
        address _sender,
        address _contract,
        bytes4 _selector
    ) external returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.
pragma solidity ^0.8.19;

interface IDependencyRegistryCompatibleV0 {
    /// Dependency registry managed by Art Blocks
    function artblocksDependencyRegistryAddress()
        external
        view
        returns (address);

    /**
     * @notice Returns script information for project `_projectId`.
     * @param _projectId Project to be queried.
     * @return scriptTypeAndVersion Project's script type and version
     * (e.g. "p5js(atSymbol)1.0.0")
     * @return aspectRatio Aspect ratio of project (e.g. "1" for square,
     * "1.77777778" for 16:9, etc.)
     * @return scriptCount Count of scripts for project
     */
    function projectScriptDetails(
        uint256 _projectId
    )
        external
        view
        returns (
            string memory scriptTypeAndVersion,
            string memory aspectRatio,
            uint256 scriptCount
        );
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.
pragma solidity ^0.8.0;

interface IEngineRegistryV0 {
    /// ADDRESS
    /**
     * @notice contract has been registered as a contract that is powered by the Art Blocks Engine.
     */
    event ContractRegistered(
        address indexed _contractAddress,
        bytes32 _coreVersion,
        bytes32 _coreType
    );

    /// ADDRESS
    /**
     * @notice contract has been unregistered as a contract that is powered by the Art Blocks Engine.
     */
    event ContractUnregistered(address indexed _contractAddress);

    /**
     * @notice Emits a `ContractRegistered` event with the provided information.
     * @dev this function should be gated to only deployer addresses.
     */
    function registerContract(
        address _contractAddress,
        bytes32 _coreVersion,
        bytes32 _coreType
    ) external;

    /**
     * @notice Emits a `ContractUnregistered` event with the provided information, validating that the provided
     *         address was indeed previously registered.
     * @dev this function should be gated to only deployer addresses.
     */
    function unregisterContract(address _contractAddress) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

interface IGenArt721CoreContractExposesHashSeed {
    // function to read the hash-seed for a given tokenId
    function tokenIdToHashSeed(
        uint256 _tokenId
    ) external view returns (bytes12);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

import "./IAdminACLV0.sol";
/// use the Royalty Registry's IManifold interface for token royalties
import "./IManifold.sol";

/**
 * @title This interface is intended to house interface items that are common
 * across all GenArt721CoreContractV3 flagship and derivative implementations.
 * This interface extends the IManifold royalty interface in order to
 * add support the Royalty Registry by default.
 * @author Art Blocks Inc.
 */
interface IGenArt721CoreContractV3_Base is IManifold {
    /**
     * @notice Token ID `_tokenId` minted to `_to`.
     */
    event Mint(address indexed _to, uint256 indexed _tokenId);

    /**
     * @notice currentMinter updated to `_currentMinter`.
     * @dev Implemented starting with V3 core
     */
    event MinterUpdated(address indexed _currentMinter);

    /**
     * @notice Platform updated on bytes32-encoded field `_field`.
     */
    event PlatformUpdated(bytes32 indexed _field);

    /**
     * @notice Project ID `_projectId` updated on bytes32-encoded field
     * `_update`.
     */
    event ProjectUpdated(uint256 indexed _projectId, bytes32 indexed _update);

    event ProposedArtistAddressesAndSplits(
        uint256 indexed _projectId,
        address _artistAddress,
        address _additionalPayeePrimarySales,
        uint256 _additionalPayeePrimarySalesPercentage,
        address _additionalPayeeSecondarySales,
        uint256 _additionalPayeeSecondarySalesPercentage
    );

    event AcceptedArtistAddressesAndSplits(uint256 indexed _projectId);

    // version and type of the core contract
    // coreVersion is a string of the form "0.x.y"
    function coreVersion() external view returns (string memory);

    // coreType is a string of the form "GenArt721CoreV3"
    function coreType() external view returns (string memory);

    // owner (pre-V3 was named admin) of contract
    // this is expected to be an Admin ACL contract for V3
    function owner() external view returns (address);

    // Admin ACL contract for V3, will be at the address owner()
    function adminACLContract() external returns (IAdminACLV0);

    // backwards-compatible (pre-V3) admin - equal to owner()
    function admin() external view returns (address);

    /**
     * Function determining if _sender is allowed to call function with
     * selector _selector on contract `_contract`. Intended to be used with
     * peripheral contracts such as minters, as well as internally by the
     * core contract itself.
     */
    function adminACLAllowed(
        address _sender,
        address _contract,
        bytes4 _selector
    ) external returns (bool);

    /// getter function of public variable
    function startingProjectId() external view returns (uint256);

    // getter function of public variable
    function nextProjectId() external view returns (uint256);

    // getter function of public mapping
    function tokenIdToProjectId(
        uint256 tokenId
    ) external view returns (uint256 projectId);

    // @dev this is not available in V0
    function isMintWhitelisted(address minter) external view returns (bool);

    function projectIdToArtistAddress(
        uint256 _projectId
    ) external view returns (address payable);

    function projectIdToAdditionalPayeePrimarySales(
        uint256 _projectId
    ) external view returns (address payable);

    function projectIdToAdditionalPayeePrimarySalesPercentage(
        uint256 _projectId
    ) external view returns (uint256);

    function projectIdToSecondaryMarketRoyaltyPercentage(
        uint256 _projectId
    ) external view returns (uint256);

    function projectURIInfo(
        uint256 _projectId
    ) external view returns (string memory projectBaseURI);

    // @dev new function in V3
    function projectStateData(
        uint256 _projectId
    )
        external
        view
        returns (
            uint256 invocations,
            uint256 maxInvocations,
            bool active,
            bool paused,
            uint256 completedTimestamp,
            bool locked
        );

    function projectDetails(
        uint256 _projectId
    )
        external
        view
        returns (
            string memory projectName,
            string memory artist,
            string memory description,
            string memory website,
            string memory license
        );

    function projectScriptDetails(
        uint256 _projectId
    )
        external
        view
        returns (
            string memory scriptTypeAndVersion,
            string memory aspectRatio,
            uint256 scriptCount
        );

    function projectScriptByIndex(
        uint256 _projectId,
        uint256 _index
    ) external view returns (string memory);

    function tokenIdToHash(uint256 _tokenId) external view returns (bytes32);

    // function to set a token's hash (must be guarded)
    function setTokenHash_8PT(uint256 _tokenId, bytes32 _hash) external;

    // @dev gas-optimized signature in V3 for `mint`
    function mint_Ecf(
        address _to,
        uint256 _projectId,
        address _by
    ) external returns (uint256 tokenId);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

import "./IAdminACLV0.sol";
import "./IGenArt721CoreContractV3_Engine.sol";

/**
 * @title This interface is intended to house interface items that are common
 * across all GenArt721CoreContractV3 Engine Flex and derivative implementations.
 * @author Art Blocks Inc.
 */
interface IGenArt721CoreContractV3_Engine_Flex is
    IGenArt721CoreContractV3_Engine
{
    /**
     * @notice When an external asset dependency is updated or added, this event is emitted.
     * @param _projectId The project ID of the project that was updated.
     * @param _index The index of the external asset dependency that was updated.
     * @param _cid The content ID of the external asset dependency. This is an empty string
     * if the dependency type is ONCHAIN.
     * @param _dependencyType The type of the external asset dependency.
     * @param _externalAssetDependencyCount The number of external asset dependencies.
     */
    event ExternalAssetDependencyUpdated(
        uint256 indexed _projectId,
        uint256 indexed _index,
        string _cid,
        ExternalAssetDependencyType _dependencyType,
        uint24 _externalAssetDependencyCount
    );

    /**
     * @notice The project id `_projectId` has had an external asset dependency removed at index `_index`.
     */
    event ExternalAssetDependencyRemoved(
        uint256 indexed _projectId,
        uint256 indexed _index
    );

    /**
     * @notice The preferred gateway for dependency type `_dependencyType` has been updated to `_gatewayAddress`.
     */
    event GatewayUpdated(
        ExternalAssetDependencyType indexed _dependencyType,
        string _gatewayAddress
    );

    /**
     * @notice The project id `_projectId` has had all external asset dependencies locked.
     * @dev This is a one-way operation. Once locked, the external asset dependencies cannot be updated.
     */
    event ProjectExternalAssetDependenciesLocked(uint256 indexed _projectId);

    /**
     * @notice An external asset dependency type. Can be one of IPFS, ARWEAVE, or ONCHAIN.
     */
    enum ExternalAssetDependencyType {
        IPFS,
        ARWEAVE,
        ONCHAIN
    }

    /**
     * @notice An external asset dependency. This is a struct that contains the CID of the dependency,
     * the type of the dependency, and the address of the bytecode for this dependency.
     */
    struct ExternalAssetDependency {
        string cid;
        ExternalAssetDependencyType dependencyType;
        address bytecodeAddress;
    }

    /**
     * @notice An external asset dependency with data. This is a convenience struct that contains the CID of the dependency,
     * the type of the dependency, the address of the bytecode for this dependency, and the data retrieved from this bytecode address.
     */
    struct ExternalAssetDependencyWithData {
        string cid;
        ExternalAssetDependencyType dependencyType;
        address bytecodeAddress;
        string data;
    }

    // preferredIPFSGateway is a url string
    function preferredIPFSGateway() external view returns (string memory);

    // preferredArweaveGateway is a url string
    function preferredArweaveGateway() external view returns (string memory);

    // updates the preferred IPFS gateway
    function updateIPFSGateway(string calldata _gateway) external;

    // updates the preferred Arweave gateway
    function updateArweaveGateway(string calldata _gateway) external;

    // locks the external asset dependencies for a project
    function lockProjectExternalAssetDependencies(uint256 _projectId) external;

    // updates the external asset dependency for a project at a given index
    function updateProjectExternalAssetDependency(
        uint256 _projectId,
        uint256 _index,
        string memory _cidOrData,
        ExternalAssetDependencyType _dependencyType
    ) external;

    // adds an external asset dependency for a project
    function addProjectExternalAssetDependency(
        uint256 _projectId,
        string memory _cidOrData,
        ExternalAssetDependencyType _dependencyType
    ) external;

    // removes an external asset dependency for a project at a given index
    function removeProjectExternalAssetDependency(
        uint256 _projectId,
        uint256 _index
    ) external;

    // getter function for project external asset dependencies
    function projectExternalAssetDependencyByIndex(
        uint256 _projectId,
        uint256 _index
    ) external view returns (ExternalAssetDependencyWithData memory);

    // getter function project external asset dependency count
    function projectExternalAssetDependencyCount(
        uint256 _projectId
    ) external view returns (uint256);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

import "./IAdminACLV0.sol";
import "./IGenArt721CoreContractV3_Base.sol";

interface IGenArt721CoreContractV3_Engine is IGenArt721CoreContractV3_Base {
    // @dev new function in V3
    function getPrimaryRevenueSplits(
        uint256 _projectId,
        uint256 _price
    )
        external
        view
        returns (
            uint256 renderProviderRevenue_,
            address payable renderProviderAddress_,
            uint256 platformProviderRevenue_,
            address payable platformProviderAddress_,
            uint256 artistRevenue_,
            address payable artistAddress_,
            uint256 additionalPayeePrimaryRevenue_,
            address payable additionalPayeePrimaryAddress_
        );

    // @dev The render provider primary sales payment address
    function renderProviderPrimarySalesAddress()
        external
        view
        returns (address payable);

    // @dev The platform provider primary sales payment address
    function platformProviderPrimarySalesAddress()
        external
        view
        returns (address payable);

    // @dev Percentage of primary sales allocated to the render provider
    function renderProviderPrimarySalesPercentage()
        external
        view
        returns (uint256);

    // @dev Percentage of primary sales allocated to the platform provider
    function platformProviderPrimarySalesPercentage()
        external
        view
        returns (uint256);

    // @dev The render provider secondary sales royalties payment address
    function renderProviderSecondarySalesAddress()
        external
        view
        returns (address payable);

    // @dev The platform provider secondary sales royalties payment address
    function platformProviderSecondarySalesAddress()
        external
        view
        returns (address payable);

    // @dev Basis points of secondary sales allocated to the render provider
    function renderProviderSecondarySalesBPS() external view returns (uint256);

    // @dev Basis points of secondary sales allocated to the platform provider
    function platformProviderSecondarySalesBPS()
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @dev Royalty Registry interface, used to support the Royalty Registry.
/// @dev Source: https://github.com/manifoldxyz/royalty-registry-solidity/blob/main/contracts/specs/IManifold.sol

/// @author: manifold.xyz

/**
 * @dev Royalty interface for creator core classes
 */
interface IManifold {
    /**
     * @dev Get royalites of a token.  Returns list of receivers and basisPoints
     *
     *  bytes4(keccak256('getRoyalties(uint256)')) == 0xbb3bafd6
     *
     *  => 0xbb3bafd6 = 0xbb3bafd6
     */
    function getRoyalties(
        uint256 tokenId
    ) external view returns (address payable[] memory, uint256[] memory);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Creatd By: Art Blocks Inc.

pragma solidity ^0.8.0;

interface IRandomizer_V3CoreBase {
    // When a core contract calls this, it can be assured that the randomizer
    // will set a bytes32 hash for tokenId `_tokenId` on the core contract.
    function assignTokenHash(uint256 _tokenId) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

/**
 * @title Art Blocks Script Storage Library
 * @notice Utilize contract bytecode as persistent storage for large chunks of script string data.
 *         This library is intended to have an external deployed copy that is released in the future,
 *         and, as such, has been designed to support both updated V1 (versioned, with purging removed)
 *         reads as well as backwards-compatible reads for both a) the unversioned "V0" storage contracts
 *         which were deployed by the original version of this libary and b) contracts that were deployed
 *         using one of the SSTORE2 implementations referenced below.
 *         For these pre-V1 storage contracts (which themselves did not have any explicit versioning semantics)
 *         backwards-compatible reads are optimistic, and only expected to work for contracts actually
 *         deployed by the original version of this library – and may fail ungracefully if attempted to be
 *         used to read from other contracts.
 *         This library is split into two components, intended to be updated in tandem, and thus included
 *         here in the same source file. One component is an internal library that is intended to be embedded
 *         directly into other contracts and provides all _write_ functionality. The other is a public library
 *         that is intended to be deployed as a standalone contract and provides all _read_ functionality.
 *
 * @author Art Blocks Inc.
 * @author Modified from 0xSequence (https://github.com/0xsequence/sstore2/blob/master/contracts/SSTORE2.sol)
 * @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SSTORE2.sol)
 *
 * @dev Compared to the above two rerferenced libraries, this contracts-as-storage implementation makes a few
 *      notably different design decisions:
 *      - uses the `string` data type for input/output on reads, rather than speaking in bytes directly
 *      - stores the "writer" address (library user) in the deployed contract bytes, which is useful for
 *        on-chain introspection and provenance purposes
 *      - stores a very simple versioning string in the deployed contract bytes, which captures the version
 *        of the library that was used to deploy the storage contract and useful for supporting future
 *        compatibility management as this library evolves (e.g. in response to EOF v1 migration plans)
 *      Also, given that much of this library is written in assembly, this library makes use of a slightly
 *      different convention (when compared to the rest of the Art Blocks smart contract repo) around
 *      pre-defining return values in some cases in order to simplify need to directly memory manage these
 *      return values.
 */

/**
 * @title Art Blocks Script Storage Library (Public, Reads)
 * @author Art Blocks Inc.
 * @notice The public library for reading from storage contracts. This library is intended to be deployed as a
 *         standalone contract, and provides all _read_ functionality.
 */
library BytecodeStorageReader {
    // Define the set of known valid version strings that may be stored in the deployed storage contract bytecode
    // note: These are all intentionally exactly 32-bytes and are null-terminated. Null-termination is used due
    //       to this being the standard expected formatting in common web3 tooling such as ethers.js. Please see
    //       the following for additional context: https://docs.ethers.org/v5/api/utils/strings/#Bytes32String
    // Used for storage contracts that were deployed by an unknown source
    bytes32 public constant UNKNOWN_VERSION_STRING =
        "UNKNOWN_VERSION_STRING_________ ";
    // Pre-dates versioning string, so this doesn't actually exist in any deployed contracts,
    // but is useful for backwards-compatible semantics with original version of this library
    bytes32 public constant V0_VERSION_STRING =
        "BytecodeStorage_V0.0.0_________ ";
    // The first versioned storage contract, deployed by an updated version of this library
    bytes32 public constant V1_VERSION_STRING =
        "BytecodeStorage_V1.0.0_________ ";
    // The current version of this library.
    bytes32 public constant CURRENT_VERSION = V1_VERSION_STRING;

    //---------------------------------------------------------------------------------------------------------------//
    // Starting Index | Size | Ending Index | Description                                                            //
    //---------------------------------------------------------------------------------------------------------------//
    // 0              | N/A  | 0            |                                                                        //
    // 0              | 1    | 1            | single byte opcode for making the storage contract non-executable      //
    // 1              | 32   | 33           | the 32 byte slot used for storing a basic versioning string            //
    // 33             | 32   | 65           | the 32 bytes for storing the deploying contract's (0-padded) address   //
    //---------------------------------------------------------------------------------------------------------------//
    // Define the offset for where the "meta bytes" end, and the "data bytes" begin. Note that this is a manually
    // calculated value, and must be updated if the above table is changed. It is expected that tests will fail
    // loudly if these values are not updated in-step with eachother.
    uint256 private constant VERSION_OFFSET = 1;
    uint256 private constant ADDRESS_OFFSET = 33;
    uint256 private constant DATA_OFFSET = 65;

    // Define the set of known *historic* offset values for where the "meta bytes" end, and the "data bytes" begin.
    // SSTORE2 deployed storage contracts take the general format of:
    // concat(0x00, data)
    // note: this is true for both variants of the SSTORE2 library
    uint256 private constant SSTORE2_DATA_OFFSET = 1;
    // V0 deployed storage contracts take the general format of:
    // concat(gated-cleanup-logic, deployer-address, data)
    uint256 private constant V0_ADDRESS_OFFSET = 72;
    uint256 private constant V0_DATA_OFFSET = 104;
    // V1 deployed storage contracts take the general format of:
    // concat(invalid opcode, version, deployer-address, data)
    uint256 private constant V1_ADDRESS_OFFSET = ADDRESS_OFFSET;
    uint256 private constant V1_DATA_OFFSET = DATA_OFFSET;

    /*//////////////////////////////////////////////////////////////
                               READ LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Read a string from contract bytecode
     * @param _address address of deployed contract with bytecode stored in the V0 or V1 format
     * @return data string read from contract bytecode
     * @dev This function performs input validation that the contract to read is in an expected format
     */
    function readFromBytecode(
        address _address
    ) public view returns (string memory data) {
        uint256 dataOffset = _bytecodeDataOffsetAt(_address);
        return string(readBytesFromBytecode(_address, dataOffset));
    }

    /**
     * @notice Read the bytes from contract bytecode that was written to the EVM using SSTORE2
     * @param _address address of deployed contract with bytecode stored in the SSTORE2 format
     * @return data bytes read from contract bytecode
     * @dev This function performs no input validation on the provided contract,
     *      other than that there is content to read (but not that its a "storage contract")
     */
    function readBytesFromSSTORE2Bytecode(
        address _address
    ) public view returns (bytes memory data) {
        return readBytesFromBytecode(_address, SSTORE2_DATA_OFFSET);
    }

    /**
     * @notice Read the bytes from contract bytecode, with an explicitly provided starting offset
     * @param _address address of deployed contract with bytecode stored in the V0 or V1 format
     * @param _offset offset to read from in contract bytecode, explicitly provided (not calculated)
     * @return data bytes read from contract bytecode
     * @dev This function performs no input validation on the provided contract,
     *      other than that there is content to read (but not that its a "storage contract")
     */
    function readBytesFromBytecode(
        address _address,
        uint256 _offset
    ) public view returns (bytes memory data) {
        // get the size of the bytecode
        uint256 bytecodeSize = _bytecodeSizeAt(_address);
        // handle case where address contains code < _offset
        if (bytecodeSize < _offset) {
            revert("ContractAsStorage: Read Error");
        }

        // handle case where address contains code >= dataOffset
        // decrement by dataOffset to account for header info
        uint256 size;
        unchecked {
            size = bytecodeSize - _offset;
        }

        assembly {
            // allocate free memory
            data := mload(0x40)
            // update free memory pointer
            // use and(x, not(0x1f) as cheaper equivalent to sub(x, mod(x, 0x20)).
            // adding 0x1f to size + logic above ensures the free memory pointer
            // remains word-aligned, following the Solidity convention.
            mstore(0x40, add(data, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            // store length of data in first 32 bytes
            mstore(data, size)
            // copy code to memory, excluding the deployer-address
            extcodecopy(_address, add(data, 0x20), _offset, size)
        }
    }

    /**
     * @notice Get address for deployer for given contract bytecode
     * @param _address address of deployed contract with bytecode stored in the V0 or V1 format
     * @return writerAddress address read from contract bytecode
     */
    function getWriterAddressForBytecode(
        address _address
    ) public view returns (address) {
        // get the size of the data
        uint256 bytecodeSize = _bytecodeSizeAt(_address);
        // the dataOffset for the bytecode
        uint256 addressOffset = _bytecodeAddressOffsetAt(_address);
        // handle case where address contains code < addressOffset + 32 (address takes a whole slot)
        if (bytecodeSize < (addressOffset + 32)) {
            revert("ContractAsStorage: Read Error");
        }

        assembly {
            // allocate free memory
            let writerAddress := mload(0x40)
            // shift free memory pointer by one slot
            mstore(0x40, add(mload(0x40), 0x20))
            // copy the 32-byte address of the data contract writer to memory
            // note: this relies on the assumption noted at the top-level of
            //       this file that the storage layout for the deployed
            //       contracts-as-storage contract looks like::
            //       | invalid opcode | version-string (unless v0) | deployer-address (padded) | data |
            extcodecopy(
                _address,
                writerAddress,
                addressOffset,
                0x20 // full 32-bytes, as address is expected to be zero-padded
            )
            return(
                writerAddress,
                0x20 // return size is entire slot, as it is zero-padded
            )
        }
    }

    /**
     * @notice Get version for given contract bytecode
     * @param _address address of deployed contract with bytecode stored in the V0 or V1 format
     * @return version version read from contract bytecode
     */
    function getLibraryVersionForBytecode(
        address _address
    ) public view returns (bytes32) {
        return _bytecodeVersionAt(_address);
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the size of the bytecode at address `_address`
     * @param _address address that may or may not contain bytecode
     * @return size size of the bytecode code at `_address`
     */
    function _bytecodeSizeAt(
        address _address
    ) private view returns (uint256 size) {
        assembly {
            size := extcodesize(_address)
        }
        if (size == 0) {
            revert("ContractAsStorage: Read Error");
        }
    }

    /**
     * @notice Returns the offset of the data in the bytecode at address `_address`
     * @param _address address that may or may not contain bytecode
     * @return dataOffset offset of data in bytecode if a known version, otherwise 0
     */
    function _bytecodeDataOffsetAt(
        address _address
    ) private view returns (uint256 dataOffset) {
        bytes32 version = _bytecodeVersionAt(_address);
        if (version == V1_VERSION_STRING) {
            dataOffset = V1_DATA_OFFSET;
        } else if (version == V0_VERSION_STRING) {
            dataOffset = V0_DATA_OFFSET;
        } else {
            // unknown version, revert
            revert("ContractAsStorage: Unsupported Version");
        }
    }

    /**
     * @notice Returns the offset of the address in the bytecode at address `_address`
     * @param _address address that may or may not contain bytecode
     * @return addressOffset offset of address in bytecode if a known version, otherwise 0
     */
    function _bytecodeAddressOffsetAt(
        address _address
    ) private view returns (uint256 addressOffset) {
        bytes32 version = _bytecodeVersionAt(_address);
        if (version == V1_VERSION_STRING) {
            addressOffset = V1_ADDRESS_OFFSET;
        } else if (version == V0_VERSION_STRING) {
            addressOffset = V0_ADDRESS_OFFSET;
        } else {
            // unknown version, revert
            revert("ContractAsStorage: Unsupported Version");
        }
    }

    /**
     * @notice Get version string for given contract bytecode
     * @param _address address of deployed contract with bytecode stored in the V0 or V1 format
     * @return version version string read from contract bytecode
     */
    function _bytecodeVersionAt(
        address _address
    ) private view returns (bytes32 version) {
        // get the size of the data
        uint256 bytecodeSize = _bytecodeSizeAt(_address);
        // handle case where address contains code < minimum expected version string size,
        // by returning early with the unknown version string
        if (bytecodeSize < (VERSION_OFFSET + 32)) {
            return UNKNOWN_VERSION_STRING;
        }

        assembly {
            // allocate free memory
            let versionString := mload(0x40)
            // shift free memory pointer by one slot
            mstore(0x40, add(mload(0x40), 0x20))
            // copy the 32-byte version string of the bytecode library to memory
            // note: this relies on the assumption noted at the top-level of
            //       this file that the storage layout for the deployed
            //       contracts-as-storage contract looks like:
            //       | invalid opcode | version-string (unless v0) | deployer-address (padded) | data |
            extcodecopy(
                _address,
                versionString,
                VERSION_OFFSET,
                0x20 // 32-byte version string
            )
            // note: must check against literal strings, as Yul does not allow for
            //       dynamic strings in switch statements.
            switch mload(versionString)
            case "BytecodeStorage_V1.0.0_________ " {
                version := V1_VERSION_STRING
            }
            case 0x2060486000396000513314601057fe5b60013614601957fe5b6000357fff0000 {
                // the v0 variant of this library pre-dates formal versioning w/ version strings,
                // so we check the first 32 bytes of the execution bytecode itself which
                // is static and known across all storage contracts deployed with the first version
                // of this library.
                version := V0_VERSION_STRING
            }
            default {
                version := UNKNOWN_VERSION_STRING
            }
        }
    }
}

/**
 * @title Art Blocks Script Storage Library (Internal, Writes)
 * @author Art Blocks Inc.
 * @notice The internal library for writing to storage contracts. This library is intended to be deployed
 *         within library client contracts that use this library to perform _write_ operations on storage.
 */
library BytecodeStorageWriter {
    /*//////////////////////////////////////////////////////////////
                           WRITE LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Write a string to contract bytecode
     * @param _data string to be written to contract. No input validation is performed on this parameter.
     * @param address_ address of deployed contract with bytecode stored in the V0 or V1 format
     */
    function writeToBytecode(
        string memory _data
    ) internal returns (address address_) {
        // prefix bytecode with
        bytes memory creationCode = abi.encodePacked(
            //---------------------------------------------------------------------------------------------------------------//
            // Opcode  | Opcode + Arguments  | Description  | Stack View                                                     //
            //---------------------------------------------------------------------------------------------------------------//
            // a.) creation code returns all code in the contract except for the first 11 (0B in hex) bytes, as these 11
            //     bytes are the creation code itself which we do not want to store in the deployed storage contract result
            //---------------------------------------------------------------------------------------------------------------//
            // 0x60    |  0x60_0B            | PUSH1 11     | codeOffset                                                     //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset                                                   //
            // 0x81    |  0x81               | DUP2         | codeOffset 0 codeOffset                                        //
            // 0x38    |  0x38               | CODESIZE     | codeSize codeOffset 0 codeOffset                               //
            // 0x03    |  0x03               | SUB          | (codeSize - codeOffset) 0 codeOffset                           //
            // 0x80    |  0x80               | DUP          | (codeSize - codeOffset) (codeSize - codeOffset) 0 codeOffset   //
            // 0x92    |  0x92               | SWAP3        | codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset)   //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset) //
            // 0x39    |  0x39               | CODECOPY     | 0 (codeSize - codeOffset)                                      //
            // 0xF3    |  0xF3               | RETURN       |                                                                //
            //---------------------------------------------------------------------------------------------------------------//
            // (11 bytes)
            hex"60_0B_59_81_38_03_80_92_59_39_F3",
            //---------------------------------------------------------------------------------------------------------------//
            // b.) ensure that the deployed storage contract is non-executeable (first opcode is the `invalid` opcode)
            //---------------------------------------------------------------------------------------------------------------//
            //---------------------------------------------------------------------------------------------------------------//
            // 0xFE    |  0xFE               | INVALID      |                                                                //
            //---------------------------------------------------------------------------------------------------------------//
            // (1 byte)
            hex"FE",
            //---------------------------------------------------------------------------------------------------------------//
            // c.) store the version string, which is already represented as a 32-byte value
            //---------------------------------------------------------------------------------------------------------------//
            // (32 bytes)
            BytecodeStorageReader.CURRENT_VERSION,
            //---------------------------------------------------------------------------------------------------------------//
            // d.) store the deploying-contract's address with 0-padding to fit a 20-byte address into a 32-byte slot
            //---------------------------------------------------------------------------------------------------------------//
            // (12 bytes)
            hex"00_00_00_00_00_00_00_00_00_00_00_00",
            // (20 bytes)
            address(this),
            // uploaded data (stored as bytecode) comes last
            _data
        );

        assembly {
            // deploy a new contract with the generated creation code.
            // start 32 bytes into creationCode to avoid copying the byte length.
            address_ := create(0, add(creationCode, 0x20), mload(creationCode))
        }

        // address must be non-zero if contract was deployed successfully
        require(address_ != address(0), "ContractAsStorage: Write Error");
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.
// Inspired by: https://ethereum.stackexchange.com/a/123950/103422

pragma solidity ^0.8.0;

/**
 * @dev Operations on bytes32 data type, dealing with conversion to string.
 */
library Bytes32Strings {
    /**
     * @dev Intended to convert a `bytes32`-encoded string literal to `string`.
     * Trims zero padding to arrive at original string literal.
     */
    function toString(
        bytes32 source
    ) internal pure returns (string memory result) {
        uint8 length = 0;
        while (source[length] != 0 && length < 32) {
            length++;
        }
        assembly {
            // free memory pointer
            result := mload(0x40)
            // update free memory pointer to new "memory end"
            // (offset is 64-bytes: 32 for length, 32 for data)
            mstore(0x40, add(result, 0x40))
            // store length in first 32-byte memory slot
            mstore(result, length)
            // write actual data in second 32-byte memory slot
            mstore(add(result, 0x20), source)
        }
    }

    /**
     * @dev Intended to check if a `bytes32`-encoded string contains a given
     * character with UTF-8 character code `utf8CharCode exactly `targetQty`
     * times. Does not support searching for multi-byte characters, only
     * characters with UTF-8 character codes < 0x80.
     */
    function containsExactCharacterQty(
        bytes32 source,
        uint8 utf8CharCode,
        uint8 targetQty
    ) internal pure returns (bool) {
        uint8 _occurrences = 0;
        uint8 i;
        for (i = 0; i < 32; ) {
            uint8 _charCode = uint8(source[i]);
            // if not a null byte, or a multi-byte UTF-8 character, check match
            if (_charCode != 0 && _charCode < 0x80) {
                if (_charCode == utf8CharCode) {
                    unchecked {
                        // no risk of overflow since max 32 iterations < max uin8=255
                        ++_occurrences;
                    }
                }
            }
            unchecked {
                // no risk of overflow since max 32 iterations < max uin8=255
                ++i;
            }
        }
        return _occurrences == targetQty;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "@openzeppelin-4.7/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin-4.7/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin-4.7/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin-4.7/contracts/utils/Address.sol";
import "@openzeppelin-4.7/contracts/utils/Context.sol";
import "@openzeppelin-4.7/contracts/utils/Strings.sol";
import "@openzeppelin-4.7/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Forked version of the OpenZeppelin v4.7.1 ERC721 contract. Utilizes a
 * struct to pack owner and hash seed into a single storage slot.
 * ---------------------
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721_PackedHashSeed is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    /// struct to pack a token owner and hash seed into same storage slot
    struct OwnerAndHashSeed {
        // 20 bytes for address of token's owner
        address owner;
        // remaining 12 bytes allocated to token hash seed
        bytes12 hashSeed;
    }

    /// mapping of token ID to OwnerAndHashSeed
    /// @dev visibility internal so inheriting contracts can access
    mapping(uint256 => OwnerAndHashSeed) internal _ownersAndHashSeeds;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(
        address owner
    ) public view virtual override returns (uint256) {
        require(
            owner != address(0),
            "ERC721: address zero is not a valid owner"
        );
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(
        uint256 tokenId
    ) public view virtual override returns (address) {
        address owner = _ownersAndHashSeeds[tokenId].owner;
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721_PackedHashSeed.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(
        uint256 tokenId
    ) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner nor approved"
        );
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownersAndHashSeeds[tokenId].owner != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) internal view virtual returns (bool) {
        address owner = ERC721_PackedHashSeed.ownerOf(tokenId);
        return (spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _ownersAndHashSeeds[tokenId].owner = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721_PackedHashSeed.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _ownersAndHashSeeds[tokenId].owner;

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ERC721_PackedHashSeed.ownerOf(tokenId) == from,
            "ERC721: transfer from incorrect owner"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _ownersAndHashSeeds[tokenId].owner = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721_PackedHashSeed.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}