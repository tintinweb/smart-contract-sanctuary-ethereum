// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { JBOwnable } from "@jbx-protocol/juice-ownable/src/JBOwnable.sol";
import { JBOperatable } from "@jbx-protocol/juice-contracts-v3/contracts/abstract/JBOperatable.sol";
import { IJBDirectory } from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBDirectory.sol";
import { IJBController3_1 } from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBController3_1.sol";
import { IJBOperatorStore } from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBOperatorStore.sol";
import { JBOperations } from "@jbx-protocol/juice-contracts-v3/contracts/libraries/JBOperations.sol";
import { JBFundingCycleMetadata } from "@jbx-protocol/juice-contracts-v3/contracts/structs/JBFundingCycleMetadata.sol";

import { IJBTiered721DelegateDeployer } from "./interfaces/IJBTiered721DelegateDeployer.sol";
import { IJBTiered721DelegateProjectDeployer } from "./interfaces/IJBTiered721DelegateProjectDeployer.sol";
import { IJBTiered721Delegate } from "./interfaces/IJBTiered721Delegate.sol";
import { JBDeployTiered721DelegateData } from "./structs/JBDeployTiered721DelegateData.sol";
import { JBLaunchFundingCyclesData } from "./structs/JBLaunchFundingCyclesData.sol";
import { JBReconfigureFundingCyclesData } from "./structs/JBReconfigureFundingCyclesData.sol";
import { JBLaunchProjectData } from "./structs/JBLaunchProjectData.sol";

