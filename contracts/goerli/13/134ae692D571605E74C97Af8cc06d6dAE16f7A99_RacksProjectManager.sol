//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IRacksProjectManager.sol";
import "./interfaces/IMRC.sol";
import "./Project.sol";
import "./Contributor.sol";
import "./Err.sol";
import "./library/StructuredLinkedList.sol";

//              ▟██████████   █████    ▟███████████   █████████████
//            ▟████████████   █████  ▟█████████████   █████████████   ███████████▛
//           ▐█████████████   █████▟███████▛  █████   █████████████   ██████████▛
//            ▜██▛    █████   ███████████▛    █████       ▟██████▛    █████████▛
//              ▀     █████   █████████▛      █████     ▟██████▛
//                    █████   ███████▛      ▟█████▛   ▟██████▛
//   ▟█████████████   ██████              ▟█████▛   ▟██████▛   ▟███████████████▙
//  ▟██████████████   ▜██████▙          ▟█████▛   ▟██████▛   ▟██████████████████▙
// ▟███████████████     ▜██████▙      ▟█████▛   ▟██████▛   ▟█████████████████████▙
//                        ▜██████▙            ▟██████▛          ┌────────┐
//                          ▜██████▙        ▟██████▛            │  LABS  │
//                                                              └────────┘

