// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../Interfaces/ThirdPartyAccountRegistryInterface.sol";

import "../Interfaces/CompanyRegistryInterface.sol";
import "../Interfaces/ThirdPartyAccountInterface.sol";
import "../Interfaces/TokenRegistryInterface.sol";

contract ThirdPartyAccountRegistryContract is AccessControl, ThirdPartyAccountRegistryInterface { 
    
    string public constant VersionString = "ThirdPartyAccountRegistryContract v1.0";
    
    address private _defaultAdminAddress;
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant PLATFORM_MODERATOR_ROLE = keccak256("PLATFORM_MODERATOR_ROLE");

    CompanyRegistryInterface private _companyRegistryInstance;
    uint private _companyId;
    uint private _entityId;
    
    // Account list data structure
    mapping(address => bool) private _isAccountRegistered;
    uint private _accountCounter;
    mapping(uint => address) private _accountMap;
    mapping(address => uint) private _accountAddressToIdMap;
    
    // Participant is holding which accounts
    mapping(address => mapping(address => bool)) _participantsChildAccountIsAdded;
    mapping(address => uint) private _participantChildrenCounters;
    mapping(address => mapping(uint => address)) private _participantChildAccountMap;
    mapping(address => mapping(address => uint)) private _participantChildAddressToIdMap;
    
    constructor(address defaultAdminAddress_, address companyRegistryAddress_, uint companyId_) {
        _setupRole(DEFAULT_ADMIN_ROLE, defaultAdminAddress_);
        _defaultAdminAddress = defaultAdminAddress_;

        _companyRegistryInstance = CompanyRegistryInterface(companyRegistryAddress_);
        _companyId = companyId_;
        _entityId = 7;
    }

    // =============================
    // ==== MANAGER_ROLE REGION ====
    // =============================
    function addAccount(address accountAddress_, address participantAddress_) onlyRole(MANAGER_ROLE) public override returns (bool) {
        require(!getIsAccountRegistered(accountAddress_), "Address is already registered account!");
        _appendAccount(accountAddress_);
        _appendChildAccountToParticipant(participantAddress_, accountAddress_);
        return true;
    }
    function removeAccount(address accountAddress_, address participantAddress_) onlyRole(MANAGER_ROLE) public override returns (bool) {
        require(getIsAccountRegistered(accountAddress_), "Address is not registered account!");
        
        _removeChildAccountFromParticipant(participantAddress_, accountAddress_);
        _removeAccount(accountAddress_);
        return true;
    }
    function switchAccounts(address firstAccountAddress_, address secondAccountAddress_) onlyRole(MANAGER_ROLE) public override returns (bool) {
        require(getIsAccountRegistered(firstAccountAddress_), "Address is not registered account!");
        require(getIsAccountRegistered(secondAccountAddress_), "Address is not registered account!");
        _switchAccount(getAccountId(firstAccountAddress_), getAccountId(secondAccountAddress_));
        return true;
    }
    
    function addAccountsParticipant(address participantAddress_, address accountAddress_) onlyRole(MANAGER_ROLE) public override returns (bool) {
        require(!getIsParticipantsChildRegistered(participantAddress_, accountAddress_), "This account already has this participant!");
        _appendChildAccountToParticipant(participantAddress_, accountAddress_);
        return true;
    }
    function removeAccountsParticipant(address participantAddress_, address accountAddress_) onlyRole(MANAGER_ROLE) public override returns (bool) {
        require(getIsAccountRegistered(accountAddress_), "Address is not registered account!");
        require(getIsParticipantsChildRegistered(participantAddress_, accountAddress_), "This account has different participant!");
        
        _removeChildAccountFromParticipant(participantAddress_, accountAddress_);
        return true;
    }
    function switchParticipantChildren(address participantAddress_, address firstAccountAddress_, address secondAccountAddress_) onlyRole(MANAGER_ROLE) public override returns (bool) {
        require(getIsParticipantsChildRegistered(participantAddress_, firstAccountAddress_), "Address is not registered account!");
        require(getIsParticipantsChildRegistered(participantAddress_, secondAccountAddress_), "Address is not registered account!");
        _switchChildAccountsOnParticipant(participantAddress_, getParticipansChildId(participantAddress_, firstAccountAddress_), getParticipansChildId(participantAddress_, secondAccountAddress_));
        return true;
    }

    // ==============================
    // ==== DEFAULT_ADMIN REGION ====
    // ==============================
    function setCompanyRegistryAddress(address companyRegistryAddress_) onlyRole(DEFAULT_ADMIN_ROLE) public override returns (bool) {
       emit CompanyRegistryAddressChanged(address(_companyRegistryInstance), companyRegistryAddress_);
       _companyRegistryInstance = CompanyRegistryInterface(companyRegistryAddress_);
        return true;
    }
    function setCompanyId(uint companyId_) onlyRole(DEFAULT_ADMIN_ROLE) public override returns (bool) {
       emit CompanyIdChanged(_companyId, companyId_);
       _companyId = companyId_;
        return true;
    }
    function setEntityId(uint entityId_) onlyRole(DEFAULT_ADMIN_ROLE) public override returns (bool) {
       emit EntityIdChanged(_entityId, entityId_);
       _entityId = entityId_;
        return true;
    }    
    
    function setDefaultAdminAddress(address defaultAdminAddress_) onlyRole(DEFAULT_ADMIN_ROLE) public override returns (bool) {
        emit DefaultAdminAddressChanged(_defaultAdminAddress, defaultAdminAddress_);
        address oldAdminAddress = _defaultAdminAddress;
        _setupRole(DEFAULT_ADMIN_ROLE, defaultAdminAddress_);

       _defaultAdminAddress = defaultAdminAddress_;
       revokeRole(DEFAULT_ADMIN_ROLE, oldAdminAddress);
        return true;
    }
    function setRoleAdmin(bytes32 role, bytes32 adminRole) onlyRole(DEFAULT_ADMIN_ROLE) public override returns (bool) {
        _setRoleAdmin(role, adminRole);
        return true;
    }

    function salvageTokensFromContract(address tokenAddress_, address to_, uint amount_) onlyRole(DEFAULT_ADMIN_ROLE) public override returns (bool) {
        IERC20(tokenAddress_).transfer(to_, amount_);
        return true;
    }
    function killContract() onlyRole(DEFAULT_ADMIN_ROLE) public override returns (bool) {
        emit ContractPurged();
        selfdestruct(payable(msg.sender));
        return true;
    }
    
    // =========================
    // ==== INTERNAL REGION ====
    // =========================
    function _appendAccount(address accountAddress_) internal returns (uint) {
        _accountMap[_accountCounter] = accountAddress_;
        _accountAddressToIdMap[accountAddress_] = _accountCounter;
        _accountCounter += 1;
        _isAccountRegistered[accountAddress_] = true;
        emit AccountAdded(accountAddress_, _accountCounter - 1);
        return _accountCounter - 1;
    }
    function _popAccount() internal returns (bool) {
        uint lastId = _accountCounter - 1;
        address lastAddress = _accountMap[lastId];
        
        _accountMap[lastId] = address(0);
        _accountAddressToIdMap[lastAddress] = 0;
        _accountCounter -= 1;
        _isAccountRegistered[lastAddress] = false;
        emit AccountRemoved(lastAddress);
        return true;
    }
    function _switchAccount(uint firstId_, uint secondId_) internal returns (bool) {
        address firstAddress = _accountMap[firstId_];
        address secondAddress = _accountMap[secondId_];
        
        _accountMap[firstId_] = secondAddress;
        _accountAddressToIdMap[secondAddress] = firstId_;
        
        _accountMap[secondId_] = firstAddress;
        _accountAddressToIdMap[firstAddress] = secondId_;
        emit AccountSwitched(firstAddress, firstId_, secondAddress, secondId_);
        return true;
    }
    function _removeAccount(address accountAddress_) internal returns (bool) {
        uint accountId = getAccountId(accountAddress_);
        if (accountId != _accountCounter - 1) {
            _switchAccount(accountId, _accountCounter - 1);
        }
        _popAccount();
        return true;
    }
    
    function _appendChildAccountToParticipant(address participantAddress_, address accountAddress_) internal returns (uint) {
        _participantChildAccountMap[participantAddress_][_participantChildrenCounters[participantAddress_]] = accountAddress_;
        _participantChildAddressToIdMap[participantAddress_][accountAddress_] = _participantChildrenCounters[participantAddress_];
        _participantChildrenCounters[participantAddress_] += 1;
        _participantsChildAccountIsAdded[participantAddress_][accountAddress_] = true;
        emit ParticipantsChildAccountAdded(participantAddress_, accountAddress_);
        return _accountCounter - 1;
    }
    function _popChildAccountFromParticipant(address participantAddress_) internal returns (bool) {
        uint lastId = _participantChildrenCounters[participantAddress_] - 1;
        address lastAddress = _participantChildAccountMap[participantAddress_][lastId];
        
        _participantChildAccountMap[participantAddress_][lastId] = address(0);
        _participantChildAddressToIdMap[participantAddress_][lastAddress] = 0;
        _participantChildrenCounters[participantAddress_] -= 1;
        _participantsChildAccountIsAdded[participantAddress_][lastAddress] = false;
        emit ChildAccountRemovedFromParticipant(participantAddress_, lastAddress);

        return true;
    }
    function _switchChildAccountsOnParticipant(address participantAddress_, uint firstId_, uint secondId_) internal returns (bool) {
        address firstAddress = _participantChildAccountMap[participantAddress_][firstId_];
        address secondAddress = _participantChildAccountMap[participantAddress_][secondId_];
        
        _participantChildAccountMap[participantAddress_][firstId_] = secondAddress;
        _participantChildAddressToIdMap[participantAddress_][secondAddress] = firstId_;
        
        _participantChildAccountMap[participantAddress_][secondId_] = firstAddress;
        _participantChildAddressToIdMap[participantAddress_][firstAddress] = secondId_;
        emit AccountSwitchedOnOwner(participantAddress_, firstAddress, firstId_, secondAddress, secondId_);
        return true;
    }
    function _removeChildAccountFromParticipant(address participantAddress_, address accountAddress_) internal returns (bool) {
        uint participantAccountId = getParticipansChildId(participantAddress_, accountAddress_);
        if (participantAccountId != getParticipantChildrenCount(participantAddress_) - 1) {
            _switchChildAccountsOnParticipant(participantAddress_, participantAccountId, getParticipantChildrenCount(participantAddress_) - 1);
        }
        _popChildAccountFromParticipant(participantAddress_);
        return true;
    }
    
    // ===============================
    // ==== PUBLIC_GETTERS REGION ====
    // ===============================
    function getAccounts(uint startIndex_, uint endIndex_) public view override returns (uint, address[] memory) {
        address[] memory accountList = new address[](endIndex_ - startIndex_);
        uint accountCounter;
        for (uint i=startIndex_; i<endIndex_; i++) {
            if (_accountMap[i] != address(0)) {
                accountList[accountCounter] = _accountMap[i];
                accountCounter += 1;
            }
        }
        return (accountCounter, accountList);
    }
    function getParticipantsChildrenAccounts(address participantAddress_, uint startIndex_, uint endIndex_) public view override returns (uint, address[] memory) {
        address[] memory accountList = new address[](endIndex_ - startIndex_);
        uint accountCounter;
        for (uint i=startIndex_; i<endIndex_; i++) {
            if (_participantChildAccountMap[participantAddress_][i] != address(0)) {
                accountList[accountCounter] = _participantChildAccountMap[participantAddress_][i];
                accountCounter += 1;
            }
        }
        return (accountCounter, accountList);
    }
    
    function getAccountAddress(uint accountId_) public view override returns (address) {
        return _accountMap[accountId_];
    }
    function getAccountId(address accountAddress_) public view override returns (uint) {
        return _accountAddressToIdMap[accountAddress_];
    }
    function getIsAccountRegistered(address accountAddress_) public view override returns (bool) {
        return _isAccountRegistered[accountAddress_];
    }
    function getAccountCount() public view override returns (uint) {
        return _accountCounter;
    }

    function getParticipantsChildAddress(address participantAddress_, uint accountId_) public view override returns (address) {
        return _participantChildAccountMap[participantAddress_][accountId_];
    }
    function getParticipansChildId(address participantAddress_, address accountAddress_) public view override returns (uint) {
        return _participantChildAddressToIdMap[participantAddress_][accountAddress_];
    }
    function getIsParticipantsChildRegistered(address participantAddress_, address accountAddress_) public view override returns (bool) {
        return _participantsChildAccountIsAdded[participantAddress_][accountAddress_];
    }
    function getParticipantChildrenCount(address participantAddress_) public view override returns (uint) {
        return _participantChildrenCounters[participantAddress_];
    }

    function getCompanyRegistryAddress() public view override returns (address) {
        return address(_companyRegistryInstance);
    }
    
    function getVersion() public pure override returns (bytes32) {
        return keccak256(abi.encode(VersionString));
    }
    function getCompanyId() public view override returns (uint) {
        return _companyId;
    }
    function getEntityId() public view override returns (uint) {
        return _entityId;
    }
    function getDefaultAdminAddress() public view override returns (address) {
        return _defaultAdminAddress;
    }
}

