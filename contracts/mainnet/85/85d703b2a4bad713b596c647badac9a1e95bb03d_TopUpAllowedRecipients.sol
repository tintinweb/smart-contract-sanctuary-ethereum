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
/// @notice Interface of method from Aragon's Finance contract to create a new payment
interface IFinance {
    function newImmediatePayment(
        address _token,
        address _receiver,
        uint256 _amount,
        string memory _reference
    ) external;
}
// SPDX-FileCopyrightText: 2021 Lido <[email protected]>




/// @author psirex
/// @notice Interface which every EVMScript factory used in EasyTrack contract has to implement
interface IEVMScriptFactory {
    function createEVMScript(address _creator, bytes memory _evmScriptCallData)
        external
        returns (bytes memory);
}
// SPDX-FileCopyrightText: 2021 Lido <[email protected]>






/// @author psirex
/// @notice Provides methods to update motion duration, objections threshold, and limit of active motions of Easy Track
contract MotionSettings is AccessControl {
    // -------------
    // EVENTS
    // -------------
    event MotionDurationChanged(uint256 _motionDuration);
    event MotionsCountLimitChanged(uint256 _newMotionsCountLimit);
    event ObjectionsThresholdChanged(uint256 _newThreshold);

    // -------------
    // ERRORS
    // -------------

    string private constant ERROR_VALUE_TOO_SMALL = "VALUE_TOO_SMALL";
    string private constant ERROR_VALUE_TOO_LARGE = "VALUE_TOO_LARGE";

    // ------------
    // CONSTANTS
    // ------------
    /// @notice Upper bound for motionsCountLimit variable.
    uint256 public constant MAX_MOTIONS_LIMIT = 24;

    /// @notice Upper bound for objectionsThreshold variable.
    /// @dev Stored in basis points (1% = 100)
    uint256 public constant MAX_OBJECTIONS_THRESHOLD = 500;

    /// @notice Lower bound for motionDuration variable
    uint256 public constant MIN_MOTION_DURATION = 48 hours;

    /// ------------------
    /// STORAGE VARIABLES
    /// ------------------

    /// @notice Percent from total supply of governance tokens required to reject motion.
    /// @dev Value stored in basis points: 1% == 100.
    uint256 public objectionsThreshold;

    /// @notice Max count of active motions
    uint256 public motionsCountLimit;

    /// @notice Minimal time required to pass before enacting of motion
    uint256 public motionDuration;

    // ------------
    // CONSTRUCTOR
    // ------------
    constructor(
        address _admin,
        uint256 _motionDuration,
        uint256 _motionsCountLimit,
        uint256 _objectionsThreshold
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setMotionDuration(_motionDuration);
        _setMotionsCountLimit(_motionsCountLimit);
        _setObjectionsThreshold(_objectionsThreshold);
    }

    // ------------------
    // EXTERNAL METHODS
    // ------------------

    /// @notice Sets the minimal time required to pass before enacting of motion
    function setMotionDuration(uint256 _motionDuration) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setMotionDuration(_motionDuration);
    }

    /// @notice Sets percent from total supply of governance tokens required to reject motion
    function setObjectionsThreshold(uint256 _objectionsThreshold)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setObjectionsThreshold(_objectionsThreshold);
    }

    /// @notice Sets max count of active motions.
    function setMotionsCountLimit(uint256 _motionsCountLimit)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setMotionsCountLimit(_motionsCountLimit);
    }

    function _setMotionDuration(uint256 _motionDuration) internal {
        require(_motionDuration >= MIN_MOTION_DURATION, ERROR_VALUE_TOO_SMALL);
        motionDuration = _motionDuration;
        emit MotionDurationChanged(_motionDuration);
    }

    function _setObjectionsThreshold(uint256 _objectionsThreshold) internal {
        require(_objectionsThreshold <= MAX_OBJECTIONS_THRESHOLD, ERROR_VALUE_TOO_LARGE);
        objectionsThreshold = _objectionsThreshold;
        emit ObjectionsThresholdChanged(_objectionsThreshold);
    }

    function _setMotionsCountLimit(uint256 _motionsCountLimit) internal {
        require(_motionsCountLimit <= MAX_MOTIONS_LIMIT, ERROR_VALUE_TOO_LARGE);
        motionsCountLimit = _motionsCountLimit;
        emit MotionsCountLimitChanged(_motionsCountLimit);
    }
}
// SPDX-FileCopyrightText: 2021 Lido <[email protected]>




