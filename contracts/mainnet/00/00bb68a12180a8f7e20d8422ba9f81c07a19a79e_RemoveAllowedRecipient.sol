/**
 *Submitted for verification at Etherscan.io on 2022-11-23
*/

// SPDX-License-Identifier: MIT & GPL-3.0
// SPDX-FileCopyrightText: 2021 Lido <[email protected]>


pragma solidity ^0.8.4;

/// @author psirex
/// @notice A helper contract contains logic to validate that only a trusted caller has access to certain methods.
/// @dev Trusted caller set once on deployment and can't be changed.
contract TrustedCaller {
    string private constant ERROR_TRUSTED_CALLER_IS_ZERO_ADDRESS = "TRUSTED_CALLER_IS_ZERO_ADDRESS";
    string private constant ERROR_CALLER_IS_FORBIDDEN = "CALLER_IS_FORBIDDEN";

    address public immutable trustedCaller;

    constructor(address _trustedCaller) {
        require(_trustedCaller != address(0), ERROR_TRUSTED_CALLER_IS_ZERO_ADDRESS);
        trustedCaller = _trustedCaller;
    }

    modifier onlyTrustedCaller(address _caller) {
        require(_caller == trustedCaller, ERROR_CALLER_IS_FORBIDDEN);
        _;
    }
}
// SPDX-FileCopyrightText: 2021 Lido <[email protected]>




/// @author psirex
/// @notice Contains methods for convenient creation
/// of EVMScripts in EVMScript factories contracts
library EVMScriptCreator {
    // Id of default CallsScript Aragon's executor.
    bytes4 private constant SPEC_ID = hex"00000001";

    /// @notice Encodes one method call as EVMScript
    function createEVMScript(
        address _to,
        bytes4 _methodId,
        bytes memory _evmScriptCallData
    ) internal pure returns (bytes memory _commands) {
        return
            abi.encodePacked(
                SPEC_ID,
                _to,
                uint32(_evmScriptCallData.length) + 4,
                _methodId,
                _evmScriptCallData
            );
    }

    /// @notice Encodes multiple calls of the same method on one contract as EVMScript
    function createEVMScript(
        address _to,
        bytes4 _methodId,
        bytes[] memory _evmScriptCallData
    ) internal pure returns (bytes memory _evmScript) {
        for (uint256 i = 0; i < _evmScriptCallData.length; ++i) {
            _evmScript = bytes.concat(
                _evmScript,
                abi.encodePacked(
                    _to,
                    uint32(_evmScriptCallData[i].length) + 4,
                    _methodId,
                    _evmScriptCallData[i]
                )
            );
        }
        _evmScript = bytes.concat(SPEC_ID, _evmScript);
    }

    /// @notice Encodes multiple calls to different methods within the same contract as EVMScript
    function createEVMScript(
        address _to,
        bytes4[] memory _methodIds,
        bytes[] memory _evmScriptCallData
    ) internal pure returns (bytes memory _evmScript) {
        require(_methodIds.length == _evmScriptCallData.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < _methodIds.length; ++i) {
            _evmScript = bytes.concat(
                _evmScript,
                abi.encodePacked(
                    _to,
                    uint32(_evmScriptCallData[i].length) + 4,
                    _methodIds[i],
                    _evmScriptCallData[i]
                )
            );
        }
        _evmScript = bytes.concat(SPEC_ID, _evmScript);
    }

    /// @notice Encodes multiple calls to different contracts as EVMScript
    function createEVMScript(
        address[] memory _to,
        bytes4[] memory _methodIds,
        bytes[] memory _evmScriptCallData
    ) internal pure returns (bytes memory _evmScript) {
        require(_to.length == _methodIds.length, "LENGTH_MISMATCH");
        require(_to.length == _evmScriptCallData.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < _to.length; ++i) {
            _evmScript = bytes.concat(
                _evmScript,
                abi.encodePacked(
                    _to[i],
                    uint32(_evmScriptCallData[i].length) + 4,
                    _methodIds[i],
                    _evmScriptCallData[i]
                )
            );
        }
        _evmScript = bytes.concat(SPEC_ID, _evmScript);
    }
}
// SPDX-FileCopyrightText: 2022 Lido <[email protected]>