// SPDX-License-Identifier: MIT

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
        _checkRole(role, _msgSender());
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
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
     * If the calling account had been granted `role`, emits a {RoleRevoked}
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

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

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
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "../Interfaces/ThirdPartyAccountInterface.sol";

interface ThirdPartyAccountRegistryInterface is IAccessControl {
    
    // =============================
    // ==== MANAGER_ROLE REGION ====
    // =============================
    function addAccount(address participantAddress_, address accountAddress_) external returns (bool);
    function removeAccount(address participantAddress_, address accountAddress_) external returns (bool);
    function switchAccounts(address firstAccountAddress_, address secondAccountAddress_) external returns (bool);
    
    function addAccountsParticipant(address participantAddress_, address accountAddress_) external returns (bool);
    function removeAccountsParticipant(address accountAddress_, address participantAddress_) external returns (bool);
    function switchParticipantChildren(address participantAddress_, address firstAccountAddress_, address secondAccountAddress_) external returns (bool);
    
    // ==============================
    // ==== DEFAULT_ADMIN REGION ====
    // ==============================
    function setCompanyRegistryAddress(address companyRegistryAddress_) external returns (bool);
    function setCompanyId(uint companyId_) external returns (bool);
    function setEntityId(uint entityId_) external returns (bool);
    