/// @author psirex
/// @notice Contains methods to extract primitive types from bytes
library BytesUtils {
    function bytes24At(bytes memory data, uint256 location) internal pure returns (bytes24 result) {
        uint256 word = uint256At(data, location);
        assembly {
            result := word
        }
    }

    function addressAt(bytes memory data, uint256 location) internal pure returns (address result) {
        uint256 word = uint256At(data, location);
        assembly {
            result := shr(
                96,
                and(word, 0xffffffffffffffffffffffffffffffffffffffff000000000000000000000000)
            )
        }
    }

    function uint32At(bytes memory _data, uint256 _location) internal pure returns (uint32 result) {
        uint256 word = uint256At(_data, _location);

        assembly {
            result := shr(
                224,
                and(word, 0xffffffff00000000000000000000000000000000000000000000000000000000)
            )
        }
    }

    function uint256At(bytes memory data, uint256 location) internal pure returns (uint256 result) {
        assembly {
            result := mload(add(data, add(0x20, location)))
        }
    }
}
// SPDX-FileCopyrightText: 2021 Lido <[email protected]>






/// @author psirex
/// @notice Provides methods to convinient work with permissions bytes
/// @dev Permissions - is a list of tuples (address, bytes4) encoded into a bytes representation.
/// Each tuple (address, bytes4) describes a method allowed to be called by EVMScript
library EVMScriptPermissions {
    using BytesUtils for bytes;

    // -------------
    // CONSTANTS
    // -------------

    /// Bytes size of SPEC_ID in EVMScript
    uint256 private constant SPEC_ID_SIZE = 4;

    /// Size of the address type in bytes
    uint256 private constant ADDRESS_SIZE = 20;

    /// Bytes size of calldata length in EVMScript
    uint256 private constant CALLDATA_LENGTH_SIZE = 4;

    /// Bytes size of method selector
    uint256 private constant METHOD_SELECTOR_SIZE = 4;

    /// Bytes size of one item in permissions
    uint256 private constant PERMISSION_SIZE = ADDRESS_SIZE + METHOD_SELECTOR_SIZE;

    // ------------------
    // INTERNAL METHODS
    // ------------------

    /// @notice Validates that passed EVMScript calls only methods allowed in permissions.
    /// @dev Returns false if provided permissions are invalid (has a wrong length or empty)
    function canExecuteEVMScript(bytes memory _permissions, bytes memory _evmScript)
        internal
        pure
        returns (bool)
    {
        uint256 location = SPEC_ID_SIZE; // first 4 bytes reserved for SPEC_ID
        if (!isValidPermissions(_permissions) || _evmScript.length <= location) {
            return false;
        }

        while (location < _evmScript.length) {
            (bytes24 methodToCall, uint32 callDataLength) = _getNextMethodId(_evmScript, location);
            if (!_hasPermission(_permissions, methodToCall)) {
                return false;
            }
            location += ADDRESS_SIZE + CALLDATA_LENGTH_SIZE + callDataLength;
        }
        return true;
    }

    /// @notice Validates that bytes with permissions not empty and has correct length
    function isValidPermissions(bytes memory _permissions) internal pure returns (bool) {
        return _permissions.length > 0 && _permissions.length % PERMISSION_SIZE == 0;
    }

    // Retrieves bytes24 which describes tuple (address, bytes4)
    // from EVMScript starting from _location position
    function _getNextMethodId(bytes memory _evmScript, uint256 _location)
        private
        pure
        returns (bytes24, uint32)
    {
        address recipient = _evmScript.addressAt(_location);
        uint32 callDataLength = _evmScript.uint32At(_location + ADDRESS_SIZE);
        uint32 functionSelector =
            _evmScript.uint32At(_location + ADDRESS_SIZE + CALLDATA_LENGTH_SIZE);
        return (bytes24(uint192(functionSelector)) | bytes20(recipient), callDataLength);
    }

    // Validates that passed _methodToCall contained in permissions
    function _hasPermission(bytes memory _permissions, bytes24 _methodToCall)
        private
        pure
        returns (bool)
    {
        uint256 location = 0;
        while (location < _permissions.length) {
            bytes24 permission = _permissions.bytes24At(location);
            if (permission == _methodToCall) {
                return true;
            }
            location += PERMISSION_SIZE;
        }
        return false;
    }
}
// SPDX-FileCopyrightText: 2021 Lido <[email protected]>









