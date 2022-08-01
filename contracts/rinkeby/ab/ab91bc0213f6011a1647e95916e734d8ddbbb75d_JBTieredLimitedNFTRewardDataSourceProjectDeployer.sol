// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@jbx-protocol/contracts-v2/contracts/abstract/JBOperatable.sol';
import '@jbx-protocol/contracts-v2/contracts/interfaces/IJBController.sol';
import '@jbx-protocol/contracts-v2/contracts/interfaces/IJBProjects.sol';
import '@jbx-protocol/contracts-v2/contracts/libraries/JBOperations.sol';
import './JBTieredLimitedNFTRewardDataSource.sol';
import './interfaces/IJBTieredLimitedNFTRewardDataSourceProjectDeployer.sol';

/**
  @notice
  Deploys a project with a tiered limited NFT reward data source attached.

  @dev
  Adheres to -
  IJBTieredLimitedNFTRewardDataSourceProjectDeployer: General interface for the generic controller methods in this contract that interacts with funding cycles and tokens according to the protocol's rules.

  @dev
  Inherits from -
  JBOperatable: Several functions in this contract can only be accessed by a project owner, or an address that has been preconfifigured to be an operator of the project.
*/
contract JBTieredLimitedNFTRewardDataSourceProjectDeployer is
  IJBTieredLimitedNFTRewardDataSourceProjectDeployer,
  JBOperatable
{
  //*********************************************************************//
  // --------------- public immutable stored properties ---------------- //
  //*********************************************************************//

  /** 
    @notice
    The controller with which new projects should be deployed. 
  */
  IJBController public immutable override controller;

  //*********************************************************************//
  // -------------------------- constructor ---------------------------- //
  //*********************************************************************//

  /** 
    @param _controller The controller with which new projects should be deployed. 
    @param _operatorStore A contract storing operator assignments.
  */
  constructor(IJBController _controller, IJBOperatorStore _operatorStore)
    JBOperatable(_operatorStore)
  {
    controller = _controller;
  }

  //*********************************************************************//
  // ---------------------- external transactions ---------------------- //
  //*********************************************************************//

  /** 
    @notice 
    Launches a new project with a tiered NFT rewards data source attached.

    @param _owner The address to set as the owner of the project. The project ERC-721 will be owned by this address.
    @param _deployTieredNFTRewardDataSourceData Data necessary to fulfill the transaction to deploy a tiered limited NFT rewward data source.
    @param _launchProjectData Data necessary to fulfill the transaction to launch a project.

    @return projectId The ID of the newly configured project.
  */
  function launchProjectFor(
    address _owner,
    JBDeployTieredNFTRewardDataSourceData memory _deployTieredNFTRewardDataSourceData,
    JBLaunchProjectData memory _launchProjectData
  ) external override returns (uint256 projectId) {
    // Get the project ID, optimistically knowing it will be one greater than the current count.
    projectId = controller.projects().count() + 1;

    // Deploy the data source contract.
    address _dataSourceAddress = deployDataSource(projectId, _deployTieredNFTRewardDataSourceData);

    // Set the data source address as the data source of the provided metadata.
    _launchProjectData.metadata.dataSource = _dataSourceAddress;

    // Set the project to use the data source for it's pay function.
    _launchProjectData.metadata.useDataSourceForPay = true;

    // Launch the project.
    _launchProjectFor(_owner, _launchProjectData);
  }

  /** 
    @notice 
    Launches funding cycle's for a project with a tiered NFT rewards data source attached.

    @dev
    Only a project owner or operator can launch its funding cycles.

    @param _projectId The ID of the project having funding cycles launched. 
    @param _deployTieredNFTRewardDataSourceData Data necessary to fulfill the transaction to deploy a tiered limited NFT rewward data source.
    @param _launchFundingCyclesData Data necessary to fulfill the transaction to launch funding cycles for the project.

    @return configuration The configuration of the funding cycle that was successfully created.  
  */
  function launchFundingCyclesFor(
    uint256 _projectId,
    JBDeployTieredNFTRewardDataSourceData memory _deployTieredNFTRewardDataSourceData,
    JBLaunchFundingCyclesData memory _launchFundingCyclesData
  )
    external
    override
    requirePermission(
      controller.projects().ownerOf(_projectId),
      _projectId,
      JBOperations.RECONFIGURE
    )
    returns (uint256 configuration)
  {
    // Deploy the data source contract.
    address _dataSourceAddress = deployDataSource(_projectId, _deployTieredNFTRewardDataSourceData);

    // Set the data source address as the data source of the provided metadata.
    _launchFundingCyclesData.metadata.dataSource = _dataSourceAddress;

    // Set the project to use the data source for it's pay function.
    _launchFundingCyclesData.metadata.useDataSourceForPay = true;

    // Launch the funding cycles.
    return _launchFundingCyclesFor(_projectId, _launchFundingCyclesData);
  }

  /** 
    @notice 
    Reconfigures funding cycles for a project with a tiered NFT rewards data source attached.

    @dev
    Only a project's owner or a designated operator can configure its funding cycles.

    @param _projectId The ID of the project having funding cycles launched. 
    @param _deployTieredNFTRewardDataSourceData Data necessary to fulfill the transaction to deploy a tiered limited NFT rewward data source.
    @param _reconfigureFundingCyclesData Data necessary to fulfill the transaction to reconfigure funding cycles for the project.

    @return configuration The configuration of the funding cycle that was successfully reconfigured.
  */
  function reconfigureFundingCyclesOf(
    uint256 _projectId,
    JBDeployTieredNFTRewardDataSourceData memory _deployTieredNFTRewardDataSourceData,
    JBReconfigureFundingCyclesData memory _reconfigureFundingCyclesData
  )
    external
    override
    requirePermission(
      controller.projects().ownerOf(_projectId),
      _projectId,
      JBOperations.RECONFIGURE
    )
    returns (uint256 configuration)
  {
    // Deploy the data source contract.
    address _dataSourceAddress = deployDataSource(_projectId, _deployTieredNFTRewardDataSourceData);

    // Set the data source address as the data source of the provided metadata.
    _reconfigureFundingCyclesData.metadata.dataSource = _dataSourceAddress;

    // Set the project to use the data source for it's pay function.
    _reconfigureFundingCyclesData.metadata.useDataSourceForPay = true;

    // Reconfigure the funding cycles.
    return _reconfigureFundingCyclesOf(_projectId, _reconfigureFundingCyclesData);
  }

  //*********************************************************************//
  // ----------------------- public transactions ----------------------- //
  //*********************************************************************//

  /** 
    @notice
    Deploys a Tiered limited NFT reward data source.

    @param _projectId The ID of the project for which the data source should apply.
    @param _deployTieredNFTRewardDataSourceData Data necessary to fulfill the transaction to deploy a tiered limited NFT rewward data source.

    @return newDatasource The address of the newly deployed data source.
  */
  function deployDataSource(
    uint256 _projectId,
    JBDeployTieredNFTRewardDataSourceData memory _deployTieredNFTRewardDataSourceData
  ) public override returns (address newDatasource) {
    newDatasource = address(
      new JBTieredLimitedNFTRewardDataSource(
        _projectId,
        _deployTieredNFTRewardDataSourceData.directory,
        _deployTieredNFTRewardDataSourceData.name,
        _deployTieredNFTRewardDataSourceData.symbol,
        _deployTieredNFTRewardDataSourceData.tokenUriResolver,
        _deployTieredNFTRewardDataSourceData.contractUri,
        _deployTieredNFTRewardDataSourceData.baseUri,
        _deployTieredNFTRewardDataSourceData.owner,
        _deployTieredNFTRewardDataSourceData.tierData,
        _deployTieredNFTRewardDataSourceData.store
      )
    );

    emit DatasourceDeployed(_projectId, newDatasource);
  }

  //*********************************************************************//
  // ------------------------ internal functions ----------------------- //
  //*********************************************************************//

  /** 
    @notice
    Launches a project.

    @param _owner The address to set as the owner of the project. The project ERC-721 will be owned by this address.
    @param _launchProjectData Data necessary to fulfill the transaction to launch the project.
  */
  function _launchProjectFor(address _owner, JBLaunchProjectData memory _launchProjectData)
    internal
  {
    controller.launchProjectFor(
      _owner,
      _launchProjectData.projectMetadata,
      _launchProjectData.data,
      _launchProjectData.metadata,
      _launchProjectData.mustStartAtOrAfter,
      _launchProjectData.groupedSplits,
      _launchProjectData.fundAccessConstraints,
      _launchProjectData.terminals,
      _launchProjectData.memo
    );
  }

  /** 
    @notice
    Launches funding cycles for a project.

    @param _projectId The ID of the project having funding cycles launched. 
    @param _launchFundingCyclesData Data necessary to fulfill the transaction to launch funding cycles for the project.

    @return configuration The configuration of the funding cycle that was successfully created.  
  */
  function _launchFundingCyclesFor(
    uint256 _projectId,
    JBLaunchFundingCyclesData memory _launchFundingCyclesData
  ) internal returns (uint256) {
    return
      controller.launchFundingCyclesFor(
        _projectId,
        _launchFundingCyclesData.data,
        _launchFundingCyclesData.metadata,
        _launchFundingCyclesData.mustStartAtOrAfter,
        _launchFundingCyclesData.groupedSplits,
        _launchFundingCyclesData.fundAccessConstraints,
        _launchFundingCyclesData.terminals,
        _launchFundingCyclesData.memo
      );
  }

  /** 
    @notice
    Reconfigure funding cycles for a project.

    @param _projectId The ID of the project having funding cycles launched. 
    @param _reconfigureFundingCyclesData Data necessary to fulfill the transaction to launch funding cycles for the project.

    @return The configuration of the funding cycle that was successfully reconfigured.
  */
  function _reconfigureFundingCyclesOf(
    uint256 _projectId,
    JBReconfigureFundingCyclesData memory _reconfigureFundingCyclesData
  ) internal returns (uint256) {
    return
      controller.reconfigureFundingCyclesOf(
        _projectId,
        _reconfigureFundingCyclesData.data,
        _reconfigureFundingCyclesData.metadata,
        _reconfigureFundingCyclesData.mustStartAtOrAfter,
        _reconfigureFundingCyclesData.groupedSplits,
        _reconfigureFundingCyclesData.fundAccessConstraints,
        _reconfigureFundingCyclesData.memo
      );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBOperatable.sol';

/** 
  @notice
  Modifiers to allow access to functions based on the message sender's operator status.

  @dev
  Adheres to -
  IJBOperatable: General interface for the methods in this contract that interact with the blockchain's state according to the protocol's rules.
*/
abstract contract JBOperatable is IJBOperatable {
  //*********************************************************************//
  // --------------------------- custom errors -------------------------- //
  //*********************************************************************//
  error UNAUTHORIZED();

  //*********************************************************************//
  // ---------------------------- modifiers ---------------------------- //
  //*********************************************************************//

  /** 
    @notice
    Only allows the speficied account or an operator of the account to proceed. 

    @param _account The account to check for.
    @param _domain The domain namespace to look for an operator within. 
    @param _permissionIndex The index of the permission to check for. 
  */
  modifier requirePermission(
    address _account,
    uint256 _domain,
    uint256 _permissionIndex
  ) {
    _requirePermission(_account, _domain, _permissionIndex);
    _;
  }

  /** 
    @notice
    Only allows the speficied account, an operator of the account to proceed, or a truthy override flag. 

    @param _account The account to check for.
    @param _domain The domain namespace to look for an operator within. 
    @param _permissionIndex The index of the permission to check for. 
    @param _override A condition to force allowance for.
  */
  modifier requirePermissionAllowingOverride(
    address _account,
    uint256 _domain,
    uint256 _permissionIndex,
    bool _override
  ) {
    _requirePermissionAllowingOverride(_account, _domain, _permissionIndex, _override);
    _;
  }

  //*********************************************************************//
  // ---------------- public immutable stored properties --------------- //
  //*********************************************************************//

  /** 
    @notice 
    A contract storing operator assignments.
  */
  IJBOperatorStore public immutable override operatorStore;

  //*********************************************************************//
  // -------------------------- constructor ---------------------------- //
  //*********************************************************************//

  /** 
    @param _operatorStore A contract storing operator assignments.
  */
  constructor(IJBOperatorStore _operatorStore) {
    operatorStore = _operatorStore;
  }

  //*********************************************************************//
  // -------------------------- internal views ------------------------- //
  //*********************************************************************//

  /** 
    @notice
    Require the message sender is either the account or has the specified permission.

    @param _account The account to allow.
    @param _domain The domain namespace within which the permission index will be checked.
    @param _permissionIndex The permission index that an operator must have within the specified domain to be allowed.
  */
  function _requirePermission(
    address _account,
    uint256 _domain,
    uint256 _permissionIndex
  ) internal view {
    if (
      msg.sender != _account &&
      !operatorStore.hasPermission(msg.sender, _account, _domain, _permissionIndex) &&
      !operatorStore.hasPermission(msg.sender, _account, 0, _permissionIndex)
    ) revert UNAUTHORIZED();
  }

  /** 
    @notice
    Require the message sender is either the account, has the specified permission, or the override condition is true.

    @param _account The account to allow.
    @param _domain The domain namespace within which the permission index will be checked.
    @param _domain The permission index that an operator must have within the specified domain to be allowed.
    @param _override The override condition to allow.
  */
  function _requirePermissionAllowingOverride(
    address _account,
    uint256 _domain,
    uint256 _permissionIndex,
    bool _override
  ) internal view {
    if (
      !_override &&
      msg.sender != _account &&
      !operatorStore.hasPermission(msg.sender, _account, _domain, _permissionIndex) &&
      !operatorStore.hasPermission(msg.sender, _account, 0, _permissionIndex)
    ) revert UNAUTHORIZED();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../structs/JBFundAccessConstraints.sol';
import './../structs/JBFundingCycleData.sol';
import './../structs/JBFundingCycleMetadata.sol';
import './../structs/JBGroupedSplits.sol';
import './../structs/JBProjectMetadata.sol';
import './IJBDirectory.sol';
import './IJBFundingCycleStore.sol';
import './IJBMigratable.sol';
import './IJBPaymentTerminal.sol';
import './IJBSplitsStore.sol';
import './IJBToken.sol';
import './IJBTokenStore.sol';

interface IJBController is IERC165 {
  event LaunchProject(uint256 configuration, uint256 projectId, string memo, address caller);

  event LaunchFundingCycles(uint256 configuration, uint256 projectId, string memo, address caller);

  event ReconfigureFundingCycles(
    uint256 configuration,
    uint256 projectId,
    string memo,
    address caller
  );

  event SetFundAccessConstraints(
    uint256 indexed fundingCycleConfiguration,
    uint256 indexed fundingCycleNumber,
    uint256 indexed projectId,
    JBFundAccessConstraints constraints,
    address caller
  );

  event DistributeReservedTokens(
    uint256 indexed fundingCycleConfiguration,
    uint256 indexed fundingCycleNumber,
    uint256 indexed projectId,
    address beneficiary,
    uint256 tokenCount,
    uint256 beneficiaryTokenCount,
    string memo,
    address caller
  );

  event DistributeToReservedTokenSplit(
    uint256 indexed projectId,
    uint256 indexed domain,
    uint256 indexed group,
    JBSplit split,
    uint256 tokenCount,
    address caller
  );

  event MintTokens(
    address indexed beneficiary,
    uint256 indexed projectId,
    uint256 tokenCount,
    uint256 beneficiaryTokenCount,
    string memo,
    uint256 reservedRate,
    address caller
  );

  event BurnTokens(
    address indexed holder,
    uint256 indexed projectId,
    uint256 tokenCount,
    string memo,
    address caller
  );

  event Migrate(uint256 indexed projectId, IJBMigratable to, address caller);

  event PrepMigration(uint256 indexed projectId, address from, address caller);

  function projects() external view returns (IJBProjects);

  function fundingCycleStore() external view returns (IJBFundingCycleStore);

  function tokenStore() external view returns (IJBTokenStore);

  function splitsStore() external view returns (IJBSplitsStore);

  function directory() external view returns (IJBDirectory);

  function reservedTokenBalanceOf(uint256 _projectId, uint256 _reservedRate)
    external
    view
    returns (uint256);

  function distributionLimitOf(
    uint256 _projectId,
    uint256 _configuration,
    IJBPaymentTerminal _terminal,
    address _token
  ) external view returns (uint256 distributionLimit, uint256 distributionLimitCurrency);

  function overflowAllowanceOf(
    uint256 _projectId,
    uint256 _configuration,
    IJBPaymentTerminal _terminal,
    address _token
  ) external view returns (uint256 overflowAllowance, uint256 overflowAllowanceCurrency);

  function totalOutstandingTokensOf(uint256 _projectId, uint256 _reservedRate)
    external
    view
    returns (uint256);

  function getFundingCycleOf(uint256 _projectId, uint256 _configuration)
    external
    view
    returns (JBFundingCycle memory fundingCycle, JBFundingCycleMetadata memory metadata);

  function latestConfiguredFundingCycleOf(uint256 _projectId)
    external
    view
    returns (
      JBFundingCycle memory,
      JBFundingCycleMetadata memory metadata,
      JBBallotState
    );

  function currentFundingCycleOf(uint256 _projectId)
    external
    view
    returns (JBFundingCycle memory fundingCycle, JBFundingCycleMetadata memory metadata);

  function queuedFundingCycleOf(uint256 _projectId)
    external
    view
    returns (JBFundingCycle memory fundingCycle, JBFundingCycleMetadata memory metadata);

  function launchProjectFor(
    address _owner,
    JBProjectMetadata calldata _projectMetadata,
    JBFundingCycleData calldata _data,
    JBFundingCycleMetadata calldata _metadata,
    uint256 _mustStartAtOrAfter,
    JBGroupedSplits[] memory _groupedSplits,
    JBFundAccessConstraints[] memory _fundAccessConstraints,
    IJBPaymentTerminal[] memory _terminals,
    string calldata _memo
  ) external returns (uint256 projectId);

  function launchFundingCyclesFor(
    uint256 _projectId,
    JBFundingCycleData calldata _data,
    JBFundingCycleMetadata calldata _metadata,
    uint256 _mustStartAtOrAfter,
    JBGroupedSplits[] memory _groupedSplits,
    JBFundAccessConstraints[] memory _fundAccessConstraints,
    IJBPaymentTerminal[] memory _terminals,
    string calldata _memo
  ) external returns (uint256 configuration);

  function reconfigureFundingCyclesOf(
    uint256 _projectId,
    JBFundingCycleData calldata _data,
    JBFundingCycleMetadata calldata _metadata,
    uint256 _mustStartAtOrAfter,
    JBGroupedSplits[] memory _groupedSplits,
    JBFundAccessConstraints[] memory _fundAccessConstraints,
    string calldata _memo
  ) external returns (uint256);

  function issueTokenFor(
    uint256 _projectId,
    string calldata _name,
    string calldata _symbol
  ) external returns (IJBToken token);

  function changeTokenOf(
    uint256 _projectId,
    IJBToken _token,
    address _newOwner
  ) external;

  function mintTokensOf(
    uint256 _projectId,
    uint256 _tokenCount,
    address _beneficiary,
    string calldata _memo,
    bool _preferClaimedTokens,
    bool _useReservedRate
  ) external returns (uint256 beneficiaryTokenCount);

  function burnTokensOf(
    address _holder,
    uint256 _projectId,
    uint256 _tokenCount,
    string calldata _memo,
    bool _preferClaimedTokens
  ) external;

  function distributeReservedTokensOf(uint256 _projectId, string memory _memo)
    external
    returns (uint256);

  function migrate(uint256 _projectId, IJBMigratable _to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import './../structs/JBProjectMetadata.sol';
import './IJBTokenUriResolver.sol';

interface IJBProjects is IERC721 {
  event Create(
    uint256 indexed projectId,
    address indexed owner,
    JBProjectMetadata metadata,
    address caller
  );

  event SetMetadata(uint256 indexed projectId, JBProjectMetadata metadata, address caller);

  event SetTokenUriResolver(IJBTokenUriResolver indexed resolver, address caller);

  function count() external view returns (uint256);

  function metadataContentOf(uint256 _projectId, uint256 _domain)
    external
    view
    returns (string memory);

  function tokenUriResolver() external view returns (IJBTokenUriResolver);

  function createFor(address _owner, JBProjectMetadata calldata _metadata)
    external
    returns (uint256 projectId);

  function setMetadataOf(uint256 _projectId, JBProjectMetadata calldata _metadata) external;

  function setTokenUriResolver(IJBTokenUriResolver _newResolver) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

library JBOperations {
  uint256 public constant RECONFIGURE = 1;
  uint256 public constant REDEEM = 2;
  uint256 public constant MIGRATE_CONTROLLER = 3;
  uint256 public constant MIGRATE_TERMINAL = 4;
  uint256 public constant PROCESS_FEES = 5;
  uint256 public constant SET_METADATA = 6;
  uint256 public constant ISSUE = 7;
  uint256 public constant CHANGE_TOKEN = 8;
  uint256 public constant MINT = 9;
  uint256 public constant BURN = 10;
  uint256 public constant CLAIM = 11;
  uint256 public constant TRANSFER = 12;
  uint256 public constant REQUIRE_CLAIM = 13;
  uint256 public constant SET_CONTROLLER = 14;
  uint256 public constant SET_TERMINALS = 15;
  uint256 public constant SET_PRIMARY_TERMINAL = 16;
  uint256 public constant USE_ALLOWANCE = 17;
  uint256 public constant SET_SPLITS = 18;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@jbx-protocol/contracts-v2/contracts/libraries/JBTokens.sol';
import '@jbx-protocol/contracts-v2/contracts/libraries/JBConstants.sol';
import '@openzeppelin/contracts/governance/utils/Votes.sol';
import './abstract/JBNFTRewardDataSource.sol';
import './interfaces/IJBTieredLimitedNFTRewardDataSource.sol';
import './interfaces/ITokenSupplyDetails.sol';
import './libraries/JBIpfsDecoder.sol';

/**
  @title
  JBTieredLimitedNFTRewardDataSource

  @notice
  Juicebox data source that offers NFTs to project contributors.

  @notice 
  This contract allows project creators to reward contributors with NFTs. 
  Intended use is to incentivize initial project support by minting a limited number of NFTs to the first N contributors among various price tiers.
*/
contract JBTieredLimitedNFTRewardDataSource is
  IJBTieredLimitedNFTRewardDataSource,
  // ITokenSupplyDetails,
  JBNFTRewardDataSource,
  Votes
{
  //*********************************************************************//
  // --------------------------- custom errors ------------------------- //
  //*********************************************************************//

  error OVERSPENDING();

  //*********************************************************************//
  // --------------- public immutable stored properties ---------------- //
  //*********************************************************************//

  // /**
  //   @notice
  //   The token to expect contributions to be made in.
  // */
  // address public immutable override contributionToken;

  /**
    @notice
    The contract that stores and manages the nft's data.
  */
  IJBTieredLimitedNFTRewardDataSourceStore public immutable override store;

  //*********************************************************************//
  // --------------------- public stored properties -------------------- //
  //*********************************************************************//

  /**
    @notice
    The common base for the tokenUri's

    @dev
    No setter to insure immutability
  */
  string public baseUri;

  //*********************************************************************//
  // ------------------------- external views -------------------------- //
  //*********************************************************************//

  // /**
  //   @notice
  //   The total supply of issued NFTs from all tiers.

  //   @return supply The total number of NFTs between all tiers.
  // */
  // function totalSupply() external view override returns (uint256 supply) {
  //   return store.totalSupply(address(this));
  // }

  // /**
  //   @notice
  //   The total number of tokens with the given ID.
  //   @return Either 1 if the token has been minted, or 0 if it hasnt.
  // */
  // function tokenSupplyOf(uint256 _tokenId) external view override returns (uint256) {
  //   return ownerOf(_tokenId) != address(0) ? 1 : 0;
  // }

  // /**
  //   @notice
  //   The total number of tokens owned by the given owner.
  //   @param _owner The address to check the balance of.
  //   @return The number of tokens owners by the owner.
  // */
  // function totalOwnerBalanceOf(address _owner) external view override returns (uint256) {
  //   return balanceOf(_owner);
  // }

  // /**
  //   @notice
  //   The total number of tokens with the given ID owned by the given owner.
  //   @param _owner The address to check the balance of.
  //   @param _tokenId The ID of the token to check the owner's balance of.
  //   @return Either 1 if the owner has the token, or 0 if it does not.
  // */
  // function ownerTokenBalanceOf(address _owner, uint256 _tokenId)
  //   external
  //   view
  //   override
  //   returns (uint256)
  // {
  //   return ownerOf(_tokenId) == _owner ? 1 : 0;
  // }

  /** 
    @notice 
    The total number of tokens owned by the given owner. 

    @param _owner The address to check the balance of.

    @return balance The number of tokens owners by the owner accross all tiers.
  */
  function balanceOf(address _owner) public view override returns (uint256 balance) {
    return store.balanceOf(address(this), _owner);
  }

  //*********************************************************************//
  // -------------------------- public views --------------------------- //
  //*********************************************************************//

  /** 
    @notice
    TokenURI of the provided token ID.

    @dev
    Defer to the tokenUriResolver if set, otherwise, use the tokenUri set with the tier.

    @param _tokenId The ID of the token to get the tier tokenUri for. 

    @return The token URI corresponding with the tier or the tokenUriResolver URI.
  */
  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    // A token without an owner doesn't have a URI.
    if (_owners[_tokenId] == address(0)) return '';

    // If a token URI resolver is provided, use it to resolve the token URI.
    if (address(tokenUriResolver) != address(0)) return tokenUriResolver.getUri(_tokenId);

    // Return the token URI for the token's tier.
    return JBIpfsDecoder.decode(baseUri, store.tier(address(this), _tokenId).data.tokenUri);
  }

  // /**
  //   @notice
  //   The cumulative weight the given token IDs have in redemptions compared to the `totalRedemptionWeight`.

  //   @param _tokenIds The IDs of the tokens to get the cumulative redemption weight of.

  //   @return weight The weight.
  // */
  // function redemptionWeightOf(uint256[] memory _tokenIds)
  //   public
  //   view
  //   override
  //   returns (uint256 weight)
  // {
  //   return store.redemptionWeightOf(address(this), _tokenIds);
  // }

  // /**
  //   @notice
  //   The cumulative weight that all token IDs have in redemptions.

  //   @return weight The total weight.
  // */
  // function totalRedemptionWeight() public view override returns (uint256 weight) {
  //   return store.totalRedemptionWeight(address(this));
  // }

  // /**
  //   @notice
  //   Indicates if this contract adheres to the specified interface.

  //   @dev
  //   See {IERC165-supportsInterface}.

  //   @param _interfaceId The ID of the interface to check for adherance to.
  // */
  // function supportsInterface(bytes4 _interfaceId) public view override returns (bool) {
  //   return
  //     _interfaceId == type(IJBTieredLimitedNFTRewardDataSource).interfaceId ||
  //     _interfaceId == type(ITokenSupplyDetails).interfaceId ||
  //     super.supportsInterface(_interfaceId);
  // }

  //*********************************************************************//
  // -------------------------- constructor ---------------------------- //
  //*********************************************************************//

  /**
    @param _projectId The ID of the project for which this NFT should be minted in response to payments made. 
    @param _directory The directory of terminals and controllers for projects.
    @param _name The name of the token.
    @param _symbol The symbol that the token should be represented by.
    @param _tokenUriResolver A contract responsible for resolving the token URI for each token ID.
    @param _contractUri A URI where contract metadata can be found. 
    @param _owner The address that should own this contract.
    @param _tierData The tiers according to which token distribution will be made. Must be passed in order of contribution floor, with implied increasing value.
    @param _store A contract that stores the NFT's data.
  */
  constructor(
    uint256 _projectId,
    IJBDirectory _directory,
    string memory _name,
    string memory _symbol,
    IJBTokenUriResolver _tokenUriResolver,
    string memory _contractUri,
    string memory _baseUri,
    address _owner,
    JBNFTRewardTierData[] memory _tierData,
    IJBTieredLimitedNFTRewardDataSourceStore _store
  )
    JBNFTRewardDataSource(
      _projectId,
      _directory,
      _name,
      _symbol,
      _tokenUriResolver,
      _contractUri,
      _owner
    )
    EIP712(_name, '1')
  {
    baseUri = _baseUri;
    store = _store;

    _store.recordAddTierData(_tierData, true);
  }

  //*********************************************************************//
  // ---------------------- external transactions ---------------------- //
  //*********************************************************************//

  /** 
    @notice
    Mint a token within the tier for the provided value.

    @dev
    Only a project owner can mint tokens.

    @param _tierId The ID of the tier to mint within.
    @param _count The number of reserved tokens to mint. 
  */
  function mintReservesFor(uint256 _tierId, uint256 _count) external override {
    // Record the minted reserves for the tier.
    uint256[] memory _tokenIds = store.recordMintReservesFor(_tierId, _count);

    // Keep a reference to the token ID being iterated on.
    uint256 _tokenId;

    address _reservedTokenBeneficiary = store.reservedTokenBeneficiary(address(this));

    for (uint256 _i; _i < _count; ) {
      // Set the token ID.
      _tokenId = _tokenIds[_i];

      // Mint the token.
      _mint(_reservedTokenBeneficiary, _tokenId);

      emit MintReservedToken(_tokenId, _tierId, _reservedTokenBeneficiary, msg.sender);

      unchecked {
        ++_i;
      }
    }
  }

  /** 
    @notice
    Adjust the tiers mintable in this contract, adhering to any locked tier constraints. 

    @param _tierDataToAdd An array of tier data to add.
    @param _tierIdsToRemove An array of tier IDs to remove.
  */
  function adjustTiers(
    JBNFTRewardTierData[] memory _tierDataToAdd,
    uint256[] memory _tierIdsToRemove
  ) external override onlyOwner {
    // Add tiers.
    if (_tierDataToAdd.length != 0) store.recordAddTierData(_tierDataToAdd, false);

    // Remove tiers.
    if (_tierIdsToRemove.length != 0) store.recordRemoveTierIds(_tierIdsToRemove);
  }

  /** 
    @notice
    Sets the beneificiary of the reserved tokens. 

    @param _beneficiary The beneificiary of the reserved tokens.
  */
  function setReservedTokenBeneficiary(address _beneficiary) external override onlyOwner {
    // Set the beneficiary.
    store.recordSetReservedTokenBeneficiary(_beneficiary);

    emit SetReservedTokenBeneficiary(_beneficiary, msg.sender);
  }

  //*********************************************************************//
  // ------------------------ internal functions ----------------------- //
  //*********************************************************************//

  // /**
  //   @notice
  //   Mints a token for a given contribution to the beneficiary.

  //   @dev
  //   `_data.metadata` should include the reward tiers being requested in increments of 8 bits starting at bits 32.

  //   @param _data The Juicebox standard project contribution data.
  // */
  // function _processContribution(JBDidPayData calldata _data) internal override {
  //   // Make sure the contribution is being made in the expected token.
  //   if (_data.amount.token != JBTokens.ETH) return;

  //   // Set the leftover amount as the initial value.
  //   uint256 _leftoverAmount = _data.amount.value;

  //   // Keep a reference to a flag indicating if a mint is expected from discretionary funds. Defaults to false, meaning to mint is expected.
  //   bool _expectMintFromExtraFunds;

  //   // Keep a reference to the flag indicating if funds should be refunded if not spent. Defaults to false, meaning no funds will be returned.
  //   bool _dontOverspend;

  //   // skip the first 32 bits which are used by the JB protocol to pass the paying project's ID when paying from a JBSplit.
  //   // Check the 4 bits interfaceId to verify the metadata is intended for this contract
  //   if (
  //     _data.metadata.length > 36 &&
  //     bytes4(_data.metadata[32:36]) == type(IJBNFTRewardDataSource).interfaceId
  //   ) {
  //     // Keep references to the metadata properties.
  //     bool _dontMint;
  //     uint8[] memory _tierIdsToMint;

  //     // Decode the metadata
  //     (, , _dontMint, _expectMintFromExtraFunds, _dontOverspend, _tierIdsToMint) = abi.decode(
  //       _data.metadata,
  //       (bytes32, bytes4, bool, bool, bool, uint8[])
  //     );

  //     // Don't mint if not desired.
  //     if (_dontMint) return;

  //     // Mint rewards if they were specified. If there are no rewards but a default NFT should be minted, do so.
  //     if (_tierIdsToMint.length != 0)
  //       _leftoverAmount = _mintAll(_leftoverAmount, _tierIdsToMint, _data.beneficiary);
  //   }

  //   // If there are funds leftover, mint the best available with it.
  //   if (_leftoverAmount != 0)
  //     _leftoverAmount = _mintBestAvailableTier(
  //       _leftoverAmount,
  //       _data.beneficiary,
  //       _expectMintFromExtraFunds
  //     );

  //   // Make sure there are no leftover funds after minting if not expected.
  //   if (_dontOverspend && _leftoverAmount != 0) revert OVERSPENDING();
  // }

  /** 
    @notice
    Mints a token in the best available tier.

    @param _amount The amount to base the mint on.
    @param _beneficiary The address to mint for.
    @param _expectMint A flag indicating if a mint was expected.

    @return  leftoverAmount The amount leftover after the mint.
  */
  function _mintBestAvailableTier(
    uint256 _amount,
    address _beneficiary,
    bool _expectMint
  ) internal returns (uint256 leftoverAmount) {
    // Keep a reference to the token ID.
    uint256 _tokenId;

    // Keep a reference to the tier ID.
    uint256 _tierId;

    // Record the mint.
    (_tokenId, _tierId, leftoverAmount) = store.recordMintBestAvailableTier(
      _amount,
      _beneficiary,
      _expectMint
    );

    // If there's no best tier, return.
    if (_tokenId == 0) return _amount;

    // Mint the tokens.
    _mint(_beneficiary, _tokenId);

    emit Mint(_tokenId, _tierId, _beneficiary, _amount - leftoverAmount, 0, msg.sender);
  }

  /** 
    @notice
    Mints a token in all provided tiers.

    @param _amount The amount to base the mints on. All mints' price floors must fit in this amount.
    @param _mintTierIds An array of tier IDs that the user wants to mint
    @param _beneficiary The address to mint for.

    @return leftoverAmount The amount leftover after the mint.
  */
  function _mintAll(
    uint256 _amount,
    uint8[] memory _mintTierIds,
    address _beneficiary
  ) internal returns (uint256 leftoverAmount) {
    // Set the leftover amount to be the initial amount.
    leftoverAmount = _amount;

    // Keep a reference to the tier ID being iterated on.
    uint256 _tierId;

    uint256 _mintsLength = _mintTierIds.length;

    for (uint256 _i; _i < _mintsLength; ) {
      // Get a reference to the tier being iterated on.
      _tierId = _mintTierIds[_i];

      if (_tierId != 0) {
        // Keep a reference to the token ID.
        uint256 _tokenId;

        // Record the mint.
        (_tokenId, leftoverAmount) = store.recordMint(leftoverAmount, _tierId, _beneficiary);

        // Mint the tokens.
        _mint(_beneficiary, _tokenId);

        emit Mint(_tokenId, _tierId, _beneficiary, _amount, _mintsLength, msg.sender);
      }

      unchecked {
        ++_i;
      }
    }
  }

  /**
    @notice
    The voting units for an account from its NFTs across all tiers. NFTs have a tier-specific preset number of voting units. 

    @param _account The account to get voting units for.

    @return units The voting units for the account.
  */
  function _getVotingUnits(address _account)
    internal
    view
    virtual
    override
    returns (uint256 units)
  {
    return store.votingUnitsOf(address(this), _account);
  }

  /**
    @notice
    Transfer voting units after the transfer of a token.

    @param _from The address where the transfer is originating.
    @param _to The address to which the transfer is being made.
    @param _tokenId The ID of the token being transfered.
   */
  function _afterTokenTransfer(
    address _from,
    address _to,
    uint256 _tokenId
  ) internal virtual override {
    // Get a reference to the tier.
    JBNFTRewardTier memory _tier = store.tierOfTokenId(address(this), _tokenId);

    if (_tier.data.votingUnits > 0)
      // Transfer the voting units.
      _transferVotingUnits(_from, _to, _tier.data.votingUnits);

    super._afterTokenTransfer(_from, _to, _tokenId);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@jbx-protocol/contracts-v2/contracts/interfaces/IJBController.sol';
import '@jbx-protocol/contracts-v2/contracts/interfaces/IJBProjects.sol';
import '@jbx-protocol/contracts-v2/contracts/structs/JBProjectMetadata.sol';
import '../structs/JBDeployTieredNFTRewardDataSourceData.sol';
import '../structs/JBLaunchProjectData.sol';
import '../structs/JBLaunchFundingCyclesData.sol';
import '../structs/JBReconfigureFundingCyclesData.sol';

interface IJBTieredLimitedNFTRewardDataSourceProjectDeployer {
  event DatasourceDeployed(uint256 indexed projectId, address newDatasource);

  function controller() external view returns (IJBController);

  function launchProjectFor(
    address _owner,
    JBDeployTieredNFTRewardDataSourceData memory _deployTieredNFTRewardDataSourceData,
    JBLaunchProjectData memory _launchProjectData
  ) external returns (uint256 projectId);

  function launchFundingCyclesFor(
    uint256 _projectId,
    JBDeployTieredNFTRewardDataSourceData memory _deployTieredNFTRewardDataSourceData,
    JBLaunchFundingCyclesData memory _launchFundingCyclesData
  ) external returns (uint256 configuration);

  function reconfigureFundingCyclesOf(
    uint256 _projectId,
    JBDeployTieredNFTRewardDataSourceData memory _deployTieredNFTRewardDataSourceData,
    JBReconfigureFundingCyclesData memory _reconfigureFundingCyclesData
  ) external returns (uint256 configuration);

  function deployDataSource(
    uint256 _projectId,
    JBDeployTieredNFTRewardDataSourceData memory _deployTieredNFTRewardDataSourceData
  ) external returns (address dataSource);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBOperatorStore.sol';

interface IJBOperatable {
  function operatorStore() external view returns (IJBOperatorStore);
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
pragma solidity 0.8.6;

import './../interfaces/IJBPaymentTerminal.sol';

/** 
  @member terminal The terminal within which the distribution limit and the overflow allowance applies.
  @member token The token for which the fund access constraints apply.
  @member distributionLimit The amount of the distribution limit, as a fixed point number with the same number of decimals as the terminal within which the limit applies.
  @member distributionLimitCurrency The currency of the distribution limit.
  @member overflowAllowance The amount of the allowance, as a fixed point number with the same number of decimals as the terminal within which the allowance applies.
  @member overflowAllowanceCurrency The currency of the overflow allowance.
*/
struct JBFundAccessConstraints {
  IJBPaymentTerminal terminal;
  address token;
  uint256 distributionLimit;
  uint256 distributionLimitCurrency;
  uint256 overflowAllowance;
  uint256 overflowAllowanceCurrency;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBFundingCycleBallot.sol';

/** 
  @member duration The number of seconds the funding cycle lasts for, after which a new funding cycle will start. A duration of 0 means that the funding cycle will stay active until the project owner explicitly issues a reconfiguration, at which point a new funding cycle will immediately start with the updated properties. If the duration is greater than 0, a project owner cannot make changes to a funding cycle's parameters while it is active – any proposed changes will apply to the subsequent cycle. If no changes are proposed, a funding cycle rolls over to another one with the same properties but new `start` timestamp and a discounted `weight`.
  @member weight A fixed point number with 18 decimals that contracts can use to base arbitrary calculations on. For example, payment terminals can use this to determine how many tokens should be minted when a payment is received.
  @member discountRate A percent by how much the `weight` of the subsequent funding cycle should be reduced, if the project owner hasn't configured the subsequent funding cycle with an explicit `weight`. If it's 0, each funding cycle will have equal weight. If the number is 90%, the next funding cycle will have a 10% smaller weight. This weight is out of `JBConstants.MAX_DISCOUNT_RATE`.
  @member ballot An address of a contract that says whether a proposed reconfiguration should be accepted or rejected. It can be used to create rules around how a project owner can change funding cycle parameters over time.
*/
struct JBFundingCycleData {
  uint256 duration;
  uint256 weight;
  uint256 discountRate;
  IJBFundingCycleBallot ballot;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './JBGlobalFundingCycleMetadata.sol';
import './../interfaces/IJBFundingCycleDataSource.sol';

/** 
  @member global Data used globally in non-migratable ecosystem contracts.
  @member reservedRate The reserved rate of the funding cycle. This number is a percentage calculated out of `JBConstants.MAX_RESERVED_RATE`.
  @member redemptionRate The redemption rate of the funding cycle. This number is a percentage calculated out of `JBConstants.MAX_REDEMPTION_RATE`.
  @member ballotRedemptionRate The redemption rate to use during an active ballot of the funding cycle. This number is a percentage calculated out of `JBConstants.MAX_REDEMPTION_RATE`.
  @member pausePay A flag indicating if the pay functionality should be paused during the funding cycle.
  @member pauseDistributions A flag indicating if the distribute functionality should be paused during the funding cycle.
  @member pauseRedeem A flag indicating if the redeem functionality should be paused during the funding cycle.
  @member pauseBurn A flag indicating if the burn functionality should be paused during the funding cycle.
  @member allowMinting A flag indicating if the mint functionality should be allowed during the funding cycle.
  @member allowChangeToken A flag indicating if changing tokens should be allowed during this funding cycle.
  @member allowTerminalMigration A flag indicating if migrating terminals should be allowed during this funding cycle.
  @member allowControllerMigration A flag indicating if migrating controllers should be allowed during this funding cycle.
  @member holdFees A flag indicating if fees should be held during this funding cycle.
  @member useTotalOverflowForRedemptions A flag indicating if redemptions should use the project's balance held in all terminals instead of the project's local terminal balance from which the redemption is being fulfilled.
  @member useDataSourceForPay A flag indicating if the data source should be used for pay transactions during this funding cycle.
  @member useDataSourceForRedeem A flag indicating if the data source should be used for redeem transactions during this funding cycle.
  @member dataSource The data source to use during this funding cycle.
*/
struct JBFundingCycleMetadata {
  JBGlobalFundingCycleMetadata global;
  uint256 reservedRate;
  uint256 redemptionRate;
  uint256 ballotRedemptionRate;
  bool pausePay;
  bool pauseDistributions;
  bool pauseRedeem;
  bool pauseBurn;
  bool allowMinting;
  bool allowChangeToken;
  bool allowTerminalMigration;
  bool allowControllerMigration;
  bool holdFees;
  bool useTotalOverflowForRedemptions;
  bool useDataSourceForPay;
  bool useDataSourceForRedeem;
  address dataSource;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './JBSplit.sol';

/** 
  @member group The group indentifier.
  @member splits The splits to associate with the group.
*/
struct JBGroupedSplits {
  uint256 group;
  JBSplit[] splits;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/** 
  @member content The metadata content.
  @member domain The domain within which the metadata applies.
*/
struct JBProjectMetadata {
  string content;
  uint256 domain;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBFundingCycleStore.sol';
import './IJBPaymentTerminal.sol';
import './IJBProjects.sol';

interface IJBDirectory {
  event SetController(uint256 indexed projectId, address indexed controller, address caller);

  event AddTerminal(uint256 indexed projectId, IJBPaymentTerminal indexed terminal, address caller);

  event SetTerminals(uint256 indexed projectId, IJBPaymentTerminal[] terminals, address caller);

  event SetPrimaryTerminal(
    uint256 indexed projectId,
    address indexed token,
    IJBPaymentTerminal indexed terminal,
    address caller
  );

  event SetIsAllowedToSetFirstController(address indexed addr, bool indexed flag, address caller);

  function projects() external view returns (IJBProjects);

  function fundingCycleStore() external view returns (IJBFundingCycleStore);

  function controllerOf(uint256 _projectId) external view returns (address);

  function isAllowedToSetFirstController(address _address) external view returns (bool);

  function terminalsOf(uint256 _projectId) external view returns (IJBPaymentTerminal[] memory);

  function isTerminalOf(uint256 _projectId, IJBPaymentTerminal _terminal)
    external
    view
    returns (bool);

  function primaryTerminalOf(uint256 _projectId, address _token)
    external
    view
    returns (IJBPaymentTerminal);

  function setControllerOf(uint256 _projectId, address _controller) external;

  function setTerminalsOf(uint256 _projectId, IJBPaymentTerminal[] calldata _terminals) external;

  function setPrimaryTerminalOf(
    uint256 _projectId,
    address _token,
    IJBPaymentTerminal _terminal
  ) external;

  function setIsAllowedToSetFirstController(address _address, bool _flag) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../enums/JBBallotState.sol';
import './../structs/JBFundingCycle.sol';
import './../structs/JBFundingCycleData.sol';

interface IJBFundingCycleStore {
  event Configure(
    uint256 indexed configuration,
    uint256 indexed projectId,
    JBFundingCycleData data,
    uint256 metadata,
    uint256 mustStartAtOrAfter,
    address caller
  );

  event Init(uint256 indexed configuration, uint256 indexed projectId, uint256 indexed basedOn);

  function latestConfigurationOf(uint256 _projectId) external view returns (uint256);

  function get(uint256 _projectId, uint256 _configuration)
    external
    view
    returns (JBFundingCycle memory);

  function latestConfiguredOf(uint256 _projectId)
    external
    view
    returns (JBFundingCycle memory fundingCycle, JBBallotState ballotState);

  function queuedOf(uint256 _projectId) external view returns (JBFundingCycle memory fundingCycle);

  function currentOf(uint256 _projectId) external view returns (JBFundingCycle memory fundingCycle);

  function currentBallotStateOf(uint256 _projectId) external view returns (JBBallotState);

  function configureFor(
    uint256 _projectId,
    JBFundingCycleData calldata _data,
    uint256 _metadata,
    uint256 _mustStartAtOrAfter
  ) external returns (JBFundingCycle memory fundingCycle);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IJBMigratable {
  function prepForMigrationOf(uint256 _projectId, address _from) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

interface IJBPaymentTerminal is IERC165 {
  function acceptsToken(address _token, uint256 _projectId) external view returns (bool);

  function currencyForToken(address _token) external view returns (uint256);

  function decimalsForToken(address _token) external view returns (uint256);

  // Return value must be a fixed point number with 18 decimals.
  function currentEthOverflowOf(uint256 _projectId) external view returns (uint256);

  function pay(
    uint256 _projectId,
    uint256 _amount,
    address _token,
    address _beneficiary,
    uint256 _minReturnedTokens,
    bool _preferClaimedTokens,
    string calldata _memo,
    bytes calldata _metadata
  ) external payable returns (uint256 beneficiaryTokenCount);

  function addToBalanceOf(
    uint256 _projectId,
    uint256 _amount,
    address _token,
    string calldata _memo,
    bytes calldata _metadata
  ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../structs/JBSplit.sol';
import './IJBDirectory.sol';
import './IJBProjects.sol';

interface IJBSplitsStore {
  event SetSplit(
    uint256 indexed projectId,
    uint256 indexed domain,
    uint256 indexed group,
    JBSplit split,
    address caller
  );

  function projects() external view returns (IJBProjects);

  function directory() external view returns (IJBDirectory);

  function splitsOf(
    uint256 _projectId,
    uint256 _domain,
    uint256 _group
  ) external view returns (JBSplit[] memory);

  function set(
    uint256 _projectId,
    uint256 _domain,
    uint256 _group,
    JBSplit[] memory _splits
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IJBToken {
  function decimals() external view returns (uint8);

  function totalSupply(uint256 _projectId) external view returns (uint256);

  function balanceOf(address _account, uint256 _projectId) external view returns (uint256);

  function mint(
    uint256 _projectId,
    address _account,
    uint256 _amount
  ) external;

  function burn(
    uint256 _projectId,
    address _account,
    uint256 _amount
  ) external;

  function approve(
    uint256,
    address _spender,
    uint256 _amount
  ) external;

  function transfer(
    uint256 _projectId,
    address _to,
    uint256 _amount
  ) external;

  function transferFrom(
    uint256 _projectId,
    address _from,
    address _to,
    uint256 _amount
  ) external;

  function transferOwnership(uint256 _projectId, address _newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBProjects.sol';
import './IJBToken.sol';

interface IJBTokenStore {
  event Issue(
    uint256 indexed projectId,
    IJBToken indexed token,
    string name,
    string symbol,
    address caller
  );

  event Mint(
    address indexed holder,
    uint256 indexed projectId,
    uint256 amount,
    bool tokensWereClaimed,
    bool preferClaimedTokens,
    address caller
  );

  event Burn(
    address indexed holder,
    uint256 indexed projectId,
    uint256 amount,
    uint256 initialUnclaimedBalance,
    uint256 initialClaimedBalance,
    bool preferClaimedTokens,
    address caller
  );

  event Claim(
    address indexed holder,
    uint256 indexed projectId,
    uint256 initialUnclaimedBalance,
    uint256 amount,
    address caller
  );

  event ShouldRequireClaim(uint256 indexed projectId, bool indexed flag, address caller);

  event Change(
    uint256 indexed projectId,
    IJBToken indexed newToken,
    IJBToken indexed oldToken,
    address owner,
    address caller
  );

  event Transfer(
    address indexed holder,
    uint256 indexed projectId,
    address indexed recipient,
    uint256 amount,
    address caller
  );

  function tokenOf(uint256 _projectId) external view returns (IJBToken);

  function projectOf(IJBToken _token) external view returns (uint256);

  function projects() external view returns (IJBProjects);

  function unclaimedBalanceOf(address _holder, uint256 _projectId) external view returns (uint256);

  function unclaimedTotalSupplyOf(uint256 _projectId) external view returns (uint256);

  function totalSupplyOf(uint256 _projectId) external view returns (uint256);

  function balanceOf(address _holder, uint256 _projectId) external view returns (uint256 _result);

  function requireClaimFor(uint256 _projectId) external view returns (bool);

  function issueFor(
    uint256 _projectId,
    string calldata _name,
    string calldata _symbol
  ) external returns (IJBToken token);

  function changeFor(
    uint256 _projectId,
    IJBToken _token,
    address _newOwner
  ) external returns (IJBToken oldToken);

  function burnFrom(
    address _holder,
    uint256 _projectId,
    uint256 _amount,
    bool _preferClaimedTokens
  ) external;

  function mintFor(
    address _holder,
    uint256 _projectId,
    uint256 _amount,
    bool _preferClaimedTokens
  ) external;

  function shouldRequireClaimingFor(uint256 _projectId, bool _flag) external;

  function claimFor(
    address _holder,
    uint256 _projectId,
    uint256 _amount
  ) external;

  function transferFrom(
    address _holder,
    uint256 _projectId,
    address _recipient,
    uint256 _amount
  ) external;
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
pragma solidity 0.8.6;

interface IJBTokenUriResolver {
  function getUri(uint256 _projectId) external view returns (string memory tokenUri);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

library JBTokens {
  /** 
    @notice 
    The ETH token address in Juicebox is represented by 0x000000000000000000000000000000000000EEEe.
  */
  address public constant ETH = address(0x000000000000000000000000000000000000EEEe);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/**
  @notice
  Global constants used across Juicebox contracts.
*/
library JBConstants {
  uint256 public constant MAX_RESERVED_RATE = 10000;
  uint256 public constant MAX_REDEMPTION_RATE = 10000;
  uint256 public constant MAX_DISCOUNT_RATE = 1000000000;
  uint256 public constant SPLITS_TOTAL_PERCENT = 1000000000;
  uint256 public constant MAX_FEE = 1000000000;
  uint256 public constant MAX_FEE_DISCOUNT = 1000000000;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (governance/utils/Votes.sol)
pragma solidity ^0.8.0;

import "../../utils/Context.sol";
import "../../utils/Counters.sol";
import "../../utils/Checkpoints.sol";
import "../../utils/cryptography/draft-EIP712.sol";
import "./IVotes.sol";

/**
 * @dev This is a base abstract contract that tracks voting units, which are a measure of voting power that can be
 * transferred, and provides a system of vote delegation, where an account can delegate its voting units to a sort of
 * "representative" that will pool delegated voting units from different accounts and can then use it to vote in
 * decisions. In fact, voting units _must_ be delegated in order to count as actual votes, and an account has to
 * delegate those votes to itself if it wishes to participate in decisions and does not have a trusted representative.
 *
 * This contract is often combined with a token contract such that voting units correspond to token units. For an
 * example, see {ERC721Votes}.
 *
 * The full history of delegate votes is tracked on-chain so that governance protocols can consider votes as distributed
 * at a particular block number to protect against flash loans and double voting. The opt-in delegate system makes the
 * cost of this history tracking optional.
 *
 * When using this module the derived contract must implement {_getVotingUnits} (for example, make it return
 * {ERC721-balanceOf}), and can use {_transferVotingUnits} to track a change in the distribution of those units (in the
 * previous example, it would be included in {ERC721-_beforeTokenTransfer}).
 *
 * _Available since v4.5._
 */
abstract contract Votes is IVotes, Context, EIP712 {
    using Checkpoints for Checkpoints.History;
    using Counters for Counters.Counter;

    bytes32 private constant _DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    mapping(address => address) private _delegation;
    mapping(address => Checkpoints.History) private _delegateCheckpoints;
    Checkpoints.History private _totalCheckpoints;

    mapping(address => Counters.Counter) private _nonces;

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) public view virtual override returns (uint256) {
        return _delegateCheckpoints[account].latest();
    }

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastVotes(address account, uint256 blockNumber) public view virtual override returns (uint256) {
        return _delegateCheckpoints[account].getAtBlock(blockNumber);
    }

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastTotalSupply(uint256 blockNumber) public view virtual override returns (uint256) {
        require(blockNumber < block.number, "Votes: block not yet mined");
        return _totalCheckpoints.getAtBlock(blockNumber);
    }

    /**
     * @dev Returns the current total supply of votes.
     */
    function _getTotalSupply() internal view virtual returns (uint256) {
        return _totalCheckpoints.latest();
    }

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) public view virtual override returns (address) {
        return _delegation[account];
    }

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) public virtual override {
        address account = _msgSender();
        _delegate(account, delegatee);
    }

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= expiry, "Votes: signature expired");
        address signer = ECDSA.recover(
            _hashTypedDataV4(keccak256(abi.encode(_DELEGATION_TYPEHASH, delegatee, nonce, expiry))),
            v,
            r,
            s
        );
        require(nonce == _useNonce(signer), "Votes: invalid nonce");
        _delegate(signer, delegatee);
    }

    /**
     * @dev Delegate all of `account`'s voting units to `delegatee`.
     *
     * Emits events {DelegateChanged} and {DelegateVotesChanged}.
     */
    function _delegate(address account, address delegatee) internal virtual {
        address oldDelegate = delegates(account);
        _delegation[account] = delegatee;

        emit DelegateChanged(account, oldDelegate, delegatee);
        _moveDelegateVotes(oldDelegate, delegatee, _getVotingUnits(account));
    }

    /**
     * @dev Transfers, mints, or burns voting units. To register a mint, `from` should be zero. To register a burn, `to`
     * should be zero. Total supply of voting units will be adjusted with mints and burns.
     */
    function _transferVotingUnits(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        if (from == address(0)) {
            _totalCheckpoints.push(_add, amount);
        }
        if (to == address(0)) {
            _totalCheckpoints.push(_subtract, amount);
        }
        _moveDelegateVotes(delegates(from), delegates(to), amount);
    }

    /**
     * @dev Moves delegated votes from one delegate to another.
     */
    function _moveDelegateVotes(
        address from,
        address to,
        uint256 amount
    ) private {
        if (from != to && amount > 0) {
            if (from != address(0)) {
                (uint256 oldValue, uint256 newValue) = _delegateCheckpoints[from].push(_subtract, amount);
                emit DelegateVotesChanged(from, oldValue, newValue);
            }
            if (to != address(0)) {
                (uint256 oldValue, uint256 newValue) = _delegateCheckpoints[to].push(_add, amount);
                emit DelegateVotesChanged(to, oldValue, newValue);
            }
        }
    }

    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Consumes a nonce.
     *
     * Returns the current value and increments nonce.
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }

    /**
     * @dev Returns an address nonce.
     */
    function nonces(address owner) public view virtual returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev Returns the contract's {EIP712} domain separator.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev Must return the voting units held by an account.
     */
    function _getVotingUnits(address) internal view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@paulrberg/contracts/math/PRBMath.sol';
import '@jbx-protocol/contracts-v2/contracts/interfaces/IJBFundingCycleDataSource.sol';
import '@jbx-protocol/contracts-v2/contracts/interfaces/IJBPayDelegate.sol';
import '@jbx-protocol/contracts-v2/contracts/interfaces/IJBPayoutRedemptionPaymentTerminal.sol';
import '@jbx-protocol/contracts-v2/contracts/libraries/JBConstants.sol';
import '@jbx-protocol/contracts-v2/contracts/structs/JBPayParamsData.sol';
import '@jbx-protocol/contracts-v2/contracts/structs/JBTokenAmount.sol';

import './ERC721.sol';
import '../interfaces/IJBNFTRewardDataSource.sol';

/**
  @title 
  JBNFTRewardDataSource

  @notice 
  Data source that offers project contributors NFTs.

  @dev 
  This JBFundingCycleDataSource implementation will simply through the weight, reclaimAmount, and memos they are called with.

  @dev
  Adheres to -
  IJBNFTRewardDataSource: General interface for the methods in this contract that interact with the blockchain's state according to the protocol's rules.
  IJBFundingCycleDataSource: Allows this contract to be attached to a funding cycle to have its methods called during regular protocol operations.
  IJBPayDelegate: Allows this contract to receive callbacks when a project receives a payment.
  IJBRedemptionDelegate: Allows this contract to receive callbacks when a token holder redeems.

  @dev
  Inherits from -
  todo
  ERC721Votes: A checkpointable standard definition for non-fungible tokens (NFTs).
  Ownable: Includes convenience functionality for checking a message sender's permissions before executing certain transactions.
*/
abstract contract JBNFTRewardDataSource is
  IJBNFTRewardDataSource,
  IJBFundingCycleDataSource,
  IJBPayDelegate,
  // IJBRedemptionDelegate,
  ERC721,
  Ownable
{
  using Strings for uint256;

  //*********************************************************************//
  // --------------------------- custom errors ------------------------- //
  //*********************************************************************//

  error INVALID_PAYMENT_EVENT();
  error INVALID_REDEMPTION_EVENT();
  error UNAUTHORIZED();
  error UNEXPECTED();

  //*********************************************************************//
  // --------------------- internal stored properties ------------------ //
  //*********************************************************************//

  // /**
  //   @notice
  //   The first owner of each token ID, stored on first transfer out.

  //   _tokenId The ID of the token to get the stored first owner of.
  // */
  // mapping(uint256 => address) internal _firstOwnerOf;

  //*********************************************************************//
  // --------------- public immutable stored properties ---------------- //
  //*********************************************************************//

  /**
    @notice
    The ID of the project this NFT should be distributed for.
  */
  uint256 public immutable override projectId;

  /**
    @notice
    The directory of terminals and controllers for projects.
  */
  IJBDirectory public immutable override directory;

  //*********************************************************************//
  // --------------------- public stored properties -------------------- //
  //*********************************************************************//

  /**
    @notice
    Custom token URI resolver, superceeds base URI.
  */
  IJBTokenUriResolver public override tokenUriResolver;

  /**
    @notice
    Contract metadata uri.
  */
  string public override contractUri;

  //*********************************************************************//
  // ------------------------- external views -------------------------- //
  //*********************************************************************//

  // /**
  //   @notice
  //   The first owner of each token ID.

  //   @param _tokenId The ID of the token to get the stored first owner of.

  //   @return The first owner of the token.
  // */
  // function firstOwnerOf(uint256 _tokenId) external view override returns (address) {
  //   // If the stored first owner is set, return it.
  //   if (_firstOwnerOf[_tokenId] != address(0)) return _firstOwnerOf[_tokenId];

  //   // Otherwise the first owner must be the current owner.
  //   return _owners[_tokenId];
  // }

  /**
    @notice 
    Part of IJBFundingCycleDataSource, this function gets called when the project receives a payment. It will set itself as the delegate to get a callback from the terminal.

    @dev 
    This function will revert if the contract calling it is not the store of one of the project's terminals. 

    @param _data The Juicebox standard project contribution data.

    @return weight The weight that tokens should get minted in accordance to 
    @return memo The memo that should be forwarded to the event.
    @return delegate A delegate to call once the payment has taken place.
  */
  function payParams(JBPayParamsData calldata _data)
    external
    view
    override
    returns (
      uint256 weight,
      string memory memo,
      IJBPayDelegate delegate
    )
  {
    // Forward the recieved weight and memo, and use this contract as a pay delegate.
    return (_data.weight, _data.memo, IJBPayDelegate(address(this)));
  }

  /**
    @notice 
    Part of IJBFundingCycleDataSource, this function gets called when a project's token holders redeem. It will return the standard properties.

    @param _data The Juicebox standard project redemption data.

    @return reclaimAmount The amount that should be reclaimed from the treasury.
    @return memo The memo that should be forwarded to the event.
    @return delegate A delegate to call once the redemption has taken place.
  */
  function redeemParams(JBRedeemParamsData calldata _data)
    external
    view
    override
    returns (
      uint256 reclaimAmount,
      string memory memo,
      IJBRedemptionDelegate delegate
    )
  {
    return (_data.reclaimAmount.value, _data.memo, IJBRedemptionDelegate(address(0)));
    // // Make sure fungible project tokens aren't being redeemed too.
    // if (_data.tokenCount > 0) revert UNEXPECTED();

    // // If redemption rate is 0, nothing can be reclaimed from the treasury
    // if (_data.redemptionRate == 0) return (0, _data.memo, IJBRedemptionDelegate(address(this)));

    // // Decode the metadata, Skip the first 32 bits which are used by the JB protocol.
    // uint256[] memory _decodedTokenIds = abi.decode(_data.metadata, (uint256[]));

    // // Get a reference to the redemption rate of the provided tokens.
    // uint256 _redemptionWeight = redemptionWeightOf(_decodedTokenIds);

    // // Get a reference to the total redemption weight.
    // uint256 _totalRedemptionWeight = totalRedemptionWeight();

    // // Get a reference to the linear proportion.
    // uint256 _base = PRBMath.mulDiv(_data.overflow, _redemptionWeight, _totalRedemptionWeight);

    // // These conditions are all part of the same curve. Edge conditions are separated because fewer operation are necessary.
    // if (_data.redemptionRate == JBConstants.MAX_REDEMPTION_RATE)
    //   return (_base, _data.memo, IJBRedemptionDelegate(address(this)));

    // // Return the weighted overflow, and this contract as the delegate so that tokens can be deleted.
    // return (
    //   PRBMath.mulDiv(
    //     _base,
    //     _data.redemptionRate +
    //       PRBMath.mulDiv(
    //         _redemptionWeight,
    //         JBConstants.MAX_REDEMPTION_RATE - _data.redemptionRate,
    //         _totalRedemptionWeight
    //       ),
    //     JBConstants.MAX_REDEMPTION_RATE
    //   ),
    //   _data.memo,
    //   IJBRedemptionDelegate(address(this))
    // );
  }

  // /**
  //   @notice
  //   The cumulative weight the given token IDs have in redemptions compared to the `totalRedemptionWeight`.

  //   @param _tokenIds The IDs of the tokens to get the cumulative redemption weight of.

  //   @return The weight.
  // */
  // function redemptionWeightOf(uint256[] memory _tokenIds) public view virtual returns (uint256) {
  //   _tokenIds; // Prevents unused var compiler and natspec complaints.
  //   return 0;
  // }

  // /**
  //   @notice
  //   The cumulative weight that all token IDs have in redemptions.

  //   @return The total weight.
  // */
  // function totalRedemptionWeight() public view virtual returns (uint256) {
  //   return 0;
  // }

  //*********************************************************************//
  // -------------------------- public views --------------------------- //
  //*********************************************************************//

  // /**
  //   @notice
  //   Indicates if this contract adheres to the specified interface.

  //   @dev
  //   See {IERC165-supportsInterface}.

  //   @param _interfaceId The ID of the interface to check for adherance to.
  // */
  // function supportsInterface(bytes4 _interfaceId)
  //   public
  //   view
  //   virtual
  //   override(ERC721, IERC165)
  //   returns (bool)
  // {
  //   return
  //     _interfaceId == type(IJBNFTRewardDataSource).interfaceId ||
  //     _interfaceId == type(IJBFundingCycleDataSource).interfaceId ||
  //     _interfaceId == type(IJBPayDelegate).interfaceId ||
  //     super.supportsInterface(_interfaceId);
  // }

  //*********************************************************************//
  // -------------------------- constructor ---------------------------- //
  //*********************************************************************//

  /**
    @param _projectId The ID of the project for which this NFT should be minted in response to payments made. 
    @param _directory The directory of terminals and controllers for projects.
    @param _name The name of the token.
    @param _symbol The symbol that the token should be represented by.
    @param _tokenUriResolver A contract responsible for resolving the token URI for each token ID.
    @param _contractUri A URI where contract metadata can be found. 
    @param _owner The address that will own this contract.
  */
  constructor(
    uint256 _projectId,
    IJBDirectory _directory,
    string memory _name,
    string memory _symbol,
    IJBTokenUriResolver _tokenUriResolver,
    string memory _contractUri,
    address _owner
  ) ERC721(_name, _symbol) {
    projectId = _projectId;
    directory = _directory;
    tokenUriResolver = _tokenUriResolver;
    contractUri = _contractUri;

    // Transfer the ownership to the specified address.
    if (_owner != address(0)) _transferOwnership(_owner);
  }

  //*********************************************************************//
  // ---------------------- external transactions ---------------------- //
  //*********************************************************************//

  /**
    @notice 
    Part of IJBPayDelegate, this function gets called when the project receives a payment. It will mint an NFT to the contributor (_data.beneficiary) if conditions are met.

    @dev 
    This function will revert if the contract calling is not one of the project's terminals. 

    @param _data The Juicebox standard project contribution data.
  */
  function didPay(JBDidPayData calldata _data) external virtual override {
    // Make sure the caller is a terminal of the project, and the call is being made on behalf of an interaction with the correct project.
    if (
      !directory.isTerminalOf(projectId, IJBPaymentTerminal(msg.sender)) ||
      _data.projectId != projectId
    ) revert INVALID_PAYMENT_EVENT();

    // Process the contribution.
    _processContribution(_data);
  }

  // /**
  //   @notice
  //   Part of IJBRedeemDelegate, this function gets called when the token holder redeems. It will burn the specified NFTs to reclaim from the treasury to the _data.beneficiary.

  //   @dev
  //   This function will revert if the contract calling is not one of the project's terminals.

  //   @param _data The Juicebox standard project redemption data.
  // */
  // function didRedeem(JBDidRedeemData calldata _data) external virtual override {
  //   // Make sure the caller is a terminal of the project, and the call is being made on behalf of an interaction with the correct project.
  //   if (
  //     !directory.isTerminalOf(projectId, IJBPaymentTerminal(msg.sender)) ||
  //     _data.projectId != projectId
  //   ) revert INVALID_REDEMPTION_EVENT();

  //   // Decode the metadata, Skip the first 32 bits which are used by the JB protocol.
  //   uint256[] memory _decodedTokenIds = abi.decode(_data.metadata, (uint256[]));

  //   // Get a reference to the number of token IDs being checked.
  //   uint256 _numberOfTokenIds = _decodedTokenIds.length;

  //   // Keep a reference to the token ID being iterated on.
  //   uint256 _tokenId;

  //   // Iterate through all tokens, burning them if the owner is correct.
  //   for (uint256 _i; _i < _numberOfTokenIds; ) {
  //     // Set the token's ID.
  //     _tokenId = _decodedTokenIds[_i];

  //     // Make sure the token's owner is correct.
  //     if (_owners[_tokenId] != _data.holder) revert UNAUTHORIZED();

  //     // Burn the token.
  //     _burn(_tokenId);

  //     unchecked {
  //       ++_i;
  //     }
  //   }
  // }

  /**
    @notice
    Set a contract metadata uri to contain opensea-style metadata.

    @dev
    Only the contract's owner can set the contract URI.

    @param _contractUri The new contract URI.
  */
  function setContractUri(string calldata _contractUri) external override onlyOwner {
    // Store the new value.
    contractUri = _contractUri;

    emit SetContractUri(_contractUri, msg.sender);
  }

  /**
    @notice
    Set a token URI resolver.

    @dev
    Only the contract's owner can set the token URI resolver.

    @param _tokenUriResolver The new base URI.
  */
  function setTokenUriResolver(IJBTokenUriResolver _tokenUriResolver) external override onlyOwner {
    // Store the new value.
    tokenUriResolver = _tokenUriResolver;

    emit SetTokenUriResolver(_tokenUriResolver, msg.sender);
  }

  //*********************************************************************//
  // ---------------------- internal transactions ---------------------- //
  //*********************************************************************//

  function _processContribution(JBDidPayData calldata _data) internal virtual {}

  // /**
  //   @notice
  //   User the hook to register the first owner if it's not yet regitered.
  // */
  // function _beforeTokenTransfer(
  //   address _from,
  //   address _to,
  //   uint256 _tokenId
  // ) internal virtual override {
  //   _to; // Prevents unused var compiler and natspec complaints.

  //   // If there's no stored first owner, and the transfer isn't originating from the zero address as expected for mints, store the first owner.
  //   if (_firstOwnerOf[_tokenId] == address(0) && _from != address(0))
  //     _firstOwnerOf[_tokenId] = _from;
  // }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@jbx-protocol/contracts-v2/contracts/interfaces/IJBProjects.sol';
import './../structs/JBNFTRewardTierData.sol';
import './../structs/JBNFTRewardTier.sol';
import './IJBTieredLimitedNFTRewardDataSourceStore.sol';

interface IJBTieredLimitedNFTRewardDataSource {
  event Mint(
    uint256 indexed tokenId,
    uint256 indexed tierId,
    address indexed beneficiary,
    uint256 totalAmountContributed,
    uint256 numRewards,
    address caller
  );

  event MintReservedToken(
    uint256 indexed tokenId,
    uint256 indexed tierId,
    address indexed beneficiary,
    address caller
  );

  event SetReservedTokenBeneficiary(address indexed beneficiary, address caller);

  function store() external view returns (IJBTieredLimitedNFTRewardDataSourceStore);

  function adjustTiers(
    JBNFTRewardTierData[] memory _tierDataToAdd,
    uint256[] memory _tierIdsToRemove
  ) external;

  function mintReservesFor(uint256 _tierId, uint256 _count) external;

  function setReservedTokenBeneficiary(address _beneficiary) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface ITokenSupplyDetails {
  function totalSupply() external view returns (uint256);

  function tokenSupplyOf(uint256) external view returns (uint256);

  function totalOwnerBalanceOf(address) external view returns (uint256);

  function ownerTokenBalanceOf(address, uint256) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/**
  @notice
  Utilities to decode an IPFS hash.
*/
library JBIpfsDecoder {
  //*********************************************************************//
  // ------------------- internal constant properties ------------------ //
  //*********************************************************************//

  /**
    @notice
    Just a kind reminder to our readers

    @dev
    Used in base58ToString
  */
  bytes internal constant _ALPHABET = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

  function decode(string memory _baseUri, bytes32 _hexString)
    external
    pure
    returns (string memory)
  {
    // Concatenate the hex string with the fixed IPFS hash part (0x12 and 0x20)
    bytes memory completeHexString = abi.encodePacked(bytes2(0x1220), _hexString);

    // Convert the hex string to an hash
    string memory ipfsHash = _toBase58(completeHexString);

    // Concatenate with the base URI
    return string(abi.encodePacked(_baseUri, ipfsHash));
  }

  /**
    @notice
    Convert an hex string to base58

    @notice 
    Written by Martin Ludfall - Licence: MIT
  */
  function _toBase58(bytes memory _source) private pure returns (string memory) {
    if (_source.length == 0) return new string(0);
    uint8[] memory digits = new uint8[](46); // hash size with the prefix
    digits[0] = 0;
    uint8 digitlength = 1;
    for (uint256 i = 0; i < _source.length; ++i) {
      uint256 carry = uint8(_source[i]);
      for (uint256 j = 0; j < digitlength; ++j) {
        carry += uint256(digits[j]) * 256;
        digits[j] = uint8(carry % 58);
        carry = carry / 58;
      }

      while (carry > 0) {
        digits[digitlength] = uint8(carry % 58);
        digitlength++;
        carry = carry / 58;
      }
    }
    return string(_toAlphabet(_reverse(_truncate(digits, digitlength))));
  }

  function _truncate(uint8[] memory _array, uint8 _length) private pure returns (uint8[] memory) {
    uint8[] memory output = new uint8[](_length);
    for (uint256 i = 0; i < _length; i++) {
      output[i] = _array[i];
    }
    return output;
  }

  function _reverse(uint8[] memory _input) private pure returns (uint8[] memory) {
    uint8[] memory output = new uint8[](_input.length);
    for (uint256 i = 0; i < _input.length; i++) {
      output[i] = _input[_input.length - 1 - i];
    }
    return output;
  }

  function _toAlphabet(uint8[] memory _indices) private pure returns (bytes memory) {
    bytes memory output = new bytes(_indices.length);
    for (uint256 i = 0; i < _indices.length; i++) {
      output[i] = _ALPHABET[_indices[i]];
    }
    return output;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@jbx-protocol/contracts-v2/contracts/interfaces/IJBDirectory.sol';
import '@jbx-protocol/contracts-v2/contracts/interfaces/IJBTokenUriResolver.sol';
import './JBNFTRewardTierData.sol';
import './../interfaces/IJBTieredLimitedNFTRewardDataSourceStore.sol';

/**
  @member directory The directory of terminals and controllers for projects.
  @member name The name of the token.
  @member symbol The symbol that the token should be represented by.
  @member tokenUriResolver A contract responsible for resolving the token URI for each token ID.
  @member contractUri A URI where contract metadata can be found. 
  @member owner The address that should own this contract.
  @member tierData The tier data according to which token distribution will be made. 
  @member shouldMintByDefault A flag indicating if contributions should mint NFTs if a tier's treshold is passed even if the tier ID isn't specified. 
  @member reservedTokenBeneficiary The address receiving the reserved token
  @member store The store contract to use.
*/
struct JBDeployTieredNFTRewardDataSourceData {
  IJBDirectory directory;
  string name;
  string symbol;
  IJBTokenUriResolver tokenUriResolver;
  string contractUri;
  string baseUri;
  address owner;
  JBNFTRewardTierData[] tierData;
  bool shouldMintByDefault;
  address reservedTokenBeneficiary;
  IJBTieredLimitedNFTRewardDataSourceStore store;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@jbx-protocol/contracts-v2/contracts/interfaces/IJBPaymentTerminal.sol';
import '@jbx-protocol/contracts-v2/contracts/structs/JBProjectMetadata.sol';
import '@jbx-protocol/contracts-v2/contracts/structs/JBFundingCycleData.sol';
import '@jbx-protocol/contracts-v2/contracts/structs/JBFundingCycleMetadata.sol';
import '@jbx-protocol/contracts-v2/contracts/structs/JBGroupedSplits.sol';
import '@jbx-protocol/contracts-v2/contracts/structs/JBFundAccessConstraints.sol';

/**
  @member projectMetadata Metadata to associate with the project within a particular domain. This can be updated any time by the owner of the project.
  @member data Data that defines the project's first funding cycle. These properties will remain fixed for the duration of the funding cycle.
  @member metadata Metadata specifying the controller specific params that a funding cycle can have. These properties will remain fixed for the duration of the funding cycle.
  @member mustStartAtOrAfter The time before which the configured funding cycle cannot start.
  @member groupedSplits An array of splits to set for any number of groups. 
  @member fundAccessConstraints An array containing amounts that a project can use from its treasury for each payment terminal. Amounts are fixed point numbers using the same number of decimals as the accompanying terminal. The `_distributionLimit` and `_overflowAllowance` parameters must fit in a `uint232`.
  @member terminals Payment terminals to add for the project.
  @member memo A memo to pass along to the emitted event.
*/
struct JBLaunchProjectData {
  JBProjectMetadata projectMetadata;
  JBFundingCycleData data;
  JBFundingCycleMetadata metadata;
  uint256 mustStartAtOrAfter;
  JBGroupedSplits[] groupedSplits;
  JBFundAccessConstraints[] fundAccessConstraints;
  IJBPaymentTerminal[] terminals;
  string memo;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@jbx-protocol/contracts-v2/contracts/interfaces/IJBPaymentTerminal.sol';
import '@jbx-protocol/contracts-v2/contracts/structs/JBFundingCycleData.sol';
import '@jbx-protocol/contracts-v2/contracts/structs/JBFundingCycleMetadata.sol';
import '@jbx-protocol/contracts-v2/contracts/structs/JBGroupedSplits.sol';
import '@jbx-protocol/contracts-v2/contracts/structs/JBFundAccessConstraints.sol';

/**
  @member data Data that defines the project's first funding cycle. These properties will remain fixed for the duration of the funding cycle.
  @member metadata Metadata specifying the controller specific params that a funding cycle can have. These properties will remain fixed for the duration of the funding cycle.
  @member mustStartAtOrAfter The time before which the configured funding cycle cannot start.
  @member groupedSplits An array of splits to set for any number of groups. 
  @member fundAccessConstraints An array containing amounts that a project can use from its treasury for each payment terminal. Amounts are fixed point numbers using the same number of decimals as the accompanying terminal. The `_distributionLimit` and `_overflowAllowance` parameters must fit in a `uint232`.
  @member terminals Payment terminals to add for the project.
  @member memo A memo to pass along to the emitted event.
*/
struct JBLaunchFundingCyclesData {
  JBFundingCycleData data;
  JBFundingCycleMetadata metadata;
  uint256 mustStartAtOrAfter;
  JBGroupedSplits[] groupedSplits;
  JBFundAccessConstraints[] fundAccessConstraints;
  IJBPaymentTerminal[] terminals;
  string memo;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@jbx-protocol/contracts-v2/contracts/interfaces/IJBPaymentTerminal.sol';
import '@jbx-protocol/contracts-v2/contracts/structs/JBFundingCycleData.sol';
import '@jbx-protocol/contracts-v2/contracts/structs/JBFundingCycleMetadata.sol';
import '@jbx-protocol/contracts-v2/contracts/structs/JBGroupedSplits.sol';
import '@jbx-protocol/contracts-v2/contracts/structs/JBFundAccessConstraints.sol';

/**
  @member data Data that defines the project's first funding cycle. These properties will remain fixed for the duration of the funding cycle.
  @member metadata Metadata specifying the controller specific params that a funding cycle can have. These properties will remain fixed for the duration of the funding cycle.
  @member mustStartAtOrAfter The time before which the configured funding cycle cannot start.
  @member groupedSplits An array of splits to set for any number of groups. 
  @member fundAccessConstraints An array containing amounts that a project can use from its treasury for each payment terminal. Amounts are fixed point numbers using the same number of decimals as the accompanying terminal. The `_distributionLimit` and `_overflowAllowance` parameters must fit in a `uint232`.
  @member terminals Payment terminals to add for the project.
  @member memo A memo to pass along to the emitted event.
*/
struct JBReconfigureFundingCyclesData {
  JBFundingCycleData data;
  JBFundingCycleMetadata metadata;
  uint256 mustStartAtOrAfter;
  JBGroupedSplits[] groupedSplits;
  JBFundAccessConstraints[] fundAccessConstraints;
  string memo;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../structs/JBOperatorData.sol';

interface IJBOperatorStore {
  event SetOperator(
    address indexed operator,
    address indexed account,
    uint256 indexed domain,
    uint256[] permissionIndexes,
    uint256 packed
  );

  function permissionsOf(
    address _operator,
    address _account,
    uint256 _domain
  ) external view returns (uint256);

  function hasPermission(
    address _operator,
    address _account,
    uint256 _domain,
    uint256 _permissionIndex
  ) external view returns (bool);

  function hasPermissions(
    address _operator,
    address _account,
    uint256 _domain,
    uint256[] calldata _permissionIndexes
  ) external view returns (bool);

  function setOperator(JBOperatorData calldata _operatorData) external;

  function setOperators(JBOperatorData[] calldata _operatorData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../enums/JBBallotState.sol';
import './IJBFundingCycleStore.sol';

interface IJBFundingCycleBallot is IERC165 {
  function duration() external view returns (uint256);

  function stateOf(
    uint256 _projectId,
    uint256 _configuration,
    uint256 _start
  ) external view returns (JBBallotState);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBFundingCycleDataSource.sol';

/** 
  @member allowSetTerminals A flag indicating if setting terminals should be allowed during this funding cycle.
  @member allowSetController A flag indicating if setting a new controller should be allowed during this funding cycle.
*/
struct JBGlobalFundingCycleMetadata {
  bool allowSetTerminals;
  bool allowSetController;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../structs/JBPayParamsData.sol';
import './../structs/JBRedeemParamsData.sol';
import './IJBFundingCycleStore.sol';
import './IJBPayDelegate.sol';
import './IJBRedemptionDelegate.sol';

interface IJBFundingCycleDataSource is IERC165 {
  function payParams(JBPayParamsData calldata _data)
    external
    returns (
      uint256 weight,
      string memory memo,
      IJBPayDelegate delegate
    );

  function redeemParams(JBRedeemParamsData calldata _data)
    external
    returns (
      uint256 reclaimAmount,
      string memory memo,
      IJBRedemptionDelegate delegate
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBSplitAllocator.sol';

/** 
  @member preferClaimed A flag that only has effect if a projectId is also specified, and the project has a token contract attached. If so, this flag indicates if the tokens that result from making a payment to the project should be delivered claimed into the beneficiary's wallet, or unclaimed to save gas.
  @member preferAddToBalance A flag indicating if a distribution to a project should prefer triggering it's addToBalance function instead of its pay function.
  @member percent The percent of the whole group that this split occupies. This number is out of `JBConstants.SPLITS_TOTAL_PERCENT`.
  @member projectId The ID of a project. If an allocator is not set but a projectId is set, funds will be sent to the protocol treasury belonging to the project who's ID is specified. Resulting tokens will be routed to the beneficiary with the claimed token preference respected.
  @member beneficiary An address. The role the of the beneficary depends on whether or not projectId is specified, and whether or not an allocator is specified. If allocator is set, the beneficiary will be forwarded to the allocator for it to use. If allocator is not set but projectId is set, the beneficiary is the address to which the project's tokens will be sent that result from a payment to it. If neither allocator or projectId are set, the beneficiary is where the funds from the split will be sent.
  @member lockedUntil Specifies if the split should be unchangeable until the specified time, with the exception of extending the locked period.
  @member allocator If an allocator is specified, funds will be sent to the allocator contract along with all properties of this split.
*/
struct JBSplit {
  bool preferClaimed;
  bool preferAddToBalance;
  uint256 percent;
  uint256 projectId;
  address payable beneficiary;
  uint256 lockedUntil;
  IJBSplitAllocator allocator;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

enum JBBallotState {
  Active,
  Approved,
  Failed
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBFundingCycleBallot.sol';

/** 
  @member number The funding cycle number for the cycle's project. Each funding cycle has a number that is an increment of the cycle that directly preceded it. Each project's first funding cycle has a number of 1.
  @member configuration The timestamp when the parameters for this funding cycle were configured. This value will stay the same for subsequent funding cycles that roll over from an originally configured cycle.
  @member basedOn The `configuration` of the funding cycle that was active when this cycle was created.
  @member start The timestamp marking the moment from which the funding cycle is considered active. It is a unix timestamp measured in seconds.
  @member duration The number of seconds the funding cycle lasts for, after which a new funding cycle will start. A duration of 0 means that the funding cycle will stay active until the project owner explicitly issues a reconfiguration, at which point a new funding cycle will immediately start with the updated properties. If the duration is greater than 0, a project owner cannot make changes to a funding cycle's parameters while it is active – any proposed changes will apply to the subsequent cycle. If no changes are proposed, a funding cycle rolls over to another one with the same properties but new `start` timestamp and a discounted `weight`.
  @member weight A fixed point number with 18 decimals that contracts can use to base arbitrary calculations on. For example, payment terminals can use this to determine how many tokens should be minted when a payment is received.
  @member discountRate A percent by how much the `weight` of the subsequent funding cycle should be reduced, if the project owner hasn't configured the subsequent funding cycle with an explicit `weight`. If it's 0, each funding cycle will have equal weight. If the number is 90%, the next funding cycle will have a 10% smaller weight. This weight is out of `JBConstants.MAX_DISCOUNT_RATE`.
  @member ballot An address of a contract that says whether a proposed reconfiguration should be accepted or rejected. It can be used to create rules around how a project owner can change funding cycle parameters over time.
  @member metadata Extra data that can be associated with a funding cycle.
*/
struct JBFundingCycle {
  uint256 number;
  uint256 configuration;
  uint256 basedOn;
  uint256 start;
  uint256 duration;
  uint256 weight;
  uint256 discountRate;
  IJBFundingCycleBallot ballot;
  uint256 metadata;
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Checkpoints.sol)
pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SafeCast.sol";

/**
 * @dev This library defines the `History` struct, for checkpointing values as they change at different points in
 * time, and later looking up past values by block number. See {Votes} as an example.
 *
 * To create a history of checkpoints define a variable type `Checkpoints.History` in your contract, and store a new
 * checkpoint for the current transaction block using the {push} function.
 *
 * _Available since v4.5._
 */
library Checkpoints {
    struct Checkpoint {
        uint32 _blockNumber;
        uint224 _value;
    }

    struct History {
        Checkpoint[] _checkpoints;
    }

    /**
     * @dev Returns the value in the latest checkpoint, or zero if there are no checkpoints.
     */
    function latest(History storage self) internal view returns (uint256) {
        uint256 pos = self._checkpoints.length;
        return pos == 0 ? 0 : self._checkpoints[pos - 1]._value;
    }

    /**
     * @dev Returns the value at a given block number. If a checkpoint is not available at that block, the closest one
     * before it is returned, or zero otherwise.
     */
    function getAtBlock(History storage self, uint256 blockNumber) internal view returns (uint256) {
        require(blockNumber < block.number, "Checkpoints: block not yet mined");

        uint256 high = self._checkpoints.length;
        uint256 low = 0;
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (self._checkpoints[mid]._blockNumber > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        return high == 0 ? 0 : self._checkpoints[high - 1]._value;
    }

    /**
     * @dev Pushes a value onto a History so that it is stored as the checkpoint for the current block.
     *
     * Returns previous value and new value.
     */
    function push(History storage self, uint256 value) internal returns (uint256, uint256) {
        uint256 pos = self._checkpoints.length;
        uint256 old = latest(self);
        if (pos > 0 && self._checkpoints[pos - 1]._blockNumber == block.number) {
            self._checkpoints[pos - 1]._value = SafeCast.toUint224(value);
        } else {
            self._checkpoints.push(
                Checkpoint({_blockNumber: SafeCast.toUint32(block.number), _value: SafeCast.toUint224(value)})
            );
        }
        return (old, value);
    }

    /**
     * @dev Pushes a value onto a History, by updating the latest value using binary operation `op`. The new value will
     * be set to `op(latest, delta)`.
     *
     * Returns previous value and new value.
     */
    function push(
        History storage self,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) internal returns (uint256, uint256) {
        return push(self, op(latest(self), delta));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (governance/utils/IVotes.sol)
pragma solidity ^0.8.0;

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 *
 * _Available since v4.5._
 */
interface IVotes {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     */
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) external view returns (address);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external;

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
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

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "prb-math/contracts/PRBMath.sol";

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../structs/JBDidPayData.sol';

interface IJBPayDelegate is IERC165 {
  function didPay(JBDidPayData calldata _data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import './../structs/JBFee.sol';
import './IJBAllowanceTerminal.sol';
import './IJBDirectory.sol';
import './IJBFeeGauge.sol';
import './IJBPayoutTerminal.sol';
import './IJBProjects.sol';
import './IJBPayDelegate.sol';
import './IJBPaymentTerminal.sol';
import './IJBPrices.sol';
import './IJBRedemptionDelegate.sol';
import './IJBRedemptionTerminal.sol';
import './IJBSingleTokenPaymentTerminal.sol';
import './IJBSingleTokenPaymentTerminalStore.sol';
import './IJBSplitsStore.sol';

interface IJBPayoutRedemptionPaymentTerminal is
  IJBPaymentTerminal,
  IJBPayoutTerminal,
  IJBAllowanceTerminal,
  IJBRedemptionTerminal
{
  event AddToBalance(
    uint256 indexed projectId,
    uint256 amount,
    uint256 refundedFees,
    string memo,
    bytes metadata,
    address caller
  );

  event Migrate(
    uint256 indexed projectId,
    IJBPaymentTerminal indexed to,
    uint256 amount,
    address caller
  );

  event DistributePayouts(
    uint256 indexed fundingCycleConfiguration,
    uint256 indexed fundingCycleNumber,
    uint256 indexed projectId,
    address beneficiary,
    uint256 amount,
    uint256 distributedAmount,
    uint256 fee,
    uint256 beneficiaryDistributionAmount,
    string memo,
    address caller
  );

  event UseAllowance(
    uint256 indexed fundingCycleConfiguration,
    uint256 indexed fundingCycleNumber,
    uint256 indexed projectId,
    address beneficiary,
    uint256 amount,
    uint256 distributedAmount,
    uint256 netDistributedamount,
    string memo,
    address caller
  );

  event HoldFee(
    uint256 indexed projectId,
    uint256 indexed amount,
    uint256 indexed fee,
    uint256 feeDiscount,
    address beneficiary,
    address caller
  );

  event ProcessFee(
    uint256 indexed projectId,
    uint256 indexed amount,
    bool indexed wasHeld,
    address beneficiary,
    address caller
  );

  event RefundHeldFees(
    uint256 indexed projectId,
    uint256 indexed amount,
    uint256 indexed refundedFees,
    uint256 leftoverAmount,
    address caller
  );

  event Pay(
    uint256 indexed fundingCycleConfiguration,
    uint256 indexed fundingCycleNumber,
    uint256 indexed projectId,
    address payer,
    address beneficiary,
    uint256 amount,
    uint256 beneficiaryTokenCount,
    string memo,
    bytes metadata,
    address caller
  );

  event DelegateDidPay(IJBPayDelegate indexed delegate, JBDidPayData data, address caller);

  event RedeemTokens(
    uint256 indexed fundingCycleConfiguration,
    uint256 indexed fundingCycleNumber,
    uint256 indexed projectId,
    address holder,
    address beneficiary,
    uint256 tokenCount,
    uint256 reclaimedAmount,
    string memo,
    bytes metadata,
    address caller
  );

  event DelegateDidRedeem(
    IJBRedemptionDelegate indexed delegate,
    JBDidRedeemData data,
    address caller
  );

  event DistributeToPayoutSplit(
    uint256 indexed projectId,
    uint256 indexed domain,
    uint256 indexed group,
    JBSplit split,
    uint256 amount,
    address caller
  );

  event SetFee(uint256 fee, address caller);

  event SetFeeGauge(IJBFeeGauge indexed feeGauge, address caller);

  event SetFeelessAddress(address indexed addrs, bool indexed flag, address caller);

  function projects() external view returns (IJBProjects);

  function splitsStore() external view returns (IJBSplitsStore);

  function directory() external view returns (IJBDirectory);

  function prices() external view returns (IJBPrices);

  function store() external view returns (IJBSingleTokenPaymentTerminalStore);

  function baseWeightCurrency() external view returns (uint256);

  function payoutSplitsGroup() external view returns (uint256);

  function heldFeesOf(uint256 _projectId) external view returns (JBFee[] memory);

  function fee() external view returns (uint256);

  function feeGauge() external view returns (IJBFeeGauge);

  function isFeelessAddress(address _contract) external view returns (bool);

  function migrate(uint256 _projectId, IJBPaymentTerminal _to) external returns (uint256 balance);

  function processFees(uint256 _projectId) external;

  function setFee(uint256 _fee) external;

  function setFeeGauge(IJBFeeGauge _feeGauge) external;

  function setFeelessAddress(address _contract, bool _flag) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBPaymentTerminal.sol';
import './JBTokenAmount.sol';

/** 
  @member terminal The terminal that is facilitating the payment.
  @member payer The address from which the payment originated.
  @member amount The amount of the payment. Includes the token being paid, the value, the number of decimals included, and the currency of the amount.
  @member projectId The ID of the project being paid.
  @member currentFundingCycleConfiguration The configuration of the funding cycle during which the payment is being made.
  @member beneficiary The specified address that should be the beneficiary of anything that results from the payment.
  @member weight The weight of the funding cycle during which the payment is being made.
  @member reservedRate The reserved rate of the funding cycle during which the payment is being made.
  @member memo The memo that was sent alongside the payment.
  @member metadata Extra data provided by the payer.
*/
struct JBPayParamsData {
  IJBPaymentTerminal terminal;
  address payer;
  JBTokenAmount amount;
  uint256 projectId;
  uint256 currentFundingCycleConfiguration;
  address beneficiary;
  uint256 weight;
  uint256 reservedRate;
  string memo;
  bytes metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/* 
  @member token The token the payment was made in.
  @member value The amount of tokens that was paid, as a fixed point number.
  @member decimals The number of decimals included in the value fixed point number.
  @member currency The expected currency of the value.
**/
struct JBTokenAmount {
  address token;
  uint256 value;
  uint256 decimals;
  uint256 currency;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

/**
 * @dev Doesn't track balances.
 *
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
  using Address for address;
  using Strings for uint256;

  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  // Mapping from token ID to owner address
  mapping(uint256 => address) internal _owners;

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
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
    @dev Balance tracking to be overriden by childs
  */
  function balanceOf(address owner) external view virtual override returns (uint256 balance) {
    owner;
    return 0;
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId) public view virtual override returns (address) {
    address owner = _owners[tokenId];
    require(owner != address(0), 'ERC721: invalid token ID');
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
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    _requireMinted(tokenId);

    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
  }

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
   * by default, can be overridden in child contracts.
   */
  function _baseURI() internal view virtual returns (string memory) {
    return '';
  }

  /**
   * @dev See {IERC721-approve}.
   */
  function approve(address to, uint256 tokenId) public virtual override {
    address owner = ERC721.ownerOf(tokenId);
    require(to != owner, 'ERC721: approval to current owner');

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      'ERC721: approve caller is not token owner nor approved for all'
    );

    _approve(to, tokenId);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId) public view virtual override returns (address) {
    _requireMinted(tokenId);

    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) public virtual override {
    _setApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
  {
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
      'ERC721: caller is not token owner nor approved'
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
    safeTransferFrom(from, to, tokenId, '');
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
      'ERC721: caller is not token owner nor approved'
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
      'ERC721: transfer to non ERC721Receiver implementer'
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
    return _owners[tokenId] != address(0);
  }

  /**
   * @dev Returns whether `spender` is allowed to manage `tokenId`.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function _isApprovedOrOwner(address spender, uint256 tokenId)
    internal
    view
    virtual
    returns (bool)
  {
    address owner = ERC721.ownerOf(tokenId);
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
    _safeMint(to, tokenId, '');
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
      'ERC721: transfer to non ERC721Receiver implementer'
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
    require(to != address(0), 'ERC721: mint to the zero address');
    require(!_exists(tokenId), 'ERC721: token already minted');

    _beforeTokenTransfer(address(0), to, tokenId);

    _owners[tokenId] = to;

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
    address owner = ERC721.ownerOf(tokenId);

    _beforeTokenTransfer(owner, address(0), tokenId);

    // Clear approvals
    _approve(address(0), tokenId);

    delete _owners[tokenId];

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
    require(ERC721.ownerOf(tokenId) == from, 'ERC721: transfer from incorrect owner');
    require(to != address(0), 'ERC721: transfer to the zero address');

    _beforeTokenTransfer(from, to, tokenId);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId);

    _owners[tokenId] = to;

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
    emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
    require(owner != operator, 'ERC721: approve to caller');
    _operatorApprovals[owner][operator] = approved;
    emit ApprovalForAll(owner, operator, approved);
  }

  /**
   * @dev Reverts if the `tokenId` has not been minted yet.
   */
  function _requireMinted(uint256 tokenId) internal view virtual {
    require(_exists(tokenId), 'ERC721: invalid token ID');
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
      try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (
        bytes4 retval
      ) {
        return retval == IERC721Receiver.onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert('ERC721: transfer to non ERC721Receiver implementer');
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@jbx-protocol/contracts-v2/contracts/interfaces/IJBDirectory.sol';
import '@jbx-protocol/contracts-v2/contracts/interfaces/IJBTokenUriResolver.sol';

interface IJBNFTRewardDataSource {
  event SetContractUri(string indexed contractUri, address caller);

  event SetBaseUri(string indexed baseUri, address caller);

  event SetTokenUriResolver(IJBTokenUriResolver indexed newResolver, address caller);

  function projectId() external view returns (uint256);

  function directory() external view returns (IJBDirectory);

  function contractUri() external view returns (string memory);

  function tokenUriResolver() external view returns (IJBTokenUriResolver);

  // function firstOwnerOf(uint256 _tokenId) external view returns (address);

  function setContractUri(string calldata _contractMetadataUri) external;

  function setTokenUriResolver(IJBTokenUriResolver _tokenUriResolverAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/**
  @member contributionFloor The minimum contribution to qualify for this tier.
  @member lockedUntil The time up to which this tier cannot be removed or paused.
  @member remainingQuantity Remaining number of tokens in this tier. Together with idCeiling this enables for consecutive, increasing token ids to be issued to contributors.
  @member initialQuantity The initial `remainingAllowance` value when the tier was set.
  @member votingUnits The amount of voting significance to give this tier compared to others.
  @memver reservedRate The number of minted tokens needed in the tier to allow for minting another reserved token.
  @member tokenUri The URI to use for each token within the tier.
*/
struct JBNFTRewardTierData {
  uint80 contributionFloor;
  uint48 lockedUntil;
  uint48 remainingQuantity;
  uint48 initialQuantity;
  uint16 votingUnits;
  uint16 reservedRate;
  bytes32 tokenUri;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './JBNFTRewardTierData.sol';

/**
  @member id The tier's ID.
  @member data The data describing the tier's properties.
*/
struct JBNFTRewardTier {
  uint256 id;
  JBNFTRewardTierData data;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../structs/JBNFTRewardTierData.sol';
import './../structs/JBNFTRewardTier.sol';

interface IJBTieredLimitedNFTRewardDataSourceStore {
  event AddTier(uint256 indexed tierId, JBNFTRewardTierData data, address caller);
  event RemoveTier(uint256 indexed tierId, address caller);

  function totalSupply(address _nft) external view returns (uint256);

  function balanceOf(address _nft, address _owner) external view returns (uint256);

  function numberOfTiers(address _nft) external view returns (uint256);

  function tiers(address _nft) external view returns (JBNFTRewardTier[] memory tiers);

  function tier(address _nft, uint256 _id) external view returns (JBNFTRewardTier memory tier);

  function tierBalanceOf(
    address _nft,
    address _owner,
    uint256 _tier
  ) external view returns (uint256);

  function tierOfTokenId(address _nft, uint256 _tokenId)
    external
    view
    returns (JBNFTRewardTier memory tier);

  function tierIdOfToken(uint256 _tokenId) external pure returns (uint256);

  // function redemptionWeightOf(address _nft, uint256[] memory _tokenIds)
  //   external
  //   view
  //   returns (uint256 weight);

  // function totalRedemptionWeight(address _nft) external view returns (uint256 weight);

  function numberOfReservedTokensOutstandingFor(address _nft, uint256 _tierId)
    external
    view
    returns (uint256);

  function numberOfReservesMintedFor(address _nft, uint256 _tierId) external view returns (uint256);

  function isTierRemoved(address _nft, uint256 _tierId) external view returns (bool);

  function votingUnitsOf(address _nft, address _account) external view returns (uint256 units);

  function reservedTokenBeneficiary(address _nft) external view returns (address);

  function recordAddTierData(JBNFTRewardTierData[] memory _tierData, bool _constructorTiers)
    external;

  function recordMintReservesFor(uint256 _tierId, uint256 _count)
    external
    returns (uint256[] memory tokenIds);

  function recordMintBestAvailableTier(
    uint256 _amount,
    address _beneficiary,
    bool _expectMint
  )
    external
    returns (
      uint256 tokenId,
      uint256 tierId,
      uint256 leftoverAmount
    );

  function recordSetReservedTokenBeneficiary(address _beneficiary) external;

  function recordMint(
    uint256 _amount,
    uint256 _tierId,
    address _beneficiary
  ) external returns (uint256 tokenId, uint256 leftoverAmount);

  function recordRemoveTierIds(uint256[] memory _tierIds) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/** 
  @member operator The address of the operator.
  @member domain The domain within which the operator is being given permissions. A domain of 0 is a wildcard domain, which gives an operator access to all domains.
  @member permissionIndexes The indexes of the permissions the operator is being given.
*/
struct JBOperatorData {
  address operator;
  uint256 domain;
  uint256[] permissionIndexes;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBPaymentTerminal.sol';
import './JBTokenAmount.sol';

/** 
  @member terminal The terminal that is facilitating the redemption.
  @member holder The holder of the tokens being redeemed.
  @member projectId The ID of the project whos tokens are being redeemed.
  @member currentFundingCycleConfiguration The configuration of the funding cycle during which the redemption is being made.
  @member tokenCount The proposed number of tokens being redeemed, as a fixed point number with 18 decimals.
  @member totalSupply The total supply of tokens used in the calculation, as a fixed point number with 18 decimals.
  @member overflow The amount of overflow used in the reclaim amount calculation.
  @member reclaimAmount The amount that should be reclaimed by the redeemer using the protocol's standard bonding curve redemption formula. Includes the token being reclaimed, the reclaim value, the number of decimals included, and the currency of the reclaim amount.
  @member useTotalOverflow If overflow across all of a project's terminals is being used when making redemptions.
  @member redemptionRate The redemption rate of the funding cycle during which the redemption is being made.
  @member ballotRedemptionRate The ballot redemption rate of the funding cycle during which the redemption is being made.
  @member memo The proposed memo that is being emitted alongside the redemption.
  @member metadata Extra data provided by the redeemer.
*/
struct JBRedeemParamsData {
  IJBPaymentTerminal terminal;
  address holder;
  uint256 projectId;
  uint256 currentFundingCycleConfiguration;
  uint256 tokenCount;
  uint256 totalSupply;
  uint256 overflow;
  JBTokenAmount reclaimAmount;
  bool useTotalOverflow;
  uint256 redemptionRate;
  uint256 ballotRedemptionRate;
  string memo;
  bytes metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../structs/JBDidRedeemData.sol';

interface IJBRedemptionDelegate is IERC165 {
  function didRedeem(JBDidRedeemData calldata _data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import '../structs/JBSplitAllocationData.sol';

interface IJBSplitAllocator is IERC165 {
  function allocate(JBSplitAllocationData calldata _data) external payable;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248) {
        require(value >= type(int248).min && value <= type(int248).max, "SafeCast: value doesn't fit in 248 bits");
        return int248(value);
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240) {
        require(value >= type(int240).min && value <= type(int240).max, "SafeCast: value doesn't fit in 240 bits");
        return int240(value);
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232) {
        require(value >= type(int232).min && value <= type(int232).max, "SafeCast: value doesn't fit in 232 bits");
        return int232(value);
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224) {
        require(value >= type(int224).min && value <= type(int224).max, "SafeCast: value doesn't fit in 224 bits");
        return int224(value);
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216) {
        require(value >= type(int216).min && value <= type(int216).max, "SafeCast: value doesn't fit in 216 bits");
        return int216(value);
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208) {
        require(value >= type(int208).min && value <= type(int208).max, "SafeCast: value doesn't fit in 208 bits");
        return int208(value);
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200) {
        require(value >= type(int200).min && value <= type(int200).max, "SafeCast: value doesn't fit in 200 bits");
        return int200(value);
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192) {
        require(value >= type(int192).min && value <= type(int192).max, "SafeCast: value doesn't fit in 192 bits");
        return int192(value);
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184) {
        require(value >= type(int184).min && value <= type(int184).max, "SafeCast: value doesn't fit in 184 bits");
        return int184(value);
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176) {
        require(value >= type(int176).min && value <= type(int176).max, "SafeCast: value doesn't fit in 176 bits");
        return int176(value);
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168) {
        require(value >= type(int168).min && value <= type(int168).max, "SafeCast: value doesn't fit in 168 bits");
        return int168(value);
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160) {
        require(value >= type(int160).min && value <= type(int160).max, "SafeCast: value doesn't fit in 160 bits");
        return int160(value);
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152) {
        require(value >= type(int152).min && value <= type(int152).max, "SafeCast: value doesn't fit in 152 bits");
        return int152(value);
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144) {
        require(value >= type(int144).min && value <= type(int144).max, "SafeCast: value doesn't fit in 144 bits");
        return int144(value);
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136) {
        require(value >= type(int136).min && value <= type(int136).max, "SafeCast: value doesn't fit in 136 bits");
        return int136(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120) {
        require(value >= type(int120).min && value <= type(int120).max, "SafeCast: value doesn't fit in 120 bits");
        return int120(value);
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112) {
        require(value >= type(int112).min && value <= type(int112).max, "SafeCast: value doesn't fit in 112 bits");
        return int112(value);
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104) {
        require(value >= type(int104).min && value <= type(int104).max, "SafeCast: value doesn't fit in 104 bits");
        return int104(value);
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96) {
        require(value >= type(int96).min && value <= type(int96).max, "SafeCast: value doesn't fit in 96 bits");
        return int96(value);
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88) {
        require(value >= type(int88).min && value <= type(int88).max, "SafeCast: value doesn't fit in 88 bits");
        return int88(value);
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80) {
        require(value >= type(int80).min && value <= type(int80).max, "SafeCast: value doesn't fit in 80 bits");
        return int80(value);
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72) {
        require(value >= type(int72).min && value <= type(int72).max, "SafeCast: value doesn't fit in 72 bits");
        return int72(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56) {
        require(value >= type(int56).min && value <= type(int56).max, "SafeCast: value doesn't fit in 56 bits");
        return int56(value);
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48) {
        require(value >= type(int48).min && value <= type(int48).max, "SafeCast: value doesn't fit in 48 bits");
        return int48(value);
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40) {
        require(value >= type(int40).min && value <= type(int40).max, "SafeCast: value doesn't fit in 40 bits");
        return int40(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= type(int24).min && value <= type(int24).max, "SafeCast: value doesn't fit in 24 bits");
        return int24(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivFixedPointOverflow(uint256 prod1);

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivOverflow(uint256 prod1, uint256 denominator);

/// @notice Emitted when one of the inputs is type(int256).min.
error PRBMath__MulDivSignedInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows int256.
error PRBMath__MulDivSignedOverflow(uint256 rAbs);

/// @notice Emitted when the input is MIN_SD59x18.
error PRBMathSD59x18__AbsInputTooSmall();

/// @notice Emitted when ceiling a number overflows SD59x18.
error PRBMathSD59x18__CeilOverflow(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__DivInputTooSmall();

/// @notice Emitted when one of the intermediary unsigned results overflows SD59x18.
error PRBMathSD59x18__DivOverflow(uint256 rAbs);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathSD59x18__ExpInputTooBig(int256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathSD59x18__Exp2InputTooBig(int256 x);

/// @notice Emitted when flooring a number underflows SD59x18.
error PRBMathSD59x18__FloorUnderflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format overflows SD59x18.
error PRBMathSD59x18__FromIntOverflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format underflows SD59x18.
error PRBMathSD59x18__FromIntUnderflow(int256 x);

/// @notice Emitted when the product of the inputs is negative.
error PRBMathSD59x18__GmNegativeProduct(int256 x, int256 y);

/// @notice Emitted when multiplying the inputs overflows SD59x18.
error PRBMathSD59x18__GmOverflow(int256 x, int256 y);

/// @notice Emitted when the input is less than or equal to zero.
error PRBMathSD59x18__LogInputTooSmall(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__MulInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__MulOverflow(uint256 rAbs);

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__PowuOverflow(uint256 rAbs);

/// @notice Emitted when the input is negative.
error PRBMathSD59x18__SqrtNegativeInput(int256 x);

/// @notice Emitted when the calculating the square root overflows SD59x18.
error PRBMathSD59x18__SqrtOverflow(int256 x);

/// @notice Emitted when addition overflows UD60x18.
error PRBMathUD60x18__AddOverflow(uint256 x, uint256 y);

/// @notice Emitted when ceiling a number overflows UD60x18.
error PRBMathUD60x18__CeilOverflow(uint256 x);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathUD60x18__ExpInputTooBig(uint256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathUD60x18__Exp2InputTooBig(uint256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format format overflows UD60x18.
error PRBMathUD60x18__FromUintOverflow(uint256 x);

/// @notice Emitted when multiplying the inputs overflows UD60x18.
error PRBMathUD60x18__GmOverflow(uint256 x, uint256 y);

/// @notice Emitted when the input is less than 1.
error PRBMathUD60x18__LogInputTooSmall(uint256 x);

/// @notice Emitted when the calculating the square root overflows UD60x18.
error PRBMathUD60x18__SqrtOverflow(uint256 x);

/// @notice Emitted when subtraction underflows UD60x18.
error PRBMathUD60x18__SubUnderflow(uint256 x, uint256 y);

/// @dev Common mathematical functions used in both PRBMathSD59x18 and PRBMathUD60x18. Note that this shared library
/// does not always assume the signed 59.18-decimal fixed-point or the unsigned 60.18-decimal fixed-point
/// representation. When it does not, it is explicitly mentioned in the NatSpec documentation.
library PRBMath {
    /// STRUCTS ///

    struct SD59x18 {
        int256 value;
    }

    struct UD60x18 {
        uint256 value;
    }

    /// STORAGE ///

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @dev Largest power of two divisor of SCALE.
    uint256 internal constant SCALE_LPOTD = 262144;

    /// @dev SCALE inverted mod 2^256.
    uint256 internal constant SCALE_INVERSE =
        78156646155174841979727994598816262306175212592076161876661_508869554232690281;

    /// FUNCTIONS ///

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    /// @dev Has to use 192.64-bit fixed-point numbers.
    /// See https://ethereum.stackexchange.com/a/96594/24693.
    /// @param x The exponent as an unsigned 192.64-bit fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // Start from 0.5 in the 192.64-bit fixed-point format.
            result = 0x800000000000000000000000000000000000000000000000;

            // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
            // because the initial result is 2^191 and all magic factors are less than 2^65.
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }

            // We're doing two things at the same time:
            //
            //   1. Multiply the result by 2^n + 1, where "2^n" is the integer part and the one is added to account for
            //      the fact that we initially set the result to 0.5. This is accomplished by subtracting from 191
            //      rather than 192.
            //   2. Convert the result to the unsigned 60.18-decimal fixed-point format.
            //
            // This works because 2^(191-ip) = 2^ip / 2^191, where "ip" is the integer part "2^n".
            result *= SCALE;
            result >>= (191 - (x >> 64));
        }
    }

    /// @notice Finds the zero-based index of the first one in the binary representation of x.
    /// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
    /// @param x The uint256 number for which to find the index of the most significant bit.
    /// @return msb The index of the most significant bit as an uint256.
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The multiplicand as an uint256.
    /// @param y The multiplier as an uint256.
    /// @param denominator The divisor as an uint256.
    /// @return result The result as an uint256.
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
        // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2^256 + prod0.
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division.
        if (prod1 == 0) {
            unchecked {
                result = prod0 / denominator;
            }
            return result;
        }

        // Make sure the result is less than 2^256. Also prevents denominator == 0.
        if (prod1 >= denominator) {
            revert PRBMath__MulDivOverflow(prod1, denominator);
        }

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0].
        uint256 remainder;
        assembly {
            // Compute remainder using mulmod.
            remainder := mulmod(x, y, denominator)

            // Subtract 256 bit number from 512 bit number.
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
        // See https://cs.stackexchange.com/q/138556/92363.
        unchecked {
            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by lpotdod.
                denominator := div(denominator, lpotdod)

                // Divide [prod1 prod0] by lpotdod.
                prod0 := div(prod0, lpotdod)

                // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one.
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * lpotdod;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /// @notice Calculates floor(x*y÷1e18) with full precision.
    ///
    /// @dev Variant of "mulDiv" with constant folding, i.e. in which the denominator is always 1e18. Before returning the
    /// final result, we add 1 if (x * y) % SCALE >= HALF_SCALE. Without this, 6.6e-19 would be truncated to 0 instead of
    /// being rounded to 1e-18.  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717.
    ///
    /// Requirements:
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    /// - It is assumed that the result can never be type(uint256).max when x and y solve the following two equations:
    ///     1. x * y = type(uint256).max * SCALE
    ///     2. (x * y) % SCALE >= SCALE / 2
    ///
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function mulDivFixedPoint(uint256 x, uint256 y) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= SCALE) {
            revert PRBMath__MulDivFixedPointOverflow(prod1);
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(x, y, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            unchecked {
                result = (prod0 / SCALE) + roundUpUnit;
                return result;
            }
        }

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev An extension of "mulDiv" for signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - None of the inputs can be type(int256).min.
    /// - The result must fit within int256.
    ///
    /// @param x The multiplicand as an int256.
    /// @param y The multiplier as an int256.
    /// @param denominator The divisor as an int256.
    /// @return result The result as an int256.
    function mulDivSigned(
        int256 x,
        int256 y,
        int256 denominator
    ) internal pure returns (int256 result) {
        if (x == type(int256).min || y == type(int256).min || denominator == type(int256).min) {
            revert PRBMath__MulDivSignedInputTooSmall();
        }

        // Get hold of the absolute values of x, y and the denominator.
        uint256 ax;
        uint256 ay;
        uint256 ad;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
            ad = denominator < 0 ? uint256(-denominator) : uint256(denominator);
        }

        // Compute the absolute value of (x*y)÷denominator. The result must fit within int256.
        uint256 rAbs = mulDiv(ax, ay, ad);
        if (rAbs > uint256(type(int256).max)) {
            revert PRBMath__MulDivSignedOverflow(rAbs);
        }

        // Get the signs of x, y and the denominator.
        uint256 sx;
        uint256 sy;
        uint256 sd;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
            sd := sgt(denominator, sub(0, 1))
        }

        // XOR over sx, sy and sd. This is checking whether there are one or three negative signs in the inputs.
        // If yes, the result should be negative.
        result = sx ^ sy ^ sd == 0 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The uint256 number for which to calculate the square root.
    /// @return result The result as an uint256.
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the least power of two that is greater than or equal to sqrt(x).
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './JBTokenAmount.sol';

/** 
  @member payer The address from which the payment originated.
  @member projectId The ID of the project for which the payment was made.
  @member currentFundingCycleConfiguration The configuration of the funding cycle during which the payment is being made.
  @member amount The amount of the payment. Includes the token being paid, the value, the number of decimals included, and the currency of the amount.
  @member projectTokenCount The number of project tokens minted for the beneficiary.
  @member beneficiary The address to which the tokens were minted.
  @member preferClaimedTokens A flag indicating whether the request prefered to mint project tokens into the beneficiaries wallet rather than leaving them unclaimed. This is only possible if the project has an attached token contract.
  @member memo The memo that is being emitted alongside the payment.
  @member metadata Extra data to send to the delegate.
*/
struct JBDidPayData {
  address payer;
  uint256 projectId;
  uint256 currentFundingCycleConfiguration;
  JBTokenAmount amount;
  uint256 projectTokenCount;
  address beneficiary;
  bool preferClaimedTokens;
  string memo;
  bytes metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/** 
  @member amount The total amount the fee was taken from, as a fixed point number with the same number of decimals as the terminal in which this struct was created.
  @member fee The percent of the fee, out of MAX_FEE.
  @member feeDiscount The discount of the fee.
  @member beneficiary The address that will receive the tokens that are minted as a result of the fee payment.
*/
struct JBFee {
  uint256 amount;
  uint32 fee;
  uint32 feeDiscount;
  address beneficiary;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IJBAllowanceTerminal {
  function useAllowanceOf(
    uint256 _projectId,
    uint256 _amount,
    uint256 _currency,
    address _token,
    uint256 _minReturnedTokens,
    address payable _beneficiary,
    string calldata _memo
  ) external returns (uint256 netDistributedAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IJBFeeGauge {
  function currentDiscountFor(uint256 _projectId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IJBPayoutTerminal {
  function distributePayoutsOf(
    uint256 _projectId,
    uint256 _amount,
    uint256 _currency,
    address _token,
    uint256 _minReturnedTokens,
    string calldata _memo
  ) external returns (uint256 netLeftoverDistributionAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBPriceFeed.sol';

interface IJBPrices {
  event AddFeed(uint256 indexed currency, uint256 indexed base, IJBPriceFeed feed);

  function feedFor(uint256 _currency, uint256 _base) external view returns (IJBPriceFeed);

  function priceFor(
    uint256 _currency,
    uint256 _base,
    uint256 _decimals
  ) external view returns (uint256);

  function addFeedFor(
    uint256 _currency,
    uint256 _base,
    IJBPriceFeed _priceFeed
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IJBRedemptionTerminal {
  function redeemTokensOf(
    address _holder,
    uint256 _projectId,
    uint256 _count,
    address _token,
    uint256 _minReturnedTokens,
    address payable _beneficiary,
    string calldata _memo,
    bytes calldata _metadata
  ) external returns (uint256 reclaimAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBPaymentTerminal.sol';

interface IJBSingleTokenPaymentTerminal is IJBPaymentTerminal {
  function token() external view returns (address);

  function currency() external view returns (uint256);

  function decimals() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../structs/JBFundingCycle.sol';
import './../structs/JBTokenAmount.sol';
import './IJBDirectory.sol';
import './IJBFundingCycleStore.sol';
import './IJBPayDelegate.sol';
import './IJBPrices.sol';
import './IJBRedemptionDelegate.sol';
import './IJBSingleTokenPaymentTerminal.sol';

interface IJBSingleTokenPaymentTerminalStore {
  function fundingCycleStore() external view returns (IJBFundingCycleStore);

  function directory() external view returns (IJBDirectory);

  function prices() external view returns (IJBPrices);

  function balanceOf(IJBSingleTokenPaymentTerminal _terminal, uint256 _projectId)
    external
    view
    returns (uint256);

  function usedDistributionLimitOf(
    IJBSingleTokenPaymentTerminal _terminal,
    uint256 _projectId,
    uint256 _fundingCycleNumber
  ) external view returns (uint256);

  function usedOverflowAllowanceOf(
    IJBSingleTokenPaymentTerminal _terminal,
    uint256 _projectId,
    uint256 _fundingCycleConfiguration
  ) external view returns (uint256);

  function currentOverflowOf(IJBSingleTokenPaymentTerminal _terminal, uint256 _projectId)
    external
    view
    returns (uint256);

  function currentTotalOverflowOf(
    uint256 _projectId,
    uint256 _decimals,
    uint256 _currency
  ) external view returns (uint256);

  function currentReclaimableOverflowOf(
    IJBSingleTokenPaymentTerminal _terminal,
    uint256 _projectId,
    uint256 _tokenCount,
    bool _useTotalOverflow
  ) external view returns (uint256);

  function currentReclaimableOverflowOf(
    uint256 _projectId,
    uint256 _tokenCount,
    uint256 _totalSupply,
    uint256 _overflow
  ) external view returns (uint256);

  function recordPaymentFrom(
    address _payer,
    JBTokenAmount memory _amount,
    uint256 _projectId,
    uint256 _baseWeightCurrency,
    address _beneficiary,
    string calldata _memo,
    bytes calldata _metadata
  )
    external
    returns (
      JBFundingCycle memory fundingCycle,
      uint256 tokenCount,
      IJBPayDelegate delegate,
      string memory memo
    );

  function recordRedemptionFor(
    address _holder,
    uint256 _projectId,
    uint256 _tokenCount,
    string calldata _memo,
    bytes calldata _metadata
  )
    external
    returns (
      JBFundingCycle memory fundingCycle,
      uint256 reclaimAmount,
      IJBRedemptionDelegate delegate,
      string memory memo
    );

  function recordDistributionFor(
    uint256 _projectId,
    uint256 _amount,
    uint256 _currency
  ) external returns (JBFundingCycle memory fundingCycle, uint256 distributedAmount);

  function recordUsedAllowanceOf(
    uint256 _projectId,
    uint256 _amount,
    uint256 _currency
  ) external returns (JBFundingCycle memory fundingCycle, uint256 withdrawnAmount);

  function recordAddedBalanceFor(uint256 _projectId, uint256 _amount) external;

  function recordMigration(uint256 _projectId) external returns (uint256 balance);
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
pragma solidity 0.8.6;

import './JBTokenAmount.sol';

/** 
  @member holder The holder of the tokens being redeemed.
  @member projectId The ID of the project with which the redeemed tokens are associated.
  @member currentFundingCycleConfiguration The configuration of the funding cycle during which the redemption is being made.
  @member projectTokenCount The number of project tokens being redeemed.
  @member reclaimedAmount The amount reclaimed from the treasury. Includes the token being reclaimed, the value, the number of decimals included, and the currency of the amount.
  @member beneficiary The address to which the reclaimed amount will be sent.
  @member memo The memo that is being emitted alongside the redemption.
  @member metadata Extra data to send to the delegate.
*/
struct JBDidRedeemData {
  address holder;
  uint256 projectId;
  uint256 currentFundingCycleConfiguration;
  uint256 projectTokenCount;
  JBTokenAmount reclaimedAmount;
  address payable beneficiary;
  string memo;
  bytes metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './JBSplit.sol';

/** 
  @member token The token being sent to the split allocator.
  @member amount The amount being sent to the split allocator, as a fixed point number.
  @member decimals The number of decimals in the amount.
  @member projectId The project to which the split belongs.
  @member group The group to which the split belongs.
  @member split The split that caused the allocation.
*/
struct JBSplitAllocationData {
  address token;
  uint256 amount;
  uint256 decimals;
  uint256 projectId;
  uint256 group;
  JBSplit split;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IJBPriceFeed {
  function currentPrice(uint256 _targetDecimals) external view returns (uint256);
}