    function setDefaultAdminAddress(address defaultAdminAddress_) external returns (bool);
    function setRoleAdmin(bytes32 role, bytes32 adminRole) external returns (bool);
    
    function salvageTokensFromContract(address tokenAddress_, address to_, uint amount_) external returns (bool);
    function killContract() external returns (bool);
    
    // =======================
    // ==== PUBLIC REGION ====
    // =======================
    function getAccounts(uint startIndex_, uint endIndex_) external returns (uint, address[] memory);
    function getParticipantsChildrenAccounts(address participantAddress_, uint startIndex_, uint endIndex_) external returns (uint, address[] memory);

    function getAccountAddress(uint accountId_) external view returns (address);
    function getAccountId(address accountAddress_) external view returns (uint);
    function getIsAccountRegistered(address accountAddress_) external view returns (bool);
    function getAccountCount() external view returns (uint);
    
    function getParticipantsChildAddress(address participantAddress_, uint accountId_) external view returns (address);
    function getParticipansChildId(address participantAddress_, address accountAddress_) external view returns (uint);
    function getIsParticipantsChildRegistered(address participantAddress_, address accountAddress_) external view returns (bool);
    function getParticipantChildrenCount(address participantAddress_) external view returns (uint);
    
    function getCompanyRegistryAddress() external view returns (address);

