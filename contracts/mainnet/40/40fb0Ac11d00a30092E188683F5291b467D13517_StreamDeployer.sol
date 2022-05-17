//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Stream.sol";

/// @title The Stream Deployer Contract for Orgs
/// @author nowonder, jaxcoder, qedk, supriyaamisshra
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
contract StreamDeployer is Ownable {

    /// @dev emitted when a new org is created.
    event OrganizationDeployed(
        address indexed orgAddress,
        address indexed ownerAddress,
        string organizationName
    );

    address[] public organizations;

    constructor (address _owner) {
        transferOwnership(_owner);
    }

    /// @dev deploys a stream factory contract for a specified organization.
    /// @param _orgName the name of the organization
    /// @param _owner the owner address for the org
    /// @param _addresses any addresses you want to have a stream on deploy
    /// @param _caps the caps for the addresses
    /// @param _frequency the frequency for the addresses
    /// @param _startsFull the bool for each address to start full or not
    /// @param _tokenAddress the stream token address for the org
    /// @param _name the stream name for the org
    function deployOrganization(
        string memory _orgName,
        string memory _orgLogoURI,
        string memory _orgDescription,
        address _owner,
        address[] memory _addresses,
        uint256[] memory _caps,
        uint256[] memory _frequency,
        bool[] memory _startsFull,
        string[] memory _name,
        IERC20 _tokenAddress
    ) external {
        MultiStream deployedOrganization = new MultiStream(
            _orgName,
            _orgLogoURI,
            _orgDescription,
            _owner,
            _addresses,
            _caps,
            _frequency,
            _startsFull,
            _name,
            address(_tokenAddress)
        );
        
        organizations.push(address(deployedOrganization));

        emit OrganizationDeployed(
            address(deployedOrganization),
            _owner,
            _orgName
        );

    }

    /// @dev gets a page of organizations
    /// @param _page page number
    /// @param _resultsPerPage how many to return per page
    function getOrganizations(
        uint256 _page,
        uint256 _resultsPerPage
    )
        external
        view
        returns (address[] memory)
    {
        uint256 _orgIndex = _resultsPerPage * _page - _resultsPerPage;

        if (
            organizations.length == 0 ||
            _orgIndex > organizations.length - 1
        ) {
            return new address[](0);
        }

        address[] memory _orgs = new address[](_resultsPerPage);
        uint256 _returnCounter = 0;
        
        for (
            _orgIndex;
            _orgIndex < _resultsPerPage * _page;
            _orgIndex++
        ) {
            if (_orgIndex <= organizations.length - 1) {
                _orgs[_returnCounter] = organizations[_orgIndex];
            } else {
                _orgs[_returnCounter] = address(0);
            }
            _returnCounter++;
        }
        return _orgs;
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

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error NotYourStream();
error NotEnoughBalance();
error NotEnoughPledged();
error SendMore();
error IncreaseByMore();
error IncreasedByTooMuch();
error CantWithdrawToBurnAddress();
error CantDepositFromBurnAddress();
error StreamDisabled();
error StreamDoesNotExist();
error TransferFailed();
error DepositAmountTooSmall();
error DepositFailed();
error InvalidFrequency();
error InsufficientPrivileges();
error StreamAlreadyExists();

/// @title Organization Streams Contract
/// @author ghostffcode, jaxcoder, nowonder, qedk, supriyaamisshra
/// @notice the meat and potatoes of the stream
contract MultiStream is Ownable, AccessControl, ReentrancyGuard {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    /// @dev Describe a stream 
    struct Stream {
        /// @dev stream cap
        uint256 cap;
        /// @dev stream frequency
        uint256 frequency;
        /// @dev last withdraw
        uint256 last;
        /// @dev tokens pledged to this stream
        uint256 pledged;
        ///@dev stream name 
        string name;
    }

    /// @dev Describe a stream for view purposes
    struct StreamView {
        /// @dev owner address
        address owner;
        /// @dev stream cap
        uint256 cap;
        /// @dev stream frequency
        uint256 frequency;
        /// @dev last withdraw
        uint256 last;
        /// @dev stream balance
        uint256 balance;
        /// @dev pledged/eligible balance
        uint256 pledged;
        ///@dev stream name 
        string name;
    }

    /// @dev organization info
    struct OrgInfo {
        /// @dev org name
        string name;
        /// @dev logo URI
        string logoURI;
        /// @dev description
        string description;
        /// @dev track total stream count
        uint256 totalStreams;
        /// @dev track total payouts for UI
        uint256 totalPaid;
        /// @dev token
        IERC20 dToken;
    }

    OrgInfo public orgInfo;
    uint256 streamCount;
    mapping(address => uint256) inverseOwnerIndex;
    mapping(uint256 => address) ownerIndex;
    mapping(address => Stream) streams;
    mapping(address => bool) disabled;

    event Withdraw(address indexed to, uint256 amount, string reason);
    event Deposit(address indexed stream, address indexed from, uint256 amount, string reason);
    /// @dev StreamAdded event to track the streams after creation
    event StreamAdded(address creator, address user, string name);

    modifier hasCorrectRole() {
        if (!hasRole(MANAGER_ROLE, _msgSender())) {
            if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
                revert InsufficientPrivileges();
            }
        }
        _;
    }

    constructor(
        string memory _orgName,
        string memory _orgLogoURI,
        string memory _orgDescription,
        address _owner,
        address[] memory _addresses,
        uint256[] memory _caps,
        uint256[] memory _frequency,
        bool[] memory _startsFull,
        string[] memory _name,
        address _tokenAddress
    ) {
        /* 
        @ note Init Org Details
        */
        orgInfo = OrgInfo(
            _orgName,
            _orgLogoURI,
            _orgDescription,
            _addresses.length,
            0,
            IERC20(_tokenAddress)
        );

        /* 
        @ note Init Streams
        */
        for (uint256 i = 0; i < _addresses.length; ++i) {
            ownerIndex[streamCount] = _addresses[i];
            inverseOwnerIndex[_addresses[i]] = streamCount;
            streamCount += 1;
            uint256 last;
            if (_startsFull[i] == true) {
                last = block.timestamp - _frequency[i];
            } else {
                last = block.timestamp;
            }
            Stream memory stream = Stream(_caps[i], _frequency[i], last, 0, _name[i]);
            streams[_addresses[i]] = stream;
            emit StreamAdded(_msgSender(), _addresses[i], _name[i]);
        }

        /* 
        @ note Init Roles
        */
        transferOwnership(_owner);
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
    }

    function addManager(address _manager) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MANAGER_ROLE, _manager);
    }

    function removeManager(address _manager)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        revokeRole(MANAGER_ROLE, _manager);
    }

    /// @dev add a stream for user
    function addStream(
        address _beneficiary,
        uint256 _cap,
        uint256 _frequency,
        bool _startsFull,
        string calldata _name
    ) external hasCorrectRole {
        if (streams[_beneficiary].last > 0) {
            revert StreamAlreadyExists();
        }
        ownerIndex[streamCount] = _beneficiary;
        inverseOwnerIndex[_beneficiary] = streamCount;
        streamCount += 1;
        uint256 last;
        if (_startsFull == true) {
            last = block.timestamp - _frequency;
        } else {
            last = block.timestamp;
        }
        Stream memory stream = Stream(_cap, _frequency, last, 0, _name);
        streams[_beneficiary] = stream;
        orgInfo.totalStreams += 1;
        emit StreamAdded(_msgSender(), _beneficiary, _name);
    }

    /// @dev Transfers remaining balance and disables stream
    function disableStream(address _beneficiary) external hasCorrectRole {
        uint256 totalAmount = streamBalance(_beneficiary);

        uint256 cappedLast = block.timestamp - streams[_beneficiary].frequency;
        if (streams[_beneficiary].last < cappedLast) {
            streams[_beneficiary].last = cappedLast;
        }
        streams[_beneficiary].last =
            streams[_beneficiary].last +
            (((block.timestamp - streams[_beneficiary].last) * totalAmount) /
                totalAmount);

        if (!orgInfo.dToken.transfer(_beneficiary, totalAmount)) revert TransferFailed();

        disabled[_beneficiary] = true;
        streams[_beneficiary].cap = 0;
        orgInfo.totalStreams -= 1;
    }

    /// @dev Transfers remaining balance and deletes stream
    function deleteStream(address _beneficiary) external hasCorrectRole {
        uint256 totalAmount = streamBalance(_beneficiary);

        if(!orgInfo.dToken.transfer(msg.sender, totalAmount)) revert TransferFailed();

        streamCount -= 1;
        // Trigger gas refunds
        delete streams[_beneficiary];
        delete ownerIndex[inverseOwnerIndex[_beneficiary]];
        delete inverseOwnerIndex[_beneficiary];
        delete disabled[_beneficiary];
    }

    /// @dev Reactivates a stream for user
    function enableStream(
        address _beneficiary,
        uint256 _cap,
        uint256 _frequency,
        bool _startsFull
    ) external hasCorrectRole {

        streams[_beneficiary].cap = _cap;
        streams[_beneficiary].frequency = _frequency;

        if (_startsFull == true) {
            streams[_beneficiary].last = block.timestamp - _frequency;
        } else {
            streams[_beneficiary].last = block.timestamp;
        }

        disabled[_beneficiary] = false;
        orgInfo.totalStreams += 1;
    }

    /// @dev Get the balance of a stream by address
    /// @return balance of the stream by address
    function streamBalance(address _beneficiary) public view returns (uint256) {

        if (block.timestamp - streams[_beneficiary].last > streams[_beneficiary].frequency) {
            return streams[_beneficiary].cap;
        }
        return
            (streams[_beneficiary].cap * (block.timestamp - streams[_beneficiary].last)) /
            streams[_beneficiary].frequency;
    }

    /// @dev Withdraw from a stream
    /// @param payoutAddress account to withdraw into
    /// @param amount amount of withdraw
    /// @param reason a reason
    function streamWithdraw(address payoutAddress, uint256 amount, string calldata reason)
        external
    {
        if (payoutAddress == address(0)) revert CantWithdrawToBurnAddress();
        if (disabled[msg.sender] == true) revert StreamDisabled();

        uint256 totalAmountCanWithdraw = streamBalance(msg.sender);
        if (totalAmountCanWithdraw < amount) revert NotEnoughBalance();
        if (amount > streams[msg.sender].pledged) revert NotEnoughPledged();

        uint256 cappedLast = block.timestamp - streams[msg.sender].frequency;
        if (streams[msg.sender].last < cappedLast) {
            streams[msg.sender].last = cappedLast;
        }
        streams[msg.sender].last =
            streams[msg.sender].last +
            (((block.timestamp - streams[msg.sender].last) * amount) /
                totalAmountCanWithdraw);

        if (!orgInfo.dToken.transfer(payoutAddress, amount)) revert TransferFailed();

        orgInfo.totalPaid += amount;
        streams[msg.sender].pledged -= amount;
        emit Withdraw(payoutAddress, amount, reason);
    }

    /// @notice Deposits tokens into a specified stream
    /// @dev Deposit into stream
    /// @param _stream a user stream
    /// @param reason reason for deposit
    /// @param  value the amount of the deposit
    function streamDeposit(address _stream, string memory reason, uint256 value)
        external
        nonReentrant
    {
        if (_msgSender() == address(0)) revert CantDepositFromBurnAddress();
        if (disabled[_stream] == true) revert StreamDisabled();
        if (value < (streams[_stream].cap / 10)) revert DepositAmountTooSmall();
        if (!orgInfo.dToken.transferFrom(_msgSender(), address(this), value)) revert DepositFailed();
        streams[_stream].pledged += value;
        emit Deposit(_stream, _msgSender(), value, reason);
    }

    /// @dev Increase the cap of the stream
    /// @param _increase how much to increase the cap
    function increaseCap(uint256 _increase, address beneficiary)
        external
        hasCorrectRole
    {
        if (_increase == 0) revert IncreaseByMore();

        if ((streams[beneficiary].cap + _increase) >= 1 ether)
            revert IncreasedByTooMuch();
        streams[beneficiary].cap = streams[beneficiary].cap + _increase;
    }

    /// @dev Update the frequency of a stream
    /// @param _frequency the new frequency
    function updateFrequency(uint256 _frequency, address beneficiary)
        external
        hasCorrectRole
    {
        if(_frequency < 0) revert InvalidFrequency();
        if (_frequency == 0) revert IncreaseByMore();
        streams[beneficiary].frequency = _frequency;
    }

    /// @dev checks whether org has an active stream for user
    /// @param _userAddress a users address
    function hasStream(address _userAddress)
        public
        view
        returns (bool)
    {
        return streams[_userAddress].frequency != 0 && disabled[_userAddress] != true;
    }

    /// @dev gets stream details
    /// @param _userAddress a users address
    function getStreamView(address _userAddress)
        public
        view
        returns (StreamView memory)
    {
        return StreamView(_userAddress, streams[_userAddress].cap,
                    streams[_userAddress].frequency, streams[_userAddress].last,
                    streamBalance(_userAddress), streams[_userAddress].pledged, streams[_userAddress].name);
    }

    /// @dev gets a page of streams
    /// @param _page a page number
    /// @param _resultsPerPage number of results per page
    function getStreams(
        uint256 _page,
        uint256 _resultsPerPage
    )
        public
        view
        returns (StreamView[] memory)
    {
        uint256 _ownerIndex = _resultsPerPage * _page - _resultsPerPage;

        if (
            streamCount == 0 ||
            _ownerIndex > streamCount - 1
        ) {
            return new StreamView[](0);
        }

        StreamView[] memory _streams = new StreamView[](_resultsPerPage);
        uint256 _returnCounter = 0;
        uint256 _skipped = 0;
        address currentOwner = address(0);
        
        for (
            _ownerIndex;
            _ownerIndex < ((_resultsPerPage * _page) + _skipped);
            _ownerIndex++
        ) {
            if (_ownerIndex <= streamCount - 1) {
                currentOwner = ownerIndex[_ownerIndex];
                if (disabled[currentOwner]) {
                    _skipped++;
                    continue;
                }
                _streams[_returnCounter] = StreamView(currentOwner, streams[currentOwner].cap,
                    streams[currentOwner].frequency, streams[currentOwner].last,
                    streamBalance(currentOwner), streams[currentOwner].pledged, streams[currentOwner].name);
            } else {
                _streams[_returnCounter] = StreamView(address(0), 0,0,0,0,0, "");
            }
            _returnCounter++;
        }
        return _streams;
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
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

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
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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