contract RacksProjectManager is IRacksProjectManager, Ownable, AccessControl {
    /// @notice tokens
    IMRC private immutable mrc;
    IERC20 private erc20;

    /// @notice State variables
    bytes32 private constant ADMIN_ROLE = 0x00;
    address[] private contributors;
    bool private paused;
    uint256 progressiveId;

    using StructuredLinkedList for StructuredLinkedList.List;
    StructuredLinkedList.List private projectsList;
    mapping(uint256 => Project) private projectStore;

    mapping(address => bool) private walletIsContributor;
    mapping(address => bool) private accountIsBanned;
    mapping(address => uint256) private projectId;
    mapping(address => Contributor) private contributorsData;

    /// @notice Check that user is Admin
    modifier onlyAdmin() {
        if (!hasRole(ADMIN_ROLE, msg.sender)) revert adminErr();
        _;
    }

    /// @notice Check that user is Holder or Admin
    modifier onlyHolder() {
        if (mrc.balanceOf(msg.sender) < 1 && !hasRole(ADMIN_ROLE, msg.sender)) revert holderErr();
        _;
    }

    /// @notice Check that the smart contract is paused
    modifier isNotPaused() {
        if (paused) revert pausedErr();
        _;
    }

    ///////////////////
    //  Constructor  //
    ///////////////////
    constructor(IMRC _mrc, IERC20 _erc20) {
        erc20 = _erc20;
        mrc = _mrc;
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    ///////////////////////
    //  Logic Functions  //
    ///////////////////////

    /**
     * @notice Create Project
     * @dev Only callable by Admins
     */
    function createProject(
        string memory _name,
        uint256 _colateralCost,
        uint256 _reputationLevel,
        uint256 _maxContributorsNumber
    ) external onlyAdmin isNotPaused {
        if (
            _colateralCost <= 0 ||
            _reputationLevel <= 0 ||
            _maxContributorsNumber <= 0 ||
            bytes(_name).length <= 0
        ) revert projectInvalidParameterErr();

        Project newProject = new Project(
            this,
            _name,
            _colateralCost,
            _reputationLevel,
            _maxContributorsNumber
        );

        progressiveId++;
        projectStore[progressiveId] = newProject;
        projectId[address(newProject)] = progressiveId;
        projectsList.pushFront(progressiveId);

        _setupRole(ADMIN_ROLE, address(newProject));
        emit newProjectCreated(_name, address(newProject));
    }

    /**
     * @notice Add Contributor
     * @dev Only callable by Holders who are not already Contributors
     */
    function registerContributor() external onlyHolder isNotPaused {
        if (walletIsContributor[msg.sender]) revert contributorAlreadyExistsErr();

        contributors.push(msg.sender);
        walletIsContributor[msg.sender] = true;
        contributorsData[msg.sender] = Contributor(msg.sender, 1, 0, false);
        emit newContributorRegistered(msg.sender);
    }

    ////////////////////////
    //  Helper Functions  //
    ////////////////////////

    /**
     * @notice Set new Admin
     * @dev Only callable by the Admin
     */
    function addAdmin(address _newAdmin) external onlyOwner {
        grantRole(ADMIN_ROLE, _newAdmin);
    }

    /**
     * @notice Remove an account from the user role
     * @dev Only callable by the Admin
     */
    function removeAdmin(address _account) external virtual onlyOwner {
        revokeRole(ADMIN_ROLE, _account);
    }

    ///////////////////////
    //  Setter Functions //
    ///////////////////////

    /**
     * @notice Set new ERC20 Token
     * @dev Only callable by the Admin
     */
    function setERC20Address(address _erc20) external onlyAdmin {
        erc20 = IERC20(_erc20);
    }

    /**
     * @notice Set a ban state for a Contributor
     * @dev Only callable by Admins.
     */
    function setContributorStateToBanList(address _account, bool _state) external onlyAdmin {
        accountIsBanned[_account] = _state;

        if (_state == true) {
            (bool existNext, uint256 i) = projectsList.getNextNode(0);

            while (i != 0 && existNext) {
                Project project = projectStore[i];

                if (project.isActive() && project.isContributorInProject(_account)) {
                    project.removeContributor(_account, false);
                }

                (existNext, i) = projectsList.getNextNode(i);
            }
        }
    }

    /// @inheritdoc IRacksProjectManager
    function setAccountToContributorData(address _account, Contributor memory _newData)
        public
        override
        onlyAdmin
    {
        contributorsData[_account] = _newData;
    }

    /// Increase Contributor's Reputation Level
    function increaseContributorLv(address _account, uint256 levels) public onlyAdmin {
        if (levels <= 0) revert invalidParameterErr();
        Contributor memory contributor = contributorsData[_account];
        contributor.reputationLevel += levels;
        contributor.reputationPoints = 0;
        contributorsData[_account] = contributor;
    }

    function setIsPaused(bool _newPausedValue) public onlyAdmin {
        paused = _newPausedValue;
    }

    ////////////////////////
    //  Getter Functions //
    //////////////////////

    /// @inheritdoc IRacksProjectManager
    function isAdmin(address _account) public view override returns (bool) {
        return hasRole(ADMIN_ROLE, _account);
    }

    /// @notice Returns MRC address
    function getMRCInterface() external view returns (IMRC) {
        return mrc;
    }

    /// @inheritdoc IRacksProjectManager
    function getERC20Interface() public view override returns (IERC20) {
        return erc20;
    }

    /// @inheritdoc IRacksProjectManager
    function getRacksPMOwner() public view override returns (address) {
        return owner();
    }

    /// @inheritdoc IRacksProjectManager
    function isContributorBanned(address _account) external view override returns (bool) {
        return accountIsBanned[_account];
    }

    /**
     * @notice Get projects depending on Level
     * @dev Only callable by Holders
     */
    function getProjects() public view onlyHolder returns (Project[] memory) {
        if (hasRole(ADMIN_ROLE, msg.sender)) return getAllProjects();
        Project[] memory filteredProjects = new Project[](projectsList.sizeOf());

        unchecked {
            uint256 callerReputationLv = walletIsContributor[msg.sender]
                ? contributorsData[msg.sender].reputationLevel
                : 1;
            uint256 j = 0;
            (bool existNext, uint256 i) = projectsList.getNextNode(0);

            while (i != 0 && existNext) {
                if (projectStore[i].getReputationLevel() <= callerReputationLv) {
                    filteredProjects[j] = projectStore[i];
                    j++;
                }
                (existNext, i) = projectsList.getNextNode(i);
            }
        }

        return filteredProjects;
    }

    function getAllProjects() private view returns (Project[] memory) {
        Project[] memory allProjects = new Project[](projectsList.sizeOf());

        uint256 j = 0;
        (bool existNext, uint256 i) = projectsList.getNextNode(0);

        while (i != 0 && existNext) {
            allProjects[j] = projectStore[i];
            j++;
            (existNext, i) = projectsList.getNextNode(i);
        }

        return allProjects;
    }

    /// @notice Get Contributor by index
    function getContributor(uint256 _index) public view returns (Contributor memory) {
        return contributorsData[contributors[_index]];
    }

    /// @inheritdoc IRacksProjectManager
    function isWalletContributor(address _account) public view override returns (bool) {
        return walletIsContributor[_account];
    }

    /// @inheritdoc IRacksProjectManager
    function getContributorData(address _account)
        public
        view
        override
        returns (Contributor memory)
    {
        return contributorsData[_account];
    }

    /**
     * @notice Get total number of projects
     * @dev Only callable by Holders
     */
    function getNumberOfProjects() external view onlyHolder returns (uint256) {
        return projectsList.sizeOf();
    }

    /**
     * @notice Get total number of contributors
     * @dev Only callable by Holders
     */
    function getNumberOfContributors() external view onlyHolder returns (uint256) {
        return contributors.length;
    }

    /// @inheritdoc IRacksProjectManager
    function isPaused() external view override returns (bool) {
        return paused;
    }

    /// @inheritdoc IRacksProjectManager
    function deleteProject() external override {
        uint256 id = projectId[msg.sender];

        require(id != 0);

        projectId[msg.sender] = 0;
        projectsList.remove(id);
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
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Project.sol";
import "../Contributor.sol";
import "./IMRC.sol";
import "../Err.sol";

interface IRacksProjectManager {
    /////////////////
    ///   Events  ///
    /////////////////

    /**
     * @notice Event emitted when a new contributor is registered in RacksProjectManager
     */
    event newContributorRegistered(address newContributor);

    /**
     * @notice Event emitted when a new project is created in RacksProjectsManager
     */
    event newProjectCreated(string name, address newProjectAddress);

    /////////////////////////////
    ///   Abstract functions  ///
    /////////////////////////////

    /**
     * @notice Returns true if @param _account is admin in RacksProjectsManager otherwise returns false
     */
    function isAdmin(address _account) external view returns (bool);

    /**
     * @notice Get the address of the ERC20 used in RacksProjectsManger for colateral in projects
     */
    function getERC20Interface() external view returns (IERC20);

    /**
     * @notice Get the address of the owner of the contract
     */
    function getRacksPMOwner() external view returns (address);

    /**
     * @notice Returns true if @pram _account is registered as contributors otherwise return false
     */
    function isWalletContributor(address _account) external view returns (bool);

    /**
     * @notice Returns true if @pram _account is banned otherwise return false
     */
    function isContributorBanned(address _account) external view returns (bool);

    /**
     * @notice Returns all the data associated with @param _account contributor
     */
    function getContributorData(address _account) external view returns (Contributor memory);

    /**
     * @notice Update contributor data associated with @param _account contributor
     */
    function setAccountToContributorData(address _account, Contributor memory _newData) external;

    /**
     * @notice Return true if the RacksProjectsManager is paused, otherwise false
     */
    function isPaused() external view returns (bool);

    /**
     * @notice Deletes the project associated with the address of msg.sender Delete the project
     * @dev This function is called from Projects contracts when is deleted
     */
    function deleteProject() external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IMRC is IERC721Enumerable {
    /**
     *  @notice a function of the smart contract of Mr. Crypto by RacksMafia
     */
    function walletOfOwner(address account) external view returns (uint256[] memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IRacksProjectManager.sol";
import "./Contributor.sol";
import "./Err.sol";
import "./library/StructuredLinkedList.sol";

contract Project is Ownable, AccessControl {
    /// @notice Enumerations
    enum ProjectState {
        Pending,
        Active,
        Finished,
        Deleted
    }

    /// @notice Constants
    ProjectState private constant PENDING = ProjectState.Pending;
    ProjectState private constant ACTIVE = ProjectState.Active;
    ProjectState private constant FINISHED = ProjectState.Finished;
    ProjectState private constant DELETED = ProjectState.Deleted;
    bytes32 private constant ADMIN_ROLE = 0x00;

    /// @notice Interfaces
    IRacksProjectManager private immutable racksPM;

    /// @notice projectContributors
    using StructuredLinkedList for StructuredLinkedList.List;
    StructuredLinkedList.List private contributorList;

    uint256 private progressiveId = 0;
    mapping(uint256 => Contributor) private projectContributors;
    mapping(address => uint256) private contributorId;
    mapping(address => uint256) private participationOfContributors;
    mapping(address => uint256) private projectFunds;

    /// @notice State variables
    string private name;
    uint256 private colateralCost;
    uint256 private reputationLevel;
    uint256 private maxContributorsNumber;
    ProjectState private projectState;
    IERC20 private immutable racksPM_ERC20;

    /// @notice Check that the project has no contributors, therefore is editable
    modifier isEditable() {
        if (contributorList.sizeOf() > 0) revert projectNoEditableErr();
        _;
    }

    /// @notice Check that the project is not finished
    modifier isNotFinished() {
        if (projectState == FINISHED) revert projectFinishedErr();
        _;
    }

    /// @notice Check that user is Admin
    modifier onlyAdmin() {
        if (!hasRole(ADMIN_ROLE, msg.sender)) revert adminErr();
        _;
    }

    /// @notice Check that user is Contributor
    modifier onlyContributor() {
        if (!racksPM.isWalletContributor(msg.sender)) revert contributorErr();
        _;
    }

    /// @notice Check that the smart contract is not Paused
    modifier isNotPaused() {
        if (racksPM.isPaused()) revert pausedErr();
        _;
    }

    /// @notice Check that the smart contract is not Pending
    modifier isNotPending() {
        if (projectState == PENDING) revert pendingErr();
        _;
    }

    /// @notice Check that the smart contract is not Deleted
    modifier isNotDeleted() {
        if (projectState == DELETED) revert deletedErr();
        _;
    }

    /// @notice Events
    event newProjectContributorsRegistered(address projectAddress, address newProjectContributor);
    event projectFunded(address projectAddress, address funderWallet, uint256 amount);

    constructor(
        IRacksProjectManager _racksPM,
        string memory _name,
        uint256 _colateralCost,
        uint256 _reputationLevel,
        uint256 _maxContributorsNumber
    ) {
        racksPM = _racksPM;
        name = _name;
        colateralCost = _colateralCost;
        reputationLevel = _reputationLevel;
        maxContributorsNumber = _maxContributorsNumber;
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, _racksPM.getRacksPMOwner());
        racksPM_ERC20 = _racksPM.getERC20Interface();
        projectState = PENDING;
    }

    ////////////////////////
    //  Logic Functions  //
    //////////////////////

    /**
     * @notice Add Project Contributor
     * @dev Only callable by Holders who are already Contributors
     */
    function registerProjectContributor()
        external
        onlyContributor
        isNotFinished
        isNotPaused
        isNotDeleted
        isNotPending
    {
        if (isContributorInProject(msg.sender)) revert projectContributorAlreadyExistsErr();
        if (contributorList.sizeOf() == maxContributorsNumber)
            revert maxContributorsNumberExceededErr();

        Contributor memory contributor = racksPM.getContributorData(msg.sender);

        if (racksPM.isContributorBanned(contributor.wallet)) revert projectContributorIsBannedErr();
        if (contributor.reputationLevel < reputationLevel)
            revert projectContributorHasNoReputationEnoughErr();

        progressiveId++;
        projectContributors[progressiveId] = contributor;
        contributorList.pushFront(progressiveId);
        contributorId[contributor.wallet] = progressiveId;

        emit newProjectContributorsRegistered(address(this), msg.sender);

        bool success = racksPM_ERC20.transferFrom(msg.sender, address(this), colateralCost);
        if (!success) revert erc20TransferFailed();
    }

    /**
     * @notice Finish Project
     * @dev Only callable by Admins when the project isn't completed
     * - The contributors and participationWeights array must have the same size of the project contributors list.
     * - If there is a banned Contributor in the project, you have to pass his address and participation (should be 0) anyways.
     * - The sum of @param _participationWeights can not be more than 100
     */
    function finishProject(
        uint256 _totalReputationPointsReward,
        address[] memory _contributors,
        uint256[] memory _participationWeights
    ) external onlyAdmin isNotFinished isNotPaused isNotDeleted isNotPending {
        if (
            _totalReputationPointsReward <= 0 ||
            _contributors.length != contributorList.sizeOf() ||
            _participationWeights.length != contributorList.sizeOf()
        ) revert projectInvalidParameterErr();

        projectState = FINISHED;
        uint256 totalParticipationWeight = 0;
        unchecked {
            for (uint256 i = 0; i < _contributors.length; i++) {
                if (!isContributorInProject(_contributors[i])) revert contributorErr();

                uint256 participationWeight = _participationWeights[i];

                participationOfContributors[_contributors[i]] = participationWeight;
                totalParticipationWeight += participationWeight;
            }
            if (totalParticipationWeight > 100) revert projectInvalidParameterErr();
        }
        unchecked {
            (bool existNext, uint256 i) = contributorList.getNextNode(0);

            while (i != 0 && existNext) {
                address contrAddress = projectContributors[i].wallet;

                uint256 reputationToIncrease = (_totalReputationPointsReward *
                    participationOfContributors[contrAddress]) / 100;

                increaseContributorReputation(reputationToIncrease, i);
                racksPM.setAccountToContributorData(contrAddress, projectContributors[i]);

                bool success = racksPM_ERC20.transfer(contrAddress, colateralCost);
                if (!success) revert erc20TransferFailed();

                (existNext, i) = contributorList.getNextNode(i);
            }
        }
        if (racksPM_ERC20.balanceOf(address(this)) > 0) shareProfits();
    }

    /**
     * @notice Fund the project with ERC20
     * @dev This serves as a reward to contributors
     */
    function fundProject(uint256 _amount) external isNotPaused isNotDeleted isNotPending {
        if (_amount <= 0 || contributorList.sizeOf() < 1) revert invalidParameterErr();

        projectFunds[msg.sender] += _amount;
        emit projectFunded(address(this), msg.sender, _amount);
        bool success = racksPM_ERC20.transferFrom(msg.sender, address(this), _amount);
        if (!success) revert erc20TransferFailed();
    }

    /**
     * @notice Give Away extra rewards
     * @dev Only callable by Admins when the project is completed
     */
    function giveAway() external onlyAdmin isNotPaused isNotDeleted isNotPending {
        if (projectState != ProjectState.Finished) revert notCompletedErr();

        if (address(this).balance <= 0 && racksPM_ERC20.balanceOf(address(this)) <= 0)
            revert noFundsGiveAwayErr();

        shareProfits();
    }

    ////////////////////////
    //  Helper Functions //
    //////////////////////

    /**
     * @notice Used to give away profits
     * @dev Only callable by Admins when project completed
     */
    function shareProfits() private onlyAdmin {
        if (projectState != ProjectState.Finished) revert notCompletedErr();

        unchecked {
            uint256 projectBalanceERC20 = racksPM_ERC20.balanceOf(address(this));
            uint256 projectBalanceEther = address(this).balance;
            (bool existNext, uint256 i) = contributorList.getNextNode(0);

            while (i != 0 && existNext) {
                address contrAddress = projectContributors[i].wallet;
                if (racksPM_ERC20.balanceOf(address(this)) > 0) {
                    bool successTransfer = racksPM_ERC20.transfer(
                        contrAddress,
                        (projectBalanceERC20 * participationOfContributors[contrAddress]) / 100
                    );
                    if (!successTransfer) revert erc20TransferFailed();
                }

                if (address(this).balance > 0) {
                    (bool success, ) = contrAddress.call{
                        value: (projectBalanceEther * participationOfContributors[contrAddress]) /
                            100
                    }("");
                    if (!success) revert transferGiveAwayFailed();
                }
                (existNext, i) = contributorList.getNextNode(i);
            }
        }
    }

    /**
     * @notice Set new Admin
     * @dev Only callable by the Admin
     */
    function addAdmin(address _newAdmin) external onlyOwner isNotDeleted {
        grantRole(ADMIN_ROLE, _newAdmin);
    }

    /**
     * @notice Remove an account from the user role
     * @dev Only callable by the Admin
     */
    function removeAdmin(address _account) external virtual onlyOwner isNotDeleted {
        revokeRole(ADMIN_ROLE, _account);
    }

    /**
     * @notice Increase Contributor's reputation
     * @dev Only callable by Admins internally
     */
    function increaseContributorReputation(uint256 _reputationPointsReward, uint256 _index)
        private
        onlyAdmin
        isNotDeleted
    {
        unchecked {
            Contributor memory _contributor = projectContributors[_index];

            uint256 grossReputationPoints = _contributor.reputationPoints + _reputationPointsReward;

            while (grossReputationPoints >= (_contributor.reputationLevel * 100)) {
                grossReputationPoints -= (_contributor.reputationLevel * 100);
                _contributor.reputationLevel++;
            }
            _contributor.reputationPoints = grossReputationPoints;

            projectContributors[_index] = _contributor;
        }
    }

    /**
     * @notice Provides information about supported interfaces (required by AccessControl)
     */
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(_interfaceId);
    }

    function deleteProject() public onlyAdmin isNotDeleted isEditable {
        projectState = DELETED;

        racksPM.deleteProject();
    }

    function removeContributor(address _contributor, bool _returnColateral)
        public
        onlyAdmin
        isNotDeleted
    {
        if (!isContributorInProject(_contributor)) revert contributorErr();

        uint256 id = contributorId[_contributor];
        contributorId[_contributor] = 0;
        contributorList.remove(id);

        if (_returnColateral) {
            bool success = racksPM_ERC20.transfer(_contributor, colateralCost);
            if (!success) revert erc20TransferFailed();
        }
    }

    ////////////////////////
    //  Setter Functions //
    //////////////////////

    /**
     * @notice  the Project State
     * @dev Only callable by Admins when the project has no Contributor yet and is pending.
     */
    function approveProject() external onlyAdmin isNotPaused isNotDeleted {
        if (projectState == PENDING) projectState = ACTIVE;
    }

    /**
     * @notice  the Project Name
     * @dev Only callable by Admins when the project has no Contributor yet.
     */
    function setName(string memory _name) external onlyAdmin isEditable isNotPaused isNotDeleted {
        if (bytes(_name).length <= 0) revert projectInvalidParameterErr();
        name = _name;
    }

    /**
     * @notice Edit the Colateral Cost
     * @dev Only callable by Admins when the project has no Contributor yet.
     */
    function setColateralCost(uint256 _colateralCost)
        external
        onlyAdmin
        isEditable
        isNotPaused
        isNotDeleted
    {
        if (_colateralCost <= 0) revert projectInvalidParameterErr();
        colateralCost = _colateralCost;
    }

    /**
     * @notice Edit the Reputation Level
     * @dev Only callable by Admins when the project has no Contributor yet.
     */
    function setReputationLevel(uint256 _reputationLevel)
        external
        onlyAdmin
        isEditable
        isNotPaused
        isNotDeleted
    {
        if (_reputationLevel <= 0) revert projectInvalidParameterErr();
        reputationLevel = _reputationLevel;
    }

    /**
     * @notice Edit the Reputation Level
     * @dev Only callable by Admins when the project has no Contributor yet.
     */
    function setMaxContributorsNumber(uint256 _maxContributorsNumber)
        external
        onlyAdmin
        isNotPaused
        isNotDeleted
    {
        if (_maxContributorsNumber <= 0 || _maxContributorsNumber < contributorList.sizeOf())
            revert projectInvalidParameterErr();
        maxContributorsNumber = _maxContributorsNumber;
    }

    ////////////////////////
    //  Getter Functions //
    //////////////////////

    /// @notice Get the project name
    function getName() external view returns (string memory) {
        return name;
    }

    /// @notice Get the colateral cost to enter as contributor
    function getColateralCost() external view returns (uint256) {
        return colateralCost;
    }

    /// @notice Get the reputation level of the project
    function getReputationLevel() external view returns (uint256) {
        return reputationLevel;
    }

    /// @notice Get the maximum contributor that can be in the project
    function getMaxContributors() external view returns (uint256) {
        return maxContributorsNumber;
    }

    /// @notice Get total number of contributors
    function getNumberOfContributors() external view returns (uint256) {
        return contributorList.sizeOf();
    }

    /// @notice Get all contributor addresses
    function getAllContributorsAddress() external view returns (address[] memory) {
        address[] memory allContributors = new address[](contributorList.sizeOf());

        uint256 j = 0;
        (bool existNext, uint256 i) = contributorList.getNextNode(0);

        while (i != 0 && existNext) {
            allContributors[j] = projectContributors[i].wallet;
            j++;
            (existNext, i) = contributorList.getNextNode(i);
        }

        return allContributors;
    }

    /// @notice Get contributor by address
    function getContributorByAddress(address _account)
        external
        view
        onlyAdmin
        returns (Contributor memory)
    {
        uint256 id = contributorId[_account];
        return projectContributors[id];
    }

    /// @notice Return true if the address is a contributor in the project
    function isContributorInProject(address _contributor) public view returns (bool) {
        return contributorId[_contributor] != 0;
    }

    /// @notice Get the participation weight in percent
    function getContributorParticipation(address _contributor) external view returns (uint256) {
        if (projectState != ProjectState.Finished) revert notCompletedErr();
        return participationOfContributors[_contributor];
    }

    /// @notice Get the balance of funds given by an address
    function getAccountFunds(address _account) external view returns (uint256) {
        return projectFunds[_account];
    }

    /// @notice Get the balance of funds given by an address
    function getProjectFunds() external view returns (uint256) {
        uint256 projectBalanceERC20 = racksPM_ERC20.balanceOf(address(this));

        if (projectState != FINISHED && contributorList.sizeOf() > 0)
            projectBalanceERC20 -= colateralCost * contributorList.sizeOf();
        return projectBalanceERC20;
    }

    /// @notice Returns whether the project is pending or not
    function isPending() external view returns (bool) {
        return projectState == PENDING;
    }

    /// @notice Returns whether the project is active or not
    function isActive() external view returns (bool) {
        return projectState == ACTIVE;
    }

    /// @notice Return true is the project is completed, otherwise return false
    function isFinished() external view returns (bool) {
        return projectState == FINISHED;
    }

    /// @notice Returns whether the project is deleted or not
    function isDeleted() external view returns (bool) {
        return projectState == DELETED;
    }

    receive() external payable {}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/// @notice struct Contributor when a holder has been registered
struct Contributor {
    address wallet;
    uint256 reputationLevel;
    uint256 reputationPoints;
    bool banned;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

error adminErr();
error holderErr();
error contributorErr();
error contributorAlreadyExistsErr();
error projectContributorAlreadyExistsErr();
error maxContributorsNumberExceededErr();
error projectContributorIsBannedErr();
error erc20TransferFailed();
error transferGiveAwayFailed();
error projectNoEditableErr();
error projectInvalidParameterErr();
error invalidParameterErr();
error projectFinishedErr();
error noFundsWithdrawErr();
error noFundsGiveAwayErr();
error notCompletedErr();
error projectContributorHasNoReputationEnoughErr();
error pausedErr();
error deletedErr();
error pendingErr();

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/**
 * @title StructuredLinkedList
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev An utility library for using sorted linked list data structures in your Solidity project.
 */
library StructuredLinkedList {
    uint256 private constant _NULL = 0;
    uint256 private constant _HEAD = 0;

    bool private constant _PREV = false;
    bool private constant _NEXT = true;

    struct List {
        uint256 size;
        mapping(uint256 => mapping(bool => uint256)) list;
    }

    /**
     * @dev Checks if the node exists
     * @param self stored linked list from contract
     * @param _node a node to search for
     * @return bool true if node exists, false otherwise
     */
    function nodeExists(List storage self, uint256 _node) internal view returns (bool) {
        if (self.list[_node][_PREV] == _HEAD && self.list[_node][_NEXT] == _HEAD) {
            if (self.list[_HEAD][_NEXT] == _node) {
                return true;
            } else {
                return false;
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Returns the number of elements in the list
     * @param self stored linked list from contract
     * @return uint256
     */
    function sizeOf(List storage self) internal view returns (uint256) {
        return self.size;
    }

    /**
     * @dev Returns the link of a node `_node` in direction `_direction`.
     * @param self stored linked list from contract
     * @param _node id of the node to step from
     * @param _direction direction to step in
     * @return bool, uint256 true if node exists or false otherwise, node in _direction
     */
    function getAdjacent(
        List storage self,
        uint256 _node,
        bool _direction
    ) internal view returns (bool, uint256) {
        if (!nodeExists(self, _node)) {
            return (false, 0);
        } else {
            return (true, self.list[_node][_direction]);
        }
    }

    /**
     * @dev Returns the link of a node `_node` in direction `_NEXT`.
     * @param self stored linked list from contract
     * @param _node id of the node to step from
     * @return bool, uint256 true if node exists or false otherwise, next node
     */
    function getNextNode(List storage self, uint256 _node) internal view returns (bool, uint256) {
        return getAdjacent(self, _node, _NEXT);
    }

    /**
     * @dev Returns the link of a node `_node` in direction `_PREV`.
     * @param self stored linked list from contract
     * @param _node id of the node to step from
     * @return bool, uint256 true if node exists or false otherwise, previous node
     */
    function getPreviousNode(List storage self, uint256 _node)
        internal
        view
        returns (bool, uint256)
    {
        return getAdjacent(self, _node, _PREV);
    }

    /**
     * @dev Insert node `_new` beside existing node `_node` in direction `_NEXT`.
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _new  new node to insert
     * @return bool true if success, false otherwise
     */
    function insertAfter(
        List storage self,
        uint256 _node,
        uint256 _new
    ) internal returns (bool) {
        return _insert(self, _node, _new, _NEXT);
    }

    /**
     * @dev Insert node `_new` beside existing node `_node` in direction `_PREV`.
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _new  new node to insert
     * @return bool true if success, false otherwise
     */
    function insertBefore(
        List storage self,
        uint256 _node,
        uint256 _new
    ) internal returns (bool) {
        return _insert(self, _node, _new, _PREV);
    }

    /**
     * @dev Removes an entry from the linked list
     * @param self stored linked list from contract
     * @param _node node to remove from the list
     * @return uint256 the removed node
     */
    function remove(List storage self, uint256 _node) internal returns (uint256) {
        if ((_node == _NULL) || (!nodeExists(self, _node))) {
            return 0;
        }
        _createLink(self, self.list[_node][_PREV], self.list[_node][_NEXT], _NEXT);
        delete self.list[_node][_PREV];
        delete self.list[_node][_NEXT];

        self.size -= 1; // NOT: SafeMath library should be used here to decrement.

        return _node;
    }

    /**
     * @dev Pushes an entry to the head of the linked list
     * @param self stored linked list from contract
     * @param _node new entry to push to the head
     * @return bool true if success, false otherwise
     */
    function pushFront(List storage self, uint256 _node) internal returns (bool) {
        return _push(self, _node, _NEXT);
    }

    /**
     * @dev Pushes an entry to the tail of the linked list
     * @param self stored linked list from contract
     * @param _node new entry to push to the tail
     * @return bool true if success, false otherwise
     */
    function pushBack(List storage self, uint256 _node) internal returns (bool) {
        return _push(self, _node, _PREV);
    }

    /**
     * @dev Pushes an entry to the head of the linked list
     * @param self stored linked list from contract
     * @param _node new entry to push to the head
     * @param _direction push to the head (_NEXT) or tail (_PREV)
     * @return bool true if success, false otherwise
     */
    function _push(
        List storage self,
        uint256 _node,
        bool _direction
    ) private returns (bool) {
        return _insert(self, _HEAD, _node, _direction);
    }

    /**
     * @dev Pops the first entry from the linked list
     * @param self stored linked list from contract
     * @param _direction pop from the head (_NEXT) or the tail (_PREV)
     * @return uint256 the removed node
     */
    function _pop(List storage self, bool _direction) private returns (uint256) {
        uint256 adj;
        (, adj) = getAdjacent(self, _HEAD, _direction);
        return remove(self, adj);
    }

    /**
     * @dev Insert node `_new` beside existing node `_node` in direction `_direction`.
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _new  new node to insert
     * @param _direction direction to insert node in
     * @return bool true if success, false otherwise
     */
    function _insert(
        List storage self,
        uint256 _node,
        uint256 _new,
        bool _direction
    ) private returns (bool) {
        if (!nodeExists(self, _new) && nodeExists(self, _node)) {
            uint256 c = self.list[_node][_direction];
            _createLink(self, _node, _new, _direction);
            _createLink(self, _new, c, _direction);

            self.size += 1; // NOT: SafeMath library should be used here to increment.

            return true;
        }

        return false;
    }

    /**
     * @dev Creates a bidirectional link between two nodes on direction `_direction`
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _link node to link to in the _direction
     * @param _direction direction to insert node in
     */
    function _createLink(
        List storage self,
        uint256 _node,
        uint256 _link,
        bool _direction
    ) private {
        self.list[_link][!_direction] = _node;
        self.list[_node][_direction] = _link;
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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