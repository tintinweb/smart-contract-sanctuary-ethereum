// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IWorkspaceRegistry.sol";
import "./interfaces/IGrant.sol";
import "./interfaces/IApplicationRegistry.sol";

/// @title Registry for all the grant applications used for updates on application
/// and requesting funds/milestone approvals
contract ApplicationRegistry is Ownable, Pausable, IApplicationRegistry {
    /// @notice Number of applications submitted
    uint96 public applicationCount;

    /// @notice possible states of an application milestones
    enum MilestoneState {
        Submitted,
        Requested,
        Approved
    }

    /// @notice possible states of an application
    enum ApplicationState {
        Submitted,
        Resubmit,
        Approved,
        Rejected,
        Complete
    }

    /// @notice types of reward disbursals
    enum DisbursalType {
        LockedAmount,
        P2P
    }

    /// @notice structure holding each application data
    struct Application {
        uint96 id;
        uint96 workspaceId;
        address grant;
        address owner;
        uint48 milestoneCount;
        uint48 milestonesDone;
        string metadataHash;
        ApplicationState state;
    }

    /// @notice mapping to store applicationId along with application
    mapping(uint96 => Application) public applications;

    /// @dev mapping to store application owner along with grant address
    /// ex: for application id - 0, grant addr - 0x0
    /// applicantGrant[0][0x0] will be = true, this is used to prevent duplicate entry
    mapping(address => mapping(address => bool)) private applicantGrant;

    /// @notice mapping to store applicationId along with milestones
    mapping(uint96 => mapping(uint48 => MilestoneState)) public applicationMilestones;

    /// @notice interface for using external functionalities like checking workspace admin
    IWorkspaceRegistry public workspaceReg;

    // --- Events ---
    /// @notice Emitted when a new application is submitted
    event ApplicationSubmitted(
        uint96 indexed applicationId,
        address grant,
        address owner,
        string metadataHash,
        uint48 milestoneCount,
        uint256 time
    );

    /// @notice Emitted when a new application is updated
    event ApplicationUpdated(
        uint96 indexed applicationId,
        address owner,
        string metadataHash,
        ApplicationState state,
        uint48 milestoneCount,
        uint256 time
    );

    /// @notice Emitted when application milestone is updated
    event MilestoneUpdated(uint96 _id, uint96 _milestoneId, MilestoneState _state, string _metadataHash, uint256 time);

    modifier onlyWorkspaceAdminOrReviewer(uint96 _workspaceId) {
        require(
            workspaceReg.isWorkspaceAdminOrReviewer(_workspaceId, msg.sender),
            "Unauthorised: Neither an admin nor a reviewer"
        );
        _;
    }

    /**
     * @notice sets workspace registry contract interface
     * @param _workspaceReg WorkspaceRegistry interface
     */
    function setWorkspaceReg(IWorkspaceRegistry _workspaceReg) external onlyOwner whenNotPaused {
        workspaceReg = _workspaceReg;
    }

    /**
     * @notice Create/submit application
     * @param _grant address of Grant for which the application is submitted
     * @param _workspaceId workspaceId to which the grant belongs
     * @param _metadataHash application metadata pointer to IPFS file
     * @param _milestoneCount number of milestones under the application
     */
    function submitApplication(
        address _grant,
        uint96 _workspaceId,
        string memory _metadataHash,
        uint48 _milestoneCount
    ) external whenNotPaused {
        require(!applicantGrant[msg.sender][_grant], "ApplicationSubmit: Already applied to grant once");
        IGrant grantRef = IGrant(_grant);
        require(grantRef.active(), "ApplicationSubmit: Invalid grant");
        uint96 _id = applicationCount;
        assert(applicationCount + 1 > applicationCount);
        applicationCount += 1;
        applications[_id] = Application(
            _id,
            _workspaceId,
            _grant,
            msg.sender,
            _milestoneCount,
            0,
            _metadataHash,
            ApplicationState.Submitted
        );
        applicantGrant[msg.sender][_grant] = true;
        emit ApplicationSubmitted(_id, _grant, msg.sender, _metadataHash, _milestoneCount, block.timestamp);
        grantRef.incrementApplicant();
    }

    /**
     * @notice Update application
     * @param _applicationId target applicationId which needs to be updated
     * @param _metadataHash updated application metadata pointer to IPFS file
     */
    function updateApplicationMetadata(
        uint96 _applicationId,
        string memory _metadataHash,
        uint48 _milestoneCount
    ) external whenNotPaused {
        Application storage application = applications[_applicationId];
        require(application.owner == msg.sender, "ApplicationUpdate: Unauthorised");
        require(application.state == ApplicationState.Resubmit, "ApplicationUpdate: Invalid state");
        /// @dev we need to reset milestone state of all the milestones set previously
        for (uint48 i = 0; i < application.milestoneCount; i++) {
            applicationMilestones[_applicationId][i] = MilestoneState.Submitted;
        }
        application.milestoneCount = _milestoneCount;
        application.metadataHash = _metadataHash;
        application.state = ApplicationState.Submitted;
        emit ApplicationUpdated(
            _applicationId,
            msg.sender,
            _metadataHash,
            ApplicationState.Submitted,
            _milestoneCount,
            block.timestamp
        );
    }

    /**
     * @notice Update application state
     * @param _applicationId target applicationId for which state needs to be updated
     * @param _workspaceId workspace id of application's grant
     * @param _state updated state
     * @param _reasonMetadataHash metadata file hash with state change reason
     */
    function updateApplicationState(
        uint96 _applicationId,
        uint96 _workspaceId,
        ApplicationState _state,
        string memory _reasonMetadataHash
    ) external whenNotPaused onlyWorkspaceAdminOrReviewer(_workspaceId) {
        Application storage application = applications[_applicationId];
        require(application.workspaceId == _workspaceId, "ApplicationStateUpdate: Invalid workspace");
        /// @notice grant creator can only make below transitions
        /// @notice Submitted => Resubmit
        /// @notice Submitted => Approved
        /// @notice Submitted => Rejected
        if (
            (application.state == ApplicationState.Submitted && _state == ApplicationState.Resubmit) ||
            (application.state == ApplicationState.Submitted && _state == ApplicationState.Approved) ||
            (application.state == ApplicationState.Submitted && _state == ApplicationState.Rejected)
        ) {
            application.state = _state;
        } else {
            revert("ApplicationStateUpdate: Invalid state transition");
        }
        emit ApplicationUpdated(
            _applicationId,
            msg.sender,
            _reasonMetadataHash,
            _state,
            application.milestoneCount,
            block.timestamp
        );
    }

    /**
     * @notice Mark application as complete
     * @param _applicationId target applicationId which needs to be marked as complete
     * @param _workspaceId workspace id of application's grant
     * @param _reasonMetadataHash metadata file hash with application overall feedback
     */
    function completeApplication(
        uint96 _applicationId,
        uint96 _workspaceId,
        string memory _reasonMetadataHash
    ) external whenNotPaused onlyWorkspaceAdminOrReviewer(_workspaceId) {
        Application storage application = applications[_applicationId];
        require(application.workspaceId == _workspaceId, "ApplicationStateUpdate: Invalid workspace");
        require(
            application.milestonesDone == application.milestoneCount,
            "CompleteApplication: Invalid milestones state"
        );

        application.state = ApplicationState.Complete;

        emit ApplicationUpdated(
            _applicationId,
            msg.sender,
            _reasonMetadataHash,
            ApplicationState.Complete,
            application.milestoneCount,
            block.timestamp
        );
    }

    /**
     * @notice Update application milestone state
     * @param _applicationId target applicationId for which milestone needs to be updated
     * @param _milestoneId target milestoneId which needs to be updated
     * @param _reasonMetadataHash metadata file hash with state change reason
     */
    function requestMilestoneApproval(
        uint96 _applicationId,
        uint48 _milestoneId,
        string memory _reasonMetadataHash
    ) external whenNotPaused {
        Application memory application = applications[_applicationId];
        require(application.owner == msg.sender, "MilestoneStateUpdate: Unauthorised");
        require(application.state == ApplicationState.Approved, "MilestoneStateUpdate: Invalid application state");
        require(_milestoneId < application.milestoneCount, "MilestoneStateUpdate: Invalid milestone id");
        require(
            applicationMilestones[_applicationId][_milestoneId] == MilestoneState.Submitted,
            "MilestoneStateUpdate: Invalid state transition"
        );
        applicationMilestones[_applicationId][_milestoneId] = MilestoneState.Requested;
        emit MilestoneUpdated(
            _applicationId,
            _milestoneId,
            MilestoneState.Requested,
            _reasonMetadataHash,
            block.timestamp
        );
    }

    /**
     * @notice Update application milestone state
     * @param _applicationId target applicationId for which milestone needs to be updated
     * @param _milestoneId target milestoneId which needs to be updated
     * @param _workspaceId workspace id of application's grant
     * @param _reasonMetadataHash metadata file hash with state change reason
     */
    function approveMilestone(
        uint96 _applicationId,
        uint48 _milestoneId,
        uint96 _workspaceId,
        string memory _reasonMetadataHash
    ) external whenNotPaused onlyWorkspaceAdminOrReviewer(_workspaceId) {
        Application storage application = applications[_applicationId];
        require(application.workspaceId == _workspaceId, "ApplicationStateUpdate: Invalid workspace");
        require(application.state == ApplicationState.Approved, "MilestoneStateUpdate: Invalid application state");
        require(_milestoneId < application.milestoneCount, "MilestoneStateUpdate: Invalid milestone id");
        MilestoneState currentState = applicationMilestones[_applicationId][_milestoneId];
        /// @notice grant creator can only make below transitions
        /// @notice Submitted => Approved
        /// @notice Requested => Approved
        if (currentState == MilestoneState.Submitted || currentState == MilestoneState.Requested) {
            applicationMilestones[_applicationId][_milestoneId] = MilestoneState.Approved;
        } else {
            revert("MilestoneStateUpdate: Invalid state transition");
        }

        application.milestonesDone += 1;

        emit MilestoneUpdated(
            _applicationId,
            _milestoneId,
            MilestoneState.Approved,
            _reasonMetadataHash,
            block.timestamp
        );
    }

    /**
     * @notice returns application owner
     * @param _applicationId applicationId for which owner is required
     * @return address of application owner
     */
    function getApplicationOwner(uint96 _applicationId) external view override returns (address) {
        Application memory application = applications[_applicationId];
        return application.owner;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/// @title Interface of workspaceRegistry contract
interface IWorkspaceRegistry {
    /// @notice Returns a boolean value indicating whether specified address is owner of given workspace
    function isWorkspaceAdmin(uint96 _id, address _member) external view returns (bool);

    /// @notice Returns a boolean value indicating whether specified address is admin or reviewer of given workspace
    function isWorkspaceAdminOrReviewer(uint96 _id, address _member) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/// @title Interface of the grant contract
interface IGrant {
    /// @notice Returns a boolean value indicating whether a grant is active
    function active() external view returns (bool);

    /// @notice It increments number of applicants against the grant
    /// and is invoked at the time of submitting application
    function incrementApplicant() external;

    /// @notice It disburses reward to application owner using locked funds
    function disburseReward(
        uint96 _applicationId,
        uint96 _milestoneId,
        address _asset,
        uint256 _amount,
        address _sender
    ) external;

    /// @notice It disburses reward to application owner P2P from workspace admin wallet
    function disburseRewardP2P(
        uint96 _applicationId,
        uint96 _milestoneId,
        address _asset,
        uint256 _amount,
        address _sender
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/// @title Interface of the applicationRegistry contract
interface IApplicationRegistry {
    /// @notice Returns owner of application using specified application id
    function getApplicationOwner(uint96 _applicationId) external view returns (address);
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