/// @title JBTiered721DelegateProjectDeployer
/// @notice Deploys a project with an associated tiered 721 delegate.
/// @custom:version 3.3
contract JBTiered721DelegateProjectDeployer is JBOperatable, IJBTiered721DelegateProjectDeployer {
    //*********************************************************************//
    // --------------- public immutable stored properties ---------------- //
    //*********************************************************************//

    /// @notice The directory of terminals and controllers for projects.
    IJBDirectory public immutable override directory;

    /// @notice The contract responsible for deploying the delegate.
    IJBTiered721DelegateDeployer public immutable override delegateDeployer;

    //*********************************************************************//
    // -------------------------- constructor ---------------------------- //
    //*********************************************************************//

    /// @param _directory The directory of terminals and controllers for projects.
    /// @param _delegateDeployer The delegate deployer.
    /// @param _operatorStore A contract storing operator assignments.
    constructor(
        IJBDirectory _directory,
        IJBTiered721DelegateDeployer _delegateDeployer,
        IJBOperatorStore _operatorStore
    ) JBOperatable(_operatorStore) {
        directory = _directory;
        delegateDeployer = _delegateDeployer;
    }

    //*********************************************************************//
    // ---------------------- external transactions ---------------------- //
    //*********************************************************************//

    /// @notice Launches a new project with a tiered 721 delegate attached.
    /// @param _owner The address to set as the owner of the project. The project's ERC-721 will be owned by this address.
    /// @param _deployTiered721DelegateData Data necessary to deploy the delegate.
    /// @param _launchProjectData Data necessary to launch the project.
    /// @param _controller The controller with which the funding cycles should be configured.
    /// @return projectId The ID of the newly configured project.
    function launchProjectFor(
        address _owner,
        JBDeployTiered721DelegateData memory _deployTiered721DelegateData,
        JBLaunchProjectData memory _launchProjectData,
        IJBController3_1 _controller
    ) external override returns (uint256 projectId) {
        // Get the project ID, optimistically knowing it will be one greater than the current count.
        projectId = directory.projects().count() + 1;

        // Deploy the delegate contract.
        IJBTiered721Delegate _delegate =
            delegateDeployer.deployDelegateFor(projectId, _deployTiered721DelegateData, directory);

        // Launch the project.
        _launchProjectFor(_owner, _launchProjectData, _delegate, _controller);

        // Transfer the ownership of the delegate to the project.
        JBOwnable(address(_delegate)).transferOwnershipToProject(projectId);
    }

    /// @notice Launches funding cycles for a project with an attached delegate.
    /// @dev Only a project's owner or operator can launch its funding cycles.
    /// @param _projectId The ID of the project for which the funding cycles will be launched.
    /// @param _deployTiered721DelegateData Data necessary to deploy a delegate.
    /// @param _launchFundingCyclesData Data necessary to launch the funding cycles for the project.
    /// @param _controller The controller with which the funding cycles should be configured.
    /// @return configuration The configuration of the funding cycle that was successfully created.
    function launchFundingCyclesFor(
        uint256 _projectId,
        JBDeployTiered721DelegateData memory _deployTiered721DelegateData,
        JBLaunchFundingCyclesData memory _launchFundingCyclesData,
        IJBController3_1 _controller
    )
        external
        override
        requirePermission(directory.projects().ownerOf(_projectId), _projectId, JBOperations.RECONFIGURE)
        returns (uint256 configuration)
    {
        // Deploy the delegate contract.
        IJBTiered721Delegate _delegate =
            delegateDeployer.deployDelegateFor(_projectId, _deployTiered721DelegateData, directory);

        // Transfer the ownership of the delegate to the project.
        JBOwnable(address(_delegate)).transferOwnershipToProject(_projectId);

        // Launch the funding cycles.
        return _launchFundingCyclesFor(_projectId, _launchFundingCyclesData, _delegate, _controller);
    }
    
    /// @notice Reconfigures funding cycles for a project with an attached delegate.
    /// @dev Only a project's owner or operator can configure its funding cycles.
    /// @param _projectId The ID of the project for which funding cycles are being reconfigured.
    /// @param _deployTiered721DelegateData Data necessary to deploy a delegate.
    /// @param _reconfigureFundingCyclesData Data necessary to reconfigure the funding cycle.
    /// @param _controller The controller with which the funding cycles should be configured.
    /// @return configuration The configuration of the successfully reconfigured funding cycle.
    function reconfigureFundingCyclesOf(
        uint256 _projectId,
        JBDeployTiered721DelegateData memory _deployTiered721DelegateData,
        JBReconfigureFundingCyclesData memory _reconfigureFundingCyclesData,
        IJBController3_1 _controller
    )
        external
        override
        requirePermission(directory.projects().ownerOf(_projectId), _projectId, JBOperations.RECONFIGURE)
        returns (uint256 configuration)
    {
        // Deploy the delegate contract.
        IJBTiered721Delegate _delegate =
            delegateDeployer.deployDelegateFor(_projectId, _deployTiered721DelegateData, directory);

        // Transfer the ownership of the delegate to the project.
        JBOwnable(address(_delegate)).transferOwnershipToProject(_projectId);

        // Reconfigure the funding cycles.
        return _reconfigureFundingCyclesOf(_projectId, _reconfigureFundingCyclesData, _delegate, _controller);
    }

    //*********************************************************************//
    // ------------------------ internal functions ----------------------- //
    //*********************************************************************//

    /// @notice Launches a project.
    /// @param _owner The address to set as the project's owner.
    /// @param _launchProjectData Data needed to launch the project.
    /// @param _dataSource The data source to set for the project.
    /// @param _controller The controller to be used for configuring the project's funding cycles.
    function _launchProjectFor(
        address _owner,
        JBLaunchProjectData memory _launchProjectData,
        IJBTiered721Delegate _dataSource,
        IJBController3_1 _controller
    ) internal {
        _controller.launchProjectFor(
            _owner,
            _launchProjectData.projectMetadata,
            _launchProjectData.data,
            JBFundingCycleMetadata({
                global: _launchProjectData.metadata.global,
                reservedRate: _launchProjectData.metadata.reservedRate,
                redemptionRate: _launchProjectData.metadata.redemptionRate,
                ballotRedemptionRate: _launchProjectData.metadata.ballotRedemptionRate,
                pausePay: _launchProjectData.metadata.pausePay,
                pauseDistributions: _launchProjectData.metadata.pauseDistributions,
                pauseRedeem: _launchProjectData.metadata.pauseRedeem,
                pauseBurn: _launchProjectData.metadata.pauseBurn,
                allowMinting: _launchProjectData.metadata.allowMinting,
                allowTerminalMigration: _launchProjectData.metadata.allowTerminalMigration,
                allowControllerMigration: _launchProjectData.metadata.allowControllerMigration,
                holdFees: _launchProjectData.metadata.holdFees,
                preferClaimedTokenOverride: _launchProjectData.metadata.preferClaimedTokenOverride,
                useTotalOverflowForRedemptions: _launchProjectData.metadata.useTotalOverflowForRedemptions,
                // Enable using the data source for the project's pay function.
                useDataSourceForPay: true,
                useDataSourceForRedeem: _launchProjectData.metadata.useDataSourceForRedeem,
                // Set the delegate address as the data source of the project's funding cycle metadata.
                dataSource: address(_dataSource),
                metadata: _launchProjectData.metadata.metadata
            }),
            _launchProjectData.mustStartAtOrAfter,
            _launchProjectData.groupedSplits,
            _launchProjectData.fundAccessConstraints,
            _launchProjectData.terminals,
            _launchProjectData.memo
        );
    }

    /// @notice Launches a funding cycle for a project.
    /// @param _projectId The project ID to launch a funding cycle for.
    /// @param _launchFundingCyclesData Data necessary to launch a funding cycle for the project.
    /// @param _dataSource The data source to be set for the project.
    /// @param _controller The controller to configure the project's funding cycles with.
    /// @return configuration The configuration of the funding cycle that was successfully created.
    function _launchFundingCyclesFor(
        uint256 _projectId,
        JBLaunchFundingCyclesData memory _launchFundingCyclesData,
        IJBTiered721Delegate _dataSource,
        IJBController3_1 _controller
    ) internal returns (uint256) {
        return _controller.launchFundingCyclesFor(
            _projectId,
            _launchFundingCyclesData.data,
            JBFundingCycleMetadata({
                global: _launchFundingCyclesData.metadata.global,
                reservedRate: _launchFundingCyclesData.metadata.reservedRate,
                redemptionRate: _launchFundingCyclesData.metadata.redemptionRate,
                ballotRedemptionRate: _launchFundingCyclesData.metadata.ballotRedemptionRate,
                pausePay: _launchFundingCyclesData.metadata.pausePay,
                pauseDistributions: _launchFundingCyclesData.metadata.pauseDistributions,
                pauseRedeem: _launchFundingCyclesData.metadata.pauseRedeem,
                pauseBurn: _launchFundingCyclesData.metadata.pauseBurn,
                allowMinting: _launchFundingCyclesData.metadata.allowMinting,
                allowTerminalMigration: _launchFundingCyclesData.metadata.allowTerminalMigration,
                allowControllerMigration: _launchFundingCyclesData.metadata.allowControllerMigration,
                holdFees: _launchFundingCyclesData.metadata.holdFees,
                preferClaimedTokenOverride: _launchFundingCyclesData.metadata.preferClaimedTokenOverride,
                useTotalOverflowForRedemptions: _launchFundingCyclesData.metadata.useTotalOverflowForRedemptions,
                // Set the project to use the data source for its pay function.
                useDataSourceForPay: true,
                useDataSourceForRedeem: _launchFundingCyclesData.metadata.useDataSourceForRedeem,
                // Set the delegate address as the data source of the provided metadata.
                dataSource: address(_dataSource),
                metadata: _launchFundingCyclesData.metadata.metadata
            }),
            _launchFundingCyclesData.mustStartAtOrAfter,
            _launchFundingCyclesData.groupedSplits,
            _launchFundingCyclesData.fundAccessConstraints,
            _launchFundingCyclesData.terminals,
            _launchFundingCyclesData.memo
        );
    }

    /// @notice Reconfigure funding cycles for a project.
    /// @param _projectId The ID of the project for which the funding cycles are being reconfigured.
    /// @param _reconfigureFundingCyclesData Data necessary to reconfigure the project's funding cycles.
    /// @param _dataSource The data source to be set for the project.
    /// @param _controller The controller to be used for configuring the project's funding cycles.
    /// @return The configuration of the successfully reconfigured funding cycle.
    function _reconfigureFundingCyclesOf(
        uint256 _projectId,
        JBReconfigureFundingCyclesData memory _reconfigureFundingCyclesData,
        IJBTiered721Delegate _dataSource,
        IJBController3_1 _controller
    ) internal returns (uint256) {
        return _controller.reconfigureFundingCyclesOf(
            _projectId,
            _reconfigureFundingCyclesData.data,
            JBFundingCycleMetadata({
                global: _reconfigureFundingCyclesData.metadata.global,
                reservedRate: _reconfigureFundingCyclesData.metadata.reservedRate,
                redemptionRate: _reconfigureFundingCyclesData.metadata.redemptionRate,
                ballotRedemptionRate: _reconfigureFundingCyclesData.metadata.ballotRedemptionRate,
                pausePay: _reconfigureFundingCyclesData.metadata.pausePay,
                pauseDistributions: _reconfigureFundingCyclesData.metadata.pauseDistributions,
                pauseRedeem: _reconfigureFundingCyclesData.metadata.pauseRedeem,
                pauseBurn: _reconfigureFundingCyclesData.metadata.pauseBurn,
                allowMinting: _reconfigureFundingCyclesData.metadata.allowMinting,
                allowTerminalMigration: _reconfigureFundingCyclesData.metadata.allowTerminalMigration,
                allowControllerMigration: _reconfigureFundingCyclesData.metadata.allowControllerMigration,
                holdFees: _reconfigureFundingCyclesData.metadata.holdFees,
                preferClaimedTokenOverride: _reconfigureFundingCyclesData.metadata.preferClaimedTokenOverride,
                useTotalOverflowForRedemptions: _reconfigureFundingCyclesData.metadata.useTotalOverflowForRedemptions,
                // Set the project to use the data source for its pay function.
                useDataSourceForPay: true,
                useDataSourceForRedeem: _reconfigureFundingCyclesData.metadata.useDataSourceForRedeem,
                // Set the delegate address as the data source of the provided metadata.
                dataSource: address(_dataSource),
                metadata: _reconfigureFundingCyclesData.metadata.metadata
            }),
            _reconfigureFundingCyclesData.mustStartAtOrAfter,
            _reconfigureFundingCyclesData.groupedSplits,
            _reconfigureFundingCyclesData.fundAccessConstraints,
            _reconfigureFundingCyclesData.memo
        );
    }
}

