// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "AccessControlUpgradeable.sol";

import "ICryptoPageCalcUserRate.sol";
import "ICryptoPageUserRateToken.sol";
import "ICryptoPageCommunity.sol";

import {DataTypes} from "DataTypes.sol";


/// @title The contract calculates rates of users
/// @author Crypto.Page Team
/// @notice
/// @dev
contract PageCalcUserRate is
Initializable,
AccessControlUpgradeable,
IPageCalcUserRate
{

    IPageUserRateToken public userRateToken;

    bytes32 public constant BANK_ROLE = keccak256("BANK_ROLE");
    bytes32 public constant DEAL_ROLE = keccak256("DEAL_ROLE");

    uint256 public constant TOKEN_ID_MULTIPLYING_FACTOR = 100;
    bytes constant FOR_RATE_TOKEN_DATA = "";

    //for RedeemedCount
    uint256[10] public interestAdjustment;
    int256 public MAX_PERCENT;

    enum UserRatesType {
        RESERVE, HUNDRED_UP, THOUSAND_UP, HUNDRED_DOWN, THOUSAND_DOWN,
        TEN_MESSAGE, HUNDRED_MESSAGE, THOUSAND_MESSAGE,
        TEN_POST, HUNDRED_POST, THOUSAND_POST,
        DEAL_GUARANTOR, DEAL_SELLER, DEAL_BUYER
    }

    struct RateCount {
        uint64 messageCount;
        uint64 postCount;
        uint64 upCount;
        uint64 downCount;
    }

    struct RedeemedCount {
        uint64[3] messageCount;
        uint64[3] postCount;
        uint64[2] upCount;
        uint64[2] downCount;
    }

    mapping(uint256 => mapping(address => RateCount)) private activityCounter;
    mapping(uint256 => mapping(address => RedeemedCount)) private redeemedCounter;

    event SetInterestAdjustment(uint256[10] oldValue, uint256[10] newValue);
    event SetMaxPercent(int256 oldValue, int256 newValue);
    event AddedDealActivity(address user, DataTypes.ActivityType activityType);

    /**
     * @dev check that the address passed is not 0.
     */
    modifier notAddress0(address _address) {
        require(_address != address(0), "PageCalcUserRate: Address 0 is not valid");
        _;
    }

    /**
     * @dev Makes the initialization of the initial values for the smart contract
     *
     * @param _admin Address of admin
     * @param _userRateToken Address of bank
     */
    function initialize(address _admin, address _userRateToken) external initializer {
        require(_admin != address(0), "PageCalcUserRate: wrong admin address");
        require(_userRateToken != address(0), "PageCalcUserRate: wrong bank address");

        _setupRole(DEFAULT_ADMIN_ROLE, _admin);

        userRateToken = IPageUserRateToken(_userRateToken);
        MAX_PERCENT = 10000;
        interestAdjustment = [1, 10, 30, 40, 50, 60, 20, 40, 20, 40];
    }

    /**
     * @dev Returns the smart contract version
     *
     */
    function version() external pure override returns (string memory) {
        return "1";
    }

    /**
     * @dev Accepts ether to the balance of the contract
     * Required for testing
     *
     */
    receive() external payable {
        // React to receiving ether
        // Uncomment for production
        //revert("PageBank: asset transfer prohibited");
    }

    /**
     * @dev The main function for users who write messages.
     * Keeps records of user activities.
     *
     * @param communityId ID of community
     * @param user User wallet address
     * @param activityType Activity type, taken from enum
     */
    function checkCommunityActivity(
        uint256 communityId,
        address user,
        DataTypes.ActivityType activityType
    ) external override onlyRole(BANK_ROLE) notAddress0(user) returns(int256 resultPercent)
    {
        addActivity(communityId, user, activityType);
        uint256 baseTokenId = communityId * TOKEN_ID_MULTIPLYING_FACTOR;

        checkMessages(baseTokenId, communityId, user);
        checkPosts(baseTokenId, communityId, user);
        checkUps(baseTokenId, communityId, user);
        checkDowns(baseTokenId, communityId, user);

        return calcPercent(user, baseTokenId);
    }

    /**
     * @dev The function for users making deals.
     * Keeps records of user activities.
     *
     * @param user User wallet address
     * @param activityType Activity type, taken from enum
     */
    function addDealActivity(address user, DataTypes.ActivityType activityType) external override onlyRole(DEAL_ROLE) notAddress0(user) {
        uint256 tokenId = 0;
        if (activityType == DataTypes.ActivityType.DEAL_GUARANTOR) {
            tokenId = uint256(UserRatesType.DEAL_GUARANTOR);
        }
        if (activityType == DataTypes.ActivityType.DEAL_SELLER) {
            tokenId = uint256(UserRatesType.DEAL_SELLER);
        }
        if (activityType == DataTypes.ActivityType.DEAL_BUYER) {
            tokenId = uint256(UserRatesType.DEAL_BUYER);
        }

        userRateToken.mint(user, tokenId, 1, FOR_RATE_TOKEN_DATA);
        emit AddedDealActivity(user, activityType);
    }

    /**
     * @dev Calculates the percentage for accruing tokens when creating a post or message.
     *
     * @param user User wallet address
     * @param baseTokenId Token ID for rating tokens
     */
    function calcPercent(address user, uint256 baseTokenId) public view  returns(int256 resultPercent) {
        resultPercent = 0;
        uint256[10] memory weight = interestAdjustment;
        uint256[] memory messageAmount = new uint256[](3);
        uint256[] memory postAmount = new uint256[](3);
        uint256[] memory upAmount = new uint256[](2);
        uint256[] memory downAmount = new uint256[](2);

        messageAmount[0] = userRateToken.balanceOf(user, baseTokenId + uint256(UserRatesType.TEN_MESSAGE) + 0);
        messageAmount[1] = userRateToken.balanceOf(user, baseTokenId + uint256(UserRatesType.TEN_MESSAGE) + 1);
        messageAmount[2] = userRateToken.balanceOf(user, baseTokenId + uint256(UserRatesType.TEN_MESSAGE) + 2);

        postAmount[0] = userRateToken.balanceOf(user, baseTokenId + uint256(UserRatesType.TEN_POST) + 0);
        postAmount[1] = userRateToken.balanceOf(user, baseTokenId + uint256(UserRatesType.TEN_POST) + 1);
        postAmount[2] = userRateToken.balanceOf(user, baseTokenId + uint256(UserRatesType.TEN_POST) + 2);

        upAmount[0] = userRateToken.balanceOf(user, baseTokenId + uint256(UserRatesType.HUNDRED_UP) + 0);
        upAmount[1] = userRateToken.balanceOf(user, baseTokenId + uint256(UserRatesType.HUNDRED_UP) + 1);

        downAmount[0] = userRateToken.balanceOf(user, baseTokenId + uint256(UserRatesType.HUNDRED_DOWN) + 0);
        downAmount[1] = userRateToken.balanceOf(user, baseTokenId + uint256(UserRatesType.HUNDRED_DOWN) + 1);

        resultPercent += int256(weight[0] * messageAmount[0] + weight[1] * messageAmount[1] + weight[2] * messageAmount[2]);
        resultPercent += int256(weight[3] * postAmount[0] + weight[4] * postAmount[1] + weight[5] * postAmount[2]);
        resultPercent += int256(weight[6] * upAmount[0] + weight[7] * upAmount[1]);
        resultPercent -= int256(weight[8] * downAmount[0] + weight[9] * downAmount[1]);

        if (resultPercent > MAX_PERCENT) {
            resultPercent = MAX_PERCENT;
        }
    }

    /**
     * @dev Shows user activity when creating posts or messages.
     *
     * @param communityId ID of community
     * @param user User wallet address
     */
    function getUserActivity(uint256 communityId, address user) external override  view returns(
        uint64 messageCount,
        uint64 postCount,
        uint64 upCount,
        uint64 downCount
    ) {
        RateCount memory counter = activityCounter[communityId][user];

        messageCount = counter.messageCount;
        postCount = counter.postCount;
        upCount = counter.upCount;
        downCount = counter.downCount;
    }

    /**
     * @dev Shows the activity of the user paid for by NFT tokens for rating when creating posts or messages.
     *
     * @param communityId ID of community
     * @param user User wallet address
     */
    function getUserRedeemed(uint256 communityId, address user) external override view returns(
        uint64[3] memory messageCount,
        uint64[3] memory postCount,
        uint64[2] memory upCount,
        uint64[2] memory downCount
    ) {
        RedeemedCount memory counter = redeemedCounter[communityId][user];

        messageCount = counter.messageCount;
        postCount = counter.postCount;
        upCount = counter.upCount;
        downCount = counter.downCount;
    }

    /**
     * @dev Allows you to change the values for interest calculation.
     *
     * @param values Array of new values
     */
    function setInterestAdjustment(uint256[10] calldata values) onlyRole(DEFAULT_ADMIN_ROLE) external override {
        uint256 all;
        for (uint256 i=0; i<10; i++) {
            all += values[i];
        }
        require(all <= 10000, "PageCalcUserRate: wrong values");
        emit SetInterestAdjustment(interestAdjustment, values);
        interestAdjustment = values;
    }

    /**
     * @dev Allows you to change the MAX_PERCENT value for percent calculation.
     *
     * @param value New values of MAX_PERCENT
     */
    function setMaxPercent(int256 value) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(value != MAX_PERCENT, "Setting the same value");
        emit SetMaxPercent(MAX_PERCENT, value);
        MAX_PERCENT = value;
    }


    // *** --- Private area --- ***

    /**
     * @dev Checking and counting user messages.
     *
     * @param tokenId Token ID for rating tokens
     * @param communityId ID of community
     * @param user User wallet address
     */
    function checkMessages(uint256 tokenId, uint256 communityId, address user) private {
        uint256 realMessageCount = activityCounter[communityId][user].messageCount;

        checkMessagesByIndex(tokenId, communityId, user, realMessageCount, 0);
        checkMessagesByIndex(tokenId, communityId, user, realMessageCount, 1);
        checkMessagesByIndex(tokenId, communityId, user, realMessageCount, 2);
    }

    /**
     * @dev Checking and counting user posts.
     *
     * @param tokenId Token ID for rating tokens
     * @param communityId ID of community
     * @param user User wallet address
     */
    function checkPosts(uint256 tokenId, uint256 communityId, address user) private {
        uint256 realPostCount = activityCounter[communityId][user].postCount;

        checkPostsByIndex(tokenId, communityId, user, realPostCount, 0);
        checkPostsByIndex(tokenId, communityId, user, realPostCount, 1);
        checkPostsByIndex(tokenId, communityId, user, realPostCount, 2);
    }

    /**
     * @dev Checking and counting user Upvotes.
     *
     * @param tokenId Token ID for rating tokens
     * @param communityId ID of community
     * @param user User wallet address
     */
    function checkUps(uint256 tokenId, uint256 communityId, address user) private {
        uint256 realUpCount = activityCounter[communityId][user].upCount;

        checkUpsByIndex(tokenId, communityId, user, realUpCount, 0);
        checkUpsByIndex(tokenId, communityId, user, realUpCount, 1);
    }

    /**
     * @dev Checking and counting user Downvotes.
     *
     * @param tokenId Token ID for rating tokens
     * @param communityId ID of community
     * @param user User wallet address
     */
    function checkDowns(uint256 tokenId, uint256 communityId, address user) private {
        uint256 realDownCount = activityCounter[communityId][user].downCount;

        checkDownsByIndex(tokenId, communityId, user, realDownCount, 0);
        checkDownsByIndex(tokenId, communityId, user, realDownCount, 1);
    }

    /**
     * @dev Checking messages for mint new tokens.
     *
     * @param tokenId Token ID for rating tokens
     * @param communityId ID of community
     * @param user User wallet address
     * @param realMessageCount Total user messages
     * @param index Decimal for count
     */
    function checkMessagesByIndex(
        uint256 tokenId,
        uint256 communityId,
        address user,
        uint256 realMessageCount,
        uint256 index
    ) private {
        RedeemedCount storage redeemCounter = redeemedCounter[communityId][user];

        uint256 number = realMessageCount / (10 * 10**index);
        uint64 mintNumber = uint64(number) - redeemCounter.messageCount[index];
        if (mintNumber > 0) {
            redeemCounter.messageCount[index] += mintNumber;
            userRateToken.mint(
                user, tokenId + uint256(UserRatesType.TEN_MESSAGE) + index, mintNumber, FOR_RATE_TOKEN_DATA
            );
        }
    }

    /**
     * @dev Checking posts for mint new tokens.
     *
     * @param tokenId Token ID for rating tokens
     * @param communityId ID of community
     * @param user User wallet address
     * @param realPostCount Total user posts
     * @param index Decimal for count
     */
    function checkPostsByIndex(uint256 tokenId, uint256 communityId, address user, uint256 realPostCount, uint256 index) private {
        RedeemedCount storage redeemCounter = redeemedCounter[communityId][user];

        uint256 number = realPostCount / (10 * 10**index);
        uint256 mintNumber = number - redeemCounter.postCount[index];
        if (mintNumber > 0) {
            redeemCounter.postCount[index] += uint64(mintNumber);
            userRateToken.mint(
                user, tokenId + uint256(UserRatesType.TEN_POST) + index, mintNumber, FOR_RATE_TOKEN_DATA
            );
        }
    }

    /**
     * @dev Checking Upvotes for mint new tokens.
     *
     * @param tokenId Token ID for rating tokens
     * @param communityId ID of community
     * @param user User wallet address
     * @param realUpCount Total user Upvotes
     * @param index Decimal for count
     */
    function checkUpsByIndex(uint256 tokenId, uint256 communityId, address user, uint256 realUpCount, uint256 index) private {
        RedeemedCount storage redeemCounter = redeemedCounter[communityId][user];

        uint256 number = realUpCount / (10 * 10**(index+1));
        uint256 mintNumber = number - redeemCounter.upCount[index];
        if (mintNumber > 0) {
            redeemCounter.upCount[index] += uint64(mintNumber);
            userRateToken.mint(
                user, tokenId + uint256(UserRatesType.HUNDRED_UP) + index, mintNumber, FOR_RATE_TOKEN_DATA
            );
        }
    }

    /**
     * @dev Checking Downvotes for mint new tokens.
     *
     * @param tokenId Token ID for rating tokens
     * @param communityId ID of community
     * @param user User wallet address
     * @param realDownCount Total user Downvotes
     * @param index Decimal for count
     */
    function checkDownsByIndex(uint256 tokenId, uint256 communityId, address user, uint256 realDownCount, uint256 index) private {
        RedeemedCount storage redeemCounter = redeemedCounter[communityId][user];

        uint256 number = realDownCount / (10 * 10**(index+1));
        uint256 mintNumber = number - redeemCounter.downCount[index];
        if (mintNumber > 0) {
            redeemCounter.downCount[index] += uint64(mintNumber);
            userRateToken.mint(
                user, tokenId + uint256(UserRatesType.HUNDRED_DOWN) + index, mintNumber, FOR_RATE_TOKEN_DATA
            );
        }
    }

    /**
     * @dev Adds new user activities to counters when working in communities.
     *
     * @param communityId ID of community
     * @param user User wallet address
     * @param activityType Activity type, taken from enum
     */
    function addActivity(uint256 communityId, address user, DataTypes.ActivityType activityType) private {
        RateCount storage counter = activityCounter[communityId][user];
        if (activityType == DataTypes.ActivityType.POST) {
            counter.postCount++;
        }
        if (activityType == DataTypes.ActivityType.MESSAGE) {
            counter.messageCount++;
        }
        if (activityType == DataTypes.ActivityType.UP) {
            counter.upCount++;
        }
        if (activityType == DataTypes.ActivityType.DOWN) {
            counter.downCount++;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "IAccessControlUpgradeable.sol";
import "ContextUpgradeable.sol";
import "StringsUpgradeable.sol";
import "ERC165Upgradeable.sol";
import "Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

import "IERC165Upgradeable.sol";
import "Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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

pragma solidity 0.8.15;

import {DataTypes} from "DataTypes.sol";

interface IPageCalcUserRate {

    function version() external pure returns (string memory);

    function checkCommunityActivity(
        uint256 communityId,
        address user,
        DataTypes.ActivityType activityType
    ) external returns(int256 resultPercent);

    function addDealActivity(address user, DataTypes.ActivityType activityType) external;

    function calcPercent(address user, uint256 baseTokenId) external view returns(int256 resultPercent);

    function getUserActivity(uint256 communityId, address user) external view returns(
        uint64 messageCount,
        uint64 postCount,
        uint64 upCount,
        uint64 downCount
    );

    function getUserRedeemed(uint256 communityId, address user) external view returns(
        uint64[3] memory messageCount,
        uint64[3] memory postCount,
        uint64[2] memory upCount,
        uint64[2] memory downCount
    );

    function setInterestAdjustment(uint256[10] calldata values) external;

    function setMaxPercent(int256 value) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "EnumerableSetUpgradeable.sol";

library DataTypes {

    enum ActivityType { POST, MESSAGE, UP, DOWN, DEAL_GUARANTOR, DEAL_SELLER, DEAL_BUYER }

    struct DealMessage {
        string message;
        address sender;
        uint256 writeTime;
    }

    struct SafeDeal {
        string description;
        address seller;
        address buyer;
        address guarantor;
        uint256 amount;
        uint128 startTime;
        uint128 endTime;
        bool startSellerApprove;
        bool startBuyerApprove;
        bool endSellerApprove;
        bool endBuyerApprove;
        bool isIssue;
        bool isEth;
        bool isFinished;
        DealMessage[] messages;
    }

    struct AddressUintsVote {
        string description;
        address creator;
        uint128 execMethodNumber;
        uint128 finishTime;
        uint128 yesCount;
        uint128 noCount;
        uint64[4] newValues;
        address user;
        EnumerableSetUpgradeable.AddressSet voteUsers;
        bool active;
    }

    struct AddressUintVote {
        string description;
        address creator;
        uint128 finishTime;
        uint128 yesCount;
        uint128 noCount;
        uint128 value;
        address user;
        EnumerableSetUpgradeable.AddressSet voteUsers;
        bool active;
    }

    struct UintVote {
        string description;
        address creator;
        uint128 finishTime;
        uint128 yesCount;
        uint128 noCount;
        uint128 newValue;
        EnumerableSetUpgradeable.AddressSet voteUsers;
        bool active;
    }

    struct BoolVote {
        string description;
        address creator;
        uint128 finishTime;
        uint128 yesCount;
        uint128 noCount;
        bool newValue;
        EnumerableSetUpgradeable.AddressSet voteUsers;
        bool active;
    }

    struct AddressVote {
        string description;
        address creator;
        uint128 finishTime;
        uint128 yesCount;
        uint128 noCount;
        address user;
        EnumerableSetUpgradeable.AddressSet voteUsers;
        EnumerableSetUpgradeable.UintSet voteCommunities;
        bool active;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "IERC1155Upgradeable.sol";

interface IPageUserRateToken is IERC1155Upgradeable {

    function version() external pure returns (string memory);

    function setCalcRateContract(address calcUserRateContract) external;

    function totalSupply(uint256 id) external view returns (uint256);

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IPageCommunity {

    function version() external pure returns (string memory);

    function addCommunity(string memory desc) external;

    function readCommunity(uint256 communityId) external view returns(
        string memory name,
        address creator,
        address[] memory moderators,
        uint256[] memory postIds,
        address[] memory users,
        address[] memory bannedUsers,
        uint256 usersCount,
        bool isActive,
        bool isPrivate,
        bool isPostOwner
    );

    function getCommunityDaysInCommunityToVote(uint256 communityId) external view returns (uint256);

    function getCommunityUpPostsInCommunityToVote(uint256 communityId) external view returns (uint256);

    function addModerator(uint256 communityId, address moderator) external;

    function removeModerator(uint256 communityId, address moderator) external;

    function setPostOwner(uint256 communityId) external;

    function transferPost(uint256 communityId, uint256 postId, address wallet) external returns(bool);

    function addBannedUser(uint256 communityId, address user) external;

    function removeBannedUser(uint256 communityId, address user) external;

    function join(uint256 communityId) external;

    function quit(uint256 communityId) external;

    function writePost(
        uint256 communityId,
        string memory ipfsHash,
        address _owner
    ) external;

    function readPost(uint256 postId) external view returns(
        string memory ipfsHash,
        address creator,
        uint64 upCount,
        uint64 downCount,
        uint256 price,
        uint256 commentCount,
        address[] memory upDownUsers,
        bool isView
    );

    function burnPost(uint256 postId) external;

    function setPostVisibility(uint256 postId, bool newVisible) external;

    function changeCommunityActive(uint256 communityId) external;

    function setCommunityPrivate(uint256 communityId, bool newPrivate) external;

    function getPostPrice(uint256 postId) external view returns (uint256);

    function getPostsIdsByCommunityId(uint256 communityId) external view returns (uint256[] memory);

    function writeComment(
        uint256 postId,
        string memory ipfsHash,
        bool isUp,
        bool isDown,
        address _owner
    ) external;

    function readComment(uint256 postId, uint256 commentId) external view returns(
        string memory ipfsHash,
        address creator,
        address _owner,
        uint256 price,
        bool isUp,
        bool isDown,
        bool isView
    );

    function burnComment(uint256 postId, uint256 commentId) external;

    function setCommunityUpPostsInCommunityToVote(uint256 communityId, uint256 newUpPostsInCommunityToVote) external;

    function setCommunityDaysInCommunityToVote(uint256 communityId, uint256 newDaysInCommunityToVote) external;

    function setVisibilityComment(
        uint256 postId,
        uint256 commentId,
        bool newVisible
    ) external;

    function setMaxModerators(uint256 newValue) external;

    function setDefaultDaysInCommunityToVote(uint256 newValue) external;

    function setDefaultUpPostsInCommunityToVote(uint256 newValue) external;

    function addVoterContract(address newContract) external;

    function changeSupervisor(address newUser) external;

    function getCommentCount(uint256 postId) external view returns(uint256);

    function isCommunityCreator(uint256 communityId, address user) external view returns(bool);

    function isCommunityActiveUser(uint256 communityId, address user) external returns(bool);

    function isCommunityJoinedUser(uint256 communityId, address user) external returns(bool);

    function isCommunityPostOwner(uint256 communityId) external view returns(bool);

    function isBannedUser(uint256 communityId, address user) external view returns(bool);

    function isCommunityModerator(uint256 communityId, address user) external view returns(bool);

    function getCommunityIdByPostId(uint256 postId) external view returns(uint256);

    function OPEN_FORUM_ID() external returns(uint256);

    function isUpDownUser(uint256 postId, address user) external view returns(bool);

    function isActiveCommunity(uint256 communityId) external view returns(bool);

    function isActiveCommunityByPostId(uint256 postId) external view returns(bool);

    function isPrivateCommunity(uint256 communityId) external view returns(bool);

    function isEligibleToVoting(uint256 communityId, address user) external view returns(bool);
}