/// @author zuzueeka
/// @notice Interface of methods from BokkyPooBahsDateTimeContract to deal with dates
interface IBokkyPooBahsDateTimeContract {
    function timestampToDate(uint256 timestamp)
        external
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        );

    function timestampFromDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) external pure returns (uint256 timestamp);

    function addMonths(uint256 timestamp, uint256 _months)
        external
        pure
        returns (uint256 newTimestamp);
}




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
// SPDX-FileCopyrightText: 2022 Lido <[email protected]>









/// @author zuzueeka
/// @notice Stores limits params and provides limit-enforcement logic
///
/// ▲ spendableBalance = limit-spentAmount
/// |
/// │             |................              |..               limit-spentAmount = limit-0 = limit
/// │.....        |                ...           |
/// │     ........|                   ......     |  ..............
///               |                         .....|
/// │─────────────────────────────────────────────────────────────> Time
/// |     ^       |                ^  ^     ^    |  ^              (^ - Motion enactment)
/// │             |currentPeriodEndTimestamp     |currentPeriodEndTimestamp
/// |             |spentAmount=0                 |spentAmount=0
///
/// currentPeriodEndTimestamp is calculated as a calendar date of the beginning of
/// a next month, bi-months, quarter, half year, or year period.
/// If, for example, periodDurationMonths = 3, then it is considered that the date changes once a quarter.
/// And currentPeriodEndTimestamp can take values 1 Apr, 1 Jul, 1 Oct, 1 Jan.
/// If periodDurationMonths = 1, then shift of currentPeriodEndTimestamp occurs once a month
/// and currentPeriodEndTimestamp can take values 1 Feb, 1 Mar, 1 Apr, etc
///
contract LimitsChecker is AccessControl {
    // -------------
    // EVENTS
    // -------------
    event LimitsParametersChanged(uint256 _limit, uint256 _periodDurationMonths);
    event SpendableAmountChanged(
        uint256 _alreadySpentAmount,
        uint256 _spendableBalance,
        uint256 indexed _periodStartTimestamp,
        uint256 _periodEndTimestamp
    );
    event CurrentPeriodAdvanced(uint256 indexed _periodStartTimestamp);
    event BokkyPooBahsDateTimeContractChanged(address indexed _newAddress);
    event SpentAmountChanged(uint256 _newSpentAmount);

    // -------------
    // ERRORS
    // -------------
    string private constant ERROR_INVALID_PERIOD_DURATION = "INVALID_PERIOD_DURATION";
    string private constant ERROR_SUM_EXCEEDS_SPENDABLE_BALANCE = "SUM_EXCEEDS_SPENDABLE_BALANCE";
    string private constant ERROR_TOO_LARGE_LIMIT = "TOO_LARGE_LIMIT";
    string private constant ERROR_SAME_DATE_TIME_CONTRACT_ADDRESS =
        "SAME_DATE_TIME_CONTRACT_ADDRESS";
    string private constant ERROR_SPENT_AMOUNT_EXCEEDS_LIMIT = "ERROR_SPENT_AMOUNT_EXCEEDS_LIMIT";

    // -------------
    // ROLES
    // -------------
    bytes32 public constant SET_PARAMETERS_ROLE = keccak256("SET_PARAMETERS_ROLE");
    bytes32 public constant UPDATE_SPENT_AMOUNT_ROLE = keccak256("UPDATE_SPENT_AMOUNT_ROLE");

    // -------------
    // CONSTANTS
    // -------------

    // ------------
    // STORAGE VARIABLES
    // ------------

    /// @notice Address of BokkyPooBahsDateTimeContract
    IBokkyPooBahsDateTimeContract public bokkyPooBahsDateTimeContract;

    /// @notice Length of period in months
    uint64 internal periodDurationMonths;

    /// @notice End of the current period
    uint128 internal currentPeriodEndTimestamp;

    /// @notice The maximum that can be spent in a period
    uint128 internal limit;

    /// @notice Amount already spent in the period
    uint128 internal spentAmount;

    // ------------
    // CONSTRUCTOR
    // ------------
    /// @param _setParametersRoleHolders List of addresses which will
    ///     be granted with role SET_PARAMETERS_ROLE
    /// @param _updateSpentAmountRoleHolders List of addresses which will
    ///     be granted with role UPDATE_SPENT_AMOUNT_ROLE
    /// @param _bokkyPooBahsDateTimeContract Address of bokkyPooBahs DateTime Contract
    constructor(
        address[] memory _setParametersRoleHolders,
        address[] memory _updateSpentAmountRoleHolders,
        IBokkyPooBahsDateTimeContract _bokkyPooBahsDateTimeContract
    ) {
        for (uint256 i = 0; i < _setParametersRoleHolders.length; i++) {
            _setupRole(SET_PARAMETERS_ROLE, _setParametersRoleHolders[i]);
        }
        for (uint256 i = 0; i < _updateSpentAmountRoleHolders.length; i++) {
            _setupRole(UPDATE_SPENT_AMOUNT_ROLE, _updateSpentAmountRoleHolders[i]);
        }
        bokkyPooBahsDateTimeContract = _bokkyPooBahsDateTimeContract;
    }

    // -------------
    // EXTERNAL METHODS
    // -------------

    /// @notice Checks if _payoutAmount is less or equal than the may be spent
    /// @param _payoutAmount Motion total amount
    /// @param _motionDuration Motion duration - minimal time required to pass before enacting of motion
    /// @return True if _payoutAmount is less or equal than may be spent
    /// @dev note that upfront check is used to compare _paymentSum with total limit in case
    /// when motion is started in one period and will be probably enacted in the next.
    function isUnderSpendableBalance(uint256 _payoutAmount, uint256 _motionDuration)
        external
        view
        returns (bool)
    {
        if (block.timestamp + _motionDuration >= currentPeriodEndTimestamp) {
            return _payoutAmount <= limit;
        } else {
            return _payoutAmount <= _spendableBalance(limit, spentAmount);
        }
    }

    /// @notice Checks if _payoutAmount may be spent and increases spentAmount by _payoutAmount.
    /// @notice Also updates the period boundaries if necessary.
    function updateSpentAmount(uint256 _payoutAmount) external onlyRole(UPDATE_SPENT_AMOUNT_ROLE) {
        uint256 spentAmountLocal = spentAmount;
        uint256 limitLocal = limit;
        uint256 currentPeriodEndTimestampLocal = currentPeriodEndTimestamp;

        /// When it is necessary to shift the currentPeriodEndTimestamp it takes on a new value.
        /// And also spent is set to zero. Thus begins a new period.
        if (block.timestamp >= currentPeriodEndTimestampLocal) {
            currentPeriodEndTimestampLocal = _getPeriodEndFromTimestamp(block.timestamp);
            spentAmountLocal = 0;
            emit CurrentPeriodAdvanced(
                _getPeriodStartFromTimestamp(currentPeriodEndTimestampLocal - 1)
            );
            currentPeriodEndTimestamp = uint128(currentPeriodEndTimestampLocal);
        }

        require(
            _payoutAmount <= _spendableBalance(limitLocal, spentAmountLocal),
            ERROR_SUM_EXCEEDS_SPENDABLE_BALANCE
        );
        spentAmountLocal += _payoutAmount;
        spentAmount = uint128(spentAmountLocal);

        (
            uint256 alreadySpentAmount,
            uint256 spendableBalanceInPeriod,
            uint256 periodStartTimestamp,
            uint256 periodEndTimestamp
        ) = _getCurrentPeriodState(limitLocal, spentAmountLocal, currentPeriodEndTimestampLocal);

        emit SpendableAmountChanged(
            alreadySpentAmount,
            spendableBalanceInPeriod,
            periodStartTimestamp,
            periodEndTimestamp
        );
    }

    /// @notice Returns balance that can be spent in the current period
    /// @notice If period advanced and no call to updateSpentAmount or setLimitParameters made,
    /// @notice then the method will return spendable balance corresponding to the previous period.
    /// @return Balance that can be spent in the current period
    function spendableBalance() external view returns (uint256) {
        return _spendableBalance(limit, spentAmount);
    }

    /// @notice Sets periodDurationMonths and limit
    /// @notice Calculates currentPeriodEndTimestamp as a calendar date of the beginning of next period.
    /// @param _limit Limit to set
    /// @param _periodDurationMonths Length of period in months. Must be 1, 2, 3, 6 or 12.
    function setLimitParameters(uint256 _limit, uint256 _periodDurationMonths)
        external
        onlyRole(SET_PARAMETERS_ROLE)
    {
        require(_limit <= type(uint128).max, ERROR_TOO_LARGE_LIMIT);

        _validatePeriodDurationMonths(_periodDurationMonths);
        periodDurationMonths = uint64(_periodDurationMonths);
        uint256 currentPeriodEndTimestampLocal = _getPeriodEndFromTimestamp(block.timestamp);
        emit CurrentPeriodAdvanced(
            _getPeriodStartFromTimestamp(currentPeriodEndTimestampLocal - 1)
        );
        currentPeriodEndTimestamp = uint128(currentPeriodEndTimestampLocal);
        limit = uint128(_limit);

        emit LimitsParametersChanged(_limit, _periodDurationMonths);
    }

    /// @notice Returns limit and periodDurationMonths
    /// @return limit - the maximum that can be spent in a period
    /// @return periodDurationMonths - length of period in months
    function getLimitParameters() external view returns (uint256, uint256) {
        return (limit, periodDurationMonths);
    }

    /// @notice Returns state of the current period: amount spent, balance available for spending,
    /// @notice start date of the current period and end date of the current period
    /// @notice If period advanced and the period was not shifted,
    /// @notice then the method will return spendable balance corresponding to the previous period.
    /// @return _alreadySpentAmount - amount already spent in the current period
    /// @return _spendableBalanceInPeriod - balance available for spending in the current period
    /// @return _periodStartTimestamp - start date of the current period
    /// @return _periodEndTimestamp - end date of the current period
    function getPeriodState()
        external
        view
        returns (
            uint256 _alreadySpentAmount,
            uint256 _spendableBalanceInPeriod,
            uint256 _periodStartTimestamp,
            uint256 _periodEndTimestamp
        )
    {
        return _getCurrentPeriodState(limit, spentAmount, currentPeriodEndTimestamp);
    }

    /// @notice Sets address of BokkyPooBahsDateTime contract
    /// @dev Need this to be able to replace the contract in case of a bug in it
    /// @param _bokkyPooBahsDateTimeContract New address of the BokkyPooBahsDateTime library
    function setBokkyPooBahsDateTimeContract(address _bokkyPooBahsDateTimeContract)
        external
        onlyRole(SET_PARAMETERS_ROLE)
    {
        require(
            _bokkyPooBahsDateTimeContract != address(bokkyPooBahsDateTimeContract),
            ERROR_SAME_DATE_TIME_CONTRACT_ADDRESS
        );

        bokkyPooBahsDateTimeContract = IBokkyPooBahsDateTimeContract(_bokkyPooBahsDateTimeContract);
        emit BokkyPooBahsDateTimeContractChanged(_bokkyPooBahsDateTimeContract);
    }

    /// @notice Allows setting the amount of spent tokens in the current period manually
    /// @param _newSpentAmount New value for the amount of spent tokens in the current period
    function unsafeSetSpentAmount(uint256 _newSpentAmount) external onlyRole(SET_PARAMETERS_ROLE) {
        require(_newSpentAmount <= limit, ERROR_SPENT_AMOUNT_EXCEEDS_LIMIT);

        if (spentAmount != _newSpentAmount) {
            spentAmount = uint128(_newSpentAmount);
            emit SpentAmountChanged(_newSpentAmount);
        }
    }

    // ------------------
    // PRIVATE METHODS
    // ------------------
    function _getCurrentPeriodState(
        uint256 _limit,
        uint256 _spentAmount,
        uint256 _currentPeriodEndTimestamp
    )
        internal
        view
        returns (
            uint256 _alreadySpentAmount,
            uint256 _spendableBalanceInPeriod,
            uint256 _periodStartTimestamp,
            uint256 _periodEndTimestamp
        )
    {
        return (
            _spentAmount,
            _spendableBalance(_limit, _spentAmount),
            _getPeriodStartFromTimestamp(_currentPeriodEndTimestamp - 1),
            _currentPeriodEndTimestamp
        );
    }

    function _spendableBalance(uint256 _limit, uint256 _spentAmount)
        internal
        pure
        returns (uint256)
    {
        return _spentAmount < _limit ? _limit - _spentAmount : 0;
    }

    function _validatePeriodDurationMonths(uint256 _periodDurationMonths) internal pure {
        require(
            _periodDurationMonths == 1 ||
                _periodDurationMonths == 2 ||
                _periodDurationMonths == 3 ||
                _periodDurationMonths == 6 ||
                _periodDurationMonths == 12,
            ERROR_INVALID_PERIOD_DURATION
        );
    }

    function _getPeriodStartFromTimestamp(uint256 _timestamp) internal view returns (uint256) {
        // Get year and number of month of the timestamp:
        (uint256 year, uint256 month, ) = bokkyPooBahsDateTimeContract.timestampToDate(_timestamp);
        // We assume that the year will remain the same,
        // because the beginning of the current calendar period will necessarily be in the same year.
        uint256 periodStartYear = year;
        // Get the number of the start date month:
        uint256 periodStartMonth = _getFirstMonthInPeriodFromMonth(month, periodDurationMonths);
        // The beginning of the period always matches the calendar date of the beginning of the month.
        uint256 periodStartDay = 1;
        return
            bokkyPooBahsDateTimeContract.timestampFromDate(
                periodStartYear,
                periodStartMonth,
                periodStartDay
            );
    }

    function _getFirstMonthInPeriodFromMonth(uint256 _month, uint256 _periodDurationMonths)
        internal
        pure
        returns (uint256 _firstMonthInPeriod)
    {
        require(_periodDurationMonths != 0, ERROR_INVALID_PERIOD_DURATION);

        // To get the number of the first month in the period:
        //   1. get the number of the period within the current year, starting from its beginning:
        uint256 periodNumber = (_month - 1) / _periodDurationMonths;
        //   2. and then the number of the first month in this period:
        _firstMonthInPeriod = periodNumber * _periodDurationMonths + 1;
        // The shift by - 1 and then by + 1 happens because the months in the calendar start from 1 and not from 0.
    }

    function _getPeriodEndFromTimestamp(uint256 _timestamp) internal view returns (uint256) {
        uint256 periodStart = _getPeriodStartFromTimestamp(_timestamp);
        return bokkyPooBahsDateTimeContract.addMonths(periodStart, periodDurationMonths);
    }
}
// SPDX-FileCopyrightText: 2022 Lido <[email protected]>






