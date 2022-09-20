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

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "prb-math/contracts/PRBMath.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@paulrberg/contracts/math/PRBMath.sol';
import './abstract/JBControllerUtility.sol';
import './libraries/JBConstants.sol';

/** 
  @notice 
  Manages funding cycle configurations and scheduling.

  @dev
  Adheres to -
  IJBFundingCycleStore: General interface for the methods in this contract that interact with the blockchain's state according to the protocol's rules.

  @dev
  Inherits from -
  JBControllerUtility: Includes convenience functionality for checking if the message sender is the current controller of the project whose data is being manipulated.
*/
contract JBFundingCycleStore is JBControllerUtility, IJBFundingCycleStore {
  //*********************************************************************//
  // --------------------------- custom errors ------------------------- //
  //*********************************************************************//
  error INVALID_BALLOT();
  error INVALID_DISCOUNT_RATE();
  error INVALID_DURATION();
  error INVALID_TIMEFRAME();
  error INVALID_WEIGHT();
  error NO_SAME_BLOCK_RECONFIGURATION();

  //*********************************************************************//
  // --------------------- private stored properties ------------------- //
  //*********************************************************************//

  /** 
    @notice
    Stores the user defined properties of each funding cycle, packed into one storage slot.

    _projectId The ID of the project to get properties of.
    _configuration The funding cycle configuration to get properties of.
  */
  mapping(uint256 => mapping(uint256 => uint256)) private _packedUserPropertiesOf;

  /** 
    @notice
    Stores the properties added by the mechanism to manage and schedule each funding cycle, packed into one storage slot.
    
    _projectId The ID of the project to get instrinsic properties of.
    _configuration The funding cycle configuration to get properties of.
  */
  mapping(uint256 => mapping(uint256 => uint256)) private _packedIntrinsicPropertiesOf;

  /** 
    @notice
    Stores the metadata for each funding cycle configuration, packed into one storage slot.

    _projectId The ID of the project to get metadata of.
    _configuration The funding cycle configuration to get metadata of.
  */
  mapping(uint256 => mapping(uint256 => uint256)) private _metadataOf;

  //*********************************************************************//
  // --------------------- public stored properties -------------------- //
  //*********************************************************************//

  /** 
    @notice 
    The latest funding cycle configuration for each project.

    _projectId The ID of the project to get the latest funding cycle configuration of.
  */
  mapping(uint256 => uint256) public override latestConfigurationOf;

  //*********************************************************************//
  // ------------------------- external views -------------------------- //
  //*********************************************************************//

  /**
    @notice 
    Get the funding cycle with the given configuration for the specified project.

    @param _projectId The ID of the project to which the funding cycle belongs.
    @param _configuration The configuration of the funding cycle to get.

    @return fundingCycle The funding cycle.
  */
  function get(uint256 _projectId, uint256 _configuration)
    external
    view
    override
    returns (JBFundingCycle memory fundingCycle)
  {
    return _getStructFor(_projectId, _configuration);
  }

  /**
    @notice 
    The latest funding cycle to be configured for the specified project, and its current ballot state.

    @param _projectId The ID of the project to get the latest configured funding cycle of.

    @return fundingCycle The project's queued funding cycle.
    @return ballotState The state of the ballot for the reconfiguration.
  */
  function latestConfiguredOf(uint256 _projectId)
    external
    view
    override
    returns (JBFundingCycle memory fundingCycle, JBBallotState ballotState)
  {
    // Get a reference to the latest funding cycle configuration.
    uint256 _fundingCycleConfiguration = latestConfigurationOf[_projectId];

    // Resolve the funding cycle for the latest configuration.
    fundingCycle = _getStructFor(_projectId, _fundingCycleConfiguration);

    // Resolve the ballot state.
    ballotState = _ballotStateOf(
      _projectId,
      fundingCycle.configuration,
      fundingCycle.start,
      fundingCycle.basedOn
    );
  }

  /**
    @notice 
    The funding cycle that's next up for the specified project.

    @dev
    If a queued funding cycle of the project is not found, returns an empty funding cycle with all properties set to 0.

    @param _projectId The ID of the project to get the queued funding cycle of.

    @return fundingCycle The project's queued funding cycle.
  */
  function queuedOf(uint256 _projectId)
    external
    view
    override
    returns (JBFundingCycle memory fundingCycle)
  {
    // If the project does not have a funding cycle, return an empty struct.
    if (latestConfigurationOf[_projectId] == 0) return _getStructFor(0, 0);

    // Get a reference to the configuration of the standby funding cycle.
    uint256 _standbyFundingCycleConfiguration = _standbyOf(_projectId);

    // If it exists, return its funding cycle if it is approved.
    if (_standbyFundingCycleConfiguration > 0) {
      fundingCycle = _getStructFor(_projectId, _standbyFundingCycleConfiguration);

      if (_isApproved(_projectId, fundingCycle)) return fundingCycle;

      // Resolve the funding cycle for the latest configured funding cycle.
      fundingCycle = _getStructFor(_projectId, fundingCycle.basedOn);
    } else {
      // Resolve the funding cycle for the latest configured funding cycle.
      fundingCycle = _getStructFor(_projectId, latestConfigurationOf[_projectId]);

      // If the latest funding cycle starts in the future, it must start in the distant future
      // since its not in standby. In this case base the queued cycles on the base cycle.
      if (fundingCycle.start > block.timestamp)
        fundingCycle = _getStructFor(_projectId, fundingCycle.basedOn);
    }

    // There's no queued if the current has a duration of 0.
    if (fundingCycle.duration == 0) return _getStructFor(0, 0);

    // Check to see if this funding cycle's ballot is approved.
    // If so, return a funding cycle based on it.
    if (_isApproved(_projectId, fundingCycle)) return _mockFundingCycleBasedOn(fundingCycle, false);

    // Get the funding cycle of its base funding cycle, which carries the last approved configuration.
    fundingCycle = _getStructFor(_projectId, fundingCycle.basedOn);

    // There's no queued if the base, which must still be the current, has a duration of 0.
    if (fundingCycle.duration == 0) return _getStructFor(0, 0);

    // Return a mock of the next up funding cycle.
    return _mockFundingCycleBasedOn(fundingCycle, false);
  }

  /**
    @notice 
    The funding cycle that is currently active for the specified project.

    @dev
    If a current funding cycle of the project is not found, returns an empty funding cycle with all properties set to 0.

    @param _projectId The ID of the project to get the current funding cycle of.

    @return fundingCycle The project's current funding cycle.
  */
  function currentOf(uint256 _projectId)
    external
    view
    override
    returns (JBFundingCycle memory fundingCycle)
  {
    // If the project does not have a funding cycle, return an empty struct.
    if (latestConfigurationOf[_projectId] == 0) return _getStructFor(0, 0);

    // Get a reference to the configuration of the eligible funding cycle.
    uint256 _fundingCycleConfiguration = _eligibleOf(_projectId);

    // Keep a reference to the eligible funding cycle.
    JBFundingCycle memory _fundingCycle;

    // If an eligible funding cycle exists...
    if (_fundingCycleConfiguration > 0) {
      // Resolve the funding cycle for the eligible configuration.
      _fundingCycle = _getStructFor(_projectId, _fundingCycleConfiguration);

      // Check to see if this funding cycle's ballot is approved.
      // If so, return it.
      if (_isApproved(_projectId, _fundingCycle)) return _fundingCycle;

      // If it hasn't been approved, set the funding cycle configuration to be the configuration of the funding cycle that it's based on,
      // which carries the last approved configuration.
      _fundingCycleConfiguration = _fundingCycle.basedOn;
    } else {
      // No upcoming funding cycle found that is eligible to become active,
      // so use the last configuration.
      _fundingCycleConfiguration = latestConfigurationOf[_projectId];

      // Get the funding cycle for the latest ID.
      _fundingCycle = _getStructFor(_projectId, _fundingCycleConfiguration);

      // If it's not approved or if it hasn't yet started, get a reference to the funding cycle that the latest is based on, which has the latest approved configuration.
      if (!_isApproved(_projectId, _fundingCycle) || block.timestamp < _fundingCycle.start)
        _fundingCycleConfiguration = _fundingCycle.basedOn;
    }

    // If there is not funding cycle to base the current one on, there can't be a current one.
    if (_fundingCycleConfiguration == 0) return _getStructFor(0, 0);

    // The funding cycle to base a current one on.
    _fundingCycle = _getStructFor(_projectId, _fundingCycleConfiguration);

    // If the base has no duration, it's still the current one.
    if (_fundingCycle.duration == 0) return _fundingCycle;

    // Return a mock of the current funding cycle.
    return _mockFundingCycleBasedOn(_fundingCycle, true);
  }

  /** 
    @notice 
    The current ballot state of the project.

    @param _projectId The ID of the project to check the ballot state of.

    @return The project's current ballot's state.
  */
  function currentBallotStateOf(uint256 _projectId) external view override returns (JBBallotState) {
    // Get a reference to the latest funding cycle configuration.
    uint256 _fundingCycleConfiguration = latestConfigurationOf[_projectId];

    // Resolve the funding cycle for the latest configuration.
    JBFundingCycle memory _fundingCycle = _getStructFor(_projectId, _fundingCycleConfiguration);

    return
      _ballotStateOf(
        _projectId,
        _fundingCycle.configuration,
        _fundingCycle.start,
        _fundingCycle.basedOn
      );
  }

  //*********************************************************************//
  // -------------------------- constructor ---------------------------- //
  //*********************************************************************//

  /** 
    @param _directory A contract storing directories of terminals and controllers for each project.
  */
  // solhint-disable-next-line no-empty-blocks
  constructor(IJBDirectory _directory) JBControllerUtility(_directory) {}

  //*********************************************************************//
  // ---------------------- external transactions ---------------------- //
  //*********************************************************************//

  /**
    @notice 
    Configures the next eligible funding cycle for the specified project.

    @dev
    Only a project's current controller can configure its funding cycles.

    @param _projectId The ID of the project being configured.
    @param _data The funding cycle configuration data.
    @param _metadata Arbitrary extra data to associate with this funding cycle configuration that's not used within.
    @param _mustStartAtOrAfter The time before which the initialized funding cycle cannot start.

    @return The funding cycle that the configuration will take effect during.
  */
  function configureFor(
    uint256 _projectId,
    JBFundingCycleData calldata _data,
    uint256 _metadata,
    uint256 _mustStartAtOrAfter
  ) external override onlyController(_projectId) returns (JBFundingCycle memory) {
    // Duration must fit in a uint32.
    if (_data.duration > type(uint32).max) revert INVALID_DURATION();

    // Discount rate must be less than or equal to 100%.
    if (_data.discountRate > JBConstants.MAX_DISCOUNT_RATE) revert INVALID_DISCOUNT_RATE();

    // Weight must fit into a uint88.
    if (_data.weight > type(uint88).max) revert INVALID_WEIGHT();

    // If the start date is in the past, set it to be the current timestamp.
    if (_mustStartAtOrAfter < block.timestamp) _mustStartAtOrAfter = block.timestamp;

    // Make sure the min start date fits in a uint56, and that the start date of an upcoming cycle also starts within the max.
    if (_mustStartAtOrAfter + _data.duration > type(uint56).max) revert INVALID_TIMEFRAME();

    // Ballot should be a valid contract, supporting the correct interface
    if (_data.ballot != IJBFundingCycleBallot(address(0))) {
      address _ballot = address(_data.ballot);

      // No contract at the address ?
      if (_ballot.code.length == 0) revert INVALID_BALLOT();

      // Make sure the ballot supports the expected interface.
      try _data.ballot.supportsInterface(type(IJBFundingCycleBallot).interfaceId) returns (
        bool _supports
      ) {
        if (!_supports) revert INVALID_BALLOT(); // Contract exists at the address but with the wrong interface
      } catch {
        revert INVALID_BALLOT(); // No ERC165 support
      }
    }

    // The configuration timestamp is now.
    uint256 _configuration = block.timestamp;

    // Set up a reconfiguration by configuring intrinsic properties.
    _configureIntrinsicPropertiesFor(_projectId, _configuration, _data.weight, _mustStartAtOrAfter);

    // Efficiently stores a funding cycles provided user defined properties.
    // If all user config properties are zero, no need to store anything as the default value will have the same outcome.
    if (
      _data.ballot != IJBFundingCycleBallot(address(0)) ||
      _data.duration > 0 ||
      _data.discountRate > 0
    ) {
      // ballot in bits 0-159 bytes.
      uint256 packed = uint160(address(_data.ballot));

      // duration in bits 160-191 bytes.
      packed |= _data.duration << 160;

      // discountRate in bits 192-223 bytes.
      packed |= _data.discountRate << 192;

      // Set in storage.
      _packedUserPropertiesOf[_projectId][_configuration] = packed;
    }

    // Set the metadata if needed.
    if (_metadata > 0) _metadataOf[_projectId][_configuration] = _metadata;

    emit Configure(_configuration, _projectId, _data, _metadata, _mustStartAtOrAfter, msg.sender);

    // Return the funding cycle for the new configuration.
    return _getStructFor(_projectId, _configuration);
  }

  //*********************************************************************//
  // --------------------- private helper functions -------------------- //
  //*********************************************************************//

  /**
    @notice 
    Updates the configurable funding cycle for this project if it exists, otherwise creates one.

    @param _projectId The ID of the project to find a configurable funding cycle for.
    @param _configuration The time at which the funding cycle was configured.
    @param _weight The weight to store in the configured funding cycle.
    @param _mustStartAtOrAfter The time before which the initialized funding cycle can't start.
  */
  function _configureIntrinsicPropertiesFor(
    uint256 _projectId,
    uint256 _configuration,
    uint256 _weight,
    uint256 _mustStartAtOrAfter
  ) private {
    // If there's not yet a funding cycle for the project, initialize one.
    if (latestConfigurationOf[_projectId] == 0)
      // Use an empty funding cycle as the base.
      return
        _initFor(_projectId, _getStructFor(0, 0), _configuration, _mustStartAtOrAfter, _weight);

    // Get the active funding cycle's configuration.
    uint256 _currentConfiguration = _eligibleOf(_projectId);

    // If an eligible funding cycle does not exist, get a reference to the latest funding cycle configuration for the project.
    if (_currentConfiguration == 0)
      // Get the latest funding cycle's configuration.
      _currentConfiguration = latestConfigurationOf[_projectId];

    // Get a reference to the funding cycle.
    JBFundingCycle memory _baseFundingCycle = _getStructFor(_projectId, _currentConfiguration);

    if (!_isApproved(_projectId, _baseFundingCycle) || block.timestamp < _baseFundingCycle.start)
      // If it hasn't been approved or hasn't yet started, set the ID to be the funding cycle it's based on,
      // which carries the latest approved configuration.
      _baseFundingCycle = _getStructFor(_projectId, _baseFundingCycle.basedOn);

    // The configuration can't be the same as the base configuration.
    if (_baseFundingCycle.configuration == _configuration) revert NO_SAME_BLOCK_RECONFIGURATION();

    // The time after the ballot of the provided funding cycle has expired.
    // If the provided funding cycle has no ballot, return the current timestamp.
    uint256 _timestampAfterBallot = _baseFundingCycle.ballot == IJBFundingCycleBallot(address(0))
      ? 0
      : _configuration + _baseFundingCycle.ballot.duration();

    _initFor(
      _projectId,
      _baseFundingCycle,
      _configuration,
      // Can only start after the ballot.
      _timestampAfterBallot > _mustStartAtOrAfter ? _timestampAfterBallot : _mustStartAtOrAfter,
      _weight
    );
  }

  /**
    @notice 
    Initializes a funding cycle with the specified properties.

    @param _projectId The ID of the project to which the funding cycle being initialized belongs.
    @param _baseFundingCycle The funding cycle to base the initialized one on.
    @param _configuration The configuration of the funding cycle being initialized.
    @param _mustStartAtOrAfter The time before which the initialized funding cycle cannot start.
    @param _weight The weight to give the newly initialized funding cycle.
  */
  function _initFor(
    uint256 _projectId,
    JBFundingCycle memory _baseFundingCycle,
    uint256 _configuration,
    uint256 _mustStartAtOrAfter,
    uint256 _weight
  ) private {
    // If there is no base, initialize a first cycle.
    if (_baseFundingCycle.number == 0) {
      // The first number is 1.
      uint256 _number = 1;

      // Set fresh intrinsic properties.
      _packAndStoreIntrinsicPropertiesOf(
        _configuration,
        _projectId,
        _number,
        _weight,
        _baseFundingCycle.configuration,
        _mustStartAtOrAfter
      );
    } else {
      // Derive the correct next start time from the base.
      uint256 _start = _deriveStartFrom(_baseFundingCycle, _mustStartAtOrAfter);

      // A weight of 1 is treated as a weight of 0.
      // This is to allow a weight of 0 (default) to represent inheriting the discounted weight of the previous funding cycle.
      _weight = _weight > 0
        ? (_weight == 1 ? 0 : _weight)
        : _deriveWeightFrom(_baseFundingCycle, _start);

      // Derive the correct number.
      uint256 _number = _deriveNumberFrom(_baseFundingCycle, _start);

      // Update the intrinsic properties.
      _packAndStoreIntrinsicPropertiesOf(
        _configuration,
        _projectId,
        _number,
        _weight,
        _baseFundingCycle.configuration,
        _start
      );
    }

    // Set the project's latest funding cycle configuration.
    latestConfigurationOf[_projectId] = _configuration;

    emit Init(_configuration, _projectId, _baseFundingCycle.configuration);
  }

  /**
    @notice 
    Efficiently stores a funding cycle's provided intrinsic properties.

    @param _configuration The configuration of the funding cycle to pack and store.
    @param _projectId The ID of the project to which the funding cycle belongs.
    @param _number The number of the funding cycle.
    @param _weight The weight of the funding cycle.
    @param _basedOn The configuration of the base funding cycle.
    @param _start The start time of this funding cycle.
  */
  function _packAndStoreIntrinsicPropertiesOf(
    uint256 _configuration,
    uint256 _projectId,
    uint256 _number,
    uint256 _weight,
    uint256 _basedOn,
    uint256 _start
  ) private {
    // weight in bits 0-87.
    uint256 packed = _weight;

    // basedOn in bits 88-143.
    packed |= _basedOn << 88;

    // start in bits 144-199.
    packed |= _start << 144;

    // number in bits 200-255.
    packed |= _number << 200;

    // Store the packed value.
    _packedIntrinsicPropertiesOf[_projectId][_configuration] = packed;
  }

  /**
    @notice 
    The project's stored funding cycle that hasn't yet started and should be used next, if one exists.

    @dev
    A value of 0 is returned if no funding cycle was found.

    @dev
    Assumes the project has a latest configuration.
    
    @param _projectId The ID of a project to look through for a standby cycle.

    @return configuration The configuration of the standby funding cycle if one exists, or 0 if one doesn't exist.
  */
  function _standbyOf(uint256 _projectId) private view returns (uint256 configuration) {
    // Get a reference to the project's latest funding cycle.
    configuration = latestConfigurationOf[_projectId];

    // Get the necessary properties for the latest funding cycle.
    JBFundingCycle memory _fundingCycle = _getStructFor(_projectId, configuration);

    // There is no upcoming funding cycle if the latest funding cycle has already started.
    if (block.timestamp >= _fundingCycle.start) return 0;

    // If this is the first funding cycle, it is queued.
    if (_fundingCycle.number == 1) return configuration;

    // Get the necessary properties for the base funding cycle.
    JBFundingCycle memory _baseFundingCycle = _getStructFor(_projectId, _fundingCycle.basedOn);

    // If the latest configuration doesn't start until after another base cycle, return 0.
    if (
      _baseFundingCycle.duration > 0 &&
      block.timestamp < _fundingCycle.start - _baseFundingCycle.duration
    ) return 0;
  }

  /**
    @notice 
    The project's stored funding cycle that has started and hasn't yet expired.
    
    @dev
    A value of 0 is returned if no funding cycle was found.

    @dev
    Assumes the project has a latest configuration.

    @param _projectId The ID of the project to look through.

    @return configuration The configuration of an eligible funding cycle if one exists, or 0 if one doesn't exist.
  */
  function _eligibleOf(uint256 _projectId) private view returns (uint256 configuration) {
    // Get a reference to the project's latest funding cycle.
    configuration = latestConfigurationOf[_projectId];

    // Get the latest funding cycle.
    JBFundingCycle memory _fundingCycle = _getStructFor(_projectId, configuration);

    // If the latest is expired, return an empty funding cycle.
    // A duration of 0 cannot be expired.
    if (
      _fundingCycle.duration > 0 && block.timestamp >= _fundingCycle.start + _fundingCycle.duration
    ) return 0;

    // Return the funding cycle's configuration if it has started.
    if (block.timestamp >= _fundingCycle.start) return _fundingCycle.configuration;

    // Get a reference to the cycle's base configuration.
    JBFundingCycle memory _baseFundingCycle = _getStructFor(_projectId, _fundingCycle.basedOn);

    // If the base cycle isn't eligible, the project has no eligible cycle.
    // A duration of 0 is always eligible.
    if (
      _baseFundingCycle.duration > 0 &&
      block.timestamp >= _baseFundingCycle.start + _baseFundingCycle.duration
    ) return 0;

    // Return the configuration that the latest funding cycle is based on.
    configuration = _fundingCycle.basedOn;
  }

  /** 
    @notice 
    A view of the funding cycle that would be created based on the provided one if the project doesn't make a reconfiguration.

    @dev
    Returns an empty funding cycle if there can't be a mock funding cycle based on the provided one.

    @dev
    Assumes a funding cycle with a duration of 0 will never be asked to be the base of a mock.

    @param _baseFundingCycle The funding cycle that the resulting funding cycle should follow.
    @param _allowMidCycle A flag indicating if the mocked funding cycle is allowed to already be mid cycle.

    @return A mock of what the next funding cycle will be.
  */
  function _mockFundingCycleBasedOn(JBFundingCycle memory _baseFundingCycle, bool _allowMidCycle)
    private
    view
    returns (JBFundingCycle memory)
  {
    // Get the distance of the current time to the start of the next possible funding cycle.
    // If the returned mock cycle must not yet have started, the start time of the mock must be in the future.
    uint256 _mustStartAtOrAfter = !_allowMidCycle
      ? block.timestamp + 1
      : block.timestamp - _baseFundingCycle.duration + 1;

    // Derive what the start time should be.
    uint256 _start = _deriveStartFrom(_baseFundingCycle, _mustStartAtOrAfter);

    // Derive what the number should be.
    uint256 _number = _deriveNumberFrom(_baseFundingCycle, _start);

    return
      JBFundingCycle(
        _number,
        _baseFundingCycle.configuration,
        _baseFundingCycle.basedOn,
        _start,
        _baseFundingCycle.duration,
        _deriveWeightFrom(_baseFundingCycle, _start),
        _baseFundingCycle.discountRate,
        _baseFundingCycle.ballot,
        _baseFundingCycle.metadata
      );
  }

  /** 
    @notice 
    The date that is the nearest multiple of the specified funding cycle's duration from its end.

    @param _baseFundingCycle The funding cycle to base the calculation on.
    @param _mustStartAtOrAfter A date that the derived start must be on or come after.

    @return start The next start time.
  */
  function _deriveStartFrom(JBFundingCycle memory _baseFundingCycle, uint256 _mustStartAtOrAfter)
    private
    pure
    returns (uint256 start)
  {
    // A subsequent cycle to one with a duration of 0 should start as soon as possible.
    if (_baseFundingCycle.duration == 0) return _mustStartAtOrAfter;

    // The time when the funding cycle immediately after the specified funding cycle starts.
    uint256 _nextImmediateStart = _baseFundingCycle.start + _baseFundingCycle.duration;

    // If the next immediate start is now or in the future, return it.
    if (_nextImmediateStart >= _mustStartAtOrAfter) return _nextImmediateStart;

    // The amount of seconds since the `_mustStartAtOrAfter` time which results in a start time that might satisfy the specified constraints.
    uint256 _timeFromImmediateStartMultiple = (_mustStartAtOrAfter - _nextImmediateStart) %
      _baseFundingCycle.duration;

    // A reference to the first possible start timestamp.
    start = _mustStartAtOrAfter - _timeFromImmediateStartMultiple;

    // Add increments of duration as necessary to satisfy the threshold.
    while (_mustStartAtOrAfter > start) start = start + _baseFundingCycle.duration;
  }

  /** 
    @notice 
    The accumulated weight change since the specified funding cycle.

    @param _baseFundingCycle The funding cycle to base the calculation on.
    @param _start The start time of the funding cycle to derive a number for.

    @return weight The derived weight, as a fixed point number with 18 decimals.
  */
  function _deriveWeightFrom(JBFundingCycle memory _baseFundingCycle, uint256 _start)
    private
    pure
    returns (uint256 weight)
  {
    // A subsequent cycle to one with a duration of 0 should have the next possible weight.
    if (_baseFundingCycle.duration == 0)
      return
        PRBMath.mulDiv(
          _baseFundingCycle.weight,
          JBConstants.MAX_DISCOUNT_RATE - _baseFundingCycle.discountRate,
          JBConstants.MAX_DISCOUNT_RATE
        );

    // The weight should be based off the base funding cycle's weight.
    weight = _baseFundingCycle.weight;

    // If the discount is 0, the weight doesn't change.
    if (_baseFundingCycle.discountRate == 0) return weight;

    // The difference between the start of the base funding cycle and the proposed start.
    uint256 _startDistance = _start - _baseFundingCycle.start;

    // Apply the base funding cycle's discount rate for each cycle that has passed.
    uint256 _discountMultiple;
    unchecked {
      _discountMultiple = _startDistance / _baseFundingCycle.duration; // Non-null duration is excluded above
    }

    for (uint256 _i; _i < _discountMultiple; ) {
      // The number of times to apply the discount rate.
      // Base the new weight on the specified funding cycle's weight.
      weight = PRBMath.mulDiv(
        weight,
        JBConstants.MAX_DISCOUNT_RATE - _baseFundingCycle.discountRate,
        JBConstants.MAX_DISCOUNT_RATE
      );

      // The calculation doesn't need to continue if the weight is 0.
      if (weight == 0) break;

      unchecked {
        ++_i;
      }
    }
  }

  /** 
    @notice 
    The number of the next funding cycle given the specified funding cycle.

    @param _baseFundingCycle The funding cycle to base the calculation on.
    @param _start The start time of the funding cycle to derive a number for.

    @return The funding cycle number.
  */
  function _deriveNumberFrom(JBFundingCycle memory _baseFundingCycle, uint256 _start)
    private
    pure
    returns (uint256)
  {
    // A subsequent cycle to one with a duration of 0 should be the next number.
    if (_baseFundingCycle.duration == 0) return _baseFundingCycle.number + 1;

    // The difference between the start of the base funding cycle and the proposed start.
    uint256 _startDistance = _start - _baseFundingCycle.start;

    // Find the number of base cycles that fit in the start distance.
    return _baseFundingCycle.number + (_startDistance / _baseFundingCycle.duration);
  }

  /** 
    @notice 
    Checks to see if the provided funding cycle is approved according to the correct ballot.

    @param _projectId The ID of the project to which the funding cycle belongs. 
    @param _fundingCycle The funding cycle to get an approval flag for.

    @return The approval flag.
  */
  function _isApproved(uint256 _projectId, JBFundingCycle memory _fundingCycle)
    private
    view
    returns (bool)
  {
    return
      _ballotStateOf(
        _projectId,
        _fundingCycle.configuration,
        _fundingCycle.start,
        _fundingCycle.basedOn
      ) == JBBallotState.Approved;
  }

  /**
    @notice 
    A project's latest funding cycle configuration approval status.

    @param _projectId The ID of the project to which the funding cycle belongs.
    @param _configuration The funding cycle configuration to get the ballot state of.
    @param _start The start time of the funding cycle configuration to get the ballot state of.
    @param _ballotFundingCycleConfiguration The configuration of the funding cycle which is configured with the ballot that should be used.

    @return The ballot state of the project.
  */
  function _ballotStateOf(
    uint256 _projectId,
    uint256 _configuration,
    uint256 _start,
    uint256 _ballotFundingCycleConfiguration
  ) private view returns (JBBallotState) {
    // If there is no ballot funding cycle, implicitly approve.
    if (_ballotFundingCycleConfiguration == 0) return JBBallotState.Approved;

    // Get the ballot funding cycle.
    JBFundingCycle memory _ballotFundingCycle = _getStructFor(
      _projectId,
      _ballotFundingCycleConfiguration
    );

    // If there is no ballot, the ID is auto approved.
    if (_ballotFundingCycle.ballot == IJBFundingCycleBallot(address(0)))
      return JBBallotState.Approved;

    // Return the ballot's state
    return _ballotFundingCycle.ballot.stateOf(_projectId, _configuration, _start);
  }

  /**
    @notice 
    Unpack a funding cycle's packed stored values into an easy-to-work-with funding cycle struct.

    @param _projectId The ID of the project to which the funding cycle belongs.
    @param _configuration The funding cycle configuration to get the full struct for.

    @return fundingCycle A funding cycle struct.
  */
  function _getStructFor(uint256 _projectId, uint256 _configuration)
    private
    view
    returns (JBFundingCycle memory fundingCycle)
  {
    // Return an empty funding cycle if the configuration specified is 0.
    if (_configuration == 0) return fundingCycle;

    fundingCycle.configuration = _configuration;

    uint256 _packedIntrinsicProperties = _packedIntrinsicPropertiesOf[_projectId][_configuration];

    // weight in bits 0-87 bits.
    fundingCycle.weight = uint256(uint88(_packedIntrinsicProperties));
    // basedOn in bits 88-143 bits.
    fundingCycle.basedOn = uint256(uint56(_packedIntrinsicProperties >> 88));
    // start in bits 144-199 bits.
    fundingCycle.start = uint256(uint56(_packedIntrinsicProperties >> 144));
    // number in bits 200-255 bits.
    fundingCycle.number = uint256(uint56(_packedIntrinsicProperties >> 200));

    uint256 _packedUserProperties = _packedUserPropertiesOf[_projectId][_configuration];

    // ballot in bits 0-159 bits.
    fundingCycle.ballot = IJBFundingCycleBallot(address(uint160(_packedUserProperties)));
    // duration in bits 160-191 bits.
    fundingCycle.duration = uint256(uint32(_packedUserProperties >> 160));
    // discountRate in bits 192-223 bits.
    fundingCycle.discountRate = uint256(uint32(_packedUserProperties >> 192));

    fundingCycle.metadata = _metadataOf[_projectId][_configuration];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import './../interfaces/IJBControllerUtility.sol';

/** 
  @notice
  Provides tools for contracts with functionality that can only be accessed by a project's controller.

  @dev
  Adheres to -
  IJBControllerUtility: General interface for the methods in this contract that interact with the blockchain's state according to the protocol's rules.
*/
abstract contract JBControllerUtility is IJBControllerUtility {
  //*********************************************************************//
  // --------------------------- custom errors -------------------------- //
  //*********************************************************************//
  error CONTROLLER_UNAUTHORIZED();

  //*********************************************************************//
  // ---------------------------- modifiers ---------------------------- //
  //*********************************************************************//

  /** 
    @notice
    Only allows the controller of the specified project to proceed. 

    @param _projectId The ID of the project. 
  */
  modifier onlyController(uint256 _projectId) {
    if (address(directory.controllerOf(_projectId)) != msg.sender) revert CONTROLLER_UNAUTHORIZED();
    _;
  }

  //*********************************************************************//
  // ---------------- public immutable stored properties --------------- //
  //*********************************************************************//

  /** 
    @notice 
    The directory of terminals and controllers for projects.
  */
  IJBDirectory public immutable override directory;

  //*********************************************************************//
  // -------------------------- constructor ---------------------------- //
  //*********************************************************************//

  /** 
    @param _directory A contract storing directories of terminals and controllers for each project.
  */
  constructor(IJBDirectory _directory) {
    directory = _directory;
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

import './IJBDirectory.sol';

interface IJBControllerUtility {
  function directory() external view returns (IJBDirectory);
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
pragma solidity ^0.8.0;

interface IJBTokenUriResolver {
  function getUri(uint256 _projectId) external view returns (string memory tokenUri);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
  @notice
  Global constants used across Juicebox contracts.
*/
library JBConstants {
  uint256 public constant MAX_RESERVED_RATE = 10_000;
  uint256 public constant MAX_REDEMPTION_RATE = 10_000;
  uint256 public constant MAX_DISCOUNT_RATE = 1_000_000_000;
  uint256 public constant SPLITS_TOTAL_PERCENT = 1_000_000_000;
  uint256 public constant MAX_FEE = 1_000_000_000;
  uint256 public constant MAX_FEE_DISCOUNT = 1_000_000_000;
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

/** 
  @member content The metadata content.
  @member domain The domain within which the metadata applies.
*/
struct JBProjectMetadata {
  string content;
  uint256 domain;
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

        // Set the initial guess to the closest power of two that is higher than x.
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