    function getVersion() external pure returns (bytes32);
    function getCompanyId() external view returns (uint);
    function getEntityId() external view returns (uint);
    function getDefaultAdminAddress() external view returns (address);
    
    // =======================
    // ==== EVENTS REGION ====
    // =======================
    event AccountAdded(address indexed accountAddress, uint accountId);
    event AccountRemoved(address indexed accountAddress);
    event AccountSwitched(address indexed firstAccountAddress, uint firstAccountId, address indexed secondAccountAddress, uint secondAccountId);
    event ParticipantsChildAccountAdded(address indexed participantAddress, address indexed accountAddress);
    event ChildAccountRemovedFromParticipant(address indexed participantAddress, address indexed accountAddress);
    event AccountSwitchedOnOwner(address indexed ownerAddress, address indexed firstAccountAddress, uint firstAccountId, address indexed secondAccountAddress, uint secondAccountId);
    
    event ContractPurged();
    event CompanyRegistryAddressChanged(address from, address to);
    event CompanyIdChanged(uint from, uint to);
    event EntityIdChanged(uint newEntityId, uint oldEntityId);
    event DefaultAdminAddressChanged(address from, address to);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";

interface CompanyRegistryInterface is IAccessControl {

    // =============================
    // ==== MANAGER_ROLE REGION ====
    // =============================
    function addNewCompany(string memory companyName_) external returns (bool);
    function enableCompany(uint companyId_) external returns (bool);
    function disableCompany(uint companyId_) external returns (bool);
    function changeCompanyName(uint companyId_, string memory companyName_) external returns (bool);
    function addEntityAddressToTheCompany(uint companyId_, uint[] memory entityIds_, address[] memory entityAddresses_) external returns (bool);

