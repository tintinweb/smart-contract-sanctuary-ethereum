// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Grant.sol";

/// @title Factory contract used to create new grants,
/// each grant is a new contract deployed using this factory
contract GrantFactory is Ownable, Pausable {
    /// @notice Emitted when a new grant contract is deployed
    event GrantCreated(address grantAddress, uint96 workspaceId, string metadataHash, uint256 time);

    /**
     * @notice Create a new grant in the registry, can be called by workspace admins
     * @param _workspaceId id of workspace to which the grant belongs
     * @param _metadataHash grant metadata pointer to ipfs file
     * @param _workspaceReg workspace registry interface
     * @param _applicationReg application registry interface
     * @return address of created grant contract
     */
    function createGrant(
        uint96 _workspaceId,
        string memory _metadataHash,
        IWorkspaceRegistry _workspaceReg,
        IApplicationRegistry _applicationReg
    ) external whenNotPaused returns (address) {
        require(_workspaceReg.isWorkspaceAdmin(_workspaceId, msg.sender), "GrantCreate: Unauthorised");
        address _grantAddress = address(new Grant(_workspaceId, _metadataHash, _workspaceReg, _applicationReg));
        emit GrantCreated(_grantAddress, _workspaceId, _metadataHash, block.timestamp);
        return _grantAddress;
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
pragma solidity 0.8.7;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IWorkspaceRegistry.sol";
import "./interfaces/IApplicationRegistry.sol";

/// @title Singleton grant contract used for updating a grant, depositing and disbursal of reward funds
contract Grant {
    /// @notice workspaceId to which the grant belongs
    uint96 public workspaceId;

    /// @notice number of submitted applicantions
    uint96 public numApplicants;

    /// @notice grant metadata pointer to IPFS hash
    string public metadataHash;

    /// @notice denotes if grant is receiving applications
    bool public active;

    /// @notice applicationRegistry interface used for fetching application owner
    IApplicationRegistry public applicationReg;

    /// @notice workspaceRegistry interface used for fetching fetching workspace admin
    IWorkspaceRegistry public workspaceReg;

    /// @notice Emitted when a grant is updated
    event GrantUpdated(uint96 indexed workspaceId, string metadataHash, bool active, uint256 time);

    /// @notice Emitted when funds are deposited
    event FundsDeposited(address asset, uint256 amount, uint256 time);

    /// @notice Emitted when funds are withdrawn
    event FundsWithdrawn(address asset, uint256 amount, address recipient, uint256 time);

    /// @notice Emitted when fund deposit fails
    event FundsDepositFailed(address asset, uint256 amount, uint256 time);

    /// @notice Emitted when grant milestone is disbursed
    event DisburseReward(
        uint96 indexed applicationId,
        uint96 milestoneId,
        address asset,
        address sender,
        uint256 amount,
        uint256 time
    );

    /// @notice Emitted when disbursal fails
    event DisburseRewardFailed(
        uint96 indexed applicationId,
        uint96 milestoneId,
        address asset,
        address sender,
        uint256 amount,
        uint256 time
    );

    modifier onlyWorkspaceAdmin() {
        require(workspaceReg.isWorkspaceAdmin(workspaceId, msg.sender), "Unauthorised: Not an admin");
        _;
    }

    modifier onlyApplicationRegistry() {
        require(msg.sender == address(applicationReg), "Unauthorised: Not applicationRegistry");
        _;
    }

    /**
     * @notice Set grant details on contract deployment
     * @param _workspaceId workspace id to which the grant belong
     * @param _metadataHash metadata pointer
     * @param _workspaceReg workspace registry interface
     * @param _applicationReg application registry interface
     */
    constructor(
        uint96 _workspaceId,
        string memory _metadataHash,
        IWorkspaceRegistry _workspaceReg,
        IApplicationRegistry _applicationReg
    ) {
        workspaceId = _workspaceId;
        active = true;
        metadataHash = _metadataHash;
        applicationReg = _applicationReg;
        workspaceReg = _workspaceReg;
    }

    /**
     * @notice Update number of applications on grant, can be called by applicationRegistry contract
     */
    function incrementApplicant() external onlyApplicationRegistry {
        assert(numApplicants + 1 > numApplicants);
        numApplicants += 1;
    }

    /**
     * @notice Update the metadata pointer of a grant, can be called by workspace admins
     * @param _metadataHash New URL that points to grant metadata
     */
    function updateGrant(string memory _metadataHash) external onlyWorkspaceAdmin {
        require(numApplicants == 0, "GrantUpdate: Applicants have already started applying");
        metadataHash = _metadataHash;
        emit GrantUpdated(workspaceId, _metadataHash, active, block.timestamp);
    }

    /**
     * @notice Update grant accessibility, can be called by workspace admins
     * @param _canAcceptApplication set to false for disabling grant from receiving new applications
     */
    function updateGrantAccessibility(bool _canAcceptApplication) external onlyWorkspaceAdmin {
        active = _canAcceptApplication;
        emit GrantUpdated(workspaceId, metadataHash, _canAcceptApplication, block.timestamp);
    }

    /**
     * @notice Deposit funds to a workspace, can be called by anyone
     * @param _erc20Interface interface for erc20 asset using which rewards are disbursed
     * @param _amount Amount to be deposited for a given asset
     */
    function depositFunds(IERC20 _erc20Interface, uint256 _amount) external {
        emit FundsDeposited(address(_erc20Interface), _amount, block.timestamp);
        if (_amount > _erc20Interface.allowance(msg.sender, address(this))) {
            emit FundsDepositFailed(address(_erc20Interface), _amount, block.timestamp);
            revert("Please approve funds before transfer");
        }
        require(_erc20Interface.transferFrom(msg.sender, address(this), _amount), "Failed to transfer funds");
    }

    /**
     * @notice Withdraws funds from a grant to specified recipient, can be called only by workspace admin
     * @param _erc20Interface interface for erc20 asset using which rewards are disbursed
     * @param _amount Amount to be withdrawn for a given asset
     * @param _recipient address of wallet where the funds should be withdrawn to
     */
    function withdrawFunds(
        IERC20 _erc20Interface,
        uint256 _amount,
        address _recipient
    ) external onlyWorkspaceAdmin {
        emit FundsWithdrawn(address(_erc20Interface), _amount, _recipient, block.timestamp);
        require(_erc20Interface.transfer(_recipient, _amount), "Failed to transfer funds");
    }

    /**
     * @notice Disburses grant reward, can be called by applicationRegistry contract
     * @param _applicationId application id for which the funds are disbursed
     * @param _milestoneId milestone id for which the funds are disbursed
     * @param _erc20Interface interface for erc20 asset using which rewards are disbursed
     * @param _amount amount disbursed
     * @param _sender address of person trasferring reward
     */
    function disburseReward(
        uint96 _applicationId,
        uint96 _milestoneId,
        IERC20 _erc20Interface,
        uint256 _amount,
        address _sender
    ) external onlyApplicationRegistry {
        emit DisburseReward(_applicationId, _milestoneId, address(_erc20Interface), _sender, _amount, block.timestamp);
        require(
            _erc20Interface.transfer(applicationReg.getApplicationOwner(_applicationId), _amount),
            "Failed to transfer funds"
        );
    }

    /**
     * @notice Disburses grant reward, can be called by applicationRegistry contract
     * @param _applicationId application id for which the funds are disbursed
     * @param _milestoneId milestone id for which the funds are disbursed
     * @param _erc20Interface interface for erc20 asset using which rewards are disbursed
     * @param _amount amount disbursed
     * @param _sender address of person trasferring reward
     */
    function disburseRewardP2P(
        uint96 _applicationId,
        uint96 _milestoneId,
        IERC20 _erc20Interface,
        uint256 _amount,
        address _sender
    ) external onlyApplicationRegistry {
        emit DisburseReward(_applicationId, _milestoneId, address(_erc20Interface), _sender, _amount, block.timestamp);
        require(
            _erc20Interface.transferFrom(_sender, applicationReg.getApplicationOwner(_applicationId), _amount),
            "Failed to transfer funds"
        );
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/// @title Interface of the applicationRegistry contract
interface IApplicationRegistry {
    /// @notice Returns owner of application using specified application id
    function getApplicationOwner(uint96 _applicationId) external view returns (address);
}