/// @author psirex, zuzueeka
/// @title Registry of allowed addresses for payouts
/// @notice Stores list of allowed addresses
contract AllowedRecipientsRegistry is LimitsChecker {
    // -------------
    // EVENTS
    // -------------
    event RecipientAdded(address indexed _recipient, string _title);
    event RecipientRemoved(address indexed _recipient);

    // -------------
    // ROLES
    // -------------
    bytes32 public constant ADD_RECIPIENT_TO_ALLOWED_LIST_ROLE =
        keccak256("ADD_RECIPIENT_TO_ALLOWED_LIST_ROLE");
    bytes32 public constant REMOVE_RECIPIENT_FROM_ALLOWED_LIST_ROLE =
        keccak256("REMOVE_RECIPIENT_FROM_ALLOWED_LIST_ROLE");

    // -------------
    // ERRORS
    // -------------
    string private constant ERROR_RECIPIENT_ALREADY_ADDED_TO_ALLOWED_LIST =
        "RECIPIENT_ALREADY_ADDED_TO_ALLOWED_LIST";
    string private constant ERROR_RECIPIENT_NOT_FOUND_IN_ALLOWED_LIST =
        "RECIPIENT_NOT_FOUND_IN_ALLOWED_LIST";

    // -------------
    // VARIABLES
    // -------------

    /// @dev List of allowed addresses for payouts
    address[] public allowedRecipients;

    // Position of the address in the `allowedRecipients` array,
    // plus 1 because index 0 means a value is not in the set.
    mapping(address => uint256) private allowedRecipientIndices;

    // -------------
    // CONSTRUCTOR
    // -------------

    /// @param _admin Address which will be granted with role DEFAULT_ADMIN_ROLE
    /// @param _addRecipientToAllowedListRoleHolders List of addresses which will be
    ///     granted with role ADD_RECIPIENT_TO_ALLOWED_LIST_ROLE
    /// @param _removeRecipientFromAllowedListRoleHolders List of addresses which will
    ///     be granted with role REMOVE_RECIPIENT_FROM_ALLOWED_LIST_ROLE
    /// @param _setParametersRoleHolders List of addresses which will
    ///     be granted with role SET_PARAMETERS_ROLE
    /// @param _updateSpentAmountRoleHolders List of addresses which will
    ///     be granted with role UPDATE_SPENT_AMOUNT_ROLE
    /// @param _bokkyPooBahsDateTimeContract Address of bokkyPooBahs DateTime Contract
    constructor(
        address _admin,
        address[] memory _addRecipientToAllowedListRoleHolders,
        address[] memory _removeRecipientFromAllowedListRoleHolders,
        address[] memory _setParametersRoleHolders,
        address[] memory _updateSpentAmountRoleHolders,
        IBokkyPooBahsDateTimeContract _bokkyPooBahsDateTimeContract
    )
        LimitsChecker(
            _setParametersRoleHolders,
            _updateSpentAmountRoleHolders,
            _bokkyPooBahsDateTimeContract
        )
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        for (uint256 i = 0; i < _addRecipientToAllowedListRoleHolders.length; i++) {
            _setupRole(
                ADD_RECIPIENT_TO_ALLOWED_LIST_ROLE,
                _addRecipientToAllowedListRoleHolders[i]
            );
        }
        for (uint256 i = 0; i < _removeRecipientFromAllowedListRoleHolders.length; i++) {
            _setupRole(
                REMOVE_RECIPIENT_FROM_ALLOWED_LIST_ROLE,
                _removeRecipientFromAllowedListRoleHolders[i]
            );
        }
    }

    // -------------
    // EXTERNAL METHODS
    // -------------

    /// @notice Adds address to list of allowed addresses for payouts
    function addRecipient(address _recipient, string memory _title)
        external
        onlyRole(ADD_RECIPIENT_TO_ALLOWED_LIST_ROLE)
    {
        require(
            allowedRecipientIndices[_recipient] == 0,
            ERROR_RECIPIENT_ALREADY_ADDED_TO_ALLOWED_LIST
        );

        allowedRecipients.push(_recipient);
        allowedRecipientIndices[_recipient] = allowedRecipients.length;
        emit RecipientAdded(_recipient, _title);
    }

    /// @notice Removes address from list of allowed addresses for payouts
    /// @dev To delete an allowed address from the allowedRecipients array in O(1),
    /// we swap the element to delete with the last one in the array,
    /// and then remove the last element (sometimes called as 'swap and pop').
    function removeRecipient(address _recipient)
        external
        onlyRole(REMOVE_RECIPIENT_FROM_ALLOWED_LIST_ROLE)
    {
        uint256 index = _getAllowedRecipientIndex(_recipient);
        uint256 lastIndex = allowedRecipients.length - 1;

        if (index != lastIndex) {
            address lastAllowedRecipient = allowedRecipients[lastIndex];
            allowedRecipients[index] = lastAllowedRecipient;
            allowedRecipientIndices[lastAllowedRecipient] = index + 1;
        }

        allowedRecipients.pop();
        delete allowedRecipientIndices[_recipient];
        emit RecipientRemoved(_recipient);
    }

    /// @notice Returns if passed address is listed as allowed recipient in the registry
    function isRecipientAllowed(address _recipient) external view returns (bool) {
        return allowedRecipientIndices[_recipient] > 0;
    }

    /// @notice Returns current list of allowed recipients
    function getAllowedRecipients() external view returns (address[] memory) {
        return allowedRecipients;
    }

    // ------------------
    // PRIVATE METHODS
    // ------------------

    function _getAllowedRecipientIndex(address _recipient) private view returns (uint256 _index) {
        _index = allowedRecipientIndices[_recipient];
        require(_index > 0, ERROR_RECIPIENT_NOT_FOUND_IN_ALLOWED_LIST);
        _index -= 1;
    }
}
// SPDX-FileCopyrightText: 2021 Lido <[email protected]>