/// @author psirex
/// @notice Provides methods to add/remove EVMScript factories
/// and contains an internal method for the convenient creation of EVMScripts
contract EVMScriptFactoriesRegistry is AccessControl {
    using EVMScriptPermissions for bytes;

    // -------------
    // EVENTS
    // -------------

    event EVMScriptFactoryAdded(address indexed _evmScriptFactory, bytes _permissions);
    event EVMScriptFactoryRemoved(address indexed _evmScriptFactory);

    // ------------
    // STORAGE VARIABLES
    // ------------

    /// @notice List of allowed EVMScript factories
    address[] public evmScriptFactories;

    // Position of the EVMScript factory in the `evmScriptFactories` array,
    // plus 1 because index 0 means a value is not in the set.
    mapping(address => uint256) internal evmScriptFactoryIndices;

    /// @notice Permissions of current list of allowed EVMScript factories.
    mapping(address => bytes) public evmScriptFactoryPermissions;

    // ------------
    // CONSTRUCTOR
    // ------------
    constructor(address _admin) {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    // ------------------
    // EXTERNAL METHODS
    // ------------------

    /// @notice Adds new EVMScript Factory to the list of allowed EVMScript factories with given permissions.
    /// Be careful about factories and their permissions added via this method. Only reviewed and tested
    /// factories must be added via this method.
    function addEVMScriptFactory(address _evmScriptFactory, bytes memory _permissions)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_permissions.isValidPermissions(), "INVALID_PERMISSIONS");
        require(!_isEVMScriptFactory(_evmScriptFactory), "EVM_SCRIPT_FACTORY_ALREADY_ADDED");
        evmScriptFactories.push(_evmScriptFactory);
        evmScriptFactoryIndices[_evmScriptFactory] = evmScriptFactories.length;
        evmScriptFactoryPermissions[_evmScriptFactory] = _permissions;
        emit EVMScriptFactoryAdded(_evmScriptFactory, _permissions);
    }

    /// @notice Removes EVMScript factory from the list of allowed EVMScript factories
    /// @dev To delete a EVMScript factory from the rewardPrograms array in O(1),
    /// we swap the element to delete with the last one in the array, and then remove
    /// the last element (sometimes called as 'swap and pop').
    function removeEVMScriptFactory(address _evmScriptFactory)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 index = _getEVMScriptFactoryIndex(_evmScriptFactory);
        uint256 lastIndex = evmScriptFactories.length - 1;

        if (index != lastIndex) {
            address lastEVMScriptFactory = evmScriptFactories[lastIndex];
            evmScriptFactories[index] = lastEVMScriptFactory;
            evmScriptFactoryIndices[lastEVMScriptFactory] = index + 1;
        }

        evmScriptFactories.pop();
        delete evmScriptFactoryIndices[_evmScriptFactory];
        delete evmScriptFactoryPermissions[_evmScriptFactory];
        emit EVMScriptFactoryRemoved(_evmScriptFactory);
    }

    /// @notice Returns current list of EVMScript factories
    function getEVMScriptFactories() external view returns (address[] memory) {
        return evmScriptFactories;
    }

    /// @notice Returns if passed address are listed as EVMScript factory in the registry
    function isEVMScriptFactory(address _maybeEVMScriptFactory) external view returns (bool) {
        return _isEVMScriptFactory(_maybeEVMScriptFactory);
    }

    // ------------------
    // INTERNAL METHODS
    // ------------------

    /// @notice Creates EVMScript using given EVMScript factory
    /// @dev Checks permissions of resulting EVMScript and reverts with error
    /// if script tries to call methods not listed in permissions
    function _createEVMScript(
        address _evmScriptFactory,
        address _creator,
        bytes memory _evmScriptCallData
    ) internal returns (bytes memory _evmScript) {
        require(_isEVMScriptFactory(_evmScriptFactory), "EVM_SCRIPT_FACTORY_NOT_FOUND");
        _evmScript = IEVMScriptFactory(_evmScriptFactory).createEVMScript(
            _creator,
            _evmScriptCallData
        );
        bytes memory permissions = evmScriptFactoryPermissions[_evmScriptFactory];
        require(permissions.canExecuteEVMScript(_evmScript), "HAS_NO_PERMISSIONS");
    }

    // ------------------
    // PRIVATE METHODS
    // ------------------

    function _getEVMScriptFactoryIndex(address _evmScriptFactory)
        private
        view
        returns (uint256 _index)
    {
        _index = evmScriptFactoryIndices[_evmScriptFactory];
        require(_index > 0, "EVM_SCRIPT_FACTORY_NOT_FOUND");
        _index -= 1;
    }

    function _isEVMScriptFactory(address _maybeEVMScriptFactory) private view returns (bool) {
        return evmScriptFactoryIndices[_maybeEVMScriptFactory] > 0;
    }
}
// SPDX-FileCopyrightText: 2021 Lido <[email protected]>




