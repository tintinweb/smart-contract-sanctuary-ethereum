// SPDX-License-Identifier: MIT

pragma solidity 0.8.4; 

import "./FactiivStore.sol";
import "./FactiivRewards.sol";
import "./interfaces/IFactiiv.sol";
import "./interfaces/IOwned.sol";
import "./_openZeppelin/AccessControl.sol";
import "./FactsToken.sol";

contract Factiiv is IFactiiv, FactiivStore, AccessControl {

  using Bytes32Set for Bytes32Set.Set;
  using AddressSet for AddressSet.Set;
  using FactiivRewards for FactiivRewards.App;

  FactiivRewards.App userBalances;
  FactsToken factsToken;

  string public constant override versionRecipient = "2.2.0";
  bytes32 public constant override GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
  bytes32 public constant override ATTESTOR_ROLE = keccak256("ATTESTER_ROLE");
  bytes32 public constant override ARBITRATOR_ROLE = keccak256("ARBITRATOR ROLE");

  constructor(address root, address forwarder, address _factsToken) {
    _setupRole(DEFAULT_ADMIN_ROLE, root);
    _setupRole(GOVERNANCE_ROLE, root);
    _setTrustedForwarder(forwarder);
    factsToken = FactsToken(_factsToken);
    userBalances.setParentSharePercent(10**17); // 10%, 0.10, 18 decimal integer
    _initializeUser(IOwned(trustedForwarder()).owner(), IOwned(trustedForwarder()).owner());
    emit Deployed(root, forwarder, _factsToken);
  }
  
  /***************************
   * Internal accounts
   ***************************/

  // function burnTokens(uint256 amount) internal {
  //   address sender = _msgSender();
  //   factsToken.burn(amount);
  //   userBalances.sub(sender, amount);
  //   emit BurnFrom(sender, amount);
  // }

  function getUserBalance(address _userAddress) public view override returns(uint256) {
      return userBalances.balanceOf(_userAddress);
  }

  function getUserToParent(address _userAddress) external view override returns(uint256) {
      return userBalances.toParent(_userAddress);
  }

  function getUserParent(address _userAddress) external view override returns(address) {
      return userBalances.userParent(_userAddress);
  }

  function deposit(uint256 amount) external override {
      depositTo(_msgSender(), amount);
  }

  function depositTo(address userAddress, uint256 amount) public override {
    //if sender not initialized sets trusted forwarder owner as sender's parent
    //if reciever is not initialized sets sender as its parent 
    //just changed the order of parameters

    address sender = _msgSender();
    if(!isInitialized(sender)) _initializeUser(sender, IOwned(trustedForwarder()).owner()); // forwarder owner adopts sender  
    if(!isInitialized(userAddress)) _initializeUser(userAddress, sender); // sender adopts receiver
    
    factsToken.transferFrom(sender, address(this), amount);
    userBalances.add(userAddress, amount);
    emit Deposit(sender, userAddress, amount);
  }
  
  function toForwarder(address userAddress, uint256 amount) external override {
    require(isTrustedForwarder(msg.sender), "Factiiv::unauthorized");
    userBalances.sub(userAddress, amount);
    factsToken.transfer(msg.sender, amount);
    emit ToForwarder(userAddress, msg.sender, amount);
  }

  function withdraw(uint256 amount) public override {
    address sender = _msgSender();
    require(userBalances.balanceOf(sender) > amount, "Factiiv::withdraw: NSF");
    userBalances.sub(_msgSender(), amount);
    factsToken.transfer(sender, amount);
    emit Withdraw(sender, amount);
  }

  function inviteUser(address userAddress) public override {
    initializeUser(userAddress, _msgSender());
  }

  function initializeUser(address userAddress, address parentAddress) internal {
    // require(!isInitialized(userAddress), "Factiiv::initializeUser: user initialized");
    require(isInitialized(parentAddress), "Factiiv::initializeUser: parent uniniialized");
    _initializeUser(userAddress, parentAddress);
  }

  function _initializeUser(address userAddress, address parentAddress) private {
    upsertUser(userAddress);
    userBalances.initializeUser(userAddress, parentAddress);
    emit UserInitialized(userAddress, parentAddress);
  }

  function isInitialized(address userAddress) public view override returns(bool) {
    return userBalances.isInitialized(userAddress);
  }

  function transfer(address to, uint256 amount) public override {
    _transfer(_msgSender(), to, amount);
  }

  function _transfer(address from, address to, uint256 amount) internal {
      require(userBalances.balanceOf(from) >= amount, "Factiiv::_transfer: NSF");
      userBalances.sub(from, amount);
      userBalances.add(to, amount);
      emit TransferInternal(from, to, amount);
  }

  function payRewardTo(address userAddress, uint256 reward) external override {
    address sender = _msgSender();
    require(reward > 0, "Reward is Zero"); 
    require(userBalances.balanceOf(sender) >= reward, "Factiiv::payRewardTo: NSF");
    userBalances.payReward(userAddress, reward);
    userBalances.sub(sender, reward);
  }

  function pullReward(address childAddress) external override {
    userBalances.pullUp(_msgSender(), childAddress);
  }
  
  /***************************
   * Master Tables
   ***************************/  

  function setMinimumAmount(uint256 minimum) external override onlyRole(GOVERNANCE_ROLE) {
    minimumAmount = minimum;
    emit SetMinimum(_msgSender(), minimum);
  }

  function setParentSharePercent(uint256 percent) external override onlyRole(GOVERNANCE_ROLE) {
    userBalances.setParentSharePercent(percent);
    emit ParentSharePercent(_msgSender(), percent);
  }

  function createRelationshipType(string memory desc) external override onlyRole(GOVERNANCE_ROLE) returns (bytes32 id) {
    id = _createRelationshipType(_msgSender(), desc);
  }

  function updateRelationshipType(bytes32 id, string memory desc) external override onlyRole(GOVERNANCE_ROLE) {
    _updateRelationshipType(_msgSender(), id, desc);
  }

  function createAttestationType(string memory desc) external override onlyRole(GOVERNANCE_ROLE) returns (bytes32 id) {
    id = _createAttestationType(_msgSender(), desc);
  }

  function updateAttestationType(bytes32 id, string memory desc) external override onlyRole(GOVERNANCE_ROLE) {
    _updateAttestationType(_msgSender(), id, desc);
  }

  /***************************
   * Attestations
   ***************************/
  function createAttestation(address subject, bytes32 typeId, string memory payload) external override onlyRole(ATTESTOR_ROLE) returns (bytes32 id) {
    address sender = _msgSender();
    if(!isInitialized(subject))  (subject, sender);
    id = _createAttestation(_msgSender(), subject, typeId, payload);
  }

  function updateAttestation(address subject, bytes32 id, string memory payload) external override onlyRole(ATTESTOR_ROLE) {
    _updateAttestation(_msgSender(), subject, id, payload);
  }

  /***************************
   * Relationships
   ***************************/

  function createRelationship(bytes32 typeId, string memory desc, uint256 amount, address to) external override returns(bytes32 id) {
    address sender = _msgSender();
    if(!isInitialized(sender)) _initializeUser(sender, IOwned(trustedForwarder()).owner()); 
    if(!isInitialized(to))  (to, sender);
    id = _createRelationship(sender, typeId, desc, amount, to);
  }

  function updateRelationship(bytes32 id, Lifecycle lifecycle, string memory metadata) external override {
    address sender = _msgSender();
    require(
      canUpdateRelationship(sender, id), 
      "Factiiv::updateRelationship: permission denied");

    Relationship storage r = relationshipInfo[id];
    uint256 historyCount = r.history.length;
    Stage storage s = r.history[historyCount-1];

    if(s.lifecycle == Lifecycle.Proposed) {
      require(sender == r.to, "Factiiv::updateRelationship: sender should be relationship Reciever");
      require(lifecycle == Lifecycle.Accepted, "Factiiv::updateRelationship: stage should be Accepted");
      _updateRelationship(sender, id, lifecycle, metadata);
      return;
    } else if(s.lifecycle == Lifecycle.Accepted) {
      require(sender == r.from, "Factiiv::updateRelationship: sender should be Initiator");
      require(lifecycle == Lifecycle.Closed, "Factiiv::updateRelationship: stage should be Closed");
      _updateRelationship(sender, id, lifecycle, metadata);
      return;
    }
    else if(s.lifecycle == Lifecycle.Closed && lifecycle == Lifecycle.toRated || s.lifecycle == Lifecycle.fromRated && lifecycle == Lifecycle.toRated) {
      require(sender == r.to, "Factiiv::updateRelationship: sender should be Reciever");
      // require(lifecycle == Lifecycle.toRated, "Factiiv::updateRelationship: stage should be toRated");
      _updateRelationship(sender, id, lifecycle, metadata);
      return;
    } else if(s.lifecycle == Lifecycle.Closed && lifecycle == Lifecycle.fromRated || s.lifecycle == Lifecycle.toRated && lifecycle == Lifecycle.fromRated) {
      require(sender == r.from, "Factiiv::updateRelationship: sender should be Intiator");
      // require(lifecycle == Lifecycle.fromRated, "Factiiv::updateRelationship: stage should be fromRated");
      _updateRelationship(sender, id, lifecycle, metadata);
      return;
    } 
    else {
      revert("Factiiv::updateRelationship: invalid action");
    }
  }

  /***************************
   * delete relationship
   ***************************/  

  function deleteRelationship(bytes32 id) external override {
    require(
      canUpdateRelationship(_msgSender(), id),
      "Factiiv.deleteRelationship : not a participant, arbitrator or goverance");
    require(
      relationshipStage(id) == Lifecycle.Proposed,
      "Factiiv.deleteRelationship : relationship is accepted"
    );  
    _deleteRelationship(_msgSender(), id);
  }

  function arbitrationDelete(address userAddress, bytes32 id) external override onlyRole(ARBITRATOR_ROLE) {
    _deleteRelationship(userAddress, id);
  }

  /***************************
   * Access
   ***************************/ 

  function relationshipStage(bytes32 id) public view override returns(Lifecycle lifecycle) {
    Relationship storage r = relationshipInfo[id];
    uint256 historyCount = r.history.length;
    Stage storage s = r.history[historyCount-1];
    lifecycle = s.lifecycle;
  }

  function canUpdateRelationship(address updater, bytes32 id) public view override returns(bool) {
    Relationship storage r = relationshipInfo[id];
    return(
      r.from == updater ||
      r.to == updater ||
      hasRole(ARBITRATOR_ROLE, updater) ||
      hasRole(GOVERNANCE_ROLE, updater)
    );
  }  

  /***************************
   * View 
   ***************************/  

  /*** function signatures ***/

  // function getFunctionSignature(string memory functionString) public pure override returns(bytes4 functionSelector) {
  //   functionSelector = bytes4(keccak256(bytes(functionString)));
  // }

  /*** master tables ***/  

  function relationshipTypeCount() external view override returns(uint256 count) {
    count = relationshipTypeSet.count();
  }

  function relationshipTypeIdAtIndex(uint256 row) external view override returns(bytes32 id) {
    id = relationshipTypeSet.keyAtIndex(row);
  }

  function attestationTypeCount() external view override returns(uint256 count) {
    count = attestationTypeSet.count();
  }

  function attestationTypeAtIndex(uint256 row) external view override returns(bytes32 id) {
    id = attestationTypeSet.keyAtIndex(row);
  }

  /*** users ***/ 

  function userCount() external view override returns(uint256) {
    return userSet.count();
  }

  function userAtIndex(uint256 index) external view override returns(address) {
    return userSet.keyAtIndex(index);
  }

  function userMeta(address userAddr) external view override returns(uint256 linksOut, uint256 linksIn, uint256 attestations) {
    User storage u = user[userAddr];
    return(
      u.senderJoinSet.count(),
      u.receiverJoinSet.count(),
      u.attestationSet.count()
    );
  }

  function userSendRelationshipAtIndex(address userAddr, uint256 row) external view override returns(bytes32 id) {
    User storage u = user[userAddr];
    id = u.senderJoinSet.keyAtIndex(row);
  }

  function userReceiveRelationshipAtIndex(address userAddr, uint256 row) external view override returns(bytes32 id) {
    User storage u = user[userAddr];
    id = u.receiverJoinSet.keyAtIndex(row);
  }

  function userAttestationAtIndex(address userAddr, uint256 row) external view override returns(bytes32 id) {
    User storage u = user[userAddr];
    id = u.attestationSet.keyAtIndex(row);
  }

  /*** global ***/ 

  function relationshipCount() external view override returns(uint256 count) {
    count = relationshipSet.count();
  }

  function attestationCount() external view override returns(uint256 count) {
    count = attestationSet.count();
  }

  function relationshipAtIndex(uint256 row) external override view returns(bytes32 id) {
    id = relationshipSet.keyAtIndex(row);
  }

  function attestationAtIndex(uint256 row) external view override returns(bytes32 id) {
    id = attestationSet.keyAtIndex(row);
  }

  function factsTokenAddress() external view override returns(address) {
    return address(factsToken);
  }

  function parentRewardShare() external view override returns(uint256) {
    return userBalances.parentSharePercent;
  }

}

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract FactsToken is ERC20,  ERC20Burnable {

    uint256 constant private _INITIAL_SUPPLY = 2000000000000 * 10 ** 18;

    constructor() ERC20("FACTIIV", "FACTS") {
        _mint(msg.sender, _INITIAL_SUPPLY);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../_opengsn/BaseRelayRecipient.sol";

/**
 Uses BaseRelayRecipient for Context
 */

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
abstract contract AccessControl is BaseRelayRecipient, IAccessControl, ERC165 {
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

pragma solidity 0.8.4; 

import "./IFactiivStore.sol";

interface IOwned {
    function owner() external view returns(address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4; 

import "./IFactiivStore.sol";

interface IFactiiv is IFactiivStore {

  event Deployed(address root, address forwarder, address factsToken);
  event ParentSharePercent(address sender, uint256 percent);
  event Deposit(address indexed from, address indexed to, uint256 amount);
  event Withdraw(address indexed user, uint256 amount);
  event BurnFrom(address indexed user, uint256 amount);
  event TransferInternal(address indexed from, address indexed to, uint256 amount);
  event UserInitialized(address indexed user, address indexed parentAddress);
  event ToForwarder(address indexed user, address forwarder, uint256 amount);

  function GOVERNANCE_ROLE() external pure returns(bytes32);
  function ATTESTOR_ROLE() external pure returns(bytes32);
  function ARBITRATOR_ROLE() external pure returns(bytes32);
  function getUserBalance(address _userAddress) external view returns(uint256);
  function getUserToParent(address _userAddress) external view returns(uint256);
  function getUserParent(address _userAddress) external view returns(address);
  function deposit(uint256 amount) external;
  function depositTo(address userAddress, uint256 amount) external;
  function toForwarder(address userAddress, uint256 amount) external;
  function withdraw(uint256 amount) external;
  function inviteUser(address userAddress) external;
  function isInitialized(address userAddress) external view returns(bool);
  function transfer(address to, uint256 amount) external;
  function payRewardTo(address userAddress, uint256 reward) external;
  function pullReward(address childAddress) external;
  function setMinimumAmount(uint256 minimum) external;
  function setParentSharePercent(uint256 percent) external;
  function createRelationshipType(string memory desc) external returns(bytes32 id);
  function updateRelationshipType(bytes32 id, string memory desc) external;
  function createAttestationType(string memory desc) external returns (bytes32 id);
  function updateAttestationType(bytes32 id, string memory desc) external;
  function createAttestation(address subject, bytes32 typeId, string memory payload) external returns (bytes32 id);
  function updateAttestation(address subject, bytes32 id, string memory payload) external;
  function createRelationship(bytes32 typeId, string memory desc, uint256 amount, address to) external returns(bytes32 id);
  function updateRelationship(bytes32 id, Lifecycle lifecycle, string memory metadata) external; 
  function deleteRelationship(bytes32 id) external;
  function arbitrationDelete(address userAddress, bytes32 id) external;
  function relationshipStage(bytes32 id) external view returns(Lifecycle lifecycle);
  function canUpdateRelationship(address updater, bytes32 id) external view returns(bool);
  // function getFunctionSignature(string memory functionString) external pure returns(bytes4 functionSelector);
  function relationshipTypeCount() external view returns(uint256 count);
  function relationshipTypeIdAtIndex(uint256 row) external view returns(bytes32 id);
  function attestationTypeCount() external view returns(uint256 count);
  function attestationTypeAtIndex(uint256 row) external view returns(bytes32 id);
  function userCount() external view returns(uint256);
  function userAtIndex(uint256 index) external view returns(address);
  function userMeta(address userAddr) external view returns(uint256 linksOut, uint256 linksIn, uint256 attestations);
  function userSendRelationshipAtIndex(address userAddr, uint256 row) external view returns(bytes32 id);
  function userReceiveRelationshipAtIndex(address userAddr, uint256 row) external view returns(bytes32 id);
  function userAttestationAtIndex(address userAddr, uint256 row) external view returns(bytes32 id);
  function relationshipCount() external view returns(uint256 count);
  function attestationCount() external view returns(uint256 count);
  function relationshipAtIndex(uint256 row) external view returns(bytes32 id);
  function attestationAtIndex(uint256 row) external view returns(bytes32 id);
  function factsTokenAddress() external view returns(address);
  function parentRewardShare() external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

library FactiivRewards {

    address private constant NULL_ADDRESS = address(0);
    uint256 private constant PRECISION = 10**18;

    event PaidReward(
        address indexed from,
        address indexed to, 
        uint256 grossAmount, 
        uint256 netAmount, 
        uint256 allocatedToParent);

    struct App {
        uint256 parentSharePercent;             // portion of rewards to share with referrer
        mapping(address => Balance) balance;    // user balance with meta data
    }

    struct Balance {
        address parent;                         // usually a referrer, receives a portion of rewards earned by referrals
        uint256 user;                           // user balance available to withdraw or spend
        uint256 toParent;                       // funds to pass on to the parent
    }

    function setParentSharePercent(App storage self, uint256 _parentShare) public{
        require(_parentShare > 0, "FactiivRewards::setParentSharePercent:Share is zero");
        self.parentSharePercent = _parentShare;
    }

    function initializeUser(App storage self, address user, address parent) public{
        Balance storage balance = self.balance[user];
        require(balance.parent == NULL_ADDRESS, "FactiivRewards::initializeUser: User is already initialized");
        balance.parent = parent;
    }

    function isInitialized(App storage self, address user) public view returns(bool) {
        return self.balance[user].parent != NULL_ADDRESS;
    }

    function balanceOf(App storage self, address user) public view returns(uint256) {
        return self.balance[user].user;
    }

    function toParent(App storage self, address user) public view returns(uint256) {
        return self.balance[user].toParent;
    }

    function userParent(App storage self, address user) public view returns(address) {
        return self.balance[user].parent;
    }

    function add(App storage self, address user, uint256 amount) public{
        Balance storage bal = self.balance[user];
        bal.user += amount;
        sendUp(self, user);
    }

    function sub(App storage self, address user, uint256 amount) public{
        Balance storage bal = self.balance[user];
        bal.user -= amount;
        sendUp(self, user);
    }

    function payReward(App storage self, address user, uint256 reward) public{
        Balance storage bal = self.balance[user];
        uint256 _toParent = (bal.parent == user) ? 0 : (reward * self.parentSharePercent) / PRECISION;
        uint256 grossReward = reward;
        reward -= _toParent;
        bal.toParent += _toParent;
        bal.user += reward;
        emit PaidReward(
            user,
            bal.parent,
            grossReward, 
            reward, 
            grossReward - reward);        
        sendUp(self, user);
    }

    function sendUp(App storage self, address user) internal {
        Balance storage bal = self.balance[user];
        address parent = bal.parent;
        if(bal.toParent > 0) pullUp(self, parent, user);
    }

    function pullUp(App storage self, address user, address referral) internal {
        Balance storage userBalance = self.balance[user];
        Balance storage referralBalance = self.balance[referral];
        uint256 referralToParent = referralBalance.toParent;
        require(referralBalance.parent == user, "FactiivRewards::pullUp: cannot pull from unrelated user");
        require(referralToParent > 0, "FactiivRewards::pullUp: Not Enough To Pull");
        uint256 toUserParent = (referralToParent * self.parentSharePercent) / PRECISION;
        if(referralToParent> 0) {
            userBalance.toParent += toUserParent;
            userBalance.user += referralToParent - toUserParent;
            referralBalance.toParent = 0;
        }

        emit PaidReward(
            referral,
            user,
            referralToParent, 
            referralToParent - toUserParent,
            toUserParent); 
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./lib/AddressSet.sol";
import "./lib/Bytes32Set.sol";
import "./interfaces/IFactiivStore.sol";

/// @notice : inheritable datastore layout and CRUD operations (WIP)

contract FactiivStore is IFactiivStore {

  using AddressSet for AddressSet.Set;
  using Bytes32Set for Bytes32Set.Set;

  bytes32 private constant NULL_BYTES32 = bytes32(0x0);
  uint256 public override nonce; 
  uint256 public override  minimumAmount; 

  struct User {
    Bytes32Set.Set senderJoinSet; 
    Bytes32Set.Set receiverJoinSet; 
    Bytes32Set.Set attestationSet; 
  }

  AddressSet.Set userSet;
  mapping(address => User)  user; 

  Bytes32Set.Set relationshipSet; 
  mapping(bytes32 => Relationship) internal relationshipInfo; 

  Bytes32Set.Set attestationSet; 
  mapping(bytes32 => Attestation) internal attestationInfo; 

  Bytes32Set.Set relationshipTypeSet; 
  mapping(bytes32 => string) public override relationshipTypeDesc; 
  
  Bytes32Set.Set attestationTypeSet; 
  mapping(bytes32 => string) public override attestationTypeDesc;
  
  /***************************
   * Master Tables
   ***************************/

  function relationship(bytes32 id) public view override returns(Relationship memory) {
    return relationshipInfo[id];
  }

  function attestation(bytes32 id) public view override returns(Attestation memory) {
    return attestationInfo[id];
  }

  function _createRelationshipType(
    address from,
    string memory desc
  ) 
    internal
    returns(
      bytes32 id
    )
  {
    id = _keyGen();
    relationshipTypeSet.insert(
      id, 
      "FactiivStore::_createRelationshipType: id exists");
    relationshipTypeDesc[id] = desc;
    emit NewRelationshipType(from, id, desc);
  }

  function _updateRelationshipType(
    address from,
    bytes32 id, 
    string memory desc
  )
    internal 
  {
    require(
      relationshipTypeSet.exists(id),
      "FactiivStore::_updateRelationship: unknown relationshipType");
    relationshipTypeDesc[id]= desc;
    emit UpdateRelationshipType(from, id, desc);
  }

  function _createAttestationType(
    address from,
    string memory desc
  )
    internal 
    returns(
      bytes32 id
    )
  {
    id = _keyGen();
    attestationTypeSet.insert(
      id, 
      "FactiivStore::_createAttestationType: id exists");
    attestationTypeDesc[id] = desc;
    emit NewAttestationType(from, id, desc);
  }

  function _updateAttestationType(
    address from,
    bytes32 id, 
    string memory desc
  )
    internal
  {
    require(
      attestationTypeSet.exists(id),
      "FactivvStore::_updateAttestionType: unknown id"
    );
    attestationTypeDesc[id] = desc;
    emit UpdateAttestionType(from, id, desc);
  }

  /***************************
   * Attestations
   ***************************/

  function _createAttestation(
    address from,
    address subject,
    bytes32 typeId,
    string memory payload
  )
    internal 
    returns (bytes32 id) 
  {
    id = _keyGen();
    Attestation storage a = attestationInfo[id];
    User storage u = user[subject];
    a.signer = from;
    a.user = subject;
    a.typeId = typeId;
    a.payload = payload;
    u.attestationSet.insert(
      id,
      "FactiivStore::_createAttestation: id exists (user)"
    );
    attestationSet.insert(
      id,
      "FactiivStore::_createAttestation: id exists"
    );
    emit NewAttestation(from, subject, id, typeId, payload);
  }

  /// @dev : attestion type is unchangeable, by design

  function _updateAttestation(
    address from,
    address subject,
    bytes32 id,
    string memory payload
  ) 
    internal 
  {
    require(
      attestationSet.exists(id),
      "FactiivStore::updateAttestion: unknown attestation"
    );
    Attestation storage a = attestationInfo[id];
    a.payload = payload;
    emit UpdateAttestation(from, subject, id, a.typeId, payload);
  }

  /***************************
   * Relationships
   ***************************/

  function _createRelationship(
    address from,
    bytes32 typeId,
    string memory desc,
    uint256 amount,
    address to
  ) 
    internal 
    returns (bytes32 id) 
  {
    require(
      relationshipTypeSet.exists(typeId),
      "FactiivStore::createRelationship: unknown typeId");
    require(
      amount > minimumAmount,
      "FactiivStore::createRelationship: amount below minimum");
    require(
      msg.sender != to, 
      "FactiivStore::createRelationship: to = sender");
    id = _keyGen();
    Stage memory s = Stage({
      lifecycle: Lifecycle.Proposed,
      metadata: ""
    });
    Relationship storage r = relationshipInfo[id];
    User storage f = user[from];
    User storage t = user[to];
    r.typeId = typeId;
    r.amount = amount;
    r.from = from;
    r.to = to;
    r.description = desc;
    r.history.push(s);
    relationshipSet.insert(id, "FactiivStore::createRelationship: id exists");
    
    // the next two checks should never fail

    t.receiverJoinSet.insert(id, "FactiivStore::createRelationship: 500 (to)");
    f.senderJoinSet.insert(id, "FactiivStore::createRelationship: 500 (from)");
    emit NewRelationship(from, to, id, typeId, desc, amount);
  }

  function _updateRelationship(
    address from,
    bytes32 id,
    Lifecycle lifecycle,
    string memory metadata
  ) 
    internal 
  {
    Relationship storage r = relationshipInfo[id];
    // require(relationshipSet.exists(id), "FactiivStore::acceptRelationship: unknown id"
    // );
    Stage memory s = Stage({
      lifecycle: lifecycle,
      metadata: metadata
    });
    r.history.push(s);

    emit UpdateRelationship(
      from,
      id,
      lifecycle,
      metadata
    );
  }

  /***************************
   * Arbitration
   ***************************/

  function _deleteRelationship(
    address from,
    bytes32 id
  ) 
    internal 
  {
    Relationship storage r = relationshipInfo[id];
    User storage f = user[r.from];
    User storage t = user[r.to];
    delete relationshipInfo[id];
    relationshipSet.remove(id, "FactiivStore::_deleteRelationship: unknown relationship id 1");
    f.senderJoinSet.remove(id, "FactiivStore::_deleteRelationship: unknown relationship id 2");
    t.receiverJoinSet.remove(id, "FactiivStore::_deleteRelationship: unknown relationship id 3");
    emit DeleteRelationship(
      from, 
      id
    );
  }

  /***************************
   * Internal
   ***************************/  

  function _keyGen() private returns (bytes32 uid) {
    nonce++;
    uid = keccak256(abi.encodePacked(address(this), nonce));
  }

  function upsertUser(address userAddress) public {
    if(!userSet.exists(userAddress)) userSet.insert(userAddress);
  }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/// @notice : inheritable datastore layout and CRUD operations (WIP)

interface IFactiivStore {

  enum Lifecycle {
    Proposed,
    Accepted,
    Closed,
    toRated,
    fromRated
  }

  struct Relationship {
    bytes32 typeId; 
    string description; 
    uint256 amount; 
    address from; 
    address to; 
    Stage[] history; 
    address arbitrator;
  }
  
  struct Stage {
    Lifecycle lifecycle; 
    string metadata; 
  }

  struct Attestation {
    address signer;
    address user; 
    bytes32 typeId;
    string payload; 
  }

  event NewRelationshipType(
    address indexed sender,
    bytes32 indexed id,
    string description
  );
  event UpdateRelationshipType(
    address indexed sender,
    bytes32 indexed id, 
    string desc
  );
  event NewAttestationType(
    address indexed sender,
    bytes32 indexed id,
    string description
  );
  event UpdateAttestionType(
    address indexed sender, 
    bytes32 indexed id, 
    string desc
  );
  event NewAttestation(
    address indexed signer,
    address indexed user,
    bytes32 indexed id,
    bytes32 typeId,
    string payload
  );
  event UpdateAttestation(
    address indexed signer,
    address indexed user,
    bytes32 indexed id,
    bytes32 typeId,
    string payload
  );
  event NewRelationship(
    address indexed from,
    address indexed to,
    bytes32 indexed id,
    bytes32 typeId,
    string desc,
    uint256 amount
  );
  event UpdateRelationship(
    address indexed from,
    bytes32 indexed id,
    Lifecycle lifecycle,
    string metadata
  );
  event DeleteRelationship(
      address indexed from, 
      bytes32 indexed id
  );
  event SetMinimum(
    address sender, 
    uint256 minimumAmount
  );

  function nonce() external view returns(uint256);
  function minimumAmount() external view returns(uint256);
  function relationship(bytes32) external view returns(Relationship memory);
  function attestation(bytes32) external view returns(Attestation calldata);
  function relationshipTypeDesc(bytes32) external view returns(string memory);
  function attestationTypeDesc(bytes32) external view returns(string memory);
}

// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;

import "./IRelayRecipient.sol";

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    function trustedForwarder() public virtual view returns (address){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

library Bytes32Set {
    
    struct Set {
        mapping(bytes32 => uint) keyPointers;
        bytes32[] keyList;
    }
    
    /**
     * @notice insert a key. 
     * @dev duplicate keys are not permitted.
     * @param self storage pointer to a Set. 
     * @param key value to insert.
     */
    function insert(Set storage self, bytes32 key, string memory error) internal {
        require(!exists(self, key), error);
        self.keyPointers[key] = self.keyList.length;
        self.keyList.push(key);
    }

    /**
     * @notice remove a key.
     * @dev key to remove must exist. 
     * @param self storage pointer to a Set.
     * @param key value to remove.
     */
    function remove(Set storage self, bytes32 key, string memory error) internal {
        require(exists(self, key), error);
        uint last = count(self) - 1;
        uint rowToReplace = self.keyPointers[key];
        if(rowToReplace != last) {
            bytes32 keyToMove = self.keyList[last];
            self.keyPointers[keyToMove] = rowToReplace;
            self.keyList[rowToReplace] = keyToMove;
        }
        delete self.keyPointers[key];
        self.keyList.pop();
    }

    /**
     * @notice count the keys.
     * @param self storage pointer to a Set. 
     */    
    function count(Set storage self) internal view returns(uint) {
        return(self.keyList.length);
    }
    
    /**
     * @notice check if a key is in the Set.
     * @param self storage pointer to a Set.
     * @param key value to check. 
     * @return bool true: Set member, false: not a Set member.
     */
    function exists(Set storage self, bytes32 key) internal view returns(bool) {
        if(self.keyList.length == 0) return false;
        return self.keyList[self.keyPointers[key]] == key;
    }

    /**
     * @notice fetch a key by row (enumerate).
     * @param self storage pointer to a Set.
     * @param index row to enumerate. Must be < count() - 1.
     */    
    function keyAtIndex(Set storage self, uint index) internal view returns(bytes32) {
        return self.keyList[index];
    }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

/**
 * @notice Key sets with enumeration and delete. Uses mappings for random
 * and existence checks and dynamic arrays for enumeration. Key uniqueness is enforced. 
 * @dev Sets are unordered. Delete operations reorder keys. All operations have a 
 * fixed gas cost at any scale, O(1). 
 * author: Rob Hitchens
 */

library AddressSet {
    
    struct Set {
        mapping(address => uint) keyPointers;
        address[] keyList;
    }

    /**
     * @notice insert a key. 
     * @dev duplicate keys are not permitted.
     * @param self storage pointer to a Set. 
     * @param key value to insert.
     */    
    function insert(Set storage self, address key) internal {
        require(!exists(self, key), "AddressSet: key already exists in the set.");
        self.keyPointers[key] = self.keyList.length;
        self.keyList.push(key);
    }

    /**
     * @notice remove a key.
     * @dev key to remove must exist. 
     * @param self storage pointer to a Set.
     * @param key value to remove.
     */    
    function remove(Set storage self, address key) internal {
        require(exists(self, key), "AddressSet: key does not exist in the set.");
        uint last = count(self) - 1;
        uint rowToReplace = self.keyPointers[key];
        if(rowToReplace != last) {
            address keyToMove = self.keyList[last];
            self.keyPointers[keyToMove] = rowToReplace;
            self.keyList[rowToReplace] = keyToMove;
        }
        delete self.keyPointers[key];
        self.keyList.pop();
    }

    /**
     * @notice count the keys.
     * @param self storage pointer to a Set. 
     */       
    function count(Set storage self) internal view returns(uint) {
        return(self.keyList.length);
    }

    /**
     * @notice check if a key is in the Set.
     * @param self storage pointer to a Set.
     * @param key value to check. 
     * @return bool true: Set member, false: not a Set member.
     */  
    function exists(Set storage self, address key) internal view returns(bool) {
        if(self.keyList.length == 0) return false;
        return self.keyList[self.keyPointers[key]] == key;
    }

    /**
     * @notice fetch a key by row (enumerate).
     * @param self storage pointer to a Set.
     * @param index row to enumerate. Must be < count() - 1.
     */      
    function keyAtIndex(Set storage self, uint index) internal view returns(address) {
        return self.keyList[index];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal virtual view returns (bytes calldata);

    function versionRecipient() external virtual view returns (string memory);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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