/// @author psirex
/// @notice Interface which every EVMScript factory used in EasyTrack contract has to implement
interface IEVMScriptFactory {
    function createEVMScript(address _creator, bytes memory _evmScriptCallData)
        external
        returns (bytes memory);
}
// SPDX-FileCopyrightText: 2022 Lido <[email protected]>









/// @author psirex, zuzueeka
/// @notice Creates EVMScript to remove allowed recipient address from AllowedRecipientsRegistry
contract RemoveAllowedRecipient is TrustedCaller, IEVMScriptFactory {
    // -------------
    // ERRORS
    // -------------
    string private constant ERROR_ALLOWED_RECIPIENT_NOT_FOUND = "ALLOWED_RECIPIENT_NOT_FOUND";

    // -------------
    // VARIABLES
    // -------------

    /// @notice Address of AllowedRecipientsRegistry
    AllowedRecipientsRegistry public allowedRecipientsRegistry;

    // -------------
    // CONSTRUCTOR
    // -------------

    constructor(address _trustedCaller, address _allowedRecipientsRegistry)
        TrustedCaller(_trustedCaller)
    {
        allowedRecipientsRegistry = AllowedRecipientsRegistry(_allowedRecipientsRegistry);
    }

    // -------------
    // EXTERNAL METHODS
    // -------------

    /// @notice Creates EVMScript to remove allowed recipient address from allowedRecipientsRegistry
    /// @param _creator Address who creates EVMScript
    /// @param _evmScriptCallData Encoded tuple: (address recipientAddress)
    function createEVMScript(address _creator, bytes memory _evmScriptCallData)
        external
        view
        override
        onlyTrustedCaller(_creator)
        returns (bytes memory)
    {
        require(
            allowedRecipientsRegistry.isRecipientAllowed(
                _decodeEVMScriptCallData(_evmScriptCallData)
            ),
            ERROR_ALLOWED_RECIPIENT_NOT_FOUND
        );
        return
            EVMScriptCreator.createEVMScript(
                address(allowedRecipientsRegistry),
                allowedRecipientsRegistry.removeRecipient.selector,
                _evmScriptCallData
            );
    }

    /// @notice Decodes call data used by createEVMScript method
    /// @param _evmScriptCallData Encoded tuple: (address recipientAddress)
    /// @return recipientAddress Address to remove
    function decodeEVMScriptCallData(bytes memory _evmScriptCallData)
        external
        pure
        returns (address recipientAddress)
    {
        return _decodeEVMScriptCallData(_evmScriptCallData);
    }

    // ------------------
    // PRIVATE METHODS
    // ------------------

    function _decodeEVMScriptCallData(bytes memory _evmScriptCallData)
        private
        pure
        returns (address)
    {
        return abi.decode(_evmScriptCallData, (address));
    }
}