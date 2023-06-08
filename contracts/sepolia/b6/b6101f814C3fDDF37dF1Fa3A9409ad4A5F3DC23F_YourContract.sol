// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Defining custom errors for better error handling
error NoValueSent();
error InsufficientFundsInContract(uint256 requested, uint256 available);
error NoActiveFlowForCreator(address creator);
error InsufficientInFlow(uint256 requested, uint256 available);
error EtherSendingFailed(address recipient);
error LengthsMismatch();
error CapCannotBeZero();
error InvalidCreatorAddress();
error CreatorAlreadyExists();
error ContractIsStopped();
error MaxCreatorsReached();
error AccessDenied();
error MismatchedTokenAndCapArrays();
error InvalidTokenAddress();
error DuplicateUserNotAllowed();
error TokenAddressIsInActiveUse(address tokenAddress);

contract YourContract is AccessControl, ReentrancyGuard {



    // Fixed cycle and max creators
    uint256 immutable CYCLE = 30 minutes;
    uint256 immutable MAXCREATORS = 25;

    // Emergency mode variable
    bool public stopped = false;

    // Primary admin for remaining balances
    address private primaryAdmin;

    // Modifier to check for admin permissions
    modifier onlyAdmin() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert AccessDenied();
        _;
    }


       // Constructor to setup admin role
    constructor(address _primaryAdmin) {
        _setupRole(DEFAULT_ADMIN_ROLE, _primaryAdmin);
        primaryAdmin = _primaryAdmin;

    }


    // Function to modify admin roles
    function modifyAdminRole(address adminAddress, bool shouldGrant) public onlyAdmin {
        if (shouldGrant) {
            grantRole(DEFAULT_ADMIN_ROLE, adminAddress);
        } else {
            revokeRole(DEFAULT_ADMIN_ROLE, adminAddress);
        }
    }

    // Struct to store information about creator's flow
    struct CreatorFlowInfo {
        uint256 cap; // Maximum amount of funds that can be withdrawn in a cycle (in wei)
        uint256 last; // The timestamp of the last withdrawal
    }

    // Adding a new struct for ERC20 creator flow information
     struct ERC20CreatorFlowInfo {
        mapping(address => uint256) caps;
        uint256 last;
    }

    // Mapping to store the flow info of each creator
    mapping(address => CreatorFlowInfo) public flowingCreators;
    // Mapping to store the index of each creator in the activeCreators array
    mapping(address => uint256) public creatorIndex;
    // Array to store the addresses of all active creators
    address[] public activeCreators;

    // Adding new mapping to store ERC20 creator flow information
    mapping(address => ERC20CreatorFlowInfo) public erc20FlowingCreators;
    // Mapping to store the index of each ERC20 creator in the erc20ActiveCreators array
    mapping(address => uint256) public erc20CreatorIndex;
    // Array to store the addresses of all active ERC20 creators
    address[] public erc20ActiveCreators;

    mapping(address => bool) public uniqueTokenAddresses;


    // Declare events to log various activities
    event FundsReceived(address indexed from, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount, string reason);
    event CreatorAdded(address indexed to, uint256 amount, uint256 cycle);
    event CreatorUpdated(address indexed to, uint256 amount, uint256 cycle);
    event CreatorRemoved(address indexed to);
    event AgreementDrained(address indexed to, uint256 amount);

    // Adding new events for ERC20 support
    event ERC20FundsReceived(address indexed token, address indexed from, uint256 amount);
    event ERC20Withdrawn(address indexed token, address indexed to, uint256 amount, string reason);
    event ERC20CreatorAdded(address indexed token, address indexed to, uint256 amount, uint256 cycle);
    event ERC20CreatorUpdated(address indexed token, address indexed to, uint256 amount, uint256 cycle);
    event ERC20CreatorRemoved(address indexed token, address indexed to);
    event ERC20AgreementDrained(address indexed token, address indexed to, uint256 amount);
    event ERC20Rescued(address indexed token, address indexed to, uint256 amount);

    // Check if a flow for a creator is active
    modifier isFlowActive(address _creator) {
        if (flowingCreators[_creator].cap == 0) revert NoActiveFlowForCreator(_creator);
        _;
    }

    // Check if an ERC20 flow for a creator is active
    modifier isERC20FlowActive(address _creator, address _token) {
        if (erc20FlowingCreators[_creator].caps[_token] == 0) revert NoActiveFlowForCreator(_creator);
        _;
    }

    // Check if the contract is stopped
    modifier stopInEmergency() {
        if (stopped) revert ContractIsStopped();
        _;
    }

    //Fund contract
    function fundContract() public payable {
        if (msg.value == 0) revert NoValueSent();
        emit FundsReceived(msg.sender, msg.value);
    }

    //Fund contract with ERC-20 tokens
    function fundContractERC20(address _token, uint256 _amount) public {
        if (_amount == 0) revert NoValueSent();
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        emit ERC20FundsReceived(_token, msg.sender, _amount);
    }

    // Enable or disable emergency mode
    function emergencyMode(bool _enable) public onlyAdmin {
        stopped = _enable;
    }

    // Get all creators' data.
    function allCreatorsData(address[] calldata _creators) public view returns (CreatorFlowInfo[] memory) {
        uint256 creatorLength = _creators.length;
        CreatorFlowInfo[] memory result = new CreatorFlowInfo[](creatorLength);
        for (uint256 i = 0; i < creatorLength; ++i) {
            address creatorAddress = _creators[i];
            result[i] = flowingCreators[creatorAddress];
        }
        return result;
    }

    // Get the available amount for a creator.
    function availableCreatorAmount(address _creator) public view isFlowActive(_creator) returns (uint256) {
        CreatorFlowInfo memory creatorFlow = flowingCreators[_creator];
        uint256 timePassed = block.timestamp - creatorFlow.last;
        uint256 cycleDuration = CYCLE;

        if (timePassed < cycleDuration) {
            uint256 availableAmount = (timePassed * creatorFlow.cap) / cycleDuration;
            return availableAmount;
        } else {
            return creatorFlow.cap;
        }
    }

   function availableCreatorAmountERC20(address _creator, address _token) public view isERC20FlowActive(_creator, _token) returns (uint256) {
        ERC20CreatorFlowInfo storage creatorERC20Flow = erc20FlowingCreators[_creator];

        uint256 cap = creatorERC20Flow.caps[_token];
        if (cap == 0) revert CapCannotBeZero();

        uint256 timePassed = block.timestamp - creatorERC20Flow.last;

        if (timePassed < CYCLE) {
            uint256 availableAmount = (timePassed * cap) / CYCLE;
            return availableAmount;
        } else {
            return cap;
        }
    }

    // Add a new creator's flow. No more than 25 creators are allowed.
    function addCreatorFlow(address payable _creator, uint256 _cap) public onlyAdmin {
        // Check for maximum creators.
        if (activeCreators.length >= MAXCREATORS) revert MaxCreatorsReached();
        
        validateCreatorInput(_creator, _cap);
        flowingCreators[_creator] = CreatorFlowInfo(_cap, block.timestamp);
        activeCreators.push(_creator);
        creatorIndex[_creator] = activeCreators.length - 1;
        emit CreatorAdded(_creator, _cap, CYCLE);
    }

      // Add a batch of creators.
  function addBatch(address[] memory _creators, uint256[] memory _caps) public onlyAdmin {
    uint256 cLength = _creators.length;
    if (cLength != _caps.length) revert LengthsMismatch();
    for (uint256 i = 0; i < cLength; ) {
      addCreatorFlow(payable(_creators[i]), _caps[i]);
      unchecked {
        ++i;
      }
    }
  }

    // Add a new creator's ERC20 based flow.
    function addCreatorERC20Flow(
    address payable _creator,
    address[] memory _tokenAddresses,
    uint256[] memory _caps
) external onlyAdmin {

    if (erc20ActiveCreators.length >= MAXCREATORS) revert MaxCreatorsReached();
    if (_tokenAddresses.length != _caps.length) revert LengthsMismatch();

    for (uint256 i = 0; i < _tokenAddresses.length; ++i) {
        if (_tokenAddresses[i] == address(0)) revert InvalidTokenAddress();
        if (_caps[i] == 0) revert CapCannotBeZero();
        if (erc20FlowingCreators[_creator].caps[_tokenAddresses[i]] != 0) revert DuplicateUserNotAllowed();

        
        erc20FlowingCreators[_creator].caps[_tokenAddresses[i]] = _caps[i];
        emit ERC20CreatorAdded(_tokenAddresses[i], _creator, _caps[i], CYCLE);
    }

    if (erc20CreatorIndex[_creator] == 0 && _creator != erc20ActiveCreators[0]) {
        erc20FlowingCreators[_creator].last = block.timestamp;
        erc20ActiveCreators.push(_creator);
        erc20CreatorIndex[_creator] = erc20ActiveCreators.length - 1;
    }
}