/// @notice Interface of EVMScript executor used by EasyTrack
interface IEVMScriptExecutor {
    function executeEVMScript(bytes memory _evmScript) external returns (bytes memory);
}






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
// SPDX-FileCopyrightText: 2021 Lido <[email protected]>











interface IMiniMeToken {
    function balanceOfAt(address _owner, uint256 _blockNumber) external pure returns (uint256);

    function totalSupplyAt(uint256 _blockNumber) external view returns (uint256);
}

/// @author psirex
/// @notice Contains main logic of Easy Track
contract EasyTrack is Pausable, AccessControl, MotionSettings, EVMScriptFactoriesRegistry {
    struct Motion {
        uint256 id;
        address evmScriptFactory;
        address creator;
        uint256 duration;
        uint256 startDate;
        uint256 snapshotBlock;
        uint256 objectionsThreshold;
        uint256 objectionsAmount;
        bytes32 evmScriptHash;
    }

    // -------------
    // EVENTS
    // -------------
    event MotionCreated(
        uint256 indexed _motionId,
        address _creator,
        address indexed _evmScriptFactory,
        bytes _evmScriptCallData,
        bytes _evmScript
    );
    event MotionObjected(
        uint256 indexed _motionId,
        address indexed _objector,
        uint256 _weight,
        uint256 _newObjectionsAmount,
        uint256 _newObjectionsAmountPct
    );
    event MotionRejected(uint256 indexed _motionId);
    event MotionCanceled(uint256 indexed _motionId);
    event MotionEnacted(uint256 indexed _motionId);
    event EVMScriptExecutorChanged(address indexed _evmScriptExecutor);

    // -------------
    // ERRORS
    // -------------
    string private constant ERROR_ALREADY_OBJECTED = "ALREADY_OBJECTED";
    string private constant ERROR_NOT_ENOUGH_BALANCE = "NOT_ENOUGH_BALANCE";
    string private constant ERROR_NOT_CREATOR = "NOT_CREATOR";
    string private constant ERROR_MOTION_NOT_PASSED = "MOTION_NOT_PASSED";
    string private constant ERROR_UNEXPECTED_EVM_SCRIPT = "UNEXPECTED_EVM_SCRIPT";
    string private constant ERROR_MOTION_NOT_FOUND = "MOTION_NOT_FOUND";
    string private constant ERROR_MOTIONS_LIMIT_REACHED = "MOTIONS_LIMIT_REACHED";

    // -------------
    // ROLES
    // -------------
    bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE");
    bytes32 public constant UNPAUSE_ROLE = keccak256("UNPAUSE_ROLE");
    bytes32 public constant CANCEL_ROLE = keccak256("CANCEL_ROLE");

    // -------------
    // CONSTANTS
    // -------------

    // Stores 100% in basis points
    uint256 internal constant HUNDRED_PERCENT = 10000;

    // ------------
    // STORAGE VARIABLES
    // ------------

    /// @notice List of active motions
    Motion[] public motions;

    // Id of the lastly created motion
    uint256 internal lastMotionId;

    /// @notice Address of governanceToken which implements IMiniMeToken interface
    IMiniMeToken public governanceToken;

    /// @notice Address of current EVMScriptExecutor
    IEVMScriptExecutor public evmScriptExecutor;

    // Position of the motion in the `motions` array, plus 1
    // because index 0 means a value is not in the set.
    mapping(uint256 => uint256) internal motionIndicesByMotionId;

    /// @notice Stores if motion with given id has been objected from given address.
    mapping(uint256 => mapping(address => bool)) public objections;

    // ------------
    // CONSTRUCTOR
    // ------------
    constructor(
        address _governanceToken,
        address _admin,
        uint256 _motionDuration,
        uint256 _motionsCountLimit,
        uint256 _objectionsThreshold
    )
        EVMScriptFactoriesRegistry(_admin)
        MotionSettings(_admin, _motionDuration, _motionsCountLimit, _objectionsThreshold)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(PAUSE_ROLE, _admin);
        _setupRole(UNPAUSE_ROLE, _admin);
        _setupRole(CANCEL_ROLE, _admin);

        governanceToken = IMiniMeToken(_governanceToken);
    }

    // ------------------
    // EXTERNAL METHODS
    // ------------------

    /// @notice Creates new motion
    /// @param _evmScriptFactory Address of EVMScript factory registered in Easy Track
    /// @param _evmScriptCallData Encoded call data of EVMScript factory
    /// @return _newMotionId Id of created motion
    function createMotion(address _evmScriptFactory, bytes memory _evmScriptCallData)
        external
        whenNotPaused
        returns (uint256 _newMotionId)
    {
        require(motions.length < motionsCountLimit, ERROR_MOTIONS_LIMIT_REACHED);

        Motion storage newMotion = motions.push();
        _newMotionId = ++lastMotionId;

        newMotion.id = _newMotionId;
        newMotion.creator = msg.sender;
        newMotion.startDate = block.timestamp;
        newMotion.snapshotBlock = block.number;
        newMotion.duration = motionDuration;
        newMotion.objectionsThreshold = objectionsThreshold;
        newMotion.evmScriptFactory = _evmScriptFactory;
        motionIndicesByMotionId[_newMotionId] = motions.length;

        bytes memory evmScript =
            _createEVMScript(_evmScriptFactory, msg.sender, _evmScriptCallData);
        newMotion.evmScriptHash = keccak256(evmScript);

        emit MotionCreated(
            _newMotionId,
            msg.sender,
            _evmScriptFactory,
            _evmScriptCallData,
            evmScript
        );
    }

    /// @notice Enacts motion with given id
    /// @param _motionId Id of motion to enact
    /// @param _evmScriptCallData Encoded call data of EVMScript factory. Same as passed on the creation
    /// of motion with the given motion id. Transaction reverts if EVMScript factory call data differs
    function enactMotion(uint256 _motionId, bytes memory _evmScriptCallData)
        external
        whenNotPaused
    {
        Motion storage motion = _getMotion(_motionId);
        require(motion.startDate + motion.duration <= block.timestamp, ERROR_MOTION_NOT_PASSED);

        address creator = motion.creator;
        bytes32 evmScriptHash = motion.evmScriptHash;
        address evmScriptFactory = motion.evmScriptFactory;

        _deleteMotion(_motionId);
        emit MotionEnacted(_motionId);

        bytes memory evmScript = _createEVMScript(evmScriptFactory, creator, _evmScriptCallData);
        require(evmScriptHash == keccak256(evmScript), ERROR_UNEXPECTED_EVM_SCRIPT);

        evmScriptExecutor.executeEVMScript(evmScript);
    }

    /// @notice Submits an objection from `governanceToken` holder.
    /// @param _motionId Id of motion to object
    function objectToMotion(uint256 _motionId) external {
        Motion storage motion = _getMotion(_motionId);
        require(!objections[_motionId][msg.sender], ERROR_ALREADY_OBJECTED);
        objections[_motionId][msg.sender] = true;

        uint256 snapshotBlock = motion.snapshotBlock;
        uint256 objectorBalance = governanceToken.balanceOfAt(msg.sender, snapshotBlock);
        require(objectorBalance > 0, ERROR_NOT_ENOUGH_BALANCE);

        uint256 totalSupply = governanceToken.totalSupplyAt(snapshotBlock);
        uint256 newObjectionsAmount = motion.objectionsAmount + objectorBalance;
        uint256 newObjectionsAmountPct = (HUNDRED_PERCENT * newObjectionsAmount) / totalSupply;

        emit MotionObjected(
            _motionId,
            msg.sender,
            objectorBalance,
            newObjectionsAmount,
            newObjectionsAmountPct
        );

        if (newObjectionsAmountPct < motion.objectionsThreshold) {
            motion.objectionsAmount = newObjectionsAmount;
        } else {
            _deleteMotion(_motionId);
            emit MotionRejected(_motionId);
        }
    }

    /// @notice Cancels motion with given id
    /// @param _motionId Id of motion to cancel
    /// @dev Method reverts if it is called with not existed _motionId
    function cancelMotion(uint256 _motionId) external {
        Motion storage motion = _getMotion(_motionId);
        require(motion.creator == msg.sender, ERROR_NOT_CREATOR);
        _deleteMotion(_motionId);
        emit MotionCanceled(_motionId);
    }

    /// @notice Cancels all motions with given ids
    /// @param _motionIds Ids of motions to cancel
    function cancelMotions(uint256[] memory _motionIds) external onlyRole(CANCEL_ROLE) {
        for (uint256 i = 0; i < _motionIds.length; ++i) {
            if (motionIndicesByMotionId[_motionIds[i]] > 0) {
                _deleteMotion(_motionIds[i]);
                emit MotionCanceled(_motionIds[i]);
            }
        }
    }

    /// @notice Cancels all active motions
    function cancelAllMotions() external onlyRole(CANCEL_ROLE) {
        uint256 motionsCount = motions.length;
        while (motionsCount > 0) {
            motionsCount -= 1;
            uint256 motionId = motions[motionsCount].id;
            _deleteMotion(motionId);
            emit MotionCanceled(motionId);
        }
    }

    /// @notice Sets new EVMScriptExecutor
    /// @param _evmScriptExecutor Address of new EVMScriptExecutor
    function setEVMScriptExecutor(address _evmScriptExecutor)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        evmScriptExecutor = IEVMScriptExecutor(_evmScriptExecutor);
        emit EVMScriptExecutorChanged(_evmScriptExecutor);
    }

    /// @notice Pauses Easy Track if it isn't paused.
    /// Paused Easy Track can't create and enact motions
    function pause() external whenNotPaused onlyRole(PAUSE_ROLE) {
        _pause();
    }

    /// @notice Unpauses Easy Track if it is paused
    function unpause() external whenPaused onlyRole(UNPAUSE_ROLE) {
        _unpause();
    }

    /// @notice Returns if an _objector can submit an objection to motion with id equals to _motionId or not
    /// @param _motionId Id of motion to check opportunity to object
    /// @param _objector Address of objector
    function canObjectToMotion(uint256 _motionId, address _objector) external view returns (bool) {
        Motion storage motion = _getMotion(_motionId);
        uint256 balance = governanceToken.balanceOfAt(_objector, motion.snapshotBlock);
        return balance > 0 && !objections[_motionId][_objector];
    }

    /// @notice Returns list of active motions
    function getMotions() external view returns (Motion[] memory) {
        return motions;
    }

    /// @notice Returns motion with the given id
    /// @param _motionId Id of motion to retrieve
    function getMotion(uint256 _motionId) external view returns (Motion memory) {
        return _getMotion(_motionId);
    }

    // -------
    // PRIVATE METHODS
    // -------

    // Removes motion from list of active moitons
    // To delete a motion from the moitons array in O(1), we swap the element to delete with the last one in
    // the array, and then remove the last element (sometimes called as 'swap and pop').
    function _deleteMotion(uint256 _motionId) private {
        uint256 index = motionIndicesByMotionId[_motionId] - 1;
        uint256 lastIndex = motions.length - 1;

        if (index != lastIndex) {
            Motion storage lastMotion = motions[lastIndex];
            motions[index] = lastMotion;
            motionIndicesByMotionId[lastMotion.id] = index + 1;
        }

        motions.pop();
        delete motionIndicesByMotionId[_motionId];
    }

    // Returns motion with given id if it exists
    function _getMotion(uint256 _motionId) private view returns (Motion storage) {
        uint256 _motionIndex = motionIndicesByMotionId[_motionId];
        require(_motionIndex > 0, ERROR_MOTION_NOT_FOUND);
        return motions[_motionIndex - 1];
    }
}
// SPDX-FileCopyrightText: 2022 Lido <[email protected]>











