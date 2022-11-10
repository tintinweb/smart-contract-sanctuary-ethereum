/**
 *Submitted for verification at Etherscan.io on 2022-11-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*
'########::'########:'########::'##::::'##:
 ##.... ##: ##.....:: ##.... ##: ##:::: ##:
 ##:::: ##: ##::::::: ##:::: ##: ##:::: ##:
 ########:: ######::: ########:: ##:::: ##:
 ##.... ##: ##...:::: ##.. ##::: ##:::: ##:
 ##:::: ##: ##::::::: ##::. ##:: ##:::: ##:
 ########:: ########: ##:::. ##:. #######::
........:::........::..:::::..:::.......:::
*/

interface IModule {
  function getModule(uint module_) external view returns (address);
}

/**
 * @notice Permission system trying to avoid centralized power
 */
contract Roles {
  /**
   * @notice Add or remove every role
   */
  address private _superAdminRole;

  /**
   * @notice The address of the votation system
   */
  address private _votationContract;

  /**
   * @notice FALSE flag
   */
  uint128 public constant FALSE = 0;

  /**
   * @notice TRUE flag
   */
  uint128 public constant TRUE = 1;

  /**
   * @notice Amount of admins
   */
  uint256 private amountOfAdmins;

  /**
   * @notice Module Manager instance
   */
  IModule moduleManager;

  /**
   * @notice Is an address an admin?
   */
  mapping(address => uint128) private adminRole;

  /**
   * @notice Is an address a moderator?
   */
  mapping(address => uint128) private moderatorRole;

  /**
   * @notice Is an address a verified user?
   */
  mapping(address => uint128) private verifiedUserRole;

  /**
   * @notice Is an address a user?
   */
  mapping(address => uint128) private userRole;

  /**
   * @notice Fan token register
   */
  mapping(address => uint128) private fanTokenRole;

  //! --------------------------------------------------------------------------- EVENTS ---------------------------------------------------------------------------

  /**
   * @notice If this contract changes superadminship
   */
  event SuperOwnershipTransferred(address previousOwner, address newOwner);

  /**
   * @notice When an admin is added
   * @param authority The authority that added a new admin
   * @param newAdmin The new admin
   */
  event AddedAdmin(address authority, address newAdmin);

  /**
   * @notice When a moderator is added
   * @param authority The authority that added a new moderator
   * @param newModerator The new moderator
   */
  event AddedModerator(address authority, address newModerator);

  /**
   * @notice When a verified user is added
   * @param authority The authority that added a new verified user
   * @param newVerifiedUser The new verified user
   */
  event AddedVerifiedUser(address authority, address newVerifiedUser);

  /**
   * @notice When a user is added
   * @param authority The authority that added a new user
   * @param newUser The new user
   */
  event AddedUser(address authority, address newUser);

  /**
   * @notice When a fan token is added
   * @param authority The admin that added a fan token
   * @param newFanToken The added fan token address
   */
  event AddedFanToken(address authority, address newFanToken);

  /**
   * @notice When an admin is removed
   * @param authority The authority that removed an admin
   * @param oldAdmin The old admin
   */
  event RemovedAdmin(address authority, address oldAdmin);

  /**
   * @notice When a moderador is removed
   * @param authority The authority that removed an moderator
   * @param oldModerator The old moderator
   */
  event RemovedModerator(address authority, address oldModerator);

  /**
   * @notice When a verified user is removed
   * @param authority The authority that removed a verified user
   * @param oldVerifiedUser The old verified user
   */
  event RemovedVerifiedUser(address authority, address oldVerifiedUser);

  /**
   * @notice When a user is removed
   * @param authority The authority that removed a user
   * @param oldUser The old user
   */
  event RemovedUser(address authority, address oldUser);

  /**
   * @notice When a fan token is removed
   * @param authority The admin that removed a fan token
   * @param oldFanToken The removed fan token address
   */
  event RemovedFanToken(address authority, address oldFanToken);

  /**
   * @notice The constructor that makes the msg.sender the super admin
   */
  constructor(address module_) {
    _transferSuperAdminship(msg.sender);
    adminRole[msg.sender] = TRUE;
    amountOfAdmins++;
    moduleManager = IModule(module_);
    _votationContract = moduleManager.getModule(3);
  }

  //! --------------------------------------------------------------------------- MODIFIERS ---------------------------------------------------------------------------

  /**
   * @notice Action restricted to superadmins
   */
  modifier onlySuperAdmin() {
    require(msg.sender == superAdmin(), "E101");
    _;
  }

  /**
   * @notice Action restricted to admins
   */
  modifier onlyAdmins() {
    require((isAdmin(msg.sender)) || (msg.sender == superAdmin()), "E102");
    _;
  }

  /**
   * @notice Action restricted to moderators
   */
  modifier onlyModerators() {
    require(
      (isModerator(msg.sender)) ||
        (isAdmin(msg.sender)) ||
        (msg.sender == superAdmin()),
      "E103"
    );
    _;
  }

  /**
   * @notice Action restricted to votation module
   */
  modifier onlyVotation() {
    require(msg.sender == _votationContract, "E104");
    _;
  }

  //! --------------------------------------------------------------------------- ADMINSHIP METHODS ---------------------------------------------------------------------------

  /**
   * @notice Renounce super adminship
   */
  function renounceSuperAdminship() public virtual onlySuperAdmin {
    _transferSuperAdminship(address(0));
  }

  /**
   * @notice Transfer super adminship
   * @param newSuperAdmin The new super admin
   */
  function transferSuperAdminship(address newSuperAdmin)
    public
    virtual
    onlySuperAdmin
  {
    require(newSuperAdmin != address(0));
    _transferSuperAdminship(newSuperAdmin);
  }

  /**
   * @notice Really transfer super adminship
   * @param newSuperAdmin The new super admin
   * @dev internal
   */
  function _transferSuperAdminship(address newSuperAdmin) internal virtual {
    address oldSuperAdmin = _superAdminRole;
    _superAdminRole = newSuperAdmin;
    emit SuperOwnershipTransferred(oldSuperAdmin, newSuperAdmin);
  }

  //! --------------------------------------------------------------------------- ADDS ---------------------------------------------------------------------------

  /**
   * @notice Add a new admin
   * @param newAdmin The new admin
   */
  function addAdmin(address newAdmin) public virtual onlyVotation {
    adminRole[newAdmin] = TRUE;
    amountOfAdmins++;
    emit AddedAdmin(msg.sender, newAdmin);
  }

  /**
   * @notice Add a moderator
   * @param newModerator The new moderator
   * @dev Only admins can execute this function
   */
  function addModerator(address newModerator) public virtual onlyAdmins {
    moderatorRole[newModerator] = TRUE;
    emit AddedModerator(msg.sender, newModerator);
  }

  /**
   * @notice Add a user
   * @param newUser The new user
   * @dev Only moderators can execute this function
   */
  function addUser(address newUser) public virtual onlyModerators {
    userRole[newUser] = TRUE;
    emit AddedUser(msg.sender, newUser);
  }

  /**
   * @notice Add a verified user
   * @param newVerifiedUser The new moderator
   * @dev Only moderators and admins can execute this function
   */
  function addVerifiedUser(address newVerifiedUser)
    public
    virtual
    onlyModerators
  {
    if (isUser(newVerifiedUser)) userRole[newVerifiedUser] = FALSE;
    verifiedUserRole[newVerifiedUser] = TRUE;
    emit AddedVerifiedUser(msg.sender, newVerifiedUser);
  }

  /**
   * @notice Add a fan token
   * @param newFanToken The fan token to be added
   */
  function addFanToken(address newFanToken) public virtual onlyModerators {
    fanTokenRole[newFanToken] = TRUE;
    emit AddedFanToken(msg.sender, newFanToken);
  }

  //! --------------------------------------------------------------------------- REMOVES ---------------------------------------------------------------------------

  /**
   * @notice Remove an old admin
   * @param oldAdmin The old admin
   * @dev This function is only called by this contract
   */
  function removeAdmin(address oldAdmin) public virtual onlyVotation {
    adminRole[oldAdmin] = FALSE;
    amountOfAdmins--;
    emit RemovedAdmin(msg.sender, oldAdmin);
  }

  /**
   * @notice Remove a moderator
   * @param oldModerator The old moderator
   * @dev Only admins can execute this function
   */
  function removeModerator(address oldModerator) public virtual onlyAdmins {
    moderatorRole[oldModerator] = FALSE;
    emit RemovedModerator(msg.sender, oldModerator);
  }

  /**
   * @notice Remove a user
   * @param oldUser The old user
   * @dev Only moderators can execute this function
   */
  function removeUser(address oldUser) public virtual onlyModerators {
    userRole[oldUser] = FALSE;
    emit RemovedUser(msg.sender, oldUser);
  }

  /**
   * @notice Remove verified user
   * @param oldVerifiedUser The old verified user
   * @dev Only moderators and admins can execute this function
   */
  function removeVerifiedUser(address oldVerifiedUser)
    public
    virtual
    onlyModerators
  {
    verifiedUserRole[oldVerifiedUser] = FALSE;
    emit RemovedVerifiedUser(msg.sender, oldVerifiedUser);
  }

  /**
   * @notice Remove a fan token
   * @param oldFanToken The fan token to be removed
   */
  function removeFanToken(address oldFanToken) public virtual onlyModerators {
    fanTokenRole[oldFanToken] = FALSE;
    emit RemovedFanToken(msg.sender, oldFanToken);
  }

  //! --------------------------------------------------------------------------- SETERS ---------------------------------------------------------------------------

  /**
   * @notice Changes the votation contract, this affects the modifier
   * @param votation_ The new address
   */
  function setVotingSC(address votation_) public onlySuperAdmin {
    _votationContract = votation_;
  }

  //! --------------------------------------------------------------------------- GETERS ---------------------------------------------------------------------------

  /**
   * @notice Returns if the 'admin' given is admin
   * @param user_ The admin
   * @return true if is verified, false otherwise
   */
  function isAdmin(address user_) public view virtual returns (bool) {
    return adminRole[user_] == TRUE ? true : false;
  }

  /**
   * @notice Returns if the 'moderator' given is moderator
   * @param user_ The moderator
   * @return true if is verified, false otherwise
   */
  function isModerator(address user_) public view virtual returns (bool) {
    return moderatorRole[user_] == TRUE ? true : false;
  }

  /**
   * @notice Returns if the user given is verified
   * @param user_ The user
   * @return true if is verified, false otherwise
   */
  function isVerifiedUser(address user_) public view virtual returns (bool) {
    return verifiedUserRole[user_] == TRUE ? true : false;
  }

  /**
   * @notice Returns if the user has user role
   * @param user_ The user
   * @return true if is user, false otherwise
   */
  function isUser(address user_) public view virtual returns (bool) {
    return (userRole[user_] == TRUE) ? true : false;
  }

  /**
   * @notice Returns if the fanToken has fanToken role
   * @param fanToken_ The fan token address
   * @return true if is , false otherwise
   */
  function isFanToken(address fanToken_) public view virtual returns (bool) {
    return (fanTokenRole[fanToken_] == TRUE) ? true : false;
  }

  /**
   * @notice Gets the amount of admins
   * @return The amount of admins
   */
  function getAdminCount() public view returns (uint256) {
    return amountOfAdmins;
  }

  /**
   * @notice Returns the address of the superAdmin if there is one
   * @return the address of the super admin
   */
  function superAdmin() public view virtual returns (address) {
    return _superAdminRole;
  }
}