    // ==============================
    // ==== DEFAULT_ADMIN REGION ====
    // ==============================
    function appendEntity(string memory entityName_) external returns (bool);
    function popEntity() external returns (bool);
    function changeEntitiesName(uint entityId_, string memory entityName_) external returns (bool);
    function enableEntity(uint entityId_) external returns (bool);
    function disableEntity(uint entityId_) external returns (bool);

    function setDefaultAdminAddress(address defaultAdminAddress_) external returns (bool);
    function setRoleAdmin(bytes32 role, bytes32 adminRole) external returns (bool);

    function salvageTokensFromContract(address tokenAddress, address to, uint amount) external returns (bool);
    function killContract() external returns (bool);

    // ===============================
    // ==== PUBLIC_GETTERS REGION ====
    // ===============================
    function isEntityEnabled(uint companyId_, uint entityId_, address entityAddress_) external view returns (bool);
    
    function getCompanyCount() external view returns (uint);
    function getCompanies(uint startIndex_, uint endIndex_) external view returns (uint, uint[] memory);
    function getCompaniesData(uint startIndex_, uint endIndex_, address filterAddress_) external view returns (uint[] memory, string[] memory, bool[] memory);

    function getIsCompanyRegistered(uint companyId_) external view returns (bool);
    function getCompanyName(uint companyId_) external view returns (string memory);
    function getCompanyActivity(uint companyId_) external view returns (bool);
    function getCompanyEntity(uint companyId_, uint entityId_) external view returns (address);
    function getCompanyEntities(uint companyId_) external view returns (address[] memory);
    function getCompanyData(uint companyId_) external view returns (uint, string memory, bool, address[] memory);
    
    function getEntityCount() external view returns (uint);
    function getEntities(uint startIndex_, uint endIndex_) external view returns (uint, uint[] memory);
    function getEntityData(uint entityId_) external view returns (uint, bool, string memory);
    function getIsEntityEnabled(uint entityId_) external view returns (bool);
    function getEntityName(uint entityId_) external view returns (string memory);
    
    function getVersion() external pure returns (bytes32);
    function getDefaultAdminAddress() external view returns (address);
    
    // =======================
    // ==== EVENTS REGION ====
    // =======================
    event CompanyAdded(uint companyId, string companyName);
    event CompanyNameChanged(uint companyId, string oldName, string newName);
    event CompanyEntityChanged(uint companyId, uint entityId, address oldAddress, address newAddress);
    event CompanyEnabled(uint companyId);
    event CompanyDisabled(uint companyId);

    event EntityAdded(uint entityId, string entityName);
    event EntityRemoved(uint entityId, string entityName);
    event EntityNameChanged(uint entityId, string oldName, string newName);
    event EntityEnabled(uint entityId);
    event EntityDisabled(uint entityId);

    event ContractKilled();
    event DefaultAdminAddressChanged(address from, address to);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";

interface ThirdPartyAccountInterface is IAccessControl {
    
    // =======================
    // ==== PUBLIC REGION ====
    // =======================
    function transfer(address tokenAddress_, address to_, uint amount_) external returns (bool);
    function execute(address contractAddress, string memory functionSignature, bytes memory parameters) external returns(bytes memory);
    
    // =============================
    // ==== MANAGER_ROLE REGION ====
    // =============================
    function setThirdPartyOwnerAddress(address newThirdPartyOwnerAddress_) external returns (bool);
    function disableAccount() external returns (bool);
    function enableAccount() external returns (bool);
    function purgeAccount() external returns (bool);
    