/// @notice Creates EVMScript to top up allowed recipients addresses within the current spendable balance
contract TopUpAllowedRecipients is TrustedCaller, IEVMScriptFactory {
    // -------------
    // ERRORS
    // -------------
    string private constant ERROR_LENGTH_MISMATCH = "LENGTH_MISMATCH";
    string private constant ERROR_EMPTY_DATA = "EMPTY_DATA";
    string private constant ERROR_ZERO_AMOUNT = "ZERO_AMOUNT";
    string private constant ERROR_RECIPIENT_NOT_ALLOWED = "RECIPIENT_NOT_ALLOWED";
    string private constant ERROR_SUM_EXCEEDS_SPENDABLE_BALANCE = "SUM_EXCEEDS_SPENDABLE_BALANCE";

    // -------------
    // VARIABLES
    // -------------

    /// @notice Address of EasyTrack contract
    EasyTrack public immutable easyTrack;

    /// @notice Address of Aragon's Finance contract
    IFinance public immutable finance;

    /// @notice Address of payout token
    address public token;

    /// @notice Address of AllowedRecipientsRegistry contract
    AllowedRecipientsRegistry public allowedRecipientsRegistry;

    // -------------
    // CONSTRUCTOR
    // -------------

    /// @param _trustedCaller Address that has access to certain methods.
    ///     Set once on deployment and can't be changed.
    /// @param _allowedRecipientsRegistry Address of AllowedRecipientsRegistry contract
    /// @param _finance Address of Aragon's Finance contract
    /// @param _token Address of payout token
    /// @param _easyTrack Address of EasyTrack contract
    constructor(
        address _trustedCaller,
        address _allowedRecipientsRegistry,
        address _finance,
        address _token,
        address _easyTrack
    ) TrustedCaller(_trustedCaller) {
        finance = IFinance(_finance);
        token = _token;
        allowedRecipientsRegistry = AllowedRecipientsRegistry(_allowedRecipientsRegistry);
        easyTrack = EasyTrack(_easyTrack);
    }

    // -------------
    // EXTERNAL METHODS
    // -------------

    /// @notice Creates EVMScript to top up allowed recipients addresses
    /// @param _creator Address who creates EVMScript
    /// @param _evmScriptCallData Encoded tuple: (address[] recipients, uint256[] amounts) where
    /// recipients - addresses of recipients to top up
    /// amounts - corresponding amounts of token to transfer
    /// @dev note that the arrays below has one extra element to store limit enforcement calls
    function createEVMScript(address _creator, bytes memory _evmScriptCallData)
        external
        view
        override
        onlyTrustedCaller(_creator)
        returns (bytes memory)
    {
        (address[] memory recipients, uint256[] memory amounts) = _decodeEVMScriptCallData(
            _evmScriptCallData
        );
        uint256 totalAmount = _validateEVMScriptCallData(recipients, amounts);

        address[] memory to = new address[](recipients.length + 1);
        bytes4[] memory methodIds = new bytes4[](recipients.length + 1);
        bytes[] memory evmScriptsCalldata = new bytes[](recipients.length + 1);

        to[0] = address(allowedRecipientsRegistry);
        methodIds[0] = allowedRecipientsRegistry.updateSpentAmount.selector;
        evmScriptsCalldata[0] = abi.encode(totalAmount);

        for (uint256 i = 0; i < recipients.length; ++i) {
            to[i + 1] = address(finance);
            methodIds[i + 1] = finance.newImmediatePayment.selector;
            evmScriptsCalldata[i + 1] = abi.encode(
                token,
                recipients[i],
                amounts[i],
                "Easy Track: top up recipient"
            );
        }

        return EVMScriptCreator.createEVMScript(to, methodIds, evmScriptsCalldata);
    }

    /// @notice Decodes call data used by createEVMScript method
    /// @param _evmScriptCallData Encoded tuple: (address[] recipients, uint256[] amounts) where
    /// recipients - addresses of recipients to top up
    /// amounts - corresponding amounts of token to transfer
    /// @return recipients Addresses of recipients to top up
    /// @return amounts Amounts of token to transfer
    function decodeEVMScriptCallData(bytes memory _evmScriptCallData)
        external
        pure
        returns (address[] memory recipients, uint256[] memory amounts)
    {
        return _decodeEVMScriptCallData(_evmScriptCallData);
    }

    // ------------------
    // PRIVATE METHODS
    // ------------------

    function _validateEVMScriptCallData(address[] memory _recipients, uint256[] memory _amounts)
        private
        view
        returns (uint256 totalAmount)
    {
        require(_amounts.length == _recipients.length, ERROR_LENGTH_MISMATCH);
        require(_recipients.length > 0, ERROR_EMPTY_DATA);

        for (uint256 i = 0; i < _recipients.length; ++i) {
            require(_amounts[i] > 0, ERROR_ZERO_AMOUNT);
            require(
                allowedRecipientsRegistry.isRecipientAllowed(_recipients[i]),
                ERROR_RECIPIENT_NOT_ALLOWED
            );
            totalAmount += _amounts[i];
        }

        _validateSpendableBalance(totalAmount);
    }

    function _decodeEVMScriptCallData(bytes memory _evmScriptCallData)
        private
        pure
        returns (address[] memory recipients, uint256[] memory amounts)
    {
        return abi.decode(_evmScriptCallData, (address[], uint256[]));
    }

    function _validateSpendableBalance(uint256 _amount) private view {
        require(
            allowedRecipientsRegistry.isUnderSpendableBalance(_amount, easyTrack.motionDuration()),
            ERROR_SUM_EXCEEDS_SPENDABLE_BALANCE
        );
    }
}