function addBatchERC20Creators(
    address[] memory _creators,
    address[][] memory _tokenAddresses,
    uint256[][] memory _caps
) public onlyAdmin {
    uint256 cLength = _creators.length;
    if (cLength != _caps.length && cLength != _tokenAddresses.length) revert LengthsMismatch();
    
    for (uint256 i = 0; i < cLength; ++i) {

        if (_tokenAddresses[i].length != _caps[i].length) revert MismatchedTokenAndCapArrays();
        
        for (uint256 j = 0; j < _tokenAddresses[i].length; ++j) {
            if (_tokenAddresses[i][j] == address(0)) revert InvalidTokenAddress();
            if (_caps[i][j] == 0) revert CapCannotBeZero();
            
            erc20FlowingCreators[_creators[i]].caps[_tokenAddresses[i][j]] = _caps[i][j];
            emit ERC20CreatorAdded(_tokenAddresses[i][j], _creators[i], _caps[i][j], CYCLE);
        }
        
        erc20FlowingCreators[_creators[i]].last = block.timestamp;
        erc20ActiveCreators.push(_creators[i]);
        erc20CreatorIndex[_creators[i]] = erc20ActiveCreators.length - 1;
    }
}
// Validate the input for a creator.
    function validateCreatorInput(address payable _creator, uint256 _cap) internal view {
        if (_creator == address(0)) revert InvalidCreatorAddress();
        if (_cap == 0) revert CapCannotBeZero();
        if (flowingCreators[_creator].cap > 0) revert CreatorAlreadyExists();
    }

    // Update a creator's flow cap and cycle.
    function updateCreatorFlowCapCycle(
        address payable _creator,
        uint256 _newCap
    ) public onlyAdmin isFlowActive(_creator) {
        if (_newCap == 0) revert CapCannotBeZero();

        CreatorFlowInfo storage creatorFlow = flowingCreators[_creator];

        // Set the new cap without calculating the used portion in the current cycle
        creatorFlow.cap = _newCap;

        uint256 timestamp = block.timestamp;
        uint256 timePassed = timestamp - creatorFlow.last;

        // Only change the cycle start timestamp if the new cycle is less than the time passed since the last withdrawal
        if (CYCLE < timePassed) {
            creatorFlow.last = timestamp - (CYCLE);
        }

        emit CreatorUpdated(_creator, _newCap, CYCLE);
    }

    // Update a creator's ERC20 flow cap and cycle.
      function updateCreatorERC20FlowCapCycle(
        address payable _creator,
        address _token,
        uint256 _newCap
    ) external onlyAdmin isERC20FlowActive(_creator, _token) {
        if (_newCap == 0) revert CapCannotBeZero();

        ERC20CreatorFlowInfo storage creatorERC20Flow = erc20FlowingCreators[_creator];

        // Set the new cap without calculating the used portion in the current cycle
        creatorERC20Flow.caps[_token] = _newCap;

        uint256 timestamp = block.timestamp;
        uint256 timePassed = timestamp - creatorERC20Flow.last;

        // Only change the cycle start timestamp if the new cycle is less than the time passed since the last withdrawal
        if (CYCLE < timePassed) {
            creatorERC20Flow.last = timestamp - (CYCLE);
        }

        emit ERC20CreatorUpdated(_token, _creator, _newCap, CYCLE);
    }

    function removeCreatorFlow(address _creator) public onlyAdmin isFlowActive(_creator) {
        uint256 creatorIndexToRemove = creatorIndex[_creator];
        address lastCreator = activeCreators[activeCreators.length - 1];

        // Check if the creator to be removed is the last one in the list
        if (_creator != lastCreator) {
            activeCreators[creatorIndexToRemove] = lastCreator;
            creatorIndex[lastCreator] = creatorIndexToRemove;
        }

        activeCreators.pop();

        delete flowingCreators[_creator];
        delete creatorIndex[_creator];

        emit CreatorRemoved(_creator);
    }

    // Remove a creator's ERC20 flow.
   function removeCreatorERC20Flow(address _creator, address _token) external onlyAdmin isERC20FlowActive(_creator, _token) {

    if (erc20FlowingCreators[_creator].caps[_token] == 0) revert CapCannotBeZero();

    // Remove the given token's cap for the given creator
    delete erc20FlowingCreators[_creator].caps[_token];

    // Check if the creator has any other active token flows
    bool hasOtherActiveTokenFlows = false;
    for (uint256 i = 0; i < erc20ActiveCreators.length; i++) {
        if (erc20FlowingCreators[_creator].caps[erc20ActiveCreators[i]] > 0) {
            hasOtherActiveTokenFlows = true;
            break;
        }
    }

    // If the creator doesn't have any other active token flows, remove them from erc20ActiveCreators array and delete the erc20CreatorIndex entry
    if (!hasOtherActiveTokenFlows) {
        uint256 erc20CreatorIndexToRemove = erc20CreatorIndex[_creator];
        address lastERC20Creator = erc20ActiveCreators[erc20ActiveCreators.length - 1];

        // Check if the creator to be removed is the last one in the list
        if (_creator != lastERC20Creator) {
            erc20ActiveCreators[erc20CreatorIndexToRemove] = lastERC20Creator;
            erc20CreatorIndex[lastERC20Creator] = erc20CreatorIndexToRemove;
        }

        erc20ActiveCreators.pop();
        delete erc20CreatorIndex[_creator];
    }

    emit ERC20CreatorRemoved(_token, _creator);
}
    // Creator withdraws funds.
    function flowWithdraw(
        uint256 _amount,
        string memory _reason
    ) public isFlowActive(msg.sender) nonReentrant stopInEmergency {
        CreatorFlowInfo storage creatorFlow = flowingCreators[msg.sender];

        uint256 totalAmountCanWithdraw = availableCreatorAmount(msg.sender);
        if (totalAmountCanWithdraw < _amount) revert InsufficientInFlow(_amount, totalAmountCanWithdraw);

        uint256 creatorflowLast = creatorFlow.last;
        uint256 timestamp = block.timestamp;
        uint256 cappedLast = timestamp - CYCLE;
        if (creatorflowLast < cappedLast) {
            creatorflowLast = cappedLast;
        }

        uint256 contractFunds = address(this).balance;
        if (contractFunds < _amount) revert InsufficientFundsInContract(_amount, contractFunds);

        (bool sent, ) = msg.sender.call{value: _amount, gas: 21000}(""); // Considered reasonable amount of gas limit for simple eth transfers, assuming recipient is an EOA
        if (!sent) revert EtherSendingFailed(msg.sender);

        creatorFlow.last = creatorflowLast + (((timestamp - creatorflowLast) * _amount) / totalAmountCanWithdraw);

        emit Withdrawn(msg.sender, _amount, _reason);
    }

    // Creator withdraws ERC-20 tokens.
    function erc20Withdraw(
        address _token,
        uint256 _amount,
        string memory _reason
    ) external nonReentrant stopInEmergency isERC20FlowActive(msg.sender, _token) {
        uint256 totalAmountCanWithdraw = availableCreatorAmountERC20(msg.sender, _token);
        if (totalAmountCanWithdraw < _amount) revert InsufficientInFlow(_amount, totalAmountCanWithdraw);

        uint256 creatorERC20FlowLast = erc20FlowingCreators[msg.sender].last;
        uint256 timestamp = block.timestamp;
        uint256 cappedLast = timestamp - CYCLE;
        if (creatorERC20FlowLast < cappedLast) {
            creatorERC20FlowLast = cappedLast;
        }

        uint256 tokenBalance = IERC20(_token).balanceOf(address(this));
        if (tokenBalance < _amount) revert InsufficientFundsInContract(_amount, tokenBalance);

        IERC20(_token).transfer(msg.sender, _amount);

        erc20FlowingCreators[msg.sender].last = creatorERC20FlowLast + (((timestamp - creatorERC20FlowLast) * _amount) / totalAmountCanWithdraw);

        emit ERC20Withdrawn(_token, msg.sender, _amount, _reason);
    }