// SPDX-License-Identifier: MIT
// Juicebox variation on OpenZeppelin Ownable
pragma solidity ^0.8.0;

import { JBOwnableOverrides, IJBProjects, IJBOperatorStore } from "./JBOwnableOverrides.sol";

contract JBOwnable is JBOwnableOverrides {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
      @param _projects the JBProjects to use to get the owner of the project
      @param _operatorStore the operatorStore to use for the permissions
     */
    constructor(
        IJBProjects _projects,
        IJBOperatorStore _operatorStore
    ) JBOwnableOverrides(_projects, _operatorStore) {}

    /**
     * @dev Throws if called by an account that is not the owner and does not have permission to act as the owner
     */
    modifier onlyOwner() virtual {
        _checkOwner();
        _;
    }

    function _emitTransferEvent(address previousOwner, address newOwner)
        internal
        virtual
        override
    {
        emit OwnershipTransferred(previousOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

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
pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../structs/JBFundAccessConstraints.sol';
import './../structs/JBFundingCycleData.sol';
import './../structs/JBFundingCycleMetadata.sol';
import './../structs/JBGroupedSplits.sol';
import './../structs/JBProjectMetadata.sol';
import './IJBController3_0_1.sol';
import './IJBDirectory.sol';
import './IJBFundingCycleStore.sol';
import './IJBMigratable.sol';
import './IJBPaymentTerminal.sol';
import './IJBSplitsStore.sol';
import './IJBTokenStore.sol';

interface IJBController3_1 is IJBController3_0_1, IERC165 {
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
pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

library JBOperations {
  uint256 public constant RECONFIGURE = 1;
  uint256 public constant REDEEM = 2;
  uint256 public constant MIGRATE_CONTROLLER = 3;
  uint256 public constant MIGRATE_TERMINAL = 4;
  uint256 public constant PROCESS_FEES = 5;
  uint256 public constant SET_METADATA = 6;
  uint256 public constant ISSUE = 7;
  uint256 public constant SET_TOKEN = 8;
  uint256 public constant MINT = 9;
  uint256 public constant BURN = 10;
  uint256 public constant CLAIM = 11;
  uint256 public constant TRANSFER = 12;
  uint256 public constant REQUIRE_CLAIM = 13; // unused in v3
  uint256 public constant SET_CONTROLLER = 14;
  uint256 public constant SET_TERMINALS = 15;
  uint256 public constant SET_PRIMARY_TERMINAL = 16;
  uint256 public constant USE_ALLOWANCE = 17;
  uint256 public constant SET_SPLITS = 18;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './JBGlobalFundingCycleMetadata.sol';

/** 
  @member global Data used globally in non-migratable ecosystem contracts.
  @member reservedRate The reserved rate of the funding cycle. This number is a percentage calculated out of `JBConstants.MAX_RESERVED_RATE`.
  @member redemptionRate The redemption rate of the funding cycle. This number is a percentage calculated out of `JBConstants.MAX_REDEMPTION_RATE`.
  @member ballotRedemptionRate The redemption rate to use during an active ballot of the funding cycle. This number is a percentage calculated out of `JBConstants.MAX_REDEMPTION_RATE`.
  @member pausePay A flag indicating if the pay functionality should be paused during the funding cycle.
  @member pauseDistributions A flag indicating if the distribute functionality should be paused during the funding cycle.
  @member pauseRedeem A flag indicating if the redeem functionality should be paused during the funding cycle.
  @member pauseBurn A flag indicating if the burn functionality should be paused during the funding cycle.
  @member allowMinting A flag indicating if minting tokens should be allowed during this funding cycle.
  @member allowTerminalMigration A flag indicating if migrating terminals should be allowed during this funding cycle.
  @member allowControllerMigration A flag indicating if migrating controllers should be allowed during this funding cycle.
  @member holdFees A flag indicating if fees should be held during this funding cycle.
  @member preferClaimedTokenOverride A flag indicating if claimed tokens should always be prefered to unclaimed tokens when minting.
  @member useTotalOverflowForRedemptions A flag indicating if redemptions should use the project's balance held in all terminals instead of the project's local terminal balance from which the redemption is being fulfilled.
  @member useDataSourceForPay A flag indicating if the data source should be used for pay transactions during this funding cycle.
  @member useDataSourceForRedeem A flag indicating if the data source should be used for redeem transactions during this funding cycle.
  @member dataSource The data source to use during this funding cycle.
  @member metadata Metadata of the metadata, up to uint8 in size.
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
  bool allowTerminalMigration;
  bool allowControllerMigration;
  bool holdFees;
  bool preferClaimedTokenOverride;
  bool useTotalOverflowForRedemptions;
  bool useDataSourceForPay;
  bool useDataSourceForRedeem;
  address dataSource;
  uint256 metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IJBDirectory } from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBDirectory.sol";

import { JB721GovernanceType } from "../enums/JB721GovernanceType.sol";
import { JBDeployTiered721DelegateData } from "../structs/JBDeployTiered721DelegateData.sol";
import { IJBTiered721Delegate } from "./IJBTiered721Delegate.sol";

interface IJBTiered721DelegateDeployer {
    event DelegateDeployed(
        uint256 indexed projectId,
        IJBTiered721Delegate newDelegate,
        JB721GovernanceType governanceType,
        IJBDirectory directory
    );

    function deployDelegateFor(
        uint256 projectId,
        JBDeployTiered721DelegateData memory deployTieredNFTRewardDelegateData,
        IJBDirectory directory
    ) external returns (IJBTiered721Delegate delegate);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IJBDirectory } from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBDirectory.sol";
import { IJBProjects } from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBProjects.sol";
import { IJBController3_1 } from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBController3_1.sol";
import { JBProjectMetadata } from "@jbx-protocol/juice-contracts-v3/contracts/structs/JBProjectMetadata.sol";

import { JBDeployTiered721DelegateData } from "../structs/JBDeployTiered721DelegateData.sol";
import { JBLaunchProjectData } from "../structs/JBLaunchProjectData.sol";
import { JBLaunchFundingCyclesData } from "../structs/JBLaunchFundingCyclesData.sol";
import { JBReconfigureFundingCyclesData } from "../structs/JBReconfigureFundingCyclesData.sol";
import { IJBTiered721DelegateDeployer } from "./IJBTiered721DelegateDeployer.sol";

interface IJBTiered721DelegateProjectDeployer {
    function directory() external view returns (IJBDirectory);

    function delegateDeployer() external view returns (IJBTiered721DelegateDeployer);

    function launchProjectFor(
        address owner,
        JBDeployTiered721DelegateData memory deployTiered721DelegateData,
        JBLaunchProjectData memory launchProjectData,
        IJBController3_1 controller
    ) external returns (uint256 projectId);

    function launchFundingCyclesFor(
        uint256 projectId,
        JBDeployTiered721DelegateData memory deployTiered721DelegateData,
        JBLaunchFundingCyclesData memory launchFundingCyclesData,
        IJBController3_1 controller
    ) external returns (uint256 configuration);

    function reconfigureFundingCyclesOf(
        uint256 projectId,
        JBDeployTiered721DelegateData memory deployTiered721DelegateData,
        JBReconfigureFundingCyclesData memory reconfigureFundingCyclesData,
        IJBController3_1 controller
    ) external returns (uint256 configuration);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IJBDirectory } from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBDirectory.sol";
import { IJBFundingCycleStore } from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBFundingCycleStore.sol";
import { IJBPrices } from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPrices.sol";

import { IJB721Delegate } from "./IJB721Delegate.sol";
import { IJB721TokenUriResolver } from "./IJB721TokenUriResolver.sol";
import { IJBTiered721DelegateStore } from "./IJBTiered721DelegateStore.sol";
import { JB721PricingParams } from "./../structs/JB721PricingParams.sol";
import { JB721TierParams } from "./../structs/JB721TierParams.sol";
import { JBTiered721Flags } from "./../structs/JBTiered721Flags.sol";
import { JBTiered721MintReservesForTiersData } from "./../structs/JBTiered721MintReservesForTiersData.sol";
import { JBTiered721MintForTiersData } from "./../structs/JBTiered721MintForTiersData.sol";

interface IJBTiered721Delegate is IJB721Delegate {
    event Mint(
        uint256 indexed tokenId,
        uint256 indexed tierId,
        address indexed beneficiary,
        uint256 totalAmountContributed,
        address caller
    );

    event MintReservedToken(
        uint256 indexed tokenId, uint256 indexed tierId, address indexed beneficiary, address caller
    );

    event AddTier(uint256 indexed tierId, JB721TierParams data, address caller);

    event RemoveTier(uint256 indexed tierId, address caller);

    event SetEncodedIPFSUri(uint256 indexed tierId, bytes32 encodedIPFSUri, address caller);

    event SetBaseUri(string indexed baseUri, address caller);

    event SetContractUri(string indexed contractUri, address caller);

    event SetTokenUriResolver(IJB721TokenUriResolver indexed newResolver, address caller);

    event AddCredits(
        uint256 indexed changeAmount, uint256 indexed newTotalCredits, address indexed account, address caller
    );

    event UseCredits(
        uint256 indexed changeAmount, uint256 indexed newTotalCredits, address indexed account, address caller
    );

    function codeOrigin() external view returns (address);

    function store() external view returns (IJBTiered721DelegateStore);

    function fundingCycleStore() external view returns (IJBFundingCycleStore);

    function pricingContext() external view returns (uint256, uint256, IJBPrices);

    function creditsOf(address _address) external view returns (uint256);

    function firstOwnerOf(uint256 _tokenId) external view returns (address);

    function baseURI() external view returns (string memory);

    function contractURI() external view returns (string memory);

    function adjustTiers(JB721TierParams[] memory tierDataToAdd, uint256[] memory tierIdsToRemove) external;

    function mintReservesFor(JBTiered721MintReservesForTiersData[] memory mintReservesForTiersData) external;

    function mintReservesFor(uint256 tierId, uint256 count) external;

    function mintFor(uint16[] calldata tierIds, address beneficiary) external returns (uint256[] memory tokenIds);

    function setMetadata(
        string memory baseUri,
        string calldata contractMetadataUri,
        IJB721TokenUriResolver tokenUriResolver,
        uint256 encodedIPFSUriTierId,
        bytes32 encodedIPFSUri
    ) external;

    function initialize(
        uint256 projectId,
        IJBDirectory directory,
        string memory name,
        string memory symbol,
        IJBFundingCycleStore fundingCycleStore,
        string memory baseUri,
        IJB721TokenUriResolver tokenUriResolver,
        string memory contractUri,
        JB721PricingParams memory pricing,
        IJBTiered721DelegateStore store,
        JBTiered721Flags memory flags
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBDirectory.sol";
import "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBFundingCycleStore.sol";
import "./../enums/JB721GovernanceType.sol";
import "./../interfaces/IJB721TokenUriResolver.sol";
import "./../interfaces/IJBTiered721DelegateStore.sol";
import "./JB721PricingParams.sol";
import "./JBTiered721Flags.sol";

/**
 * @custom:member name The name of the token.
 *   @custom:member symbol The symbol that the token should be represented by.
 *   @custom:member fundingCycleStore A contract storing all funding cycle configurations.
 *   @custom:member baseUri A URI to use as a base for full token URIs.
 *   @custom:member tokenUriResolver A contract responsible for resolving the token URI for each token ID.
 *   @custom:member contractUri A URI where contract metadata can be found. 
 *   @custom:member pricing The tier pricing according to which token distribution will be made. 
 *   @custom:member reservedTokenBeneficiary The address receiving the reserved token
 *   @custom:member store The store contract to use.
 *   @custom:member flags A set of flags that help define how this contract works.
 *   @custom:member governanceType The type of governance to allow the NFTs to be used for.
 */
struct JBDeployTiered721DelegateData {
    string name;
    string symbol;
    IJBFundingCycleStore fundingCycleStore;
    string baseUri;
    IJB721TokenUriResolver tokenUriResolver;
    string contractUri;
    JB721PricingParams pricing;
    address reservedTokenBeneficiary;
    IJBTiered721DelegateStore store;
    JBTiered721Flags flags;
    JB721GovernanceType governanceType;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPaymentTerminal.sol";
import "@jbx-protocol/juice-contracts-v3/contracts/structs/JBFundingCycleData.sol";
import "@jbx-protocol/juice-contracts-v3/contracts/structs/JBFundAccessConstraints.sol";
import "@jbx-protocol/juice-contracts-v3/contracts/structs/JBGroupedSplits.sol";
import "./JBPayDataSourceFundingCycleMetadata.sol";

/**
 * @custom:member data Data that defines the project's first funding cycle. These properties will remain fixed for the duration of the funding cycle.
 *   @custom:member metadata Metadata specifying the controller specific params that a funding cycle can have. These properties will remain fixed for the duration of the funding cycle.
 *   @custom:member mustStartAtOrAfter The time before which the configured funding cycle cannot start.
 *   @custom:member groupedSplits An array of splits to set for any number of groups. 
 *   @custom:member fundAccessConstraints An array containing amounts that a project can use from its treasury for each payment terminal. Amounts are fixed point numbers using the same number of decimals as the accompanying terminal. The `_distributionLimit` and `_overflowAllowance` parameters must fit in a `uint232`.
 *   @custom:member terminals Payment terminals to add for the project.
 *   @custom:member memo A memo to pass along to the emitted event.
 */
struct JBLaunchFundingCyclesData {
    JBFundingCycleData data;
    JBPayDataSourceFundingCycleMetadata metadata;
    uint256 mustStartAtOrAfter;
    JBGroupedSplits[] groupedSplits;
    JBFundAccessConstraints[] fundAccessConstraints;
    IJBPaymentTerminal[] terminals;
    string memo;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@jbx-protocol/juice-contracts-v3/contracts/structs/JBFundingCycleData.sol";
import "@jbx-protocol/juice-contracts-v3/contracts/structs/JBFundAccessConstraints.sol";
import "@jbx-protocol/juice-contracts-v3/contracts/structs/JBGroupedSplits.sol";
import "./JBPayDataSourceFundingCycleMetadata.sol";

/**
 * @custom:member data Data that defines the project's first funding cycle. These properties will remain fixed for the duration of the funding cycle.
 *   @custom:member metadata Metadata specifying the controller specific params that a funding cycle can have. These properties will remain fixed for the duration of the funding cycle.
 *   @custom:member mustStartAtOrAfter The time before which the configured funding cycle cannot start.
 *   @custom:member groupedSplits An array of splits to set for any number of groups. 
 *   @custom:member fundAccessConstraints An array containing amounts that a project can use from its treasury for each payment terminal. Amounts are fixed point numbers using the same number of decimals as the accompanying terminal. The `_distributionLimit` and `_overflowAllowance` parameters must fit in a `uint232`.
 *   @custom:member terminals Payment terminals to add for the project.
 *   @custom:member memo A memo to pass along to the emitted event.
 */
struct JBReconfigureFundingCyclesData {
    JBFundingCycleData data;
    JBPayDataSourceFundingCycleMetadata metadata;
    uint256 mustStartAtOrAfter;
    JBGroupedSplits[] groupedSplits;
    JBFundAccessConstraints[] fundAccessConstraints;
    string memo;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPaymentTerminal.sol";
import "@jbx-protocol/juice-contracts-v3/contracts/structs/JBProjectMetadata.sol";
import "@jbx-protocol/juice-contracts-v3/contracts/structs/JBFundingCycleData.sol";
import "@jbx-protocol/juice-contracts-v3/contracts/structs/JBFundAccessConstraints.sol";
import "@jbx-protocol/juice-contracts-v3/contracts/structs/JBGroupedSplits.sol";
import "./JBPayDataSourceFundingCycleMetadata.sol";

/**
 * @custom:member projectMetadata Metadata to associate with the project within a particular domain. This can be updated any time by the owner of the project.
 *   @custom:member data Data that defines the project's first funding cycle. These properties will remain fixed for the duration of the funding cycle.
 *   @custom:member metadata Metadata specifying the controller specific params that a funding cycle can have. These properties will remain fixed for the duration of the funding cycle.
 *   @custom:member mustStartAtOrAfter The time before which the configured funding cycle cannot start.
 *   @custom:member groupedSplits An array of splits to set for any number of groups. 
 *   @custom:member fundAccessConstraints An array containing amounts that a project can use from its treasury for each payment terminal. Amounts are fixed point numbers using the same number of decimals as the accompanying terminal. The `_distributionLimit` and `_overflowAllowance` parameters must fit in a `uint232`.
 *   @custom:member terminals Payment terminals to add for the project.
 *   @custom:member memo A memo to pass along to the emitted event.
 */
struct JBLaunchProjectData {
    JBProjectMetadata projectMetadata;
    JBFundingCycleData data;
    JBPayDataSourceFundingCycleMetadata metadata;
    uint256 mustStartAtOrAfter;
    JBGroupedSplits[] groupedSplits;
    JBFundAccessConstraints[] fundAccessConstraints;
    IJBPaymentTerminal[] terminals;
    string memo;
}

// SPDX-License-Identifier: MIT
// Juicebox variation on OpenZeppelin Ownable

pragma solidity ^0.8.0;

import { JBOwner } from "./struct/JBOwner.sol";
import { IJBOwnable } from "./interfaces/IJBOwnable.sol";

import { IJBOperatable } from '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBOperatable.sol';
import { IJBOperatorStore } from "@jbx-protocol/juice-contracts-v3/contracts/abstract/JBOperatable.sol";
import { IJBProjects } from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBProjects.sol";
import { Context } from "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions and can grant other users permission to those functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner or an approved address.
 *
 * Supports meta-transactions.
 */
abstract contract JBOwnableOverrides is Context, IJBOwnable, IJBOperatable {
    //*********************************************************************//
    // --------------------------- custom errors --------------------------//
    //*********************************************************************//

    error UNAUTHORIZED();
    error INVALID_NEW_OWNER(address ownerAddress, uint256 projectId);

    //*********************************************************************//
    // ---------------- public immutable stored properties --------------- //
    //*********************************************************************//

    /** 
        @notice 
        A contract storing operator assignments.
    */
    IJBOperatorStore public immutable operatorStore;

    /**
        @notice
        The IJBProjects to use to get the owner of a project
     */
    IJBProjects public immutable projects;

    //*********************************************************************//
    // --------------------- public stored properties -------------------- //
    //*********************************************************************//

    /**
       @notice
       the JBOwner information
     */
    JBOwner public override jbOwner;

    //*********************************************************************//
    // -------------------------- constructor ---------------------------- //
    //*********************************************************************//

    /**
      @param _projects the JBProjects to use to get the owner of the project
      @param _operatorStore the operatorStore to use for the permissions
     */
    constructor(
        IJBProjects _projects,
        IJBOperatorStore _operatorStore
    ) {
        operatorStore = _operatorStore;
        projects = _projects;

        _transferOwnership(msg.sender);
    }

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
        Only allows callers that have received permission from the projectOwner for this project.

        @param _permissionIndex The index of the permission to check for. 
    */
    modifier requirePermissionFromOwner(
        uint256 _permissionIndex
    ) {
        JBOwner memory _ownerData = jbOwner;

        address _owner = _ownerData.projectId == 0 ?
         _ownerData.owner : projects.ownerOf(_ownerData.projectId);

        _requirePermission(_owner, _ownerData.projectId, _permissionIndex);
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
    // --------------------------- public methods ------------------------ //
    //*********************************************************************//

    /**
     @notice Returns the address of the current project owner.
    */
    function owner() public view virtual returns (address) {
        JBOwner memory _ownerData = jbOwner;

        if(_ownerData.projectId == 0)
            return _ownerData.owner;

        return projects.ownerOf(_ownerData.projectId);
    }

    /**
       @notice Leaves the contract without owner. It will not be possible to call
       `onlyOwner`/`_checkOwner` functions anymore. Can only be called by the current owner.
     
       NOTE: Renouncing ownership will leave the contract without an owner,
       thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual {
        _checkOwner();
        _transferOwnership(address(0), 0);
    }

    /**
       @notice Transfers ownership of the contract to a new account (`newOwner`).
       Can only be called by the current owner.
       @param _newOwner the static address that should receive ownership
     */
    function transferOwnership(address _newOwner) public virtual {
        _checkOwner();
        if(_newOwner == address(0))
            revert INVALID_NEW_OWNER(_newOwner, 0);
            
        _transferOwnership(_newOwner, 0);
    }

    /**
       @notice Transfer ownershipt of the contract to a (Juicebox) project
       @dev ProjectID is limited to a uint88
       @param _projectId the project that should receive ownership
     */
    function transferOwnershipToProject(uint256 _projectId) public virtual {
        _checkOwner();
        if(_projectId == 0 || _projectId > type(uint88).max)
            revert INVALID_NEW_OWNER(address(0), _projectId);

        _transferOwnership(address(0), uint88(_projectId));
    }

    /**
       @notice Sets the permission index that allows other callers to perform operations on behave of the project owner
       @param _permissionIndex the permissionIndex to use for 'onlyOwner' calls
     */
    function setPermissionIndex(uint8 _permissionIndex) public virtual {
        _checkOwner();
        _setPermissionIndex(_permissionIndex);
    }

    //*********************************************************************//
    // -------------------------- internal methods ----------------------- //
    //*********************************************************************//

    /**
       @dev Sets the permission index that allows other callers to perform operations on behave of the project owner
       Internal function without access restriction.

       @param _permissionIndex the permissionIndex to use for 'onlyOwner' calls
     */
    function _setPermissionIndex(uint8 _permissionIndex) internal virtual {
        jbOwner.permissionIndex = _permissionIndex;
        emit PermissionIndexChanged(_permissionIndex);
    }

    /**
       @dev helper to allow for drop-in replacement of OZ

       @param _newOwner the static address that should become the owner of this contract
     */
    function _transferOwnership(address _newOwner) internal virtual {
        _transferOwnership(_newOwner, 0);
    }

    /**
       @dev Transfers ownership of the contract to a new account (`_newOwner`) OR a project (`_projectID`).
       Internal function without access restriction.

       @param _newOwner the static owner address that should receive ownership
       @param _projectId the projectId this contract should follow ownership of
     */
    function _transferOwnership(address _newOwner, uint88 _projectId) internal virtual {
        // Can't both set a new owner and set a projectId to have ownership
        if (_projectId != 0 && _newOwner != address(0))
            revert INVALID_NEW_OWNER(_newOwner, _projectId); 
        // Load the owner data from storage
        JBOwner memory _ownerData = jbOwner;
        // Get an address representation of the old owner
        address _oldOwner = _ownerData.projectId == 0 ?
         _ownerData.owner : projects.ownerOf(_ownerData.projectId);
        // Update the storage to the new owner and reset the permissionIndex
        // this is to prevent clashing permissions for the new user/owner
        jbOwner = JBOwner({
            owner: _newOwner,
            projectId: _projectId,
            permissionIndex: 0
        });
        // Emit the ownership transferred event using an address representation of the new owner
        _emitTransferEvent(_oldOwner, _projectId == 0 ? _newOwner : projects.ownerOf(_projectId));
    }

    //*********************************************************************//
    // -------------------------- internal views ------------------------- //
    //*********************************************************************//

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        JBOwner memory _ownerData = jbOwner;

        address _owner = _ownerData.projectId == 0 ?
         _ownerData.owner : projects.ownerOf(_ownerData.projectId);
        
        _requirePermission(_owner, _ownerData.projectId, _ownerData.permissionIndex);
    }

    /** 
    @dev
    Require the message sender is either the account or has the specified permission.

    @param _account The account to allow.
    @param _domain The domain namespace within which the permission index will be checked.
    @param _permissionIndex The permission index that an operator must have within the specified domain to be allowed.
  */
    function _requirePermission(
        address _account,
        uint256 _domain,
        uint256 _permissionIndex
    ) internal view virtual {
        address _sender = _msgSender();
        if (
            _sender != _account &&
            !operatorStore.hasPermission(
                _sender,
                _account,
                _domain,
                _permissionIndex
            ) &&
            !operatorStore.hasPermission(_sender, _account, 0, _permissionIndex)
        ) revert UNAUTHORIZED();
    }

    /** 
    @dev
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
    ) internal view virtual {
        // short-circuit if the override is true
        if (_override) return;
        // Perform regular check otherwise
        _requirePermission(_account, _domain, _permissionIndex);
    }

    function _emitTransferEvent(address previousOwner, address newOwner) internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IJBOperatorStore.sol';

interface IJBOperatable {
  function operatorStore() external view returns (IJBOperatorStore);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

/** 
  @member content The metadata content.
  @member domain The domain within which the metadata applies.
*/
struct JBProjectMetadata {
  string content;
  uint256 domain;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../structs/JBFundAccessConstraints.sol';
import './../structs/JBFundingCycleData.sol';
import './../structs/JBFundingCycleMetadata.sol';
import './../structs/JBGroupedSplits.sol';
import './../structs/JBProjectMetadata.sol';
import './IJBController.sol';
import './IJBDirectory.sol';
import './IJBFundingCycleStore.sol';
import './IJBMigratable.sol';
import './IJBPaymentTerminal.sol';
import './IJBSplitsStore.sol';
import './IJBTokenStore.sol';

interface IJBController3_0_1 {
  function reservedTokenBalanceOf(uint256 _projectId) external view returns (uint256);
  function totalOutstandingTokensOf(uint256 _projectId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBMigratable {
  function prepForMigrationOf(uint256 _projectId, address _from) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../structs/JBGroupedSplits.sol';
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
    JBGroupedSplits[] memory _groupedSplits
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IJBFundingCycleStore.sol';
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

  event Set(uint256 indexed projectId, IJBToken indexed newToken, address caller);

  event Transfer(
    address indexed holder,
    uint256 indexed projectId,
    address indexed recipient,
    uint256 amount,
    address caller
  );

  function tokenOf(uint256 _projectId) external view returns (IJBToken);

  function projects() external view returns (IJBProjects);

  function fundingCycleStore() external view returns (IJBFundingCycleStore);

  function unclaimedBalanceOf(address _holder, uint256 _projectId) external view returns (uint256);

  function unclaimedTotalSupplyOf(uint256 _projectId) external view returns (uint256);

  function totalSupplyOf(uint256 _projectId) external view returns (uint256);

  function balanceOf(address _holder, uint256 _projectId) external view returns (uint256 _result);

  function issueFor(
    uint256 _projectId,
    string calldata _name,
    string calldata _symbol
  ) external returns (IJBToken token);

  function setFor(uint256 _projectId, IJBToken _token) external;

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
pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

/** 
  @member allowSetTerminals A flag indicating if setting terminals should be allowed during this funding cycle.
  @member allowSetController A flag indicating if setting a new controller should be allowed during this funding cycle.
  @member pauseTransfers A flag indicating if the project token transfer functionality should be paused during the funding cycle.
*/
struct JBGlobalFundingCycleMetadata {
  bool allowSetTerminals;
  bool allowSetController;
  bool pauseTransfers;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum JB721GovernanceType {
    NONE,
    ONCHAIN
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

import { IJBDirectory } from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBDirectory.sol";

interface IJB721Delegate {
    function projectId() external view returns (uint256);

    function directory() external view returns (IJBDirectory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJB721TokenUriResolver {
    function tokenUriOf(address nft, uint256 tokenId) external view returns (string memory tokenUri);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IJB721TokenUriResolver } from "./IJB721TokenUriResolver.sol";
import { JB721TierParams } from "./../structs/JB721TierParams.sol";
import { JB721Tier } from "./../structs/JB721Tier.sol";
import { JBTiered721Flags } from "./../structs/JBTiered721Flags.sol";

interface IJBTiered721DelegateStore {
    event CleanTiers(address indexed nft, address caller);

    function totalSupplyOf(address _nft) external view returns (uint256);

    function balanceOf(address _nft, address _owner) external view returns (uint256);

    function maxTierIdOf(address _nft) external view returns (uint256);

    function tiersOf(
        address nft,
        uint256[] calldata categories,
        bool includeResolvedUri,
        uint256 startingSortIndex,
        uint256 size
    ) external view returns (JB721Tier[] memory tiers);

    function tierOf(address nft, uint256 id, bool includeResolvedUri) external view returns (JB721Tier memory tier);

    function tierBalanceOf(address nft, address owner, uint256 tier) external view returns (uint256);

    function tierOfTokenId(address nft, uint256 tokenId, bool includeResolvedUri)
        external
        view
        returns (JB721Tier memory tier);

    function tierIdOfToken(uint256 tokenId) external pure returns (uint256);

    function encodedIPFSUriOf(address nft, uint256 tierId) external view returns (bytes32);

    function redemptionWeightOf(address nft, uint256[] memory tokenIds) external view returns (uint256 weight);

    function totalRedemptionWeight(address nft) external view returns (uint256 weight);

    function numberOfReservedTokensOutstandingFor(address nft, uint256 tierId) external view returns (uint256);

    function numberOfReservesMintedFor(address nft, uint256 tierId) external view returns (uint256);

    function numberOfBurnedFor(address nft, uint256 tierId) external view returns (uint256);

    function isTierRemoved(address nft, uint256 tierId) external view returns (bool);

    function flagsOf(address nft) external view returns (JBTiered721Flags memory);

    function votingUnitsOf(address nft, address account) external view returns (uint256 units);

    function tierVotingUnitsOf(address nft, address account, uint256 tierId) external view returns (uint256 units);

    function defaultReservedTokenBeneficiaryOf(address nft) external view returns (address);

    function reservedTokenBeneficiaryOf(address nft, uint256 tierId) external view returns (address);

    function tokenUriResolverOf(address nft) external view returns (IJB721TokenUriResolver);

    function encodedTierIPFSUriOf(address nft, uint256 tokenId) external view returns (bytes32);

    function recordAddTiers(JB721TierParams[] memory tierData) external returns (uint256[] memory tierIds);

    function recordMintReservesFor(uint256 tierId, uint256 count) external returns (uint256[] memory tokenIds);

    function recordBurn(uint256[] memory tokenIds) external;

    function recordMint(uint256 amount, uint16[] calldata tierIds, bool isManualMint)
        external
        returns (uint256[] memory tokenIds, uint256 leftoverAmount);

    function recordTransferForTier(uint256 tierId, address from, address to) external;

    function recordRemoveTierIds(uint256[] memory tierIds) external;

    function recordSetTokenUriResolver(IJB721TokenUriResolver resolver) external;

    function recordSetEncodedIPFSUriOf(uint256 tierId, bytes32 encodedIPFSUri) external;

    function recordFlags(JBTiered721Flags calldata flag) external;

    function cleanTiers(address nft) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPrices.sol";
import "./JB721TierParams.sol";

/**
 * @custom:member tiers The tiers to set.
 *   @custom:member currency The currency that the tier contribution floors are denoted in.
 *   @custom:member decimals The number of decimals included in the tier contribution floor fixed point numbers.
 *   @custom:member prices A contract that exposes price feeds that can be used to resolved the value of a contributions that are sent in different currencies. Set to the zero address if payments must be made in `currency`.
 */
struct JB721PricingParams {
    JB721TierParams[] tiers;
    uint48 currency;
    uint48 decimals;
    IJBPrices prices;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @custom:member price The minimum contribution to qualify for this tier.
 *   @custom:member initialQuantity The initial `remainingAllowance` value when the tier was set.
 *   @custom:member votingUnits The amount of voting significance to give this tier compared to others.
 *   @custom:member reservedRate The number of minted tokens needed in the tier to allow for minting another reserved token.
 *   @custom:member reservedRateBeneficiary The beneificary of the reserved tokens for this tier.
 *   @custom:member encodedIPFSUri The URI to use for each token within the tier.
 *   @custom:member category A category to group NFT tiers by.
 *   @custom:member allowManualMint A flag indicating if the contract's owner can mint from this tier on demand.
 *   @custom:member shouldUseReservedRateBeneficiaryAsDefault A flag indicating if the `reservedTokenBeneficiary` should be stored as the default beneficiary for all tiers.
 *   @custom:member transfersPausable A flag indicating if transfers from this tier can be pausable. 
 *   @custom:member useVotingUnits A flag indicating if the voting units override should be used over the price as the tier's voting units.
 */
struct JB721TierParams {
    uint104 price;
    uint32 initialQuantity;
    uint32 votingUnits;
    uint16 reservedRate;
    address reservedTokenBeneficiary;
    bytes32 encodedIPFSUri;
    uint24 category;
    bool allowManualMint;
    bool shouldUseReservedTokenBeneficiaryAsDefault;
    bool transfersPausable;
    bool useVotingUnits;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @custom:member lockReservedTokenChanges A flag indicating if reserved tokens can change over time by adding new tiers with a reserved rate.
 *   @custom:member lockVotingUnitChanges A flag indicating if voting unit expectations can change over time by adding new tiers with voting units.
 *   @custom:member lockManualMintingChanges A flag indicating if manual minting expectations can change over time by adding new tiers with manual minting.
 *   @custom:member preventOverspending A flag indicating if payments sending more than the value the NFTs being minted are worth should be reverted.
 */
struct JBTiered721Flags {
    bool lockReservedTokenChanges;
    bool lockVotingUnitChanges;
    bool lockManualMintingChanges;
    bool preventOverspending;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @custom:member tierId The ID of the tier to mint within.
 *   @custom:member count The number of reserved tokens to mint.
 */
struct JBTiered721MintReservesForTiersData {
    uint256 tierId;
    uint256 count;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @custom:member tierIds The IDs of the tier to mint within.
 *   @custom:member beneficiary The beneficiary to mint for.
 */
struct JBTiered721MintForTiersData {
    uint16[] tierIds;
    address beneficiary;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@jbx-protocol/juice-contracts-v3/contracts/structs/JBGlobalFundingCycleMetadata.sol";

/**
 * @custom:member global Data used globally in non-migratable ecosystem contracts.
 *   @custom:member reservedRate The reserved rate of the funding cycle. This number is a percentage calculated out of `JBConstants.MAX_RESERVED_RATE`.
 *   @custom:member redemptionRate The redemption rate of the funding cycle. This number is a percentage calculated out of `JBConstants.MAX_REDEMPTION_RATE`.
 *   @custom:member ballotRedemptionRate The redemption rate to use during an active ballot of the funding cycle. This number is a percentage calculated out of `JBConstants.MAX_REDEMPTION_RATE`.
 *   @custom:member pausePay A flag indicating if the pay functionality should be paused during the funding cycle.
 *   @custom:member pauseDistributions A flag indicating if the distribute functionality should be paused during the funding cycle.
 *   @custom:member pauseRedeem A flag indicating if the redeem functionality should be paused during the funding cycle.
 *   @custom:member pauseBurn A flag indicating if the burn functionality should be paused during the funding cycle.
 *   @custom:member allowMinting A flag indicating if minting tokens should be allowed during this funding cycle.
 *   @custom:member allowTerminalMigration A flag indicating if migrating terminals should be allowed during this funding cycle.
 *   @custom:member allowControllerMigration A flag indicating if migrating controllers should be allowed during this funding cycle.
 *   @custom:member holdFees A flag indicating if fees should be held during this funding cycle.
 *   @custom:member preferClaimedTokenOverride A flag indicating if claimed tokens should always be prefered to unclaimed tokens when minting.
 *   @custom:member useTotalOverflowForRedemptions A flag indicating if redemptions should use the project's balance held in all terminals instead of the project's local terminal balance from which the redemption is being fulfilled.
 *   @custom:member useDataSourceForRedeem A flag indicating if the data source should be used for redeem transactions during this funding cycle.
 *   @custom:member metadata Metadata of the metadata, up to uint8 in size.
 */
struct JBPayDataSourceFundingCycleMetadata {
    JBGlobalFundingCycleMetadata global;
    uint256 reservedRate;
    uint256 redemptionRate;
    uint256 ballotRedemptionRate;
    bool pausePay;
    bool pauseDistributions;
    bool pauseRedeem;
    bool pauseBurn;
    bool allowMinting;
    bool allowTerminalMigration;
    bool allowControllerMigration;
    bool holdFees;
    bool preferClaimedTokenOverride;
    bool useTotalOverflowForRedemptions;
    bool useDataSourceForRedeem;
    uint256 metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
  @member owner if set then the contract belongs to this static address.
  @member projectId if set then the contract belongs to whatever address owns the project
  @member permissionIndex the permission that is required on the specified project to act as the owner for this contract.
 */
struct JBOwner {
    address owner;
    uint88 projectId;
    uint8 permissionIndex;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBOwnable {
    // event OwnershipTransferred(
    //     address indexed previousOwner,
    //     address indexed newOwner
    // );
    event PermissionIndexChanged(uint8 newIndex);

    function jbOwner()
        external
        view
        returns (
            address owner,
            uint88 projectOwner,
            uint8 permissionIndex
        );

    function transferOwnershipToProject(uint256 _projectId) external;

    function setPermissionIndex(uint8 _permissionIndex) external;
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
pragma solidity ^0.8.0;

enum JBBallotState {
  Active,
  Approved,
  Failed
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

interface IJBTokenUriResolver {
  function getUri(uint256 _projectId) external view returns (string memory tokenUri);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../enums/JBBallotState.sol';

interface IJBFundingCycleBallot is IERC165 {
  function duration() external view returns (uint256);

  function stateOf(
    uint256 _projectId,
    uint256 _configuration,
    uint256 _start
  ) external view returns (JBBallotState);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

interface IJBToken {
  function projectId() external view returns (uint256);

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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBPriceFeed {
  function currentPrice(uint256 _targetDecimals) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
 * @custom:member id The tier's ID.
 *   @custom:member price The price that must be paid to qualify for this tier.
 *   @custom:member remainingQuantity Remaining number of tokens in this tier. Together with idCeiling this enables for consecutive, increasing token ids to be issued to contributors.
 *   @custom:member initialQuantity The initial `remainingAllowance` value when the tier was set.
 *   @custom:member votingUnits The amount of voting significance to give this tier compared to others.
 *   @custom:member reservedRate The number of minted tokens needed in the tier to allow for minting another reserved token.
 *   @custom:member reservedRateBeneficiary The beneificary of the reserved tokens for this tier.
 *   @custom:member encodedIPFSUri The URI to use for each token within the tier.
 *   @custom:member category A category to group NFT tiers by.
 *   @custom:member allowManualMint A flag indicating if the contract's owner can mint from this tier on demand.
 *   @custom:member transfersPausable A flag indicating if transfers from this tier can be pausable. 
 *   @custom:member resolvedTokenUri A resolved token URI if a resolver is included for the NFT to which this tier belongs.
 */
struct JB721Tier {
    uint256 id;
    uint256 price;
    uint256 remainingQuantity;
    uint256 initialQuantity;
    uint256 votingUnits;
    uint256 reservedRate;
    address reservedTokenBeneficiary;
    bytes32 encodedIPFSUri;
    uint256 category;
    bool allowManualMint;
    bool transfersPausable;
    string resolvedUri;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import '../structs/JBSplitAllocationData.sol';

/**
  @title
  Split allocator

  @notice
  Provide a way to process a single split with extra logic

  @dev
  Adheres to:
  IERC165 for adequate interface integration

  @dev
  The contract address should be set as an allocator in the adequate split
*/
interface IJBSplitAllocator is IERC165 {
  /**
    @notice
    This function is called by JBPaymentTerminal.distributePayoutOf(..), during the processing of the split including it

    @dev
    Critical business logic should be protected by an appropriate access control. The token and/or eth are optimistically transfered
    to the allocator for its logic.
    
    @param _data the data passed by the terminal, as a JBSplitAllocationData struct:
                  address token;
                  uint256 amount;
                  uint256 decimals;
                  uint256 projectId;
                  uint256 group;
                  JBSplit split;
  */
  function allocate(JBSplitAllocationData calldata _data) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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