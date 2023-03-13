// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./interfaces/ICommonBlacklist.sol";

contract CommonBlacklist is ICommonBlacklist, OwnableUpgradeable, AccessControlUpgradeable {

    bytes32 public constant BLACKLIST_OPERATOR_ROLE = keccak256("BLACKLIST_OPERATOR_ROLE");
    address public constant GNOSIS = 0x126481E4E79cBc8b4199911342861F7535e76EE7;

    // user
    // is_blacklisted
    mapping(address => bool) public blacklist;

    // token
    // user
    // is_blacklisted
    mapping(address => mapping (address => bool)) public internal_blacklist;


    // token
    // limits struct { inComeDay, inComeMonth, outComeDay, outComeMonth }
    mapping(address => TokenLimit) public token_limits;

    // token
    // user
    // date
    // transfers struct { inCome, outCome }
    mapping(address => mapping (address => mapping (uint256 => TokenTransfers))) public token_transfers;

    // token
    // has limit struct { hasInComeDayLimit, hasInComeMonthLimit, hasOutComeDayLimit, hasOutComeMonthLimit }
    mapping(address => TokenLimitDisabling) public tokens_with_limits;

    // contract
    // has exception
    mapping(address => bool) public contracts_exclusion_list;

    // Events
    event SetTokenLimit(address token, uint256 inComeDayLimit, uint256 inComeMonthLimit, uint256 outComeDayLimit, uint256 outComeMonthLimit);
    event SetTokenLimitStatus(address token, bool hasInComeDayLimit, bool hasInComeMonthLimit, bool hasOutComeDayLimit, bool hasOutComeMonthLimit);
    event AddToExclusionList(address token);
    event RemoveFromExclusionList(address token);

    uint256[50] __gap;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // Modifier for roles
    modifier onlyBlacklistOperator() {
        require(hasRole(BLACKLIST_OPERATOR_ROLE, _msgSender()), "Not a blacklist operator");
        _;
    }

    function initialize() external initializer {
        __AccessControl_init();
        __Ownable_init();

        contracts_exclusion_list[address(0)] = true;

//        transferOwnership(GNOSIS);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Add user to global blacklist
     * @param _users: users array for adding to blacklist
     *
     * @dev Callable by blacklist operator
     *
     */
    function addUsersToBlacklist(
        address[] memory _users
    ) external onlyBlacklistOperator {
        for (uint i; i < _users.length; i++) {
            require(_users[i] != address(0), "Cannot be zero address");

            blacklist[_users[i]] = true;
        }
    }

    /**
     * @notice Remove users from global blacklist
     * @param _users: users array for removing from blacklist
     *
     * @dev Callable by blacklist operator
     *
     */
    function removeUsersFromBlacklist(
        address[] memory _users
    ) external onlyBlacklistOperator {
        for (uint i; i < _users.length; i++) {
            blacklist[_users[i]] = false;
        }
    }

    /**
     * @notice Add user to internal blacklist
     * @param _token: address of token contract
     * @param _users: users array for adding to blacklist
     *
     * @dev Callable by blacklist operator
     *
     */
    function addUsersToInternalBlacklist(
        address _token,
        address[] memory _users
    ) external onlyBlacklistOperator {
        for (uint i; i < _users.length; i++) {
            require(_users[i] != address(0), "Cannot be zero address");

            internal_blacklist[_token][_users[i]] = true;
        }
    }

    /**
     * @notice Remove users from internal blacklist
     * @param _token: address of token contract
     * @param _users: users array for removing from blacklist
     *
     * @dev Callable by blacklist operator
     *
     */
    function removeUsersFromInternalBlacklist(
        address _token,
        address[] memory _users
    ) external onlyBlacklistOperator {
        for (uint i; i < _users.length; i++) {
            internal_blacklist[_token][_users[i]] = false;
        }
    }

    /**
     * @notice Getting information if user blacklisted
     * @param _sender: sender address
     * @param _from: from address
     * @param _to: to address
     *
     */
    function userIsBlacklisted(
        address _sender,
        address _from,
        address _to
    ) external view returns(bool) {
        return blacklist[_sender] || blacklist[_from] || blacklist[_to];
    }

    /**
     * @notice Getting information if user in internal blacklist
     * @param _token: address of token contract
     * @param _sender: sender address
     * @param _from: from address
     * @param _to: to address
     *
     */
    function userIsInternalBlacklisted(
        address _token,
        address _sender,
        address _from,
        address _to
    ) external view returns(bool) {
        return internal_blacklist[_token][_sender] || internal_blacklist[_token][_from] || internal_blacklist[_token][_to];
    }

    /**
     * @notice Getting information about the presence of users from the list in the blacklist
     * @param _token: address of token contract
     * @param _users: list of user address
     *
     */
    function usersFromListIsBlacklisted(
        address _token,
        address[] memory _users
    ) external view returns(address[] memory) {
        uint256 length = 0;

        for (uint i; i < _users.length; i++) {
            bool hasMatch = _token == address(0) ? blacklist[_users[i]] : internal_blacklist[_token][_users[i]] || blacklist[_users[i]];
            if (hasMatch) {
                length += 1;
            }
        }

        address[] memory list = new address[](length);

        if (length == 0) {
            return list;
        }

        uint256 listCounter = 0;

        for (uint i; i < _users.length; i++) {
            bool hasMatch = _token == address(0) ? blacklist[_users[i]] : internal_blacklist[_token][_users[i]] || blacklist[_users[i]];
            if (hasMatch) {
                list[listCounter] = _users[i];
                listCounter++;
            }
        }

        return list;
    }

    /**
     * @notice Function returns current day
     */
    function getCurrentDay() public view returns(uint256) {
        (,, uint256 day) = _timestampToDate(block.timestamp);
        return getCurrentMonth() * 100 + day;
    }

    /**
     * @notice Function returns current month
     */
    function getCurrentMonth() public view returns(uint256) {
        (uint256 year, uint256 month,) = _timestampToDate(block.timestamp);

        return year * 100 + month;
    }

    /**
     * @notice Setting token limits
     * @param _token: address of token contract
     * @param _inComeDayLimit: day limit for income token transfer
     * @param _inComeMonthLimit: month limit for income token transfer
     * @param _outComeDayLimit: day limit for outcome token transfer
     * @param _outComeMonthLimit: month limit for outcome token transfer
     *
     * @dev Callable by blacklist operator
     *
     */
    function settingTokenLimits(
        address _token,
        uint256 _inComeDayLimit,
        uint256 _inComeMonthLimit,
        uint256 _outComeDayLimit,
        uint256 _outComeMonthLimit
    ) external onlyBlacklistOperator {
        token_limits[_token] = TokenLimit(_inComeDayLimit, _inComeMonthLimit, _outComeDayLimit, _outComeMonthLimit);

        emit SetTokenLimit(_token, _inComeDayLimit, _inComeMonthLimit, _outComeDayLimit, _outComeMonthLimit);
    }

    /**
     * @notice Save income user transfers
     * @param _from: from address
     * @param _to: to address
     * @param _amount: amount of tokens
     *
     */
    function saveUserTransfers(
        address _from,
        address _to,
        uint256 _amount
    ) external {
        uint256 currentMonth = getCurrentMonth();
        uint256 currentDay = getCurrentDay();

        if (tokens_with_limits[msg.sender].hasInComeDayLimit) {
            token_transfers[msg.sender][_to][currentDay].inCome += _amount;
        }

        if (tokens_with_limits[msg.sender].hasInComeMonthLimit) {
            token_transfers[msg.sender][_to][currentMonth].inCome += _amount;
        }

        if (tokens_with_limits[msg.sender].hasOutComeDayLimit) {
            token_transfers[msg.sender][_from][currentDay].outCome += _amount;
        }

        if (tokens_with_limits[msg.sender].hasOutComeMonthLimit) {
            token_transfers[msg.sender][_from][currentMonth].outCome += _amount;
        }
    }

    /**
     * @notice Adding Contracts to exclusion list
     * @param _contract: address of contract
     *
     * @dev Callable by blacklist operator
     *
     */
    function addContractToExclusionList(
        address _contract
    ) external onlyBlacklistOperator {
        contracts_exclusion_list[_contract] = true;

        emit AddToExclusionList(_contract);
    }

    /**
     * @notice Removing Contracts from exclusion list
     * @param _contract: address of contract
     *
     * @dev Callable by blacklist operator
     *
     */
    function removeContractFromExclusionList(
        address _contract
    ) external onlyBlacklistOperator {
        contracts_exclusion_list[_contract] = false;

        emit RemoveFromExclusionList(_contract);
    }

    /**
     * @notice Checking the user for the limits allows
     * @param _token: address of token contract
     * @param _from: spender user address
     * @param _to: recipient user address
     * @param _amount: amount of tokens
     *
     */
    function limitAllows(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) external view returns(
        bool dayInComeLimitAllow,
        bool monthInComeLimitAllow,
        bool dayOutComeLimitAllow,
        bool monthOutComeLimitAllow
    ) {
        uint256 currentMonth = getCurrentMonth();
        uint256 currentDay = getCurrentDay();

        dayInComeLimitAllow = !tokens_with_limits[_token].hasInComeDayLimit || contracts_exclusion_list[_to] ? true :
            token_transfers[_token][_to][currentDay].inCome + _amount <= token_limits[_token].inComeDay;

        monthInComeLimitAllow = !tokens_with_limits[_token].hasInComeMonthLimit || contracts_exclusion_list[_to] ? true :
            token_transfers[_token][_to][currentMonth].inCome + _amount <= token_limits[_token].inComeMonth;

        dayOutComeLimitAllow = !tokens_with_limits[_token].hasOutComeDayLimit || contracts_exclusion_list[_from] ? true :
            token_transfers[_token][_from][currentDay].outCome + _amount <= token_limits[_token].outComeDay;

        monthOutComeLimitAllow = !tokens_with_limits[_token].hasOutComeMonthLimit || contracts_exclusion_list[_from] ? true :
            token_transfers[_token][_from][currentMonth].outCome + _amount <= token_limits[_token].outComeMonth;

    }

    /**
     * @notice Getting token limits
     * @param _token: address of token contract
     *
     */
    function getTokenLimits(
        address _token
    ) external view returns(TokenLimit memory) {
        return token_limits[_token];
    }

    /**
     * @notice Getting user token transfers
     * @param _token: address of token contract
     * @param _user: user address
     *
     */
    function getUserTokenTransfers(
        address _token,
        address _user
    ) public view returns(
        uint256 dayInComeTransfers,
        uint256 monthInComeTransfers,
        uint256 dayOutComeTransfers,
        uint256 monthOutComeTransfers
    ) {
        uint256 currentMonth = getCurrentMonth();
        uint256 currentDay = getCurrentDay();

        dayInComeTransfers = uint256(token_transfers[_token][_user][currentDay].inCome);
        monthInComeTransfers = uint256(token_transfers[_token][_user][currentMonth].inCome);
        dayOutComeTransfers = uint256(token_transfers[_token][_user][currentDay].outCome);
        monthOutComeTransfers = uint256(token_transfers[_token][_user][currentMonth].outCome);
    }

    /**
     * @notice Disable/Enable token limits
     * @param _token: address of token contract
     * @param _hasInComeDayLimit: for disabling income day limits
     * @param _hasInComeMonthLimit: for disabling income month limits
     * @param _hasOutComeDayLimit: for disabling outcome day limits
     * @param _hasOutComeMonthLimit: for disabling outcome month limits
     *
     * @dev Callable by blacklist operator
     *
     */
    function changeDisablingTokenLimits(
        address _token,
        bool _hasInComeDayLimit,
        bool _hasInComeMonthLimit,
        bool _hasOutComeDayLimit,
        bool _hasOutComeMonthLimit
    ) external onlyBlacklistOperator {
        tokens_with_limits[_token] = TokenLimitDisabling(
            _hasInComeDayLimit,
            _hasInComeMonthLimit,
            _hasOutComeDayLimit,
            _hasOutComeMonthLimit
        );

        emit SetTokenLimitStatus(
            _token,
            _hasInComeDayLimit,
            _hasInComeMonthLimit,
            _hasOutComeDayLimit,
            _hasOutComeMonthLimit
        );
    }

    /**
     * @notice Getting remaining limit for user
     * @param _token: address of token contract
     * @param _user: user address
     *
     */
    function getUserRemainingLimit(
        address _token,
        address _user
    ) external view returns(
        uint256 dayInComeRemaining,
        uint256 monthInComeRemaining,
        uint256 dayOutComeRemaining,
        uint256 monthOutComeRemaining
    ) {
        (uint256 dayInComeTransfers,
        uint256 monthInComeTransfers,
        uint256 dayOutComeTransfers,
        uint256 monthOutComeTransfers) = getUserTokenTransfers(_token, _user);

        dayInComeRemaining = uint256(token_limits[_token].inComeDay - dayInComeTransfers);
        monthInComeRemaining = uint256(token_limits[_token].inComeMonth - monthInComeTransfers);
        dayOutComeRemaining = uint256(token_limits[_token].outComeDay - dayOutComeTransfers);
        monthOutComeRemaining = uint256(token_limits[_token].outComeMonth - monthOutComeTransfers);
    }

    /**
     * @notice Getting current date from timestamp
     * @param _timestamp: Timestamp
     *
     */
    function _timestampToDate(
        uint256 _timestamp
    ) internal pure returns (uint256 year, uint256 month, uint256 day) {
        unchecked {
            uint256 SECONDS_PER_DAY = 24 * 60 * 60;
            int256 _days = int256(_timestamp / SECONDS_PER_DAY);

            int256 L = _days + 68569 + 2440588;
            int256 N = (4 * L) / 146097;
            L = L - (146097 * N + 3) / 4;
            int256 _year = (4000 * (L + 1)) / 1461001;
            L = L - (1461 * _year) / 4 + 31;
            int256 _month = (80 * L) / 2447;
            int256 _day = L - (2447 * _month) / 80;
            L = _month / 11;
            _month = _month + 2 - 12 * L;
            _year = 100 * (N - 49) + _year + L;

            year = uint256(_year);
            month = uint256(_month);
            day = uint256(_day);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ICommonBlacklist {

    /**
     * @notice Limits struct
     */
    struct TokenLimit {
        uint256 inComeDay;
        uint256 inComeMonth;
        uint256 outComeDay;
        uint256 outComeMonth;
    }

    /**
     * @notice Limits struct
     */
    struct TokenTransfers {
        uint256 inCome;
        uint256 outCome;
    }

    /**
     * @notice Limits disabling struct
     */
    struct TokenLimitDisabling {
        bool hasInComeDayLimit;
        bool hasInComeMonthLimit;
        bool hasOutComeDayLimit;
        bool hasOutComeMonthLimit;
    }

    /**
     * @notice Add user to global blacklist
     * @param _users: users array for adding to blacklist
     *
     * @dev Callable by blacklist operator
     *
     */
    function addUsersToBlacklist(
        address[] memory _users
    ) external;

    /**
     * @notice Remove users from global blacklist
     * @param _users: users array for removing from blacklist
     *
     * @dev Callable by blacklist operator
     *
     */
    function removeUsersFromBlacklist(
        address[] memory _users
    ) external;

    /**
     * @notice Add user to internal blacklist
     * @param _token: address of token contract
     * @param _users: users array for adding to blacklist
     *
     * @dev Callable by blacklist operator
     *
     */
    function addUsersToInternalBlacklist(
        address _token,
        address[] memory _users
    ) external;

    /**
     * @notice Remove users from internal blacklist
     * @param _token: address of token contract
     * @param _users: users array for removing from blacklist
     *
     * @dev Callable by blacklist operator
     *
     */
    function removeUsersFromInternalBlacklist(
        address _token,
        address[] memory _users
    ) external;

    /**
     * @notice Getting information if user blacklisted
     * @param _sender: sender address
     * @param _from: from address
     * @param _to: to address
     *
     */
    function userIsBlacklisted(
        address _sender,
        address _from,
        address _to
    ) external view returns(bool);

    /**
     * @notice Getting information if user in internal blacklist
     * @param _token: address of token contract
     * @param _sender: sender address
     * @param _from: from address
     * @param _to: to address
     *
     */
    function userIsInternalBlacklisted(
        address _token,
        address _sender,
        address _from,
        address _to
    ) external view returns(bool);

    /**
     * @notice Getting information about the presence of users from the list in the blacklist
     * @param _token: address of token contract
     * @param _users: list of user address
     *
     */
    function usersFromListIsBlacklisted(
        address _token,
        address[] memory _users
    ) external view returns(address[] memory);

    /**
     * @notice Function returns current day
     */
    function getCurrentDay() external view returns(uint256);

    /**
     * @notice Function returns current month
     */
    function getCurrentMonth() external view returns(uint256);

    /**
     * @notice Setting token limits
     * @param _token: address of token contract
     * @param _inComeDayLimit: day limit for income token transfer
     * @param _inComeMonthLimit: month limit for income token transfer
     * @param _outComeDayLimit: day limit for outcome token transfer
     * @param _outComeMonthLimit: month limit for outcome token transfer
     *
     * @dev Callable by blacklist operator
     *
     */
    function settingTokenLimits(
        address _token,
        uint256 _inComeDayLimit,
        uint256 _inComeMonthLimit,
        uint256 _outComeDayLimit,
        uint256 _outComeMonthLimit
    ) external;

    /**
     * @notice Save income user transfers
     * @param _from: from address
     * @param _to: to address
     * @param _amount: amount of tokens
     *
     */
    function saveUserTransfers(
        address _from,
        address _to,
        uint256 _amount
    ) external;

    /**
     * @notice Adding Contracts to exclusion list
     * @param _contract: address of contract
     *
     * @dev Callable by blacklist operator
     *
     */
    function addContractToExclusionList(
        address _contract
    ) external;

    /**
     * @notice Removing Contracts from exclusion list
     * @param _contract: address of contract
     *
     * @dev Callable by blacklist operator
     *
     */
    function removeContractFromExclusionList(
        address _contract
    ) external;

    /**
     * @notice Checking the user for the limits allows
     * @param _token: address of token contract
     * @param _from: spender user address
     * @param _to: recipient user address
     * @param _amount: amount of tokens
     *
     */
    function limitAllows(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) external view returns(
        bool dayInComeLimitAllow,
        bool monthInComeLimitAllow,
        bool dayOutComeLimitAllow,
        bool monthOutComeLimitAllow
    );

    /**
     * @notice Getting token limits
     * @param _token: address of token contract
     *
     */
    function getTokenLimits(
        address _token
    ) external view returns(TokenLimit memory);

    /**
     * @notice Getting user token transfers
     * @param _token: address of token contract
     * @param _user: user address
     *
     */
    function getUserTokenTransfers(
        address _token,
        address _user
    ) external view returns(
        uint256 dayInComeTransfers,
        uint256 monthInComeTransfers,
        uint256 dayOutComeTransfers,
        uint256 monthOutComeTransfers
    );

    /**
     * @notice Disable/Enable token limits
     * @param _token: address of token contract
     * @param _hasInComeDayLimit: for disabling income day limits
     * @param _hasInComeMonthLimit: for disabling income month limits
     * @param _hasOutComeDayLimit: for disabling outcome day limits
     * @param _hasOutComeMonthLimit: for disabling outcome month limits
     *
     * @dev Callable by blacklist operator
     *
     */
    function changeDisablingTokenLimits(
        address _token,
        bool _hasInComeDayLimit,
        bool _hasInComeMonthLimit,
        bool _hasOutComeDayLimit,
        bool _hasOutComeMonthLimit
    ) external;

    /**
     * @notice Getting remaining limit for user
     * @param _token: address of token contract
     * @param _user: user address
     *
     */
    function getUserRemainingLimit(
        address _token,
        address _user
    ) external view returns(
        uint256 dayInComeRemaining,
        uint256 monthInComeRemaining,
        uint256 dayOutComeRemaining,
        uint256 monthOutComeRemaining
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
        _checkRole(role);
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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