// Drain the agreement to the current primary admin
function drainAgreement() public onlyAdmin nonReentrant {
    // Ether Drain
    uint256 remainingBalance = address(this).balance;
    if (remainingBalance > 0) {
        (bool sent, ) = primaryAdmin.call{value: remainingBalance}("");
        if (!sent) revert EtherSendingFailed(primaryAdmin);

        emit AgreementDrained(primaryAdmin, remainingBalance);
    }
    
    // Clear uniqueTokenAddresses mapping before populating it
    for (uint256 i = 0; i < activeCreators.length; ++i) {
        uniqueTokenAddresses[activeCreators[i]] = false;
    }
    
    // Collect unique token addresses
    for (uint256 i = 0; i < erc20ActiveCreators.length; ++i) {
        address creator = erc20ActiveCreators[i];
        for (uint256 j = 0; j < activeCreators.length; ++j) {
            address token = activeCreators[j];
            if (erc20FlowingCreators[creator].caps[token] > 0 && !uniqueTokenAddresses[token]) {
                uniqueTokenAddresses[token] = true;
            }
        }
    }
}

// Function to rescue ERC20 tokens sent by mistake
   function rescueERC20Tokens(address _tokenAddress, uint256 _amount, address _recipient) public onlyAdmin {
        // Check if the given token address is not in the active ERC20 creators list for any creator
        for (uint256 i = 0; i < erc20ActiveCreators.length; ++i) {
            address creatorAddress = erc20ActiveCreators[i];
            if (erc20FlowingCreators[creatorAddress].caps[_tokenAddress] > 0) revert TokenAddressIsInActiveUse(_tokenAddress);
        }
          
        // Check if the amount to rescue is less than or equal to the contract's token balance
        uint256 tokenBalance = IERC20(_tokenAddress).balanceOf(address(this));
        if (tokenBalance < _amount) revert InsufficientFundsInContract(_amount, tokenBalance);

        // Transfer the tokens to the recipient address
        IERC20(_tokenAddress).transfer(_recipient, _amount);

        emit ERC20Rescued(_tokenAddress, _recipient, _amount);
    }

    // Fallback function to receive ether
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

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
                        Strings.toHexString(account),
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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
        return a > b ? a : b;
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
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

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
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}