    // ==============================
    // ==== DEFAULT_ADMIN REGION ====
    // ==============================
    function setCompanyRegistryAddress(address companyRegistryAddress_) external returns (bool);
    function setCompanyId(uint companyId_) external returns (bool);
    function setDefaultAdminAddress(address defaultAdminAddress_) external returns (bool);
    
    function salvageTokensFromContract(address tokenAddress, address to, uint amount) external returns (bool);
    function killContract() external returns (bool);
    
    // ===============================
    // ==== PUBLIC_GETTERS REGION ====
    // ===============================
    function getAccountData() external view returns (address, address);
    function getThirdPartyOwnerAddress() external view returns (address);
    
    function getCompanyRegistryAddress() external view returns (address);
    function getIdentityRegistryAddress() external view returns (address);
    function getTokenRegistryAddress() external view returns (address);
    
    function getEnabled() external view returns (bool);
    function getVersion() external pure returns (bytes32);
    function getCompanyId() external view returns (uint);
    function getDefaultAdminAddress() external view returns (address);
    
    // =======================
    // ==== EVENTS REGION ====
    // =======================
    event ThirdPartyOwnerChanged(address from, address to);
    event Enabled(bool option);
    event TransactionExecuted(address tokenAddress, address to, uint amount);
    event ExecuteExecuted(address contractAddress, string functionSignature, bytes parameters);
    
    event AccountPurged();
    event CompanyRegistryAddressChanged(address from, address to);
    event CompanyIdChanged(uint from, uint to);
    event DefaultAdminAddressChanged(address from, address to);
    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";

interface TokenRegistryInterface is IAccessControl {
    
    // ==========================
    // ==== MODERATOR REGION ====
    // ==========================
    function addNewToken(address newTokenAddress) external returns (bool);
    function removeToken(address tokenAddress) external returns (bool);
    function switchTokenPosition(address firstTokenAddres, address secondTokenAddress) external returns (bool);
    
    // ==============================
    // ==== DEFAULT_ADMIN REGION ====
    // ==============================
    function setCompanyRegistryAddress(address companyRegistryAddress_) external returns (bool);
    function setCompanyId(uint companyId_) external returns (bool);
    function setEntityId(uint entityId_) external returns (bool);
    
    function setDefaultAdminAddress(address defaultAdminAddress_) external returns (bool);
    function setRoleAdmin(bytes32 role, bytes32 adminRole) external returns (bool);
    
    function salvageTokensFromContract(address tokenAddress_, address to_, uint amount_) external returns (bool);
    function killContract() external returns (bool);
    
    // ===============================
    // ==== PUBLIC_GETTERS REGION ====
    // ===============================
    function getTokens(uint startIndex_, uint endIndex_) external view returns (uint, address[] memory);
    function getTokenData(uint startIndex_, uint endIndex_) external view returns (address[] memory, string[] memory, string[] memory, string[] memory);
    function getAccountBalances(address accountAddress_, uint startIndex_, uint endIndex_) external returns (address[] memory, uint[] memory);
    function getHoldsTokens(address accountAddress_) external view returns (bool);

    function getTokenAddress(uint tokenId_) external view returns(address);
    function getTokenId(address tokenAddress_) external view returns(uint);
    function getIsTokenRegistered(address tokenAddress_) external view returns (bool);
    function getTokenCount() external view returns (uint);
    
    function getCompanyRegistryAddress() external view returns (address);
    
    function getVersion() external pure returns (bytes32);
    function getCompanyId() external view returns (uint);
    function getEntityId() external view returns (uint);
    function getDefaultAdminAddress() external view returns (address);
    
    // =======================
    // ==== EVENTS REGION ====
    // =======================
    event TokenAdded(uint tokenId, address indexed tokenAddress);
    event TokenSwitched(uint firstId, address indexed firstTokenAddress, uint secondId, address indexed secondTokenAddress);
    event TokenRemoved(uint lastId, address indexed tokenAddress);

    event ContractPurged();
    event CompanyRegistryAddressChanged(address from, address to);
    event CompanyIdChanged(uint from, uint to);
    event EntityIdChanged(uint newEntityId, uint oldEntityId);
    event DefaultAdminAddressChanged(address from, address to);
}

// SPDX-License-Identifier: MIT

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